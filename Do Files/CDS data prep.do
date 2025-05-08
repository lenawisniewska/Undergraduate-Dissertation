cd "/Users/lenawisniewska/Desktop/Diss"

//finding year averages for temperature
use "raw data/2_metre_temperature.dta", clear
rename _2_metre_temperature temperature
generate str_longitude = string(longitude)
generate str_latitude = string(latitude)
generate longitude_latitude = str_longitude + "," + str_latitude
collapse (mean) avyrtemp = temperature, by(longitude_latitude year)
save "intermediate data/average_temperature_by_id_year.dta", replace

use "intermediate data/average_temperature_by_id_year.dta", clear
split longitude_latitude, parse(,) gen(part)
rename part1 longitude
rename part2 latitude
destring longitude, replace
destring latitude, replace
generate str_year = string(year)
generate id = longitude_latitude + "," + str_year
save "intermediate data/temperatureFINAL.dta", replace


//same for total precipitation
use "raw data/total_precipitation.dta", clear
rename Total_precipitation totalprecipitation
generate str_longitude = string(longitude)
generate str_latitude = string(latitude)
generate longitude_latitude = str_longitude + "," + str_latitude
collapse (mean) avyrprecip = totalprecipitation, by(longitude_latitude year)
save "intermediate data/average_totalprecipitation_by_id_year.dta", replace

use "intermediate data/average_totalprecipitation_by_id_year.dta", clear
split longitude_latitude, parse(,) gen(part)
rename part1 longitude
rename part2 latitude
destring longitude, replace
destring latitude, replace
generate str_year = string(year)
generate id = longitude_latitude + "," + str_year
save "intermediate data/totalprecipitationFINAL.dta", replace

//same for CAPE
use "raw data/convective_available_potential_energy.dta", clear
rename Convective_available_potential_e CAPE
generate str_longitude = string(longitude)
generate str_latitude = string(latitude)
generate longitude_latitude = str_longitude + "," + str_latitude
collapse (mean) avyrCAPE = CAPE, by(longitude_latitude year)
save "intermediate data/average_CAPE_by_id_year.dta", replace

use "intermediate data/average_CAPE_by_id_year.dta", clear
split longitude_latitude, parse(,) gen(part)
rename part1 longitude
rename part2 latitude
destring longitude, replace
destring latitude, replace
generate str_year = string(year)
generate id = longitude_latitude + "," + str_year
save "intermediate data/CAPEFINAL.dta", replace

//now CAPE_p - need to first merge while they're still monthly, multiply, and only then average
use "raw data/convective_available_potential_energy.dta", clear
rename Convective_available_potential_e CAPE
generate str_longitude = string(longitude)
generate str_latitude = string(latitude)
generate str_year = string(year)
generate str_month = string(month)
generate id = str_longitude + "," + str_latitude + "," + str_year + "," + str_month
save "intermediate data/CAPEforPmerge.dta", replace

use "raw data/mean_total_precipitation_rate.dta", clear
rename Mean_total_precipitation_rate precipitationrate
generate str_longitude = string(longitude)
generate str_latitude = string(latitude)
generate str_year = string(year)
generate str_month = string(month)
generate id = str_longitude + "," + str_latitude + "," + str_year + "," + str_month
summarize precipitationrate
generate precipitationrate1 = precipitationrate*3600
summarize precipitationrate1
save "intermediate data/PforCAPEmerge.dta", replace

use "intermediate data/CAPEforPmerge.dta", clear
sort id
merge 1:1 id using "intermediate data/PforCAPEmerge.dta", force    
drop _merge
save "intermediate data/CAPE_Pmonthly.dta", replace

use "intermediate data/CAPE_Pmonthly.dta", clear
generate light_month_rate = 3600*CAPE*precipitationrate
generate longitude_latitude = str_longitude + "," + str_latitude
collapse (mean) light_year_rate  = light_month_rate, by(longitude_latitude year)
generate loglight_rate = ln(light_year_rate)
generate str_year = string(year)
generate id = longitude_latitude + "," + str_year
save "intermediate data/loglightFINAL.dta", replace

//mergining the 3
use "intermediate data/temperatureFINAL.dta", clear
local files "totalprecipitationFINAL.dta loglightFINAL.dta CAPEFINAL.dta"
foreach file in `files' {
    merge 1:1 id using "/Users/lenawisniewska/Desktop/Diss/intermediate data/`file'", force    
     drop _merge
}

gen ln_temperature = ln(avyrtemp)
gen ln_tp = ln(avyrprecip)
summarize avyrtemp
rename loglight_rate loglight
keep year longitude latitude ln_temperature ln_tp loglight light_year_rate avyrtemp avyrprecip avyrCAPE
save "/Users/lenawisniewska/Desktop/Diss/intermediate data/CDSfinal.dta", replace

use "intermediate data/CDSfinal.dta", clear

//check
list if longitude == 8.5 & latitude == 12.5 & year == 2014
