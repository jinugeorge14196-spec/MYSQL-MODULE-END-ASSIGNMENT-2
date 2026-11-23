USE ecomm;
SET SQL_SAFE_UPDATES = 0;

-- 1. DATA CLEANING (5 Marks)
DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

SET @mean_wth = (SELECT ROUND(AVG(WarehouseToHome)) FROM customer_churn WHERE WarehouseToHome IS NOT NULL);
UPDATE customer_churn SET WarehouseToHome = @mean_wth WHERE WarehouseToHome IS NULL;

SET @mean_hours = (SELECT ROUND(AVG(HourSpendOnApp)) FROM customer_churn WHERE HourSpendOnApp IS NOT NULL);
UPDATE customer_churn SET HourSpendOnApp = @mean_hours WHERE HourSpendOnApp IS NULL;

SET @mean_hike = (SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) FROM customer_churn WHERE OrderAmountHikeFromlastYear IS NOT NULL);
UPDATE customer_churn SET OrderAmountHikeFromlastYear = @mean_hike WHERE OrderAmountHikeFromlastYear IS NULL;

SET @mean_days = (SELECT ROUND(AVG(DaySinceLastOrder)) FROM customer_churn WHERE DaySinceLastOrder IS NOT NULL);
UPDATE customer_churn SET DaySinceLastOrder = @mean_days WHERE DaySinceLastOrder IS NULL;

SET @mode_tenure = (SELECT Tenure FROM customer_churn WHERE Tenure IS NOT NULL GROUP BY Tenure ORDER BY COUNT(*) DESC LIMIT 1);
UPDATE customer_churn SET Tenure = @mode_tenure WHERE Tenure IS NULL;

SET @mode_coupon = (SELECT CouponUsed FROM customer_churn WHERE CouponUsed IS NOT NULL GROUP BY CouponUsed ORDER BY COUNT(*) DESC LIMIT 1);
UPDATE customer_churn SET CouponUsed = @mode_coupon WHERE CouponUsed IS NULL;

SET @mode_orders = (SELECT OrderCount FROM customer_churn WHERE OrderCount IS NOT NULL GROUP BY OrderCount ORDER BY COUNT(*) DESC LIMIT 1);
UPDATE customer_churn SET OrderCount = @mode_orders WHERE OrderCount IS NULL;

UPDATE customer_churn SET PreferredLoginDevice = 'Mobile Phone' WHERE PreferredLoginDevice = 'Phone';
UPDATE customer_churn SET PreferedOrderCat = 'Mobile Phone' WHERE PreferedOrderCat = 'Mobile';
UPDATE customer_churn
SET PreferredPaymentMode = CASE PreferredPaymentMode
    WHEN 'COD' THEN 'Cash on Delivery'
    WHEN 'CC' THEN 'Credit Card'
    ELSE PreferredPaymentMode
END;

-- 2. DATA TRANSFORMATION (3 Marks)
ALTER TABLE customer_churn
CHANGE COLUMN PreferedOrderCat PreferredOrderCat VARCHAR(20),
CHANGE COLUMN HourSpendOnApp HoursSpentOnApp INT;

ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(5),
ADD COLUMN ChurnStatus VARCHAR(10);

UPDATE customer_churn
SET
    ComplaintReceived = IF(Complain = 1, 'Yes', 'No'),
    ChurnStatus = IF(Churn = 1, 'Churned', 'Active');

ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

SET SQL_SAFE_UPDATES = 1;
-- Q1. Count of churned and active customers
SELECT ChurnStatus, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

-- Q2. Average tenure and total cashback amount of churned customers
SELECT ROUND(AVG(Tenure), 2) AS AverageTenure, SUM(CashbackAmount) AS TotalCashbackAmount
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- Q3. Percentage of churned customers who complained
SELECT ROUND((SUM(CASE WHEN ComplaintReceived = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS ChurnedComplaintPercentage
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- Q4. City tier with highest number of churned customers whose preferred order category is Laptop & Accessory
SELECT CityTier, COUNT(*) AS ChurnedCustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Churned'
  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCustomerCount DESC
LIMIT 1;
-- Q5. Most preferred payment mode among active customers
SELECT PreferredPaymentMode, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY CustomerCount DESC
LIMIT 1;

-- Q6. Total order amount hike from last year for single customers who prefer mobile phones
SELECT SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM customer_churn
WHERE MaritalStatus = 'Single'
  AND PreferredOrderCat = 'Mobile Phone';

-- Q7. Average number of devices registered among customers who used UPI as preferred payment mode
SELECT ROUND(AVG(NumberOfDeviceRegistered), 2) AS AvgDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

-- Q8. City tier with the highest number of customers
SELECT CityTier, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;

-- Q9. Gender that utilized the highest number of coupons
SELECT Gender, SUM(CouponUsed) AS TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

-- Q10. Number of customers and maximum hours spent on the app in each preferred order category
SELECT PreferredOrderCat, COUNT(*) AS CustomerCount, MAX(HoursSpentOnApp) AS MaxHoursSpentOnApp
FROM customer_churn
GROUP BY PreferredOrderCat;

-- Q11. Total order count for customers who prefer credit cards and have maximum satisfaction score
SELECT SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
  AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- Q12. Average satisfaction score of customers who have complained
SELECT ROUND(AVG(SatisfactionScore), 2) AS AvgSatisfactionScore
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

-- Q13. Preferred order category among customers who used more than 5 coupons
SELECT DISTINCT PreferredOrderCat
FROM customer_churn
WHERE CouponUsed > 5;

-- Q14. Top 3 preferred order categories with the highest average cashback amount
SELECT PreferredOrderCat, ROUND(AVG(CashbackAmount), 2) AS AvgCashbackAmount
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgCashbackAmount DESC
LIMIT 3;

-- Q15. Preferred payment modes of customers whose average tenure is 10 months and placed > 500 orders
SELECT PreferredPaymentMode
FROM customer_churn
GROUP BY PreferredPaymentMode
HAVING ROUND(AVG(Tenure)) = 10
   AND SUM(OrderCount) > 500;

-- Q16. Distance category breakdown by churn status
SELECT
    CASE
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, ChurnStatus;

-- Q17. Order details of married customers in City Tier-1 with order count > overall average order count
SELECT *
FROM customer_churn
WHERE MaritalStatus = 'Married'
  AND CityTier = 1
  AND OrderCount > (SELECT AVG(OrderCount) FROM customer_churn);