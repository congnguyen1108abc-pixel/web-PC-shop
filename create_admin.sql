-- ============================================================
-- TẠO TÀI KHOẢN ADMIN
-- Database: PC_Store
-- Chạy script này trong SQL Server Management Studio (SSMS)
-- ============================================================

USE PC_Store;
GO

-- Kiểm tra email đã tồn tại chưa
IF EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@hypercore.vn')
BEGIN
    PRINT N'Email đã tồn tại. Đang cập nhật Role thành Admin...';
    UPDATE Users
    SET Role = 'Admin', IsActive = 1
    WHERE Email = 'admin@hypercore.vn';
    PRINT N'Đã cập nhật xong.';
END
ELSE
BEGIN
    -- INSERT tài khoản admin mới
    -- Password: Admin@123  →  SHA256 hash (giống hệt C# AuthController)
    INSERT INTO Users (FullName, Email, PasswordHash, PhoneNumber, LoginProvider, Role, IsActive)
    VALUES (
        N'Super Admin',
        'admin@hypercore.vn',
        'e86f78a8a3caf0b60d8e74e5942aa6d86dc150cd3c03338aef25b7d2d7e3acc7',
        '0900000000',
        'Local',
        'Admin',
        1
    );
    PRINT N'Tạo tài khoản Admin thành công! UserID = ' + CAST(SCOPE_IDENTITY() AS NVARCHAR);
END
GO

-- Xác nhận kết quả
SELECT UserID, FullName, Email, Role, IsActive, CreatedAt
FROM Users
WHERE Email = 'admin@hypercore.vn';
GO
