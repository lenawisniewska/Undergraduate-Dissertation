cd "/Users/lenawisniewska/Desktop/Diss"
use "final data/regressions_prepared_final.dta", clear

generate outages_in_community_per1000 = outages_in_community_per*100
drop outages_in_community_percentage
rename outages_in_community_per1000 outages_in_community_percentage
summarize outages_in_community_percentage

drop outages_per_female
generate outages_per_female = outages_in_community_percentage*female
gen outages_per_skill = outages_in_community_percentage*skilled
gen outages_skill_female = outages_in_community_percentage*skilled*female
generate loglight_skilled = loglight*skilled
generate loglight_skill_female = loglight*skilled*female
generate age_skill = age*skilled
generate agesq_skill = agesq*skilled
generate cell_skill = cell_PSU*skilled

drop if country == .
drop if year == .
drop if education == .
drop if employment_half == .
drop if outages_in_community_percentage == .
drop if loglight == .
drop if female == .
drop if age == .
drop if cell_PSU == .
drop if ln_temperature == .
drop if ln_tp == .
drop if urban == .
count

**************************
*    OCCUPATION TABLE    *
**************************

drop if occupation == 0 | occupation == 1 | occupation == 95
tabulate occupation if female == 0 
tabulate occupation if female == 1

*******************************
*    TABLE 1 - FIRST STAGE    *
*******************************

**for outages
reghdfe outages_in_community_per loglight loglight_female age  agesq  female  cell_PSU ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num)
estimates store fs1

** for the interaction
reghdfe outages_per_female loglight loglight_female age  agesq  female  cell_PSU ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num)
estimates store fs2

esttab fs1 fs2, star(* 0.10 ** 0.05 *** 0.01)

//obtaining F stat for first stage
rename outages_in_community_per outages

ivreg2 employment_half age  agesq  female  cell_PSU ln_temperature ln_tp urban i.education i.country i.year (outages = loglight) [pw= withinwt], first cl(location_num)

ivreg2 employment_half (outages outages_per_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female  ln_temperature   ln_tp urban i.education i.country i.year [pw= withinwt],  first cl(location_num)

rename outages outages_in_community_percentage

//scatter plot
binscatter outages_in_community_percentage loglight, n(20) name(plot2, replace)
graph export "firststage_10.jpg", as(jpg) replace

*******************************
*    TABLE 2 - INTERACTION    *
*******************************

**OLS
reghdfe employment_half outages_in_community_percentage age agesq  female  cell_PSU ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num)
estimates store ols1

reghdfe employment_half outages_in_community_percentage outages_per_female age age_female agesq  agesq_female female  cell_PSU cell_female ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num)
estimates store ols2

**IV
ivreghdfe employment_half age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_per = loglight) [pw= withinwt],  abs(education country year) cl(location_num)
estimates store iv1

ivreghdfe employment_half (outages_in_community_percentage outages_per_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female  ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education) cl(location_num)
estimates store iv2
lincom outages_in_community_percentage + outages_per_female 

esttab ols1 ols2 iv1 iv2, star(* 0.10 ** 0.05 *** 0.01)

//esttab ols1o ols2o iv1o iv2o, star(* 0.10 ** 0.05 *** 0.01)

//esttab iv2 iv2o,  star(* 0.10 ** 0.05 *** 0.01)


ivreghdfe employment_half (outages_in_community_percentage outages_per_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female  ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education) cl(location_num)

ologit employment x1 x2 x3

****************************************
*    TABLE 4 - SKILLED VS UNSKILLED    *
****************************************

//no interactions
ivreghdfe employment_half female  skilled age  agesq  cell_PSU ln_temperature ln_tp urban (outages_in_community_per = loglight) [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store skilled1

//interactions with skill
ivreghdfe employment_half (outages_in_community_percentage outages_per_skill = loglight loglight_skilled) female skilled age age_skill  agesq agesq_skill  cell_PSU cell_skill  ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education) cl(location_num)
estimates store skilled2

//interactions with female and skill
ivreghdfe employment_half (outages_in_community_percentage outages_per_skill outages_per_female = loglight loglight_skilled loglight_female) female skilled age age_female  agesq  agesq_female cell_PSU cell_female  ln_temperature   ln_tp urban age_skill agesq_skill cell_skill  [pw= withinwt],  absorb(country year education) cl(location_num)
estimates store skilled3

//three way interaction + both two way interactions
ivreghdfe employment_half (outages_in_community_percentage outages_per_skill outages_per_female outages_skill_female = loglight loglight_skilled loglight_female loglight_skill_female) female skilled age age_female age_skill agesq agesq_skill agesq_female   cell_PSU  cell_female cell_skill  ln_temperature   ln_tp urban[pw= withinwt],  absorb(country year education) cl(location_num)
estimates store skilled4
test outages_per_female outages_skill_female

esttab skilled1 skilled2 skilled3 skilled4, star(* 0.10 ** 0.05 *** 0.01)

summarize employment if skilled == 0 | skilled == 1


ivreghdfe employment_half (outages_in_community_percentage outages_per_skill outages_per_female outages_skill_female = loglight loglight_skilled loglight_female loglight_skill_female) female skilled age age_female age_skill agesq agesq_skill agesq_female   cell_PSU  cell_female cell_skill  ln_temperature   ln_tp urban occupation[pw= withinwt],  absorb(country year education) cl(location_num)
estimates store skilled5

esttab skilled4 skilled5, star(* 0.10 ** 0.05 *** 0.01)


**********************************************
*    TABLE 5 - CONTROLLING FOR OCCUPATION   *
**********************************************

drop if occupation == .
summarize employment_half

ivreghdfe employment_half (outages_in_community_percentage outages_per_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education) cl(location_num)
estimates store iv1o
lincom outages_in_community_percentage + outages_per_female 

ivreghdfe employment_half (outages_in_community_percentage outages_per_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education occupation) cl(location_num)
estimates store iv2o
lincom outages_in_community_percentage + outages_per_female 

esttab iv1o iv2o, star(* 0.10 ** 0.05 *** 0.01)


////ROBUSTNESS ----->
********************************
*    TABLE 5 - PLACEBO TEST    *
********************************
//I only run reduced form regressions, because since these communities have 0 electrified households, they have a missing value for outages (because otherwise they'd have 0 in the denominator)
use "final data/regressions_prepared_forplacebo.dta", clear //dataset with only places with missing value for outages, whereas my normal dataset has only places with a NOT missing values for outages

reghdfe employment_half loglight age  agesq  female  cell_PSU  ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num) 

///----> not only is it not significantly from 0, but it's not even negative! good!

use "final data/regressions_prepared_final.dta", clear


**************************************************APPENDIX***************************************************************

///TABLE A1


///TABLE A2

**********************************************ADDITIONAL APPENDIX********************************************************

///TABLE B1

**************************
*   REPLICATING MENSAH   *
**************************

**OLS
reghdfe employment outages_in_community_dummy age agesq  female  cell_PSU ln_temperature ln_tp [pw= withinwt],  abs(education country year) cl(uniqueea) 
// he gets -0.021, i get -0.0197
estimates store ols

**IV
ivreghdfe employment age  agesq  female  cell_PSU ln_temperature ln_tp (outages_in_community_dummy = loglight) [pw= withinwt],  abs(education country year) cl(uniqueea)
estimates store iv
// he gets -0.137, i get -0.133

esttab ols iv, star(* 0.10 ** 0.05 *** 0.01)


///TABLE B2

**************************
*    GENDER SUBSAMPLE    *
**************************

**OLS
reghdfe employment outages_in_community_dummy age agesq  female  cell_PSU ln_temperature ln_tp urban if female == 0 [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store olsmale

reghdfe employment outages_in_community_dummy age agesq  female  cell_PSU ln_temperature ln_tp urban if female == 1 [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store olsfemale

**IV
ivreghdfe employment age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_dummy = loglight) if female == 0 [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store ivmale

ivreghdfe employment age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_dummy = loglight) if female == 1 [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store ivfemale

**REDUCED FORM
reghdfe employment loglight  age  agesq  female  cell_PSU ln_temperature ln_tp urban if female == 0 [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store reducedmale

reghdfe employment loglight  age  agesq  female  cell_PSU ln_temperature ln_tp urban if female == 1 [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store reducedfemale

esttab olsmale olsfemale ivmale ivfemale reducedmale reducedfemale, star(* 0.10 ** 0.05 *** 0.01)













//---> ADDITIONAL APPENDIX IF AT ALL
************************************
*   TABLE 2 - GENERAL REGRESSION   *
************************************
//only 1 reduce column, bc there are not 2 options for outages, because it doesn't use outages (its reduced)
// SLIGHT ISSUE: theyre not significant

**OLS
reghdfe employment outages_in_community_dummy age agesq  female  cell_PSU ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store ols1
reghdfe employment outages_in_community_per age agesq  female  cell_PSU ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store ols2

**IV
ivreghdfe employment age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_dummy = loglight) [pw= withinwt],  abs(education country year) cl(location_num)
estimates store iv1

ivreghdfe employment age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_per = loglight) [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store iv2

**REDUCED FORM
reghdfe employment loglight  age  agesq  female  cell_PSU ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num)
estimates store reduced1

esttab ols1 ols2 iv1 iv2 reduced1, star(* 0.10 ** 0.05 *** 0.01)

**************************************************
*    USING 0/1 EMPLOYMENT AS ROBUSTNESS CHECK    *
**************************************************

**OLS
reghdfe employment outages_in_community_percentage outages_per_female age agesq  female  cell_PSU ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num)
estimates store ols1a

reghdfe employment outages_in_community_percentage outages_per_female age age_female agesq  agesq_female female  cell_PSU cell_female ln_temperature ln_tp urban [pw= withinwt],  abs(education country year) cl(location_num)
estimates store ols2a

**IV
ivreghdfe employment age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_per = loglight) [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store iv1a

ivreghdfe employment (outages_in_community_percentage outages_per_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female  ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education) cl(location_num)
estimates store iv2a
lincom outages_in_community_percentage + outages_per_female 

esttab ols1a ols2a iv1a iv2a, star(* 0.10 ** 0.05 *** 0.01)




******************************************
*    TABLE 3 - EXTENSIVE VS INTENSIVE    *
******************************************

///if we consider part time employment, find more negative effect for both men and women. women go from -0.06 to -0.09, men go from -0.17 to -0.19

**extensive
ivreghdfe employment age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_dummy outages_dum_female = loglight loglight_female) [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store extensive1

ivreghdfe employment (outages_in_community_dummy outages_dum_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female  ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education#female) cl(location_num)
estimates store extensive2
lincom outages_in_community_dummy + outages_dum_female  //-0.06

**intensive and extensive
ivreghdfe employment_half age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_dummy outages_dum_female = loglight loglight_female) [pw= withinwt],  abs(education country year) cl(location_num) 
estimates store main1

ivreghdfe employment_half (outages_in_community_dummy outages_dum_female = loglight loglight_female) female age age_female  agesq  agesq_female cell_PSU cell_female  ln_temperature   ln_tp urban [pw= withinwt],  absorb(country year education#female) cl(location_num)
estimates store main2
lincom outages_in_community_dummy + outages_dum_female  //-0.088 -> more negative

esttab extensive1 extensive2 main1 main2, star(* 0.10 ** 0.05 *** 0.01)

***only intensive
gen employed = 0
replace employed = 1 if employment_half == 0.5 | employment_half == 1

ivreghdfe employment_half age  agesq  female  cell_PSU ln_temperature ln_tp urban (outages_in_community_dummy outages_dum_female = loglight loglight_female) if employed == 1 [pw= withinwt],  abs(education country year) cl(location_num) 






