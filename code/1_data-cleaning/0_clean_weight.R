#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# survey weight variables
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - wt_comb: Combined survey weight for pooled Main+Opioid sample analysis
#   - strata: Stratification variable (2 strata)
#   - psu: Primary sampling unit for cluster sampling (63 clusters)
#' ==============

#' =============================================================================
#' Path Configuration - Supports both Snakemake and standalone execution
#' =============================================================================

if (!exists("snakemake")) {
    # Standalone mode - load configuration file
    config_path <- paste0("../", "config_paths.R")
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
            weight = get_rawdata_subdir_path('weight', 'P2P_panel_weights.dta'),
            df_clock = get_processed_path('p2p_clock.rds'),
            df_demo = get_processed_path('p2p_demo_cleaned.rds')
        ),
        output = list(
            df_weight = get_processed_path('p2p_weight.rds')
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
library(survey)

log_info('Load weight data ...')
dt_weight = import(snakemake@input$weight)
setDT(dt_weight)

dt_wt = dt_weight[, c('su_id', 'wt_comb', 'strata', 'psu')]

log_info('# add weight adjustment for the sample selection')

dt_clock = readRDS(snakemake@input$df_clock)

# select the one file
dt_clock = unique(dt_clock, by = 'su_id')

log_info('# load demographic data')
dt_demo = readRDS(snakemake@input$df_demo)

log_info('# combine multiple data sets ')

dt_merged = merge(dt_demo, dt_clock, by ='su_id', all= TRUE)
dt_merged = merge(dt_merged, dt_wt, by = 'su_id', all = TRUE)
dt_merged[, in_epigen := ifelse(is.na(batch_int), 0, 1)]

dt_merged[, age_group := cut(age, breaks = c(0, 30, 40, 50, 60, 70, 80, 90, 110), include.lowest = TRUE)]

log_info('# create weights')

xx = c('race_single','gender_birth','age','age_group', 'education')
yy = 'in_epigen'
weight = 'wt_comb'

adata = dt_merged[,
	c('su_id', xx,yy,weight),with=FALSE]

#adata[, age := as.factor(age)]

adata = na.omit(adata)

for (var in xx){
	if (is.factor(adata[[var]])){
	adata[[var]] = factor(adata[[var]],
		levels=levels(adata[[var]])[levels(adata[[var]]) %in% c("REFUSED","DON'T KNOW")==FALSE])
	}
}

sdata= svydesign(
	id = ~1,
	weights = as.formula(paste0('~', weight)),
	data = adata[!is.na(get(weight)),],
	)

fit_model1 = as.formula(paste0(yy, '~',
	paste0(c(xx), collapse='+')
	))

fit = svyglm(formula=fit_model1, design=sdata, family=quasibinomial(link='logit'))

adata$participation_pred = c(predict(fit,
	type = 'response',
	newdata = adata))

adata[, wt_comb_part := wt_comb * 1 / participation_pred]

#dt_wt = merge(dt_wt, adata[, c('su_id', 'wt_final2_part')], by ='su_id', all = TRUE)

saveRDS(dt_wt, snakemake@output$df_weight)

