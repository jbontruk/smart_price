# Libraries ----
library(tidyverse)
library(openxlsx)
domain <- function(x) strsplit(gsub("http://|https://|www\\.", "", x), "/")[[c(1, 1)]]
# Get data ----
load('/home/jbontruk/BitBucket/smart_price/rdata/master_data.RData')
# Join urls and product_details ----
l <- strsplit(as.character(products_details$urls), ';')
t <- unique(data.frame(url_id = unlist(l),
                       product_id = rep(products_details$product_id, lengths(l)),
                       stringsAsFactors = F))
urls <- left_join(urls, t)

t <- products_details %>%
  group_by(product_id) %>%
  summarise(max_create_date = max(create_date))

product_dict <- left_join(products_details, t, by = 'product_id') %>%
  filter(create_date == max_create_date) %>%
  unique() %>%
  select(product_id, product_name, category_name, brand_name, product_cost, create_date)

data <- left_join(urls, product_dict, by = "product_id") %>%
  select(-change_day)

data$shop_name <- sapply(data$url, domain)
# Prepare data 'PriceDetails' ----
t <- data %>%
  group_by(url_id) %>%
  summarise(max_create_date = max(create_date.x))

t <- left_join(data, t, by = "url_id") %>%
  filter(create_date.x == max_create_date) %>%
  select(-max_create_date) %>%
  filter(price > 0)

t <- t[order(t$product_id, t$price),] %>%
  select(product_id, brand_name, category_name, product_name, product_cost, url, price, shop_name) %>%
  group_by(product_id) %>%
  mutate(rank = row_number(),
         min_price = as.integer(min(price)),
         avg_price = as.integer(mean(price)),
         max_price = as.integer(max(price)),
         product_cost = as.integer(product_cost),
         shop_count = n(),
         price = as.integer(price)) %>%
  data.frame()

cheapest_shops <- t %>%
  filter(price == min_price) %>%
  group_by(product_id) %>%
  mutate(cheapest_shops = paste0(shop_name, collapse = ", ")) %>%
  select(product_id, cheapest_shops) %>%
  distinct(product_id, cheapest_shops)

t <- left_join(t, cheapest_shops)

max_rank <- as.numeric(max(t$rank))

t <- t %>%
  mutate(formula = paste0('=HYPERLINK("', url, '", "', price, ' - ', shop_name, '")'),
         sklep = ifelse(rank < 10, 
                        paste0('Sklep ', 0, rank),
                        paste0('Sklep ', rank))) %>%
  rename(Brand = brand_name,
         Kategoria = category_name,
         `Nazwa produktu` = product_name,
         `Cena SRP` = product_cost,
         `Min. cena` = min_price,
         `Ĺšrednia cena` = avg_price,
         `Max. cena` = max_price,
         `L. sklepĂłw` = shop_count,
         `NajtaĹ„sze sklepy` = cheapest_shops) %>%
  select(-product_id, -url, -price, -shop_name, -rank)

price_details <- spread(t, key = sklep, value = formula) %>%
  arrange(Brand, `Nazwa produktu`)
price_details[is.na(price_details)] <- ""
# Generate Excels ----
email_dict <- readRDS('/home/jbontruk/BitBucket/smart_price/email_dict/email_dict.RDS')
for (brand_name in email_dict$brand) {
  if (brand_name == 'Total') {
    t <- price_details
  }
  else {
    t <- price_details %>%
      filter(Brand == brand_name)
  }
  # Create Workbook ----
  wb <- createWorkbook()
  addWorksheet(wb, "PriceDetails")
  hs1 <- createStyle(fontSize = 12, fgFill = "#FFFF00", textDecoration = "bold",
                     halign = "LEFT", valign = "CENTER")
  linkStyle <- createStyle(fontColour = "#0000FF", textDecoration = "underline")
  # Prepare Sheet 'PriceDetails' ----
  for (i in 10:(max_rank + 9)) {
    class(t[,i]) <- "formula"
  }
  
  mergeCells(wb, "PriceDetails", cols = 1:3, rows = 1)
  PriceDetailsHead <- "Witaj w SmartPrice! 'WĹ‚Ä…cz edytowanie' aby wyĹ›wietliÄ‡ spis cen i linki."
  writeData(wb, "PriceDetails", x = PriceDetailsHead, startCol = 1, startRow = 1)
  addStyle(wb, "PriceDetails", style = hs1, rows = 1, cols = 1)
  
  writeDataTable(wb, "PriceDetails", x = t, startCol = 1, startRow = 3,
                 tableStyle = "TableStyleLight8")
  addStyle(wb, "PriceDetails", style = linkStyle, rows = 4:1000, cols = 10:50, gridExpand = T)
  
  setColWidths(wb, "PriceDetails", cols = c(1:2, 4:8), widths = 11)
  setColWidths(wb, "PriceDetails", cols = 3, widths = 35)
  setColWidths(wb, "PriceDetails", cols = 9:50, widths = 18)
  
  freezePane(wb, "PriceDetails", firstActiveRow = 4, firstActiveCol = 4)
  # Save Excel ----
  setwd("/home/jbontruk/BitBucket/smart_price/excel")
  saveWorkbook(wb, paste0("SmartPrice_", brand_name, "_", Sys.Date(), ".xlsx"), overwrite = T)
}