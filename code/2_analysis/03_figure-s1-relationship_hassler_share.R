#!/usr/bin/env Rscript
# Purpose: Plot the share of hasslers across relationship categories.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(ggsci)
  library(rio)
  library(cowplot)
})

# =============================================================================
# Path Configuration - Supports both Snakemake and standalone execution
# =============================================================================

if (exists("snakemake")) {
  # Running via Snakemake - use provided paths
  alters_path <- snakemake@input[["alters"]]
  output_share <- snakemake@output[["rel_share"]]

} else {
  # Running standalone - check for command line args first
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) >= 2) {
    alters_path <- args[[1]]
    output_share <- args[[2]]
  } else {
    # Load configuration file
    config_path <- file.path(dirname(sys.frame(1)$ofile), "..", "config_paths.R")
    if (!file.exists(config_path)) {
      stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Set script-specific paths using config
    alters_path <- get_raw_path("egocentric_networks.dta")
    output_share <- get_output_path("figure_s1_relationship_hassler_share.png")
  }
}

dt <- import(alters_path)
setDT(dt)
setnames(dt, tolower(names(dt)))

dt[hassle_freq > 90, hassle_freq := NA]
dt[strength > 90, strength := NA]
dt[hassle_freq %in% c(0, 1, 2), hassler := 0]
dt[hassle_freq %in% c(3), hassler := 1]

rel_partner <- paste0("relationship_", c("spouse", "partner"))
rel_kin <- paste0(
  "relationship_",
  c("parent", "sibling", "child", "grandparent", "grandchild", "relative")
)
rel_nonkin <- paste0(
  "relationship_",
  c("friend", "coworker", "neighbor", "roommate", "churchmember", "healthprov", "other")
)
rel_vars <- c(rel_partner, rel_kin, rel_nonkin)

rel_summary <- rbindlist(lapply(rel_vars, function(var) {
  ties_per_ego <- dt[get(var) %in% c(0, 1), .(cnt = sum(get(var), na.rm = TRUE)), by = su_id]
  mean_count <- mean(ties_per_ego$cnt, na.rm = TRUE)
  hassler_pct <- dt[get(var) == 1, mean(hassler, na.rm = TRUE)]
  hassler_counts <- dt[, .(cnt = sum(get(var) == 1 & hassler == 1, na.rm = TRUE)), by = su_id]
  mean_hassler <- mean(hassler_counts$cnt, na.rm = TRUE)
  total_hasslers <- dt[get(var) == 1, sum(hassler, na.rm = TRUE)]
  data.table(
    relationship = gsub("relationship_", "", var),
    mean_count = mean_count,
    hassler_pct = hassler_pct,
    mean_hassler = mean_hassler,
    total_hasslers = total_hasslers
  )
}), fill = TRUE)

rel_summary[
  relationship %in% c("spouse", "partner"),
  relationship_type := "partner"
]
rel_summary[
  relationship %in% c("parent", "sibling", "child", "grandparent", "grandchild", "relative"),
  relationship_type := "kin"
]
rel_summary[
  relationship %in% c("friend", "coworker", "neighbor", "roommate", "churchmember", "healthprov", "other"),
  relationship_type := "nonkin"
]

desired_order <- rev(c(
  "partner", "spouse",
  "child", "parent", "grandparent", "sibling", "relative", "grandchild",
  "other", "roommate", "coworker", "friend", "neighbor", "churchmember", "healthprov"
))
rel_summary[, relationship := factor(relationship, levels = desired_order)]
rel_summary[, relationship_type := factor(relationship_type, levels = c("partner", "kin", "nonkin"))]

rel_summary[, hassler_pct_pct := hassler_pct * 100]

mean_plot <- ggplot(
  rel_summary,
  aes(x = mean_count, y = relationship)
) +
  geom_col(fill = "grey30", alpha = 0.9) +
  geom_text(
    aes(label = sprintf("%.1f", mean_count)),
    hjust = 1.1,
    color = "black",
    size = 3
  ) +
  scale_x_reverse(
    labels = function(x) abs(x)
  ) +
  scale_y_discrete(position = "right") +
  labs(
    x = "Mean number of alters",
    y = NULL
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.title.y = element_blank(),
    axis.text.y = element_text(hjust = 1)
  ) +
  facet_grid(relationship_type ~ ., scales = "free_y", space = "free_y")

share_plot <- ggplot(
  rel_summary,
  aes(x = hassler_pct_pct, y = relationship)
) +
  geom_col(fill = "#e41a1c", alpha = 0.9) +
  geom_text(
    aes(label = sprintf("%.1f%%", hassler_pct_pct)),
    hjust = -0.1,
    color = "#e41a1c",
    size = 3
  ) +
  scale_x_continuous(
    labels = function(x) sprintf("%.0f%%", x),
    expand = expansion(mult = c(0, 0.2))
  ) +
  labs(
    x = "Hassler share (% of alters)",
    y = NULL
  ) +
  theme_bw() +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.title.y = element_blank(),
    strip.text.y = element_blank(),
    strip.background = element_blank()
  ) +
  facet_grid(relationship_type ~ ., scales = "free_y", space = "free_y")

combined_plot <- plot_grid(
  mean_plot,
  share_plot,
  ncol = 2,
  align = "v",
  axis = "tb",
  rel_widths = c(1, 1)
)

dir.create(dirname(output_share), recursive = TRUE, showWarnings = FALSE)
ggsave(output_share, combined_plot, width = 7, height = 4)

