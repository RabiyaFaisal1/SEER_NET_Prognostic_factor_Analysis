#Step 1 — Polished KM plot: Stage
km_known_stage <- readRDS
library(survminer)

km_stage_plot <-
  ggsurvplot(km_known_stage,
                            data = df_known_stage,
                            pval = TRUE,
                            conf.int = TRUE,
                            risk.table = TRUE,
                            palette = c("#2E86AB", "#F6AE2D", "#F26419"),
                            legend.title = "Stage",
                            legend.labs = c("Localized", "Regional", "Distant"),
                            xlab = "Months since diagnosis",
                            ylab = "Survival probability",
                            title = "Kaplan-Meier Survival by Stage",
                            ggtheme = theme_minimal())

dir.create("outputs/figures", showWarnings = FALSE, recursive = TRUE)

png("outputs/figures/km_stage_final.png", width = 2000, height = 1600, res = 200)
print(km_stage_plot)
dev.off()  

#Step 2 — Polished KM plot: Site group
km_site_plot <- 
  ggsurvplot(km_site,
             data = df,
             pval = TRUE,
             conf.int = FALSE,
             risk.table = TRUE,
             legend.title = "Primary site",
             legend.labs = c("Appendix", "Colon", "Lung/Bronchus", "Other",
                             "Pancreas", "Rectum", "Small intestine",
                             "Stomach", "Unknown primary"),
             xlab = "Months since diagnosis",
             ylab = "Survival probability",
             title = "Kaplan-Meier Survival by Primary Site Group",
             ggtheme = theme_minimal())

png("outputs/figures/km_site_final.png", width = 2400, height = 1800, res = 200)
print(km_site_plot)
dev.off()

#Step 3 — Forest plot of the final Cox model's hazard ratios
library(broom)
label_map <- c(
  "summary_stage_2000_1998_2017Regional" = "Stage: Regional",
  "summary_stage_2000_1998_2017Distant" = "Stage: Distant",
  "site_groupColon" = "Site: Colon",
  "site_groupLung/Bronchus" = "Site: Lung/Bronchus",
  "site_groupOther" = "Site: Other",
  "site_groupPancreas" = "Site: Pancreas",
  "site_groupRectum" = "Site: Rectum",
  "site_groupSmall intestine" = "Site: Small intestine",
  "site_groupStomach" = "Site: Stomach",
  "sexMale" = "Sex: Male",
  "race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanicNon-Hispanic American Indian/Alaska Native" = "Race: AI/AN",
  "race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanicNon-Hispanic Asian or Pacific Islander" = "Race: Asian/PI",
  "race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanicNon-Hispanic Black" = "Race: Black",
  "race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanicNon-Hispanic Unknown Race" = "Race: Unknown*",
  "race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanicNon-Hispanic White" = "Race: White",
  "histology_factorCarcinoid tumor, NOS" = "Histology: Carcinoid tumor",
  "histology_factorComposite carcinoid" = "Histology: Composite carcinoid",
  "histology_factorGoblet cell carcinoid" = "Histology: Goblet cell carcinoid",
  "histology_factorNeuroendocrine carcinoma, NOS" = "Histology: Neuroendocrine carcinoma",
  "histology_factorOther rare NET subtype" = "Histology: Other rare subtype"
)

forest_data <- tidy(cox_final, exponentiate = TRUE, conf.int = TRUE) %>%
  mutate(term = recode(term, !!!label_map))

ggplot(forest_data, aes(x = estimate, y = reorder(term, estimate))) +
  geom_point(size = 3, color = "#2E86AB") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2, color = "#2E86AB") +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray40") +
  scale_x_log10() +
  labs(title = "Adjusted Hazard Ratios (Final Cox Model)",
       subtitle = "*Unknown Race treated with caution — likely a data-quality artifact",
       x = "Hazard Ratio (log scale)", y = NULL) +
  theme_minimal()

ggsave("outputs/figures/cox_forest_plot.png", width = 10, height = 9, dpi = 200)

#Step 4 — Table 1: Baseline characteristics summary

install.packages("gtsummary")
library(gtsummary)

df_known_stage <- df_known_stage %>%
  mutate(age_group_display = factor(age_group_v2,
                                    levels = c("00-09 years", "10-14 years", "15-19 years",
                                               "20-24 years", "25-29 years", "30-34 years",
                                               "35-39 years", "40-44 years", "45-49 years",
                                               "50-54 years", "55-59 years", "60-64 years",
                                               "65-69 years", "70-74 years", "75-79 years",
                                               "80-84 years", "85-89 years", "90+ years")))

table1 <- df_known_stage %>%
  select(summary_stage_2000_1998_2017, sex, age_group_display, site_group,
         race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic, histology_factor) %>%
  tbl_summary(by = summary_stage_2000_1998_2017,
              label = list(
                sex ~ "Sex",
                age_group_display ~ "Age group",
                site_group ~ "Primary site",
                race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic ~ "Race/ethnicity",
                histology_factor ~ "Histologic type"
              )) %>%
  add_overall() %>%
  add_p()

table1

#Step 5 — Consolidate & export everything, close out Phase 6
library(gt)
install.packages("webshot2")
library(webshot2)

table1 %>%
  as_gt() %>%
  gtsave("outputs/figures/table1_baseline_characteristics.png")

table1 %>%
  as_gt() %>%
  gtsave("outputs/table1_baseline_characteristics.html")

list.files("outputs/figures")


