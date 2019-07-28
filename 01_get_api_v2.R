# Libraries ----
library(dplyr)
library(httr)
library(rjson)
library(lubridate)
library(reshape2)
library(purrr)
library(rlist)

# API v2 config ----
apikey <- readLines("/home/jbontruk/BitBucket/smart_price/auth/apikey.txt")
apitoken <- readLines("/home/jbontruk/BitBucket/smart_price/auth/apitoken.txt")
p_url <- 'https://prisync.com/api/v2/'
logs <- '/home/jbontruk/BitBucket/smart_price/logs/logs_01_get_api_v2.txt'

# Get products ----
t1 <- Sys.time()
write(paste0('Script start: ', t1, '\n'), file = logs, append = T)
for (i in 1:1000) {
  if(i == 1){ 
    j = 0
    get <- httr::GET(paste0(p_url, 'list/product/startFrom/0'),
                     add_headers("apikey" = apikey, "apitoken" = apitoken))
    t <- fromJSON(content(get, type="text"))
    products <- t$results
    nextURL <- t$nextURL
  }
  else{
    if(!is.null(nextURL)){
      j = j + 100
      get <- httr::GET(paste0(p_url, 'list/product/startFrom/', j),
                       add_headers("apikey" = apikey, "apitoken" = apitoken))
      t <- fromJSON(content(get, type="text"))
      products <- c(products, t$results)
      nextURL <- t$nextURL
      message(paste0('Products downloaded: ', length(products), ' Status code: ', get$status_code))
    }
  }
}

write(paste0('Products downloaded: ', length(products), ' with last status code: ', get$status_code),
      file = logs, append = T)
setwd('/home/jbontruk/BitBucket/smart_price/rds')
saveRDS(products, file = paste0('products_', 
                                year(get$date), '_',
                                month(get$date), '_',
                                day(get$date), '_',
                                hour(get$date), '_',
                                minute(get$date), '_',
                                second(get$date), '_',
                                '.RDS'))

products_ids <- sapply(products, '[[', 1)
length(products_ids) == length(unique(products_ids))
products_ids <- unique(products_ids)

# Get products details ----
t2 <- Sys.time()
products_details <- list()
j <- 1
for (i in products_ids) {
  get <- httr::GET(paste0(p_url, 'get/product/id/', i),
                   add_headers("apikey" = apikey, "apitoken" = apitoken))
  t <- fromJSON(content(get, type="text"))
  products_details[[j]] <- t
  j = j+1
  message(paste0('Products details downloaded: ', j-1, ' Status code: ', get$status_code))
}

write(paste0('Products details downloaded: ', j-1, ' with last status code: ', get$status_code),
      file = logs, append = T)
setwd('/home/jbontruk/BitBucket/smart_price/rds')
saveRDS(products_details, file = paste0('products_details_', 
                                        year(get$date), '_',
                                        month(get$date), '_',
                                        day(get$date), '_',
                                        hour(get$date), '_',
                                        minute(get$date), '_',
                                        second(get$date), '_',
                                        '.RDS'))

url_ids <- unlist(sapply(products_details, '[[', 9))
length(url_ids) == length(unique(url_ids))
message('Number of URLs: ', length(unique(url_ids)))

# Get urls ----
t3 <- Sys.time()
urls <- list()
j <- 1
for (i in url_ids) {
  get <- httr::GET(paste0(p_url, 'get/url/id/', i),
                   add_headers("apikey" = apikey, "apitoken" = apitoken))
  t <- fromJSON(content(get, type="text"))
  urls[[j]] <- t
  j = j+1
  message(paste0('URLs downloaded: ', j-1, ' Status code: ', get$status_code))
}

write(paste0('URLs downloaded: ', j-1, ' with last status code: ', get$status_code),
      file = logs, append = T)
setwd('/home/jbontruk/BitBucket/smart_price/rds')
saveRDS(urls, file = paste0('urls_',
                            year(get$date), '_',
                            month(get$date), '_',
                            day(get$date), '_',
                            hour(get$date), '_',
                            minute(get$date), '_',
                            second(get$date), '_',
                            '.RDS'))

t4 <- Sys.time()
message(paste0('1: ', t1, '\n 2: ', t2, '\n 3: ', t3, "\n 4: ", t4))
message(paste0('Calkowity czas wykonania: ', round(t4-t1,2), ' min.'))
write(paste0('Time elapsed: ', round(t4-t1, 2), ' min. \n Script end: ', t4),
      file = logs, append = T)