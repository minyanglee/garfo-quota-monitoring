###########################################################
###########################################################
# This R script pulls in other quota monitoring from the GARFO website.  
# It does minimal data cleaning and saves the results in .Rdata and .dta format.
# Im testing how to 
# It is mostly "list" friendly -- all you need to do is add locations of the html files.
###########################################################
###########################################################

rm(list=ls())
library(rvest)
library(plyr)
library(foreign)
library(data.table)
library(RCurl)
options(stringsAsFactors = FALSE)
YOUR.PROJECT.PATH<-"/home/mlee/Documents/projects/scraper/"
YOUR.OUTPUT.PATH<-"/home/mlee/Documents/projects/scraper/daily_data_out/mid"

setwd(YOUR.PROJECT.PATH)

# For each table you want to download and store, you need to name of html file, and location on the interweb
# I had to split this up into the prefix (GARFO), folder (GARFO.FOLDER), and dataset.names (without the .html) extension. It's a little hinky.
# https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Quota_Monitoring/2018/20180908/blue20180908.html


today<-20180908

#today<-format(Sys.Date(), format="%Y%m%d")
year<-format(Sys.Date(), format="%Y")
dataset.names<-c("blue","bsb","scup", "dog","fluke")

GARFO<-file.path("https://www.greateratlantic.fisheries.noaa.gov/ro/fso/reports/Quota_Monitoring",year)


###########################################################
# You shouldn't need to edit anything below this line.
###########################################################

html.filenames<-paste0(dataset.names,today,".html")
dataset.names.ext<-paste0(dataset.names,".Rdata")
tables.to.parse<-paste0(GARFO,today,"/",html.filenames)
storage.locations<-file.path(YOUR.OUTPUT.PATH,dataset.names.ext)

js.to.parse<-gsub(".html",".js",tables.to.parse)

#cast to lists0
#tables.to.parse<-as.list(tables.to.parse)
storage.locations<-as.list(storage.locations)

dataset.names.ext<-as.list(dataset.names.ext)
#js.to.parse<-as.list(js.to.parse)


dataset.names.ext<-as.list(dataset.names.ext)
dataset.names.full<-file.path(YOUR.OUTPUT.PATH,dataset.names.ext)
#This is a small function that helps parse the tables


zz<-length(dataset.names.full)

for (ii in 1:zz) {
  
if (!file.exists(dataset.names.full[ii])) {
    #do stuff 
    empty<-data.frame()
    name<-paste(dataset.names[ii])
    assign(name, empty)
    save(list=name, file=dataset.names.full[ii])
  }
  
}


storage.locations<-unlist(storage.locations)
dataset.names<-unlist(dataset.names)

############################################# 
############### Define some functions. ############### 
############################################# 
# read.in.chunks function reads in each of the lines of a table, parses it, and sticks it into a data frame.

# Construct the pattern matching. This was done by inspeting source.
states=c("ME","NH", "MA", "RI", "CT", "NY", "NJ", "DE", "MD","VA", "NC", "SC", "GA", "FL") 
z<-".html([^<]*)"
pattern.grab=paste0(z,states)
pattern.grab=as.list(pattern.grab)



#This is a small function that helps parse the tables
read.in.chunks<-function(patts){
  working_lines <- grep(patts,working_table,value=FALSE)
  if (length(working_lines>=1)) {
  start<-working_lines
  stop<-start+8
  grabbed<-working_table[start:stop]
  grabbed<-trimws(gsub("<td class=\"r data\">", "",grabbed),which=c("both"))
  grabbed<-trimws(gsub("</td>", "",grabbed),which=c("both"))
  grabbed<-trimws(gsub("</a>", "",grabbed),which=c("both"))
  grabbed<-trimws(gsub(",", "",grabbed),which=c("both"))
  grabbed<-trimws(gsub("<td class=\\\"l data\\\"><a href=\\\"", "",grabbed),which=c("both"))
  grabbed<-trimws(gsub(".+html\\\">", "",grabbed),which=c("both"))
  # grabbed<-trimws(gsub("l[.]+html", "",grabbed),which=c("both"))
  grabbed<-grabbed[!grabbed %in% ""]
  grabbed
  }
}




 #load in old data
 my.old.data<-unlist(lapply(as.list(storage.locations),function(x) mget(load(x))), recursive=FALSE)
 storage.locations<-unlist(storage.locations)

 #Start the function here 

tables.to.parse<-unlist(tables.to.parse)
zz<-length(tables.to.parse)



for (i in 1:zz) {
  if (url.exists(tables.to.parse[i])==FALSE){
    print("does not exist")
  } else{
   
  working_table <- readLines(tables.to.parse[i])
  parsed.data<-lapply(pattern.grab,read.in.chunks)
  parsed.data<-do.call(rbind.data.frame, parsed.data)
  
  
  table.head.start <- grep("<thead>",working_table,value=FALSE)
  table.head.end <- grep("</thead>",working_table,value=FALSE)
  
  table.heading<-working_table[table.head.start:table.head.end]
  table.heading<-table.heading[8:15]
  table.heading<-trimws(gsub("<th class=\"c header\" scope=\"col\">", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("</th>", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("</br>", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("<br>", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("<br/>", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("&#39;", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("</tr>", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("</thread>", "",table.heading),which=c("both"))
  
  table.heading<-trimws(gsub("\\(", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("\\)", "",table.heading),which=c("both"))
  
  table.heading<-trimws(gsub("\\(%\\)", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("\\-", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("%", "",table.heading),which=c("both"))
  table.heading<-trimws(gsub("Pounds", "",table.heading),which=c("both"))
  # apply the table names to the dataframe
  colnames(parsed.data) <- table.heading
  
  
  js.working<-gsub(".html",".js",tables.to.parse[i])
  working.header<- readLines(js.working)
  
  working.header<-working.header[6:16]
  working.header<-paste(working.header,sep=" ", collapse="")
  
  
  
  working.header<-trimws(gsub("\\+" ,"" ,working.header), which=c("both"))
  working.header<-trimws(gsub("\\\"" ,"" ,working.header), which=c("both"))
  working.header<-gsub("\\s", "",working.header)
  
  #working.header<-trimws(gsub("\\\","" ,working.header),which=c("both"))

  
  
  
  working.header<-unlist(strsplit(working.header,"PeriodDates:"))[2]
  working.header<-unlist(strsplit(working.header,"<BR>"))
  
  
  working.header<-trimws(gsub(".+black>","" ,working.header), which=c("both"))
  dates<-trimws(gsub("</font.+</TABLE>", "",working.header))
  
  parsed.data<-cbind(parsed.data,tables.to.parse[i],dates[1], dates[2], dates[3], dates[4])
  table.heading<- c(table.heading,"source","datadate","reportdate","quotaperiod","quotaperioddates")
  colnames(parsed.data) <- table.heading
  
   
   temp<-rbind(my.old.data[[i]],parsed.data)

   #Strip out duplicates
   temp<-unique(temp)
   
   # assign the values of temp to a new dataframe
   name<-paste(dataset.names[i])
   assign(name, temp)
   save(list=name, file=storage.locations[i])
   write.dta(temp, file.path(YOUR.OUTPUT.PATH,paste0(dataset.names[i],".dta")))
  # 
  #shouldn't be necessary, but just in case
  #rm(temp)
  #rm(name)
  }
  }



