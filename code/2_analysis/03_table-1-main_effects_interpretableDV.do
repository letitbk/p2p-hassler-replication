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
    local ame_path "${OUTPUT_DIR}/table_1_main_effects_interpretableDV_ame.csv"
    local est_path "${OUTPUT_DIR}/table_1_main_effects_interpretableDV_est.csv"
    local ok_path "${OUTPUT_DIR}/table_1_main_effects_interpretableDV.ok"
}

di as text "Data path: `data_path'"

use "`data_path'", clear

svyset fips [pweight = wt_final2]

local control_var i.batch_int leukocytes_ic age i.race3 i.gender_birth i.educ3 i.marital3 i.n_size_all

* Create top10 indicators for pace and ageaccelgrim2 within each age group
* Create age groups in 10-year intervals (10s, 20s, 30s, etc.)
capture drop age_group_10yr
gen age_group_10yr = floor(age / 5) * 10
label var age_group_10yr "Age group in 10-year intervals"

gen age_group_5yr = floor(age / 5) * 5
label var age_group_5yr "Age group in 5-year intervals"
recode age_group_5yr (15 = 20) (80/max =80)
tab age_group_5yr

* Calculate 90th percentile threshold for pace within each 5-year age group
capture drop pace_p90_by_age
bysort age_group_5yr: egen pace_p90_by_age = pctile(pace), p(90)

* Create top10 indicator for pace (top 10% = values >= 90th percentile)
capture drop top10_pace
gen byte top10_pace = (pace >= pace_p90_by_age) if ~missing(pace) & ~missing(pace_p90_by_age)
label var top10_pace "Top 10% PACE within 5-year age group"

* Calculate 90th percentile threshold for ageaccelgrim2 within each 5-year age group
capture drop ageaccelgrim2_p90_by_age
bysort age_group_5yr: egen ageaccelgrim2_p90_by_age = pctile(ageaccelgrim2), p(90)

* Create top10 indicator for ageaccelgrim2 (top 10% = values >= 90th percentile)
capture drop top10_ageaccelgrim2
gen byte top10_ageaccelgrim2 = (ageaccelgrim2 >= ageaccelgrim2_p90_by_age) if ~missing(ageaccelgrim2) & ~missing(ageaccelgrim2_p90_by_age)
label var top10_ageaccelgrim2 "Top 10% AgeAccelGrim2 within 5-year age group"

* Clean up temporary percentile variables
drop pace_p90_by_age ageaccelgrim2_p90_by_age

* Standardize n_size_hassler (z-score: mean=0, sd=1)
capture drop std_n_size_hassler
quietly summarize n_size_hassler
gen std_n_size_hassler = (n_size_hassler - r(mean)) / r(sd)
label var std_n_size_hassler "Standardized n_size_hassler (z-score)"

* Standardize pace (z-score: mean=0, sd=1)
capture drop std_pace
quietly summarize pace
gen std_pace = (pace - r(mean)) / r(sd)
label var std_pace "Standardized pace (z-score)"

* Standardize ageaccelgrim2 (z-score: mean=0, sd=1)
capture drop std_ageaccelgrim2
quietly summarize ageaccelgrim2
gen std_ageaccelgrim2 = (ageaccelgrim2 - r(mean)) / r(sd)
label var std_ageaccelgrim2 "Standardized ageaccelgrim2 (z-score)"

estimates clear
svy: logit top10_pace `control_var' c.n_size_hassler if ~missing(n_size_hassler)
estimates store pace_est1
margins, dydx(n_size_hassler) post
estimates store pace_m1

svy: logit top10_ageaccelgrim2 `control_var' c.n_size_hassler if ~missing(n_size_hassler)
estimates store ageaccelgrim2_est1
margins, dydx(n_size_hassler) post
estimates store ageaccelgrim2_m1

svy: reg std_pace `control_var' c.std_n_size_hassler if ~missing(std_n_size_hassler)
estimates store pace_est2
margins, dydx(std_n_size_hassler) post
estimates store pace_m2

svy: reg std_ageaccelgrim2 `control_var' c.std_n_size_hassler if ~missing(std_n_size_hassler)
estimates store ageaccelgrim2_est2
margins, dydx(std_n_size_hassler) post
estimates store ageaccelgrim2_m2

* smoking indicator
gen smoking = (smoke_status == 3 | smoke_status == 4) if ~missing(smoke_status)

svy: reg std_pace `control_var' smoking if ~missing(smoking)
estimates store pace_est3
margins, dydx(smoking) post
estimates store pace_m3

svy: reg std_ageaccelgrim2 `control_var' smoking if ~missing(smoking)
estimates store ageaccelgrim2_est3
margins, dydx(smoking) post
estimates store ageaccelgrim2_m3

esttab *_m* using "`ame_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)
esttab *_est* using "`est_path'", csv se mtitle nogap label replace star(+ 0.1 * 0.05 ** 0.01)

file open fh using "`ok_path'", write replace
file close fh
