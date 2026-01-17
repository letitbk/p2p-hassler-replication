#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# occupation variables
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - combined_occ_label: Combined occupation label (used for occ_group)
#' ==============

#' =============================================================================
#' Path Configuration - Supports both Snakemake and standalone execution
#' =============================================================================

if (!exists('snakemake')) {
    # Standalone mode - load configuration file
    config_path <- paste0("../", "config_paths.R")
    if (!file.exists(config_path)) {
        stop("Configuration file not found. Please copy config_paths.R.template to config_paths.R and edit paths.")
    }
    source(config_path)

    # Create mock snakemake object for standalone execution
    snakemake <- setClass("snakemake",
      slots = c(
        input = "list",
        params = "list",
        output = "list")
    )

    snakemake = new(
        "snakemake",
        input = list(
            end = get_raw_path('end_material.dta'),
            occupation_coding = get_rawdata_subdir_path('occupation', 'emus_occupations.dta')
        ),
        output = list(
            df_occupation = get_processed_path('p2p_occupation.rds')
        )
    )

} else {
    # Snakemake mode - set up logging
    log_file = file(snakemake@log[[1]], open = "wt")
    sink(log_file, type = "output")
    sink(log_file, type = "message")
}

library(data.table)
library(rio)
library(fst)
library(logger)


log_info('# load baseline data')

dt_end = import(snakemake@input$end)
setDT(dt_end)
names(dt_end) = tolower(names(dt_end))

dt_occupation = import(snakemake@input$occupation_coding)
setDT(dt_occupation)


log_info('# load completes ....')

# merge
dt_merged = merge(dt_end, dt_occupation, by = 'su_id', all.x = TRUE)

# map emp_status using factor
dt_merged[, emp_status_label := factor(emp_status,
    levels = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10),
    labels = c('Working Full-time', 'Working Part-time', 'Temporarily Laid Off/Sick Leave/Maternity Leave', 'Unemployed Looking for Work', 'Unemployed Not Looking for Work', 'Retired', 'Disabled', 'Homemaker', 'Student', 'Other'))
]

# now use both occupation data sets from
dt_merged[farming %in% c(0,1),occ_farming := ifelse(farming == 1, 1, 0)]
dt_merged[automotive %in% c(0,1),occ_automotive := ifelse(automotive == 1, 1, 0)]
dt_merged[construction %in% c(0,1),occ_construction := ifelse(construction == 1, 1, 0)]
dt_merged[manufacturing %in% c(0,1),occ_manufacturing := ifelse(manufacturing == 1, 1, 0)]
dt_merged[railroad %in% c(0,1),occ_railroad := ifelse(railroad == 1, 1, 0)]
dt_merged[forestry %in% c(0,1),occ_forestry := ifelse(forestry == 1, 1, 0)]
dt_merged[electrical %in% c(0,1),occ_electrical := ifelse(electrical == 1, 1, 0)]
dt_merged[beauty %in% c(0,1),occ_beauty := ifelse(beauty == 1, 1, 0)]
dt_merged[welding %in% c(0,1),occ_welding := ifelse(welding == 1, 1, 0)]
dt_merged[fire %in% c(0,1),occ_fire := ifelse(fire == 1, 1, 0)]


# combine these two categories
# ---- lookups ----
occ1_labels <- c(
  `11`="Management Occupations",
  `13`="Business & Financial Operations Occupations",
  `15`="Computer & Mathematical Occupations",
  `17`="Architecture & Engineering Occupations",
  `19`="Life, Physical, & Social Science Occupations",
  `21`="Community & Social Service Occupations",
  `23`="Legal Occupations",
  `25`="Educational Instruction & Library Occupations",
  `27`="Arts, Design, Entertainment, Sports, & Media Occupations",
  `29`="Healthcare Practitioners & Technical Occupations",
  `31`="Healthcare Support Occupations",
  `33`="Protective Service Occupations",
  `35`="Food Preparation & Serving Related Occupations",
  `37`="Building & Grounds Cleaning & Maintenance Occupations",
  `39`="Personal Care & Service Occupations",
  `41`="Sales & Related Occupations",
  `43`="Office & Administrative Support Occupations",
  `45`="Farming, Fishing, & Forestry Occupations",
  `47`="Construction & Extraction Occupations",
  `49`="Installation, Maintenance, & Repair Occupations",
  `51`="Production Occupations",
  `53`="Transportation & Material Moving Occupations",
  `55`="Military Specific Occupations",
  `57`="Other, please specify",
  `99`="Multiple trade occupations" # tie-break bucket
)

flag_to_occ1 <- c(
  occ_farming      = 45,   # farming/forestry : Framing, Fishing, & Forestry Occupations
  occ_automotive   = 49,   # auto tech/mech : Installation, Maintenance, & Repair Occupations
  occ_construction = 47,   # construction trades : Construction & Extraction Occupations
  occ_manufacturing= 51,   # plant/shop floor : Production Occupations
  occ_railroad     = 53,   # rail transport : Transportation & Material Moving Occupations
  occ_forestry     = 45,   # forestry : Farming, Fishing, & Forestry Occupations
  occ_electrical   = 49,   # electrician : Installation, Maintenance, & Repair Occupations
  occ_beauty       = 39,   # barber/beautician : Personal Care & Service Occupations
  occ_welding      = 51,   # welder : Production Occupations
  occ_fire         = 33    # firefighter : Protective Service Occupations
)

# ---- function ----
flag_cols <- intersect(names(flag_to_occ1), names(dt_merged))

# long view of flags that are O
dt_merged[, occ_multiple := NA]

for (var in flag_cols){
    dt_merged[get(var) == 1,  occ_multiple := as.double(flag_to_occ1[var])]
}


dt_merged[,occ_multiple := as.double(occ_multiple)]

# WARNING: I have to address the multiple occupations issues

# combine with precedence: keep occ1 if not 57/NA; else use occ2; else keep occ1 (NA or 57)
dt_merged[, combined_occ_code :=
    fcase(
        !is.na(occ_multiple), occ_multiple,
        !is.na(occupation_imp), occupation_imp,
        default = occ_multiple
    )
]
dt_merged[,table(combined_occ_code)]
dt_merged[,table(combined_occ_code, no_industry)] # most of them are no industry

# relabel using occ1_labels
dt_merged[, combined_occ_label := unname(occ1_labels[as.character(combined_occ_code)])]

#dt_merged[no_industry == 1 & is.na(combined_occ_label) , table(emp_status_label)]

dt_merged[is.na(combined_occ_label) &
    emp_status_label %in% c('Working Full-time', 'Working Part-time', 'Temporarily Laid Off/Sick Leave/Maternity Leave'),
    combined_occ_label := 'Missing Industry']

dt_merged[is.na(combined_occ_label) &
    emp_status_label %in% c('Unemployed Looking for Work', 'Unemployed Not Looking for Work'),
    combined_occ_label := 'Unemployed']

dt_merged[is.na(combined_occ_label) &
    emp_status_label %in% c('Retired', 'Disabled', 'Homemaker', 'Student', 'Other'),
    combined_occ_label := 'Not in labor force']

log_info(paste0('number of still missing occupation/industry: ', nrow(dt_merged[is.na(combined_occ_label), ])))

dt_merged[, table(combined_occ_label)]

log_info('save data ...')
saveRDS(dt_merged[, c('su_id', 'combined_occ_label')], snakemake@output$df_occupation)


