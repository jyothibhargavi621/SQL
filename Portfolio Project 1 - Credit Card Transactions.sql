-- SQL porfolio project.
-- download credit card transactions dataset from below link :
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
-- import the dataset in sql server with table name : credit_card_transcations
-- change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
-- (alternatively you can use the dataset present in zip file)
-- while importing make sure to change the data types of columns. by defualt it shows everything as varchar.

-- write 4-6 queries to explore the dataset and put your findings 

-- solve below questions
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
SELECT 
    City,
    SUM(Amount) AS Total_Spend,
    (SUM(Amount) * 100.0 / (SELECT SUM(Amount) FROM credit_card_transcations)) AS Percentage_Contribution
FROM 
    credit_card_transcations
GROUP BY 
    City
ORDER BY 
    Total_Spend DESC
LIMIT 5;
-- 2- write a query to print highest spend month and amount spent in that month for each card type
SELECT 
    Card_Type,
    EXTRACT(MONTH FROM Transaction_Date) AS Month,
    SUM(Amount) AS Total_Spent
FROM 
    credit_card_transcations
GROUP BY 
    Card_Type, EXTRACT(MONTH FROM Transaction_Date)
HAVING 
    SUM(Amount) = (
        SELECT 
            MAX(Monthly_Spend) 
        FROM 
            (SELECT 
                Card_Type,
                EXTRACT(MONTH FROM Transaction_Date) AS Month,
                SUM(Amount) AS Monthly_Spend
            FROM 
                credit_card_transcations
            GROUP BY 
                Card_Type, EXTRACT(MONTH FROM Transaction_Date)
            ) AS Monthly_Spend_By_Card_Type
        WHERE 
            Monthly_Spend_By_Card_Type.Card_Type = credit_card_transcations.Card_Type
    );
-- 3- write a query to print the transaction details(all columns from the table) for each card type when
	-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
WITH Monthly_Spend_By_Card_Type AS (
    SELECT 
        Card_Type,
        EXTRACT(MONTH FROM Transaction_Date) AS Month,
        SUM(Amount) AS Monthly_Spend,
        RANK() OVER (PARTITION BY Card_Type ORDER BY SUM(Amount) DESC) AS Spend_Rank
    FROM 
        credit_card_transcations
    GROUP BY 
        Card_Type, EXTRACT(MONTH FROM Transaction_Date)
)
SELECT 
    Card_Type,
    Month,
    Monthly_Spend AS Total_Spent
FROM 
    Monthly_Spend_By_Card_Type
WHERE 
    Spend_Rank = 1;
-- 4- write a query to find city which had lowest percentage spend for gold card type
WITH Total_Spend_By_City AS (
    SELECT 
        City,
        SUM(CASE WHEN Card_Type = 'Gold' THEN Amount ELSE 0 END) AS Gold_Spend,
        SUM(Amount) AS Total_Spend
    FROM 
        credit_card_transcations
    GROUP BY 
        City
)
SELECT 
    City,
    (Gold_Spend * 100.0 / Total_Spend) AS Percentage_Spend
FROM 
    Total_Spend_By_City
ORDER BY 
    Percentage_Spend ASC
LIMIT 1;
-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
WITH Expense_Summary AS (
    SELECT 
        City,
        MAX(CASE WHEN Amount = Highest_Expense THEN Expense_Type END) AS Highest_Expense_Type,
        MIN(CASE WHEN Amount = Lowest_Expense THEN Expense_Type END) AS Lowest_Expense_Type
    FROM (
        SELECT 
            City,
            Exp_Type,
            SUM(Amount) AS Amount,
            RANK() OVER (PARTITION BY City ORDER BY SUM(Amount) DESC) AS Highest_Rank,
            RANK() OVER (PARTITION BY City ORDER BY SUM(Amount) ASC) AS Lowest_Rank
        FROM 
            credit_card_transcations
        GROUP BY 
            City, Exp_Type
    ) AS Ranked_Expenses
    WHERE 
        Highest_Rank = 1 OR Lowest_Rank = 1
    GROUP BY 
        City
)
SELECT 
    City,
    max(highest_exp_type),
    min(lowest_Exp_Type),
FROM 
    Expense_Summary;
-- 6- write a query to find percentage contribution of spends by females for each expense type
SELECT 
    Exp_Type,
    SUM(CASE WHEN Gender = 'Female' THEN Amount ELSE 0 END) * 100.0 / SUM(Amount) AS Female_Contribution_Percentage
FROM 
    credit_card_transcations
GROUP BY 
    Exp_Type;
-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
WITH Jan_2014 AS (
    SELECT 
        Card_Type,
        Exp_Type,
        SUM(Amount) AS Jan_2014_Spend
    FROM 
        credit_card_transcations
    WHERE 
        EXTRACT(MONTH FROM Transaction_Date) = 1
        AND EXTRACT(YEAR FROM Transaction_Date) = 2014
    GROUP BY 
        Card_Type, Exp_Type
),
Dec_2013 AS (
    SELECT 
        Card_Type,
        Exp_Type,
        SUM(Amount) AS Dec_2013_Spend
    FROM 
        credit_card_transcations
    WHERE 
        EXTRACT(MONTH FROM Transaction_Date) = 12
        AND EXTRACT(YEAR FROM Transaction_Date) = 2013
    GROUP BY 
        Card_Type, Exp_Type
)
SELECT 
    Jan_2014.Card_Type,
    Jan_2014.Exp_Type,
    (Jan_2014.Jan_2014_Spend - Dec_2013_Spend) AS Month_Over_Month_Growth
FROM 
    Jan_2014
JOIN 
    Dec_2013 ON Jan_2014.Card_Type = Dec_2013.Card_Type AND Jan_2014.Exp_Type = Dec_2013.Exp_Type
ORDER BY 
    Month_Over_Month_Growth DESC
LIMIT 1;
-- 8- during weekends which city has highest total spend to total no of transcations ratio 
WITH Weekend_Transactions AS (
    SELECT 
        City,
        COUNT(*) AS Total_Transactions,
        SUM(Amount) AS Total_Spend
    FROM 
        credit_card_transcations
    WHERE 
        EXTRACT(DOW FROM Transaction_Date) IN (6, 0) -- 6 represents Saturday, 0 represents Sunday
    GROUP BY 
        City
)
SELECT 
    City,
    Total_Spend,
    Total_Transactions,
    Total_Spend / Total_Transactions AS Spend_to_Transactions_Ratio
FROM 
    credit_card_Transcations
ORDER BY 
    Spend_to_Transactions_Ratio DESC
LIMIT 1;
-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH City_First_Transaction AS (
    SELECT 
        City,
        MIN(Transaction_Date) AS First_Transaction_Date
    FROM 
        credit_card_transcation
    GROUP BY 
        City
),
City_Transaction_Count AS (
    SELECT 
        City,
        COUNT(*) AS Transaction_Count
    FROM 
        credit_card_transcation
    GROUP BY 
        City
),
City_500th_Transaction AS (
    SELECT 
        c.City,
        MIN(DATEDIFF('day', c.First_Transaction_Date, t.Transaction_Date)) AS Days_To_500th_Transaction)
    FROM 
        City_First_Transaction c
    JOIN 
        credit_card_transcation t ON c.City = t.City
    JOIN 
        City_Transaction_Count cc ON c.City = cc.City
    WHERE 
        cc.Transaction_Count >= 500
    GROUP BY 
        c.City
)
SELECT 
    City,
    Days_To_500th_Transaction
FROM 
    City_500th_Transaction
ORDER BY 
    Days_To_500th_Transaction
LIMIT 1;
-- once you are done with this create a github repo to put that link in your resume. Some example github links:
-- https://github.com/ptyadana/SQL-Data-Analysis-and-Visualization-Projects/tree/master/Advanced%20SQL%20for%20Application%20Development
-- https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/COVID%20Portfolio%20Project%20-%20Data%20Exploration.sql