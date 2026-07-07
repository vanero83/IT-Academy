-- Nivel 1

-- Exercici 1
-- A partir dels documents adjunts (estructura_dades i dades_introduir), 
-- importa les dues taules. Mostra les característiques principals de l'esquema creat 
-- i explica les diferents taules i variables que existeixen. 
-- Assegura't d'incloure un diagrama que il·lustri la relació entre les diferents taules i variables.

CREATE DATABASE IF NOT EXISTS transactions;

USE transactions;

DROP TABLE IF EXISTS transactions.company;

CREATE TABLE transactions.company (
	id VARCHAR(100) PRIMARY KEY,
	company_name VARCHAR(100),
	phone VARCHAR(100),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(100)
    );

DROP TABLE IF EXISTS transactions.transaction;

CREATE TABLE transactions.transaction (
	id VARCHAR(100) PRIMARY KEY,
	credit_card_id VARCHAR(100),
	company_id VARCHAR(100), 
	user_id VARCHAR(100),
	lat FLOAT,
	longitude FLOAT,
	timestamp TIMESTAMP,
	amount VARCHAR(100),
	declined BOOLEAN
    );

-- Hacer comprobaciones de PK
    
SELECT company.id, COUNT(*) AS "total_companies_ids"
FROM company
GROUP BY company.id
HAVING COUNT(*) > 1;

SELECT company.*
FROM company
WHERE id IS NULL;

SELECT transaction.id, COUNT(*) AS "total_transactions_ids"
FROM transaction
GROUP BY transaction.id
HAVING COUNT(*) > 1;

SELECT transaction.*
FROM transaction
WHERE id IS NULL;

-- Hacer comprobaciones de FK

SELECT DISTINCT transaction.company_id
FROM transaction
LEFT JOIN company
    ON transaction.company_id = company.id
WHERE company.id IS NULL;

-- Asignar relaciones

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_company
FOREIGN KEY (company_id)
REFERENCES company(id);

-- Exercici 2
-- Utilitzant JOIN realitzaràs les següents consultes:

-- Llistat dels països que estan fent compres

SELECT 
	DISTINCT company.country
FROM company
JOIN transaction
	ON company.id = transaction.company_id
    ;
    
-- Des de quants països es realitzen les compres.

SELECT 
	COUNT(DISTINCT company.country) AS "total_countries"
FROM company
JOIN transaction
	ON company.id = transaction.company_id
    ;

-- Identifica la companyia amb la mitjana més gran de vendes.

SELECT 
	company.company_name, 
    ROUND(AVG(amount), 2) AS "avg_amount"
FROM company
JOIN transaction
	ON company.id = transaction.company_id
GROUP BY company.company_name
HAVING AVG(amount) = (
    SELECT MAX(avg_amount)
    FROM (
        SELECT AVG(amount) AS avg_amount
        FROM company
        JOIN transaction
        ON company.id = transaction.company_id
        GROUP BY company.company_name
    ) AS averages
);

-- Exercici 3
-- Utilitzant només subconsultes (sense utilitzar JOIN):

-- Mostra totes les transaccions realitzades per empreses d'Alemanya 
-- Se contempla "realitzades" como "completadas/efectivas"

SELECT 
	transaction.id 
FROM transaction
WHERE transaction.company_id IN (
	SELECT company.id
    FROM company
    WHERE country = "Germany"
    )
AND transaction.declined = 0
;

-- Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
-- Se contempla "realitzades" como "completadas/efectivas" 
-- La media se ha calculado incluyendo "totes" las transacciones, delcinadas o no

SELECT 
	DISTINCT company.company_name
FROM company
JOIN transaction
	ON company.id = transaction.company_id
WHERE transaction.amount > (
		SELECT AVG(transaction.amount) as "transaction_avg"
		FROM transaction
    )
AND transaction.declined = 0
;

-- Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
-- Se contempla "registradas" como todas las transacciones, declinadas o no.

SELECT 
	company.*
FROM company
WHERE company.id NOT IN (
	SELECT transaction.company_id
    FROM transaction
    WHERE transaction.company_id IS NOT NULL
    )
;

SELECT 
	company.*
FROM company
LEFT JOIN transaction
	ON company.id = transaction.company_id
    WHERE transaction.company_id IS NULL
;


-- Exercici 4
-- La teva tasca és dissenyar i crear una taula anomenada "credit_card" 
-- que emmagatzemi detalls crucials sobre les targetes de crèdit. 
-- La nova taula ha de ser capaç d'identificar de manera única cada targeta i establir 
-- una relació adequada amb les altres dues taules ("transaction" i "company"). 
-- Després de crear la taula serà necessari que ingressis la informació del document 
-- denominat "dades_introduir_credit". Recorda mostrar el diagrama i realitzar una breu descripció d'aquest.

DROP TABLE IF EXISTS transactions.credit_card;

CREATE TABLE transactions.credit_card (
	id VARCHAR(100) PRIMARY KEY,
    iban VARCHAR(200), 
    pan VARCHAR(100), 
    pin VARCHAR(100), 
    cvv VARCHAR(100), 
    expiring_date VARCHAR(100)
    )
;

-- Comprobaciones PK y FK

SELECT credit_card.id, COUNT(*) AS "total_cards_ids"
FROM credit_card
GROUP BY credit_card.id
HAVING COUNT(*) > 1;

SELECT credit_card.*
FROM credit_card
WHERE id IS NULL;

SELECT DISTINCT transaction.credit_card_id
FROM transaction
LEFT JOIN credit_card
    ON transaction.credit_card_id = credit_card.id
WHERE credit_card.id IS NULL;

-- Establecer relaciones

ALTER TABLE `transaction`
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);


-- Exercici 5
-- El departament de Recursos Humans ha identificat un error en el número de compte 
-- associat a la targeta de crèdit amb ID CcU-2938. 
-- La informació que ha de mostrar-se per a aquest registre és: TR323456312213576817699999. 
-- Recorda mostrar que el canvi es va realitzar.

UPDATE credit_card
SET credit_card.iban = "TR323456312213576817699999"
WHERE credit_card.id = "CcU-2938"
;

SELECT credit_card.*
FROM credit_card
WHERE credit_card.id = "CcU-2938"
;

-- Exercici 6
-- En la taula "transaction" ingressa una nova transacció

SELECT credit_card.*
FROM credit_card
WHERE credit_card.id = 'CcU-9999'
;

SELECT company.*
FROM company
WHERE company.id = 'b-9999'
;

INSERT INTO credit_card (id)
VALUES ('CcU-9999');

INSERT INTO company (id)
VALUES ('b-9999');


INSERT INTO transaction (
	id, 
    credit_card_id, 
    company_id, 
    user_id, 
    lat, 
    longitude, 
    amount, 
    declined
    )
VALUES (
	"108B1D1D-5B23-A76C-55EF-C568E49A99DD", 
	"CcU-9999", 
    "b-9999", 
    9999, 
    829.999, 
    -117.999, 
    111.11, 
    0
    )
;

SELECT transaction.*
FROM transaction
WHERE transaction.credit_card_id = 'CcU-9999'
;

-- Exercici 7
-- Des de recursos humans et sol·liciten eliminar la columna "pan" 
-- de la taula credit_card. Recorda mostrar el canvi realitzat.

ALTER TABLE credit_card
DROP COLUMN pan
;

DESCRIBE credit_card;


-- Exercici 8
-- Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, 
-- almenys 4 taules de les quals puguis realitzar les següents consultes:

CREATE DATABASE IF NOT EXISTS exercici_8;

USE exercici_8;

-- Tabla "companies" 

DROP TABLE IF EXISTS exercici_8.companies;

CREATE TABLE exercici_8.companies (
    company_id VARCHAR(150) PRIMARY KEY,
    company_name VARCHAR(150),
    phone VARCHAR(150),
    email VARCHAR(150),
    country VARCHAR(150),
    website VARCHAR(150),
    merchant_category VARCHAR(150),
    merchant_price_position VARCHAR(150)
)
;

LOAD DATA 
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE exercici_8.companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

SELECT companies.* 
FROM companies
LIMIT 10
;

-- Tabla "credit_cards" 

DROP TABLE IF EXISTS exercici_8.credit_cards;

CREATE TABLE exercici_8.credit_cards (
    id VARCHAR(150) PRIMARY KEY,
    user_id VARCHAR(150),
    iban VARCHAR(150),
    pan VARCHAR(150),
    pin VARCHAR(150),
    cvv VARCHAR(150),
    track1 VARCHAR(150),
    track2 VARCHAR(150),
    expiring_date VARCHAR(150),
    card_type VARCHAR(150),
    card_renewal_flag VARCHAR(150)
)
;

LOAD DATA 
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE exercici_8.credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

SELECT credit_cards.* 
FROM credit_cards
LIMIT 10
;

-- Tabla "transactions"

DROP TABLE IF EXISTS exercici_8.transactions;
 
CREATE TABLE exercici_8.transactions (
    id VARCHAR(150) PRIMARY KEY,
    card_id VARCHAR(150),
    business_id VARCHAR(150),
    timestamp VARCHAR(150),
    amount VARCHAR(150),
    declined VARCHAR(150),
    product_ids VARCHAR(150),
    user_id VARCHAR(150),
    lat VARCHAR(150),
    longitude VARCHAR(150),
    discount_amount VARCHAR(150),
    tax_amount VARCHAR(150),
    shipping_amount VARCHAR(150),
    channel VARCHAR(150),
    campaign_id VARCHAR(150),
    device_type VARCHAR(150),
    is_international VARCHAR(150),
    decline_reason VARCHAR(150),
    distance_km VARCHAR(150)
    )
    ;

LOAD DATA 
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE exercici_8.transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

SELECT transactions.* 
FROM transactions
LIMIT 10
;

-- Tabla "total_users" como union de american y european users

DROP TABLE IF EXISTS exercici_8.total_users;

CREATE TABLE exercici_8.total_users (
    id VARCHAR(150) PRIMARY KEY,
    name VARCHAR(150),
    surname VARCHAR(150),
    phone VARCHAR(150),
    email VARCHAR(150),
    birth_date VARCHAR(150),
    country VARCHAR(150),
    city VARCHAR(150),
    postal_code VARCHAR(150),
    address VARCHAR(150),
    signup_date VARCHAR(150),
    user_segment VARCHAR(150),
    income_band VARCHAR(150),
    region VARCHAR(150)
)
;

LOAD DATA 
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/european_users.csv'
INTO TABLE exercici_8.total_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address,
    signup_date,
    user_segment,
    income_band
)
SET total_users.region = "European"
;

LOAD DATA 
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/american_users.csv'
INTO TABLE exercici_8.total_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    id,
    name,
    surname,
    phone,
    email,
    birth_date,
    country,
    city,
    postal_code,
    address,
    signup_date,
    user_segment,
    income_band
)
SET total_users.region = "American"
;

SELECT total_users.*
FROM total_users
LIMIT 10
;

-- Comprobaciones PK

-- PK tabla "total_users"

SELECT total_users.id, COUNT(*) AS "total_users_ids"
FROM total_users
GROUP BY total_users.id
HAVING COUNT(*) > 1;

SELECT total_users.*
FROM total_users
WHERE total_users.id IS NULL;

-- PK tabla "companies"

SELECT companies.company_id, COUNT(*) AS "total_companies_ids"
FROM companies
GROUP BY companies.company_id
HAVING COUNT(*) > 1;

SELECT companies.*
FROM companies
WHERE companies.company_id IS NULL;

-- PK tabla "credit_cards"

SELECT credit_cards.id, COUNT(*) AS "total_credit_cards_ids"
FROM credit_cards
GROUP BY credit_cards.id
HAVING COUNT(*) > 1;

SELECT credit_cards.*
FROM credit_cards
WHERE credit_cards.id IS NULL;

-- PK tabla "transactions"

SELECT transactions.id, COUNT(*) AS "total_transactions_ids"
FROM transactions
GROUP BY transactions.id
HAVING COUNT(*) > 1;

SELECT transactions.*
FROM transactions
WHERE id IS NULL;


-- Comprobaciones FK

SELECT DISTINCT transactions.business_id
FROM transactions
LEFT JOIN companies
    ON transactions.business_id = companies.company_id
WHERE companies.company_id IS NULL;

SELECT DISTINCT transactions.user_id
FROM transactions
LEFT JOIN total_users
    ON transactions.user_id = total_users.id
WHERE total_users.id IS NULL;

SELECT DISTINCT transactions.card_id
FROM transactions
LEFT JOIN credit_cards
    ON transactions.card_id = credit_cards.id
WHERE credit_cards.id IS NULL;


-- Crear relaciones

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_companies
FOREIGN KEY (business_id)
REFERENCES companies(company_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_credit_cards
FOREIGN KEY (card_id)
REFERENCES credit_cards(id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_total_users
FOREIGN KEY (user_id)
REFERENCES total_users(id);


-- Exercici 9
-- Realitza una subconsulta que mostri tots els usuaris amb més de 80 transaccions utilitzant almenys 2 taules. 

SELECT 
	total_users.id, 
    total_users.name
FROM total_users
WHERE total_users.id IN (
	SELECT transactions.user_id
    FROM transactions
    GROUP BY transactions.user_id
    HAVING COUNT(transactions.user_id) > 80
    )
;

-- Exercici_10
-- Mostra la mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd, utilitza almenys 2 taules.

SELECT 
	credit_cards.iban, 
    ROUND(AVG(transactions.amount), 2) AS "avg_amount"
FROM credit_cards
JOIN transactions 
	ON credit_cards.id = transactions.card_id
JOIN companies
	ON companies.company_id = transactions.business_id
WHERE companies.company_name = "Donec Ltd"
GROUP BY credit_cards.iban
;

-- NIvel 2

-- Exercici 1
-- Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
-- Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT 
	DATE(transactions.timestamp) AS "exact_day", 
    ROUND(SUM(transactions.amount), 2) AS "total_amount"
FROM transactions
GROUP BY DATE(transactions.timestamp)
ORDER BY SUM(transactions.amount) DESC
LIMIT 5
;

-- Exercici 2
-- Presenta el nom, telèfon, país, data i amount, d'aquelles empreses 
-- que van realitzar transaccions amb un valor comprès entre 350 i 400 euros 
-- i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
-- Ordena els resultats de major a menor quantitat. (CAMBIAR IN)

SELECT 
	companies.company_name, 
    companies.phone, 
    companies.country, 
    DATE(transactions.timestamp) AS "date", 
    ROUND(transactions.amount, 2)
FROM companies
JOIN transactions
	ON transactions.business_id = companies.company_id
WHERE (transactions.amount BETWEEN 350 AND 400) 
	AND (DATE(transactions.timestamp) IN ("2015-04-29", "2018-07-20", "2024-03-13"))
ORDER BY transactions.amount DESC
;

-- Exercici 3
-- Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, 
-- per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, 
-- però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis 
-- si tenen igual o més de 400 transaccions o menys.

SELECT
	companies.company_name,
	COUNT(transactions.id) AS "total_transactions",
CASE
	WHEN COUNT(transactions.id) < 400 THEN "below_400"
    ELSE "plus_400"
END AS "total_trans_category"
FROM transactions
JOIN companies
	ON transactions.business_id = companies.company_id
GROUP BY companies.company_id, companies.company_name
ORDER BY COUNT(transactions.id)
;

-- Exercici 4
-- Elimina de la taula transaction el registre amb 
-- ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

SELECT transactions.*
FROM transactions
WHERE transactions.id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD"
;

DELETE FROM transactions
WHERE transactions.id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD"
;

SELECT transactions.*
FROM transactions
WHERE transactions.id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD"
;

-- Exercici 5 DECLINED 0
-- La secció de màrqueting desitja tenir accés a informació específica per a realitzar 
-- anàlisi i estratègies efectives. S'ha sol·licitat crear una vista que proporcioni detalls clau 
-- sobre les companyies i les seves transaccions. Serà necessària que creïs una vista anomenada 
-- VistaMarketing que contingui la següent informació: Nom de la companyia. Telèfon de contacte. 
-- País de residència. Mitjana de compra realitzat per cada companyia. Presenta la vista creada, 
-- ordenant les dades de major a menor mitjana de compra.

CREATE VIEW VistaMarketing AS
SELECT 
	companies.company_name, 
    companies.phone, 
    companies.country, 
    ROUND(AVG(transactions.amount), 2) "avg_amount"
FROM companies
JOIN transactions
	ON companies.company_id = transactions.business_id
WHERE transactions.declined = 0
GROUP BY 
	companies.company_id,
    companies.company_name, 
    companies.phone, 
    companies.country
;

SELECT VistaMarketing.*
FROM VistaMarketing
ORDER BY VistaMarketing.avg_amount DESC
;


-- Nivel 3

-- Exercici 1
-- Crea una nova taula que reflecteixi l'estat de les targetes de crèdit 
-- basat en si les tres últimes transaccions han estat declinades aleshores és inactiu, 
-- si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:

-- Quantes targetes estan actives?
-- subconsulta cardid, declined, rownumber(evitar doble subconsulta) 4995

DROP TABLE IF EXISTS exercici_8.credit_card_status;

CREATE TABLE credit_card_status AS
SELECT 
    case_transaction.card_id,
    CASE 
        WHEN SUM(case_transaction.declined) = 3 THEN 'inactive'
        ELSE 'active'
    END AS card_status
FROM (
    SELECT 
        transactions.card_id,
        transactions.declined,
        ROW_NUMBER() OVER (
            PARTITION BY transactions.card_id  
            ORDER BY transactions.timestamp DESC
        ) AS last_transaction
    FROM transactions
) AS case_transaction
WHERE case_transaction.last_transaction <= 3
GROUP BY case_transaction.card_id;

SELECT COUNT(card_status) AS "active_credit_card"
FROM credit_card_status
WHERE credit_card_status.card_status = "active"
;

-- Exercici 2
-- Crea una taula amb la qual puguem unir les dades de l'arxiu de products.csv 
-- amb la base de dades creada (ja que fins ara no podíem fer-ho), 
-- tenint en compte que des de transaction tens product_ids. Genera la següent consulta:

-- Necessitem conèixer el nombre de vegades que s'ha venut cada producte.

-- Tabla "products"

DROP TABLE IF EXISTS exercici_8.products;
 
CREATE TABLE exercici_8.products (
    id VARCHAR(150) PRIMARY KEY,
    product_name VARCHAR(150),
    price VARCHAR(150),
    colour VARCHAR(150),
    weight VARCHAR(150),
    warehouse_id VARCHAR(150),
    category VARCHAR(150),
    brand VARCHAR(150),
    cost VARCHAR(150),
    launch_date VARCHAR(150)
    )
    ;
    
LOAD DATA 
INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE exercici_8.products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

SELECT products.* 
FROM products
LIMIT 10
;

-- Comprobar PK y FK

SELECT products.id, COUNT(*)
FROM products
GROUP BY products.id
HAVING COUNT(*) > 1;

SELECT products.*
FROM products
WHERE products.id IS NULL;

SELECT DISTINCT transactions.product_ids
FROM transactions
LEFT JOIN products
    ON transactions.product_ids = products.id
WHERE products.id IS NULL;


-- Creación tabla puente

DROP TABLE IF EXISTS exercici_8.trans_product;

CREATE TABLE trans_product AS
	SELECT 
		transactions.id AS "transaction_id",
		TRIM(single_product.value) AS "product_id"
	FROM transactions
	JOIN JSON_TABLE(
		CONCAT('["', REPLACE(transactions.product_ids, ',', '","'), '"]'),
		'$[*]' COLUMNS (value VARCHAR(100) PATH '$')
	) AS single_product
;

SELECT trans_product.*
FROM trans_product
LIMIT 10
;

-- Establecimiento de relaciones, PK y FK

ALTER TABLE trans_product
ADD CONSTRAINT fk_trans_product_transactions
FOREIGN KEY (transaction_id)
REFERENCES transactions(id);

ALTER TABLE trans_product
ADD CONSTRAINT fk_trans_product_product
FOREIGN KEY (product_id)
REFERENCES products(id);


-- total ventas por producto

SELECT 
	trans_product.product_id, 
	products.product_name, 
    COUNT(DISTINCT trans_product.transaction_id) AS "total_sells"
FROM trans_product
JOIN products
	ON trans_product.product_id = products.id
GROUP BY trans_product.product_id, products.product_name
ORDER BY COUNT(DISTINCT trans_product.transaction_id) DESC;

