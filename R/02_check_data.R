# Step 3: data-quality checks; every rule must print TRUE
library(dplyr)
retention <- read.csv("data/clean/retention.csv")

# Check 1: subgroups add up to Total
students <- function(g) retention$students[retention$group == g]
check1 <- all(students("Female") + students("Male") <= students("Total"))
gender_gap <- data.frame(cohort = 2014:2023,
                         not_female_or_male = students("Total") - students("Female") - students("Male"))
check2 <- all(students("International") + students("Domestic") == students("Total"))
check3 <- all(students("In-province high school") + students("Out-of-province HS and Others") == students("Total"))

# Check 2: every percentage is between 0 and 100
pct <- retention %>% select(starts_with("ret_"), starts_with("grad_"))
check4 <- all(pct >= 0 & pct <= 100, na.rm = TRUE)

# Check 3: graduation never goes down over time
grad <- retention %>% select(grad_y3, grad_y4, grad_y5, grad_y6, grad_y7, grad_y8, grad_y9, grad_y10)
check5 <- all(apply(grad, 1, function(r) { r <- r[!is.na(r)]; all(diff(r) >= 0) }))

# Check 4: 7 groups x 10 cohorts
check6 <- nrow(retention) == 70 && all(table(retention$group) == 10)

results <- c("Female + Male <= Total" = check1,
             "International + Domestic = Total" = check2,
             "In-province + Out-of-province = Total" = check3,
             "All % between 0 and 100" = check4,
             "Graduation never goes down" = check5,
             "7 groups x 10 cohorts" = check6)
print(results)
print(gender_gap)
