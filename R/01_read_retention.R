# Step 2: turn the uOttawa retention PDF into a table
library(pdftools)
library(dplyr)
library(stringr)

text  <- pdf_text("data/raw/2023-24_uOttawa_CSRDE.pdf")   # one long text per page
lines <- unlist(strsplit(text, "\n"))                       # cut it into lines

rows  <- list()
group <- NA
for (line in lines) {
  if (str_detect(line, "Cohort Type")) {                    # a new group starts (Total, Female, ...)
    group <- str_trim(str_remove(line, "Cohort Type"))
  }
  if (str_detect(line, "^\\s+20\\d\\d\\s+\\d+")) {          # a data line starts with a year
    nums <- as.numeric(str_extract_all(line, "\\d+")[[1]])
    rows[[length(rows) + 1]] <- data.frame(group = group,
                                           cohort = nums[1],
                                           students = nums[2],
                                           values = I(list(nums[-(1:2)])))
  }
}
raw <- bind_rows(rows)

# Column names in the order the PDF prints them
col_names <- c("ret_y2", "ret_y3", "grad_y3", "ret_y4", "grad_y4", "ret_y5", "grad_y5",
               "ret_y6", "grad_y6", "ret_y7", "grad_y7", "ret_y8", "grad_y8",
               "ret_y9", "grad_y9", "ret_y10", "grad_y10", "ret_y11")

retention <- raw
for (i in seq_along(col_names)) {
  retention[[col_names[i]]] <- sapply(raw$values, function(v) if (length(v) >= i) v[i] else NA)
}
retention$values <- NULL

dir.create("data/clean", showWarnings = FALSE)
write.csv(retention, "data/clean/retention.csv", row.names = FALSE)
print(head(retention, 3))
cat("Rows:", nrow(retention), " Groups:", paste(unique(retention$group), collapse = ", "), "\n")
