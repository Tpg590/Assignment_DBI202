Use master
go
-- ALTER DATABASE DepartmentStoreManagementSystem SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

drop database if exists DepartmentStoreManagementSystem
go
create database DepartmentStoreManagementSystem
go
use DepartmentStoreManagementSystem
go

create table Supplier(
	SupplierID int identity(1,1) primary key,
	SupplierName nvarchar(250) NOT NULL,
	PhoneNumber varchar(11) NOT NULL,
	Email varchar(50),
	Address nvarchar(250) NOT NULL,
	City nvarchar(50) NOT NULL
)



create table Customer(
	CustomerID int identity(1,1) primary key,
	FirstName nvarchar(20) NOT NULL,
	LastName nvarchar(20) NOT NULL,
	Gender varchar(6) check (Gender = 'Male' or Gender = 'Female' ),
	PhoneNumber varchar(11) NOT NULL,
	Email varchar(50),
	Address nvarchar(250) NOT NULL,
	City nvarchar(50) NOT NULL,
	RegistrationDate date
)


create table Employee(
	EmployeeID int identity(1,1) primary key,
	FirstName nvarchar(20) NOT NULL,
	LastName nvarchar(20) NOT NULL,
	Gender varchar(6) check (Gender = 'Male' or Gender = 'Female' ),
	PhoneNumber varchar(11) NOT NULL,
	Email varchar(50),
	Address nvarchar(250) NOT NULL,
	City nvarchar(50) NOT NULL,
	HireDate date check (HireDate <= getdate()),
	JobTitle nvarchar(50) NOT NULL,
	Department nvarchar(50) NOT NULL,
	Salary int NOT NULL
)


create table ShippingProvider(
	ProviderID int identity(1,1) primary key,
	ProviderName nvarchar(250) NOT NULL,
	Contacts nvarchar(250) NOT NULL
)


create table Category(
	CategoryID int identity(1,1) primary key,
	CategoryName nvarchar(250) NOT NULL,
	description nvarchar(250)
)



create table Product(
	ProductID int identity(1,1) primary key,
	ProductName nvarchar(250) NOT NULL,
	Description nvarchar(250) NOT NULL,
	Brand nvarchar(250),
	Price int NOT NULL,
	StockQuanlity nvarchar(250) NOT NULL,
	Unit varchar(50),
	ImageURL TEXT NOT NULL,
	CategoryID int references Category(CategoryID),
	SupplierID int references Supplier(SupplierID)

)

create table Inventory(
	QuantityReceived varchar(250),
	ReceivedDate date check (ReceivedDate <= getdate()),
	SupplierID int references Supplier(SupplierID),
	ProductID int references Product(ProductID),
	Primary key(SupplierID, ProductID)
)


Create table [Order](
	OrderID int identity(1,1) primary key,
	OrderDate date check (OrderDate <= getdate()),
	ShippingAddress nvarchar(250) NOT NULL,
	ShippingCity nvarchar(50) NOT NULL,
	Status nvarchar(250),
	TotalAmount int NOT NULL,
	PaymentMethod nvarchar(250) NOT NULL,
	PromisedDate date check (PromisedDate <= getdate()),
	ShippingFees int NOT NULL,
	TrackingCode varchar(250) NOT NULL,
	EmployeeID int references Employee(EmployeeID),
	CustomerID int references Customer(CustomerID),
	ProviderID int references ShippingProvider(ProviderID)
)

create table Contain(
	Quanlity varchar(250),
	ProductID int references Product(ProductID),
	OrderID int references [Order](OrderID),
	Primary key (ProductID, OrderID)
)

Create table Promotion(
	PromotionID int identity(1,1) primary key,
	DiscountPercentage int NOT NULL,
	DiscountAmount int NOT NULL,
	StartDate date check (StartDate <= getdate()),
	EndDate date,
	Description nvarchar(250),
	ProductID int  references Product(ProductID)
)

ALTER TABLE Promotion
ADD CONSTRAINT chk_EndDate CHECK (EndDate >= StartDate);
go

-- Triggers

-- 1. Trigger to update StockQuantity in Product table after a new order is placed
CREATE TRIGGER UpdateStockQuantity
ON Contain
AFTER INSERT
AS
BEGIN
    UPDATE Product
    SET StockQuanlity = CAST(CAST(StockQuanlity AS INT) - CAST(inserted.Quanlity AS INT) AS VARCHAR(250))
    FROM Product
    JOIN inserted ON Product.ProductID = inserted.ProductID;
END;
go
-- 2. Trigger to prevent adding future HireDates for employees (INSTEAD OF)
CREATE TRIGGER PreventFutureHireDate
ON Employee
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE HireDate > GETDATE())
    BEGIN
        RAISERROR('Hire date cannot be in the future.', 16, 1);
        -- No need for ROLLBACK TRANSACTION here, as we are preventing the insert/update
    END
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            IF EXISTS (SELECT 1 FROM deleted)
            BEGIN
                -- Update
                UPDATE Employee
                SET FirstName = inserted.FirstName,
                    LastName = inserted.LastName,
                    Gender = inserted.Gender,
                    PhoneNumber = inserted.PhoneNumber,
                    Email = inserted.Email,
                    Address = inserted.Address,
                    City = inserted.City,
                    HireDate = inserted.HireDate,
                    JobTitle = inserted.JobTitle,
                    Department = inserted.Department,
                    Salary = inserted.Salary
                FROM Employee
                JOIN inserted ON Employee.EmployeeID = inserted.EmployeeID;

            END
            ELSE
            BEGIN
                -- Insert
                INSERT INTO Employee (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, HireDate, JobTitle, Department, Salary)
                SELECT FirstName, LastName, Gender, PhoneNumber, Email, Address, City, HireDate, JobTitle, Department, Salary
                FROM inserted;
            END
        END
    END;
END;
go
-- 3. Trigger to prevent adding future ReceivedDates for Inventory (INSTEAD OF)
CREATE TRIGGER PreventFutureReceivedDate
ON Inventory
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE ReceivedDate > GETDATE())
    BEGIN
        RAISERROR('Received date cannot be in the future.', 16, 1);
    END
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            IF EXISTS (SELECT 1 FROM deleted)
            BEGIN
                -- Update
                UPDATE Inventory
                SET QuantityReceived = inserted.QuantityReceived,
                    ReceivedDate = inserted.ReceivedDate,
                    SupplierID = inserted.SupplierID,
                    ProductID = inserted.ProductID
                FROM Inventory
                JOIN inserted ON Inventory.SupplierID = inserted.SupplierID AND Inventory.ProductID = inserted.ProductID;
            END
            ELSE
            BEGIN
                -- Insert
                INSERT INTO Inventory (QuantityReceived, ReceivedDate, SupplierID, ProductID)
                SELECT QuantityReceived, ReceivedDate, SupplierID, ProductID
                FROM inserted;
            END
        END
    END;
END;
go
-- 4. Trigger to prevent future OrderDates or PromisedDates (INSTEAD OF)
CREATE TRIGGER PreventFutureOrderOrPromisedDates
ON [Order]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE OrderDate > GETDATE() OR PromisedDate > GETDATE())
    BEGIN
        RAISERROR('Order date or promised date cannot be in the future.', 16, 1);
        RETURN; -- Important: Stop execution to prevent insert/update
    END
    ELSE
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted)
        BEGIN
            IF EXISTS (SELECT 1 FROM deleted)
            BEGIN
                -- Update
                UPDATE [Order]
                SET OrderDate = inserted.OrderDate,
                    ShippingAddress = inserted.ShippingAddress,
                    ShippingCity = inserted.ShippingCity,
                    Status = inserted.Status,
                    TotalAmount = inserted.TotalAmount,
                    PaymentMethod = inserted.PaymentMethod,
                    PromisedDate = inserted.PromisedDate,
                    ShippingFees = inserted.ShippingFees,
                    TrackingCode = inserted.TrackingCode,
                    EmployeeID = inserted.EmployeeID,
                    CustomerID = inserted.CustomerID,
                    ProviderID = inserted.ProviderID
                FROM [Order]
                JOIN inserted ON [Order].OrderID = inserted.OrderID;
            END
            ELSE
            BEGIN
                -- Insert
                INSERT INTO [Order] (OrderDate, ShippingAddress, ShippingCity, Status, TotalAmount, PaymentMethod, PromisedDate, ShippingFees, TrackingCode, EmployeeID, CustomerID, ProviderID)
                SELECT OrderDate, ShippingAddress, ShippingCity, Status, TotalAmount, PaymentMethod, PromisedDate, ShippingFees, TrackingCode, EmployeeID, CustomerID, ProviderID
                FROM inserted;
            END
        END
    END;
END;
go
-- Functions

-- 1. Function to calculate the total order amount based on OrderID
CREATE FUNCTION CalculateOrderTotal (@OrderID INT)
RETURNS INT
AS
BEGIN
    DECLARE @TotalAmount INT;
    SELECT @TotalAmount = SUM(CAST(Contain.Quanlity AS INT) * Product.Price)
    FROM Contain
    JOIN Product ON Contain.ProductID = Product.ProductID
    WHERE Contain.OrderID = @OrderID;
    RETURN @TotalAmount;
END;
go
-- 2. Function to get the number of orders placed by a customer
CREATE FUNCTION GetCustomerOrderCount (@CustomerID INT)
RETURNS INT
AS
BEGIN
    DECLARE @OrderCount INT;
    SELECT @OrderCount = COUNT(*)
    FROM [Order]
    WHERE CustomerID = @CustomerID;
    RETURN @OrderCount;
END;
go
-- 3. Function to get the average product price in a category
CREATE FUNCTION GetAverageCategoryPrice (@CategoryID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @AveragePrice DECIMAL(10, 2);
    SELECT @AveragePrice = AVG(CAST(Price AS DECIMAL(10, 2)))
    FROM Product
    WHERE CategoryID = @CategoryID;
    RETURN @AveragePrice;
END;
go
-- Stored Procedures

-- 1. Stored procedure to add a new order
CREATE PROCEDURE AddNewOrder
    @OrderDate DATE,
    @ShippingAddress NVARCHAR(250),
    @ShippingCity NVARCHAR(50),
    @Status NVARCHAR(250),
    @PaymentMethod NVARCHAR(250),
    @PromisedDate DATE,
    @ShippingFees INT,
    @TrackingCode VARCHAR(250),
    @EmployeeID INT,
    @CustomerID INT,
    @ProviderID INT
AS
BEGIN
    INSERT INTO [Order] (OrderDate, ShippingAddress, ShippingCity, Status, PaymentMethod, PromisedDate, ShippingFees, TrackingCode, EmployeeID, CustomerID, ProviderID)
    VALUES (@OrderDate, @ShippingAddress, @ShippingCity, @Status, @PaymentMethod, @PromisedDate, @ShippingFees, @TrackingCode, @EmployeeID, @CustomerID, @ProviderID);
END;
go
-- 2. Stored procedure to update product price
CREATE PROCEDURE UpdateProductPrice
    @ProductID INT,
    @NewPrice INT
AS
BEGIN
    UPDATE Product
    SET Price = @NewPrice
    WHERE ProductID = @ProductID;
END;
go
-- 3. Stored procedure to get the total order amount for a customer
CREATE PROCEDURE GetCustomerTotalOrderAmount
    @CustomerID INT
AS
BEGIN
    SELECT SUM(dbo.CalculateOrderTotal(OrderID)) AS TotalAmount
    FROM [Order]
    WHERE CustomerID = @CustomerID;
END;
go
-- 4. Store procedure to add a new category
CREATE PROCEDURE AddCategory
    @CategoryName nvarchar(250),
    @description nvarchar(250)
AS
BEGIN
    INSERT INTO Category(CategoryName, description)
    VALUES(@CategoryName,@description)
END;
go
-- 5. Store procedure to add a new Supplier
CREATE PROCEDURE AddSupplier
    @SupplierName nvarchar(250),
    @PhoneNumber varchar(11),
    @Email varchar(50),
    @Address nvarchar(250),
    @City nvarchar(50)
AS
BEGIN
    Insert into Supplier (SupplierName, PhoneNumber, Email, Address, City)
    VALUES (@SupplierName, @PhoneNumber, @Email, @Address, @City)
END;
go

-- Supplier data
INSERT INTO Supplier (SupplierName, PhoneNumber, Email, Address, City) VALUES
('Global Goods Inc.', '18005551001', 'contact@globalgoods.com', '123 Supply Ave', 'Chicago'),
('Metro Distributors', '18005551002', 'sales@metrodist.com', '456 Wholesale Blvd', 'Los Angeles'),
('Prime Products Ltd', '18005551003', 'orders@primeproducts.com', '789 Vendor St', 'Atlanta'),
('Superior Supplies', '18005551004', 'info@superiorsupplies.com', '321 Merchandise Dr', 'Dallas'),
('Quality Vendors', '18005551005', 'service@qualityvendors.com', '654 Commerce Rd', 'Seattle'),
('National Distributors', '18005551006', 'sales@nationaldist.com', '987 Trading Pkwy', 'Miami'),
('EastCoast Suppliers', '18005551007', 'info@eastcoastsuppliers.com', '741 Export Ln', 'Boston'),
('Western Goods Co', '18005551008', 'orders@westerngoods.com', '852 Import Dr', 'Phoenix'),
('Southern Distributors', '18005551009', 'contact@southerndist.com', '963 Supply Rd', 'Houston'),
('Northern Products', '18005551010', 'sales@northernproducts.com', '159 Vendor Ave', 'Denver'),
('Premium Supplies Inc', '18005551011', 'info@premiumsupplies.com', '357 Wholesale St', 'Detroit'),
('Value Vendors LLC', '18005551012', 'orders@valuevendors.com', '486 Merchandise Ln', 'Philadelphia'),
('Central Distributors', '18005551013', 'service@centraldist.com', '259 Trading Ave', 'Minneapolis'),
('Coastal Suppliers', '18005551014', 'contact@coastalsuppliers.com', '753 Commerce Dr', 'San Diego'),
('Mountain Vendors Co', '18005551015', 'info@mountainvendors.com', '951 Export Rd', 'Portland');

-- Customer data
INSERT INTO Customer (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, RegistrationDate) VALUES
('John', 'Smith', 'Male', '12125551001', 'john.smith@email.com', '123 Main St', 'New York', '2022-01-10'),
('Emma', 'Johnson', 'Female', '12125551002', 'emma.j@email.com', '456 Oak Ave', 'Los Angeles', '2022-01-15'),
('Michael', 'Williams', 'Male', '12125551003', 'michael.w@email.com', '789 Pine Rd', 'Chicago', '2022-02-01'),
('Sophia', 'Brown', 'Female', '12125551004', 'sophia.b@email.com', '321 Maple Dr', 'Houston', '2022-02-12'),
('James', 'Jones', 'Male', '12125551005', 'james.j@email.com', '654 Cedar St', 'Phoenix', '2022-03-05'),
('Olivia', 'Garcia', 'Female', '12125551006', 'olivia.g@email.com', '987 Birch Ln', 'Philadelphia', '2022-03-18'),
('Robert', 'Miller', 'Male', '12125551007', 'robert.m@email.com', '741 Elm St', 'San Antonio', '2022-04-02'),
('Ava', 'Davis', 'Female', '12125551008', 'ava.d@email.com', '852 Spruce Ave', 'San Diego', '2022-04-15'),
('William', 'Rodriguez', 'Male', '12125551009', 'william.r@email.com', '963 Willow Rd', 'Dallas', '2022-05-01'),
('Isabella', 'Martinez', 'Female', '12125551010', 'isabella.m@email.com', '159 Aspen Dr', 'San Jose', '2022-05-20'),
('David', 'Hernandez', 'Male', '12125551011', 'david.h@email.com', '357 Oak St', 'Austin', '2022-06-06'),
('Mia', 'Lopez', 'Female', '12125551012', 'mia.l@email.com', '486 Pine Ave', 'Jacksonville', '2022-06-18'),
('Joseph', 'Gonzalez', 'Male', '12125551013', 'joseph.g@email.com', '259 Maple Rd', 'Fort Worth', '2022-07-02'),
('Charlotte', 'Wilson', 'Female', '12125551014', 'charlotte.w@email.com', '753 Cedar Ln', 'Columbus', '2022-07-15'),
('Thomas', 'Anderson', 'Male', '12125551015', 'thomas.a@email.com', '951 Birch Dr', 'Indianapolis', '2022-08-01');

-- Employee data
INSERT INTO Employee (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, HireDate, JobTitle, Department, Salary) VALUES
('Daniel', 'Clark', 'Male', '13135551001', 'daniel.c@store.com', '123 Staff St', 'New York', '2021-01-10', 'Store Manager', 'Management', 75000),
('Jessica', 'Lewis', 'Female', '13135551002', 'jessica.l@store.com', '456 Employee Ave', 'Chicago', '2021-02-15', 'Assistant Manager', 'Management', 65000),
('Matthew', 'Lee', 'Male', '13135551003', 'matthew.l@store.com', '789 Worker Rd', 'Los Angeles', '2021-03-01', 'Department Supervisor', 'Sales', 55000),
('Emily', 'Walker', 'Female', '13135551004', 'emily.w@store.com', '321 Personnel Dr', 'Houston', '2021-03-20', 'Sales Associate', 'Sales', 45000),
('Christopher', 'Hall', 'Male', '13135551005', 'chris.h@store.com', '654 Staff Ln', 'Phoenix', '2021-04-10', 'Cashier', 'Front End', 40000),
('Ashley', 'Allen', 'Female', '13135551006', 'ashley.a@store.com', '987 Employee St', 'Philadelphia', '2021-04-25', 'Inventory Specialist', 'Inventory', 48000),
('Joshua', 'Young', 'Male', '13135551007', 'joshua.y@store.com', '741 Worker Ave', 'San Antonio', '2021-05-15', 'Customer Service Rep', 'Customer Service', 42000),
('Amanda', 'King', 'Female', '13135551008', 'amanda.k@store.com', '852 Personnel Rd', 'San Diego', '2021-06-01', 'Marketing Coordinator', 'Marketing', 52000),
('Andrew', 'Wright', 'Male', '13135551009', 'andrew.w@store.com', '963 Staff Dr', 'Dallas', '2021-06-20', 'IT Specialist', 'IT', 60000),
('Sarah', 'Scott', 'Female', '13135551010', 'sarah.s@store.com', '159 Employee Ln', 'San Jose', '2021-07-05', 'HR Coordinator', 'Human Resources', 55000),
('Ryan', 'Green', 'Male', '13135551011', 'ryan.g@store.com', '357 Worker St', 'Austin', '2021-07-25', 'Accountant', 'Finance', 58000),
('Nicole', 'Baker', 'Female', '13135551012', 'nicole.b@store.com', '486 Personnel Ave', 'Jacksonville', '2021-08-10', 'Sales Associate', 'Sales', 44000),
('Kevin', 'Adams', 'Male', '13135551013', 'kevin.a@store.com', '259 Staff Rd', 'Fort Worth', '2021-08-30', 'Stock Clerk', 'Inventory', 41000),
('Michelle', 'Nelson', 'Female', '13135551014', 'michelle.n@store.com', '753 Employee Dr', 'Columbus', '2021-09-15', 'Cashier', 'Front End', 40000),
('Jason', 'Hill', 'Male', '13135551015', 'jason.h@store.com', '951 Worker Ln', 'Indianapolis', '2021-10-01', 'Security Officer', 'Security', 46000);

-- ShippingProvider data
INSERT INTO ShippingProvider (ProviderName, Contacts) VALUES
('Express Delivery', 'Phone: 18001234567, Email: contact@expressdelivery.com'),
('Swift Shipping', 'Phone: 18009876543, Email: support@swiftshipping.com'),
('Rapid Transit', 'Phone: 18005554321, Email: info@rapidtransit.com'),
('Reliable Logistics', 'Phone: 18007778888, Email: service@reliablelogistics.com'),
('Global Shipping Co', 'Phone: 18003334444, Email: help@globalshipping.com'),
('Fast Track Delivery', 'Phone: 18006667777, Email: support@fasttrackdelivery.com'),
('Safe Shipment Inc', 'Phone: 18002221111, Email: contact@safeshipment.com'),
('Priority Post', 'Phone: 18004445555, Email: info@prioritypost.com'),
('Quality Carriers', 'Phone: 18008889999, Email: service@qualitycarriers.com'),
('Speedy Logistics', 'Phone: 18001112222, Email: help@speedylogistics.com'),
('Direct Delivery', 'Phone: 18005556666, Email: support@directdelivery.com'),
('Trusted Transport', 'Phone: 18007773333, Email: contact@trustedtransport.com'),
('ProShip Services', 'Phone: 18009994444, Email: info@proship.com'),
('Nationwide Express', 'Phone: 18006668888, Email: service@nationwideexpress.com'),
('Metro Freight', 'Phone: 18003337777, Email: help@metrofreight.com');

-- Category data
INSERT INTO Category (CategoryName, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Apparel for men, women, and children'),
('Home & Kitchen', 'Household items and kitchen appliances'),
('Beauty & Personal Care', 'Cosmetics, skincare, and personal hygiene products'),
('Groceries', 'Food and beverage items'),
('Toys & Games', 'Entertainment items for children and adults'),
('Sports & Outdoors', 'Equipment and gear for sports and outdoor activities'),
('Books & Stationery', 'Reading materials and office supplies'),
('Health & Wellness', 'Products for health maintenance and wellness'),
('Furniture', 'Home and office furniture'),
('Automotive', 'Car parts and accessories'),
('Jewelry & Accessories', 'Decorative items for personal adornment'),
('Pet Supplies', 'Products for pets and pet care'),
('Garden & Outdoor', 'Gardening supplies and outdoor equipment'),
('Baby Products', 'Items for infants and toddlers');

-- Product data
INSERT INTO Product (ProductName, Description, Brand, Price, StockQuanlity, Unit, ImageURL, CategoryID, SupplierID) VALUES
('Smartphone XS', 'Latest model smartphone with advanced features', 'TechGiant', 899, '150', 'piece', 'http://example.com/images/smartphone_xs.jpg', 1, 1),
('Men''s T-Shirt', 'Comfortable cotton t-shirt for casual wear', 'FashionBrand', 25, '300', 'piece', 'http://example.com/images/mens_tshirt.jpg', 2, 2),
('Coffee Maker', 'Programmable coffee maker with 12-cup capacity', 'HomeAppliances', 75, '100', 'piece', 'http://example.com/images/coffee_maker.jpg', 3, 3),
('Facial Cleanser', 'Gentle facial cleanser for all skin types', 'BeautyCosmetics', 15, '200', 'bottle', 'http://example.com/images/facial_cleanser.jpg', 4, 4),
('Organic Cereal', 'Whole grain organic breakfast cereal', 'HealthyFoods', 6, '250', 'box', 'http://example.com/images/organic_cereal.jpg', 5, 5),
('Board Game Set', 'Family board game collection with 5 classic games', 'GameMasters', 35, '80', 'set', 'http://example.com/images/board_game_set.jpg', 6, 6),
('Yoga Mat', 'Non-slip yoga mat for exercise and meditation', 'FitnessPro', 30, '120', 'piece', 'http://example.com/images/yoga_mat.jpg', 7, 7),
('Notebook Set', 'Premium hardcover notebooks, pack of 3', 'PaperGoods', 18, '180', 'set', 'http://example.com/images/notebook_set.jpg', 8, 8),
('Multivitamin', 'Daily multivitamin supplement, 90 tablets', 'HealthEssentials', 22, '160', 'bottle', 'http://example.com/images/multivitamin.jpg', 9, 9),
('Office Chair', 'Ergonomic office chair with lumbar support', 'ComfortSeating', 149, '50', 'piece', 'http://example.com/images/office_chair.jpg', 10, 10),
('Car Cleaning Kit', 'Complete car cleaning and detailing kit', 'AutoCare', 45, '70', 'kit', 'http://example.com/images/car_cleaning_kit.jpg', 11, 11),
('Silver Necklace', 'Sterling silver pendant necklace', 'LuxuryJewels', 85, '60', 'piece', 'http://example.com/images/silver_necklace.jpg', 12, 12),
('Dog Food', 'Premium dry dog food, 20lb bag', 'PetNutrition', 38, '90', 'bag', 'http://example.com/images/dog_food.jpg', 13, 13),
('Garden Tools Set', 'Essential gardening tools, 5-piece set', 'GardenPro', 55, '65', 'set', 'http://example.com/images/garden_tools.jpg', 14, 14),
('Baby Stroller', 'Lightweight foldable baby stroller', 'InfantCare', 189, '40', 'piece', 'http://example.com/images/baby_stroller.jpg', 15, 15),
('Wireless Earbuds', 'Bluetooth wireless earbuds with charging case', 'AudioTech', 79, '110', 'pair', 'http://example.com/images/wireless_earbuds.jpg', 1, 2),
('Women''s Jeans', 'Slim fit denim jeans for women', 'DenimStyle', 45, '130', 'piece', 'http://example.com/images/womens_jeans.jpg', 2, 3);

-- Inventory data
INSERT INTO Inventory (QuantityReceived, ReceivedDate, SupplierID, ProductID) VALUES
('50', '2022-11-15', 1, 1),
('100', '2022-11-10', 2, 2),
('30', '2022-11-05', 3, 3),
('75', '2022-10-28', 4, 4),
('80', '2022-10-20', 5, 5),
('25', '2022-10-15', 6, 6),
('40', '2022-10-10', 7, 7),
('60', '2022-10-05', 8, 8),
('50', '2022-09-28', 9, 9),
('15', '2022-09-20', 10, 10),
('25', '2022-09-15', 11, 11),
('20', '2022-09-10', 12, 12),
('30', '2022-09-05', 13, 13),
('20', '2022-08-28', 14, 14),
('15', '2022-08-20', 15, 15),
('40', '2022-08-15', 2, 16),
('45', '2022-08-10', 3, 17);

-- Order data
INSERT INTO [Order] (OrderDate, ShippingAddress, ShippingCity, Status, TotalAmount, PaymentMethod, PromisedDate, ShippingFees, TrackingCode, EmployeeID, CustomerID, ProviderID) VALUES
('2022-12-01', '123 Delivery St', 'New York', 'Completed', 935, 'Credit Card', '2022-12-05', 10, 'TRK12345678', 1, 1, 1),
('2022-12-02', '456 Shipping Ave', 'Chicago', 'Completed', 150, 'PayPal', '2022-12-06', 8, 'TRK23456789', 2, 2, 2),
('2022-12-03', '789 Delivery Rd', 'Los Angeles', 'In Transit', 320, 'Credit Card', '2022-12-07', 12, 'TRK34567890', 3, 3, 3),
('2022-12-04', '321 Shipping Dr', 'Houston', 'Processing', 95, 'Debit Card', '2022-12-08', 9, 'TRK45678901', 4, 4, 4),
('2022-12-05', '654 Delivery Ln', 'Phoenix', 'Completed', 210, 'Credit Card', '2022-12-09', 11, 'TRK56789012', 5, 5, 5),
('2022-12-06', '987 Shipping St', 'Philadelphia', 'In Transit', 180, 'PayPal', '2022-12-10', 10, 'TRK67890123', 6, 6, 6),
('2022-12-07', '741 Delivery Ave', 'San Antonio', 'Processing', 270, 'Credit Card', '2022-12-11', 8, 'TRK78901234', 7, 7, 7),
('2022-12-08', '852 Shipping Rd', 'San Diego', 'Completed', 120, 'Debit Card', '2022-12-12', 9, 'TRK89012345', 8, 8, 8),
('2022-12-09', '963 Delivery Dr', 'Dallas', 'In Transit', 450, 'Credit Card', '2022-12-13', 12, 'TRK90123456', 9, 9, 9),
('2022-12-10', '159 Shipping Ln', 'San Jose', 'Processing', 85, 'PayPal', '2022-12-14', 8, 'TRK01234567', 10, 10, 10),
('2022-12-11', '357 Delivery St', 'Austin', 'Completed', 195, 'Credit Card', '2022-12-15', 10, 'TRK12345098', 11, 11, 11),
('2022-12-12', '486 Shipping Ave', 'Jacksonville', 'In Transit', 230, 'Debit Card', '2022-12-16', 11, 'TRK23450987', 12, 12, 12),
('2022-12-13', '259 Delivery Rd', 'Fort Worth', 'Processing', 310, 'Credit Card', '2022-12-17', 9, 'TRK34509876', 13, 13, 13),
('2022-12-14', '753 Shipping Dr', 'Columbus', 'Completed', 175, 'PayPal', '2022-12-18', 10, 'TRK45098765', 14, 14, 14),
('2022-12-15', '951 Delivery Ln', 'Indianapolis', 'In Transit', 520, 'Credit Card', '2022-12-19', 12, 'TRK50987654', 15, 15, 15);

-- Contain data
INSERT INTO Contain (Quanlity, ProductID, OrderID) VALUES
('1', 1, 1),
('2', 2, 2),
('1', 3, 3),
('3', 4, 4),
('1', 5, 5),
('2', 6, 6),
('3', 7, 7),
('2', 8, 8),
('1', 9, 9),
('4', 10, 10),
('1', 11, 11),
('1', 12, 12),
('2', 13, 13),
('3', 14, 14),
('1', 15, 15),
('2', 16, 1),
('1', 17, 2);

-- Promotion data
INSERT INTO Promotion (DiscountPercentage, DiscountAmount, StartDate, EndDate, Description, ProductID) VALUES
(10, 90, '2022-11-01', '2022-12-31', 'Holiday Sale', 1),
(15, 4, '2022-11-01', '2022-12-31', 'Winter Discount', 2),
(20, 15, '2022-11-15', '2022-12-15', 'Black Friday Deal', 3),
(10, 2, '2022-12-01', '2022-12-31', 'December Special', 4),
(25, 2, '2022-11-20', '2022-12-20', 'Clearance Sale', 5),
(15, 5, '2022-12-10', '2023-01-10', 'New Year Promo', 6),
(20, 6, '2022-11-10', '2022-12-10', 'Limited Time Offer', 7),
(10, 2, '2022-12-05', '2023-01-05', 'Winter Sale', 8),
(30, 7, '2022-11-25', '2022-12-25', 'Christmas Special', 9),
(15, 22, '2022-12-15', '2023-01-15', 'Year-End Discount', 10),
(10, 5, '2022-11-05', '2022-12-05', 'November Deal', 11),
(25, 21, '2022-12-20', '2023-01-20', 'Holiday Offer', 12),
(20, 8, '2022-11-15', '2023-01-15', 'Seasonal Discount', 13),
(15, 8, '2022-12-01', '2022-12-31', 'December Promo', 14),
(30, 57, '2022-11-28', '2022-12-28', 'Special Discount', 15);