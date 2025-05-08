cd "/Users/lenawisniewska/Desktop/Diss"

use "final data/merged_data23.03.dta", clear

//countries
keep if inlist(country, ///
    3, 4, 6, 7, 8, 10, 11, 12, 14, 15, ///
    16, 17, 18, 19, 21, 22, 23, 24, 26, 27, ///
    28, 30, 35, 36, 37)

//employment: change to 0/1 binary where both full and part time count as 1
rename employment employment_raw
generate employment = . 
replace employment = 1 if employment_raw == 2 | employment_raw == 3 //full time and part time counts
replace employment = 0 if employment_raw == 1

//employment: change to 0/1 binary where only full time counts as 1
generate employment_alternative = . 
replace employment_alternative = 1 if employment_raw == 3
replace employment_alternative = 0 if employment_raw == 1 | employment_raw == 2

//employment: change to 0/0.5/1
generate employment_half = . 
replace employment_half = 1 if employment_raw == 3
replace employment_half = 0.5 if employment_raw == 2 
replace employment_half = 0 if employment_raw == 1

//education: change to 4 categories
generate educationM = . 
replace educationM = 0 if education == 0
replace educationM = 1 if education == 1 //informal
replace educationM = 2 if education == 2 | education == 3 //primary
replace educationM = 3 if  education == 4 | education == 5 //secondary
replace educationM = 4 if education == 6 | education == 7 | education == 8 | education == 9 //tertiary
drop if education == .
count

//making all regressions the same
drop if age == .
drop if female == .
drop if cell_PSU == .
drop if outages_in_community_dummy == . //this means excluding people in communities where no one has access
drop if outages_in_community_percentage == .
drop if employment == .
count // 34,352

save "final data/regressions_35k_final.dta", replace

use "final data/regressions_35k_final.dta", clear
drop if round == "7"
collapse (mean) connected, by(country)
sort connected
list

********************
*    PREPARATION   *
********************
use "final data/regressions_35k_final.dta", clear

generate high_electrification = . //take top 15
replace high_electrification = 1 if inlist(country, 19, 28, 24, 7, 10, 6, 11, 8, 18, 26, 36, 22, 3, 30, 14)
replace high_electrification = 0 if inlist(country, 16, 12, 21, 4, 35, 27, 15, 23, 17)

rename outages_in_community_percentage outages_in_community_per
winsor2 employment_raw employment employment_alternative employment_half female age agesq loglight outages_in_community_per outages_in_community_dummy cell_PSU ln_temperature ln_tp high_electrification, by(year country)
drop high_electrification
rename high_electrification_w high_electrification
drop employment
rename employment_w employment
drop employment_alternative
rename employment_alternative_w employment_alternative
drop employment_raw
rename employment_raw_w employment_raw
drop employment_half
rename employment_half_w employment_half
drop female
rename female_w female
drop age
rename age_w age
drop agesq
rename agesq_w agesq
drop loglight
rename loglight_w loglight
drop outages_in_community_per
rename outages_in_community_per_w outages_in_community_percentage
drop outages_in_community_dummy
rename outages_in_community_dummy_w outages_in_community_dummy
drop cell_PSU
rename cell_PSU_w cell_PSU
drop ln_temperature
rename ln_temperature_w ln_temperature
drop ln_tp
rename ln_tp_w ln_tp

generate outages_dum_female = outages_in_community_dummy * female
generate outages_per_female = outages_in_community_per * female
generate loglight_female = loglight * female
generate age_female = age * female
generate agesq_female = agesq * female
generate cell_female = cell_PSU * female
generate ln_temperature_female = ln_temperature * female
generate ln_tp_female = ln_tp * female

tabulate occupation
gen skilled = .
replace skilled = 0 if inlist(occupation, 2, 3, 4, 5, 6)
replace skilled = 1 if inlist(occupation, 7, 8, 9, 10, 11, 12)
gen skillsample = . 
replace skillsample = 1 if skilled == 1 | skilled == 0
gen agri = .
replace agri = 0 if inlist(occupation, 2, 7, 8, 9, 10, 11, 12, 4, 5, 6)
replace agri = 1 if inlist(occupation, 3)

tabulate urbrur
gen urban = .
replace urban = 1 if urbrur == 1
replace urban = 0 if urbrur == 2

replace electricity_house = . if electricity_house == 0
generate outages_house = 6 - electricity_house
tabulate outages_house

tabulate age
drop if location_num == .

save "final data/regressions_prepared_final.dta", replace
