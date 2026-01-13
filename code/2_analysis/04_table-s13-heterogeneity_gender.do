*------------------------------------------------------------
* Table: Heterogeneity by Gender
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
    local ame_path "${OUTPUT_DIR}/table_s12_heterogeneity_gender_ame.csv"
    local est_path "${OUTPUT_DIR}/table_s12_heterogeneity_gender_est.csv"
    local ok_path "${OUTPUT_DIR}/table_s12_heterogeneity_gender.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

svyset fips [pweight = wt_final2]

tab gender_birth

local control_var i.batch_int leukocytes_ic age i.race3 i.educ3 i.marital3 i.n_size_all

*------------------------------------------------------------
* Interaction models
*------------------------------------------------------------
estimates clear

svy: reg pace `control_var' c.n_size_hassler##i.gender_birth
estimates store pace_gender_inter
margins gender_birth, dydx(n_size_hassler) post
estimates store pace_gender_inter_m

svy: reg ageaccelgrim2 `control_var' c.n_size_hassler##i.gender_birth
estimates store grimage2_gender_inter
margins gender_birth, dydx(n_size_hassler) post
estimates store grimage2_gender_inter_m

*------------------------------------------------------------
* Separate regressions by gender
*------------------------------------------------------------
forvalues i = 1/2 {
    quietly svy: reg pace `control_var' c.n_size_hassler if gender_birth == `i' & gender_birth < . & n_size_hassler < .
    estimates store pace_gender_reg`i'
    quietly margins, dydx(n_size_hassler) post
    estimates store pace_gender_m`i'
}

forvalues i = 1/2 {
    quietly svy: reg ageaccelgrim2 `control_var' c.n_size_hassler if gender_birth == `i' & gender_birth < . & n_size_hassler < .
    estimates store grimage2_gender_reg`i'
    quietly margins, dydx(n_size_hassler) post
    estimates store grimage2_gender_m`i'
}

local gender_margin_models pace_gender_inter_m grimage2_gender_inter_m pace_gender_m1 pace_gender_m2 grimage2_gender_m1 grimage2_gender_m2
local gender_reg_models pace_gender_inter grimage2_gender_inter pace_gender_reg1 pace_gender_reg2 grimage2_gender_reg1 grimage2_gender_reg2

esttab `gender_margin_models' using "`ame_path'", csv se ///
    mtitle("Pace (Inter)" "AgeAccel (Inter)" "Pace: Gender 1" "Pace: Gender 2" ///
           "AgeAccel: Gender 1" "AgeAccel: Gender 2") ///
    nogap label replace star(+ 0.1 * 0.05 ** 0.01)

esttab `gender_reg_models' using "`est_path'", csv se ///
    mtitle("Pace (Inter)" "AgeAccel (Inter)" "Pace (reg): Gender 1" "Pace (reg): Gender 2" ///
           "AgeAccel (reg): Gender 1" "AgeAccel (reg): Gender 2") ///
    nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
