#!/usr/bin/env Rscript
# Purpose: Visualize survey-weighted network metrics by hassler type.
# Uses pre-computed metrics from 0_clean_network_refactored.r (p2p_egonetwork_alter.rds)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(marginaleffects)
  library(rio)
  library(survey)
})

# =============================================================================
# Path Configuration - Supports both Snakemake and standalone execution
# =============================================================================

if (exists("snakemake")) {
  # Running via Snakemake - use provided paths
  alters_path <- snakemake@input[["alters"]]
  main_data_path <- snakemake@input[["data"]]
  output_file <- snakemake@output[[1]]

} else {
  # Running standalone - check for command line args first
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 3) {
    alters_path <- args[[1]]
    main_data_path <- args[[2]]
    output_file <- args[[3]]
  } else {
    # Load configuration file
    config_path <- file.path(dirname(sys.frame(1)$ofile), "..", "config_paths.R")
    if (!file.exists(config_path)) {
      stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Set script-specific paths using config
    alters_path <- get_processed_path("p2p_egonetwork_alter.rds")
    main_data_path <- get_processed_path("p2p_epigen_0501.rds")
    output_file <- get_output_path("figure_3_network_by_hassler.png")
  }
}

# Load cleaned alter-level data with pre-computed metrics ----------------------
dt_alters <- readRDS(alters_path)
setDT(dt_alters)

dt_main <- readRDS(main_data_path)
setDT(dt_main)
ego_weights <- dt_main[, .(su_id, wt_final2)]

# Prepare metrics for analysis ------------------------------------------------
# Note: 'strength' column was skipped in data cleaning, so use available metrics
metrics <- dt_alters[, .(
  su_id, person, hassler_type, relationship_type,
  hassle_freq, multiplex, strength,
  network_size, degree, degree_weighted, between
)]

metrics <- merge(metrics, ego_weights, by = c("su_id"), all.x = TRUE)
metrics <- metrics[!is.na(hassler_type) & !is.na(wt_final2)]

# Survey-weighted estimates ---------------------------------------------------
svy_design <- svydesign(id = ~su_id, weights = ~wt_final2, data = metrics)

# Use available metrics (strength not available)
outcomes <- c("strength", "degree_weighted", "multiplex")

estimate_dt <- rbindlist(lapply(outcomes, function(outcome) {
  message('Predicting ', outcome)
  model <- svyglm(as.formula(paste(outcome, "~ hassler_type")), design = svy_design)
  pred_dt <- avg_predictions(model, type = "response", variable = "hassler_type",
                             conf.level = 0.95, wts = weights(model))
  setDT(pred_dt)
  pred_dt[, outcome := outcome]
}), fill = TRUE)

estimate_dt_rel <- rbindlist(lapply(outcomes, function(outcome) {
  message('Predicting ', outcome)
  model <- svyglm(as.formula(paste(outcome, "~ relationship_type")), design = svy_design)
  pred_dt <- avg_predictions(model, type = "response", variable = "relationship_type",
                             conf.level = 0.95, wts = weights(model))
  setDT(pred_dt)
  pred_dt[, outcome := outcome]
}), fill = TRUE)

estimate_dt <- rbind(estimate_dt, estimate_dt_rel, fill = TRUE)

# Format labels for plotting --------------------------------------------------
outcome_labels <- c(
  strength = "Tie Strength with Ego",
  degree_weighted = "Alter-level Centrality",
  multiplex = "Multiplexity (count of tie types)"
)
estimate_dt[, outcome_label := factor(outcome, levels = names(outcome_labels), labels = outcome_labels)]

estimate_dt[relationship_type == 'partner/spouse', relationship_type := 'Partner']
estimate_dt[relationship_type == 'kin', relationship_type := 'Kin']
estimate_dt[relationship_type == 'non-kin', relationship_type := 'Non-kin']
estimate_dt[is.na(relationship_type), relationship_type := gsub(" Non-hassler| Hassler", '', hassler_type)]
estimate_dt[, relationship_type := factor(relationship_type, levels = c('Partner', 'Kin', 'Non-kin'))]

estimate_dt[!is.na(hassler_type), hassler := ifelse(grepl("Non-hassler", hassler_type), 'Non-hassler', 'Hassler')]
estimate_dt[is.na(hassler_type), hassler := 'All']
estimate_dt[, hassler := factor(hassler, levels = c('Non-hassler', 'Hassler', 'All'))]

# Create plot -----------------------------------------------------------------
p <- ggplot(
  estimate_dt[hassler != 'All'],
  aes(x = relationship_type, y = estimate, ymin = conf.low, ymax = conf.high, color = hassler)
) +
  geom_pointrange(size = 0.8, alpha = 0.8, position = position_dodge(width = 0.5)) +
  scale_color_manual(values = c("Non-hassler" = "grey", "Hassler" = "red"), name = NULL) +
  facet_wrap(~ outcome_label, scales = 'free_y', nrow = 1) +
  theme_bw() +
  theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x = NULL, y = "Means with 95% Confidence Intervals")

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
ggsave(output_file, p, width = 8, height = 4)
