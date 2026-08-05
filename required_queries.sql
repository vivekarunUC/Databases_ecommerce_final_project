
-- Query 1: List active products that currently have inventory.
SELECT ProductID, Name, Category, Price, StockQuantity
FROM Product
WHERE IsActive = 1 AND StockQuantity > 0
ORDER BY Category, Name;

-- Query 2: Multi-table query showing customers and products purchased
-- where the recorded unit price is greater than $100.
SELECT
    c.FirstName || ' ' || c.LastName AS CustomerName,
    p.Name AS ProductName,
    pi.Quantity,
    pi.UnitPrice,
    pu.PurchaseDate
FROM Customer AS c
JOIN Purchase AS pu ON c.CustomerID = pu.CustomerID
JOIN PurchaseItem AS pi ON pu.PurchaseID = pi.PurchaseID
JOIN Product AS p ON pi.ProductID = p.ProductID
WHERE pi.UnitPrice > 100
ORDER BY pu.PurchaseDate;

-- Query 3: Show total sales and units sold by product.
SELECT
    p.ProductID,
    p.Name,
    COALESCE(SUM(pi.Quantity), 0) AS UnitsSold,
    ROUND(COALESCE(SUM(pi.Quantity * pi.UnitPrice), 0), 2) AS SalesRevenue
FROM Product AS p
LEFT JOIN PurchaseItem AS pi ON p.ProductID = pi.ProductID
LEFT JOIN Purchase AS pu ON pi.PurchaseID = pu.PurchaseID
    AND pu.Status <> 'Cancelled'
GROUP BY p.ProductID, p.Name
ORDER BY SalesRevenue DESC;

-- Query 4: Show each customer and the value of completed/non-cancelled purchases.
SELECT
    c.CustomerID,
    c.FirstName || ' ' || c.LastName AS CustomerName,
    COUNT(pu.PurchaseID) AS PurchaseCount,
    ROUND(COALESCE(SUM(pu.TotalAmount), 0), 2) AS LifetimeValue
FROM Customer AS c
LEFT JOIN Purchase AS pu ON c.CustomerID = pu.CustomerID
    AND pu.Status <> 'Cancelled'
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY LifetimeValue DESC;

-- Query 5: Find products that should be restocked.
SELECT ProductID, Name, Category, StockQuantity
FROM Product
WHERE IsActive = 1 AND StockQuantity < 10
ORDER BY StockQuantity ASC;
