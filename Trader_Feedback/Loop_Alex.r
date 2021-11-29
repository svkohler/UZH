
# set the correct working directory to corresponding files
setwd("/home/svkohler/OneDrive/Desktop/UZH/R project/UZH_Feedbackreport/Dummy_data")

# source the general requirements file directly from different path here (not necessary)
source("/home/svkohler/OneDrive/Desktop/UZH/R project/UZH_Feedbackreport/requirements.R", chdir=TRUE)

# load data matrix (dim: IDs x metrics)
metrics <- read.csv("data.csv", sep=";")
# extract information about min/max values 


# define IDs to loop over. Here dummy first three to see whether procedure works
IDs <- 1:3

for(i in IDs){
  #get row of current ID
  metrics_ID <- metrics[metrics$id==i,]
  #extract date
  start_date <- metrics_ID$start_date
  end_date <- metrics_ID$end_date
  # extract currency
  curr <- metrics_ID$curr
  # transform metrics in rectangular form for table. Fill row by row.
  metrics_ID_table <- matrix(data=NA, nrow=5, ncol=5)
  colnames(metrics_ID_table) <- c("Portfolio", "Benchmark", "SMI", "EuroStoxx", "S&P 500")
  rownames(metrics_ID_table) <- c("Mean Raw Return", "Return Volatility", "Sharpe Ratio", "Benchmark adj. Return", "Residual Risk")
  metrics_ID_table[1,] <- unlist(metrics_ID[5:9])
  metrics_ID_table[2,] <- unlist(metrics_ID[10:14])
  metrics_ID_table[3,] <- unlist(metrics_ID[15:19])
  metrics_ID_table[4,1] <- unlist(metrics_ID[20])
  metrics_ID_table[5,1] <- unlist(metrics_ID[21])
  # transform investment style figures in rectangular form for table. Fill row by row.
  inv_style_ID_table <- matrix(data=NA, nrow=5, ncol=4)
  colnames(inv_style_ID_table) <- c("Portfolio", "SMI", "EuroStoxx", "S&P 500")
  rownames(inv_style_ID_table) <- c("Market", "Size", "Value", "Momentum", "Diversification")
  inv_style_ID_table[1,] <- unlist(metrics_ID[22:25])
  inv_style_ID_table[2,] <- unlist(metrics_ID[26:29])
  inv_style_ID_table[3,] <- unlist(metrics_ID[30:33])
  inv_style_ID_table[4,] <- unlist(metrics_ID[34:37])
  inv_style_ID_table[5,] <- unlist(metrics_ID[38:41])
  # transform trading behaviour figures in rectangular form for table. Fill row by row.
  trad_behav_ID_table <- matrix(data=NA, nrow=5, ncol=1)
  colnames(trad_behav_ID_table) <- c("Portfolio")
  rownames(trad_behav_ID_table) <- c("Turnover", "Temperament", "Activity", "Conviction", "Disposition effect")
  trad_behav_ID_table[1,] <- unlist(metrics_ID[42])
  trad_behav_ID_table[2,] <- unlist(metrics_ID[43])
  trad_behav_ID_table[3,] <- unlist(metrics_ID[44])
  trad_behav_ID_table[4,] <- unlist(metrics_ID[45])
  trad_behav_ID_table[5,] <- unlist(metrics_ID[46])
  # load the data file correspomding to the current ID
  data_ID <- read.csv(paste0(i, ".csv"), sep=";")
  data_ID$date <- as.Date(data_ID$date, format="%d.%m.%Y")
  
  # check if not empty
  if(nrow(data_ID)==0){
    print(sprintf("Dataframe for ID %i is empty.", i))
    next()
  }
  
  rmarkdown::render(input = "/home/svkohler/OneDrive/Desktop/UZH/R project/UZH_Feedbackreport/Feedbackreport_Alex_v4_loop.Rmd", 
                    output_format = "pdf_document",
                    output_file = paste("test_report_", i,"_", Sys.Date(), ".pdf", sep=''),
                    output_dir = "/home/svkohler/OneDrive/Desktop/UZH/LoopReports",
                    params = list(date = paste(as.character(start_date),as.character(end_date), sep="-"), Id = i, currency=as.name(curr)))
}





