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