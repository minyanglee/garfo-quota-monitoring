# garfo-quota-monitoring
A collection of code to scrape GARFO's quota monitoring pages. GARFO does quota monitoring updates every week, but the old versions are not updated on the internet.  This collection of code parses the GARFO quota monitoring tables and stores the data contained in those tables.  The construction (column headings in particular) of the tables varies slightly by FMP, so slightly different code is requires for many of these.

# R scripts
Both of the R scripts should run with very minor changes to directories

readin_groundfish_from_web.R is an R script to download and parse the Sector Summary and Common Pool Summary html tables.
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Sectors/Sector_Summary_2018.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/common_pool/Common_Pool_Summary_2018.html

readin_others_from_web.R is an R script to download and parse the herring, haddock catch cap, RHS_mackerel, and RHS_herring html tables.
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/herring/qm_herring.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/HaddockBycatchReport/qm_haddock_catch_caps.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Herring_RHS/qm_herring_rhs_catch_caps.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Mackerel_RHS/qm_mackerel_rhs_catch_caps.html

# Stata Wrapper
batch_download_quota_monitoring.do is a stata .do file that calls the scripts above. It makes some simple exploratory graphs and copies data and graphs to a shared drive where people can see it.  You'll need stata to run this file.  
