# collection of libraries used for R-project

library(knitr)
library(markdown)
library(rmarkdown)
library(dplyr)
library(ggplot2)
library(hrbrthemes)
library(gridExtra)
library(grid)
library(lattice)
library(kableExtra)
library(scales)
library(lubridate)
library(StatMeasures)
library(readstata13)
library("plot3D")
library(PerformanceAnalytics)
library(knitr)
library(markdown)
library(rmarkdown)
library(dplyr)
library(ggplot2)
library(hrbrthemes)
library(gridExtra)
library(grid)
library(lattice)
library(kableExtra)
library(scales)
library(lubridate)
library(StatMeasures)
library(magrittr)

stacking <- function(df){
  #save specs of dataframe
  colnames <- colnames(df)
  rownames <- rownames(df)
  dimension <- dim(df)
  #define the matrix
  df_new <- data.frame(matrix(nrow=dimension[1]*dimension[2], ncol = 3))
  colnames(df_new) <- c("variable", "value", "category")
  df_new[,1] <- rep(rownames, dimension[2])
  
  for(i in 1:dimension[2]){
    cn <- colnames[i]
    df_new[(i:(i+(dimension[1]-1)))+(i-1)*(dimension[1]-1),2] <- df[,i]
    df_new[(i:(i+(dimension[1]-1)))+(i-1)*(dimension[1]-1),3] <- cn
  }
  
  if(class(df_new$variable)!="factor"){
    df_new$variable <- as.factor(df_new$variable)
  }
  
  if(class(df_new$category)!="factor"){
    df_new$category <- as.factor(df_new$category)
  }
  
  return(df_new)
}