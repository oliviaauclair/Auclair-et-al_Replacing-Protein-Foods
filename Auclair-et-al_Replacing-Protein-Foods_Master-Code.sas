
/**********************************************************************************************************************************************************************
																	  							
	Project title: Partial substitutions of animal with plant protein foods in Canadian diets	
				   have synergies and trade-offs among nutrition, health and climate outcomes	
 											 	  												
	Authors: Olivia Auclair[1], Patricia Eustachio Colombo[2,3], James Milner[3,4], Sergio A. Burgos [1,5,6]

		[1] Department of Animal Science, McGill University, 21111 Lakeshore Rd, Sainte-Anne-de-Bellevue, H9X 3V9, Québec, Canada 
		[2] Department of Biosciences and Nutrition, Karolinska Institutet, Stockholm, 171 77, Sweden
		[3] Centre on Climate Change and Planetary Health, London School of Hygiene and Tropical Medicine, London, WC1E 7HT, United Kingdom
		[4] Department of Public Health, Environments and Society, London School of Hygiene and Tropical Medicine, London, WC1H 9SH, United Kingdom
		[5] Department of Medicine, McGill University, 845 Sherbrooke St W, Montréal, H3A 0G4, Québec, Canada
		[6] Metabolic Disorders and Complications Program, Research Institute of McGill University Health Centre, 1001 Decarie Blvd, Montréal, H4A 3J1, Québec, Canada

	Correspondence to: Sergio A. Burgos, sergio.burgos@mcgill.ca

	Code last modified by OA on 2023-07-11														
																  							
**********************************************************************************************************************************************************************/

/***********************************************************************/
/*																	   */
/* STEP 1 - Merge HS file with 24-h recalls							   */
/*																	   */
/***********************************************************************/

/***********************************************************************/
/* Step 1.1: Merge 24-h recall files with food descriptions 		   */
/***********************************************************************/

/*FID file (24-h recalls, multiple records per respondent)*/
libname fid "S:\CCHS_ESCC_2015_NU\CCHS_ESCC_2015_NU_v3\data_donnees\data\sas_en\FID";
data fid; set fid.cchs_2015_fid_nofmt_f1_v2;
run;
	
	/*Summary FID file (only keep variables of interest for clarity)*/
	data fid_smry;
		set fid;
		keep sampleid suppid seqid fid_fid fid_cde fid_fgr fid_wtg fid_ekc fid_fas fid_pro fid_dmg fid_cal fid_iro fid_sod fid_pot fid_car fid_fap fid_fam;
	run; 

/*FDC file (food descriptions, 1 record per food)*/
libname fdc "S:\CCHS_ESCC_2015_NU\CCHS_ESCC_2015_NU_v3\data_donnees\data\sas_en\FDC";
data fdc; set fdc.cchs_2015_nu_fdc_f1_nofmt_v3;
run;

	/*Summary FDC file (only keep variables of interest for clarity)*/
	data desc_smry;
		set fdc;
		keep fid_cde fdc_den /*fdc_ekc fdc_pro fdc_sug fdc_fas fdc_dmg fdc_cal fdc_iro fdc_sod fdc_pot*/;
	run;

/*Merge FID and FDC files*/
proc sort data=fid_smry; by fid_cde; run;
proc sort data=desc_smry; by fid_cde; run;

data rclls;
	merge fid_smry desc_smry;
	by fid_cde;
	if suppid=. then delete;
run;

/***********************************************************************/
/* Step 1.2: Link CCHS foods to free sugars database				   */
/***********************************************************************/

/*Free sugars database (Rana et al., 2021)*/
proc import datafile='K:\Replacement Scenarios (CF-RS)\CF-RS_Data-Files\free_sugars.xlsx'
out=freesug
dbms=xlsx
replace;
run;
/*7,041 observations*/

data freesug_v2;
	set freesug;
	fid_cde=input(code, best12.);
run; 
/*7,041 observations*/

proc sort data=freesug_v2; by fid_cde; run;
proc sort data=rclls; by fid_cde; run;

data rclls_v2;
	merge rclls freesug_v2;
	by fid_cde;
	if suppid=. then delete;
	/*Set missing values for fid_wtg to .*/
	if fid_wtg > 99999 then fid_wtg=.;	
	/*Express free sugars per g (instead of per 100 g) and multiply by food weight*/					
	if free_sug ne . and free_sug ne 0 and fid_wtg ne . then free_sug_g=fid_wtg*(free_sug/100);
	if free_sug=0 then free_sug_g=0;
	if free_sug=. then free_sug_g=.;
	drop code description /*free_sug*/;
run;

proc means n nmiss mean min max data=rclls_v2;
	var free_sug free_sug_g;
run;

/***********************************************************************/
/* Step 1.3: Apply exlcusion criteria to HS file					   */
/***********************************************************************/

/*HS file (1 record per respondent)*/
libname hs "S:\CCHS_ESCC_2015_NU\CCHS_ESCC_2015_NU_v3\data_donnees\data\sas_en\HS";
data hs; set hs.cchs_2015_nu_hs_nofmt_f1_v2;
run;
/*20,487 observations*/

data hs_exclu;
	set hs;
	/*Excusion criteria*/
	if dhh_age <19 then delete;								/*Respondents <19 y*/
	if whc_03=1 then delete;								/*Pregnant women*/
	if whc_05=1 then delete;								/*Breastfeeding women*/
	/*Respondents that did not complete a 24-h recall*/
	if sampleid='1207019131002865079_'
	or sampleid='3518029531110247512_'
	or sampleid='3520483061118731181_'
	or sampleid='35D0741841124421623_' then delete;
	id=1;													/*Variable to identify sample respondents post exclusion critiera*/	
	keep sampleid id fsddfas fsddfam fsddfap fsddsod fsddekc;								
run;
/*n = 13,612 observations (Master Files)*/

/*20,487 - 13,919 (<19 y) = 6,568 (32.06%)
13,919 - 13,803 (pregnant) = 116 (0.57%)
13,803 - 13,616 (breastfeeding) = 187 (0.09%)
13,616 - 13,612 (no 24-h recall) = 4 (0.02%)

/***********************************************************************/
/* Step 1.4: Merge HS file with 24-h recalls file 					   */
/***********************************************************************/

proc sort data=hs_exclu; by sampleid; run;
proc sort data=rclls_v2; by sampleid; run;

/*This file contains the 24-h recalls of CCHS sample (exclusion criteria applied)*/
data hs_rclls;
	merge hs_exclu rclls_v2;
	by sampleid;
	if id=1;
	/*Set missing values for energy and nutrients to .*/
	if fid_ekc > 99999 then fid_ekc=.;						/*Energy*/
	/*if fid_sug > 99999 then fid_sug=.;					/*Sugar*/
	if fid_fas > 99999 then fid_fas=.;						/*Saturated fat*/
	if fid_pro > 99999 then fid_pro=.;						/*Protein*/
	if fid_dmg > 99999 then fid_dmg=.;						/*Vitamin D*/
	if fid_cal > 99999 then fid_cal=.;						/*Calcium*/
	if fid_iro > 99999 then fid_iro=.;						/*Iron*/
	if fid_sod > 99999 then fid_sod=.;						/*Sodium*/
	if fid_pot > 99999 then fid_pot=.;						/*Potassium*/
	if fid_car > 99999 then fid_car=.;						/*Carbs*/
	if fid_fam > 99999 then fid_fam=.;						/*MUFAs*/
	if fid_fap > 99999 then fid_fap=.;						/*PUFAs*/
	drop id;
run;
/*653,861 observations (PUMF)*/
/*648,495 observations (Master Files)*/

proc sort data=hs_rclls; by sampleid suppid seqid; run;

/*Check for missing values*/
proc means n nmiss min max data=hs_rclls;
	var fid_wtg fid_ekc fid_pro fid_fas fid_dmg fid_cal fid_iro fid_sod fid_pot fid_car;
run;

/***********************************************************************/
/*																	   */
/* STEP 2 - Link dataFIELD to CCHS foods							   */
/*																	   */
/***********************************************************************/

/***********************************************************************/
/* Step 2.1: Merge FCID Recipe Database and WWEIA food descriptions    */
/***********************************************************************/

/*FCID Recipe Database*/
proc import datafile='K:\Carbon Footprint Manuscript (CF-HD)\CF_HD_Jan 2021_Data\wweia.xlsx'
out=wweia
dbms=xlsx
replace;
run;
/*129,863 observations*/

/*WWEIA food descriptions*/
proc import datafile='K:\Carbon Footprint Manuscript (CF-HD)\CF_HD_Jan 2021_Data\wweia_descriptions.xlsx'
out=wweia_dscrpt
dbms=xlsx
replace;
run;
/*7,154 observations*/

proc sort data=wweia; by food_code; run;
proc sort data=wweia_dscrpt; by food_code; run;

/*Merge WWEIA foods with their descriptions*/
data wweia_all;
	merge wweia wweia_dscrpt;
	by food_code;
	/*Keeping only default recipes*/
	if mod_code=0	
	/*15 foods did not have a default recipe*/	
	or food_code=13210530 or food_code=24174200 or food_code=24175200
	or food_code=26141130 or food_code=27450660 or food_code=56103020
	or food_code=56207210 or food_code=56208540 or food_code=58126120
	or food_code=71962020 or food_code=72113220 or food_code=72128421
	or food_code=75207023 or food_code=75220023 or food_code=75233023;
	/*Out of these 15 foods, 3 had more than one mod_code*/
	if mod_code=203966 or mod_code=206868 or mod_code=206524 then delete;
	keep food_code mod_code ingredient_num fcid_code commodity_weight food_desc;
run;
/*77,005 observations*/
/*7,154 foods*/

/***********************************************************************/
/* Step 2.2: Link ghge and food loss estimates to WWEIA foods by cmdty */
/***********************************************************************/

/*dataFIELD*/
proc import datafile='K:\Carbon Footprint Manuscript (CF-HD)\CF_HD_Jan 2021_Data\datafield.xlsx'
out=datafield
dbms=xlsx
replace;
run;
/*354 commodities*/

/*Custom food loss dataset*/
proc import datafile='K:\Carbon Footprint Manuscript (CF-HD)\CF_HD_Jan 2021_Data\food_loss.xlsx'
out=foodloss
dbms=xlsx
replace;
run;
/*354 commodities*/

data foodloss;
	set foodloss;
	keep fcid_code total_loss;
run;

proc sort data=wweia_all; by fcid_code; run;
proc sort data=datafield; by fcid_code; run;
proc sort data=foodloss; by fcid_code; run;

data mrg_fcid_cde; 
	merge wweia_all datafield foodloss;
	by fcid_code;
	
	/*A handful of foods have a commodity weight >100, which I cannot explain*/

	/*Creating a variable to express commodity weight as a proportion*/
	cmdty_pcnt=commodity_weight/100;

	/*Creating a variable for ghge per commodity*/
	ghge_kg_cmdty=cmdty_pcnt*ghge;

	/*Creating a variable for total ghge per kg of commodity accounting for losses*/	
	ghge_loss_kg_cmdty=cmdty_pcnt*ghge*(100/(100-total_loss)); 

run;

/***********************************************************************/
/* Step 2.3: Aggregate ghge per WWEIA food 							   */
/***********************************************************************/

proc sort data=mrg_fcid_cde; by food_code ingredient_num; run;

proc sql;
	create table ghge_cmdty_sum as
	select Food_Code,
	/*Aggregate ghge per WWEIA food*/
	sum (ghge_kg_cmdty) as ghge_kg_food,
	/*Aggregate ghge accounting for food loss per WWEIA food*/
	sum (ghge_loss_kg_cmdty) as ghge_loss_kg_food from mrg_fcid_cde
	group by Food_Code;
quit;
/*7,154 foods*/

/*Merge WWEIA foods back with descriptions*/
proc sort data=ghge_cmdty_sum; by food_code; run;
proc sort data=wweia_dscrpt; by food_code; run;

data wweia_ghge;
	merge ghge_cmdty_sum wweia_dscrpt;
	by food_code;
	drop food_abbrev_desc;
run;
/*7,154 foods*/

/***********************************************************************/
/* Step 2.4: Link WWEIA foods to CCHS foods 						   */
/***********************************************************************/

/*Import NSS-FNDDS Linkage dataset obtained from Dr. Sharon Kirkpatrick, U of Waterloo, which links WWEIA with CCHS foods*/
proc import datafile='K:\Carbon Footprint Manuscript (CF-HD)\CF_HD_Jan 2021_Data\nss_fndds_sk.xlsx'
out=nss_fndds_sk
dbms=xlsx
replace;
run;
/*5,180 observations*/

/*Nearly 500 foods in NSS-FNDDS Linkage dataset did not link to WWEIA foods in the FCID Recipe Database.
This file contains those missing foods, along with 'alternate' FNDDS food codes, which I
assigned by searching for matching/similar codes in the FCID Recipe Database. These alternate
codes are used to replace NSS-FNDDS Linkage dataset's codes to ensure proper and comprehansive linking. In total,
499 foods did not link. The file below contains 489 foods. The remaining 10 lack FCID codes
and thus were not linked to GHGE at the commodity level. They are, however, captured in the 
'exception foods' step below.*/
 
/*OA's dataset containing alternate codes for WWEIA foods for those that did not link to CCHS foods*/
proc import datafile='K:\Carbon Footprint Manuscript (CF-HD)\CF_HD_Jan 2021_Data\nss_fndds_miss.xlsx'
out=nss_fndds_miss
dbms=xlsx
replace;
run;
/*489 observations*/

data nss_fndds_miss2;
	set nss_fndds_miss;
	keep fid_cde id alternate_fndds_code alternate_fndds_description;
run;

proc sort data=nss_fndds_sk; by fid_cde; run;
proc sort data=nss_fndds_miss2; by fid_cde; run;

/*Replace WWEIA food codes with alternate codes*/
data nss_fndds;
	merge nss_fndds_sk nss_fndds_miss2;
	by fid_cde;
	/*Replacing NSS-FNDDS Linkage dataset's FNDDS codes with those manually picked from the FCID Recipe Database*/
	if id=1 then food_code=alternate_fndds_code;
run;
/*5,180 observations*/	

/*Link CCHS foods to their GHGE*/
proc sort data=wweia_ghge; by food_code; run;
proc sort data=nss_fndds; by food_code; run;

data cchs_ghge;
	merge nss_fndds wweia_ghge;
	by food_code;
	if fid_cde=. then delete;
run;
/*5,180 observations*/

proc means n nmiss data=cchs_ghge;
	var ghge_kg_food ghge_loss_kg_food;
run;
/*465 CCHS foods in NSS-FNDDS Linkage dataset's with no ghge*/

/***********************************************************************/
/* Step 2.5: Link ghge to CCHS foods in the FID file				   */
/***********************************************************************/

data cchs_ghge2;
	set cchs_ghge;
	length fid_cde 6;
run;

proc sort data=hs_rclls; by fid_cde; run;
proc sort data=cchs_ghge2; by fid_cde; run;

/*Link CCHS foods as consumed by sample to GHGE*/
/*Exclusion criteria already applied in hs_fid*/
data rclls_ghge;
	merge hs_rclls cchs_ghge2;
	by fid_cde;
	if suppid=. then delete;
run;

/***********************************************************************/
/* STEP 2.6: Link GHGE for exception foods directly to CCHS foods 	   */
/***********************************************************************/

/*Heller et al., 2018 noted a handful of foods that they linked directly to LCA values,
since these provided better estimates than ones aggregate from dataFIELD commodities.
This is what we are doing here. We are also linking estimates for dairy products from
Verge et al., 2013 directly to CCHS foods since these provided better estimates than proxies
in dataFIELD. Many spices were in the CCHS but not dataFIELD, so we used dataFIELD value for 
Spices, other = 0.87 as a proxy for most missing ones.*/

data rclls_ghge_ovrd;
	set rclls_ghge;

	/*Loss values from Statistics Canada unless otherwise specified*/
	/*EQUATION: ghge_loss_kg_cmdty=cmdty_pcnt*ghge*(100/(100-total_loss))*/
	/*In this case, cmdty_pcnt=1*/

	/*CHEESE*/
	if fid_fgr="14B" or fid_fgr="14C" or fid_fgr="14D" then ghge_kg_food=5.3;
	if fid_fgr="14B" or fid_fgr="14C" or fid_fgr="14D" then ghge_loss_kg_food=5.3*(100/(100-20.1));

	/*COTTAGE CHEESE*/
	if fid_fgr="14A" then ghge_kg_food=1.8;
	if fid_fgr="14A" then ghge_loss_kg_food=1.8*(100/(100-40));

	/*YOGHURT (incl. frozen yogurt)*/
	if fid_fgr="15A" or fid_fgr="15B" or fid_fgr="09C" then ghge_kg_food=1.5;
	if fid_fgr="15A" or fid_fgr="15B" or fid_fgr="09C" then ghge_loss_kg_food=1.5*(100/(100-30.5));

	/*MILK (incl. eggnog)*/
	if fid_fgr="10A" or fid_fgr="10B" or fid_fgr="10C" or fid_fgr="10D" or fid_cde=55 then ghge_kg_food=1;
	if fid_fgr="10A" or fid_fgr="10B" or fid_fgr="10C" or fid_fgr="10D" or fid_cde=55 then ghge_loss_kg_food=1*(100/(100-29.5));

	/*BUTTERMILK*/
	if fid_cde=124 or fid_cde=5487 or fid_cde=7024 then ghge_kg_food=1.1;
	if fid_cde=124 or fid_cde=5487 or fid_cde=7024 then ghge_loss_kg_food=1.1*(100/(100-28.1));

	/*MILK POWDER (incl. whey and buttermilk powder)*/
	if fid_cde=67 or fid_cde=78 or fid_cde=80 or fid_cde=115 or fid_cde=134 or fid_cde=2896 or fid_cde=2900 then ghge_kg_food=10.1;
	if fid_cde=67 or fid_cde=78 or fid_cde=80 or fid_cde=115 or fid_cde=134 or fid_cde=2896 or fid_cde=2900 then ghge_loss_kg_food=10.1*(100/(100-42));

	/*CONCENTRATED MILK*/
	if fid_fgr="10E" or fid_fgr="10F" or fid_fgr="10G" or fid_fgr="10H" then ghge_kg_food=3.1;
	if fid_fgr="10E" or fid_fgr="10F" or fid_fgr="10G" or fid_fgr="10H" then ghge_loss_kg_food=3.1*(100/(100-25.5));

	/*CREAM*/
	if fid_fgr="13A" or fid_fgr="13B" or fid_fgr="13C" then ghge_kg_food=2.1;
	if fid_fgr="13A" or fid_fgr="13B" or fid_fgr="13C" then ghge_loss_kg_food=2.1*(100/(100-22.6));

	/*SOUR CREAM*/
	if fid_fgr="13D" then ghge_kg_food=2.5;
	if fid_fgr="13D" then ghge_loss_kg_food=2.5*(100/(100-19.2));

	/*BUTTER*/
	if fid_fgr="17A" then ghge_kg_food=7.3;
	if fid_fgr="17A" then ghge_loss_kg_food=7.3*(100/(100-39.4));

	/*FROZEN DAIRY (incl. milk shakes)*/
	if fid_fgr="09A" or fid_fgr="09B" or fid_cde=75 or fid_cde=76 or fid_cde=4165 or fid_cde=5857 or fid_cde=7294 then ghge_kg_food=2.1;
	if fid_fgr="09A" or fid_fgr="09B" or fid_cde=75 or fid_cde=76 or fid_cde=4165 or fid_cde=5857 or fid_cde=7294 then ghge_loss_kg_food=2.1*(100/(100-33));

	/*TOFU*/
	/*Loss factor=fluid milk (proxy for soy milk)*/
	if fid_fgr="37B" then ghge_kg_food=1.664;
	if fid_fgr="37B" then ghge_loss_kg_food=1.664*(100/(100-29.54));												

	/*CARBONATED DRINKS*/
	if fid_fgr="46A" or fid_fgr="46B" then ghge_kg_food=0.066;
	if fid_fgr="46A" or fid_fgr="46B" then ghge_loss_kg_food=0.066*(100/(100-15.4));

	/*BEER*/
	if fid_fgr="49A" or fid_fgr="49B" then ghge_kg_food=0.315;
	if fid_fgr="49A" or fid_fgr="49B" then ghge_loss_kg_food=0.315*(100/(100-7.8));

	/*LIQUOR*/
	if fid_fgr="47A" or fid_fgr="47B" then ghge_kg_food=2.171;
	if fid_fgr="47A" or fid_fgr="47B" then ghge_loss_kg_food=2.171*(100/(100-7.85));

	/*SNAIL*/
	if fid_cde=5635 then ghge_kg_food=0.7;
	if fid_cde=5635  then ghge_loss_kg_food=0.7*(100/(100-45.7));

	/*SPICES*/	
	/*Loss values from LAFA*/	
	if fid_cde=169 then ghge_kg_food=0.87; if fid_cde=169 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, allspice, ground*/
	if fid_cde=171 then ghge_kg_food=2.495; if fid_cde=171 then ghge_loss_kg_food=2.495*(100/(100-13.33));			/*Spices, basil, dried*/
	if fid_cde=173 then ghge_kg_food=0.87; if fid_cde=173 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, caraway seed*/
	if fid_cde=175 then ghge_kg_food=0.87; if fid_cde=175 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, celery seed*/
	if fid_cde=177 then ghge_kg_food=0.87; if fid_cde=177 then ghge_loss_kg_food=0.87*(100/(100-13.33));	 		/*Spices, chili powder*/
	if fid_cde=178 then ghge_kg_food=0.87; if fid_cde=178 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, cinnamon, ground*/ 
	if fid_cde=179 then ghge_kg_food=0.87; if fid_cde=179 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, cloves, ground*/
	if fid_cde=180 then ghge_kg_food=0.87; if fid_cde=180 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, coriander leaf (cilantro), dried*/
	if fid_cde=182 then ghge_kg_food=0.87; if fid_cde=182 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, cumin seed*/
	if fid_cde=183 then ghge_kg_food=0.87; if fid_cde=183 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, curry powder*/
	if fid_cde=184 then ghge_kg_food=0.87; if fid_cde=184 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, dill seed*/
	if fid_cde=186 then ghge_kg_food=0.87; if fid_cde=186 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, fennel seed*/
	if fid_cde=188 then ghge_kg_food=0.87; if fid_cde=188 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, garlic powder*/
	if fid_cde=189 then ghge_kg_food=0.87; if fid_cde=189 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, ginger, ground*/
	if fid_cde=190 then ghge_kg_food=0.87; if fid_cde=190 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, mace, ground*/
	if fid_cde=191 then ghge_kg_food=0.87; if fid_cde=191 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, marjoram, ground*/
	if fid_cde=192 then ghge_kg_food=0.87; if fid_cde=192 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, mustard seed, yellow*/
	if fid_cde=193 then ghge_kg_food=0.87; if fid_cde=193 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, nutmeg, ground*/
	if fid_cde=194 then ghge_kg_food=0.87; if fid_cde=194 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, onion powder*/
	if fid_cde=195 then ghge_kg_food=0.87; if fid_cde=195 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, oregano, ground*/
	if fid_cde=196 then ghge_kg_food=0.87; if fid_cde=196 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, paprika*/
	if fid_cde=197 then ghge_kg_food=0.87; if fid_cde=197 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Parsley, dried*/
	if fid_cde=198 then ghge_kg_food=0.87; if fid_cde=198 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, pepper, black*/
	if fid_cde=199 then ghge_kg_food=0.87; if fid_cde=199 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, pepper, red or cayenne*/
	if fid_cde=200 then ghge_kg_food=0.87; if fid_cde=200 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, pepper, white*/
	if fid_cde=202 then ghge_kg_food=0.87; if fid_cde=202 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, poultry seasoning*/
	if fid_cde=203 then ghge_kg_food=0.87; if fid_cde=203 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, pumpkin pie spice*/
	if fid_cde=205 then ghge_kg_food=0.87; if fid_cde=205 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, saffron*/
	if fid_cde=206 then ghge_kg_food=0.87; if fid_cde=206 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, sage, ground*/
	if fid_cde=207 then ghge_kg_food=0.87; if fid_cde=207 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, savory, ground*/
	if fid_cde=210 then ghge_kg_food=0.87; if fid_cde=210 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, thyme, dried*/
	if fid_cde=211 then ghge_kg_food=0.87; if fid_cde=211 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, turmeric, ground*/
	if fid_cde=2138 then ghge_kg_food=0.87; if fid_cde=2138 then  ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Onion, dehydrated flakes*/
	if fid_cde=4725 then ghge_kg_food=0.87; if fid_cde=4725 then  ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Spices, spearmint, fresh*/
	if fid_cde=6312 then ghge_kg_food=0.87; if fid_cde=6312 then ghge_loss_kg_food=0.87*(100/(100-13.33));			/*Seasoning mix, taco, dry mix*/
	if fid_cde=212 then ghge_kg_food=0.22; if fid_cde=212 then ghge_loss_kg_food=0.22*(100/(100-49.5));				/*Basil, fresh*/

	drop FNDDS_DESCRIPTION NSS_DESCRIPTION LINKAGE_SOURCE id ALTERNATE_FNDDS_CODE ALTERNATE_FNDDS_DESCRIPTION;
run;

proc sort data=rclls_ghge_ovrd; by sampleid suppid seqid; run;

/***********************************************************************/
/*																	   */
/* STEP 3 - Categorize protein foods into food subgroups			   */
/*																	   */
/***********************************************************************/

/***********************************************************************/
/* Step 3.1: Categorize foods 										   */
/***********************************************************************/

data sbgrps;
	set rclls_ghge_ovrd;

/*RED AND PROCESSED MEAT*/
	/*Beef*/
		if FID_FGR="22A" or FID_FGR="22B" or FID_FGR="22C" or FID_FGR="23A"
		or FID_FGR="23B"
			then food_subgrp=1;
	/*Lamb*/
		if FID_FGR="24A" or FID_FGR="24B"
			then food_subgrp=2;
	/*Pork*/
		if FID_FGR="25A" or FID_FGR="25B" or FID_FGR="25C" or FID_FGR="25D"
		or FID_FGR="25E"
			then food_subgrp=3;
	/*Luncheon and other meat (liver, offal, game meat)*/
		if FID_FGR="28A" or FID_FGR="28B" or FID_FGR="29A" or FID_FGR="30A"
		or FID_FGR="31A" or FID_FGR="32A"
			then food_subgrp=4;

/*DAIRY*/
	/*Milk*/
		if FID_FGR="10A" or FID_FGR="10B" or FID_FGR="10C" or FID_FGR="10D"
		or FID_FGR="10E" or FID_FGR="10F" or FID_FGR="10G" or FID_FGR="10H"
		or FID_FGR="10I" or FID_FGR="10K"
			then food_subgrp=5;
	/*Cheese*/
		if FID_FGR="14A" or FID_FGR="14B" or FID_FGR="14C" or FID_FGR="14D"
			then food_subgrp=6;
	/*Yoghurt*/	
		if FID_FGR="15A" or FID_FGR="15B"
			then food_subgrp=7;
	/*Cream*/
		if FID_FGR="13A" or FID_FGR="13B" or FID_FGR="13C" or FID_FGR="13D"
			then food_subgrp=8;
	/*Butter*/
		if FID_FGR="17A"
			then food_subgrp=9;
	/*Frozen dairy*/
		if FID_FGR="09A" or FID_FGR="09B" or FID_FGR="09C" 
			then food_subgrp=10;

/*NUTS, SEEDS, AND LEGUMES (including soy beverage)*/
	/*Nuts and nut butters*/
		if FID_FGR="33A" or FID_FGR="33C"
			then food_subgrp=11;
	/*Seeds*/
		if FID_FGR="33B"
			then food_subgrp=12;
	/*Legumes (including beans and peas)*/
		if FID_FGR="36A" or FID_FGR="36K" or FID_FGR="37A"
			then food_subgrp=13;
	/*Tofu*/
		if FID_FGR="37B"
			then food_subgrp=14;
	/*Soy beverage*/
		if fid_cde=6329 or fid_cde=6330 or fid_cde=6720
			then food_subgrp=15;

run;

proc freq data=sbgrps;
	table food_subgrp;
run;

/*Check ghge coverage*/
/*proc sort data=sbgrps; by fid_cde; run;
data cvrg;
	update sbgrps(obs=0)sbgrps;
	by fid_cde;
	if ghge_loss_kg_food=.;
	keep fid_cde fdc_den ghge_loss_kg_food;
run;
/*2,621 observations*/
/*proc means n nmiss data=cvrg;
	var ghge_loss_kg_food;
run;
/*100-(115/2,621) = 95.61% coverage*/

/***********************************************************************/
/* Step 3.2: Variable for GHGE accounting for amount of food consumed  */
/***********************************************************************/

data sbgrps; 
	set sbgrps;
		
	/*This variable will be aggregated for replacement foods per respondent*/
	/*Food grams/1000 -> kg * GHGE = X CO2-eq*/
	if fid_wtg ne . and ghge_loss_kg_food ne . then kg_x_co2eq_per_kg=(fid_wtg/1000)*ghge_loss_kg_food;

run;

proc means n nmiss min max data=sbgrps;
	var kg_x_co2eq_per_kg;
run;

/***********************************************************************/
/*																	   */
/* STEP 4 - HEFI-2019												   */
/*																	   */
/***********************************************************************/

proc import datafile='K:\Replacement Scenarios (CF-RS)\CF-RS_Data-Files\hefi_2019.xlsx'
out=hefi
dbms=xlsx
replace;
run;

data hefi;
	set hefi;
	if ra_g="NA" then ra_g=.;
	ra_g_numeric=input(ra_g, best5.);
	drop ra_g fdc_den;
run;

data hefi;
	set hefi;
	length fid_cde 6;
run;

proc sort data=sbgrps; by fid_cde; run;
proc sort data=hefi; by fid_cde; run;

/*Merge HEFI dataset with CCHS data*/
data fid_hefi;
	merge sbgrps hefi;
	by fid_cde;
	if suppid=. /*or suppid=2*/ then delete;
run;
/*648,495 observations (both recalls)*/
/*495,179 observations (1st recall)

/*Convert RA_g to numeric*/
/*Calculate derived variables*/
data fid_hefi;
	set fid_hefi;
	if fid_wtg ne . and ra_g_numeric ne . then ra_cnsmd=fid_wtg/ra_g_numeric;
run;

/*Comparing HEFI and protein foods group categories*/
/*data cchs_hefi_ctgry;
	set fid_hefi;
	keep fid_cde food_subgrp HEFI2019Cat;
	if HEFI2019Cat="not considered (e.g. herbs, spices, fats, oils, no RA)" then delete;
run;

proc sort data=cchs_hefi_ctgry; by HEFI2019Cat food_subgrp; run;

proc freq data=cchs_hefi_ctgry;
	table HEFI2019Cat*food_subgrp;
run;

/*What we need to do is aggregate ras for each hefi component and food_subgrp*/

/*Aggregate RAs per HEFI group*/

/***********/																
/*Vegfruits*/																
/***********/																
	data hefi_vegfruits;															
		set fid_hefi;														
		if hefi2019cat="vegfruits";														
	run;															
	proc sql;															
		create table ra_vegfruits as														
		select sampleid,														
		sum (ra_cnsmd) as vegfruits1,														
		sum (fid_wtg) as vegfruits1_wtg from hefi_vegfruits														
		group by sampleid;														
	quit;															
/*food_subgrp #13*/																
	data hefi_vegfruits_13;															
		set fid_hefi;														
		if hefi2019cat="vegfruits" and food_subgrp=13;														
	run;															
	proc sql;															
		create table ra_vegfruits_13 as														
		select sampleid,														
		sum (ra_cnsmd) as vegfruits1_13,														
		sum (fid_wtg) as vegfruits1_13_wtg from hefi_vegfruits_13														
		group by sampleid;														
	quit;															
																
/*Wholegrfoods*/																
	data hefi_wholegrfoods;															
		set fid_hefi;														
		if hefi2019cat="wholegrfoods";														
	run;															
	proc sql;															
		create table ra_wholegrfoods as														
		select sampleid,														
		sum (ra_cnsmd) as wholegrfoods1,														
		sum (fid_wtg) as wholegrfoods1_wtg from hefi_wholegrfoods														
		group by sampleid;														
	quit;															
																
/*Nonwholegrfoods*/																
	data hefi_nonwholegrfoods;															
		set fid_hefi;														
		if hefi2019cat="nonwholegrfoods";														
	run;															
	proc sql;															
		create table ra_nonwholegrfoods as														
		select sampleid,														
		sum (ra_cnsmd) as nonwholegrfoods1,														
		sum (fid_wtg) as nonwholegrfoods1_wtg from hefi_nonwholegrfoods														
		group by sampleid;														
	quit;															
																
/****************/																
/*Profoodsanimal*/																
/****************/																
	data hefi_profoodsanimal;															
		set fid_hefi;														
		if hefi2019cat="profoodsanimal";														
	run;															
	proc sql;															
		create table ra_profoodsanimal as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsanimal1,														
		sum (fid_wtg) as profoodsanimal1_wtg from hefi_profoodsanimal														
		group by sampleid;														
	quit;															
/*food_subgrp #1*/																
	data hefi_profoodsanimal_1;															
		set fid_hefi;														
		if hefi2019cat="profoodsanimal" and food_subgrp=1;														
	run;															
	proc sql;															
		create table ra_profoodsanimal_1 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsanimal1_1,														
		sum (fid_wtg) as profoodsanimal1_1_wtg from hefi_profoodsanimal_1														
		group by sampleid;														
	quit;															
/*food_subgrp #2*/																
	data hefi_profoodsanimal_2;															
		set fid_hefi;														
		if hefi2019cat="profoodsanimal" and food_subgrp=2;														
	run;															
	proc sql;															
		create table ra_profoodsanimal_2 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsanimal1_2,														
		sum (fid_wtg) as profoodsanimal1_2_wtg from hefi_profoodsanimal_2														
		group by sampleid;														
	quit;															
/*food_subgrp #3*/																
	data hefi_profoodsanimal_3;															
		set fid_hefi;														
		if hefi2019cat="profoodsanimal" and food_subgrp=3;														
	run;															
	proc sql;															
		create table ra_profoodsanimal_3 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsanimal1_3,														
		sum (fid_wtg) as profoodsanimal1_3_wtg from hefi_profoodsanimal_3														
		group by sampleid;														
	quit;															
/*food_subgrp #4*/																
	data hefi_profoodsanimal_4;															
		set fid_hefi;														
		if hefi2019cat="profoodsanimal" and food_subgrp=4;														
	run;															
	proc sql;															
		create table ra_profoodsanimal_4 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsanimal1_4,														
		sum (fid_wtg) as profoodsanimal1_4_wtg from hefi_profoodsanimal_4														
		group by sampleid;														
	quit;															
/*food_subgrp #6*/																
	data hefi_profoodsanimal_6;															
		set fid_hefi;														
		if hefi2019cat="profoodsanimal" and food_subgrp=6;														
	run;															
	proc sql;															
		create table ra_profoodsanimal_6 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsanimal1_6,														
		sum (fid_wtg) as profoodsanimal1_6_wtg from hefi_profoodsanimal_6														
		group by sampleid;														
	quit;															
/*food_subgrp #7*/																
	data hefi_profoodsanimal_7;															
		set fid_hefi;														
		if hefi2019cat="profoodsanimal" and food_subgrp=7;														
	run;															
	proc sql;															
		create table ra_profoodsanimal_7 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsanimal1_7,														
		sum (fid_wtg) as profoodsanimal1_7_wtg from hefi_profoodsanimal_7														
		group by sampleid;														
	quit;															
																
/***************/																
/*Profoodsplant*/																
/***************/																
	data hefi_profoodsplant;															
		set fid_hefi;														
		if hefi2019cat="profoodsplant";														
	run;															
	proc sql;															
		create table ra_profoodsplant as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsplant1,														
		sum (fid_wtg) as profoodsplant1_wtg from hefi_profoodsplant														
		group by sampleid;														
	quit;															
/*food_subgrp #7*/																
	data hefi_profoodsplant_7;															
		set fid_hefi;														
		if hefi2019cat="profoodsplant" and food_subgrp=7;														
	run;															
	proc sql;															
		create table ra_profoodsplant_7 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsplant1_7,														
		sum (fid_wtg) as profoodsplant1_7_wtg from hefi_profoodsplant_7														
		group by sampleid;														
	quit;															
/*food_subgrp #11*/																
	data hefi_profoodsplant_11;															
		set fid_hefi;														
		if hefi2019cat="profoodsplant" and food_subgrp=11;														
	run;															
	proc sql;															
		create table ra_profoodsplant_11 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsplant1_11,														
		sum (fid_wtg) as profoodsplant1_11_wtg from hefi_profoodsplant_11														
		group by sampleid;														
	quit;															
/*food_subgrp #12*/																
	data hefi_profoodsplant_12;															
		set fid_hefi;														
		if hefi2019cat="profoodsplant" and food_subgrp=12;														
	run;															
	proc sql;															
		create table ra_profoodsplant_12 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsplant1_12,														
		sum (fid_wtg) as profoodsplant1_12_wtg from hefi_profoodsplant_12														
		group by sampleid;														
	quit;															
/*food_subgrp #13*/																
	data hefi_profoodsplant_13;															
		set fid_hefi;														
		if hefi2019cat="profoodsplant" and food_subgrp=13;														
	run;															
	proc sql;															
		create table ra_profoodsplant_13 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsplant1_13,														
		sum (fid_wtg) as profoodsplant1_13_wtg from hefi_profoodsplant_13														
		group by sampleid;														
	quit;															
/*food_subgrp #14*/																
	data hefi_profoodsplant_14;															
		set fid_hefi;														
		if hefi2019cat="profoodsplant" and food_subgrp=14;														
	run;															
	proc sql;															
		create table ra_profoodsplant_14 as														
		select sampleid,														
		sum (ra_cnsmd) as profoodsplant1_14,														
		sum (fid_wtg) as profoodsplant1_14_wtg from hefi_profoodsplant_14														
		group by sampleid;														
	quit;															
																
/************/																
/*Otherfoods*/																
/************/																
	data hefi_otherfoods;															
		set fid_hefi;														
		if hefi2019cat="otherfoods";														
	run;															
	proc sql;															
		create table ra_otherfoods as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1,														
		sum (fid_wtg) as otherfoods1_wtg from hefi_otherfoods 														
		group by sampleid;														
	quit;															
/*food_subgrp #1*/																
	data hefi_otherfoods_1;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=1;														
	run;															
	proc sql;															
		create table ra_otherfoods_1 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_1,														
		sum (fid_wtg) as otherfoods1_1_wtg from hefi_otherfoods_1														
		group by sampleid;														
	quit;															
/*food_subgrp #3*/																
	data hefi_otherfoods_3;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=3;														
	run;															
	proc sql;															
		create table ra_otherfoods_3 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_3,														
		sum (fid_wtg) as otherfoods1_3_wtg from hefi_otherfoods_3														
		group by sampleid;														
	quit;															
/*food_subgrp #4*/																
	data hefi_otherfoods_4;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=4;														
	run;															
	proc sql;															
		create table ra_otherfoods_4 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_4,														
		sum (fid_wtg) as otherfoods1_4_wtg from hefi_otherfoods_4														
		group by sampleid;														
	quit;															
/*food_subgrp #5*/																
	data hefi_otherfoods_5;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=5;														
	run;															
	proc sql;															
		create table ra_otherfoods_5 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_5,														
		sum (fid_wtg) as otherfoods1_5_wtg from hefi_otherfoods_5														
		group by sampleid;														
	quit;															
/*food_subgrp #6*/																
	data hefi_otherfoods_6;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=6;														
	run;															
	proc sql;															
		create table ra_otherfoods_6 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_6,														
		sum (fid_wtg) as otherfoods1_6_wtg from hefi_otherfoods_6														
		group by sampleid;														
	quit;															
/*food_subgrp #7*/																
	data hefi_otherfoods_7;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=7;														
	run;															
	proc sql;															
		create table ra_otherfoods_7 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_7,														
		sum (fid_wtg) as otherfoods1_7_wtg from hefi_otherfoods_7														
		group by sampleid;														
	quit;															
/*food_subgrp #8*/																
	data hefi_otherfoods_8;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=8;														
	run;															
	proc sql;															
		create table ra_otherfoods_8 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_8,														
		sum (fid_wtg) as otherfoods1_8_wtg from hefi_otherfoods_8														
		group by sampleid;														
	quit;															
/*food_subgrp #10*/																
	data hefi_otherfoods_10;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=10;														
	run;															
	proc sql;															
		create table ra_otherfoods_10 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_10,														
		sum (fid_wtg) as otherfoods1_10_wtg from hefi_otherfoods_10														
		group by sampleid;														
	quit;															
/*food_subgrp #11*/																
	data hefi_otherfoods_11;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=11;														
	run;															
	proc sql;															
		create table ra_otherfoods_11 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_11,														
		sum (fid_wtg) as otherfoods1_11_wtg from hefi_otherfoods_11														
		group by sampleid;														
	quit;															
/*food_subgrp #14*/																
	data hefi_otherfoods_14;															
		set fid_hefi;														
		if hefi2019cat="otherfoods" and food_subgrp=14;														
	run;															
	proc sql;															
		create table ra_otherfoods_14 as														
		select sampleid,														
		sum (ra_cnsmd) as otherfoods1_14,														
		sum (fid_wtg) as otherfoods1_14_wtg from hefi_otherfoods_14														
		group by sampleid;														
	quit;															
																
/*Waterhealthybev*/																
	data hefi_waterhealthybev;															
		set fid_hefi;														
		if hefi2019cat="waterhealthybev";														
	run;															
	proc sql;															
		create table ra_waterhealthybev as														
		select sampleid,														
		sum (ra_cnsmd) as waterhealthybev1,														
		sum (fid_wtg) as waterhealthybev1_wtg from hefi_waterhealthybev														
		group by sampleid;														
	quit;															
																
/*************/																
/*Unsweetmilk*/																
/*************/																
	data hefi_unsweetmilk;															
		set fid_hefi;														
		if hefi2019cat="unsweetmilk";														
	run;															
	proc sql;															
		create table ra_unsweetmilk as														
		select sampleid,														
		sum (ra_cnsmd) as unsweetmilk1,														
		sum (fid_wtg) as unsweetmilk1_wtg from hefi_unsweetmilk														
		group by sampleid;														
	quit;															
/*food_subgrp #5*/																
	data hefi_unsweetmilk_5;															
		set fid_hefi;														
		if hefi2019cat="unsweetmilk" and food_subgrp=5;														
	run;															
	proc sql;															
		create table ra_unsweetmilk_5 as														
		select sampleid,														
		sum (ra_cnsmd) as unsweetmilk1_5,														
		sum (fid_wtg) as unsweetmilk1_5_wtg from hefi_unsweetmilk_5														
		group by sampleid;														
	quit;															
																
/********************/																
/*Unsweetplantbevpro*/																
/********************/																
	data hefi_unsweetplantbevpro;															
		set fid_hefi;														
		if hefi2019cat="unsweetplantbevpro";														
	run;															
	proc sql;															
		create table ra_unsweetplantbevpro as														
		select sampleid,														
		sum (ra_cnsmd) as unsweetplantbevpro1,														
		sum (fid_wtg) as unsweetplantbevpro1_wtg from hefi_unsweetplantbevpro														
		group by sampleid;														
	quit;															
/*food_subgrp #15*/																
	data hefi_unsweetplantbevpro_15;															
		set fid_hefi;														
		if hefi2019cat="unsweetplantbevpro" and food_subgrp=15;														
	run;															
	proc sql;															
		create table ra_unsweetplantbevpro_15 as														
		select sampleid,														
		sum (ra_cnsmd) as unsweetplantbevpro1_15,														
		sum (fid_wtg) as unsweetplantbevpro1_15_wtg from hefi_unsweetplantbevpro_15														
		group by sampleid;														
	quit;															
																
/****************/																
/*Otherbeverages*/																
/****************/																
	data hefi_otherbeverages;															
		set fid_hefi;														
		if hefi2019cat="otherbeverages";														
	run;															
	proc sql;															
		create table ra_otherbeverages as														
		select sampleid,														
		sum (ra_cnsmd) as otherbeverages1,														
		sum (fid_wtg) as otherbeverages1_wtg from hefi_otherbeverages														
		group by sampleid;														
	quit;															
/*food_subgrp #5*/																
	data hefi_otherbeverages_5;															
		set fid_hefi;														
		if hefi2019cat="otherbeverages" and food_subgrp=5;														
	run;															
	proc sql;															
		create table ra_otherbeverages_5 as														
		select sampleid,														
		sum (ra_cnsmd) as otherbeverages1_5,														
		sum (fid_wtg) as otherbeverages1_5_wtg from hefi_otherbeverages_5														
		group by sampleid;														
	quit;															
/*food_subgrp #15*/																
	data hefi_otherbeverages_15;															
		set fid_hefi;														
		if hefi2019cat="otherbeverages" and food_subgrp=15;														
	run;															
	proc sql;															
		create table ra_otherbeverages_15 as														
		select sampleid,														
		sum (ra_cnsmd) as otherbeverages1_15,														
		sum (fid_wtg) as otherbeverages1_15_wtg from hefi_otherbeverages_15														
		group by sampleid;														
	quit;															
																
/*Freesugars*/																
	proc sql;															
		create table g_freesugars as														
		select sampleid,														
		sum (free_sug_g) as freesugars1 from fid_hefi														
		group by sampleid;														
	quit;															
																
/*Energy*/																
	proc sql;															
		create table energy as														
		select sampleid,														
		sum (fid_ekc) as energy1 from fid_hefi														
		group by sampleid;														
	quit;															
																
/*MUFAs*/																
	proc sql;															
		create table mufas as														
		select sampleid,														
		sum (fid_fam) as mufa1 from fid_hefi														
		group by sampleid;														
	quit;															
																
/*PUFAs*/																
	proc sql;															
		create table pufas as														
		select sampleid,														
		sum (fid_fap) as pufa1 from fid_hefi														
		group by sampleid;														
	quit;															
																
/*Saturated fat*/																
	proc sql;															
		create table satfat as														
		select sampleid,														
		sum (fid_fas) as satfat1 from fid_hefi														
		group by sampleid;														
	quit;															
																
/*Sodium*/																
	proc sql;															
		create table sodium as														
		select sampleid,														
		sum (fid_sod) as sodium1 from fid_hefi														
		group by sampleid;														
	quit;															

/*Merge with HS*/
data hs_ra_sum;
merge ra_vegfruits
ra_vegfruits_13
ra_wholegrfoods
ra_nonwholegrfoods
ra_profoodsanimal
ra_profoodsanimal_1
ra_profoodsanimal_2
ra_profoodsanimal_3
ra_profoodsanimal_4
ra_profoodsanimal_6
ra_profoodsanimal_7
ra_profoodsplant
ra_profoodsplant_7
ra_profoodsplant_11
ra_profoodsplant_12
ra_profoodsplant_13
ra_profoodsplant_14
ra_otherfoods
ra_otherfoods_1
ra_otherfoods_3
ra_otherfoods_4
ra_otherfoods_5
ra_otherfoods_6
ra_otherfoods_7
ra_otherfoods_8
ra_otherfoods_10
ra_otherfoods_11
ra_otherfoods_14
ra_waterhealthybev
ra_unsweetmilk
ra_unsweetmilk_5
ra_unsweetplantbevpro
ra_unsweetplantbevpro_15
ra_otherbeverages
ra_otherbeverages_5
ra_otherbeverages_15
g_freesugars
energy
mufas
pufas
satfat
sodium;
by sampleid;
run;

/*Set missing values to 0*/
data hs_ra_sum;
	set hs_ra_sum;

/*RAs(consumed)*/
	if vegfruits1=. then vegfruits1=0;
	if vegfruits1_13=. then vegfruits1_13=0;

	if wholegrfoods1=. then wholegrfoods1=0;

	if nonwholegrfoods1=. then nonwholegrfoods1=0;

	if profoodsanimal1=. then profoodsanimal1=0;
	if profoodsanimal1_1=. then profoodsanimal1_1=0;
	if profoodsanimal1_2=. then profoodsanimal1_2=0;
	if profoodsanimal1_3=. then profoodsanimal1_3=0;
	if profoodsanimal1_4=. then profoodsanimal1_4=0;
	if profoodsanimal1_6=. then profoodsanimal1_6=0;
	if profoodsanimal1_7=. then profoodsanimal1_7=0;
 
	if profoodsplant1=. then profoodsplant1=0;
	if profoodsplant1_7=. then profoodsplant1_7=0;
	if profoodsplant1_11=. then profoodsplant1_11=0;
	if profoodsplant1_12=. then profoodsplant1_12=0;
	if profoodsplant1_13=. then profoodsplant1_13=0;
	if profoodsplant1_14=. then profoodsplant1_14=0;

	if otherfoods1=. then otherfoods1=0;
	if otherfoods1_1=. then otherfoods1_1=0;
	if otherfoods1_3=. then otherfoods1_3=0;
	if otherfoods1_4=. then otherfoods1_4=0;
	if otherfoods1_5=. then otherfoods1_5=0;
	if otherfoods1_6=. then otherfoods1_6=0;
	if otherfoods1_7=. then otherfoods1_7=0;
	if otherfoods1_8=. then otherfoods1_8=0;
	if otherfoods1_10=. then otherfoods1_10=0;
	if otherfoods1_11=. then otherfoods1_11=0;
	if otherfoods1_14=. then otherfoods1_14=0;

	if waterhealthybev1=. then waterhealthybev1=0;

	if unsweetmilk1=. then unsweetmilk1=0;
	if unsweetmilk1_5=. then unsweetmilk1_5=0;

	if unsweetplantbevpro1=. then unsweetplantbevpro1=0;
	if unsweetplantbevpro1_15=. then unsweetplantbevpro1_15=0;

	if otherbeverages1=. then otherbeverages1=0;
	if otherbeverages1_5=. then otherbeverages1_5=0;
	if otherbeverages1_15=. then otherbeverages1_15=0;

/*Food weight*/
	if vegfruits1_wtg=. then vegfruits1_wtg=0;	
	if vegfruits1_13_wtg=. then vegfruits1_13_wtg=0;
	
	if wholegrfoods1_wtg=. then wholegrfoods1_wtg=0;
	
	if nonwholegrfoods1_wtg=. then nonwholegrfoods1_wtg=0;
	
	if profoodsanimal1_wtg=. then profoodsanimal1_wtg=0;
	if profoodsanimal1_1_wtg=. then profoodsanimal1_1_wtg=0;
	if profoodsanimal1_2_wtg=. then profoodsanimal1_2_wtg=0;
	if profoodsanimal1_3_wtg=. then profoodsanimal1_3_wtg=0;
	if profoodsanimal1_4_wtg=. then profoodsanimal1_4_wtg=0;
	if profoodsanimal1_6_wtg=. then profoodsanimal1_6_wtg=0;
	if profoodsanimal1_7_wtg=. then profoodsanimal1_7_wtg=0;
 	
	if profoodsplant1_wtg=. then profoodsplant1_wtg=0;
	if profoodsplant1_7_wtg=. then profoodsplant1_7_wtg=0;
	if profoodsplant1_11_wtg=. then profoodsplant1_11_wtg=0;
	if profoodsplant1_12_wtg=. then profoodsplant1_12_wtg=0;
	if profoodsplant1_13_wtg=. then profoodsplant1_13_wtg=0;
	if profoodsplant1_14_wtg=. then profoodsplant1_14_wtg=0;
	
	if otherfoods1_wtg=. then otherfoods1_wtg=0;
	if otherfoods1_1_wtg=. then otherfoods1_1_wtg=0;
	if otherfoods1_3_wtg=. then otherfoods1_3_wtg=0;
	if otherfoods1_4_wtg=. then otherfoods1_4_wtg=0;
	if otherfoods1_5_wtg=. then otherfoods1_5_wtg=0;
	if otherfoods1_6_wtg=. then otherfoods1_6_wtg=0;
	if otherfoods1_7_wtg=. then otherfoods1_7_wtg=0;
	if otherfoods1_8_wtg=. then otherfoods1_8_wtg=0;
	if otherfoods1_10_wtg=. then otherfoods1_10_wtg=0;
	if otherfoods1_11_wtg=. then otherfoods1_11_wtg=0;
	if otherfoods1_14_wtg=. then otherfoods1_14_wtg=0;
	
	if waterhealthybev1_wtg=. then waterhealthybev1_wtg=0;
	
	if unsweetmilk1_wtg=. then unsweetmilk1_wtg=0;
	if unsweetmilk1_5_wtg=. then unsweetmilk1_5_wtg=0;
	
	if unsweetplantbevpro1_wtg=. then unsweetplantbevpro1_wtg=0;
	if unsweetplantbevpro1_15_wtg=. then unsweetplantbevpro1_15_wtg=0;
	
	if otherbeverages1_wtg=. then otherbeverages1_wtg=0;
	if otherbeverages1_5_wtg=. then otherbeverages1_5_wtg=0;
	if otherbeverages1_15_wtg=. then otherbeverages1_15_wtg=0;

/*Nutrients*/
	if freesugars1=. then freesugars1=0;

	if energy1=. then energy1=0;

	if mufa1=. then mufa1=0;

	if pufa1=. then pufa1=0;

	if satfat1=. then satfat1=0;

	if sodium1=. then sodium1=0;

run;

proc means n nmiss min max data=hs_ra_sum;
	var vegfruits1 vegfruits1_13 wholegrfoods1 nonwholegrfoods1 profoodsanimal1
		profoodsanimal1_1 profoodsanimal1_2 profoodsanimal1_3 profoodsanimal1_4
		profoodsanimal1_6 profoodsanimal1_7 profoodsplant1 profoodsplant1_7
		profoodsplant1_11 profoodsplant1_12 profoodsplant1_13 profoodsplant1_14
		otherfoods1 otherfoods1_1 otherfoods1_3 otherfoods1_4 otherfoods1_5
		otherfoods1_6 otherfoods1_7 otherfoods1_8 otherfoods1_10 otherfoods1_11
		otherfoods1_14 waterhealthybev1 unsweetmilk1 unsweetmilk1_5
		unsweetplantbevpro1 unsweetplantbevpro1_15 otherbeverages1 otherbeverages1_5
		otherbeverages1_15 

		vegfruits1_wtg vegfruits1_13_wtg wholegrfoods1_wtg
		nonwholegrfoods1_wtg profoodsanimal1_wtg profoodsanimal1_1_wtg
		profoodsanimal1_2_wtg profoodsanimal1_3_wtg profoodsanimal1_4_wtg
		profoodsanimal1_6_wtg profoodsanimal1_7_wtg profoodsplant1_wtg
		profoodsplant1_7_wtg profoodsplant1_11_wtg profoodsplant1_12_wtg
		profoodsplant1_13_wtg profoodsplant1_14_wtg otherfoods1_wtg otherfoods1_1_wtg
		otherfoods1_3_wtg otherfoods1_4_wtg otherfoods1_5_wtg otherfoods1_6_wtg
		otherfoods1_7_wtg otherfoods1_8_wtg otherfoods1_10_wtg otherfoods1_11_wtg
		otherfoods1_14_wtg waterhealthybev1_wtg unsweetmilk1_wtg unsweetmilk1_5_wtg
		unsweetplantbevpro1_wtg unsweetplantbevpro1_15_wtg otherbeverages1_wtg
		otherbeverages1_5_wtg otherbeverages1_15_wtg freesugars1 energy1 mufa1 pufa1
		satfat1 sodium1;
run;

/*Unique RAs for HEFI components per person based on thier consumption profile (expressed in units/g)*/
data hs_ra_sum;
	set hs_ra_sum;
	if vegfruits1 ne 0 then unq_vegfruits1=vegfruits1/vegfruits1_wtg;
	if vegfruits1_13 ne 0 then unq_vegfruits1_13=vegfruits1_13/vegfruits1_13_wtg;
	if wholegrfoods1 ne 0 then unq_wholegrfoods1=wholegrfoods1/wholegrfoods1_wtg;
	if nonwholegrfoods1 ne 0 then unq_nonwholegrfoods1=nonwholegrfoods1/nonwholegrfoods1_wtg;
	if profoodsanimal1 ne 0 then unq_profoodsanimal1=profoodsanimal1/profoodsanimal1_wtg;
	if profoodsanimal1_1 ne 0 then unq_profoodsanimal1_1=profoodsanimal1_1/profoodsanimal1_1_wtg;
	if profoodsanimal1_2 ne 0 then unq_profoodsanimal1_2=profoodsanimal1_2/profoodsanimal1_2_wtg;
	if profoodsanimal1_3 ne 0 then unq_profoodsanimal1_3=profoodsanimal1_3/profoodsanimal1_3_wtg;
	if profoodsanimal1_4 ne 0 then unq_profoodsanimal1_4=profoodsanimal1_4/profoodsanimal1_4_wtg;
	if profoodsanimal1_6 ne 0 then unq_profoodsanimal1_6=profoodsanimal1_6/profoodsanimal1_6_wtg;
	if profoodsanimal1_7 ne 0 then unq_profoodsanimal1_7=profoodsanimal1_7/profoodsanimal1_7_wtg;
	if profoodsplant1 ne 0 then unq_profoodsplant1=profoodsplant1/profoodsplant1_wtg;
	if profoodsplant1_7 ne 0 then unq_profoodsplant1_7=profoodsplant1_7/profoodsplant1_7_wtg;
	if profoodsplant1_11 ne 0 then unq_profoodsplant1_11=profoodsplant1_11/profoodsplant1_11_wtg;
	if profoodsplant1_12 ne 0 then unq_profoodsplant1_12=profoodsplant1_12/profoodsplant1_12_wtg;
	if profoodsplant1_13 ne 0 then unq_profoodsplant1_13=profoodsplant1_13/profoodsplant1_13_wtg;
	if profoodsplant1_14 ne 0 then unq_profoodsplant1_14=profoodsplant1_14/profoodsplant1_14_wtg;
	if otherfoods1 ne 0 then unq_otherfoods1=otherfoods1/otherfoods1_wtg;
	if otherfoods1_1 ne 0 then unq_otherfoods1_1=otherfoods1_1/otherfoods1_1_wtg;
	if otherfoods1_3 ne 0 then unq_otherfoods1_3=otherfoods1_3/otherfoods1_3_wtg;
	if otherfoods1_4 ne 0 then unq_otherfoods1_4=otherfoods1_4/otherfoods1_4_wtg;
	if otherfoods1_5 ne 0 then unq_otherfoods1_5=otherfoods1_5/otherfoods1_5_wtg;
	if otherfoods1_6 ne 0 then unq_otherfoods1_6=otherfoods1_6/otherfoods1_6_wtg;
	if otherfoods1_7 ne 0 then unq_otherfoods1_7=otherfoods1_7/otherfoods1_7_wtg;
	if otherfoods1_8 ne 0 then unq_otherfoods1_8=otherfoods1_8/otherfoods1_8_wtg;
	if otherfoods1_10 ne 0 then unq_otherfoods1_10=otherfoods1_10/otherfoods1_10_wtg;
	if otherfoods1_11 ne 0 then unq_otherfoods1_11=otherfoods1_11/otherfoods1_11_wtg;
	if otherfoods1_14 ne 0 then unq_otherfoods1_14=otherfoods1_14/otherfoods1_14_wtg;
	if waterhealthybev1 ne 0 then unq_waterhealthybev1=waterhealthybev1/waterhealthybev1_wtg;
	if unsweetmilk1 ne 0 then unq_unsweetmilk1=unsweetmilk1/unsweetmilk1_wtg;
	if unsweetmilk1_5 ne 0 then unq_unsweetmilk1_5=unsweetmilk1_5/unsweetmilk1_5_wtg;
	if unsweetplantbevpro1 ne 0 then unq_unsweetplantbevpro1=unsweetplantbevpro1/unsweetplantbevpro1_wtg;
	if unsweetplantbevpro1_15 ne 0 then unq_unsweetplantbevpro1_15=unsweetplantbevpro1_15/unsweetplantbevpro1_15_wtg;
	if otherbeverages1 ne 0 then unq_otherbeverages1=otherbeverages1/otherbeverages1_wtg;
	if otherbeverages1_5 ne 0 then unq_otherbeverages1_5=otherbeverages1_5/otherbeverages1_5_wtg;
	if otherbeverages1_15 ne 0 then unq_otherbeverages1_15=otherbeverages1_15/otherbeverages1_15_wtg;	
run; 

/***********************************************************************/
/*																	   */
/* STEP 5 - Aggregate g of food and ghge for the FIRST RECALL DAY	   */
/*																	   */
/***********************************************************************/

/*Keep only 1st recall day*/
data day1;
	set sbgrps;
	if suppid=1;
run;

/***********************************************************************/
/* Step 5.1: Sum g, GHGE, and nutrients from each food per respondent  */
/***********************************************************************/

/*NOTE 2021-11-30 : fid_sug (total sugar) changes to free_sug_g (free sugars)*/

/*Beef*/
data beef;
	set day1;
	if food_subgrp=1;
run;
proc sql;
	create table beef_sum as
	select sampleid,
	sum (fid_wtg) as beef_wtg,									/*Food weight*/
	sum (fid_ekc) as beef_ekc,									/*Energy*/	
	sum (free_sug_g) as beef_sug,								/*FREE SUGARS*/
	sum (fid_fas) as beef_sat,									/*Sat fat*/
	sum (fid_pro) as beef_pro,									/*Protein*/
	sum (fid_dmg) as beef_vitD,									/*Vitamin D*/	
	sum (fid_cal) as beef_ca,									/*Calcium*/
	sum (fid_iro) as beef_fe,									/*Iron*/
	sum (fid_sod) as beef_na,									/*Sodium*/
	sum (fid_pot) as beef_k,									/*Potassium*/
	sum (fid_car) as beef_carb,									/*Carbs*/
	sum (fid_fam) as beef_mufa,									/*MUFAs*/
	sum (fid_fap) as beef_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as beef_co2eq from beef				/*CO2-eq*/
	group by sampleid;														
quit;

/*Lamb*/
data lamb;
	set day1;
	if food_subgrp=2;
run;
proc sql;
	create table lamb_sum as
	select sampleid,
	sum (fid_wtg) as lamb_wtg,									/*Food weight*/	
	sum (fid_ekc) as lamb_ekc,									/*Energy*/	
	sum (free_sug_g) as lamb_sug,								/*Sugar*/	
	sum (fid_fas) as lamb_sat,									/*Sat fat*/	
	sum (fid_pro) as lamb_pro,									/*Protein*/	
	sum (fid_dmg) as lamb_vitD,									/*Vitamin D*/	
	sum (fid_cal) as lamb_ca,									/*Calcium*/	
	sum (fid_iro) as lamb_fe,									/*Iron*/	
	sum (fid_sod) as lamb_na,									/*Sodium*/	
	sum (fid_pot) as lamb_k,									/*Potassium*/
	sum (fid_car) as lamb_carb,									/*Carbs*/
	sum (fid_fam) as lamb_mufa,									/*MUFAs*/
	sum (fid_fap) as lamb_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as lamb_co2eq from lamb				/*CO2-eq*/						
	group by sampleid;
quit;

/*Pork*/
data pork;
	set day1;
	if food_subgrp=3;
run;
proc sql;
	create table pork_sum as
	select sampleid,
	sum (fid_wtg) as pork_wtg,									/*Food weight*/	
	sum (fid_ekc) as pork_ekc,									/*Energy*/	
	sum (free_sug_g) as pork_sug,								/*Sugar*/	
	sum (fid_fas) as pork_sat,									/*Sat fat*/	
	sum (fid_pro) as pork_pro,									/*Protein*/	
	sum (fid_dmg) as pork_vitD,									/*Vitamin D*/	
	sum (fid_cal) as pork_ca,									/*Calcium*/	
	sum (fid_iro) as pork_fe,									/*Iron*/	
	sum (fid_sod) as pork_na,									/*Sodium*/	
	sum (fid_pot) as pork_k,									/*Potassium*/
	sum (fid_car) as pork_carb,									/*Carbs*/
	sum (fid_fam) as pork_mufa,									/*MUFAs*/
	sum (fid_fap) as pork_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as pork_co2eq from pork				/*CO2-eq*/						
	group by sampleid;
quit;

/*Luncheon and other meats*/
data lnchn;
	set day1;
	if food_subgrp=4;
run;
proc sql;
	create table lnchn_sum as
	select sampleid,
	sum (fid_wtg) as lnchn_wtg,									/*Food weight*/	
	sum (fid_ekc) as lnchn_ekc,									/*Energy*/	
	sum (free_sug_g) as lnchn_sug,								/*Sugar*/	
	sum (fid_fas) as lnchn_sat,									/*Sat fat*/	
	sum (fid_pro) as lnchn_pro,									/*Protein*/	
	sum (fid_dmg) as lnchn_vitD,								/*Vitamin D*/	
	sum (fid_cal) as lnchn_ca,									/*Calcium*/	
	sum (fid_iro) as lnchn_fe,									/*Iron*/	
	sum (fid_sod) as lnchn_na,									/*Sodium*/	
	sum (fid_pot) as lnchn_k,									/*Potassium*/	
	sum (fid_car) as lnchn_carb,								/*Carbs*/
	sum (fid_fam) as lnchn_mufa,									/*MUFAs*/
	sum (fid_fap) as lnchn_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as lnchn_co2eq from lnchn			/*CO2-eq*/						
	group by sampleid;
quit;

/*Milk*/
data milk;
	set day1;
	if food_subgrp=5;
run;
proc sql;
	create table milk_sum as
	select sampleid,
	sum (fid_wtg) as milk_wtg,									/*Food weight*/	
	sum (fid_ekc) as milk_ekc,									/*Energy*/	
	sum (free_sug_g) as milk_sug,								/*Sugar*/	
	sum (fid_fas) as milk_sat,									/*Sat fat*/	
	sum (fid_pro) as milk_pro,									/*Protein*/	
	sum (fid_dmg) as milk_vitD,									/*Vitamin D*/	
	sum (fid_cal) as milk_ca,									/*Calcium*/	
	sum (fid_iro) as milk_fe,									/*Iron*/	
	sum (fid_sod) as milk_na,									/*Sodium*/	
	sum (fid_pot) as milk_k,									/*Potassium*/
	sum (fid_car) as milk_carb,									/*Carbs*/
	sum (fid_fam) as milk_mufa,									/*MUFAs*/
	sum (fid_fap) as milk_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as milk_co2eq from milk				/*CO2-eq*/												
	group by sampleid;
quit;

/*Cheese*/
data cheese;
	set day1;							
	if food_subgrp=6;
run;
proc sql;
	create table cheese_sum as
	select sampleid,
	sum (fid_wtg) as cheese_wtg,								/*Food weight*/	
	sum (fid_ekc) as cheese_ekc,								/*Energy*/	
	sum (free_sug_g) as cheese_sug,								/*Sugar*/	
	sum (fid_fas) as cheese_sat,								/*Sat fat*/	
	sum (fid_pro) as cheese_pro,								/*Protein*/	
	sum (fid_dmg) as cheese_vitD,								/*Vitamin D*/	
	sum (fid_cal) as cheese_ca,									/*Calcium*/	
	sum (fid_iro) as cheese_fe,									/*Iron*/	
	sum (fid_sod) as cheese_na,									/*Sodium*/	
	sum (fid_pot) as cheese_k,									/*Potassium*/
	sum (fid_car) as cheese_carb,								/*Carbs*/	
	sum (fid_fam) as cheese_mufa,									/*MUFAs*/
	sum (fid_fap) as cheese_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as cheese_co2eq from cheese			/*CO2-eq*/									
	group by sampleid;
quit;

/*Yoghurt*/
data yghrt;
	set day1;
	if food_subgrp=7;
run;
proc sql;
	create table yghrt_sum as
	select sampleid,
	sum (fid_wtg) as yghrt_wtg,									/*Food weight*/	
	sum (fid_ekc) as yghrt_ekc,									/*Energy*/	
	sum (free_sug_g) as yghrt_sug,								/*Sugar*/	
	sum (fid_fas) as yghrt_sat,									/*Sat fat*/	
	sum (fid_pro) as yghrt_pro,									/*Protein*/	
	sum (fid_dmg) as yghrt_vitD,								/*Vitamin D*/	
	sum (fid_cal) as yghrt_ca,									/*Calcium*/	
	sum (fid_iro) as yghrt_fe,									/*Iron*/	
	sum (fid_sod) as yghrt_na,									/*Sodium*/	
	sum (fid_pot) as yghrt_k,									/*Potassium*/	
	sum (fid_car) as yghrt_carb,								/*Carbs*/	
	sum (fid_fam) as yghrt_mufa,								/*MUFAs*/
	sum (fid_fap) as yghrt_pufa,								/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as yghrt_co2eq from yghrt			/*CO2-eq*/									
	group by sampleid;
quit;

/*Cream*/
data cream;
	set day1;
	if food_subgrp=8;
run;
proc sql;
	create table cream_sum as
	select sampleid,
	sum (fid_wtg) as cream_wtg,									/*Food weight*/	
	sum (fid_ekc) as cream_ekc,									/*Energy*/	
	sum (free_sug_g) as cream_sug,								/*Sugar*/	
	sum (fid_fas) as cream_sat,									/*Sat fat*/	
	sum (fid_pro) as cream_pro,									/*Protein*/	
	sum (fid_dmg) as cream_vitD,								/*Vitamin D*/	
	sum (fid_cal) as cream_ca,									/*Calcium*/	
	sum (fid_iro) as cream_fe,									/*Iron*/	
	sum (fid_sod) as cream_na,									/*Sodium*/	
	sum (fid_pot) as cream_k,									/*Potassium*/
	sum (fid_car) as cream_carb,								/*Carbs*/	
	sum (fid_fam) as cream_mufa,								/*MUFAs*/
	sum (fid_fap) as cream_pufa,								/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as cream_co2eq from cream			/*CO2-eq*/									
	group by sampleid;
quit;

/*Butter*/
data butr;
	set day1;
	if food_subgrp=9;
run;
proc sql;
	create table butr_sum as
	select sampleid,
	sum (fid_wtg) as butr_wtg,									/*Food weight*/	
	sum (fid_ekc) as butr_ekc,									/*Energy*/	
	sum (free_sug_g) as butr_sug,								/*Sugar*/	
	sum (fid_fas) as butr_sat,									/*Sat fat*/	
	sum (fid_pro) as butr_pro,									/*Protein*/	
	sum (fid_dmg) as butr_vitD,									/*Vitamin D*/	
	sum (fid_cal) as butr_ca,									/*Calcium*/	
	sum (fid_iro) as butr_fe,									/*Iron*/	
	sum (fid_sod) as butr_na,									/*Sodium*/	
	sum (fid_pot) as butr_k,									/*Potassium*/
	sum (fid_car) as butr_carb,									/*Carbs*/
	sum (fid_fam) as butr_mufa,									/*MUFAs*/
	sum (fid_fap) as butr_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as butr_co2eq from butr				/*CO2-eq*/											
	group by sampleid;
quit;

/*Frozen dairy*/
data frzn;
	set day1;
	if food_subgrp=10;
run;
proc sql;
	create table frzn_sum as
	select sampleid,
	sum (fid_wtg) as frzn_wtg,									/*Food weight*/	
	sum (fid_ekc) as frzn_ekc,									/*Energy*/	
	sum (free_sug_g) as frzn_sug,								/*Sugar*/	
	sum (fid_fas) as frzn_sat,									/*Sat fat*/	
	sum (fid_pro) as frzn_pro,									/*Protein*/	
	sum (fid_dmg) as frzn_vitD,									/*Vitamin D*/	
	sum (fid_cal) as frzn_ca,									/*Calcium*/	
	sum (fid_iro) as frzn_fe,									/*Iron*/	
	sum (fid_sod) as frzn_na,									/*Sodium*/	
	sum (fid_pot) as frzn_k,									/*Potassium*/
	sum (fid_car) as frzn_carb,									/*Carbs*/	
	sum (fid_fam) as frzn_mufa,									/*MUFAs*/
	sum (fid_fap) as frzn_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as frzn_co2eq from frzn				/*CO2-eq*/											
	group by sampleid;
quit;

/*Nuts*/
data nuts;
	set day1;
	if food_subgrp=11;
run;
proc sql;
	create table nuts_sum as
	select sampleid,
	sum (fid_wtg) as nuts_wtg,									/*Food weight*/	
	sum (fid_ekc) as nuts_ekc,									/*Energy*/	
	sum (free_sug_g) as nuts_sug,								/*Sugar*/	
	sum (fid_fas) as nuts_sat,									/*Sat fat*/	
	sum (fid_pro) as nuts_pro,									/*Protein*/	
	sum (fid_dmg) as nuts_vitD,									/*Vitamin D*/	
	sum (fid_cal) as nuts_ca,									/*Calcium*/	
	sum (fid_iro) as nuts_fe,									/*Iron*/	
	sum (fid_sod) as nuts_na,									/*Sodium*/	
	sum (fid_pot) as nuts_k,									/*Potassium*/	
	sum (fid_car) as nuts_carb,									/*Carbs*/
	sum (fid_fam) as nuts_mufa,									/*MUFAs*/
	sum (fid_fap) as nuts_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as nuts_co2eq from nuts				/*CO2-eq*/			
	group by sampleid;
quit;

/*Seeds*/
data seeds;
	set day1;
	if food_subgrp=12;
run;
proc sql;
	create table seeds_sum as
	select sampleid,
	sum (fid_wtg) as seeds_wtg,									/*Food weight*/	
	sum (fid_ekc) as seeds_ekc,									/*Energy*/	
	sum (free_sug_g) as seeds_sug,								/*Sugar*/	
	sum (fid_fas) as seeds_sat,									/*Sat fat*/	
	sum (fid_pro) as seeds_pro,									/*Protein*/	
	sum (fid_dmg) as seeds_vitD,								/*Vitamin D*/	
	sum (fid_cal) as seeds_ca,									/*Calcium*/	
	sum (fid_iro) as seeds_fe,									/*Iron*/	
	sum (fid_sod) as seeds_na,									/*Sodium*/	
	sum (fid_pot) as seeds_k,									/*Potassium*/	
	sum (fid_car) as seeds_carb,								/*Carbs*/
	sum (fid_fam) as seeds_mufa,								/*MUFAs*/
	sum (fid_fap) as seeds_pufa,								/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as seeds_co2eq from seeds			/*CO2-eq*/
	group by sampleid;
quit;
	
/*Legumes*/
data lgmes;
	set day1;
	if food_subgrp=13;
run;
proc sql;
	create table lgmes_sum as
	select sampleid,
	sum (fid_wtg) as lgmes_wtg,									/*Food weight*/	
	sum (fid_ekc) as lgmes_ekc,									/*Energy*/	
	sum (free_sug_g) as lgmes_sug,								/*Sugar*/	
	sum (fid_fas) as lgmes_sat,									/*Sat fat*/	
	sum (fid_pro) as lgmes_pro,									/*Protein*/	
	sum (fid_dmg) as lgmes_vitD,								/*Vitamin D*/	
	sum (fid_cal) as lgmes_ca,									/*Calcium*/	
	sum (fid_iro) as lgmes_fe,									/*Iron*/	
	sum (fid_sod) as lgmes_na,									/*Sodium*/	
	sum (fid_pot) as lgmes_k,									/*Potassium*/
	sum (fid_car) as lgmes_carb,								/*Carbs*/	
	sum (fid_fam) as lgmes_mufa,								/*MUFAs*/
	sum (fid_fap) as lgmes_pufa,								/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as lgmes_co2eq from lgmes			/*CO2-eq*/								
	group by sampleid;
quit;

/*Tofu*/
data tofu;
	set day1;
	if food_subgrp=14;
run;
proc sql;
	create table tofu_sum as
	select sampleid,
	sum (fid_wtg) as tofu_wtg,									/*Food weight*/	
	sum (fid_ekc) as tofu_ekc,									/*Energy*/	
	sum (free_sug_g) as tofu_sug,								/*Sugar*/	
	sum (fid_fas) as tofu_sat,									/*Sat fat*/	
	sum (fid_pro) as tofu_pro,									/*Protein*/	
	sum (fid_dmg) as tofu_vitD,									/*Vitamin D*/	
	sum (fid_cal) as tofu_ca,									/*Calcium*/	
	sum (fid_iro) as tofu_fe,									/*Iron*/	
	sum (fid_sod) as tofu_na,									/*Sodium*/	
	sum (fid_pot) as tofu_k,									/*Potassium*/	
	sum (fid_car) as tofu_carb,									/*Carbs*/
	sum (fid_fam) as tofu_mufa,									/*MUFAs*/
	sum (fid_fap) as tofu_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as tofu_co2eq from tofu				/*CO2-eq*/								
	group by sampleid;
quit;

/*Soy beverage*/
data soybev;
	set day1;
	if food_subgrp=15;
run;
proc sql;
	create table soybev_sum as
	select sampleid,
	sum (fid_wtg) as soybev_wtg,								
	sum (fid_ekc) as soybev_ekc,							
	sum (free_sug_g) as soybev_sug,						
	sum (fid_fas) as soybev_sat,							
	sum (fid_pro) as soybev_pro,								
	sum (fid_dmg) as soybev_vitD,								
	sum (fid_cal) as soybev_ca,								
	sum (fid_iro) as soybev_fe,									
	sum (fid_sod) as soybev_na,								
	sum (fid_pot) as soybev_k,	
	sum (fid_car) as soybev_carb,
	sum (fid_fam) as soybev_mufa,								
	sum (fid_fap) as soybev_pufa,										
	sum (kg_x_co2eq_per_kg) as soybev_co2eq from soybev														
	group by sampleid;
quit;

/*All other foods*/
data other;
	set day1;
	if food_subgrp=.;
run;
proc sql;
	create table other_sum as
	select sampleid,
	sum (fid_wtg) as other_wtg,									/*Food weight*/	
	sum (fid_ekc) as other_ekc,									/*Energy*/	
	sum (free_sug_g) as other_sug,								/*Sugar*/	
	sum (fid_fas) as other_sat,									/*Sat fat*/	
	sum (fid_pro) as other_pro,									/*Protein*/	
	sum (fid_dmg) as other_vitD,								/*Vitamin D*/	
	sum (fid_cal) as other_ca,									/*Calcium*/	
	sum (fid_iro) as other_fe,									/*Iron*/	
	sum (fid_sod) as other_na,									/*Sodium*/	
	sum (fid_pot) as other_k,									/*Potassium*/
	sum (fid_car) as other_carb,								/*Carbs*/	
	sum (fid_fam) as other_mufa,								/*MUFAs*/
	sum (fid_fap) as other_pufa,								/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as other_co2eq from other			/*CO2-eq*/											
	group by sampleid;
quit;

/*Meat*/ 
data meat;
	set day1;
	if food_subgrp=1 or food_subgrp=2 or food_subgrp=3 or food_subgrp=4;
run;
proc sql;
	create table meat_sum as
	select sampleid,
	sum (fid_wtg) as meat_wtg from meat						
	group by sampleid;
quit;

/*Dairy*/
data dairy;
	set day1;
	if food_subgrp=5 or food_subgrp=6 or food_subgrp=7 or food_subgrp=8 or food_subgrp=9 or food_subgrp=10;
run;
proc sql;
	create table dairy_sum as
	select sampleid,
	sum (fid_wtg) as dairy_wtg from dairy						
	group by sampleid;
quit;

/*Nuts, seeds, and legumes*/ 
data nsl;
	set day1;
	if food_subgrp=11 or food_subgrp=12 or food_subgrp=13 or food_subgrp=14 /*or food_subgrp=15*/;
run;
proc sql;
	create table nsl_sum as
	select sampleid,
	sum (fid_wtg) as nsl_wtg from nsl						
	group by sampleid;
quit;

/*Free sugars*/
proc sql;
	create table freesug_sum as
	select sampleid,
	sum (free_sug_g) as tot_free_sug from day1						
	group by sampleid;
quit;

/***********************************************************************/
/* Step 5.2: Merge sum datasets 									   */
/***********************************************************************/

/*NUTRIENT PROFILES AND GHGE*/

/*Red and processed meat*/
proc sort data=beef_sum; by sampleid; run;
proc sort data=lamb_sum; by sampleid; run;
proc sort data=pork_sum; by sampleid; run;
proc sort data=lnchn_sum; by sampleid; run;
/*Dairy*/
proc sort data=milk_sum; by sampleid; run;
proc sort data=cheese_sum; by sampleid; run;
proc sort data=yghrt_sum; by sampleid; run;
proc sort data=cream_sum; by sampleid; run;
proc sort data=butr_sum; by sampleid; run;
proc sort data=frzn_sum; by sampleid; run;
/*Nuts, seeds, and legumes*/
proc sort data=nuts_sum; by sampleid; run;
proc sort data=seeds_sum; by sampleid; run;
proc sort data=lgmes_sum; by sampleid; run;
proc sort data=tofu_sum; by sampleid; run;
proc sort data=soybev_sum; by sampleid; run;
proc sort data=other_sum; by sampleid; run;
/*Totals*/
proc sort data=meat_sum; by sampleid; run;
proc sort data=dairy_sum; by sampleid; run;
proc sort data=nsl_sum; by sampleid; run;
proc sort data=freesug_sum; by sampleid; run;

/*Merge datasets*/
data baseline;
	merge beef_sum lamb_sum pork_sum lnchn_sum milk_sum cheese_sum yghrt_sum cream_sum butr_sum frzn_sum nuts_sum seeds_sum lgmes_sum tofu_sum soybev_sum other_sum meat_sum dairy_sum nsl_sum freesug_sum;
	by sampleid;
	suppid=1;
run;
/*13,529 observations (PUMF)*/
/*13,612 observations (Master Files)*/

/***********************************************************************/
/*																	   */
/* STEP 6 - Aggregate g of food and ghge for the SECOND RECALL DAY	   */
/*																	   */
/***********************************************************************/

/*Keep only 1st recall day*/
data day2;
	set sbgrps;
	if suppid=2;
run;

/***********************************************************************/
/* Step 6.1: Sum g, GHGE, and nutrients from each food per respondent  */
/***********************************************************************/	    

/*Beef*/
data beef2;
	set day2;
	if food_subgrp=1;
run;
proc sql;
	create table beef_sum2 as
	select sampleid,
	sum (fid_wtg) as beef_wtg,									/*Food weight*/
	sum (fid_ekc) as beef_ekc,									/*Energy*/	
	sum (free_sug_g) as beef_sug,								/*Sugar*/
	sum (fid_fas) as beef_sat,									/*Sat fat*/
	sum (fid_pro) as beef_pro,									/*Protein*/
	sum (fid_dmg) as beef_vitD,									/*Vitamin D*/	
	sum (fid_cal) as beef_ca,									/*Calcium*/
	sum (fid_iro) as beef_fe,									/*Iron*/
	sum (fid_sod) as beef_na,									/*Sodium*/
	sum (fid_pot) as beef_k,									/*Potassium*/
	sum (fid_car) as beef_carb,									/*Carbs*/
	sum (fid_fam) as beef_mufa,									/*MUFAs*/
	sum (fid_fap) as beef_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as beef_co2eq from beef2			/*CO2-eq*/
	group by sampleid;														
quit;

/*Lamb*/
data lamb2;
	set day2;
	if food_subgrp=2;
run;
proc sql;
	create table lamb_sum2 as
	select sampleid,
	sum (fid_wtg) as lamb_wtg,									/*Food weight*/	
	sum (fid_ekc) as lamb_ekc,									/*Energy*/	
	sum (free_sug_g) as lamb_sug,								/*Sugar*/	
	sum (fid_fas) as lamb_sat,									/*Sat fat*/	
	sum (fid_pro) as lamb_pro,									/*Protein*/	
	sum (fid_dmg) as lamb_vitD,									/*Vitamin D*/	
	sum (fid_cal) as lamb_ca,									/*Calcium*/	
	sum (fid_iro) as lamb_fe,									/*Iron*/	
	sum (fid_sod) as lamb_na,									/*Sodium*/	
	sum (fid_pot) as lamb_k,									/*Potassium*/	
	sum (fid_car) as lamb_carb,									/*Carbs*/
	sum (fid_fam) as lamb_mufa,									/*MUFAs*/
	sum (fid_fap) as lamb_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as lamb_co2eq from lamb2			/*CO2-eq*/						
	group by sampleid;
quit;

/*Pork*/
data pork2;
	set day2;
	if food_subgrp=3;
run;
proc sql;
	create table pork_sum2 as
	select sampleid,
	sum (fid_wtg) as pork_wtg,									/*Food weight*/	
	sum (fid_ekc) as pork_ekc,									/*Energy*/	
	sum (free_sug_g) as pork_sug,								/*Sugar*/	
	sum (fid_fas) as pork_sat,									/*Sat fat*/	
	sum (fid_pro) as pork_pro,									/*Protein*/	
	sum (fid_dmg) as pork_vitD,									/*Vitamin D*/	
	sum (fid_cal) as pork_ca,									/*Calcium*/	
	sum (fid_iro) as pork_fe,									/*Iron*/	
	sum (fid_sod) as pork_na,									/*Sodium*/	
	sum (fid_pot) as pork_k,									/*Potassium*/
	sum (fid_car) as pork_carb,									/*Carbs*/	
	sum (fid_fam) as pork_mufa,									/*MUFAs*/
	sum (fid_fap) as pork_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as pork_co2eq from pork2			/*CO2-eq*/						
	group by sampleid;
quit;

/*Luncheon and other meats*/
data lnchn2;
	set day2;
	if food_subgrp=4;
run;
proc sql;
	create table lnchn_sum2 as
	select sampleid,
	sum (fid_wtg) as lnchn_wtg,									/*Food weight*/	
	sum (fid_ekc) as lnchn_ekc,									/*Energy*/	
	sum (free_sug_g) as lnchn_sug,								/*Sugar*/	
	sum (fid_fas) as lnchn_sat,									/*Sat fat*/	
	sum (fid_pro) as lnchn_pro,									/*Protein*/	
	sum (fid_dmg) as lnchn_vitD,								/*Vitamin D*/	
	sum (fid_cal) as lnchn_ca,									/*Calcium*/	
	sum (fid_iro) as lnchn_fe,									/*Iron*/	
	sum (fid_sod) as lnchn_na,									/*Sodium*/	
	sum (fid_pot) as lnchn_k,									/*Potassium*/	
	sum (fid_car) as lnchn_carb,								/*Carbs*/
	sum (fid_fam) as lnchn_mufa,								/*MUFAs*/
	sum (fid_fap) as lnchn_pufa,								/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as lnchn_co2eq from lnchn2			/*CO2-eq*/						
	group by sampleid;
quit;

/*Milk*/
data milk2;
	set day2;
	if food_subgrp=5;
run;
proc sql;
	create table milk_sum2 as
	select sampleid,
	sum (fid_wtg) as milk_wtg,									/*Food weight*/	
	sum (fid_ekc) as milk_ekc,									/*Energy*/	
	sum (free_sug_g) as milk_sug,								/*Sugar*/	
	sum (fid_fas) as milk_sat,									/*Sat fat*/	
	sum (fid_pro) as milk_pro,									/*Protein*/	
	sum (fid_dmg) as milk_vitD,									/*Vitamin D*/	
	sum (fid_cal) as milk_ca,									/*Calcium*/	
	sum (fid_iro) as milk_fe,									/*Iron*/	
	sum (fid_sod) as milk_na,									/*Sodium*/	
	sum (fid_pot) as milk_k,									/*Potassium*/
	sum (fid_car) as milk_carb,									/*Carbs*/
	sum (fid_fam) as milk_mufa,									/*MUFAs*/
	sum (fid_fap) as milk_pufa,									/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as milk_co2eq from milk2			/*CO2-eq*/												
	group by sampleid;
quit;

/*Cheese*/
data cheese2;
	set day2;							
	if food_subgrp=6;
run;
proc sql;
	create table cheese_sum2 as
	select sampleid,
	sum (fid_wtg) as cheese_wtg,								/*Food weight*/	
	sum (fid_ekc) as cheese_ekc,								/*Energy*/	
	sum (free_sug_g) as cheese_sug,								/*Sugar*/	
	sum (fid_fas) as cheese_sat,								/*Sat fat*/	
	sum (fid_pro) as cheese_pro,								/*Protein*/	
	sum (fid_dmg) as cheese_vitD,								/*Vitamin D*/	
	sum (fid_cal) as cheese_ca,									/*Calcium*/	
	sum (fid_iro) as cheese_fe,									/*Iron*/	
	sum (fid_sod) as cheese_na,									/*Sodium*/	
	sum (fid_pot) as cheese_k,									/*Potassium*/
	sum (fid_car) as cheese_carb,								/*Carbs*/
	sum (fid_fam) as cheese_mufa,								/*MUFAs*/
	sum (fid_fap) as cheese_pufa,								/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as cheese_co2eq from cheese2		/*CO2-eq*/									
	group by sampleid;
quit;

/*Yoghurt*/
data yghrt2;
	set day2;
	if food_subgrp=7;
run;
proc sql;
	create table yghrt_sum2 as
	select sampleid,
	sum (fid_wtg) as yghrt_wtg,									/*Food weight*/	
	sum (fid_ekc) as yghrt_ekc,									/*Energy*/	
	sum (free_sug_g) as yghrt_sug,								/*Sugar*/	
	sum (fid_fas) as yghrt_sat,									/*Sat fat*/	
	sum (fid_pro) as yghrt_pro,									/*Protein*/	
	sum (fid_dmg) as yghrt_vitD,								/*Vitamin D*/	
	sum (fid_cal) as yghrt_ca,									/*Calcium*/	
	sum (fid_iro) as yghrt_fe,									/*Iron*/	
	sum (fid_sod) as yghrt_na,									/*Sodium*/	
	sum (fid_pot) as yghrt_k,									/*Potassium*/
	sum (fid_car) as yghrt_carb,								/*Carbs*/
	sum (fid_fam) as yghrt_mufa,								/*MUFAs*/
	sum (fid_fap) as yghrt_pufa,								/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as yghrt_co2eq from yghrt2			/*CO2-eq*/									
	group by sampleid;
quit;

/*Cream*/
data cream2;
	set day2;
	if food_subgrp=8;
run;
proc sql;
	create table cream_sum2 as
	select sampleid,
	sum (fid_wtg) as cream_wtg,									/*Food weight*/	
	sum (fid_ekc) as cream_ekc,									/*Energy*/	
	sum (free_sug_g) as cream_sug,								/*Sugar*/	
	sum (fid_fas) as cream_sat,									/*Sat fat*/	
	sum (fid_pro) as cream_pro,									/*Protein*/	
	sum (fid_dmg) as cream_vitD,								/*Vitamin D*/	
	sum (fid_cal) as cream_ca,									/*Calcium*/	
	sum (fid_iro) as cream_fe,									/*Iron*/	
	sum (fid_sod) as cream_na,									/*Sodium*/	
	sum (fid_pot) as cream_k,									/*Potassium*/
	sum (fid_car) as cream_carb,								/*Carbs*/
	sum (fid_fam) as cream_mufa,								/*MUFAs*/
	sum (fid_fap) as cream_pufa,								/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as cream_co2eq from cream2			/*CO2-eq*/									
	group by sampleid;
quit;

/*Butter*/
data butr2;
	set day2;
	if food_subgrp=9;
run;
proc sql;
	create table butr_sum2 as
	select sampleid,
	sum (fid_wtg) as butr_wtg,									/*Food weight*/	
	sum (fid_ekc) as butr_ekc,									/*Energy*/	
	sum (free_sug_g) as butr_sug,								/*Sugar*/	
	sum (fid_fas) as butr_sat,									/*Sat fat*/	
	sum (fid_pro) as butr_pro,									/*Protein*/	
	sum (fid_dmg) as butr_vitD,									/*Vitamin D*/	
	sum (fid_cal) as butr_ca,									/*Calcium*/	
	sum (fid_iro) as butr_fe,									/*Iron*/	
	sum (fid_sod) as butr_na,									/*Sodium*/	
	sum (fid_pot) as butr_k,									/*Potassium*/	
	sum (fid_car) as butr_carb,									/*Carbs*/
	sum (fid_fam) as butr_mufa,									/*MUFAs*/
	sum (fid_fap) as butr_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as butr_co2eq from butr2			/*CO2-eq*/											
	group by sampleid;
quit;

/*Frozen dairy*/
data frzn2;
	set day2;
	if food_subgrp=10;
run;
proc sql;
	create table frzn_sum2 as
	select sampleid,
	sum (fid_wtg) as frzn_wtg,									/*Food weight*/	
	sum (fid_ekc) as frzn_ekc,									/*Energy*/	
	sum (free_sug_g) as frzn_sug,								/*Sugar*/	
	sum (fid_fas) as frzn_sat,									/*Sat fat*/	
	sum (fid_pro) as frzn_pro,									/*Protein*/	
	sum (fid_dmg) as frzn_vitD,									/*Vitamin D*/	
	sum (fid_cal) as frzn_ca,									/*Calcium*/	
	sum (fid_iro) as frzn_fe,									/*Iron*/	
	sum (fid_sod) as frzn_na,									/*Sodium*/	
	sum (fid_pot) as frzn_k,									/*Potassium*/
	sum (fid_car) as frzn_carb,									/*Carbs*/	
	sum (fid_fam) as frzn_mufa,									/*MUFAs*/
	sum (fid_fap) as frzn_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as frzn_co2eq from frzn2			/*CO2-eq*/											
	group by sampleid;
quit;

/*Nuts*/
data nuts2;
	set day2;
	if food_subgrp=11;
run;
proc sql;
	create table nuts_sum2 as
	select sampleid,
	sum (fid_wtg) as nuts_wtg,									/*Food weight*/	
	sum (fid_ekc) as nuts_ekc,									/*Energy*/	
	sum (free_sug_g) as nuts_sug,								/*Sugar*/	
	sum (fid_fas) as nuts_sat,									/*Sat fat*/	
	sum (fid_pro) as nuts_pro,									/*Protein*/	
	sum (fid_dmg) as nuts_vitD,									/*Vitamin D*/	
	sum (fid_cal) as nuts_ca,									/*Calcium*/	
	sum (fid_iro) as nuts_fe,									/*Iron*/	
	sum (fid_sod) as nuts_na,									/*Sodium*/	
	sum (fid_pot) as nuts_k,									/*Potassium*/
	sum (fid_car) as nuts_carb,									/*Carbs*/	
	sum (fid_fam) as nuts_mufa,									/*MUFAs*/
	sum (fid_fap) as nuts_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as nuts_co2eq from nuts2			/*CO2-eq*/								
	group by sampleid;
quit;

/*Seeds*/
data seeds2;
	set day2;
	if food_subgrp=12;
run;
proc sql;
	create table seeds_sum2 as
	select sampleid,
	sum (fid_wtg) as seeds_wtg,									/*Food weight*/	
	sum (fid_ekc) as seeds_ekc,									/*Energy*/	
	sum (free_sug_g) as seeds_sug,								/*Sugar*/	
	sum (fid_fas) as seeds_sat,									/*Sat fat*/	
	sum (fid_pro) as seeds_pro,									/*Protein*/	
	sum (fid_dmg) as seeds_vitD,								/*Vitamin D*/	
	sum (fid_cal) as seeds_ca,									/*Calcium*/	
	sum (fid_iro) as seeds_fe,									/*Iron*/	
	sum (fid_sod) as seeds_na,									/*Sodium*/	
	sum (fid_pot) as seeds_k,									/*Potassium*/
	sum (fid_car) as seeds_carb,								/*Carbs*/
	sum (fid_fam) as seeds_mufa,								/*MUFAs*/
	sum (fid_fap) as seeds_pufa,								/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as seeds_co2eq from seeds2			/*CO2-eq*/							
	group by sampleid;
quit;
	
/*Legumes*/
data lgmes2;
	set day2;
	if food_subgrp=13;
run;
proc sql;
	create table lgmes_sum2 as
	select sampleid,
	sum (fid_wtg) as lgmes_wtg,									/*Food weight*/	
	sum (fid_ekc) as lgmes_ekc,									/*Energy*/	
	sum (free_sug_g) as lgmes_sug,								/*Sugar*/	
	sum (fid_fas) as lgmes_sat,									/*Sat fat*/	
	sum (fid_pro) as lgmes_pro,									/*Protein*/	
	sum (fid_dmg) as lgmes_vitD,								/*Vitamin D*/	
	sum (fid_cal) as lgmes_ca,									/*Calcium*/	
	sum (fid_iro) as lgmes_fe,									/*Iron*/	
	sum (fid_sod) as lgmes_na,									/*Sodium*/	
	sum (fid_pot) as lgmes_k,									/*Potassium*/
	sum (fid_car) as lgmes_carb,								/*Carbs*/
	sum (fid_fam) as lgmes_mufa,								/*MUFAs*/
	sum (fid_fap) as lgmes_pufa,								/*PUFAs*/	
	sum (kg_x_co2eq_per_kg) as lgmes_co2eq from lgmes2			/*CO2-eq*/						
	group by sampleid;
quit;

/*Tofu*/
data tofu2;
	set day2;
	if food_subgrp=14;
run;
proc sql;
	create table tofu_sum2 as
	select sampleid,
	sum (fid_wtg) as tofu_wtg,									/*Food weight*/	
	sum (fid_ekc) as tofu_ekc,									/*Energy*/	
	sum (free_sug_g) as tofu_sug,								/*Sugar*/	
	sum (fid_fas) as tofu_sat,									/*Sat fat*/	
	sum (fid_pro) as tofu_pro,									/*Protein*/	
	sum (fid_dmg) as tofu_vitD,									/*Vitamin D*/	
	sum (fid_cal) as tofu_ca,									/*Calcium*/	
	sum (fid_iro) as tofu_fe,									/*Iron*/	
	sum (fid_sod) as tofu_na,									/*Sodium*/	
	sum (fid_pot) as tofu_k,									/*Potassium*/
	sum (fid_car) as tofu_carb,									/*Carbs*/	
	sum (fid_fam) as tofu_mufa,									/*MUFAs*/
	sum (fid_fap) as tofu_pufa,									/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as tofu_co2eq from tofu2			/*CO2-eq*/								
	group by sampleid;
quit;

/*Soy beverage*/
data soybev2;
	set day2;
	if food_subgrp=15;
run;
proc sql;
	create table soybev_sum2 as
	select sampleid,
	sum (fid_wtg) as soybev_wtg,									
	sum (fid_ekc) as soybev_ekc,							
	sum (free_sug_g) as soybev_sug,								
	sum (fid_fas) as soybev_sat,								
	sum (fid_pro) as soybev_pro,							
	sum (fid_dmg) as soybev_vitD,								
	sum (fid_cal) as soybev_ca,								
	sum (fid_iro) as soybev_fe,										
	sum (fid_sod) as soybev_na,									
	sum (fid_pot) as soybev_k,	
	sum (fid_car) as soybev_carb,
	sum (fid_fam) as soybev_mufa,									
	sum (fid_fap) as soybev_pufa,									
	sum (kg_x_co2eq_per_kg) as soybev_co2eq from soybev2												
	group by sampleid;
quit;

/*All other foods*/
data other2;
	set day2;
	if food_subgrp=.;
run;
proc sql;
	create table other_sum2 as
	select sampleid,
	sum (fid_wtg) as other_wtg,									/*Food weight*/	
	sum (fid_ekc) as other_ekc,									/*Energy*/	
	sum (free_sug_g) as other_sug,								/*Sugar*/	
	sum (fid_fas) as other_sat,									/*Sat fat*/	
	sum (fid_pro) as other_pro,									/*Protein*/	
	sum (fid_dmg) as other_vitD,								/*Vitamin D*/	
	sum (fid_cal) as other_ca,									/*Calcium*/	
	sum (fid_iro) as other_fe,									/*Iron*/	
	sum (fid_sod) as other_na,									/*Sodium*/	
	sum (fid_pot) as other_k,									/*Potassium*/	
	sum (fid_car) as other_carb,								/*Carbs*/
	sum (fid_fam) as other_mufa,								/*MUFAs*/
	sum (fid_fap) as other_pufa,								/*PUFAs*/
	sum (kg_x_co2eq_per_kg) as other_co2eq from other2			/*CO2-eq*/											
	group by sampleid;
quit;

/*Meat*/ 
data meat2;
	set day2;
	if food_subgrp=1 or food_subgrp=2 or food_subgrp=3 or food_subgrp=4;
run;
proc sql;
	create table meat_sum2 as
	select sampleid,
	sum (fid_wtg) as meat_wtg from meat2						
	group by sampleid;
quit;

/*Dairy*/
data dairy2;
	set day2;
	if food_subgrp=5 or food_subgrp=6 or food_subgrp=7 or food_subgrp=8 or food_subgrp=9 or food_subgrp=10;
run;
proc sql;
	create table dairy_sum2 as
	select sampleid,
	sum (fid_wtg) as dairy_wtg from dairy2						
	group by sampleid;
quit;

/*Nuts, seeds, and legumes*/ 
data nsl2;
	set day2;
	if food_subgrp=11 or food_subgrp=12 or food_subgrp=13 or food_subgrp=14 /*or food_subgrp=15*/;
run;
proc sql;
	create table nsl_sum2 as
	select sampleid,
	sum (fid_wtg) as nsl_wtg from nsl2						
	group by sampleid;
quit;

/*Free sugars*/
proc sql;
	create table freesug_sum2 as
	select sampleid,
	sum (free_sug_g) as tot_free_sug from day2						
	group by sampleid;
quit;

/***********************************************************************/
/* Step 6.2: Merge sum datasets 									   */
/***********************************************************************/

/*NUTRIENT PROFILES AND GHGE*/

/*Red and processed meat*/
proc sort data=beef_sum2; by sampleid; run;
proc sort data=lamb_sum2; by sampleid; run;
proc sort data=pork_sum2; by sampleid; run;
proc sort data=lnchn_sum2; by sampleid; run;
/*Dairy*/
proc sort data=milk_sum2; by sampleid; run;
proc sort data=cheese_sum2; by sampleid; run;
proc sort data=yghrt_sum2; by sampleid; run;
proc sort data=cream_sum2; by sampleid; run;
proc sort data=butr_sum2; by sampleid; run;
proc sort data=frzn_sum2; by sampleid; run;
/*Nuts, seeds, and legumes*/
proc sort data=nuts_sum2; by sampleid; run;
proc sort data=seeds_sum2; by sampleid; run;
proc sort data=lgmes_sum2; by sampleid; run;
proc sort data=tofu_sum2; by sampleid; run;
proc sort data=soybev_sum2; by sampleid; run;
proc sort data=other_sum2; by sampleid; run;
/*Totals*/
proc sort data=meat_sum2; by sampleid; run;
proc sort data=dairy_sum2; by sampleid; run;
proc sort data=nsl_sum2; by sampleid; run;
proc sort data=freesug_sum2; by sampleid; run;

/*Merge datasets*/
data baseline2;
	merge beef_sum2 lamb_sum2 pork_sum2 lnchn_sum2 milk_sum2 cheese_sum2 yghrt_sum2 cream_sum2 butr_sum2 frzn_sum2 nuts_sum2 seeds_sum2 lgmes_sum2 tofu_sum2 soybev_sum2 other_sum2 meat_sum2 dairy_sum2 nsl_sum2 freesug_sum2;
	by sampleid;
	suppid=2;
run;

/***********************************************************************/
/*																	   */
/* STEP 7 - Merge BOTH RECALL DAYS									   */
/*																	   */
/***********************************************************************/

/*HS_NCI (1 or 2 records per respondent depending on whether they did 1 or 2 recalls*/
libname hs_nci "S:\CCHS_ESCC_2015_NU\CCHS_ESCC_2015_NU_v3\data_donnees\data\sas_en\HS_NCI";
data hs_nci; set hs_nci.cchs_2015_hs_nci_nofmt_f1_v1;
run;

/*Apply exclusion criteria and create demographic variables*/
data nci_exclu;
	set hs_nci;

/*Apply exclusion criteria*/
	if dhh_age <19 then delete;																				/*Respondents <19 y*/
	if whc_03=1 then delete;																				/*Pregnant women*/
	if whc_05=1 then delete;																				/*Breastfeeding women*/
	if sampleid='1207019131002865079_'																		/*Respondents that did not complete a 24-h recall*/
	or sampleid='3518029531110247512_'
	or sampleid='3520483061118731181_'
	or sampleid='35D0741841124421623_' then delete;

/*Demographics*/
	/* Sex*/
	if DHH_SEX=1 then sex=1; else sex=2;																	/* Males=1 and females=2 */

	/* DRI age groups*/
	if DHHDDRI in (8,9) then age_grp=1;																		/* 19-30 y */
	if DHHDDRI in (10,11) then age_grp=2;																	/* 31-50 y */
	if DHHDDRI in (12,13) then age_grp=3;																	/* 51-70 y */
	if DHHDDRI in (14,15) then age_grp=4;																	/* 71+ y */

	/*Ethnicity*/
	if SDC_43A=1 then ethncty=1;																			/*White*/ 																			
	if SDC_41=1 or SDC_43B=1 or SDC_43J=1 or SDC_43K=1 or SDC_43E=1
	or SDC_43G=1 or SDC_43C=1 or SDC_43H=1 or SDC_43I=1 or SDC_43D=1
	or SDC_43F=1 or SDC_43L=1 then ethncty=2;																/*Other*/
	if ethncty=. then ethncty=2;

	/*Education level*/
	if EDU_21=01 OR EDU_21=96 OR EDU_21=97 OR EDU_21=98 OR EDU_21=99 then edu=1; 							/*Less than secondary or skips*/
	if EDU_21=02 then edu=2;																				/*Secondary*/
	if EDU_21=03 OR EDU_21=04 OR EDU_21=05 then edu=3; 														/*Some post-secondary*/
	if EDU_21=06 OR EDU_21=07 then edu=4;																	/*Post-secondary*/																						

	/*Income*/
	if INC_05B=01 or INC_05B=02 or INC_05B=03 or INC_05B=04 or INC_05B=05 or INC_05B=06
	or INC_05B=07 then incm=1;					  															/*<50 K*/              
	if INC_05C=01 or INC_05C=02 or INC_05C=03 or INC_05C=04 or INC_05C=05 then incm=2; 					   	/*50K-100K*/ 
	if INC_05C=06 then incm=3; 							                                               		/*100K-150K*/ 
	if INC_05C=07 then incm=4;							                                              		/*>150K*/  

/*GBD age groups (to be used for health outcomes)*/
	if dhh_age>=19 and dhh_age=<24 then age_gbd=1;
	if dhh_age>=25 and dhh_age=<29 then age_gbd=2;
	if dhh_age>=30 and dhh_age=<34 then age_gbd=3;
	if dhh_age>=35 and dhh_age=<39 then age_gbd=4;
	if dhh_age>=40 and dhh_age=<44 then age_gbd=5;
	if dhh_age>=45 and dhh_age=<49 then age_gbd=6;
	if dhh_age>=50 and dhh_age=<54 then age_gbd=7;
	if dhh_age>=55 and dhh_age=<59 then age_gbd=8;
	if dhh_age>=60 and dhh_age=<64 then age_gbd=9;
	if dhh_age>=65 and dhh_age=<69 then age_gbd=10;
	if dhh_age>=70 and dhh_age=<74 then age_gbd=11;
	if dhh_age>=75 and dhh_age=<79 then age_gbd=12;
	if dhh_age>=80 and dhh_age=<84 then age_gbd=13;
	if dhh_age>=85 and dhh_age=<89 then age_gbd=14;
	if dhh_age>=90 and dhh_age=<94 then age_gbd=15;
	if dhh_age>=95 then age_gbd=16;

/*Covariates for NCI*/
	seq2=(SUPPID=2);
	weekend=(ADMFW=2);
	if DHH_SEX=1 then sex=0; else sex=1;

	keep sampleid suppid wts_m wts_mhw admfw dhhddri dhh_sex dhh_age mhwdbmi mhwdhtm mhwdwtk sex age_grp ethncty edu incm
	fsddwtg fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddcar fsddesa fsddeca fsddepr fsddcar age_gbd
	fsddfam fsddfap VSDFCAL VSDFIRO VSDFPOT VSDFSOD VSDFSOD VSDFDMG DHHDDRI
	seq2 weekend;

run;
/*17,921 observations*/
/*13,612 respondents*/

/*Merge day1 and day2*/
data baseline_all;
	set baseline baseline2;
run;
/*17,921 observations*/

proc sort data=nci_exclu; by sampleid suppid; run;
proc sort data=baseline_all; by sampleid suppid; run;

data baseline_final;
	merge nci_exclu baseline_all;
	by sampleid suppid;
	idnty=1;
run;
/*17,921 observations*/

/*Check n*/
/*data n;
	update baseline_final(obs=0)baseline_final;
	by sampleid;
run;
/*13,612 observations (i.e., respondents)*/
/*proc freq data=baseline_final;
	table suppid;
run;
/*13,612 1st recalls*/
/*4,309 2nd recalls*/

/***********************************************************************/
/*																	   */
/* STEP 8 - SUPPLEMENTS												   */
/*																	   */
/***********************************************************************/

/*VDC file (description of nutritional supplements and amount per dosage unit; like FDC)*/
/*libname vdc "S:\CCHS_ESCC_2015_NU\CCHS_ESCC_2015_NU_v3\data_donnees\data\sas_en\VDC";
data vdc; set vdc.cchs_2015_vdc_nofmt_f1_v1;
run;

/*VST file*/
libname vst "S:\CCHS_ESCC_2015_NU\CCHS_ESCC_2015_NU_v3\data_donnees\data\sas_en\VST";
data vst; set vst.cchs_2015_vst_nofmt_f1_v1;
run;

/*Cleaning up VST file based on our nutrients of interest*/
data vst_nutr_cncrn;
	set vst;
	if VSTDCAL>99999 then VSTDCAL=.;									/*Total daily calcium intake from all supplement sources (mg)*/
	if VSTDIRO>99999 then VSTDIRO=.;									/*Total daily iron intake from all supplement sources (mg)*/
	if VSTDPOT>99999 then VSTDPOT=.;									/*Total daily potassium intake from all supplement sources (mg)*/
	if VSTDDMG>99999 then VSTDDMG=.;									/*Total daily viamin D intake from all supplement sources (mcg)*/
	if VSTDSOD>99999 then VSTDSOD=.;									/*Total daily sodium intake from all supplement sources (mg)*/
	keep sampleid suppid VSTDCAL VSTDIRO VSTDPOT VSTDDMG VSTDSOD;
run;

/*I'd have to make seperate files for day1 and day2 then merge with baseline (day1) and baseline2 (day2) summary files.
Then I'd add intake from supplements to total nutrient intakes at the end.*/
	
proc sort data=vst_nutr_cncrn; by sampleid suppid; run;

data final_sample_supp;
	merge vst_nutr_cncrn baseline_final;
	by sampleid suppid;
	if idnty=1;
	drop idnty;
run; 
/*17,921 obs*/

/*Check % of sample taking supplements by DRI group*/
data freq_supp; set nci_exclu; if suppid=1; run;
/*13,612 obs*/
proc freq data=freq_supp;
	table vsdfcal*dhhddri;
run;
proc freq data=freq_supp;
	table vsdfiro*dhhddri;
run;
proc freq data=freq_supp;
	table vsdfpot*dhhddri;
run;
/*proc freq data=freq_supp;
	table vsdfsod*dhhddri;
run;*/
proc freq data=freq_supp;
	table vsdfdmg*dhhddri;
run;

/***********************************************************************/
/*																	   */
/* STEP 9 - Create ratios for nuts, seeds, and legumes				   */
/*			and % energy from free sug							       */
/*																	   */
/***********************************************************************/

data baseline_final;
	set baseline_final;

/*Create ratios for g of nuts, seeds, and legumes consumed individually relative to total*/
	if nuts_wtg ne . then nuts_pcnt=(nuts_wtg/nsl_wtg);
	if seeds_wtg ne . then seeds_pcnt=(seeds_wtg/nsl_wtg);
	if lgmes_wtg ne . then lgmes_pcnt=(lgmes_wtg/nsl_wtg);
	if tofu_wtg ne . then tofu_pcnt=(tofu_wtg/nsl_wtg);

/*Set missing values to 0*/
	if nuts_pcnt=. then nuts_pcnt=0;
	if seeds_pcnt=. then seeds_pcnt=0;
	if lgmes_pcnt=. then lgmes_pcnt=0;
	if tofu_pcnt=. then tofu_pcnt=0;

/*We also want to create variables for % tot energy intake from free sug and sat fat*/
	if tot_free_sug ne 0 and fsddekc ne 0 then tot_sug_pcnt=((tot_free_sug*4)/fsddekc)*100;
	if tot_free_sug=0 then tot_sug_pcnt=0;

/*We also need to create a variable for total nsl (including soy bev), only relevent to obs diets*/

/*Compare to variable fsddesa*/
	/*if fsddfas ne 0 and fsddekc ne 0 then satfat_pcnt=((fsddfas*9)/fsddekc)*100;
	if fsddfas=0 then satfat_pcnt=0;
 
	if fsddcar ne 0 and fsddekc ne 0 then carb_pcnt=((fsddcar*4)/fsddekc)*100;
	if fsddcar=0 then carb_pcnt=0;

	if fsddpro ne 0 and fsddekc ne 0 then prot_pcnt=((fsddpro*4)/fsddekc)*100;
	if fsddpro=0 then prot_pcnt=0;*/

run;
/*17,921 observations (Master Files)*/
/*3 missing values for satfat_pcnt; these repsondents have values for satfat but 0 energy intake*/

proc means data=baseline_final;
var tot_free_sug tot_sug_pcnt;
run;

/*proc means n nmiss min max mean data=baseline_final;
	var fsddfas fsddcar fsddpro satfat_pcnt carb_pcnt prot_pcnt fsddesa fsddeca fsddepr;
run;
/*My calculated values are not exactly equal to derived variables*/

/*Ratios (Master Files) of nuts, seeds, and legumes consumed by overall sample, unweighted (see supplementary step at the end of this code):
  	- Total nuts = 166353.37557 / 551590.52918 = 0.301588528
  	- Total seeds = 19529.603249 / 551590.52918 = 0.03540598
  	- Total legumes = 328392.51782 / 551590.52918 = 0.595355613
  	- Total tofu = 37315.032535 / 551590.52918 = 0.067649879

/***********************************************************************/
/*																	   */
/* STEP 10 - Create unique multipliers for GHGE and nutrients   	   */
/*			based on respondents' consumption profiles				   */
/*																	   */
/***********************************************************************/

/*Explanation of variables:
		- beef_wtg: g of beef consumed by each individual
		- beef_co2eq: co2-eq/kg x kg = co2-eq from beef [per food item]
		- unq_beef_co2eq: co2-eq / kg = co2-eq/kg [per person] (i.e., unique GHGE value based on each respondents' beef consumption profile)
			-> this variable can be used as a unique multiplier to estimate co2eq for foods post=replacement*/ 

data baseline_final;
	set baseline_final;

/*Unique GHGE per person based on thier consumption profile (expressed in CO2-eq/kg)*/
	if beef_wtg ne . and beef_co2eq ne . then unq_beef_co2eq=beef_co2eq/(beef_wtg/1000);	
	if lamb_wtg ne . and lamb_co2eq ne . then unq_lamb_co2eq=lamb_co2eq/(lamb_wtg/1000);
	if pork_wtg ne . and pork_co2eq ne . then unq_pork_co2eq=pork_co2eq/(pork_wtg/1000);
	if lnchn_wtg ne . and lnchn_co2eq ne . then unq_lnchn_co2eq=lnchn_co2eq/(lnchn_wtg/1000);
	if milk_wtg ne . and milk_co2eq ne . then unq_milk_co2eq=milk_co2eq/(milk_wtg/1000);	
	if cheese_wtg ne . and cheese_co2eq ne . then unq_cheese_co2eq=cheese_co2eq/(cheese_wtg/1000);	
	if yghrt_wtg ne . and yghrt_co2eq ne . then unq_yghrt_co2eq=yghrt_co2eq/(yghrt_wtg/1000);	
	if cream_wtg ne . and cream_co2eq ne . then unq_cream_co2eq=cream_co2eq/(cream_wtg/1000);	
	if butr_wtg ne . and butr_co2eq ne . then unq_butr_co2eq=butr_co2eq/(butr_wtg/1000);	
	if frzn_wtg ne . and frzn_co2eq ne . then unq_frzn_co2eq=frzn_co2eq/(frzn_wtg/1000);	
	if nuts_wtg ne . and nuts_co2eq ne . then unq_nuts_co2eq=nuts_co2eq/(nuts_wtg/1000);
	if seeds_wtg ne . and seeds_co2eq ne . then unq_seeds_co2eq=seeds_co2eq/(seeds_wtg/1000);
	if lgmes_wtg ne . and lgmes_co2eq ne . then unq_lgmes_co2eq=lgmes_co2eq/(lgmes_wtg/1000);	
	if tofu_wtg ne . and tofu_co2eq ne . then unq_tofu_co2eq=tofu_co2eq/(tofu_wtg/1000);		
	if soybev_wtg ne . and soybev_co2eq ne . then unq_soybev_co2eq=soybev_co2eq/(soybev_wtg/1000);

/*Unique NUTRIENTS per person based on consumption profile (expressed in units/g)*/
	/*Beef*/
	if beef_wtg ne . and beef_ekc ne . then unq_beef_ekc=beef_ekc/beef_wtg;
	if beef_wtg ne . and beef_sug ne . then unq_beef_sug=beef_sug/beef_wtg;
	if beef_wtg ne . and beef_sat ne . then unq_beef_sat=beef_sat/beef_wtg;
	if beef_wtg ne . and beef_pro ne . then unq_beef_pro=beef_pro/beef_wtg;
	if beef_wtg ne . and beef_vitD ne . then unq_beef_vitD=beef_vitD/beef_wtg;
	if beef_wtg ne . and beef_ca ne . then unq_beef_ca=beef_ca/beef_wtg;
	if beef_wtg ne . and beef_fe ne . then unq_beef_fe=beef_fe/beef_wtg;
	if beef_wtg ne . and beef_na ne . then unq_beef_na=beef_na/beef_wtg;
	if beef_wtg ne . and beef_k ne . then unq_beef_k=beef_k/beef_wtg;
	if beef_wtg ne . and beef_carb ne . then unq_beef_carb=beef_carb/beef_wtg;
	if beef_wtg ne . and beef_mufa ne . then unq_beef_mufa=beef_mufa/beef_wtg;
	if beef_wtg ne . and beef_pufa ne . then unq_beef_pufa=beef_pufa/beef_wtg;
	/*Lamb*/
	if lamb_wtg ne . and lamb_ekc ne . then unq_lamb_ekc=lamb_ekc/lamb_wtg;
	if lamb_wtg ne . and lamb_sug ne . then unq_lamb_sug=lamb_sug/lamb_wtg;
	if lamb_wtg ne . and lamb_sat ne . then unq_lamb_sat=lamb_sat/lamb_wtg;
	if lamb_wtg ne . and lamb_pro ne . then unq_lamb_pro=lamb_pro/lamb_wtg;
	if lamb_wtg ne . and lamb_vitD ne . then unq_lamb_vitD=lamb_vitD/lamb_wtg;
	if lamb_wtg ne . and lamb_ca ne . then unq_lamb_ca=lamb_ca/lamb_wtg;
	if lamb_wtg ne . and lamb_fe ne . then unq_lamb_fe=lamb_fe/lamb_wtg;
	if lamb_wtg ne . and lamb_na ne . then unq_lamb_na=lamb_na/lamb_wtg;
	if lamb_wtg ne . and lamb_k ne . then unq_lamb_k=lamb_k/lamb_wtg;
	if lamb_wtg ne . and lamb_carb ne . then unq_lamb_carb=lamb_carb/lamb_wtg;
	if lamb_wtg ne . and lamb_mufa ne . then unq_lamb_mufa=lamb_mufa/lamb_wtg;
	if lamb_wtg ne . and lamb_pufa ne . then unq_lamb_pufa=lamb_pufa/lamb_wtg;
	/*Pork*/
	if pork_wtg ne . and pork_ekc ne . then unq_pork_ekc=pork_ekc/pork_wtg;
	if pork_wtg ne . and pork_sug ne . then unq_pork_sug=pork_sug/pork_wtg;
	if pork_wtg ne . and pork_sat ne . then unq_pork_sat=pork_sat/pork_wtg;
	if pork_wtg ne . and pork_pro ne . then unq_pork_pro=pork_pro/pork_wtg;
	if pork_wtg ne . and pork_vitD ne . then unq_pork_vitD=pork_vitD/pork_wtg;
	if pork_wtg ne . and pork_ca ne . then unq_pork_ca=pork_ca/pork_wtg;
	if pork_wtg ne . and pork_fe ne . then unq_pork_fe=pork_fe/pork_wtg;
	if pork_wtg ne . and pork_na ne . then unq_pork_na=pork_na/pork_wtg;
	if pork_wtg ne . and pork_k ne . then unq_pork_k=pork_k/pork_wtg;
	if pork_wtg ne . and pork_carb ne . then unq_pork_carb=pork_carb/pork_wtg;
	if pork_wtg ne . and pork_mufa ne . then unq_pork_mufa=pork_mufa/pork_wtg;
	if pork_wtg ne . and pork_pufa ne . then unq_pork_pufa=pork_pufa/pork_wtg;
	/*Luncheon and other meats*/
	if lnchn_wtg ne . and lnchn_ekc ne . then unq_lnchn_ekc=lnchn_ekc/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_sug ne . then unq_lnchn_sug=lnchn_sug/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_sat ne . then unq_lnchn_sat=lnchn_sat/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_pro ne . then unq_lnchn_pro=lnchn_pro/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_vitD ne . then unq_lnchn_vitD=lnchn_vitD/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_ca ne . then unq_lnchn_ca=lnchn_ca/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_fe ne . then unq_lnchn_fe=lnchn_fe/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_na ne . then unq_lnchn_na=lnchn_na/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_k ne . then unq_lnchn_k=lnchn_k/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_carb ne . then unq_lnchn_carb=lnchn_carb/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_mufa ne . then unq_lnchn_mufa=lnchn_mufa/lnchn_wtg;
	if lnchn_wtg ne . and lnchn_pufa ne . then unq_lnchn_pufa=lnchn_pufa/lnchn_wtg;
	/*Milk*/
	if milk_wtg ne . and milk_ekc ne . then unq_milk_ekc=milk_ekc/milk_wtg;
	if milk_wtg ne . and milk_sug ne . then unq_milk_sug=milk_sug/milk_wtg;
	if milk_wtg ne . and milk_sat ne . then unq_milk_sat=milk_sat/milk_wtg;
	if milk_wtg ne . and milk_pro ne . then unq_milk_pro=milk_pro/milk_wtg;
	if milk_wtg ne . and milk_vitD ne . then unq_milk_vitD=milk_vitD/milk_wtg;
	if milk_wtg ne . and milk_ca ne . then unq_milk_ca=milk_ca/milk_wtg;
	if milk_wtg ne . and milk_fe ne . then unq_milk_fe=milk_fe/milk_wtg;
	if milk_wtg ne . and milk_na ne . then unq_milk_na=milk_na/milk_wtg;
	if milk_wtg ne . and milk_k ne . then unq_milk_k=milk_k/milk_wtg;
	if milk_wtg ne . and milk_carb ne . then unq_milk_carb=milk_carb/milk_wtg;
	if milk_wtg ne . and milk_mufa ne . then unq_milk_mufa=milk_mufa/milk_wtg;
	if milk_wtg ne . and milk_pufa ne . then unq_milk_pufa=milk_pufa/milk_wtg;
	/*Cheese*/
	if cheese_wtg ne . and cheese_ekc ne . then unq_cheese_ekc=cheese_ekc/cheese_wtg;
	if cheese_wtg ne . and cheese_sug ne . then unq_cheese_sug=cheese_sug/cheese_wtg;
	if cheese_wtg ne . and cheese_sat ne . then unq_cheese_sat=cheese_sat/cheese_wtg;
	if cheese_wtg ne . and cheese_pro ne . then unq_cheese_pro=cheese_pro/cheese_wtg;
	if cheese_wtg ne . and cheese_vitD ne . then unq_cheese_vitD=cheese_vitD/cheese_wtg;
	if cheese_wtg ne . and cheese_ca ne . then unq_cheese_ca=cheese_ca/cheese_wtg;
	if cheese_wtg ne . and cheese_fe ne . then unq_cheese_fe=cheese_fe/cheese_wtg;
	if cheese_wtg ne . and cheese_na ne . then unq_cheese_na=cheese_na/cheese_wtg;
	if cheese_wtg ne . and cheese_k ne . then unq_cheese_k=cheese_k/cheese_wtg;
	if cheese_wtg ne . and cheese_carb ne . then unq_cheese_carb=cheese_carb/cheese_wtg;
	if cheese_wtg ne . and cheese_mufa ne . then unq_cheese_mufa=cheese_mufa/cheese_wtg;
	if cheese_wtg ne . and cheese_pufa ne . then unq_cheese_pufa=cheese_pufa/cheese_wtg;
	/*Yoghurt*/
	if yghrt_wtg ne . and yghrt_ekc ne . then unq_yghrt_ekc=yghrt_ekc/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_sug ne . then unq_yghrt_sug=yghrt_sug/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_sat ne . then unq_yghrt_sat=yghrt_sat/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_pro ne . then unq_yghrt_pro=yghrt_pro/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_vitD ne . then unq_yghrt_vitD=yghrt_vitD/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_ca ne . then unq_yghrt_ca=yghrt_ca/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_fe ne . then unq_yghrt_fe=yghrt_fe/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_na ne . then unq_yghrt_na=yghrt_na/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_k ne . then unq_yghrt_k=yghrt_k/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_carb ne . then unq_yghrt_carb=yghrt_carb/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_mufa ne . then unq_yghrt_mufa=yghrt_mufa/yghrt_wtg;
	if yghrt_wtg ne . and yghrt_pufa ne . then unq_yghrt_pufa=yghrt_pufa/yghrt_wtg;
	/*Creams*/
	if cream_wtg ne . and cream_ekc ne . then unq_cream_ekc=cream_ekc/cream_wtg;
	if cream_wtg ne . and cream_sug ne . then unq_cream_sug=cream_sug/cream_wtg;
	if cream_wtg ne . and cream_sat ne . then unq_cream_sat=cream_sat/cream_wtg;
	if cream_wtg ne . and cream_pro ne . then unq_cream_pro=cream_pro/cream_wtg;
	if cream_wtg ne . and cream_vitD ne . then unq_cream_vitD=cream_vitD/cream_wtg;
	if cream_wtg ne . and cream_ca ne . then unq_cream_ca=cream_ca/cream_wtg;
	if cream_wtg ne . and cream_fe ne . then unq_cream_fe=cream_fe/cream_wtg;
	if cream_wtg ne . and cream_na ne . then unq_cream_na=cream_na/cream_wtg;
	if cream_wtg ne . and cream_k ne . then unq_cream_k=cream_k/cream_wtg;
	if cream_wtg ne . and cream_carb ne . then unq_cream_carb=cream_carb/cream_wtg;
	if cream_wtg ne . and cream_mufa ne . then unq_cream_mufa=cream_mufa/cream_wtg;
	if cream_wtg ne . and cream_pufa ne . then unq_cream_pufa=cream_pufa/cream_wtg;
	/*Butter*/
	if butr_wtg ne . and butr_ekc ne . then unq_butr_ekc=butr_ekc/butr_wtg;
	if butr_wtg ne . and butr_sug ne . then unq_butr_sug=butr_sug/butr_wtg;
	if butr_wtg ne . and butr_sat ne . then unq_butr_sat=butr_sat/butr_wtg;
	if butr_wtg ne . and butr_pro ne . then unq_butr_pro=butr_pro/butr_wtg;
	if butr_wtg ne . and butr_vitD ne . then unq_butr_vitD=butr_vitD/butr_wtg;
	if butr_wtg ne . and butr_ca ne . then unq_butr_ca=butr_ca/butr_wtg;
	if butr_wtg ne . and butr_fe ne . then unq_butr_fe=butr_fe/butr_wtg;
	if butr_wtg ne . and butr_na ne . then unq_butr_na=butr_na/butr_wtg;
	if butr_wtg ne . and butr_k ne . then unq_butr_k=butr_k/butr_wtg;
	if butr_wtg ne . and butr_carb ne . then unq_butr_carb=butr_carb/butr_wtg;
	if butr_wtg ne . and butr_mufa ne . then unq_butr_mufa=butr_mufa/butr_wtg;
	if butr_wtg ne . and butr_pufa ne . then unq_butr_pufa=butr_pufa/butr_wtg;
	/*Frozen dairy*/
	if frzn_wtg ne . and frzn_ekc ne . then unq_frzn_ekc=frzn_ekc/frzn_wtg;
	if frzn_wtg ne . and frzn_sug ne . then unq_frzn_sug=frzn_sug/frzn_wtg;
	if frzn_wtg ne . and frzn_sat ne . then unq_frzn_sat=frzn_sat/frzn_wtg;
	if frzn_wtg ne . and frzn_pro ne . then unq_frzn_pro=frzn_pro/frzn_wtg;
	if frzn_wtg ne . and frzn_vitD ne . then unq_frzn_vitD=frzn_vitD/frzn_wtg;
	if frzn_wtg ne . and frzn_ca ne . then unq_frzn_ca=frzn_ca/frzn_wtg;
	if frzn_wtg ne . and frzn_fe ne . then unq_frzn_fe=frzn_fe/frzn_wtg;
	if frzn_wtg ne . and frzn_na ne . then unq_frzn_na=frzn_na/frzn_wtg;
	if frzn_wtg ne . and frzn_k ne . then unq_frzn_k=frzn_k/frzn_wtg;
	if frzn_wtg ne . and frzn_carb ne . then unq_frzn_carb=frzn_carb/frzn_wtg;
	if frzn_wtg ne . and frzn_mufa ne . then unq_frzn_mufa=frzn_mufa/frzn_wtg;
	if frzn_wtg ne . and frzn_pufa ne . then unq_frzn_pufa=frzn_pufa/frzn_wtg;
	/*Nuts*/
	if nuts_wtg ne . and nuts_ekc ne . then unq_nuts_ekc=nuts_ekc/nuts_wtg;
	if nuts_wtg ne . and nuts_sug ne . then unq_nuts_sug=nuts_sug/nuts_wtg;
	if nuts_wtg ne . and nuts_sat ne . then unq_nuts_sat=nuts_sat/nuts_wtg;
	if nuts_wtg ne . and nuts_pro ne . then unq_nuts_pro=nuts_pro/nuts_wtg;
	if nuts_wtg ne . and nuts_vitD ne . then unq_nuts_vitD=nuts_vitD/nuts_wtg;
	if nuts_wtg ne . and nuts_ca ne . then unq_nuts_ca=nuts_ca/nuts_wtg;
	if nuts_wtg ne . and nuts_fe ne . then unq_nuts_fe=nuts_fe/nuts_wtg;
	if nuts_wtg ne . and nuts_na ne . then unq_nuts_na=nuts_na/nuts_wtg;
	if nuts_wtg ne . and nuts_k ne . then unq_nuts_k=nuts_k/nuts_wtg;
	if nuts_wtg ne . and nuts_carb ne . then unq_nuts_carb=nuts_carb/nuts_wtg;
	if nuts_wtg ne . and nuts_mufa ne . then unq_nuts_mufa=nuts_mufa/nuts_wtg;
	if nuts_wtg ne . and nuts_pufa ne . then unq_nuts_pufa=nuts_pufa/nuts_wtg;
	/*Seeds*/
	if seeds_wtg ne . and seeds_ekc ne . then unq_seeds_ekc=seeds_ekc/seeds_wtg;
	if seeds_wtg ne . and seeds_sug ne . then unq_seeds_sug=seeds_sug/seeds_wtg;
	if seeds_wtg ne . and seeds_sat ne . then unq_seeds_sat=seeds_sat/seeds_wtg;
	if seeds_wtg ne . and seeds_pro ne . then unq_seeds_pro=seeds_pro/seeds_wtg;
	if seeds_wtg ne . and seeds_vitD ne . then unq_seeds_vitD=seeds_vitD/seeds_wtg;
	if seeds_wtg ne . and seeds_ca ne . then unq_seeds_ca=seeds_ca/seeds_wtg;
	if seeds_wtg ne . and seeds_fe ne . then unq_seeds_fe=seeds_fe/seeds_wtg;
	if seeds_wtg ne . and seeds_na ne . then unq_seeds_na=seeds_na/seeds_wtg;
	if seeds_wtg ne . and seeds_k ne . then unq_seeds_k=seeds_k/seeds_wtg;
	if seeds_wtg ne . and seeds_carb ne . then unq_seeds_carb=seeds_carb/seeds_wtg;
	if seeds_wtg ne . and seeds_mufa ne . then unq_seeds_mufa=seeds_mufa/seeds_wtg;
	if seeds_wtg ne . and seeds_pufa ne . then unq_seeds_pufa=seeds_pufa/seeds_wtg;
	/*Legumes*/
	if lgmes_wtg ne . and lgmes_ekc ne . then unq_lgmes_ekc=lgmes_ekc/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_sug ne . then unq_lgmes_sug=lgmes_sug/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_sat ne . then unq_lgmes_sat=lgmes_sat/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_pro ne . then unq_lgmes_pro=lgmes_pro/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_vitD ne . then unq_lgmes_vitD=lgmes_vitD/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_ca ne . then unq_lgmes_ca=lgmes_ca/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_fe ne . then unq_lgmes_fe=lgmes_fe/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_na ne . then unq_lgmes_na=lgmes_na/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_k ne . then unq_lgmes_k=lgmes_k/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_carb ne . then unq_lgmes_carb=lgmes_carb/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_mufa ne . then unq_lgmes_mufa=lgmes_mufa/lgmes_wtg;
	if lgmes_wtg ne . and lgmes_pufa ne . then unq_lgmes_pufa=lgmes_pufa/lgmes_wtg;
	/*Tofu*/
	if tofu_wtg ne . and tofu_ekc ne . then unq_tofu_ekc=tofu_ekc/tofu_wtg;
	if tofu_wtg ne . and tofu_sug ne . then unq_tofu_sug=tofu_sug/tofu_wtg;
	if tofu_wtg ne . and tofu_sat ne . then unq_tofu_sat=tofu_sat/tofu_wtg;
	if tofu_wtg ne . and tofu_pro ne . then unq_tofu_pro=tofu_pro/tofu_wtg;
	if tofu_wtg ne . and tofu_vitD ne . then unq_tofu_vitD=tofu_vitD/tofu_wtg;
	if tofu_wtg ne . and tofu_ca ne . then unq_tofu_ca=tofu_ca/tofu_wtg;
	if tofu_wtg ne . and tofu_fe ne . then unq_tofu_fe=tofu_fe/tofu_wtg;
	if tofu_wtg ne . and tofu_na ne . then unq_tofu_na=tofu_na/tofu_wtg;
	if tofu_wtg ne . and tofu_k ne . then unq_tofu_k=tofu_k/tofu_wtg;
	if tofu_wtg ne . and tofu_carb ne . then unq_tofu_carb=tofu_carb/tofu_wtg;
	if tofu_wtg ne . and tofu_mufa ne . then unq_tofu_mufa=tofu_mufa/tofu_wtg;
	if tofu_wtg ne . and tofu_pufa ne . then unq_tofu_pufa=tofu_pufa/tofu_wtg;
	/*Soy beverage*/
	if soybev_wtg ne . and soybev_ekc ne . then unq_soybev_ekc=soybev_ekc/soybev_wtg;
	if soybev_wtg ne . and soybev_sug ne . then unq_soybev_sug=soybev_sug/soybev_wtg;
	if soybev_wtg ne . and soybev_sat ne . then unq_soybev_sat=soybev_sat/soybev_wtg;
	if soybev_wtg ne . and soybev_pro ne . then unq_soybev_pro=soybev_pro/soybev_wtg;
	if soybev_wtg ne . and soybev_vitD ne . then unq_soybev_vitD=soybev_vitD/soybev_wtg;
	if soybev_wtg ne . and soybev_ca ne . then unq_soybev_ca=soybev_ca/soybev_wtg;
	if soybev_wtg ne . and soybev_fe ne . then unq_soybev_fe=soybev_fe/soybev_wtg;
	if soybev_wtg ne . and soybev_na ne . then unq_soybev_na=soybev_na/soybev_wtg;
	if soybev_wtg ne . and soybev_k ne . then unq_soybev_k=soybev_k/soybev_wtg;
	if soybev_wtg ne . and soybev_carb ne . then unq_soybev_carb=soybev_carb/soybev_wtg;
	if soybev_wtg ne . and soybev_mufa ne . then unq_soybev_mufa=soybev_mufa/soybev_wtg;
	if soybev_wtg ne . and soybev_pufa ne . then unq_soybev_pufa=soybev_pufa/soybev_wtg;

run;
/*17,921 observations (Master Files)*/

/***********************************************************************/

/*Check number of recalls with 0 intake of animal and plant protein foods to know whether
to use one- or two-part NCI model for unbiquitously vs. episodically consumed foods*/
proc sort data=baseline_final; by sampleid; run;
data CHECK;
 	set baseline_final;
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=.;
run;
/*6046 observations*/
data CHECK_sampleid;
	update CHECK(obs=0)CHECK;
	by sampleid;
run;
/*5407 recalls that did not report meat*/

data CHECK_sampleid;
	set CHECK_sampleid;
	if suppid=1;
run;
/*4004 of these obs are 1st recalls*/

data CHECK_dairy;
 	set baseline_final;
	if milk_wtg=. and cheese_wtg=. and yghrt_wtg=. and cream_wtg=. and butr_wtg=. and frzn_wtg=0;
run;
/*0 observations*/

data CHECK_milk;
 	set baseline_final;
	if milk_wtg=.;
run;
/*4017 observations*/

data CHECK_sampleid_milk;
	update CHECK_milk(obs=0)CHECK_milk;
	by sampleid;
run;
/*3671 recalls that did not report meat*/

data CHECK_sampleid_milk;
	set CHECK_sampleid_milk;
	if suppid=1;
run;
/*2683 of these obs are 1st recalls*/

data CHECK_soybev;
 	set baseline_final;
	if soybev_wtg=.;
run;
/*17686 observations*/

data CHECK_sampleid_soybev;
	update CHECK_soybev(obs=0)CHECK_soybev;
	by sampleid;
run;
/*13451 recalls that did not report meat*/

data CHECK_sampleid_soybev;
	set CHECK_sampleid_soybev;
	if suppid=1;
run;
/*9187 of these obs are 1st recalls*/

data CHECK_plants;
 	set baseline_final;
	if nuts_wtg=. and seeds_wtg=. and lgmes_wtg=. and tofu_wtg=.;
run;
/*8877 observations*/

data CHECK_sampleid_plants;
	update CHECK_plants(obs=0)CHECK_plants;
	by sampleid;
run;
/*5407 recalls that did not report meat*/

data CHECK_sampleid_plants;
	set CHECK_sampleid_plants;
	if suppid=1;
run;
*/4004 of these obs are 1st recalls*/

/***********************************************************************/

/***********************************************************************/
/*																	   */
/* STEP 11 - Replacement scenarios									   */
/*																	   */
/***********************************************************************/

/******************************************************************************/
/* RS2 -> Replace 50% of dairy with nuts, seeds, and legumes (milk w/ soy bev)*/
/******************************************************************************/

/************************************/
/* Conduct replacements - g of food */
/************************************/

/*Milk is part of dairy, but soybev is not part of nsl because ratios for nsl were generated using this variable (which did not include soy bev).
  So, a new variable for original amount of nsl consumed (g), including soybev, was created -> nsl_wtg_w_soy. Soybev2 is included in nsl_wtg2.*/
data rs2_50;
data rs2_50; 
	set baseline_final;

/*If the inividual consumed dairy, cut that in half*/
	if dairy_wtg ne . then dairy_wtg2=dairy_wtg/2;
	if milk_wtg ne . then milk_wtg2=milk_wtg/2;
	if cheese_wtg ne . then cheese_wtg2=cheese_wtg/2;
	if yghrt_wtg ne . then yghrt_wtg2=yghrt_wtg/2;
	if cream_wtg ne . then cream_wtg2=cream_wtg/2;
	if butr_wtg ne . then butr_wtg2=butr_wtg/2;
	if frzn_wtg ne . then frzn_wtg2=frzn_wtg/2;

/*If the individual consumed dairy AND nuts OR seeds OR legumes OR tofu*/
	/*Milk*/
	if milk_wtg ne . and soybev_wtg ne . then soybev_wtg2=(milk_wtg/2);
	/*if milk_wtg ne . and nuts_wtg ne . then nuts_milk_wtg2=(milk_wtg*nuts_pcnt/2);		
	if milk_wtg ne . and seeds_wtg ne . then seeds_milk_wtg2=(milk_wtg*seeds_pcnt/2);	
	if milk_wtg ne . and lgmes_wtg ne . then lgmes_milk_wtg2=(milk_wtg*lgmes_pcnt/2);	
	if milk_wtg ne . and tofu_wtg ne . then tofu_milk_wtg2=(milk_wtg*tofu_pcnt/2);	
	/*Cheese*/	
	if cheese_wtg ne . and nuts_wtg ne . then nuts_cheese_wtg2=(cheese_wtg*nuts_pcnt/2);	
	if cheese_wtg ne . and seeds_wtg ne . then seeds_cheese_wtg2=(cheese_wtg*seeds_pcnt/2);	
	if cheese_wtg ne . and lgmes_wtg ne . then lgmes_cheese_wtg2=(cheese_wtg*lgmes_pcnt/2);	
	if cheese_wtg ne . and tofu_wtg ne . then tofu_cheese_wtg2=(cheese_wtg*tofu_pcnt/2);	
	/*Yoghurt*/
	if yghrt_wtg ne . and nuts_wtg ne . then nuts_yghrt_wtg2=(yghrt_wtg*nuts_pcnt/2);	
	if yghrt_wtg ne . and seeds_wtg ne . then seeds_yghrt_wtg2=(yghrt_wtg*seeds_pcnt/2);	
	if yghrt_wtg ne . and lgmes_wtg ne . then lgmes_yghrt_wtg2=(yghrt_wtg*lgmes_pcnt/2);	
	if yghrt_wtg ne . and tofu_wtg ne . then tofu_yghrt_wtg2=(yghrt_wtg*tofu_pcnt/2);	
	/*Cream*/
	if cream_wtg ne . and nuts_wtg ne . then nuts_cream_wtg2=(cream_wtg*nuts_pcnt/2);	
	if cream_wtg ne . and seeds_wtg ne . then seeds_cream_wtg2=(cream_wtg*seeds_pcnt/2);	
	if cream_wtg ne . and lgmes_wtg ne . then lgmes_cream_wtg2=(cream_wtg*lgmes_pcnt/2);	
	if cream_wtg ne . and tofu_wtg ne . then tofu_cream_wtg2=(cream_wtg*tofu_pcnt/2);	
	/*Butter*/
	if butr_wtg ne . and nuts_wtg ne . then nuts_butr_wtg2=(butr_wtg*nuts_pcnt/2);	
	if butr_wtg ne . and seeds_wtg ne . then seeds_butr_wtg2=(butr_wtg*seeds_pcnt/2);	
	if butr_wtg ne . and lgmes_wtg ne . then lgmes_butr_wtg2=(butr_wtg*lgmes_pcnt/2);	
	if butr_wtg ne . and tofu_wtg ne . then tofu_butr_wtg2=(butr_wtg*tofu_pcnt/2);	
	/*Frozen dairy*/
	if frzn_wtg ne . and nuts_wtg ne . then nuts_frzn_wtg2=(frzn_wtg*nuts_pcnt/2);	
	if frzn_wtg ne . and seeds_wtg ne . then seeds_frzn_wtg2=(frzn_wtg*seeds_pcnt/2);	
	if frzn_wtg ne . and lgmes_wtg ne . then lgmes_frzn_wtg2=(frzn_wtg*lgmes_pcnt/2);	
	if frzn_wtg ne . and tofu_wtg ne . then tofu_frzn_wtg2=(frzn_wtg*tofu_pcnt/2);	

/*If the individual consumed nuts OR seeds OR legumes OR tofu BUT NOT dairy*/
	if dairy_wtg=. and nuts_wtg ne . then nuts_wtg2=nuts_wtg;
	if dairy_wtg=. and seeds_wtg ne . then seeds_wtg2=seeds_wtg;
	if dairy_wtg=. and lgmes_wtg ne . then lgmes_wtg2=lgmes_wtg;
	if dairy_wtg=. and tofu_wtg ne . then tofu_wtg2=tofu_wtg;
	if milk_wtg=. and soybev_wtg ne . then soybev_wtg2=soybev_wtg;

/*If the individual did not originally consume dairy, set to 0*/
	if dairy_wtg=. then dairy_wtg=0;
	if milk_wtg=. then milk_wtg=0;
	if cheese_wtg=. then cheese_wtg=0;
	if yghrt_wtg=. then yghrt_wtg=0;
	if cream_wtg=. then cream_wtg=0;
	if butr_wtg=. then butr_wtg=0;
	if frzn_wtg=. then frzn_wtg=0;

/*If the individual did not originally consume nsl, set to 0*/
	if nsl_wtg=. then nsl_wtg=0;	
	if nuts_wtg=. then nuts_wtg=0;	
	if seeds_wtg=. then seeds_wtg=0;	
	if lgmes_wtg=. then lgmes_wtg=0;	
	if tofu_wtg=. then tofu_wtg=0;
	if soybev_wtg=. then soybev_wtg=0;	
	
/*Set missing values post-replacement to 0*/
	if milk_wtg2=. then milk_wtg2=0;
	if cheese_wtg2=. then cheese_wtg2=0;	
	if yghrt_wtg2=. then yghrt_wtg2=0;	
	if cream_wtg2=. then cream_wtg2=0;
	if butr_wtg2=. then butr_wtg2=0;
	if frzn_wtg2=. then frzn_wtg2=0;
			
	if nuts_wtg2=. then nuts_wtg2=0;	
	if seeds_wtg2=. then seeds_wtg2=0;	
	if lgmes_wtg2=. then lgmes_wtg2=0;	
	if tofu_wtg2=. then tofu_wtg2=0;
	if soybev_wtg2=. then soybev_wtg2=0;

	/*if nuts_milk_wtg2=. then nuts_milk_wtg2=0;
	if seeds_milk_wtg2=. then seeds_milk_wtg2=0;
	if lgmes_milk_wtg2=. then lgmes_milk_wtg2=0;
	if tofu_milk_wtg2=. then tofu_milk_wtg2=0;*/

	if nuts_cheese_wtg2=. then nuts_cheese_wtg2=0;
	if seeds_cheese_wtg2=. then seeds_cheese_wtg2=0;
	if lgmes_cheese_wtg2=. then lgmes_cheese_wtg2=0;
	if tofu_cheese_wtg2=. then tofu_cheese_wtg2=0;
	
	if nuts_yghrt_wtg2=. then nuts_yghrt_wtg2=0;
	if seeds_yghrt_wtg2=. then seeds_yghrt_wtg2=0;
	if lgmes_yghrt_wtg2=. then lgmes_yghrt_wtg2=0;
	if tofu_yghrt_wtg2=. then tofu_yghrt_wtg2=0;

	if nuts_cream_wtg2=. then nuts_cream_wtg2=0;
	if seeds_cream_wtg2=. then seeds_cream_wtg2=0;
	if lgmes_cream_wtg2=. then lgmes_cream_wtg2=0;
	if tofu_cream_wtg2=. then tofu_cream_wtg2=0;

	if nuts_butr_wtg2=. then nuts_butr_wtg2=0;
	if seeds_butr_wtg2=. then seeds_butr_wtg2=0;
	if lgmes_butr_wtg2=. then lgmes_butr_wtg2=0;
	if tofu_butr_wtg2=. then tofu_butr_wtg2=0;

	if nuts_frzn_wtg2=. then nuts_frzn_wtg2=0;
	if seeds_frzn_wtg2=. then seeds_frzn_wtg2=0;
	if lgmes_frzn_wtg2=. then lgmes_frzn_wtg2=0;
	if tofu_frzn_wtg2=. then tofu_frzn_wtg2=0;

/*Later we have to account for other foods, set to 0 here*/
	if meat_wtg=. then meat_wtg=0;											
	if beef_wtg=. then beef_wtg=0;
	if lamb_wtg=. then lamb_wtg=0;
	if pork_wtg=. then pork_wtg=0;
	if lnchn_wtg=. then lnchn_wtg=0;
	if other_wtg=. then other_wtg=0;

/*If the individual consumed dairy BUT NOT nuts OR seeds OR legumes OR tofu, use ratios for overall sample*/
	if milk_wtg ne 0 and soybev_wtg=0 then soybev_wtg2=milk_wtg/2;
	if dairy_wtg ne 0 and nsl_wtg=0 then nuts_wtg2=/*(milk_wtg*0.301588528/2)+*/(cheese_wtg*0.301588528/2)+(yghrt_wtg*0.301588528/2)+(cream_wtg*0.301588528/2)+(butr_wtg*0.301588528/2)+(frzn_wtg*0.301588528/2);
	if dairy_wtg ne 0 and nsl_wtg=0 then seeds_wtg2=/*(milk_wtg*0.03540598/2)+*/(cheese_wtg*0.03540598/2)+(yghrt_wtg*0.03540598/2)+(cream_wtg*0.03540598/2)+(butr_wtg*0.03540598/2)+(frzn_wtg*0.03540598/2); 
	if dairy_wtg ne 0 and nsl_wtg=0 then lgmes_wtg2=/*(milk_wtg*0.595355613/2)+*/(cheese_wtg*0.595355613/2)+(yghrt_wtg*0.595355613/2)+(cream_wtg*0.595355613/2)+(butr_wtg*0.595355613/2)+(frzn_wtg*0.595355613/2); 
	if dairy_wtg ne 0 and nsl_wtg=0 then tofu_wtg2=/*(milk_wtg*0.067649879/2)+*/(cheese_wtg*0.067649879/2)+(yghrt_wtg*0.067649879/2)+(cream_wtg*0.067649879/2)+(butr_wtg*0.067649879/2)+(frzn_wtg*0.067649879/2); 

/*Create one variable for nuts, seeds, and legumes weight post-replacement, accounting for g of nsl at baseline*/
	if milk_wtg ne 0 and soybev_wtg ne 0 then soybev_wtg2=soybev_wtg+soybev_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then nuts_wtg2=nuts_wtg+/*nuts_milk_wtg2+*/nuts_cheese_wtg2+nuts_yghrt_wtg2+nuts_cream_wtg2+nuts_butr_wtg2+nuts_frzn_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then seeds_wtg2=seeds_wtg+/*seeds_milk_wtg2+*/seeds_cheese_wtg2+seeds_yghrt_wtg2+seeds_cream_wtg2+seeds_butr_wtg2+seeds_frzn_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then lgmes_wtg2=lgmes_wtg+/*lgmes_milk_wtg2+*/lgmes_cheese_wtg2+lgmes_yghrt_wtg2+lgmes_cream_wtg2+lgmes_butr_wtg2+lgmes_frzn_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then tofu_wtg2=tofu_wtg+/*tofu_milk_wtg2+*/tofu_cheese_wtg2+tofu_yghrt_wtg2+tofu_cream_wtg2+tofu_butr_wtg2+tofu_frzn_wtg2;

/*Create variables for total dairy and total nsl g post-replacement*/
/*Note that milk_wtg2+cheese_wtg2+yghrt_wtg2+cream_wtg2+butr_wtg2+frzn_wtg2 (i.e., dairy_wtg2) should = nsl_wtg2 - nsl_wtg*/		
	dairy_wtg2=milk_wtg2+cheese_wtg2+yghrt_wtg2+cream_wtg2+butr_wtg2+frzn_wtg2;
	nsl_wtg2=nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg2;		

	diet_wtg=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+soybev_wtg;
	diet_wtg2=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+milk_wtg2+cheese_wtg2+yghrt_wtg2+cream_wtg2+butr_wtg2+frzn_wtg2+other_wtg+nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg2;

/*This is a test to see if we are accounting for ALL foods (compare to fsddwtg)*/
	fsddwtg_chk=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+soybev_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg;

/*Create variable for original g of nuts, seeds, and legumes consumed including soybev*/
	nsl_wtg_w_soy=nsl_wtg+soybev_wtg;

/*To ensure math checks out by hand, just keep relevant variables*/
/*keep sampleid fsddwtg fsddwtg_chk milk_wtg cheese_wtg yghrt_wtg cream_wtg butr_wtg frzn_wtg nsl_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg soybev_wtg	 
	 milk_wtg2 cheese_wtg2 yghrt_wtg2 cream_wtg2 butr_wtg2 frzn_wtg2 nsl_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2 soybev_wtg2
	 nuts_cheese_wtg2 nuts_yghrt_wtg2 nuts_cream_wtg2 nuts_butr_wtg2 nuts_frzn_wtg2
	 seeds_cheese_wtg2 seeds_yghrt_wtg2 seeds_cream_wtg2 seeds_butr_wtg2 seeds_frzn_wtg2
	 lgmes_cheese_wtg2 lgmes_yghrt_wtg2 lgmes_cream_wtg2 lgmes_butr_wtg2 lgmes_frzn_wtg2
	 tofu_cheese_wtg2 tofu_yghrt_wtg2 tofu_cream_wtg2 tofu_butr_wtg2 tofu_frzn_wtg2
	 nuts_pcnt seeds_pcnt lgmes_pcnt tofu_pcnt
	 dairy_wtg nsl_wtg dairy_wtg2 nsl_wtg2
	 nsl_wtg_w_soy;

	 /*nuts_milk_wtg2 seeds_milk_wtg2 lgmes_milk_wtg2 tofu_milk_wtg2*/ 

run;
/*17,921 observations (Master Files)*/
		
/*Preliminary results (g)*/
proc means n nmiss mean min max data=rs2_50;
	var milk_wtg milk_wtg2 cheese_wtg cheese_wtg2 yghrt_wtg yghrt_wtg2 cream_wtg cream_wtg2 butr_wtg butr_wtg2 frzn_wtg frzn_wtg2
	nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2 soybev_wtg soybev_wtg2
	diet_wtg diet_wtg2;
run;

/*Check how many respondents did not originally consume PPF*/
data no_nsl; set rs2_50; if nsl_wtg=0; if suppid=2 then delete; run;

/************************************/
/* Conduct replacements - GHGE 		*/
/************************************/
data rs2_50_ghge;
	set rs2_50;

/*If the respondent consumed dairy, simply divide ghge of g of meat originally consumed in half*/
	if milk_wtg ne 0 and milk_co2eq ne . then milk_co2eq2=milk_co2eq/2;
	if cheese_wtg ne 0 and cheese_co2eq ne . then cheese_co2eq2=cheese_co2eq/2;
	if yghrt_wtg ne 0 and yghrt_co2eq ne . then yghrt_co2eq2=yghrt_co2eq/2;
	if cream_wtg ne 0 and cream_co2eq ne . then cream_co2eq2=cream_co2eq/2;
	if butr_wtg ne 0 and butr_co2eq ne . then butr_co2eq2=butr_co2eq/2;
	if frzn_wtg ne 0 and frzn_co2eq ne . then frzn_co2eq2=frzn_co2eq/2;

/*For respondents that originally consumed nsl, multiply unique ghge based on their nsl consumption profile by g of nsl replaced; then, add this to original ghge
for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl)*/
	if nuts_wtg ne 0 and unq_nuts_co2eq ne . then nuts_co2eq2=nuts_co2eq+(unq_nuts_co2eq*((nuts_wtg2-nuts_wtg)/1000));
	if seeds_wtg ne 0 and unq_seeds_co2eq ne . then seeds_co2eq2=seeds_co2eq+(unq_seeds_co2eq*((seeds_wtg2-seeds_wtg)/1000));
	if lgmes_wtg ne 0 and unq_lgmes_co2eq ne . then lgmes_co2eq2=lgmes_co2eq+(unq_lgmes_co2eq*((lgmes_wtg2-lgmes_wtg)/1000));
	if tofu_wtg ne 0 and unq_tofu_co2eq ne . then tofu_co2eq2=tofu_co2eq+(unq_tofu_co2eq*((tofu_wtg2-tofu_wtg)/1000));
	if soybev_wtg ne 0 and unq_soybev_co2eq ne . then soybev_co2eq2=soybev_co2eq+(unq_soybev_co2eq*((soybev_wtg2-soybev_wtg)/1000));											

/*For respodents that did not originally consume dairy, ghge=0 after replacement*/
	if milk_wtg=0 then milk_co2eq2=0;
	if cheese_wtg=0 then cheese_co2eq2=0;
	if yghrt_wtg=0 then yghrt_co2eq2=0;
	if cream_wtg=0 then cream_co2eq2=0;
	if butr_wtg=0 then butr_co2eq2=0;
	if frzn_wtg=0 then frzn_co2eq2=0;

/*For respondents that did not originally consume nsl, use a weighted average ghge*/
/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_co2eq2=2.303442774*(nuts_wtg2/1000);
	if seeds_wtg=0 then seeds_co2eq2=0.883544384*(seeds_wtg2/1000);
	if lgmes_wtg=0 then lgmes_co2eq2=1.388278602*(lgmes_wtg2/1000);
	if tofu_wtg=0 then tofu_co2eq2=2.3616*(tofu_wtg2/1000);
	if soybev_wtg=0 then soybev_co2eq2=0.379125733*(tofu_wtg2/1000);

/*Setting missing values to 0 here*/
	if milk_co2eq=. then milk_co2eq=0;
	if cheese_co2eq=. then cheese_co2eq=0;
	if yghrt_co2eq=. then yghrt_co2eq=0;
	if cream_co2eq=. then cream_co2eq=0;
	if butr_co2eq=. then butr_co2eq=0;
	if frzn_co2eq=. then frzn_co2eq=0;
	if nuts_co2eq=. then nuts_co2eq=0;
	if seeds_co2eq=. then seeds_co2eq=0;
	if lgmes_co2eq=. then lgmes_co2eq=0;
	if tofu_co2eq=. then tofu_co2eq=0;
	if soybev_co2eq=. then soybev_co2eq=0;
		
	if milk_co2eq2=. then milk_co2eq2=0;
	if cheese_co2eq2=. then cheese_co2eq2=0;
	if yghrt_co2eq2=. then yghrt_co2eq2=0;
	if cream_co2eq2=. then cream_co2eq2=0;
	if butr_co2eq2=. then butr_co2eq2=0;
	if frzn_co2eq2=. then frzn_co2eq2=0;
	if nuts_co2eq2=. then nuts_co2eq2=0;
	if seeds_co2eq2=. then seeds_co2eq2=0;
	if lgmes_co2eq2=. then lgmes_co2eq2=0;
	if soybev_co2eq2=. then soybev_co2eq2=0;

	/*Setting missing values to 0 for other foods here*/
	if beef_co2eq=. then beef_co2eq=0;
	if lamb_co2eq=. then lamb_co2eq=0;
	if pork_co2eq=. then pork_co2eq=0;
	if lnchn_co2eq=. then lnchn_co2eq=0;
	if other_co2eq=. then other_co2eq=0;

	/*Create variables for total dairy and total nsl ghge pre- and post-replacement*/
	tot_dairy_co2eq=milk_co2eq+cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq;
	tot_dairy_co2eq2=milk_co2eq2+cheese_co2eq2+yghrt_co2eq2+cream_co2eq2+butr_co2eq2+frzn_co2eq2;
	tot_nsl_co2eq=nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+soybev_co2eq;
	tot_nsl_co2eq2=nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+soybev_co2eq2;
	tot_meat_co2eq=beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq;

	/*Create variables for total ghge pre- and post-replacement*/
	tot_co2eq=milk_co2eq+cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+other_co2eq+nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+soybev_co2eq+
	beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq;
	tot_co2eq2=milk_co2eq2+cheese_co2eq2+yghrt_co2eq2+cream_co2eq2+butr_co2eq2+frzn_co2eq2+nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+soybev_co2eq2+
	beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq+other_co2eq;

	/*Create variables for CO2-eq/1000 kcal*/
	if fsddekc ne 0 then tot_co2eq_kcal=(tot_co2eq/fsddekc)*1000;
	if fsddekc ne 0 then tot_co2eq2_kcal=(tot_co2eq2/fsddekc)*1000;

	/*keep sampleid fsddwtg fsddwtg_chk milk_wtg cheese_wtg yghrt_wtg cream_wtg butr_wtg frzn_wtg nsl_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg soybev_wtg	 
	 milk_wtg2 cheese_wtg2 yghrt_wtg2 cream_wtg2 butr_wtg2 frzn_wtg2 nsl_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2 soybev_wtg2
	 nuts_cheese_wtg2 nuts_yghrt_wtg2 nuts_cream_wtg2 nuts_butr_wtg2 nuts_frzn_wtg2
	 seeds_cheese_wtg2 seeds_yghrt_wtg2 seeds_cream_wtg2 seeds_butr_wtg2 seeds_frzn_wtg2
	 lgmes_cheese_wtg2 lgmes_yghrt_wtg2 lgmes_cream_wtg2 lgmes_butr_wtg2 lgmes_frzn_wtg2
	 tofu_cheese_wtg2 tofu_yghrt_wtg2 tofu_cream_wtg2 tofu_butr_wtg2 tofu_frzn_wtg2
	 nuts_pcnt seeds_pcnt lgmes_pcnt tofu_pcnt
	 dairy_wtg nsl_wtg dairy_wtg2 nsl_wtg2
	 nsl_wtg_w_soy
	milk_co2eq cheese_co2eq yghrt_co2eq cream_co2eq butr_co2eq frzn_co2eq nuts_co2eq seeds_co2eq lgmes_co2eq tofu_co2eq soybev_co2eq
	milk_co2eq2 cheese_co2eq2 yghrt_co2eq2 cream_co2eq2 butr_co2eq2 frzn_co2eq2 nuts_co2eq2 seeds_co2eq2 lgmes_co2eq2 tofu_co2eq2 soybev_co2eq2
	unq_nuts_co2eq unq_seeds_co2eq unq_lgmes_co2eq unq_tofu_co2eq
	tot_dairy_co2eq tot_dairy_co2eq2 tot_nsl_co2eq tot_nsl_co2eq2 tot_meat_co2eq;*/

run;
/*17,921 observations (Master Files)*/

/*Preliminary results (ghge)*/
proc means n nmiss mean min max data=rs2_50_ghge;	
	var milk_co2eq milk_co2eq2 cheese_co2eq cheese_co2eq2 yghrt_co2eq yghrt_co2eq2 cream_co2eq cream_co2eq2 butr_co2eq butr_co2eq2 frzn_co2eq frzn_co2eq2
		nuts_co2eq nuts_co2eq2 seeds_co2eq seeds_co2eq2 lgmes_co2eq lgmes_co2eq2 tofu_co2eq tofu_co2eq2
		tot_dairy_co2eq tot_dairy_co2eq2 tot_nsl_co2eq tot_nsl_co2eq2 tot_co2eq tot_co2eq2;
run;	

/************************************/
/* Conduct replacements - Nutrients */
/************************************/

/*Note that the same method for calculating ghge is used here for nutrients*/

data rs2_50_nutr;
	set rs2_50_ghge;

/*If the respondent consumed dairy, simply divide intake of nutrients originally consumed from dairy in half*/
/*Alternatively, multiply unique ekc based on their meat consumption profile by g of meat after replacement*/
/*Note that these come out to the same thing*/
	/*Energy*/					
		if milk_wtg ne 0 and milk_ekc ne . then milk_ekc2=milk_ekc/2;	
		if cheese_wtg ne 0 and cheese_ekc ne . then cheese_ekc2=cheese_ekc/2;	
		if yghrt_wtg ne 0 and yghrt_ekc ne . then yghrt_ekc2=yghrt_ekc/2;		
		if cream_wtg ne 0 and cream_ekc ne . then cream_ekc2=cream_ekc/2;
		if butr_wtg ne 0 and butr_ekc ne . then butr_ekc2=butr_ekc/2;
		if frzn_wtg ne 0 and frzn_ekc ne . then frzn_ekc2=frzn_ekc/2;	
		/*if milk_wtg ne 0 and unq_milk_ekc ne . then milk_ekc2_v2=unq_milk_ekc*milk_wtg2;				
		if cheese_wtg ne 0 and unq_cheese_ekc ne . then cheese_ekc2_v2=unq_cheese_ekc*cheese_wtg2;				
		if yghrt_wtg ne 0 and unq_yghrt_ekc ne . then yghrt_ekc2_v2=unq_yghrt_ekc*yghrt_wtg2;				
		if cream_wtg ne 0 and unq_cream_ekc ne . then cream_ekc2_v2=unq_cream_ekc*cream_wtg2;				
		if butr_wtg ne 0 and unq_butr_ekc ne . then butr_ekc2_v2=unq_butr_ekc*butr_wtg2;				
		if frzn_wtg ne 0 and unq_frzn_ekc ne . then frzn_ekc2_v2=unq_frzn_ekc*frzn_wtg2;*/
	/*Sugar*/
		if milk_wtg ne 0 and milk_sug ne . then milk_sug2=milk_sug/2;		
		if cheese_wtg ne 0 and cheese_sug ne . then cheese_sug2=cheese_sug/2;		
		if yghrt_wtg ne 0 and yghrt_sug ne . then yghrt_sug2=yghrt_sug/2;		
		if cream_wtg ne 0 and cream_sug ne . then cream_sug2=cream_sug/2;		
		if butr_wtg ne 0 and butr_sug ne . then butr_sug2=butr_sug/2;		
		if frzn_wtg ne 0 and frzn_sug ne . then frzn_sug2=frzn_sug/2;		
	/*Saturated fat*/
		if milk_wtg ne 0 and milk_sat ne . then milk_sat2=milk_sat/2;		
		if cheese_wtg ne 0 and cheese_sat ne . then cheese_sat2=cheese_sat/2;		
		if yghrt_wtg ne 0 and yghrt_sat ne . then yghrt_sat2=yghrt_sat/2;		
		if cream_wtg ne 0 and cream_sat ne . then cream_sat2=cream_sat/2;		
		if butr_wtg ne 0 and butr_sat ne . then butr_sat2=butr_sat/2;		
		if frzn_wtg ne 0 and frzn_sat ne . then frzn_sat2=frzn_sat/2;		
	/*Protein*/			
		if milk_wtg ne 0 and milk_pro ne . then milk_pro2=milk_pro/2;		
		if cheese_wtg ne 0 and cheese_pro ne . then cheese_pro2=cheese_pro/2;		
		if yghrt_wtg ne 0 and yghrt_pro ne . then yghrt_pro2=yghrt_pro/2;		
		if cream_wtg ne 0 and cream_pro ne . then cream_pro2=cream_pro/2;		
		if butr_wtg ne 0 and butr_pro ne . then butr_pro2=butr_pro/2;		
		if frzn_wtg ne 0 and frzn_pro ne . then frzn_pro2=frzn_pro/2;			
	/*Vitamin D*/			
		if milk_wtg ne 0 and milk_vitD ne . then milk_vitD2=milk_vitD/2;		
		if cheese_wtg ne 0 and cheese_vitD ne . then cheese_vitD2=cheese_vitD/2;		
		if yghrt_wtg ne 0 and yghrt_vitD ne . then yghrt_vitD2=yghrt_vitD/2;		
		if cream_wtg ne 0 and cream_vitD ne . then cream_vitD2=cream_vitD/2;		
		if butr_wtg ne 0 and butr_vitD ne . then butr_vitD2=butr_vitD/2;		
		if frzn_wtg ne 0 and frzn_vitD ne . then frzn_vitD2=frzn_vitD/2;		
	/*Calcium*/	
		if milk_wtg ne 0 and milk_ca ne . then milk_ca2=milk_ca/2;		
		if cheese_wtg ne 0 and cheese_ca ne . then cheese_ca2=cheese_ca/2;		
		if yghrt_wtg ne 0 and yghrt_ca ne . then yghrt_ca2=yghrt_ca/2;		
		if cream_wtg ne 0 and cream_ca ne . then cream_ca2=cream_ca/2;		
		if butr_wtg ne 0 and butr_ca ne . then butr_ca2=butr_ca/2;		
		if frzn_wtg ne 0 and frzn_ca ne . then frzn_ca2=frzn_ca/2;			
	/*Iron*/				
		if milk_wtg ne 0 and milk_fe ne . then milk_fe2=milk_fe/2;		
		if cheese_wtg ne 0 and cheese_fe ne . then cheese_fe2=cheese_fe/2;		
		if yghrt_wtg ne 0 and yghrt_fe ne . then yghrt_fe2=yghrt_fe/2;		
		if cream_wtg ne 0 and cream_fe ne . then cream_fe2=cream_fe/2;		
		if butr_wtg ne 0 and butr_fe ne . then butr_fe2=butr_fe/2;		
		if frzn_wtg ne 0 and frzn_fe ne . then frzn_fe2=frzn_fe/2;		
	/*Sodium*/					
		if milk_wtg ne 0 and milk_na ne . then milk_na2=milk_na/2;		
		if cheese_wtg ne 0 and cheese_na ne . then cheese_na2=cheese_na/2;		
		if yghrt_wtg ne 0 and yghrt_na ne . then yghrt_na2=yghrt_na/2;		
		if cream_wtg ne 0 and cream_na ne . then cream_na2=cream_na/2;		
		if butr_wtg ne 0 and butr_na ne . then butr_na2=butr_na/2;		
		if frzn_wtg ne 0 and frzn_na ne . then frzn_na2=frzn_na/2;
	/*Potassium*/		
		if milk_wtg ne 0 and milk_k ne . then milk_k2=milk_k/2;		
		if cheese_wtg ne 0 and cheese_k ne . then cheese_k2=cheese_k/2;		
		if yghrt_wtg ne 0 and yghrt_k ne . then yghrt_k2=yghrt_k/2;		
		if cream_wtg ne 0 and cream_k ne . then cream_k2=cream_k/2;		
		if butr_wtg ne 0 and butr_k ne . then butr_k2=butr_k/2;		
		if frzn_wtg ne 0 and frzn_k ne . then frzn_k2=frzn_k/2;	
	/*Carbs*/
		if milk_wtg ne 0 and milk_carb ne . then milk_carb2=milk_carb/2;		
		if cheese_wtg ne 0 and cheese_carb ne . then cheese_carb2=cheese_carb/2;		
		if yghrt_wtg ne 0 and yghrt_carb ne . then yghrt_carb2=yghrt_carb/2;		
		if cream_wtg ne 0 and cream_carb ne . then cream_carb2=cream_carb/2;		
		if butr_wtg ne 0 and butr_carb ne . then butr_carb2=butr_carb/2;		
		if frzn_wtg ne 0 and frzn_carb ne . then frzn_carb2=frzn_carb/2;	
	/*MUFAs*/		
		if milk_wtg ne 0 and milk_mufa ne . then milk_mufa2=milk_mufa/2;		
		if cheese_wtg ne 0 and cheese_mufa ne . then cheese_mufa2=cheese_mufa/2;		
		if yghrt_wtg ne 0 and yghrt_mufa ne . then yghrt_mufa2=yghrt_mufa/2;		
		if cream_wtg ne 0 and cream_mufa ne . then cream_mufa2=cream_mufa/2;		
		if butr_wtg ne 0 and butr_mufa ne . then butr_mufa2=butr_mufa/2;		
		if frzn_wtg ne 0 and frzn_mufa ne . then frzn_mufa2=frzn_mufa/2;
	/*PUFAs*/			
		if milk_wtg ne 0 and milk_pufa ne . then milk_pufa2=milk_pufa/2;		
		if cheese_wtg ne 0 and cheese_pufa ne . then cheese_pufa2=cheese_pufa/2;		
		if yghrt_wtg ne 0 and yghrt_pufa ne . then yghrt_pufa2=yghrt_pufa/2;		
		if cream_wtg ne 0 and cream_pufa ne . then cream_pufa2=cream_pufa/2;		
		if butr_wtg ne 0 and butr_pufa ne . then butr_pufa2=butr_pufa/2;		
		if frzn_wtg ne 0 and frzn_pufa ne . then frzn_pufa2=frzn_pufa/2;			

/*For respondents that originally consumed nsl, multiply unique ekc based on their nsl consumption profile by g of nsl replaced; then, add this to original ekc
for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl) (these come out to the same thing)*/
	/*Energy*/
		if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2=nuts_ekc+(unq_nuts_ekc*(nuts_wtg2-nuts_wtg)); 
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2=seeds_ekc+(unq_seeds_ekc*(seeds_wtg2-seeds_wtg));
		if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2=lgmes_ekc+(unq_lgmes_ekc*(lgmes_wtg2-lgmes_wtg));
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2=tofu_ekc+(unq_tofu_ekc*(tofu_wtg2-tofu_wtg));
		if soybev_wtg ne 0 and unq_soybev_ekc ne . then soybev_ekc2=soybev_ekc+(unq_soybev_ekc*(soybev_wtg2-soybev_wtg));
		/*if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2_v2=unq_nuts_ekc*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2_v2=unq_seeds_ekc*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2_v2=unq_lgmes_ekc*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2_v2=unq_tofu_ekc*tofu_wtg2;*/
	/*Sugar*/
		if nuts_wtg ne 0 and unq_nuts_sug ne . then nuts_sug2=unq_nuts_sug*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sug ne . then seeds_sug2=unq_seeds_sug*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sug ne . then lgmes_sug2=unq_lgmes_sug*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sug ne . then tofu_sug2=unq_tofu_sug*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_sug ne . then soybev_sug2=unq_soybev_sug*soybev_wtg2;	
		/*if nuts_wtg ne 0 and unq_nuts_sug ne . then nuts_sug2_v2=unq_nuts_sug*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sug ne . then seeds_sug2_v2=unq_seeds_sug*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sug ne . then lgmes_sug2_v2=unq_lgmes_sug*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sug ne . then tofu_sug2_v2=unq_tofu_sug*tofu_wtg2;*/
	/*Saturated fat*/
		if nuts_wtg ne 0 and unq_nuts_sat ne . then nuts_sat2=unq_nuts_sat*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sat ne . then seeds_sat2=unq_seeds_sat*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sat ne . then lgmes_sat2=unq_lgmes_sat*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sat ne . then tofu_sat2=unq_tofu_sat*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_sat ne . then soybev_sat2=unq_soybev_sat*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_sat ne . then nuts_sat2_v2=unq_nuts_sat*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sat ne . then seeds_sat2_v2=unq_seeds_sat*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sat ne . then lgmes_sat2_v2=unq_lgmes_sat*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sat ne . then tofu_sat2_v2=unq_tofu_sat*tofu_wtg2;*/	
	/*Protein*/
		if nuts_wtg ne 0 and unq_nuts_pro ne . then nuts_pro2=unq_nuts_pro*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pro ne . then seeds_pro2=unq_seeds_pro*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pro ne . then lgmes_pro2=unq_lgmes_pro*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pro ne . then tofu_pro2=unq_tofu_pro*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_pro ne . then soybev_pro2=unq_soybev_pro*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_pro ne . then nuts_pro2_v2=unq_nuts_pro*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pro ne . then seeds_pro2_v2=unq_seeds_pro*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pro ne . then lgmes_pro2_v2=unq_lgmes_pro*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pro ne . then tofu_pro2_v2=unq_tofu_pro*tofu_wtg2;*/
	/*Vitamin D*/
		if nuts_wtg ne 0 and unq_nuts_vitD ne . then nuts_vitD2=unq_nuts_vitD*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_vitD ne . then seeds_vitD2=unq_seeds_vitD*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_vitD ne . then lgmes_vitD2=unq_lgmes_vitD*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_vitD ne . then tofu_vitD2=unq_tofu_vitD*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_vitD ne . then soybev_vitD2=unq_soybev_vitD*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_vitD ne . then nuts_vitD2_v2=unq_nuts_vitD*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_vitD ne . then seeds_vitD2_v2=unq_seeds_vitD*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_vitD ne . then lgmes_vitD2_v2=unq_lgmes_vitD*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_vitD ne . then tofu_vitD2_v2=unq_tofu_vitD*tofu_wtg2;*/
	/*Calcium*/
		if nuts_wtg ne 0 and unq_nuts_ca ne . then nuts_ca2=unq_nuts_ca*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ca ne . then seeds_ca2=unq_seeds_ca*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ca ne . then lgmes_ca2=unq_lgmes_ca*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ca ne . then tofu_ca2=unq_tofu_ca*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_ca ne . then soybev_ca2=unq_soybev_ca*soybev_wtg2;								
		/*if nuts_wtg ne 0 and unq_nuts_ca ne . then nuts_ca2_v2=unq_nuts_ca*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ca ne . then seeds_ca2_v2=unq_seeds_ca*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ca ne . then lgmes_ca2_v2=unq_lgmes_ca*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ca ne . then tofu_ca2_v2=unq_tofu_ca*tofu_wtg2;*/	
	/*Iron*/
		if nuts_wtg ne 0 and unq_nuts_fe ne . then nuts_fe2=unq_nuts_fe*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_fe ne . then seeds_fe2=unq_seeds_fe*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_fe ne . then lgmes_fe2=unq_lgmes_fe*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_fe ne . then tofu_fe2=unq_tofu_fe*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_fe ne . then soybev_fe2=unq_soybev_fe*soybev_wtg2;	
		/*if nuts_wtg ne 0 and unq_nuts_fe ne . then nuts_fe2_v2=unq_nuts_fe*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_fe ne . then seeds_fe2_v2=unq_seeds_fe*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_fe ne . then lgmes_fe2_v2=unq_lgmes_fe*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_fe ne . then tofu_fe2_v2=unq_tofu_fe*tofu_wtg2;*/
	/*Sodium*/
		if nuts_wtg ne 0 and unq_nuts_na ne . then nuts_na2=unq_nuts_na*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_na ne . then seeds_na2=unq_seeds_na*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_na ne . then lgmes_na2=unq_lgmes_na*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_na ne . then tofu_na2=unq_tofu_na*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_na ne . then soybev_na2=unq_soybev_na*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_na ne . then nuts_na2_v2=unq_nuts_na*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_na ne . then seeds_na2_v2=unq_seeds_na*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_na ne . then lgmes_na2_v2=unq_lgmes_na*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_na ne . then tofu_na2_v2=unq_tofu_na*tofu_wtg2;*/	
	/*Potassium*/
		if nuts_wtg ne 0 and unq_nuts_k ne . then nuts_k2=unq_nuts_k*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_k ne . then seeds_k2=unq_seeds_k*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_k ne . then lgmes_k2=unq_lgmes_k*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_k ne . then tofu_k2=unq_tofu_k*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_k ne . then soybev_k2=unq_soybev_k*soybev_wtg2;	
		/*if nuts_wtg ne 0 and unq_nuts_k ne . then nuts_k2_v2=unq_nuts_k*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_k ne . then seeds_k2_v2=unq_seeds_k*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_k ne . then lgmes_k2_v2=unq_lgmes_k*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_k ne . then tofu_k2_v2=unq_tofu_k*tofu_wtg2;*/	
	/*Carbs*/
		if nuts_wtg ne 0 and unq_nuts_carb ne . then nuts_carb2=unq_nuts_carb*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_carb ne . then seeds_carb2=unq_seeds_carb*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_carb ne . then lgmes_carb2=unq_lgmes_carb*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_carb ne . then tofu_carb2=unq_tofu_carb*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_carb ne . then soybev_carb2=unq_soybev_carb*soybev_wtg2;	
	/*MUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_mufa ne . then nuts_mufa2=unq_nuts_mufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_mufa ne . then seeds_mufa2=unq_seeds_mufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_mufa ne . then lgmes_mufa2=unq_lgmes_mufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_mufa ne . then tofu_mufa2=unq_tofu_mufa*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_mufa ne . then soybev_mufa2=unq_soybev_mufa*soybev_wtg2;	
	/*PUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_pufa ne . then nuts_pufa2=unq_nuts_pufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pufa ne . then seeds_pufa2=unq_seeds_pufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pufa ne . then lgmes_pufa2=unq_lgmes_pufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pufa ne . then tofu_pufa2=unq_tofu_pufa*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_pufa ne . then soybev_pufa2=unq_soybev_pufa*soybev_wtg2;	

/*For respodents that did not originally consume dairy, nutrients=0 after replacement*/
	if milk_wtg=0 then milk_ekc2=0;	
	if milk_wtg=0 then milk_sug2=0;
	if milk_wtg=0 then milk_sat2=0;
	if milk_wtg=0 then milk_pro2=0;
	if milk_wtg=0 then milk_vitD2=0;
	if milk_wtg=0 then milk_ca2=0;
	if milk_wtg=0 then milk_fe2=0;
	if milk_wtg=0 then milk_na2=0;
	if milk_wtg=0 then milk_k2=0;
	if milk_wtg=0 then milk_carb2=0;
	if milk_wtg=0 then milk_mufa2=0;
	if milk_wtg=0 then milk_pufa2=0;
	
	if cheese_wtg=0 then cheese_ekc2=0;
	if cheese_wtg=0 then cheese_sug2=0;
	if cheese_wtg=0 then cheese_sat2=0;
	if cheese_wtg=0 then cheese_pro2=0;
	if cheese_wtg=0 then cheese_vitD2=0;
	if cheese_wtg=0 then cheese_ca2=0;
	if cheese_wtg=0 then cheese_fe2=0;
	if cheese_wtg=0 then cheese_na2=0;
	if cheese_wtg=0 then cheese_k2=0;
	if cheese_wtg=0 then cheese_carb2=0;
	if cheese_wtg=0 then cheese_mufa2=0;
	if cheese_wtg=0 then cheese_pufa2=0;
	
	if yghrt_wtg=0 then yghrt_ekc2=0;
	if yghrt_wtg=0 then yghrt_sug2=0;
	if yghrt_wtg=0 then yghrt_sat2=0;
	if yghrt_wtg=0 then yghrt_pro2=0;
	if yghrt_wtg=0 then yghrt_vitD2=0;
	if yghrt_wtg=0 then yghrt_ca2=0;
	if yghrt_wtg=0 then yghrt_fe2=0;
	if yghrt_wtg=0 then yghrt_na2=0;
	if yghrt_wtg=0 then yghrt_k2=0;
	if yghrt_wtg=0 then yghrt_carb2=0;
	if yghrt_wtg=0 then yghrt_mufa2=0;
	if yghrt_wtg=0 then yghrt_pufa2=0;
	
	if cream_wtg=0 then cream_ekc2=0;
	if cream_wtg=0 then cream_sug2=0;
	if cream_wtg=0 then cream_sat2=0;
	if cream_wtg=0 then cream_pro2=0;
	if cream_wtg=0 then cream_vitD2=0;
	if cream_wtg=0 then cream_ca2=0;
	if cream_wtg=0 then cream_fe2=0;
	if cream_wtg=0 then cream_na2=0;
	if cream_wtg=0 then cream_k2=0;
	if cream_wtg=0 then cream_carb2=0;
	if cream_wtg=0 then cream_mufa2=0;
	if cream_wtg=0 then cream_pufa2=0;

	if butr_wtg=0 then butr_ekc2=0;
	if butr_wtg=0 then butr_sug2=0;
	if butr_wtg=0 then butr_sat2=0;
	if butr_wtg=0 then butr_pro2=0;
	if butr_wtg=0 then butr_vitD2=0;
	if butr_wtg=0 then butr_ca2=0;
	if butr_wtg=0 then butr_fe2=0;
	if butr_wtg=0 then butr_na2=0;
	if butr_wtg=0 then butr_k2=0;
	if butr_wtg=0 then butr_carb2=0;
	if butr_wtg=0 then butr_mufa2=0;
	if butr_wtg=0 then butr_pufa2=0;

	if frzn_wtg=0 then frzn_ekc2=0;
	if frzn_wtg=0 then frzn_sug2=0;
	if frzn_wtg=0 then frzn_sat2=0;
	if frzn_wtg=0 then frzn_pro2=0;
	if frzn_wtg=0 then frzn_vitD2=0;
	if frzn_wtg=0 then frzn_ca2=0;
	if frzn_wtg=0 then frzn_fe2=0;
	if frzn_wtg=0 then frzn_na2=0;
	if frzn_wtg=0 then frzn_k2=0;
	if frzn_wtg=0 then frzn_carb2=0;
	if frzn_wtg=0 then frzn_mufa2=0;
	if frzn_wtg=0 then frzn_pufa2=0;

/*For respondents that did not originally consume nsl, use a weighted average for nutrients*/
/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_ekc2=6.068735152*nuts_wtg2;
	if nuts_wtg=0 then nuts_sug2=0.023412133*nuts_wtg2;		/*Note that this is weighted avg. for FREE SUGARS*/
	if nuts_wtg=0 then nuts_sat2=0.078223051*nuts_wtg2;
	if nuts_wtg=0 then nuts_pro2=0.189748537*nuts_wtg2;
	if nuts_wtg=0 then nuts_vitD2=0*nuts_wtg2;
	if nuts_wtg=0 then nuts_ca2=1.047177739*nuts_wtg2;
	if nuts_wtg=0 then nuts_fe2=0.028762549*nuts_wtg2;
	if nuts_wtg=0 then nuts_na2=1.538556973*nuts_wtg2;
	if nuts_wtg=0 then nuts_k2=5.879183898*nuts_wtg2;
	if nuts_wtg=0 then nuts_carb2=0.208693214*nuts_wtg2;
	if nuts_wtg=0 then nuts_mufa2=0.250425621*nuts_wtg2;
	if nuts_wtg=0 then nuts_pufa2=0.184819969*nuts_wtg2;

	if seeds_wtg=0 then seeds_ekc2=5.588623188*seeds_wtg2;
	if seeds_wtg=0 then seeds_sug2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_sat2=0.053096123*seeds_wtg2;
	if seeds_wtg=0 then seeds_pro2=0.212654067*seeds_wtg2;
	if seeds_wtg=0 then seeds_vitD2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_ca2=1.625144928*seeds_wtg2;
	if seeds_wtg=0 then seeds_fe2=0.060998279*seeds_wtg2;
	if seeds_wtg=0 then seeds_na2=0.780842391*seeds_wtg2;
	if seeds_wtg=0 then seeds_k2=7.510996377*seeds_wtg2;
	if seeds_wtg=0 then seeds_carb2=0.236999647*seeds_wtg2;
	if seeds_wtg=0 then seeds_mufa2=0.111621132*seeds_wtg2;
	if seeds_wtg=0 then seeds_pufa2=0.269852745*seeds_wtg2;

	if lgmes_wtg=0 then lgmes_ekc2=0.93228815*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sug2=0.003114783*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sat2=0.001913132*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pro2=0.057528201*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_vitD2=0*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_ca2=0.366772379*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_fe2=0.01791809*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_na2=1.035202046*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_k2=2.539577153*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_carb2=0.161040051*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_mufa2=0.003398607*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pufa2=0.004636307*lgmes_wtg2;

	if tofu_wtg=0 then tofu_ekc2=2.428236398*tofu_wtg2;
	if tofu_wtg=0 then tofu_sug2=0.000317073*tofu_wtg2;
	if tofu_wtg=0 then tofu_sat2=0.020709869*tofu_wtg2;
	if tofu_wtg=0 then tofu_pro2=0.227237148*tofu_wtg2;
	if tofu_wtg=0 then tofu_vitD2=0*tofu_wtg2;
	if tofu_wtg=0 then tofu_ca2=1.770863039*tofu_wtg2;
	if tofu_wtg=0 then tofu_fe2=0.032112383*tofu_wtg2;
	if tofu_wtg=0 then tofu_na2=6.259924953*tofu_wtg2;
	if tofu_wtg=0 then tofu_k2=1.671575985*tofu_wtg2;
	if tofu_wtg=0 then tofu_carb2=0.114113884*tofu_wtg2;
	if tofu_wtg=0 then tofu_mufa2=0.03100454*tofu_wtg2;
	if tofu_wtg=0 then tofu_pufa2=0.065414953*tofu_wtg2;

	if soybev_wtg=0 then soybev_ekc2=0.431954397*soybev_wtg2;
	if soybev_wtg=0 then soybev_sug2=0.032720554*soybev_wtg2;
	if soybev_wtg=0 then soybev_sat2=0.002055863*soybev_wtg2;
	if soybev_wtg=0 then soybev_pro2=0.025984365*soybev_wtg2;
	if soybev_wtg=0 then soybev_vitD2=0.0084*soybev_wtg2;
	if soybev_wtg=0 then soybev_ca2=1.232*soybev_wtg2;
	if soybev_wtg=0 then soybev_fe2=0.004219544*soybev_wtg2;
	if soybev_wtg=0 then soybev_na2=0.469218241*soybev_wtg2;
	if soybev_wtg=0 then soybev_k2=1.479*soybev_wtg2;
	if soybev_wtg=0 then soybev_carb2=0.049561564*soybev_wtg2;
	if soybev_wtg=0 then soybev_mufa2=0.003819218*soybev_wtg2;
	if soybev_wtg=0 then soybev_pufa2=0.00860228*soybev_wtg2;

/*Setting missing values to 0 here*/
	if milk_ekc=. then milk_ekc=0;	
	if milk_sug=. then milk_sug=0;
	if milk_sat=. then milk_sat=0;
	if milk_pro=. then milk_pro=0;
	if milk_vitD=. then milk_vitD=0;
	if milk_ca=. then milk_ca=0;
	if milk_fe=. then milk_fe=0;
	if milk_na=. then milk_na=0;
	if milk_k=. then milk_k=0;
	if milk_carb=. then milk_carb=0;
	if milk_mufa=. then milk_mufa=0;
	if milk_pufa=. then milk_pufa=0;
	
	if cheese_ekc=. then cheese_ekc=0;
	if cheese_sug=. then cheese_sug=0;
	if cheese_sat=. then cheese_sat=0;
	if cheese_pro=. then cheese_pro=0;
	if cheese_vitD=. then cheese_vitD=0;
	if cheese_ca=. then cheese_ca=0;
	if cheese_fe=. then cheese_fe=0;
	if cheese_na=. then cheese_na=0;
	if cheese_k=. then cheese_k=0;
	if cheese_carb=. then cheese_carb=0;
	if cheese_mufa=. then cheese_mufa=0;
	if cheese_pufa=. then cheese_pufa=0;
	
	if yghrt_ekc=. then yghrt_ekc=0;
	if yghrt_sug=. then yghrt_sug=0;
	if yghrt_sat=. then yghrt_sat=0;
	if yghrt_pro=. then yghrt_pro=0;
	if yghrt_vitD=. then yghrt_vitD=0;
	if yghrt_ca=. then yghrt_ca=0;
	if yghrt_fe=. then yghrt_fe=0;
	if yghrt_na=. then yghrt_na=0;
	if yghrt_k=. then yghrt_k=0;
	if yghrt_carb=. then yghrt_carb=0;
	if yghrt_mufa=. then yghrt_mufa=0;
	if yghrt_pufa=. then yghrt_pufa=0;
	
	if cream_ekc=. then cream_ekc=0;
	if cream_sug=. then cream_sug=0;
	if cream_sat=. then cream_sat=0;
	if cream_pro=. then cream_pro=0;
	if cream_vitD=. then cream_vitD=0;
	if cream_ca=. then cream_ca=0;
	if cream_fe=. then cream_fe=0;
	if cream_na=. then cream_na=0;
	if cream_k=. then cream_k=0;
	if cream_carb=. then cream_carb=0;
	if cream_mufa=. then cream_mufa=0;
	if cream_pufa=. then cream_pufa=0;

	if butr_ekc=. then butr_ekc=0;	
	if butr_sug=. then butr_sug=0;
	if butr_sat=. then butr_sat=0;
	if butr_pro=. then butr_pro=0;
	if butr_vitD=. then butr_vitD=0;
	if butr_ca=. then butr_ca=0;
	if butr_fe=. then butr_fe=0;
	if butr_na=. then butr_na=0;
	if butr_k=. then butr_k=0;
	if butr_carb=. then butr_carb=0;
	if butr_mufa=. then butr_mufa=0;
	if butr_pufa=. then butr_pufa=0;

	if frzn_ekc=. then frzn_ekc=0;	
	if frzn_sug=. then frzn_sug=0;
	if frzn_sat=. then frzn_sat=0;
	if frzn_pro=. then frzn_pro=0;
	if frzn_vitD=. then frzn_vitD=0;
	if frzn_ca=. then frzn_ca=0;
	if frzn_fe=. then frzn_fe=0;
	if frzn_na=. then frzn_na=0;
	if frzn_k=. then frzn_k=0;
	if frzn_carb=. then frzn_carb=0;
	if frzn_mufa=. then frzn_mufa=0;
	if frzn_pufa=. then frzn_pufa=0;

	if nuts_ekc=. then nuts_ekc=0;
	if nuts_sug=. then nuts_sug=0;
	if nuts_sat=. then nuts_sat=0;
	if nuts_pro=. then nuts_pro=0;
	if nuts_vitD=. then nuts_vitD=0;
	if nuts_ca=. then nuts_ca=0;
	if nuts_fe=. then nuts_fe=0;
	if nuts_na=. then nuts_na=0;
	if nuts_k=. then nuts_k=0;
	if nuts_carb=. then nuts_carb=0;
	if nuts_mufa=. then nuts_mufa=0;
	if nuts_pufa=. then nuts_pufa=0;

	if seeds_ekc=. then seeds_ekc=0;
	if seeds_sug=. then seeds_sug=0;
	if seeds_sat=. then seeds_sat=0;
	if seeds_pro=. then seeds_pro=0;
	if seeds_vitD=. then seeds_vitD=0;
	if seeds_ca=. then seeds_ca=0;
	if seeds_fe=. then seeds_fe=0;
	if seeds_na=. then seeds_na=0;
	if seeds_k=. then seeds_k=0;
	if seeds_carb=. then seeds_carb=0;
	if seeds_mufa=. then seeds_mufa=0;
	if seeds_pufa=. then seeds_pufa=0;

	if lgmes_ekc=. then lgmes_ekc=0;
	if lgmes_sug=. then lgmes_sug=0;
	if lgmes_sat=. then lgmes_sat=0;
	if lgmes_pro=. then lgmes_pro=0;
	if lgmes_vitD=. then lgmes_vitD=0;
	if lgmes_ca=. then lgmes_ca=0;
	if lgmes_fe=. then lgmes_fe=0;
	if lgmes_na=. then lgmes_na=0;
	if lgmes_k=. then lgmes_k=0;
	if lgmes_carb=. then lgmes_carb=0;
	if lgmes_mufa=. then lgmes_mufa=0;
	if lgmes_pufa=. then lgmes_pufa=0;

	if tofu_ekc=. then tofu_ekc=0;
	if tofu_sug=. then tofu_sug=0;
	if tofu_sat=. then tofu_sat=0;
	if tofu_pro=. then tofu_pro=0;
	if tofu_vitD=. then tofu_vitD=0;
	if tofu_ca=. then tofu_ca=0;
	if tofu_fe=. then tofu_fe=0;
	if tofu_na=. then tofu_na=0;
	if tofu_k=. then tofu_k=0;
	if tofu_carb=. then tofu_carb=0;
	if tofu_mufa=. then tofu_mufa=0;
	if tofu_pufa=. then tofu_pufa=0;

	if soybev_ekc=. then soybev_ekc=0;
	if soybev_sug=. then soybev_sug=0;
	if soybev_sat=. then soybev_sat=0;
	if soybev_pro=. then soybev_pro=0;
	if soybev_vitD=. then soybev_vitD=0;
	if soybev_ca=. then soybev_ca=0;
	if soybev_fe=. then soybev_fe=0;
	if soybev_na=. then soybev_na=0;
	if soybev_k=. then soybev_k=0;
	if soybev_carb=. then soybev_carb=0;
	if soybev_mufa=. then soybev_mufa=0;
	if soybev_pufa=. then soybev_pufa=0;

/*Setting missing values to 0 for other foods here*/
	if beef_ekc=. then beef_ekc=0;
	if beef_sug=. then beef_sug=0;
	if beef_sat=. then beef_sat=0;
	if beef_pro=. then beef_pro=0;
	if beef_vitD=. then beef_vitD=0;
	if beef_ca=. then beef_ca=0;
	if beef_fe=. then beef_fe=0;
	if beef_na=. then beef_na=0;
	if beef_k=. then beef_k=0;
	if beef_carb=. then beef_carb=0;
	if beef_mufa=. then beef_mufa=0;
	if beef_pufa=. then beef_pufa=0;

	if lamb_ekc=. then lamb_ekc=0;
	if lamb_sug=. then lamb_sug=0;
	if lamb_sat=. then lamb_sat=0;
	if lamb_pro=. then lamb_pro=0;
	if lamb_vitD=. then lamb_vitD=0;
	if lamb_ca=. then lamb_ca=0;
	if lamb_fe=. then lamb_fe=0;
	if lamb_na=. then lamb_na=0;
	if lamb_k=. then lamb_k=0;
	if lamb_carb=. then lamb_carb=0;
	if lamb_mufa=. then lamb_mufa=0;
	if lamb_pufa=. then lamb_pufa=0;

	if pork_ekc=. then pork_ekc=0;
	if pork_sug=. then pork_sug=0;
	if pork_sat=. then pork_sat=0;
	if pork_pro=. then pork_pro=0;
	if pork_vitD=. then pork_vitD=0;
	if pork_ca=. then pork_ca=0;
	if pork_fe=. then pork_fe=0;
	if pork_na=. then pork_na=0;
	if pork_k=. then pork_k=0;
	if pork_carb=. then pork_carb=0;
	if pork_mufa=. then pork_mufa=0;
	if pork_pufa=. then pork_pufa=0;

	if lnchn_ekc=. then lnchn_ekc=0;
	if lnchn_sug=. then lnchn_sug=0;
	if lnchn_sat=. then lnchn_sat=0;
	if lnchn_pro=. then lnchn_pro=0;
	if lnchn_vitD=. then lnchn_vitD=0;
	if lnchn_ca=. then lnchn_ca=0;
	if lnchn_fe=. then lnchn_fe=0;
	if lnchn_na=. then lnchn_na=0;
	if lnchn_k=. then lnchn_k=0;
	if lnchn_carb=. then lnchn_carb=0;
	if lnchn_mufa=. then lnchn_mufa=0;
	if lnchn_pufa=. then lnchn_pufa=0;

	if other_ekc=. then other_ekc=0;
	if other_sug=. then other_sug=0;
	if other_sat=. then other_sat=0;
	if other_pro=. then other_pro=0;
	if other_vitD=. then other_vitD=0;
	if other_ca=. then other_ca=0;
	if other_fe=. then other_fe=0;
	if other_na=. then other_na=0;
	if other_k=. then other_k=0;
	if other_carb=. then other_carb=0;
	if other_mufa=. then other_mufa=0;
	if other_pufa=. then other_pufa=0;

/*Variables for protein*/
	dairy_pro=milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro;
	nsl_pro=nuts_pro+seeds_pro+lgmes_pro+tofu_pro+soybev_pro;
	dairy_pro2=milk_pro2+cheese_pro2+yghrt_pro2+cream_pro2+butr_pro2+frzn_pro2;
	nsl_pro2=nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+soybev_pro2;
	meat_pro=beef_pro+lamb_pro+pork_pro+lnchn_pro;
/*Variables for energy*/
	dairy_ekc=milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc;
	nsl_ekc=nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	dairy_ekc2=milk_ekc2+cheese_ekc2+yghrt_ekc2+cream_ekc2+butr_ekc2+frzn_ekc2;
	nsl_ekc2=nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc2;
	meat_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc;
/*Variables for carbs*/
	dairy_carb=milk_carb+cheese_carb+yghrt_carb+cream_carb+butr_carb+frzn_carb;
	nsl_carb=nuts_carb+seeds_carb+lgmes_carb+tofu_carb+soybev_carb;
	dairy_carb2=milk_carb2+cheese_carb2+yghrt_carb2+cream_carb2+butr_carb2+frzn_carb2;
	nsl_carb2=nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb2;
	meat_carb=beef_carb+lamb_carb+pork_carb+lnchn_carb;

/*Variables for total energy intake*/
	diet_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc+nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	diet_ekc2=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+milk_ekc2+cheese_ekc2+yghrt_ekc2+cream_ekc2+butr_ekc2+frzn_ekc2+other_ekc+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc2;

/*keep sampleid milk_ekc cheese_ekc yghrt_ekc cream_ekc butr_ekc frzn_ekc milk_ekc2 cheese_ekc2 yghrt_ekc2 cream_ekc2 butr_ekc2 frzn_ekc2 	
	 nuts_ekc seeds_ekc lgmes_ekc tofu_ekc nuts_ekc2 seeds_ekc2 lgmes_ekc2 tofu_ekc2
	 milk_carb cheese_carb yghrt_carb cream_carb butr_carb frzn_carb milk_carb2 cheese_carb2 yghrt_carb2 cream_carb2 butr_carb2 frzn_carb2 	
	 nuts_carb seeds_carb lgmes_carb tofu_carb nuts_carb2 seeds_carb2 lgmes_carb2 tofu_carb2
	 unq_nuts_ekc unq_seeds_ekc unq_lgmes_ekc unq_tofu_ekc
	 nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2;*/

run;
/*17,921 observations (Master Files)*/

proc means n nmiss mean min max data=rs2_50_nutr;	
	var milk_ekc milk_ekc2 milk_sug milk_sug2 milk_sat milk_sat2 milk_pro milk_pro2 milk_vitD milk_vitD2 milk_ca milk_ca2 milk_fe milk_fe2 milk_na milk_na2 milk_k milk_k2 milk_carb milk_carb2	milk_mufa milk_mufa2 milk_pufa milk_pufa2		
		cheese_ekc cheese_ekc2 cheese_sug cheese_sug2 cheese_sat cheese_sat2 cheese_pro cheese_pro2 cheese_vitD cheese_vitD2 cheese_ca cheese_ca2 cheese_fe cheese_fe2 cheese_na cheese_na2 cheese_k cheese_k2 cheese_carb cheese_carb2 cheese_mufa cheese_mufa2 cheese_pufa cheese_pufa2
		yghrt_ekc yghrt_ekc2 yghrt_sug yghrt_sug2 yghrt_sat yghrt_sat2 yghrt_pro yghrt_pro2 yghrt_vitD yghrt_vitD2 yghrt_ca yghrt_ca2 yghrt_fe yghrt_fe2 yghrt_na yghrt_na2 yghrt_k yghrt_k2 yghrt_carb yghrt_carb2 yghrt_mufa yghrt_mufa2 yghrt_pufa yghrt_pufa2
		cream_ekc cream_ekc2 cream_sug cream_sug2 cream_sat cream_sat2 cream_pro cream_pro2 cream_vitD cream_vitD2 cream_ca cream_ca2 cream_fe cream_fe2 cream_na cream_na2 cream_k cream_k2 cream_carb cream_carb2 cream_mufa cream_mufa2 cream_pufa cream_pufa2
		butr_ekc butr_ekc2 butr_sug butr_sug2 butr_sat butr_sat2 butr_pro butr_pro2 butr_vitD butr_vitD2 butr_ca butr_ca2 butr_fe butr_fe2 butr_na butr_na2 butr_k butr_k2 butr_carb butr_carb2 butr_mufa butr_mufa2 butr_pufa butr_pufa2		
		frzn_ekc frzn_ekc2 frzn_sug frzn_sug2 frzn_sat frzn_sat2 frzn_pro frzn_pro2 frzn_vitD frzn_vitD2 frzn_ca frzn_ca2 frzn_fe frzn_fe2 frzn_na frzn_na2 frzn_k frzn_k2 frzn_carb frzn_carb2 frzn_mufa frzn_mufa2 frzn_pufa frzn_pufa2
		nuts_ekc nuts_ekc2 nuts_sug nuts_sug2 nuts_sat nuts_sat2 nuts_pro nuts_pro2 nuts_vitD nuts_vitD2 nuts_ca nuts_ca2 nuts_fe nuts_fe2 nuts_na nuts_na2 nuts_k nuts_k2 nuts_carb nuts_carb2 nuts_mufa nuts_mufa2 nuts_pufa nuts_pufa2
		seeds_ekc seeds_ekc2 seeds_sug seeds_sug2 seeds_sat seeds_sat2 seeds_pro seeds_pro2 seeds_vitD seeds_vitD2 seeds_ca seeds_ca2 seeds_fe seeds_fe2 seeds_na seeds_na2 seeds_k seeds_k2 seeds_carb seeds_carb2 seeds_mufa seeds_mufa2 seeds_pufa seeds_pufa2
		lgmes_ekc lgmes_ekc2 lgmes_sug lgmes_sug2 lgmes_sat lgmes_sat2 lgmes_pro lgmes_pro2 lgmes_vitD lgmes_vitD2 lgmes_ca lgmes_ca2 lgmes_fe lgmes_fe2 lgmes_na lgmes_na2 lgmes_k lgmes_k2 lgmes_carb lgmes_carb2 lgmes_mufa lgmes_mufa2 lgmes_pufa lgmes_pufa2
		tofu_ekc tofu_ekc2 tofu_sug tofu_sug2 tofu_sat tofu_sat2 tofu_pro tofu_pro2 tofu_vitD tofu_vitD2 tofu_ca tofu_ca2 tofu_fe tofu_fe2 tofu_na tofu_na2 tofu_k tofu_k2 tofu_carb tofu_carb2 tofu_mufa tofu_mufa2 tofu_pufa tofu_pufa2
		beef_ekc beef_sug beef_sat beef_pro beef_vitD beef_ca beef_fe beef_na beef_k beef_carb beef_mufa beef_pufa		
		lamb_ekc lamb_sug lamb_sat lamb_pro lamb_vitD lamb_ca lamb_fe lamb_na lamb_k lamb_carb lamb_mufa lamb_pufa
		pork_ekc pork_sug pork_sat pork_pro pork_vitD pork_ca pork_fe pork_na pork_k pork_carb pork_mufa pork_pufa
		lnchn_ekc lnchn_sug lnchn_sat lnchn_pro lnchn_vitD lnchn_ca lnchn_fe lnchn_na lnchn_k lnchn_carb lnchn_mufa lnchn_pufa
		other_ekc other_sug other_sat other_pro other_vitD other_ca other_fe other_na other_k other_carb other_mufa other_pufa
		diet_ekc diet_ekc2;
run;

/*Some nutrient values are still missing. These are genuine missing values at the FID level. For example, there are 106 missing values for cheese_sug.
These respondents consumed cheese, but sug values are missing. It's okay to set them to 0 as done below, because we need to aggregate nutrient totals.
To verify, run the following lines:*/

/*proc means n nmiss data=rs2_50_nutr; var cheese_sug cheese_sug2; run;
data a;
	set rs2_50_nutr;
	if cheese_sug2=.;
	id=1;
	keep sampleid cheese_wtg cheese_sug cheese_sug2 id;
run;

data b;
	set sbgrps;
	if sampleid='10010584210007265121' and food_subgrp=6;
run;

/*Set missing vlues to 0 or else they will not add up*/
data rs2_50_nutr;
	set rs2_50_nutr;
	/*if milk_sug2=. then milk_sug2=0;*/
	if milk_sat2=. then milk_sat2=0;
	if milk_vitD2=. then milk_vitD2=0;
	if milk_fe2=. then milk_fe2=0;
	if milk_na2=. then milk_na2=0;
	if milk_k2=. then milk_k2=0;
	if milk_mufa2=. then milk_mufa2=0;
	if milk_pufa2=. then milk_pufa2=0;
	/*if cheese_sug2=. then cheese_sug2=0;*/
	if cheese_vitD2=. then cheese_vitD2=0;
	if cheese_fe2=. then cheese_fe2=0;
	if cheese_mufa2=. then cheese_mufa2=0;
	if cheese_pufa2=. then cheese_pufa2=0;
	if cream_sug2=. then cream_sug2=0;
	if cream_vitD2=. then cream_vitD2=0;
	if nuts_sug2=. then nuts_sug2=0;
	if nuts_vitD2=. then nuts_vitD2=0;
	/*if seeds_sug2=. then seeds_sug2=0;*/
	if seeds_vitD2=. then seeds_vitD2=0;
	/*if lgmes_sug2=. then lgmes_sug2=0;*/
	if lgmes_vitD2=. then lgmes_vitD2=0;
run;

/* !!!!!!!!!!!!!!!!!!!!!!! */
/*Use this as input for NCI*/
/* !!!!!!!!!!!!!!!!!!!!!!! */
data rs2_50_nutr_nci;
	set rs2_50_nutr;
/*Nutrient totals*/

/*After*/
	tot_ekc2=milk_ekc2+cheese_ekc2+yghrt_ekc2+cream_ekc2+butr_ekc2+frzn_ekc2+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc2+beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+other_ekc;
	tot_sug2=milk_sug2+cheese_sug2+yghrt_sug2+cream_sug2+butr_sug2+frzn_sug2+nuts_sug2+seeds_sug2+lgmes_sug2+tofu_sug2+soybev_sug2+beef_sug+lamb_sug+pork_sug+lnchn_sug+other_sug;
	tot_sat2=milk_sat2+cheese_sat2+yghrt_sat2+cream_sat2+butr_sat2+frzn_sat2+nuts_sat2+seeds_sat2+lgmes_sat2+tofu_sat2+soybev_sat2+beef_sat+lamb_sat+pork_sat+lnchn_sat+other_sat;
	tot_pro2=milk_pro2+cheese_pro2+yghrt_pro2+cream_pro2+butr_pro2+frzn_pro2+nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+soybev_pro2+beef_pro+lamb_pro+pork_pro+lnchn_pro+other_pro;
	tot_vitD2=milk_vitD2+cheese_vitD2+yghrt_vitD2+cream_vitD2+butr_vitD2+frzn_vitD2+nuts_vitD2+seeds_vitD2+lgmes_vitD2+tofu_vitD2+soybev_vitD2+beef_vitD+lamb_vitD+pork_vitD+lnchn_vitD+other_vitD;
	tot_ca2=milk_ca2+cheese_ca2+yghrt_ca2+cream_ca2+butr_ca2+frzn_ca2+nuts_ca2+seeds_ca2+lgmes_ca2+tofu_ca2+soybev_ca2+beef_ca+lamb_ca+pork_ca+lnchn_ca+other_ca;
	tot_fe2=milk_fe2+cheese_fe2+yghrt_fe2+cream_fe2+butr_fe2+frzn_fe2+nuts_fe2+seeds_fe2+lgmes_fe2+tofu_fe2+soybev_fe2+beef_fe+lamb_fe+pork_fe+lnchn_fe+other_fe;
	tot_na2=milk_na2+cheese_na2+yghrt_na2+cream_na2+butr_na2+frzn_na2+nuts_na2+seeds_na2+lgmes_na2+tofu_na2+soybev_na2+beef_na+lamb_na+pork_na+lnchn_na+other_na;
	tot_k2=milk_k2+cheese_k2+yghrt_k2+cream_k2+butr_k2+frzn_k2+nuts_k2+seeds_k2+lgmes_k2+tofu_k2+soybev_k2+beef_k+lamb_k+pork_k+lnchn_k+other_k;
	tot_carb2=milk_carb2+cheese_carb2+yghrt_carb2+cream_carb2+butr_carb2+frzn_carb2+nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb2+beef_carb+lamb_carb+pork_carb+lnchn_carb+other_carb;
	tot_mufa2=milk_mufa2+cheese_mufa2+yghrt_mufa2+cream_mufa2+butr_mufa2+frzn_mufa2+nuts_mufa2+seeds_mufa2+lgmes_mufa2+tofu_mufa2+soybev_mufa2+beef_mufa+lamb_mufa+pork_mufa+lnchn_mufa+other_mufa;
	tot_pufa2=milk_pufa2+cheese_pufa2+yghrt_pufa2+cream_pufa2+butr_pufa2+frzn_pufa2+nuts_pufa2+seeds_pufa2+lgmes_pufa2+tofu_pufa2+soybev_pufa2+beef_pufa+lamb_pufa+pork_pufa+lnchn_pufa+other_pufa;

	/*Free sugars and saturated fat expressed as a percentage of total energy intake*/
	if tot_sug2 ne 0 and tot_ekc2 ne 0 then tot_sug2_pcnt=((tot_sug2*4)/tot_ekc2)*100;
	if tot_sug2=0 or tot_ekc2=0 then tot_sug2_pcnt=0;

	if tot_sat2 ne 0 and tot_ekc2 ne 0 then tot_sat2_pcnt=((tot_sat2*9)/tot_ekc2)*100;
	if tot_sat2=0 or tot_ekc2=0 then tot_sat2_pcnt=0;

	/*keep sampleid suppid wts_m wts_mhw admfw dhhddri dhh_sex dhh_age mhwdbmi mhwdhtm mhwdwtk
	fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_sug2_pcnt tot_sat2_pcnt;*/
run;
/*17,921 observations (Master Files)*/

/*Preliminary results (nutrients)*/
proc means n nmiss mean min max data=rs2_50_nutr_nci;	
	var fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa fsddcar fsddfam fsddfap tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_carb2 tot_sug2_pcnt tot_sat2_pcnt
		tot_mufa2 tot_pufa2;
run;
/*g of free sug (tot_free_sug) is around 53 and free sug as % of TEI is around 11, which is in line with Rana et al. 2021*/

/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Input for NCI w/ supplements*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
data rs2_50_nutr_nci;
	set rs2_50_nutr_nci;
	idnty=1;
run;

proc sort data=rs2_50_nutr_nci; by sampleid suppid; run;
proc sort data=vst_nutr_cncrn; by sampleid suppid; run;

data rs2_50_nutr_nci_supp;
	merge rs2_50_nutr_nci vst_nutr_cncrn;
	by sampleid suppid;
	if idnty=1;
	drop idnty;
run; 
/*17,921 obs*/

data rs2_50_nutr_nci_supp;
	set rs2_50_nutr_nci_supp;
	/*vitD supplement users: vitD_supp_user=1; non-users: vitD_supp_user=2*/
	if vsdfdmg=1 then vitD_supp_user=1; else vitD_supp_user=2;
	if vsdfcal=1 then cal_supp_user=1; else cal_supp_user=2;
	if vsdfiro=1 then iron_supp_user=1; else iron_supp_user=2;
	if vsdfpot=1 then pot_supp_user=1; else pot_supp_user=2;
run;

data rs2_50_nutr_nci_supp;
	set rs2_50_nutr_nci_supp;

/*Nutrient intakes from food + supplements (observed)*/
	if VSTDCAL ne . then tot_ca_supp=FSDDCAL+VSTDCAL;
	if VSTDIRO ne . then tot_fe_supp=FSDDIRO+VSTDIRO;
	if VSTDPOT ne . then tot_k_supp=FSDDPOT+VSTDPOT;
	if VSTDDMG ne . then tot_vitD_supp=FSDDDMG+VSTDDMG;
	if VSTDSOD ne . then tot_na_supp=FSDDSOD+VSTDSOD;

	if VSTDCAL=. then tot_ca_supp=FSDDCAL;
	if VSTDIRO=. then tot_fe_supp=FSDDIRO;
	if VSTDPOT=. then tot_k_supp=FSDDPOT;
	if VSTDDMG=. then tot_vitD_supp=FSDDDMG;
	if VSTDSOD=. then tot_na_supp=FSDDSOD; 

/*Nutrient intakes from food + supplements (replacements)*/
	if VSTDCAL ne . then tot_ca2_supp=tot_ca2+VSTDCAL;
	if VSTDIRO ne . then tot_fe2_supp=tot_fe2+VSTDIRO;
	if VSTDPOT ne . then tot_k2_supp=tot_k2+VSTDPOT;
	if VSTDDMG ne . then tot_vitD2_supp=tot_vitD2+VSTDDMG;
	if VSTDSOD ne . then tot_na2_supp=tot_na2+VSTDSOD;

	if VSTDCAL=. then tot_ca2_supp=tot_ca2;
	if VSTDIRO=. then tot_fe2_supp=tot_fe2;
	if VSTDPOT=. then tot_k2_supp=tot_k2;
	if VSTDDMG=. then tot_vitD2_supp=tot_vitD2;
	if VSTDSOD=. then tot_na2_supp=tot_na2; 

run;

/*Datasets for vitD*/
data rs2_50_supp_users_vitD;
	set rs2_50_nutr_nci_supp;
	if vitD_supp_user=1;
run;
data rs2_50_supp_nonusers_vitD;
	set rs2_50_nutr_nci_supp;
	if vitD_supp_user=2;
run;

/*Datasets for iron*/
data rs2_50_supp_users_iron;
	set rs2_50_nutr_nci_supp;
	if iron_supp_user=1;
run;
data rs2_50_supp_nonusers_iron;
	set rs2_50_nutr_nci_supp;
	if iron_supp_user=2;
run;

/*Datasets for calcium*/
data rs2_50_supp_users_cal;
	set rs2_50_nutr_nci_supp;
	if cal_supp_user=1;
run;
data rs2_50_supp_nonusers_cal;
	set rs2_50_nutr_nci_supp;
	if cal_supp_user=2;
run;

/*Datasets for potassium*/
data rs2_50_supp_users_pot;
	set rs2_50_nutr_nci_supp;
	if pot_supp_user=1;
run;
data rs2_50_supp_nonusers_pot;
	set rs2_50_nutr_nci_supp;
	if pot_supp_user=2;
run;

proc means n nmiss mean min max data=rs2_50_nutr_nci_supp;	
	var fsddcal fsddiro fsddpot fsdddmg fsddsod tot_ca2 tot_fe2 tot_vitD2 tot_k2 tot_na2
		tot_ca_supp tot_fe_supp tot_k_supp tot_vitD_supp tot_na_supp tot_ca2_supp tot_fe2_supp tot_k2_supp tot_vitD2_supp tot_na2_supp;
run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Use this for health outcome anaylses*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */

data rs2_50_nutr_nci;
	set rs2_50_nutr_nci;

/*Observed diets*/

	/*Red meat*/
	/*red_meat_wtg=beef_wtg+lamb_wtg+pork_wtg;
	red_meat_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2;

	/*Nuts and seeds*/
	nts_sds_wtg=nuts_wtg+seeds_wtg;
	nts_sds_wtg2=nuts_wtg2+seeds_wtg2;

run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/* Use this for nci anaylses for foods */
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*This can be used for observed diets and RS2-25%*/
data rs2_50_food_nci;
	set rs2_50_nutr_nci;
	keep sampleid suppid seq2 weekend wts_m sex dhh_age
		/*red_meat_wtg lnchn_wtg*/ nts_sds_wtg lgmes_wtg milk_wtg
		/*red_meat_wtg2 lnchn_wtg2*/ nts_sds_wtg2 lgmes_wtg2 milk_wtg2;
run;
/*17,921 obs*/

proc means data=rs2_50_food_nci; var milk_wtg2; run;

/*Check red meat intake (obs) for males*/
/*data a_m; set rs2_50_food_nci; if sex=0; run;
proc means data=a_m; var red_meat_wtg; run;

/*Check red meat intake (obs) for females*/
/*data a_f; set rs2_50_food_nci; if sex=1; run;
proc means data=a_f; var red_meat_wtg; run;

/******************************************************************************/
/* RS2 -> Replace 25% of dairy with nuts, seeds, and legumes (milk w/ soy bev)*/
/******************************************************************************/

/************************************/
/* Conduct replacements - g of food */
/************************************/

/*Milk is part of dairy, but soybev is not part of nsl because ratios for nsl were generated using this variable (which did not include soy bev).
  So, a new variable for original amount of nsl consumed (g), including soybev, was created -> nsl_wtg_w_soy. Soybev2 is included in nsl_wtg2.*/

data rs2_25;
	set baseline_final;

/*If the inividual consumed dairy, cut that in half*/
	if dairy_wtg ne . then dairy_wtg2=dairy_wtg-(dairy_wtg*0.25);
	if milk_wtg ne . then milk_wtg2=milk_wtg-(milk_wtg*0.25);
	if cheese_wtg ne . then cheese_wtg2=cheese_wtg-(cheese_wtg*0.25);
	if yghrt_wtg ne . then yghrt_wtg2=yghrt_wtg-(yghrt_wtg*0.25);
	if cream_wtg ne . then cream_wtg2=cream_wtg-(cream_wtg*0.25);
	if butr_wtg ne . then butr_wtg2=butr_wtg-(butr_wtg*0.25);
	if frzn_wtg ne . then frzn_wtg2=frzn_wtg-(frzn_wtg*0.25);

/*If the individual consumed dairy AND nuts OR seeds OR legumes OR tofu*/
	/*Milk*/
	if milk_wtg ne . and soybev_wtg ne . then soybev_wtg2=milk_wtg*0.25;
	/*Cheese*/	
	if cheese_wtg ne . and nuts_wtg ne . then nuts_cheese_wtg2=cheese_wtg*0.25*nuts_pcnt;		
	if cheese_wtg ne . and seeds_wtg ne . then seeds_cheese_wtg2=cheese_wtg*0.25*seeds_pcnt;	
	if cheese_wtg ne . and lgmes_wtg ne . then lgmes_cheese_wtg2=cheese_wtg*0.25*lgmes_pcnt;
	if cheese_wtg ne . and tofu_wtg ne . then tofu_cheese_wtg2=cheese_wtg*0.25*tofu_pcnt;	
	/*Yoghurt*/
	if yghrt_wtg ne . and nuts_wtg ne . then nuts_yghrt_wtg2=yghrt_wtg*0.25*nuts_pcnt;	
	if yghrt_wtg ne . and seeds_wtg ne . then seeds_yghrt_wtg2=yghrt_wtg*0.25*seeds_pcnt;	
	if yghrt_wtg ne . and lgmes_wtg ne . then lgmes_yghrt_wtg2=yghrt_wtg*0.25*lgmes_pcnt;	
	if yghrt_wtg ne . and tofu_wtg ne . then tofu_yghrt_wtg2=yghrt_wtg*0.25*tofu_pcnt;
	/*Cream*/
	if cream_wtg ne . and nuts_wtg ne . then nuts_cream_wtg2=cream_wtg*0.25*nuts_pcnt;	
	if cream_wtg ne . and seeds_wtg ne . then seeds_cream_wtg2=cream_wtg*0.25*seeds_pcnt;	
	if cream_wtg ne . and lgmes_wtg ne . then lgmes_cream_wtg2=cream_wtg*0.25*lgmes_pcnt;	
	if cream_wtg ne . and tofu_wtg ne . then tofu_cream_wtg2=cream_wtg*0.25*tofu_pcnt;	
	/*Butter*/
	if butr_wtg ne . and nuts_wtg ne . then nuts_butr_wtg2=butr_wtg*0.25*nuts_pcnt;
	if butr_wtg ne . and seeds_wtg ne . then seeds_butr_wtg2=butr_wtg*0.25*seeds_pcnt;	
	if butr_wtg ne . and lgmes_wtg ne . then lgmes_butr_wtg2=butr_wtg*0.25*lgmes_pcnt;	
	if butr_wtg ne . and tofu_wtg ne . then tofu_butr_wtg2=butr_wtg*0.25*tofu_pcnt;
	/*Frozen dairy*/
	if frzn_wtg ne . and nuts_wtg ne . then nuts_frzn_wtg2=frzn_wtg*0.25*nuts_pcnt;
	if frzn_wtg ne . and seeds_wtg ne . then seeds_frzn_wtg2=frzn_wtg*0.25*seeds_pcnt;
	if frzn_wtg ne . and lgmes_wtg ne . then lgmes_frzn_wtg2=frzn_wtg*0.25*lgmes_pcnt;
	if frzn_wtg ne . and tofu_wtg ne . then tofu_frzn_wtg2=frzn_wtg*0.25*tofu_pcnt;		

/*If the individual consumed nuts OR seeds OR legumes OR tofu BUT NOT dairy*/
	if dairy_wtg=. and nuts_wtg ne . then nuts_wtg2=nuts_wtg;
	if dairy_wtg=. and seeds_wtg ne . then seeds_wtg2=seeds_wtg;
	if dairy_wtg=. and lgmes_wtg ne . then lgmes_wtg2=lgmes_wtg;
	if dairy_wtg=. and tofu_wtg ne . then tofu_wtg2=tofu_wtg;
	if milk_wtg=. and soybev_wtg ne . then soybev_wtg2=soybev_wtg;

/*If the individual did not originally consume dairy, set to 0*/
	if dairy_wtg=. then dairy_wtg=0;
	if milk_wtg=. then milk_wtg=0;
	if cheese_wtg=. then cheese_wtg=0;
	if yghrt_wtg=. then yghrt_wtg=0;
	if cream_wtg=. then cream_wtg=0;
	if butr_wtg=. then butr_wtg=0;
	if frzn_wtg=. then frzn_wtg=0;

/*If the individual did not originally consume nsl, set to 0*/
	if nsl_wtg=. then nsl_wtg=0;	
	if nuts_wtg=. then nuts_wtg=0;	
	if seeds_wtg=. then seeds_wtg=0;	
	if lgmes_wtg=. then lgmes_wtg=0;	
	if tofu_wtg=. then tofu_wtg=0;
	if soybev_wtg=. then soybev_wtg=0;	
	
/*Set missing values post-replacement to 0*/
	if milk_wtg2=. then milk_wtg2=0;
	if cheese_wtg2=. then cheese_wtg2=0;	
	if yghrt_wtg2=. then yghrt_wtg2=0;	
	if cream_wtg2=. then cream_wtg2=0;
	if butr_wtg2=. then butr_wtg2=0;
	if frzn_wtg2=. then frzn_wtg2=0;
			
	if nuts_wtg2=. then nuts_wtg2=0;	
	if seeds_wtg2=. then seeds_wtg2=0;	
	if lgmes_wtg2=. then lgmes_wtg2=0;	
	if tofu_wtg2=. then tofu_wtg2=0;
	if soybev_wtg2=. then soybev_wtg2=0;

	/*if nuts_milk_wtg2=. then nuts_milk_wtg2=0;
	if seeds_milk_wtg2=. then seeds_milk_wtg2=0;
	if lgmes_milk_wtg2=. then lgmes_milk_wtg2=0;
	if tofu_milk_wtg2=. then tofu_milk_wtg2=0;*/

	if nuts_cheese_wtg2=. then nuts_cheese_wtg2=0;
	if seeds_cheese_wtg2=. then seeds_cheese_wtg2=0;
	if lgmes_cheese_wtg2=. then lgmes_cheese_wtg2=0;
	if tofu_cheese_wtg2=. then tofu_cheese_wtg2=0;
	
	if nuts_yghrt_wtg2=. then nuts_yghrt_wtg2=0;
	if seeds_yghrt_wtg2=. then seeds_yghrt_wtg2=0;
	if lgmes_yghrt_wtg2=. then lgmes_yghrt_wtg2=0;
	if tofu_yghrt_wtg2=. then tofu_yghrt_wtg2=0;

	if nuts_cream_wtg2=. then nuts_cream_wtg2=0;
	if seeds_cream_wtg2=. then seeds_cream_wtg2=0;
	if lgmes_cream_wtg2=. then lgmes_cream_wtg2=0;
	if tofu_cream_wtg2=. then tofu_cream_wtg2=0;

	if nuts_butr_wtg2=. then nuts_butr_wtg2=0;
	if seeds_butr_wtg2=. then seeds_butr_wtg2=0;
	if lgmes_butr_wtg2=. then lgmes_butr_wtg2=0;
	if tofu_butr_wtg2=. then tofu_butr_wtg2=0;

	if nuts_frzn_wtg2=. then nuts_frzn_wtg2=0;
	if seeds_frzn_wtg2=. then seeds_frzn_wtg2=0;
	if lgmes_frzn_wtg2=. then lgmes_frzn_wtg2=0;
	if tofu_frzn_wtg2=. then tofu_frzn_wtg2=0;

/*Later we have to account for other foods, set to 0 here*/
	if meat_wtg=. then meat_wtg=0;											
	if beef_wtg=. then beef_wtg=0;
	if lamb_wtg=. then lamb_wtg=0;
	if pork_wtg=. then pork_wtg=0;
	if lnchn_wtg=. then lnchn_wtg=0;
	if other_wtg=. then other_wtg=0;

/*If the individual consumed dairy BUT NOT nuts OR seeds OR legumes OR tofu, use ratios for overall sample*/
	if milk_wtg ne 0 and soybev_wtg=0 then soybev_wtg2=milk_wtg*0.25;
	if dairy_wtg ne 0 and nsl_wtg=0 then nuts_wtg2=/*(milk_wtg*0.301588528/2)+*/(cheese_wtg*0.301588528*0.25)+(yghrt_wtg*0.301588528*0.25)+(cream_wtg*0.301588528*0.25)+(butr_wtg*0.301588528*0.25)+(frzn_wtg*0.301588528*0.25);
	if dairy_wtg ne 0 and nsl_wtg=0 then seeds_wtg2=/*(milk_wtg*0.03540598/2)+*/(cheese_wtg*0.03540598*0.25)+(yghrt_wtg*0.03540598*0.25)+(cream_wtg*0.03540598*0.25)+(butr_wtg*0.03540598*0.25)+(frzn_wtg*0.03540598*0.25); 
	if dairy_wtg ne 0 and nsl_wtg=0 then lgmes_wtg2=/*(milk_wtg*0.595355613/2)+*/(cheese_wtg*0.595355613*0.25)+(yghrt_wtg*0.595355613*0.25)+(cream_wtg*0.595355613*0.25)+(butr_wtg*0.595355613*0.25)+(frzn_wtg*0.595355613*0.25); 
	if dairy_wtg ne 0 and nsl_wtg=0 then tofu_wtg2=/*(milk_wtg*0.067649879/2)+*/(cheese_wtg*0.067649879*0.25)+(yghrt_wtg*0.067649879*0.25)+(cream_wtg*0.067649879*0.25)+(butr_wtg*0.067649879*0.25)+(frzn_wtg*0.067649879*0.25); 

/*Create one variable for nuts, seeds, and legumes weight post-replacement, accounting for g of nsl at baseline*/
	if milk_wtg ne 0 and soybev_wtg ne 0 then soybev_wtg2=soybev_wtg+soybev_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then nuts_wtg2=nuts_wtg+/*nuts_milk_wtg2+*/nuts_cheese_wtg2+nuts_yghrt_wtg2+nuts_cream_wtg2+nuts_butr_wtg2+nuts_frzn_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then seeds_wtg2=seeds_wtg+/*seeds_milk_wtg2+*/seeds_cheese_wtg2+seeds_yghrt_wtg2+seeds_cream_wtg2+seeds_butr_wtg2+seeds_frzn_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then lgmes_wtg2=lgmes_wtg+/*lgmes_milk_wtg2+*/lgmes_cheese_wtg2+lgmes_yghrt_wtg2+lgmes_cream_wtg2+lgmes_butr_wtg2+lgmes_frzn_wtg2;
	if dairy_wtg ne 0 and nsl_wtg ne 0 then tofu_wtg2=tofu_wtg+/*tofu_milk_wtg2+*/tofu_cheese_wtg2+tofu_yghrt_wtg2+tofu_cream_wtg2+tofu_butr_wtg2+tofu_frzn_wtg2;

/*Create variables for total dairy and total nsl g post-replacement*/
/*Note that milk_wtg2+cheese_wtg2+yghrt_wtg2+cream_wtg2+butr_wtg2+frzn_wtg2 (i.e., dairy_wtg2) should = nsl_wtg2 - nsl_wtg*/		
	dairy_wtg2=milk_wtg2+cheese_wtg2+yghrt_wtg2+cream_wtg2+butr_wtg2+frzn_wtg2;
	nsl_wtg2=nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg2;	

	diet_wtg=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+soybev_wtg;
	diet_wtg2=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+milk_wtg2+cheese_wtg2+yghrt_wtg2+cream_wtg2+butr_wtg2+frzn_wtg2+other_wtg+nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg2;

/*This is a test to see if we are accounting for ALL foods (compare to fsddwtg)*/
	fsddwtg_chk=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+soybev_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg;

/*Create variable for original g of nuts, seeds, and legumes consumed including soybev*/
	nsl_wtg_w_soy=nsl_wtg+soybev_wtg;

/*To ensure math checks out by hand, just keep relevant variables*/
/*keep sampleid fsddwtg fsddwtg_chk milk_wtg cheese_wtg yghrt_wtg cream_wtg butr_wtg frzn_wtg nsl_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg soybev_wtg	 
	 milk_wtg2 cheese_wtg2 yghrt_wtg2 cream_wtg2 butr_wtg2 frzn_wtg2 nsl_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2 soybev_wtg2
	 nuts_cheese_wtg2 nuts_yghrt_wtg2 nuts_cream_wtg2 nuts_butr_wtg2 nuts_frzn_wtg2
	 seeds_cheese_wtg2 seeds_yghrt_wtg2 seeds_cream_wtg2 seeds_butr_wtg2 seeds_frzn_wtg2
	 lgmes_cheese_wtg2 lgmes_yghrt_wtg2 lgmes_cream_wtg2 lgmes_butr_wtg2 lgmes_frzn_wtg2
	 tofu_cheese_wtg2 tofu_yghrt_wtg2 tofu_cream_wtg2 tofu_butr_wtg2 tofu_frzn_wtg2
	 nuts_pcnt seeds_pcnt lgmes_pcnt tofu_pcnt
	 dairy_wtg nsl_wtg dairy_wtg2 nsl_wtg2
	 nsl_wtg_w_soy;

	 /*nuts_milk_wtg2 seeds_milk_wtg2 lgmes_milk_wtg2 tofu_milk_wtg2*/ 

run;
/*17,921 observations (Master Files)*/
		
/*Preliminary results (g)*/
proc means n nmiss mean min max data=rs2_25;
	var milk_wtg milk_wtg2 cheese_wtg cheese_wtg2 yghrt_wtg yghrt_wtg2 cream_wtg cream_wtg2 butr_wtg butr_wtg2 frzn_wtg frzn_wtg2
	nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2 soybev_wtg soybev_wtg2
	diet_wtg diet_wtg2;
run;

/************************************/
/* Conduct replacements - GHGE 		*/
/************************************/
data rs2_25_ghge;
	set rs2_25;

/*If the respondent consumed dairy, simply divide ghge of g of meat originally consumed in half*/
	if milk_wtg ne 0 and milk_co2eq ne . then milk_co2eq2=milk_co2eq-(milk_co2eq*0.25);
	if cheese_wtg ne 0 and cheese_co2eq ne . then cheese_co2eq2=cheese_co2eq-(cheese_co2eq*0.25);
	if yghrt_wtg ne 0 and yghrt_co2eq ne . then yghrt_co2eq2=yghrt_co2eq-(yghrt_co2eq*0.25);
	if cream_wtg ne 0 and cream_co2eq ne . then cream_co2eq2=cream_co2eq-(cream_co2eq*0.25);
	if butr_wtg ne 0 and butr_co2eq ne . then butr_co2eq2=butr_co2eq-(butr_co2eq*0.25);
	if frzn_wtg ne 0 and frzn_co2eq ne . then frzn_co2eq2=frzn_co2eq-(frzn_co2eq*0.25);

/*For respondents that originally consumed nsl, multiply unique ghge based on their nsl consumption profile by g of nsl replaced; then, add this to original ghge
for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl)*/
	if nuts_wtg ne 0 and unq_nuts_co2eq ne . then nuts_co2eq2=nuts_co2eq+(unq_nuts_co2eq*((nuts_wtg2-nuts_wtg)/1000));
	if seeds_wtg ne 0 and unq_seeds_co2eq ne . then seeds_co2eq2=seeds_co2eq+(unq_seeds_co2eq*((seeds_wtg2-seeds_wtg)/1000));
	if lgmes_wtg ne 0 and unq_lgmes_co2eq ne . then lgmes_co2eq2=lgmes_co2eq+(unq_lgmes_co2eq*((lgmes_wtg2-lgmes_wtg)/1000));
	if tofu_wtg ne 0 and unq_tofu_co2eq ne . then tofu_co2eq2=tofu_co2eq+(unq_tofu_co2eq*((tofu_wtg2-tofu_wtg)/1000));
	if soybev_wtg ne 0 and unq_soybev_co2eq ne . then soybev_co2eq2=soybev_co2eq+(unq_soybev_co2eq*((soybev_wtg2-soybev_wtg)/1000));											

/*For respodents that did not originally consume dairy, ghge=0 after replacement*/
	if milk_wtg=0 then milk_co2eq2=0;
	if cheese_wtg=0 then cheese_co2eq2=0;
	if yghrt_wtg=0 then yghrt_co2eq2=0;
	if cream_wtg=0 then cream_co2eq2=0;
	if butr_wtg=0 then butr_co2eq2=0;
	if frzn_wtg=0 then frzn_co2eq2=0;

/*For respondents that did not originally consume nsl, use a weighted average ghge*/
/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_co2eq2=2.303442774*(nuts_wtg2/1000);
	if seeds_wtg=0 then seeds_co2eq2=0.883544384*(seeds_wtg2/1000);
	if lgmes_wtg=0 then lgmes_co2eq2=1.388278602*(lgmes_wtg2/1000);
	if tofu_wtg=0 then tofu_co2eq2=2.3616*(tofu_wtg2/1000);
	if soybev_wtg=0 then soybev_co2eq2=0.379125733*(tofu_wtg2/1000);

/*Setting missing values to 0 here*/
	if milk_co2eq=. then milk_co2eq=0;
	if cheese_co2eq=. then cheese_co2eq=0;
	if yghrt_co2eq=. then yghrt_co2eq=0;
	if cream_co2eq=. then cream_co2eq=0;
	if butr_co2eq=. then butr_co2eq=0;
	if frzn_co2eq=. then frzn_co2eq=0;
	if nuts_co2eq=. then nuts_co2eq=0;
	if seeds_co2eq=. then seeds_co2eq=0;
	if lgmes_co2eq=. then lgmes_co2eq=0;
	if tofu_co2eq=. then tofu_co2eq=0;
	if soybev_co2eq=. then soybev_co2eq=0;
		
	if milk_co2eq2=. then milk_co2eq2=0;
	if cheese_co2eq2=. then cheese_co2eq2=0;
	if yghrt_co2eq2=. then yghrt_co2eq2=0;
	if cream_co2eq2=. then cream_co2eq2=0;
	if butr_co2eq2=. then butr_co2eq2=0;
	if frzn_co2eq2=. then frzn_co2eq2=0;
	if nuts_co2eq2=. then nuts_co2eq2=0;
	if seeds_co2eq2=. then seeds_co2eq2=0;
	if lgmes_co2eq2=. then lgmes_co2eq2=0;
	if soybev_co2eq2=. then soybev_co2eq2=0;

	/*Setting missing values to 0 for other foods here*/
	if beef_co2eq=. then beef_co2eq=0;
	if lamb_co2eq=. then lamb_co2eq=0;
	if pork_co2eq=. then pork_co2eq=0;
	if lnchn_co2eq=. then lnchn_co2eq=0;
	if other_co2eq=. then other_co2eq=0;

	/*Create variables for total dairy and total nsl ghge pre- and post-replacement*/
	tot_dairy_co2eq=milk_co2eq+cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq;
	tot_dairy_co2eq2=milk_co2eq2+cheese_co2eq2+yghrt_co2eq2+cream_co2eq2+butr_co2eq2+frzn_co2eq2;
	tot_nsl_co2eq=nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+soybev_co2eq;
	tot_nsl_co2eq2=nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+soybev_co2eq2;
	tot_meat_co2eq=beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq;

	/*Create variables for total ghge pre- and post-replacement*/
	tot_co2eq=milk_co2eq+cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+other_co2eq+nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+soybev_co2eq+
	beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq;
	tot_co2eq2=milk_co2eq2+cheese_co2eq2+yghrt_co2eq2+cream_co2eq2+butr_co2eq2+frzn_co2eq2+nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+soybev_co2eq2+
	beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq+other_co2eq;

	/*Create variables for CO2-eq/1000 kcal*/
	if fsddekc ne 0 then tot_co2eq_kcal=(tot_co2eq/fsddekc)*1000;
	if fsddekc ne 0 then tot_co2eq2_kcal=(tot_co2eq2/fsddekc)*1000;

	/*keep sampleid fsddwtg fsddwtg_chk milk_wtg cheese_wtg yghrt_wtg cream_wtg butr_wtg frzn_wtg nsl_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg soybev_wtg	 
	 milk_wtg2 cheese_wtg2 yghrt_wtg2 cream_wtg2 butr_wtg2 frzn_wtg2 nsl_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2 soybev_wtg2
	 nuts_cheese_wtg2 nuts_yghrt_wtg2 nuts_cream_wtg2 nuts_butr_wtg2 nuts_frzn_wtg2
	 seeds_cheese_wtg2 seeds_yghrt_wtg2 seeds_cream_wtg2 seeds_butr_wtg2 seeds_frzn_wtg2
	 lgmes_cheese_wtg2 lgmes_yghrt_wtg2 lgmes_cream_wtg2 lgmes_butr_wtg2 lgmes_frzn_wtg2
	 tofu_cheese_wtg2 tofu_yghrt_wtg2 tofu_cream_wtg2 tofu_butr_wtg2 tofu_frzn_wtg2
	 nuts_pcnt seeds_pcnt lgmes_pcnt tofu_pcnt
	 dairy_wtg nsl_wtg dairy_wtg2 nsl_wtg2
	 nsl_wtg_w_soy
	milk_co2eq cheese_co2eq yghrt_co2eq cream_co2eq butr_co2eq frzn_co2eq nuts_co2eq seeds_co2eq lgmes_co2eq tofu_co2eq soybev_co2eq
	milk_co2eq2 cheese_co2eq2 yghrt_co2eq2 cream_co2eq2 butr_co2eq2 frzn_co2eq2 nuts_co2eq2 seeds_co2eq2 lgmes_co2eq2 tofu_co2eq2 soybev_co2eq2
	unq_nuts_co2eq unq_seeds_co2eq unq_lgmes_co2eq unq_tofu_co2eq
	tot_dairy_co2eq tot_dairy_co2eq2 tot_nsl_co2eq tot_nsl_co2eq2 tot_meat_co2eq;*/

run;
/*17,921 observations (Master Files)*/

/*Preliminary results (ghge)*/
proc means n nmiss mean min max data=rs2_25_ghge;	
	var milk_co2eq milk_co2eq2 cheese_co2eq cheese_co2eq2 yghrt_co2eq yghrt_co2eq2 cream_co2eq cream_co2eq2 butr_co2eq butr_co2eq2 frzn_co2eq frzn_co2eq2
		nuts_co2eq nuts_co2eq2 seeds_co2eq seeds_co2eq2 lgmes_co2eq lgmes_co2eq2 tofu_co2eq tofu_co2eq2
		tot_dairy_co2eq tot_dairy_co2eq2 tot_nsl_co2eq tot_nsl_co2eq2 tot_co2eq tot_co2eq2;
run;	

/************************************/
/* Conduct replacements - Nutrients */
/************************************/

/*Note that the same method for calculating ghge is used here for nutrients*/

data rs2_25_nutr;
	set rs2_25_ghge;

/*If the respondent consumed dairy, simply divide intake of nutrients originally consumed from dairy in half*/
/*Alternatively, multiply unique ekc based on their meat consumption profile by g of meat after replacement*/
/*Note that these come out to the same thing*/
	/*Energy*/					
		if milk_wtg ne 0 and milk_ekc ne . then milk_ekc2=milk_ekc-(milk_ekc*0.25);	
		if cheese_wtg ne 0 and cheese_ekc ne . then cheese_ekc2=cheese_ekc-(cheese_ekc*0.25);	
		if yghrt_wtg ne 0 and yghrt_ekc ne . then yghrt_ekc2=yghrt_ekc-(yghrt_ekc*0.25);		
		if cream_wtg ne 0 and cream_ekc ne . then cream_ekc2=cream_ekc-(cream_ekc*0.25);
		if butr_wtg ne 0 and butr_ekc ne . then butr_ekc2=butr_ekc-(butr_ekc*0.25);
		if frzn_wtg ne 0 and frzn_ekc ne . then frzn_ekc2=frzn_ekc-(frzn_ekc*0.25);	
	/*Sugar*/
		if milk_wtg ne 0 and milk_sug ne . then milk_sug2=milk_sug-(milk_sug*0.25);		
		if cheese_wtg ne 0 and cheese_sug ne . then cheese_sug2=cheese_sug-(cheese_sug*0.25);		
		if yghrt_wtg ne 0 and yghrt_sug ne . then yghrt_sug2=yghrt_sug-(yghrt_sug*0.25);		
		if cream_wtg ne 0 and cream_sug ne . then cream_sug2=cream_sug-(cream_sug*0.25);		
		if butr_wtg ne 0 and butr_sug ne . then butr_sug2=butr_sug-(butr_sug*0.25);		
		if frzn_wtg ne 0 and frzn_sug ne . then frzn_sug2=frzn_sug-(frzn_sug*0.25);		
	/*Saturated fat*/
		if milk_wtg ne 0 and milk_sat ne . then milk_sat2=milk_sat-(milk_sat*0.25);		
		if cheese_wtg ne 0 and cheese_sat ne . then cheese_sat2=cheese_sat-(cheese_sat*0.25);		
		if yghrt_wtg ne 0 and yghrt_sat ne . then yghrt_sat2=yghrt_sat-(yghrt_sat*0.25);		
		if cream_wtg ne 0 and cream_sat ne . then cream_sat2=cream_sat-(cream_sat*0.25);		
		if butr_wtg ne 0 and butr_sat ne . then butr_sat2=butr_sat-(butr_sat*0.25);		
		if frzn_wtg ne 0 and frzn_sat ne . then frzn_sat2=frzn_sat-(frzn_sat*0.25);		
	/*Protein*/			
		if milk_wtg ne 0 and milk_pro ne . then milk_pro2=milk_pro-(milk_pro*0.25);		
		if cheese_wtg ne 0 and cheese_pro ne . then cheese_pro2=cheese_pro-(cheese_pro*0.25);		
		if yghrt_wtg ne 0 and yghrt_pro ne . then yghrt_pro2=yghrt_pro-(yghrt_pro*0.25);		
		if cream_wtg ne 0 and cream_pro ne . then cream_pro2=cream_pro-(cream_pro*0.25);		
		if butr_wtg ne 0 and butr_pro ne . then butr_pro2=butr_pro-(butr_pro*0.25);		
		if frzn_wtg ne 0 and frzn_pro ne . then frzn_pro2=frzn_pro-(frzn_pro*0.25);			
	/*Vitamin D*/			
		if milk_wtg ne 0 and milk_vitD ne . then milk_vitD2=milk_vitD-(milk_vitD*0.25);		
		if cheese_wtg ne 0 and cheese_vitD ne . then cheese_vitD2=cheese_vitD-(cheese_vitD*0.25);		
		if yghrt_wtg ne 0 and yghrt_vitD ne . then yghrt_vitD2=yghrt_vitD-(yghrt_vitD*0.25);		
		if cream_wtg ne 0 and cream_vitD ne . then cream_vitD2=cream_vitD-(cream_vitD*0.25);		
		if butr_wtg ne 0 and butr_vitD ne . then butr_vitD2=butr_vitD-(butr_vitD*0.25);		
		if frzn_wtg ne 0 and frzn_vitD ne . then frzn_vitD2=frzn_vitD-(frzn_vitD*0.25);		
	/*Calcium*/	
		if milk_wtg ne 0 and milk_ca ne . then milk_ca2=milk_ca-(milk_ca*0.25);		
		if cheese_wtg ne 0 and cheese_ca ne . then cheese_ca2=cheese_ca-(cheese_ca*0.25);		
		if yghrt_wtg ne 0 and yghrt_ca ne . then yghrt_ca2=yghrt_ca-(yghrt_ca*0.25);		
		if cream_wtg ne 0 and cream_ca ne . then cream_ca2=cream_ca-(cream_ca*0.25);		
		if butr_wtg ne 0 and butr_ca ne . then butr_ca2=butr_ca-(butr_ca*0.25);		
		if frzn_wtg ne 0 and frzn_ca ne . then frzn_ca2=frzn_ca-(frzn_ca*0.25);			
	/*Iron*/				
		if milk_wtg ne 0 and milk_fe ne . then milk_fe2=milk_fe-(milk_fe*0.25);		
		if cheese_wtg ne 0 and cheese_fe ne . then cheese_fe2=cheese_fe-(cheese_fe*0.25);		
		if yghrt_wtg ne 0 and yghrt_fe ne . then yghrt_fe2=yghrt_fe-(yghrt_fe*0.25);		
		if cream_wtg ne 0 and cream_fe ne . then cream_fe2=cream_fe-(cream_fe*0.25);		
		if butr_wtg ne 0 and butr_fe ne . then butr_fe2=butr_fe-(butr_fe*0.25);		
		if frzn_wtg ne 0 and frzn_fe ne . then frzn_fe2=frzn_fe-(frzn_fe*0.25);		
	/*Sodium*/					
		if milk_wtg ne 0 and milk_na ne . then milk_na2=milk_na-(milk_na*0.25);		
		if cheese_wtg ne 0 and cheese_na ne . then cheese_na2=cheese_na-(cheese_na*0.25);		
		if yghrt_wtg ne 0 and yghrt_na ne . then yghrt_na2=yghrt_na-(yghrt_na*0.25);		
		if cream_wtg ne 0 and cream_na ne . then cream_na2=cream_na-(cream_na*0.25);		
		if butr_wtg ne 0 and butr_na ne . then butr_na2=butr_na-(butr_na*0.25);		
		if frzn_wtg ne 0 and frzn_na ne . then frzn_na2=frzn_na-(frzn_na*0.25);
	/*Potassium*/		
		if milk_wtg ne 0 and milk_k ne . then milk_k2=milk_k-(milk_k*0.25);		
		if cheese_wtg ne 0 and cheese_k ne . then cheese_k2=cheese_k-(cheese_k*0.25);		
		if yghrt_wtg ne 0 and yghrt_k ne . then yghrt_k2=yghrt_k-(yghrt_k*0.25);		
		if cream_wtg ne 0 and cream_k ne . then cream_k2=cream_k-(cream_k*0.25);		
		if butr_wtg ne 0 and butr_k ne . then butr_k2=butr_k-(butr_k*0.25);		
		if frzn_wtg ne 0 and frzn_k ne . then frzn_k2=frzn_k-(frzn_k*0.25);	
	/*Carbs*/
		if milk_wtg ne 0 and milk_carb ne . then milk_carb2=milk_carb-(milk_carb*0.25);		
		if cheese_wtg ne 0 and cheese_carb ne . then cheese_carb2=cheese_carb-(cheese_carb*0.25);		
		if yghrt_wtg ne 0 and yghrt_carb ne . then yghrt_carb2=yghrt_carb-(yghrt_carb*0.25);	
		if cream_wtg ne 0 and cream_carb ne . then cream_carb2=cream_carb-(cream_carb*0.25);		
		if butr_wtg ne 0 and butr_carb ne . then butr_carb2=butr_carb-(butr_carb*0.25);		
		if frzn_wtg ne 0 and frzn_carb ne . then frzn_carb2=frzn_carb-(frzn_carb*0.25);
	/*MUFAs*/		
		if milk_wtg ne 0 and milk_mufa ne . then milk_mufa2=milk_mufa-(milk_mufa*0.25);		
		if cheese_wtg ne 0 and cheese_mufa ne . then cheese_mufa2=cheese_mufa-(cheese_mufa*0.25);		
		if yghrt_wtg ne 0 and yghrt_mufa ne . then yghrt_mufa2=yghrt_mufa-(yghrt_mufa*0.25);		
		if cream_wtg ne 0 and cream_mufa ne . then cream_mufa2=cream_mufa-(cream_mufa*0.25);		
		if butr_wtg ne 0 and butr_mufa ne . then butr_mufa2=butr_mufa-(butr_mufa*0.25);		
		if frzn_wtg ne 0 and frzn_mufa ne . then frzn_mufa2=frzn_mufa-(frzn_mufa*0.25);
	/*PUFAs*/			
		if milk_wtg ne 0 and milk_pufa ne . then milk_pufa2=milk_pufa-(milk_pufa*0.25);				
		if cheese_wtg ne 0 and cheese_pufa ne . then cheese_pufa2=cheese_pufa-(cheese_pufa*0.25);		
		if yghrt_wtg ne 0 and yghrt_pufa ne . then yghrt_pufa2=yghrt_pufa-(yghrt_pufa*0.25);		
		if cream_wtg ne 0 and cream_pufa ne . then cream_pufa2=cream_pufa-(cream_pufa*0.25);		
		if butr_wtg ne 0 and butr_pufa ne . then butr_pufa2=butr_pufa-(butr_pufa*0.25);		
		if frzn_wtg ne 0 and frzn_pufa ne . then frzn_pufa2=frzn_pufa-(frzn_pufa*0.25);		

/*For respondents that originally consumed nsl, multiply unique ekc based on their nsl consumption profile by g of nsl replaced; then, add this to original ekc
for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl) (these come out to the same thing)*/
	/*Energy*/
		if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2=nuts_ekc+(unq_nuts_ekc*(nuts_wtg2-nuts_wtg)); 
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2=seeds_ekc+(unq_seeds_ekc*(seeds_wtg2-seeds_wtg));
		if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2=lgmes_ekc+(unq_lgmes_ekc*(lgmes_wtg2-lgmes_wtg));
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2=tofu_ekc+(unq_tofu_ekc*(tofu_wtg2-tofu_wtg));
		if soybev_wtg ne 0 and unq_soybev_ekc ne . then soybev_ekc2=soybev_ekc+(unq_soybev_ekc*(soybev_wtg2-soybev_wtg));
		/*if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2_v2=unq_nuts_ekc*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2_v2=unq_seeds_ekc*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2_v2=unq_lgmes_ekc*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2_v2=unq_tofu_ekc*tofu_wtg2;*/
	/*Sugar*/
		if nuts_wtg ne 0 and unq_nuts_sug ne . then nuts_sug2=unq_nuts_sug*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sug ne . then seeds_sug2=unq_seeds_sug*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sug ne . then lgmes_sug2=unq_lgmes_sug*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sug ne . then tofu_sug2=unq_tofu_sug*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_sug ne . then soybev_sug2=unq_soybev_sug*soybev_wtg2;	
		/*if nuts_wtg ne 0 and unq_nuts_sug ne . then nuts_sug2_v2=unq_nuts_sug*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sug ne . then seeds_sug2_v2=unq_seeds_sug*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sug ne . then lgmes_sug2_v2=unq_lgmes_sug*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sug ne . then tofu_sug2_v2=unq_tofu_sug*tofu_wtg2;*/
	/*Saturated fat*/
		if nuts_wtg ne 0 and unq_nuts_sat ne . then nuts_sat2=unq_nuts_sat*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sat ne . then seeds_sat2=unq_seeds_sat*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sat ne . then lgmes_sat2=unq_lgmes_sat*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sat ne . then tofu_sat2=unq_tofu_sat*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_sat ne . then soybev_sat2=unq_soybev_sat*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_sat ne . then nuts_sat2_v2=unq_nuts_sat*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sat ne . then seeds_sat2_v2=unq_seeds_sat*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sat ne . then lgmes_sat2_v2=unq_lgmes_sat*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sat ne . then tofu_sat2_v2=unq_tofu_sat*tofu_wtg2;*/	
	/*Protein*/
		if nuts_wtg ne 0 and unq_nuts_pro ne . then nuts_pro2=unq_nuts_pro*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pro ne . then seeds_pro2=unq_seeds_pro*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pro ne . then lgmes_pro2=unq_lgmes_pro*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pro ne . then tofu_pro2=unq_tofu_pro*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_pro ne . then soybev_pro2=unq_soybev_pro*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_pro ne . then nuts_pro2_v2=unq_nuts_pro*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pro ne . then seeds_pro2_v2=unq_seeds_pro*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pro ne . then lgmes_pro2_v2=unq_lgmes_pro*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pro ne . then tofu_pro2_v2=unq_tofu_pro*tofu_wtg2;*/
	/*Vitamin D*/
		if nuts_wtg ne 0 and unq_nuts_vitD ne . then nuts_vitD2=unq_nuts_vitD*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_vitD ne . then seeds_vitD2=unq_seeds_vitD*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_vitD ne . then lgmes_vitD2=unq_lgmes_vitD*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_vitD ne . then tofu_vitD2=unq_tofu_vitD*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_vitD ne . then soybev_vitD2=unq_soybev_vitD*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_vitD ne . then nuts_vitD2_v2=unq_nuts_vitD*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_vitD ne . then seeds_vitD2_v2=unq_seeds_vitD*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_vitD ne . then lgmes_vitD2_v2=unq_lgmes_vitD*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_vitD ne . then tofu_vitD2_v2=unq_tofu_vitD*tofu_wtg2;*/
	/*Calcium*/
		if nuts_wtg ne 0 and unq_nuts_ca ne . then nuts_ca2=unq_nuts_ca*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ca ne . then seeds_ca2=unq_seeds_ca*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ca ne . then lgmes_ca2=unq_lgmes_ca*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ca ne . then tofu_ca2=unq_tofu_ca*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_ca ne . then soybev_ca2=unq_soybev_ca*soybev_wtg2;								
		/*if nuts_wtg ne 0 and unq_nuts_ca ne . then nuts_ca2_v2=unq_nuts_ca*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ca ne . then seeds_ca2_v2=unq_seeds_ca*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ca ne . then lgmes_ca2_v2=unq_lgmes_ca*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ca ne . then tofu_ca2_v2=unq_tofu_ca*tofu_wtg2;*/	
	/*Iron*/
		if nuts_wtg ne 0 and unq_nuts_fe ne . then nuts_fe2=unq_nuts_fe*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_fe ne . then seeds_fe2=unq_seeds_fe*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_fe ne . then lgmes_fe2=unq_lgmes_fe*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_fe ne . then tofu_fe2=unq_tofu_fe*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_fe ne . then soybev_fe2=unq_soybev_fe*soybev_wtg2;	
		/*if nuts_wtg ne 0 and unq_nuts_fe ne . then nuts_fe2_v2=unq_nuts_fe*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_fe ne . then seeds_fe2_v2=unq_seeds_fe*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_fe ne . then lgmes_fe2_v2=unq_lgmes_fe*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_fe ne . then tofu_fe2_v2=unq_tofu_fe*tofu_wtg2;*/
	/*Sodium*/
		if nuts_wtg ne 0 and unq_nuts_na ne . then nuts_na2=unq_nuts_na*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_na ne . then seeds_na2=unq_seeds_na*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_na ne . then lgmes_na2=unq_lgmes_na*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_na ne . then tofu_na2=unq_tofu_na*tofu_wtg2;
		if soybev_wtg ne 0 and unq_soybev_na ne . then soybev_na2=unq_soybev_na*soybev_wtg2;
		/*if nuts_wtg ne 0 and unq_nuts_na ne . then nuts_na2_v2=unq_nuts_na*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_na ne . then seeds_na2_v2=unq_seeds_na*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_na ne . then lgmes_na2_v2=unq_lgmes_na*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_na ne . then tofu_na2_v2=unq_tofu_na*tofu_wtg2;*/	
	/*Potassium*/
		if nuts_wtg ne 0 and unq_nuts_k ne . then nuts_k2=unq_nuts_k*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_k ne . then seeds_k2=unq_seeds_k*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_k ne . then lgmes_k2=unq_lgmes_k*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_k ne . then tofu_k2=unq_tofu_k*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_k ne . then soybev_k2=unq_soybev_k*soybev_wtg2;	
		/*if nuts_wtg ne 0 and unq_nuts_k ne . then nuts_k2_v2=unq_nuts_k*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_k ne . then seeds_k2_v2=unq_seeds_k*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_k ne . then lgmes_k2_v2=unq_lgmes_k*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_k ne . then tofu_k2_v2=unq_tofu_k*tofu_wtg2;*/	
	/*Carbs*/
		if nuts_wtg ne 0 and unq_nuts_carb ne . then nuts_carb2=unq_nuts_carb*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_carb ne . then seeds_carb2=unq_seeds_carb*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_carb ne . then lgmes_carb2=unq_lgmes_carb*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_carb ne . then tofu_carb2=unq_tofu_carb*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_carb ne . then soybev_carb2=unq_soybev_carb*soybev_wtg2;	
	/*MUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_mufa ne . then nuts_mufa2=unq_nuts_mufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_mufa ne . then seeds_mufa2=unq_seeds_mufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_mufa ne . then lgmes_mufa2=unq_lgmes_mufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_mufa ne . then tofu_mufa2=unq_tofu_mufa*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_mufa ne . then soybev_mufa2=unq_soybev_mufa*soybev_wtg2;	
	/*PUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_pufa ne . then nuts_pufa2=unq_nuts_pufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pufa ne . then seeds_pufa2=unq_seeds_pufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pufa ne . then lgmes_pufa2=unq_lgmes_pufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pufa ne . then tofu_pufa2=unq_tofu_pufa*tofu_wtg2;	
		if soybev_wtg ne 0 and unq_soybev_pufa ne . then soybev_pufa2=unq_soybev_pufa*soybev_wtg2;	

/*For respodents that did not originally consume dairy, nutrients=0 after replacement*/
	if milk_wtg=0 then milk_ekc2=0;	
	if milk_wtg=0 then milk_sug2=0;
	if milk_wtg=0 then milk_sat2=0;
	if milk_wtg=0 then milk_pro2=0;
	if milk_wtg=0 then milk_vitD2=0;
	if milk_wtg=0 then milk_ca2=0;
	if milk_wtg=0 then milk_fe2=0;
	if milk_wtg=0 then milk_na2=0;
	if milk_wtg=0 then milk_k2=0;
	if milk_wtg=0 then milk_carb2=0;
	if milk_wtg=0 then milk_mufa2=0;
	if milk_wtg=0 then milk_pufa2=0;
	
	if cheese_wtg=0 then cheese_ekc2=0;
	if cheese_wtg=0 then cheese_sug2=0;
	if cheese_wtg=0 then cheese_sat2=0;
	if cheese_wtg=0 then cheese_pro2=0;
	if cheese_wtg=0 then cheese_vitD2=0;
	if cheese_wtg=0 then cheese_ca2=0;
	if cheese_wtg=0 then cheese_fe2=0;
	if cheese_wtg=0 then cheese_na2=0;
	if cheese_wtg=0 then cheese_k2=0;
	if cheese_wtg=0 then cheese_carb2=0;
	if cheese_wtg=0 then cheese_mufa2=0;
	if cheese_wtg=0 then cheese_pufa2=0;
	
	if yghrt_wtg=0 then yghrt_ekc2=0;
	if yghrt_wtg=0 then yghrt_sug2=0;
	if yghrt_wtg=0 then yghrt_sat2=0;
	if yghrt_wtg=0 then yghrt_pro2=0;
	if yghrt_wtg=0 then yghrt_vitD2=0;
	if yghrt_wtg=0 then yghrt_ca2=0;
	if yghrt_wtg=0 then yghrt_fe2=0;
	if yghrt_wtg=0 then yghrt_na2=0;
	if yghrt_wtg=0 then yghrt_k2=0;
	if yghrt_wtg=0 then yghrt_carb2=0;
	if yghrt_wtg=0 then yghrt_mufa2=0;
	if yghrt_wtg=0 then yghrt_pufa2=0;
	
	if cream_wtg=0 then cream_ekc2=0;
	if cream_wtg=0 then cream_sug2=0;
	if cream_wtg=0 then cream_sat2=0;
	if cream_wtg=0 then cream_pro2=0;
	if cream_wtg=0 then cream_vitD2=0;
	if cream_wtg=0 then cream_ca2=0;
	if cream_wtg=0 then cream_fe2=0;
	if cream_wtg=0 then cream_na2=0;
	if cream_wtg=0 then cream_k2=0;
	if cream_wtg=0 then cream_carb2=0;
	if cream_wtg=0 then cream_mufa2=0;
	if cream_wtg=0 then cream_pufa2=0;

	if butr_wtg=0 then butr_ekc2=0;
	if butr_wtg=0 then butr_sug2=0;
	if butr_wtg=0 then butr_sat2=0;
	if butr_wtg=0 then butr_pro2=0;
	if butr_wtg=0 then butr_vitD2=0;
	if butr_wtg=0 then butr_ca2=0;
	if butr_wtg=0 then butr_fe2=0;
	if butr_wtg=0 then butr_na2=0;
	if butr_wtg=0 then butr_k2=0;
	if butr_wtg=0 then butr_carb2=0;
	if butr_wtg=0 then butr_mufa2=0;
	if butr_wtg=0 then butr_pufa2=0;

	if frzn_wtg=0 then frzn_ekc2=0;
	if frzn_wtg=0 then frzn_sug2=0;
	if frzn_wtg=0 then frzn_sat2=0;
	if frzn_wtg=0 then frzn_pro2=0;
	if frzn_wtg=0 then frzn_vitD2=0;
	if frzn_wtg=0 then frzn_ca2=0;
	if frzn_wtg=0 then frzn_fe2=0;
	if frzn_wtg=0 then frzn_na2=0;
	if frzn_wtg=0 then frzn_k2=0;
	if frzn_wtg=0 then frzn_carb2=0;
	if frzn_wtg=0 then frzn_mufa2=0;
	if frzn_wtg=0 then frzn_pufa2=0;

/*For respondents that did not originally consume nsl, use a weighted average for nutrients*/
/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_ekc2=6.068735152*nuts_wtg2;
	if nuts_wtg=0 then nuts_sug2=0.023412133*nuts_wtg2;		/*Note that this is weighted avg. for FREE SUGARS*/
	if nuts_wtg=0 then nuts_sat2=0.078223051*nuts_wtg2;
	if nuts_wtg=0 then nuts_pro2=0.189748537*nuts_wtg2;
	if nuts_wtg=0 then nuts_vitD2=0*nuts_wtg2;
	if nuts_wtg=0 then nuts_ca2=1.047177739*nuts_wtg2;
	if nuts_wtg=0 then nuts_fe2=0.028762549*nuts_wtg2;
	if nuts_wtg=0 then nuts_na2=1.538556973*nuts_wtg2;
	if nuts_wtg=0 then nuts_k2=5.879183898*nuts_wtg2;
	if nuts_wtg=0 then nuts_carb2=0.208693214*nuts_wtg2;
	if nuts_wtg=0 then nuts_mufa2=0.250425621*nuts_wtg2;
	if nuts_wtg=0 then nuts_pufa2=0.184819969*nuts_wtg2;

	if seeds_wtg=0 then seeds_ekc2=5.588623188*seeds_wtg2;
	if seeds_wtg=0 then seeds_sug2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_sat2=0.053096123*seeds_wtg2;
	if seeds_wtg=0 then seeds_pro2=0.212654067*seeds_wtg2;
	if seeds_wtg=0 then seeds_vitD2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_ca2=1.625144928*seeds_wtg2;
	if seeds_wtg=0 then seeds_fe2=0.060998279*seeds_wtg2;
	if seeds_wtg=0 then seeds_na2=0.780842391*seeds_wtg2;
	if seeds_wtg=0 then seeds_k2=7.510996377*seeds_wtg2;
	if seeds_wtg=0 then seeds_carb2=0.236999647*seeds_wtg2;
	if seeds_wtg=0 then seeds_mufa2=0.111621132*seeds_wtg2;
	if seeds_wtg=0 then seeds_pufa2=0.269852745*seeds_wtg2;

	if lgmes_wtg=0 then lgmes_ekc2=0.93228815*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sug2=0.003114783*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sat2=0.001913132*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pro2=0.057528201*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_vitD2=0*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_ca2=0.366772379*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_fe2=0.01791809*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_na2=1.035202046*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_k2=2.539577153*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_carb2=0.161040051*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_mufa2=0.003398607*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pufa2=0.004636307*lgmes_wtg2;

	if tofu_wtg=0 then tofu_ekc2=2.428236398*tofu_wtg2;
	if tofu_wtg=0 then tofu_sug2=0.000317073*tofu_wtg2;
	if tofu_wtg=0 then tofu_sat2=0.020709869*tofu_wtg2;
	if tofu_wtg=0 then tofu_pro2=0.227237148*tofu_wtg2;
	if tofu_wtg=0 then tofu_vitD2=0*tofu_wtg2;
	if tofu_wtg=0 then tofu_ca2=1.770863039*tofu_wtg2;
	if tofu_wtg=0 then tofu_fe2=0.032112383*tofu_wtg2;
	if tofu_wtg=0 then tofu_na2=6.259924953*tofu_wtg2;
	if tofu_wtg=0 then tofu_k2=1.671575985*tofu_wtg2;
	if tofu_wtg=0 then tofu_carb2=0.114113884*tofu_wtg2;
	if tofu_wtg=0 then tofu_mufa2=0.03100454*tofu_wtg2;
	if tofu_wtg=0 then tofu_pufa2=0.065414953*tofu_wtg2;

	if soybev_wtg=0 then soybev_ekc2=0.431954397*soybev_wtg2;
	if soybev_wtg=0 then soybev_sug2=0.032720554*soybev_wtg2;
	if soybev_wtg=0 then soybev_sat2=0.002055863*soybev_wtg2;
	if soybev_wtg=0 then soybev_pro2=0.025984365*soybev_wtg2;
	if soybev_wtg=0 then soybev_vitD2=0.0084*soybev_wtg2;
	if soybev_wtg=0 then soybev_ca2=1.232*soybev_wtg2;
	if soybev_wtg=0 then soybev_fe2=0.004219544*soybev_wtg2;
	if soybev_wtg=0 then soybev_na2=0.469218241*soybev_wtg2;
	if soybev_wtg=0 then soybev_k2=1.479*soybev_wtg2;
	if soybev_wtg=0 then soybev_carb2=0.049561564*soybev_wtg2;
	if soybev_wtg=0 then soybev_mufa2=0.003819218*soybev_wtg2;
	if soybev_wtg=0 then soybev_pufa2=0.00860228*soybev_wtg2;

/*Setting missing values to 0 here*/
	if milk_ekc=. then milk_ekc=0;	
	if milk_sug=. then milk_sug=0;
	if milk_sat=. then milk_sat=0;
	if milk_pro=. then milk_pro=0;
	if milk_vitD=. then milk_vitD=0;
	if milk_ca=. then milk_ca=0;
	if milk_fe=. then milk_fe=0;
	if milk_na=. then milk_na=0;
	if milk_k=. then milk_k=0;
	if milk_carb=. then milk_carb=0;
	if milk_mufa=. then milk_mufa=0;
	if milk_pufa=. then milk_pufa=0;
	
	if cheese_ekc=. then cheese_ekc=0;
	if cheese_sug=. then cheese_sug=0;
	if cheese_sat=. then cheese_sat=0;
	if cheese_pro=. then cheese_pro=0;
	if cheese_vitD=. then cheese_vitD=0;
	if cheese_ca=. then cheese_ca=0;
	if cheese_fe=. then cheese_fe=0;
	if cheese_na=. then cheese_na=0;
	if cheese_k=. then cheese_k=0;
	if cheese_carb=. then cheese_carb=0;
	if cheese_mufa=. then cheese_mufa=0;
	if cheese_pufa=. then cheese_pufa=0;
	
	if yghrt_ekc=. then yghrt_ekc=0;
	if yghrt_sug=. then yghrt_sug=0;
	if yghrt_sat=. then yghrt_sat=0;
	if yghrt_pro=. then yghrt_pro=0;
	if yghrt_vitD=. then yghrt_vitD=0;
	if yghrt_ca=. then yghrt_ca=0;
	if yghrt_fe=. then yghrt_fe=0;
	if yghrt_na=. then yghrt_na=0;
	if yghrt_k=. then yghrt_k=0;
	if yghrt_carb=. then yghrt_carb=0;
	if yghrt_mufa=. then yghrt_mufa=0;
	if yghrt_pufa=. then yghrt_pufa=0;
	
	if cream_ekc=. then cream_ekc=0;
	if cream_sug=. then cream_sug=0;
	if cream_sat=. then cream_sat=0;
	if cream_pro=. then cream_pro=0;
	if cream_vitD=. then cream_vitD=0;
	if cream_ca=. then cream_ca=0;
	if cream_fe=. then cream_fe=0;
	if cream_na=. then cream_na=0;
	if cream_k=. then cream_k=0;
	if cream_carb=. then cream_carb=0;
	if cream_mufa=. then cream_mufa=0;
	if cream_pufa=. then cream_pufa=0;

	if butr_ekc=. then butr_ekc=0;	
	if butr_sug=. then butr_sug=0;
	if butr_sat=. then butr_sat=0;
	if butr_pro=. then butr_pro=0;
	if butr_vitD=. then butr_vitD=0;
	if butr_ca=. then butr_ca=0;
	if butr_fe=. then butr_fe=0;
	if butr_na=. then butr_na=0;
	if butr_k=. then butr_k=0;
	if butr_carb=. then butr_carb=0;
	if butr_mufa=. then butr_mufa=0;
	if butr_pufa=. then butr_pufa=0;

	if frzn_ekc=. then frzn_ekc=0;	
	if frzn_sug=. then frzn_sug=0;
	if frzn_sat=. then frzn_sat=0;
	if frzn_pro=. then frzn_pro=0;
	if frzn_vitD=. then frzn_vitD=0;
	if frzn_ca=. then frzn_ca=0;
	if frzn_fe=. then frzn_fe=0;
	if frzn_na=. then frzn_na=0;
	if frzn_k=. then frzn_k=0;
	if frzn_carb=. then frzn_carb=0;
	if frzn_mufa=. then frzn_mufa=0;
	if frzn_pufa=. then frzn_pufa=0;

	if nuts_ekc=. then nuts_ekc=0;
	if nuts_sug=. then nuts_sug=0;
	if nuts_sat=. then nuts_sat=0;
	if nuts_pro=. then nuts_pro=0;
	if nuts_vitD=. then nuts_vitD=0;
	if nuts_ca=. then nuts_ca=0;
	if nuts_fe=. then nuts_fe=0;
	if nuts_na=. then nuts_na=0;
	if nuts_k=. then nuts_k=0;
	if nuts_carb=. then nuts_carb=0;
	if nuts_mufa=. then nuts_mufa=0;
	if nuts_pufa=. then nuts_pufa=0;

	if seeds_ekc=. then seeds_ekc=0;
	if seeds_sug=. then seeds_sug=0;
	if seeds_sat=. then seeds_sat=0;
	if seeds_pro=. then seeds_pro=0;
	if seeds_vitD=. then seeds_vitD=0;
	if seeds_ca=. then seeds_ca=0;
	if seeds_fe=. then seeds_fe=0;
	if seeds_na=. then seeds_na=0;
	if seeds_k=. then seeds_k=0;
	if seeds_carb=. then seeds_carb=0;
	if seeds_mufa=. then seeds_mufa=0;
	if seeds_pufa=. then seeds_pufa=0;

	if lgmes_ekc=. then lgmes_ekc=0;
	if lgmes_sug=. then lgmes_sug=0;
	if lgmes_sat=. then lgmes_sat=0;
	if lgmes_pro=. then lgmes_pro=0;
	if lgmes_vitD=. then lgmes_vitD=0;
	if lgmes_ca=. then lgmes_ca=0;
	if lgmes_fe=. then lgmes_fe=0;
	if lgmes_na=. then lgmes_na=0;
	if lgmes_k=. then lgmes_k=0;
	if lgmes_carb=. then lgmes_carb=0;
	if lgmes_mufa=. then lgmes_mufa=0;
	if lgmes_pufa=. then lgmes_pufa=0;

	if tofu_ekc=. then tofu_ekc=0;
	if tofu_sug=. then tofu_sug=0;
	if tofu_sat=. then tofu_sat=0;
	if tofu_pro=. then tofu_pro=0;
	if tofu_vitD=. then tofu_vitD=0;
	if tofu_ca=. then tofu_ca=0;
	if tofu_fe=. then tofu_fe=0;
	if tofu_na=. then tofu_na=0;
	if tofu_k=. then tofu_k=0;
	if tofu_carb=. then tofu_carb=0;
	if tofu_mufa=. then tofu_mufa=0;
	if tofu_pufa=. then tofu_pufa=0;

	if soybev_ekc=. then soybev_ekc=0;
	if soybev_sug=. then soybev_sug=0;
	if soybev_sat=. then soybev_sat=0;
	if soybev_pro=. then soybev_pro=0;
	if soybev_vitD=. then soybev_vitD=0;
	if soybev_ca=. then soybev_ca=0;
	if soybev_fe=. then soybev_fe=0;
	if soybev_na=. then soybev_na=0;
	if soybev_k=. then soybev_k=0;
	if soybev_carb=. then soybev_carb=0;
	if soybev_mufa=. then soybev_mufa=0;
	if soybev_pufa=. then soybev_pufa=0;

/*Setting missing values to 0 for other foods here*/
	if beef_ekc=. then beef_ekc=0;
	if beef_sug=. then beef_sug=0;
	if beef_sat=. then beef_sat=0;
	if beef_pro=. then beef_pro=0;
	if beef_vitD=. then beef_vitD=0;
	if beef_ca=. then beef_ca=0;
	if beef_fe=. then beef_fe=0;
	if beef_na=. then beef_na=0;
	if beef_k=. then beef_k=0;
	if beef_carb=. then beef_carb=0;
	if beef_mufa=. then beef_mufa=0;
	if beef_pufa=. then beef_pufa=0;

	if lamb_ekc=. then lamb_ekc=0;
	if lamb_sug=. then lamb_sug=0;
	if lamb_sat=. then lamb_sat=0;
	if lamb_pro=. then lamb_pro=0;
	if lamb_vitD=. then lamb_vitD=0;
	if lamb_ca=. then lamb_ca=0;
	if lamb_fe=. then lamb_fe=0;
	if lamb_na=. then lamb_na=0;
	if lamb_k=. then lamb_k=0;
	if lamb_carb=. then lamb_carb=0;
	if lamb_mufa=. then lamb_mufa=0;
	if lamb_pufa=. then lamb_pufa=0;

	if pork_ekc=. then pork_ekc=0;
	if pork_sug=. then pork_sug=0;
	if pork_sat=. then pork_sat=0;
	if pork_pro=. then pork_pro=0;
	if pork_vitD=. then pork_vitD=0;
	if pork_ca=. then pork_ca=0;
	if pork_fe=. then pork_fe=0;
	if pork_na=. then pork_na=0;
	if pork_k=. then pork_k=0;
	if pork_carb=. then pork_carb=0;
	if pork_mufa=. then pork_mufa=0;
	if pork_pufa=. then pork_pufa=0;

	if lnchn_ekc=. then lnchn_ekc=0;
	if lnchn_sug=. then lnchn_sug=0;
	if lnchn_sat=. then lnchn_sat=0;
	if lnchn_pro=. then lnchn_pro=0;
	if lnchn_vitD=. then lnchn_vitD=0;
	if lnchn_ca=. then lnchn_ca=0;
	if lnchn_fe=. then lnchn_fe=0;
	if lnchn_na=. then lnchn_na=0;
	if lnchn_k=. then lnchn_k=0;
	if lnchn_carb=. then lnchn_carb=0;
	if lnchn_mufa=. then lnchn_mufa=0;
	if lnchn_pufa=. then lnchn_pufa=0;

	if other_ekc=. then other_ekc=0;
	if other_sug=. then other_sug=0;
	if other_sat=. then other_sat=0;
	if other_pro=. then other_pro=0;
	if other_vitD=. then other_vitD=0;
	if other_ca=. then other_ca=0;
	if other_fe=. then other_fe=0;
	if other_na=. then other_na=0;
	if other_k=. then other_k=0;
	if other_carb=. then other_carb=0;
	if other_mufa=. then other_mufa=0;
	if other_pufa=. then other_pufa=0;

/*Variables for protein*/
	dairy_pro=milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro;
	nsl_pro=nuts_pro+seeds_pro+lgmes_pro+tofu_pro+soybev_pro;
	dairy_pro2=milk_pro2+cheese_pro2+yghrt_pro2+cream_pro2+butr_pro2+frzn_pro2;
	nsl_pro2=nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+soybev_pro2;
	meat_pro=beef_pro+lamb_pro+pork_pro+lnchn_pro;
/*Variables for energy*/
	dairy_ekc=milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc;
	nsl_ekc=nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	dairy_ekc2=milk_ekc2+cheese_ekc2+yghrt_ekc2+cream_ekc2+butr_ekc2+frzn_ekc2;
	nsl_ekc2=nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc2;
	meat_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc;
/*Variables for carbs*/
	dairy_carb=milk_carb+cheese_carb+yghrt_carb+cream_carb+butr_carb+frzn_carb;
	nsl_carb=nuts_carb+seeds_carb+lgmes_carb+tofu_carb+soybev_carb;
	dairy_carb2=milk_carb2+cheese_carb2+yghrt_carb2+cream_carb2+butr_carb2+frzn_carb2;
	nsl_carb2=nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb2;
	meat_carb=beef_carb+lamb_carb+pork_carb+lnchn_carb;

/*Variables for total energy intake*/
	diet_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc+nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	diet_ekc2=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+milk_ekc2+cheese_ekc2+yghrt_ekc2+cream_ekc2+butr_ekc2+frzn_ekc2+other_ekc+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc2;

/*keep sampleid milk_ekc cheese_ekc yghrt_ekc cream_ekc butr_ekc frzn_ekc milk_ekc2 cheese_ekc2 yghrt_ekc2 cream_ekc2 butr_ekc2 frzn_ekc2 	
	 nuts_ekc seeds_ekc lgmes_ekc tofu_ekc nuts_ekc2 seeds_ekc2 lgmes_ekc2 tofu_ekc2
	 milk_carb cheese_carb yghrt_carb cream_carb butr_carb frzn_carb milk_carb2 cheese_carb2 yghrt_carb2 cream_carb2 butr_carb2 frzn_carb2 	
	 nuts_carb seeds_carb lgmes_carb tofu_carb nuts_carb2 seeds_carb2 lgmes_carb2 tofu_carb2
	 unq_nuts_ekc unq_seeds_ekc unq_lgmes_ekc unq_tofu_ekc
	 nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2;*/

run;
/*17,921 observations (Master Files)*/

proc means n nmiss mean min max data=rs2_25_nutr;	
	var milk_ekc milk_ekc2 milk_sug milk_sug2 milk_sat milk_sat2 milk_pro milk_pro2 milk_vitD milk_vitD2 milk_ca milk_ca2 milk_fe milk_fe2 milk_na milk_na2 milk_k milk_k2 milk_carb milk_carb2	milk_mufa milk_mufa2 milk_pufa milk_pufa2		
		cheese_ekc cheese_ekc2 cheese_sug cheese_sug2 cheese_sat cheese_sat2 cheese_pro cheese_pro2 cheese_vitD cheese_vitD2 cheese_ca cheese_ca2 cheese_fe cheese_fe2 cheese_na cheese_na2 cheese_k cheese_k2 cheese_carb cheese_carb2 cheese_mufa cheese_mufa2 cheese_pufa cheese_pufa2
		yghrt_ekc yghrt_ekc2 yghrt_sug yghrt_sug2 yghrt_sat yghrt_sat2 yghrt_pro yghrt_pro2 yghrt_vitD yghrt_vitD2 yghrt_ca yghrt_ca2 yghrt_fe yghrt_fe2 yghrt_na yghrt_na2 yghrt_k yghrt_k2 yghrt_carb yghrt_carb2 yghrt_mufa yghrt_mufa2 yghrt_pufa yghrt_pufa2
		cream_ekc cream_ekc2 cream_sug cream_sug2 cream_sat cream_sat2 cream_pro cream_pro2 cream_vitD cream_vitD2 cream_ca cream_ca2 cream_fe cream_fe2 cream_na cream_na2 cream_k cream_k2 cream_carb cream_carb2 cream_mufa cream_mufa2 cream_pufa cream_pufa2
		butr_ekc butr_ekc2 butr_sug butr_sug2 butr_sat butr_sat2 butr_pro butr_pro2 butr_vitD butr_vitD2 butr_ca butr_ca2 butr_fe butr_fe2 butr_na butr_na2 butr_k butr_k2 butr_carb butr_carb2 butr_mufa butr_mufa2 butr_pufa butr_pufa2		
		frzn_ekc frzn_ekc2 frzn_sug frzn_sug2 frzn_sat frzn_sat2 frzn_pro frzn_pro2 frzn_vitD frzn_vitD2 frzn_ca frzn_ca2 frzn_fe frzn_fe2 frzn_na frzn_na2 frzn_k frzn_k2 frzn_carb frzn_carb2 frzn_mufa frzn_mufa2 frzn_pufa frzn_pufa2
		nuts_ekc nuts_ekc2 nuts_sug nuts_sug2 nuts_sat nuts_sat2 nuts_pro nuts_pro2 nuts_vitD nuts_vitD2 nuts_ca nuts_ca2 nuts_fe nuts_fe2 nuts_na nuts_na2 nuts_k nuts_k2 nuts_carb nuts_carb2 nuts_mufa nuts_mufa2 nuts_pufa nuts_pufa2
		seeds_ekc seeds_ekc2 seeds_sug seeds_sug2 seeds_sat seeds_sat2 seeds_pro seeds_pro2 seeds_vitD seeds_vitD2 seeds_ca seeds_ca2 seeds_fe seeds_fe2 seeds_na seeds_na2 seeds_k seeds_k2 seeds_carb seeds_carb2 seeds_mufa seeds_mufa2 seeds_pufa seeds_pufa2
		lgmes_ekc lgmes_ekc2 lgmes_sug lgmes_sug2 lgmes_sat lgmes_sat2 lgmes_pro lgmes_pro2 lgmes_vitD lgmes_vitD2 lgmes_ca lgmes_ca2 lgmes_fe lgmes_fe2 lgmes_na lgmes_na2 lgmes_k lgmes_k2 lgmes_carb lgmes_carb2 lgmes_mufa lgmes_mufa2 lgmes_pufa lgmes_pufa2
		tofu_ekc tofu_ekc2 tofu_sug tofu_sug2 tofu_sat tofu_sat2 tofu_pro tofu_pro2 tofu_vitD tofu_vitD2 tofu_ca tofu_ca2 tofu_fe tofu_fe2 tofu_na tofu_na2 tofu_k tofu_k2 tofu_carb tofu_carb2 tofu_mufa tofu_mufa2 tofu_pufa tofu_pufa2
		beef_ekc beef_sug beef_sat beef_pro beef_vitD beef_ca beef_fe beef_na beef_k beef_carb beef_mufa beef_pufa		
		lamb_ekc lamb_sug lamb_sat lamb_pro lamb_vitD lamb_ca lamb_fe lamb_na lamb_k lamb_carb lamb_mufa lamb_pufa
		pork_ekc pork_sug pork_sat pork_pro pork_vitD pork_ca pork_fe pork_na pork_k pork_carb pork_mufa pork_pufa
		lnchn_ekc lnchn_sug lnchn_sat lnchn_pro lnchn_vitD lnchn_ca lnchn_fe lnchn_na lnchn_k lnchn_carb lnchn_mufa lnchn_pufa
		other_ekc other_sug other_sat other_pro other_vitD other_ca other_fe other_na other_k other_carb other_mufa other_pufa
		diet_ekc diet_ekc2;
run;

/*Some nutrient values are still missing. These are genuine missing values at the FID level. For example, there are 106 missing values for cheese_sug.
These respondents consumed cheese, but sug values are missing. It's okay to set them to 0 as done below, because we need to aggregate nutrient totals.
To verify, run the following lines:*/

/*proc means n nmiss data=rs2_50_nutr; var cheese_sug cheese_sug2; run;
data a;
	set rs2_50_nutr;
	if cheese_sug2=.;
	id=1;
	keep sampleid cheese_wtg cheese_sug cheese_sug2 id;
run;

data b;
	set sbgrps;
	if sampleid='10010584210007265121' and food_subgrp=6;
run;

/*Set missing vlues to 0 or else they will not add up*/
data rs2_25_nutr;
	set rs2_25_nutr;
	/*if milk_sug2=. then milk_sug2=0;*/
	if milk_sat2=. then milk_sat2=0;
	if milk_vitD2=. then milk_vitD2=0;
	if milk_fe2=. then milk_fe2=0;
	if milk_na2=. then milk_na2=0;
	if milk_k2=. then milk_k2=0;
	if milk_mufa2=. then milk_mufa2=0;
	if milk_pufa2=. then milk_pufa2=0;
	/*if cheese_sug2=. then cheese_sug2=0;*/
	if cheese_vitD2=. then cheese_vitD2=0;
	if cheese_fe2=. then cheese_fe2=0;
	if cheese_mufa2=. then cheese_mufa2=0;
	if cheese_pufa2=. then cheese_pufa2=0;
	if cream_sug2=. then cream_sug2=0;
	if cream_vitD2=. then cream_vitD2=0;
	if nuts_sug2=. then nuts_sug2=0;
	if nuts_vitD2=. then nuts_vitD2=0;
	/*if seeds_sug2=. then seeds_sug2=0;*/
	if seeds_vitD2=. then seeds_vitD2=0;
	/*if lgmes_sug2=. then lgmes_sug2=0;*/
	if lgmes_vitD2=. then lgmes_vitD2=0;
run;

/* !!!!!!!!!!!!!!!!!!!!!!! */
/*Use this as input for NCI*/
/* !!!!!!!!!!!!!!!!!!!!!!! */
data rs2_25_nutr_nci;
	set rs2_25_nutr;
/*Nutrient totals*/

/*After*/
	tot_ekc2=milk_ekc2+cheese_ekc2+yghrt_ekc2+cream_ekc2+butr_ekc2+frzn_ekc2+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc2+beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+other_ekc;
	tot_sug2=milk_sug2+cheese_sug2+yghrt_sug2+cream_sug2+butr_sug2+frzn_sug2+nuts_sug2+seeds_sug2+lgmes_sug2+tofu_sug2+soybev_sug2+beef_sug+lamb_sug+pork_sug+lnchn_sug+other_sug;
	tot_sat2=milk_sat2+cheese_sat2+yghrt_sat2+cream_sat2+butr_sat2+frzn_sat2+nuts_sat2+seeds_sat2+lgmes_sat2+tofu_sat2+soybev_sat2+beef_sat+lamb_sat+pork_sat+lnchn_sat+other_sat;
	tot_pro2=milk_pro2+cheese_pro2+yghrt_pro2+cream_pro2+butr_pro2+frzn_pro2+nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+soybev_pro2+beef_pro+lamb_pro+pork_pro+lnchn_pro+other_pro;
	tot_vitD2=milk_vitD2+cheese_vitD2+yghrt_vitD2+cream_vitD2+butr_vitD2+frzn_vitD2+nuts_vitD2+seeds_vitD2+lgmes_vitD2+tofu_vitD2+soybev_vitD2+beef_vitD+lamb_vitD+pork_vitD+lnchn_vitD+other_vitD;
	tot_ca2=milk_ca2+cheese_ca2+yghrt_ca2+cream_ca2+butr_ca2+frzn_ca2+nuts_ca2+seeds_ca2+lgmes_ca2+tofu_ca2+soybev_ca2+beef_ca+lamb_ca+pork_ca+lnchn_ca+other_ca;
	tot_fe2=milk_fe2+cheese_fe2+yghrt_fe2+cream_fe2+butr_fe2+frzn_fe2+nuts_fe2+seeds_fe2+lgmes_fe2+tofu_fe2+soybev_fe2+beef_fe+lamb_fe+pork_fe+lnchn_fe+other_fe;
	tot_na2=milk_na2+cheese_na2+yghrt_na2+cream_na2+butr_na2+frzn_na2+nuts_na2+seeds_na2+lgmes_na2+tofu_na2+soybev_na2+beef_na+lamb_na+pork_na+lnchn_na+other_na;
	tot_k2=milk_k2+cheese_k2+yghrt_k2+cream_k2+butr_k2+frzn_k2+nuts_k2+seeds_k2+lgmes_k2+tofu_k2+soybev_k2+beef_k+lamb_k+pork_k+lnchn_k+other_k;
	tot_carb2=milk_carb2+cheese_carb2+yghrt_carb2+cream_carb2+butr_carb2+frzn_carb2+nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb2+beef_carb+lamb_carb+pork_carb+lnchn_carb+other_carb;
	tot_mufa2=milk_mufa2+cheese_mufa2+yghrt_mufa2+cream_mufa2+butr_mufa2+frzn_mufa2+nuts_mufa2+seeds_mufa2+lgmes_mufa2+tofu_mufa2+soybev_mufa2+beef_mufa+lamb_mufa+pork_mufa+lnchn_mufa+other_mufa;
	tot_pufa2=milk_pufa2+cheese_pufa2+yghrt_pufa2+cream_pufa2+butr_pufa2+frzn_pufa2+nuts_pufa2+seeds_pufa2+lgmes_pufa2+tofu_pufa2+soybev_pufa2+beef_pufa+lamb_pufa+pork_pufa+lnchn_pufa+other_pufa;

	/*Free sugars and saturated fat expressed as a percentage of total energy intake*/
	if tot_sug2 ne 0 and tot_ekc2 ne 0 then tot_sug2_pcnt=((tot_sug2*4)/tot_ekc2)*100;
	if tot_sug2=0 or tot_ekc2=0 then tot_sug2_pcnt=0;

	if tot_sat2 ne 0 and tot_ekc2 ne 0 then tot_sat2_pcnt=((tot_sat2*9)/tot_ekc2)*100;
	if tot_sat2=0 or tot_ekc2=0 then tot_sat2_pcnt=0;

	/*keep sampleid suppid wts_m wts_mhw admfw dhhddri dhh_sex dhh_age mhwdbmi mhwdhtm mhwdwtk
	fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_sug2_pcnt tot_sat2_pcnt;*/
run;
/*17,921 observations (Master Files)*/

/*Preliminary results (nutrients)*/
proc means n nmiss mean min max data=rs2_25_nutr_nci;	
		var fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa fsddcar fsddfam fsddfap tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_carb2 tot_sug2_pcnt tot_sat2_pcnt
		tot_mufa2 tot_pufa2;
run;
/*g of free sug (tot_free_sug) is around 53 and free sug as % of TEI is around 11, which is in line with Rana et al. 2021*/

/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Input for NCI w/ supplements*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
data rs2_25_nutr_nci;
	set rs2_25_nutr_nci;
	idnty=1;
run;

proc sort data=rs2_25_nutr_nci; by sampleid suppid; run;
proc sort data=vst_nutr_cncrn; by sampleid suppid; run;

data rs2_25_nutr_nci_supp;
	merge rs2_25_nutr_nci vst_nutr_cncrn;
	by sampleid suppid;
	if idnty=1;
	drop idnty;
run; 
/*17,921 obs*/

data rs2_25_nutr_nci_supp;
	set rs2_25_nutr_nci_supp;
	/*vitD supplement users: vitD_supp_user=1; non-users: vitD_supp_user=2*/
	if vsdfdmg=1 then vitD_supp_user=1; else vitD_supp_user=2;
	if vsdfcal=1 then cal_supp_user=1; else cal_supp_user=2;
	if vsdfiro=1 then iron_supp_user=1; else iron_supp_user=2;
	if vsdfpot=1 then pot_supp_user=1; else pot_supp_user=2;
run;

data rs2_25_nutr_nci_supp;
	set rs2_25_nutr_nci_supp;

/*Nutrient intakes from food + supplements (observed)*/
	if VSTDCAL ne . then tot_ca_supp=FSDDCAL+VSTDCAL;
	if VSTDIRO ne . then tot_fe_supp=FSDDIRO+VSTDIRO;
	if VSTDPOT ne . then tot_k_supp=FSDDPOT+VSTDPOT;
	if VSTDDMG ne . then tot_vitD_supp=FSDDDMG+VSTDDMG;
	if VSTDSOD ne . then tot_na_supp=FSDDSOD+VSTDSOD;

	if VSTDCAL=. then tot_ca_supp=FSDDCAL;
	if VSTDIRO=. then tot_fe_supp=FSDDIRO;
	if VSTDPOT=. then tot_k_supp=FSDDPOT;
	if VSTDDMG=. then tot_vitD_supp=FSDDDMG;
	if VSTDSOD=. then tot_na_supp=FSDDSOD; 

/*Nutrient intakes from food + supplements (replacements)*/
	if VSTDCAL ne . then tot_ca2_supp=tot_ca2+VSTDCAL;
	if VSTDIRO ne . then tot_fe2_supp=tot_fe2+VSTDIRO;
	if VSTDPOT ne . then tot_k2_supp=tot_k2+VSTDPOT;
	if VSTDDMG ne . then tot_vitD2_supp=tot_vitD2+VSTDDMG;
	if VSTDSOD ne . then tot_na2_supp=tot_na2+VSTDSOD;

	if VSTDCAL=. then tot_ca2_supp=tot_ca2;
	if VSTDIRO=. then tot_fe2_supp=tot_fe2;
	if VSTDPOT=. then tot_k2_supp=tot_k2;
	if VSTDDMG=. then tot_vitD2_supp=tot_vitD2;
	if VSTDSOD=. then tot_na2_supp=tot_na2; 

run;

/*Datasets for vitD*/
data rs2_25_supp_users_vitD;
	set rs2_25_nutr_nci_supp;
	if vitD_supp_user=1;
run;
/* 6278 observations */
data rs2_25_supp_nonusers_vitD;
	set rs2_25_nutr_nci_supp;
	if vitD_supp_user=2;
run;
/* 11643 observations */

/*Datasets for iron*/
data rs2_25_supp_users_iron;
	set rs2_25_nutr_nci_supp;
	if iron_supp_user=1;
run;
/* 2739 observations */
data rs2_25_supp_nonusers_iron;
	set rs2_25_nutr_nci_supp;
	if iron_supp_user=2;
run;
/* 15182 observations */

/*Datasets for calcium*/
data rs2_25_supp_users_cal;
	set rs2_25_nutr_nci_supp;
	if cal_supp_user=1;
run;
/* 4550 observations */
data rs2_25_supp_nonusers_cal;
	set rs2_25_nutr_nci_supp;
	if cal_supp_user=2;
run;
/* 13371 observations */

/*Datasets for potassium*/
data rs2_25_supp_users_pot;
	set rs2_25_nutr_nci_supp;
	if pot_supp_user=1;
run;
/* 1987 observations */
data rs2_25_supp_nonusers_pot;
	set rs2_25_nutr_nci_supp;
	if pot_supp_user=2;
run;
/* 15934 observations */

proc means n nmiss mean min max data=rs2_25_nutr_nci_supp;	
	var fsddcal fsddiro fsddpot fsdddmg fsddsod tot_ca2 tot_fe2 tot_vitD2 tot_k2 tot_na2
		tot_ca_supp tot_fe_supp tot_k_supp tot_vitD_supp tot_na_supp tot_ca2_supp tot_fe2_supp tot_k2_supp tot_vitD2_supp tot_na2_supp;
run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Use this for health outcome anaylses*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */

data rs2_25_nutr_nci;
	set rs2_25_nutr_nci;

/*Observed diets*/

	/*Red meat*/
	/*red_meat_wtg=beef_wtg+lamb_wtg+pork_wtg;
	red_meat_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2;

	/*Nuts and seeds*/
	nts_sds_wtg=nuts_wtg+seeds_wtg;
	nts_sds_wtg2=nuts_wtg2+seeds_wtg2;

run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/* Use this for nci anaylses for foods */
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*This can be used for observed diets and RS2-25%*/
data rs2_25_food_nci;
	set rs2_25_nutr_nci;
	keep sampleid suppid seq2 weekend wts_m sex dhh_age
		/*red_meat_wtg lnchn_wtg*/ nts_sds_wtg lgmes_wtg milk_wtg
		/*red_meat_wtg2 lnchn_wtg2*/ nts_sds_wtg2 lgmes_wtg2 milk_wtg2;
run;
/*17,921 obs*/

/*Check red meat intake (obs) for males*/
/*data a_m; set rs2_25_food_nci; if sex=0; run;
proc means data=a_m; var red_meat_wtg; run;

/*Check red meat intake (obs) for females*/
/*data a_f; set rs2_25_food_nci; if sex=1; run;
proc means data=a_f; var red_meat_wtg; run;

/******************************************************************************/
/* RS1 -> Replace 50% of red and processed meat with nuts, seeds, and legumes */
/******************************************************************************/

/************************************/
/* Conduct replacements - g of food */
/************************************/
data rs1_50;
	set baseline_final;

/*If the individual consumed meat, cut that in half*/
	if meat_wtg ne . then meat_wtg2=meat_wtg/2;
	if beef_wtg ne . then beef_wtg2=beef_wtg/2;
	if lamb_wtg ne . then lamb_wtg2=lamb_wtg/2;
	if pork_wtg ne . then pork_wtg2=pork_wtg/2;
	if lnchn_wtg ne . then lnchn_wtg2=lnchn_wtg/2;

/*If the individual consumed meat AND nuts OR seeds OR legumes OR tofu*/
	/*Beef*/
	if beef_wtg ne . and nuts_wtg ne . then nuts_beef_wtg2=(beef_wtg*nuts_pcnt/2);
	if beef_wtg ne . and seeds_wtg ne . then seeds_beef_wtg2=(beef_wtg*seeds_pcnt/2);
	if beef_wtg ne . and lgmes_wtg ne . then lgmes_beef_wtg2=(beef_wtg*lgmes_pcnt/2);
	if beef_wtg ne . and tofu_wtg ne . then tofu_beef_wtg2=(beef_wtg*tofu_pcnt/2);	
	/*Lamb*/
	if lamb_wtg ne . and nuts_wtg ne . then nuts_lamb_wtg2=(lamb_wtg*nuts_pcnt/2);	
	if lamb_wtg ne . and seeds_wtg ne . then seeds_lamb_wtg2=(lamb_wtg*seeds_pcnt/2);	
	if lamb_wtg ne . and lgmes_wtg ne . then lgmes_lamb_wtg2=(lamb_wtg*lgmes_pcnt/2);	
	if lamb_wtg ne . and tofu_wtg ne . then tofu_lamb_wtg2=(lamb_wtg*tofu_pcnt/2);
	/*Pork*/
	if pork_wtg ne . and nuts_wtg ne . then nuts_pork_wtg2=(pork_wtg*nuts_pcnt/2);	
	if pork_wtg ne . and seeds_wtg ne . then seeds_pork_wtg2=(pork_wtg*seeds_pcnt/2);	
	if pork_wtg ne . and lgmes_wtg ne . then lgmes_pork_wtg2=(pork_wtg*lgmes_pcnt/2);	
	if pork_wtg ne . and tofu_wtg ne . then tofu_pork_wtg2=(pork_wtg*tofu_pcnt/2);	
	/*Luncheon and other meats*/	
	if lnchn_wtg ne . and nuts_wtg ne . then nuts_lnchn_wtg2=(lnchn_wtg*nuts_pcnt/2);	
	if lnchn_wtg ne . and seeds_wtg ne . then seeds_lnchn_wtg2=(lnchn_wtg*seeds_pcnt/2);	
	if lnchn_wtg ne . and lgmes_wtg ne . then lgmes_lnchn_wtg2=(lnchn_wtg*lgmes_pcnt/2);	
	if lnchn_wtg ne . and tofu_wtg ne . then tofu_lnchn_wtg2=(lnchn_wtg*tofu_pcnt/2);	

/*If the individual consumed nuts OR seeds OR legumes OR tofu BUT NOT meat*/
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and nuts_wtg ne . then nuts_wtg2=nuts_wtg;
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and seeds_wtg ne . then seeds_wtg2=seeds_wtg;
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and lgmes_wtg ne . then lgmes_wtg2=lgmes_wtg;
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and tofu_wtg ne . then tofu_wtg2=tofu_wtg;

/*If the individual did not originally consume meat, set to 0*/
	if meat_wtg=. then meat_wtg=0;
	if beef_wtg=. then beef_wtg=0;
	if lamb_wtg=. then lamb_wtg=0;
	if pork_wtg=. then pork_wtg=0;
	if lnchn_wtg=. then lnchn_wtg=0;

/*If the individual did not originally consume nsl, set to 0*/
	if nsl_wtg=. then nsl_wtg=0;
	if nuts_wtg=. then nuts_wtg=0;
	if seeds_wtg=. then seeds_wtg=0;
	if lgmes_wtg=. then lgmes_wtg=0;
	if tofu_wtg=. then tofu_wtg=0;	

/*Set missing values post-replacement to 0*/
	if beef_wtg2=. then beef_wtg2=0;
	if lamb_wtg2=. then lamb_wtg2=0;
	if pork_wtg2=. then pork_wtg2=0;
	if lnchn_wtg2=. then lnchn_wtg2=0;

	if nuts_wtg2=. then nuts_wtg2=0;
	if seeds_wtg2=. then seeds_wtg2=0;
	if lgmes_wtg2=. then lgmes_wtg2=0;
	if tofu_wtg2=. then tofu_wtg2=0;

	if nuts_beef_wtg2=. then nuts_beef_wtg2=0;
	if seeds_beef_wtg2=. then seeds_beef_wtg2=0;
	if lgmes_beef_wtg2=. then lgmes_beef_wtg2=0;
	if tofu_beef_wtg2=. then tofu_beef_wtg2=0;

	if nuts_lamb_wtg2=. then nuts_lamb_wtg2=0;
	if seeds_lamb_wtg2=. then seeds_lamb_wtg2=0;
	if lgmes_lamb_wtg2=. then lgmes_lamb_wtg2=0;
	if tofu_lamb_wtg2=. then tofu_lamb_wtg2=0;

	if nuts_pork_wtg2=. then nuts_pork_wtg2=0;
	if seeds_pork_wtg2=. then seeds_pork_wtg2=0;
	if lgmes_pork_wtg2=. then lgmes_pork_wtg2=0;
	if tofu_pork_wtg2=. then tofu_pork_wtg2=0;

	if nuts_lnchn_wtg2=. then nuts_lnchn_wtg2=0;
	if seeds_lnchn_wtg2=. then seeds_lnchn_wtg2=0;
	if lgmes_lnchn_wtg2=. then lgmes_lnchn_wtg2=0;
	if tofu_lnchn_wtg2=. then tofu_lnchn_wtg2=0;

/*Later we have to account for other foods, set to 0 here*/
	if dairy_wtg=. then dairy_wtg=0;											
	if milk_wtg=. then milk_wtg=0;
	if cheese_wtg=. then cheese_wtg=0;
	if yghrt_wtg=. then yghrt_wtg=0;
	if cream_wtg=. then cream_wtg=0;
	if butr_wtg=. then butr_wtg=0;
	if frzn_wtg=. then frzn_wtg=0;
	if soybev_wtg=. then soybev_wtg=0;
	if other_wtg=. then other_wtg=0;

/*If the individual consumed meat BUT NOT nuts OR seeds OR legumes OR tofu, use ratios for overall sample*/
	if meat_wtg ne 0 and nsl_wtg=0 then nuts_wtg2=(beef_wtg*0.301588528/2)+(lamb_wtg*0.301588528/2)+(pork_wtg*0.301588528/2)+(lnchn_wtg*0.301588528/2);
	if meat_wtg ne 0 and nsl_wtg=0 then seeds_wtg2=(beef_wtg*0.03540598/2)+(lamb_wtg*0.03540598/2)+(pork_wtg*0.03540598/2)+(lnchn_wtg*0.03540598/2); 
	if meat_wtg ne 0 and nsl_wtg=0 then lgmes_wtg2=(beef_wtg*0.595355613/2)+(lamb_wtg*0.595355613/2)+(pork_wtg*0.595355613/2)+(lnchn_wtg*0.595355613/2); 
	if meat_wtg ne 0 and nsl_wtg=0 then tofu_wtg2=(beef_wtg*0.067649879/2)+(lamb_wtg*0.067649879/2)+(pork_wtg*0.067649879/2)+(lnchn_wtg*0.067649879/2); 

/*Create one variable for nuts, seeds, and legumes weight post-replacement, accounting for g of nsl at baseline*/
	if meat_wtg ne 0 and nsl_wtg ne 0 then nuts_wtg2=nuts_wtg+nuts_beef_wtg2+nuts_lamb_wtg2+nuts_pork_wtg2+nuts_lnchn_wtg2;
	if meat_wtg ne 0 and nsl_wtg ne 0 then seeds_wtg2=seeds_wtg+seeds_beef_wtg2+seeds_lamb_wtg2+seeds_pork_wtg2+seeds_lnchn_wtg2;
	if meat_wtg ne 0 and nsl_wtg ne 0 then lgmes_wtg2=lgmes_wtg+lgmes_beef_wtg2+lgmes_lamb_wtg2+lgmes_pork_wtg2+lgmes_lnchn_wtg2;
	if meat_wtg ne 0 and nsl_wtg ne 0 then tofu_wtg2=tofu_wtg+tofu_beef_wtg2+tofu_lamb_wtg2+tofu_pork_wtg2+tofu_lnchn_wtg2;

/*Create variables for total meat and total nsl g post-replacement*/
/*Note that beef_wtg2+lamb_wtg2+pork_wtg2+lnchn_wtg2 (i.e., meat_wtg2) should = nsl_wtg2 - nsl_wtg*/
	meat_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2+lnchn_wtg2;
	nsl_wtg2=nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg;

	diet_wtg=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+soybev_wtg;
	diet_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2+lnchn_wtg2+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg+nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg;

/*This is a test to see if we are accounting for ALL foods (compare to fsddwtg)*/
	/*fsddwtg_chk=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+soybev_wtg+other_wtg;

/*To ensure math checks out by hand, just keep relevant variables*/
/*keep sampleid beef_wtg lamb_wtg pork_wtg lnchn_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg 
			  beef_wtg2 lamb_wtg2 pork_wtg2 lnchn_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2
			  meat_wtg nsl_wtg
			  meat_wtg2 nsl_wtg2
			  diet_wtg diet_wtg2;*/
run;
/*17,921 observations (Master Files)*/

/*Verification examples:
	- Person 1:
		- Consumed 75 g of luncheon and 17.52 g of nuts
		- 37.5 g luncheon added to amount of nuts originally consumed = 37.5 g (lnchn) + 17.52 g (nuts) = 55.02 g nuts
	- Person 2:
		- Did not consume meat, only 10.75 g of nuts
		- No replacement done, g of nuts before and after are the same
	- Person 3:
		- Consumed 134 g of beef and 75 g of luncheon, did not consume any nuts, seeds, or legumes
		- 67 g of beef and 37.5 g of luncheon to distribute among nuts, seeds, and legumes in proportions consumed by overall sample
			- beef -> nsl: 67 g x 0.302 (nuts) = 20.23 g of nuts; 67 x 0.035 (seeds) = 2.35 g seeds; 67 x 0.595 (legumes) = 39.87 g of legumes; 67 x 0.068 = 4.57 g of tofu (sum all = 67 g)
			- luncheon -> nsl: 37.5 g x 0.302 (nuts) = 11.33 g of nuts; 37.5 x 0.035 (seeds) = 1.31 g seeds; 37.5 x 0.595 (legumes) = 22.31 g of legumes; 37.5 x 0.068 = 2.55 g of tofu (sum all = 37.5)
		- g of nuts post replacement = 20.23 g (from beef) + 11.33 (from luncheon) = 31.52 g
		- g of seeds post replacement = 2.35 g (from beef) + 1.31 (from luncheon) = 3.7 g 
		- g of legumes post replacement = 39.87 g (from beef) + 22.31 (from luncheon) = 62.22 g 
		- g of tofu post replacement = 4.57 g (from beef) + 2.55 (from luncheon) = 7.12 g
		- sum all = 67 g + 37.5 g = 104.5 g
	- Person 13: 
		- Consumed 16.2 g of pork, 5.3 g of nuts, and 18.13 g of legumes
		- 8.1 g of pork to distribute among nuts and legumes in proportions consumed by the respondent (23% nuts and 77% legumes)
			- pork -> nuts: 8.1 x 0.23 = 1.83
			- pork -> legumes: 8.1 x 0.77 = 6.26
	 	- g of nuts post-replacement = 1.83 + 5.3 (amount originally consumed) = 7.14
		- g of legumes post-replacement = 6.26 + 18.13 (amount originally consumed) = 24.39*/
	
/*Preliminary results (g)*/
proc means n nmiss mean min max data=rs1_50;	
	var beef_wtg beef_wtg2 lamb_wtg lamb_wtg2 pork_wtg pork_wtg2 lnchn_wtg lnchn_wtg2
		nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2
		milk_wtg cheese_wtg yghrt_wtg cream_wtg butr_wtg frzn_wtg /*soybev_wtg*/ other_wtg
		diet_wtg diet_wtg2;
run;	

/************************************/
/* Conduct replacements - GHGE 		*/
/************************************/
data rs1_50_ghge;
	set rs1_50;

	/*If the respondent consumed meat, simply divide ghge of g of meat originally consumed in half*/
	/*Alternatively, multiply unique ghge based on their meat consumption profile by g of meat after replacement*/
	/*Note that these come out to the same thing*/
	if beef_wtg ne 0 and beef_co2eq ne . then beef_co2eq2=beef_co2eq/2;
	if lamb_wtg ne 0 and lamb_co2eq ne . then lamb_co2eq2=lamb_co2eq/2;
	if pork_wtg ne 0 and pork_co2eq ne . then pork_co2eq2=pork_co2eq/2;
	if lnchn_wtg ne 0 and lnchn_co2eq ne . then lnchn_co2eq2=lnchn_co2eq/2;
	/*if beef_wtg ne 0 and unq_beef_co2eq ne . then beef_co2eq2_v2=unq_beef_co2eq*(beef_wtg2/1000);			
	if lamb_wtg ne 0 and unq_lamb_co2eq ne . then lamb_co2eq2_v2=unq_lamb_co2eq*(lamb_wtg2/1000);
	if pork_wtg ne 0 and unq_pork_co2eq ne . then pork_co2eq2_v2=unq_pork_co2eq*(pork_wtg2/1000);
	if lnchn_wtg ne 0 and unq_lnchn_co2eq ne . then lnchn_co2eq2_v2=unq_lnchn_co2eq*(lnchn_wtg2/1000);*/

	/*For respondents that originally consumed nsl, multiply unique ghge based on their nsl consumption profile by g of nsl replaced; then, add this to original ghge
	for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl) (these come out to the same thing)*/
	if nuts_wtg ne 0 and unq_nuts_co2eq ne . then nuts_co2eq2=nuts_co2eq+(unq_nuts_co2eq*((nuts_wtg2-nuts_wtg)/1000));
	if seeds_wtg ne 0 and unq_seeds_co2eq ne . then seeds_co2eq2=seeds_co2eq+(unq_seeds_co2eq*((seeds_wtg2-seeds_wtg)/1000));
	if lgmes_wtg ne 0 and unq_lgmes_co2eq ne . then lgmes_co2eq2=lgmes_co2eq+(unq_lgmes_co2eq*((lgmes_wtg2-lgmes_wtg)/1000));
	if tofu_wtg ne 0 and unq_tofu_co2eq ne . then tofu_co2eq2=tofu_co2eq+(unq_tofu_co2eq*((tofu_wtg2-tofu_wtg)/1000));
	/*if nuts_wtg ne 0 and unq_nuts_co2eq ne . then nuts_co2eq2_v2=unq_nuts_co2eq*(nuts_wtg2/1000);
	if seeds_wtg ne 0 and unq_seeds_co2eq ne . then seeds_co2eq2_v2=unq_seeds_co2eq*(seeds_wtg2/1000);
	if lgmes_wtg ne 0 and unq_lgmes_co2eq ne . then lgmes_co2eq2_v2=unq_lgmes_co2eq*(lgmes_wtg2/1000);
	if tofu_wtg ne 0 and unq_tofu_co2eq ne . then tofu_co2eq2_v2=unq_tofu_co2eq*(tofu_wtg2/1000);*/

	/*For respodents that did not originally consume beef, ghge=0 after replacement*/
	if beef_wtg=0 then beef_co2eq2=0;
	if lamb_wtg=0 then lamb_co2eq2=0;
	if pork_wtg=0 then pork_co2eq2=0;
	if lnchn_wtg=0 then lnchn_co2eq2=0;

	/*For respondents that did not originally consume nsl, use a weighted average ghge*/
	/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_co2eq2=2.303442774*(nuts_wtg2/1000);
	if seeds_wtg=0 then seeds_co2eq2=0.883544384*(seeds_wtg2/1000);
	if lgmes_wtg=0 then lgmes_co2eq2=1.388278602*(lgmes_wtg2/1000);
	if tofu_wtg=0 then tofu_co2eq2=2.3616*(tofu_wtg2/1000);

	/*Setting missing values to 0 here*/
	if beef_co2eq=. then beef_co2eq=0;
	if lamb_co2eq=. then lamb_co2eq=0;
	if pork_co2eq=. then pork_co2eq=0;
	if lnchn_co2eq=. then lnchn_co2eq=0;
	if nuts_co2eq=. then nuts_co2eq=0;
	if seeds_co2eq=. then seeds_co2eq=0;
	if lgmes_co2eq=. then lgmes_co2eq=0;
	if tofu_co2eq=. then tofu_co2eq=0;

	if beef_co2eq2=. then beef_co2eq2=0;
	if lamb_co2eq2=. then lamb_co2eq2=0;
	if pork_co2eq2=. then pork_co2eq2=0;
	if lnchn_co2eq2=. then lnchn_co2eq2=0;
	if nuts_co2eq2=. then nuts_co2eq2=0;
	if seeds_co2eq2=. then seeds_co2eq2=0;
	if lgmes_co2eq2=. then lgmes_co2eq2=0;
	if tofu_co2eq2=. then tofu_co2eq2=0;

	/*Setting missing values to 0 for other foods here*/
	if cheese_co2eq=. then cheese_co2eq=0;
	if yghrt_co2eq=. then yghrt_co2eq=0;
	if cream_co2eq=. then cream_co2eq=0;
	if butr_co2eq=. then butr_co2eq=0;
	if frzn_co2eq=. then frzn_co2eq=0;
	if milk_co2eq=. then milk_co2eq=0;
	if soybev_co2eq=. then soybev_co2eq=0;
	if other_co2eq=. then other_co2eq=0;

	/*Create variables for total meat and total nsl ghge pre- and post-replacement*/
	tot_meat_co2eq=beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq;
	tot_meat_co2eq2=beef_co2eq2+lamb_co2eq2+pork_co2eq2+lnchn_co2eq2;
	tot_nsl_co2eq=nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+soybev_co2eq;
	tot_nsl_co2eq2=nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+soybev_co2eq;
	tot_dairy_co2eq=cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+milk_co2eq;

	/*Create variables for total ghge pre- and post-replacement*/
	tot_co2eq=beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq+nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+
	cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+milk_co2eq+soybev_co2eq+other_co2eq;
	tot_co2eq2=beef_co2eq2+lamb_co2eq2+pork_co2eq2+lnchn_co2eq2+nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+
	cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+milk_co2eq+soybev_co2eq+other_co2eq;

	/*Create variables for CO2-eq/1000 kcal*/
	if fsddekc ne 0 then tot_co2eq_kcal=(tot_co2eq/fsddekc)*1000;
	if fsddekc ne 0 then tot_co2eq2_kcal=(tot_co2eq2/fsddekc)*1000;

	/*keep sampleid beef_wtg lamb_wtg pork_wtg lnchn_wtg nsl_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg
	beef_wtg2 lamb_wtg2 pork_wtg2 lnchn_wtg2 nsl_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2
	nuts_beef_wtg2 nuts_lamb_wtg2 nuts_pork_wtg2 nuts_lnchn_wtg2
	seeds_beef_wtg2 seeds_lamb_wtg2 seeds_pork_wtg2 seeds_lnchn_wtg2
	lgmes_beef_wtg2 lgmes_lamb_wtg2 lgmes_pork_wtg2 lgmes_lnchn_wtg2
	tofu_beef_wtg2 tofu_lamb_wtg2 tofu_pork_wtg2 tofu_lnchn_wtg2
	nuts_pcnt seeds_pcnt lgmes_pcnt tofu_pcnt
	meat_wtg nsl_wtg meat_wtg2 nsl_wtg2 
	beef_co2eq lamb_co2eq pork_co2eq lnchn_co2eq nuts_co2eq seeds_co2eq lgmes_co2eq tofu_co2eq
	beef_co2eq2 lamb_co2eq2 pork_co2eq2 lnchn_co2eq2 nuts_co2eq2 seeds_co2eq2 lgmes_co2eq2 tofu_co2eq2
	unq_nuts_co2eq unq_seeds_co2eq unq_lgmes_co2eq unq_tofu_co2eq;*/

run;
/*17,921 observations (Master Files)*/

proc means n nmiss mean min max data=rs1_50_ghge;
	var fsddekc tot_co2eq_kcal tot_co2eq2_kcal;
run;

/*Verification examples:
	- Person 1:
		- Consumed luncheon and nuts
			- co2eq luncheon post-replacement = 1.34 (lnchn_co2eq)/2 = 0.67
			- co2eq nuts post-replacement =  0.007 (co2eq of nuts originally consumed) + (0.414 (unique nuts multiplier) x ((55.02 - 17.52) (nuts_wtg2 - nuts_wtg) / 1000))) = 0.02
	- Person 2:
		- Did not consume meat, only nuts
		- No replacement done, co2eq of nuts before and after are the same
	- Person 3:
		- Consumed beef and luncheon, did not consume any nuts, seeds, or legumes
			- co2eq beef post-replacement = 5.8/2 = 2.9
			- co2eq luncheon post-replacement = 2.8/2 = 1.4
			- co2eq nuts post-replacement = 2.3 (avg. weighted GHGE from 'Food-List') x nuts_wtg2/1000 = 0.07
			- co2eq seeds post-replacement = 0.9 (avg. weighted GHGE from 'Food-List') x seeds_wtg2/1000 = 0.003
			- co2eq legumes post-replacement = 1.4 (avg. weighted GHGE from 'Food-List') x lgmes_wtg2/1000 = 0.08
			- co2eq tofu post-replacement = 2.4 (avg. weighted GHGE from 'Food-List') x tofu_wtg2/1000 = 0.02
	- Person 13: 
		- Consumed pork, nuts, and legumes
			- co2eq pork post-replacement = 0.06 (pork_co2eq)/2 = 0.03
			- co2eq nuts post-replacement =  0.011 (co2eq of nuts originally consumed) + (2.209 (unique nuts multiplier) x ((7.14 - 5.3) (nuts_wtg2 - nuts_wtg) / 1000))) = 0.015
			- co2eq legumes post-replacement =  0.044 (co2eq of legumes originally consumed) + (2.44 (unique nuts multiplier) x ((24.39 - 18.13) (legumes_wtg2 - legmes_wtg) / 1000))) = 0.059*/

/*Preliminary results (ghge)*/
proc means n nmiss mean min max data=rs1_50_ghge;	
	var beef_co2eq beef_co2eq2 lamb_co2eq lamb_co2eq2 pork_co2eq pork_co2eq2 lnchn_co2eq lnchn_co2eq2
	nuts_co2eq nuts_co2eq2 seeds_co2eq seeds_co2eq2 lgmes_co2eq lgmes_co2eq2 tofu_co2eq tofu_co2eq2
	cheese_co2eq yghrt_co2eq cream_co2eq butr_co2eq frzn_co2eq milk_co2eq /*soybev_co2eq*/ other_co2eq
	tot_meat_co2eq tot_meat_co2eq2 tot_nsl_co2eq tot_nsl_co2eq2 tot_co2eq tot_co2eq2;
run;

/************************************/
/* Conduct replacements - Nutrients */
/************************************/

/*Note that the same method for calculating ghge is used here for nutrients*/

data rs1_50_nutr;
	set rs1_50_ghge;

/*If the respondent consumed meat, simply divide intake of nutrients originally consumed from meat in half*/
/*Alternatively, multiply unique ekc based on their meat consumption profile by g of meat after replacement*/
/*Note that these come out to the same thing*/
	/*Energy*/
		if beef_wtg ne 0 and beef_ekc ne . then beef_ekc2=beef_ekc/2;
		if lamb_wtg ne 0 and lamb_ekc ne . then lamb_ekc2=lamb_ekc/2;	
		if pork_wtg ne 0 and pork_ekc ne . then pork_ekc2=pork_ekc/2;	
		if lnchn_wtg ne 0 and lnchn_ekc ne . then lnchn_ekc2=lnchn_ekc/2;
		/*if beef_wtg ne 0 and unq_beef_ekc ne . then beef_ekc2_v2=unq_beef_ekc*beef_wtg2;
		if lamb_wtg ne 0 and unq_lamb_ekc ne . then lamb_ekc2_v2=unq_lamb_ekc*lamb_wtg2;	
		if pork_wtg ne 0 and unq_pork_ekc ne . then pork_ekc2_v2=unq_pork_ekc*pork_wtg2;
		if lnchn_wtg ne 0 and unq_lnchn_ekc ne . then lnchn_ekc2_v2=unq_lnchn_ekc*lnchn_wtg2;*/	
	/*Sugar*/
		if beef_wtg ne 0 and beef_sug ne . then beef_sug2=beef_sug/2;	
		if lamb_wtg ne 0 and lamb_sug ne . then lamb_sug2=lamb_sug/2;	
		if pork_wtg ne 0 and pork_sug ne . then pork_sug2=pork_sug/2;	
		if lnchn_wtg ne 0 and lnchn_sug ne . then lnchn_sug2=lnchn_sug/2;	
		/*if beef_wtg ne 0 and unq_beef_sug ne . then beef_sug2_v2=unq_beef_sug*beef_wtg2;					
		if lamb_wtg ne 0 and unq_lamb_sug ne . then lamb_sug2_v2=unq_lamb_sug*lamb_wtg2;	
		if pork_wtg ne 0 and unq_pork_sug ne . then pork_sug2_v2=unq_pork_sug*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_sug ne . then lnchn_sug2_v2=unq_lnchn_sug*lnchn_wtg2;*/				
	/*Saturated fat*/
		if beef_wtg ne 0 and beef_sat ne . then beef_sat2=beef_sat/2;	
		if lamb_wtg ne 0 and lamb_sat ne . then lamb_sat2=lamb_sat/2;	
		if pork_wtg ne 0 and pork_sat ne . then pork_sat2=pork_sat/2;	
		if lnchn_wtg ne 0 and lnchn_sat ne . then lnchn_sat2=lnchn_sat/2;	
		/*if beef_wtg ne 0 and unq_beef_sat ne . then beef_sat2_v2=unq_beef_sat*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_sat ne . then lamb_sat2_v2=unq_lamb_sat*lamb_wtg2;								
		if pork_wtg ne 0 and unq_pork_sat ne . then pork_sat2_v2=unq_pork_sat*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_sat ne . then lnchn_sat2_v2=unq_lnchn_sat*lnchn_wtg2;*/		
	/*Protein*/
		if beef_wtg ne 0 and beef_pro ne . then beef_pro2=beef_pro/2;	
		if lamb_wtg ne 0 and lamb_pro ne . then lamb_pro2=lamb_pro/2;	
		if pork_wtg ne 0 and pork_pro ne . then pork_pro2=pork_pro/2;	
		if lnchn_wtg ne 0 and lnchn_pro ne . then lnchn_pro2=lnchn_pro/2;	
		/*if beef_wtg ne 0 and unq_beef_pro ne . then beef_pro2_v2=unq_beef_pro*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_pro ne . then lamb_pro2_v2=unq_lamb_pro*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_pro ne . then pork_pro2_v2=unq_pork_pro*pork_wtg2;							
		if lnchn_wtg ne 0 and unq_lnchn_pro ne . then lnchn_pro2_v2=unq_lnchn_pro*lnchn_wtg2;*/			
	/*Vitamin D*/
		if beef_wtg ne 0 and beef_vitD ne . then beef_vitD2=beef_vitD/2;	
		if lamb_wtg ne 0 and lamb_vitD ne . then lamb_vitD2=lamb_vitD/2;	
		if pork_wtg ne 0 and pork_vitD ne . then pork_vitD2=pork_vitD/2;	
		if lnchn_wtg ne 0 and lnchn_vitD ne . then lnchn_vitD2=lnchn_vitD/2;	
		/*if beef_wtg ne 0 and unq_beef_vitD ne . then beef_vitD2_v2=unq_beef_vitD*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_vitD ne . then lamb_vitD2_v2=unq_lamb_vitD*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_vitD ne . then pork_vitD2_v2=unq_pork_vitD*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_vitD ne . then lnchn_vitD2_v2=unq_lnchn_vitD*lnchn_wtg2;*/				
	/*Calcium*/
		if beef_wtg ne 0 and beef_ca ne . then beef_ca2=beef_ca/2;	
		if lamb_wtg ne 0 and lamb_ca ne . then lamb_ca2=lamb_ca/2;	
		if pork_wtg ne 0 and pork_ca ne . then pork_ca2=pork_ca/2;	
		if lnchn_wtg ne 0 and lnchn_ca ne . then lnchn_ca2=lnchn_ca/2;	
		/*if beef_wtg ne 0 and unq_beef_ca ne . then beef_ca2_v2=unq_beef_ca*beef_wtg2;								
		if lamb_wtg ne 0 and unq_lamb_ca ne . then lamb_ca2_v2=unq_lamb_ca*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_ca ne . then pork_ca2_v2=unq_pork_ca*pork_wtg2;							
		if lnchn_wtg ne 0 and unq_lnchn_ca ne . then lnchn_ca2_v2=unq_lnchn_ca*lnchn_wtg2;*/					
	/*Iron*/
		if beef_wtg ne 0 and beef_fe ne . then beef_fe2=beef_fe/2;	
		if lamb_wtg ne 0 and lamb_fe ne . then lamb_fe2=lamb_fe/2;	
		if pork_wtg ne 0 and pork_fe ne . then pork_fe2=pork_fe/2;	
		if lnchn_wtg ne 0 and lnchn_fe ne . then lnchn_fe2=lnchn_fe/2;		
		/*if beef_wtg ne 0 and unq_beef_fe ne . then beef_fe2_v2=unq_beef_fe*beef_wtg2;								
		if lamb_wtg ne 0 and unq_lamb_fe ne . then lamb_fe2_v2=unq_lamb_fe*lamb_wtg2;								
		if pork_wtg ne 0 and unq_pork_fe ne . then pork_fe2_v2=unq_pork_fe*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_fe ne . then lnchn_fe2_v2=unq_lnchn_fe*lnchn_wtg2;*/							
	/*Sodium*/
		if beef_wtg ne 0 and beef_na ne . then beef_na2=beef_na/2;	
		if lamb_wtg ne 0 and lamb_na ne . then lamb_na2=lamb_na/2;	
		if pork_wtg ne 0 and pork_na ne . then pork_na2=pork_na/2;	
		if lnchn_wtg ne 0 and lnchn_na ne . then lnchn_na2=lnchn_na/2;	
		/*if beef_wtg ne 0 and unq_beef_na ne . then beef_na2_v2=unq_beef_na*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_na ne . then lamb_na2_v2=unq_lamb_na*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_na ne . then pork_na2_v2=unq_pork_na*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_na ne . then lnchn_na2_v2=unq_lnchn_na*lnchn_wtg2;*/							
	/*Potassium*/	
		if beef_wtg ne 0 and beef_k ne . then beef_k2=beef_k/2;	
		if lamb_wtg ne 0 and lamb_k ne . then lamb_k2=lamb_k/2;	
		if pork_wtg ne 0 and pork_k ne . then pork_k2=pork_k/2;	
		if lnchn_wtg ne 0 and lnchn_k ne . then lnchn_k2=lnchn_k/2;	
		/*if beef_wtg ne 0 and unq_beef_k ne . then beef_k2_v2=unq_beef_k*beef_wtg2;				
		if lamb_wtg ne 0 and unq_lamb_k ne . then lamb_k2_v2=unq_lamb_k*lamb_wtg2;						
		if pork_wtg ne 0 and unq_pork_k ne . then pork_k2_v2=unq_pork_k*pork_wtg2;							
		if lnchn_wtg ne 0 and unq_lnchn_k ne . then lnchn_k2_v2=unq_lnchn_k*lnchn_wtg2;*/
	/*Carbs*/
		if beef_wtg ne 0 and beef_carb ne . then beef_carb2=beef_carb/2;		
		if lamb_wtg ne 0 and lamb_carb ne . then lamb_carb2=lamb_carb/2;		
		if pork_wtg ne 0 and pork_carb ne . then pork_carb2=pork_carb/2;		
		if lnchn_wtg ne 0 and lnchn_carb ne . then lnchn_carb2=lnchn_carb/2;	
	/*MUFAs*/			
		if beef_wtg ne 0 and beef_mufa ne . then beef_mufa2=beef_mufa/2;		
		if lamb_wtg ne 0 and lamb_mufa ne . then lamb_mufa2=lamb_mufa/2;		
		if pork_wtg ne 0 and pork_mufa ne . then pork_mufa2=pork_mufa/2;		
		if lnchn_wtg ne 0 and lnchn_mufa ne . then lnchn_mufa2=lnchn_mufa/2;
	/*PUFAs*/			
		if beef_wtg ne 0 and beef_pufa ne . then beef_pufa2=beef_pufa/2;		
		if lamb_wtg ne 0 and lamb_pufa ne . then lamb_pufa2=lamb_pufa/2;		
		if pork_wtg ne 0 and pork_pufa ne . then pork_pufa2=pork_pufa/2;		
		if lnchn_wtg ne 0 and lnchn_pufa ne . then lnchn_pufa2=lnchn_pufa/2;			

/*For respondents that originally consumed nsl, multiply unique ekc based on their nsl consumption profile by g of nsl replaced; then, add this to original ekc
for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl) (these come out to the same thing)*/
	/*Energy*/
		if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2=nuts_ekc+(unq_nuts_ekc*(nuts_wtg2-nuts_wtg));
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2=seeds_ekc+(unq_seeds_ekc*(seeds_wtg2-seeds_wtg));
		if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2=lgmes_ekc+(unq_lgmes_ekc*(lgmes_wtg2-lgmes_wtg));
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2=tofu_ekc+(unq_tofu_ekc*(tofu_wtg2-tofu_wtg));
		/*if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2_v2=unq_nuts_ekc*nuts_wtg2;
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2_v2=unq_seeds_ekc*seeds_wtg2;
	  	if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2_v2=unq_lgmes_ekc*lgmes_wtg2;
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2_v2=unq_tofu_ekc*tofu_wtg2;*/
	/*Sugar*/
		if nuts_wtg ne 0 and unq_nuts_sug ne . then nuts_sug2=unq_nuts_sug*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sug ne . then seeds_sug2=unq_seeds_sug*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sug ne . then lgmes_sug2=unq_lgmes_sug*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sug ne . then tofu_sug2=unq_tofu_sug*tofu_wtg2;	
	/*Saturated fat*/
		if nuts_wtg ne 0 and unq_nuts_sat ne . then nuts_sat2=unq_nuts_sat*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sat ne . then seeds_sat2=unq_seeds_sat*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sat ne . then lgmes_sat2=unq_lgmes_sat*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sat ne . then tofu_sat2=unq_tofu_sat*tofu_wtg2;	
	/*Protein*/
		if nuts_wtg ne 0 and unq_nuts_pro ne . then nuts_pro2=unq_nuts_pro*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pro ne . then seeds_pro2=unq_seeds_pro*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pro ne . then lgmes_pro2=unq_lgmes_pro*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pro ne . then tofu_pro2=unq_tofu_pro*tofu_wtg2;	
	/*Vitamin D*/
		if nuts_wtg ne 0 and unq_nuts_vitD ne . then nuts_vitD2=unq_nuts_vitD*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_vitD ne . then seeds_vitD2=unq_seeds_vitD*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_vitD ne . then lgmes_vitD2=unq_lgmes_vitD*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_vitD ne . then tofu_vitD2=unq_tofu_vitD*tofu_wtg2;	
	/*Calcium*/
		if nuts_wtg ne 0 and unq_nuts_ca ne . then nuts_ca2=unq_nuts_ca*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ca ne . then seeds_ca2=unq_seeds_ca*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ca ne . then lgmes_ca2=unq_lgmes_ca*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ca ne . then tofu_ca2=unq_tofu_ca*tofu_wtg2;	
	/*Iron*/
		if nuts_wtg ne 0 and unq_nuts_fe ne . then nuts_fe2=unq_nuts_fe*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_fe ne . then seeds_fe2=unq_seeds_fe*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_fe ne . then lgmes_fe2=unq_lgmes_fe*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_fe ne . then tofu_fe2=unq_tofu_fe*tofu_wtg2;	
	/*Sodium*/
		if nuts_wtg ne 0 and unq_nuts_na ne . then nuts_na2=unq_nuts_na*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_na ne . then seeds_na2=unq_seeds_na*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_na ne . then lgmes_na2=unq_lgmes_na*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_na ne . then tofu_na2=unq_tofu_na*tofu_wtg2;	
	/*Potassium*/
		if nuts_wtg ne 0 and unq_nuts_k ne . then nuts_k2=unq_nuts_k*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_k ne . then seeds_k2=unq_seeds_k*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_k ne . then lgmes_k2=unq_lgmes_k*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_k ne . then tofu_k2=unq_tofu_k*tofu_wtg2;	
	/*Carbs*/
		if nuts_wtg ne 0 and unq_nuts_carb ne . then nuts_carb2=unq_nuts_carb*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_carb ne . then seeds_carb2=unq_seeds_carb*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_carb ne . then lgmes_carb2=unq_lgmes_carb*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_carb ne . then tofu_carb2=unq_tofu_carb*tofu_wtg2;
	/*MUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_mufa ne . then nuts_mufa2=unq_nuts_mufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_mufa ne . then seeds_mufa2=unq_seeds_mufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_mufa ne . then lgmes_mufa2=unq_lgmes_mufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_mufa ne . then tofu_mufa2=unq_tofu_mufa*tofu_wtg2;	
	/*PUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_pufa ne . then nuts_pufa2=unq_nuts_pufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pufa ne . then seeds_pufa2=unq_seeds_pufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pufa ne . then lgmes_pufa2=unq_lgmes_pufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pufa ne . then tofu_pufa2=unq_tofu_pufa*tofu_wtg2;	

/*For respondents that did not originally consume meat, nutrients=0 after replacement*/
	if beef_wtg=0 then beef_ekc2=0;
	if beef_wtg=0 then beef_sug2=0;
	if beef_wtg=0 then beef_sat2=0;
	if beef_wtg=0 then beef_pro2=0;
	if beef_wtg=0 then beef_vitD2=0;
	if beef_wtg=0 then beef_ca2=0;
	if beef_wtg=0 then beef_fe2=0;
	if beef_wtg=0 then beef_na2=0;
	if beef_wtg=0 then beef_k2=0;
	if beef_wtg=0 then beef_carb2=0;
	if beef_wtg=0 then beef_mufa2=0;
	if beef_wtg=0 then beef_pufa2=0;

	if lamb_wtg=0 then lamb_ekc2=0;
	if lamb_wtg=0 then lamb_sug2=0;
	if lamb_wtg=0 then lamb_sat2=0;
	if lamb_wtg=0 then lamb_pro2=0;
	if lamb_wtg=0 then lamb_vitD2=0;
	if lamb_wtg=0 then lamb_ca2=0;
	if lamb_wtg=0 then lamb_fe2=0;
	if lamb_wtg=0 then lamb_na2=0;
	if lamb_wtg=0 then lamb_k2=0;
	if lamb_wtg=0 then lamb_carb2=0;
	if lamb_wtg=0 then lamb_mufa2=0;
	if lamb_wtg=0 then lamb_pufa2=0;

	if pork_wtg=0 then pork_ekc2=0;
	if pork_wtg=0 then pork_sug2=0;
	if pork_wtg=0 then pork_sat2=0;
	if pork_wtg=0 then pork_pro2=0;
	if pork_wtg=0 then pork_vitD2=0;
	if pork_wtg=0 then pork_ca2=0;
	if pork_wtg=0 then pork_fe2=0;
	if pork_wtg=0 then pork_na2=0;
	if pork_wtg=0 then pork_k2=0;
	if pork_wtg=0 then pork_carb2=0;
	if pork_wtg=0 then pork_mufa2=0;
	if pork_wtg=0 then pork_pufa2=0;

	if lnchn_wtg=0 then lnchn_ekc2=0;
	if lnchn_wtg=0 then lnchn_sug2=0;
	if lnchn_wtg=0 then lnchn_sat2=0;
	if lnchn_wtg=0 then lnchn_pro2=0;
	if lnchn_wtg=0 then lnchn_vitD2=0;
	if lnchn_wtg=0 then lnchn_ca2=0;
	if lnchn_wtg=0 then lnchn_fe2=0;
	if lnchn_wtg=0 then lnchn_na2=0;
	if lnchn_wtg=0 then lnchn_k2=0;
	if lnchn_wtg=0 then lnchn_carb2=0;
	if lnchn_wtg=0 then lnchn_mufa2=0;
	if lnchn_wtg=0 then lnchn_pufa2=0;

/*For respondents that did not originally consume nsl, use a weighted average for nutrients*/
/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_ekc2=6.068735152*nuts_wtg2;
	if nuts_wtg=0 then nuts_sug2=0.023412133*nuts_wtg2;		/*Note that this is weighted avg. for FREE SUGARS*/
	if nuts_wtg=0 then nuts_sat2=0.078223051*nuts_wtg2;
	if nuts_wtg=0 then nuts_pro2=0.189748537*nuts_wtg2;
	if nuts_wtg=0 then nuts_vitD2=0*nuts_wtg2;
	if nuts_wtg=0 then nuts_ca2=1.047177739*nuts_wtg2;
	if nuts_wtg=0 then nuts_fe2=0.028762549*nuts_wtg2;
	if nuts_wtg=0 then nuts_na2=1.538556973*nuts_wtg2;
	if nuts_wtg=0 then nuts_k2=5.879183898*nuts_wtg2;
	if nuts_wtg=0 then nuts_carb2=0.208693214*nuts_wtg2;
	if nuts_wtg=0 then nuts_mufa2=0.250425621*nuts_wtg2;
	if nuts_wtg=0 then nuts_pufa2=0.184819969*nuts_wtg2;

	if seeds_wtg=0 then seeds_ekc2=5.588623188*seeds_wtg2;
	if seeds_wtg=0 then seeds_sug2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_sat2=0.053096123*seeds_wtg2;
	if seeds_wtg=0 then seeds_pro2=0.212654067*seeds_wtg2;
	if seeds_wtg=0 then seeds_vitD2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_ca2=1.625144928*seeds_wtg2;
	if seeds_wtg=0 then seeds_fe2=0.060998279*seeds_wtg2;
	if seeds_wtg=0 then seeds_na2=0.780842391*seeds_wtg2;
	if seeds_wtg=0 then seeds_k2=7.510996377*seeds_wtg2;
	if seeds_wtg=0 then seeds_carb2=0.236999647*seeds_wtg2;
	if seeds_wtg=0 then seeds_mufa2=0.111621132*seeds_wtg2;
	if seeds_wtg=0 then seeds_pufa2=0.269852745*seeds_wtg2;

	if lgmes_wtg=0 then lgmes_ekc2=0.93228815*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sug2=0.003114783*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sat2=0.001913132*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pro2=0.057528201*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_vitD2=0*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_ca2=0.366772379*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_fe2=0.01791809*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_na2=1.035202046*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_k2=2.539577153*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_carb2=0.161040051*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_mufa2=0.003398607*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pufa2=0.004636307*lgmes_wtg2;

	if tofu_wtg=0 then tofu_ekc2=2.428236398*tofu_wtg2;
	if tofu_wtg=0 then tofu_sug2=0.000317073*tofu_wtg2;
	if tofu_wtg=0 then tofu_sat2=0.020709869*tofu_wtg2;
	if tofu_wtg=0 then tofu_pro2=0.227237148*tofu_wtg2;
	if tofu_wtg=0 then tofu_vitD2=0*tofu_wtg2;
	if tofu_wtg=0 then tofu_ca2=1.770863039*tofu_wtg2;
	if tofu_wtg=0 then tofu_fe2=0.032112383*tofu_wtg2;
	if tofu_wtg=0 then tofu_na2=6.259924953*tofu_wtg2;
	if tofu_wtg=0 then tofu_k2=1.671575985*tofu_wtg2;
	if tofu_wtg=0 then tofu_carb2=0.114113884*tofu_wtg2;
	if tofu_wtg=0 then tofu_mufa2=0.03100454*tofu_wtg2;
	if tofu_wtg=0 then tofu_pufa2=0.065414953*tofu_wtg2;

/*Setting missing values to 0 here*/
	if beef_ekc=. then beef_ekc=0;
	if beef_sug=. then beef_sug=0;
	if beef_sat=. then beef_sat=0;
	if beef_pro=. then beef_pro=0;
	if beef_vitD=. then beef_vitD=0;
	if beef_ca=. then beef_ca=0;
	if beef_fe=. then beef_fe=0;
	if beef_na=. then beef_na=0;
	if beef_k=. then beef_k=0;
	if beef_carb=. then beef_carb=0;
	if beef_mufa=. then beef_mufa=0;
	if beef_pufa=. then beef_pufa=0;

	if lamb_ekc=. then lamb_ekc=0;
	if lamb_sug=. then lamb_sug=0;
	if lamb_sat=. then lamb_sat=0;
	if lamb_pro=. then lamb_pro=0;
	if lamb_vitD=. then lamb_vitD=0;
	if lamb_ca=. then lamb_ca=0;
	if lamb_fe=. then lamb_fe=0;
	if lamb_na=. then lamb_na=0;
	if lamb_k=. then lamb_k=0;
	if lamb_carb=. then lamb_carb=0;
	if lamb_mufa=. then lamb_mufa=0;
	if lamb_pufa=. then lamb_pufa=0;

	if pork_ekc=. then pork_ekc=0;
	if pork_sug=. then pork_sug=0;
	if pork_sat=. then pork_sat=0;
	if pork_pro=. then pork_pro=0;
	if pork_vitD=. then pork_vitD=0;
	if pork_ca=. then pork_ca=0;
	if pork_fe=. then pork_fe=0;
	if pork_na=. then pork_na=0;
	if pork_k=. then pork_k=0;
	if pork_carb=. then pork_carb=0;
	if pork_mufa=. then pork_mufa=0;
	if pork_pufa=. then pork_pufa=0;

	if lnchn_ekc=. then lnchn_ekc=0;
	if lnchn_sug=. then lnchn_sug=0;
	if lnchn_sat=. then lnchn_sat=0;
	if lnchn_pro=. then lnchn_pro=0;
	if lnchn_vitD=. then lnchn_vitD=0;
	if lnchn_ca=. then lnchn_ca=0;
	if lnchn_fe=. then lnchn_fe=0;
	if lnchn_na=. then lnchn_na=0;
	if lnchn_k=. then lnchn_k=0;
	if lnchn_carb=. then lnchn_carb=0;
	if lnchn_mufa=. then lnchn_mufa=0;
	if lnchn_pufa=. then lnchn_pufa=0;

	if nuts_ekc=. then nuts_ekc=0;
	if nuts_sug=. then nuts_sug=0;
	if nuts_sat=. then nuts_sat=0;
	if nuts_pro=. then nuts_pro=0;
	if nuts_vitD=. then nuts_vitD=0;
	if nuts_ca=. then nuts_ca=0;
	if nuts_fe=. then nuts_fe=0;
	if nuts_na=. then nuts_na=0;
	if nuts_k=. then nuts_k=0;
	if nuts_carb=. then nuts_carb=0;
	if nuts_mufa=. then nuts_mufa=0;
	if nuts_pufa=. then nuts_pufa=0;

	if seeds_ekc=. then seeds_ekc=0;
	if seeds_sug=. then seeds_sug=0;
	if seeds_sat=. then seeds_sat=0;
	if seeds_pro=. then seeds_pro=0;
	if seeds_vitD=. then seeds_vitD=0;
	if seeds_ca=. then seeds_ca=0;
	if seeds_fe=. then seeds_fe=0;
	if seeds_na=. then seeds_na=0;
	if seeds_k=. then seeds_k=0;
	if seeds_carb=. then seeds_carb=0;
	if seeds_mufa=. then seeds_mufa=0;
	if seeds_pufa=. then seeds_pufa=0;

	if lgmes_ekc=. then lgmes_ekc=0;
	if lgmes_sug=. then lgmes_sug=0;
	if lgmes_sat=. then lgmes_sat=0;
	if lgmes_pro=. then lgmes_pro=0;
	if lgmes_vitD=. then lgmes_vitD=0;
	if lgmes_ca=. then lgmes_ca=0;
	if lgmes_fe=. then lgmes_fe=0;
	if lgmes_na=. then lgmes_na=0;
	if lgmes_k=. then lgmes_k=0;
	if lgmes_carb=. then lgmes_carb=0;
	if lgmes_mufa=. then lgmes_mufa=0;
	if lgmes_pufa=. then lgmes_pufa=0;

	if tofu_ekc=. then tofu_ekc=0;
	if tofu_sug=. then tofu_sug=0;
	if tofu_sat=. then tofu_sat=0;
	if tofu_pro=. then tofu_pro=0;
	if tofu_vitD=. then tofu_vitD=0;
	if tofu_ca=. then tofu_ca=0;
	if tofu_fe=. then tofu_fe=0;
	if tofu_na=. then tofu_na=0;
	if tofu_k=. then tofu_k=0;
	if tofu_carb=. then tofu_carb=0;
	if tofu_mufa=. then tofu_mufa=0;
	if tofu_pufa=. then tofu_pufa=0;

/*Setting missing values to 0 for other foods here*/
	if milk_ekc=. then milk_ekc=0;
	if milk_sug=. then milk_sug=0;
	if milk_sat=. then milk_sat=0;
	if milk_pro=. then milk_pro=0;
	if milk_vitD=. then milk_vitD=0;
	if milk_ca=. then milk_ca=0;
	if milk_fe=. then milk_fe=0;
	if milk_na=. then milk_na=0;
	if milk_k=. then milk_k=0;
	if milk_carb=. then milk_carb=0;
	if milk_mufa=. then milk_mufa=0;
	if milk_pufa=. then milk_pufa=0;

	if cheese_ekc=. then cheese_ekc=0;
	if cheese_sug=. then cheese_sug=0;
	if cheese_sat=. then cheese_sat=0;
	if cheese_pro=. then cheese_pro=0;
	if cheese_vitD=. then cheese_vitD=0;
	if cheese_ca=. then cheese_ca=0;
	if cheese_fe=. then cheese_fe=0;
	if cheese_na=. then cheese_na=0;
	if cheese_k=. then cheese_k=0;
	if cheese_carb=. then cheese_carb=0;
	if cheese_mufa=. then cheese_mufa=0;
	if cheese_pufa=. then cheese_pufa=0;

	if yghrt_ekc=. then yghrt_ekc=0;
	if yghrt_sug=. then yghrt_sug=0;
	if yghrt_sat=. then yghrt_sat=0;
	if yghrt_pro=. then yghrt_pro=0;
	if yghrt_vitD=. then yghrt_vitD=0;
	if yghrt_ca=. then yghrt_ca=0;
	if yghrt_fe=. then yghrt_fe=0;
	if yghrt_na=. then yghrt_na=0;
	if yghrt_k=. then yghrt_k=0;
	if yghrt_carb=. then yghrt_carb=0;
	if yghrt_mufa=. then yghrt_mufa=0;
	if yghrt_pufa=. then yghrt_pufa=0;

  	if cream_ekc=. then cream_ekc=0;
	if cream_sug=. then cream_sug=0;
	if cream_sat=. then cream_sat=0;
	if cream_pro=. then cream_pro=0;
	if cream_vitD=. then cream_vitD=0;
	if cream_ca=. then cream_ca=0;
	if cream_fe=. then cream_fe=0;
	if cream_na=. then cream_na=0;
	if cream_k=. then cream_k=0;
	if cream_carb=. then cream_carb=0;
	if cream_mufa=. then cream_mufa=0;
	if cream_pufa=. then cream_pufa=0;

 	if butr_ekc=. then butr_ekc=0;
	if butr_sug=. then butr_sug=0;
	if butr_sat=. then butr_sat=0;
	if butr_pro=. then butr_pro=0;
	if butr_vitD=. then butr_vitD=0;
	if butr_ca=. then butr_ca=0;
	if butr_fe=. then butr_fe=0;
	if butr_na=. then butr_na=0;
	if butr_k=. then butr_k=0;
	if butr_carb=. then butr_carb=0;
	if butr_mufa=. then butr_mufa=0;
	if butr_pufa=. then butr_pufa=0;

	if frzn_ekc=. then frzn_ekc=0;
	if frzn_sug=. then frzn_sug=0;
	if frzn_sat=. then frzn_sat=0;
	if frzn_pro=. then frzn_pro=0;
	if frzn_vitD=. then frzn_vitD=0;
	if frzn_ca=. then frzn_ca=0;
	if frzn_fe=. then frzn_fe=0;
	if frzn_na=. then frzn_na=0;
	if frzn_k=. then frzn_k=0;
	if frzn_carb=. then frzn_carb=0;
	if frzn_mufa=. then frzn_mufa=0;
	if frzn_pufa=. then frzn_pufa=0;

	if soybev_ekc=. then soybev_ekc=0;
	if soybev_sug=. then soybev_sug=0;
	if soybev_sat=. then soybev_sat=0;
	if soybev_pro=. then soybev_pro=0;
	if soybev_vitD=. then soybev_vitD=0;
	if soybev_ca=. then soybev_ca=0;
	if soybev_fe=. then soybev_fe=0;
	if soybev_na=. then soybev_na=0;
	if soybev_k=. then soybev_k=0;
	if soybev_carb=. then soybev_carb=0;
	if soybev_mufa=. then soybev_mufa=0;
	if soybev_pufa=. then soybev_pufa=0;

	if other_ekc=. then other_ekc=0;
	if other_sug=. then other_sug=0;
	if other_sat=. then other_sat=0;
	if other_pro=. then other_pro=0;
	if other_vitD=. then other_vitD=0;
	if other_ca=. then other_ca=0;
	if other_fe=. then other_fe=0;
	if other_na=. then other_na=0;
	if other_k=. then other_k=0;
	if other_carb=. then other_carb=0;
	if other_mufa=. then other_mufa=0;
	if other_pufa=. then other_pufa=0;

	meat_pro=beef_pro+lamb_pro+pork_pro+lnchn_pro;
	nsl_pro=nuts_pro+seeds_pro+lgmes_pro+tofu_pro+soybev_pro;
	meat_pro2=beef_pro2+lamb_pro2+pork_pro2+lnchn_pro2;
	nsl_pro2=nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+soybev_pro;
	dairy_pro=milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro;

	meat_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc;
	nsl_ekc=nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	meat_ekc2=beef_ekc2+lamb_ekc2+pork_ekc2+lnchn_ekc2;
	nsl_ekc2=nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc;
	dairy_ekc=milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc;

/*Variables for carbs*/
	meat_carb=beef_carb+lamb_carb+pork_carb+lnchn_carb;
	dairy_carb=milk_carb+cheese_carb+yghrt_carb+cream_carb+butr_carb+frzn_carb;
	nsl_carb=nuts_carb+seeds_carb+lgmes_carb+tofu_carb+soybev_carb;
	meat_carb2=beef_carb2+lamb_carb2+pork_carb2+lnchn_carb2;
	nsl_carb2=nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb;
	
	diet_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc+nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	diet_ekc2=beef_ekc2+lamb_ekc2+pork_ekc2+lnchn_ekc2+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc;

/*keep sampleid beef_ekc lamb_ekc pork_ekc lnchn_ekc beef_ekc2 lamb_ekc2 pork_ekc2 lnchn_ekc2 
	 nuts_ekc seeds_ekc lgmes_ekc tofu_ekc nuts_ekc2 seeds_ekc2 lgmes_ekc2 tofu_ekc2
	 unq_nuts_ekc unq_seeds_ekc unq_lgmes_ekc unq_tofu_ekc
	 nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2;*/

run;
/*17,921 observations (Master Files)*/

/*Verification examples (ekc):
	- Person 1:
		- Consumed luncheon and nuts
			- ekc luncheon post-replacement = 218.25 (lnchn_ekc)/2 = 109.125
			- ekc nuts post-replacement =  102.84 (ekc of nuts originally consumed) + (5.87 (unique nuts multiplier) x (55.02 - 17.52) (nuts_wtg2 - nuts_wtg)) = 322.96
	- Person 2:
		- Did not consume meat, only nuts
		- No replacement done, ekc of nuts before and after are the same
	- Person 3:
		- Consumed beef and luncheon, did not consume any nuts, seeds, or legumes
			- ekc beef post-replacement = 261.31/2 = 130.65
			- ekc luncheon post-replacement = 232.5/2 = 116.25
			- ekc nuts post-replacement = 6.07 (avg. weighted ekc from 'Food-List') x nuts_wtg2 = 191.3
			- ekc seeds post-replacement = 5.59 (avg. weighted ekc from 'Food-List') x seeds_wtg2 = 20.68
			- ekc legumes post-replacement = 0.93 (avg. weighted ekc from 'Food-List') x lgmes_wtg2 = 58
			- ekc tofu post-replacement = 2.43 (avg. weighted ekc from 'Food-List') x tofu_wtg2 = 17.17
	- Person 13: 
		- Consumed pork, nuts, and legumes
			- ekc pork post-replacement = 59.616 (pork_ekc)/2 = 29.81
			- ekc nuts post-replacement =  35.25 (ekc of nuts originally consumed) + (6.64 (unique nuts multiplier) x (7.14 - 5.3) (nuts_wtg2 - nuts_wtg)) = 47.4
			- ekc legumes post-replacement =  14.68 (ekc of legumes originally consumed) + (0.81 (unique nuts multiplier) x (24.39 - 18.13) (legumes_wtg2 - legmes_wtg)) = 19.75*/

proc means n nmiss mean data=rs1_50_nutr;
	var beef_ekc beef_ekc2 beef_sug beef_sug2 beef_sat beef_sat2 beef_pro beef_pro2 beef_vitD beef_vitD2 beef_ca beef_ca2 beef_fe beef_fe2 beef_na beef_na2 beef_k beef_k2 beef_carb beef_carb2 beef_mufa beef_mufa2 beef_pufa beef_pufa2
		lamb_ekc lamb_ekc2 lamb_sug lamb_sug2 lamb_sat lamb_sat2 lamb_pro lamb_pro2 lamb_vitD lamb_vitD2 lamb_ca lamb_ca2 lamb_fe lamb_fe2 lamb_na lamb_na2 lamb_k lamb_k2 lamb_carb lamb_carb2 lamb_mufa lamb_mufa2 lamb_pufa lamb_pufa2
		pork_ekc pork_ekc2 pork_sug pork_sug2 pork_sat pork_sat2 pork_pro pork_pro2 pork_vitD pork_vitD2 pork_ca pork_ca2 pork_fe pork_fe2 pork_na pork_na2 pork_k pork_k2 pork_carb pork_carb2 pork_mufa pork_mufa2 pork_pufa pork_pufa2
		lnchn_ekc lnchn_ekc2 lnchn_sug lnchn_sug2 lnchn_sat lnchn_sat2 lnchn_pro lnchn_pro2 lnchn_vitD lnchn_vitD2 lnchn_ca lnchn_ca2 lnchn_fe lnchn_fe2 lnchn_na lnchn_na2 lnchn_k lnchn_k2 lnchn_carb lnchn_carb2 lnchn_mufa lnchn_mufa2 lnchn_pufa lnchn_pufa2
		nuts_ekc nuts_ekc2 nuts_sug nuts_sug2 nuts_sat nuts_sat2 nuts_pro nuts_pro2 nuts_vitD nuts_vitD2 nuts_ca nuts_ca2 nuts_fe nuts_fe2 nuts_na nuts_na2 nuts_k nuts_k2 nuts_carb nuts_carb2 nuts_mufa nuts_mufa2 nuts_pufa nuts_pufa2
		seeds_ekc seeds_ekc2 seeds_sug seeds_sug2 seeds_sat seeds_sat2 seeds_pro seeds_pro2 seeds_vitD seeds_vitD2 seeds_ca seeds_ca2 seeds_fe seeds_fe2 seeds_na seeds_na2 seeds_k seeds_k2 seeds_carb seeds_carb2 seeds_mufa seeds_mufa2 seeds_pufa seeds_pufa2
		lgmes_ekc lgmes_ekc2 lgmes_sug lgmes_sug2 lgmes_sat lgmes_sat2 lgmes_pro lgmes_pro2 lgmes_vitD lgmes_vitD2 lgmes_ca lgmes_ca2 lgmes_fe lgmes_fe2 lgmes_na lgmes_na2 lgmes_k lgmes_k2 lgmes_carb lgmes_carb2 lgmes_mufa lgmes_mufa2 lgmes_pufa lgmes_pufa2
		tofu_ekc tofu_ekc2 tofu_sug tofu_sug2 tofu_sat tofu_sat2 tofu_pro tofu_pro2 tofu_vitD tofu_vitD2 tofu_ca tofu_ca2 tofu_fe tofu_fe2 tofu_na tofu_na2 tofu_k tofu_k2 tofu_carb tofu_carb2 tofu_mufa tofu_mufa2 tofu_pufa tofu_pufa2
		milk_ekc milk_sug milk_sat milk_pro milk_vitD milk_ca milk_fe milk_na milk_k milk_carb milk_mufa milk_pufa 
		cheese_ekc cheese_sug cheese_sat cheese_pro cheese_vitD cheese_ca cheese_fe cheese_na cheese_k cheese_carb cheese_mufa cheese_pufa
		yghrt_ekc yghrt_sug yghrt_sat yghrt_pro yghrt_vitD yghrt_ca yghrt_fe yghrt_na yghrt_k yghrt_carb yghrt_mufa yghrt_pufa
		cream_ekc cream_sug cream_sat cream_pro cream_vitD cream_ca cream_fe cream_na cream_k cream_carb cream_mufa cream_pufa
		butr_ekc butr_sug butr_sat butr_pro butr_vitD butr_ca butr_fe butr_na butr_k butr_carb butr_mufa butr_pufa
		frzn_ekc frzn_sug frzn_sat frzn_pro frzn_vitD frzn_ca frzn_fe frzn_na frzn_k frzn_carb frzn_mufa frzn_pufa
		soybev_ekc soybev_sug soybev_sat soybev_pro soybev_vitD soybev_ca soybev_fe soybev_na soybev_k soybev_carb soybev_mufa soybev_pufa
		other_ekc other_sug other_sat other_pro other_vitD other_ca other_fe other_na other_k other_carb other_mufa other_pufa
		diet_ekc diet_ekc2;
run; 

/*Some nutrient values are still missing. These are genuine missing values at the FID level. For example, there are 291 missing values for beef_vitD.
These respondents consumed beef, but vitD values are missing. It's okay to set them to 0 as done below, because we need to aggregate nutrient totals.
To verify, run the following lines:

proc means n nmiss data=rs1_50_nutr; var beef_vitD beef_vitD2; run;
data a;
	set rs1_50_nutr;
	if beef_vitD=. and beef_vitD2 ne 0;
	id=1;
	keep sampleid beef_wtg beef_vitD beef_vitD2 id;
run;

data b;
	set sbgrps;
	if sampleid='1209073911176613746_' and food_subgrp=1;
run;*/

/*Set missing alues to 0 or else they will not add up*/
data rs1_50_nutr;
	set rs1_50_nutr;
	if beef_vitD2=. then beef_vitD2=0;
	/*if pork_sug2=. then pork_sug2=0;*/
	if pork_sat2=. then pork_sat2=0;
	if pork_vitD2=. then pork_vitD2=0;
	if pork_fe2=. then pork_fe2=0;
	if pork_mufa2=. then pork_mufa2=0;
	if pork_pufa2=. then pork_pufa2=0;
	/*if lnchn_sug2=. then lnchn_sug2=0;*/
	if lnchn_vitD2=. then lnchn_vitD2=0;
	/*if nuts_sug2=. then nuts_sug2=0;*/
	if nuts_vitD2=. then nuts_vitD2=0;
	/*if seeds_sug2=. then seeds_sug2=0;*/
	if seeds_vitD2=. then seeds_vitD2=0;
	/*if lgmes_sug2=. then lgmes_sug2=0;*/
	if lgmes_vitD2=. then lgmes_vitD2=0;
run;

/* !!!!!!!!!!!!!!!!!!!!!!! */
/*Use this as input for NCI*/
/* !!!!!!!!!!!!!!!!!!!!!!! */
data rs1_50_nutr_nci;
	set rs1_50_nutr;
/*Nutrient totals*/
/*Before - Note that these are equivalent to fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot (HS)*/
	/*tot_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc;
	tot_sug=beef_sug+lamb_sug+pork_sug+lnchn_sug+nuts_sug+seeds_sug+lgmes_sug+tofu_sug+milk_sug+cheese_sug+yghrt_sug+cream_sug+butr_sug+frzn_sug+other_sug;
	tot_sat=beef_sat+lamb_sat+pork_sat+lnchn_sat+nuts_sat+seeds_sat+lgmes_sat+tofu_sat+milk_sat+cheese_sat+yghrt_sat+cream_sat+butr_sat+frzn_sat+other_sat;
	tot_pro=beef_pro+lamb_pro+pork_pro+lnchn_pro+nuts_pro+seeds_pro+lgmes_pro+tofu_pro+milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro+other_pro;
	tot_vitD=beef_vitD+lamb_vitD+pork_vitD+lnchn_vitD+nuts_vitD+seeds_vitD+lgmes_vitD+tofu_vitD+milk_vitD+cheese_vitD+yghrt_vitD+cream_vitD+butr_vitD+frzn_vitD+other_vitD;
	tot_ca=beef_ca+lamb_ca+pork_ca+lnchn_ca+nuts_ca+seeds_ca+lgmes_ca+tofu_ca+milk_ca+cheese_ca+yghrt_ca+cream_ca+butr_ca+frzn_ca+other_ca;
	tot_fe=beef_fe+lamb_fe+pork_fe+lnchn_fe+nuts_fe+seeds_fe+lgmes_fe+tofu_fe+milk_fe+cheese_fe+yghrt_fe+cream_fe+butr_fe+frzn_fe+other_fe;
	tot_na=beef_na+lamb_na+pork_na+lnchn_na+nuts_na+seeds_na+lgmes_na+tofu_na+milk_na+cheese_na+yghrt_na+cream_na+butr_na+frzn_na+other_na;
	tot_k=beef_k+lamb_k+pork_k+lnchn_k+nuts_k+seeds_k+lgmes_k+tofu_k+milk_k+cheese_k+yghrt_k+cream_k+butr_k+frzn_k+other_k;

	/*Note that the variable fsddesa refers to saturated fat as a % of TEI*/
	/*Note that we created a variable for free sugars as a % of TEI in step 9 (tot_sug_pcnt)*/
	/*I checked if tot_sug = tot_free_sug and ot checks out; also tot_sug_pcnt_v2 = tot_sug_pcnt*/

	/*tot_sug=beef_sug+lamb_sug+pork_sug+lnchn_sug+nuts_sug+seeds_sug+lgmes_sug+tofu_sug+milk_sug+cheese_sug+yghrt_sug+cream_sug+butr_sug+frzn_sug+other_sug;
	tot_sug_pcnt_v2=((tot_sug*4)/fsddekc)*100;

/*After*/
	tot_ekc2=beef_ekc2+lamb_ekc2+pork_ekc2+lnchn_ekc2+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc;
	tot_sug2=beef_sug2+lamb_sug2+pork_sug2+lnchn_sug2+nuts_sug2+seeds_sug2+lgmes_sug2+tofu_sug2+milk_sug+cheese_sug+yghrt_sug+cream_sug+butr_sug+frzn_sug+other_sug;
	tot_sat2=beef_sat2+lamb_sat2+pork_sat2+lnchn_sat2+nuts_sat2+seeds_sat2+lgmes_sat2+tofu_sat2+milk_sat+cheese_sat+yghrt_sat+cream_sat+butr_sat+frzn_sat+other_sat;
	tot_pro2=beef_pro2+lamb_pro2+pork_pro2+lnchn_pro2+nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro+other_pro;
	tot_vitD2=beef_vitD2+lamb_vitD2+pork_vitD2+lnchn_vitD2+nuts_vitD2+seeds_vitD2+lgmes_vitD2+tofu_vitD2+milk_vitD+cheese_vitD+yghrt_vitD+cream_vitD+butr_vitD+frzn_vitD+other_vitD;
	tot_ca2=beef_ca2+lamb_ca2+pork_ca2+lnchn_ca2+nuts_ca2+seeds_ca2+lgmes_ca2+tofu_ca2+milk_ca+cheese_ca+yghrt_ca+cream_ca+butr_ca+frzn_ca+other_ca;
	tot_fe2=beef_fe2+lamb_fe2+pork_fe2+lnchn_fe2+nuts_fe2+seeds_fe2+lgmes_fe2+tofu_fe2+milk_fe+cheese_fe+yghrt_fe+cream_fe+butr_fe+frzn_fe+other_fe;
	tot_na2=beef_na2+lamb_na2+pork_na2+lnchn_na2+nuts_na2+seeds_na2+lgmes_na2+tofu_na2+milk_na+cheese_na+yghrt_na+cream_na+butr_na+frzn_na+other_na;
	tot_k2=beef_k2+lamb_k2+pork_k2+lnchn_k2+nuts_k2+seeds_k2+lgmes_k2+tofu_k2+milk_k+cheese_k+yghrt_k+cream_k+butr_k+frzn_k+other_k;
	tot_carb2=beef_carb2+lamb_carb2+pork_carb2+lnchn_carb2+nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb+milk_carb+cheese_carb+yghrt_carb+cream_carb+butr_carb+frzn_carb+other_carb;
	tot_mufa2=beef_mufa2+lamb_mufa2+pork_mufa2+lnchn_mufa2+nuts_mufa2+seeds_mufa2+lgmes_mufa2+tofu_mufa2+milk_mufa+cheese_mufa+yghrt_mufa+cream_mufa+butr_mufa+frzn_mufa+other_mufa;
	tot_pufa2=beef_pufa2+lamb_pufa2+pork_pufa2+lnchn_pufa2+nuts_pufa2+seeds_pufa2+lgmes_pufa2+tofu_pufa2+milk_pufa+cheese_pufa+yghrt_pufa+cream_pufa+butr_pufa+frzn_pufa+other_pufa;

	/*Free sugars and saturated fat expressed as a percentage of total energy intake*/
	if tot_sug2 ne 0 and tot_ekc2 ne 0 then tot_sug2_pcnt=((tot_sug2*4)/tot_ekc2)*100;
	if tot_sug2=0 or tot_ekc2=0 then tot_sug2_pcnt=0;

	if tot_sat2 ne 0 and tot_ekc2 ne 0 then tot_sat2_pcnt=((tot_sat2*9)/tot_ekc2)*100;
	if tot_sat2=0 or tot_ekc2=0 then tot_sat2_pcnt=0;

	/*keep sampleid suppid wts_m wts_mhw admfw dhhddri dhh_sex dhh_age mhwdbmi mhwdhtm mhwdwtk
	fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_sug2_pcnt tot_sat2_pcnt;*/
run;
/*17,921 observations (Master Files)*/

/*Preliminary results (nutrients)*/
proc means n nmiss mean min max data=rs1_50_nutr_nci;	
		var fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa fsddcar fsddfam fsddfap tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_carb2 tot_sug2_pcnt tot_sat2_pcnt
		tot_mufa2 tot_pufa2;
run;
/*g of free sug (tot_free_sug) is around 53 and free sug as % of TEI is around 11, which is in line with Rana et al. 2021*/

/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Input for NCI w/ supplements*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
data rs1_50_nutr_nci;
	set rs1_50_nutr_nci;
	idnty=1;
run;

proc sort data=rs1_50_nutr_nci; by sampleid suppid; run;
proc sort data=vst_nutr_cncrn; by sampleid suppid; run;

data rs1_50_nutr_nci_supp;
	merge rs1_50_nutr_nci vst_nutr_cncrn;
	by sampleid suppid;
	if idnty=1;
	drop idnty;
run; 
/*17,921 obs*/

data rs1_50_nutr_nci_supp;
	set rs1_50_nutr_nci_supp;
	/*vitD supplement users: vitD_supp_user=1; non-users: vitD_supp_user=2*/
	if vsdfdmg=1 then vitD_supp_user=1; else vitD_supp_user=2;
	if vsdfcal=1 then cal_supp_user=1; else cal_supp_user=2;
	if vsdfiro=1 then iron_supp_user=1; else iron_supp_user=2;
	if vsdfpot=1 then pot_supp_user=1; else pot_supp_user=2;
run;

data rs1_50_nutr_nci_supp;
	set rs1_50_nutr_nci_supp;

/*Nutrient intakes from food + supplements (observed)*/
	if VSTDCAL ne . then tot_ca_supp=FSDDCAL+VSTDCAL;
	if VSTDIRO ne . then tot_fe_supp=FSDDIRO+VSTDIRO;
	if VSTDPOT ne . then tot_k_supp=FSDDPOT+VSTDPOT;
	if VSTDDMG ne . then tot_vitD_supp=FSDDDMG+VSTDDMG;
	if VSTDSOD ne . then tot_na_supp=FSDDSOD+VSTDSOD;

	if VSTDCAL=. then tot_ca_supp=FSDDCAL;
	if VSTDIRO=. then tot_fe_supp=FSDDIRO;
	if VSTDPOT=. then tot_k_supp=FSDDPOT;
	if VSTDDMG=. then tot_vitD_supp=FSDDDMG;
	if VSTDSOD=. then tot_na_supp=FSDDSOD; 

/*Nutrient intakes from food + supplements (replacements)*/
	if VSTDCAL ne . then tot_ca2_supp=tot_ca2+VSTDCAL;
	if VSTDIRO ne . then tot_fe2_supp=tot_fe2+VSTDIRO;
	if VSTDPOT ne . then tot_k2_supp=tot_k2+VSTDPOT;
	if VSTDDMG ne . then tot_vitD2_supp=tot_vitD2+VSTDDMG;
	if VSTDSOD ne . then tot_na2_supp=tot_na2+VSTDSOD;

	if VSTDCAL=. then tot_ca2_supp=tot_ca2;
	if VSTDIRO=. then tot_fe2_supp=tot_fe2;
	if VSTDPOT=. then tot_k2_supp=tot_k2;
	if VSTDDMG=. then tot_vitD2_supp=tot_vitD2;
	if VSTDSOD=. then tot_na2_supp=tot_na2; 

run;

/*Datasets for vitD*/
data rs1_50_supp_users_vitD;
	set rs1_50_nutr_nci_supp;
	if vitD_supp_user=1;
run;
/* 6278 observations */
data rs1_50_supp_nonusers_vitD;
	set rs1_50_nutr_nci_supp;
	if vitD_supp_user=2;
run;
/* 11643 observations */

/*Datasets for iron*/
data rs1_50_supp_users_iron;
	set rs1_50_nutr_nci_supp;
	if iron_supp_user=1;
run;
/* 2739 observations */
data rs1_50_supp_nonusers_iron;
	set rs1_50_nutr_nci_supp;
	if iron_supp_user=2;
run;
/* 15182 observations */

/*Datasets for calcium*/
data rs1_50_supp_users_cal;
	set rs1_50_nutr_nci_supp;
	if cal_supp_user=1;
run;
/* 4550 observations */
data rs1_50_supp_nonusers_cal;
	set rs1_50_nutr_nci_supp;
	if cal_supp_user=2;
run;
/* 13371 observations */

/*Datasets for potassium*/
data rs1_50_supp_users_pot;
	set rs1_50_nutr_nci_supp;
	if pot_supp_user=1;
run;
/* 1987 observations */
data rs1_50_supp_nonusers_pot;
	set rs1_50_nutr_nci_supp;
	if pot_supp_user=2;
run;
/* 15934 observations */

proc means n nmiss mean min max data=rs1_50_nutr_nci_supp;	
	var fsddcal fsddiro fsddpot fsdddmg fsddsod tot_ca2 tot_fe2 tot_vitD2 tot_k2 tot_na2
		tot_ca_supp tot_fe_supp tot_k_supp tot_vitD_supp tot_na_supp tot_ca2_supp tot_fe2_supp tot_k2_supp tot_vitD2_supp tot_na2_supp;
run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Use this for health outcome anaylses*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */

data rs1_50_nutr_nci;
	set rs1_50_nutr_nci;

/*Observed diets*/

	/*Red meat*/
	red_meat_wtg=beef_wtg+lamb_wtg+pork_wtg;
	red_meat_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2;

	/*Nuts and seeds*/
	nts_sds_wtg=nuts_wtg+seeds_wtg;
	nts_sds_wtg2=nuts_wtg2+seeds_wtg2;

run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/* Use this for nci anaylses for foods */
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*This can be used for observed diets and RS1-25% but NOT RS1-50% or RS2 scenarios (need milk_wtg2)*/
data rs1_50_food_nci;
	set rs1_50_nutr_nci;
	keep sampleid suppid seq2 weekend wts_m sex dhh_age
		red_meat_wtg lnchn_wtg nts_sds_wtg lgmes_wtg milk_wtg
		red_meat_wtg2 lnchn_wtg2 nts_sds_wtg2 lgmes_wtg2 /*milk_wtg2*/;
run;
/*17,921 obs*/

/*Check red meat intake (obs) for males*/
data a_m; set rs1_50_food_nci; if sex=0; run;
proc means data=a_m; var red_meat_wtg; run;

/*Check red meat intake (obs) for females*/
data a_f; set rs1_50_food_nci; if sex=1; run;
proc means data=a_f; var red_meat_wtg; run;

/******************************************************************************/
/* RS1 -> Replace 25% of red and processed meat with nuts, seeds, and legumes */
/******************************************************************************/

/************************************/
/* Conduct replacements - g of food */
/************************************/
data rs1_25;
	set baseline_final;

/*If the individual consumed meat, multiply by 0.75*/
	if meat_wtg ne . then meat_wtg2=meat_wtg-(meat_wtg*0.25);
	if beef_wtg ne . then beef_wtg2=beef_wtg-(beef_wtg*0.25);
	if lamb_wtg ne . then lamb_wtg2=lamb_wtg-(lamb_wtg*0.25);
	if pork_wtg ne . then pork_wtg2=pork_wtg-(pork_wtg*0.25);
	if lnchn_wtg ne . then lnchn_wtg2=lnchn_wtg-(lnchn_wtg*0.25);

/*If the individual consumed meat AND nuts OR seeds OR legumes OR tofu*/
	/*Beef*/
	if beef_wtg ne . and nuts_wtg ne . then nuts_beef_wtg2=beef_wtg*0.25*nuts_pcnt;
	if beef_wtg ne . and seeds_wtg ne . then seeds_beef_wtg2=beef_wtg*0.25*seeds_pcnt;
	if beef_wtg ne . and lgmes_wtg ne . then lgmes_beef_wtg2=beef_wtg*0.25*lgmes_pcnt;
	if beef_wtg ne . and tofu_wtg ne . then tofu_beef_wtg2=beef_wtg*0.25*tofu_pcnt;	
	/*Lamb*/
	if lamb_wtg ne . and nuts_wtg ne . then nuts_lamb_wtg2=lamb_wtg*0.25*nuts_pcnt;
	if lamb_wtg ne . and seeds_wtg ne . then seeds_lamb_wtg2=lamb_wtg*0.25*seeds_pcnt;
	if lamb_wtg ne . and lgmes_wtg ne . then lgmes_lamb_wtg2=lamb_wtg*0.25*lgmes_pcnt;	
	if lamb_wtg ne . and tofu_wtg ne . then tofu_lamb_wtg2=lamb_wtg*0.25*tofu_pcnt;
	/*Pork*/
	if pork_wtg ne . and nuts_wtg ne . then nuts_pork_wtg2=pork_wtg*0.25*nuts_pcnt;
	if pork_wtg ne . and seeds_wtg ne . then seeds_pork_wtg2=pork_wtg*0.25*seeds_pcnt;	
	if pork_wtg ne . and lgmes_wtg ne . then lgmes_pork_wtg2=pork_wtg*0.25*lgmes_pcnt;	
	if pork_wtg ne . and tofu_wtg ne . then tofu_pork_wtg2=pork_wtg*0.25*tofu_pcnt;
	/*Luncheon and other meats*/	
	if lnchn_wtg ne . and nuts_wtg ne . then nuts_lnchn_wtg2=lnchn_wtg*0.25*nuts_pcnt;
	if lnchn_wtg ne . and seeds_wtg ne . then seeds_lnchn_wtg2=lnchn_wtg*0.25*seeds_pcnt;
	if lnchn_wtg ne . and lgmes_wtg ne . then lgmes_lnchn_wtg2=lnchn_wtg*0.25*lgmes_pcnt;
	if lnchn_wtg ne . and tofu_wtg ne . then tofu_lnchn_wtg2=lnchn_wtg*0.25*tofu_pcnt;

/*If the individual consumed nuts OR seeds OR legumes OR tofu BUT NOT meat*/
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and nuts_wtg ne . then nuts_wtg2=nuts_wtg;
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and seeds_wtg ne . then seeds_wtg2=seeds_wtg;
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and lgmes_wtg ne . then lgmes_wtg2=lgmes_wtg;
	if beef_wtg=. and lamb_wtg=. and pork_wtg=. and lnchn_wtg=. and tofu_wtg ne . then tofu_wtg2=tofu_wtg;

/*If the individual did not originally consume meat, set to 0*/
	if meat_wtg=. then meat_wtg=0;
	if beef_wtg=. then beef_wtg=0;
	if lamb_wtg=. then lamb_wtg=0;
	if pork_wtg=. then pork_wtg=0;
	if lnchn_wtg=. then lnchn_wtg=0;

/*If the individual did not originally consume nsl, set to 0*/
	if nsl_wtg=. then nsl_wtg=0;
	if nuts_wtg=. then nuts_wtg=0;
	if seeds_wtg=. then seeds_wtg=0;
	if lgmes_wtg=. then lgmes_wtg=0;
	if tofu_wtg=. then tofu_wtg=0;	

/*Set missing values post-replacement to 0*/
	if beef_wtg2=. then beef_wtg2=0;
	if lamb_wtg2=. then lamb_wtg2=0;
	if pork_wtg2=. then pork_wtg2=0;
	if lnchn_wtg2=. then lnchn_wtg2=0;

	if nuts_wtg2=. then nuts_wtg2=0;
	if seeds_wtg2=. then seeds_wtg2=0;
	if lgmes_wtg2=. then lgmes_wtg2=0;
	if tofu_wtg2=. then tofu_wtg2=0;

	if nuts_beef_wtg2=. then nuts_beef_wtg2=0;
	if seeds_beef_wtg2=. then seeds_beef_wtg2=0;
	if lgmes_beef_wtg2=. then lgmes_beef_wtg2=0;
	if tofu_beef_wtg2=. then tofu_beef_wtg2=0;

	if nuts_lamb_wtg2=. then nuts_lamb_wtg2=0;
	if seeds_lamb_wtg2=. then seeds_lamb_wtg2=0;
	if lgmes_lamb_wtg2=. then lgmes_lamb_wtg2=0;
	if tofu_lamb_wtg2=. then tofu_lamb_wtg2=0;

	if nuts_pork_wtg2=. then nuts_pork_wtg2=0;
	if seeds_pork_wtg2=. then seeds_pork_wtg2=0;
	if lgmes_pork_wtg2=. then lgmes_pork_wtg2=0;
	if tofu_pork_wtg2=. then tofu_pork_wtg2=0;

	if nuts_lnchn_wtg2=. then nuts_lnchn_wtg2=0;
	if seeds_lnchn_wtg2=. then seeds_lnchn_wtg2=0;
	if lgmes_lnchn_wtg2=. then lgmes_lnchn_wtg2=0;
	if tofu_lnchn_wtg2=. then tofu_lnchn_wtg2=0;

/*Later we have to account for other foods, set to 0 here*/
	if milk_wtg=. then milk_wtg=0;
	if cheese_wtg=. then cheese_wtg=0;
	if yghrt_wtg=. then yghrt_wtg=0;
	if cream_wtg=. then cream_wtg=0;
	if butr_wtg=. then butr_wtg=0;
	if frzn_wtg=. then frzn_wtg=0;
	if soybev_wtg=. then soybev_wtg=0;
	if other_wtg=. then other_wtg=0;

/*If the individual consumed meat BUT NOT nuts OR seeds OR legumes OR tofu, use ratios for overall sample*/
	if meat_wtg ne 0 and nsl_wtg=0 then nuts_wtg2=(beef_wtg*0.25*0.301588528)+(lamb_wtg*0.25*0.301588528)+(pork_wtg*0.25*0.301588528)+(lnchn_wtg*0.25*0.301588528);
	if meat_wtg ne 0 and nsl_wtg=0 then seeds_wtg2=(beef_wtg*0.25*0.03540598)+(lamb_wtg*0.25*0.03540598)+(pork_wtg*0.25*0.03540598)+(lnchn_wtg*0.25*0.03540598);
	if meat_wtg ne 0 and nsl_wtg=0 then lgmes_wtg2=(beef_wtg*0.25*0.595355613)+(lamb_wtg*0.25*0.595355613)+(pork_wtg*0.25*0.595355613)+(lnchn_wtg*0.25*0.595355613);
	if meat_wtg ne 0 and nsl_wtg=0 then tofu_wtg2=(beef_wtg*0.25*0.067649879)+(lamb_wtg*0.25*0.067649879)+(pork_wtg*0.25*0.067649879)+(lnchn_wtg*0.25*0.067649879);

/*Create one variable for nuts, seeds, and legumes weight post-replacement, accounting for g of nsl at baseline*/
	if meat_wtg ne 0 and nsl_wtg ne 0 then nuts_wtg2=nuts_wtg+nuts_beef_wtg2+nuts_lamb_wtg2+nuts_pork_wtg2+nuts_lnchn_wtg2;
	if meat_wtg ne 0 and nsl_wtg ne 0 then seeds_wtg2=seeds_wtg+seeds_beef_wtg2+seeds_lamb_wtg2+seeds_pork_wtg2+seeds_lnchn_wtg2;
	if meat_wtg ne 0 and nsl_wtg ne 0 then lgmes_wtg2=lgmes_wtg+lgmes_beef_wtg2+lgmes_lamb_wtg2+lgmes_pork_wtg2+lgmes_lnchn_wtg2;
	if meat_wtg ne 0 and nsl_wtg ne 0 then tofu_wtg2=tofu_wtg+tofu_beef_wtg2+tofu_lamb_wtg2+tofu_pork_wtg2+tofu_lnchn_wtg2;

/*Create variables for total meat and total nsl g post-replacement*/
/*Note that beef_wtg2+lamb_wtg2+pork_wtg2+lnchn_wtg2 (i.e., meat_wtg2) should = nsl_wtg2 - nsl_wtg*/
	meat_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2+lnchn_wtg2;
	nsl_wtg2=nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg;

	diet_wtg=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+soybev_wtg;
	diet_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2+lnchn_wtg2+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+other_wtg+nuts_wtg2+seeds_wtg2+lgmes_wtg2+tofu_wtg2+soybev_wtg;

/*This is a test to see if we are accounting for ALL foods (compare to fsddwtg)*/
	/*fsddwtg_chk=beef_wtg+lamb_wtg+pork_wtg+lnchn_wtg+nuts_wtg+seeds_wtg+lgmes_wtg+tofu_wtg+milk_wtg+cheese_wtg+yghrt_wtg+cream_wtg+butr_wtg+frzn_wtg+soybev_wtg+other_wtg;

/*To ensure math checks out by hand, just keep relevant variables*/
/*keep sampleid beef_wtg lamb_wtg pork_wtg lnchn_wtg nsl_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg
	 beef_wtg2 lamb_wtg2 pork_wtg2 lnchn_wtg2 nsl_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2
	 nuts_beef_wtg2 nuts_lamb_wtg2 nuts_pork_wtg2 nuts_lnchn_wtg2
	 seeds_beef_wtg2 seeds_lamb_wtg2 seeds_pork_wtg2 seeds_lnchn_wtg2
	 lgmes_beef_wtg2 lgmes_lamb_wtg2 lgmes_pork_wtg2 lgmes_lnchn_wtg2
	 tofu_beef_wtg2 tofu_lamb_wtg2 tofu_pork_wtg2 tofu_lnchn_wtg2
	 nuts_pcnt seeds_pcnt lgmes_pcnt tofu_pcnt
	 meat_wtg nsl_wtg meat_wtg2 nsl_wtg2;*/

run;
/*17,921 observations (Master Files)*/

/*Verification example:
	- Person 1: 
		- Consumed 75 g of lnchn and 17.519 g of nuts
		- 75 g * 0.25 = 18.75 g of lnchn to replace with nuts
		- nuts_wtg2 = 17.519 g + 18.75 g = 36.269 g
		- lnchn_wtg2 = 75 - (75 * 0.25) = 56.25 g
	- Person 2:
		- Did not consume meat, only 10.75 g of nuts
		- No replacement done, g of nuts before and after are the same
	- Person 3:
		- Consumed 134 g of beef, 75 g of lnchn, and 0 g of nuts, seeds, and legumes
		- 134 g * 0.25 = 33.5 g of beef to distribute among nuts, seeds, and legumes in proportions consumed by sample and 75 * 0.25 = 18.75 g of lnchn to distribute
		- nsl from beef = 134*0.25*0.302 (nuts) + 134*0.25*0.035 (seeds) + 134*0.25*0.595 (lgmes) + 134*0.25*0.068 (tofu) = 33.5 g
		- nsl from lnchn = 75*0.25*0.302 (nuts) + 75*0.25*0.035 (seeds) + 75*0.25*0.595 (lgmes) + 75*0.25*0.068 (tofu) = 18.75 g
		- nsl_wtg2 = 33.5 g + 18.75 g = 52.25 g (meat_wtg * 0.25 = nsl_wtg2)
	- Person 13: 
		- Consumed 16.2 g of pork, 5.3 g of nuts, and 18.13 g of legumes
		- 16.2 g * 0.25 = 4.05 g of pork to distribute among nuts and legumes
		- nuts_wtg2 = 16.2 g * 0.25 * 0.226 (nuts_pcnt) = 0.916 g
		- lgmes_wtg2 = 16.2 g * 0.25 * 0.774 (lgmes_pcnt) = 3.135 g
		- nsl_wtg2 = 0.916 g + 3.135 g = 4.05 g*/  
	
/*Preliminary results (g)*/
proc means n nmiss mean min max data=rs1_25;	
	var beef_wtg beef_wtg2 lamb_wtg lamb_wtg2 pork_wtg pork_wtg2 lnchn_wtg lnchn_wtg2
		nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2
		milk_wtg cheese_wtg yghrt_wtg cream_wtg butr_wtg frzn_wtg /*soybev_wtg*/ other_wtg;
run;	

/************************************/
/* Conduct replacements - GHGE 		*/
/************************************/
data rs1_25_ghge;
	set rs1_25;

	/*If the respondent consumed meat, simply divide ghge of g of meat originally consumed in half*/
	/*Alternatively, multiply unique ghge based on their meat consumption profile by g of meat after replacement*/
	/*Note that these come out to the same thing*/
	if beef_wtg ne 0 and beef_co2eq ne . then beef_co2eq2=beef_co2eq-(beef_co2eq*0.25);
	if lamb_wtg ne 0 and lamb_co2eq ne . then lamb_co2eq2=lamb_co2eq-(lamb_co2eq*0.25);
	if pork_wtg ne 0 and pork_co2eq ne . then pork_co2eq2=pork_co2eq-(pork_co2eq*0.25);
	if lnchn_wtg ne 0 and lnchn_co2eq ne . then lnchn_co2eq2=lnchn_co2eq-(lnchn_co2eq*0.25);
	/*if beef_wtg ne 0 and unq_beef_co2eq ne . then beef_co2eq2_v2=unq_beef_co2eq*(beef_wtg2/1000);			
	if lamb_wtg ne 0 and unq_lamb_co2eq ne . then lamb_co2eq2_v2=unq_lamb_co2eq*(lamb_wtg2/1000);
	if pork_wtg ne 0 and unq_pork_co2eq ne . then pork_co2eq2_v2=unq_pork_co2eq*(pork_wtg2/1000);
	if lnchn_wtg ne 0 and unq_lnchn_co2eq ne . then lnchn_co2eq2_v2=unq_lnchn_co2eq*(lnchn_wtg2/1000);*/

	/*For respondents that originally consumed nsl, multiply unique ghge based on their nsl consumption profile by g of nsl replaced; then, add this to original ghge
	for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl) (these come out to the same thing)*/
	if nuts_wtg ne 0 and unq_nuts_co2eq ne . then nuts_co2eq2=nuts_co2eq+(unq_nuts_co2eq*((nuts_wtg2-nuts_wtg)/1000));
	if seeds_wtg ne 0 and unq_seeds_co2eq ne . then seeds_co2eq2=seeds_co2eq+(unq_seeds_co2eq*((seeds_wtg2-seeds_wtg)/1000));
	if lgmes_wtg ne 0 and unq_lgmes_co2eq ne . then lgmes_co2eq2=lgmes_co2eq+(unq_lgmes_co2eq*((lgmes_wtg2-lgmes_wtg)/1000));
	if tofu_wtg ne 0 and unq_tofu_co2eq ne . then tofu_co2eq2=tofu_co2eq+(unq_tofu_co2eq*((tofu_wtg2-tofu_wtg)/1000));
	/*if nuts_wtg ne 0 and unq_nuts_co2eq ne . then nuts_co2eq2_v2=unq_nuts_co2eq*(nuts_wtg2/1000);
	if seeds_wtg ne 0 and unq_seeds_co2eq ne . then seeds_co2eq2_v2=unq_seeds_co2eq*(seeds_wtg2/1000);
	if lgmes_wtg ne 0 and unq_lgmes_co2eq ne . then lgmes_co2eq2_v2=unq_lgmes_co2eq*(lgmes_wtg2/1000);
	if tofu_wtg ne 0 and unq_tofu_co2eq ne . then tofu_co2eq2_v2=unq_tofu_co2eq*(tofu_wtg2/1000);*/

	/*For respodents that did not originally consume beef, ghge=0 after replacement*/
	if beef_wtg=0 then beef_co2eq2=0;
	if lamb_wtg=0 then lamb_co2eq2=0;
	if pork_wtg=0 then pork_co2eq2=0;
	if lnchn_wtg=0 then lnchn_co2eq2=0;

	/*For respondents that did not originally consume nsl, use a weighted average ghge*/
	/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_co2eq2=2.303442774*(nuts_wtg2/1000);
	if seeds_wtg=0 then seeds_co2eq2=0.883544384*(seeds_wtg2/1000);
	if lgmes_wtg=0 then lgmes_co2eq2=1.388278602*(lgmes_wtg2/1000);
	if tofu_wtg=0 then tofu_co2eq2=2.3616*(tofu_wtg2/1000);

	/*Setting missing values to 0 here*/
	if beef_co2eq=. then beef_co2eq=0;
	if lamb_co2eq=. then lamb_co2eq=0;
	if pork_co2eq=. then pork_co2eq=0;
	if lnchn_co2eq=. then lnchn_co2eq=0;
	if nuts_co2eq=. then nuts_co2eq=0;
	if seeds_co2eq=. then seeds_co2eq=0;
	if lgmes_co2eq=. then lgmes_co2eq=0;
	if tofu_co2eq=. then tofu_co2eq=0;

	if beef_co2eq2=. then beef_co2eq2=0;
	if lamb_co2eq2=. then lamb_co2eq2=0;
	if pork_co2eq2=. then pork_co2eq2=0;
	if lnchn_co2eq2=. then lnchn_co2eq2=0;
	if nuts_co2eq2=. then nuts_co2eq2=0;
	if seeds_co2eq2=. then seeds_co2eq2=0;
	if lgmes_co2eq2=. then lgmes_co2eq2=0;
	if tofu_co2eq2=. then tofu_co2eq2=0;

	/*Setting missing values to 0 for other foods here*/
	if cheese_co2eq=. then cheese_co2eq=0;
	if yghrt_co2eq=. then yghrt_co2eq=0;
	if cream_co2eq=. then cream_co2eq=0;
	if butr_co2eq=. then butr_co2eq=0;
	if frzn_co2eq=. then frzn_co2eq=0;
	if milk_co2eq=. then milk_co2eq=0;
	if soybev_co2eq=. then soybev_co2eq=0;
	if other_co2eq=. then other_co2eq=0;

	/*Create variables for total meat and total nsl ghge pre- and post-replacement*/
	tot_meat_co2eq=beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq;
	tot_meat_co2eq2=beef_co2eq2+lamb_co2eq2+pork_co2eq2+lnchn_co2eq2;
	tot_nsl_co2eq=nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+soybev_co2eq;
	tot_nsl_co2eq2=nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+soybev_co2eq;
	tot_dairy_co2eq=cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+milk_co2eq;

	/*Create variables for total ghge pre- and post-replacement*/
	tot_co2eq=beef_co2eq+lamb_co2eq+pork_co2eq+lnchn_co2eq+nuts_co2eq+seeds_co2eq+lgmes_co2eq+tofu_co2eq+
	cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+milk_co2eq+soybev_co2eq+other_co2eq;
	tot_co2eq2=beef_co2eq2+lamb_co2eq2+pork_co2eq2+lnchn_co2eq2+nuts_co2eq2+seeds_co2eq2+lgmes_co2eq2+tofu_co2eq2+
	cheese_co2eq+yghrt_co2eq+cream_co2eq+butr_co2eq+frzn_co2eq+milk_co2eq+soybev_co2eq+other_co2eq;

	/*Create variables for CO2-eq/1000 kcal*/
	if fsddekc ne 0 then tot_co2eq_kcal=(tot_co2eq/fsddekc)*1000;
	if fsddekc ne 0 then tot_co2eq2_kcal=(tot_co2eq2/fsddekc)*1000;

	/*keep sampleid beef_wtg lamb_wtg pork_wtg lnchn_wtg nsl_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg
	beef_wtg2 lamb_wtg2 pork_wtg2 lnchn_wtg2 nsl_wtg2 nuts_wtg2 seeds_wtg2 lgmes_wtg2 tofu_wtg2
	nuts_beef_wtg2 nuts_lamb_wtg2 nuts_pork_wtg2 nuts_lnchn_wtg2
	seeds_beef_wtg2 seeds_lamb_wtg2 seeds_pork_wtg2 seeds_lnchn_wtg2
	lgmes_beef_wtg2 lgmes_lamb_wtg2 lgmes_pork_wtg2 lgmes_lnchn_wtg2
	tofu_beef_wtg2 tofu_lamb_wtg2 tofu_pork_wtg2 tofu_lnchn_wtg2
	nuts_pcnt seeds_pcnt lgmes_pcnt tofu_pcnt
	meat_wtg nsl_wtg meat_wtg2 nsl_wtg2 
	beef_co2eq lamb_co2eq pork_co2eq lnchn_co2eq nuts_co2eq seeds_co2eq lgmes_co2eq tofu_co2eq
	beef_co2eq2 lamb_co2eq2 pork_co2eq2 lnchn_co2eq2 nuts_co2eq2 seeds_co2eq2 lgmes_co2eq2 tofu_co2eq2
	unq_nuts_co2eq unq_seeds_co2eq unq_lgmes_co2eq unq_tofu_co2eq;*/

run;
/*17,921 observations (Master Files)*/

proc means n nmiss mean min max data=rs1_25_ghge;
	var tot_co2eq tot_co2eq2;
run;

/*This needs to be corrected! 2022-02-17*/

/*Verification examples:
	- Person 1:
		- Consumed luncheon and nuts
			- co2eq luncheon post-replacement = 1.34 (lnchn_co2eq)/2 = 0.67
			- co2eq nuts post-replacement =  0.007 (co2eq of nuts originally consumed) + (0.414 (unique nuts multiplier) x ((55.02 - 17.52) (nuts_wtg2 - nuts_wtg) / 1000))) = 0.02
	- Person 2:
		- Did not consume meat, only nuts
		- No replacement done, co2eq of nuts before and after are the same
	- Person 3:
		- Consumed beef and luncheon, did not consume any nuts, seeds, or legumes
			- co2eq beef post-replacement = 5.8/2 = 2.9
			- co2eq luncheon post-replacement = 2.8/2 = 1.4
			- co2eq nuts post-replacement = 2.3 (avg. weighted GHGE from 'Food-List') x nuts_wtg2/1000 = 0.07
			- co2eq seeds post-replacement = 0.9 (avg. weighted GHGE from 'Food-List') x seeds_wtg2/1000 = 0.003
			- co2eq legumes post-replacement = 1.4 (avg. weighted GHGE from 'Food-List') x lgmes_wtg2/1000 = 0.08
			- co2eq tofu post-replacement = 2.4 (avg. weighted GHGE from 'Food-List') x tofu_wtg2/1000 = 0.02
	- Person 13: 
		- Consumed pork, nuts, and legumes
			- co2eq pork post-replacement = 0.06 (pork_co2eq)/2 = 0.03
			- co2eq nuts post-replacement =  0.011 (co2eq of nuts originally consumed) + (2.209 (unique nuts multiplier) x ((7.14 - 5.3) (nuts_wtg2 - nuts_wtg) / 1000))) = 0.015
			- co2eq legumes post-replacement =  0.044 (co2eq of legumes originally consumed) + (2.44 (unique nuts multiplier) x ((24.39 - 18.13) (legumes_wtg2 - legmes_wtg) / 1000))) = 0.059*/

/*Check for missing values for food items with a wtg but no co2eq*/
/*These are foods with missing values, ignore or try to link at dataFIELD step*/
/*data a;
	set rs1_50_ghge;
	keep sampleid beef_wtg lamb_wtg pork_wtg lnchn_wtg nuts_wtg seeds_wtg lgmes_wtg tofu_wtg
	beef_co2eq lamb_co2eq pork_co2eq lnchn_co2eq nuts_co2eq seeds_co2eq lgmes_co2eq tofu_co2eq;
	/*if beef_wtg ne 0 and beef_co2eq=.;*/
	/*if lamb_wtg ne 0 and lamb_co2eq=.;*/
	/*if pork_wtg ne 0 and pork_co2eq=.;*/
	/*if lnchn_wtg ne 0 and lnchn_co2eq=.;*/
	/*if nuts_wtg ne 0 and nuts_co2eq=.;*/
	/*if seeds_wtg ne 0 and seeds_co2eq=.;*/
	/*if lgmes_wtg ne 0 and lgmes_co2eq=.;*/
	/*if tofu_wtg ne 0 and tofu_co2eq=.;*/
/*run;
/*beef (n=1): sampleid=4808050941301640016_
pork(n=1): sampleid=11D1404221000359367_
lnchn (n=7): sampleid=1007054451197617664_
		sampleid=2449028351042425312_
		sampleid=2467002051058755337_
		sampleid=3521071431125191640_
		sampleid=35D0423451106629779_
		sampleid=48D1175061027571339_
		sampleid=5915337131091514090_
lgmes (n=2): sampleid=1005008521001581556_
		sampleid=3519092721114034633_*/

/*data b;
	set sbgrps;
	if sampleid='3519092721114034633_' and food_subgrp=13;
run;

/*Preliminary results (ghge)*/
proc means n nmiss mean min max data=rs1_25_ghge;	
	var beef_co2eq beef_co2eq2 lamb_co2eq lamb_co2eq2 pork_co2eq pork_co2eq2 lnchn_co2eq lnchn_co2eq2
	nuts_co2eq nuts_co2eq2 seeds_co2eq seeds_co2eq2 lgmes_co2eq lgmes_co2eq2 tofu_co2eq tofu_co2eq2
	cheese_co2eq yghrt_co2eq cream_co2eq butr_co2eq frzn_co2eq milk_co2eq /*soybev_co2eq*/ other_co2eq
	tot_meat_co2eq tot_meat_co2eq2 tot_nsl_co2eq tot_nsl_co2eq2 tot_co2eq tot_co2eq2;
run;

/************************************/
/* Conduct replacements - Nutrients */
/************************************/

/*Note that the same method for calculating ghge is used here for nutrients*/

data rs1_25_nutr;
	set rs1_25_ghge;

/*If the respondent consumed meat, simply divide intake of nutrients originally consumed from meat in half*/
/*Alternatively, multiply unique ekc based on their meat consumption profile by g of meat after replacement*/
/*Note that these come out to the same thing*/
	/*Energy*/
		if beef_wtg ne 0 and beef_ekc ne . then beef_ekc2=beef_ekc-(beef_ekc*0.25);
		if lamb_wtg ne 0 and lamb_ekc ne . then lamb_ekc2=lamb_ekc-(lamb_ekc*0.25);	
		if pork_wtg ne 0 and pork_ekc ne . then pork_ekc2=pork_ekc-(pork_ekc*0.25);	
		if lnchn_wtg ne 0 and lnchn_ekc ne . then lnchn_ekc2=lnchn_ekc-(lnchn_ekc*0.25);
		/*if beef_wtg ne 0 and unq_beef_ekc ne . then beef_ekc2_v2=unq_beef_ekc*beef_wtg2;
		if lamb_wtg ne 0 and unq_lamb_ekc ne . then lamb_ekc2_v2=unq_lamb_ekc*lamb_wtg2;	
		if pork_wtg ne 0 and unq_pork_ekc ne . then pork_ekc2_v2=unq_pork_ekc*pork_wtg2;
		if lnchn_wtg ne 0 and unq_lnchn_ekc ne . then lnchn_ekc2_v2=unq_lnchn_ekc*lnchn_wtg2;*/	
	/*Sugar*/
		if beef_wtg ne 0 and beef_sug ne . then beef_sug2=beef_sug-(beef_sug*0.25);	
		if lamb_wtg ne 0 and lamb_sug ne . then lamb_sug2=lamb_sug-(lamb_sug*0.25);	
		if pork_wtg ne 0 and pork_sug ne . then pork_sug2=pork_sug-(pork_sug*0.25);	
		if lnchn_wtg ne 0 and lnchn_sug ne . then lnchn_sug2=lnchn_sug-(lnchn_sug*0.25);	
		/*if beef_wtg ne 0 and unq_beef_sug ne . then beef_sug2_v2=unq_beef_sug*beef_wtg2;					
		if lamb_wtg ne 0 and unq_lamb_sug ne . then lamb_sug2_v2=unq_lamb_sug*lamb_wtg2;	
		if pork_wtg ne 0 and unq_pork_sug ne . then pork_sug2_v2=unq_pork_sug*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_sug ne . then lnchn_sug2_v2=unq_lnchn_sug*lnchn_wtg2;*/				
	/*Saturated fat*/
		if beef_wtg ne 0 and beef_sat ne . then beef_sat2=beef_sat-(beef_sat*0.25);	
		if lamb_wtg ne 0 and lamb_sat ne . then lamb_sat2=lamb_sat-(lamb_sat*0.25);	
		if pork_wtg ne 0 and pork_sat ne . then pork_sat2=pork_sat-(pork_sat*0.25);	
		if lnchn_wtg ne 0 and lnchn_sat ne . then lnchn_sat2=lnchn_sat-(lnchn_sat*0.25);	
		/*if beef_wtg ne 0 and unq_beef_sat ne . then beef_sat2_v2=unq_beef_sat*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_sat ne . then lamb_sat2_v2=unq_lamb_sat*lamb_wtg2;								
		if pork_wtg ne 0 and unq_pork_sat ne . then pork_sat2_v2=unq_pork_sat*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_sat ne . then lnchn_sat2_v2=unq_lnchn_sat*lnchn_wtg2;*/		
	/*Protein*/
		if beef_wtg ne 0 and beef_pro ne . then beef_pro2=beef_pro-(beef_pro*0.25);	
		if lamb_wtg ne 0 and lamb_pro ne . then lamb_pro2=lamb_pro-(lamb_pro*0.25);	
		if pork_wtg ne 0 and pork_pro ne . then pork_pro2=pork_pro-(pork_pro*0.25);	
		if lnchn_wtg ne 0 and lnchn_pro ne . then lnchn_pro2=lnchn_pro-(lnchn_pro*0.25);	
		/*if beef_wtg ne 0 and unq_beef_pro ne . then beef_pro2_v2=unq_beef_pro*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_pro ne . then lamb_pro2_v2=unq_lamb_pro*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_pro ne . then pork_pro2_v2=unq_pork_pro*pork_wtg2;							
		if lnchn_wtg ne 0 and unq_lnchn_pro ne . then lnchn_pro2_v2=unq_lnchn_pro*lnchn_wtg2;*/			
	/*Vitamin D*/
		if beef_wtg ne 0 and beef_vitD ne . then beef_vitD2=beef_vitD-(beef_vitD*0.25);	
		if lamb_wtg ne 0 and lamb_vitD ne . then lamb_vitD2=lamb_vitD-(lamb_vitD*0.25);	
		if pork_wtg ne 0 and pork_vitD ne . then pork_vitD2=pork_vitD-(pork_vitD*0.25);	
		if lnchn_wtg ne 0 and lnchn_vitD ne . then lnchn_vitD2=lnchn_vitD-(lnchn_vitD*0.25);	
		/*if beef_wtg ne 0 and unq_beef_vitD ne . then beef_vitD2_v2=unq_beef_vitD*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_vitD ne . then lamb_vitD2_v2=unq_lamb_vitD*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_vitD ne . then pork_vitD2_v2=unq_pork_vitD*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_vitD ne . then lnchn_vitD2_v2=unq_lnchn_vitD*lnchn_wtg2;*/				
	/*Calcium*/
		if beef_wtg ne 0 and beef_ca ne . then beef_ca2=beef_ca-(beef_ca*0.25);	
		if lamb_wtg ne 0 and lamb_ca ne . then lamb_ca2=lamb_ca-(lamb_ca*0.25);	
		if pork_wtg ne 0 and pork_ca ne . then pork_ca2=pork_ca-(pork_ca*0.25);	
		if lnchn_wtg ne 0 and lnchn_ca ne . then lnchn_ca2=lnchn_ca-(lnchn_ca*0.25);	
		/*if beef_wtg ne 0 and unq_beef_ca ne . then beef_ca2_v2=unq_beef_ca*beef_wtg2;								
		if lamb_wtg ne 0 and unq_lamb_ca ne . then lamb_ca2_v2=unq_lamb_ca*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_ca ne . then pork_ca2_v2=unq_pork_ca*pork_wtg2;							
		if lnchn_wtg ne 0 and unq_lnchn_ca ne . then lnchn_ca2_v2=unq_lnchn_ca*lnchn_wtg2;*/					
	/*Iron*/
		if beef_wtg ne 0 and beef_fe ne . then beef_fe2=beef_fe-(beef_fe*0.25);	
		if lamb_wtg ne 0 and lamb_fe ne . then lamb_fe2=lamb_fe-(lamb_fe*0.25);	
		if pork_wtg ne 0 and pork_fe ne . then pork_fe2=pork_fe-(pork_fe*0.25);	
		if lnchn_wtg ne 0 and lnchn_fe ne . then lnchn_fe2=lnchn_fe-(lnchn_fe*0.25);		
		/*if beef_wtg ne 0 and unq_beef_fe ne . then beef_fe2_v2=unq_beef_fe*beef_wtg2;								
		if lamb_wtg ne 0 and unq_lamb_fe ne . then lamb_fe2_v2=unq_lamb_fe*lamb_wtg2;								
		if pork_wtg ne 0 and unq_pork_fe ne . then pork_fe2_v2=unq_pork_fe*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_fe ne . then lnchn_fe2_v2=unq_lnchn_fe*lnchn_wtg2;*/							
	/*Sodium*/
		if beef_wtg ne 0 and beef_na ne . then beef_na2=beef_na-(beef_na*0.25);	
		if lamb_wtg ne 0 and lamb_na ne . then lamb_na2=lamb_na-(lamb_na*0.25);	
		if pork_wtg ne 0 and pork_na ne . then pork_na2=pork_na-(pork_na*0.25);	
		if lnchn_wtg ne 0 and lnchn_na ne . then lnchn_na2=lnchn_na-(lnchn_na*0.25);	
		/*if beef_wtg ne 0 and unq_beef_na ne . then beef_na2_v2=unq_beef_na*beef_wtg2;							
		if lamb_wtg ne 0 and unq_lamb_na ne . then lamb_na2_v2=unq_lamb_na*lamb_wtg2;							
		if pork_wtg ne 0 and unq_pork_na ne . then pork_na2_v2=unq_pork_na*pork_wtg2;								
		if lnchn_wtg ne 0 and unq_lnchn_na ne . then lnchn_na2_v2=unq_lnchn_na*lnchn_wtg2;*/							
	/*Potassium*/	
		if beef_wtg ne 0 and beef_k ne . then beef_k2=beef_k-(beef_k*0.25);	
		if lamb_wtg ne 0 and lamb_k ne . then lamb_k2=lamb_k-(lamb_k*0.25);	
		if pork_wtg ne 0 and pork_k ne . then pork_k2=pork_k-(pork_k*0.25);	
		if lnchn_wtg ne 0 and lnchn_k ne . then lnchn_k2=lnchn_k-(lnchn_k*0.25);	
		/*if beef_wtg ne 0 and unq_beef_k ne . then beef_k2_v2=unq_beef_k*beef_wtg2;				
		if lamb_wtg ne 0 and unq_lamb_k ne . then lamb_k2_v2=unq_lamb_k*lamb_wtg2;						
		if pork_wtg ne 0 and unq_pork_k ne . then pork_k2_v2=unq_pork_k*pork_wtg2;							
		if lnchn_wtg ne 0 and unq_lnchn_k ne . then lnchn_k2_v2=unq_lnchn_k*lnchn_wtg2;*/	
	/*Carbs*/
		if beef_wtg ne 0 and beef_carb ne . then beef_carb2=beef_carb-(beef_carb*0.25);		
		if lamb_wtg ne 0 and lamb_carb ne . then lamb_carb2=lamb_carb-(lamb_carb*0.25);		
		if pork_wtg ne 0 and pork_carb ne . then pork_carb2=pork_carb-(pork_carb*0.25);	
		if lnchn_wtg ne 0 and lnchn_carb ne . then lnchn_carb2=lnchn_carb-(lnchn_carb*0.25);	
	/*MUFAs*/			
		if beef_wtg ne 0 and beef_mufa ne . then beef_mufa2=beef_mufa-(beef_mufa*0.25);		
		if lamb_wtg ne 0 and lamb_mufa ne . then lamb_mufa2=lamb_mufa-(lamb_mufa*0.25);		
		if pork_wtg ne 0 and pork_mufa ne . then pork_mufa2=pork_mufa-(pork_mufa*0.25);		
		if lnchn_wtg ne 0 and lnchn_mufa ne . then lnchn_mufa2=lnchn_mufa-(lnchn_mufa*0.25);
	/*PUFAs*/			
		if beef_wtg ne 0 and beef_pufa ne . then beef_pufa2=beef_pufa-(beef_pufa*0.25);		
		if lamb_wtg ne 0 and lamb_pufa ne . then lamb_pufa2=lamb_pufa-(lamb_pufa*0.25);		
		if pork_wtg ne 0 and pork_pufa ne . then pork_pufa2=pork_pufa-(pork_pufa*0.25);		
		if lnchn_wtg ne 0 and lnchn_pufa ne . then lnchn_pufa2=lnchn_pufa-(lnchn_pufa*0.25);				

/*For respondents that originally consumed nsl, multiply unique ekc based on their nsl consumption profile by g of nsl replaced; then, add this to original ekc
for nsl before the replacement (i.e., we are only using the unique ghge for the grams of nsl being replaced, not for all nsl) (these come out to the same thing)*/
	/*Energy*/
		if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2=nuts_ekc+(unq_nuts_ekc*(nuts_wtg2-nuts_wtg));
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2=seeds_ekc+(unq_seeds_ekc*(seeds_wtg2-seeds_wtg));
		if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2=lgmes_ekc+(unq_lgmes_ekc*(lgmes_wtg2-lgmes_wtg));
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2=tofu_ekc+(unq_tofu_ekc*(tofu_wtg2-tofu_wtg));
		/*if nuts_wtg ne 0 and unq_nuts_ekc ne . then nuts_ekc2_v2=unq_nuts_ekc*nuts_wtg2;
		if seeds_wtg ne 0 and unq_seeds_ekc ne . then seeds_ekc2_v2=unq_seeds_ekc*seeds_wtg2;
	  	if lgmes_wtg ne 0 and unq_lgmes_ekc ne . then lgmes_ekc2_v2=unq_lgmes_ekc*lgmes_wtg2;
		if tofu_wtg ne 0 and unq_tofu_ekc ne . then tofu_ekc2_v2=unq_tofu_ekc*tofu_wtg2;*/
	/*Sugar*/
		if nuts_wtg ne 0 and unq_nuts_sug ne . then nuts_sug2=unq_nuts_sug*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sug ne . then seeds_sug2=unq_seeds_sug*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sug ne . then lgmes_sug2=unq_lgmes_sug*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sug ne . then tofu_sug2=unq_tofu_sug*tofu_wtg2;	
	/*Saturated fat*/
		if nuts_wtg ne 0 and unq_nuts_sat ne . then nuts_sat2=unq_nuts_sat*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_sat ne . then seeds_sat2=unq_seeds_sat*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_sat ne . then lgmes_sat2=unq_lgmes_sat*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_sat ne . then tofu_sat2=unq_tofu_sat*tofu_wtg2;	
	/*Protein*/
		if nuts_wtg ne 0 and unq_nuts_pro ne . then nuts_pro2=unq_nuts_pro*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pro ne . then seeds_pro2=unq_seeds_pro*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pro ne . then lgmes_pro2=unq_lgmes_pro*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pro ne . then tofu_pro2=unq_tofu_pro*tofu_wtg2;	
	/*Vitamin D*/
		if nuts_wtg ne 0 and unq_nuts_vitD ne . then nuts_vitD2=unq_nuts_vitD*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_vitD ne . then seeds_vitD2=unq_seeds_vitD*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_vitD ne . then lgmes_vitD2=unq_lgmes_vitD*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_vitD ne . then tofu_vitD2=unq_tofu_vitD*tofu_wtg2;	
	/*Calcium*/
		if nuts_wtg ne 0 and unq_nuts_ca ne . then nuts_ca2=unq_nuts_ca*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_ca ne . then seeds_ca2=unq_seeds_ca*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_ca ne . then lgmes_ca2=unq_lgmes_ca*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_ca ne . then tofu_ca2=unq_tofu_ca*tofu_wtg2;	
	/*Iron*/
		if nuts_wtg ne 0 and unq_nuts_fe ne . then nuts_fe2=unq_nuts_fe*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_fe ne . then seeds_fe2=unq_seeds_fe*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_fe ne . then lgmes_fe2=unq_lgmes_fe*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_fe ne . then tofu_fe2=unq_tofu_fe*tofu_wtg2;	
	/*Sodium*/
		if nuts_wtg ne 0 and unq_nuts_na ne . then nuts_na2=unq_nuts_na*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_na ne . then seeds_na2=unq_seeds_na*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_na ne . then lgmes_na2=unq_lgmes_na*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_na ne . then tofu_na2=unq_tofu_na*tofu_wtg2;	
	/*Potassium*/
		if nuts_wtg ne 0 and unq_nuts_k ne . then nuts_k2=unq_nuts_k*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_k ne . then seeds_k2=unq_seeds_k*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_k ne . then lgmes_k2=unq_lgmes_k*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_k ne . then tofu_k2=unq_tofu_k*tofu_wtg2;	
	/*Carbs*/
		if nuts_wtg ne 0 and unq_nuts_carb ne . then nuts_carb2=unq_nuts_carb*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_carb ne . then seeds_carb2=unq_seeds_carb*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_carb ne . then lgmes_carb2=unq_lgmes_carb*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_carb ne . then tofu_carb2=unq_tofu_carb*tofu_wtg2;
	/*MUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_mufa ne . then nuts_mufa2=unq_nuts_mufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_mufa ne . then seeds_mufa2=unq_seeds_mufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_mufa ne . then lgmes_mufa2=unq_lgmes_mufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_mufa ne . then tofu_mufa2=unq_tofu_mufa*tofu_wtg2;	
	/*PUFAs*/		
		if nuts_wtg ne 0 and unq_nuts_pufa ne . then nuts_pufa2=unq_nuts_pufa*nuts_wtg2;	
		if seeds_wtg ne 0 and unq_seeds_pufa ne . then seeds_pufa2=unq_seeds_pufa*seeds_wtg2;	
		if lgmes_wtg ne 0 and unq_lgmes_pufa ne . then lgmes_pufa2=unq_lgmes_pufa*lgmes_wtg2;	
		if tofu_wtg ne 0 and unq_tofu_pufa ne . then tofu_pufa2=unq_tofu_pufa*tofu_wtg2;	

/*For respondents that did not originally consume meat, nutrients=0 after replacement*/
	if beef_wtg=0 then beef_ekc2=0;
	if beef_wtg=0 then beef_sug2=0;
	if beef_wtg=0 then beef_sat2=0;
	if beef_wtg=0 then beef_pro2=0;
	if beef_wtg=0 then beef_vitD2=0;
	if beef_wtg=0 then beef_ca2=0;
	if beef_wtg=0 then beef_fe2=0;
	if beef_wtg=0 then beef_na2=0;
	if beef_wtg=0 then beef_k2=0;
	if beef_wtg=0 then beef_carb2=0;
	if beef_wtg=0 then beef_mufa2=0;
	if beef_wtg=0 then beef_pufa2=0;

	if lamb_wtg=0 then lamb_ekc2=0;
	if lamb_wtg=0 then lamb_sug2=0;
	if lamb_wtg=0 then lamb_sat2=0;
	if lamb_wtg=0 then lamb_pro2=0;
	if lamb_wtg=0 then lamb_vitD2=0;
	if lamb_wtg=0 then lamb_ca2=0;
	if lamb_wtg=0 then lamb_fe2=0;
	if lamb_wtg=0 then lamb_na2=0;
	if lamb_wtg=0 then lamb_k2=0;
	if lamb_wtg=0 then lamb_carb2=0;
	if lamb_wtg=0 then lamb_mufa2=0;
	if lamb_wtg=0 then lamb_pufa2=0;

	if pork_wtg=0 then pork_ekc2=0;
	if pork_wtg=0 then pork_sug2=0;
	if pork_wtg=0 then pork_sat2=0;
	if pork_wtg=0 then pork_pro2=0;
	if pork_wtg=0 then pork_vitD2=0;
	if pork_wtg=0 then pork_ca2=0;
	if pork_wtg=0 then pork_fe2=0;
	if pork_wtg=0 then pork_na2=0;
	if pork_wtg=0 then pork_k2=0;
	if pork_wtg=0 then pork_carb2=0;
	if pork_wtg=0 then pork_mufa2=0;
	if pork_wtg=0 then pork_pufa2=0;

	if lnchn_wtg=0 then lnchn_ekc2=0;
	if lnchn_wtg=0 then lnchn_sug2=0;
	if lnchn_wtg=0 then lnchn_sat2=0;
	if lnchn_wtg=0 then lnchn_pro2=0;
	if lnchn_wtg=0 then lnchn_vitD2=0;
	if lnchn_wtg=0 then lnchn_ca2=0;
	if lnchn_wtg=0 then lnchn_fe2=0;
	if lnchn_wtg=0 then lnchn_na2=0;
	if lnchn_wtg=0 then lnchn_k2=0;
	if lnchn_wtg=0 then lnchn_carb2=0;
	if lnchn_wtg=0 then lnchn_mufa2=0;
	if lnchn_wtg=0 then lnchn_pufa2=0;

/*For respondents that did not originally consume nsl, use a weighted average for nutrients*/
/*Values updated using those obtained from Master Files*/
	if nuts_wtg=0 then nuts_ekc2=6.068735152*nuts_wtg2;
	if nuts_wtg=0 then nuts_sug2=0.023412133*nuts_wtg2;		/*Note that this is weighted avg. for FREE SUGARS*/
	if nuts_wtg=0 then nuts_sat2=0.078223051*nuts_wtg2;
	if nuts_wtg=0 then nuts_pro2=0.189748537*nuts_wtg2;
	if nuts_wtg=0 then nuts_vitD2=0*nuts_wtg2;
	if nuts_wtg=0 then nuts_ca2=1.047177739*nuts_wtg2;
	if nuts_wtg=0 then nuts_fe2=0.028762549*nuts_wtg2;
	if nuts_wtg=0 then nuts_na2=1.538556973*nuts_wtg2;
	if nuts_wtg=0 then nuts_k2=5.879183898*nuts_wtg2;
	if nuts_wtg=0 then nuts_carb2=0.208693214*nuts_wtg2;
	if nuts_wtg=0 then nuts_mufa2=0.250425621*nuts_wtg2;
	if nuts_wtg=0 then nuts_pufa2=0.184819969*nuts_wtg2;

	if seeds_wtg=0 then seeds_ekc2=5.588623188*seeds_wtg2;
	if seeds_wtg=0 then seeds_sug2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_sat2=0.053096123*seeds_wtg2;
	if seeds_wtg=0 then seeds_pro2=0.212654067*seeds_wtg2;
	if seeds_wtg=0 then seeds_vitD2=0*seeds_wtg2;
	if seeds_wtg=0 then seeds_ca2=1.625144928*seeds_wtg2;
	if seeds_wtg=0 then seeds_fe2=0.060998279*seeds_wtg2;
	if seeds_wtg=0 then seeds_na2=0.780842391*seeds_wtg2;
	if seeds_wtg=0 then seeds_k2=7.510996377*seeds_wtg2;
	if seeds_wtg=0 then seeds_carb2=0.236999647*seeds_wtg2;
	if seeds_wtg=0 then seeds_mufa2=0.111621132*seeds_wtg2;
	if seeds_wtg=0 then seeds_pufa2=0.269852745*seeds_wtg2;

	if lgmes_wtg=0 then lgmes_ekc2=0.93228815*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sug2=0.003114783*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_sat2=0.001913132*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pro2=0.057528201*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_vitD2=0*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_ca2=0.366772379*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_fe2=0.01791809*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_na2=1.035202046*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_k2=2.539577153*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_carb2=0.161040051*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_mufa2=0.003398607*lgmes_wtg2;
	if lgmes_wtg=0 then lgmes_pufa2=0.004636307*lgmes_wtg2;

	if tofu_wtg=0 then tofu_ekc2=2.428236398*tofu_wtg2;
	if tofu_wtg=0 then tofu_sug2=0.000317073*tofu_wtg2;
	if tofu_wtg=0 then tofu_sat2=0.020709869*tofu_wtg2;
	if tofu_wtg=0 then tofu_pro2=0.227237148*tofu_wtg2;
	if tofu_wtg=0 then tofu_vitD2=0*tofu_wtg2;
	if tofu_wtg=0 then tofu_ca2=1.770863039*tofu_wtg2;
	if tofu_wtg=0 then tofu_fe2=0.032112383*tofu_wtg2;
	if tofu_wtg=0 then tofu_na2=6.259924953*tofu_wtg2;
	if tofu_wtg=0 then tofu_k2=1.671575985*tofu_wtg2;
	if tofu_wtg=0 then tofu_carb2=0.114113884*tofu_wtg2;
	if tofu_wtg=0 then tofu_mufa2=0.03100454*tofu_wtg2;
	if tofu_wtg=0 then tofu_pufa2=0.065414953*tofu_wtg2;

/*Setting missing values to 0 here*/
	if beef_ekc=. then beef_ekc=0;
	if beef_sug=. then beef_sug=0;
	if beef_sat=. then beef_sat=0;
	if beef_pro=. then beef_pro=0;
	if beef_vitD=. then beef_vitD=0;
	if beef_ca=. then beef_ca=0;
	if beef_fe=. then beef_fe=0;
	if beef_na=. then beef_na=0;
	if beef_k=. then beef_k=0;
	if beef_carb=. then beef_carb=0;
	if beef_mufa=. then beef_mufa=0;
	if beef_pufa=. then beef_pufa=0;

	if lamb_ekc=. then lamb_ekc=0;
	if lamb_sug=. then lamb_sug=0;
	if lamb_sat=. then lamb_sat=0;
	if lamb_pro=. then lamb_pro=0;
	if lamb_vitD=. then lamb_vitD=0;
	if lamb_ca=. then lamb_ca=0;
	if lamb_fe=. then lamb_fe=0;
	if lamb_na=. then lamb_na=0;
	if lamb_k=. then lamb_k=0;
	if lamb_carb=. then lamb_carb=0;
	if lamb_mufa=. then lamb_mufa=0;
	if lamb_pufa=. then lamb_pufa=0;

	if pork_ekc=. then pork_ekc=0;
	if pork_sug=. then pork_sug=0;
	if pork_sat=. then pork_sat=0;
	if pork_pro=. then pork_pro=0;
	if pork_vitD=. then pork_vitD=0;
	if pork_ca=. then pork_ca=0;
	if pork_fe=. then pork_fe=0;
	if pork_na=. then pork_na=0;
	if pork_k=. then pork_k=0;
	if pork_carb=. then pork_carb=0;
	if pork_mufa=. then pork_mufa=0;
	if pork_pufa=. then pork_pufa=0;

	if lnchn_ekc=. then lnchn_ekc=0;
	if lnchn_sug=. then lnchn_sug=0;
	if lnchn_sat=. then lnchn_sat=0;
	if lnchn_pro=. then lnchn_pro=0;
	if lnchn_vitD=. then lnchn_vitD=0;
	if lnchn_ca=. then lnchn_ca=0;
	if lnchn_fe=. then lnchn_fe=0;
	if lnchn_na=. then lnchn_na=0;
	if lnchn_k=. then lnchn_k=0;
	if lnchn_carb=. then lnchn_carb=0;
	if lnchn_mufa=. then lnchn_mufa=0;
	if lnchn_pufa=. then lnchn_pufa=0;

	if nuts_ekc=. then nuts_ekc=0;
	if nuts_sug=. then nuts_sug=0;
	if nuts_sat=. then nuts_sat=0;
	if nuts_pro=. then nuts_pro=0;
	if nuts_vitD=. then nuts_vitD=0;
	if nuts_ca=. then nuts_ca=0;
	if nuts_fe=. then nuts_fe=0;
	if nuts_na=. then nuts_na=0;
	if nuts_k=. then nuts_k=0;
	if nuts_carb=. then nuts_carb=0;
	if nuts_mufa=. then nuts_mufa=0;
	if nuts_pufa=. then nuts_pufa=0;

	if seeds_ekc=. then seeds_ekc=0;
	if seeds_sug=. then seeds_sug=0;
	if seeds_sat=. then seeds_sat=0;
	if seeds_pro=. then seeds_pro=0;
	if seeds_vitD=. then seeds_vitD=0;
	if seeds_ca=. then seeds_ca=0;
	if seeds_fe=. then seeds_fe=0;
	if seeds_na=. then seeds_na=0;
	if seeds_k=. then seeds_k=0;
	if seeds_carb=. then seeds_carb=0;
	if seeds_mufa=. then seeds_mufa=0;
	if seeds_pufa=. then seeds_pufa=0;

	if lgmes_ekc=. then lgmes_ekc=0;
	if lgmes_sug=. then lgmes_sug=0;
	if lgmes_sat=. then lgmes_sat=0;
	if lgmes_pro=. then lgmes_pro=0;
	if lgmes_vitD=. then lgmes_vitD=0;
	if lgmes_ca=. then lgmes_ca=0;
	if lgmes_fe=. then lgmes_fe=0;
	if lgmes_na=. then lgmes_na=0;
	if lgmes_k=. then lgmes_k=0;
	if lgmes_carb=. then lgmes_carb=0;
	if lgmes_mufa=. then lgmes_mufa=0;
	if lgmes_pufa=. then lgmes_pufa=0;

	if tofu_ekc=. then tofu_ekc=0;
	if tofu_sug=. then tofu_sug=0;
	if tofu_sat=. then tofu_sat=0;
	if tofu_pro=. then tofu_pro=0;
	if tofu_vitD=. then tofu_vitD=0;
	if tofu_ca=. then tofu_ca=0;
	if tofu_fe=. then tofu_fe=0;
	if tofu_na=. then tofu_na=0;
	if tofu_k=. then tofu_k=0;
	if tofu_carb=. then tofu_carb=0;
	if tofu_mufa=. then tofu_mufa=0;
	if tofu_pufa=. then tofu_pufa=0;

/*Setting missing values to 0 for other foods here*/
	if milk_ekc=. then milk_ekc=0;
	if milk_sug=. then milk_sug=0;
	if milk_sat=. then milk_sat=0;
	if milk_pro=. then milk_pro=0;
	if milk_vitD=. then milk_vitD=0;
	if milk_ca=. then milk_ca=0;
	if milk_fe=. then milk_fe=0;
	if milk_na=. then milk_na=0;
	if milk_k=. then milk_k=0;
	if milk_carb=. then milk_carb=0;
	if milk_mufa=. then milk_mufa=0;
	if milk_pufa=. then milk_pufa=0;

	if cheese_ekc=. then cheese_ekc=0;
	if cheese_sug=. then cheese_sug=0;
	if cheese_sat=. then cheese_sat=0;
	if cheese_pro=. then cheese_pro=0;
	if cheese_vitD=. then cheese_vitD=0;
	if cheese_ca=. then cheese_ca=0;
	if cheese_fe=. then cheese_fe=0;
	if cheese_na=. then cheese_na=0;
	if cheese_k=. then cheese_k=0;
	if cheese_carb=. then cheese_carb=0;
	if cheese_mufa=. then cheese_mufa=0;
	if cheese_pufa=. then cheese_pufa=0;

	if yghrt_ekc=. then yghrt_ekc=0;
	if yghrt_sug=. then yghrt_sug=0;
	if yghrt_sat=. then yghrt_sat=0;
	if yghrt_pro=. then yghrt_pro=0;
	if yghrt_vitD=. then yghrt_vitD=0;
	if yghrt_ca=. then yghrt_ca=0;
	if yghrt_fe=. then yghrt_fe=0;
	if yghrt_na=. then yghrt_na=0;
	if yghrt_k=. then yghrt_k=0;
	if yghrt_carb=. then yghrt_carb=0;
	if yghrt_mufa=. then yghrt_mufa=0;
	if yghrt_pufa=. then yghrt_pufa=0;

  	if cream_ekc=. then cream_ekc=0;
	if cream_sug=. then cream_sug=0;
	if cream_sat=. then cream_sat=0;
	if cream_pro=. then cream_pro=0;
	if cream_vitD=. then cream_vitD=0;
	if cream_ca=. then cream_ca=0;
	if cream_fe=. then cream_fe=0;
	if cream_na=. then cream_na=0;
	if cream_k=. then cream_k=0;
	if cream_carb=. then cream_carb=0;
	if cream_mufa=. then cream_mufa=0;
	if cream_pufa=. then cream_pufa=0;

 	if butr_ekc=. then butr_ekc=0;
	if butr_sug=. then butr_sug=0;
	if butr_sat=. then butr_sat=0;
	if butr_pro=. then butr_pro=0;
	if butr_vitD=. then butr_vitD=0;
	if butr_ca=. then butr_ca=0;
	if butr_fe=. then butr_fe=0;
	if butr_na=. then butr_na=0;
	if butr_k=. then butr_k=0;
	if butr_carb=. then butr_carb=0;
	if butr_mufa=. then butr_mufa=0;
	if butr_pufa=. then butr_pufa=0;

	if frzn_ekc=. then frzn_ekc=0;
	if frzn_sug=. then frzn_sug=0;
	if frzn_sat=. then frzn_sat=0;
	if frzn_pro=. then frzn_pro=0;
	if frzn_vitD=. then frzn_vitD=0;
	if frzn_ca=. then frzn_ca=0;
	if frzn_fe=. then frzn_fe=0;
	if frzn_na=. then frzn_na=0;
	if frzn_k=. then frzn_k=0;
	if frzn_carb=. then frzn_carb=0;
	if frzn_mufa=. then frzn_mufa=0;
	if frzn_pufa=. then frzn_pufa=0;

	if soybev_ekc=. then soybev_ekc=0;
	if soybev_sug=. then soybev_sug=0;
	if soybev_sat=. then soybev_sat=0;
	if soybev_pro=. then soybev_pro=0;
	if soybev_vitD=. then soybev_vitD=0;
	if soybev_ca=. then soybev_ca=0;
	if soybev_fe=. then soybev_fe=0;
	if soybev_na=. then soybev_na=0;
	if soybev_k=. then soybev_k=0;
	if soybev_carb=. then soybev_carb=0;
	if soybev_mufa=. then soybev_mufa=0;
	if soybev_pufa=. then soybev_pufa=0;

	if other_ekc=. then other_ekc=0;
	if other_sug=. then other_sug=0;
	if other_sat=. then other_sat=0;
	if other_pro=. then other_pro=0;
	if other_vitD=. then other_vitD=0;
	if other_ca=. then other_ca=0;
	if other_fe=. then other_fe=0;
	if other_na=. then other_na=0;
	if other_k=. then other_k=0;
	if other_carb=. then other_carb=0;
	if other_mufa=. then other_mufa=0;
	if other_pufa=. then other_pufa=0;

	meat_pro=beef_pro+lamb_pro+pork_pro+lnchn_pro;
	nsl_pro=nuts_pro+seeds_pro+lgmes_pro+tofu_pro+soybev_pro;
	meat_pro2=beef_pro2+lamb_pro2+pork_pro2+lnchn_pro2;
	nsl_pro2=nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+soybev_pro;
	dairy_pro=milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro;

	meat_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc;
	nsl_ekc=nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	meat_ekc2=beef_ekc2+lamb_ekc2+pork_ekc2+lnchn_ekc2;
	nsl_ekc2=nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc;
	dairy_ekc=milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc;

/*Variables for carbs*/
	meat_carb=beef_carb+lamb_carb+pork_carb+lnchn_carb;
	dairy_carb=milk_carb+cheese_carb+yghrt_carb+cream_carb+butr_carb+frzn_carb;
	nsl_carb=nuts_carb+seeds_carb+lgmes_carb+tofu_carb+soybev_carb;
	meat_carb2=beef_carb2+lamb_carb2+pork_carb2+lnchn_carb2;
	nsl_carb2=nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb;
	
	diet_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc+nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+soybev_ekc;
	diet_ekc2=beef_ekc2+lamb_ekc2+pork_ekc2+lnchn_ekc2+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+soybev_ekc;

/*keep sampleid beef_ekc lamb_ekc pork_ekc lnchn_ekc beef_ekc2 lamb_ekc2 pork_ekc2 lnchn_ekc2 
	 nuts_ekc seeds_ekc lgmes_ekc tofu_ekc nuts_ekc2 seeds_ekc2 lgmes_ekc2 tofu_ekc2
	 unq_nuts_ekc unq_seeds_ekc unq_lgmes_ekc unq_tofu_ekc
	 nuts_wtg nuts_wtg2 seeds_wtg seeds_wtg2 lgmes_wtg lgmes_wtg2 tofu_wtg tofu_wtg2;*/

run;
/*17,921 observations (Master Files)*/

/*This needs to be corrected! 2022-02-17*/

/*Verification examples (ekc):
	- Person 1:
		- Consumed luncheon and nuts
			- ekc luncheon post-replacement = 218.25 (lnchn_ekc)/2 = 109.125
			- ekc nuts post-replacement =  102.84 (ekc of nuts originally consumed) + (5.87 (unique nuts multiplier) x (55.02 - 17.52) (nuts_wtg2 - nuts_wtg)) = 322.96
	- Person 2:
		- Did not consume meat, only nuts
		- No replacement done, ekc of nuts before and after are the same
	- Person 3:
		- Consumed beef and luncheon, did not consume any nuts, seeds, or legumes
			- ekc beef post-replacement = 261.31/2 = 130.65
			- ekc luncheon post-replacement = 232.5/2 = 116.25
			- ekc nuts post-replacement = 6.07 (avg. weighted ekc from 'Food-List') x nuts_wtg2 = 191.3
			- ekc seeds post-replacement = 5.59 (avg. weighted ekc from 'Food-List') x seeds_wtg2 = 20.68
			- ekc legumes post-replacement = 0.93 (avg. weighted ekc from 'Food-List') x lgmes_wtg2 = 58
			- ekc tofu post-replacement = 2.43 (avg. weighted ekc from 'Food-List') x tofu_wtg2 = 17.17
	- Person 13: 
		- Consumed pork, nuts, and legumes
			- ekc pork post-replacement = 59.616 (pork_ekc)/2 = 29.81
			- ekc nuts post-replacement =  35.25 (ekc of nuts originally consumed) + (6.64 (unique nuts multiplier) x (7.14 - 5.3) (nuts_wtg2 - nuts_wtg)) = 47.4
			- ekc legumes post-replacement =  14.68 (ekc of legumes originally consumed) + (0.81 (unique nuts multiplier) x (24.39 - 18.13) (legumes_wtg2 - legmes_wtg)) = 19.75*/

proc means n nmiss mean data=rs1_25_nutr;
	var beef_ekc beef_ekc2 beef_sug beef_sug2 beef_sat beef_sat2 beef_pro beef_pro2 beef_vitD beef_vitD2 beef_ca beef_ca2 beef_fe beef_fe2 beef_na beef_na2 beef_k beef_k2 beef_carb beef_carb2 beef_mufa beef_mufa2 beef_pufa beef_pufa2
		lamb_ekc lamb_ekc2 lamb_sug lamb_sug2 lamb_sat lamb_sat2 lamb_pro lamb_pro2 lamb_vitD lamb_vitD2 lamb_ca lamb_ca2 lamb_fe lamb_fe2 lamb_na lamb_na2 lamb_k lamb_k2 lamb_carb lamb_carb2 lamb_mufa lamb_mufa2 lamb_pufa lamb_pufa2
		pork_ekc pork_ekc2 pork_sug pork_sug2 pork_sat pork_sat2 pork_pro pork_pro2 pork_vitD pork_vitD2 pork_ca pork_ca2 pork_fe pork_fe2 pork_na pork_na2 pork_k pork_k2 pork_carb pork_carb2 pork_mufa pork_mufa2 pork_pufa pork_pufa2
		lnchn_ekc lnchn_ekc2 lnchn_sug lnchn_sug2 lnchn_sat lnchn_sat2 lnchn_pro lnchn_pro2 lnchn_vitD lnchn_vitD2 lnchn_ca lnchn_ca2 lnchn_fe lnchn_fe2 lnchn_na lnchn_na2 lnchn_k lnchn_k2 lnchn_carb lnchn_carb2 lnchn_mufa lnchn_mufa2 lnchn_pufa lnchn_pufa2
		nuts_ekc nuts_ekc2 nuts_sug nuts_sug2 nuts_sat nuts_sat2 nuts_pro nuts_pro2 nuts_vitD nuts_vitD2 nuts_ca nuts_ca2 nuts_fe nuts_fe2 nuts_na nuts_na2 nuts_k nuts_k2 nuts_carb nuts_carb2 nuts_mufa nuts_mufa2 nuts_pufa nuts_pufa2
		seeds_ekc seeds_ekc2 seeds_sug seeds_sug2 seeds_sat seeds_sat2 seeds_pro seeds_pro2 seeds_vitD seeds_vitD2 seeds_ca seeds_ca2 seeds_fe seeds_fe2 seeds_na seeds_na2 seeds_k seeds_k2 seeds_carb seeds_carb2 seeds_mufa seeds_mufa2 seeds_pufa seeds_pufa2
		lgmes_ekc lgmes_ekc2 lgmes_sug lgmes_sug2 lgmes_sat lgmes_sat2 lgmes_pro lgmes_pro2 lgmes_vitD lgmes_vitD2 lgmes_ca lgmes_ca2 lgmes_fe lgmes_fe2 lgmes_na lgmes_na2 lgmes_k lgmes_k2 lgmes_carb lgmes_carb2 lgmes_mufa lgmes_mufa2 lgmes_pufa lgmes_pufa2
		tofu_ekc tofu_ekc2 tofu_sug tofu_sug2 tofu_sat tofu_sat2 tofu_pro tofu_pro2 tofu_vitD tofu_vitD2 tofu_ca tofu_ca2 tofu_fe tofu_fe2 tofu_na tofu_na2 tofu_k tofu_k2 tofu_carb tofu_carb2 tofu_mufa tofu_mufa2 tofu_pufa tofu_pufa2
		milk_ekc milk_sug milk_sat milk_pro milk_vitD milk_ca milk_fe milk_na milk_k milk_carb milk_mufa milk_pufa 
		cheese_ekc cheese_sug cheese_sat cheese_pro cheese_vitD cheese_ca cheese_fe cheese_na cheese_k cheese_carb cheese_mufa cheese_pufa
		yghrt_ekc yghrt_sug yghrt_sat yghrt_pro yghrt_vitD yghrt_ca yghrt_fe yghrt_na yghrt_k yghrt_carb yghrt_mufa yghrt_pufa
		cream_ekc cream_sug cream_sat cream_pro cream_vitD cream_ca cream_fe cream_na cream_k cream_carb cream_mufa cream_pufa
		butr_ekc butr_sug butr_sat butr_pro butr_vitD butr_ca butr_fe butr_na butr_k butr_carb butr_mufa butr_pufa
		frzn_ekc frzn_sug frzn_sat frzn_pro frzn_vitD frzn_ca frzn_fe frzn_na frzn_k frzn_carb frzn_mufa frzn_pufa
		soybev_ekc soybev_sug soybev_sat soybev_pro soybev_vitD soybev_ca soybev_fe soybev_na soybev_k soybev_carb soybev_mufa soybev_pufa
		other_ekc other_sug other_sat other_pro other_vitD other_ca other_fe other_na other_k other_carb other_mufa other_pufa
		diet_ekc diet_ekc2;
run; 

/*Some nutrient values are still missing. These are genuine missing values at the FID level. For example, there are 291 missing values for beef_vitD.
These respondents consumed beef, but vitD values are missing. It's okay to set them to 0 as done below, because we need to aggregate nutrient totals.
To verify, run the following lines:

proc means n nmiss data=rs1_50_nutr; var beef_vitD beef_vitD2; run;
data a;
	set rs1_50_nutr;
	if beef_vitD=. and beef_vitD2 ne 0;
	id=1;
	keep sampleid beef_wtg beef_vitD beef_vitD2 id;
run;

data b;
	set sbgrps;
	if sampleid='1209073911176613746_' and food_subgrp=1;
run;*/

/*Another test
/*data a;
set rs1_25_nutr;
if beef_vitD2=.;
keep sampleid beef_vitD2 beef_vitD beef_wtg unq_beef_vitD;
run;

data b;	
set beef_sum;
if sampleid='1001034851000879612_'; run;

/*Set missing values to 0 or else they will not add up*/
data rs1_25_nutr;
	set rs1_25_nutr;
	if beef_vitD2=. then beef_vitD2=0;
	/*if pork_sug2=. then pork_sug2=0;*/
	if pork_sat2=. then pork_sat2=0;
	if pork_vitD2=. then pork_vitD2=0;
	if pork_fe2=. then pork_fe2=0;
	if pork_mufa2=. then pork_mufa2=0;
	if pork_pufa2=. then pork_pufa2=0;
	/*if lnchn_sug2=. then lnchn_sug2=0;*/
	if lnchn_vitD2=. then lnchn_vitD2=0;
	/*if nuts_sug2=. then nuts_sug2=0;*/
	if nuts_vitD2=. then nuts_vitD2=0;
	/*if seeds_sug2=. then seeds_sug2=0;*/
	if seeds_vitD2=. then seeds_vitD2=0;
	/*if lgmes_sug2=. then lgmes_sug2=0;*/
	if lgmes_vitD2=. then lgmes_vitD2=0;
run;

/* !!!!!!!!!!!!!!!!!!!!!!! */
/*Use this as input for NCI*/
/* !!!!!!!!!!!!!!!!!!!!!!! */
data rs1_25_nutr_nci;
	set rs1_25_nutr;
/*Nutrient totals*/
/*Before - Note that these are equivalent to fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot (HS)*/
	/*tot_ekc=beef_ekc+lamb_ekc+pork_ekc+lnchn_ekc+nuts_ekc+seeds_ekc+lgmes_ekc+tofu_ekc+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc;
	tot_sug=beef_sug+lamb_sug+pork_sug+lnchn_sug+nuts_sug+seeds_sug+lgmes_sug+tofu_sug+milk_sug+cheese_sug+yghrt_sug+cream_sug+butr_sug+frzn_sug+other_sug;
	tot_sat=beef_sat+lamb_sat+pork_sat+lnchn_sat+nuts_sat+seeds_sat+lgmes_sat+tofu_sat+milk_sat+cheese_sat+yghrt_sat+cream_sat+butr_sat+frzn_sat+other_sat;
	tot_pro=beef_pro+lamb_pro+pork_pro+lnchn_pro+nuts_pro+seeds_pro+lgmes_pro+tofu_pro+milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro+other_pro;
	tot_vitD=beef_vitD+lamb_vitD+pork_vitD+lnchn_vitD+nuts_vitD+seeds_vitD+lgmes_vitD+tofu_vitD+milk_vitD+cheese_vitD+yghrt_vitD+cream_vitD+butr_vitD+frzn_vitD+other_vitD;
	tot_ca=beef_ca+lamb_ca+pork_ca+lnchn_ca+nuts_ca+seeds_ca+lgmes_ca+tofu_ca+milk_ca+cheese_ca+yghrt_ca+cream_ca+butr_ca+frzn_ca+other_ca;
	tot_fe=beef_fe+lamb_fe+pork_fe+lnchn_fe+nuts_fe+seeds_fe+lgmes_fe+tofu_fe+milk_fe+cheese_fe+yghrt_fe+cream_fe+butr_fe+frzn_fe+other_fe;
	tot_na=beef_na+lamb_na+pork_na+lnchn_na+nuts_na+seeds_na+lgmes_na+tofu_na+milk_na+cheese_na+yghrt_na+cream_na+butr_na+frzn_na+other_na;
	tot_k=beef_k+lamb_k+pork_k+lnchn_k+nuts_k+seeds_k+lgmes_k+tofu_k+milk_k+cheese_k+yghrt_k+cream_k+butr_k+frzn_k+other_k;

	/*Note that the variable fsddesa refers to saturated fat as a % of TEI*/
	/*Note that we created a variable for free sugars as a % of TEI in step 9 (tot_sug_pcnt)*/
	/*I checked if tot_sug = tot_free_sug and ot checks out; also tot_sug_pcnt_v2 = tot_sug_pcnt*/

	/*tot_sug=beef_sug+lamb_sug+pork_sug+lnchn_sug+nuts_sug+seeds_sug+lgmes_sug+tofu_sug+milk_sug+cheese_sug+yghrt_sug+cream_sug+butr_sug+frzn_sug+other_sug;
	tot_sug_pcnt_v2=((tot_sug*4)/fsddekc)*100;

/*After*/
	tot_ekc2=beef_ekc2+lamb_ekc2+pork_ekc2+lnchn_ekc2+nuts_ekc2+seeds_ekc2+lgmes_ekc2+tofu_ekc2+milk_ekc+cheese_ekc+yghrt_ekc+cream_ekc+butr_ekc+frzn_ekc+other_ekc;
	tot_sug2=beef_sug2+lamb_sug2+pork_sug2+lnchn_sug2+nuts_sug2+seeds_sug2+lgmes_sug2+tofu_sug2+milk_sug+cheese_sug+yghrt_sug+cream_sug+butr_sug+frzn_sug+other_sug;
	tot_sat2=beef_sat2+lamb_sat2+pork_sat2+lnchn_sat2+nuts_sat2+seeds_sat2+lgmes_sat2+tofu_sat2+milk_sat+cheese_sat+yghrt_sat+cream_sat+butr_sat+frzn_sat+other_sat;
	tot_pro2=beef_pro2+lamb_pro2+pork_pro2+lnchn_pro2+nuts_pro2+seeds_pro2+lgmes_pro2+tofu_pro2+milk_pro+cheese_pro+yghrt_pro+cream_pro+butr_pro+frzn_pro+other_pro;
	tot_vitD2=beef_vitD2+lamb_vitD2+pork_vitD2+lnchn_vitD2+nuts_vitD2+seeds_vitD2+lgmes_vitD2+tofu_vitD2+milk_vitD+cheese_vitD+yghrt_vitD+cream_vitD+butr_vitD+frzn_vitD+other_vitD;
	tot_ca2=beef_ca2+lamb_ca2+pork_ca2+lnchn_ca2+nuts_ca2+seeds_ca2+lgmes_ca2+tofu_ca2+milk_ca+cheese_ca+yghrt_ca+cream_ca+butr_ca+frzn_ca+other_ca;
	tot_fe2=beef_fe2+lamb_fe2+pork_fe2+lnchn_fe2+nuts_fe2+seeds_fe2+lgmes_fe2+tofu_fe2+milk_fe+cheese_fe+yghrt_fe+cream_fe+butr_fe+frzn_fe+other_fe;
	tot_na2=beef_na2+lamb_na2+pork_na2+lnchn_na2+nuts_na2+seeds_na2+lgmes_na2+tofu_na2+milk_na+cheese_na+yghrt_na+cream_na+butr_na+frzn_na+other_na;
	tot_k2=beef_k2+lamb_k2+pork_k2+lnchn_k2+nuts_k2+seeds_k2+lgmes_k2+tofu_k2+milk_k+cheese_k+yghrt_k+cream_k+butr_k+frzn_k+other_k;
	tot_carb2=beef_carb2+lamb_carb2+pork_carb2+lnchn_carb2+nuts_carb2+seeds_carb2+lgmes_carb2+tofu_carb2+soybev_carb+milk_carb+cheese_carb+yghrt_carb+cream_carb+butr_carb+frzn_carb+other_carb;
	tot_mufa2=beef_mufa2+lamb_mufa2+pork_mufa2+lnchn_mufa2+nuts_mufa2+seeds_mufa2+lgmes_mufa2+tofu_mufa2+milk_mufa+cheese_mufa+yghrt_mufa+cream_mufa+butr_mufa+frzn_mufa+other_mufa;
	tot_pufa2=beef_pufa2+lamb_pufa2+pork_pufa2+lnchn_pufa2+nuts_pufa2+seeds_pufa2+lgmes_pufa2+tofu_pufa2+milk_pufa+cheese_pufa+yghrt_pufa+cream_pufa+butr_pufa+frzn_pufa+other_pufa;

	/*Free sugars and saturated fat expressed as a percentage of total energy intake*/
	if tot_sug2 ne 0 and tot_ekc2 ne 0 then tot_sug2_pcnt=((tot_sug2*4)/tot_ekc2)*100;
	if tot_sug2=0 or tot_ekc2=0 then tot_sug2_pcnt=0;

	if tot_sat2 ne 0 and tot_ekc2 ne 0 then tot_sat2_pcnt=((tot_sat2*9)/tot_ekc2)*100;
	if tot_sat2=0 or tot_ekc2=0 then tot_sat2_pcnt=0;

	/*keep sampleid suppid wts_m wts_mhw admfw dhhddri dhh_sex dhh_age mhwdbmi mhwdhtm mhwdwtk
	fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_sug2_pcnt tot_sat2_pcnt;*/
run;
/*17,921 observations (Master Files)*/

proc means data=rs1_25_nutr_nci;
	var beef_carb2 lamb_carb2 pork_carb2 lnchn_carb2 nuts_carb2 seeds_carb2 lgmes_carb2 tofu_carb2 soybev_carb milk_carb cheese_carb yghrt_carb cream_carb butr_carb frzn_carb other_carb;
run;

/*Preliminary results (nutrients)*/
proc means n nmiss mean min max data=rs1_25_nutr_nci;	
	var fsddekc fsddsug fsddfas fsddpro fsdddmg fsddcal fsddiro fsddsod fsddpot fsddesa fsddcar fsddfam fsddfap tot_sug_pcnt tot_ekc2 tot_sug2 tot_sat2 tot_pro2 tot_vitD2 tot_ca2 tot_fe2 tot_na2 tot_k2 tot_carb2 tot_sug2_pcnt tot_sat2_pcnt
		tot_mufa2 tot_pufa2;
run;
/*g of free sug (tot_free_sug) is around 53 and free sug as % of TEI is around 11, which is in line with Rana et al. 2021*/

/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Input for NCI w/ supplements*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!! */
data rs1_25_nutr_nci;
	set rs1_25_nutr_nci;
	idnty=1;
run;

proc sort data=rs1_25_nutr_nci; by sampleid suppid; run;
proc sort data=vst_nutr_cncrn; by sampleid suppid; run;

data rs1_25_nutr_nci_supp;
	merge rs1_25_nutr_nci vst_nutr_cncrn;
	by sampleid suppid;
	if idnty=1;
	drop idnty;
run; 
/*17,921 obs*/

data rs1_25_nutr_nci_supp;
	set rs1_25_nutr_nci_supp;
	/*vitD supplement users: vitD_supp_user=1; non-users: vitD_supp_user=2*/
	if vsdfdmg=1 then vitD_supp_user=1; else vitD_supp_user=2;
	if vsdfcal=1 then cal_supp_user=1; else cal_supp_user=2;
	if vsdfiro=1 then iron_supp_user=1; else iron_supp_user=2;
	if vsdfpot=1 then pot_supp_user=1; else pot_supp_user=2;
run;

data rs1_25_nutr_nci_supp;
	set rs1_25_nutr_nci_supp;

/*Nutrient intakes from food + supplements (observed)*/
	if VSTDCAL ne . then tot_ca_supp=FSDDCAL+VSTDCAL;
	if VSTDIRO ne . then tot_fe_supp=FSDDIRO+VSTDIRO;
	if VSTDPOT ne . then tot_k_supp=FSDDPOT+VSTDPOT;
	if VSTDDMG ne . then tot_vitD_supp=FSDDDMG+VSTDDMG;
	if VSTDSOD ne . then tot_na_supp=FSDDSOD+VSTDSOD;

	if VSTDCAL=. then tot_ca_supp=FSDDCAL;
	if VSTDIRO=. then tot_fe_supp=FSDDIRO;
	if VSTDPOT=. then tot_k_supp=FSDDPOT;
	if VSTDDMG=. then tot_vitD_supp=FSDDDMG;
	if VSTDSOD=. then tot_na_supp=FSDDSOD; 

/*Nutrient intakes from food + supplements (replacements)*/
	if VSTDCAL ne . then tot_ca2_supp=tot_ca2+VSTDCAL;
	if VSTDIRO ne . then tot_fe2_supp=tot_fe2+VSTDIRO;
	if VSTDPOT ne . then tot_k2_supp=tot_k2+VSTDPOT;
	if VSTDDMG ne . then tot_vitD2_supp=tot_vitD2+VSTDDMG;
	if VSTDSOD ne . then tot_na2_supp=tot_na2+VSTDSOD;

	if VSTDCAL=. then tot_ca2_supp=tot_ca2;
	if VSTDIRO=. then tot_fe2_supp=tot_fe2;
	if VSTDPOT=. then tot_k2_supp=tot_k2;
	if VSTDDMG=. then tot_vitD2_supp=tot_vitD2;
	if VSTDSOD=. then tot_na2_supp=tot_na2; 

run;

/*Datasets for vitD*/
data rs1_25_supp_users_vitD;
	set rs1_25_nutr_nci_supp;
	if vitD_supp_user=1;
run;
/* 6278 observations */
data rs1_25_supp_nonusers_vitD;
	set rs1_25_nutr_nci_supp;
	if vitD_supp_user=2;
run;
/* 11643 observations */

proc freq data=rs1_25_supp_users_vitD;
	table dhhddri;
run;

/*Datasets for iron*/
data rs1_25_supp_users_iron;
	set rs1_25_nutr_nci_supp;
	if iron_supp_user=1;
run;
/* 2739 observations */
data rs1_25_supp_nonusers_iron;
	set rs1_25_nutr_nci_supp;
	if iron_supp_user=2;
run;
/* 15182 observations */

/*Datasets for calcium*/
data rs1_25_supp_users_cal;
	set rs1_25_nutr_nci_supp;
	if cal_supp_user=1;
run;
/* 4550 observations */
data rs1_25_supp_nonusers_cal;
	set rs1_25_nutr_nci_supp;
	if cal_supp_user=2;
run;
/* 13371 observations */

/*Datasets for potassium*/
data rs1_25_supp_users_pot;
	set rs1_25_nutr_nci_supp;
	if pot_supp_user=1;
run;
/* 1987 observations */
data rs1_25_supp_nonusers_pot;
	set rs1_25_nutr_nci_supp;
	if pot_supp_user=2;
run;
/* 15934 observations */

proc means n nmiss mean min max data=rs1_25_nutr_nci_supp;	
	var fsddcal fsddiro fsddpot fsdddmg fsddsod tot_ca2 tot_fe2 tot_vitD2 tot_k2 tot_na2
		tot_ca_supp tot_fe_supp tot_k_supp tot_vitD_supp tot_na_supp tot_ca2_supp tot_fe2_supp tot_k2_supp tot_vitD2_supp tot_na2_supp;
run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*Use this for health outcome anaylses*/
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
data rs1_25_nutr_nci;
	set rs1_25_nutr_nci;

/*Observed diets*/

	/*Red meat*/
	red_meat_wtg=beef_wtg+lamb_wtg+pork_wtg;
	red_meat_wtg2=beef_wtg2+lamb_wtg2+pork_wtg2;

	/*Nuts and seeds*/
	nts_sds_wtg=nuts_wtg+seeds_wtg;
	nts_sds_wtg2=nuts_wtg2+seeds_wtg2;

run;

/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/* Use this for nci anaylses for foods */
/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
/*This can be used for observed diets and RS1-25% but NOT RS1-50% or RS2 scenarios (need milk_wtg2)*/
data rs1_25_food_nci;
	set rs1_25_nutr_nci;
	keep sampleid suppid seq2 weekend wts_m sex dhh_age
		red_meat_wtg lnchn_wtg nts_sds_wtg lgmes_wtg milk_wtg
		red_meat_wtg2 lnchn_wtg2 nts_sds_wtg2 lgmes_wtg2 /*milk_wtg2*/;
run;
/*17,921 obs*/

/*Check red meat intake (obs) for males*/
data a_m; set rs1_25_food_nci; if sex=0; run;
proc means data=a_m; var red_meat_wtg; run;

/*Check red meat intake (obs) for females*/
data a_f; set rs1_25_food_nci; if sex=1; run;
proc means data=a_f; var red_meat_wtg; run;


/*Check % of recalls that reported 0 intake of:
	- red_meat_wtg
	- lnchn_wtg
	- nts_sds_wtg
	- lgmes_wtg
	- milk_wtg*/

proc sort data=rs1_25_nutr_nci; by sampleid suppid; run;

data rs1_25_nutr_nci_test;
	set rs1_25_nutr_nci;
	keep sampleid suppid dhh_sex dhh_age wts_m seq2 weekend dhhddri
/*Observed intakes*/
	red_meat_wtg lnchn_wtg nts_sds_wtg lgmes_wtg milk_wtg
/*Intakes of red and processed meat and plant protien food post-replacement (RS1-25% and RS1-50%)*/
	red_meat_wtg lnchn_wtg nts_sds_wtg2 lgmes_wtg2;
run;
/*17,921 obs (1st and second recalls)*/

data rs1_25_nutr_nci_test_1;
	set rs1_25_nutr_nci_test;
/*Observed diets*/
	/*if red_meat_wtg ne 0 then delete;
	if lnchn_wtg ne 0 then delete;
	if nts_sds_wtg ne 0 then delete;
	if lgmes_wtg ne 0 then delete;
	if milk_wtg ne 0 then delete;*/

/*RS1-25% and RS1-50% (only % of recalls reporting plant protein foods would change)*/
	/*if nts_sds_wtg2 ne 0 then delete;*/
	if lgmes_wtg2 ne 0 then delete;

run;

proc sort data=rs2_25_nutr_nci; by sampleid suppid; run;

data rs2_25_nutr_nci_test;
	set rs2_25_nutr_nci;
	keep sampleid suppid dhh_sex /*red_meat_wtg lnchn_wtg nts_sds_wtg lgmes_wtg milk_wtg*/
	nts_sds_wtg2 lgmes_wtg2;
run;
/*17,921 obs (1st and second recalls)*/

data rs2_25_nutr_nci_test_1;
	set rs2_25_nutr_nci_test;
/*RS2-25% and RS2-50% (only % of recalls reporting plant protein foods would change)*/
	if nts_sds_wtg2 ne 0 then delete;
	/*if lgmes_wtg2 ne 0 then delete;*/
run;
