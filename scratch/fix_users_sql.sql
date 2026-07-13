-- 1. Thêm cột Ngân hàng vào bảng Users nếu chưa tồn tại
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'BankName')
BEGIN
    ALTER TABLE Users ADD BankName NVARCHAR(100) NULL;
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'BankAccountNumber')
BEGIN
    ALTER TABLE Users ADD BankAccountNumber NVARCHAR(50) NULL;
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'BankAccountName')
BEGIN
    ALTER TABLE Users ADD BankAccountName NVARCHAR(100) NULL;
END
GO

-- 2. Tạo hoặc sửa sp_User_UpdateBank
CREATE OR ALTER PROCEDURE sp_User_UpdateBank
    @UserId INT,
    @BankName NVARCHAR(100),
    @BankAccountNumber NVARCHAR(50),
    @BankAccountName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users
    SET BankName = @BankName,
        BankAccountNumber = @BankAccountNumber,
        BankAccountName = @BankAccountName,
        UpdatedAt = GETDATE()
    WHERE UserID = @UserId;
    
    SELECT @UserId AS UpdatedUserId;
END;
GO

-- 3. Sửa sp_Admin_GetUsers
CREATE OR ALTER PROCEDURE sp_Admin_GetUsers
    @Role      NVARCHAR(20) = NULL,
    @IsActive  BIT = NULL,
    @Keyword   NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.UserID,
        u.FullName,
        u.Email,
        u.PhoneNumber,
        u.AvatarURL,
        u.Role,
        u.IsActive,
        u.CreatedAt,
        u.UpdatedAt,
        COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) AS TotalSpent,
        CASE 
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 100000000 THEN N'Kim Cương'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 50000000 THEN N'Vàng'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 30000000 THEN N'Bạc'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 10000000 THEN N'Đồng'
            ELSE N'Chưa phân hạng'
        END AS MembershipTier,
        (SELECT COUNT(*) FROM Orders o WHERE o.UserID = u.UserID AND o.DiscountAmount > 0 AND o.Status = N'Hoàn tất') AS LoyaltyDiscountUses
    FROM Users u
    WHERE (@Role IS NULL OR u.Role = @Role)
      AND (@IsActive IS NULL OR u.IsActive = @IsActive)
      AND
      (
          @Keyword IS NULL
          OR u.FullName LIKE N'%' + @Keyword + N'%'
          OR u.Email LIKE N'%' + @Keyword + N'%'
          OR u.PhoneNumber LIKE N'%' + @Keyword + N'%'
      )
    ORDER BY u.CreatedAt DESC, u.UserID DESC;
END;
GO

-- 4. Sửa sp_Admin_GetUserDetail
CREATE OR ALTER PROCEDURE dbo.sp_Admin_GetUserDetail
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.UserID,
        u.FullName,
        u.Email,
        u.PhoneNumber,
        u.AvatarURL,
        u.Role,
        u.IsActive,
        u.CreatedAt,
        u.UpdatedAt,
        COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) AS TotalSpent,
        CASE 
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 100000000 THEN N'Kim Cương'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 50000000 THEN N'Vàng'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 30000000 THEN N'Bạc'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 10000000 THEN N'Đồng'
            ELSE N'Chưa phân hạng'
        END AS MembershipTier,
        (SELECT COUNT(*) FROM Orders o WHERE o.UserID = u.UserID AND o.DiscountAmount > 0 AND o.Status = N'Hoàn tất') AS LoyaltyDiscountUses
    FROM dbo.Users u
    WHERE u.UserID = @UserID;

    SELECT
        ur.UserRoleID,
        ur.UserID,
        ur.RoleCode,
        rp.RoleName,
        rp.Description,
        rp.IsActive AS PermissionIsActive,
        ur.AssignedAt,
        ur.AssignedBy,
        ab.FullName AS AssignedByName
    FROM dbo.UserRoles ur
    LEFT JOIN dbo.RolePermissions rp
        ON ur.RoleCode = rp.RoleCode
    LEFT JOIN dbo.Users ab
        ON ur.AssignedBy = ab.UserID
    WHERE ur.UserID = @UserID
    ORDER BY ur.AssignedAt DESC, ur.UserRoleID DESC;

    SELECT
        AddressID,
        UserID,
        ReceiverName,
        PhoneNumber,
        Province,
        District,
        Ward,
        DetailAddress,
        IsDefault,
        CreatedAt
    FROM dbo.UserAddresses
    WHERE UserID = @UserID
    ORDER BY IsDefault DESC, CreatedAt DESC;
END;
GO

-- 5. Sửa sp_User_GetProfile
CREATE OR ALTER PROCEDURE sp_User_GetProfile
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.UserID,
        u.FullName,
        u.Email,
        u.PhoneNumber,
        u.AvatarURL,
        u.Role,
        u.IsActive,
        u.CreatedAt,
        u.UpdatedAt,
        COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) AS TotalSpent,
        CASE 
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 100000000 THEN N'Kim Cương'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 50000000 THEN N'Vàng'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 30000000 THEN N'Bạc'
            WHEN COALESCE((SELECT SUM(o.FinalAmount) FROM Orders o WHERE o.UserID = u.UserID AND o.Status = N'Hoàn tất'), 0) >= 10000000 THEN N'Đồng'
            ELSE N'Chưa phân hạng'
        END AS MembershipTier,
        (SELECT COUNT(*) FROM Orders o WHERE o.UserID = u.UserID AND o.DiscountAmount > 0 AND o.Status = N'Hoàn tất') AS LoyaltyDiscountUses,
        u.BankName,
        u.BankAccountNumber,
        u.BankAccountName
    FROM Users u
    WHERE u.UserID = @UserID;
END;
GO
