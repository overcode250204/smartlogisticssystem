-- 1. Bảng Phân quyền (Roles)
CREATE TABLE Roles (
    RoleID SERIAL PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL,
    Description VARCHAR(255)
);

-- 2. Bảng Người dùng (Users)
CREATE TABLE Users (
    UserID SERIAL PRIMARY KEY,
    RoleID INT NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    Phone VARCHAR(20),
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID)
);

-- 3. Bảng Nhà cung cấp (Suppliers)
CREATE TABLE Suppliers (
    SupplierID SERIAL PRIMARY KEY,
    SupplierName VARCHAR(150) NOT NULL,
    ContactPhone VARCHAR(20),
    Address VARCHAR(255),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng Sản phẩm (Products)
CREATE TABLE Products (
    ProductID SERIAL PRIMARY KEY,
    SupplierID INT NOT NULL,
    ProductCode VARCHAR(50) UNIQUE NOT NULL,
    ProductName VARCHAR(150) NOT NULL,
    MinStockLevel INT DEFAULT 10,
    Price DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- 5. Bảng Lô hàng Tồn kho (Inventory Batches)
CREATE TABLE InventoryBatches (
    BatchID SERIAL PRIMARY KEY,
    ProductID INT NOT NULL,
    ImportDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ExpirationDate TIMESTAMP,
    Quantity INT NOT NULL,
    Status VARCHAR(50) DEFAULT 'Good',
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- 6. Bảng Hóa đơn Tài chính (Invoices)
CREATE TABLE Invoices (
    InvoiceID SERIAL PRIMARY KEY,
    InvoiceType VARCHAR(50) NOT NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    CreatedBy INT NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

-- 7. Bảng Đơn giao hàng (Orders)
CREATE TABLE Orders (
    OrderID SERIAL PRIMARY KEY,
    DriverID INT,
    DestinationAddress VARCHAR(255) NOT NULL,
    OrderStatus VARCHAR(50) DEFAULT 'Pending',
    TotalWeight DECIMAL(10,2),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (DriverID) REFERENCES Users(UserID)
);

-- 8. Bảng Theo dõi Tọa độ (OrderTracking)
CREATE TABLE OrderTracking (
    TrackingID SERIAL PRIMARY KEY,
    OrderID INT NOT NULL,
    Latitude DECIMAL(10,8) NOT NULL,
    Longitude DECIMAL(11,8) NOT NULL,
    RecordedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Note VARCHAR(255),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- ==========================================
-- ĐỔ DỮ LIỆU MẪU (MOCK DATA)
-- ==========================================

INSERT INTO Roles (RoleName, Description) VALUES 
('Admin', 'Quản trị viên toàn hệ thống'),
('WarehouseManager', 'Quản lý kho bãi'),
('Driver', 'Tài xế giao hàng');

INSERT INTO Users (RoleID, FullName, Email, PasswordHash, Phone) VALUES 
(1, 'Nguyễn Văn Quản Trị', 'admin@logistics.com', 'hashed_pw_123', '0901111111'),
(2, 'Trần Thủ Kho', 'thukho@logistics.com', 'hashed_pw_123', '0902222222'),
(3, 'Lê Văn Tài Xế', 'taixe1@logistics.com', 'hashed_pw_123', '0903333333');

INSERT INTO Suppliers (SupplierName, ContactPhone, Address) VALUES 
('Công ty Điện tử Samsung', '1800588889', 'Khu công nghệ cao, Quận 9'),
('Công ty Nhựa Duy Tân', '0283933333', 'Bình Tân, TP.HCM');

INSERT INTO Products (SupplierID, ProductCode, ProductName, MinStockLevel, Price) VALUES 
(1, 'SS-TV-55', 'Smart TV Samsung 55 Inch', 5, 12000000),
(2, 'DT-BX-01', 'Thùng nhựa chứa hàng 50L', 50, 150000);

INSERT INTO InventoryBatches (ProductID, Quantity, Status) VALUES 
(1, 20, 'Good'),
(1, 2, 'Damaged'),
(2, 100, 'Good');

INSERT INTO Invoices (InvoiceType, TotalAmount, CreatedBy) VALUES 
('Import', 240000000, 2),
('Import', 15000000, 2);

INSERT INTO Orders (DriverID, DestinationAddress, OrderStatus, TotalWeight) VALUES 
(3, 'Siêu thị Điện máy Xanh, Quận 1, TP.HCM', 'Delivering', 150.5);

INSERT INTO OrderTracking (OrderID, Latitude, Longitude, Note) VALUES 
(1, 10.762622, 106.660172, 'Rời khỏi kho'),
(1, 10.771121, 106.671112, 'Đang di chuyển trên đường 3/2');