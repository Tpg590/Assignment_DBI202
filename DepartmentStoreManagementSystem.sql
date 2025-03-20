Use master

-- ALTER DATABASE DepartmentStoreManagementSystem SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

drop database if exists DepartmentStoreManagementSystem

create database DepartmentStoreManagementSystem

use DepartmentStoreManagementSystem


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