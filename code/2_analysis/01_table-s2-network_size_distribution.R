#!/usr/bin/env Rscript
# Purpose: Tabulate overall network size distribution and hassler prevalence.

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
    config_path <- file.path(dirname(sys.frame(1)$ofile), "..", "config_paths.R")
    if (!file.exists(config_path)) {
      stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Set script-specific paths using config
    data_path <- get_processed_path("p2p_epigen_0501.rds")
    output_file <- get_output_path("table_s2_distribution_network_size.xlsx")
  }
}

dt <- readRDS(data_path)
dt[, n_size_10 := fifelse(n_size_all > 10, 10, n_size_all)]

summary_tab <- dt[
  ,
  .(
    N = .N,
    p_hassler = mean(p_hassler, na.rm = TRUE)
  ),
  by = n_size_10
][
  ,
  p := N / sum(N) * 100
][order(n_size_10)]

summary_tab <- rbind(
  summary_tab,
  data.table(
    n_size_10 = "mean",
    N = mean(dt$n_size_10, na.rm = TRUE),
    p = 100,
    p_hassler = mean(dt$p_hassler, na.rm = TRUE)
  ),
  data.table(
    n_size_10 = "sd",
    N = sd(dt$n_size_10, na.rm = TRUE),
    p = NA_real_,
    p_hassler = sd(dt$p_hassler, na.rm = TRUE)
  ),
  fill = TRUE
)

summary_tab[
  ,
  `:=`(
    N = round(N, 2),
    p = round(p, 1),
    p_hassler = round(p_hassler * 100, 1)
  )
]

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
export(summary_tab, output_file)
