

Use ecomm;

Set SQL_SAFE_UPDATES = 0;

-- Impute mean for WarehouseToHome and round to the nearest integer
UPDATE customer_churn 
SET 
    WarehouseToHome = (SELECT 
            CAST(ROUND(avg_val) AS UNSIGNED)
        FROM
            (SELECT 
                AVG(WarehouseToHome) AS avg_val
            FROM
                customer_churn
            WHERE
                WarehouseToHome IS NOT NULL) AS subquery)
WHERE
    WarehouseToHome IS NULL;


-- Impute mean for HourSpendOnApp and round to the nearest integer
UPDATE customer_churn 
SET 
    HourSpendOnApp = (SELECT 
            CAST(ROUND(avg_val) AS UNSIGNED)
        FROM
            (SELECT 
                AVG(HourSpendOnApp) AS avg_val
            FROM
                customer_churn
            WHERE
                HourSpendOnApp IS NOT NULL) AS subquery)
WHERE
    HourSpendOnApp IS NULL;



-- Impute mean for OrderAmountHikeFromlastYear and round to the nearest integer
UPDATE customer_churn 
SET 
    OrderAmountHikeFromlastYear = (SELECT 
            CAST(ROUND(avg_val) AS UNSIGNED)
        FROM
            (SELECT 
                AVG(OrderAmountHikeFromlastYear) AS avg_val
            FROM
                customer_churn
            WHERE
                OrderAmountHikeFromlastYear IS NOT NULL) AS subquery)
WHERE
    OrderAmountHikeFromlastYear IS NULL;


-- Impute mean for DaySinceLastOrder and round to the nearest integer
UPDATE customer_churn 
SET 
    DaySinceLastOrder = (SELECT 
            CAST(ROUND(avg_val) AS UNSIGNED)
        FROM
            (SELECT 
                AVG(DaySinceLastOrder) AS avg_val
            FROM
                customer_churn
            WHERE
                DaySinceLastOrder IS NOT NULL) AS subquery)
WHERE
    DaySinceLastOrder IS NULL;

-- Finding Mode to Impute Tenure
SELECT 
    Tenure, COUNT(*)
FROM
    customer_churn
GROUP BY Tenure
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Calculate mode using user-defined variables
set @tenure_mode = (select Tenure from customer_churn group by Tenure order by count(*) limit 1);

-- Update NULL values in Tenure with the mode
UPDATE customer_churn 
SET 
    Tenure = @tenure_mode
WHERE
    Tenure IS NULL;


-- Finding Mode to Impute CouponUsed
SELECT 
    CouponUsed, COUNT(*)
FROM
    customer_churn
GROUP BY CouponUsed
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Calculate mode using user-defined variables
set @CouponUsed_mode = (select CouponUsed from customer_churn group by CouponUsed order by count(*) limit 1);

-- Update NULL values in CouponUsed with the mode
UPDATE customer_churn 
SET 
    CouponUsed = @CouponUsed_mode
WHERE
    CouponUsed IS NULL;

-- Finding Mode to OrderCount 
SELECT 
    OrderCount, COUNT(*)
FROM
    customer_churn
GROUP BY OrderCount
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Calculate mode using user-defined variables
set @OrderCount_mode = (select OrderCount from customer_churn group by OrderCount order by count(*) limit 1);

-- Update NULL values in OrderCount with the mode
UPDATE customer_churn 
SET 
    OrderCount = @OrderCount_mode
WHERE
    OrderCount IS NULL;


--  Where the 'WarehouseToHome' values are greater than 100 delete the rows   
DELETE FROM customer_churn 
WHERE
    WarehouseToHome > 100;
    
-- Replacing the values in column 'Phone' - 'Mobile Phone'
UPDATE customer_churn 
SET 
    PreferredLoginDevice = REPLACE(PreferredLoginDevice,
        'Phone',
        'Mobile Phone')
WHERE
    PreferredLoginDevice LIKE '%Phone%';

-- ## Replacing the values in column 'Mobile Phone' - its happen 'Mobile Mobile Phone' then 'Mobile Phone' ##
UPDATE customer_churn 
SET 
    PreferredLoginDevice = REPLACE(PreferredLoginDevice,
        'Mobile Mobile Phone',
        'Mobile Phone')
WHERE
    PreferredLoginDevice LIKE '%Phone%';

-- Replacing the values in column 'COD' - 'Cash on Delivery'
UPDATE customer_churn 
SET 
    PreferredPaymentMode = REPLACE(PreferredPaymentMode,
        'COD',
        'Cash on Delivery')
WHERE
    PreferredPaymentMode = 'COD';

-- Replacing the values in column 'CC' - 'Credit Card'
UPDATE customer_churn 
SET 
    PreferredPaymentMode = REPLACE(PreferredPaymentMode,
        'CC',
        'Credit Card')
WHERE
    PreferredPaymentMode = 'CC';

-- Rename the column "PreferedOrderCat" to "PreferredOrderCat"
ALTER TABLE customer_churn
RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;

-- Rename the column "HourSpendOnApp" to "HoursSpentOnApp"
ALTER TABLE customer_churn
RENAME COLUMN HourSpendOnApp to HoursSpentOnApp;

-- Add Column Complaint Received
ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(3);

-- Update Complaint Received Based on Values in Complain
UPDATE customer_churn 
SET 
    ComplaintReceived = CASE
        WHEN Complain = 1 THEN 'Yes'
        ELSE 'No'
    END;

-- Add Column Churn Status
ALTER TABLE customer_churn
ADD COLUMN ChurnStatus VARCHAR(25);

-- Update Churn Status Based on Values in Churn
UPDATE customer_churn 
SET 
    ChurnStatus = CASE
        WHEN Churn = 1 THEN 'Churned'
        ELSE 'Active'
    END;

-- Drop the columns "Churn" and "Complain" from the table
ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- 1. The count of churned and active customers
SELECT 
    ChurnStatus, COUNT(*) AS CustomerCount
FROM
    customer_churn
GROUP BY ChurnStatus;

-- 2.  Average tenure of customers who churned
SELECT 
    AVG(Tenure) AS AverageTenure
FROM
    customer_churn
WHERE
    ChurnStatus = 'Churned';

-- 3.  The total cashback amount earned by customers who churned
SELECT 
    SUM(CashbackAmount) AS TotalCashback
FROM
    customer_churn
WHERE
    ChurnStatus = 'Churned';

-- 4. Percentage of churned customers who complained
SELECT 
    (COUNT(CASE
        WHEN
            ChurnStatus = 'Churned'
                AND ComplaintReceived = 'Yes'
        THEN
            1
    END) / COUNT(CASE
        WHEN ChurnStatus = 'Churned' THEN 1
    END)) * 100 AS PercentageComplained
FROM
    customer_churn;

-- 5. Gender distribution of customers who complained
SELECT 
    Gender, COUNT(*) AS CustomerCount
FROM
    customer_churn
WHERE
    ComplaintReceived = 'Yes'
GROUP BY Gender;

-- 6. Identify the city tier with the highest number of churned customers preferred order category is Laptop & Accessory. give code and comments
SELECT 
    CityTier, COUNT(*) AS ChurnedCustomerCount
FROM
    customer_churn
WHERE
    ChurnStatus = 'Churned'
        AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCustomerCount DESC
LIMIT 1;

-- 7. Identify the most preferred payment mode among active customers
SELECT 
    PreferredPaymentMode, COUNT(*) AS PaymentModeCount
FROM
    customer_churn
WHERE
    ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY PaymentModeCount DESC
LIMIT 1;

-- 8. List the preferred login device(s) among customers who took more than 10 days since their last order
SELECT DISTINCT
    PreferredLoginDevice
FROM
    customer_churn
WHERE
    DaySinceLastOrder > 10;

-- 9. List the number of active customers who spent more than 3 hours on the app
SELECT 
    COUNT(*) AS ActiveCustomersWhoSpentMoreThan3Hours
FROM
    customer_churn
WHERE
    ChurnStatus = 'Active'
        AND HoursSpentOnApp > 3;

-- 10. Find the average cashback amount received by customers who spent at least 2 hours on the app
SELECT 
    AVG(CashbackAmount) AS AverageCashback
FROM
    customer_churn
WHERE
    HoursSpentOnApp >= 2;

-- 11. Display the maximum hours spent on the app by customers in each preferred order category
SELECT 
    PreferredOrderCat, MAX(HoursSpentOnApp) AS MaxHoursSpent
FROM
    customer_churn
GROUP BY PreferredOrderCat;

-- 12. Find the average order amount hike from last year for customers in each marital status category
SELECT 
    MaritalStatus,
    AVG(OrderAmountHikeFromLastYear) AS AverageOrderAmountHike
FROM
    customer_churn
GROUP BY MaritalStatus;

-- 13. Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
SELECT 
    SUM(OrderAmountHikeFromLastYear) AS TotalOrderAmountHike
FROM
    customer_churn
WHERE
    MaritalStatus = 'Single'
        AND PreferredOrderCat = 'Mobile Phone';

-- 14. Find the average number of devices registered among customers who used UPI as their preferred payment mode
SELECT 
    AVG(NumberOfDeviceRegistered) AS AverageDevicesRegistered
FROM
    customer_churn
WHERE
    PreferredPaymentMode = 'UPI';

-- 15. Determine the city tier with the highest number of customers
SELECT 
    CityTier, COUNT(*) AS CustomerCount
FROM
    customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;

-- 16. Find the marital status of customers with the highest number of addresses
SELECT 
    MaritalStatus, MAX(NumberOfAddress) AS MaxAddresses
FROM
    customer_churn
GROUP BY MaritalStatus
ORDER BY MaxAddresses DESC
LIMIT 1;

-- 17. Identify the gender that utilized the highest number of coupons
SELECT 
    Gender, SUM(CouponUsed) AS TotalCouponsUsed
FROM
    customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

-- List the average satisfaction score in each of the preferred order categories
SELECT 
    PreferredOrderCat,
    AVG(SatisfactionScore) AS AverageSatisfactionScore
FROM
    customer_churn
GROUP BY PreferredOrderCat;

-- 19. Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score
SELECT 
    SUM(OrderCount) AS TotalOrderCount
FROM
    customer_churn
WHERE
    PreferredPaymentMode = 'Credit Card'
        AND SatisfactionScore = (SELECT 
            MAX(SatisfactionScore)
        FROM
            customer_churn);

-- 20. How many customers are there who spent only one hour on the app and days since their last order was more than 5?
SELECT 
    COUNT(*) AS CustomerCount
FROM
    customer_churn
WHERE
    HoursSpentOnApp = 1
        AND DaySinceLastOrder > 5;

-- 21. What is the average satisfaction score of customers who have complained?
SELECT 
    AVG(SatisfactionScore) AS AverageSatisfactionScore
FROM
    customer_churn
WHERE
    ComplaintReceived = 'Yes';

-- 22. How many customers are there in each preferred order category?
SELECT 
    PreferredOrderCat, COUNT(*) AS CustomerCount
FROM
    customer_churn
GROUP BY PreferredOrderCat;

-- 23. What is the average cashback amount received by married customers?
SELECT 
    AVG(CashbackAmount) AS AverageCashback
FROM
    customer_churn
WHERE
    MaritalStatus = 'Married';

-- 24. What is the average number of devices registered by customers who are not using Mobile Phone as their preferred login device?
SELECT 
    AVG(NumberOfDeviceRegistered) AS AverageDevicesRegistered
FROM
    customer_churn
WHERE
    PreferredLoginDevice != 'Mobile Phone';

-- 25. List the preferred order category among customers who used more than 5 coupons
SELECT 
    PreferredOrderCat
FROM
    customer_churn
WHERE
    CouponUsed > 5;

-- 26. List the top 3 preferred order categories with the highest average cashback amount
SELECT 
    PreferredOrderCat, AVG(CashbackAmount) AS AverageCashback
FROM
    customer_churn
GROUP BY PreferredOrderCat
ORDER BY AverageCashback DESC
LIMIT 3;
 
-- 27. Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders
SELECT 
    PreferredPaymentMode
FROM
    customer_churn
WHERE
    Tenure = 10 AND OrderCount > 500;
  
 /* Categorize the WarehouseToHome column into four categories
'Very Close Distance' for distances <= 5km
'Close Distance' for distances <= 10km
'Moderate Distance' for distances <= 15km
'Far Distance' for distances > 15km */
SELECT 
    CASE
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM
    customer_churn
GROUP BY DistanceCategory , ChurnStatus
ORDER BY DistanceCategory , ChurnStatus;


/* Are married (assuming a column like MaritalStatus with the value 'Married').
Live in City Tier-1 (assuming a column like CityTier with a value of '1').
Have order counts greater than the average number of orders placed by all customers */
SELECT 
    *
FROM
    customer_churn
WHERE
    MaritalStatus = 'Married'
        AND CityTier = 1
        AND OrderCount > (SELECT 
            AVG(OrderCount)
        FROM
            customer_churn);

-- Create a ‘customer_returns’ table
CREATE TABLE customer_returns (
    ReturnID INT PRIMARY KEY auto_increment,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10, 2)
);

--  insert the following data in ‘customer_returns’ table
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
    (1001, 50022, '2023-01-01', 2130),
    (1002, 50316, '2023-01-23', 2000),
    (1003, 51099, '2023-02-14', 2290),
    (1004, 52321, '2023-03-08', 2510),
    (1005, 52928, '2023-03-20', 3000),
    (1006, 53749, '2023-04-17', 1740),
    (1007, 54206, '2023-04-21', 3250),
    (1008, 54838, '2023-04-30', 1990);

-- Display the return details along with the customer details of those who have churned and have made complaints
SELECT
    cr.ReturnID,
    cr.CustomerID,
    cr.ReturnDate,
    cr.RefundAmount,
    cc.ChurnStatus
FROM customer_returns cr
JOIN customer_churn cc ON cr.CustomerID = cc.CustomerID
WHERE cc.ChurnStatus = 'Churned';
