# to load data source this file. More convenient than to load in each separate file
setwd(paste0(getwd(),"/data"))

EuroStoxx <- read.dta13("EuroStoxx50.dta")
# load the latest factor data. status: 30.09.2020
Factor_Europe <- readRDS("Europe_3_Factors_Daily.RDS")
Factor_Developed <- readRDS("Developed_3_Factors_Daily.RDS")
Factor_North_America <- readRDS("North_America_3_Factors_Daily.RDS")
FF3Daily <- read.dta13("FF3Daily.dta")
# load the latest Wikifolio data
WikiDaily_01122020 <- read.dta13("WikiDaily_forFeedback.dta")

# manipulating data, make copy first
WikiDaily_mod <- WikiDaily_01122020
# extract number of different WikiIds and add column of facilitated Ids
IDs <- length(unique(WikiDaily_01122020$wikiId))
WikiDaily_mod$wiki_nr <- as.factor(WikiDaily_mod$wikiId)
levels(WikiDaily_mod$wiki_nr) <- c(1:IDs)
# decide which columns to keep
WikiDaily_selected <- WikiDaily_mod[,c("date", "wiki_nr", "ret", "close", "aum")]
# first return per IDs is NaN since no reference close price available. Fill with zero.
WikiDaily_selected <- na.zero(WikiDaily_selected)