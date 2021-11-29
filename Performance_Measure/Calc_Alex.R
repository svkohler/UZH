# !!! make sure to have set up the correct working directory and saved the appropriate files
setwd("C:/Users/svenk/OneDrive/Desktop/UZH/Repo/Performance_Measure")

# source libraries
source("requirements.R")

# load functions file
source("functions_PI.R")

# load data, extract IDs, select relevant columns, fill NA (takes +/- 2 min)
source("load_process_data.R")

######################
# Implement performance measure
######################

# convex combination of average excess return and variance (annualized)

# PI = L*(R_p-R_f)-(1-L)*variance

#define global variables which are used for performance measure calculations
days_ret <-  252 # trading days, only weekdays in dates (check: unique(weekdays(WikiDaily_selected$date)))
days_vola <- 252 # average number of trading days in a year
min_days <- 1000 # minimum investment period in days
IDs <- max(c(WikiDaily_selected$wiki_nr)) # defines loop to be executed
factor_data_name <- "developed" # define the factor data to be used
verbose <- TRUE

# get the right factor data (in this calculation not important, only fetches rf)
factor_data <- get_factor_data(factor_data_name)

# calculate cross sectional SD of average returns/SDs to get appropriate lambda
# First: calculate average return/SD of returns per ID
avg_ret <- rep(0,IDs)
SDs <- rep(0,IDs)
pb <- txtProgressBar(min = 0, max = IDs, style = 3, width=100) # progress bar
for(i in 1:IDs){
  WikiDaily_Id <- WikiDaily_selected[WikiDaily_selected$wiki_nr==i,]
  # merge the different dataframes on date
  WikiDaily_merge <- merge_mult(list_of_dfs=list(WikiDaily_Id, factor_data), by=c("date"))
  avg_ret[i] <- mean(WikiDaily_merge$ret-WikiDaily_merge$RF)
  SDs[i] <- sqrt(var(WikiDaily_merge$ret-WikiDaily_merge$RF))
  # update progress bar
  setTxtProgressBar(pb, i)
}
# Second: calculate SD of avg. returns/SD of returns
SD_avg_ret <- sqrt(var(avg_ret))
SD_SDs <- sqrt(var(SDs))

# calculate lambda
lambda <- SD_avg_ret/(SD_avg_ret+SD_SDs)

# collect performance measures per wiki-ID
PIs <- matrix(nrow = IDs, ncol=3)
colnames(PIs) <- c("Total", "1st half", "2nd half") # split in halfs to later calculate autocorrelation between them

# collect sharpe ratios per wiki-ID
SRs <- matrix(nrow = IDs, ncol=3)
colnames(SRs) <- c("Total", "1st half", "2nd half") # split in halfs to later calculate autocorrelation between them

pb <- txtProgressBar(min = 0, max = IDs, style = 3, width=100) # progress bar
# loop through all available wiki IDs
ignored_IDs <- 0
for(i in 1:IDs){
  WikiDaily_Id <- WikiDaily_selected[WikiDaily_selected$wiki_nr==i,]
  # merge the different dataframes on date
  WikiDaily_merge <- merge_mult(list_of_dfs=list(WikiDaily_Id, factor_data), by=c("date"))
  if(nrow(WikiDaily_merge)<=min_days){
    if(verbose==TRUE){
      ignored_IDs <- ignored_IDs+1
      print(sprintf("Trader with ID %i does not satisfy minimum investment period. Share ignored: %.2f%%", i, ignored_IDs*100/IDs)) 
    }
    next()
  }
  # save start and end date
  start_date <- min(WikiDaily_merge$date)
  end_date <- max(WikiDaily_merge$date)
  # calculate PI for whole investment period
  PIs[i,1] <- PI(prices = WikiDaily_merge$ret, rf=WikiDaily_merge$RF, lambda=lambda, returns=TRUE)
  # calculate SR for whole investment period
  SRs[i,1] <- sharpe_ratio(ret=WikiDaily_merge$ret, rf=WikiDaily_merge$RF, 
                           time_adj = TRUE, 
                           time_unit = "years",
                           start_date = start_date, 
                           end_date = end_date)
  # NOW: split investment period in half
  WikiDaily_merge_1st <- WikiDaily_merge[1:round(nrow(WikiDaily_merge)/2),]
  WikiDaily_merge_2nd <- WikiDaily_merge[(round(nrow(WikiDaily_merge)/2)+1):nrow(WikiDaily_merge),]
  # calculate PI for separate halfs
  PIs[i,2] <- PI(prices = WikiDaily_merge_1st$ret, rf=WikiDaily_merge_1st$RF, lambda=lambda, returns=TRUE)
  PIs[i,3] <- PI(prices = WikiDaily_merge_2nd$ret, rf=WikiDaily_merge_2nd$RF, lambda=lambda, returns=TRUE)
  # calculate SR for separate halfs
  SRs[i,2] <- sharpe_ratio(ret=WikiDaily_merge_1st$ret, rf=WikiDaily_merge_1st$RF, 
                           time_adj = TRUE, 
                           time_unit = "years",
                           start_date = min(WikiDaily_merge_1st$date), 
                           end_date = max(WikiDaily_merge_1st$date))
  SRs[i,3] <- sharpe_ratio(ret=WikiDaily_merge_2nd$ret, rf=WikiDaily_merge_2nd$RF, 
                           time_adj = TRUE, 
                           time_unit = "years",
                           start_date = min(WikiDaily_merge_2nd$date), 
                           end_date = max(WikiDaily_merge_2nd$date))
  # update progress bar
  setTxtProgressBar(pb, i)
}
print(paste0("Total: ", IDs, ", Ignored: ", ignored_IDs, ". Fraction ignored: ", round(ignored_IDs*100/IDs, 2), "%."))
# [1] "Total: 7340, Ignored: 4233. Fraction ignored: 57.67%." results from last run


saveRDS(PIs, file=paste0("Customized_Performance_Measures",".RDS"))
saveRDS(SRs, file=paste0("Sharpe_Ratios",".RDS"))

#####################
# calculate various correlation
#####################

# drop NA
clean_PIs <- na.omit(PIs)
clean_SRs <- na.omit(SRs)

# autocorrelation of PI (1st/2nd half)
autoC_PI <- cor(clean_PIs[,2], clean_PIs[,3])
# autocorrelation of SR (1st/2nd half)
autoC_SR <- cor(clean_SRs[,2], clean_SRs[,3])

# correlation between PI and SR
corr_PI_SR <- cor(clean_PIs[,1], clean_SRs[,1])



# plot 1st vs 2nd half
# PIs
plot(x = clean_PIs[,2], y=clean_PIs[,3], 
     xlab = "PI 1st half",
     ylab = "PI 2nd half",
     main = paste0("Autocorrelation of PI: ", round(autoC_PI,2)),
     col=rgb(0,0,0, alpha=0.3))

# SRs
plot(x = clean_SRs[,2], y=clean_SRs[,3], 
     xlab = "SR 1st half",
     ylab = "SR 2nd half",
     main = paste0("Autocorrelation of Sharpe Ratios: ", round(autoC_SR,2)),
     col=rgb(0,0,0, alpha=0.3))

# L-shape in plot is artefact from thresholding the SR at zero when negative. 

