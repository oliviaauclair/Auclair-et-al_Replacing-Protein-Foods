#################################################################################################################################################################
#
# Project title: Partial substitutions of animal with plant protein foods in Canadian diets	
#                have synergies and trade-offs among nutrition, health and climate outcomes	
#
# Authors: Olivia Auclair[1], Patricia Eustachio Colombo[2,3], James Milner[3,4], Sergio A. Burgos [1,5,6]

# [1] Department of Animal Science, McGill University, 21111 Lakeshore Rd, Sainte-Anne-de-Bellevue, H9X 3V9, Québec, Canada 
# [2] Department of Biosciences and Nutrition, Karolinska Institutet, Stockholm, 171 77, Sweden
# [3] Centre on Climate Change and Planetary Health, London School of Hygiene and Tropical Medicine, London, WC1E 7HT, United Kingdom
# [4] Department of Public Health, Environments and Society, London School of Hygiene and Tropical Medicine, London, WC1H 9SH, United Kingdom
# [5] Department of Medicine, McGill University, 845 Sherbrooke St W, Montréal, H3A 0G4, Québec, Canada
# [6] Metabolic Disorders and Complications Program, Research Institute of McGill University Health Centre, 1001 Decarie Blvd, Montréal, H4A 3J1, Québec, Canada
#
# Correspondence to: Sergio A. Burgos, sergio.burgos@mcgill.ca
#
# Code last modified by OA on 2023-08-03
#
# Description: Input data and pre-processing for diet health model (PART 1)
#              Original code by PEC and JM
#              Adapted for this project by OA (follow notes for OA)
#
#################################################################################################################################################################

#OA
setwd("C:/Users/olive/Desktop/CF-RS_Health-Outcomes")

# OA - Input scenario (1: red and processed meat 25%; 2: red and processed meat 50%; 3: dairy 25%; 4: dairy 50%)
# Required GHG reduction (%) (change) 
Scenario <- 1

# OA - (input 'central', 'low', or 'high' for central, lower, or upper bounds for RR)
# Exposure-response sensitivity (change depending)
er.sensitivity <- 'central'

# Output files (update accordingly) # 
eval(parse(text=paste("out.file.male <- 'male_hia_results_Scenario", Scenario, ".csv'", sep="")))
eval(parse(text=paste("out.file.female <- 'female_hia_results_Scenario", Scenario, ".csv'", sep="")))

# OA - Modelled exposure changes (1st value is change in intake of protein food for scenario 1, 2nd value for scenarios 2, etc.)
  #For % attributed to plants, set red.meat.changes.male.all, promeat.changes.male.all and milk.changes.male.all each to <- c(0, 0, 0, 0)
  #For % attributed to animals, set nuts.changes.male.all and lgmes.changes.male.all each to <- c(0, 0, 0, 0)
#Males
nuts.changes.male.all <- c(9.91, 19.57, 8.55, 17.44)
lgmes.changes.male.all <- c(11.71, 21.95, 9.93, 19.19)
redmeat.changes.male.all <- c(-15.32, -30.65, 0, 0)
promeat.changes.male.all <- c(-6.67, -13.34, 0, 0)
milk.changes.male.all <- c(0, 0, -41.13, -82.26)

  #For % attributed to plants, set red.meat.changes.female.all, promeat.changes.female.all and milk.changes.female.all each to <- c(0, 0, 0, 0)
  #For % attributed to animals, set nuts.changes.female.all and lgmes.changes.female.all each to <- c(0, 0, 0, 0)
#Females
nuts.changes.female.all <- c(5.62, 11.22, 9.85, 18.31)
lgmes.changes.female.all <- c(5.54, 11.92, 10.36, 19.14)
redmeat.changes.female.all <- c(-9.58, -19.17, 0, 0)
promeat.changes.female.all <- c(-3.08,-6.15, 0, 0)
milk.changes.female.all <- c(0, 0, -35.80, -71.59)

#OA - Exposure changes
#Males
redmeat.change.male <- redmeat.changes.male.all[Scenario]
promeat.change.male <- promeat.changes.male.all[Scenario]
milk.change.male <- milk.changes.male.all[Scenario]
nuts.change.male <- nuts.changes.male.all[Scenario]
lgmes.change.male <- lgmes.changes.male.all[Scenario]

#Females
redmeat.change.female <- redmeat.changes.female.all[Scenario]
promeat.change.female <- promeat.changes.female.all[Scenario]
milk.change.female <- milk.changes.female.all[Scenario]
nuts.change.female <- nuts.changes.female.all[Scenario]
lgmes.change.female <- lgmes.changes.female.all[Scenario]

################################################################################

#OA - Time-varying functions provided by PEC

# Read in disease-specific time-varying functions
chd.time.function <- read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/chd_time_function.csv', header=FALSE)
diabetes.time.function <- read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/diabetes_time_function.csv', header=FALSE)
coloc.time.function <- read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/coloc_time_function.csv', header=FALSE)

#OA
# Read in life table population data
male.population <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/population_male.csv', header=TRUE))
female.population <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/population_female.csv', header=TRUE))

# Read in baseline all-cause mortality
male.allcause.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/allcause_male.csv', header=TRUE))
female.allcause.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/allcause_female.csv', header=TRUE))

# Read in baseline disease-specific mortality
male.chd.disease.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/chd_male.csv', header=TRUE))
female.chd.disease.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/chd_female.csv', header=TRUE))
male.diabetes.disease.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/diabetes_male.csv', header=TRUE))
female.diabetes.disease.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/diabetes_female.csv', header=TRUE))
male.coloc.disease.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/coloc_male.csv', header=TRUE))
female.coloc.disease.mort <- as.matrix(read.csv(file='C:/Users/olive/Desktop/CF-RS_Health-Outcomes/coloc_female.csv', header=TRUE))

# Relative risks (with denominators)

if (er.sensitivity == 'central') {
  
  #OA - Ischemic heart disease
  lgmes.chd.rr <- 0.81
  lgmes.chd.inc <- 50
  nuts.chd.rr <- 0.91
  nuts.chd.inc <- 4.05
  promeat.chd.rr <- 0.64
  promeat.chd.inc <- -50
  
  #OA - Colorectal cancer
  redmeat.coloc.rr <- 0.86
  redmeat.coloc.inc <- -100
  promeat.coloc.rr <- 0.85
  promeat.coloc.inc <- -50
  milk.coloc.rr <- 1.11
  milk.coloc.inc <- -226.8
  
  #OA - Type 2 diabetes
  nuts.diabetes.rr <- 0.96
  nuts.diabetes.inc <- 4.05
  redmeat.diabetes.rr <- 0.82
  redmeat.diabetes.inc <- -100
  promeat.diabetes.rr <- 0.62
  promeat.diabetes.inc <- -50
  
} else if (er.sensitivity == 'low') {
  
  #OA - Ischemic heart disease
  lgmes.chd.rr <- 0.72
  lgmes.chd.inc <- 50
  nuts.chd.rr <- 0.88
  nuts.chd.inc <- 4.05
  promeat.chd.rr <- 0.48
  promeat.chd.inc <- -50

  #OA - Colorectal cancer
  redmeat.coloc.rr <- 0.76
  redmeat.coloc.inc <- -100
  promeat.coloc.rr <- 0.79
  promeat.coloc.inc <- -50
  milk.coloc.rr <- 1.04
  milk.coloc.inc <- -226.8
  
  #OA - Type 2 diabetes
  nuts.diabetes.rr <- 0.95
  nuts.diabetes.inc <- 4.05
  redmeat.diabetes.rr <- 0.71
  redmeat.diabetes.inc <- -100
  promeat.diabetes.rr <- 0.54
  promeat.diabetes.inc <- -50
  
} else if (er.sensitivity == 'high') {
  
  #OA - Ischemic heart disease
  lgmes.chd.rr <- 0.91
  lgmes.chd.inc <- 50
  nuts.chd.rr <- 0.94
  nuts.chd.inc <- 4.05
  promeat.chd.rr <- 0.98
  promeat.chd.inc <- -50

  #OA - Colorectal cancer
  redmeat.coloc.rr <- 0.97
  redmeat.coloc.inc <- -100
  promeat.coloc.rr <- 0.91
  promeat.coloc.inc <- -50
  milk.coloc.rr <- 1.2
  milk.coloc.inc <- -226.8
  
  #OA - Type 2 diabetes
  nuts.diabetes.rr <- 0.98
  nuts.diabetes.inc <- 4.05
  redmeat.diabetes.rr <- 0.97
  redmeat.diabetes.inc <- -100
  promeat.diabetes.rr <- 0.79
  promeat.diabetes.inc <- -50
  
}

# Changes in risk
#OA - Ischemic heart disease
chd.risk.change.male <- (exp((log(lgmes.chd.rr) / lgmes.chd.inc) * lgmes.change.male)) *
  (exp((log(nuts.chd.rr) / nuts.chd.inc) * nuts.change.male)) *
  (exp((log(promeat.chd.rr) / promeat.chd.inc) * promeat.change.male))
chd.risk.change.female <- (exp((log(lgmes.chd.rr) / lgmes.chd.inc) * lgmes.change.female)) *
  (exp((log(nuts.chd.rr) / nuts.chd.inc) * nuts.change.female)) *
  (exp((log(promeat.chd.rr) / promeat.chd.inc) * promeat.change.female))

#OA - Colorectal cancer
coloc.risk.change.male <- (exp((log(promeat.coloc.rr) / promeat.coloc.inc) * promeat.change.male)) *
  (exp((log(redmeat.coloc.rr) / redmeat.coloc.inc) * redmeat.change.male)) *
  (exp((log(milk.coloc.rr) / milk.coloc.inc) * milk.change.male))
coloc.risk.change.female <- (exp((log(promeat.coloc.rr) / promeat.coloc.inc) * promeat.change.female)) *
  (exp((log(redmeat.coloc.rr) / redmeat.coloc.inc) * redmeat.change.female)) *
  (exp((log(milk.coloc.rr) / milk.coloc.inc) * milk.change.female))

#OA - Type 2 diabetes
diabetes.risk.change.male <- (exp((log(promeat.diabetes.rr) / promeat.diabetes.inc) * promeat.change.male)) *
  (exp((log(redmeat.diabetes.rr) / redmeat.diabetes.inc) * redmeat.change.male)) *
  (exp((log(nuts.diabetes.rr) / nuts.diabetes.inc) * nuts.change.male))
diabetes.risk.change.female <- (exp((log(promeat.diabetes.rr) / promeat.diabetes.inc) * promeat.change.female)) *
  (exp((log(redmeat.diabetes.rr) / redmeat.diabetes.inc) * redmeat.change.female)) *
  (exp((log(nuts.diabetes.rr) / nuts.diabetes.inc) * nuts.change.female))

# Time frame
time.frame <- 106 # 106 years