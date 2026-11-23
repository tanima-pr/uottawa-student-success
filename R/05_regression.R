# Step 6: logistic regression across all cohorts
library(dplyr)
retention <- read.csv("data/clean/retention.csv")

# Model 1: coming back for year 2 ~ international/domestic + start year
m1_data <- retention %>%
  filter(group %in% c("Domestic", "International")) %>%
  mutate(came_back = round(ret_y2 / 100 * students),
         left      = students - came_back,
         group     = relevel(factor(group), ref = "Domestic"),
         years_since_2014 = cohort - 2014)
model1 <- glm(cbind(came_back, left) ~ group + years_since_2014, family = binomial, data = m1_data)
print(summary(model1))
print(round(exp(cbind(odds_ratio = coef(model1), confint.default(model1))), 3))

# Robustness check: residual deviance (99.7) is much larger than df (17), so allow extra variation
model1b <- glm(cbind(came_back, left) ~ group + years_since_2014, family = quasibinomial, data = m1_data)
print(summary(model1b))

# Model 2: graduated within 6 years ~ female/male + start year (2014-2018)
m2_data <- retention %>%
  filter(group %in% c("Female", "Male"), !is.na(grad_y6)) %>%
  mutate(graduated = round(grad_y6 / 100 * students),
         not_yet   = students - graduated,
         group     = relevel(factor(group), ref = "Male"),
         years_since_2014 = cohort - 2014)
model2 <- glm(cbind(graduated, not_yet) ~ group + years_since_2014, family = binomial, data = m2_data)
print(summary(model2))
print(round(exp(cbind(odds_ratio = coef(model2), confint.default(model2))), 3))
