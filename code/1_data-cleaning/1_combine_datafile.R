#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# combine all data files
#' ==============
# This script merges all cleaned data files into a single analysis-ready dataset.
# Output variables include epigenetic clocks, network measures, demographics,
# health outcomes, and control variables.
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
            df_clock = get_processed_path('p2p_clock.rds'),
            df_smoke = get_processed_path('p2p_smoke.rds'),
            df_service = get_processed_path('p2p_service_utilization.rds'),
            df_weight = get_processed_path('p2p_weight.rds'),
            df_demo = get_processed_path('p2p_demo_cleaned.rds'),
            df_general_health = get_processed_path('p2p_general_health.rds'),
            df_mental_health = get_processed_path('p2p_mental_health.rds'),
            df_familyhealth = get_processed_path('p2p_familyhealth.rds'),
            df_biomeasure = get_processed_path('p2p_biomeasures.rds'),
            df_belief = get_processed_path('p2p_belief_cleaned.rds'),
            df_egonetwork = get_processed_path('p2p_egonetwork.rds'),
            df_occupation = get_processed_path('p2p_occupation.rds'),
            df_ehr_processed = get_processed_path('p2p_ehr_processed.rds'),
            df_covid_wave3 = get_processed_path('p2p_covid_wave3.rds')
        ),
        output = list(
            df_epigen = get_processed_path('p2p_epigen_0501.rds'),
            df_epigen_dta = get_processed_path('p2p_epigen_0501.dta')
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
library(marginaleffects)

log_info("Load all data ...")
df_clock = readRDS(snakemake@input$df_clock)
df_smoke = readRDS(snakemake@input$df_smoke)
df_service = readRDS(snakemake@input$df_service)
df_weight = readRDS(snakemake@input$df_weight)
df_demo = readRDS(snakemake@input$df_demo)
df_general_health = readRDS(snakemake@input$df_general_health)
df_mental_health = readRDS(snakemake@input$df_mental_health)
df_familyhealth = readRDS(snakemake@input$df_familyhealth)
df_biomeasure = readRDS(snakemake@input$df_biomeasure)
df_belief = readRDS(snakemake@input$df_belief)
df_egonetwork = readRDS(snakemake@input$df_egonetwork)
df_occupation = readRDS(snakemake@input$df_occupation)
df_ehr_processed = readRDS(snakemake@input$df_ehr_processed)
df_covid_wave3 = readRDS(snakemake@input$df_covid_wave3)

log_info("# combine multiple data sets ")
merge_list = list(
    df_demo,
    df_egonetwork,
    df_clock,
    df_weight,
    df_smoke,
    df_service,
    df_general_health,
    df_mental_health,
    df_familyhealth,
    df_biomeasure,
    df_belief,
    df_occupation,
    df_ehr_processed,
    df_covid_wave3
)

df_merged = Reduce(
    function(left, right) merge(left, right, by = "su_id", all = TRUE),
    merge_list
)
log_info("Merged dataset has {nrow(df_merged)} rows and {ncol(df_merged)} columns")


# okay, then predict who is part of the epigenome sample
df_merged[, weight_one := 1]
df_merged[, i_hassler := fifelse(
    !is.na(n_size_hassler),
    as.integer(n_size_hassler > 0),
    NA_integer_
)]

# some additional data cleaning
#df_merged[, batch := factor(batch)]
df_merged[, batch_int := factor(batch_int)]

# create covid indicator
#df_merged[, saliva_date_time := as.POSIXct(saliva_measurements_starttime, format = "%m/%d/%Y %H:%M")]
#df_merged[, saliva_date := as.Date(saliva_date_time)]

df_merged[, interview_date := as.Date(interview_date)]
df_merged[, covid := ifelse(interview_date >= as.Date('2020-04-01'), 1, 0)]


# age adjustment using regression models
#df_merged[,table(age2)]
df_merged[, age2 := ifelse(age > 80, 80, age)]

for (var in c('horvath','skinblood','phenoage','pace','dnamgrimage2')){
	age_model = lm(as.formula(paste0(var, '~ age')),
			data = df_merged)
	df_merged[[paste0(var,'_pred')]] = predict(age_model, newdata = df_merged)
	df_merged[[paste0(var,'_res')]] = df_merged[[var]] - df_merged[[paste0(var,'_pred')]]
}

# check some correlations
#tab1 = df_merged[, cor(.SD, use = 'pairwise.complete.obs'), .SDcols = c('age','horvath','skinblood','phenoage', 'pace')]
#tab2 = df_merged[, cor(.SD, use = 'pairwise.complete.obs'), .SDcols = c('age','horvath_res','skinblood_res','phenoage_res', 'pace')]
#
#df_merged[, cor.test(horvath, phenoage)]
#df_merged[, cor.test(horvath, pace)]

saveRDS(df_merged, snakemake@output$df_epigen)
export(df_merged, snakemake@output$df_epigen_dta)
