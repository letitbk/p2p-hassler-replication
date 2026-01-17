#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# mental health variables
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - anx_severity: Anxiety severity score
#   - dep_severity: Depression severity score
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
            mental_health = get_raw_path('mental_health.dta')
        ),
        output = list(
            df_mental_health = get_processed_path('p2p_mental_health.rds')
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
dt_mh = import(snakemake@input$mental_health)
setDT(dt_mh)
names(dt_mh) = tolower(names(dt_mh))

dt_mh[anx_severity > 900, anx_severity := NA]
dt_mh[dep_severity > 900, dep_severity := NA]


dt_mh = dt_mh[,c('su_id','anx_severity', 'dep_severity')]
log_info('# save processed data')

saveRDS(dt_mh, snakemake@output$df_mental_health)


