# Neuroendocrine Tumour Survival and Prognostic Factor Analysis
### A Statistical Investigation Using SEER Data

![Status](https://img.shields.io/badge/Status-Completed-success)
![R](https://img.shields.io/badge/R-4.5.2-276DC3?logo=r)
![Data](https://img.shields.io/badge/Data-SEER%20NCI-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)


<img width="2000" height="1600" alt="km_stage_final" src="https://github.com/user-attachments/assets/cefb0e45-0025-4e8f-bf49-1804d79ce646" />


*Figure: Overall survival by stage at diagnosis. Median survival: 242 months (Localized) vs. 130 months (Regional) vs. 12 months (Distant).*

---

> Can where a tumour starts — and how early it's caught — predict how long a patient survives? This project answers that question using 142,803 real patient records from the U.S. National Cancer Institute's SEER registry, applying survival analysis methods (Kaplan-Meier, Cox proportional hazards regression) to neuroendocrine tumours (NETs) — a rare, understudied cancer type sitting at the intersection of neuroscience, oncology, and rare-disease research.


---

## 📋 Table of Contents

- [Overview](#overview)
- [Dataset](#dataset)
- [Methods](#methods)
- [Key Findings](#key-findings)
- [Model Diagnostics & Limitations](#model-diagnostics--limitations)
- [Repository Structure](#repository-structure)
- [Tools & Packages](#tools--packages)
- [Author](#author)

---

## Overview

Neuroendocrine tumours (NETs) arise from cells that share properties of both nerve cells and hormone-producing cells, and can occur almost anywhere in the body — from the lungs to the pancreas to the small intestine. They are rare, biologically diverse, and — critically for this project — almost never the subject of undergraduate research portfolios, despite the availability of high-quality open population data.

This project builds a complete, reproducible survival-analysis pipeline in R, answering two linked research questions:

1. **Do tumour site and stage at diagnosis predict overall survival in NET patients?**
2. **Does patient age confound the relationship between stage and survival** — and more broadly, how much does adjusting for age, sex, race, and histologic subtype change the crude, unadjusted picture?

Along the way, the project also deliberately demonstrates *why* proper survival-analysis methods matter, by directly comparing Cox regression (which correctly handles censored patients) against a naive logistic regression (which does not) — using the project's own data as the evidence.

---

## Dataset

**Source:** [SEER Program](https://seer.cancer.gov) (Surveillance, Epidemiology, and End Results), National Cancer Institute, USA.

**Database:** *Incidence – SEER Research Data, 17 Registries, Nov 2025 Sub (2000–2023)*, released April 2026, based on the November 2025 submission.

**Full citation:**
> Surveillance, Epidemiology, and End Results (SEER) Program (www.seer.cancer.gov) SEER*Stat Database: Incidence – SEER Research Data, 17 Registries, Nov 2025 Sub (2000–2023), National Cancer Institute, DCCPS, Surveillance Research Program, released April 2026, based on the November 2025 submission.

**Cohort definition:** All records with Histologic Type (ICD-O-3) codes 8240–8246 — the standard morphology range for neuroendocrine tumours (carcinoid tumour, enterochromaffin cell carcinoid, goblet cell carcinoid, composite carcinoid, adenocarcinoid tumour, and neuroendocrine carcinoma).

**Size:** 142,803 patient records exported via SEER\*Stat (v9.0.43), reduced to **142,420** after removing 383 records (0.27%) with an undocumented survival time.

**Variables (9):**

| Variable | Description |
|---|---|
| Age recode | 20 pre-binned age bands (00 → 90+ years) |
| Sex | Male / Female |
| Year of diagnosis | 2000–2023 |
| Primary Site | Raw ICD-10-style site label (228 distinct values → grouped into 9 organ-system categories for analysis) |
| Histologic Type (ICD-O-3) | 8240–8246, recoded to readable subtype names |
| Summary Stage | Localized / Regional / Distant / Unknown / Blank |
| Survival months | Follow-up time from diagnosis |
| Vital Status | Dead / Alive (used to build the death event indicator) |
| Race and origin | 6-category recode (NHW, NHB, NHAIAN, NHAPI, Hispanic, Unknown) |

Access was obtained via SEER's public researcher registration process (no cost, no patient identifiers, standard academic-use agreement); no protected health information is included anywhere in this repository.

<img width="2760" height="2480" alt="seer_nets_cohort_flow" src="https://github.com/user-attachments/assets/2924afa8-d283-4f1e-8078-ceba7748c79a" />

---

## How the Data Was Obtained

1. Registered at seer.cancer.gov/data-software via the "SEER Incidence Data 1975–2023" request form, providing institutional affiliation (University of the Punjab) and a stated research purpose.
2. Accepted the SEER Acknowledgment of Treatment Data Limitations and the Data Use Agreement Certification.
3. Received SEER*Stat account credentials, then downloaded and installed SEER*Stat v9.0.43.
4. Opened a Case Listing session and selected the Incidence – SEER Research Data, 17 Registries, Nov 2025 Sub (2000–2023) database.
5. In the Selection tab, filtered to Histologic Type (ICD-O-3) codes 8240–8246 (the NET morphology range).
6. In the Table tab, added the 9 variables used in this analysis to the column output.
7. Executed the query (accepting SEER's standard warnings about staging and race-coding conventions) and exported the result as CSV, with variable names as column headers — producing the raw export.csv (142,803 rows) used as the starting point for Phase 1.

## Methods

The analysis was carried out in six sequential, fully scripted phases. Each script is self-contained and reproducible from the last — running `01` through `06` in order regenerates the entire analysis from the raw export.

### Phase 1 — Data Cleaning (`01_data_cleaning.R`)
Imported the raw export, removed the 383 records with unusable survival time, converted all categorical variables to proper factors, recoded numeric histology codes to readable subtype labels (collapsing two ultra-rare subtypes, n=62 and n=8, into a single "Other rare NET subtype" category), and consolidated the 228 raw site labels into 9 clinically meaningful organ-system groups (Appendix, Colon, Lung/Bronchus, Pancreas, Rectum, Small intestine, Stomach, Unknown primary, Other).

### Phase 2 — Exploratory Data Analysis (`02_eda.R`)
Descriptive statistics, frequency tables, univariate visualizations, bivariate contingency tables with chi-square tests (Sex×Stage, Site×Stage, Race×Stage), a mosaic plot and heatmap, and an ANOVA/Pearson correlation check on Year of diagnosis.


<img width="648" height="423" alt="Eda_Mosaic_plot_Site group_vs_Stage" src="https://github.com/user-attachments/assets/e2aaf893-fb1f-4345-898e-59419afb448b" />


*Figure: Mosaic Plot of site vs stage in explanatory data analysis.*


### Phase 3 — Kaplan-Meier Survival Analysis (`03_kaplan_meier.R`)
Built the survival object (time + censoring indicator), fit the overall Kaplan-Meier curve, then stratified curves by Stage and by Site group, each with a log-rank test for group differences.


<img width="622" height="454" alt="Overall_Kaplan–Meier_survival_curve " src="https://github.com/user-attachments/assets/bc2b5a61-8b3d-4f11-a838-483af79211bf" />


*Figure: Overall Kaplan-Meier Survival Curve from phase 3.*


### Phase 4 — Cox Proportional Hazards Modelling (`04_cox_regression.R`)
Univariate Cox models screening each predictor individually, followed by a multivariate model combining Stage, Site, Age, Sex, Race, and Histology. Isolated Age's specific confounding contribution to Stage's effect, and directly compared the Cox model's hazard ratios against a naive logistic regression fit on the same predictors — demonstrating the practical consequence of ignoring censoring.


<img width="2000" height="1800" alt="cox_forest_plot" src="https://github.com/user-attachments/assets/5f891bf3-5cfa-48de-bd38-4b26b0631449" />


*Figure: Cox Forest Plot generated from phase 6.*


### Phase 5 — Model Diagnostics (`05_diagnostics.R`)
Tested the proportional hazards assumption via Schoenfeld residuals (`cox.zph`). Age showed a clear, interpretable violation and was addressed by stratification in the final model; Stage, Site, and Histology also showed statistically significant departures (expected given the large sample size), documented as a stated limitation rather than corrected structurally.


<img width="509" height="438" alt="Schoenfeld_residuals_age" src="https://github.com/user-attachments/assets/45f7ba06-9910-43f2-9068-dac425e180ae" />


*Figure: Schoenfeld residuals for Flagged Variable age.*


### Phase 6 — Final Visualization & Polish (`06_visualization.R`)
Publication-style Kaplan-Meier plots for Stage and Site, a forest plot of the final model's adjusted hazard ratios, and a baseline-characteristics summary table ("Table 1") stratified by Stage.


<img width="2400" height="1800" alt="km_site_final" src="https://github.com/user-attachments/assets/d889cc25-81c6-4ed9-b3b0-2b5950f7100b" />


*Figure: Polished KM plot: Site group.*
---

## Key Findings

### 1. Survival differs enormously by stage at diagnosis
Median overall survival: **242 months (Localized)** vs. **130 months (Regional)** vs. **12 months (Distant)** — roughly a **20-fold difference** between the best- and worst-prognosis groups, confirmed by a highly significant log-rank test (χ²=31,505, p<0.0001).

### 2. Where the tumour starts strongly predicts how early it's caught
**Rectal NETs are diagnosed at Localized stage 93.4% of the time; Pancreatic NETs only 38.9% of the time.** This single relationship — driven by differences in symptom visibility and screening availability across organs — underlies much of the site-based survival gap seen throughout the analysis.

### 3. The adjusted (Cox) model confirms Stage and Site as the dominant predictors
In the final, PH-corrected multivariate model: **Distant stage HR = 4.33** (95% CI 4.21–4.44) relative to Localized; Lung/Bronchus and "Other" sites carried roughly 1.9× the hazard of Appendix (the best-prognosis site). Several crude associations that looked strong on their own — Rectum's apparent survival advantage, the observed Race gap, and Histologic subtype's raw effect — **shrank to near-null once properly adjusted for Stage, Site, and Age**, demonstrating that these were substantially confounded relationships, not independent effects.

### 4. Age explains part, but not all, of Stage's crude effect
Adjusting for age alone reduced Distant stage's hazard ratio from 6.44 (unadjusted) to 5.65 — accounting for roughly a third of the total reduction seen once every covariate was included (final adjusted HR: 4.33). The remainder reflects the combined influence of site, sex, race, and histology.

### 5. Ignoring censoring meaningfully distorts results
A naive logistic regression (dead/alive only, ignoring follow-up time) produced systematically more extreme estimates than the Cox model across every covariate tested — most dramatically for age (**Cox HR 8.23 vs. logistic OR 90.45** for the 90+ age group). This is a direct, data-driven demonstration of why time-to-event methods are necessary for survival data rather than simple binary outcome models.

### 6. "Unknown primary site" is the single worst prognostic group
Median survival of just 9 months (univariate HR = 9.08 vs. Appendix) — worse than any known site, and clinically consistent with the fact that an undetermined primary is usually a marker of advanced, widely spread disease. This group could not be evaluated in the multivariate model, since every Unknown-primary patient also had missing Stage data — a structural limitation documented explicitly below.

---

## Model Diagnostics & Limitations

- **Missing stage data:** ~45% of records have no recorded Summary Stage (Blank or Unknown/unstaged). The primary Stage-based analyses use only the Localized/Regional/Distant subset (n=78,314); the excluded categories were examined separately and did not follow the expected clinical severity gradient, consistent with being data-quality artifacts rather than a fourth clinical stage.
- **Proportional hazards assumption:** Tested via Schoenfeld residuals. Age showed clear time-dependence and was handled through stratification in the final model (at the cost of losing an explicit age hazard ratio and reducing model concordance from 0.812 to 0.759). Stage, Site, and Histologic type also showed statistically significant departures from proportional hazards — given the very large sample size, these tests are highly sensitive to small deviations; diagnostic plots did not provide equally strong visual evidence of substantial non-proportionality across all three, so their hazard ratios are interpreted as average effects over the follow-up period rather than constant instantaneous effects.
- **"Non-Hispanic Unknown Race" category:** Consistently behaved anomalously across multiple independent analyses (unusually high localized-stage rate, unusually low adjusted hazard ratio) despite its small size (n≈2,000). Treated throughout as a likely administrative/data-quality artifact, not a genuine biological or demographic finding.
- **Observational data:** All associations reported here are observational, not causal. In particular, race-based findings should be interpreted with care — they may reflect a combination of biological, socioeconomic, and healthcare-access factors not captured by this dataset, and are not to be read as evidence of an inherent causal effect of race itself.
- **Follow-up time varies by diagnosis year:** Patients diagnosed later in the study period have mechanically shorter possible follow-up, which limits the interpretability of any Year-of-diagnosis correlation (addressed explicitly in Phase 2).

---

## Repository Structure

```
├── data/
│   ├── export.csv                       # Raw SEER export
│   ├── cleaned_NET_Data.rds             # Phase 1 checkpoint
│   ├── df_known_stage.rds               # Known-stage subset
│   └── cox_*_model.rds                  # Saved fitted models
├── scripts/
│   ├── 01_data_cleaning.R
│   ├── 02_eda.R
│   ├── 03_kaplan_meier.R
│   ├── 04_cox_regression.R
│   ├── 05_diagnostics.R
│   └── 06_visualization.R
├── outputs/
│   ├── *.csv                            # Summary tables, model results
│   └── figures/
│       ├── km_stage_final.png
│       ├── km_site_final.png
│       ├── cox_forest_plot.png
│       └── table1_baseline_characteristics.png
└── README.md
```

---

## Tools & Packages

**R** (v4.5.2) with `tidyverse`, `survival`, `survminer`, `janitor`, `psych`, `broom`, and `gtsummary`.

**Dependencies:** See `requirements.txt` for the full R package list.

---

## Author

**Rabiya Faisal** — Final-year BS Biotechnology student, University of the Punjab, Lahore, Pakistan, transitioning into data analytics.

Data obtained with academic affiliation via SEER's public researcher registration process. This project is intended as a portfolio demonstration of applied survival-analysis methods, and is structured to be extensible into undergraduate research, a conference poster, or a student journal submission.

**License:** MIT License (see `LICENSE` file).
