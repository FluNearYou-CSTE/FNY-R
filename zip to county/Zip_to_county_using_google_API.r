library(RCurl)
library(RJSONIO)



### this function creates the url with the address to be passed on to google for geocoding
construct.geocode.url <- function(address, return.call = "json", sensor = "false") {
  root <- "http://maps.google.com/maps/api/geocode/"
  u <- paste(root, return.call, "?address=", address, "&sensor=", sensor, sep = "")
  return(URLencode(u))
}

### this function collects lat/long data from google
gGeoCode <- function(address,verbose=FALSE) {
  if(verbose) cat(address,"\n")
  u <- construct.geocode.url(address)
  doc <- getURL(u)
  x <- fromJSON(doc,simplify = FALSE)
  if(x$status=="OK") {
    county <- x$results[[1]]$address_components[[3]]$short_name
    return(c(county))
  } else {
    return(c("NA"))
  }
}
