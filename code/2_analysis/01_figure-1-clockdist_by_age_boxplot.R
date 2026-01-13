#!/usr/bin/env Rscript
# Purpose: Create faceted boxplots of DunedinPACE and GrimAge2 by age group.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
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
    output_file <- get_output_path("figure_1_clockdist_by_age_boxplot.png")
  }
}

dt <- readRDS(data_path)
dt[, age_cap85 := fifelse(age >= 85, 85, age)]
dt[, age_cap85 := cut(age_cap85, breaks = c(17, 30, 40, 50, 60, 70, 85), include.lowest = TRUE, right = TRUE)]

long_dt <- melt(
  dt[!is.na(age_cap85), .(su_id, age_cap85, pace, ageaccelgrim2)],
  id.vars = c("su_id", "age_cap85")
)

stats <- long_dt[
  ,
  .(
    xmin = min(value, na.rm = TRUE),
    lower = quantile(value, 0.25, na.rm = TRUE),
    middle = median(value, na.rm = TRUE),
    upper = quantile(value, 0.75, na.rm = TRUE),
    xmax = max(value, na.rm = TRUE)
  ),
  by = .(age_cap85, variable)
]

stats[, y := as.numeric(as.factor(age_cap85))]
stats[
  ,
  variable := factor(
    variable,
    levels = c("ageaccelgrim2", "pace"),
    labels = c("Age-accelerated GrimAge2", "DunedinPACE")
  )
]

p <- ggplot(stats, aes(y = factor(age_cap85))) +
  geom_rect(
    aes(xmin = lower, xmax = middle, ymin = y - 0.4, ymax = y + 0.4),
    fill = "grey",
    alpha = 0.5
  ) +
  geom_rect(
    aes(xmin = middle, xmax = upper, ymin = y - 0.4, ymax = y + 0.4),
    fill = "black",
    alpha = 0.5
  ) +
  geom_segment(aes(x = middle, xend = middle, y = y - 0.4, yend = y + 0.4)) +
  geom_segment(aes(x = xmin, xend = lower, y = y, yend = y)) +
  geom_segment(aes(x = upper, xend = xmax, y = y, yend = y)) +
  geom_vline(
    data = data.table(
      variable = c("DunedinPACE", "Age-accelerated GrimAge2"),
      xintercept = c(1, 0)
    ),
    aes(xintercept = xintercept),
    color = "red"
  ) +
  facet_wrap(~variable, scales = "free_x") +
  theme_bw() +
  labs(x = "Epigenetic Clock Values", y = "Biological Age Group")

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
ggsave(output_file, p, width = 7, height = 4)
