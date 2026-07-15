-- Nivell 1 
-- Exercici 1

-- Creación del Silver Dataset 
CREATE SCHEMA IF NOT EXISTS `sprint3-analytics-vanero.sprint3_silver`
OPTIONS (
  location = 'EU'
);

-- Creación del Gold Dataset (Cloud Shell)
bq mk --dataset --location=EU sprint3-analytics-vanero:sprint3_gold


-- Exercici 2
-- Creación tabla externa transactions_raw

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-vanero.sprint3_bronze.transactions_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';',
  skip_leading_rows = 1
);

-- Comprobación de datos de archivos CSV en Cloud Shell

gsutil cat gs://bootcamp-data-analytics-public/CRM/credit_cards.csv | head -n 5
gsutil cat gs://bootcamp-data-analytics-public/CRM/american_users.csv | head -n 5
gsutil cat gs://bootcamp-data-analytics-public/CRM/european_users.csv | head -n 5

-- Creación tabla externa companies_raw

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-vanero.sprint3_bronze.companies_raw` (
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1  
);

-- Creación tablas externas american-users_raw, european_users_raw, credit_cards_raw

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-vanero.sprint3_bronze.american_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-vanero.sprint3_bronze.european_users_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-vanero.sprint3_bronze.credit_cards_raw`
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1
); 

-- Exercici 4
-- SQL script generado por IA para la creación de transactions_raw_native

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_bronze.transactions_raw_native` AS
SELECT *
FROM
  `sprint3-analytics-vanero.sprint3_bronze.transactions_raw`;
  
-- Código para revisión comparativa de uso entre tablas nativa y externa

SELECT id
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw`;

SELECT id
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw_native`;

-- Código para revisión de uso de LIMIT

SELECT id
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw_native`
LIMIT 10;

-- Consulta Limit2: tabla nativa
SELECT id
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw_native`
LIMIT 10;

-- Exercici 5
-- Comprobación de formato de columna "timestamp" en tabla "transactions_raw_native"

SELECT 
  MIN(timestamp) AS min_timestamp,
  MAX(timestamp) AS max_timestamp
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw`;

-- Ejecución exercici 5: "5 dias con más ventas de 2021"

SELECT
  DATE(timestamp) AS transaction_date,
  ROUND(SUM(amount), 2) AS total_income
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw_native`
WHERE EXTRACT(YEAR FROM  DATE(timestamp)) = 2021
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Exercici 6
-- Consultas complejas

SELECT
  c.company_name,
  c.country,
  DATE(t.timestamp) AS t_date
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw_native` AS t
JOIN `sprint3-analytics-vanero.sprint3_bronze.companies_raw` AS c
  ON t.business_id = c.company_id
WHERE DATE(t.timestamp) IN ("2015-04-29", "2018-07-20", "2024-03-13")
  AND t.amount BETWEEN 100 AND 200;

-- Nivell 2  

-- Exercici 1
-- Creación tabla products_clean (silver)

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  SAFE_CAST(SUBSTR(warehouse_id, 4) AS INT64) AS warehouse_id,
  SAFE_CAST(price AS FLOAT64) AS price,
  weight,
FROM `sprint3-analytics-vanero.sprint3_bronze.products_raw`;

-- Exercici 2
-- Creación de tabla transactions_clean (silver)

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  timestamp,
  IFNULL (SAFE_CAST(amount AS FLOAT64), 0) AS amount,
    declined,
  ARRAY(
    SELECT SAFE_CAST(TRIM(product_id_text) AS INT64)
    FROM UNNEST(SPLIT(product_ids, ',')) AS product_id_text
  ) AS product_ids,
  user_id,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-vanero.sprint3_bronze.transactions_raw`;

-- Exercici 3
-- Creación tabla users_combined (silver)

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_silver.users_combined` AS
SELECT
  id AS user_id,
  * EXCEPT (id),
  'american' AS origin
FROM `sprint3-analytics-vanero.sprint3_bronze.american_users_raw`

UNION ALL

SELECT
  id AS user_id,
  * EXCEPT (id),
  'european' AS origin
FROM `sprint3-analytics-vanero.sprint3_bronze.european_users_raw`;
 
-- Exercici 4 
-- Creación de tablas companies:clean y credit_cards_clean 

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_silver.companies_clean` AS
SELECT *
FROM `sprint3-analytics-vanero.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_silver.credit_cards_clean` AS
SELECT 
  * EXCEPT (id),
  id AS card_id
FROM `sprint3-analytics-vanero.sprint3_bronze.credit_cards_raw`; 


-- AlterTable transactions_clean

ALTER TABLE `sprint3-analytics-vanero.sprint3_silver.transactions_clean`
RENAME COLUMN business_id TO company_id;

-- Nivell 3

-- Exercici 1
-- Vista Marketing y consulta clasificada

CREATE OR REPLACE VIEW `sprint3-analytics-vanero.sprint3_gold.v_marketing_kpis` AS
SELECT 
  c.company_name,
  c.phone,
  c.country,
  ROUND(AVG(t.amount), 2) as avg_amount,
  CASE
    WHEN AVG(t.amount) > 250 THEN "premium"
    ELSE "standard"
  END AS client_tier
FROM `sprint3-analytics-vanero.sprint3_silver.companies_clean`AS c
JOIN `sprint3-analytics-vanero.sprint3_silver.transactions_clean`AS t
  ON c.company_id = t.company_id
WHERE t.declined = 0
GROUP BY
  c.company_id,
  c.company_name,
  c.phone,
  c.country;


SELECT *
FROM `sprint3-analytics-vanero.sprint3_gold.v_marketing_kpis`
ORDER BY
  client_tier,
  avg_amount DESC;

-- Exercici 2  
-- Update de la tabla "products_clean" con todos los campos

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  SAFE_CAST(price AS FLOAT64) AS price,
  colour,
  weight,
  SAFE_CAST(SUBSTR(warehouse_id, 4) AS INT64) AS warehouse_id,
  category,
  brand,
  cost,
  launch_date
FROM `sprint3-analytics-vanero.sprint3_bronze.products_raw`;

-- Consulta final y visualilzación de resultados

CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_gold.product_sales_ranking` AS
WITH array_products AS (
  SELECT
    product_id
  FROM `sprint3-analytics-vanero.sprint3_silver.transactions_clean` AS t,
  UNNEST(t.product_ids) AS product_id
)
SELECT
  p.product_id,
  p.name,
  ROUND(p.price, 2) AS price
  p.colour,
  COUNT(ap.product_id) AS total_sold
FROM `sprint3-analytics-vanero.sprint3_silver.products_clean` AS p
LEFT JOIN array_products AS ap
  ON p.product_id = ap.product_id
GROUP BY
  p.product_id,
  p.name,
  p.price,
  p.colour
ORDER BY total_sold DESC;


SELECT *
FROM `sprint3-analytics-vanero.sprint3_gold.product_sales_ranking`
LIMIT 10;

-- Exercici 3
-- Consulta para descargar la tabla Top Productes


SELECT *
FROM `sprint3-analytics-vanero.sprint3_gold.product_sales_ranking`
ORDER BY total_sold DESC;