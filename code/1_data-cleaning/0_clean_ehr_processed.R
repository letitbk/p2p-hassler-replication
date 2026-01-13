#!/usr/bin/env Rscript

#' ==============================================================================
#' P2P Data Cleaning - EHR Processed Variables
#' ==============================================================================
#'
#' Purpose: Compute comorbidity indices from Electronic Health Records (EHR)
#'
#' Input files:
#'   - p2p_demo_cleaned.rds: P2P demographic data with interview dates
#'   - RDRP-5085 Diagnoses.csv: ICD-9/10 diagnosis codes from EHR
#'   - RDRP-5085 Encounters.csv: Healthcare encounter records
#'
#' Output variables:
#'   - su_id: Subject ID
#'   - cci_charlson_past3years: Charlson Comorbidity Index (3-year lookback)
#'   - any_encounter_3years: Any healthcare encounter in past 3 years (binary)
#'
#' Methods:
#'   - Charlson Comorbidity Index computed using the 'comorbidity' R package
#'   - ICD-9 and ICD-10 codes are processed separately then combined
#'   - Uses Charlson weighting scheme (score range: 0-37)
#'   - 3-year lookback window relative to survey interview date
#' ==============================================================================

#' =============================================================================
#' Path Configuration - Supports both Snakemake and standalone execution
#' =============================================================================

if (!exists('snakemake')) {
    # Standalone mode - load configuration file
    config_path <- file.path(dirname(sys.frame(1)$ofile), "..", "config_paths.R")
    if (!file.exists(config_path)) {
        stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Create mock snakemake object for standalone execution
    snakemake <- setClass("snakemake",
      slots = c(
        input = "list",
        params = "list",
        output = "list")
    )

    snakemake = new(
        "snakemake",
        input = list(
            df_demo = get_processed_path('p2p_demo_cleaned.rds'),
            ehr_diagnoses = get_ehr_path('RDRP-5085 Diagnoses.csv'),
            ehr_encounters = get_ehr_path('RDRP-5085 Encounters.csv')
        ),
        output = list(
            df_ehr_processed = get_processed_path('p2p_ehr_processed.rds')
        )
    )

} else {
    # Snakemake mode - set up logging
    log_file = file(snakemake@log[[1]], open = "wt")
    sink(log_file, type = "output")
    sink(log_file, type = "message")
}

library(data.table)
library(rio)
library(logger)
library(comorbidity)

log_info('Loading baseline data...')

# Load P2P demo data (for interview dates)
dt_demo = readRDS(snakemake@input$df_demo)

# Load EHR data (use read.csv to avoid mmap issues on network drives)
dt_ehr_encounters = as.data.table(read.csv(snakemake@input$ehr_encounters, stringsAsFactors = FALSE))
dt_ehr_diagnoses = as.data.table(read.csv(snakemake@input$ehr_diagnoses, stringsAsFactors = FALSE))

# Standardize column names
names(dt_ehr_encounters) = tolower(names(dt_ehr_encounters))
names(dt_ehr_diagnoses) = tolower(names(dt_ehr_diagnoses))

log_info('Processing encounter dates...')

# Parse encounter arrival dates
Sys.setlocale("LC_TIME", "C")
dt_ehr_encounters[, date_arrival := as.Date(
    as.POSIXct(strptime(arrive_date, "%d%b%Y:%H:%M:%S"), tz = "America/New_York")
)]

# Merge with interview dates to compute time windows
setnames(dt_ehr_encounters, 'subjectid', 'su_id')
dt_ehr_encounters = merge(
    dt_ehr_encounters,
    dt_demo[, c('su_id', 'interview_date')],
    by = 'su_id',
    all.x = TRUE
)
dt_ehr_encounters[, interview_date := as.Date(interview_date)]
dt_ehr_encounters[, diff_from_survey := interview_date - date_arrival]

# Flag encounters within 3 years before survey
dt_ehr_encounters[diff_from_survey > 0, within_3years := ifelse(diff_from_survey <= 365 * 3, 1, 0)]

log_info('Processing diagnosis codes...')

# Add encounter dates to diagnoses
setnames(dt_ehr_diagnoses, 'subjectid', 'su_id')
dt_ehr_diagnoses = merge(
    dt_ehr_diagnoses,
    dt_ehr_encounters[, c('su_id', 'masked_encounter_id', 'date_arrival', 'interview_date', 'within_3years')],
    by = c('su_id', 'masked_encounter_id'),
    all.x = TRUE
)

# Normalize diagnosis codes
dt_ehr_diagnoses[, dx_code := toupper(dx_code)]

log_info('Computing Charlson Comorbidity Index...')

# Function to compute Charlson scores from ICD codes
compute_charlson_score <- function(dt_dx) {
    if (nrow(dt_dx) == 0) return(data.table(su_id = character(), cci_charlson = numeric()))

    # Helper to compute comorbidity object
    compute_map <- function(dt_codes, map_name) {
        if (nrow(dt_codes) == 0) return(NULL)
        comorbidity(
            x = as.data.frame(dt_codes),
            id = "su_id",
            code = "dx_code",
            map = map_name,
            assign0 = TRUE
        )
    }

    # Separate ICD-10 and ICD-9 codes
    dx10 = dt_dx[dx_code_system == 'ICD-10', .(su_id, dx_code)]
    dx9  = dt_dx[dx_code_system == 'ICD-9',  .(su_id, dx_code)]

    char10 = compute_map(dx10, "charlson_icd10_quan")
    char9  = compute_map(dx9,  "charlson_icd9_quan")

    # Combine ICD-9 and ICD-10 results
    if (is.null(char10) && is.null(char9)) {
        return(data.table(su_id = character(), cci_charlson = numeric()))
    }

    if (is.null(char10)) {
        char_all = char9
    } else if (is.null(char9)) {
        char_all = char10
    } else {
        # Merge and take maximum indicator for each condition
        df_a = as.data.frame(char10)
        df_b = as.data.frame(char9)
        ind_cols = setdiff(union(names(df_a), names(df_b)), "su_id")

        for (col in setdiff(ind_cols, names(df_a))) df_a[[col]] = 0L
        for (col in setdiff(ind_cols, names(df_b))) df_b[[col]] = 0L

        merged = merge(
            df_a[, c("su_id", ind_cols)],
            df_b[, c("su_id", ind_cols)],
            by = "su_id", all = TRUE, suffixes = c(".a", ".b")
        )

        for (col in ind_cols) {
            va = merged[[paste0(col, ".a")]]
            vb = merged[[paste0(col, ".b")]]
            va[is.na(va)] = 0L
            vb[is.na(vb)] = 0L
            merged[[col]] = pmax(as.integer(va), as.integer(vb))
        }

        char_all = merged[, c("su_id", ind_cols)]
        class(char_all) = c("comorbidity", class(char_all))
        attr(char_all, "map") = "charlson_icd10_quan"
    }

    # Compute Charlson-weighted score
    cci_score = score(char_all, weights = "charlson", assign0 = FALSE)

    result = data.table(
        su_id = char_all$su_id,
        cci_charlson = as.numeric(cci_score)
    )

    return(result)
}

# Compute Charlson scores for 3-year window
dt_dx_3years = dt_ehr_diagnoses[
    dx_code_system %in% c('ICD-9', 'ICD-10') & within_3years == 1
]
pat_charlson = compute_charlson_score(dt_dx_3years)
setnames(pat_charlson, 'cci_charlson', 'cci_charlson_past3years')

log_info('Computing encounter indicators...')

# Count encounters within 3-year window
pat_encounter = dt_ehr_encounters[
    within_3years == 1,
    .(n_encounters = .N),
    by = 'su_id'
]

# Get all unique subjects from encounters
all_subjects = unique(dt_ehr_encounters$su_id)
dt_merged = data.table(su_id = all_subjects)

# Merge Charlson scores
dt_merged = merge(dt_merged, pat_charlson, by = "su_id", all.x = TRUE)

# Create any_encounter indicator
dt_merged = merge(dt_merged, pat_encounter, by = "su_id", all.x = TRUE)
dt_merged[, any_encounter_3years := ifelse(!is.na(n_encounters), 1, 0)]
dt_merged[, n_encounters := NULL]

log_info('Saving output...')

# Keep only required columns
dt_output = dt_merged[, .(su_id, cci_charlson_past3years, any_encounter_3years)]

saveRDS(dt_output, snakemake@output$df_ehr_processed)
export(dt_output, gsub('.rds', '.dta', snakemake@output$df_ehr_processed))

log_info('Done. Output: %s', snakemake@output$df_ehr_processed)
