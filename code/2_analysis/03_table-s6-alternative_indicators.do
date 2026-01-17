*------------------------------------------------------------
* Table: Alternative Indicators of Hasslers
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
    local ame_path "${OUTPUT_DIR}/table_s6_alternative_indicators_ame.csv"
    local est_path "${OUTPUT_DIR}/table_s6_alternative_indicators_est.csv"
    local ok_path "${OUTPUT_DIR}/table_s6_alternative_indicators.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear


svyset psu [pweight = wt_comb], strata(strata)

local control_var i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all

estimates clear

svy: reg pace `control_var' c.p_hassler
estimates store pace_est1
margins, dydx(p_hassler) post
estimates store pace_m1

* add p_hassler_cat
svy: reg pace `control_var' i.p_hassler_cat
estimates store pace_est2
margins, dydx(p_hassler_cat) post
estimates store pace_m2

svy: reg pace `control_var' mean_hassler_freq
estimates store pace_est3
margins, dydx(mean_hassler_freq) post
estimates store pace_m3

svy: reg ageaccelgrim2 `control_var' c.p_hassler
estimates store grimage2_est1
margins, dydx(p_hassler) post
estimates store grimage2_m1

* add p_hassler_cat
svy: reg ageaccelgrim2 `control_var' i.p_hassler_cat
estimates store grimage2_est2
margins, dydx(p_hassler_cat) post
estimates store grimage2_m2

svy: reg ageaccelgrim2 `control_var' mean_hassler_freq if ~missing(n_size_hassler)
estimates store grimage2_est3
margins, dydx(mean_hassler_freq) post
estimates store grimage2_m3

esttab *_m* using "`ame_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)
esttab *_est* using "`est_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
