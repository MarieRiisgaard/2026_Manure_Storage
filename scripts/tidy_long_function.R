tidy_midas_global <- function(data, SampleID_column_name = "SampleID"){
  
  library(tidyverse)
    
  
  data$tax <- data$tax %>% 
    mutate(Phylum = if_else(condition = str_detect(Phylum, 'p__'), true = Phylum, false = paste0("unclassified_", Kingdom))) %>% 
    mutate(Class = if_else(condition = str_detect(Class, 'c__'), true = Class, false = paste0("unclassified_", Phylum))) %>% 
    mutate(Order = if_else(condition = str_detect(Order, 'o__'), true = Order, false = paste0("unclassified_", Class))) %>% 
    mutate(Family = if_else(condition = str_detect(Family, 'f__'), true = Family, false = paste0("unclassified_", Order))) %>% 
    mutate(Genus = if_else(condition = str_detect(Genus, 'g__'), true = Genus, false = paste0("unclassified_", Family))) %>% 
    mutate(Species = if_else(condition = str_detect(Species, 's__'), true = Species, false = paste0("unclassified_", Genus))) %>% 
    mutate(Class = str_replace(string = Class, pattern = ".*(_[a-z]__.*)", replacement = "unclassified\\1")) %>% 
    mutate(Order = str_replace(string = Order, pattern = ".*(_[a-z]__.*)", replacement = "unclassified\\1")) %>% 
    mutate(Family = str_replace(string = Family, pattern = ".*(_[a-z]__.*)", replacement = "unclassified\\1")) %>% 
    mutate(Genus= str_replace(string = Genus, pattern = ".*(_[a-z]__.*)", replacement = "unclassified\\1")) %>% 
    mutate(Species = str_replace(string = Species, pattern = ".*(_[a-z]__.*)", replacement = "unclassified\\1")) %>% 
    mutate(Phylum = if_else(str_detect(Phylum, "unclassified"), paste0(Phylum, "_", OTU), Phylum),
           Class = if_else(str_detect(Class, "unclassified"), paste0(Class, "_", OTU), Class),
           Order = if_else(str_detect(Order, "unclassified"), paste0(Order, "_", OTU), Order),
           Family = if_else(str_detect(Family, "unclassified"), paste0(Family, "_", OTU), Family),
           Genus = if_else(str_detect(Genus, "unclassified"), paste0(Genus, "_", OTU), Genus),
           Species = if_else(str_detect(Species, "unclassified"), paste0(Species, "_", OTU), Species)
    )
  
  
  tidy_test <- data %>% 
    #amp_subset_samples(Country == country) %>% 
    amp_export_long() %>%
    as_tibble() %>% 
    rename("SampleID" = SampleID_column_name) %>% 
    mutate(SampleID_n = SampleID) %>% 
    #filter(count != 0) %>%   #  <--- filtering step to make datahandling faster (8/8-22) 
    #left_join(., growth, by = c("OTU")) %>% 
    #left_join(., gut_tax, by = c("Species")) %>% 
    # replace_na(list(growth_group_assignment = 'not_known', Guild = 'not_known', gut = 'not_gut_genus')) %>% 
    # mutate(
    #   growth_group_assignment = 
    #     ifelse(str_detect(string = Genus, pattern = "unclassified") & growth_group_assignment != "not_known", yes = "not_known", no = growth_group_assignment), 
    #   growth_group_assignment = 
    #     ifelse(str_detect(string = Species, pattern = "unclassified") & growth_group_assignment != "not_known", yes = "Unclassified ASVs", no = growth_group_assignment), 
    #   Guild = 
    #     ifelse(str_detect(string = Genus, pattern = "unclassified") & Guild != "not_known", yes = "not_known", no = Guild), 
    #   Guild = 
    #     ifelse(str_detect(string = Species, pattern = "unclassified") & Guild == "not_known", yes = "Unclassified ASVs", no = Guild), 
    # ) %>% 
    nest(samples = c(SampleID_n, Kingdom, Phylum, Class, Order, Family, Genus, Species, OTU, count
                     #growth_group_assignment, gut, Guild
                     )) %>%
    mutate(samples = map(.x = samples, 
                         ~mutate(.x, 
                                 tot_count = sum(count)))) %>% 
    mutate(samples = map(.x = samples, 
                         ~mutate(.x, 
                                 rel_abun_ASV = count/tot_count*100))) %>% 
    mutate(samples = map(.x = samples, ~group_by(.x, Species) %>% mutate(rel_abun_species = sum(rel_abun_ASV)) %>% ungroup())) %>% 
    mutate(samples = map(.x = samples, ~group_by(.x, Genus) %>% mutate(rel_abun_genus = sum(rel_abun_ASV))%>% ungroup())) %>%
    ungroup()
    #mutate(samples = map(.x = samples, ~group_by(.x, growth_group_assignment) %>% mutate(rel_abun_growth = sum(rel_abun_ASV)))) %>% 
    #mutate(samples = map(.x = samples, ~group_by(.x, Guild) %>% mutate(rel_abun_guild = sum(rel_abun_ASV)))) %>% 
    #mutate(samples = map(.x = samples, ~group_by(.x, gut) %>% mutate(rel_abun_gut = sum(rel_abun_ASV)) %>% ungroup())) %>% 
    # mutate(samples = map(.x = samples, ~mutate(.x, gut = factor(gut, 
    #                                                             levels = c("gut_genus", "not_gut_genus"),
    #                                                             labels = c("__Gut bacteria__", "__Not gut<br>bacteria__"
    #                                                             ))))) %>% 
    # mutate(samples = map(.x = samples, ~mutate(.x, growth_group_assignment = factor(growth_group_assignment, 
    #                                                                                 levels = c("growing",  "disappearing", "surviving", "ambiguous", 
    #                                                                                            "not_known", "Unclassified ASVs"),
    #                                                                                 labels=c("__Growing__", "__Disapearing__", "__Surviving__", "__Ambiguous__", 
    #                                                                                          "__Not known__", "__Unclassified ASVs__"))))) %>%
    # mutate(samples = map(.x = samples, ~mutate(.x, Guild = factor(Guild, 
    #                                                               levels = c( "PAO", "nitrifiers", "filaments", "GAO", "Other", 
    #                                                                           "not_known", "Unclassified ASVs"),
    #                                                               labels = c("__PAO__","__Nitrifiers__", "__Filaments__", "__GAO__" ,"__Other__", 
    #                                                                          "__Not known__", "__Unclassified ASVs__")))))
    # 
  
    }




