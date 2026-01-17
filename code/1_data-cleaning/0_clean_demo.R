#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# demographic variables
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - interview_date: Interview date
#   - gender_birth: Gender at birth (factor)
#   - race_single: Race/ethnicity (White, Black, Hispanic, Asian, AIAN, Other)
#   - age: Age in years
#   - education: Education level (factor)
#   - marital_status: Marital status (factor)
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
            demo = get_raw_path('demographics.dta'),
            age_fixed = get_rawdata_subdir_path('age', 'p2p_age_estimate.sav')
        ),
        output = list(
            df_demo = get_processed_path('p2p_demo_cleaned.rds')
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

attach_label_to_variable = function(x, na_exclude = TRUE){
		var_lab = attr(x,'labels')
		if (na_exclude) {
			var_lab = var_lab[var_lab %in% c(91, 92, 97, 98) == FALSE]
		}
		if (!is.null(var_lab)) {
			x = factor(x,levels=var_lab,labels=names(var_lab))
		}
		return(x)
}


log_info('# load baseline data')

dt_demo = import(snakemake@input$demo)

log_info('# load age fixed data')
dt_age_fixed = import(snakemake@input$age_fixed)
setDT(dt_age_fixed)
names(dt_age_fixed) = tolower(names(dt_age_fixed))

log_info('# load completes ....')
setDT(dt_demo)
dt_demo[, interview_date := as.character(as.Date(DEMOGRAPHICS_STARTTIME))]

names(dt_demo) = tolower(names(dt_demo))

log_info('# race coding')
race_var = c(grep('race', names(dt_demo), value = TRUE),'ethnicity')

for (var in race_var) {
	message(var, ' ... cat : ' ,paste0(unique(dt_demo[[var]]),collapse=' / '))
	dt_demo[get(var) %in% c(92, 97), (var) := NA]
}

# readjust race variables
dt_demo[, race_single := NULL]

dt_demo[, race_multiple := rowSums(.SD, na.rm = TRUE), .SDcols = c('race_white', 'race_black_afam', 'race_amind', 'race_asian', 'race_nathaw_pacis', 'race_other')]
dt_demo[race_multiple == 0, race_multiple := NA]
dt_demo[, race_multiple := ifelse(race_multiple > 1, 1, 0)]

dt_demo[race_multiple == 0 & race_white == 1, race_single := 'White']
dt_demo[race_multiple == 0 & race_black_afam == 1, race_single := 'Black']
dt_demo[race_multiple == 0 & race_amind == 1, race_single := 'AIAN']
dt_demo[race_multiple == 0 & race_asian == 1, race_single := 'Asian']
dt_demo[race_multiple == 0 & race_nathaw_pacis == 1, race_single := 'Other']
dt_demo[race_multiple == 0 & race_other == 1, race_single := 'Other']
dt_demo[race_multiple == 1, race_single := 'Other']
dt_demo[ethnicity == 1, race_single := 'Hispanic']

dt_demo[, race_single := factor(race_single,
    levels = c('White','Black','Hispanic','Asian','AIAN', 'Other'))]

log_info('# gender coding')
dt_demo[, gender_birth := attach_label_to_variable(gender_birth)]

log_info('# age coding')
dt_demo[,age := year(demographics_starttime)-year(dob_date)]

log_info('# education coding')
dt_demo[, education := attach_label_to_variable(education)]

log_info('# marital_status coding')
dt_demo[, marital_status := attach_label_to_variable(marital_status)]

log_info('# imigration status coding')
dt_demo[, native_born := ifelse(attach_label_to_variable(country_origin) == 'YES', 1, 0)]


log_info('# merge age fixed data')
dt_demo = merge(dt_demo, dt_age_fixed[, c('su_id','eligible_hh_member_age_p2p')], by = 'su_id', all.x = TRUE)

log_info('# fill age')
dt_demo[is.na(age), age := eligible_hh_member_age_p2p]
dt_demo[is.na(age), age := 2019 - 1950]

sel_demo = c('su_id','interview_date',
    'gender_birth','race_single',
    'race_black_afam','race_white','race_asian','ethnicity',
    'age','education','marital_status','native_born')

processed_data = dt_demo[,..sel_demo]

log_info('save data ...')
saveRDS(processed_data, snakemake@output$df_demo)


