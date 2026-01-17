*------------------------------------------------------------
* Table: Other Health Outcomes
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
    local ame_path "${OUTPUT_DIR}/table_s7_other_outcomes_ame.csv"
    local est_path "${OUTPUT_DIR}/table_s8-s9_other_outcomes_est.csv"
    local ok_path "${OUTPUT_DIR}/table_s7-s9_other_outcomes.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

svyset psu [pweight = wt_comb], strata(strata)

local control_var i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all

estimates clear

svy: reg general_health `control_var' c.n_size_hassler
estimates store est1
margins, dydx(n_size_hassler) post
estimates store m1

svy: reg mental_health `control_var' c.n_size_hassler
estimates store est2
margins, dydx(n_size_hassler) post
estimates store m2

svy: reg physical_health `control_var' c.n_size_hassler
estimates store est3
margins, dydx(n_size_hassler) post
estimates store m3

svy: reg anx_severity `control_var' c.n_size_hassler
estimates store est4
margins, dydx(n_size_hassler) post
estimates store m4

svy: reg dep_severity `control_var' c.n_size_hassler
estimates store est5
margins, dydx(n_size_hassler) post
estimates store m5

svy: reg inflammation `control_var' c.n_size_hassler
estimates store est6
margins, dydx(n_size_hassler) post
estimates store m6

svy: reg multi_morbidity `control_var' c.n_size_hassler if n_missing_morbidity == 0
estimates store est7
margins, dydx(n_size_hassler) post
estimates store m7

svy: reg waist_to_hip_ratio `control_var' c.n_size_hassler
estimates store est8
margins, dydx(n_size_hassler) post
estimates store m8

svy: reg bmi `control_var' c.n_size_hassler
estimates store est9
margins, dydx(n_size_hassler) post
estimates store m9

svy: reg height `control_var' c.n_size_hassler
estimates store est10
margins, dydx(n_size_hassler) post
estimates store m10

esttab m* using "`ame_path'", csv se mtitle(general_health mental_health physical_health anx_severity dep_severity inflammation multi_morbidity waist_to_hip_ratio bmi height) nogap label replace star(+ 0.1 * 0.05 ** 0.01)
esttab est* using "`est_path'", csv se mtitle(general_health mental_health physical_health anx_severity dep_severity inflammation multi_morbidity waist_to_hip_ratio bmi height) nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
