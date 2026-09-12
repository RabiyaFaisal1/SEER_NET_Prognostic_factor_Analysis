#Step 1 — Build the survival object and fit the overall KM curve
surv_obj <- Surv(time = df$survival_months, event = df$death_event)

km_overall <- survfit(surv_obj ~ 1, data = df)
summary(km_overall)$table

#Step 2 — Plot the overall KM curve
ggsurvplot(km_overall,
           data = df,
           conf.int = TRUE,
           risk.table = TRUE,
           surv.median.line = "hv",
           xlab = "Months since Dignosis" ,
           ylab = "Survival Probability",
           title = "Overall Kaplan-Meier Survival Curve (NET patients)"
             )

#Step 3 — Kaplan-Meier stratified by Stage + log-rank test
km_stage <- surv_fit(surv_obj ~ summary_stage_2000_1998_2017 ,data= df)
summary(km_stage) $table
#log-rank test
 survdiff(surv_obj ~ summary_stage_2000_1998_2017 ,data= df)

#Step 4 — Plot KM curves by Stage (known-stage patients only)
df_known_stage <- df %>%
   filter(summary_stage_2000_1998_2017 %in% c("Localized", "Regional", "Distant")) %>%
   droplevels()
 
km_known_stage <- survfit(Surv(survival_months, death_event) ~ summary_stage_2000_1998_2017, 
                           data = df_known_stage)

ggsurvplot(km_known_stage,
           data = df_known_stage,
           conf.int = TRUE,
           risk.table = TRUE,
           pval = TRUE,
           xlab = "Months since Diagnosis",
           ylab = "Survival Probability",
           legend.title = "stage",
           title = "Kaplan-Meier Survival by Stage (Localized/Regional/Distant)"
           )

#Step 5 — Kaplan-Meier stratified by Site group + log-rank test
km_site <- survfit(surv_obj ~ site_group, data = df)
summary(km_site)$table

survdiff(surv_obj ~ site_group, data = df)

#Step 6 — Plot KM curves by Site group
ggsurvplot(km_site,
           data = df,
           pval = TRUE,
           conf.int = TRUE,
           risk.table = TRUE,
           xlab = "Months since Diagnosis",
           ylab = "Survival Probability",
           legend.title = "primary site",
           legend = "right",
           title = "Kaplan-Meier Survival by Primary Site Group"
           )

#Step 7 — Consolidate & save Phase 3 outputs
dir.create("outputs", showWarnings = FALSE)

write_csv(as.data.frame(summary(km_stage)$table), "outputs/km_median_by_stage_all5.csv")
write_csv(as.data.frame(summary(km_known_stage)$table), "outputs/km_median_by_stage_known3.csv")
write_csv(as.data.frame(summary(km_site)$table), "outputs/km_median_by_site.csv")

saveRDS(df_known_stage, "data/df_known_stage.rds")
