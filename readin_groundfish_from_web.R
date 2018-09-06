###########################################################
###########################################################
# This R script pulls in  groundfish quota monitoring from the GARFO website.  
# It does minimal data cleaning and saves the results in .Rdata and .dta format.
# It currently pulls in only the Sector and Common Pool data. 
###########################################################
###########################################################


rm(list=ls())
library(rvest)
library(plyr)
library(foreign)
library(data.table)

YOUR.PROJECT.PATH<-"/home/mlee/Documents/projects/scraper/"
#YOUR.DATA.PATH<-"/home/mlee/Documents/projects/scraper/data_in"
YOUR.OUTPUT.PATH<-"/home/mlee/Documents/projects/scraper/daily_data_out/groundfish"


setwd(YOUR.PROJECT.PATH)

# For each table you want to download and store, you need to name of html file, and location on the interweb
# I had to split this up into the prefix (GARFO), folder (GARFO.FOLDER), and table.names (without the .html) extension. It's a little hinky.

GARFO<-c("https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/")
GARFO.FOLDER<-c("Sectors/","common_pool/" )
dataset.names<-c("Sector_Summary_2018","Common_Pool_Summary_2018")




###########################################################
# You shouldn't need to edit anything below this line.
###########################################################

tables.to.parse<-paste0(GARFO,GARFO.FOLDER,dataset.names,".html")
storage.locations<-file.path(YOUR.OUTPUT.PATH,paste0(dataset.names,".Rdata"))


#cast to lists
tables.to.parse<-as.list(tables.to.parse)
storage.locations<-as.list(storage.locations)
dataset.names<-as.list(table.names)
############################################# 
############### Define some functions. ############### 
############################################# 
# read.in.combine function reads in the GARFO quota monitoring tables, parses it, and sticks it into a data frame.
read.in.combine <- function(mytable) {
  file<-read_html(mytable)
  tables<-html_nodes(file, "table")
  
  table1 <- html_table(tables[1], fill = TRUE)
  #Table 1 contains the header.  There are 3 columns X1, X2, X3.  
    #X1 - title
    #X2 - headings
    #X3 - dates
  #Parse title
  title<-table1[[1]]$X1[1]
  
  # Parse Dates (X3)
  z<-table1[[1]]$X3[1]
  z<-unlist(strsplit(z," +"))
  report_date<-paste0(z[1], " ", z[2],",", z[3])
  data_date<-paste0(z[4], " ", z[5],",", z[6])
  quota_period<-paste0(z[7])
  
  #stack together
  header<-cbind(title,report_date, data_date, quota_period)
  
  table2 <- html_table(tables[2], fill = TRUE)
  myresults<-table2[[1]]
  colnames(myresults) <- as.character(unlist(myresults[1,]))
  myresults = myresults[-1, ]
  myresults<-cbind(myresults,header)
  myresults
}

# cleanup.GARFO.table does minimal cleanup. converts strings to dates. removes **s from the sub-acl field. 
cleanup.GARFO.table <- function(indirty) {
  # myt <- as.data.frame(data.table::rbindlist(indirty))
  myt <- as.data.frame(indirty)
  myt$report_date<-as.Date(myt$report_date,"%B %d,%Y")
  myt$data_date<-as.Date(myt$data_date,"%B %d,%Y")
  names(myt)[names(myt) == 'Sub-ACL** (mt)'] <- 'SubACL'
  names(myt)[names(myt) == 'Sub-ACL (mt)'] <- 'SubACL'
  names(myt)[names(myt) == 'Cumulative Kept (mt)'] <- 'CumulativeKept'
  names(myt)[names(myt) == 'Cumulative Discard (mt)'] <- 'CumulativeDiscard'
  names(myt)[names(myt) == 'Cumulative Catch (mt)'] <- 'CumulativeCatch'
  names(myt)[names(myt) == 'Percent Caught'] <- 'PercentCaught'
  
  myt
}

############################################# 
###########Actually do some stuff############ 
############################################# 
myresults<-lapply(tables.to.parse,read.in.combine)
myclean<-lapply(myresults,cleanup.GARFO.table)

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
  temp<-rbind(my.old.data[[i]],myclean[[i]])
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


