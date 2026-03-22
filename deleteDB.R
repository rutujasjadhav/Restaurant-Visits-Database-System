
# Program: delete Database
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


# DROP TABLES -> order is reverse of creation to avoid issues due to FK

# bill table
drop_table_bill <- "
DROP TABLE IF EXISTS bill; 
"
dbExecute(mydb.aiven, drop_table_bill)

# paymentMethod table
drop_table_paymentMethod <- "
DROP TABLE IF EXISTS paymentMethod; 
"
dbExecute(mydb.aiven, drop_table_paymentMethod)

# visit table
drop_table_visit <- "
DROP TABLE IF EXISTS visit; 
"
dbExecute(mydb.aiven, drop_table_visit)

# mealType table
drop_table_mealType <- "
DROP TABLE IF EXISTS mealType; 
"
dbExecute(mydb.aiven, drop_table_mealType)

# customers table
drop_table_customers <- "
DROP TABLE IF EXISTS customers; 
"
dbExecute(mydb.aiven, drop_table_customers)

# servers table
drop_table_servers <- "
DROP TABLE IF EXISTS servers; 
"
dbExecute(mydb.aiven, drop_table_servers)

# restaurants table
drop_table_restaurants <- "
DROP TABLE IF EXISTS restaurants; 
"
dbExecute(mydb.aiven, drop_table_restaurants)

# city table
drop_table_city <- "
DROP TABLE IF EXISTS city; 
"
dbExecute(mydb.aiven, drop_table_city)



# verify if tables were dropped/deleted
dbListTables(mydb.aiven)

# disconnect from the aiven database
dbDisconnect(mydb.aiven)