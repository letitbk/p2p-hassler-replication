#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# multi-morbidity variables (from family health survey)
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - multi_morbidity: Count of self-reported health conditions
#   - n_missing_morbidity: Number of missing condition responses
#' ==============

#' =============================================================================
#' Path Configuration - Supports both Snakemake and standalone execution
#' =============================================================================

if (!exists("snakemake")) {
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
            familyhealth = get_raw_path('family_health.dta')
        ),
        output = list(
            df_familyhealth = get_processed_path('p2p_familyhealth.rds')
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
library(fst)
library(logger)

log_info('# load baseline data')
dt_familyhealth = import(snakemake@input$familyhealth)
setDT(dt_familyhealth)
names(dt_familyhealth) = tolower(names(dt_familyhealth))

# create multi-morbidity measures
conditions = grep('fh_.*_self$',names(dt_familyhealth),value=TRUE)
for (x in conditions){
    dt_familyhealth[get(x) %in% 92:99, (x) := NA]
}

dt_familyhealth[,multi_morbidity := rowSums(.SD, na.rm = TRUE), .SDcols = conditions]

# count the number of missing values across columns
dt_familyhealth[, n_missing_morbidity := rowSums(is.na(.SD)), .SDcols = conditions]

# select variables I created
sel_var = c('su_id','multi_morbidity','n_missing_morbidity')

dt_familyhealth = dt_familyhealth[,..sel_var]

saveRDS(dt_familyhealth, snakemake@output$df_familyhealth)


