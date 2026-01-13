#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# belief variables: ACES (Adverse Childhood Experiences)
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - aces_sum: Sum of adverse childhood experiences
#   - aces_sum_std: Standardized ACES sum score
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
            belief = get_raw_path(file.path('P2P','2021-09 Delivery', 'Stata Files', 'beliefs_attitudes_other_scales.dta'))
        ),
        output = list(
            df_belief = get_processed_path('p2p_belief_cleaned.rds')
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

log_info('load baseline data')
dt_belief = import(snakemake@input$belief)

setDT(dt_belief)
names(dt_belief) = tolower(names(dt_belief))

var_aces = grep('aces_',names(dt_belief),value=TRUE)

for (var in var_aces){
	dt_belief[get(var) > 90, (var) := NA]
	# reverse coding
	dt_belief[, (var) := ifelse(get(var) == 1, 1, 0)]
}

dt_belief[, aces_sum := rowSums(.SD, na.rm=TRUE), .SDcols = var_aces]

log_info('save belief data')

dt_belief[, aces_sum_std := scale(aces_sum)]
dt_belief = dt_belief[,c('su_id','aces_sum','aces_sum_std'), with=F]

saveRDS(dt_belief, snakemake@output$df_belief)

