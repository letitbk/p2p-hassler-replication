*------------------------------------------------------------
* Table 1 analysis for Hassler regression summary statistics
*------------------------------------------------------------
version 17
clear all
set more off

*=============================================================================
* Path Configuration - Supports both Snakemake and standalone execution
*=============================================================================

* Get paths from environment variables (when run via Snakemake)
local data_path : env DATA_PATH
local table_path : env TABLE_PATH
local ok_path : env OK_PATH

* If environment variables not set, use config file (standalone mode)
if "`data_path'" == "" {
    * Check if config file exists
    capture confirm file "`c(pwd)'/../config_paths.do"
    if _rc {
        di as error "Configuration file not found."
        di as error "Please copy config_paths.do.template to config_paths.do and edit paths."
        exit 601
    }

    * Load shared configuration
    do "`c(pwd)'/../config_paths.do"

    * Set script-specific paths using config globals
    local data_path "${PROCESSED_DATA_DIR}/p2p_epigen_regression.dta"
    local table_path "${OUTPUT_DIR}/table_s1_summary.csv"
    local ok_path "${OUTPUT_DIR}/table_s1_summary.ok"
}

* Display paths for verification
di as text "Data path: `data_path'"
di as text "Output table: `table_path'"
di as text "OK file: `ok_path'"

use "`data_path'", clear

svyset psu [pweight = wt_comb], strata(strata)

tab occ_group, gen(occ_group_)
gen i_sp_hassler = sp_n_size_hassler > 0 if ~missing(sp_n_size_hassler)
gen i_k_hassler = k_n_size_hassler > 0 if ~missing(k_n_size_hassler)
gen i_nk_hassler = nk_n_size_hassler > 0 if ~missing(nk_n_size_hassler)

eststo clear
local summary_vars ///
    age female race3_* educ3_* marital3_* occ_group_* smoke_status_* ///
    leukocytes_ic batch_int_* ///
    covid health_insurance aces_sum matter_important_binary matter_depend_binary ///
    n_size_all n_size_hassler p_hassler mean_hassler_freq ///
    sp_n_size_hassler k_n_size_hassler nk_n_size_hassler ///
    i_sp_hassler i_k_hassler i_nk_hassler ///
    ageaccelgrim2 pace general_health mental_health physical_health ///
    inflammation cci_charlson_past3years any_encounter_3years ///
    multi_morbidity anx_severity dep_severity waist_to_hip_ratio bmi obese height
eststo: estpost summarize `summary_vars' [aw = wt_comb] if analytic_sample == 1

esttab using "`table_path'", csv ///
    cells("count mean sd min max") ///
    nomtitle nonumber replace

file open fh using "`ok_path'", write replace
file close fh

svy: mean ageaccelgrim2 pace if analytic_sample == 1