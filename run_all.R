# Runs the whole project from start to finish.
# Open R in this folder and type: source("run_all.R")
for (f in c("R/01_read_retention.R", "R/02_check_data.R", "R/03_charts.R",
            "R/04_tests.R", "R/05_regression.R")) {
  cat("\n=====", f, "=====\n")
  source(f, echo = FALSE)
}
