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
	HireDate date,
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



create table Producted(
	ProductID int identity(1,1) primary key,
	ProductName nvarchar(250) NOT NULL,
	Description nvarchar(250) NOT NULL,
	Brand nvarchar(250),
	Price int NOT NULL,
	StockQuanlity nvarchar(250) NOT NULL,
	Unit varchar(50),
	ImageURL TEXT NOT NULL,
	CategoryID int,
	SupplierID int,
	foreign key (CategoryID) references Category(CategoryID),
	foreign key (SupplierID) references Supplier(SupplierID)
)

create table Inventory(
	InventoryID int identity(1,1) primary key,
	QuantityReceived varchar(250),
	ReceivedDate date,
	SupplierID int references Supplier(SupplierID),
	ProductID int references Producted(ProductID)
)


Create table Ordered(
	OrderID int identity(1,1) primary key,
	OrderDate date,
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

create table Contain(
	ContainID int identity(1,1) primary key,
	Quanlity varchar(250),
	ProductID int references Producted(ProductID),
	OrderID int references Ordered(OrderID)
)

Create table Promotion(
	PromotionID int identity(1,1) primary key,
	DiscountPercentage int NOT NULL,
	DiscountAmount int NOT NULL,
	StartDate date,
	EndDate date,
	Description nvarchar(250),
	ProductID int  references Producted(ProductID)
)