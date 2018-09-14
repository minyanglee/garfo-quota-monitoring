###########################################################
###########################################################
# This R script pulls in  groundfish quota monitoring from the GARFO website.  
# It does minimal data cleaning and saves the results in .Rdata and .dta format.
# It currently pulls in only the Sector and Common Pool data. 
# Common pool is going to be a pain because there are trimester TACs for some stocks. For the trimester stocks, catch can be rolled forward/back. So there may be extra columns.
# and whole-year TACs for others.
###########################################################
###########################################################


rm(list=ls())
library(rvest)
library(plyr)
library(foreign)
library(data.table)

YOUR.PROJECT.PATH<-"/home/mlee/Documents/projects/scraper/"
YOUR.OUTPUT.PATH<-"/home/mlee/Documents/projects/scraper/daily_data_out/groundfish"


setwd(YOUR.PROJECT.PATH)

# For each table you want to download and store, you need to name of html file, and location on the interweb
# I had to split this up into the prefix (GARFO), folder (GARFO.FOLDER), and table.names (without the .html) extension. It's a little hinky.

GARFO<-c("https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/")
GARFO.FOLDER<-c("common_pool/" )
dataset.names<-c("Common_Pool_Summary_2018")

dataset.names.ext<-paste0(dataset.names,".Rdata")


###########################################################
# You shouldn't need to edit anything below this line.
###########################################################

tables.to.parse<-paste0(GARFO,GARFO.FOLDER,dataset.names,".html")
storage.locations<-file.path(YOUR.OUTPUT.PATH,dataset.names.ext)


#cast to lists
tables.to.parse<-as.list(tables.to.parse)
storage.locations<-as.list(storage.locations)
dataset.names<-as.list(dataset.names)
dataset.names.ext<-as.list(dataset.names.ext)


# Do these files exist? If so, then do nothing. If not, then create a null R.data frame to hold stuff.
test.exist<- function(check.these,df.names) {
z<-which(list.files(YOUR.OUTPUT.PATH) == df.names)
first_time<-length(z)<1

{if (first_time==TRUE){ 
  empty<-data.frame()
  name<-paste(df.names)
  assign(name, empty)
  save(list=name, file=check.these)
    }
  }
}
mapply(test.exist,storage.locations, dataset.names.ext)


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
  
  
  #This will pull out the 2nd table. Will break if there isn't a second table.
  #The fix: if the header doesn't look like "the full year table" don't do anything else.
  
  table3 <- html_table(tables[3], fill = TRUE)
  #Table 1 contains the header.  There are 3 columns X1, X2, X3.  
  #X1 - title
  #X2 - headings
  #X3 - dates
  #Parse title
  title<-table3[[1]]$X1[1]
  
  #Check if the word "Common Pool" and "Full Year" are in the title.  
  cp.check<-grepl("Common Pool", title, ignore.case = TRUE, useBytes = FALSE)
  full.year.check<-grepl("Full Year", title, ignore.case = TRUE, useBytes = FALSE)
  
  if (cp.check==TRUE && full.year.check==TRUE){
  # Parse Dates (X3)
  z<-table3[[1]]$X3[1]
  z<-unlist(strsplit(z," +"))
  report_date<-paste0(z[1], " ", z[2],",", z[3])
  data_date<-paste0(z[4], " ", z[5],",", z[6])
  quota_period<-paste0(z[7])
  
  
  
  #stack together the header
  header4<-cbind(title,report_date, data_date, quota_period)
  
  table4 <- html_table(tables[4], fill = TRUE)
  myresults4<-table4[[1]]
  colnames(myresults4) <- as.character(unlist(myresults4[1,]))
  myresults4 = myresults4[-1, ]
  #add the header data into the dataset
  myresults4<-cbind(myresults4,header4)
  #and stack
  
  
  myresults<-rbind(myresults, myresults4)
  }
  #This is the end of the part that will pull out the 2nd table. It will break if there isn't a second table.
  
  
  
  myresults$report_date<-as.Date(myresults$report_date,"%B %d,%Y")
  myresults$data_date<-as.Date(myresults$data_date,"%B %d,%Y")


  names(myresults)<-tolower(gsub("[^[:alnum:]]","",names(myresults)))
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
  save(list=name, file=storage.locations[[i]])
  write.dta(temp, file.path(YOUR.OUTPUT.PATH,paste0(dataset.names[[i]],".dta")))
  
  #shouldn't be necessary, but just in case
  rm(temp)
  rm(name)
}  

