# Program: create Database
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

# LOAD SQLite DATABASE
# connect to database
# conn <- dbConnect(SQLite(), "data/restaurants-db-02102026.sqlitedb")

# CREATE TABLES

# city table
create_table_city <- "
CREATE TABLE IF NOT EXISTS city (
  cityID INTEGER PRIMARY KEY,
  cityName varchar(50) NOT NULL,
  state varchar(50) NOT NULL
); 
"
dbExecute(mydb.aiven, create_table_city)

# restaurants table
create_table_restaurants <- "
CREATE TABLE IF NOT EXISTS restaurants (
  restaurantID INTEGER PRIMARY KEY,
  restaurantName varchar(50) NOT NULL,
  cityID INTEGER NOT NULL,
  hasTableService BOOLEAN NOT NULL,
  FOREIGN KEY (cityID) REFERENCES city (cityID)
); 
"
dbExecute(mydb.aiven, create_table_restaurants)

# servers table
create_table_servers <- "
CREATE TABLE IF NOT EXISTS servers (
  employeeID INTEGER PRIMARY KEY,
  firstName varchar(50) NOT NULL,
  lastName varchar(50) NOT NULL,
  startDateHired DATE NOT NULL,
  endDateHired DATE,
  hourlyRate FLOAT NOT NULL,
  birthDate DATE,
  ssn varchar(11),
  restaurantID INTEGER NOT NULL,
  FOREIGN KEY (restaurantID) REFERENCES restaurants (restaurantID)
); 
"
dbExecute(mydb.aiven, create_table_servers)

# customers table
create_table_customers <- "
CREATE TABLE IF NOT EXISTS customers (
  customerID INTEGER PRIMARY KEY,
  firstName varchar(50) NOT NULL,
  lastName varchar(50) NOT NULL,
  phoneNumber varchar(15) NOT NULL,
  emailID varchar(50) NOT NULL,
  loyaltyMember BOOLEAN NOT NULL DEFAULT FALSE
); 
"
dbExecute(mydb.aiven, create_table_customers)

# mealType table
create_table_mealType <- "
CREATE TABLE IF NOT EXISTS mealType (
  mealTypeID INTEGER PRIMARY KEY,
  mealType varchar(50) NOT NULL
); 
"
dbExecute(mydb.aiven, create_table_mealType)

# visit table
create_table_visit <- "
CREATE TABLE IF NOT EXISTS visit (
  visitID INTEGER PRIMARY KEY,
  visitDate DATE NOT NULL,
  visitTime TIME,
  partySize INTEGER,
  waitTime INTEGER DEFAULT 0,
  mealTypeID INTEGER NOT NULL,
  restaurantID INTEGER NOT NULL,
  serverID INTEGER,
  customerID INTEGER,
  FOREIGN KEY (mealTypeID) REFERENCES mealType (mealTypeID),
  FOREIGN KEY (restaurantID) REFERENCES restaurants (restaurantID),
  FOREIGN KEY (serverID) REFERENCES servers (employeeID),
  FOREIGN KEY (customerID) REFERENCES customers (customerID)
); 
"
dbExecute(mydb.aiven, create_table_visit)

# paymentMethod table
create_table_paymentMethod <- "
CREATE TABLE IF NOT EXISTS paymentMethod (
  paymentMethodID INTEGER PRIMARY KEY,
  paymentMethodName varchar(50) NOT NULL
); 
"
dbExecute(mydb.aiven, create_table_paymentMethod)

# bill table
create_table_bill <- "
CREATE TABLE IF NOT EXISTS bill (
  billID INTEGER PRIMARY KEY,
  visitID INTEGER NOT NULL,
  foodBill FLOAT NOT NULL DEFAULT 0.0,
  foodDiscountPercentage FLOAT DEFAULT 0.0,
  tipAmount FLOAT NOT NULL DEFAULT 0.0,
  orderedAlcohol BOOLEAN NOT NULL,
  alcoholBill FLOAT DEFAULT 0.0,
  paymentMethodID INTEGER NOT NULL,
  FOREIGN KEY (visitID) REFERENCES visit (visitID),
  FOREIGN KEY (paymentMethodID) REFERENCES paymentMethod (paymentMethodID)
); 
"
dbExecute(mydb.aiven, create_table_bill)



# verify if tables were created
dbListTables(mydb.aiven)

# disconnect from the aiven database
dbDisconnect(mydb.aiven)

