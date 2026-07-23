-- Nivell 1
-- Exercici 1

SELECT t.*
FROM `sprint3-analytics-vanero.sprint3_silver.transactions_clean` AS t
JOIN `sprint3-analytics-vanero.sprint3_silver.companies_clean` AS c
  ON c.company_id = t.company_id
WHERE country = "Germany"
  AND DATE(timestamp) = "2022-03-12";
  
-- Exercici 2
-- Part 1
CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_silver.transactions_recent`AS
SELECT 
  * EXCEPT (timestamp),
  TIMESTAMP_SUB(
    CURRENT_TIMESTAMP(), 
    INTERVAL CAST(RAND() * 50 AS INT64) DAY
  ) AS timestamp
FROM `sprint3-analytics-vanero.sprint3_silver.transactions_clean`;

-- Part 2
CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized`
PARTITION BY DATE(timestamp)
CLUSTER BY company_id
AS
SELECT *
FROM `sprint3-analytics-vanero.sprint3_silver.transactions_recent`;

-- Exercici 3
-- Part 1 (tabla no optimizada)
SELECT *
FROM `sprint3-analytics-vanero.sprint3_silver.transactions_recent`
WHERE timestamp BETWEEN
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND CURRENT_TIMESTAMP();
  
-- Part 2 (tabla optimizada)
SELECT *
FROM `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized`
WHERE timestamp BETWEEN
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND CURRENT_TIMESTAMP();
  
-- Exercici 4
-- Creación de las vista materializada
CREATE OR REPLACE MATERIALIZED VIEW `sprint3-analytics-vanero.sprint3_gold.mv_daily_sales`AS
SELECT
  DATE(timestamp) AS sales_date,
  SUM(amount) AS total_sales
FROM `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized`
GROUP BY 1;

-- Consulta de la vista materializada
SELECT
  sales_date,
  ROUND(total_sales, 2) AS total_sales
FROM `sprint3-analytics-vanero.sprint3_gold.mv_daily_sales`
ORDER BY 1;

-- Nivel 2

-- Exercici 1
CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_gold.VIP_Stats` AS
WITH VIP_Stats AS (
  SELECT
    t.user_id,
    COUNT(t.transaction_id) AS num_compres,
    ROUND(AVG(t.amount), 2) AS tiquet_mig,
    MAX(t.amount) AS max_compra,
    SUM(t.amount) AS total_gastat
  FROM `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized` AS t
  WHERE t.declined = 0
  GROUP BY t.user_id
  HAVING SUM(t.amount) > 500
)
SELECT
  v.user_id,
  CONCAT(u.name, ' ', u.surname) AS nom_complet,
  u.email,
  v.num_compres,
  v.tiquet_mig,
  v.max_compra,
  v.total_gastat
FROM VIP_Stats AS v
JOIN `sprint3-analytics-vanero.sprint3_silver.users_combined` AS u
  ON v.user_id = u.user_id
ORDER BY v.total_gastat DESC;

-- Exercici 2
WITH compare_sales AS (
  SELECT
    sales_date,
    total_sales,
    LAG(total_sales) OVER (ORDER BY sales_date) AS previous_sales,
  FROM `sprint3-analytics-vanero.sprint3_gold.mv_daily_sales`
)
SELECT
  sales_date,
  ROUND(total_sales, 2) AS total_day_sales,
  ROUND(previous_sales, 2) AS previous_day_sales,
  ROUND(
    SAFE_DIVIDE(total_sales - previous_sales, previous_sales) * 100, 2
  ) AS percentage_change
FROM compare_sales
ORDER BY 1;

-- Exercici 3
SELECT
  sales_date,
  ROUND(total_sales, 2) AS total_daily_sales,
  ROUND(
    SUM(total_sales) OVER (
      PARTITION BY EXTRACT(YEAR FROM sales_date)
      ORDER BY sales_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS accumulated_sales
FROM `sprint3-analytics-vanero.sprint3_gold.mv_daily_sales`
ORDER BY sales_date;

-- Exercici 4
-- Consulta seleccionada
WITH ranked_transactions AS (
  SELECT
    user_id,
    DATE(timestamp) AS transaction_date,
    amount,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY timestamp
    ) AS transaction_number
  FROM `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized`
  QUALIFY transaction_number <= 3
)
SELECT
  rt.user_id,
  CONCAT (u.name, ' ', u.surname) AS full_name,
  u.email,
  MAX(CASE WHEN rt.transaction_number = 3 THEN rt.transaction_date END) AS third_purchase_date,
  MAX(CASE WHEN rt.transaction_number = 3 THEN rt.amount END)     AS third_purchase_amount,
  ROUND(AVG(rt.amount), 2) AS avg_first_three_trans
FROM ranked_transactions as rt
JOIN `sprint3-analytics-vanero.sprint3_silver.users_combined` AS u
  ON u.user_id = rt.user_id
GROUP BY 1,2,3;

-- Consulta descartada con AVG en la función de ventana
WITH ranked_transactions AS (
  SELECT
    user_id,
    DATE(timestamp) AS transaction_date,
    amount,
    AVG(amount) OVER (PARTITION BY user_id) AS avg_first_three,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY timestamp
    ) AS transaction_number
  FROM `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized`
  QUALIFY transaction_number <= 3
)
SELECT
  rt.user_id,
  CONCAT (u.name, ' ', u.surname) AS full_name,
  u.email,
  rt.transaction_date,
  rt.amount,
  ROUND (rt.avg_first_three, 2) AS avg_first_three_trans
FROM ranked_transactions as rt
JOIN `sprint3-analytics-vanero.sprint3_silver.users_combined` AS u
  ON u.user_id = rt.user_id
WHERE rt.transaction_number = 3;
  

-- Nivell 3

-- Exercici 1
CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_gold.dim_transactions_flat` AS
  SELECT
    t.transaction_id,
    DATE(t.timestamp) AS timestamp,
   t.amount AS total_ticket,
    p.product_id AS product_sku,
    p.name AS product_name,
    p.price AS product_price
  FROM `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized` AS t
  CROSS JOIN UNNEST (t.product_ids) AS product_id
  JOIN `sprint3-analytics-vanero.sprint3_silver.products_clean` AS p
    ON CAST(product_id AS INTEGER) = p.product_id
  ORDER BY 1;
  
-- Exercici 2
SELECT
  product_sku,
  product_name,
  COUNT(transaction_id) AS total_sales
FROM `sprint3-analytics-vanero.sprint3_gold.dim_transactions_flat`
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;

-- Exercici 3

-- Función para calcular valor + impuesto
CREATE OR REPLACE FUNCTION `sprint3-analytics-vanero.sprint3_gold.calculate_tax`(
    amount NUMERIC
  )
RETURNS NUMERIC 
AS (ROUND(amount * NUMERIC '1.21',2)
);

-- Nueva tabla para programación
CREATE OR REPLACE TABLE `sprint3-analytics-vanero.sprint3_gold.dim_transactions_flat` AS
  SELECT
    t.transaction_id,
    DATE(t.timestamp) AS timestamp,
    ROUND (t.amount, 2) AS total_ticket,
    p.product_id AS product_sku,
    p.name AS product_name,
    p.price AS product_price,
    `sprint3-analytics-vanero.sprint3_gold.calculate_tax` (
        CAST(p.price AS NUMERIC)) 
        AS product_price_tax_inc
  FROM `sprint3-analytics-vanero.sprint3_gold.fact_transactions_optimized` AS t
  CROSS JOIN UNNEST (t.product_ids) AS product_id
  JOIN `sprint3-analytics-vanero.sprint3_silver.products_clean` AS p
    ON CAST(product_id AS INTEGER) = p.product_id
  ORDER BY 1;