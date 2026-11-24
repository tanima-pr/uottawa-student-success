/* Replicates R Model 1 (R/05_regression.R) in SAS.
   Run in SAS Studio (SAS OnDemand for Academics) after uploading data/clean/retention.csv.
   Change the path below to your own SAS home folder. */
%let path = /home/u64655261;

/* 1. Read the CSV into SAS */
proc import datafile="&path/retention.csv" out=retention dbms=csv replace;
  getnames=yes;
  guessingrows=max;
run;

/* 2. Domestic and international students; turn % into student counts */
data m1;
  set retention;
  where group in ("Domestic", "International");
  came_back        = round(ret_y2 / 100 * students);
  years_since_2014 = cohort - 2014;
run;

/* 3. Logistic regression (same model as R glm, family = binomial) */
proc logistic data=m1;
  class group (ref="Domestic") / param=ref;
  model came_back/students = group years_since_2014;
run;

/* 4. Overdispersion-adjusted model (like quasibinomial in R) */
proc logistic data=m1;
  class group (ref="Domestic") / param=ref;
  model came_back/students = group years_since_2014 / scale=pearson;
run;

/* Results (Nov 2026): OR International vs Domestic = 0.695 (95% CI 0.652-0.742), matching R (0.695, 0.651-0.741).
   Tiny differences: SAS rounds .5 up, R rounds .5 to even, so a few rebuilt counts differ by one student. */
