# =============================================================================
# National Graduates Survey (NGS), Class of 2020 - survey-weighted analysis
# Author: Tanima Garg
#
# Data: Statistics Canada public-use microdata file (PUMF), 16,138 respondents,
#       interviewed in 2023 (three years after graduating). Not stored in this
#       repo (the bootstrap file is 185 MB). Download 2020-CSV.zip from
#       Statistics Canada and unzip it into survey/data/raw/.
#
# Run from the repo root:   Rscript survey/R/ngs_survey_analysis.R
#
# Method:
#   - Main weight WTPF for estimates; 1,000 bootstrap replicate weights
#     (WRPF1-WRPF1000) for margins of error, as the NGS user guide specifies.
#   - Skip code 6 ("valid skip") and 9 ("not stated") are treated as missing,
#     never as "no".
#   - Quality grade from Statistics Canada's rule for proportions:
#     CV = 100 * SE / 0.5 -> A <=5, B <=15, C <=25, D <=35, E >35.
# =============================================================================

library(survey)

raw_dir  <- "survey/data/raw/5012-NGS-END_2020-CSV"
out_dir  <- "survey/output"
pbsw     <- Sys.getenv("NGS_PBSW", file.path(raw_dir, "Data/NGS2020_PBSW.txt"))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- 1. Read the survey file and the bootstrap weights ---------------------
ngs   <- read.csv(file.path(raw_dir, "ngs2020_pumf.csv"))
lines <- readLines(pbsw)
boot  <- data.frame(PUMFID = as.integer(substr(lines, 1, 5)))
for (i in 1:1000) {                       # each weight is 12 characters wide
  start <- 6 + (i - 1) * 12
  boot[[paste0("WRPF", i)]] <- as.numeric(substr(lines, start, start + 11))
}
rm(lines)

# Checks before merging: same people, no missing weights
stopifnot(nrow(boot) == nrow(ngs),
          all(sort(boot$PUMFID) == sort(ngs$PUMFID)),
          !anyNA(boot))
ngs <- merge(ngs, boot, by = "PUMFID"); rm(boot)

# ---- 2. Recode variables (codebook values) ---------------------------------
level_names <- c("1" = "College", "2" = "Bachelor's", "3" = "Master's/Doctorate")
ngs$level  <- factor(level_names[as.character(ngs$CERTLEVP)], levels = level_names)
ngs$region <- factor(ifelse(ngs$REG_INST == 3, "Ontario", "Rest of Canada"))

# Employed (LFSTATP 1) vs unemployed / not in labour force (2, 3); 9 -> NA
ngs$employed <- ifelse(ngs$LFSTATP %in% 1:3, as.numeric(ngs$LFSTATP == 1), NA)
# Job closely related to 2020 program (LMA6_11 1) vs somewhat / not (2, 3)
ngs$closely_related <- ifelse(ngs$LMA6_11 %in% 1:3, as.numeric(ngs$LMA6_11 == 1), NA)
# Owed $25,000+ at graduation (DBTALGRD 4) vs less (0-3)
ngs$debt_25k_plus <- ifelse(ngs$DBTALGRD %in% 0:4, as.numeric(ngs$DBTALGRD == 4), NA)

# ---- 3. Survey designs -----------------------------------------------------
simple <- svydesign(ids = ~1, weights = ~WTPF, data = ngs)
design <- svrepdesign(data = ngs, weights = ~WTPF, repweights = "WRPF[0-9]+",
                      type = "bootstrap", combined.weights = TRUE, mse = TRUE)

grade <- function(se) cut(100 * se / 0.5, c(-Inf, 5, 15, 25, 35, Inf),
                          labels = c("A", "B", "C", "D", "E"))

# ---- 4. Why weights matter: unweighted vs weighted mix ---------------------
mix <- data.frame(
  level      = levels(ngs$level),
  unweighted = round(as.numeric(prop.table(table(ngs$level))) * 100, 1),
  weighted   = round(as.numeric(coef(svymean(~level, simple, na.rm = TRUE))) * 100, 1))
write.csv(mix, file.path(out_dir, "01_level_mix.csv"), row.names = FALSE)

# ---- 5. Estimate tables with 95% ranges and quality grades -----------------
table_for <- function(outcome, by) {
  est <- svyby(as.formula(paste0("~", outcome)), by, design, svymean, na.rm = TRUE)
  ci  <- confint(est)
  out <- est[, all.vars(by), drop = FALSE]
  out$pct   <- round(100 * est[[outcome]], 1)
  out$low   <- round(100 * ci[, 1], 1)
  out$high  <- round(100 * ci[, 2], 1)
  out$grade <- grade(SE(est))
  rownames(out) <- NULL
  out
}

employment <- table_for("employed", ~level)
related    <- table_for("closely_related", ~level + region)
debt       <- table_for("debt_25k_plus", ~level + region)
write.csv(employment, file.path(out_dir, "02_employment_by_level.csv"), row.names = FALSE)
write.csv(related,    file.path(out_dir, "03_closely_related_by_level_region.csv"), row.names = FALSE)
write.csv(debt,       file.path(out_dir, "04_debt_25k_by_level_region.csv"), row.names = FALSE)

# ---- 6. Test: is the Ontario gap real for bachelor's graduates? ------------
bach  <- subset(design, level == "Bachelor's")
model <- svyglm(closely_related ~ region, design = bach, family = quasibinomial())
coefs <- summary(model)$coefficients
test  <- data.frame(term       = rownames(coefs),
                    estimate   = round(coefs[, 1], 4),
                    std_error  = round(coefs[, 2], 4),
                    p_value    = signif(coefs[, 4], 3),
                    odds_ratio = round(exp(coefs[, 1]), 2))
write.csv(test, file.path(out_dir, "05_bachelors_region_model.csv"), row.names = FALSE)

# ---- 7. Chart: closely related job, Ontario vs rest of Canada --------------
chart <- related[order(related$level, related$region), ]   # Ontario next to rest of Canada
png(file.path(out_dir, "closely_related_by_region.png"), width = 1000, height = 560, res = 120)
par(mar = c(4.5, 15, 3, 1))
y    <- rev(seq_len(nrow(chart)))
cols <- ifelse(chart$region == "Ontario", "#1f5fa8", "#9aa5b1")
plot(chart$pct, y, xlim = c(40, 75), pch = 19, col = cols, yaxt = "n",
     xlab = "% in a job closely related to their program (95% range)", ylab = "",
     main = "NGS Class of 2020, three years after graduating")
segments(chart$low, y, chart$high, y, col = cols, lwd = 3)
axis(2, at = y, labels = paste(chart$level, "-", chart$region), las = 1, cex.axis = 0.8)
dev.off()

# ---- 8. Print a summary ----------------------------------------------------
cat("\nUnweighted vs weighted mix (%):\n");          print(mix)
cat("\nEmployment rate by level (%):\n");            print(employment)
cat("\nJob closely related, by level and region:\n"); print(related)
cat("\nOwed $25K+, by level and region:\n");          print(debt)
cat("\nBachelor's model (Rest of Canada vs Ontario):\n"); print(test)
cat("\nSaved tables and chart to", out_dir, "\n")
