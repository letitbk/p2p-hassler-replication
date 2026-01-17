#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# clock variables (epigenetic clocks and DNA methylation measures)
#' ==============
# Variables created:
#   - su_id: Subject ID
#   - batch_int: Batch number (integer)
#   - leukocytes_ic: Leukocyte count (IC method)
#   - horvath, skinblood, phenoage, pace: Epigenetic clock measures
#   - dnamgrimage2, ageaccelgrim2: GrimAge measures
#   - inflammation: DNA methylation-based inflammation score
#' ==============

#' =============================================================================
#' Path Configuration - Supports both Snakemake and standalone execution
#' =============================================================================

if (!exists("snakemake")) {
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
            clock = get_rawdata_subdir_path('clocks', 'P2P_DNAmScores_9_30_25.csv')
        ),
        output = list(
            df_clock = get_processed_path('p2p_clock.rds')
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

log_info('Loading clock data ... ')

dt_clock = fread(snakemake@input$clock)
names(dt_clock) <- tolower(names(dt_clock))


# subset the first four or five letter of the sample name before "-CL"
dt_clock[, c('batch_int','sample_cl','plate_number') := tstrsplit(sample_name, '-')]
dt_clock[, batch_int := as.numeric(batch_int)]
dt_clock = dt_clock[duplicates == 'No', ]

# create a unique case per su_id
dt_clock = unique(dt_clock, by='su_id')

dnabased_measures = grep('^dnam',names(dt_clock),value=TRUE)
dnabased_measures= setdiff(dnabased_measures, 'dnamgrimage2')

# other 9 scores:
#
#1. inflammation: based on an EWAS of chronic low grade inflammation (measured with CRP)
#DNA methylation signatures of chronic low-grade inflammation are associated with complex diseases | Genome Biology | Full Text
#
#2. tnfa: EWAS of tumor necrosis factor alpha, a biomarker of heart disease risk
#Association of Methylation Signals With Incident Coronary Heart Disease in an Epigenome-Wide Assessment of Circulating Tumor Necrosis Factor α | Genetics and Genomics | JAMA Cardiology | JAMA Network
#
#3. mombmi: EWAS of maternal BMI
#Maternal BMI at the start of pregnancy and offspring epigenome-wide DNA methylation: findings from the pregnancy and childhood epigenetics (PACE) consortium | Human Molecular Genetics | Oxford Academic
#
#4. bmihamilton: machine learning trained predictor of BMI
#An epigenetic score for BMI based on DNA methylation correlates with poor physical health and major disease in the Lothian Birth Cohort
#
#5. bmimccartney:  machine learning trained predictor of BMI
#Epigenetic prediction of complex traits and death | Genome Biology | Full Text
#
#6. bmiwahl: EWAS of BMI
#Epigenome-wide association study of body mass index, and the adverse outcomes of adiposity | Nature
#
#7. momsmoke: EWAS of maternal smoking
#DNA Methylation in Newborns and Maternal Smoking in Pregnancy: Genome-wide Consortium Meta-analysis - ScienceDirect
#
#8. particle2.5: EWAS of particulate matter 2.5
#Prenatal Particulate Air Pollution and DNA Methylation in Newborns: An Epigenome-Wide Meta-Analysis | Environmental Health Perspectives | Vol. 127, No. 5
#
#9.  particle10: EWAS of particulate matter 10
#Prenatal Particulate Air Pollution and DNA Methylation in Newborns: An Epigenome-Wide Meta-Analysis | Environmental Health Perspectives | Vol. 127, No. 5
#
#
#The scores have the "MethIDs" so you'll need to merge to get the SU_IDs.

setnames(dt_clock, 'particle2.5','particle2_5')

additional_estimates = c('inflammation','tnfa','mombmi','bmihamilton','bmimccartney',
    'bmiwahl','momsmoke','particle2_5','particle10')

setnames(dt_clock, 'horvath1', 'horvath')
setnames(dt_clock, 'horvath2', 'skinblood')
setnames(dt_clock, 'dunedinpace', 'pace')

setnames(dt_clock, 'ic', 'leukocytes_ic')

original_clocks = c('horvath','skinblood','phenoage','pace','dnamgrimage2','ageaccelgrim2')

dt_clock = dt_clock[, c('su_id', 'batch_int', 'leukocytes', 'leukocytes_ic', original_clocks, dnabased_measures,additional_estimates, 'epi_g'), with=F]
names(dt_clock) = gsub('\\.','_', names(dt_clock))

saveRDS(dt_clock, snakemake@output$df_clock)



