*------------------------------------------------------------
* Table: Other Health Outcomes (Standardized Units)
*------------------------------------------------------------
version 17
clear all
set more off

*=============================================================================
* Path Configuration - Supports both Snakemake and standalone execution
*=============================================================================

* Get paths from environment variables (when run via Snakemake)
local data_path : env DATA_PATH
local me_csv_path : env ME_CSV_PATH
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
    local me_csv_path "${OUTPUT_DIR}/figure_4_me_other_outcomes_sdunit.csv"
    local ok_path "${OUTPUT_DIR}/figure_4_other_outcomes_sdunit.ok"
}

di as text "Data path: `data_path'"
di as text "ME CSV output: `me_csv_path'"

use "`data_path'", clear

* Create standardized versions of all dependent variables
foreach var in general_health mental_health physical_health anx_severity dep_severity inflammation multi_morbidity waist_to_hip_ratio bmi obese height pace ageaccelgrim2 {
    egen `var'_sd = std(`var')
}

svyset psu [pweight = wt_comb], strata(strata)

local control_var i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all

estimates clear

svy: reg general_health_sd `control_var' c.n_size_hassler
estimates store est1
margins, dydx(n_size_hassler) post
estimates store m1

svy: reg mental_health_sd `control_var' c.n_size_hassler
estimates store est2
margins, dydx(n_size_hassler) post
estimates store m2

svy: reg physical_health_sd `control_var' c.n_size_hassler
estimates store est3
margins, dydx(n_size_hassler) post
estimates store m3

svy: reg anx_severity_sd `control_var' c.n_size_hassler
estimates store est4
margins, dydx(n_size_hassler) post
estimates store m4

svy: reg dep_severity_sd `control_var' c.n_size_hassler
estimates store est5
margins, dydx(n_size_hassler) post
estimates store m5

svy: reg inflammation_sd `control_var' c.n_size_hassler
estimates store est6
margins, dydx(n_size_hassler) post
estimates store m6

svy: reg multi_morbidity_sd `control_var' c.n_size_hassler if n_missing_morbidity == 0
estimates store est7
margins, dydx(n_size_hassler) post
estimates store m7

svy: reg waist_to_hip_ratio_sd `control_var' c.n_size_hassler
estimates store est8
margins, dydx(n_size_hassler) post
estimates store m8

svy: reg bmi_sd `control_var' c.n_size_hassler
estimates store est9
margins, dydx(n_size_hassler) post
estimates store m9

svy: reg height_sd `control_var' c.n_size_hassler
estimates store est10
margins, dydx(n_size_hassler) post
estimates store m10

svy: reg pace_sd `control_var' c.n_size_hassler
estimates store est11
margins, dydx(n_size_hassler) post
estimates store m11

svy: reg ageaccelgrim2_sd `control_var' c.n_size_hassler
estimates store est12
margins, dydx(n_size_hassler) post
estimates store m12

* Export marginal effects with CI and p-values for plotting
tempname memhold
tempfile me_results
postfile `memhold' str50 outcome estimate se conf_low conf_high p_value using `me_results'

local outcomes "general_health mental_health physical_health anx_severity dep_severity inflammation multi_morbidity waist_to_hip_ratio bmi height pace ageaccelgrim2"
local model_num = 1
foreach outcome of local outcomes {
    quietly estimates restore m`model_num'
    local estimate = _b[n_size_hassler]
    local se = _se[n_size_hassler]
    local conf_low = `estimate' - 1.96*`se'
    local conf_high = `estimate' + 1.96*`se'
    local t_stat = `estimate'/`se'
    local p_value = 2*ttail(e(df_r), abs(`t_stat'))
    post `memhold' ("`outcome'") (`estimate') (`se') (`conf_low') (`conf_high') (`p_value')
    local model_num = `model_num' + 1
}

postclose `memhold'
preserve
use `me_results', clear
export delimited using "`me_csv_path'", replace
restore

file open fh using "`ok_path'", write replace
file close fh
