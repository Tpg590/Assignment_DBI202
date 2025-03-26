-- CRUD Operations Demo for GroceryStoreManagementSystem
USE GroceryStoreManagementSystem
-------------------- Supplier Table --------------------

-- Create (Insert)
INSERT INTO Supplier (SupplierName, PhoneNumber, Email, Address, City) VALUES
('New Supplier', '0123456789', 'new.supplier@example.com', 'New Address', 'New City');
GO

-- Read (Select All)
SELECT * FROM Supplier;
GO

-- Read (Select by ID)
SELECT * FROM Supplier WHERE SupplierID = 1;
GO

-- Update
UPDATE Supplier
SET SupplierName = 'Updated Supplier Name', PhoneNumber = '9876543210'
WHERE SupplierID = 4;
GO

-- Delete
DELETE FROM Supplier WHERE SupplierID = 4;
GO

-------------------- Customer Table --------------------

-- Create (Insert)
INSERT INTO Customer (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, RegistrationDate) VALUES
('New', 'Customer', 'Male', '0111222333', 'new.customer@example.com', 'New Customer Address', 'New Customer City', '2025-03-27');
GO

-- Read (Select All)
SELECT * FROM Customer;
GO

-- Read (Select by ID)
SELECT * FROM Customer WHERE CustomerID = 1;
GO

-- Update
UPDATE Customer
SET PhoneNumber = '9998887776', Email = 'updated.customer@example.com'
WHERE CustomerID = 4;
GO

-- Delete
DELETE FROM Customer WHERE CustomerID = 4;
GO

-------------------- Employee Table --------------------

-- Create (Insert)
INSERT INTO Employee (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, HireDate, JobTitle, Department, Salary) VALUES
('New', 'Employee', 'Female', '0222333444', 'new.employee@example.com', 'New Employee Address', 'New Employee City', '2025-03-27', 'Clerk', 'Admin', 7000000);
GO

-- Read (Select All)
SELECT * FROM Employee;
GO

-- Read (Select by ID)
SELECT * FROM Employee WHERE EmployeeID = 1;
GO

-- Update
UPDATE Employee
SET Salary = 8500000, Department = 'Finance'
WHERE EmployeeID = 3;
GO

-- Delete
DELETE FROM Employee WHERE EmployeeID = 3;
GO

-------------------- ShippingProvider Table --------------------

-- Create (Insert)
INSERT INTO ShippingProvider (ProviderName, PhoneNumber, Email) VALUES
('New Shipper', '0333444555', 'new.shipper@example.com');
GO

-- Read (Select All)
SELECT * FROM ShippingProvider;
GO

-- Read (Select by ID)
SELECT * FROM ShippingProvider WHERE ProviderID = 1;
GO

-- Update
UPDATE ShippingProvider
SET Email = 'updated.shipper@example.com'
WHERE ProviderID = 3;
GO

-- Delete
DELETE FROM ShippingProvider WHERE ProviderID = 3;
GO

-------------------- Category Table --------------------

-- Create (Insert)
INSERT INTO Category (CategoryName, description) VALUES
('New Category', 'Description for new category');
GO

-- Read (Select All)
SELECT * FROM Category;
GO

-- Read (Select by ID)
SELECT * FROM Category WHERE CategoryID = 1;
GO

-- Update
UPDATE Category
SET description = 'Updated description'
WHERE CategoryID = 5;
GO

-- Delete
DELETE FROM Category WHERE CategoryID = 5;
GO

-------------------- Product Table --------------------

-- Create (Insert) - Using Stored Procedure
EXEC InsertProductWithZeroStock
    @ProductName = 'New Product',
    @Description = 'Description of new product',
    @Brand = 'New Brand',
    @Price = 50000,
    @Unit = '1 pc',
    @ImageURL = 'url_new_product',
    @CategoryID = 1;
GO

-- Read (Select All)
SELECT * FROM Product;
GO

-- Read (Select by ID)
SELECT * FROM Product WHERE ProductID = 1;
GO

-- Update
UPDATE Product
SET Price = 55000, Brand = 'Updated Brand'
WHERE ProductID = 9;
GO

-- Delete
DELETE FROM Product WHERE ProductID = 9;
GO

-------------------- Inventory Table --------------------

-- Create (Insert) - Using Stored Procedure
EXEC InsertInventory
    @QuantityReceived = 50,
    @ReceivedDate = '2025-03-27',
    @SupplierID = 1,
    @ProductID = 3;
GO

-- Read (Select All)
SELECT * FROM Inventory;
GO

-- Read (Select by SupplierID and ProductID - Primary Key)
SELECT * FROM Inventory WHERE SupplierID = 1 AND ProductID = 1;
GO

-- Update
UPDATE Inventory
SET QuantityReceived = 150
WHERE SupplierID = 1 AND ProductID = 3;
GO

-- Delete
DELETE FROM Inventory WHERE SupplierID = 1 AND ProductID = 3;
GO

-------------------- Order Table --------------------

-- Create (Insert)
INSERT INTO [Order] (OrderDate, ShippingAddress, ShippingCity, Status, PaymentMethod, PromisedDate, ShippingFees, TrackingCode, EmployeeID, CustomerID, ProviderID) VALUES
('2025-03-27', 'New Order Address', 'New Order City', 'Pending', 'Online', '2025-03-29', 20000, 'NEWTRACK123', 1, 1, 1);
GO

-- Read (Select All)
SELECT * FROM [Order];
GO

-- Read (Select by ID)
SELECT * FROM [Order] WHERE OrderID = 1;
GO

-- Update
UPDATE [Order]
SET Status = 'Shipped', TrackingCode = 'UPDATEDTRACK456'
WHERE OrderID = 3;
GO

-- Delete
DELETE FROM [Order] WHERE OrderID = 3;
GO

-------------------- OrderItems Table --------------------

-- Create (Insert) - Using Stored Procedure
EXEC InsertOrderItem
    @ProductID = 1,
    @OrderID = 2,
    @Quantity = 1;
GO

-- Read (Select All)
SELECT * FROM OrderItems;
GO

-- Read (Select by ProductID and OrderID - Primary Key)
SELECT * FROM OrderItems WHERE ProductID = 1 AND OrderID = 1;
GO

-- Update
UPDATE OrderItems
SET Quantity = 3, Price = 33000 -- Assuming price might change or needs correction
WHERE ProductID = 1 AND OrderID = 3;
GO

-- Delete
DELETE FROM OrderItems WHERE ProductID = 1 AND OrderID = 3;
GO

-------------------- Promotion Table --------------------

-- Create (Insert)
INSERT INTO Promotion (DiscountPercentage, DiscountAmount, StartDate, EndDate, Description, ProductID) VALUES
(20, 0, '2025-03-28', '2025-04-05', '20% off new product', 1);
GO

-- Read (Select All)
SELECT * FROM Promotion;
GO

-- Read (Select by ID)
SELECT * FROM Promotion WHERE PromotionID = 1;
GO

-- Update
UPDATE Promotion
SET DiscountPercentage = 25, Description = 'Updated promotion description'
WHERE PromotionID = 3;
GO

-- Delete
DELETE FROM Promotion WHERE PromotionID = 3;
GO

-------------------- Using Functions --------------------

-- Get total price for OrderID 1
SELECT dbo.GetTotalPriceByOrderID(1) AS TotalPriceOrder1;
GO

-- Get total price for CustomerID 1
SELECT dbo.GetTotalPriceByCustomerID(1) AS TotalPriceCustomer1;
GO

-- Get number of orders for CustomerID 1
SELECT dbo.GetNumberOfOrdersByCustomerID(1) AS NumberOfOrdersCustomer1;
GO

-- Get the price of ProductID 1 with promotion
SELECT dbo.GetProductPriceWithPromotion(1) AS PriceWithPromotionProduct1;
GO

-- Get the price of ProductID 2 with promotion (no active promotion)
SELECT dbo.GetProductPriceWithPromotion(2) AS PriceWithPromotionProduct2;
GO