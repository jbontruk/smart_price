# Libraries ----
library(gmailr)
library(dplyr)
use_secret_file('/home/jbontruk/BitBucket/smart_price/auth/smartprice_client_secret.json')
email_dict <- readRDS('/home/jbontruk/BitBucket/smart_price/email_dict/email_dict.RDS')
# Send email ----
for (brand_name in email_dict$brand) {
  filename <- paste0("/home/jbontruk/BitBucket/smart_price/excel/SmartPrice_",
                     brand_name,
                     "_",
                     Sys.Date(),
                     ".xlsx")
  
  email_address <- email_dict %>%
    filter(brand == brand_name) %>%
    select(email) %>%
    as.character()
  
  subject_text <- paste0('SmartPrice Monitoring Cen - ', brand_name, ' ', Sys.Date())
  
  body_text <- 'Witamy,
  
  w załączniku przesyłamy aktualny raport.
  
  Jeśli chcą Państwo uzupełnić raport o dodatkowe produkty lub sklepy, 
  prosimy o informację zwrotną najlepiej z konkretnymi url do oferty.
  
  Cały czas pracujemy nad raportem i aplikacją SmartPrice. 
  Wszelkie sugestie z Państwa strony będą dla nas bardzo cenne.
  
  NOWA WERSJA RAPORTU
  - zawiera bezpośrednie url do konkretnej oferty sklepu
  - ceny są posortowane od najtańszej od lewej do prawej
  - konkretna komórka to oferta danego produktu z ceną oraz url
  
  Pozdrawiamy,
  Zespół SmartPrice'
  
  email <- mime() %>%
    to(email_address) %>%
    from("SmartPrice") %>%
    subject(subject_text) %>%
    text_body(body_text) %>%
    attach_part(body_text) %>%
    attach_file(filename) %>%
    send_message()
  
}
# Detach libraries ----
detach("package:gmailr", unload=TRUE)