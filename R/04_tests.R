# Step 5: two-proportion tests (is the gap real or chance?)
library(dplyr)
retention <- read.csv("data/clean/retention.csv")
row <- function(g, y) retention[retention$group == g & retention$cohort == y, ]

# Test A: year-2 return, international vs domestic, 2023
intl <- row("International", 2023); dom <- row("Domestic", 2023)
came_back <- round(c(intl$ret_y2, dom$ret_y2) / 100 * c(intl$students, dom$students))
print(came_back)
print(prop.test(came_back, c(intl$students, dom$students)))

# Test B: 6-year graduation, female vs male, 2018
f <- row("Female", 2018); m <- row("Male", 2018)
graduated <- round(c(f$grad_y6, m$grad_y6) / 100 * c(f$students, m$students))
print(graduated)
print(prop.test(graduated, c(f$students, m$students)))
