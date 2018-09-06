/* This do file:
	A. Calls an R file to pull in groundfish quota monitoring from the internet
	B. Calls an R file to pull in other quota monitoring from the internet 
	C. Does some graphing.
	D. Sticks the stata dataset and Rdata file onto my shared drive.
*/


clear
global wd "/home/mlee/Documents/projects/scraper/graphs_out"

/* the do file hidden info contains a single global macro "my_network" gives access to my network drive on home2*/

do "/home/mlee/Documents/projects/scraper/code/hidden_info.do"
cd "$wd"
display "$S_TIME $S_DATE"
global Rterm_options `"--vanilla"'
global Rterm_path `"/usr/bin/R"'


rsource using "/home/mlee/Documents/projects/scraper/code/readin_groundfish_from_web.R"
clear
rsource using "/home/mlee/Documents/projects/scraper/code/readin_others_from_web.R"

global grounddir "/home/mlee/Documents/projects/scraper/daily_data_out/groundfish"
global otherdir "/home/mlee/Documents/projects/scraper/daily_data_out/other"

local mygrounddtas: dir "$grounddir" files "*.dta"
local groundshorty: subinstr local mygrounddtas ".dta" "", all



/* Graphing for groundfish */
foreach file of local groundshorty{
	use "$grounddir/`file'.dta", clear
	format report_date data_date %td
	
	foreach var of varlist CumulativeKept CumulativeDiscard CumulativeCatch SubACL PercentCaught{
	egen c`var'=sieve(`var'), char(0123456789.)
	drop `var'
	rename c`var' `var'
	destring `var', replace
	}

	egen cstock=sieve(Stock), omit("/")
	encode cstock, gen(mystock)
	drop cstock
	xtset mystock data_date
	xtline Percent
	graph export "`file'_pct.eps", as(eps) replace 


}
local otherdta: dir "$otherdir" files "*.dta"
local othershorty: subinstr local otherdta ".dta" "", all
/* Graphing for herring */
foreach file of local othershorty{
	use "$otherdir/`file'.dta", clear
	format report_date  %td

	/* Rename the first variable "Stock" */
	qui desc, varlist
	local myf: word 1 of `r(varlist)'
	rename `myf' Stock
	egen cstock=sieve(Stock), omit("/")
	encode cstock, gen(mystock)
	drop cstock
	xtset mystock report_date
	
	foreach var of varlist Percent{
	egen c`var'=sieve(`var'), char(0123456789.)
	drop `var'
	rename c`var' `var'
	destring `var', replace
	}

	xtset mystock report_date
	xtline Percent
	graph export "`file'_pct.eps", as(eps) replace 

}
/* copy the pictures to my shared drive */
! cp *.eps "$my_network/quota_monitoring/graphs"
/* copy the data to my shared drive */

cd "/home/mlee/Documents/projects/scraper/daily_data_out"
! cp  -R * "$my_network/quota_monitoring/data"

