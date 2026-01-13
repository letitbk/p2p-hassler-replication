*------------------------------------------------------------
* Table: Heterogeneity by Age Group
*------------------------------------------------------------
version 17
clear all
set more off

*=============================================================================
* Path Configuration - Supports both Snakemake and standalone execution
*=============================================================================

* Get paths from environment variables (when run via Snakemake)
local data_path : env DATA_PATH
local ame_path : env AME_PATH
local est_path : env EST_PATH
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
    local ame_path "${OUTPUT_DIR}/table_s14_heterogeneity_agegroup_ame.csv"
    local est_path "${OUTPUT_DIR}/table_s14_heterogeneity_agegroup_est.csv"
    local ok_path "${OUTPUT_DIR}/table_s14_heterogeneity_agegroup.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

svyset fips [pweight = wt_final2]

* Define age groups aligned with Figure 1 cutpoints, capping age at 85
cap drop age_cap85 age_group
gen age_cap85 = age
replace age_cap85 = 85 if age_cap85 > 85 & age_cap85 < .
egen age_group = cut(age_cap85), at(17 30 40 50 60 70 85) icodes
label define agegrp 0 "18-30" 1 "31-40" 2 "41-50" 3 "51-60" 4 "61-70" 5 "71-85", replace
label values age_group agegrp

tab age_group

local control_var i.batch_int leukocytes_ic i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all

*------------------------------------------------------------
* Interaction models
*------------------------------------------------------------
estimates clear

svy: reg pace `control_var' c.n_size_hassler##i.age_group
estimates store pace_age_inter
margins age_group, dydx(n_size_hassler) post
estimates store pace_age_inter_m

svy: reg ageaccelgrim2 `control_var' c.n_size_hassler##i.age_group
estimates store grimage2_age_inter
margins age_group, dydx(n_size_hassler) post
estimates store grimage2_age_inter_m

local age_margin_models pace_age_inter_m grimage2_age_inter_m
local age_reg_models pace_age_inter grimage2_age_inter
local margin_titles "\"Pace (Inter)\" \"AgeAccel (Inter)\""
local reg_titles "\"Pace (Inter)\" \"AgeAccel (Inter)\""

*------------------------------------------------------------
* Separate regressions by age group
*------------------------------------------------------------
levelsof age_group, local(age_groups)

foreach g of local age_groups {
    quietly svy: reg pace `control_var' c.n_size_hassler if age_group == `g' & age_group < . & n_size_hassler < .
    estimates store pace_age_reg`g'
    quietly margins, dydx(n_size_hassler) post
    estimates store pace_age_m`g'

    quietly svy: reg ageaccelgrim2 `control_var' c.n_size_hassler if age_group == `g' & age_group < . & n_size_hassler < .
    estimates store grimage2_age_reg`g'
    quietly margins, dydx(n_size_hassler) post
    estimates store grimage2_age_m`g'

    local age_margin_models "`age_margin_models' pace_age_m`g' grimage2_age_m`g'"
    local age_reg_models "`age_reg_models' pace_age_reg`g' grimage2_age_reg`g'"

    local lbl: label (age_group) `g'
    if "`lbl'" == "" {
        local lbl "Age Group `g'"
    }
    local margin_titles "`margin_titles' \"Pace: `lbl'\" \"AgeAccel: `lbl'\""
    local reg_titles "`reg_titles' \"Pace (reg): `lbl'\" \"AgeAccel (reg): `lbl'\""
}

esttab `age_margin_models' using "`ame_path'", csv se ///
    mtitle(`margin_titles') ///
    nogap label replace star(+ 0.1 * 0.05 ** 0.01)

esttab `age_reg_models' using "`est_path'", csv se ///
    mtitle(`reg_titles') ///
    nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
