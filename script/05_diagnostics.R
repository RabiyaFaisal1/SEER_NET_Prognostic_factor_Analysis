#Step 1 — Testing the proportional hazards assumption
ph_test <- cox.zph(cox_multi)
ph_test

#Step 2 — Visualize Schoenfeld residuals for the four flagged variables
plot(ph_test, var = "summary_stage_2000_1998_2017")
plot(ph_test, var = "site_group")
plot(ph_test, var = "age_group_v2")
plot(ph_test, var = "factor(histologic_type_icd_o_3)")


cox_final <- coxph(Surv(survival_months, death_event) ~
                     summary_stage_2000_1998_2017 +
                     site_group +
                     strata(age_group_v2) +
                     sex +
                     race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic +
                     factor(histologic_type_icd_o_3),
                   data = df_known_stage)

summary(cox_final)

#Step 3 — Apply the remedy: stratify by Age
df <- df %>%
  mutate(histology_factor = factor(histologic_type_icd_o_3))

df_known_stage <- df %>%
  filter(summary_stage_2000_1998_2017 %in% c("Localized", "Regional", "Distant")) %>%
  droplevels()

cox_final <- coxph(Surv(survival_months, death_event) ~
                     summary_stage_2000_1998_2017 +
                     site_group +
                     strata(age_group_v2) +
                     sex +
                     race_and_origin_recode_nhw_nhb_nhaian_nhapi_hispanic +
                     histology_factor,
                   data = df_known_stage)

summary(cox_final)

#Step 4 — Final diagnostic write-up & export
dir.create("outputs", showWarnings = FALSE)

write_csv(as.data.frame(summary(cox_final)$coefficients), "outputs/cox_final_stratified_results.csv")
write_csv(as.data.frame(ph_test$table), "outputs/ph_assumption_test_results.csv")

saveRDS(cox_final, "data/cox_final_model.rds")
