#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# service utilization
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - health_insurance: Health insurance indicator (0/1)
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
            service = get_raw_path('service_utilization.dta')
        ),
        output = list(
            df_service = get_processed_path('p2p_service_utilization.rds')
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
df_service = import(snakemake@input$service)
setDT(df_service)
names(df_service) = tolower(names(df_service))

log_info('Clean service utilization variables ... ')

df_service[type_ins_emp == 1,health_insurance := 1]
df_service[type_ins_empspou == 1,health_insurance := 1]
df_service[type_ins_self == 1,health_insurance := 1]
df_service[type_ins_medicare == 1,health_insurance := 1]
df_service[type_ins_medicaid_hip == 1,health_insurance := 1]
df_service[type_ins_govt == 1,health_insurance := 1]
df_service[type_ins_else == 1,health_insurance := 1]
df_service[type_ins_no == 1,health_insurance := 0]

df_service = df_service[,c('su_id','health_insurance')]

saveRDS(df_service, snakemake@output$df_service)


