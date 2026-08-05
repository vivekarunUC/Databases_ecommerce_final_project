
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS PurchaseItem;
DROP TABLE IF EXISTS Purchase;
DROP TABLE IF EXISTS CreditCard;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Staff;
DROP TABLE IF EXISTS Customer;

CREATE TABLE Customer (
    CustomerID INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName TEXT NOT NULL,
    LastName TEXT NOT NULL,
    Email TEXT NOT NULL UNIQUE,
    Phone TEXT,
    CreatedAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE CreditCard (
    CardID INTEGER PRIMARY KEY AUTOINCREMENT,
    CustomerID INTEGER NOT NULL,
    CardholderName TEXT NOT NULL,
    LastFour TEXT NOT NULL CHECK (length(LastFour) = 4),
    ExpMonth INTEGER NOT NULL CHECK (ExpMonth BETWEEN 1 AND 12),
    ExpYear INTEGER NOT NULL CHECK (ExpYear >= 2026),
    BillingZip TEXT NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Staff (
    StaffID INTEGER PRIMARY KEY AUTOINCREMENT,
    FirstName TEXT NOT NULL,
    LastName TEXT NOT NULL,
    Email TEXT NOT NULL UNIQUE,
    Role TEXT NOT NULL
);

CREATE TABLE Product (
    ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    Description TEXT,
    Category TEXT NOT NULL,
    Price REAL NOT NULL CHECK (Price >= 0),
    StockQuantity INTEGER NOT NULL DEFAULT 0 CHECK (StockQuantity >= 0),
    IsActive INTEGER NOT NULL DEFAULT 1 CHECK (IsActive IN (0, 1))
);

CREATE TABLE Purchase (
    PurchaseID INTEGER PRIMARY KEY AUTOINCREMENT,
    CustomerID INTEGER NOT NULL,
    StaffID INTEGER,
    PurchaseDate TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status TEXT NOT NULL DEFAULT 'Paid'
        CHECK (Status IN ('Pending', 'Paid', 'Shipped', 'Completed', 'Cancelled')),
    TotalAmount REAL NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (StaffID) REFERENCES Staff(StaffID)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE PurchaseItem (
    PurchaseID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL CHECK (Quantity > 0),
    UnitPrice REAL NOT NULL CHECK (UnitPrice >= 0),
    PRIMARY KEY (PurchaseID, ProductID),
    FOREIGN KEY (PurchaseID) REFERENCES Purchase(PurchaseID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_product_name ON Product(Name);
CREATE INDEX idx_product_category ON Product(Category);
CREATE INDEX idx_purchase_customer ON Purchase(CustomerID);
CREATE INDEX idx_purchase_date ON Purchase(PurchaseDate);

INSERT INTO Customer (FirstName, LastName, Email, Phone) VALUES
('Maya', 'Patel', 'maya.patel@example.com', '513-555-0101'),
('Jordan', 'Lee', 'jordan.lee@example.com', '513-555-0102'),
('Alex', 'Morgan', 'alex.morgan@example.com', '513-555-0103'),
('Sofia', 'Garcia', 'sofia.garcia@example.com', '513-555-0104');

INSERT INTO CreditCard (CustomerID, CardholderName, LastFour, ExpMonth, ExpYear, BillingZip) VALUES
(1, 'Maya Patel', '4242', 8, 2028, '45219'),
(1, 'Maya Patel', '1881', 3, 2029, '45219'),
(2, 'Jordan Lee', '5556', 11, 2027, '45220'),
(3, 'Alex Morgan', '9010', 5, 2030, '45202');

INSERT INTO Staff (FirstName, LastName, Email, Role) VALUES
('Taylor', 'Brooks', 'taylor.brooks@store.com', 'Inventory Manager'),
('Chris', 'Nguyen', 'chris.nguyen@store.com', 'Sales Associate'),
('Morgan', 'Reed', 'morgan.reed@store.com', 'Store Manager');

INSERT INTO Product (Name, Description, Category, Price, StockQuantity, IsActive) VALUES
('Wireless Mechanical Keyboard', 'Compact keyboard with Bluetooth and RGB backlighting.', 'Electronics', 119.99, 14, 1),
('Noise-Canceling Headphones', 'Over-ear headphones with active noise cancellation.', 'Electronics', 249.99, 8, 1),
('Stainless Steel Water Bottle', 'Insulated 24-ounce reusable bottle.', 'Home', 29.50, 30, 1),
('Laptop Backpack', 'Water-resistant backpack with padded laptop compartment.', 'Accessories', 74.95, 20, 1),
('USB-C Hub', 'Seven-port hub with HDMI, USB, and card reader.', 'Electronics', 54.99, 25, 1),
('Desk Lamp', 'Adjustable LED desk lamp with USB charging port.', 'Home', 44.00, 16, 1),
('Discontinued Phone Stand', 'Older model phone stand.', 'Accessories', 12.99, 0, 0);

INSERT INTO Purchase (CustomerID, StaffID, PurchaseDate, Status, TotalAmount) VALUES
(1, 2, '2026-07-20 14:30:00', 'Completed', 174.98),
(2, 2, '2026-07-22 10:15:00', 'Shipped', 249.99),
(1, 3, '2026-07-25 16:40:00', 'Paid', 104.45),
(3, NULL, '2026-07-28 09:05:00', 'Paid', 163.99);

INSERT INTO PurchaseItem (PurchaseID, ProductID, Quantity, UnitPrice) VALUES
(1, 1, 1, 119.99),
(1, 5, 1, 54.99),
(2, 2, 1, 249.99),
(3, 3, 1, 29.50),
(3, 4, 1, 74.95),
(4, 1, 1, 119.99),
(4, 6, 1, 44.00);
