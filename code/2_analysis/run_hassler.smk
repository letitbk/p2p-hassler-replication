import os
from os.path import join

STATA = "/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp"

# paths
# Use symlink without spaces so Stata arguments are parsed correctly.
dir_data_raw = join('/Users/bk/Indiana University/[Sec-E] BL-SURV-Secure Storage - P2P/Stata Files')

dir_project = '/Users/bk/Indiana University/IU-IRSY-P2P - BK/'
dir_data_processed = os.path.join(dir_project, 'data', 'processed')

# Output to local repository for sharing
CODE_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(workflow.snakefile))))
dir_output_final = os.path.join(CODE_REPO, 'output')

# code directory (local repository)
CODE_PATH = os.path.dirname(os.path.abspath(workflow.snakefile))
CODE_HASSLER = os.path.dirname(CODE_PATH)  # parent of 2_analysis

# central log directory
LOG_DIR = os.path.join(CODE_PATH, "logs")

# aliases for compatibility
PROJECT_PATH = dir_project
PROCESSED_PATH = dir_data_processed
OUT_HASSLER_RR = dir_output_final

RAW_P2P_NETWORK = dir_data_raw
EGO_NETWORK_DTA = os.path.join(RAW_P2P_NETWORK, "egocentric_networks.dta")
EGO_PAIRS_DTA = os.path.join(RAW_P2P_NETWORK, "egocentric_networks_pairs.dta")

DEMO_EGO_RDS = os.path.join(PROCESSED_PATH, "p2p_demo_cleaned.rds")
EPIGEN_RDS = os.path.join(PROCESSED_PATH, "p2p_epigen_0501.rds")
ALTER_RDS = os.path.join(PROCESSED_PATH, "p2p_egonetwork_alter.rds")

RAW_DATA = os.path.join(PROCESSED_PATH, "p2p_epigen_0501.dta")
CLEANED_DATA = os.path.join(PROCESSED_PATH, "p2p_epigen_regression.dta")

# output files
TABLE1_CSV = os.path.join(OUT_HASSLER_RR, "table_s1_summary.csv")
TABLE1_OK = os.path.join(OUT_HASSLER_RR, "table_s1_summary.ok")

FIG_CLOCK_BOX = os.path.join(OUT_HASSLER_RR, "figure_1_clockdist_by_age_boxplot.png")

TABLE_NETWORK_SIZE = os.path.join(OUT_HASSLER_RR, "table_s2_distribution_network_size.xlsx")
TABLE_HASSLER_SIZE = os.path.join(OUT_HASSLER_RR, "table_s3_distribution_hassler_network_size.xlsx")

FIG_REL_SHARE = os.path.join(OUT_HASSLER_RR, "figure_s1_relationship_hassler_share.png")
FIG_NETWORK_HASSLER = os.path.join(OUT_HASSLER_RR, "figure_3_network_by_hassler.png")

MAIN_AME = os.path.join(OUT_HASSLER_RR, "table_1_main_effects_ame.csv")
MAIN_EST = os.path.join(OUT_HASSLER_RR, "table_s5_main_effects_est.csv")
MAIN_OK = os.path.join(OUT_HASSLER_RR, "table_1_s4_main_effects.ok")

MAIN_INTERP_AME = os.path.join(OUT_HASSLER_RR, "table_1_main_effects_interpretableDV_ame.csv")
MAIN_INTERP_EST = os.path.join(OUT_HASSLER_RR, "table_1_main_effects_interpretableDV_est.csv")
MAIN_INTERP_OK = os.path.join(OUT_HASSLER_RR, "table_1_main_effects_interpretableDV.ok")

ALT_AME = os.path.join(OUT_HASSLER_RR, "table_s6_alternative_indicators_ame.csv")
ALT_EST = os.path.join(OUT_HASSLER_RR, "table_s6_alternative_indicators_est.csv")
ALT_OK = os.path.join(OUT_HASSLER_RR, "table_s6_alternative_indicators.ok")

TIE_TYPES_AME = os.path.join(OUT_HASSLER_RR, "table_2_tie_types_ame.csv")
TIE_TYPES_OK = os.path.join(OUT_HASSLER_RR, "table_2_tie_types.ok")

ROBUSTNESS_AME = os.path.join(OUT_HASSLER_RR, "table_s10_main_robustness_ame.csv")
ROBUSTNESS_OK = os.path.join(OUT_HASSLER_RR, "table_s10_main_robustness.ok")

T1_AME = os.path.join(OUT_HASSLER_RR, "table_s11_longitudinal_outcomes_ame.csv")
T1_EST = os.path.join(OUT_HASSLER_RR, "table_s11_longitudinal_outcomes_est.csv")
T1_OK = os.path.join(OUT_HASSLER_RR, "table_s11_longitudinal_outcomes.ok")

OTHER_OUTCOMES_AME = os.path.join(OUT_HASSLER_RR, "table_s7_other_outcomes_ame.csv")
OTHER_OUTCOMES_EST = os.path.join(OUT_HASSLER_RR, "table_s8-s9_other_outcomes_est.csv")
OTHER_OUTCOMES_OK = os.path.join(OUT_HASSLER_RR, "table_s7-s9_other_outcomes.ok")

OTHER_OUTCOMES_SDUNIT_ME = os.path.join(OUT_HASSLER_RR, "figure_4_me_other_outcomes_sdunit.csv")
OTHER_OUTCOMES_SDUNIT_OK = os.path.join(OUT_HASSLER_RR, "figure_4_other_outcomes_sdunit.ok")
FIG_OTHER_OUTCOMES_SDUNIT = os.path.join(OUT_HASSLER_RR, "figure_4_other_outcomes_sdunit.png")
FIG_OTHER_OUTCOMES_SDUNIT_LOG = os.path.join(OUT_HASSLER_RR, "figure_4_other_outcomes_sdunit.log")


HET_GENDER_AME = os.path.join(OUT_HASSLER_RR, "table_s13_heterogeneity_gender_ame.csv")
HET_GENDER_EST = os.path.join(OUT_HASSLER_RR, "table_s13_heterogeneity_gender_est.csv")
HET_GENDER_OK = os.path.join(OUT_HASSLER_RR, "table_s13_heterogeneity_gender.ok")

HET_AGEGROUP_AME = os.path.join(OUT_HASSLER_RR, "table_s15_heterogeneity_agegroup_ame.csv")
HET_AGEGROUP_EST = os.path.join(OUT_HASSLER_RR, "table_s15_heterogeneity_agegroup_est.csv")
HET_AGEGROUP_OK = os.path.join(OUT_HASSLER_RR, "table_s15_heterogeneity_agegroup.ok")

SPOUSE_MARITAL_AME = os.path.join(OUT_HASSLER_RR, "table_s11_heterogeneity_spouse_marital_ame.csv")
SPOUSE_MARITAL_EST = os.path.join(OUT_HASSLER_RR, "table_s11_heterogeneity_spouse_marital_est.csv")
SPOUSE_HET_OK = os.path.join(OUT_HASSLER_RR, "table_s11_heterogeneity_spouse.ok")


ZIP_MCHANGE_MAIN = os.path.join(OUT_HASSLER_RR, "figure_2_marginal_effects_hasslers_zip_svy_main.csv")
FIG_ME_HASSLERS_ZIP_SVY = os.path.join(OUT_HASSLER_RR, "figure_2_marginal_effects_hasslers_zip_svy.png")
TAB_ME_HASSLERS_ZIP_SVY = os.path.join(OUT_HASSLER_RR, "table_s4_est_regression_zip_hassler.csv")

KONFOUND_N_SIZE_CSV = os.path.join(OUT_HASSLER_RR, "table_s14_konfound_n_size_hassler.csv")
KONFOUND_N_SIZE_IMPACTS = os.path.join(OUT_HASSLER_RR, "table_s14_konfound_n_size_hassler_impacts.csv")
KONFOUND_N_SIZE_OK = os.path.join(OUT_HASSLER_RR, "table_s14_konfound_n_size_hassler.ok")


rule all:
    input:
        CLEANED_DATA,
        TABLE1_OK,
        MAIN_OK,
        MAIN_INTERP_AME,
        MAIN_INTERP_EST,
        MAIN_INTERP_OK,
        ALT_OK,
        T1_OK,
        T1_AME,
        T1_EST,
        ROBUSTNESS_OK,
        TIE_TYPES_OK,
        OTHER_OUTCOMES_OK,
        OTHER_OUTCOMES_SDUNIT_ME,
        OTHER_OUTCOMES_SDUNIT_OK,
        FIG_OTHER_OUTCOMES_SDUNIT,
        FIG_OTHER_OUTCOMES_SDUNIT_LOG,
        HET_GENDER_OK,
        HET_AGEGROUP_OK,
        SPOUSE_MARITAL_AME,
        SPOUSE_MARITAL_EST,
        SPOUSE_HET_OK,
        KONFOUND_N_SIZE_CSV,
        KONFOUND_N_SIZE_IMPACTS,
        KONFOUND_N_SIZE_OK,
        FIG_CLOCK_BOX,
        TABLE_NETWORK_SIZE,
        TABLE_HASSLER_SIZE,
        FIG_REL_SHARE,
        FIG_NETWORK_HASSLER,
        FIG_ME_HASSLERS_ZIP_SVY,
        TAB_ME_HASSLERS_ZIP_SVY

rule table1_analysis:
    input:
        script=join(CODE_HASSLER, "2_analysis", "01_table-s1-analysis.do"),
        data=CLEANED_DATA
    output:
        csv=TABLE1_CSV,
        ok=TABLE1_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" TABLE_PATH="{output.csv}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_main_effects:
    input:
        script=join(CODE_HASSLER, "2_analysis", "03_table-1-s4_main_effects.do"),
        data=CLEANED_DATA
    output:
        ame=MAIN_AME,
        est=MAIN_EST,
        ok=MAIN_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" EST_PATH="{output.est}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_main_effects_interpretable_dv:
    input:
        script=join(CODE_HASSLER, "2_analysis", "03_table-1-main_effects_interpretableDV.do"),
        data=CLEANED_DATA
    output:
        ame=MAIN_INTERP_AME,
        est=MAIN_INTERP_EST,
        ok=MAIN_INTERP_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" EST_PATH="{output.est}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_alternative_indicators:
    input:
        script=join(CODE_HASSLER, "2_analysis", "03_table-s6-alternative_indicators.do"),
        data=CLEANED_DATA
    output:
        ame=ALT_AME,
        est=ALT_EST,
        ok=ALT_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" EST_PATH="{output.est}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_robustness:
    input:
        script=join(CODE_HASSLER, "2_analysis", "03_table-s10-main_robustness.do"),
        data=CLEANED_DATA
    output:
        ame=ROBUSTNESS_AME,
        ok=ROBUSTNESS_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_tie_types:
    input:
        script=join(CODE_HASSLER, "2_analysis", "03_table-2-tie_types.do"),
        data=CLEANED_DATA
    output:
        ame=TIE_TYPES_AME,
        ok=TIE_TYPES_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_other_outcomes:
    input:
        script=join(CODE_HASSLER, "2_analysis", "03_table-4-s7-s8-other_outcomes.do"),
        data=CLEANED_DATA
    output:
        ame=OTHER_OUTCOMES_AME,
        est=OTHER_OUTCOMES_EST,
        ok=OTHER_OUTCOMES_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" EST_PATH="{output.est}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'

rule table_other_outcomes_sdunit:
    input:
        script=os.path.join(CODE_HASSLER, "2_analysis", "03_figure-4-other_outcomes_sdunit.do"),
        data=CLEANED_DATA
    output:
        me_csv=OTHER_OUTCOMES_SDUNIT_ME,
        ok=OTHER_OUTCOMES_SDUNIT_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" ME_CSV_PATH="{output.me_csv}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'

rule figure_other_outcomes_sdunit:
    input:
        csv=OTHER_OUTCOMES_SDUNIT_ME
    output:
        FIG_OTHER_OUTCOMES_SDUNIT
    log:
        FIG_OTHER_OUTCOMES_SDUNIT_LOG
    script:
        "03_figure-4-other_outcomes_sdunit.R"


rule konfound_n_size_hassler:
    input:
        script=join(CODE_HASSLER, "2_analysis", "04_table-s14-konfound.do"),
        data=CLEANED_DATA
    output:
        csv=KONFOUND_N_SIZE_CSV,
        cov=KONFOUND_N_SIZE_IMPACTS,
        ok=KONFOUND_N_SIZE_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" CSV_PATH="{output.csv}" COV_PATH="{output.cov}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule figure_clockdist_by_age_boxplot:
    input:
        data=EPIGEN_RDS
    output:
        FIG_CLOCK_BOX
    script:
        "01_figure-1-clockdist_by_age_boxplot.R"


rule table_network_size_distribution:
    input:
        data=EPIGEN_RDS
    output:
        TABLE_NETWORK_SIZE
    script:
        "01_table-s2-network_size_distribution.R"


rule table_hassler_network_size_distribution:
    input:
        data=EPIGEN_RDS
    output:
        TABLE_HASSLER_SIZE
    script:
        "01_table-s3-hassler_network_size_distribution.R"


rule figure_relationship_hassler_share_by_type:
    input:
        alters=EGO_NETWORK_DTA
    output:
        rel_share=FIG_REL_SHARE
    script:
        "03_figure-s1-relationship_hassler_share.R"


rule figure_network_by_hassler:
    input:
        alters=ALTER_RDS,
        data=EPIGEN_RDS
    output:
        FIG_NETWORK_HASSLER
    script:
        "03_figure-3-network_by_hassler.R"


rule zip_mchange_hasslers_svy:
    input:
        script=join(CODE_HASSLER, "2_analysis", "02_figure-2-marginal_effects_hasslers_zip_svy.do"),
        data=CLEANED_DATA
    output:
        main=ZIP_MCHANGE_MAIN,
        est=TAB_ME_HASSLERS_ZIP_SVY
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" EST_PATH="{output.est}" CSV_MAIN="{output.main}" "{STATA}" -b do "{input.script}"'

rule figure_marginal_effects_hasslers_zip_svy:
    input:
        csv_main=ZIP_MCHANGE_MAIN,
        data=CLEANED_DATA
    output:
        plot=FIG_ME_HASSLERS_ZIP_SVY
    script:
        "02_figure-2-marginal_effects_hasslers_zip_svy.R"


rule table_heterogeneity_gender:
    input:
        script=join(CODE_HASSLER, "2_analysis", "04_table-s13-heterogeneity_gender.do"),
        data=CLEANED_DATA
    output:
        ame=HET_GENDER_AME,
        est=HET_GENDER_EST,
        ok=HET_GENDER_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" EST_PATH="{output.est}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_heterogeneity_agegroup:
    input:
        script=join(CODE_HASSLER, "2_analysis", "04_table-s15-heterogeneity_age.do"),
        data=CLEANED_DATA
    output:
        ame=HET_AGEGROUP_AME,
        est=HET_AGEGROUP_EST,
        ok=HET_AGEGROUP_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" EST_PATH="{output.est}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_t1_outcomes:
    input:
        script=join(CODE_HASSLER, "2_analysis", "04_table-s11-longitudinal_outcomes.do"),
        data=CLEANED_DATA
    output:
        ame=T1_AME,
        est=T1_EST,
        ok=T1_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_PATH="{output.ame}" EST_PATH="{output.est}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'


rule table_heterogeneity_spouse:
    input:
        script=join(CODE_HASSLER, "2_analysis", "04_table-s12-heterogeneity_spouse.do"),
        data=CLEANED_DATA
    output:
        ame_marital=SPOUSE_MARITAL_AME,
        est_marital=SPOUSE_MARITAL_EST,
        ok=SPOUSE_HET_OK
    shell:
        'mkdir -p "{LOG_DIR}" && cd "{LOG_DIR}" && DATA_PATH="{input.data}" AME_MARITAL_PATH="{output.ame_marital}" EST_MARITAL_PATH="{output.est_marital}" OK_PATH="{output.ok}" "{STATA}" -b do "{input.script}"'
