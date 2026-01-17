from os.path import join

# paths
dir_data_raw    = join('/Users/bk/Indiana University/[Sec-E] BL-SURV-Secure Storage - P2P/Stata Files')
dir_data_ehr = join('/Users/bk/Indiana University/IU-IRSY-P2P - P2P-EHR')
dir_data_covid = join('/Users/bk/Indiana University - IU-IRSY-P2P - P2P-COVID-19/COVID-19 T3/Stata')

dir_project = '/Users/bk/Indiana University/IU-IRSY-P2P - BK'
dir_data_clock = join(dir_project, 'data', 'rawdata', 'clocks')
dir_data_weight = join(dir_project, 'data', 'rawdata', 'weight')
dir_data_occupation = join(dir_project, 'data', 'rawdata', 'occupation')
dir_data_age = join(dir_project, 'data', 'rawdata', 'age')

dir_data_processed  = join(dir_project, 'data', 'processed')

# final data that can be used to replicate the analysis and shared
dir_data_final = join(dir_project, 'project', 'hassler_replication', 'data')
dir_output_final = join(dir_project, 'project', 'hassler_replication', 'output')

# target files
df_clock = join(dir_data_processed, 'p2p_clock.rds')
df_smoke = join(dir_data_processed, 'p2p_smoke.rds')
df_service = join(dir_data_processed, 'p2p_service_utilization.rds')
df_weight = join(dir_data_processed, 'p2p_weight.rds')
df_demo = join(dir_data_processed, 'p2p_demo_cleaned.rds')
df_occupation = join(dir_data_processed, 'p2p_occupation.rds')
df_general_health = join(dir_data_processed, 'p2p_general_health.rds')
df_mental_health = join(dir_data_processed, 'p2p_mental_health.rds')
df_familyhealth = join(dir_data_processed, 'p2p_familyhealth.rds')
df_biomeasure = join(dir_data_processed, 'p2p_biomeasures.rds')
df_egonetwork = join(dir_data_processed, 'p2p_egonetwork.rds')
df_egonetwork_alter = join(dir_data_processed, 'p2p_egonetwork_alter.rds')
df_ehr_processed = join(dir_data_processed, 'p2p_ehr_processed.rds')
df_belief = join(dir_data_processed, 'p2p_belief_cleaned.rds')
df_covid_wave3 = join(dir_data_processed, 'p2p_covid_wave3.rds')

df_epigen = join(dir_data_processed, 'p2p_epigen_0501.rds')
df_epigen_dta = join(dir_data_processed, 'p2p_epigen_0501.dta')
df_epigen_regression_dta = join(dir_data_processed, 'p2p_epigen_regression.dta')

# Stata executable
STATA = "/Applications/Stata/StataMP.app/Contents/MacOS/stata-mp"

## ------------------------------------------------------------------
## Rules
## ------------------------------------------------------------------
rule all:
    input:
        df_clock,
        df_smoke,
        df_service,
        df_weight,
        df_demo,
        df_general_health,
        df_mental_health,
        df_familyhealth,
        df_biomeasure,
        df_egonetwork,
        df_egonetwork_alter,
        df_occupation,
        df_ehr_processed,
        df_belief,
        df_covid_wave3,
        df_epigen,
        df_epigen_dta,
        df_epigen_regression_dta

rule clean_clock:
    input:
        clock = join(dir_data_clock, 'P2P_DNAmScores_9_30_25.csv')
    output: df_clock = df_clock
    log: join("logs", "0_clean_clock.log")
    script: "0_clean_clock.R"

rule clean_smoke:
    input:
        smoke = join(dir_data_raw, 'tobacco.dta')
    output: df_smoke = df_smoke
    log: join("logs", "0_clean_smoking.log")
    script: "0_clean_smoking.R"

rule clean_service_utilization:
    input:
        service = join(dir_data_raw, 'service_utilization.dta')
    output: df_service = df_service
    log: join("logs", "0_clean_service_utilization.log")
    script: "0_clean_service_utilization.R"

rule clean_demo:
    input:
        demo = join(dir_data_raw, 'demographics.dta'),
        age_fixed = join(dir_data_age, 'p2p_age_estimate.sav')
    output: df_demo = df_demo
    log: join("logs", "0_clean_demo.log")
    script: "0_clean_demo.R"

rule clean_ehr_processed:
    input:
        df_demo = df_demo,
        ehr_diagnoses = join(dir_data_ehr, 'RDRP-5085 Diagnoses.csv'),
        ehr_encounters = join(dir_data_ehr, 'RDRP-5085 Encounters.csv')
    output: df_ehr_processed = df_ehr_processed
    log: join("logs", "0_clean_ehr_processed.log")
    script: "0_clean_ehr_processed.R"

rule clean_occupation:
    input:
        end = join(dir_data_raw, 'end_material.dta'),
        occupation_coding = join(dir_data_occupation, 'emus_occupations.dta')
    output: df_occupation = df_occupation
    log: join("logs", "0_clean_occupation.log")
    script: "0_clean_occupation.R"

rule clean_belief:
    input:
        belief = join(dir_data_raw, 'beliefs_attitudes_other_scales.dta')
    output: df_belief = df_belief
    log: join("logs", "0_clean_belief.log")
    script: "0_clean_belief.R"

rule clean_weight:
    input:
        weight = join(dir_data_weight, 'P2P_panel_weights.dta'),
        df_clock = df_clock,
        df_demo = df_demo
    output: df_weight = df_weight
    log: join("logs", "0_clean_weight.log")
    script: "0_clean_weight.R"

rule clean_general_health:
    input:
        general_health = join(dir_data_raw, 'general_physical_health.dta')
    output: df_general_health = df_general_health
    log: join("logs", "0_clean_general_health.log")
    script: "0_clean_general_health.R"

rule clean_mental_health:
    input:
        mental_health = join(dir_data_raw, 'mental_health.dta')
    output: df_mental_health = df_mental_health
    log: join("logs", "0_clean_mental_health.log")
    script: "0_clean_mental_health.R"

rule clean_family_health:
    input:
        familyhealth = join(dir_data_raw, 'family_health.dta')
    output: df_familyhealth = df_familyhealth
    log: join("logs", "0_clean_family_health.log")
    script: "0_clean_family_health.R"

rule clean_biomeasure:
    input:
        biomeasure = join(dir_data_raw, 'saliva_and_measurements.dta')
    output: df_biomeasure = df_biomeasure
    log: join("logs", "0_clean_biomeasure.log")
    script: "0_clean_biomeasure.R"

rule clean_wave3:
    input:
        covid_wave3 = join(dir_data_covid, 'P2PCovid19 Wave3 main.dta')
    output: df_covid_wave3 = df_covid_wave3
    log: join("logs", "0_clean_wave3.log")
    script: "0_clean_wave3.R"

rule clean_network:
    input:
        egonet = join(dir_data_raw, 'egocentric_networks.dta'),
        aaties = join(dir_data_raw, 'egocentric_networks_pairs.dta'),
        df_demo = df_demo
    output:
        df_egonetwork = df_egonetwork,
        df_egonetwork_alter = df_egonetwork_alter
    log: join("logs", "0_clean_network.log")
    script: "0_clean_network_refactored.R"

rule combine_all:
    input:
        df_clock = df_clock,
        df_smoke = df_smoke,
        df_service = df_service,
        df_weight = df_weight,
        df_demo = df_demo,
        df_general_health = df_general_health,
        df_mental_health = df_mental_health,
        df_familyhealth = df_familyhealth,
        df_biomeasure = df_biomeasure,
        df_egonetwork = df_egonetwork,
        df_occupation = df_occupation,
        df_ehr_processed = df_ehr_processed,
        df_belief = df_belief,
        df_covid_wave3 = df_covid_wave3
    output:
        df_epigen = df_epigen,
        df_epigen_dta = df_epigen_dta
    log: join("logs", "1_combine_datafile.log")
    script: "1_combine_datafile.R"

rule clean_regression_data:
    input:
        script = "1_clean_data.do",
        raw = df_epigen_dta
    output:
        cleaned = df_epigen_regression_dta
    log: join("logs", "1_clean_data.log")
    shell:
        r'''
        "{STATA}" -b do {input.script:q} {output.cleaned:q}
        log_base="$(basename "{output.cleaned}" .dta).log"
        if [ -f "$log_base" ]; then
            mv "$log_base" {log}
        elif [ -f "1_clean_data.log" ]; then
            mv "1_clean_data.log" {log}
        else
            echo "Stata log not found" >&2
            exit 1
        fi
        '''
