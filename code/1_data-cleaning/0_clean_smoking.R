#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# smoking variables
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - smoke_status: Smoking status (never smoker, ever smoker, current smoker, daily smoker)
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
            smoke = get_raw_path('tobacco.dta')
        ),
        output = list(
            df_smoke = get_processed_path('p2p_smoke.rds')
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
dt_smoking = import(snakemake@input$smoke)
setDT(dt_smoking)
names(dt_smoking) = tolower(names(dt_smoking))

dt_smoking[,table(smoked_cigs)]
dt_smoking[,table(current_smoke)]

log_info('Clean smoking variables ... ')
dt_smoking[current_smoke == 1, smoke_status := 'daily smoker']
dt_smoking[current_smoke == 2, smoke_status := 'current smoker']
dt_smoking[current_smoke == 3 & smoked_cigs == 1, smoke_status := 'ever smoker']
dt_smoking[smoked_cigs == 2, smoke_status := 'never smoker']
dt_smoking[is.na(smoke_status) & smoked_cigs == 1, smoke_status := 'ever smoker']
dt_smoking[, smoke_status := factor(smoke_status,
	levels = c('never smoker','ever smoker','current smoker', 'daily smoker'))]

dt_smoke = dt_smoking[,c('su_id','smoke_status')]

saveRDS(dt_smoke, snakemake@output$df_smoke)


