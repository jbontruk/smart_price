# Libraries ----
library(tidyverse)
library(lubridate)
nullToNA <- function(x) {
  x[sapply(x, is.null)] <- NA
  return(x)
}

# Prepare to get data ----
file_names <- list.files('/home/jbontruk/BitBucket/smart_price/rds/')
products_files <- file_names[substr(file_names,1,10) == 'products_2']
products_details_files <- file_names[substr(file_names,1,10) == 'products_d']
urls_files <- file_names[substr(file_names,1,3) == 'url']

products <- data.frame(matrix(ncol = 8, nrow = 0))
colnames(products) <- c('product_id', 'product_name', 'category_id', 'category_name',
                        'brand_id', 'brand_name', 'product_code', 'create_date')
products_details <- data.frame(matrix(ncol = 12, nrow = 0))
colnames(products_details) <- c('product_id', 'product_name', 'category_id', 'category_name', 'brand_id',
                                'brand_name', 'product_code', 'external_ref', 'product_cost', 'smart_price',
                                'urls', 'create_date')
urls <- data.frame(matrix(ncol = 10, nrow = 0))
colnames(urls) <- c('url_id', 'url', 'price', 'in_stock', 'last_check',
                    'change_day', 'currency', 'last_changed', 'old_price', 'create_date')

# Get and connect data ----
for (i in file_names) {
  t <- readRDS(file = paste0('/home/jbontruk/BitBucket/smart_price/rds/', i))
  t <- lapply(t, nullToNA)
  
  if (i %in% products_details_files) {
    t <- t %>% map(function(el) {
      el$urls <- paste0(el$urls, collapse = ';')
      el
    })
  }
  
  a  <-  as.data.frame(t(matrix(unlist(t), nrow=length(unlist(t[1])))), stringsAsFactors = F)
  
  if (i %in% products_files) {
    a$date_create <- ymd_hms(substr(i, 10, nchar(i)-5))
    colnames(a) <- colnames(products)
    products <- rbind(products, a)
  }
  
  if (i %in% products_details_files) {
    a$date_create <- ymd_hms(substr(i, 18, nchar(i)-5))
    colnames(a) <- colnames(products_details)
    products_details <- rbind(products_details, a)
  }
  
  if (i %in% urls_files) {
    a$date_create <- ymd_hms(substr(i, 6, nchar(i)-5))
    colnames(a) <- colnames(urls)
    urls <- rbind(urls, a)
  }
  rm(a, t)
}

# Format data ----
products_details <- products_details %>%
  mutate(product_cost = as.numeric(gsub(",", "", product_cost)),
         smart_price = as.numeric(gsub(",", "", smart_price)))

urls <- urls %>%
  mutate(price = as.numeric(gsub(",", "", price)),
         in_stock = as.numeric(in_stock),
         last_check = ymd_hms(last_check),
         last_changed = dmy(last_changed),
         old_price = as.numeric(gsub(",", "", old_price)))
# Write data ----
setwd('/home/jbontruk/BitBucket/smart_price/rdata')
save(products, products_details, urls, file = "master_data.RData")