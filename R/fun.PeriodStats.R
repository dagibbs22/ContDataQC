# ~~~~~ Title ~~~~~
#' Daily stats for a given time period
#'
# ~~~~~ Description ~~~~~
#' Generates daily stats (N, mean, min, max, range, std deviation) for the
#' specified time period before a given date. Output is a multiple column CSV
#' (Date and Parameter Name by statistic) and a report (HTML or DOCX) with plots.
#' Input is the ouput file of the QC operation of ContDataQC().
#'
# ~~~~~ Details ~~~~~
#' The input is output file of the QC operation in ContDataQC().  That is, a file with
#' Date.Time, and parameters (matching formats in config.R).
#'
#' To get different periods (30, 60, or 90 days) change function input "fun.myPeriod.N".
#' It is possible to provide a vector for Period.N and Period.Units.
#'
#' Requires doBy library for the statistics summary and rmarkdown for the report.
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Erik.Leppo@tetratech.com (EWL)
# 20170905
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @param fun.myDate Benchmark date.
#' @param fun.myDate.Format Format of benchmark date.  This should be the same format of the date in the data file.  Default is \%Y-\%m-\%d (e.g., 2017-12-31).
#' @param fun.myPeriod.N Period length.  Default = 30.
#' @param fun.myPeriod.Units Period units (days or years written as d or y).  Default is d.
#' @param fun.myFile Filename (no directory) of data file.  Must be CSV file.
#' @param fun.myDir.import Directory for import data.  Default is current working directory.
#' @param fun.myDir.export Directory for export data.  Default is current working directory.
#' @param fun.myParam.Name Column name in myFile to perform summary statistics.
#' @param fun.myDateTime.Name Column name in myFile for date time.  Default = "Date.Time".
#' @param fun.myDateTime.Format Format of DateTime field.  Default = \%Y-\%m-\%d \%H:\%M:\%S.
#' @param fun.myThreshold Value to draw line on plot.  For example, a regulatory limit.  Default = NA
#' @param fun.myConfig Configuration file to use for this data analysis.  The default is always loaded first so only "new" values need to be included.  This is the easiest way to control date and time formats.
#' @param fun.myReport.format Report format (docx or html).  Default is specified in config.R (docx).
#' @return Returns a csv with daily means and a PDF summary with plots into the specified export directory for the specified time period before the given date.
#' @keywords continuous data, daily mean, period
#' @examples
#' # Save example file
#' df.x <- DATA_period_test2_Aw_20130101_20141231
#' write.csv(df.x,"DATA_period_test2_Aw_20130101_20141231.csv")
#'
#' # function inputs
#' myDate <- "2013-09-30"
#' myDate.Format <- "%Y-%m-%d"
#' myPeriod.N <- c(30, 60, 90, 120, 1)
#' myPeriod.Units <- c("d", "d", "d", "d", "y")
#' myFile <- "DATA_period_test2_Aw_20130101_20141231.csv"
#' myDir.import <- getwd()
#' myDir.export <- getwd()
#' myParam.Name <- "Water.Temp.C"
#' myDateTime.Name <- "Date.Time"
#' myDateTime.Format <- "%Y-%m-%d %H:%M:%S"
#' myThreshold <- 20
#' myConfig <- ""
#' myReport.format <- "docx"
#'
#' # Run Function
#' ## default report format (html)
#' PeriodStats(myDate
#'           , myDate.Format
#'           , myPeriod.N
#'           , myPeriod.Units
#'           , myFile
#'           , myDir.import
#'           , myDir.export
#'           , myParam.Name
#'           , myDateTime.Name
#'           , myDateTime.Format
#'           , myThreshold
#'           , myConfig)
#'
#' ## DOCX report format
#' PeriodStats(myDate
#'           , myDate.Format
#'           , myPeriod.N
#'           , myPeriod.Units
#'           , myFile
#'           , myDir.import
#'           , myDir.export
#'           , myParam.Name
#'           , myDateTime.Name
#'           , myDateTime.Format
#'           , myThreshold
#'           , myConfig
#'           , myReport.format)
#
#' @export
PeriodStats <- function(fun.myDate
                       , fun.myDate.Format = NA
                       , fun.myPeriod.N = 30
                       , fun.myPeriod.Units = "d"
                       , fun.myFile
                       , fun.myDir.import=getwd()
                       , fun.myDir.export=getwd()
                       , fun.myParam.Name
                       , fun.myDateTime.Name = "Date.Time"
                       , fun.myDateTime.Format = NA
                       , fun.myThreshold = NA
                       , fun.myConfig = ""
                       , fun.myReport.format=""
                       )
{##FUN.fun.Stats.START
  # 00. Debugging Variables####
  boo.DEBUG <- 0
  if(boo.DEBUG==1) {##IF.boo.DEBUG.START
    fun.myDate <- "2013-09-30"
    fun.myDate.Format <- "%Y-%m-%d"
    fun.myPeriod.N = c(30, 60, 90, 120, 1)
    fun.myPeriod.Units = c("d", "d", "d", "d", "y")
    fun.myFile <- "DATA_test2_Aw_20130101_20141231.csv"
    fun.myDir.import <- file.path(".","data-raw")
    fun.myDir.export <- getwd()
    fun.myParam.Name <- "Water.Temp.C"
    fun.myDateTime.Name <- "Date.Time"
    fun.myDateTime.Format = NA
    fun.myThreshold <- 20
    fun.myConfig=""
    # Load environment
    ContData.env <- new.env(parent = emptyenv())
    source(file.path(".","R","fun.CustomConfig.R"), local=TRUE)
  }##IF.boo.DEBUG.END

  # 0a.0. Load environment
  # config file load, 20170517
  if (fun.myConfig!="") {##IF.fun.myConfig.START
    config.load(fun.myConfig)
  }##IF.fun.myConfig.START

  # 0b.0. Load defaults from environment
  # 0b.1. Format, Date
  if (is.na(fun.myDate.Format)) {
    fun.myDate.Format = ContData.env$myFormat.Date
  }
  # 0b.2. Format, DatTime
  if (is.na(fun.myDateTime.Format)) {##IF.fun.myConfig.START
    fun.myDateTime.Format = ContData.env$myFormat.DateTime
  }##IF.fun.myConfig.START

  # 0c.0. Error Checking, Period (N vs. Units)
  len.N <- length(fun.myPeriod.N)
  len.Units <- length(fun.myPeriod.Units)
  if(len.N != len.Units) {##IF.length.START
    myMsg <- paste0("Length of period N (",len.N,") and Units (",len.Units,") does not match.")
    stop(myMsg)
  }##IF.length.END

  # 1.0 Convert date format to YYYY-MM-DD####
  fd01 <- "%Y-%m-%d" #ContData.env$myFormat.Date
  myDate.End <- as.POSIXlt(format(as.Date(fun.myDate, fun.myDate.Format), fd01))
  # use POSIX so can access parts
  # 1.1. Error Checking, Date Conversion
  if(is.na(myDate.End)) {
    myMsg <- paste0("Provided date (",fun.myDate,") and date format ("
                    ,fun.myDate.Format,") do not match.")
    stop(myMsg)
  }

  # 2.0. Load Data####
  # 2.1. Error Checking, make sure file exists
  if(fun.myFile %in% list.files(path=fun.myDir.import)==FALSE) {##IF.file.START
    #
    myMsg <- paste0("Provided file (",fun.myFile,") does not exist in the provided import directory (",fun.myDir.import,").")
    stop(myMsg)
    #
  }##IF.file.END
  # 2.2. Load File
  df.load <- read.csv(file.path(fun.myDir.import, fun.myFile),as.is=TRUE,na.strings="")
  # 2.3. Error Checking, data field names
  myNames2Match <- c(fun.myParam.Name, fun.myDateTime.Name)
  #myNames2Match %in% names(df.load)
  if(sum(myNames2Match %in% names(df.load))!=2){##IF.match.START
    myMsg <- paste0("Provided data file (",fun.myFile,") does not contain the provided paramater column name ("
                    ,fun.myParam.Name,") or date/time column name (",fun.myDateTime.Name,").")
    stop(myMsg)
  }##IF.match.END
  # 2.4.  Error Checking, DateTime format
  #df.load[,fun.myDateTime.Name] <- as.Date()


  # 3. Munge Data####
  # 3.1. Subset Fields
  df.param <- df.load[,c(fun.myDateTime.Name,fun.myParam.Name)]
  # 3.2. Add "Date" field
  myDate.Name <- "Date"
  df.param[,myDate.Name] <- as.Date(df.param[,fun.myDateTime.Name], fd01)
  # 3.3. Data column to numeric
  # may get "NAs introduced by coercion" so suppress
  df.param[,fun.myParam.Name] <- suppressWarnings(as.numeric(df.param[,fun.myParam.Name]))



  #~~~~~~~~~~~~~~~~~~~~~~~~~
  # OLD method using doBy
  # 4. Daily Stats for data####
  # Calculate daily mean, max, min, range, sd, n
  # 4.1. Define FUNCTION for use with summaryBy
  myQ <- c(0.01,0.05,0.10,0.25,0.50,0.75,0.90,0.95,0.99)
  myFUN.Names <- c("mean","median","min","max","range","sd","var","cv","n",paste("q",formatC(100*myQ,width=2,flag="0"),sep=""))
  #
  myFUN.sumBy <- function(x, ...){##FUN.myFUN.sumBy.START
    c(mean=mean(x,na.rm=TRUE)
      ,median=median(x,na.rm=TRUE)
      ,min=min(x,na.rm=TRUE)
      ,max=max(x,na.rm=TRUE)
      ,range=max(x,na.rm=TRUE)-min(x,na.rm=TRUE)
      ,sd=sd(x,na.rm=TRUE)
      ,var=var(x,na.rm=TRUE)
      ,cv=sd(x,na.rm=TRUE)/mean(x,na.rm=TRUE)
      ,n=length(x)
      ,q=quantile(x,probs=myQ,na.rm=TRUE)
    )
  }##FUN.myFUN.sumBy.END
  # 4.2.  Rename data column (summaryBy doesn't like variables)
  names(df.param)[match(fun.myParam.Name,names(df.param))] <- "x"
  # 4.2. Summary
  df.summary <- doBy::summaryBy(x~Date, data=df.param, FUN=myFUN.sumBy, na.rm=TRUE
                                , var.names=fun.myParam.Name)
  #~~~~~~~~~~~~~~~~~~~~~~~~~
  # # 4. Daily stats
  # # dplyr summary (not working with variable name)
  # x <- quo(fun.myParam.Name)
  # df.summary <- df.param %>%
  #                 dplyr::group_by(Date) %>%
  #                   dplyr::summarise(n=n()
  #                                    #,min=min(fun.myParam.Name,na.rm=TRUE)
  #                                     ,mean=mean(!!x,na.rm=TRUE)
  #                                    # ,max=mean(fun.myParam.Name,na.rm=TRUE)
  #                                    # ,sd=sd(fun.myParam.Name,na.rm=TRUE)
  #                                    )

  # 5. Determine period start date####
  # Loop through each Period (N and Units)
  numPeriods <- length(fun.myPeriod.N)
  myDate.Start <- rep(myDate.End, numPeriods)
  for (i in 1:numPeriods) {##FOR.i.START
    if(tolower(fun.myPeriod.Units[i])=="d" ) {##IF.format.START
      # day, $mday
      myDate.Start[i]$mday <- myDate.End$mday - (fun.myPeriod.N[i] - 1)
    } else if(tolower(fun.myPeriod.Units[i])=="y") {
      # year, $year
      myDate.Start[i]$year <- myDate.End$year - fun.myPeriod.N[i]
      myDate.Start[i]$mday <- myDate.End$mday + 1
    } else {
      myMsg <- paste0("Provided period units (",fun.myPeriod.Units
                      ,") unrecognized.  Accepted values are 'd', 'm', or 'y').")
      stop(myMsg)
    }##IF.format.END
  }##FOR.i.END
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # # single period
  # myDate.Start <- myDate.End
  # if(tolower(fun.myPeriod.Units)=="d" ) {##IF.format.START
  #   # day, $mday
  #   myDate.Start$mday <- myDate.End$mday - (fun.myPeriod.N - 1)
  # } else if(tolower(fun.myPeriod.Units)=="y") {
  #   # year, $year
  #   myDate.Start$year <- myDate.End$year - fun.myPeriod.N
  #   myDate.Start$mday <- myDate.End$mday + 1
  # } else {
  #   myMsg <- paste0("Provided period units (",fun.myPeriod.Units
  #                   ,") unrecognized.  Accepted values are 'd', 'm', or 'y').")
  #   stop(myMsg)
  # }##IF.format.END
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # # 6.0. Subset Date Range
  # df.subset <- df.subset[df.subset[,myDate.Name]>=myDate.Start & df.subset[,myDate.Name]<=myDate.End,]
  # # df.period <- df.summary %>%
  # #               dplyr::filter(myDate.Name>=myDate.Start, myDate.Name<=myDate.End)
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  # 6. Subset and Save summary file ####
  myDate <- format(Sys.Date(),"%Y%m%d")
  myTime <- format(Sys.time(),"%H%M%S")
  myFile.Export.ext <- ".csv"
  myFile.Export.base <- substr(fun.myFile,1,nchar(fun.myFile)-4)
  # Loop through sets
  # numPeriods defined above
  for (j in 1:numPeriods){##FOR.j.START
    # subset
    df.summary.subset <- df.summary[df.summary[,myDate.Name]>=as.Date(myDate.Start[j]) & df.summary[,myDate.Name]<=as.Date(myDate.End),]
    # create file name
    myFile.Export.full <- paste0(myFile.Export.base
                                 ,"_PeriodStats_"
                                 ,fun.myPeriod.N[j]
                                 ,fun.myPeriod.Units[j]
                                 ,"_"
                                 ,fun.myDate
                                 ,"_"
                                 ,myDate
                                 ,"_"
                                 ,myTime
                                 ,myFile.Export.ext)
    # save
    write.csv(df.summary.subset, file.path(fun.myDir.export,myFile.Export.full),quote=FALSE,row.names=FALSE)
  }##FOR.j.END

  # 7. Generate markdown summary file with plots ####
  # Error Check, Report Format
  if(fun.myReport.format==""){
    fun.myReport.format <- ContData.env$myReport.Format
  }
  fun.myReport.format <- tolower(fun.myReport.format)

  myReport.Name <- paste0("Report_PeriodStats","_",fun.myReport.format)
  myPkg <- "ContDataQC"
  if(boo.DEBUG==1){
    strFile.RMD <- file.path(getwd(),"inst","rmd",paste0(myReport.Name,".rmd")) # for testing
  } else {
    strFile.RMD <- system.file(paste0("rmd/",myReport.Name,".rmd"),package=myPkg)
  }
  #
  strFile.out.ext <- paste0(".",fun.myReport.format) #".docx" # ".html"
  strFile.out <- paste0(myFile.Export.base,"_PeriodStats_",fun.myDate,"_",myDate,"_",myTime,strFile.out.ext)
  #suppressWarnings(
  rmarkdown::render(strFile.RMD, output_file=strFile.out, output_dir=fun.myDir.export, quiet=TRUE)
  #)

  # 8. Inform user task is complete.####
  cat("Task complete.  Data (CSV) and report (",fun.myReport.format,") files saved to directory:\n")
  cat(fun.myDir.export)
  flush.console()

}##FUNCTION.END
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

