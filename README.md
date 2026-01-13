# Hassler Replication Package

Replication code for examining the association between network "hasslers" and biological aging.

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
