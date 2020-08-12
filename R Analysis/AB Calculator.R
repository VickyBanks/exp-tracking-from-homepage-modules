### Proxy connection to CRAN ###

proxy_url <- "http://www-cache-bol.reith.bbc.co.uk:80"
Sys.setenv(http_proxy = proxy_url, https_proxy = proxy_url, ftp_proxy = proxy_url)

### Loading packages needed ###
install.packages("ggstatsplot")
install.packages('devtools')
install.packages("robust")
install.packages("ggplot")
install.packages("ggjoy")
install.packages("ggpubr")
install.packages("readxl")
library(ggstatsplot)
library(robust)
library(ggplot2)
library(ggjoy)
library(ggpubr)
library(devtools)
library(readxl)
devtools::install_github("r-lib/rlang", build_vignettes = TRUE)

### Read in your files ###

Control <- read_excel('control.xlsx', col_names = c('Visitor_ID', 'Metric1'))
Variant <- read_excel('variant.xlsx', col_names = c('Visitor_ID', 'Metric1'))


### Execute the following code to create the remove_outliers function ###
### This function will remove outliers greater than than 3 standard deviations away from the mean ###

remove_outliers <- function (x) {
   y <- x[x > 0]
   outliers <- 3*sd(y) + mean(y)
   filtered <- x[x < outliers]
   valsremaining <- length(filtered)/length(x)
   if (valsremaining < 0.95){
      stop ("This function will remove more than 5% percent of your data. You need to remove outliers manually.")}
   
   else if (length(filtered)/length(x) < 0.99){
      warning("This calculation has removed between 1% and 5% of your data.") 
      filtered
   }
   else
   {filtered}
}

## Formats data ###

Variant$Variant <- paste("Variant")
Control$Variant <- paste("Control")
Experiment <- rbind(Control, Variant)
as.data.frame(Experiment)
View(Experiment)

## Performs remove_outliers function on new experiment dataframe ###

remove_outliers(Experiment$Metric1)

### The following code reads in your data and uses the ggbetweenstats function to calculate your statistic and present your plot ###

ggstatsplot::ggbetweenstats(
   data = Experiment,
   x = Variant,
   y = num_starts, ### CHANGE THIS TO THE METRIC OF INTEREST! ###
   mean.label.size = 2.5,
   type = "parametric",
   k = 3,
   pairwise.comparisons = TRUE,
   pairwise.annotation = "p.value",
   p.adjust.method = "bonferroni",
   title = "A/B Test",
   messages = TRUE)

### The following code runs an Fz distribution of your cleaned data ###

pb_starts<-ggplot(Experiment, aes(x = num_starts, y = Variant, fill = Variant)) + 
   geom_joy() + 
   xlab("Metric1")+
   ylab("Variant")+
   ggtitle("A/B Test")+
   theme_classic()

pb_starts$plot$plot_env$df_pairwise



