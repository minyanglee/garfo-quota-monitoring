/* This do file:
	A. Calls an R file to pull in groundfish quota monitoring from the internet
	B. Calls an R file to pull in other quota monitoring from the internet 
	C. Does some graphing.
	D. Sticks the stata dataset and Rdata file onto my shared drive.
	
You have added this to your crontab with
44 10 * * * /dir/to/stata/install/stata -b do '"/dir/to/code/folder/batch_download_quota_monitoring.do"' >> /tmp/cronlog.txt 2>&1

I'm graphing trimester level common pool stuff. but you could do other things, the data is all there
*/


clear
global wd "/home/mlee/Documents/projects/scraper/graphs_out"

/* the do file hidden_info contains a single global macro "my_network" gives access to my network drive on home2*/

do "/home/mlee/Documents/projects/scraper/code/hidden_info.do"
cd "$wd"
display "$S_TIME $S_DATE"
global Rterm_options `"--vanilla"'
global Rterm_path `"/usr/bin/R"'


rsource using "/home/mlee/Documents/projects/scraper/code/readin_sectors_from_web.R"
clear
rsource using "/home/mlee/Documents/projects/scraper/code/readin_commonpool_from_web.R"
clear
rsource using "/home/mlee/Documents/projects/scraper/code/readin_others_from_web.R"

global grounddir "/home/mlee/Documents/projects/scraper/daily_data_out/groundfish"
global otherdir "/home/mlee/Documents/projects/scraper/daily_data_out/other"

local mygrounddtas: dir "$grounddir" files "*.dta"
local groundshorty: subinstr local mygrounddtas ".dta" "", all



/* Graphing for groundfish */
foreach file of local groundshorty{
	use "$grounddir/`file'.dta", clear
	format reportdate datadate %td
	decode title, gen(mytitle)
	replace mytitle=ltrim(rtrim(itrim(mytitle)))
	drop if strmatch(mytitle,"Summary Table Common Pool Full Year*")
	foreach var of varlist cumulativekept cumulativediscard cumulativecatch subacl percentcaught{
	egen c`var'=sieve(`var'), char(0123456789.)
	drop `var'
	rename c`var' `var'
	destring `var', replace
	}

	egen cstock=sieve(stock), omit("/")
	encode cstock, gen(mystock)
	drop cstock
	xtset mystock datadate
	xtline percent
	graph export "`file'_pct.eps", as(eps) replace 


}
local otherdta: dir "$otherdir" files "*.dta"
local othershorty: subinstr local otherdta ".dta" "", all
/* Graphing for herring */
foreach file of local othershorty{
	use "$otherdir/`file'.dta", clear
	format reportdate  %td

	/* Rename the first variable "Stock" */
	qui desc, varlist
	local myf: word 1 of `r(varlist)'
	rename `myf' stock
	egen cstock=sieve(stock), omit("/")
	encode cstock, gen(mystock)
	drop cstock
	xtset mystock reportdate
	
	foreach var of varlist percent{
	egen c`var'=sieve(`var'), char(0123456789.)
	drop `var'
	rename c`var' `var'
	destring `var', replace
	}

	xtset mystock reportdate
	xtline percent
	graph export "`file'_pct.eps", as(eps) replace 

}
/* copy the pictures to my shared drive */
! cp *.eps "$my_network/quota_monitoring/graphs"
/* copy the data to my shared drive */

cd "/home/mlee/Documents/projects/scraper/daily_data_out"
! cp  -R * "$my_network/quota_monitoring/data"

