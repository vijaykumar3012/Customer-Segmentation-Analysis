-- ============================================================
-- BANKING CUSTOMER & TRANSACTION ANALYTICS
-- MySQL 8.0+ (uses window functions, CTEs)
-- ============================================================
-- Sections:
--   1. Schema (customers, accounts, branches, transactions)
--   2. Sample data
--   3. Analytics queries (customer, transaction, risk/churn)
-- ============================================================

CREATE DATABASE IF NOT EXISTS bank_analytics;
USE bank_analytics;

-- ------------------------------------------------------------
-- 1. SCHEMA
-- ------------------------------------------------------------

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS branches;

CREATE TABLE branches (
    branch_id       INT PRIMARY KEY AUTO_INCREMENT,
    branch_name     VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(100) NOT NULL
);

CREATE TABLE customers (
    customer_id     INT PRIMARY KEY AUTO_INCREMENT,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    date_of_birth   DATE,
    gender          ENUM('M','F','Other'),
    city            VARCHAR(100),
    customer_segment ENUM('Retail','Premium','Corporate') DEFAULT 'Retail',
    join_date       DATE NOT NULL
);

CREATE TABLE accounts (
    account_id      INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    branch_id       INT NOT NULL,
    account_type    ENUM('Savings','Current','Fixed Deposit') NOT NULL,
    account_status  ENUM('Active','Dormant','Closed') DEFAULT 'Active',
    open_date       DATE NOT NULL,
    balance         DECIMAL(15,2) DEFAULT 0.00,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

CREATE TABLE transactions (
    transaction_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    account_id          INT NOT NULL,
    transaction_date    DATETIME NOT NULL,
    transaction_type    ENUM('Deposit','Withdrawal','Transfer','Payment','Fee') NOT NULL,
    channel             ENUM('ATM','Branch','Online','Mobile','POS') NOT NULL,
    amount              DECIMAL(15,2) NOT NULL,
    balance_after        DECIMAL(15,2) NOT NULL,
    merchant_category   VARCHAR(50),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id),
    INDEX idx_txn_date (transaction_date),
    INDEX idx_txn_account (account_id)
);

-- ------------------------------------------------------------
-- 2. SAMPLE DATA
-- ------------------------------------------------------------

INSERT INTO branches (branch_name, city, state) VALUES
('MG Road Branch', 'Chennai', 'Tamil Nadu'),
('Anna Nagar Branch', 'Chennai', 'Tamil Nadu'),
('Koramangala Branch', 'Bengaluru', 'Karnataka'),
('Andheri Branch', 'Mumbai', 'Maharashtra');

INSERT INTO customers (first_name, last_name, email, date_of_birth, gender, city, customer_segment, join_date) VALUES
('Arjun','Kumar','arjun.kumar@mail.com','1990-05-12','M','Chennai','Premium','2021-01-15'),
('Divya','Rao','divya.rao@mail.com','1988-11-02','F','Chennai','Retail','2020-06-20'),
('Rahul','Singh','rahul.singh@mail.com','1995-03-25','M','Bengaluru','Retail','2022-02-10'),
('Priya','Nair','priya.nair@mail.com','1992-08-14','F','Mumbai','Corporate','2019-09-05'),
('Karthik','Iyer','karthik.iyer@mail.com','1985-01-30','M','Chennai','Premium','2018-04-01'),
('Sneha','Patel','sneha.patel@mail.com','1998-07-19','F','Mumbai','Retail','2023-03-11'),
('Vijay','Menon','vijay.menon@mail.com','1993-12-05','M','Bengaluru','Retail','2021-11-22'),
('Anjali','Gupta','anjali.gupta@mail.com','1991-06-08','F','Chennai','Corporate','2017-08-17');

INSERT INTO accounts (customer_id, branch_id, account_type, account_status, open_date, balance) VALUES
(1, 1, 'Savings', 'Active', '2021-01-15', 152000.00),
(1, 1, 'Fixed Deposit', 'Active', '2022-01-10', 500000.00),
(2, 2, 'Savings', 'Active', '2020-06-20', 34500.00),
(3, 3, 'Savings', 'Active', '2022-02-10', 12000.00),
(4, 4, 'Current', 'Active', '2019-09-05', 890000.00),
(5, 1, 'Savings', 'Dormant', '2018-04-01', 5000.00),
(6, 4, 'Savings', 'Active', '2023-03-11', 21000.00),
(7, 3, 'Current', 'Active', '2021-11-22', 67000.00),
(8, 1, 'Fixed Deposit', 'Active', '2017-08-17', 1200000.00);

-- Representative transactions across several months for pattern analysis
INSERT INTO transactions (account_id, transaction_date, transaction_type, channel, amount, balance_after, merchant_category) VALUES
(1, '2026-05-02 09:15:00', 'Deposit', 'Branch', 20000.00, 172000.00, NULL),
(1, '2026-05-10 14:22:00', 'Withdrawal', 'ATM', 5000.00, 167000.00, NULL),
(1, '2026-06-01 11:00:00', 'Payment', 'Online', 3200.00, 163800.00, 'Utilities'),
(1, '2026-06-18 19:45:00', 'Payment', 'Mobile', 1500.00, 162300.00, 'Food & Dining'),
(1, '2026-07-05 08:30:00', 'Transfer', 'Online', 40000.00, 122300.00, NULL),
(1, '2026-07-22 16:10:00', 'Deposit', 'Branch', 30000.00, 152300.00, NULL),
(2, '2026-05-14 10:05:00', 'Withdrawal', 'ATM', 2000.00, 32500.00, NULL),
(2, '2026-06-09 13:40:00', 'Payment', 'POS', 1800.00, 30700.00, 'Shopping'),
(2, '2026-07-01 09:00:00', 'Deposit', 'Mobile', 6000.00, 36700.00, NULL),
(2, '2026-07-19 20:15:00', 'Payment', 'Mobile', 2200.00, 34500.00, 'Food & Dining'),
(3, '2026-05-20 12:00:00', 'Deposit', 'Branch', 5000.00, 17000.00, NULL),
(3, '2026-06-25 17:30:00', 'Withdrawal', 'ATM', 3000.00, 14000.00, NULL),
(3, '2026-07-12 09:20:00', 'Payment', 'Online', 2000.00, 12000.00, 'Entertainment'),
(4, '2026-05-05 10:00:00', 'Transfer', 'Online', 150000.00, 740000.00, NULL),
(4, '2026-05-30 15:00:00', 'Deposit', 'Branch', 300000.00, 1040000.00, NULL),
(4, '2026-06-15 11:30:00', 'Payment', 'Online', 45000.00, 995000.00, 'Business'),
(4, '2026-07-10 09:45:00', 'Withdrawal', 'Branch', 105000.00, 890000.00, NULL),
(6, '2026-06-02 08:50:00', 'Deposit', 'Mobile', 10000.00, 31000.00, NULL),
(6, '2026-06-28 18:00:00', 'Payment', 'POS', 4500.00, 26500.00, 'Shopping'),
(6, '2026-07-15 21:00:00', 'Payment', 'Mobile', 5500.00, 21000.00, 'Food & Dining'),
(7, '2026-05-18 09:30:00', 'Deposit', 'Branch', 20000.00, 87000.00, NULL),
(7, '2026-06-20 14:00:00', 'Transfer', 'Online', 15000.00, 72000.00, NULL),
(7, '2026-07-08 10:15:00', 'Payment', 'Online', 5000.00, 67000.00, 'Utilities'),
(8, '2026-05-01 09:00:00', 'Deposit', 'Branch', 200000.00, 1400000.00, NULL),
(8, '2026-06-01 09:00:00', 'Withdrawal', 'Branch', 200000.00, 1200000.00, NULL);

-- ============================================================
-- 3. ANALYTICS QUERIES
-- ============================================================

-- 3.1 Customer 360: total balance, account count, txn count per customer
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.customer_segment,
    COUNT(DISTINCT a.account_id) AS num_accounts,
    SUM(a.balance) AS total_balance,
    COUNT(t.transaction_id) AS total_transactions
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY c.customer_id, customer_name, c.customer_segment
ORDER BY total_balance DESC;

-- 3.2 Monthly transaction volume & value trend
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
    transaction_type,
    COUNT(*) AS txn_count,
    SUM(amount) AS total_amount,
    ROUND(AVG(amount), 2) AS avg_amount
FROM transactions
GROUP BY txn_month, transaction_type
ORDER BY txn_month, transaction_type;

-- 3.3 Channel preference by customer segment
SELECT
    c.customer_segment,
    t.channel,
    COUNT(*) AS txn_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY c.customer_segment), 1) AS pct_of_segment
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
GROUP BY c.customer_segment, t.channel
ORDER BY c.customer_segment, txn_count DESC;

-- 3.4 RFM-style customer segmentation (Recency, Frequency, Monetary)
WITH rfm_base AS (
    SELECT
        a.customer_id,
        DATEDIFF('2026-08-16', MAX(t.transaction_date)) AS recency_days,
        COUNT(t.transaction_id) AS frequency,
        SUM(t.amount) AS monetary
    FROM accounts a
    JOIN transactions t ON t.account_id = a.account_id
    GROUP BY a.customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,   -- lower recency_days = better = higher score
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
    r.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    r.recency_days,
    r.frequency,
    r.monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Champion'
        WHEN (r_score + f_score + m_score) >= 7  THEN 'Loyal'
        WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk'
        ELSE 'Dormant/Low Value'
    END AS rfm_segment
FROM rfm_scored r
JOIN customers c ON c.customer_id = r.customer_id
ORDER BY rfm_total DESC;

-- 3.5 Dormant / churn-risk accounts (no transactions in last 45 days, or status flagged)
SELECT
    a.account_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_type,
    a.account_status,
    a.balance,
    MAX(t.transaction_date) AS last_txn_date,
    DATEDIFF('2026-08-16', MAX(t.transaction_date)) AS days_since_last_txn
FROM accounts a
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY a.account_id, customer_name, a.account_type, a.account_status, a.balance
HAVING days_since_last_txn > 45 OR days_since_last_txn IS NULL OR a.account_status = 'Dormant'
ORDER BY days_since_last_txn DESC;

-- 3.6 High-value / large transaction flags (simple anomaly screen: > 3x account's own avg txn)
WITH acct_avg AS (
    SELECT account_id, AVG(amount) AS avg_amount, STDDEV(amount) AS std_amount
    FROM transactions
    GROUP BY account_id
)
SELECT
    t.transaction_id,
    t.account_id,
    t.transaction_date,
    t.transaction_type,
    t.channel,
    t.amount,
    aa.avg_amount,
    ROUND(t.amount / NULLIF(aa.avg_amount, 0), 2) AS times_above_avg
FROM transactions t
JOIN acct_avg aa ON aa.account_id = t.account_id
WHERE t.amount > 3 * aa.avg_amount
ORDER BY times_above_avg DESC;

-- 3.7 Branch-level performance: total balances managed & transaction throughput
SELECT
    br.branch_name,
    br.city,
    COUNT(DISTINCT a.account_id) AS num_accounts,
    SUM(a.balance) AS total_balance_managed,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(SUM(t.amount), 2) AS total_transaction_value
FROM branches br
JOIN accounts a ON a.branch_id = br.branch_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY br.branch_id, br.branch_name, br.city
ORDER BY total_balance_managed DESC;

-- 3.8 Running balance trend per account (window function)
SELECT
    account_id,
    transaction_date,
    transaction_type,
    amount,
    balance_after,
    LAG(balance_after) OVER (PARTITION BY account_id ORDER BY transaction_date) AS prev_balance,
    balance_after - LAG(balance_after) OVER (PARTITION BY account_id ORDER BY transaction_date) AS balance_change
FROM transactions
ORDER BY account_id, transaction_date;

-- 3.9 Top spending categories per customer segment
SELECT
    c.customer_segment,
    t.merchant_category,
    COUNT(*) AS txn_count,
    SUM(t.amount) AS total_spent
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
WHERE t.transaction_type = 'Payment' AND t.merchant_category IS NOT NULL
GROUP BY c.customer_segment, t.merchant_category
ORDER BY c.customer_segment, total_spent DESC;

-- 3.10 New customer acquisition trend by month
SELECT
    DATE_FORMAT(join_date, '%Y-%m') AS join_month,
    COUNT(*) AS new_customers
FROM customers
GROUP BY join_month
ORDER BY join_month;