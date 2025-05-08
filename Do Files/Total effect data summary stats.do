cd "/Users/lenawisniewska/Desktop/Diss"

use "final data/regressions_prepared_final.dta", clear

generate unemployed = 0
replace unemployed = 1 if employment_half == 0
summarize unemployed

generate part_time = 0
replace part_time = 1 if employment_half == 0.5
summarize part_time

generate full_time = 0
replace full_time = 1 if employment_half == 1
summarize full_time

summarize age
summarize loglight
summarize cell_PSU
summarize ln_temperature
summarize ln_tp
summarize outages_in_community_percentage
summarize outages_in_community_dummy


summarize female
generate male = 0 
replace male = 1 if female == 0
summarize male

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

generate avyrtemp_celsius = avyrtemp - 273.15
summarize avyrtemp_celsius

generate cape_precipitation = exp(loglight)
summarize cape_precipitation

generate total_precipitation = avyrprecip*12

summarize skilled

estpost summarize unemployed part_time full_time outages_in_community_percentage cape_precipitation female age noeduc informal primary secondary tertiary  urban cell_PSU avyrtemp_celsius total_precipitation skilled


* Export the summary statistics as a LaTeX table
esttab using "summary_stats_S4.tex", replace ///
    cells("mean(fmt(%9.3f)) sd(fmt(%9.3f)) min(fmt(%g)) max(fmt(%g))") ///
    label nonotes ///
    title("Summary Statistics") ///
	alignment(c c c c c)
 
