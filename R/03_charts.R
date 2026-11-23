# Step 4: charts saved to outputs/
library(dplyr); library(tidyr); library(ggplot2)
retention <- read.csv("data/clean/retention.csv")

# Chart 1: graduation curves
curves <- retention %>%
  filter(group == "Total", cohort <= 2019) %>%
  select(cohort, starts_with("grad_")) %>%
  pivot_longer(-cohort, names_to = "year", values_to = "pct_graduated") %>%
  mutate(year = as.numeric(sub("grad_y", "", year))) %>%
  filter(!is.na(pct_graduated))

chart1 <- ggplot(curves, aes(x = year, y = pct_graduated, colour = factor(cohort))) +
  geom_line(linewidth = 1) + geom_point() +
  scale_x_continuous(breaks = 3:10) +
  labs(title = "How fast uOttawa first-year students graduate",
       x = "Years since starting", y = "% graduated (cumulative)", colour = "Started in") +
  theme_minimal()
ggsave("outputs/chart1_graduation_curves.png", chart1, width = 8, height = 5, bg = "white")

# Chart 2: coming back for year 2, domestic vs international
year2 <- retention %>% filter(group %in% c("Domestic", "International"))
chart2 <- ggplot(year2, aes(x = cohort, y = ret_y2, colour = group)) +
  geom_line(linewidth = 1) + geom_point() +
  scale_x_continuous(breaks = 2014:2023) +
  labs(title = "% of first-year students who came back for year 2",
       x = "Year they started", y = "% returned for year 2", colour = NULL) +
  theme_minimal()
ggsave("outputs/chart2_year2_retention.png", chart2, width = 8, height = 5, bg = "white")
