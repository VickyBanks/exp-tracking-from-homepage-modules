### Proxy connection to CRAN ###

proxy_url <- "http://www-cache-bol.reith.bbc.co.uk:80"
Sys.setenv(http_proxy = proxy_url, https_proxy = proxy_url, ftp_proxy = proxy_url)

### Loading packages needed ###
# install.packages('devtools')
# install.packages("ggstatsplot")
# install.packages("robust")
# install.packages("ggplot2")
# install.packages("ggjoy")
# install.packages("ggpubr")
# install.packages("readxl")
library(ggstatsplot)
library(robust)
library(ggplot2)
#library(ggjoy)
library(ggpubr)
library(readxl)
library(devtools)
library(readr)
library(scales)
library(dplyr)
#devtools::install_github("r-lib/rlang", build_vignettes = TRUE)

### Read in your files ###
Control <- read_csv('control.csv')
Variant1 <- read_csv('variation_1.csv')
Variant2<- Variant1

### Joins data to create experiment dataframe ###
Control$Variant <- paste("Control")
Variant1$Variant <- paste("Variant1")
Variant2$Variant <- paste("Variant2")

Experiment <- rbind(Control, Variant1,Variant2)
Experiment <- as.data.frame(Experiment) 
head(Experiment)

### Split into two df, one for starts and one for watched
ExpStarts<- Experiment %>% select(-num_watched)
ExpWatched<- Experiment %>% select(-num_starts)
head(ExpStarts)

### Execute the following code to create the remove_outliers function ###
### This function will remove outliers greater than than 3 standard deviations away from the mean ###
remove_outliers <- function (df) {
   y <- df[2][df[2] > 0] #remove any zero values
   print(paste0("mean = ", mean(y)))
   print(paste0("3sd = ",3*sd(y)))
   print(paste0("3sd + mean = ", 3*sd(y) + mean(y)))
   
   dfNoOutliers<- df%>% filter(df[2]< 3*sd(y) + mean(y)) #remove any outlisers
   valsremaining <- length(dfNoOutliers)/length(df)
   valsremaining
   
   if (valsremaining < 0.95){
      stop ("This function will remove more than 5% percent of your data. You need to remove outliers manually.")}
   
   else if (valsremaining < 0.99){
      warning("This calculation has removed between 1% and 5% of your data.") 
      print(paste0(valsremaining*100, "% has been removed"))
   }
   else{
      print("Less than 1% of data has been removed")
   }
   return(dfNoOutliers)
}

## Performs remove_outliers function on new experiment dataframe ###
ExpStarts<-remove_outliers(ExpStarts)
ExpWatched<-remove_outliers(ExpWatched)


### The following code reads in your data and uses the ggbetweenstats function to calculate your statistic and present your plot ###
###### Metric 1 - num starts ######
ggbetween_plot_starts <- ExpStarts %>%
   ggstatsplot::ggbetweenstats(
   x = Variant,
   y = num_starts, ### CHANGE THIS TO THE METRIC OF INTEREST! ###
   mean.label.size = 2.5,
   type = "parametric",       
   k = 3,
   pairwise.comparisons = TRUE,
   pairwise.annotation = "p.value",
   p.adjust.method = "bonferroni",
   title = "AB/N Test",
   messages = TRUE)

pb_starts <- ggplot_build(ggbetween_plot_starts)
results_starts<-pb_starts$plot$plot_env$df_pairwise
#View(results_starts)
results_starts
ggbetween_plot_starts


###### Metric 2 - num watched ######
ggbetween_plot_watched <- ExpWatched %>%
   ggstatsplot::ggbetweenstats(
      x = Variant,
      y = num_watched, ### CHANGE THIS TO THE METRIC OF INTEREST! ###
      mean.label.size = 2.5,
      type = "parametric",
      k = 3,
      pairwise.comparisons = TRUE,
      pairwise.annotation = "p.value",
      p.adjust.method = "bonferroni",
      title = "AB/N Test",
      messages = TRUE)

pb_watched <- ggplot_build(ggbetween_plot_watched)
results_watched<-pb_watched$plot$plot_env$df_pairwise
#View(results_watched)
results_watched
ggbetween_plot_watched



### This section of the script calculators individual uplifts between variants ###
uplift_calculator <- function(Control_Metric, Variant_Metric){
   uplift <- (Variant_Metric/Control_Metric)-1 
   uplift <- percent(uplift)
   if (uplift > 0){
      sprintf("The variant beat the control by %s", uplift, Control_Metric, Variant_Metric)
   }else{sprintf("The variant performed worse than the control by %s", uplift, Control_Metric, Variant_Metric)}
}

### Uplift calculations 

#### play starts
### Here are the means of all your varaiants ###
Control_starts <- mean(ExpStarts %>%filter(Variant == 'Control') %>% pull(num_starts))
Variant1_starts <- mean(ExpStarts %>%filter(Variant == 'Variant1') %>% pull(num_starts))
Variant2_starts <- mean(ExpStarts %>%filter(Variant == 'Variant2') %>% pull(num_starts))
### Fill in this function with your mean values ###
uplift_calculator(Control_starts, Variant1_starts)
uplift_calculator(Control_starts, Variant2_starts)
uplift_calculator(Variant1_starts, Variant2_starts)

#### play watched
### Here are the means of all your varaiants ###
Control_watched <- mean(ExpWatched %>%filter(Variant == 'Control') %>% pull(num_watched))
Variant1_watched <- mean(ExpWatched %>%filter(Variant == 'Variant1') %>% pull(num_watched))
Variant2_watched <- mean(ExpWatched %>%filter(Variant == 'Variant2') %>% pull(num_watched))
### Fill in this function with your mean values ###
uplift_calculator(Control_watched, Variant1_watched)
uplift_calculator(Control_watched, Variant2_watched)
uplift_calculator(Variant1_watched, Variant2_watched)



#### Spare

### The following code runs an Fz distribution of your cleaned data ###

ggplot(Experiment, aes(x = Metric1, y = Variant, fill = Variant)) + 
   geom_joy() + 
   xlab("Metric1")+
   ylab("Variant")+
   ggtitle("AB/N Test")+
   theme_classic()


