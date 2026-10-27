
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

CREATE TABLE Customers (
    Customer_ID   INT AUTO_INCREMENT,
    Name          VARCHAR(100) NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    Phone         VARCHAR(15)  NOT NULL,
    City          VARCHAR(50),
    CONSTRAINT pk_customers PRIMARY KEY (Customer_ID),
    CONSTRAINT uq_customers_email UNIQUE (Email),
    CONSTRAINT uq_customers_phone UNIQUE (Phone)
);

CREATE TABLE Products (
    Product_ID    INT AUTO_INCREMENT,
    Product_Name  VARCHAR(100) NOT NULL,
    Category      VARCHAR(50)  NOT NULL,
    Price         DECIMAL(10,2) NOT NULL,
    Stock         INT NOT NULL DEFAULT 0,
    CONSTRAINT pk_products PRIMARY KEY (Product_ID),
    CONSTRAINT uq_products_name UNIQUE (Product_Name),
    CONSTRAINT chk_products_price CHECK (Price > 0),
    CONSTRAINT chk_products_stock CHECK (Stock >= 0)
);

-- 2. ORDERS & ORDER_DETAILS WITH CONSTRAINTS
-- =====================================================
CREATE TABLE Orders (
    Order_ID      INT AUTO_INCREMENT,
    Customer_ID   INT NOT NULL,
    Order_Date    DATE NOT NULL DEFAULT (CURRENT_DATE),
    Total_Amount  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Order_Status  VARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT pk_orders PRIMARY KEY (Order_ID),
    CONSTRAINT fk_orders_customer FOREIGN KEY (Customer_ID)
        REFERENCES Customers (Customer_ID),
    CONSTRAINT chk_orders_total CHECK (Total_Amount >= 0),
    CONSTRAINT chk_orders_status CHECK
        (Order_Status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled'))
);

CREATE TABLE Order_Details (
    Order_Detail_ID INT AUTO_INCREMENT,
    Order_ID        INT NOT NULL,
    Product_ID      INT NOT NULL,
    Quantity        INT NOT NULL,
    Price           DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_order_details PRIMARY KEY (Order_Detail_ID),
    CONSTRAINT fk_od_order FOREIGN KEY (Order_ID)
        REFERENCES Orders (Order_ID) ON DELETE CASCADE,
    CONSTRAINT fk_od_product FOREIGN KEY (Product_ID)
        REFERENCES Products (Product_ID),
    CONSTRAINT uq_od_order_product UNIQUE (Order_ID, Product_ID),
    CONSTRAINT chk_od_quantity CHECK (Quantity > 0),
    CONSTRAINT chk_od_price CHECK (Price >= 0)
);


INSERT INTO Customers (Name, Email, Phone, City) VALUES
('Sharon',  'sharon@example.com',  '9876500001', 'Madurai'),
('Leo',     'leo@example.com',     '9876500002', 'Chennai'),
('Peter',   'peter@example.com',   '9876500003', 'Coimbatore'),
('John',    'john@example.com',    '9876500004', 'Madurai'),
('Antony',  'antony@example.com',  '9876500005', 'Trichy');

INSERT INTO Products (Product_Name, Category, Price, Stock) VALUES
('Wireless Mouse',     'Accessories', 599.00,  50),
('Mechanical Keyboard','Accessories', 2499.00, 30),
('USB-C Charger',      'Electronics', 1299.00, 40),
('Bluetooth Speaker',  'Electronics', 1999.00, 25),
('Laptop Stand',       'Accessories', 899.00,  35),
('Noise Cancelling Headphones', 'Electronics', 4999.00, 15);

INSERT INTO Orders (Customer_ID, Order_Date, Order_Status) VALUES
(1, '2026-09-01', 'Delivered'),
(2, '2026-09-05', 'Delivered'),
(1, '2026-09-12', 'Shipped'),
(3, '2026-09-18', 'Delivered'),
(4, '2026-09-25', 'Pending'),
(2, '2026-10-02', 'Shipped'),
(1, '2026-10-10', 'Pending'),
(5, '2026-10-15', 'Cancelled');

INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price) VALUES
(1, 1, 2, 599.00),
(1, 2, 1, 2499.00),
(2, 3, 1, 1299.00),
(2, 5, 2, 899.00),
(3, 4, 1, 1999.00),
(4, 6, 1, 4999.00),
(4, 1, 1, 599.00),
(5, 2, 1, 2499.00),
(5, 3, 2, 1299.00),
(6, 5, 1, 899.00),
(6, 4, 2, 1999.00),
(7, 6, 1, 4999.00),
(8, 1, 3, 599.00);

UPDATE Orders o
SET Total_Amount = (
    SELECT SUM(od.Quantity * od.Price)
    FROM Order_Details od
    WHERE od.Order_ID = o.Order_ID
);


INSERT INTO Orders (Customer_ID, Order_Date, Order_Status)
VALUES (4, CURRENT_DATE, 'Pending');

SET @new_order_id = LAST_INSERT_ID();

INSERT INTO Order_Details (Order_ID, Product_ID, Quantity, Price)
SELECT @new_order_id, Product_ID, qty, Price
FROM (
    SELECT 1 AS Product_ID, 2 AS qty, Price FROM Products WHERE Product_ID = 1
    UNION ALL
    SELECT 3, 1, Price FROM Products WHERE Product_ID = 3
    UNION ALL
    SELECT 5, 1, Price FROM Products WHERE Product_ID = 5
) AS items;

UPDATE Orders
SET Total_Amount = (
    SELECT SUM(Quantity * Price)
    FROM Order_Details
    WHERE Order_ID = @new_order_id
)
WHERE Order_ID = @new_order_id;

UPDATE Orders SET Order_Status = 'Shipped'   WHERE Order_ID = @new_order_id;
UPDATE Orders SET Order_Status = 'Delivered' WHERE Order_ID = @new_order_id;

UPDATE Order_Details
SET Quantity = 3
WHERE Order_ID = 5 AND Product_ID = 3;

UPDATE Orders
SET Total_Amount = (
    SELECT SUM(Quantity * Price)
    FROM Order_Details
    WHERE Order_ID = 5
)
WHERE Order_ID = 5;

DELETE FROM Orders WHERE Order_Status = 'Cancelled';

SELECT
    o.Order_ID,
    o.Order_Date,
    o.Order_Status,
    c.Customer_ID,
    c.Name AS Customer_Name,
    c.City,
    p.Product_ID,
    p.Product_Name,
    p.Category,
    od.Quantity,
    od.Price,
    (od.Quantity * od.Price) AS Line_Total,
    o.Total_Amount AS Order_Total
FROM Orders o
JOIN Customers c      ON o.Customer_ID = c.Customer_ID
JOIN Order_Details od ON o.Order_ID = od.Order_ID
JOIN Products p       ON od.Product_ID = p.Product_ID
ORDER BY o.Order_ID, p.Product_ID;

SELECT
    o.Order_ID, c.Name AS Customer_Name, o.Order_Date, o.Order_Status,
    p.Product_Name, od.Quantity, od.Price,
    (od.Quantity * od.Price) AS Line_Total
FROM Orders o
JOIN Customers c      ON o.Customer_ID = c.Customer_ID
JOIN Order_Details od ON o.Order_ID = od.Order_ID
JOIN Products p       ON od.Product_ID = p.Product_ID
WHERE o.Order_ID = 1;


SELECT
    c.Customer_ID,
    c.Name AS Customer_Name,
    o.Order_ID,
    o.Order_Date,
    o.Order_Status,
    o.Total_Amount
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
ORDER BY c.Customer_ID, o.Order_Date;

SELECT
    p.Product_ID,
    p.Product_Name,
    o.Order_ID,
    c.Name AS Customer_Name,
    o.Order_Date,
    od.Quantity,
    (od.Quantity * od.Price) AS Line_Total
FROM Products p
JOIN Order_Details od ON p.Product_ID = od.Product_ID
JOIN Orders o         ON od.Order_ID = o.Order_ID
JOIN Customers c      ON o.Customer_ID = c.Customer_ID
ORDER BY p.Product_ID, o.Order_Date;

SELECT
    p.Product_ID,
    p.Product_Name,
    COUNT(od.Order_Detail_ID) AS Times_Ordered
FROM Products p
LEFT JOIN Order_Details od ON p.Product_ID = od.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Times_Ordered DESC;

SELECT
    p.Product_ID,
    p.Product_Name,
    COALESCE(SUM(od.Quantity), 0) AS Total_Quantity_Sold
FROM Products p
LEFT JOIN Order_Details od ON p.Product_ID = od.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Total_Quantity_Sold DESC;

SELECT
    c.Customer_ID,
    c.Name AS Customer_Name,
    COUNT(o.Order_ID) AS Order_Count
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID, c.Name
HAVING COUNT(o.Order_ID) = (
    SELECT MAX(order_count)
    FROM (
        SELECT COUNT(*) AS order_count
        FROM Orders
        GROUP BY Customer_ID
    ) AS counts
);

SELECT
    c.Customer_ID,
    c.Name AS Customer_Name,
    COUNT(o.Order_ID) AS Total_Orders,
    COALESCE(SUM(o.Total_Amount), 0) AS Total_Spending
FROM Customers c
LEFT JOIN Orders o ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID, c.Name
ORDER BY Total_Spending DESC;

SELECT ROUND(AVG(Total_Amount), 2) AS Average_Order_Value
FROM Orders;

SELECT SUM(Total_Amount) AS Total_Sales_Amount
FROM Orders;