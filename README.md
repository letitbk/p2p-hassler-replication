# Replication Code for Hassler and Biological Aging Analysis

Replication code for examining the association between network "hasslers" and biological aging.

**Paper:** Lee, Byungkyu, Gabriele Ciciurkaite, Siyun Peng, Colter Mitchell, and Brea L. Perry. 2025. "Negative Social Ties as Emerging Risk Factors for Accelerated Aging, Inflammation, and Multimorbidity." 2025.05.23.25328261.

- paper URL: https://www.medrxiv.org/content/10.1101/2025.05.23.25328261v3

## Data Access

Data from the **P2P Health Interview Study** (restricted access).

- **Homepage**: https://irsay.iu.edu/tools-resources/data-resources/p2p-health-interview-study/
- **Contact**: Brea Perry (blperry@iu.edu)
- **Expected public release**: Summer 2026

## Requirements

### Software
- R (>= 4.0)
- Stata (>= 17)
- Python (>= 3.8) with Snakemake

### R Packages
```r
install.packages(c(
  "data.table", "ggplot2", "rio", "haven", "stringr",
  "marginaleffects", "survey", "ggsci", "cowplot",
  "comorbidity", "egor", "igraph", "logger"
))
```

### Stata Packages
```stata
ssc install estout
ssc install konfound
```

## Setup

1. Clone repository
2. Copy config templates:
   ```bash
   cp code/config_paths.R.template code/config_paths.R
   cp code/config_paths.do.template code/config_paths.do
   ```
3. Edit config files with your data paths
4. **Configure Snakemake paths**: Edit the path variables at the top of:
   - `code/Snakefile` - Set `CLEANED_DATA` to your processed data location
   - `code/1_data-cleaning/run_data_cleaning.smk` - Set `dir_data_raw`, `dir_project`, `dir_data_clock`, etc.
   - `code/2_analysis/run_hassler.smk` - Set `STATA`, `dir_data_raw`, `dir_project`, etc.

## Usage

Run complete pipeline:
```bash
cd code
snakemake --cores 4
```

Or run individual scripts:
```bash
Rscript code/2_analysis/01_figure-1-clockdist_by_age_boxplot.R
stata -b do code/2_analysis/01_table-s1-analysis.do
```

## Structure

```
hassler/
├── code/
│   ├── config_paths.R.template   # R path config template
│   ├── config_paths.do.template  # Stata path config template
│   ├── Snakefile                 # Master pipeline
│   ├── 1_data-cleaning/          # Data cleaning scripts
│   └── 2_analysis/               # Analysis scripts
└── output/                       # Generated figures and tables
```

## Output

All figures and tables are generated in `output/`:
- `figure_*.png` - Manuscript figures
- `table_*.csv` - Regression results and summary statistics

## Contact

- Code: BK Lee (bklee@nyu.edu)
- Data: Brea Perry (blperry@iu.edu)
