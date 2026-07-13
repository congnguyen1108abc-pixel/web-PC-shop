-- ----------------------------------------------------------------------------
-- SEED MOCK COMPLETED TRANSACTIONS FOR DATA MINING (HUIM) DEMO
-- ----------------------------------------------------------------------------
DECLARE @UserID INT = 4;
DECLARE @OrderID INT;

-- Đơn hàng 1: CPU i5 (4) + Mainboard B760 (8)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 7480000.00, 0, 7480000.00, N'Hà Nội', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 4, 1, 4590000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 8, 1, 2890000.00);

-- Đơn hàng 2: CPU i5 (4) + Mainboard B760 (8) + RTX 4060 (1)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 16470000.00, 0, 16470000.00, N'Hà Nội', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 4, 1, 4590000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 8, 1, 2890000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 1, 1, 8990000.00);

-- Đơn hàng 3: CPU i5 (4) + Mainboard B760 (8)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 7480000.00, 0, 7480000.00, N'Hà Nội', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 4, 1, 4590000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 8, 1, 2890000.00);

-- Đơn hàng 4: CPU i5 (4) + Mainboard B760 (8) + RTX 4060 (1)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 16470000.00, 0, 16470000.00, N'Hà Nội', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 4, 1, 4590000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 8, 1, 2890000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 1, 1, 8990000.00);

-- Đơn hàng 5: Ryzen 5 (6) + B550M (9)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 5880000.00, 0, 5880000.00, N'Đà Nẵng', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 6, 1, 2890000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 9, 1, 2990000.00);

-- Đơn hàng 6: Ryzen 5 (6) + B550M (9)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 5880000.00, 0, 5880000.00, N'Đà Nẵng', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 6, 1, 2890000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 9, 1, 2990000.00);

-- Đơn hàng 7: Ryzen 5 (6) + B550M (9) + RTX 4060 Ti (2)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 17870000.00, 0, 17870000.00, N'Đà Nẵng', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 6, 1, 2890000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 9, 1, 2990000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 2, 1, 11990000.00);

-- Đơn hàng 8: CPU i5 (4) + RTX 4060 (1)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 13580000.00, 0, 13580000.00, N'TP HCM', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 4, 1, 4590000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 1, 1, 8990000.00);

-- Đơn hàng 9: CPU i5 (4) + RTX 4060 (1)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 13580000.00, 0, 13580000.00, N'TP HCM', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 4, 1, 4590000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 1, 1, 8990000.00);

-- Đơn hàng 10: Mainboard B760 (8) + RTX 4060 (1)
INSERT INTO Orders (UserID, TotalAmount, DiscountAmount, FinalAmount, ShippingAddress, PaymentMethod, Status, PaymentStatus, OrderDate)
VALUES (@UserID, 11880000.00, 0, 11880000.00, N'TP HCM', 'COD', N'Hoàn tất', N'Đã thanh toán', GETDATE());
SET @OrderID = SCOPE_IDENTITY();
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 8, 1, 2890000.00);
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice) VALUES (@OrderID, 1, 1, 8990000.00);

PRINT '✅ Successfully seeded completed transactions!';
GO
