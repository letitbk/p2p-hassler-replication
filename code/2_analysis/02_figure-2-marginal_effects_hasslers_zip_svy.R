#!/usr/bin/env Rscript
# Purpose: Plot survey-weighted ZIP marginal effects produced by zip_mchange_hasslers_svy.do.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(rio)
  library(haven)
})

# =============================================================================
# Path Configuration - Supports both Snakemake and standalone execution
# =============================================================================

if (exists("snakemake")) {
  # Running via Snakemake - use provided paths
  csv_main <- snakemake@input[["csv_main"]]
  data_path <- snakemake@input[["data"]]
  output_file <- snakemake@output[["plot"]]

} else {
  # Running standalone - check for command line args first
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 3) {
    csv_main <- args[[1]]
    data_path <- args[[2]]
    output_file <- args[[3]]
  } else {
    # Load configuration file
    config_path <- file.path(dirname(sys.frame(1)$ofile), "..", "config_paths.R")
    if (!file.exists(config_path)) {
      stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Set script-specific paths using config
    data_path <- get_processed_path("p2p_epigen_regression.dta")
    csv_main <- get_output_path("figure_2_marginal_effects_hasslers_zip_svy_main.csv")
    output_file <- get_output_path("figure_2_marginal_effects_hasslers_zip_svy.png")
  }
}

read_effects <- function(path) {
  dt <- as.data.table(import(path))
  setnames(dt, tolower(names(dt)))
  dt
}

effects <- read_effects(csv_main)
dt_labels <- as.data.table(haven::read_dta(data_path))

get_value_labels <- function(df, var) {
  lbl <- attr(df[[var]], "labels")
  if (is.null(lbl)) return(NULL)
  setNames(names(lbl), as.character(unname(lbl)))
}

value_labels <- list(
  race3 = get_value_labels(dt_labels, "race3"),
  gender_birth = get_value_labels(dt_labels, "gender_birth"),
  educ3 = get_value_labels(dt_labels, "educ3"),
  marital3 = get_value_labels(dt_labels, "marital3"),
  occ_group = get_value_labels(dt_labels, "occ_group"),
  smoke_status = get_value_labels(dt_labels, "smoke_status")
)

var_labels <- c(
  age_sd = "Age (per 1 SD+)",
  race3 = "Race",
  gender_birth = "Gender at birth",
  educ3 = "Education",
  marital3 = "Marital status",
  covid = "Survey during COVID-19",
  smoke_status = "Smoking",
  multi_morbidity_sd = "Lifetime Multiple Morbidity (per 1 SD+)",
  general_health_sd = "Self-reported health (per 1 SD+)",
  n_size_all_sd = "Network size (per 1 SD+)",
  health_insurance = "Health insurance",
  matter_depend_binary = "How much do others depend on you",
  matter_important_binary = "How important are you to others",
  aces_sum_sd = "Adverse Childhood Experiences score (per 1 SD+)",
  occ_group = "Occupation"
)

var_categories <- c(
  age_sd = "Demographics",
  race3 = "Demographics",
  gender_birth = "Demographics",
  educ3 = "Demographics",
  marital3 = "Demographics",
  n_size_all_sd = "Psychosocial",
  health_insurance = "Demographics",
  covid = "Demographics",
  smoke_status = "Health",
  multi_morbidity_sd = "Health",
  general_health_sd = "Health",
  matter_depend_binary = "Psychosocial",
  matter_important_binary = "Psychosocial",
  aces_sum_sd = "Psychosocial",
  occ_group = "Occupation"
)

category_levels <- c("Demographics", "Occupation", "Psychosocial", "Health")

prep_labels <- function(dt) {
  dt[, level_label := as.character(level_label)]
  dt[, ref_label := as.character(ref_label)]
  dt[, base_var := fifelse(!is.na(base_var), base_var, term)]
  dt[, var_label := var_labels[base_var]]
  dt[is.na(var_label), var_label := base_var]
  dt[, level := as.character(level)]

  label_lookup <- function(bv, lvl) {
    lab <- value_labels[[bv]]
    if (is.null(lab) || is.na(lvl) || lvl == "") return("")
    if (lvl %in% names(lab)) lab[[lvl]] else ""
  }

  dt[, level_label := fifelse(level_label != "" & !is.na(level_label),
    level_label,
    mapply(label_lookup, base_var, level)
  )]
  # derive reference label per factor from base flag or first level
  ref_map <- dt[
    base_flag == 1 & level != "" & !is.na(level),
    .(ref_level = level[1]),
    by = base_var
  ]
  dt[, ref_by_var := ""]
  dt[ref_map, on = .(base_var), ref_by_var := mapply(label_lookup, base_var, i.ref_level)]
  dt <- dt[!(base_flag == 1 & level != "" & !is.na(level))]
  dt[, contrast_label := fifelse(level_label == "" | is.na(level_label), "", level_label)]
  dt[, label := fifelse(
    contrast_label == "",
    var_label,
    paste0(var_label, ": ", contrast_label,
           fifelse(ref_by_var != "" & !is.na(ref_by_var), paste0(" vs ", ref_by_var), ""))
  )]
  dt[, category := factor(var_categories[base_var], levels = category_levels)]
  dt[, signif := fifelse(p_value < 0.05, "Significant (p < 0.05)", "Not significant")]
  dt[p_value < 0.1 & p_value >= 0.05, signif := 'Significant (p < 0.1)']

  dt[, effect_dir := fifelse(estimate > 0, "Positive", "Negative")]
  dt[, color_label := ifelse(signif == "Significant (p < 0.05)", paste(effect_dir, "sig (p < 0.05)"),
                      ifelse(signif == "Significant (p < 0.1)",  paste(effect_dir, "sig (p < 0.1)"),
                                                                paste(effect_dir, "insig (p >= 0.1)")
                             )
  )]
  dt[, color_label := factor(
    color_label,
    levels = c(
      "Positive sig (p < 0.05)",
      "Negative sig (p < 0.05)",
      "Positive sig (p < 0.1)",
      "Negative sig (p < 0.1)",
      "Positive insig (p >= 0.1)",
      "Negative insig (p >= 0.1)"
    )
  )]
  dt[, panel := factor(panel,
  levels = c("Panel A: Pr(0 hasslers)", "Panel B: Expected count"),
  labels = c("Panel A: Pr(0 hasslers)", "Panel B: Expected count of hasslers"))]
  dt
}

effects <- prep_labels(effects)


order_labels <- function(dt) {
  dt[, term_order := frank(base_var, ties.method = "dense")]
  setorder(dt, panel, category, term_order, contrast_label, label)
  label_levels <- unique(dt$label)
  dt[, label := factor(label, levels = rev(label_levels))]
  dt
}

effects <- order_labels(effects)

plot_me <- function(dt, title_text) {
  ggplot(
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
      )
    ) +
    facet_grid(category ~ panel, scales = "free_y", space = "free_y") +
    scale_color_manual(
      values = c(
        "Positive sig (p < 0.05)" = "#2b8cbe",
        "Negative sig (p < 0.05)" = "#b2182b",
        "Positive sig (p < 0.1)" = "#a6cee3",
        "Negative sig (p < 0.1)" = "#fbb4b9",
        "Positive insig (p >= 0.1)" = "grey50",
        "Negative insig (p >= 0.1)" = "grey50"
      ),
      name = "Direction & significance"
    ) +
    scale_linetype_manual(
      values = c("Significant (p < 0.05)" = "solid", "Significant (p < 0.1)" = "dashed", "Not significant" = "dotted"),
      name = "Significance level"
    ) +
    theme_bw() +
    labs(
      x = "Average marginal effect",
      y = NULL,
      title = NULL
    ) +
    theme(
      legend.position = "none",
      axis.text.y = element_text(color = "black")
    )
}

p_main <- plot_me(effects[model == "multivariate"], "Determinants of hasslers")

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
ggsave(output_file, p_main, width = 10, height = 6, dpi = 1000)
ggsave(gsub('\\.png','\\.pdf',output_file), p_main, width = 10, height = 6)