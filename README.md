# garfo-quota-monitoring
A collection of code to scrape GARFO's quota monitoring pages.

readin_groundfish_from_web.R is an R script to download and parse the Sector Summary and Common Pool Summary html tables.
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Sectors/Sector_Summary_2018.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/common_pool/Common_Pool_Summary_2018.html

readin_others_from_web.R is an R script to download and parse the herring, haddock catch cap, RHS_mackerel, and RHS_herring html tables.
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/herring/qm_herring.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/HaddockBycatchReport/qm_haddock_catch_caps.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Herring_RHS/qm_herring_rhs_catch_caps.html
+ https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Mackerel_RHS/qm_mackerel_rhs_catch_caps.html

batch_download_quota_monitoring.do is a stata .do file that calls the two scripts above. It also will make some simple exploratory graphs

batchfile_scrape.sh calls that stata do file. It is useful to put that into your crontab to automate.
