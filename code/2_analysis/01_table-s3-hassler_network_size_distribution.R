#!/usr/bin/env Rscript
# Purpose: Summarize distributions of hassler network size variants.

suppressPackageStartupMessages({
  library(data.table)
  library(rio)
})

# =============================================================================
# Path Configuration - Supports both Snakemake and standalone execution
# =============================================================================

if (exists("snakemake")) {
  # Running via Snakemake - use provided paths
  data_path <- snakemake@input[["data"]]
  output_file <- snakemake@output[[1]]

} else {
  # Running standalone - check for command line args first
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 2) {
    data_path <- args[[1]]
    output_file <- args[[2]]
  } else {
    # Load configuration file
    config_path <- paste0("../", "config_paths.R")
    if (!file.exists(config_path)) {
      stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Set script-specific paths using config
    data_path <- get_processed_path("p2p_epigen_0501.rds")
    output_file <- get_output_path("table_s3_distribution_hassler_network_size.xlsx")
  }
}

dt <- readRDS(data_path)

# Only use n_size_hassler (sole and ambiv variants don't exist in the dataset)
dt[, n_size_hassler_10 := fifelse(n_size_hassler > 6, 6, n_size_hassler)]

summary_tab <- dt[, .(hassler_N = .N), by = n_size_hassler_10][
  ,
  hassler_p := hassler_N / sum(hassler_N) * 100
][order(n_size_hassler_10)]

summary_tab <- rbind(
  summary_tab,
  data.table(
    n_size_hassler_10 = "mean",
    hassler_N = mean(dt$n_size_hassler_10, na.rm = TRUE),
    hassler_p = 100
  ),
  data.table(
    n_size_hassler_10 = "sd",
    hassler_N = sd(dt$n_size_hassler_10, na.rm = TRUE),
    hassler_p = NA_real_
  ),
  fill = TRUE
)

summary_tab[
  ,
  `:=`(
    hassler_N = round(hassler_N, 2),
    hassler_p = round(hassler_p, 1)
  )
]

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
export(summary_tab, output_file)
