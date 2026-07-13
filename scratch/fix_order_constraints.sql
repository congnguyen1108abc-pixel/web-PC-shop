-- Drop status check constraint
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK__Orders__Status__22751F6C')
BEGIN
    ALTER TABLE Orders DROP CONSTRAINT CK__Orders__Status__22751F6C;
END

-- Drop payment status check constraint
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK__Orders__PaymentS__245D67DE')
BEGIN
    ALTER TABLE Orders DROP CONSTRAINT CK__Orders__PaymentS__245D67DE;
END

-- Recreate with correct Unicode values
ALTER TABLE Orders ADD CONSTRAINT CK_Orders_Status CHECK (Status IN (N'Chờ xác nhận', N'Đã xác nhận', N'Đang giao', N'Hoàn tất', N'Đã hủy'));
ALTER TABLE Orders ADD CONSTRAINT CK_Orders_PaymentStatus CHECK (PaymentStatus IN (N'Chưa thanh toán', N'Đã thanh toán', N'Hoàn tiền'));
