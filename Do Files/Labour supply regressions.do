cd "/Users/lenawisniewska/Desktop/Diss"
use "final data/GHSFINAL.dta", clear

duplicates report hhid

//generate blackouts_electric_owned = blackouts*electric_owned
//generate blackouts_electric = blackouts*electric_item
//generate urban_electric = urban*electric_item
//generate female_electric = female*electric_item
//generate age_electric = age*electric_item
//generate income_electric = income_1000*electric_item

drop if blackouts == .
drop if electric_item == .
drop if urban == .
drop if age == .
drop if female == .
drop if income_1000 == .
drop if dist_road2 == .
drop if temp_celsius == .
drop if precipitation == .
summarize owned

save "final data/GHSFINAL.dta", replace
use "final data/GHSFINAL.dta", clear

label define blackout_labels 0 "Never" 1 "Yearly" 2 "Monthly" 3 "Weekly" 4 "Daily"
label values blackouts blackout_labels

label define e_labels 0 "Non-electric" 1 "Electric"
label values electric_item e_labels

//RESULTS TABLE
logit owned blackouts electric_item urban female age income_1000 dist_road2 temp_celsius precipitation i.state, vce(cluster lga)
margins, dydx(electric_item) at(urban=(0 1) female=(0 1))
//blackouts irrelevant for whether an appliance is owned -> positive but insigifnicant
//electric items significantly less likely to be owned
estimates store ghs1

logit owned c.blackouts c.blackouts#i.electric_item i.electric_item urban female age income_1000 dist_road2 temp_celsius precipitation i.state, vce(cluster lga)
margins, dydx(electric_item) at(urban=(0 1) female=(0 1))

//with logit, we cannot interpret magnitude directly from output table. interaction terms further complicate this. the sign and significance however, can be interpreted. so what this does show is that the effect of outages is SIGNIFICANTLY more NEGATIVE for electric assets
estimates store ghs2

esttab ghs1 ghs2, star(* 0.10 ** 0.05 *** 0.01)


//margin plots
//probability of an item being owned is increasing for a nonelectric item and decreasing for electric item

margins electric_item, at(blackouts = (0(1)4) female=(0) urban=(0))
marginsplot, name(plot1, replace) graphregion(color(white))
margins electric_item, at(blackouts = (0(1)4) female=(1) urban=(0))
marginsplot, name(plot2, replace) graphregion(color(white))
margins electric_item, at(blackouts = (0(1)4) female=(0) urban=(1))
marginsplot, name(plot3, replace) graphregion(color(white))
margins electric_item, at(blackouts = (0(1)4) female=(1) urban=(1))
marginsplot, name(plot4, replace) graphregion(color(white))
graph combine plot1 plot2 plot3 plot4, col(2) graphregion(color(white))


//for descriptions
margins, dydx(female) at(urban=(0 1) electric_item=(0 1))
margins, dydx(urban) at(female=(1))
margins, dydx(blackouts) at(urban=(0 1) female=(0 1) electric_item=(0 1))

//subsample
logit owned c.blackouts urban female age income_1000 dist_road2 temp_celsius precipitation i.state if electric_item == 1, vce(cluster lga)
margins, dydx(blackouts) at(urban=(0 1) female=(0 1))









use "final data/GHSFINAL.dta", clear
*******ROBUSTNESS CHECKS*******
//Ramsey RESET: functional form
gen age_sq = age*age
gen income_sq = income_1000*income_1000
gen dist_sq = dist_road2*dist_road2
gen ln_income = ln(income_1000)
gen temp_sq = temp_celsius*temp_celsius
gen prec_sq = precipitation*precipitation

logit owned c.blackouts c.blackouts#i.electric_item i.electric_item urban female age age_sq ln_income dist_road2 dist_sq temp_celsius temp_sq precipitation prec_sq i.state, vce(cluster lga)
linktest

logit owned c.blackouts c.blackouts#i.electric_item i.electric_item urban female age income_1000 dist_road2 temp_celsius precipitation i.state, vce(cluster lga)


logit owned c.blackouts c.blackouts#i.electric_item i.electric_item urban female age age_sq ln_income dist_road2 dist_sq temp_celsius precipitation i.state, vce(cluster lga)
linktest

logit owned c.blackouts i.electric_item urban female age age_sq income_1000 income_sq dist_road2 dist_sq temp_celsius precipitation i.state, vce(cluster lga)


linktest

//Variance Inflation Factor: multicollinearity
reg owned blackouts electric_item urban female age income_1000 dist_road2 temp_celsius precipitation i.state, vce(cluster lga)
vif

