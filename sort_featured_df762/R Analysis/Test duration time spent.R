
### Calculating sample size for time spent or engagement metrics ###

###### remove outliers #######

rmoutliers <- function (x) {
  
  #Find the mean without the zeros 
  y <- x[x > 0]


  #Find the outlier boundary in the vector
  outliers <- 3*sd(y) + mean(y)
  #print(paste0("mean = ",mean(y)))
  #print(paste0("3sd = ",3*sd(y)))
  print(paste0("mean+3sd = ",3*sd(y) + mean(y)))
  
  
  #Remove values greater than the minimum outlier from the vector
  filtered <- x[x < outliers]
  
  #Percentage of values remaining
  valsremaining <- length(filtered)/length(x)
  
  #Give an error message if too much data is removed. This could happen if the data had a particularly long tail.  
  if (valsremaining < 0.95){
    stop ("This function will remove more than 5% percent of your data. You need to remove outliers manually.")}
  
  else if (length(filtered)/length(x) < 0.99){
    warning("This calculation has removed between 1% and 5% of your data.") 
    filtered
  }
  
  else
  {
    print("This calcualtion has removed less than 1% of the data")
    filtered
    }
}
################

# Significance level at 0.05 and statistical power at 0.8
coefficient <- 7.9
numberOfVariants <- 2

### read in data ###

#The data should contain 1 weeks worth of data and should be set up with users in the rows and metrics for each user (making sure they are included if they are 0!)
library(readr)
data <- read_csv("test_duration_data.csv")
#data <-read.table("nhpsplit.tsv", sep="\t", comment.char = "", stringsAsFactors = FALSE) 

# The change you should be able to see
minimumDetectableChange <- 0.20

for(col in 2:ncol(data)) {
  print(paste0("col = ",col))
  metric <- rmoutliers(data[col])
  standardDeviation <- sd(metric)
  weeklyUsers <- length(metric) * 2
  print(paste0("weekly users= ", weeklyUsers))
  
  #numberOfUsers <- coefficient * 2 * numberOfVariants * (standardDeviation^2/(minimumDetectableChange^2))
  #OR IF YOU WANT minimum detectable change to be a percentage (I THINK! Please check)
  numberOfUsers <-
    coefficient * 2 * numberOfVariants * (standardDeviation ^ 2 / ((minimumDetectableChange * mean(metric)) ^ 2))
  print(paste0("number of users  = ", numberOfUsers))
  
  timeInWeeks <- numberOfUsers / weeklyUsers
  print(paste0("time in weeks = ", timeInWeeks))
  print(" ")
}
