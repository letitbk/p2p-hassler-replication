#!/usr/bin/env Rscript

#' --------------
# P2P data cleaning ----
# ego network variables
#' ==============
# Variables created (ego-level network measures):
#   - su_id: Subject ID
#   - n_size_all: Total network size
#   - n_size_hassler: Number of hasslers in network
#   - p_hassler: Proportion of hasslers in network
#   - mean_hassler_freq: Mean frequency of negative interactions
#   - Relationship-specific measures (with prefixes):
#     * sp_*: Spouse/partner measures (sp_p_hassler, sp_n_size_all, etc.)
#     * k_*: Kin measures (k_p_hassler, k_n_size_all, etc.)
#     * nk_*: Non-kin measures (nk_p_hassler, nk_n_size_all, etc.)
#   - Additional network measures: density, constraint, betweenness, closeness, etc.
#' ==============

#' =============================================================================
#' Path Configuration - Supports both Snakemake and standalone execution
#' =============================================================================

if (!exists("snakemake")) {
    # Standalone mode - load configuration file
    config_path <- file.path(dirname(sys.frame(1)$ofile), "..", "config_paths.R")
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
            egonet = get_raw_path('egocentric_networks.dta'),
            df_demo = get_processed_path('p2p_demo_cleaned.rds'),
            aaties = get_raw_path('egocentric_networks_pairs.dta')
        ),
        output = list(
            df_egonetwork = get_processed_path('p2p_egonetwork.rds'),
            df_egonetwork_alter = get_processed_path('p2p_egonetwork_alter.rds')
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
library(egor)
library(igraph)

summarize_network_measures <- function(dt) {
	dt[
		,
		.(
			n_size_all = .N,
			n_size_hassler = sum(hassler, na.rm=TRUE),
			p_hassler = mean(hassler, na.rm=TRUE),
			mean_hassler_freq = mean(hassle_freq, na.rm=TRUE)
			),
		by = 'su_id'
	]
}

add_prefix <- function(dt, prefix) {
	if (prefix == "") {
		return(dt)
	}
	cols = setdiff(names(dt), 'su_id')
	setnames(dt, cols, paste0(prefix, cols))
	dt
}

summarize_with_prefix <- function(dt, prefix = "") {
	summary_dt = summarize_network_measures(dt)
	add_prefix(summary_dt, prefix)
}

compute_tie_proportions <- function(dt, vars, prefix = 'p_') {
	vars = intersect(vars, names(dt))
	if (length(vars) == 0) {
		return(NULL)
	}
	prop_dt = dt[
		,
		lapply(.SD, function(x) mean(x > 0, na.rm = TRUE)),
		by = 'su_id',
		.SDcols = vars
	]
	prop_cols = paste0(prefix, vars)
	setnames(prop_dt, vars, prop_cols)
	for (col in prop_cols) {
		prop_dt[is.nan(get(col)), (col) := NA_real_]
	}
	prop_dt
}

merge_by_suid <- function(tables) {
	tables = Filter(Negate(is.null), tables)
	if (length(tables) == 0) {
		return(NULL)
	}
	Reduce(function(left, right) merge(left, right, by = 'su_id', all = TRUE), tables)
}

compute_graph_metrics <- function(egor_obj, include_ego = FALSE) {

	results = lapply(seq_len(nrow(egor_obj$ego)), function(i) {
		g1 = egor_obj[i]
		graph_list = egor::as_igraph(g1, include.ego = include_ego)
		g = graph_list[[1]]

		if (igraph::vcount(g) == 0) {
			return(NULL)
		}

		# Create weighted graph from aaties
		aatie_data = g1$aatie[, c('.srcID', '.tgtID', 'net_pairs')]
		n_vertices = igraph::vcount(g)
		vertex_names = igraph::V(g)$name

		if (nrow(aatie_data) > 0) {
			g_weighted = igraph::graph_from_data_frame(aatie_data, vertices = data.frame(name = vertex_names))
			igraph::E(g_weighted)$weight = igraph::E(g_weighted)$net_pairs
			degree_weighted_raw = igraph::strength(g_weighted, mode = "total", weights = igraph::E(g_weighted)$weight, loops = FALSE)
			degree_weighted = degree_weighted_raw[vertex_names] / n_vertices

			between_raw = igraph::betweenness(g_weighted, normalized = TRUE, weights = igraph::E(g_weighted)$weight)
			between = between_raw[vertex_names]
		} else {
			degree_weighted = rep(NA_real_, n_vertices)
			between = rep(NA_real_, n_vertices)
		}

		data.frame(
			su_id = g1$ego$.egoID,
			person = igraph::V(g)$name,
			network_size = igraph::vcount(g),
			degree = igraph::degree(g),
			degree_weighted = degree_weighted,
			between = between
		)
	})
	results = Filter(Negate(is.null), results)
	if (length(results) == 0) {
		return(data.table(
			su_id = numeric(),
			person = character(),
			network_size = numeric(),
			degree = numeric(),
			degree_weighted = numeric(),
			between = numeric()
		))
	}
	rbindlist(results)
}


log_info('load baseline data')
df_egonet = import(snakemake@input$egonet)
setDT(df_egonet)
names(df_egonet) = tolower(names(df_egonet))

df_demo = import(snakemake@input$df_demo)
setDT(df_demo)
names(df_demo) = tolower(names(df_demo))

log_info('some variable cleanings ...')
df_egonet = df_egonet[person_count %in% c(92,96) == FALSE, ]

# multiplex network
for (generator in c('prob', 'health_count', 'social', 'hassle', 'health_talk')){
	df_egonet[get(generator) %in% c(92,96), (generator) := NA]
}

log_info("define multiplex network .... count the number of tie types for each ego")
df_egonet[, multiplex := rowSums(.SD, na.rm=TRUE), .SDcols = c('prob', 'health_count', 'social', 'hassle', 'health_talk')]
df_egonet[,table(multiplex)]

df_egonet[hassle_freq > 90,  hassle_freq := NA]
df_egonet[strength > 90, strength := NA]

log_info("define hassler only based on hassle frequency")
df_egonet[,table(hassle_freq)]

df_egonet[hassle_freq %in% c(0,1,2), hassler := 0]
df_egonet[hassle_freq %in% c(3), hassler := 1]

log_info('now define spouse, kin, and non-kin ties')
for (var in paste0('relationship_',c('parent','sibling','child','grandparent','grandchild','relative'))){
	df_egonet[get(var) > 90, (var) := NA]
}

df_egonet[, n_rel_partner := relationship_spouse+relationship_partner]
df_egonet[, n_rel_kin := rowSums(.SD, na.rm=TRUE), .SDcols = paste0('relationship_',c('parent','sibling','child','grandparent','grandchild','relative'))]
df_egonet[, n_rel_nonkin := rowSums(.SD, na.rm=TRUE), .SDcols = paste0('relationship_',c('friend','coworker','neighbor','roommate','churchmember','healthprov','other'))]

df_egonet[, rel_partner := ifelse(n_rel_partner > 0, 1, 0)]
df_egonet[, rel_kin := ifelse(n_rel_kin > 0, 1, 0)]
df_egonet[, rel_nonkin := ifelse(n_rel_nonkin > 0, 1, 0)]

log_info('define relationship_type and hassler_type')
df_egonet[, relationship_type := ifelse(rel_partner == 1, "partner/spouse", ifelse(rel_kin == 1, "kin", "non-kin"))]

df_egonet[, hassler_type := NA_integer_]
df_egonet[hassler == 0 & relationship_type == "partner/spouse", hassler_type := 1L]
df_egonet[hassler == 0 & relationship_type == "kin", hassler_type := 2L]
df_egonet[hassler == 0 & relationship_type == "non-kin", hassler_type := 3L]
df_egonet[hassler == 1 & relationship_type == "partner/spouse", hassler_type := 4L]
df_egonet[hassler == 1 & relationship_type == "kin", hassler_type := 5L]
df_egonet[hassler == 1 & relationship_type == "non-kin", hassler_type := 6L]

df_egonet[
  ,
  hassler_type := factor(
    hassler_type,
    levels = 1:6,
    labels = c("Partner Non-hassler", 'Kin Non-hassler', 'Non-kin Non-hassler',
    "Partner Hassler", "Kin Hassler", "Non-kin Hassler")
  )
]

log_info('Measure various network sizes...')

df_nsize_all = summarize_with_prefix(df_egonet)
df_nsize_kin = summarize_with_prefix(df_egonet[rel_kin == 1], 'k_')
df_nsize_nonkin = summarize_with_prefix(df_egonet[rel_nonkin == 1], 'nk_')
df_nsize_partner = summarize_with_prefix(df_egonet[rel_partner == 1], 'sp_')

log_info("merge network data with demo data to identify isolated cases ...")
df_nsize = merge_by_suid(list(
	df_demo[, .(su_id)],
	df_nsize_all,
	df_nsize_kin,
	df_nsize_nonkin,
	df_nsize_partner
))
setDT(df_nsize)

var_nsize = grep('n_size', names(df_nsize), value = TRUE)
for (var in var_nsize) {
	df_nsize[is.na(get(var)), (var) := 0]
	df_nsize[su_id %in% df_egonet[person_count == 92, su_id], (var) := NA]
}

log_info("measure hassler network positions")
df_aaties = import(snakemake@input$aaties)
names(df_aaties) = tolower(names(df_aaties))
setDT(df_aaties)

log_info("create alter-level data ...")
df_alters = df_egonet[, c('su_id','person',
	'prob','health_count','health_talk','social','hassle','strength',
	'sex','sex_other','race','education')]

log_info("only consider one tie for each pair ... ")
list_order = setdiff(sort(unique(df_alters$person)),c('91','92'))

df_aaties[, alter1_number := match(alter1, list_order)]
df_aaties[, alter2_number := match(alter2, list_order)]

df_aaties = df_aaties[alter1_number < alter2_number,]

log_info("drop missing NAs for pair-wise ties")
df_aaties[,table(net_pairs)] |> prop.table()
df_aaties = df_aaties[net_pairs %in% c(0,1,2,3), ]

log_info("create egoR objects")

df_ego = df_demo[, c('su_id')]

df_alters = df_egonet[, c('su_id','person')]

egor_1 <- egor(
	alters = df_alters[person %in% c(91,92)== FALSE,],
	egos = df_ego,
	aaties = df_aaties[net_pairs > 0,],
	ID.vars = list(
		ego = "su_id",
		alter = "person",
		source = "alter1",
		target = "alter2")
   )

log_info("Measure each alter's network positions ...")
df_const = compute_graph_metrics(egor_1, include_ego = FALSE)

log_info("add network measures ...")
df_const[, su_id := as.numeric(su_id)]
df_egonet_merged = merge(df_egonet, df_const, by = c('su_id','person'), all=TRUE)

log_info("combine all ego-level measures")

df_nsize[, su_id := as.numeric(su_id)]

log_info("save alter-level and ego-level network data")
saveRDS(df_egonet_merged, snakemake@output$df_egonetwork_alter)
saveRDS(df_nsize, snakemake@output$df_egonetwork)
