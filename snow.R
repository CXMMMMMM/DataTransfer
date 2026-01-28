# Params for SnowParam of BiocParallel

library(MetaboAnalystR)
library(OptiLCMS)
library(BiocParallel)

print(Sys.time())

setwd('/home/cxiaomai/MRT_UK/env/LEI_Test_0725/')
mSet <- readRDS('~/MRT_UK/env/LEI_Test_0725/D2vsH2/D2vsH2.rds')

mSet <- PerformMSnImport(mSet = mSet,
                         filesPath = c(list.files("/data/cxiaomai/MRT/MRT_Test_0725_small/", pattern = ".mzML", full.names = T, recursive = T)),
                         acquisitionMode = "DIA",
                         SWATH_file = "/home/cxiaomai/G3_UK/reference/SWATH_Mannual.txt")
DIA_1 <- function (mSet = NULL,
                   min_width = 5,
                   ppm2,
                   sn = 12,
                   span = 0.3,
                   filtering = 2000,
                   BPPARAM = SerialParam()) {
  
  if (is.null(mSet)) {
    stop("mSet is missing! Please import MSn data first.")
  }
  
  if (missing(ppm2)) {
    ppm2 <- 15
  }
  
  MSn_data <- mSet@MSnData
  idxVec <- seq_along(MSn_data[["scanrts_ms2"]])
  
  DecRes <- bplapply(
    idxVec,
    FUN = function(x, min_width, ppm2, sn, span, filt) {
      
      peak_list <- MSn_data[["peak_mtx"]]
      swath     <- as.matrix(MSn_data[["swath"]])
      
      OptiLCMS:::PerformDIADeco(
        peak_list,
        swath,
        MSn_data[["scanrts_ms1"]][[x]],
        MSn_data[["scanrts_ms2"]][[x]],
        MSn_data[["scan_ms1"]][[x]],
        MSn_data[["scan_ms2"]][[x]],
        min_width, ppm2, sn, span, filt
      )
    },
    min_width = min_width,
    ppm2 = ppm2,
    sn = sn,
    span = span,
    filt = filtering,
    BPPARAM = BPPARAM
  )
  
  mSet@MSnResults$DecRes <- DecRes
  mSet
}

BP <- SnowParam(
  workers = 2,
  type = "SOCK",
  progressbar = FALSE
)


mSet <- DIA_1(mSet,
              min_width = 5,
              span = 0.3,
              ppm2 = 30,
              sn = 12,
              filtering = 0,
              BPPARAM = BP
)
print(Sys.time())

mSet <- PerformSpectrumConsenus (mSet,
                                 ppm2 = 30,
                                 concensus_fraction = 0.25,
                                 database_path = "",
                                 use_rt = FALSE,
                                 user_dbCorrection = FALSE)

mSet <- PerformDBSearchingBatch (mSet,
                                 ppm1 = 15,
                                 ppm2 = 30,
                                 rt_tol = 5,
                                 database_path = "/home/cxiaomai/G3_UK/reference/MS2ID_Complete_v09102023.sqlite",
                                 use_rt = FALSE,
                                 enableNL = FALSE,
                                 ncores = 4L)
mSet <- PerformResultsExport (mSet,
                              type = 0L,
                              topN = 10L,
                              ncores = 4L)

dtx2 <- FormatMSnAnnotation(mSet, 5L, F)
save(mSet, file = "/home/cxiaomai/MRT_UK/env/LEI_Test_0725/D2vsH2/")
saveRDS(dtx2, '/home/cxiaomai/MRT_UK/env/LEI_Test_0725/D2vsH2/')
