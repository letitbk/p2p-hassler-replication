*------------------------------------------------------------
* Data cleaning for Hassler regression analyses
*------------------------------------------------------------
version 17
clear all
set more off

*=============================================================================
* Path Configuration - Supports both Snakemake and standalone execution
*=============================================================================

* Get output path from command line argument (Snakemake mode)
syntax [anything(name=output_path)]

* If not provided, use config file (standalone mode)
if "`output_path'" == "" {
    capture confirm file "`c(pwd)'/../config_paths.do"
    if _rc {
        di as error "Configuration file not found. Please copy config_paths.do.template to config_paths.do and edit paths."
        exit 601
    }
    do "`c(pwd)'/../config_paths.do"

    local data_path "${PROCESSED_DATA_DIR}"
    local output_path "${PROCESSED_DATA_DIR}/p2p_epigen_regression.dta"
}
else {
    * Extract data_path from output_path for consistency
    local data_path = substr("`output_path'", 1, strrpos("`output_path'", "/") - 1)
}

di as text "Data path: `data_path'"
di as text "Output path: `output_path'"

use "`data_path'/p2p_epigen_0501.dta", clear

svyset psu [pweight = wt_comb], strata(strata)

capture drop age_group
recode age ///
    (18/23 = 1 "age 18-23") ///
    (24/44 = 2 "age 24-44") ///
    (45/64 = 3 "age 45-64") ///
    (65/max = 4 "age 65+"), ///
    gen(age_group)

capture drop age_group5
egen age_group5 = cut(age), at(17 25 30 35 40 45 50 55 60 65 70 75 80 105)

recode race_single ///
    (1 = 1 "White") ///
    (2 = 2 "Black") ///
    (3/6 = 3 "Other"), ///
    gen(race3)

recode education ///
    (1/2 = 1 "HS or less than HS") ///
    (3/4 = 2 "Some college") ///
    (5 = 3 "College or higher"), ///
    gen(educ3)

recode marital_status ///
    (1 = 1 "Never-married") ///
    (2/3 = 2 "Married or living with a partner") ///
    (4/6 = 3 "Widowed/Divorced/Separated"), ///
    gen(marital3)

* hassler variables
replace p_hassler = 0 if n_size_all == 0
replace mean_hassler_freq = 0 if n_size_all == 0
replace n_size_hassler = . if missing(p_hassler)

* hassler indicators
gen byte has_hassler = n_size_hassler > 0 if ~missing(n_size_hassler)

capture drop n_size_hassler_cat
recode n_size_hassler (0=0 "0") (1=1 "1") (2=2 "2") (3=3 "3") (4=4 "4") (5/max=5 "5+"), gen(n_size_hassler_cat)
label define n_size_hassler_cat_lbl 0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5+", replace
label values n_size_hassler_cat n_size_hassler_cat_lbl

* hassler categorical variable
egen p_hassler_cat = cut(p_hassler), at(0 0.01 0.25 0.5 1) icodes label
replace p_hassler_cat = 4 if p_hassler == 1

* relationship-specific hassler variables
gen p_sp_n_size_all = sp_n_size_all / n_size_all if ~missing(sp_n_size_all)
gen p_k_n_size_all = k_n_size_all / n_size_all if ~missing(k_n_size_all)
gen p_nk_n_size_all = nk_n_size_all / n_size_all if ~missing(nk_n_size_all)

* impute missing values with 0 when network size is positive but relationship-specific hassler variables are missing
replace sp_p_hassler = 0 if missing(sp_p_hassler) & n_size_all > 0
replace k_p_hassler = 0 if missing(k_p_hassler) & n_size_all > 0
replace nk_p_hassler = 0 if missing(nk_p_hassler) & n_size_all > 0

* lable variables
label var health_insurance "Having Health Insurance"

label var n_size_all "Network Size (All)"
label var n_size_hassler "Number of Hasslers"
label var p_hassler "% Negative Ties"
label var p_hassler_cat "% Negative Ties (Categorical)"
label var mean_hassler_freq "Mean Frequency of Negative Interactions"
label var i_hassler "Presence of any negative ties"
label var sp_p_hassler "% Negative Ties among Spouse/Partner"
label var k_p_hassler "% Negative Ties among Kins"
label var nk_p_hassler "% Negative Ties among Nonkins"
label var p_sp_n_size_all "% Spouse/Partner"
label var p_k_n_size_all "% Kins"
label var p_nk_n_size_all "% Nonkins"

* occupation group variable
encode combined_occ_label, gen(combined_occ_code)

gen occ_group = .
replace occ_group = 1 if inlist(combined_occ_label, ///
    "Management Occupations", ///
    "Business & Financial Operations Occupations", ///
    "Computer & Mathematical Occupations", ///
    "Architecture & Engineering Occupations", ///
    "Legal Occupations", ///
    "Life, Physical, & Social Science Occupations")
replace occ_group = 2 if inlist(combined_occ_label, ///
    "Healthcare Practitioners & Technical Occupations", ///
    "Healthcare Support Occupations")
replace occ_group = 3 if inlist(combined_occ_label, ///
    "Educational Instruction & Library Occupations", ///
    "Community & Social Service Occupations")
replace occ_group = 4 if inlist(combined_occ_label, ///
    "Food Preparation & Serving Related Occupations", ///
    "Personal Care & Service Occupations", ///
    "Protective Service Occupations", ///
    "Building & Grounds Cleaning & Maintenance Occupations")
replace occ_group = 5 if inlist(combined_occ_label, ///
    "Sales & Related Occupations", ///
    "Office & Administrative Support Occupations")
replace occ_group = 6 if inlist(combined_occ_label, ///
    "Production Occupations", ///
    "Transportation & Material Moving Occupations", ///
    "Construction & Extraction Occupations", ///
    "Installation, Maintenance, & Repair Occupations", ///
    "Farming, Fishing, & Forestry Occupations")
replace occ_group = 7 if inlist(combined_occ_label, ///
    "Arts, Design, Entertainment, Sports, & Media Occupations")
replace occ_group = 7 if inlist(combined_occ_label, ///
    "Military Specific Occupations")
replace occ_group = 8 if inlist(combined_occ_label, ///
    "Not in labor force") | missing(combined_occ_label)
replace occ_group = 9 if inlist(combined_occ_label, ///
    "Unemployed") | missing(combined_occ_label)

replace occ_group = 10 if inlist(combined_occ_label, ///
    "Missing Industry") | missing(combined_occ_label) | combined_occ_label == ""

label define occ_group_lbl ///
    1 "Professional/Managerial" ///
    2 "Healthcare" ///
    3 "Education & Social Services" ///
    4 "Service" ///
    5 "Sales & Office" ///
    6 "Production & Transportation" ///
    7 "Other" ///
    8 "Not in labor force" ///
    9 "Unemployed" ///
    10 "Missing Industry"
label values occ_group occ_group_lbl
label var occ_group "Occupation Group (10 categories)"

* charslon morbidity variable
replace cci_charlson_past3years = 0 if missing(cci_charlson_past3years) & ~missing(any_encounter_3years)

* mattering: recategory matter_important matter_depend
gen matter_important_binary = (matter_important == 1) if ~missing(matter_important)
gen matter_depend_binary = (matter_depend == 1) if ~missing(matter_depend)

label var matter_important_binary "How important are you to others"
label var matter_depend_binary "How much do others depend on you"

* mattering: continuous indicators but reverse them
replace matter_important = 4 - matter_important if ~missing(matter_important)
replace matter_depend = 4 - matter_depend if ~missing(matter_depend)

* count the number of non-missing variables
egen n_nonmiss = rowmiss(batch_int leukocytes_ic age race3 gender_birth educ3 marital3 n_size_all n_size_hassler)

* create analytic sample indicator
gen analytic_sample = (n_nonmiss == 0)

* create dummy indicators for race, gender, education, marital status, smoking status, and batch
tab race3, gen(race3_)
tab gender_birth, gen(gender_birth_)
tab educ3, gen(educ3_)
tab marital3, gen(marital3_)
tab smoke_status, gen(smoke_status_)
tab batch_int, gen(batch_int_)

gen female = (gender_birth == 2) if ~missing(gender_birth)

* keep only variables used across analysis scripts
keep ///
    su_id psu strata wt_comb ///
    age gender_birth gender_birth_* race3 race3_* educ3 educ3_* marital3 marital3_* ///
    smoke_status smoke_status_* batch_int batch_int_* leukocytes_ic female ///
    n_size_all n_size_hassler has_hassler n_size_hassler_cat p_hassler p_hassler_cat mean_hassler_freq ///
    sp_n_size_all sp_n_size_hassler k_n_size_hassler nk_n_size_hassler ///
    general_health mental_health physical_health ageaccelgrim2 pace ///
    inflammation cci_charlson_past3years any_encounter_3years ///
    health_insurance covid ///
    multi_morbidity n_missing_morbidity aces_sum ///
    matter_important matter_depend matter_important_binary matter_depend_binary ///
    occ_group ///
    anx_severity dep_severity waist_to_hip_ratio bmi obese height ///
    wave3_general_health wave3_mental_health wave3_physical_health ///
    analytic_sample

compress


save "`output_path'", replace
