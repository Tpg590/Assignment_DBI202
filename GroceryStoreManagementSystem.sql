Use master
go
-- ALTER DATABASE GroceryStoreManagementSystem SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

drop database if exists GroceryStoreManagementSystem
go
create database GroceryStoreManagementSystem
go
use GroceryStoreManagementSystem
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
	PhoneNumber varchar(11) NOT NULL,
	Email varchar(50),
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
	StockQuantity int NOT NULL,
	Unit varchar(50),
	ImageURL TEXT NOT NULL,
	CategoryID int references Category(CategoryID)
)

create table Inventory(
	QuantityReceived int,
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
	PromisedDate date,
	ShippingFees int NOT NULL,
	TrackingCode varchar(250) NOT NULL,
	EmployeeID int references Employee(EmployeeID),
	CustomerID int references Customer(CustomerID),
	ProviderID int references ShippingProvider(ProviderID)
)

create table OrderItems(
	ProductID int references Product(ProductID),
	OrderID int references [Order](OrderID),
	Quantity int,
	Price int,
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

-- Trigger
CREATE TRIGGER TR_Customer_InsteadOfInsertUpdate_RegistrationDate
ON Customer
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Handle INSERT operations
    IF EXISTS (SELECT * FROM inserted WHERE NOT EXISTS (SELECT * FROM deleted))
    BEGIN
        INSERT INTO Customer (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, RegistrationDate)
        SELECT
            FirstName,
            LastName,
            Gender,
            PhoneNumber,
            Email,
            Address,
            City,
            CASE
                WHEN i.RegistrationDate > GETDATE() THEN GETDATE()
                ELSE i.RegistrationDate
            END
        FROM inserted i;
    END

    -- Handle UPDATE operations
    IF EXISTS (SELECT * FROM inserted WHERE EXISTS (SELECT * FROM deleted))
    BEGIN
        UPDATE c
        SET RegistrationDate = CASE
            WHEN i.RegistrationDate > GETDATE() THEN GETDATE()
            ELSE i.RegistrationDate
        END
        FROM Customer c
        INNER JOIN inserted i ON c.CustomerID = i.CustomerID
        INNER JOIN deleted d ON c.CustomerID = d.CustomerID
        WHERE i.RegistrationDate <> d.RegistrationDate;
    END
END
GO

CREATE TRIGGER TR_Employee_InsteadOfInsertUpdate_HireDate
ON Employee
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Handle INSERT operations
    IF EXISTS (SELECT * FROM inserted WHERE NOT EXISTS (SELECT * FROM deleted))
    BEGIN
        INSERT INTO Employee (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, HireDate, JobTitle, Department, Salary)
        SELECT
            FirstName,
            LastName,
            Gender,
            PhoneNumber,
            Email,
            Address,
            City,
            CASE
                WHEN i.HireDate > GETDATE() THEN GETDATE()
                ELSE i.HireDate
            END,
            JobTitle,
            Department,
            Salary
        FROM inserted i;
    END

	-- Handle UPDATE operations
    IF EXISTS (SELECT * FROM inserted WHERE EXISTS (SELECT * FROM deleted))
    BEGIN
        UPDATE e
        SET HireDate = CASE
            WHEN i.HireDate > GETDATE() THEN GETDATE()
            ELSE i.HireDate
        END
        FROM Employee e
        INNER JOIN inserted i ON e.EmployeeID = i.EmployeeID
        INNER JOIN deleted d ON e.EmployeeID = d.EmployeeID
        WHERE i.HireDate <> d.HireDate;
    END
END
GO

CREATE TRIGGER TR_Inventory_InsteadOfInsertUpdate_ReceivedDate
ON Inventory
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Handle INSERT operations
    IF EXISTS (SELECT * FROM inserted WHERE NOT EXISTS (SELECT * FROM deleted))
    BEGIN
        INSERT INTO Inventory (QuantityReceived, ReceivedDate, SupplierID, ProductID)
        SELECT
            QuantityReceived,
            CASE
                WHEN i.ReceivedDate > GETDATE() THEN GETDATE()
                ELSE i.ReceivedDate
            END,
            SupplierID,
            ProductID
        FROM inserted i;
    END

    -- Handle UPDATE operations
    IF EXISTS (SELECT * FROM inserted WHERE EXISTS (SELECT * FROM deleted))
    BEGIN
        UPDATE inv
        SET ReceivedDate = CASE
            WHEN i.ReceivedDate > GETDATE() THEN GETDATE()
            ELSE i.ReceivedDate
        END
        FROM Inventory inv
        INNER JOIN inserted i ON inv.SupplierID = i.SupplierID AND inv.ProductID = i.ProductID
        INNER JOIN deleted d ON inv.SupplierID = d.SupplierID AND inv.ProductID = d.ProductID
        WHERE i.ReceivedDate <> d.ReceivedDate;
    END
END
GO

CREATE TRIGGER TR_Order_InsteadOfInsertUpdate_OrderDate
ON [Order]
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Handle INSERT operations
    IF EXISTS (SELECT * FROM inserted WHERE NOT EXISTS (SELECT * FROM deleted))
    BEGIN
        INSERT INTO [Order] (OrderDate, ShippingAddress, ShippingCity, Status, TotalAmount, PaymentMethod, PromisedDate, ShippingFees, TrackingCode, EmployeeID, CustomerID, ProviderID)
        SELECT
            CASE
                WHEN i.OrderDate > GETDATE() THEN GETDATE()
                ELSE i.OrderDate
            END,
            ShippingAddress,
            ShippingCity,
            Status,
            TotalAmount,
            PaymentMethod,
            PromisedDate,
            ShippingFees,
            TrackingCode,
            EmployeeID,
            CustomerID,
            ProviderID
        FROM inserted i;
    END

    -- Handle UPDATE operations
    IF EXISTS (SELECT * FROM inserted WHERE EXISTS (SELECT * FROM deleted))
    BEGIN
        UPDATE o
        SET OrderDate = CASE
            WHEN i.OrderDate > GETDATE() THEN GETDATE()
            ELSE i.OrderDate
        END
        FROM [Order] o
        INNER JOIN inserted i ON o.OrderID = i.OrderID
        INNER JOIN deleted d ON o.OrderID = d.OrderID
        WHERE i.OrderDate <> d.OrderDate;
    END
END
GO

CREATE TRIGGER TR_Promotion_InsteadOfInsertUpdate_StartAndEndDate
ON Promotion
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Handle INSERT operations
    IF EXISTS (SELECT * FROM inserted WHERE NOT EXISTS (SELECT * FROM deleted))
    BEGIN
        INSERT INTO Promotion (DiscountPercentage, DiscountAmount, StartDate, EndDate, Description, ProductID)
        SELECT
            DiscountPercentage,
            DiscountAmount,
            CASE
                WHEN i.StartDate > GETDATE() THEN GETDATE()
                ELSE i.StartDate
            END,
            CASE
                WHEN i.EndDate > GETDATE() THEN GETDATE()
                ELSE i.EndDate
            END,
            Description,
            ProductID
        FROM inserted i;
    END

    -- Handle UPDATE operations
    IF EXISTS (SELECT * FROM inserted WHERE EXISTS (SELECT * FROM deleted))
    BEGIN
        UPDATE p
        SET
            StartDate = CASE
                WHEN i.StartDate > GETDATE() THEN GETDATE()
                ELSE i.StartDate
            END,
            EndDate = CASE
                WHEN i.EndDate > GETDATE() THEN GETDATE()
                ELSE i.EndDate
            END
        FROM Promotion p
        INNER JOIN inserted i ON p.PromotionID = i.PromotionID
        INNER JOIN deleted d ON p.PromotionID = d.PromotionID
        WHERE i.StartDate <> d.StartDate OR i.EndDate <> d.EndDate;
    END
END
GO

-- Function

-- Function to get total price by OrderID
CREATE FUNCTION GetTotalPriceByOrderID (@OrderID int)
RETURNS int
AS
BEGIN
    DECLARE @TotalPrice int;

    SELECT @TotalPrice = SUM(oi.Quantity * oi.Price)
    FROM OrderItems oi
    WHERE oi.OrderID = @OrderID;

    -- If no items are found for the given OrderID, return 0 or handle as needed
    IF @TotalPrice IS NULL
        SET @TotalPrice = 0;

    RETURN @TotalPrice;
END
GO

-- Function to get total price by CustomerID
CREATE FUNCTION GetTotalPriceByCustomerID (@CustomerID int)
RETURNS int
AS
BEGIN
    DECLARE @TotalCustomerPrice int;

    SELECT @TotalCustomerPrice = SUM(dbo.GetTotalPriceByOrderID(o.OrderID))
    FROM Customer c
    INNER JOIN [Order] o ON c.CustomerID = o.CustomerID
    WHERE c.CustomerID = @CustomerID;

    -- If the customer has no orders, return 0 or handle as needed
    IF @TotalCustomerPrice IS NULL
        SET @TotalCustomerPrice = 0;

    RETURN @TotalCustomerPrice;
END
GO

-- Function to get number of orders by CustomerID
CREATE FUNCTION GetNumberOfOrdersByCustomerID (@CustomerID int)
RETURNS int
AS
BEGIN
    DECLARE @NumberOfOrders int;

    SELECT @NumberOfOrders = COUNT(*)
    FROM [Order] o
    WHERE o.CustomerID = @CustomerID;

    RETURN @NumberOfOrders;
END
GO

-- Function to get the price of a product with promotion
CREATE FUNCTION GetProductPriceWithPromotion (@ProductID int)
RETURNS int
AS
BEGIN
    DECLARE @ProductPrice int;
    DECLARE @DiscountPercentage int;
    DECLARE @DiscountAmount int;
    DECLARE @FinalPrice int;
    DECLARE @CurrentDate date = GETDATE();

    -- Get the base price of the product
    SELECT @ProductPrice = Price
    FROM Product
    WHERE ProductID = @ProductID;

    IF @ProductPrice IS NULL
    BEGIN
        RETURN NULL; -- Or handle the case where the product doesn't exist
    END

    -- Get the active promotion details for the product
    SELECT TOP 1 @DiscountPercentage = DiscountPercentage, @DiscountAmount = DiscountAmount
    FROM Promotion
    WHERE ProductID = @ProductID
      AND StartDate <= @CurrentDate
      AND (EndDate >= @CurrentDate OR EndDate IS NULL)
    ORDER BY StartDate DESC; -- In case of multiple active promotions, take the latest start date

    -- Calculate the final price based on the promotion
    IF @DiscountPercentage IS NOT NULL AND @DiscountPercentage > 0
    BEGIN
        SET @FinalPrice = @ProductPrice - (@ProductPrice * @DiscountPercentage / 100);
    END
    ELSE IF @DiscountAmount IS NOT NULL AND @DiscountAmount > 0
    BEGIN
        SET @FinalPrice = @ProductPrice - @DiscountAmount;
    END
    ELSE
    BEGIN
        SET @FinalPrice = @ProductPrice; -- No active promotion
    END

    -- Ensure the final price is not negative
    IF @FinalPrice < 0
        SET @FinalPrice = 0;

    RETURN @FinalPrice;
END
GO

-- Stored procedure

-- Procedure to insert data into Product table with StockQuantity automatically set to 0 (after removing SupplierID)
CREATE PROCEDURE InsertProductWithZeroStock (
    @ProductName nvarchar(250),
    @Description nvarchar(250),
    @Brand nvarchar(250) = NULL,
    @Price int,
    @Unit varchar(50) = NULL,
    @ImageURL TEXT,
    @CategoryID int
)
AS
BEGIN
    -- Check if the CategoryID exists
    IF NOT EXISTS (SELECT 1 FROM Category WHERE CategoryID = @CategoryID)
    BEGIN
        RAISERROR('Category with the specified CategoryID does not exist.', 16, 1)
        RETURN
    END

    -- Insert data into Product table with StockQuantity set to 0
    INSERT INTO Product (ProductName, Description, Brand, Price, StockQuantity, Unit, ImageURL, CategoryID)
    VALUES (@ProductName, @Description, @Brand, @Price, 0, @Unit, @ImageURL, @CategoryID);
END
GO

-- Procedure to insert data into Inventory table and automatically increase StockQuantity in Product table
CREATE PROCEDURE InsertInventory (
    @QuantityReceived int,
    @ReceivedDate date,
    @SupplierID int,
    @ProductID int
)
AS
BEGIN
    -- Check if the ProductID exists
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR('Product with the specified ProductID does not exist.', 16, 1)
        RETURN
    END

    -- Check if the SupplierID exists
    IF NOT EXISTS (SELECT 1 FROM Supplier WHERE SupplierID = @SupplierID)
    BEGIN
        RAISERROR('Supplier with the specified SupplierID does not exist.', 16, 1)
        RETURN
    END

    -- Insert data into Inventory table
    INSERT INTO Inventory (QuantityReceived, ReceivedDate, SupplierID, ProductID)
    VALUES (@QuantityReceived, @ReceivedDate, @SupplierID, @ProductID);

    -- Increase StockQuantity in Product table
    UPDATE Product
    SET StockQuantity = StockQuantity + @QuantityReceived
    WHERE ProductID = @ProductID;
END
GO

-- Procedure to insert data into OrderItems table with automatic price and stock quantity adjustment
CREATE PROCEDURE InsertOrderItem (
    @ProductID int,
    @OrderID int,
    @Quantity int
)
AS
BEGIN
    -- Check if the ProductID exists
    IF NOT EXISTS (SELECT 1 FROM Product WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR('Product with the specified ProductID does not exist.', 16, 1)
        RETURN
    END

    -- Check if the OrderID exists
    IF NOT EXISTS (SELECT 1 FROM [Order] WHERE OrderID = @OrderID)
    BEGIN
        RAISERROR('Order with the specified OrderID does not exist.', 16, 1)
        RETURN
    END

    -- Get the current StockQuantity
    DECLARE @CurrentStockQuantity int;
    SELECT @CurrentStockQuantity = StockQuantity
    FROM Product
    WHERE ProductID = @ProductID;

    -- Adjust Quantity if it's more than StockQuantity
    IF @Quantity > @CurrentStockQuantity
    BEGIN
        SET @Quantity = @CurrentStockQuantity;
        IF @Quantity = 0
        BEGIN
            RAISERROR('Stock quantity is 0 for this product.', 16, 1)
            RETURN
        END
    END

    -- Get the price with promotion
    DECLARE @ProductPriceWithPromotion int;
    SELECT @ProductPriceWithPromotion = dbo.GetProductPriceWithPromotion(@ProductID);

    -- Insert data into OrderItems table
    INSERT INTO OrderItems (ProductID, OrderID, Quantity, Price)
    VALUES (@ProductID, @OrderID, @Quantity, @ProductPriceWithPromotion);

    -- Decrease StockQuantity in Product table
    UPDATE Product
    SET StockQuantity = StockQuantity - @Quantity
    WHERE ProductID = @ProductID;
END
GO

-- Supplier
INSERT INTO Supplier (SupplierName, PhoneNumber, Email, Address, City) VALUES
('Vinamilk', '0901234567', 'info@vinamilk.com.vn', 'No. 10 Tan Trao Street', 'Ho Chi Minh City'),
('TH True Milk', '0987654321', 'contact@thtruemilk.vn', '166 Nguyen Thai Hoc Street', 'Hanoi'),
('Unilever', '0911223344', 'customer.care@unilever.com', '203B Ly Thuong Kiet Street', 'Da Nang');

-- Customer
INSERT INTO Customer (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, RegistrationDate) VALUES
('Nguyen', 'Van A', 'Male', '0903334455', 'vana.nguyen@example.com', '123 Tran Hung Dao Street', 'Can Tho', '2025-03-15'),
('Le', 'Thi B', 'Female', '0912223344', 'thib.le@example.com', '456 30 Thang 4 Street', 'Can Tho', '2025-03-20'),
('Tran', 'Ngoc C', 'Female', '0977778899', 'ngocc.tran@example.com', '789 Nguyen Van Cu Street', 'Ho Chi Minh City', '2025-03-22');

-- Employee
INSERT INTO Employee (FirstName, LastName, Gender, PhoneNumber, Email, Address, City, HireDate, JobTitle, Department, Salary) VALUES
('Pham', 'Duc D', 'Male', '0909990011', 'ducd.pham@example.com', '321 Vo Van Kiet Street', 'Can Tho', '2024-12-01', 'Manager', 'Sales', 15000000),
('Hoang', 'Thu E', 'Female', '0933334455', 'thue.hoang@example.com', '654 Nguyen Trai Street', 'Can Tho', '2025-01-15', 'Cashier', 'Operations', 8000000);

-- ShippingProvider
INSERT INTO ShippingProvider (ProviderName, PhoneNumber, Email) VALUES
('Giao Hang Nhanh', '1900636677', 'cskh@ghn.vn'),
('Viettel Post', '19008095', 'support@viettelpost.com.vn');

-- Category
INSERT INTO Category (CategoryName, description) VALUES
('Dairy & Eggs', 'Milk, yogurt, cheese, eggs'),
('Fruits & Vegetables', 'Fresh produce'),
('Pantry', 'Canned goods, pasta, rice'),
('Beverages', 'Juice, soda, water');

-- Product
INSERT INTO Product (ProductName, Description, Brand, Price, StockQuantity, Unit, ImageURL, CategoryID) VALUES
('Fresh Milk', 'Pasteurized fresh cow milk', 'Vinamilk', 35000, 100, '1 liter', 'url_vinamilk_fresh_milk', 1),
('Yogurt - Strawberry', 'Strawberry flavored yogurt', 'TH True Milk', 15000, 150, '180g', 'url_th_yogurt_strawberry', 1),
('Apples - Fuji', 'Sweet and crisp Fuji apples', 'USA', 30000, 200, '1 kg', 'url_fuji_apples', 2),
('Bananas', 'Ripe yellow bananas', 'Vietnam', 15000, 300, '1 kg', 'url_vietnam_bananas', 2),
('Rice - Jasmine', 'Fragrant Jasmine rice', 'Tien Vua', 25000, 500, '5 kg', 'url_jasmine_rice', 3),
('Canned Sardines in Tomato Sauce', 'Sardines in rich tomato sauce', 'Ba Cay Tre', 18000, 400, '155g', 'url_canned_sardines', 3),
('Orange Juice', '100% pure orange juice', 'Minute Maid', 20000, 250, '1 liter', 'url_orange_juice', 4),
('Coca-Cola', 'Classic carbonated soft drink', 'Coca-Cola', 10000, 600, '330ml', 'url_coca_cola', 4);

-- Inventory
INSERT INTO Inventory (QuantityReceived, ReceivedDate, SupplierID, ProductID) VALUES
(120, '2025-03-20', 1, 1), -- Vinamilk supplied Fresh Milk
(180, '2025-03-22', 2, 2), -- TH True Milk supplied Yogurt
(250, '2025-03-23', 3, 3), -- Unilever (as a placeholder for fruit supplier) supplied Apples
(350, '2025-03-24', 3, 4), -- Unilever (as a placeholder for fruit supplier) supplied Bananas
(550, '2025-03-25', 3, 5), -- Unilever (as a placeholder for rice supplier) supplied Rice
(450, '2025-03-25', 3, 6), -- Unilever (as a placeholder for canned goods supplier) supplied Sardines
(300, '2025-03-25', 3, 7), -- Unilever (as a placeholder for beverage supplier) supplied Orange Juice
(650, '2025-03-25', 3, 8); -- Unilever (as a placeholder for beverage supplier) supplied Coca-Cola

-- Order
INSERT INTO [Order] (OrderDate, ShippingAddress, ShippingCity, Status, TotalAmount, PaymentMethod, PromisedDate, ShippingFees, TrackingCode, EmployeeID, CustomerID, ProviderID) VALUES
('2025-03-25', '123 Tran Hung Dao Street', 'Can Tho', 'Delivered', 70000, 'Cash', '2025-03-27', 15000, 'GHN12345', 1, 1, 1), -- Customer A ordered something
('2025-03-26', '456 30 Thang 4 Street', 'Can Tho', 'Processing', 30000, 'Credit Card', '2025-03-28', 10000, 'VTP67890', 2, 2, 2); -- Customer B placed an order

-- OrderItems
INSERT INTO OrderItems (ProductID, OrderID, Quantity, Price) VALUES
(1, 1, 2, 35000), -- 2 x Fresh Milk in Order 1
(2, 2, 2, 15000); -- 2 x Yogurt in Order 2

-- Promotion
INSERT INTO Promotion (DiscountPercentage, DiscountAmount, StartDate, EndDate, Description, ProductID) VALUES
(10, 0, '2025-03-20', '2025-03-31', '10% off on Fresh Milk', 1),
(0, 5000, '2025-03-25', NULL, '5000 VND off on Fuji Apples', 3);