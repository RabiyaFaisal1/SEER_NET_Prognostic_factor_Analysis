#Step 1 — Descriptive stats for the continuous variables
library(tidyverse)
library(psych)

df <- readRDS("data/cleaned_NET_Data.rds")

# Mean, median, SD, skew, kurtosis
describe(df$year_of_diagnosis)
describe(df$survival_months)

# Variance and IQR
var(df$year_of_diagnosis)
var(df$survival_months)

IQR(df$year_of_diagnosis)
IQR(df$survival_months)

#Step 2 — Frequency tables & proportions for categorical variables
library(janitor)
df  %>% tabyl(sex)
df %>% tabyl(summary_stage_2000_1998_2017)
df %>% tabyl(vital_status_recode_study_cutoff_used)
df %>% tabyl(race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic)
df %>% tabyl(histologic_type_icd_o_3)
df %>% tabyl(site_group)
df %>% tabyl(age_recode_with_1_year_olds_and_90)

#Step 3 — Univariate visualizations

# Bar chart: Site group, ordered by frequency
df %>%
  ggplot(aes(x= fct_infreq(site_group))) +
  geom_bar(fill = "steelblue") +
  coord_flip() +
  labs (title = "Patient Count by Primary Site Group", x = NULL, y= "Number of Patients")

# Bar chart: Stage
df %>%
  ggplot(aes(x = summary_stage_2000_1998_2017))+
  geom_bar(fill = "darkorange") +
  labs(title = "Patient Count by Summary Stage", x = NULL, y = "Number of Patients")

# Histogram + density: Survival months (our key skewed variable)
df %>%
  ggplot(aes(x = survival_months)) +
  geom_histogram(aes(y = after_stat(density)), bins = 40, fill = "grey7", color = 'white') +
  geom_density(color = "firebrick", linewidth = 1 )+
  labs(title = "Distribution of Survival Months", x = "Survival Months", y = "Density")

#Step 4 — Bivariate contingency tables + chi-square
tab_sex_stage <- table(df$sex, df$summary_stage_2000_1998_2017)
tab_sex_stage
chisq.test(tab_sex_stage)

tab_site_stage <- table(df$site_group, df$summary_stage_2000_1998_2017)
tab_site_stage
chisq.test(tab_site_stage)

tab_race_stage <- table(df$race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic, df$summary_stage_2000_1998_2017)
tab_race_stage
chisq.test(tab_race_stage)

#Step 5 — Mosaic plot & heatmap

# Mosaic plot: Site group vs Stage
mosaicplot(tab_site_stage, main = "Site Group vs Summary Stage" , color = TRUE, las = 2, cex.axis = 0.6)

# Heatmap: Race vs Stage, restricted to known-stage patient
df %>%
  filter(summary_stage_2000_1998_2017 %in% c("Localized", "Regional", "Distant")) %>% 
  count(race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic, summary_stage_2000_1998_2017) %>%
  group_by(race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic) %>%
  mutate(pct = n/sum(n)) %>%
  ggplot(aes(x = summary_stage_2000_1998_2017,
             y = race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic,
             fill = pct)) +
  geom_tile() +
  geom_text(aes(label = scales::percent(pct, accuracy = 1)), color = 'white') +
  scale_fill_viridis_c() +
  labs(title = "Stage Distribution by Race (Known Stage Only)", x ="Stage", y = NULL, fill = "% within race")
 
#Step 6 — Year of diagnosis: ANOVA + correlation
anova_site <- aov(year_of_diagnosis ~ site_group, data = df)
summary(anova_site)

cor(df$year_of_diagnosis, df$survival_months, method= "pearson")

#Step 7 — Consolidate & export summary tables
dir.create("outputs", showWarnings = FALSE)
write.csv(df %>%tabyl(summary_stage_2000_1998_2017), "outputs/summary_stage.csv")
write.csv(df%>% tabyl(site_group), "outputs/summary_site.csv")
write_csv(df %>% tabyl(race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic), "outputs/summary_race.csv")
write_csv(df %>% tabyl(histologic_type_icd_o_3), "outputs/summary_histology.csv")
