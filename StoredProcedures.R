
# Program: Stored Procedures
# Name: Rutuja Jadhav


# load required library
library(RMySQL)

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

# helper function to reconnect to aiven
reconnect <- function() {
  dbConnect(RMySQL::MySQL(),
            user = db_user_aiven,
            password = db_pwd_aiven,
            dbname = db_name_aiven,
            host = db_host_aiven,
            port = db_port_aiven,
            sslmode = "require",
            sslcert = db_cert)
}

# connect securely to remote MySQL server and database
mydb.aiven <- reconnect()



# STORED PROCEDURE 1: storeNewServer

# drop if exists
dbExecute(mydb.aiven, "DROP PROCEDURE IF EXISTS storeNewServer")

# create stored procedure
dbExecute(mydb.aiven, "
CREATE PROCEDURE storeNewServer(
  IN p_employeeID INT,
  IN p_firstName VARCHAR(50),
  IN p_lastName VARCHAR(50),
  IN p_startDateHired DATE,
  IN p_endDateHired DATE,
  IN p_hourlyRate FLOAT,
  IN p_birthDate DATE,
  IN p_ssn VARCHAR(11),
  IN p_restaurantID INT
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM servers 
    WHERE firstName = p_firstName 
    AND lastName = p_lastName 
    AND birthDate = p_birthDate
  ) THEN
    SELECT 'ERROR: Server already exists.' AS Message;
  ELSE
    INSERT INTO servers (employeeID, firstName, lastName, startDateHired, endDateHired, 
                         hourlyRate, birthDate, ssn, restaurantID)
    VALUES (p_employeeID, p_firstName, p_lastName, p_startDateHired, p_endDateHired,
            p_hourlyRate, p_birthDate, p_ssn, p_restaurantID);
    SELECT 'SUCCESS: New server added successfully.' AS Message;
  END IF;
END
")
cat("Stored procedure storeNewServer created.\n")



# TEST: storeNewServer


# TEST 1 - PASS: add a new server that does not exist
cat("\n TEST 1: Adding new server (should PASS) ---\n")
mydb.aiven <- reconnect()
tryCatch({
  result <- dbGetQuery(mydb.aiven, "CALL storeNewServer(
    99999, 'John', 'Doe', '2024-01-01', NULL, 15.00, '1990-05-15', '123-45-6789', 100
  )")
  cat("Result:", result$Message, "\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n")
})

# verify
mydb.aiven <- reconnect()
cat("Verify - server added:\n")
print(dbGetQuery(mydb.aiven, "SELECT * FROM servers WHERE employeeID = 99999"))

# TEST 2 - FAIL: add same server again (same name and birthdate)
cat("\n TEST 2: Adding duplicate server (should FAIL) ---\n")
mydb.aiven <- reconnect()
tryCatch({
  result <- dbGetQuery(mydb.aiven, "CALL storeNewServer(
    99998, 'John', 'Doe', '2024-01-01', NULL, 15.00, '1990-05-15', '123-45-6789', 100
  )")
  cat("Result:", result$Message, "\n")
}, error = function(e) {
  cat("Expected Error:", conditionMessage(e), "\n")
})



# STORED PROCEDURE 2: updateServer


# drop if exists
mydb.aiven <- reconnect()
dbExecute(mydb.aiven, "DROP PROCEDURE IF EXISTS updateServer")

# create stored procedure
dbExecute(mydb.aiven, "
CREATE PROCEDURE updateServer(
  IN p_employeeID INT,
  IN p_firstName VARCHAR(50),
  IN p_lastName VARCHAR(50),
  IN p_startDateHired DATE,
  IN p_endDateHired DATE,
  IN p_hourlyRate FLOAT,
  IN p_birthDate DATE,
  IN p_ssn VARCHAR(11),
  IN p_restaurantID INT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM servers WHERE employeeID = p_employeeID) THEN
    SELECT 'ERROR: Server does not exist.' AS Message;
    
  ELSEIF NOT EXISTS (SELECT 1 FROM restaurants WHERE restaurantID = p_restaurantID) THEN
    SELECT 'ERROR: Restaurant does not exist.' AS Message;
    
  ELSEIF p_hourlyRate <= 0 THEN
    SELECT 'ERROR: Hourly rate must be positive.' AS Message;
    
  ELSEIF p_endDateHired IS NOT NULL AND p_endDateHired <= p_startDateHired THEN
    SELECT 'ERROR: End date must be after start date.' AS Message;
    
  ELSE
    UPDATE servers
    SET firstName = p_firstName,
        lastName = p_lastName,
        startDateHired = p_startDateHired,
        endDateHired = p_endDateHired,
        hourlyRate = p_hourlyRate,
        birthDate = p_birthDate,
        ssn = p_ssn,
        restaurantID = p_restaurantID
    WHERE employeeID = p_employeeID;
    SELECT 'SUCCESS: Server updated successfully.' AS Message;
  END IF;
END
")
cat("Stored procedure updateServer created.\n")



# TEST: updateServer


# TEST 1 - PASS: update existing server with valid data
cat("\n TEST 1: Updating existing server (should PASS) ---\n")
mydb.aiven <- reconnect()
tryCatch({
  result <- dbGetQuery(mydb.aiven, "CALL updateServer(
    99999, 'John', 'Doe', '2024-01-01', '2025-01-01', 18.00, '1990-05-15', '123-45-6789', 100
  )")
  cat("Result:", result$Message, "\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n")
})

# verify
mydb.aiven <- reconnect()
cat("Verify - server updated:\n")
print(dbGetQuery(mydb.aiven, "SELECT * FROM servers WHERE employeeID = 99999"))

# TEST 2 - FAIL: update non-existent server
cat("\n TEST 2: Updating non-existent server (should FAIL) ---\n")
mydb.aiven <- reconnect()
tryCatch({
  result <- dbGetQuery(mydb.aiven, "CALL updateServer(
    00000, 'Jane', 'Smith', '2024-01-01', NULL, 15.00, '1995-03-20', '987-65-4321', 100
  )")
  cat("Result:", result$Message, "\n")
}, error = function(e) {
  cat("Expected Error:", conditionMessage(e), "\n")
})

# TEST 3 - FAIL: update with invalid hourly rate
cat("\n TEST 3: Updating with negative hourly rate (should FAIL) ---\n")
mydb.aiven <- reconnect()
tryCatch({
  result <- dbGetQuery(mydb.aiven, "CALL updateServer(
    99999, 'John', 'Doe', '2024-01-01', NULL, -5.00, '1990-05-15', '123-45-6789', 100
  )")
  cat("Result:", result$Message, "\n")
}, error = function(e) {
  cat("Expected Error:", conditionMessage(e), "\n")
})

# TEST 4 - FAIL: end date before start date
cat("\n TEST 4: End date before start date (should FAIL) ---\n")
mydb.aiven <- reconnect()
tryCatch({
  result <- dbGetQuery(mydb.aiven, "CALL updateServer(
    99999, 'John', 'Doe', '2024-01-01', '2023-01-01', 15.00, '1990-05-15', '123-45-6789', 100
  )")
  cat("Result:", result$Message, "\n")
}, error = function(e) {
  cat("Expected Error:", conditionMessage(e), "\n")
})



# Remove Test Server
mydb.aiven <- reconnect()
dbExecute(mydb.aiven, "DELETE FROM servers WHERE employeeID = 99999")
cat("\nTest server removed.\n")


# disconnect
dbDisconnect(mydb.aiven)

