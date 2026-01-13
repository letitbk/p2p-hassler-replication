#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# biomeasure variables
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - bmi: Body mass index
#   - height: Height (average of 3 measurements)
#   - waist_to_hip_ratio: Waist-to-hip ratio
#   - obese: Obesity indicator (BMI >= 30)
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
            biomeasure = get_raw_path('saliva_and_measurements.dta')
        ),
        output = list(
            df_biomeasure = get_processed_path('p2p_biomeasures.rds')
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
dt_biomeasure = import(snakemake@input$biomeasure)
setDT(dt_biomeasure)
names(dt_biomeasure) = tolower(names(dt_biomeasure))

# consider missing patterns
measure_var = grep('measure_',names(dt_biomeasure),value=TRUE)
for (m in measure_var) {
  dt_biomeasure[get(m) %in% 991:997, (m) := NA]
}


# height (average of 3 measurements)
dt_biomeasure[, height := rowMeans(.SD, na.rm=TRUE), .SDcols = c('measure_height1','measure_height2','measure_height3')]

# waist to hip ratio
dt_biomeasure[, waist := rowMeans(.SD, na.rm=TRUE), .SDcols = c('measure_waist1','measure_waist2','measure_waist3')]
dt_biomeasure[, hip := rowMeans(.SD, na.rm=TRUE), .SDcols = c('measure_hip1','measure_hip2','measure_hip3')]
dt_biomeasure[, waist_to_hip_ratio := waist/hip]

# obesity indicator
dt_biomeasure[, obese := as.integer(bmi >= 30)]

# select variables for analysis
sel_var = c('su_id','bmi','height','waist_to_hip_ratio','obese')
dt_biomeasure = dt_biomeasure[,..sel_var]

saveRDS(dt_biomeasure, snakemake@output$df_biomeasure)


