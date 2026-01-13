#!/usr/bin/env Rscript
# Purpose: Create coefficient plot for standardized health outcomes

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(rio)
  library(stringr)
})

# =============================================================================
# Path Configuration - Supports both Snakemake and standalone execution
# =============================================================================

if (exists("snakemake")) {
  # Running via Snakemake - use provided paths
  csv_path <- snakemake@input[["csv"]]
  output_file <- snakemake@output[[1]]

} else {
  # Running standalone - check for command line args first
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 2) {
    csv_path <- args[[1]]
    output_file <- args[[2]]
  } else {
    # Load configuration file
    config_path <- file.path(dirname(sys.frame(1)$ofile), "..", "config_paths.R")
    if (!file.exists(config_path)) {
      stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Set script-specific paths using config
    csv_path <- get_output_path("figure_4_me_other_outcomes_sdunit.csv")
    output_file <- get_output_path("figure_4_other_outcomes_sdunit.png")
  }
}

# Read the marginal effects
dt <- as.data.table(import(csv_path))
setnames(dt, tolower(names(dt)))

# Create nice labels for outcomes
outcome_labels <- c(
  general_health = "General health",
  mental_health = "Mental health",
  physical_health = "Physical health",
  anx_severity = "Anxiety severity",
  dep_severity = "Depression severity",
  inflammation = "Inflammation",
  multi_morbidity = "Multi-morbidity",
  waist_to_hip_ratio = "Waist-to-hip ratio",
  bmi = "BMI",
  obese = "Obese",
  height = "Height",
  pace = "DunedinPACE",
  ageaccelgrim2 = "GrimAge acceleration"
)

# Create outcome categories for grouping
outcome_categories <- c(
  general_health = "Self-rated health",
  mental_health = "Mental health",
  physical_health = "Self-rated health",
  anx_severity = "Mental health",
  dep_severity = "Mental health",
  inflammation = "Biomarkers",
  multi_morbidity = "Chronic conditions",
  waist_to_hip_ratio = "Anthropometric",
  bmi = "Anthropometric",
  obese = "Anthropometric",
  height = "Anthropometric",
  pace = "Biological aging",
  ageaccelgrim2 = "Biological aging"
)

# Define category ordering
category_levels <- c(
  "Self-rated health",
  "Mental health",
  "Chronic conditions",
  "Anthropometric",
  "Biomarkers",
  "Biological aging"
)

# Add labels and categories
dt[, label := outcome_labels[outcome]]
dt[, category := factor(outcome_categories[outcome], levels = category_levels)]

# Drop obese indicator
dt <- dt[outcome != "obese"]

dt[, signif := fifelse(p_value < 0.05, "Significant", "Not significant")]
dt[, effect_dir := fifelse(estimate > 0, "Positive", "Negative")]
dt[, color_label := fifelse(
  signif == "Significant",
  paste(effect_dir, "sig"),
  paste(effect_dir, "insig")
)]
dt[, color_label := factor(
  color_label,
  levels = c("Positive sig", "Negative sig", "Positive insig", "Negative insig")
)]

# Order outcomes by category and effect size within category
setorder(dt, category, -estimate)
label_levels <- unique(dt$label)
dt[, label := factor(label, levels = rev(label_levels))]

# Create figure title and caption in PNAS format
fig_title <- "Association Between Network Hasslers and Health Outcomes"
fig_caption <- "Average marginal effects from survey-weighted regression models examining associations between the number of network hasslers and health outcomes (standardized to SD units). Estimates reflect the change in each outcome (in standard deviation units) associated with a one-unit increase in the number of hasslers, adjusted for batch effects, leukocyte cell composition, age, race, gender, education, marital status, and network size, with 95% confidence intervals. Outcomes are grouped by domain: self-rated health, mental health, chronic conditions, anthropometric measures, biomarkers, and biological aging. Please see Table XX."

# Create the coefficient plot
p <- ggplot(
  dt,
  aes(x = estimate, y = label)
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(
    aes(
      xmin = conf_low,
      xmax = conf_high,
      color = color_label,
      linetype = signif
    ),
    size = 0.6
  ) +
  facet_grid(category ~ ., scales = "free_y", space = "free_y") +
  scale_color_manual(
    values = c(
      "Positive sig" = "#2b8cbe",
      "Negative sig" = "#b2182b",
      "Positive insig" = "#a6cee3",
      "Negative insig" = "#fbb4b9"
    ),
    name = "Direction & significance"
  ) +
  scale_linetype_manual(
    values = c("Significant" = "solid", "Not significant" = "dotted"),
    name = "p < 0.05"
  ) +
  theme_bw() +
  labs(
    x = "Effect of network hasslers (SD units)",
    y = NULL
  ) +
  theme(
    legend.position = "bottom",
    axis.text.y = element_text(color = "black", size = 10),
    strip.text.y = element_text(angle = 0, hjust = 0),
    strip.background = element_rect(fill = "grey90"),
    panel.spacing = unit(0.5, "lines")
  )

# Save the plot
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
ggsave(output_file, p, width = 8, height = 7, dpi = 300)

cat("Coefficient plot saved to:", output_file, "\n")
