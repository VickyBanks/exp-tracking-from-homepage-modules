library(dplyr)
library(readr)


results<- read_csv("vb_rec_exp_results.csv")
head(results, n = 20)

#Summary numbers
results %>% 
  select(platform,exp_group, age_range,bbc_hid3) %>%
  distinct()%>%
  group_by(platform, exp_group, age_range) %>%
  summarise(num_hids = n())


results %>% filter(num_starts ==0 & num_watched ==0)%>%
  group_by(platform, exp_group, age_range) %>%
  select(platform,exp_group, age_range,bbc_hid3) %>%
  distinct()%>%
  summarise(num_hids = n())

results %>% group_by(platform, exp_group, age_range) %>%
  summarise(total_starts = sum(num_starts),
            total_watched = sum(num_watched))

View(results %>% select(num_watched) %>%distinct())

########################################################################
# Write out files
#Control all ages
write.csv(results %>% filter(exp_group == 'control') %>%
  select(bbc_hid3, num_starts, num_watched), "control.csv", row.names = FALSE)
#Var 1 all ages
write.csv(results %>% filter(exp_group == 'variation_1') %>%
            select(bbc_hid3, num_starts, num_watched), "variation_1.csv", row.names = FALSE)
#Var 2 all ages
write.csv(results %>% filter(exp_group == 'variation_2') %>%
            select(bbc_hid3, num_starts, num_watched), "variation_2.csv", row.names = FALSE)




