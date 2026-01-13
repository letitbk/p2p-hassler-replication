*------------------------------------------------------------
* Table: Main Effects of Hasslers
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
    local ame_path "${OUTPUT_DIR}/table_1_main_effects_ame.csv"
    local est_path "${OUTPUT_DIR}/table_s5_main_effects_est.csv"
    local ok_path "${OUTPUT_DIR}/table_1_s4_main_effects.ok"
}

di as text "Data path: `data_path'"
di as text "AME output: `ame_path'"
di as text "EST output: `est_path'"

use "`data_path'", clear

svyset fips [pweight = wt_final2]

local control_var i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all


estimates clear

* Only use n_size_hassler (has_hassler and n_size_hassler_cat don't exist in dataset)
svy: reg pace `control_var' c.n_size_hassler if ~missing(n_size_hassler)
estimates store pace_est1
margins, dydx(n_size_hassler) post
estimates store pace_m1

svy: reg pace `control_var' has_hassler if ~missing(has_hassler)
estimates store pace_est2
margins, dydx(has_hassler) post
estimates store pace_m2

svy: reg pace `control_var' i.n_size_hassler_cat if ~missing(n_size_hassler_cat)
estimates store pace_est3
margins, dydx(n_size_hassler_cat) post
estimates store pace_m3


svy: reg ageaccelgrim2 `control_var' c.n_size_hassler if ~missing(n_size_hassler)
estimates store grimage2_est1
margins, dydx(n_size_hassler) post
estimates store grimage2_m1

svy: reg ageaccelgrim2 `control_var' has_hassler if ~missing(has_hassler)
estimates store grimage2_est2
margins, dydx(has_hassler) post
estimates store grimage2_m2

svy: reg ageaccelgrim2 `control_var' i.n_size_hassler_cat if ~missing(n_size_hassler_cat)
estimates store grimage2_est3
margins, dydx(n_size_hassler_cat) post
estimates store grimage2_m3

esttab *_m* using "`ame_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)
esttab *_est* using "`est_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
