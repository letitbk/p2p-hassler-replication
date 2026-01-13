*------------------------------------------------------------
* Table: Heterogeneity by Tie Types
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
    local ame_path "${OUTPUT_DIR}/table_2_tie_types_ame.csv"
    local ok_path "${OUTPUT_DIR}/table_2_tie_types.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

svyset fips [pweight = wt_final2]

local control_var i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all

estimates clear

gen i_sp_hassler = sp_n_size_hassler > 0 if ~missing(sp_n_size_hassler)
gen i_k_hassler = k_n_size_hassler > 0 if ~missing(k_n_size_hassler)
gen i_nk_hassler = nk_n_size_hassler > 0 if ~missing(nk_n_size_hassler)

* Standardize hassler counts by relationship type
egen std_sp_n_size_hassler = std(sp_n_size_hassler)
egen std_k_n_size_hassler = std(k_n_size_hassler)
egen std_nk_n_size_hassler = std(nk_n_size_hassler)


svy: reg pace `control_var' i_sp_hassler i_k_hassler i_nk_hassler
margins, dydx(i_sp_hassler i_k_hassler i_nk_hassler) post
estimates store pace_m1

svy: reg pace `control_var' std_sp_n_size_hassler std_k_n_size_hassler std_nk_n_size_hassler
margins, dydx(std_sp_n_size_hassler std_k_n_size_hassler std_nk_n_size_hassler) post
estimates store pace_m2


svy: reg ageaccelgrim2 `control_var' i_sp_hassler i_k_hassler i_nk_hassler
margins, dydx(i_sp_hassler i_k_hassler i_nk_hassler) post
estimates store grimage2_m1


svy: reg ageaccelgrim2 `control_var' std_sp_n_size_hassler std_k_n_size_hassler std_nk_n_size_hassler
margins, dydx(std_sp_n_size_hassler std_k_n_size_hassler std_nk_n_size_hassler) post
estimates store grimage2_m2


esttab * using "`ame_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
