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
# Code not modified from original
#
# Description: Mortality impacts for diet model (PART 2)
#              Original code by PEC and JM
#
#################################################################################################################################################################

# Baseline life tables

life.table.base <- function(gender) {
  
  # Set input data depending on gender  
  eval(parse(text=paste("population <- ", gender, ".population", sep="")))
  eval(parse(text=paste("allcause.mort <- ", gender, ".allcause.mort", sep="")))
  
  # Age range
  age <- matrix(c(0:105), 106, 1)
  
  # Hazard rates
  all.hazard <- matrix(0, nrow(age), 106)
  all.hazard[,1:106] <- allcause.mort[,1] / population[,1]
  
  # Survival probability
  surv <- (2 - all.hazard) / (2 + all.hazard)
  
  # Cumulative survival
  cum.surv <- matrix(0, nrow(age), 106)
  cum.surv[,1] <- surv[,1]
  cum.surv[1,2:106] <- surv[1,2:106]
  func3 <- function(i,year) {
    cum.surv[i-1,year-1] * surv[i,year]
  }
  for (i in 2:106) {
    cum.surv[2:(nrow(age)-1),i] <- mapply(func3,2:(nrow(age)-1),i)
  }
  cum.surv[nrow(age),] <- 0
  
  # Starting population
  start.pop <- matrix(0, nrow(age), 106)
  start.pop[,1] <- population[,1]
  start.pop[1,] <- population[1,]  
  for (i in 2:106) {
    for (j in 2:106) {
      start.pop[i,j] <- start.pop[i-1,j-1] * surv[i-1,j-1]
    }
  }
  #start.pop[2:106,2:106] <- cum.surv[1:105,1:105]
  
  # Expected deaths
  exp.deaths <- start.pop * (1 - surv)  
  
  # Life years lived
  life.years <- start.pop - (0.5 * exp.deaths)
  
  # Expected life years
  exp.life.years <- matrix(0, nrow(age)+1, 107)
  for (i in 106:1) {
    for (j in 106:1) {
      exp.life.years[i,j] <- exp.life.years[i+1,j+1] + life.years[i,j]
    }
  }
  
  exp.life.years <- exp.life.years[1:106,1:106]
  
  # Life expectancy
  life.exp <- exp.life.years/start.pop
  
  return(cbind(life.years, life.exp))
  
}

# Mortality impact function

life.table.impact <- function(gender, disease) {
  
  ##############################################################################
  #
  # FUNCTION NAME: mortality.current
  #
  # DESCRIPTION: Performs life table calculations for the population
  #
  # INPUTS: disease
  #
  ##############################################################################
  
  # Input data
  eval(parse(text=paste("population <- ", gender, ".population", sep="")))
  eval(parse(text=paste("allcause.mort <- ", gender, ".allcause.mort", sep="")))
  eval(parse(text=paste("disease.mort <- ", gender,".", disease, ".disease.mort", sep="")))
  eval(parse(text=paste("time.function.values <- ", disease, ".time.function", sep="")))
  eval(parse(text=paste("risk.change <- ", disease, ".risk.change.", gender, sep="")))
  eval(parse(text=paste("life.years <- base.life.table.", gender, sep="")))
  
  # Age range
  age <- matrix(c(0:105), 106, 1)
  
  # Calculate disease-specific and all other cause mortality
  other.mort <- matrix(0, nrow(age), 106)
  other.mort[,1:106] <- allcause.mort[,1] - disease.mort[,1]
  disease.hazard <- matrix(0, nrow(age), 106)
  disease.hazard[,1:106] <- disease.mort[,1] / population[,1]
  other.hazard <- matrix(0, nrow(age), 106)
  other.hazard[,1:106] <- other.mort[,1] / population[,1]
  
  # Impacted life tables over 106 years
  
  # Apply time functions over first 20 years (time function different for increasing and decreasing exposure)

  func1 <- function(year) {
    if (risk.change >= 1) {
      1 + ((risk.change - 1) * pnorm(year, mean=time.function.values[1,], sd=time.function.values[2,]))
    } else if (risk.change < 1) {
      #1 - ((1 - risk.change) * (1 - exp(-(time.function.values[3,]) * year)))
      1 - ((1 - risk.change) * pnorm(year, mean=time.function.values[1,], sd=time.function.values[2,]))
    }
  }
  
  annual.disease.impact <- matrix(0, 1, 106)
  annual.disease.impact[,1:30] <- sapply(1:30, func1)
  annual.disease.impact[,31:106] <- risk.change
  
  # Repeat over each row
  rep.row <- function(x,n) {
    matrix(rep(x,each=n),nrow=n)
  }
  annual.disease.impact <- rep.row(annual.disease.impact, nrow(age))
  
  # Impacted hazards
  impacted.disease.hazard <- disease.hazard * annual.disease.impact                                                                      
  impacted.all.hazard <- impacted.disease.hazard + other.hazard
  
  # Impacted survival probability
  impacted.surv <- (2 - impacted.all.hazard) / (2 + impacted.all.hazard)
  
  # Impacted cumulative survival
  impacted.cum.surv <- matrix(0, nrow(age), 106)
  impacted.cum.surv[,1] <- impacted.surv[,1]
  impacted.cum.surv[1,2:106] <- impacted.surv[1,2:106]
  func3 <- function(i,year) {
    impacted.cum.surv[i-1,year-1] * impacted.surv[i,year]
  }
  for (i in 2:106) {
    impacted.cum.surv[2:(nrow(age)-1),i] <- mapply(func3,2:(nrow(age)-1),i)
  }
  impacted.cum.surv[nrow(age),] <- 0
  
  # Impacted starting population (in this case 1 person)
  impacted.start.pop <- matrix(0, nrow(age), 106)
  impacted.start.pop[,1] <- population[,1]
  impacted.start.pop[1,] <- population[1,]  
  for (i in 2:106) {
    for (j in 2:106) {
      impacted.start.pop[i,j] <- impacted.start.pop[i-1,j-1] * impacted.surv[i-1,j-1]
    }
  }
  #impacted.start.pop[2:106,2:106] <- cum.surv[1:105,1:105]
  
  # Impacted expected deaths
  impacted.exp.deaths <- impacted.start.pop * (1 - impacted.surv)  
  
  # Impacted life years lived
  impacted.life.years <- impacted.start.pop - (0.5 * impacted.exp.deaths)
  
  # Expected life years
  impacted.exp.life.years <- matrix(0, nrow(age)+1, 107)
  for (i in 106:1) {
    for (j in 106:1) {
      impacted.exp.life.years[i,j] <- impacted.exp.life.years[i+1,j+1] + impacted.life.years[i,j]
    }
  }
  
  impacted.exp.life.years <- impacted.exp.life.years[1:106,1:106]
  
  # Life expectancy
  impacted.life.exp <- impacted.exp.life.years/impacted.start.pop
  
  eval(parse(text=paste("diff.life.exp <- 365 * (impacted.life.exp - ", gender, ".life.exp)", sep="")))
  
  # Difference in life years compared to baseline
  diff.life.years <- impacted.life.years - life.years
  
  return(cbind(diff.life.years, diff.life.exp))
  
}

