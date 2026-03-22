
# Program: load Database
# Name: Rutuja Jadhav

# load required library
library(RMySQL)
library(RSQLite)

# CONNECT TO AIVEN
# define settings
db_host_aiven <- "YOUR_HOST"
db_port_aiven <- 00000
db_name_aiven <- "YOUR_DB_NAME"
db_user_aiven <- "YOUR_USERNAME"
db_pwd_aiven <- "YOUR_PASSWORD"

# embedded SSL certificate
db_cert <- 
  '
-----BEGIN CERTIFICATE-----
xxxx
-----END CERTIFICATE-----
'

# connect securely to remote MySQL server and database
mydb.aiven <-  dbConnect(RMySQL::MySQL(), 
                         user = db_user_aiven, 
                         password = db_pwd_aiven,
                         dbname = db_name_aiven, 
                         host = db_host_aiven, 
                         port = db_port_aiven,
                         sslmode = "require",
                         sslcert = db_cert)

# set the path to current project directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# LOAD SQLite DATABASE
# connect to database
conn <- dbConnect(SQLite(), 'data/restaurants-db-02102026.sqlitedb')

# read csv file
df.orig <- read.csv('data/restaurant-visits-209874.csv')

# adding visitID in the start
df.orig$visitID <- 1:nrow(df.orig)

# POPULATE TABLES (same order as creating)


# city table
# create a city df in R
city_df <- dbGetQuery(conn, "SELECT DISTINCT City, State FROM restaurants;")

# create cityID column
city_df$CityID <- 1:nrow(city_df)

# insert data in city table in aiven
for (i in 1:nrow(city_df)){
  add_data_city <- sprintf("INSERT INTO city (cityID, cityName, state) VALUES(%d, '%s', '%s')",
                           city_df$CityID[i],
                           city_df$City[i],
                           city_df$State[i])
  dbExecute(mydb.aiven, add_data_city)
}

# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM city;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE city") 
cat("city table is populated.")


# restaurants table 
# create a restaurants df in R
restaurants_df <- dbGetQuery(conn, "SELECT DISTINCT rID, RestaurantName, hasTableService, City FROM restaurants;")

# merge city_df and restaurant_df to get the FK in restaurants table
restaurants_df <- merge(restaurants_df, city_df, by = "City")

# convert yes/no in hasTableService to 1/0
for (i in 1:nrow(restaurants_df)) {
  if (restaurants_df$hasTableService[i] == "yes") {
    restaurants_df$hasTableService[i] <- 1
  } else {
    restaurants_df$hasTableService[i] <- 0
  }
}

# substitute single ' with double '' to handle restaurantName with '
restaurants_df$RestaurantName <- gsub("'", "''", restaurants_df$RestaurantName)

# insert data in restaurants table in aiven
for (i in 1:nrow(restaurants_df)){
  add_data_restaurants <- sprintf("INSERT INTO restaurants (restaurantID, restaurantName, cityID, hasTableService) 
                                  VALUES(%d, '%s', %d, '%s')",
                                  restaurants_df$rID[i],
                                  restaurants_df$RestaurantName[i],
                                  restaurants_df$CityID[i],
                                  restaurants_df$hasTableService[i])
  dbExecute(mydb.aiven, add_data_restaurants)
}
# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM restaurants;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE restaurants") 
cat("restaurants table is populated.")


# servers table
# create a restaurants df in R
# we take MAX(HourlyRate) as there are duplicate EmpID with 2 different HourlyRate
servers_df <- dbGetQuery(conn, "SELECT DISTINCT EmpID, ServerName, StartDateHired, EndDateHired, 
                         MAX(HourlyRate) as HourlyRate, BirthDate, SSN, rID 
                         FROM servers
                         GROUP BY EmpID;")

# split ServerName into firstName and lastName
servers_df$firstName <- trimws(sapply(strsplit(servers_df$ServerName, ","), `[`, 2))
servers_df$lastName <- trimws(sapply(strsplit(servers_df$ServerName, ","), `[`, 1))

# ensuring ids are integers
servers_df$EmpID <- as.integer(servers_df$EmpID)
servers_df$rID <- as.integer(servers_df$rID)

# convert empty in EndDateHired to NULL
for (i in 1:nrow(servers_df)) {
  if (servers_df$EndDateHired[i] == "") {
    servers_df$EndDateHired[i] <- "NULL"
  }
  # to handle non-empty dates as 'yyyy-mm-dd' instead of yyyy-mm-dd
  else 
    servers_df$EndDateHired[i] <- paste0("'", servers_df$EndDateHired[i], "'")
}

# convert birthDate from mm/dd/yyyy to yyyy-mm-dd
servers_df$BirthDate <- as.character(as.Date(servers_df$BirthDate, format = "%m/%d/%Y"))

# convert empty in birthDate to NULL
for (i in 1:nrow(servers_df)) {
  if (is.na(servers_df$BirthDate[i])) {
    servers_df$BirthDate[i] <- "NULL"
  }
  # to handle non-empty dates as 'yyyy-mm-dd' instead of yyyy-mm-dd
  else 
    servers_df$BirthDate[i] <- paste0("'", servers_df$BirthDate[i], "'")
}

# insert data in servers table in aiven
for (i in 1:nrow(servers_df)){
  add_data_servers <- sprintf("INSERT INTO servers (employeeID, firstName, lastName, startDateHired, endDateHired, hourlyRate, birthDate, ssn, restaurantID) 
                              VALUES(%d, '%s', '%s', '%s', %s, %f, %s, '%s', %d)",
                              servers_df$EmpID[i],
                              servers_df$firstName[i],
                              servers_df$lastName[i],
                              servers_df$StartDateHired[i],
                              servers_df$EndDateHired[i],
                              servers_df$HourlyRate[i],
                              servers_df$BirthDate[i],
                              servers_df$SSN[i],
                              servers_df$rID[i]
  )
  dbExecute(mydb.aiven, add_data_servers)
}
# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM servers;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE servers") 
cat("servers table is populated.")


# customers table
# create a customer df in R 
customer_df <- df.orig[,c('CustomerName', 'CustomerPhone', 'CustomerEmail', 'LoyaltyMember')]

# customer_df with only unique customers 
customer_df <- unique(customer_df)

# drop customers with empty or NA name, email or phone number
customer_df <- customer_df[
  customer_df$CustomerName != '' & !is.na(customer_df$CustomerName) &
    customer_df$CustomerPhone != '' & !is.na(customer_df$CustomerPhone) &
    customer_df$CustomerEmail != '' & !is.na(customer_df$CustomerEmail) ,
]

# split CustomerName into firstName and lastName
customer_df$firstName <- trimws(sapply(strsplit(customer_df$CustomerName, " "), `[`, 1))
customer_df$lastName <- trimws(sapply(strsplit(customer_df$CustomerName, " "), `[`, 2))

# add customerID 
customer_df$cID <- 1:nrow(customer_df)

# insert data in customer table in aiven
for (i in 1:nrow(customer_df)){
  add_data_customers <- sprintf("INSERT INTO customers (customerID, firstName, lastName, phoneNumber, emailID, loyaltyMember) 
                              VALUES(%d, '%s', '%s', '%s', '%s', %d)",
                                customer_df$cID[i],
                                customer_df$firstName[i],
                                customer_df$lastName[i],
                                customer_df$CustomerPhone[i],
                                customer_df$CustomerEmail[i],
                                customer_df$LoyaltyMember[i]
  )
  dbExecute(mydb.aiven, add_data_customers)
}
# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM customers;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE customers")
cat("customers table is populated.")


# mealType table

# find all the different mealTypes from df
mealTypes <- unique(df.orig$MealType)

# insert data in mealType table in aiven
for (i in 1:length(mealTypes)){
  add_data_mealType <- sprintf("INSERT INTO mealType (mealTypeID, mealType)
                              VALUES(%d, '%s')",
                               i,
                               mealTypes[i]
  )
  
  dbExecute(mydb.aiven, add_data_mealType)
}
# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM mealType;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE mealType")
cat("mealType table is populated.")


# visit table
# create a visit df in R
visit_df <- df.orig[, c('visitID','VisitDate', 'VisitTime', 'PartySize', 'WaitTime', 'MealType', 'RestaurantID', 'ServerEmpID', 'CustomerName')]

# create visitID
#visit_df$visitID <- 1:nrow(visit_df)

# converting 99 partySize into NA
visit_df$PartySize <- ifelse(visit_df$PartySize == 99, NA, visit_df$PartySize)
unique(visit_df$PartySize)

# converting negative waitTime into 0
visit_df$WaitTime <- ifelse(visit_df$WaitTime < 0 , 0, visit_df$WaitTime)
unique(visit_df$WaitTime)

# merge visit_df with mealtype to get the FK via customerID
mealType_df <- dbGetQuery(mydb.aiven, "SELECT * FROM mealType")
visit_df <- merge(visit_df, mealType_df, by.x ='MealType', by.y = 'mealType')

# merge visit_df with customer_df to get the FK via customerID
# all.x is used to ensures all rows of visit_df are kept even when there is no CustomerName corresponding to it
visit_df <- merge(visit_df, customer_df[c('cID', 'CustomerName')], by='CustomerName', all.x = TRUE)

# handling NULL values 
visit_df$VisitTime <- ifelse(is.na(visit_df$VisitTime), "NULL", paste0("'", visit_df$VisitTime, "'"))
visit_df$PartySize <- ifelse(is.na(visit_df$PartySize), "NULL", visit_df$PartySize)
visit_df$WaitTime <- ifelse(is.na(visit_df$WaitTime), "NULL", visit_df$WaitTime)
visit_df$cID <- ifelse(is.na(visit_df$cID), "NULL", visit_df$cID)
visit_df$ServerEmpID <- ifelse(is.na(visit_df$ServerEmpID), "NULL", visit_df$ServerEmpID)

# insert data in visit table in aiven using batch inserts for efficiency
batch_size <- 1000
n <- nrow(visit_df)
for (start in seq(1, n, by = batch_size)) {
  end <- min(start + batch_size - 1, n)
  batch <- paste(sprintf("(%d, '%s', %s, %s, %s, %d, %d, %s, %s)",
                         visit_df$visitID[start:end],
                         visit_df$VisitDate[start:end],
                         visit_df$VisitTime[start:end],
                         visit_df$PartySize[start:end],
                         visit_df$WaitTime[start:end],
                         visit_df$mealTypeID[start:end],
                         visit_df$RestaurantID[start:end],
                         visit_df$ServerEmpID[start:end],
                         visit_df$cID[start:end]), collapse = ",")
  add_data_visit <- paste0("INSERT INTO visit (visitID, visitDate, visitTime, partySize, waitTime, mealTypeID, restaurantID, serverID, customerID) VALUES ", batch)
  dbExecute(mydb.aiven, add_data_visit)
}

# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM visit;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE visit") 
cat("visit table is populated.")







# paymentMethod table

# find all the different PaymentMethod from df
PaymentMethods <- unique(df.orig$PaymentMethod)

# insert data in paymentMethod table in aiven
for (i in 1:length(PaymentMethods)){
  add_data_paymentMethod <- sprintf("INSERT INTO paymentMethod (paymentMethodID, paymentMethodName)
                              VALUES(%d, '%s')",
                                    i,
                                    PaymentMethods[i]
  )
  
  dbExecute(mydb.aiven, add_data_paymentMethod)
}
# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM paymentMethod;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE paymentMethod")
cat("paymentMethod table is populated.")







# bill table
# create bill df in R
bill_df <- df.orig[, c('visitID', 'FoodBill', 'TipAmount', 'FoodDiscountPercentage', 
                       'orderedAlcohol', 'AlcoholBill', 'PaymentMethod')]

# create billID
bill_df$billID <- 1:nrow(bill_df)

# create paymentMethod df 
paymentMethod_df <- dbGetQuery(mydb.aiven, "SELECT * FROM paymentMethod")

# merge with visit_df to get visitID
#bill_df <- merge(bill_df, visit_df[, c('visitID', 'RestaurantID', 'VisitDate', 'VisitTime')], by = c('RestaurantID', 'VisitDate', 'VisitTime'), all.x = TRUE)

# merge bill_df and paymentMethod df to get FK paymentMethodID
bill_df <- merge(bill_df, paymentMethod_df, by.x ='PaymentMethod', by.y = 'paymentMethodName')

# convert orderedAlcohol yes/no to 1/0
bill_df$orderedAlcohol <- ifelse(bill_df$orderedAlcohol == "yes", 1, 0)

# handle NULL in AlcoholBill (when orderedAlcohol is 0, alcoholBill should be 0)
bill_df$AlcoholBill <- ifelse(is.na(bill_df$AlcoholBill), 0, bill_df$AlcoholBill)

# insert data in bill table in aiven using batch inserts for efficiency
batch_size <- 1000
n <- nrow(bill_df)
for (start in seq(1, n, by = batch_size)) {
  end <- min(start + batch_size - 1, n)
  batch <- paste(sprintf("(%d, %d, %f, %f, %f, %d, %f, %d)",
                         bill_df$billID[start:end],
                         bill_df$visitID[start:end],
                         bill_df$FoodBill[start:end],
                         bill_df$FoodDiscountPercentage[start:end],
                         bill_df$TipAmount[start:end],
                         bill_df$orderedAlcohol[start:end],
                         bill_df$AlcoholBill[start:end],
                         bill_df$paymentMethodID[start:end]), collapse = ",")
  add_data_bill <- paste0("INSERT INTO bill (billID, visitID, foodBill, foodDiscountPercentage, tipAmount, orderedAlcohol, alcoholBill, paymentMethodID) VALUES ", batch)
  dbExecute(mydb.aiven, add_data_bill)
}

# verify inserted columns
#dbGetQuery(mydb.aiven, "SELECT * FROM bill;")

# to check the types of attributes
#dbGetQuery(mydb.aiven, "DESCRIBE bill")
cat("bill table is populated.")


# disconnect from the aiven database
dbDisconnect(mydb.aiven)