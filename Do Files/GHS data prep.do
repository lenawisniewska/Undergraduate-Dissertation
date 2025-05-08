cd "/Users/lenawisniewska/Desktop/Diss"


*********assets*********
use "raw data/NGA_2012_GHSP-W2_v02_M_STATA/Post Planting Wave 2/Household/sect5a_plantingw2.dta", clear

drop state zone lga sector tracked_obs item_desc

generate owned = .
replace owned = 1 if s5q1 >= 1
replace owned = 0 if s5q1 == 0

drop s5q1

generate electric_item = 0
replace electric_item = 1 if inlist(item_cd, 314, 323, 328, 329, 316, 321, 313, 312, 320, 324, 333, 325, 332, 322, 330, 309, 327, 315, 326)

generate electric_owned = 0
replace electric_owned = 1 if owned == 1 & electric_item == 1

sort hhid

keep hhid owned electric_owned ea electric_item
save "intermediate data/nigeria_assets1.dta", replace



*********outages*********
use "raw data/NGA_2012_GHSP-W2_v02_M_STATA/Post Harvest Wave 2/Household/sect8_harvestw2.dta", clear
keep hhid s8q17 s8q23
rename s8q17 connection
rename s8q23 blackouts
tabulate blackouts
tabulate connection
generate connected = .
replace connected = 1 if connection == 1
replace connected = 0 if connection == 2
//never is 1, everyday is 2, several times a week is 3, several times a month is 4, several times a year is 5
generate outages = .
replace outages = 4 if blackouts == 2
replace outages = 3 if blackouts == 3
replace outages = 2 if blackouts == 4
replace outages = 1 if blackouts == 5
replace outages = 0 if blackouts == 1

keep hhid connected outages
sort hhid
save "intermediate data/nigeria_outages.dta", replace



*********controls*********
use "raw data/NGA_2012_GHSP-W2_v02_M_STATA/Post Planting Wave 2/Household/sect1_plantingw2.dta", clear
keep if s1q3 == 1
tabulate indiv
rename s1q2 sex
rename s1q7_year yob
keep hhid state sector sex yob lga
order hhid state sector sex yob
summarize yob
save "intermediate data/nigeria_controls.dta", replace



*********income*********
use "raw data/NGA_2012_GHSP-W2_v02_M_STATA/Post Planting Wave 2/Household/sect3a_plantingw2.dta", clear
rename s3aq21a income
keep if indiv == 1
keep hhid income
save "intermediate data/nigeria_income.dta", replace



//prepare to justify not controlling for education - too many categories


*********geo instruments*********
use "raw data/NGA_2012_GHSP-W2_v02_M_STATA/Geodata Wave 2/NGA_HouseholdGeovars_Y2.dta", clear
rename af_bio_1 temperature 
rename af_bio_12 precipitation 
rename srtm_nga elevation
keep hhid temperature precipitation elevation dist_road2
sort hhid
save "intermediate data/nigeria_weather.dta", replace



*********merge********
cd "/Users/lenawisniewska/Desktop/Diss/intermediate data"

use "nigeria_assets1.dta", clear
merge m:1 hhid using "nigeria_outages.dta" 
drop _merge
save "GHAmerge1.dta", replace

use "GHAmerge1.dta", clear
merge m:1 hhid using "nigeria_controls.dta" 
drop _merge
save "GHAmerge2.dta", replace

use "GHAmerge2.dta", clear
merge m:1 hhid using "nigeria_income.dta" 
drop _merge
save "GHAmerge3.dta", replace

use "GHAmerge3.dta", clear
merge m:1 hhid using "nigeria_weather.dta" 
drop _merge
save "GHAmerge4.dta", replace

gen urban = 0
replace urban = 1 if sector == 1

gen female = 0 
replace female = 1 if sex == 2

gen age = 2012 - yob
drop if age > 105

summarize income //amount in naira of last payment for "main job" (issue - people can be getting paid at different frequencies)
gen income_1000 = income/1000

generate temp_celsius = temperature/10

rename outages blackouts

save "/Users/lenawisniewska/Desktop/Diss/final data/GHSFINAL", replace
