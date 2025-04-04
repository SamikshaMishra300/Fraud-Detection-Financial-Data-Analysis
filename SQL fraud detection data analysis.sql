SHOW DATABASES;
USE bank;
SHOW TABLES;
SELECT * FROM transactions

-- 1. Detecting Recursive Fradulent Transactions

SET SESSION sql_mode='';

WITH RECURSIVE fraud_chain as (
SELECT nameOrig as initial_account,
nameDest as next_account,
step,
amount,
newbalanceorig
FROM 
transactions
WHERE isFraud = 1 and type = 'TRANSFER'

UNION ALL 

SELECT fc.initial_account,
t.nameDest,t.step,t.amount ,t.newbalanceorig
FROM fraud_chain fc
JOIN transactions t
ON fc.next_account = t.nameorig and fc.step < t.step 
where t.isfraud = 1 and t.type = 'TRANSFER')

SELECT * FROM fraud_chain;



with rolling_fraud as (SELECT nameorig,step,
SUM(isfraud) OVER (PARTITION BY nameorig order by step ROWS BETWEEN 4 PRECEDING and CURRENT ROW) AS fraud_rolling
FROM transactions)

SELECT * FROM rolling_fraud
WHERE fraud_rolling> 0


-- 3. Complex fraud Detection Using Multiple CTEs
-- Question:
-- Use multiple CTEs to identity accounts with suspicious activity , including large transfers, consecutive transactions without balance change, and flagged transactions.

SET SESSION sql_mode='';

SELECT 
	lt.nameorig
FROM
    (SELECT nameorig, step, amount
     FROM transactions 
     WHERE type = 'TRANSFER' AND amount > 500000) AS lt

JOIN 
    (SELECT nameorig, step, oldbalanceOrg, newbalanceOrig
     FROM transactions 
     WHERE oldbalanceOrg = newbalanceOrig) AS nbc 
     ON lt.nameorig = nbc.nameorig AND lt.step = nbc.step

JOIN 
    (SELECT nameOrig, step
     FROM transactions 
     WHERE isFlaggedFraud = 1) AS ft 
     ON lt.nameorig = ft.nameorig AND lt.step = ft.step;



    
-- 4. Write me a query that checks if the computed new_updated_Balance is the actual newbalancedest in the table. if they equal, it returns those rows

with CTE as (
SELECT amount,nameorig,oldbalancedest,newbalanceDest,(amount+oldbalancedest) as new_updated_Balance 
FROM transactions
)
SELECT * FROM CTE where new_updated_Balance = newbalanceDest;