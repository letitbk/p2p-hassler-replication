*------------------------------------------------------------
* Konfound sensitivity analysis for number of hasslers
*------------------------------------------------------------
version 17
clear all
set more off

*=============================================================================
* Path Configuration - Supports both Snakemake and standalone execution
*=============================================================================

* Get paths from environment variables (when run via Snakemake)
local data_path : env DATA_PATH
local csv_path : env CSV_PATH
local cov_path : env COV_PATH
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
    local csv_path "${OUTPUT_DIR}/table_s13_konfound_n_size_hassler.csv"
    local cov_path "${OUTPUT_DIR}/table_s13_konfound_n_size_hassler_impacts.csv"
    local ok_path "${OUTPUT_DIR}/table_s13_konfound_n_size_hassler.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

svyset psu [pweight = wt_comb], strata(strata)

capture confirm variable race3_1
if _rc {
    tab race3, gen(race3_)
}

capture confirm variable educ3_1
if _rc {
    tab educ3, gen(educ3_)
}

capture confirm variable marital3_1
if _rc {
    tab marital3, gen(marital3_)
}

capture confirm variable batch_int_1
if _rc {
    tab batch_int, gen(batch_int_)
}

capture confirm variable female
if _rc {
    gen female = (gender_birth == 2) if ~missing(gender_birth)
}

local control_var batch_int_2-batch_int_7 leukocytes_ic age race3_2 race3_3 female educ3_2 educ3_3 marital3_2 marital3_3
unab covariate_list : `control_var'

capture frame drop summary
frame create summary str20 outcome str20 exposure str6 metric ///
    double impact_threshold double unconditional_impact double rir_cases ///
    double threshold_effect double rsq double rsq_yz double rsq_xz ///
    double corr_y_ov double corr_x_ov
frame summary: set obs 0

capture frame drop impacts
frame create impacts str20 outcome str20 exposure str8 table_type str20 covariate ///
    double corr_vx double corr_vy double impact
frame impacts: set obs 0

program define add_summary
    syntax , outcome(string) exposure(string) metric(string) ///
        impact(real) uncond(real) rir(real) threshold(real) ///
        rsq(real) rsqyz(real) rsqxz(real) corry(real) corrx(real)
    frame summary {
        local newobs = _N + 1
        quietly set obs `newobs'
        replace outcome = "`outcome'" in `newobs'
        replace exposure = "`exposure'" in `newobs'
        replace metric = "`metric'" in `newobs'
        replace impact_threshold = `impact' in `newobs'
        replace unconditional_impact = `uncond' in `newobs'
        replace rir_cases = `rir' in `newobs'
        replace threshold_effect = `threshold' in `newobs'
        replace rsq = `rsq' in `newobs'
        replace rsq_yz = `rsqyz' in `newobs'
        replace rsq_xz = `rsqxz' in `newobs'
        replace corr_y_ov = `corry' in `newobs'
        replace corr_x_ov = `corrx' in `newobs'
    }
end

program define add_impact_row
    syntax , outcome(string) exposure(string) type(string) covariate(string) ///
        corrvx(real) corrvy(real) impact(real)
    frame impacts {
        local newobs = _N + 1
        quietly set obs `newobs'
        replace outcome = "`outcome'" in `newobs'
        replace exposure = "`exposure'" in `newobs'
        replace table_type = "`type'" in `newobs'
        replace covariate = "`covariate'" in `newobs'
        replace corr_vx = `corrvx' in `newobs'
        replace corr_vy = `corrvy' in `newobs'
        replace impact = `impact' in `newobs'
    }
end

* Pace outcome
tempvar sample_pace
svy: reg pace `control_var' c.n_size_hassler if ~missing(n_size_hassler)
gen byte `sample_pace' = e(sample)
estimates store pace_reg

estimates restore pace_reg
konfound n_size_hassler, indx("IT")
local pace_it = r(itcv)
local pace_uncon = r(unconitcv)
local pace_thr = r(thr)
local pace_rsq = r(Rsq)
local pace_rsqyz = r(RsqYZ)
local pace_rsqxz = r(RsqXZ)
local pace_rycv = r(r_ycv)
local pace_rxcv = r(r_xcv)
add_summary, outcome("pace") exposure("n_size_hassler") metric("IT") ///
    impact(`pace_it') uncond(`pace_uncon') rir(.) threshold(`pace_thr') ///
    rsq(`pace_rsq') rsqyz(`pace_rsqyz') rsqxz(`pace_rsqxz') ///
    corry(`pace_rycv') corrx(`pace_rxcv')

estimates restore pace_reg
konfound n_size_hassler, indx("RIR")
local pace_rir = r(rir)
local pace_thr_rir = r(thr)
local pace_rsq_rir = r(Rsq)
local pace_rsqyz_rir = r(RsqYZ)
local pace_rsqxz_rir = r(RsqXZ)
local pace_rycv_rir = r(r_ycv)
local pace_rxcv_rir = r(r_xcv)
add_summary, outcome("pace") exposure("n_size_hassler") metric("RIR") ///
    impact(.) uncond(.) rir(`pace_rir') threshold(`pace_thr_rir') ///
    rsq(`pace_rsq_rir') rsqyz(`pace_rsqyz_rir') rsqxz(`pace_rsqxz_rir') ///
    corry(`pace_rycv_rir') corrx(`pace_rxcv_rir')

local pace_covars `covariate_list'
local pace_count : word count `pace_covars'
quietly corr `pace_covars' n_size_hassler if `sample_pace' == 1
matrix mat_corrx = r(C)
quietly corr `pace_covars' pace if `sample_pace' == 1
matrix mat_corry = r(C)
local col = `pace_count' + 1
forvalues i = 1/`pace_count' {
    local cov : word `i' of `pace_covars'
    scalar corr_vx_tmp = mat_corrx[`i', `col']
    scalar corr_vy_tmp = mat_corry[`i', `col']
    local corr_vx = scalar(corr_vx_tmp)
    local corr_vy = scalar(corr_vy_tmp)
    local impact = `corr_vx' * `corr_vy'
    add_impact_row, outcome("pace") exposure("n_size_hassler") ///
        type("Raw") covariate("`cov'") corrvx(`corr_vx') ///
        corrvy(`corr_vy') impact(`impact')
}
quietly pcorr n_size_hassler `pace_covars' if `sample_pace' == 1
matrix mat_partx = r(p_corr)
quietly pcorr pace `pace_covars' if `sample_pace' == 1
matrix mat_party = r(p_corr)
forvalues i = 1/`pace_count' {
    local cov : word `i' of `pace_covars'
    scalar corr_vx_tmp = mat_partx[`i', 1]
    scalar corr_vy_tmp = mat_party[`i', 1]
    local corr_vx = scalar(corr_vx_tmp)
    local corr_vy = scalar(corr_vy_tmp)
    local impact = `corr_vx' * `corr_vy'
    add_impact_row, outcome("pace") exposure("n_size_hassler") ///
        type("Partial") covariate("`cov'") corrvx(`corr_vx') ///
        corrvy(`corr_vy') impact(`impact')
}

* AgeAccelGrim2 outcome
tempvar sample_grim
svy: reg ageaccelgrim2 `control_var' c.n_size_hassler if ~missing(n_size_hassler)
gen byte `sample_grim' = e(sample)
estimates store grim_reg

estimates restore grim_reg
konfound n_size_hassler, indx("IT")
local grim_it = r(itcv)
local grim_uncon = r(unconitcv)
local grim_thr = r(thr)
local grim_rsq = r(Rsq)
local grim_rsqyz = r(RsqYZ)
local grim_rsqxz = r(RsqXZ)
local grim_rycv = r(r_ycv)
local grim_rxcv = r(r_xcv)
add_summary, outcome("ageaccelgrim2") exposure("n_size_hassler") metric("IT") ///
    impact(`grim_it') uncond(`grim_uncon') rir(.) threshold(`grim_thr') ///
    rsq(`grim_rsq') rsqyz(`grim_rsqyz') rsqxz(`grim_rsqxz') ///
    corry(`grim_rycv') corrx(`grim_rxcv')

estimates restore grim_reg
konfound n_size_hassler, indx("RIR")
local grim_rir = r(rir)
local grim_thr_rir = r(thr)
local grim_rsq_rir = r(Rsq)
local grim_rsqyz_rir = r(RsqYZ)
local grim_rsqxz_rir = r(RsqXZ)
local grim_rycv_rir = r(r_ycv)
local grim_rxcv_rir = r(r_xcv)
add_summary, outcome("ageaccelgrim2") exposure("n_size_hassler") metric("RIR") ///
    impact(.) uncond(.) rir(`grim_rir') threshold(`grim_thr_rir') ///
    rsq(`grim_rsq_rir') rsqyz(`grim_rsqyz_rir') rsqxz(`grim_rsqxz_rir') ///
    corry(`grim_rycv_rir') corrx(`grim_rxcv_rir')

local grim_covars `covariate_list'
local grim_count : word count `grim_covars'
quietly corr `grim_covars' n_size_hassler if `sample_grim' == 1
matrix mat_corrx = r(C)
quietly corr `grim_covars' ageaccelgrim2 if `sample_grim' == 1
matrix mat_corry = r(C)
local col = `grim_count' + 1
forvalues i = 1/`grim_count' {
    local cov : word `i' of `grim_covars'
    scalar corr_vx_tmp = mat_corrx[`i', `col']
    scalar corr_vy_tmp = mat_corry[`i', `col']
    local corr_vx = scalar(corr_vx_tmp)
    local corr_vy = scalar(corr_vy_tmp)
    local impact = `corr_vx' * `corr_vy'
    add_impact_row, outcome("ageaccelgrim2") exposure("n_size_hassler") ///
        type("Raw") covariate("`cov'") corrvx(`corr_vx') ///
        corrvy(`corr_vy') impact(`impact')
}
quietly pcorr n_size_hassler `grim_covars' if `sample_grim' == 1
matrix mat_partx = r(p_corr)
quietly pcorr ageaccelgrim2 `grim_covars' if `sample_grim' == 1
matrix mat_party = r(p_corr)
forvalues i = 1/`grim_count' {
    local cov : word `i' of `grim_covars'
    scalar corr_vx_tmp = mat_partx[`i', 1]
    scalar corr_vy_tmp = mat_party[`i', 1]
    local corr_vx = scalar(corr_vx_tmp)
    local corr_vy = scalar(corr_vy_tmp)
    local impact = `corr_vx' * `corr_vy'
    add_impact_row, outcome("ageaccelgrim2") exposure("n_size_hassler") ///
        type("Partial") covariate("`cov'") corrvx(`corr_vx') ///
        corrvy(`corr_vy') impact(`impact')
}

frame summary: export delimited using "`csv_path'", replace
frame impacts: export delimited using "`cov_path'", replace

file open fh using "`ok_path'", write replace
file close fh
