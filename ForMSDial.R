# Script for analyzing MS-dial

library(tidyverse)
library(MetaboAnalystR)

setwd("~/Desktop/WorkDir/Analyze/MS-dial/")

# import MS-dial exported csv
  # csv should be formatted in excel
data <- read_csv("./Area_1_2026_01_30_17_24_50.csv")
data <- data[,1:48]

# check data type
type <- data.frame(
  column = names(data),
  class = sapply(data, typeof),
  row.names = NULL
)

# quick functional analysis
func <- data %>% mutate(
  HC1 = as.numeric(HC1),
  HC2 = as.numeric(HC2),
  D1 = as.numeric(D1),
  D2 = as.numeric(D2),
)
func <- func %>%
  dplyr::rowwise() %>%
  dplyr::mutate(
    p.value = {
      x <- dplyr::c_across(c(HC1, HC2))
      y <- dplyr::c_across(c(D1, D2))
      
      sx <- sd(x, na.rm = TRUE)
      sy <- sd(y, na.rm = TRUE)
      
      if (is.na(sx) || is.na(sy) || sx == 0 || sy == 0) {
        NA_real_
      } else {
        t.test(x, y)$p.value
      }
    }
  ) %>%
  dplyr::ungroup()

func <- func %>% select(`Average Rt(min)`,`Average Mz`,p.value)
func <- func %>% dplyr::rename(
  rt = `Average Rt(min)`,
  m.z = `Average Mz`
)
func <- func %>% mutate(mode = "positive")
func <- func %>% filter(is.na(p.value) == F)
typeof(func$p.value)
write.csv(func, "./functionalAnalysis.txt" , row.names = FALSE)

rm(list = ls())
mSet <- InitDataObjects("mass_all", "mummichog", FALSE)
mSet <- SetPeakFormat(mSet, "mpt")
mSet <- UpdateInstrumentParameters(mSet, 15.0, "mixed", "yes", 0.02)
mSet <- Read.PeakListData(mSet, "functionalAnalysis.txt")
mSet <- SetRTincluded(mSet, "minutes")
mSet <- SanityCheckMummichogData(mSet)
mSet <- SetPeakEnrichMethod(mSet, "mum", "v2")
# p = 0.1
pval <- sort(mSet[["dataSet"]][["mummi.proc"]][["p.value"]])[ceiling(length(mSet[["dataSet"]][["mummi.proc"]][["p.value"]])*0.1)]
mSet <- SetMummichogPval(mSet, pval)
mSet <- PerformPSEA(mSet, "hsa_mfn", "current", 3 , 100)
mSet <- PlotPeaks2Paths(mSet, "peaks_to_paths_ms1_", "png", 144, width=8)

