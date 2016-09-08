#! /usr/bin/env Rscript

################
## ZIP -> County, assign zip to
################

library(readr)
library(tidyr)
library(dplyr)
library(RCurl)
library(xlsx)
library(httr)
library(data.table)

## https://www.census.gov/geo/reference/codes/cou.html
state_county_fips <- getURL("http://www2.census.gov/geo/docs/reference/codes/files/national_county.txt")
state.county.fips <- data.table(read.csv(textConnection(state_county_fips),header=FALSE))
#state.county.fips <- data.table(read.csv('./national_county.csv'))
## headers dropped for unknown reason, assign
colnames(state.county.fips) <- c("STATE","STATEFP","COUNTYFP","COUNTYNAME","CLASSFP")

## https://www.google.com/url?q=http://www2.census.gov/geo/pdfs/maps-data/data/rel/explanation_zcta_county_rel_10.pdf
# zpoppct - percent of zcta in given county (GEOID)
ZC_to_county_TXT <- getURL("http://www2.census.gov/geo/docs/maps-data/data/rel/zcta_county_rel_10.txt")
zcta.county.pop <- data.table(read.csv(textConnection(ZC_to_county_TXT),header=TRUE))
#zcta.to.county <- data.table(read.csv('./zcta_county_rel_10.csv'))
# rename to merge
zcta.county.pop <- zcta.county.pop[,list(ZCTA=ZCTA5,STATEFP=STATE,COUNTYFP=COUNTY,ZPOPPCT,ZPOP)]

## for each ztca, identify with county with highest population
zcta.county.pop <- zcta.county.pop[order(ZCTA,-ZPOPPCT)]
zcta.county.pop <- zcta.county.pop[,
                                   list(STATEFP=head(STATEFP,1),
                                        COUNTYFP=head(COUNTYFP,1),
                                        ZPOP = head(ZPOP,1),
                                        ZPOPPCT=head(ZPOPPCT,1)),
                                         by=ZCTA]

## get zip -> zcta mapping
#zip_to_zcta <- getURL("http://udsmapper.org/docs/zip_to_zcta_2016.xlsx")

fileUrl <-"http://udsmapper.org/docs/zip_to_zcta_2016.xlsx"
download.file(fileUrl, destfile="./zip_to_zcta_tmp.xlsx", method="curl")

zip.to.zcta <- data.table(read.xlsx2("./zip_to_zcta_tmp.xlsx",
                                     sheetIndex=1, header=T,
                                     colClasses="character"))

zip.to.zcta <- zip.to.zcta[ZIPType=="ZIP Code Area",
                           list(ZCTA = as.integer(as.character(ZCTA_USE)),ZIP=as.character(ZIP))]


zcta.county.pop <- merge(zip.to.zcta,zcta.county.pop,by="ZCTA",all.x=TRUE)


zip.to.county <- merge(zcta.county.pop,state.county.fips,by=c("STATEFP","COUNTYFP"))

zip.to.county[,`:=`(CLASSFP=NULL,ZPOPPCT=NULL,ZPOP=NULL)]

zip.to.county[,`:=`(STATE = as.character(STATE),COUNTYNAME=as.character(COUNTYNAME))]


write.csv(zip.to.county,"./zip_to_county.csv",row.names=FALSE)
