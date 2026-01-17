#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# wave 3 variables (COVID-19 follow-up)
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - wave3_general_health: General health rating at wave 3
#   - wave3_mental_health: Mental health rating at wave 3
#   - wave3_physical_health: Physical health rating at wave 3
#' ==============

#' =============================================================================
#' Path Configuration - Supports both Snakemake and standalone execution
#' =============================================================================

if (!exists("snakemake")) {
    # Standalone mode - load configuration file
    config_path <- paste0("../", "config_paths.R")
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
            covid_wave3 = get_covid_path('P2PCovid19 Wave3 main.dta')
        ),
        output = list(
            df_covid_wave3 = get_processed_path('p2p_covid_wave3.rds')
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

log_info('# load wave 3 data')
dt_wave3 = import(snakemake@input$covid_wave3)
setDT(dt_wave3)
names(dt_wave3) = tolower(names(dt_wave3))

log_info('# create wave 3 health variables')
dt_wave3[, wave3_general_health := health1]
dt_wave3[, wave3_mental_health := health2]
dt_wave3[, wave3_physical_health := health3]

dt_wave3_processed = dt_wave3[, c('su_id','wave3_general_health','wave3_mental_health','wave3_physical_health')]

dt_wave3_processed[, su_id := as.integer(su_id)]

log_info('# save processed data')
saveRDS(dt_wave3_processed, snakemake@output$df_covid_wave3)


