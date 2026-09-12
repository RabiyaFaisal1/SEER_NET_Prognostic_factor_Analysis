
#Step 2 — Install and load packages
library(tidyverse)   # data wrangling + plotting
library(survival)    # core survival analysis functions 
library(survminer)   # nicer Kaplan-Meier plots 
library(janitor)   #tidying column headers

#Step 3 — Importing csv, using clean_names() and inspecting columns
df <- read.csv("data/export.csv") %>% 
  clean_names()
glimpse(df)

#Step 4 — Inspect every categorical variable's actual values
df %>% count(sex)
df %>% count(summary_stage_2000_1998_2017)
df %>% count(vital_status_recode_study_cutoff_used)
df %>% count(age_recode_with_1_year_olds_and_90)
df %>% count(race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic)
df %>% count(histologic_type_icd_o_3)
n_distinct(df$primary_site_labeled)
sum(df$survival_months == "Unknown")
#step 5
df <- df %>%
  filter(survival_months != "Unknown") %>%
mutate(
  survival_months = as.numeric(survival_months),
  death_event = ifelse(vital_status_recode_study_cutoff_used == "Dead", 1,0)
)
glimpse(df)

#Step 6 Converting categorical variables to proper factors & recoding histology
df <- df %>%
  mutate(
    sex = factor(sex),
    vital_status_recode_study_cutoff_used = factor(vital_status_recode_study_cutoff_used),
    race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic = factor(race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic),
    age_recode_with_1_year_olds_and_90 = factor(age_recode_with_1_year_olds_and_90, ordered = TRUE),
    summary_stage_2000_1998_2017 = factor(summary_stage_2000_1998_2017 ,
    levels= c("Localized", "Regional","Distant", "Unknown/unstaged","Blank(s)")),
 histologic_type_icd_o_3 = case_when(
   histologic_type_icd_o_3 == 8240 ~ "Carcinoid tumor, NOS",
   histologic_type_icd_o_3 == 8246 ~ "Neuroendocrine carcinoma, NOS",
   histologic_type_icd_o_3 == 8243 ~ "Goblet cell carcinoid",
   histologic_type_icd_o_3 == 8244 ~ "Composite carcinoid",
   histologic_type_icd_o_3 == 8245 ~ "Adenocarcinoid tumor",
   TRUE ~ "Other rare NET subtype" #collapses 8241 (n=62) and 8242 (n=8)
  ) %>% factor()
    )
glimpse(df)

# Step 7 — Looking at Primary Site before deciding how to group it
df %>%
  count(primary_site_labeled, sort = TRUE) %>%
  slice_head (n= 30)
#Step 8 — Group Primary Site into organ systems
df <- df %>%
  mutate(
    site_lower = str_to_lower(primary_site_labeled),
    site_group = case_when(
      str_detect(site_lower, "appendix") ~ "Appendix",
      str_detect(site_lower, "rectum|rectosigmoid") ~ "Rectum",
      str_detect(site_lower, "colon|cecum") ~ "Colon",
      str_detect(site_lower, "ileum|duodenum|jejunum|small intestine") ~ "Small intestine",
      str_detect(site_lower, "pancreas") ~ "Pancreas",
      str_detect(site_lower, "lung|bronchus") ~ "Lung/Bronchus",
      str_detect(site_lower, "stomach|cardia|antrum|fundus") ~ "Stomach",
      str_detect(site_lower, "unknown primary") ~ "Unknown primary",
      TRUE ~ "Other"
    ) %>% factor(),
    site_lower = NULL # drop the helper column, we don't need it anymore
      )
df %>% count(site_group, sort = TRUE)

#Step 9 — Save a cleaned-data checkpoint
saveRDS(df, "data/cleaned_NET_Data.rds")