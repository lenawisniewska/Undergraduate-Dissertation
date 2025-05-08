cd /Users/lenawisniewska/Desktop/Diss 

*****************
*    ROUND 6    *
*****************

import delimited "raw data/afb_full_r6.csv", clear
save "raw data/r6raw.dta", replace

use "raw data/r6raw.dta", clear
generate round = 6
drop if uniqueea == .
//generate uniqueea
generate country_string = string(country)
generate round_string = string(round)
gen str40 uniqueea_str = string(uniqueea, "%15.0g")
drop uniqueea
generate uniqueea = round_string + "_" + country_string + "_" + uniqueea_str
duplicates report uniqueea

rename q101 gender
generate female = .
replace female = 1 if gender == 2
replace female = 0 if gender == 1

rename q94 electricity_house
replace electricity_house = . if electricity_house == -1 | electricity_house == 9

rename q95 employment
replace employment = . if employment == -1 | employment == 9 | employment == 0

rename q97 education
replace education = . if education == -1 | education == 99 | education == 98

rename q1 age
replace age = . if age == -1 | age == 999 | age == 998
generate agesq = age*age

rename q96a occupation
replace occupation = . if occupation == -1 | occupation == 99 | occupation == 98

rename ea_svc_d cell_PSU // 1 is yes, 0 is no
replace cell_PSU = . if cell_PSU == 9

split dateintr, parse("-") generate(part)
generate year = part3
destring year, replace
replace year = year + 2000 
summarize year

tostring round, replace
gen respno_round = respno + "_" + round

drop if latitude == .
drop if longitude == .

tabulate q8e
rename q8e cash_income
replace cash_income = . if inlist(cash_income, 9, 98, -1)

keep respno_round country round year urbrur cell_PSU age agesq female education employment electricity_house occupation latitude longitude uniqueea withinwt cash_income locationlevel1

save "intermediate data/r6.dta", replace

*****************
*    ROUND 7    *
*****************

import delimited "raw data/R7.csv", clear
save "raw data/r7raw.dta", replace

use "raw data/r7raw.dta", clear
//sort country and round
drop country
rename country_r6list country
generate round = 7
//generate uniqueea
generate eanumb_ab_string = string(eanumb_ab)
generate country_string = string(country)
generate round_string = string(round)
generate uniqueea = round_string + "_" + country_string + "_" + eanumb_ab_string

rename ea_gps_la latitude
rename ea_gps_lo longitude
destring latitude, replace
destring longitude, replace

rename q101 gender
generate female = .
replace female = 1 if gender == 2
replace female = 0 if gender == 1

rename q93 electricity_house
replace electricity_house = . if electricity_house == -1 | electricity_house == 9 |  electricity_house == 8

rename q94 employment
replace employment = . if employment == -1 | employment == 9 | employment == 8 |  employment == 0

rename q97 education
replace education = . if education == -1 | education == 99 | education == 98

rename q1 age
replace age = . if age == -1 | age == 999 | age == 998
generate agesq = age*age

rename q96b occupation
replace occupation = . if occupation == -1 | occupation == 99 | occupation == 98 | occupation == 97

rename ea_svc_d cell_PSU
replace cell_PSU = . if cell_PSU == 9 | cell_PSU == -1

split dateintr, parse("-") generate(part)
generate year = part1
destring year, replace

tostring round, replace
gen respno_round = respno + "_" + round

drop if latitude == .
drop if longitude == .

generate loc = latitude*longitude
duplicates report loc //call this EA

tabulate q8e
rename q8e cash_income
replace cash_income = . if inlist(cash_income, 9, 8)

keep respno_round respno country round year urbrur cell_PSU age agesq female education employment electricity_house occupation latitude longitude uniqueea withinwt cash_income locationlevel1

save "intermediate data/r7.dta", replace

***************
*    MERGE    *
***************

use "intermediate data/r6.dta", clear
sort respno_round
merge 1:1 respno_round using "intermediate data/r7.dta"
save "intermediate data/AFROBAROMETERmerged.dta", replace

use "intermediate data/AFROBAROMETERmerged.dta", replace

drop respno_round
drop if longitude == .
drop if latitude == .
summarize longitude
summarize latitude

generate reliable = .
replace reliable = 1 if electricity_house == 5
replace reliable = 0 if electricity_house == 1 | electricity_house == 2 | electricity_house == 3 | electricity_house == 4 

generate connected = .
replace connected = 1 if electricity_house == 1 | electricity_house == 2 | electricity_house == 3 | electricity_house == 4 | electricity_house == 5
replace connected = 0 if electricity_house == 0 

//generating electricity measures
sort uniqueea
by uniqueea: egen n_connected = total(connected==1)
by uniqueea: egen n_noreliable = total(reliable==0)
gen outages_in_community_percentage = n_noreliable / n_connected
gen outages_in_community_dummy = .
replace outages_in_community_dummy = 1 if outages_in_community_percentage > 0.5
replace outages_in_community_dummy = 0 if outages_in_community_percentage <= 0.5
replace outages_in_community_dummy = . if outages_in_community_percentage == .

summarize outages_in_community_dummy // close but a bit off, and wrong ratio
summarize outages_in_community_percentage

drop _merge

egen location_num = group(locationlevel)

drop locationlevel1

save "intermediate data/AFROBAROMETERfinal.dta", replace

****************************
*    SUMMARY STATISTICS    *
****************************

use "intermediate data/AFROBAROMETERfinal.dta", clear 

summarize female
summarize age
summarize cell_PSU

generate employmentM = . 
replace employmentM = 1 if employment == 2 | employment == 3
replace employmentM = 0 if employment == 1
summarize employmentM

drop if education == . 
generate noeduc = 0
replace noeduc = 1 if education == 0
summarize noeduc

generate informal = 0
replace informal = 1 if education == 1
summarize informal

generate primary = 0
replace primary = 1 if education == 2 | education == 3
summarize primary

generate secondary = 0
replace secondary = 1 if  education == 4 | education == 5 
summarize secondary

generate tertiary = 0
replace tertiary = 1 if education == 6 | education == 7 | education == 8 | education == 9
summarize tertiary
