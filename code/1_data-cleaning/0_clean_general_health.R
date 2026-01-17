#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# general health variables
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - general_health: General health rating (1-5)
#   - mental_health: Mental health rating (1-5)
#   - physical_health: Physical health rating (1-5)
#   - matter_important: How important are you to others
#   - matter_depend: How much do others depend on you
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
            general_health = get_raw_path('general_physical_health.dta')
        ),
        output = list(
            df_general_health = get_processed_path('p2p_general_health.rds')
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
dt_health = import(snakemake@input$general_health)
setDT(dt_health)

names(dt_health) = tolower(names(dt_health))
dt_health[,table(general_health)]
for (var in c('general_health','mental_health','physical_health')) {
	dt_health[get(var) > 90, (var) := NA]
}

for (var in c('matter_important', 'matter_depend')) {
	dt_health[get(var) > 4, (var) := NA]
}

dt_health = dt_health[,c('su_id','general_health','mental_health','physical_health',
'matter_depend','matter_important')]

log_info('# save processed data')

saveRDS(dt_health, snakemake@output$df_general_health)


