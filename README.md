# Restaurant Visits Database System

**Author:** Rutuja Jadhav

---

## Project Overview

An end-to-end relational database system built around a large synthetic restaurant visits dataset. The project spans database modeling, schema implementation on a cloud-hosted MySQL instance, automated data loading, stored procedure development, and analytical reporting.

---

## Technologies & Tools Used

- **MySQL** (hosted on Aiven cloud) — primary database engine
- **SQLite** — source database for restaurant and server reference data
- **R / RStudio** — scripting, data loading, and analytics
- **R Packages:** `DBI`, `RMySQL`, `RSQLite`, `dplyr`, `knitr`, `kableExtra`, `sqldf`
- **R Markdown** — analytical reporting

---

## Concepts Applied

- **Conceptual, Logical, and Physical Data Modeling** — designed an ERD with entities, relationships, cardinalities, and crow's foot notation
- **Database Normalization** — implemented schema in Third Normal Form (3NF) with surrogate keys and appropriate nullable columns
- **Multi-source Data Integration** — merged data from a large CSV file and a SQLite reference database into a unified MySQL schema
- **Batch Data Loading** — automated bulk insertion of CSV records into MySQL using R with chunked processing
- **Stored Procedures** — developed two MySQL stored procedures (`storeNewServer`, `updateServer`) with business rule enforcement including duplicate detection, foreign key validation, and date integrity checks
- **Analytical Reporting** — queried the populated database in R Markdown to produce formatted revenue and performance reports by restaurant

---

## File Structure

```
RestaurantVisit.JadhavR/
│
├── data/                      # AI-generated data files (not tracked); structure documented in designDBSchema.Rmd
│
├── designDBSchema.Rmd         # ERD, normalization, and functional dependencies
├── designDBSchema.pdf         # Knitted PDF output of designDBSchema.Rmd
├── ERD.png                    # Entity Relationship Diagram
├── createDB.R                 # Schema creation script
├── deleteDB.R                 # Schema teardown script
├── loadDB.R                   # Batch data loading from CSV and SQLite
├── testDBLoading.R            # Data loading verification and tests
├── StoredProcedures.R         # Stored procedure definitions and tests
└── RevenueReport.Rmd          # R Markdown analytics report
└── RevenueReport.pdf          # Knitted PDF output of RevenueReport.Rmd
```

---

## Data

The dataset used in this project was artificially generated using AI. The data files are not included in this repository. The full structure, attributes, and relationships of the data are documented in `designDBSchema.Rmd`.

---

## How to Run

1. Clone the repository and open the project in RStudio.
2. Install required R packages: `DBI`, `RMySQL`, `RSQLite`, `dplyr`, `knitr`, `kableExtra`.
3. Place the CSV and SQLite files in the `data/` folder.
4. Update the Aiven MySQL credentials in the connection block.
5. Run `createDB.R` to create the schema.
6. Run `loadDB.R` to batch-load all data (note: this may take 15–25 minutes on the full dataset).
7. Run `testDBLoading.R` to verify the data loaded correctly.
8. Run `StoredProcedures.R` to create and test stored procedures.
9. Knit `RevenueReport.Rmd` to generate the analytics report.
10. To reset the database, run `deleteDB.R` followed by `createDB.R`.
