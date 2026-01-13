*------------------------------------------------------------
* Table: Robustness Checks
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
    local ame_path "${OUTPUT_DIR}/table_3_main_robustness_ame.csv"
    local ok_path "${OUTPUT_DIR}/table_3_main_robustness.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

capture confirm variable aces_sum_std
if _rc {
    egen aces_sum_std = std(aces_sum)
}

capture confirm variable n_size_hassler_1
if _rc {
    gen n_size_hassler_1 = n_size_hassler
    recode n_size_hassler_1 (1/max = 1)
}

svyset fips [pweight = wt_final2]

local control_var i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all

estimates clear

svy: reg pace `control_var' n_size_hassler
margins, dydx(n_size_hassler) post
estimates store pace_m1

svy: reg pace `control_var' n_size_hassler  covid health_insurance
margins, dydx(n_size_hassler) post
estimates store pace_m2

svy: reg pace `control_var' n_size_hassler  cci_charlson_past3years any_encounter_3years
margins, dydx(n_size_hassler) post
estimates store pace_m3

svy: reg pace `control_var' n_size_hassler  multi_morbidity
margins, dydx(n_size_hassler) post
estimates store pace_m4

svy: reg pace `control_var' n_size_hassler  matter_important matter_depend
margins, dydx(n_size_hassler) post
estimates store pace_m5

svy: reg pace `control_var' n_size_hassler  i.occ_group
margins, dydx(n_size_hassler) post
estimates store pace_m6

svy: reg pace `control_var' n_size_hassler  i.smoke_status
margins, dydx(n_size_hassler) post
estimates store pace_m7

svy: reg pace `control_var' n_size_hassler  c.aces_sum_std
margins, dydx(n_size_hassler) post
estimates store pace_m8

svy: reg ageaccelgrim2 `control_var' n_size_hassler
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m1

svy: reg ageaccelgrim2 `control_var' n_size_hassler  covid health_insurance
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m2

svy: reg ageaccelgrim2 `control_var' n_size_hassler  cci_charlson_past3years any_encounter_3years
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m3

svy: reg ageaccelgrim2 `control_var' n_size_hassler  multi_morbidity
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m4

svy: reg ageaccelgrim2 `control_var' n_size_hassler  matter_depend matter_important
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m5

svy: reg ageaccelgrim2 `control_var' n_size_hassler  i.occ_group
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m6

svy: reg ageaccelgrim2 `control_var' n_size_hassler  i.smoke_status
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m7

svy: reg ageaccelgrim2 `control_var' n_size_hassler  c.aces_sum_std
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m8

esttab * using "`ame_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
