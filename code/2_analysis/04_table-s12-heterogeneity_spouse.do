*------------------------------------------------------------
* Table: Heterogeneity by Marital Status and Partner Ties
*------------------------------------------------------------
version 17
clear all
set more off

*=============================================================================
* Path Configuration - Supports both Snakemake and standalone execution
*=============================================================================

* Get paths from environment variables (when run via Snakemake)
local data_path : env DATA_PATH
local ame_marital_path : env AME_MARITAL_PATH
local est_marital_path : env EST_MARITAL_PATH
local ame_partner_path : env AME_PARTNER_PATH
local est_partner_path : env EST_PARTNER_PATH
local ok_path : env OK_PATH

* If environment variables not set, use config file (standalone mode)
if "`data_path'" == "" {
    capture confirm file "`c(pwd)'/../config_paths.do"
    if _rc {
        di as error "Configuration file not found. Please copy config_paths.do.template to config_paths.do and edit paths."
        exit 601
    }
    do "`c(pwd)'/../config_paths.do"

    local data_path "${PROCESSED_DATA_DIR}/p2p_epigen_regression.dta"
    local ame_marital_path "${OUTPUT_DIR}/table_s11_heterogeneity_spouse_marital_ame.csv"
    local est_marital_path "${OUTPUT_DIR}/table_s11_heterogeneity_spouse_marital_est.csv"
    local ame_partner_path "${OUTPUT_DIR}/table_s11_heterogeneity_spouse_tie_ame.csv"
    local est_partner_path "${OUTPUT_DIR}/table_s11_heterogeneity_spouse_tie_est.csv"
    local ok_path "${OUTPUT_DIR}/table_s11_heterogeneity_spouse.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

svyset fips [pweight = wt_final2]

local control_marital i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.n_size_all

cap drop has_spouse_tie
gen byte has_spouse_tie = (sp_n_size_all > 0) if ~missing(sp_n_size_all)
replace has_spouse_tie = 0 if missing(has_spouse_tie) & n_size_all == 0
label define has_spouse_lbl 0 "No Spouse Tie" 1 "Spouse Tie", replace
label values has_spouse_tie has_spouse_lbl

estimates clear

svy: reg pace `control_marital' c.n_size_hassler##i.marital3
estimates store pace_mar_est
margins marital3, dydx(n_size_hassler) post
estimates store pace_mar_m

svy: reg pace `control_marital' c.n_size_hassler##i.marital3 if covid == 1
estimates store pace_mar_est_c
margins marital3, dydx(n_size_hassler) post
estimates store pace_mar_m_c

svy: reg pace `control_marital' c.n_size_hassler##i.marital3 if covid == 0
estimates store pace_mar_est_nc
margins marital3, dydx(n_size_hassler) post
estimates store pace_mar_m_nc


svy: reg ageaccelgrim2 `control_marital' c.n_size_hassler##i.marital3
estimates store ageacc_mar_est
margins marital3, dydx(n_size_hassler) post
estimates store ageacc_mar_m

svy: reg ageaccelgrim2 `control_marital' c.n_size_hassler##i.marital3 if covid == 1
estimates store ageacc_mar_est_c
margins marital3, dydx(n_size_hassler) post
estimates store ageacc_mar_m_c

svy: reg ageaccelgrim2 `control_marital' c.n_size_hassler##i.marital3 if covid == 0
estimates store ageacc_mar_est_nc
margins marital3, dydx(n_size_hassler) post
estimates store ageacc_mar_m_nc

local marital_margin_models pace_mar_m pace_mar_m_c pace_mar_m_nc ageacc_mar_m ageacc_mar_m_c ageacc_mar_m_nc
local marital_reg_models pace_mar_est pace_mar_est_c pace_mar_est_nc ageacc_mar_est ageacc_mar_est_c ageacc_mar_est_nc

esttab `marital_margin_models' using "`ame_marital_path'", csv se ///
    mtitle("Pace (Inter)" "Pace: COVID" "Pace: Non-COVID" ///
           "AgeAccel (Inter)" "AgeAccel: COVID" "AgeAccel: Non-COVID") ///
    nogap label replace star(+ 0.1 * 0.05 ** 0.01)

esttab `marital_reg_models' using "`est_marital_path'", csv se ///
    mtitle("Pace (Inter)" "Pace (reg): COVID" "Pace (reg): Non-COVID" ///
           "AgeAccel (Inter)" "AgeAccel (reg): COVID" "AgeAccel (reg): Non-COVID") ///
    nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
