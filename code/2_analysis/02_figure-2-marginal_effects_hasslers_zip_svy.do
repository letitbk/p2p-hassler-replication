* Purpose: Replicate figure_marginal_effects_hasslers.R using survey-weighted
* zero-inflated Poisson (ZIP) with mchange. Exports AMEs to CSV for plotting in R.
* Requires: spost13_ado (for mchange) installed in Stata.

version 17.0
clear all
set more off

*=============================================================================
* Path Configuration - Supports both Snakemake and standalone execution
*=============================================================================

* Get paths from environment variables (when run via Snakemake)
local data_path : env DATA_PATH
local csv_main : env CSV_MAIN
local est_path : env EST_PATH

* If environment variables not set, use config file (standalone mode)
if "`data_path'" == "" {
    capture confirm file "`c(pwd)'/../config_paths.do"
    if _rc {
        di as error "Configuration file not found. Please copy config_paths.do.template to config_paths.do and edit paths."
        exit 601
    }
    do "`c(pwd)'/../config_paths.do"

    local data_path "${PROCESSED_DATA_DIR}/p2p_epigen_regression.dta"
    local csv_main "${OUTPUT_DIR}/figure_2_marginal_effects_hasslers_zip_svy_main.csv"
    local est_path "${OUTPUT_DIR}/table_s4_est_regression_zip_hassler.csv"
}

di as text "Data path: `data_path'"

* ---------------------------------------------------------------------------
* Helper: export margins results to a Stata dataset
* ---------------------------------------------------------------------------
capture program drop _export_margins
program define _export_margins
    syntax , Outcome(string) Save(string) Panel(string) Model(string)

    preserve
    tempfile tmp

    margins, dydx(*) predict(`outcome')

    * capture value label names for factor predictors while original data are in memory
    local vl_race3 : value label race3
    local vl_gender_birth : value label gender_birth
    local vl_educ3 : value label educ3
    local vl_marital3 : value label marital3
    local vl_occ_group : value label occ_group

    matrix M = r(table)'
    local terms : colnames r(table)
    local n = rowsof(M)

    postfile handle str40 term double estimate se tstat p_value conf_low conf_high using `tmp', replace
    forvalues i = 1/`n' {
        local name : word `i' of `terms'
        local est = M[`i', 1]
        local s   = M[`i', 2]
        local t   = M[`i', 3]
        local p   = M[`i', 4]
        local ll  = M[`i', 5]
        local ul  = M[`i', 6]
        post handle ("`name'") (`est') (`s') (`t') (`p') (`ll') (`ul')
    }
    postclose handle

    use `tmp', clear
    gen panel     = "`panel'"
    gen outcome   = "`outcome'"
    gen model     = "`model'"

    * Parse factor indicators (e.g., 2.race3) to get base variable and level
    gen base_var = term
    gen level = ""
    gen level_num = .
    quietly replace base_var = substr(term, strpos(term, ".") + 1, .) if strpos(term, ".") > 0
    quietly replace level    = substr(term, 1, strpos(term, ".") - 1) if strpos(term, ".") > 0
    quietly replace level    = subinstr(level, "b", "", .) if strpos(level, "b") > 0
    destring level, replace force
    gen level_label = ""
    gen ref_label = ""
    gen base_flag = 0
    quietly replace base_flag = 1 if strpos(term, "b.") > 0
    order term base_var level level_label ref_label base_flag level_num

    save "`save'", replace
    restore
end

* ---------------------------------------------------------------------------
* Load and prep data
* ---------------------------------------------------------------------------
use "`data_path'", clear

* reverse scale general health
replace general_health = 4 - general_health

* Standardize continuous predictors (mean-center, per SD)
local sd_vars age n_size_all general_health multi_morbidity aces_sum matter_depend matter_important

foreach v of local sd_vars {
    quietly summarize `v'
    gen `v'_sd = (`v' - r(mean)) / r(sd)
}

* Factor variable bases (matches R choices)
* Make unemployed reference if present
capture fvset base 9 occ_group

* Predictor lists
local cont age_sd n_size_all_sd general_health_sd multi_morbidity_sd aces_sum_sd
local bin  health_insurance covid matter_depend_binary matter_important_binary
local predictors `cont' `bin' b3.educ3 i.race3 i.gender_birth i.marital3 i.occ_group i.smoke_status

* Survey design
svyset fips [pweight = wt_final2]

* ---------------------------------------------------------------------------
* Multivariate ZIP model
* ---------------------------------------------------------------------------
estimates clear
svy: zip n_size_hassler `predictors' , inflate(`predictors' _cons)
estimates store zip_hassler

tempfile main_zero main_count
_export_margins, outcome(pr(0)) save(`main_zero') panel("Panel A: Pr(0 hasslers)") model("multivariate")
_export_margins, outcome(n)     save(`main_count') panel("Panel B: Expected count") model("multivariate")

preserve
    use `main_zero', clear
    append using `main_count'
    capture mkdir "`out_dir_main'"
    export delimited using "`csv_main'", replace
restore

estimates restore zip_hassler
margins, dydx(*) predict(pr(0)) post
estimates store ame_hassler_pr0

estimates restore zip_hassler
margins, dydx(*) predict(n) post
estimates store ame_hassler_n


esttab * using "`est_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)
