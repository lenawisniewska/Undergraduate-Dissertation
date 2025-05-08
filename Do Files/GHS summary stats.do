cd "/Users/lenawisniewska/Desktop/Diss"
use "final data/GHSpremeeting.dta", clear

drop if age > 105

//precipitation is Annual Precipitation (mm) -> don't say over what area
//dist_road2 is HH Distance in (KMs) to Nearest Major Road

gen blackouts_never = .
replace blackouts_never = 0 if outages == 1 | outages == 2 | outages == 3 | outages == 4
replace blackouts_never = 1 if outages == 0

gen blackouts_yearly = .
replace blackouts_yearly = 0 if outages == 0 | outages == 2 | outages == 3 | outages == 4
replace blackouts_yearly = 1 if outages == 1

gen blackouts_monthly = .
replace blackouts_monthly = 0 if outages == 0 | outages == 1 | outages == 3 | outages == 4
replace blackouts_monthly = 1 if outages == 2

gen blackouts_weekly = .
replace blackouts_weekly = 0 if outages == 0 | outages == 1 | outages == 2 | outages == 4
replace blackouts_weekly = 1 if outages == 3

gen blackouts_daily = .
replace blackouts_daily = 0 if outages == 0 | outages == 1 | outages == 2 | outages == 3
replace blackouts_daily = 1 if outages == 4

estpost summarize total_electric total_nonelectric blackouts_never blackouts_yearly blackouts_monthly blackouts_weekly blackouts_daily urban female age income_1000 dist_road2 temp_celsius precipitation

* Export the summary statistics as a LaTeX table
esttab using "summary_stats_S5.tex", replace ///
    cells("count(fmt(%9.3f)) mean(fmt(%9.3f)) sd(fmt(%9.3f)) min(fmt(%g)) max(fmt(%g))") ///
    label nonotes ///
    title("Summary Statistics") ///
	alignment(c c c c c)

	
