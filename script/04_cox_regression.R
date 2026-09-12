#Step 1 — Univariate Cox models

# Stage — using df_known_stage, since Stage requires known values
summary(coxph(Surv(survival_months, death_event) ~ summary_stage_2000_1998_2017, data = df_known_stage))
# Site — Using Df
summary(coxph(Surv(survival_months, death_event) ~ site_group, data = df))
#Sex — Using Df
summary(coxph(Surv(survival_months, death_event) ~ sex, data = df))
#Race — Using Df
summary(coxph(Surv(survival_months, death_event) ~ race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic, data = df))
#Age — Using Df
summary(coxph(Surv(survival_months, death_event) ~ factor(age_recode_with_1_year_olds_and_90, ordered = FALSE), data = df))
#Histology — Using Df
summary(coxph(Surv(survival_months, death_event) ~ factor(histologic_type_icd_o_3), data = df))

#fixing age for sensible and well-populated reference
df <- df %>%
  mutate(age_group = relevel(factor(age_recode_with_1_year_olds_and_90, ordered = FALSE),
                             ref = "50-54 years"))
#Redoing Univeriate Cox Model for Age — Using Df
summary(coxph(Surv(survival_months, death_event) ~ factor(age_group, ordered = FALSE), data = df))
#Putting age_group in df_known_stage for multivariate Cox Model
df_known_stage <- df %>% 
  filter(summary_stage_2000_1998_2017 %in% c("Localized", "Regional", "Distant")) %>%
  droplevels()

#Step 2 — Multivariate Cox model
cox_multi <- coxph(Surv(survival_months, death_event) ~
                     summary_stage_2000_1998_2017 +
                     site_group +
                     age_group + 
                     sex + 
                     race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic +
                     factor(histologic_type_icd_o_3),
                   data = df_known_stage)
summary(cox_multi)

#Fixing the sparse young-age bands and then re-running model to reduce error
df <- df %>%
  mutate(age_group_v2 = fct_collapse(age_group,
                                     "00-09 years" = c("00 years", "01-04 years", "05-09 years")),
         age_group_v2 = relevel(age_group_v2, ref = "50-54 years"))

df_known_stage <- df %>%
  filter(summary_stage_2000_1998_2017 %in% c("Localized", "Regional", "Distant")) %>%
  droplevels()

cox_multi <- coxph(Surv(survival_months, death_event) ~
                     summary_stage_2000_1998_2017 +
                     site_group +
                     age_group_v2 +
                     sex +
                     race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic +
                     factor(histologic_type_icd_o_3),
                   data = df_known_stage)
summary(cox_multi)

#Step 3 — Isolating Age's confounding effect on Stage specifically
cox_stage_only <- coxph(Surv(survival_months, death_event) ~ summary_stage_2000_1998_2017, 
                        data = df_known_stage)
cox_stage_age <- coxph(Surv(survival_months, death_event) ~ summary_stage_2000_1998_2017 + age_group_v2, 
                       data = df_known_stage)

summary(cox_stage_only)$coefficients
summary(cox_stage_age)$coefficients

#Step 4 — Naive logistic regression vs. Cox (the censoring-impact demonstration)
logit_naive <- glm(death_event ~ summary_stage_2000_1998_2017 +
                     age_group_v2 +
                     site_group +
                     sex +
                     race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic +
                     factor(histologic_type_icd_o_3),
                   data = df_known_stage, family = binomial)
summary(logit_naive)$coefficients
exp(coef(logit_naive))

#Step 5 — Consolidate & export Phase 4 outputs

dir.create("outputs", showWarnings = FALSE)

write_csv(as.data.frame(summary(cox_multi)$coefficients), "outputs/cox_multivariate_results.csv")
write_csv(as.data.frame(summary(logit_naive)$coefficients), "outputs/logistic_naive_results.csv")

saveRDS(cox_multi, "data/cox_multi_model.rds")
saveRDS(logit_naive, "data/logit_naive_model.rds")

