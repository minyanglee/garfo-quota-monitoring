###########################################################
###########################################################
# This R script pulls in other quota monitoring from the GARFO website.  
# It does minimal data cleaning and saves the results in .Rdata and .dta format.
# It currently pulls in herring, haddock catch cap, River Herring Shad in both herring
# 	and mackerel fisheries.
# It is mostly "list" friendly -- all you need to do is add locations of the html files.
###########################################################
###########################################################

rm(list=ls())
library(rvest)
library(plyr)
library(foreign)
library(data.table)

YOUR.PROJECT.PATH<-"/home/mlee/Documents/projects/scraper/"
YOUR.OUTPUT.PATH<-"/home/mlee/Documents/projects/scraper/daily_data_out/herring"

setwd(YOUR.PROJECT.PATH)

# For each table you want to download and store, you need to name of html file, and location on the interweb
# I had to split this up into the prefix (GARFO), folder (GARFO.FOLDER), and dataset.names (without the .html) extension. It's a little hinky.
GARFO<-c("https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/")
GARFO.FOLDER<-c("herring/","HaddockBycatchReport/","Herring_RHS/","Mackerel_RHS/")
dataset.names<-c("qm_herring","qm_haddock_catch_caps","qm_herring_rhs_catch_caps", "qm_mackerel_rhs_catch_caps")



###########################################################
# You shouldn't need to edit anything below this line.
###########################################################
tables.to.parse<-paste0(GARFO,GARFO.FOLDER,dataset.names,".html")
storage.locations<-file.path(YOUR.OUTPUT.PATH,paste0(dataset.names,".Rdata"))


#cast to lists
tables.to.parse<-as.list(tables.to.parse)
storage.locations<-as.list(storage.locations)
dataset.names<-as.list(dataset.names)


# Do these files exist? If so, then do nothing. If not, then create a null R.data frame to hold stuff.
test.exist<- function(check.these,df.names) {
z<-which(list.files() == check.these)
first_time<-length(z)<1

{if (first_time==TRUE){ 
  empty<-data.frame()
  name<-paste(df.names)
  assign(name, empty)
  save(list=name, file=check.these)
    }
  }
}
mapply(test.exist,storage.locations, dataset.names)



############################################# 
############### Define some functions. ############### 
############################################# 
# read.in.combine function reads in the GARFO quota monitoring tables, parses it, and sticks it into a data frame.


qy_pattern = '<u>Quota Year:</u> <strong>'
run_pattern = '<u>Report Run on:</u> ([^<]*) <br> <u>'



read.in.combine <- function(mytable) {
  file<-read_html(mytable)
  tables<-html_nodes(file, "table")
  
  myresults <- html_table(tables[1], fill = TRUE)[[1]]

  
  thepage = readLines(mytable)
  run_lines = grep(run_pattern,thepage,value=TRUE)
  report_date<-strsplit(run_lines,"<br>")[[1]][1]
  report_date<-trimws(gsub("<u>Report Run on:</u>","",report_date),which=c("both"))
  
  
  qy_lines = grep(qy_pattern,thepage,value=TRUE)
  quota_period<-strsplit(qy_lines,"<em>")[[1]][1]
  quota_period<-strsplit(quota_period,"<u>")[[1]][3]
  quota_period<-gsub("Quota Year:</u> <strong>","",quota_period)
  quota_period<-gsub("</strong>","",quota_period)
  quota_period<-trimws(quota_period,which=c("both"))

  myresults<-cbind(myresults,report_date, quota_period)
  myresults$report_date<-as.Date(myresults$report_date,"%Y-%m-%d")
  names(myresults)[names(myresults) == 'Quota (mt)'] <- 'Quota'
  names(myresults)[names(myresults) == 'Catch Cap'] <- 'CatchCap'
  names(myresults)[names(myresults) == 'Cumulative Catch (mt)'] <- 'CumulativeCatch'
  names(myresults)[names(myresults) == 'Percent Quota Caught'] <- 'PercentQuotaCaught'
  
  myresults
}

############################################# 
###########Actually do some stuff############ 
############################################# 
myclean<-lapply(tables.to.parse,read.in.combine)

#without unlist, mget(load(x)) puts my dataframes into a list of lists.  The unlist with recursive=false 'flattens' one level of listing
my.old.data<-unlist(lapply(storage.locations,function(x) mget(load(x))), recursive=FALSE)

# I should lapply this, but I'm sick of this.  I'm writing a loop.
# assert that myclean and my.old.data are the same length
len.clean<-length(myclean)


len.old<-length(my.old.data)
len.clean==len.old


out_data<-NULL
# dataset.names contains the desired data frame names
  # assign(paste(dataset.names[[i]]) to something?
for (i in 1:len.clean) {
  #Rbind the new and old together
  
{  if (nrow(my.old.data[[i]])==0 ) {
  temp<-myclean[[i]]
  }
  else{
  temp<-rbind(my.old.data[[i]],myclean[[i]])
  }
}
  
  #Strip out duplicates
  temp<-unique(temp)
  
  #stick it into the list, just in case
  out_data[[i]]<-temp
  # assign the values of temp to a new dataframe
  name<-paste(dataset.names[[i]])
  assign(name, temp)
  save(list=name, file=storage[[i]])
  write.dta(temp, file.path(YOUR.OUTPUT.PATH,paste0(dataset.names[[i]],".dta")))
  
  #shouldn't be necessary, but just in case
  rm(temp)
  rm(name)
}  


