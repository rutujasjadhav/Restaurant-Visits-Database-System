
# Program: test Database Loading
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
conn <- dbConnect(SQLite(), '/Users/rutuja/Documents/CS5200 Database Management System/Rstudio Codes/PRACTICUM 1/CS5200.Practicum-I.JadhavR/data/restaurants-db-02102026.sqlitedb')

# read csv file
df.orig <- read.csv('/Users/rutuja/Documents/CS5200 Database Management System/Rstudio Codes/PRACTICUM 1/CS5200.Practicum-I.JadhavR/data/restaurant-visits-209874.csv')



# COUNT TESTS

# test 1: unique restaurants
csv_restaurants <- length(unique(df.orig$RestaurantID))
db_restaurants <- dbGetQuery(mydb.aiven, "SELECT COUNT(*) as count FROM restaurants")$count
cat("Restaurants - CSV:", csv_restaurants, "| DB:", db_restaurants, "|",
    ifelse(csv_restaurants == db_restaurants, "PASS", "FAIL"), "\n")

# test 2: unique customers (non-empty only)
csv_customers <- length(unique(df.orig$CustomerName[df.orig$CustomerName != '']))
db_customers <- dbGetQuery(mydb.aiven, "SELECT COUNT(*) as count FROM customers")$count
cat("Customers - CSV:", csv_customers, "| DB:", db_customers, "|",
    ifelse(csv_customers == db_customers, "PASS", "FAIL"), "\n")

# test 3: unique servers
# comparing DB servers against SQLite source (not CSV subset) as CSV does not contain all servers
sqlite_servers <- dbGetQuery(conn, "SELECT COUNT(DISTINCT EmpID) as count FROM servers")$count
db_servers <- dbGetQuery(mydb.aiven, "SELECT COUNT(*) as count FROM servers")$count
cat("Servers - SQLite:", sqlite_servers, "| DB:", db_servers, "|",
    ifelse(sqlite_servers == db_servers, "PASS", "FAIL"), "\n")

# test 4: total visits
csv_visits <- nrow(df.orig)
db_visits <- dbGetQuery(mydb.aiven, "SELECT COUNT(*) as count FROM visit")$count
cat("Visits - CSV:", csv_visits, "| DB:", db_visits, "|",
    ifelse(csv_visits == db_visits, "PASS", "FAIL"), "\n")


# SUM TESTS

# test 5: total food bill
csv_food <- round(sum(df.orig$FoodBill, na.rm = TRUE), 2)
db_food <- round(dbGetQuery(mydb.aiven, "SELECT SUM(foodBill) as total FROM bill")$total, 2)
cat("Total FoodBill - CSV:", csv_food, "| DB:", db_food, "|",
    ifelse(csv_food == db_food, "PASS", "FAIL"), "\n")

# test 6: total alcohol bill
csv_alcohol <- round(sum(df.orig$AlcoholBill, na.rm = TRUE), 2)
db_alcohol <- round(dbGetQuery(mydb.aiven, "SELECT SUM(alcoholBill) as total FROM bill")$total, 2)
cat("Total AlcoholBill - CSV:", csv_alcohol, "| DB:", db_alcohol, "|",
    ifelse(csv_alcohol == db_alcohol, "PASS", "FAIL"), "\n")

# test 7: total tip amount
csv_tips <- round(sum(df.orig$TipAmount, na.rm = TRUE), 2)
db_tips <- round(dbGetQuery(mydb.aiven, "SELECT SUM(tipAmount) as total FROM bill")$total, 2)
cat("Total TipAmount - CSV:", csv_tips, "| DB:", db_tips, "|",
    ifelse(csv_tips == db_tips, "PASS", "FAIL"), "\n")

# disconnect
dbDisconnect(mydb.aiven)
dbDisconnect(conn)
