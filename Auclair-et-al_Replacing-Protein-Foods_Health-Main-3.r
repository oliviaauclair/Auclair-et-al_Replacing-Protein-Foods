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
# Description: Main file for calling diet health impact functions (PART 3)
#              Original code by PEC and JM
#              Adapted for this project by OA (follow notes for OA)
#
#################################################################################################################################################################


#OA
source('Auclair-et-al_Replacing-Protein-Foods_Health-Inputs-1.r')
source('Auclair-et-al_Replacing-Protein-Foods_Health-Mortality-2.r')

# Call functions

# Baseline life tables
base.life.table.male <- life.table.base('male')
base.life.table.female <- life.table.base('female')

# Separate baseline life expectancy and life years
male.life.exp <- base.life.table.male[,107:212]
female.life.exp <- base.life.table.female[,107:212]
base.life.table.male <- base.life.table.male[,1:106]
base.life.table.female <- base.life.table.female[,1:106]

# Mortality impacts
chd.impact.male <- life.table.impact('male', 'chd')
chd.impact.female <- life.table.impact('female', 'chd')
diabetes.impact.male <- life.table.impact('male', 'diabetes')
diabetes.impact.female <- life.table.impact('female', 'diabetes')
coloc.impact.male <- life.table.impact('male', 'coloc')
coloc.impact.female <- life.table.impact('female', 'coloc')

# Draft code for summarising, plotting, etc.




# Life expectancy (at birth) impacts...
chd.male.le <- chd.impact.male[1,107:212]
coloc.male.le <- coloc.impact.male[1,107:212]
diabetes.male.le <- diabetes.impact.male[1,107:212]
#OA
total.male.le <- chd.male.le + diabetes.male.le  + coloc.male.le

chd.female.le <- chd.impact.female[1,107:212]
coloc.female.le <- coloc.impact.female[1,107:212]
diabetes.female.le <- diabetes.impact.female[1,107:212]
#OA
total.female.le <- chd.female.le + diabetes.female.le + coloc.female.le

average.le <- (total.male.le + total.female.le) / 2

#OA - For M and F results combined
write.csv(average.le, file=out.file.male)

#OA - For M and F results separately
write.csv(total.male.le, file=out.file.male)
write.csv(total.female.le, file=out.file.female)





# Life year impacts...
chd.male.ly <- colSums(chd.impact.male)[1:106]
coloc.male.ly <- colSums(coloc.impact.male)[1:106]
diabetes.male.ly <- colSums(diabetes.impact.male)[1:106]
#OA
total.male.ly <- chd.male.ly + diabetes.male.ly + coloc.male.ly 

chd.female.ly <- colSums(chd.impact.female)[1:106]
coloc.female.ly <- colSums(coloc.impact.female)[1:106]
diabetes.female.ly <- colSums(diabetes.impact.female)[1:106]
#OA
total.female.ly <- chd.female.ly + diabetes.female.ly + coloc.female.ly

total.ly <- total.male.ly + total.female.ly

#OA - For M and F results combined
write.csv(total.ly, file=out.file.male)

#OA - For M and F results separately
write.csv(total.male.ly, file=out.file.male)
write.csv(total.female.ly, file=out.file.female)


