-- ============================================================
--   PC STORE - FILE DATABASE ĐÃ SẮP XẾP GỌN
--   Thứ tự: TABLES -> INDEXES -> TRIGGERS -> STORED PROCEDURES
--   Lưu ý: Chỉ sắp xếp lại vị trí và thêm comment mô tả SP, không sửa logic code gốc.
--   Tổng hợp theo file: 24 Tables, 27 Indexes thủ công, 10 Triggers, 107 Stored Procedures.
-- ============================================================

-- ============================================================================
-- PHẦN 0: CREATE DATABASE / USE DATABASE
-- ============================================================================


CREATE DATABASE PC_Store;
GO
USE PC_Store;
GO

-- ============================================================================
-- PHẦN 1: TABLES
-- ============================================================================

-- [TABLE 01] Dòng gốc: 11-24

-----------------------------------------------------------
-- PHẦN 1: TẠO BẢNG (20 TABLES)
-----------------------------------------------------------

-- 1. Bảng Thương hiệu
CREATE TABLE Brands (
    BrandID     INT PRIMARY KEY IDENTITY(1,1),
    BrandName   NVARCHAR(100) NOT NULL,
    LogoURL     NVARCHAR(500),
    Description NVARCHAR(MAX),
    IsActive    BIT DEFAULT 1,
    CreatedAt   DATETIME DEFAULT GETDATE()
);
GO

-- [TABLE 02] Dòng gốc: 26-35

-- 2. Bảng Danh mục (hỗ trợ danh mục cha - con)
CREATE TABLE Categories (
    CategoryID   INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL,
    ParentID     INT NULL REFERENCES Categories(CategoryID),
    IconURL      NVARCHAR(500) NULL,
    SortOrder    INT DEFAULT 0,
    IsActive     BIT DEFAULT 1
);
GO

-- [TABLE 03] Dòng gốc: 37-52

-- 3. Bảng Người dùng (Admin & Customer)
CREATE TABLE Users (
    UserID        INT PRIMARY KEY IDENTITY(1,1),
    FullName      NVARCHAR(100),
    Email         NVARCHAR(100) UNIQUE NOT NULL,
    PasswordHash  NVARCHAR(MAX) NULL,
    LoginProvider NVARCHAR(20)  DEFAULT 'Local',   -- 'Local' hoặc 'Google'
    ProviderKey   NVARCHAR(MAX) NULL,
    PhoneNumber   NVARCHAR(15)  NULL,
    AvatarURL     NVARCHAR(500) NULL,
    Role          NVARCHAR(20)  DEFAULT 'Customer' CHECK (Role IN ('Admin', 'Staff', 'Customer')),
    IsActive      BIT           DEFAULT 1,
    CreatedAt     DATETIME      DEFAULT GETDATE(),
    UpdatedAt     DATETIME      NULL
);
GO

-- [TABLE 04] Dòng gốc: 54-67

-- 4.  Bảng Địa chỉ giao hàng (Tách riêng để hỗ trợ nhiều địa chỉ/user)
CREATE TABLE UserAddresses (
    AddressID     INT PRIMARY KEY IDENTITY(1,1),
    UserID        INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    ReceiverName  NVARCHAR(100) NOT NULL,
    PhoneNumber   NVARCHAR(15)  NOT NULL,
    Province      NVARCHAR(100) NOT NULL,
    District      NVARCHAR(100) NOT NULL,
    Ward          NVARCHAR(100) NOT NULL,
    DetailAddress NVARCHAR(255) NOT NULL,
    IsDefault     BIT           DEFAULT 0,
    CreatedAt     DATETIME      DEFAULT GETDATE()
);
GO

-- [TABLE 05] Dòng gốc: 69-86

-- 5. Bảng Sản phẩm
CREATE TABLE Products (
    ProductID      INT PRIMARY KEY IDENTITY(1,1),
    CategoryID     INT FOREIGN KEY REFERENCES Categories(CategoryID),
    BrandID        INT FOREIGN KEY REFERENCES Brands(BrandID),
    SKU            NVARCHAR(50)    UNIQUE NOT NULL,
    ProductName    NVARCHAR(255)   NOT NULL,
    Price          DECIMAL(18, 2)  NOT NULL CHECK (Price >= 0),
    DiscountPrice  DECIMAL(18, 2)  DEFAULT 0 CHECK (DiscountPrice >= 0),
    StockQuantity  INT             DEFAULT 0 CHECK (StockQuantity >= 0),
    SoldCount      INT             DEFAULT 0,   -- [MỚI] Đếm số đã bán, dùng cho "Bán chạy"
    Description    NVARCHAR(MAX),
    IsActive       BIT             DEFAULT 1,
    WarrantyMonths INT             DEFAULT 12 CHECK (WarrantyMonths >= 0),
    CreatedAt      DATETIME        DEFAULT GETDATE(),
    UpdatedAt      DATETIME        NULL
);
GO

-- [TABLE 06] Dòng gốc: 88-97

-- 6. Bảng Thư viện ảnh sản phẩm
CREATE TABLE ProductImages (
    ImageID   INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID) ON DELETE CASCADE,
    ImageURL  NVARCHAR(500) NOT NULL,
    AltText   NVARCHAR(255) NULL,   --  Mô tả ảnh (hỗ trợ SEO & accessibility)
    SortOrder INT DEFAULT 0,
    IsDefault BIT DEFAULT 0
);
GO

-- [TABLE 07] Dòng gốc: 99-107

-- 7. Bảng Thông số kỹ thuật động (EAV - phù hợp linh kiện PC đa dạng)
CREATE TABLE ProductAttributes (
    AttrID         INT PRIMARY KEY IDENTITY(1,1),
    ProductID      INT FOREIGN KEY REFERENCES Products(ProductID) ON DELETE CASCADE,
    AttributeName  NVARCHAR(100) NOT NULL,  -- Ví dụ: 'Socket', 'VRAM', 'Bus', 'TDP'
    AttributeValue NVARCHAR(255) NOT NULL,  -- Ví dụ: 'AM5', '16GB', 'PCIe 4.0', '125W'
    SortOrder      INT DEFAULT 0
);
GO

-- [TABLE 08] Dòng gốc: 109-123

-- 8. Bảng Mã giảm giá (Vouchers)
CREATE TABLE Vouchers (
    VoucherCode    NVARCHAR(20)   PRIMARY KEY,
    Description    NVARCHAR(255)  NULL,        --  Mô tả voucher
    DiscountAmount DECIMAL(18, 2) NOT NULL CHECK (DiscountAmount > 0),
    IsPercent      BIT            DEFAULT 0,   -- 0: Giảm tiền cố định | 1: Giảm theo %
    MaxDiscount    DECIMAL(18, 2) NULL,        --  Giới hạn giảm tối đa (dùng khi IsPercent=1)
    MinOrderValue  DECIMAL(18, 2) DEFAULT 0,
    ExpiryDate     DATETIME       NOT NULL,
    UsageLimit     INT            DEFAULT 0,   -- Tổng số lượt dùng còn lại
    MaxPerUser     INT            DEFAULT 1,   --  Mỗi user dùng tối đa bao nhiêu lần
    IsActive       BIT            DEFAULT 1,
    CreatedAt      DATETIME       DEFAULT GETDATE()
);
GO

-- [TABLE 09] Dòng gốc: 125-133

-- 9.  Bảng Lịch sử sử dụng Voucher (Tracking ai đã dùng mã nào)
CREATE TABLE VoucherUsage (
    UsageID     INT PRIMARY KEY IDENTITY(1,1),
    VoucherCode NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES Vouchers(VoucherCode),
    UserID      INT          NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    OrderID     INT          NULL,   -- FK sẽ được thêm sau khi tạo bảng Orders
    UsedAt      DATETIME     DEFAULT GETDATE()
);
GO

-- [TABLE 10] Dòng gốc: 135-144

-- 10. Bảng Giỏ hàng
CREATE TABLE Cart (
    CartID    INT PRIMARY KEY IDENTITY(1,1),
    UserID    INT FOREIGN KEY REFERENCES Users(UserID) ON DELETE CASCADE,
    ProductID INT FOREIGN KEY REFERENCES Products(ProductID),
    Quantity  INT NOT NULL CHECK (Quantity > 0),
    AddedAt   DATETIME DEFAULT GETDATE(),   --  Thời điểm thêm vào giỏ
    CONSTRAINT UQ_Cart_User_Product UNIQUE (UserID, ProductID)  --  Tránh trùng dòng
);
GO

-- [TABLE 11] Dòng gốc: 146-164

-- 11. Bảng Đơn hàng
CREATE TABLE Orders (
    OrderID         INT PRIMARY KEY IDENTITY(1,1),
    UserID          INT            FOREIGN KEY REFERENCES Users(UserID),
    OrderDate       DATETIME       DEFAULT GETDATE(),
    TotalAmount     DECIMAL(18, 2) NOT NULL CHECK (TotalAmount >= 0),
    DiscountAmount  DECIMAL(18, 2) DEFAULT 0,   --  Lưu số tiền đã giảm thực tế
    FinalAmount     DECIMAL(18, 2) NOT NULL,    --  Số tiền khách thực trả (sau giảm)
    VoucherCode     NVARCHAR(20)   NULL FOREIGN KEY REFERENCES Vouchers(VoucherCode),
    Status          NVARCHAR(50)   DEFAULT N'Chờ xác nhận'
                    CHECK (Status IN (N'Chờ xác nhận', N'Đã xác nhận', N'Đang giao', N'Hoàn tất', N'Đã hủy')),
    PaymentMethod   NVARCHAR(50)   NOT NULL,    -- 'COD', 'Banking', 'Momo', 'VNPay'
    PaymentStatus   NVARCHAR(50)   DEFAULT N'Chưa thanh toán'   -- 
                    CHECK (PaymentStatus IN (N'Chưa thanh toán', N'Đã thanh toán', N'Hoàn tiền')),
    ShippingAddress NVARCHAR(500)  NOT NULL,    -- Snapshot địa chỉ tại thời điểm đặt hàng
    AdminNote       NVARCHAR(500)  NULL,        --  Ghi chú nội bộ của Admin
    UpdatedAt       DATETIME       NULL
);
GO

-- [TABLE 12] Dòng gốc: 171-179

-- 12. Bảng Chi tiết Đơn hàng
CREATE TABLE OrderDetails (
    DetailID  INT PRIMARY KEY IDENTITY(1,1),
    OrderID   INT            NOT NULL FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID INT            NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    Quantity  INT            NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18, 2) NOT NULL CHECK (UnitPrice >= 0)  -- Snapshot giá tại thời điểm mua
);
GO

-- [TABLE 13] Dòng gốc: 181-193

-- 13. Bảng Đánh giá sản phẩm
CREATE TABLE Reviews (
    ReviewID   INT PRIMARY KEY IDENTITY(1,1),
    ProductID  INT           NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    UserID     INT           NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Rating     INT           NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment    NVARCHAR(MAX),
    ImageURL   NVARCHAR(500) NULL,   --  Ảnh kèm theo đánh giá
    IsApproved BIT           DEFAULT 0,   --  Admin duyệt trước khi hiển thị
    CreatedAt  DATETIME      DEFAULT GETDATE(),
    CONSTRAINT UQ_Review_User_Product UNIQUE (UserID, ProductID)  -- Mỗi user chỉ review 1 lần/SP
);
GO

-- [TABLE 14] Dòng gốc: 195-206

-- 14. Bảng Nhật ký Kho hàng
CREATE TABLE InventoryLog (
    LogID           INT PRIMARY KEY IDENTITY(1,1),
    ProductID       INT          NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    ChangeQuantity  INT          NOT NULL,   -- Dương: nhập kho | Âm: xuất kho
    QuantityAfter   INT          NOT NULL,   --  Tồn kho sau khi thay đổi (snapshot)
    LogType         NVARCHAR(50) NOT NULL,   -- 'Bán hàng', 'Nhập kho', 'Hoàn trả', 'Điều chỉnh'
    RelatedOrderID  INT          NULL,       --  FK mềm để biết log thuộc đơn hàng nào
    CreatedAt       DATETIME     DEFAULT GETDATE(),
    Note            NVARCHAR(255)
);
GO

-- [TABLE 15] Dòng gốc: 208-220

-- 15. Bảng Banner (Quản lý Slider trang chủ)
CREATE TABLE Banners (
    BannerID     INT PRIMARY KEY IDENTITY(1,1),
    Title        NVARCHAR(200)  NOT NULL,
    ImageURL     NVARCHAR(500)  NOT NULL,
    LinkURL      NVARCHAR(500)  NULL,
    DisplayOrder INT            DEFAULT 0,
    StartDate    DATETIME       NULL,   --  Ngày bắt đầu hiển thị
    EndDate      DATETIME       NULL,   --  Ngày kết thúc hiển thị
    IsActive     BIT            DEFAULT 1,
    CreatedAt    DATETIME       DEFAULT GETDATE()
);
GO

-- [TABLE 16] Dòng gốc: 222-234

-- 16. Bảng Phiếu Bảo Hành điện tử (Tự động sinh khi đơn Hoàn tất)
CREATE TABLE ProductWarranties (
    WarrantyID    INT PRIMARY KEY IDENTITY(1,1),
    OrderDetailID INT          NOT NULL FOREIGN KEY REFERENCES OrderDetails(DetailID),
    ProductID     INT          NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    UserID        INT          NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    StartDate     DATETIME     DEFAULT GETDATE(),
    EndDate       DATETIME     NOT NULL,
    WarrantyCode  NVARCHAR(50) UNIQUE NOT NULL,   -- Mã tra cứu: BH-{DetailID}-{YYYYMMDD}
    Status        NVARCHAR(50) DEFAULT N'Đang hiệu lực'
                  CHECK (Status IN (N'Đang hiệu lực', N'Đã hết hạn', N'Đang xử lý', N'Vô hiệu'))
);
GO

-- [TABLE 17] Dòng gốc: 236-249

-- 17. Bảng Yêu Cầu Bảo Hành (Claims)
CREATE TABLE WarrantyClaims (
    ClaimID     INT PRIMARY KEY IDENTITY(1,1),
    WarrantyID  INT          NOT NULL FOREIGN KEY REFERENCES ProductWarranties(WarrantyID),
    UserID      INT          NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    ClaimDate   DATETIME     DEFAULT GETDATE(),
    Description NVARCHAR(MAX) NOT NULL,   -- Tình trạng hư hỏng
    ImageURL    NVARCHAR(500) NULL,       --  Ảnh minh chứng hư hỏng
    Status      NVARCHAR(50) DEFAULT N'Đang tiếp nhận'
                CHECK (Status IN (N'Đang tiếp nhận', N'Đang sửa chữa', N'Đã hoàn trả', N'Từ chối')),
    Resolution  NVARCHAR(MAX) NULL,      -- Cách giải quyết
    ResolvedAt  DATETIME      NULL       --  Ngày giải quyết xong
);
GO

-- [TABLE 18] Dòng gốc: 251-262

-- 18. Bảng Thông báo cho người dùng (Notifications)
CREATE TABLE Notifications (
    NotifID   INT PRIMARY KEY IDENTITY(1,1),
    UserID    INT           NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    Title     NVARCHAR(200) NOT NULL,
    Message   NVARCHAR(MAX) NOT NULL,
    Type      NVARCHAR(50)  DEFAULT 'System',  -- 'Order', 'Warranty', 'Promotion', 'System'
    RelatedID INT           NULL,              -- ID liên quan (OrderID, ClaimID...)
    IsRead    BIT           DEFAULT 0,
    CreatedAt DATETIME      DEFAULT GETDATE()
);
GO

-- [TABLE 19] Dòng gốc: 264-273

-- 19. Bảng Nhật ký AI Chatbot
CREATE TABLE ChatMessages (
    MessageID   INT PRIMARY KEY IDENTITY(1,1),
    UserID      INT           NULL FOREIGN KEY REFERENCES Users(UserID),  -- NULL = khách vãng lai
    SessionID   NVARCHAR(100) NOT NULL,   -- Định danh phiên chat
    UserMessage NVARCHAR(MAX) NOT NULL,
    BotResponse NVARCHAR(MAX) NOT NULL,
    CreatedAt   DATETIME      DEFAULT GETDATE()
);
GO

-- [TABLE 20] Dòng gốc: 275-288

-- 20. Bảng Phân quyền người dùng (UserRoles)
-- Cho phép 1 Staff có thể được gán nhiều quyền khác nhau.
-- Admin quản lý bảng này hoàn toàn qua giao diện web, không cần SSMS.
-- Chỉ khi thêm 1 loại quyền hoàn toàn mới thì mới cần sửa CHECK constraint.
CREATE TABLE UserRoles (
    UserRoleID INT          PRIMARY KEY IDENTITY(1,1),
    UserID     INT          NOT NULL FOREIGN KEY REFERENCES Users(UserID) ON DELETE CASCADE,
    RoleCode   NVARCHAR(20) NOT NULL
               CHECK (RoleCode IN ('Staff_Stock', 'Staff_Order', 'Staff_Report')),
    AssignedAt DATETIME     DEFAULT GETDATE(),
    AssignedBy INT          NULL FOREIGN KEY REFERENCES Users(UserID),  -- Admin nào đã cấp quyền
    CONSTRAINT UQ_UserRole UNIQUE (UserID, RoleCode)  -- Tránh cấp trùng quyền
);
GO

-- [TABLE 21] Dòng gốc: 3430-3453





------------------------------------------------------------
-- 1. TẠO BẢNG RolePermissions
-- Bảng này dùng để quản lý danh sách quyền chi tiết của Staff
------------------------------------------------------------
IF OBJECT_ID('dbo.RolePermissions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolePermissions
    (
        PermissionID INT PRIMARY KEY IDENTITY(1,1),

        RoleCode NVARCHAR(20) NOT NULL UNIQUE,
        RoleName NVARCHAR(100) NOT NULL,
        Description NVARCHAR(255) NULL,

        IsActive BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
        UpdatedAt DATETIME NULL
    );
END
GO

-- [TABLE 22] Dòng gốc: 4488-4520


-----------------------------------------------------------
-- PHẦN BỔ SUNG: FORGOT PASSWORD / RESET PASSWORD
-- Ngày cập nhật: 2024
-- Mục đích: Cho phép user reset mật khẩu qua email
-----------------------------------------------------------

-- ============================================================
-- Bảng: PasswordResetTokens
-- Lưu token reset password (có thời hạn 15 phút)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PasswordResetTokens')
BEGIN
    CREATE TABLE PasswordResetTokens (
        TokenID       INT PRIMARY KEY IDENTITY(1,1),
        UserID        INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
        ResetToken    NVARCHAR(100) UNIQUE NOT NULL,   -- Token ngẫu nhiên (GUID)
        ExpiresAt     DATETIME NOT NULL,               -- Hết hạn sau 15 phút
        IsUsed        BIT DEFAULT 0,                   -- Đã sử dụng chưa
        CreatedAt     DATETIME DEFAULT GETDATE()
    );

    -- Index để tra cứu token nhanh
    CREATE INDEX IX_PasswordResetTokens_Token ON PasswordResetTokens(ResetToken, IsUsed, ExpiresAt);
    CREATE INDEX IX_PasswordResetTokens_User ON PasswordResetTokens(UserID, CreatedAt DESC);

    PRINT N'✓ Đã tạo bảng PasswordResetTokens';
END
ELSE
BEGIN
    PRINT N'⚠ Bảng PasswordResetTokens đã tồn tại';
END
GO

-- [TABLE 23] Dòng gốc: 4734-4756


-- ============================================================
--   REFRESH TOKEN FEATURE
--   Tính năng: Cấp lại Access Token tự động
--   Date: 2024
-- ============================================================

-----------------------------------------------------------
-- BẢNG: RefreshTokens
-----------------------------------------------------------

CREATE TABLE RefreshTokens (
    TokenID       INT PRIMARY KEY IDENTITY(1,1),
    UserID        INT NOT NULL FOREIGN KEY REFERENCES Users(UserID) ON DELETE CASCADE,
    RefreshToken  NVARCHAR(500) UNIQUE NOT NULL,  -- Token dài, random
    ExpiresAt     DATETIME NOT NULL,              -- Hết hạn sau 7 ngày
    CreatedAt     DATETIME DEFAULT GETDATE(),
    IsRevoked     BIT DEFAULT 0,                  -- Đã thu hồi chưa
    RevokedAt     DATETIME NULL,
    DeviceInfo    NVARCHAR(500) NULL,             -- User-Agent, IP (optional)
    ReplacedBy    NVARCHAR(500) NULL              -- Token mới thay thế (rotation)
);
GO

-- [TABLE 24] Dòng gốc: 4990-5034



-- Bổ sung thêm phần thanh toán VNPAY


/* -------------------------------------------------------
   1. TABLE: VNPayTransactions
------------------------------------------------------- */
IF OBJECT_ID('dbo.VNPayTransactions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.VNPayTransactions
    (
        TransactionID        INT IDENTITY(1,1) PRIMARY KEY,
        OrderID              INT NOT NULL FOREIGN KEY REFERENCES dbo.Orders(OrderID),
        vnp_TxnRef           NVARCHAR(100) NOT NULL,
        vnp_Amount           BIGINT NOT NULL,
        vnp_OrderInfo        NVARCHAR(500) NOT NULL,
        vnp_OrderType        NVARCHAR(50) NOT NULL CONSTRAINT DF_VNPay_OrderType DEFAULT('other'),
        RequestedBankCode    NVARCHAR(50) NULL,
        vnp_IpAddr           NVARCHAR(50) NOT NULL,
        RequestUrl           NVARCHAR(MAX) NULL,
        RequestData          NVARCHAR(MAX) NULL,
        vnp_TransactionNo    NVARCHAR(100) NULL,
        vnp_BankCode         NVARCHAR(50) NULL,
        vnp_BankTranNo       NVARCHAR(100) NULL,
        vnp_CardType         NVARCHAR(50) NULL,
        vnp_PayDate          NVARCHAR(14) NULL,
        vnp_ResponseCode     NVARCHAR(10) NULL,
        vnp_TransactionStatus NVARCHAR(10) NULL,
        vnp_SecureHash       NVARCHAR(500) NULL,
        Status               NVARCHAR(50) NOT NULL
            CONSTRAINT DF_VNPay_Status DEFAULT(N'Pending')
            CHECK (Status IN (N'Pending', N'Success', N'Failed', N'Cancelled', N'Expired')),
        CreatedAt            DATETIME NOT NULL CONSTRAINT DF_VNPay_CreatedAt DEFAULT(GETDATE()),
        UpdatedAt            DATETIME NULL,
        CallbackReceivedAt   DATETIME NULL,
        VerifiedAt           DATETIME NULL,
        IsIpnProcessed       BIT NOT NULL CONSTRAINT DF_VNPay_IsIpnProcessed DEFAULT(0),
        IsStockReverted      BIT NOT NULL CONSTRAINT DF_VNPay_IsStockReverted DEFAULT(0),
        ResponseData         NVARCHAR(MAX) NULL,
        ErrorMessage         NVARCHAR(500) NULL,
        CONSTRAINT UQ_VNPayTransactions_TxnRef UNIQUE (vnp_TxnRef)
    );
END
GO

/* -------------------------------------------------------
   1B. TABLE: SePayTransactions
------------------------------------------------------- */
IF OBJECT_ID('dbo.SePayTransactions', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SePayTransactions
    (
        TransactionID INT IDENTITY(1,1) PRIMARY KEY,
        OrderID INT NOT NULL FOREIGN KEY REFERENCES dbo.Orders(OrderID),
        UserID INT NOT NULL FOREIGN KEY REFERENCES dbo.Users(UserID),
        MerchantID NVARCHAR(50) NOT NULL,
        TransactionRef NVARCHAR(100) NOT NULL,
        Amount DECIMAL(15, 2) NOT NULL,
        Status NVARCHAR(50) NOT NULL CONSTRAINT DF_SePay_Status DEFAULT('pending'),
        PaymentMethod NVARCHAR(50) NULL,
        CreatedAt DATETIME NOT NULL CONSTRAINT DF_SePay_CreatedAt DEFAULT(GETUTCDATE()),
        UpdatedAt DATETIME NULL,
        ResponseData NVARCHAR(MAX) NULL,
        ErrorMessage NVARCHAR(500) NULL,
        CONSTRAINT UQ_SePayTransactions_Ref UNIQUE (TransactionRef)
    );
END
GO


-- ============================================================================
-- PHẦN 1B: RÀNG BUỘC / DỮ LIỆU PHỤ TRỢ CHO TABLES
-- ============================================================================

-- [TABLE-HELPER] Dòng gốc: 166-169

-- Thêm FK từ VoucherUsage sang Orders (sau khi Orders đã được tạo)
ALTER TABLE VoucherUsage
    ADD CONSTRAINT FK_VoucherUsage_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID);
GO

-- [TABLE-HELPER] Dòng gốc: 3455-3521


------------------------------------------------------------
-- 2. THÊM / CẬP NHẬT 5 QUYỀN STAFF MẶC ĐỊNH
------------------------------------------------------------
MERGE dbo.RolePermissions AS Target
USING
(
    SELECT 
        N'Staff_Stock' AS RoleCode,
        N'Nhân viên kho' AS RoleName,
        N'Quản lý sản phẩm, nhập kho, tồn kho, lịch sử kho' AS Description

    UNION ALL

    SELECT 
        N'Staff_Order',
        N'Nhân viên đơn hàng',
        N'Xử lý đơn hàng, xem chi tiết đơn hàng, cập nhật trạng thái đơn hàng'

    UNION ALL

    SELECT 
        N'Staff_Report',
        N'Nhân viên báo cáo',
        N'Xem dashboard, báo cáo doanh thu, thống kê, sản phẩm bán chạy'

    UNION ALL

    SELECT 
        N'Staff_Content',
        N'Nhân viên nội dung',
        N'Quản lý danh mục, thương hiệu, banner, đánh giá sản phẩm'

    UNION ALL

    SELECT 
        N'Staff_CustomerCare',
        N'Nhân viên chăm sóc khách hàng',
        N'Xem chat khách hàng, gửi thông báo, hỗ trợ bảo hành và phản hồi khách hàng'
) AS Source
ON Target.RoleCode = Source.RoleCode

WHEN MATCHED THEN
    UPDATE SET
        Target.RoleName = Source.RoleName,
        Target.Description = Source.Description,
        Target.IsActive = 1,
        Target.UpdatedAt = GETDATE()

WHEN NOT MATCHED THEN
    INSERT
    (
        RoleCode,
        RoleName,
        Description,
        IsActive,
        CreatedAt
    )
    VALUES
    (
        Source.RoleCode,
        Source.RoleName,
        Source.Description,
        1,
        GETDATE()
    );
GO

-- [TABLE-HELPER] Dòng gốc: 3523-3546


------------------------------------------------------------
-- 3. XÓA CHECK CONSTRAINT CŨ TRÊN UserRoles.RoleCode
-- Vì constraint cũ chỉ cho 3 quyền:
-- Staff_Stock, Staff_Order, Staff_Report
--
-- Sau khi xóa, UserRoles sẽ kiểm tra quyền hợp lệ
-- bằng Foreign Key sang bảng RolePermissions
------------------------------------------------------------
DECLARE @DropCheckSql NVARCHAR(MAX) = N'';

SELECT @DropCheckSql = @DropCheckSql +
    N'ALTER TABLE dbo.UserRoles DROP CONSTRAINT ' + QUOTENAME(cc.name) + N';' + CHAR(13)
FROM sys.check_constraints cc
WHERE cc.parent_object_id = OBJECT_ID(N'dbo.UserRoles')
  AND cc.definition LIKE N'%Staff_Stock%'
  AND cc.definition LIKE N'%Staff_Order%'
  AND cc.definition LIKE N'%Staff_Report%';

IF LEN(@DropCheckSql) > 0
BEGIN
    EXEC sp_executesql @DropCheckSql;
END
GO

-- [TABLE-HELPER] Dòng gốc: 3548-3566


------------------------------------------------------------
-- 4. THÊM FOREIGN KEY
-- UserRoles.RoleCode chỉ được nhận những quyền có trong RolePermissions
------------------------------------------------------------
IF NOT EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = N'FK_UserRoles_RolePermissions'
      AND parent_object_id = OBJECT_ID(N'dbo.UserRoles')
)
BEGIN
    ALTER TABLE dbo.UserRoles
    ADD CONSTRAINT FK_UserRoles_RolePermissions
    FOREIGN KEY (RoleCode)
    REFERENCES dbo.RolePermissions(RoleCode);
END
GO

-- [TABLE-HELPER] Dòng gốc: 5036-5038

IF COL_LENGTH('dbo.VNPayTransactions', 'RequestedBankCode') IS NULL
    ALTER TABLE dbo.VNPayTransactions ADD RequestedBankCode NVARCHAR(50) NULL;
GO

-- [TABLE-HELPER] Dòng gốc: 5040-5041
IF COL_LENGTH('dbo.VNPayTransactions', 'RequestData') IS NULL
    ALTER TABLE dbo.VNPayTransactions ADD RequestData NVARCHAR(MAX) NULL;
GO

-- [TABLE-HELPER] Dòng gốc: 5043-5044
IF COL_LENGTH('dbo.VNPayTransactions', 'vnp_BankTranNo') IS NULL
    ALTER TABLE dbo.VNPayTransactions ADD vnp_BankTranNo NVARCHAR(100) NULL;
GO

-- [TABLE-HELPER] Dòng gốc: 5046-5047
IF COL_LENGTH('dbo.VNPayTransactions', 'VerifiedAt') IS NULL
    ALTER TABLE dbo.VNPayTransactions ADD VerifiedAt DATETIME NULL;
GO

-- [TABLE-HELPER] Dòng gốc: 5049-5050
IF COL_LENGTH('dbo.VNPayTransactions', 'IsIpnProcessed') IS NULL
    ALTER TABLE dbo.VNPayTransactions ADD IsIpnProcessed BIT NOT NULL CONSTRAINT DF_VNPay_IsIpnProcessed_2 DEFAULT(0);
GO

-- [TABLE-HELPER] Dòng gốc: 5052-5053
IF COL_LENGTH('dbo.VNPayTransactions', 'IsStockReverted') IS NULL
    ALTER TABLE dbo.VNPayTransactions ADD IsStockReverted BIT NOT NULL CONSTRAINT DF_VNPay_IsStockReverted_2 DEFAULT(0);
GO


-- ============================================================================
-- PHẦN 2: INDEXES
-- ============================================================================

-- [INDEX-BATCH 01] Dòng gốc: 290-344


-----------------------------------------------------------
-- PHẦN 2: CHỈ MỤC (18 INDEXES) - TỐI ƯU HIỆU NĂNG
-----------------------------------------------------------

-- Tìm kiếm sản phẩm theo tên, SKU
CREATE INDEX IX_Products_Search       ON Products(ProductName, SKU);
-- Lọc sản phẩm theo danh mục + trạng thái (dùng cho trang danh mục)
CREATE INDEX IX_Products_Category     ON Products(CategoryID, IsActive);
-- Lọc sản phẩm theo thương hiệu
CREATE INDEX IX_Products_Brand        ON Products(BrandID, IsActive);
-- Sắp xếp sản phẩm bán chạy
CREATE INDEX IX_Products_SoldCount    ON Products(SoldCount DESC);



-- Truy vấn đơn hàng theo ngày và trạng thái (phục vụ báo cáo Admin)
CREATE INDEX IX_Orders_Date_Status    ON Orders(OrderDate, Status);
-- Lấy đơn hàng của 1 user (trang lịch sử đơn hàng)
CREATE INDEX IX_Orders_UserID         ON Orders(UserID, OrderDate DESC);

-- Nhật ký kho theo ngày và loại (phục vụ báo cáo nhập xuất)
CREATE INDEX IX_InventoryLog_Date     ON InventoryLog(CreatedAt, LogType);

-- Tải danh sách banner đang hoạt động theo thứ tự
CREATE INDEX IX_Banners_Active_Order  ON Banners(IsActive, DisplayOrder);

-- Load đánh giá của 1 sản phẩm, kèm rating và ngày
CREATE INDEX IX_Reviews_Product       ON Reviews(ProductID, IsApproved) INCLUDE (Rating, CreatedAt);

-- Lấy giỏ hàng của 1 user
CREATE INDEX IX_Cart_User             ON Cart(UserID);

-- Tra cứu bảo hành theo mã hoặc theo user
CREATE INDEX IX_Warranty_Code         ON ProductWarranties(WarrantyCode);
CREATE INDEX IX_Warranty_User         ON ProductWarranties(UserID);

-- Tra cứu yêu cầu bảo hành đang xử lý (Admin dashboard)
CREATE INDEX IX_WarrantyClaims_Status ON WarrantyClaims(Status);

-- Tra cứu lịch sử chat theo phiên làm việc
CREATE INDEX IX_ChatMessages_Session  ON ChatMessages(SessionID);

-- Lấy thông báo chưa đọc của 1 user
CREATE INDEX IX_Notifications_User    ON Notifications(UserID, IsRead);

-- Kiểm tra user đã dùng voucher chưa
CREATE INDEX IX_VoucherUsage_User_Code ON VoucherUsage(UserID, VoucherCode);

-- Địa chỉ mặc định của user
CREATE INDEX IX_UserAddresses_User    ON UserAddresses(UserID, IsDefault);

-- Lấy tất cả quyền của 1 user (dùng khi đăng nhập để load permissions)
CREATE INDEX IX_UserRoles_User        ON UserRoles(UserID);
GO

-- [INDEX-BATCH 02] Dòng gốc: 4758-4761

-- Index để tra cứu nhanh
CREATE INDEX IX_RefreshTokens_Token ON RefreshTokens(RefreshToken) WHERE IsRevoked = 0;
CREATE INDEX IX_RefreshTokens_User ON RefreshTokens(UserID, IsRevoked);
GO

-- [INDEX-BATCH 03] Dòng gốc: 4971-4977

-----------------------------------------------------------
-- INDEX OPTIMIZATION
-----------------------------------------------------------

-- Index để cleanup nhanh
CREATE INDEX IX_RefreshTokens_Cleanup ON RefreshTokens(ExpiresAt) WHERE IsRevoked = 0;
GO

-- [INDEX-BATCH 04] Dòng gốc: 5055-5065

/* -------------------------------------------------------
   2. INDEXES
------------------------------------------------------- */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_VNPayTransactions_OrderID'
      AND object_id = OBJECT_ID('dbo.VNPayTransactions')
)
    CREATE INDEX IX_VNPayTransactions_OrderID
    ON dbo.VNPayTransactions(OrderID);
GO

-- [INDEX-BATCH 05] Dòng gốc: 5067-5074

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_VNPayTransactions_Status_CreatedAt'
      AND object_id = OBJECT_ID('dbo.VNPayTransactions')
)
    CREATE INDEX IX_VNPayTransactions_Status_CreatedAt
    ON dbo.VNPayTransactions(Status, CreatedAt DESC);
GO

-- [INDEX-BATCH 06] Dòng gốc: 5076-5083

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_VNPayTransactions_TransactionNo'
      AND object_id = OBJECT_ID('dbo.VNPayTransactions')
)
    CREATE INDEX IX_VNPayTransactions_TransactionNo
    ON dbo.VNPayTransactions(vnp_TransactionNo);
GO

-- [INDEX-BATCH 07] Dòng gốc: 5085-5092

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_VNPayTransactions_Order_Status'
      AND object_id = OBJECT_ID('dbo.VNPayTransactions')
)
    CREATE INDEX IX_VNPayTransactions_Order_Status
    ON dbo.VNPayTransactions(OrderID, Status, CreatedAt DESC);
GO


-- ============================================================================
-- PHẦN 3: TRIGGERS
-- ============================================================================

-- [TRIGGER-HELPER] Dòng gốc: 5094-5099

/* -------------------------------------------------------
   3. CLEAN OLD BAD OBJECTS
------------------------------------------------------- */
IF OBJECT_ID('dbo.trg_VNPayTransaction_AfterUpdate', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_VNPayTransaction_AfterUpdate;
GO

-- [TRIGGER 01] trg_AfterOrderDetails_Insert | Dòng gốc: 346-401


-----------------------------------------------------------
-- PHẦN 3: TRIGGERS (7 TRIGGERS) - RÀNG BUỘC VÀ TỰ ĐỘNG HÓA
-----------------------------------------------------------

-- Trigger 1: Tự động trừ kho + ghi nhật ký + cập nhật SoldCount khi đặt hàng
CREATE TRIGGER trg_AfterOrderDetails_Insert
ON OrderDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM
        (
            SELECT ProductID, SUM(Quantity) AS TotalQty
            FROM inserted
            GROUP BY ProductID
        ) q
        JOIN Products p WITH (UPDLOCK, HOLDLOCK) ON p.ProductID = q.ProductID
        WHERE p.StockQuantity < q.TotalQty
    )
    BEGIN
        RAISERROR(N'Loi: Kho khong du hang de thuc hien giao dich nay!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    ;WITH QtyPerProduct AS
    (
        SELECT ProductID, SUM(Quantity) AS TotalQty
        FROM inserted
        GROUP BY ProductID
    )
    UPDATE p
    SET p.StockQuantity = p.StockQuantity - q.TotalQty,
        p.SoldCount     = p.SoldCount + q.TotalQty,
        p.UpdatedAt     = GETDATE()
    FROM Products p
    JOIN QtyPerProduct q ON p.ProductID = q.ProductID;

    INSERT INTO InventoryLog (ProductID, ChangeQuantity, QuantityAfter, LogType, RelatedOrderID, Note)
    SELECT
        i.ProductID,
        -i.Quantity,
        p.StockQuantity,
        N'Ban hang',
        i.OrderID,
        N'Xuat kho cho don hang #' + CAST(i.OrderID AS NVARCHAR(20))
    FROM inserted i
    JOIN Products p ON i.ProductID = p.ProductID;
END;
GO

-- [TRIGGER 02] trg_Orders_OnComplete | Dòng gốc: 403-458

-- Trigger 2: Tự động sinh phiếu bảo hành khi đơn chuyển sang "Hoàn tất"
--            + Cập nhật PaymentStatus sang "Đã thanh toán"
--            + Gửi thông báo cho khách hàng
CREATE TRIGGER trg_Orders_OnComplete
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ xử lý khi Status thay đổi sang 'Hoàn tất'
    IF NOT EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.Status = N'Hoàn tất' AND d.Status != N'Hoàn tất'
    ) RETURN;

    -- 1. Sinh phiếu bảo hành cho từng sản phẩm trong đơn
    INSERT INTO ProductWarranties (OrderDetailID, ProductID, UserID, StartDate, EndDate, WarrantyCode, Status)
    SELECT
        od.DetailID,
        od.ProductID,
        o.UserID,
        GETDATE(),
        DATEADD(MONTH, p.WarrantyMonths, GETDATE()),
        'BH-' + CAST(od.DetailID AS NVARCHAR(20)) + '-' + FORMAT(GETDATE(), 'yyyyMMdd'),
        N'Đang hiệu lực'
    FROM OrderDetails od
    JOIN Orders o        ON od.OrderID   = o.OrderID
    JOIN Products p      ON od.ProductID = p.ProductID
    JOIN inserted i      ON o.OrderID    = i.OrderID
    WHERE i.Status = N'Hoàn tất';

    -- 2. Tự động cập nhật PaymentStatus sang "Đã thanh toán"
    UPDATE Orders
    SET PaymentStatus = N'Đã thanh toán',
        UpdatedAt     = GETDATE()
    WHERE OrderID IN (
        SELECT i.OrderID FROM inserted i
        JOIN deleted d ON i.OrderID = d.OrderID
        WHERE i.Status = N'Hoàn tất' AND d.Status != N'Hoàn tất'
    );

    -- 3. Gửi thông báo cho khách hàng
    INSERT INTO Notifications (UserID, Title, Message, Type, RelatedID)
    SELECT
        i.UserID,
        N'Đơn hàng #' + CAST(i.OrderID AS NVARCHAR(20)) + N' đã hoàn tất!',
        N'Đơn hàng của bạn đã được giao thành công. Phiếu bảo hành điện tử đã được kích hoạt.',
        'Order',
        i.OrderID
    FROM inserted i
    JOIN deleted d ON i.OrderID = d.OrderID
    WHERE i.Status = N'Hoàn tất' AND d.Status != N'Hoàn tất';
END;
GO

-- [TRIGGER 03] trg_LimitActiveBanners | Dòng gốc: 460-473

-- Trigger 3: Giới hạn tối đa 5 Banner IsActive = 1 cùng lúc
CREATE TRIGGER trg_LimitActiveBanners
ON Banners
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF (SELECT COUNT(*) FROM Banners WHERE IsActive = 1) > 5
    BEGIN
        RAISERROR(N'Lỗi: Chỉ được bật tối đa 5 Banner cùng lúc!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- [TRIGGER 04] trg_PreventDeleteOrders | Dòng gốc: 475-484

-- Trigger 4: Chặn xóa vĩnh viễn đơn hàng (bảo vệ dữ liệu kế toán)
CREATE TRIGGER trg_PreventDeleteOrders
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR(N'Bảo mật: Không được xóa đơn hàng. Hãy cập nhật trạng thái sang "Đã hủy"!', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO

-- [TRIGGER 05] trg_UserAddresses_SingleDefault | Dòng gốc: 486-528

-- Trigger 5: Đảm bảo mỗi user chỉ có 1 địa chỉ IsDefault = 1
CREATE TRIGGER trg_UserAddresses_SingleDefault
ON UserAddresses
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    IF EXISTS (SELECT 1 FROM inserted WHERE IsDefault = 1)
    BEGIN
        ;WITH ChangedUsers AS
        (
            SELECT DISTINCT UserID
            FROM inserted
            WHERE IsDefault = 1
        ),
        RankedAddresses AS
        (
            SELECT
                ua.AddressID,
                ua.UserID,
                ROW_NUMBER() OVER
                (
                    PARTITION BY ua.UserID
                    ORDER BY
                        CASE WHEN i.AddressID IS NOT NULL AND i.IsDefault = 1 THEN 0 ELSE 1 END,
                        ua.CreatedAt DESC,
                        ua.AddressID DESC
                ) AS rn
            FROM UserAddresses ua
            JOIN ChangedUsers cu ON cu.UserID = ua.UserID
            LEFT JOIN inserted i ON i.AddressID = ua.AddressID
        )
        UPDATE ua
        SET IsDefault = CASE WHEN r.rn = 1 THEN 1 ELSE 0 END
        FROM UserAddresses ua
        JOIN RankedAddresses r ON r.AddressID = ua.AddressID;
    END
END;
GO

-- [TRIGGER 06] trg_Users_UpdatedAt | Dòng gốc: 530-546

-- Trigger 6: Tự động UpdatedAt cho Users
CREATE TRIGGER trg_Users_UpdatedAt
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE u
    SET UpdatedAt = GETDATE()
    FROM Users u
    JOIN inserted i ON u.UserID = i.UserID;
END;
GO

-- [TRIGGER 07] trg_Products_UpdatedAt | Dòng gốc: 548-564

-- Trigger 7: Tự động UpdatedAt cho Products
CREATE TRIGGER trg_Products_UpdatedAt
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE p
    SET UpdatedAt = GETDATE()
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID;
END;
GO

-- [TRIGGER 08] trg_Users_RevokeTokensOnDeactivate | Dòng gốc: 4941-4969

-----------------------------------------------------------
-- TRIGGER: Auto Cleanup khi User bị vô hiệu hóa
-----------------------------------------------------------

CREATE TRIGGER trg_Users_RevokeTokensOnDeactivate
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Nếu user bị set IsActive = 0, revoke tất cả tokens
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN deleted d ON i.UserID = d.UserID
        WHERE i.IsActive = 0 AND d.IsActive = 1
    )
    BEGIN
        UPDATE rt
        SET IsRevoked = 1,
            RevokedAt = GETDATE()
        FROM RefreshTokens rt
        JOIN inserted i ON rt.UserID = i.UserID
        WHERE i.IsActive = 0
          AND rt.IsRevoked = 0;
    END
END;
GO

-- [TRIGGER 09] dbo.trg_VNPayTransactions_UpdatedAt | Dòng gốc: 5101-5119

/* -------------------------------------------------------
   4. TRIGGERS
------------------------------------------------------- */
CREATE OR ALTER TRIGGER dbo.trg_VNPayTransactions_UpdatedAt
ON dbo.VNPayTransactions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE t
    SET UpdatedAt = GETDATE()
    FROM dbo.VNPayTransactions t
    JOIN inserted i ON i.TransactionID = t.TransactionID;
END;
GO

-- [TRIGGER 10] dbo.trg_PreventDeleteVNPayTransactions | Dòng gốc: 5121-5129

CREATE OR ALTER TRIGGER dbo.trg_PreventDeleteVNPayTransactions
ON dbo.VNPayTransactions
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR(N'Khong duoc xoa lich su giao dich VNPay. Hay cap nhat trang thai!', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO


-- ============================================================================
-- PHẦN 4: STORED PROCEDURES - ĐÁNH SỐ 1 ĐẾN 107
-- ============================================================================

-- DANH SÁCH TÓM TẮT STORED PROCEDURES
-- SP 001/107 | Nhóm: Auth           | sp_Auth_GoogleLogin | Tác dụng: Đăng nhập / Đăng ký bằng Google SSO
-- SP 002/107 | Nhóm: Auth           | sp_Auth_Register | Tác dụng: Đăng ký tài khoản Local
-- SP 003/107 | Nhóm: Customer       | sp_Customer_AddToCart | Tác dụng: Thêm vào giỏ hàng (tránh tạo dòng rác, dùng UNIQUE constraint)
-- SP 004/107 | Nhóm: Customer       | sp_Customer_UpdateCartItem | Tác dụng: Cập nhật / Xóa sản phẩm trong giỏ hàng
-- SP 005/107 | Nhóm: Customer       | sp_Customer_PlaceOrder | Tác dụng: [ĐÃ FIX: Tính TotalAmount có nhân Quantity - dòng 715-723 cũ bị thiếu * c.Quantity]
-- SP 006/107 | Nhóm: Customer       | sp_Customer_AddReview | Tác dụng: Thêm đánh giá sản phẩm (chỉ khi đã mua và nhận hàng)
-- SP 007/107 | Nhóm: Customer       | sp_Customer_GetOrderHistory | Tác dụng: Lấy lịch sử đơn hàng của khách
-- SP 008/107 | Nhóm: Customer       | sp_Customer_GetOrderDetail | Tác dụng: Lấy chi tiết 1 đơn hàng (có danh sách sản phẩm)
-- SP 009/107 | Nhóm: Customer       | sp_Customer_CreateWarrantyClaim | Tác dụng: Gửi yêu cầu bảo hành
-- SP 010/107 | Nhóm: Chat           | sp_Chat_SaveMessage | Tác dụng: Lưu lịch sử chat AI
-- SP 011/107 | Nhóm: Admin          | sp_Admin_ImportStock | Tác dụng: Nhập kho thủ công
-- SP 012/107 | Nhóm: Admin          | sp_Admin_UpdateOrderStatus | Tác dụng: Cập nhật trạng thái đơn hàng (có hoàn kho khi hủy đơn)
-- SP 013/107 | Nhóm: Admin          | sp_Admin_ProcessWarrantyClaim | Tác dụng: Xử lý yêu cầu bảo hành
-- SP 014/107 | Nhóm: Admin          | sp_Admin_UpsertBanner | Tác dụng: Quản lý Banner (Thêm mới hoặc Cập nhật)
-- SP 015/107 | Nhóm: Admin          | sp_Admin_GetRevenueReport | Tác dụng: Báo cáo doanh thu theo ngày (phục vụ vẽ biểu đồ)
-- SP 016/107 | Nhóm: Admin          | sp_Admin_GetLowStockAlert | Tác dụng: Cảnh báo sản phẩm sắp hết hàng
-- SP 017/107 | Nhóm: Admin          | sp_Admin_ApproveReview | Tác dụng: Duyệt hoặc từ chối đánh giá sản phẩm
-- SP 018/107 | Nhóm: Admin          | sp_Admin_GetTopSellingProducts | Tác dụng: Thống kê sản phẩm bán chạy
-- SP 019/107 | Nhóm: Auth           | sp_Auth_LoginLocal | Tác dụng: AUTH
-- SP 020/107 | Nhóm: Product        | sp_Product_GetAll | Tác dụng: PRODUCTS
-- SP 021/107 | Nhóm: Product        | sp_Product_GetById | Tác dụng: getbyid product thuộc nhóm product.
-- SP 022/107 | Nhóm: Product        | sp_Product_Create | Tác dụng: create product thuộc nhóm product.
-- SP 023/107 | Nhóm: Product        | sp_Product_Update | Tác dụng: update product thuộc nhóm product.
-- SP 024/107 | Nhóm: Product        | sp_Product_Delete | Tác dụng: delete product thuộc nhóm product.
-- SP 025/107 | Nhóm: Product        | sp_Product_GetReviews | Tác dụng: getreviews product thuộc nhóm product.
-- SP 026/107 | Nhóm: Category       | sp_Category_GetAll | Tác dụng: CATEGORIES
-- SP 027/107 | Nhóm: Category       | sp_Category_Create | Tác dụng: create category thuộc nhóm category.
-- SP 028/107 | Nhóm: Category       | sp_Category_Update | Tác dụng: update category thuộc nhóm category.
-- SP 029/107 | Nhóm: Category       | sp_Category_Delete | Tác dụng: delete category thuộc nhóm category.
-- SP 030/107 | Nhóm: Brand          | sp_Brand_GetAll | Tác dụng: BRANDS
-- SP 031/107 | Nhóm: Brand          | sp_Brand_Create | Tác dụng: create brand thuộc nhóm brand.
-- SP 032/107 | Nhóm: Brand          | sp_Brand_Update | Tác dụng: update brand thuộc nhóm brand.
-- SP 033/107 | Nhóm: Brand          | sp_Brand_Delete | Tác dụng: delete brand thuộc nhóm brand.
-- SP 034/107 | Nhóm: Customer       | sp_Customer_GetCart | Tác dụng: CART
-- SP 035/107 | Nhóm: Customer       | sp_Customer_CancelOrder | Tác dụng: ORDERS
-- SP 036/107 | Nhóm: Admin          | sp_Admin_GetOrders | Tác dụng: getorders admin thuộc nhóm admin.
-- SP 037/107 | Nhóm: Admin          | sp_Admin_GetOrderDetail | Tác dụng: getorderdetail admin thuộc nhóm admin.
-- SP 038/107 | Nhóm: Admin          | sp_Admin_DeleteReview | Tác dụng: REVIEWS
-- SP 039/107 | Nhóm: Banner         | sp_Banner_GetActive | Tác dụng: BANNERS
-- SP 040/107 | Nhóm: Banner         | sp_Banner_Delete | Tác dụng: delete banner thuộc nhóm banner.
-- SP 041/107 | Nhóm: Notification   | sp_Notification_GetByUser | Tác dụng: NOTIFICATIONS
-- SP 042/107 | Nhóm: Notification   | sp_Notification_MarkRead | Tác dụng: markread notification thuộc nhóm notification.
-- SP 043/107 | Nhóm: Customer       | sp_Customer_GetWarranties | Tác dụng: WARRANTY
-- SP 044/107 | Nhóm: Admin          | sp_Admin_GetWarrantyClaims | Tác dụng: getwarrantyclaims admin thuộc nhóm admin.
-- SP 045/107 | Nhóm: User           | sp_User_GetProfile | Tác dụng: getprofile user thuộc nhóm user.
-- SP 046/107 | Nhóm: User           | sp_User_UpdateProfile | Tác dụng: updateprofile user thuộc nhóm user.
-- SP 047/107 | Nhóm: Useraddress    | sp_UserAddress_GetByUser | Tác dụng: USER ADDRESSES
-- SP 048/107 | Nhóm: Useraddress    | sp_UserAddress_Create | Tác dụng: create useraddress thuộc nhóm useraddress.
-- SP 049/107 | Nhóm: Useraddress    | sp_UserAddress_Update | Tác dụng: update useraddress thuộc nhóm useraddress.
-- SP 050/107 | Nhóm: Useraddress    | sp_UserAddress_Delete | Tác dụng: delete useraddress thuộc nhóm useraddress.
-- SP 051/107 | Nhóm: Product        | sp_Product_AddImage | Tác dụng: PRODUCT IMAGES
-- SP 052/107 | Nhóm: Product        | sp_Product_UpdateImage | Tác dụng: updateimage product thuộc nhóm product.
-- SP 053/107 | Nhóm: Product        | sp_Product_DeleteImage | Tác dụng: deleteimage product thuộc nhóm product.
-- SP 054/107 | Nhóm: Product        | sp_Product_AddAttribute | Tác dụng: PRODUCT ATTRIBUTES
-- SP 055/107 | Nhóm: Product        | sp_Product_UpdateAttribute | Tác dụng: updateattribute product thuộc nhóm product.
-- SP 056/107 | Nhóm: Product        | sp_Product_DeleteAttribute | Tác dụng: deleteattribute product thuộc nhóm product.
-- SP 057/107 | Nhóm: Voucher        | sp_Voucher_GetAll | Tác dụng: VOUCHERS
-- SP 058/107 | Nhóm: Voucher        | sp_Voucher_GetAvailable | Tác dụng: getavailable voucher thuộc nhóm voucher.
-- SP 059/107 | Nhóm: Voucher        | sp_Voucher_Create | Tác dụng: create voucher thuộc nhóm voucher.
-- SP 060/107 | Nhóm: Voucher        | sp_Voucher_Update | Tác dụng: update voucher thuộc nhóm voucher.
-- SP 061/107 | Nhóm: Voucher        | sp_Voucher_Delete | Tác dụng: delete voucher thuộc nhóm voucher.
-- SP 062/107 | Nhóm: Admin          | sp_Admin_GetUsers | Tác dụng: ADMIN LISTS
-- SP 063/107 | Nhóm: Admin          | sp_Admin_UpdateUserStatus | Tác dụng: → dbo.sp_Admin_GetUserDetail
-- SP 064/107 | Nhóm: Admin          | sp_Admin_GetBanners | Tác dụng: getbanners admin thuộc nhóm admin.
-- SP 065/107 | Nhóm: Admin          | sp_Admin_GetReviews | Tác dụng: getreviews admin thuộc nhóm admin.
-- SP 066/107 | Nhóm: Chat           | sp_Chat_GetHistory | Tác dụng: CHAT / DASHBOARD
-- SP 067/107 | Nhóm: Admin          | sp_Admin_GetChatMessages | Tác dụng: getchatmessages admin thuộc nhóm admin.
-- SP 068/107 | Nhóm: Dashboard      | sp_Dashboard_GetSummary | Tác dụng: getsummary dashboard thuộc nhóm dashboard.
-- SP 069/107 | Nhóm: Admin          | sp_Admin_GetInventoryLog | Tác dụng: ADMIN: INVENTORY LOG
-- SP 070/107 | Nhóm: Admin          | sp_Admin_GetVoucherUsage | Tác dụng: ADMIN: VOUCHER USAGE
-- SP 071/107 | Nhóm: Admin          | sp_Admin_GetOrderDetails | Tác dụng: ADMIN: ORDER DETAILS LIST
-- SP 072/107 | Nhóm: Brand          | sp_Brand_GetById | Tác dụng: BRAND: GET BY ID
-- SP 073/107 | Nhóm: Category       | sp_Category_GetById | Tác dụng: CATEGORY: GET BY ID
-- SP 074/107 | Nhóm: Notification   | sp_Notification_MarkAllRead | Tác dụng: NOTIFICATION: MARK ALL READ
-- SP 075/107 | Nhóm: Notification   | sp_Notification_Delete | Tác dụng: NOTIFICATION: DELETE
-- SP 076/107 | Nhóm: Warranty       | sp_Warranty_GetByCode | Tác dụng: WARRANTY: GET BY CODE
-- SP 077/107 | Nhóm: Auth           | sp_Auth_ChangePassword | Tác dụng: AUTH: CHANGE PASSWORD
-- SP 078/107 | Nhóm: Admin          | sp_Admin_SendNotification | Tác dụng: ADMIN: SEND NOTIFICATION TO USER
-- SP 079/107 | Nhóm: Auth           | sp_Auth_CheckEmail | Tác dụng: AUTH: CHECK EMAIL EXISTS
-- SP 080/107 | Nhóm: Admin          | dbo.sp_Admin_GetRolePermissions | Tác dụng: 1. Lấy danh sách quyền Staff đang hoạt động
-- SP 081/107 | Nhóm: Admin          | dbo.sp_Admin_SetUserRoleAndPermissions | Tác dụng: 2. Cập nhật role chính và danh sách quyền chi tiết
-- SP 082/107 | Nhóm: Admin          | dbo.sp_Admin_ManageUserRole | Tác dụng: 3. Cấp hoặc thu hồi 1 quyền Staff cụ thể
-- SP 083/107 | Nhóm: Admin          | dbo.sp_Admin_GetUserRoles | Tác dụng: 4. Lấy danh sách quyền đã cấp cho Staff
-- SP 084/107 | Nhóm: Admin          | dbo.sp_Admin_GetUserPermissions | Tác dụng: 5. Xem quyền chi tiết của 1 user
-- SP 085/107 | Nhóm: Admin          | dbo.sp_Admin_GetUserDetail | Tác dụng: 6. Nâng cấp sp_Admin_GetUserDetail để trả RoleName, Description
-- SP 086/107 | Nhóm: Product        | sp_Product_GetAllPaged | Tác dụng: getallpaged product thuộc nhóm product.
-- SP 087/107 | Nhóm: Orders         | sp_Orders_GetAdminOrdersPaged | Tác dụng: getadminorderspaged orders thuộc nhóm orders.
-- SP 088/107 | Nhóm: Orders         | sp_Orders_GetUserHistoryPaged | Tác dụng: getuserhistorypaged orders thuộc nhóm orders.
-- SP 089/107 | Nhóm: Reviews        | sp_Reviews_GetAdminReviewsPaged | Tác dụng: getadminreviewspaged reviews thuộc nhóm reviews.
-- SP 090/107 | Nhóm: Reviews        | sp_Reviews_GetByProductPaged | Tác dụng: getbyproductpaged reviews thuộc nhóm reviews.
-- SP 091/107 | Nhóm: Notifications  | sp_Notifications_GetByUserPaged | Tác dụng: getbyuserpaged notifications thuộc nhóm notifications.
-- SP 092/107 | Nhóm: Auth           | sp_Auth_ForgotPassword | Tác dụng: forgotpassword auth thuộc nhóm auth.
-- SP 093/107 | Nhóm: Auth           | sp_Auth_ResetPassword | Tác dụng: resetpassword auth thuộc nhóm auth.
-- SP 094/107 | Nhóm: Auth           | sp_Auth_VerifyResetToken | Tác dụng: verifyresettoken auth thuộc nhóm auth.
-- SP 095/107 | Nhóm: Auth           | sp_Auth_CleanupExpiredPasswordTokens | Tác dụng: cleanupexpiredpasswordtokens auth thuộc nhóm auth.
-- SP 096/107 | Nhóm: Auth           | dbo.sp_Auth_CreateRefreshToken | Tác dụng: Tạo Refresh Token khi Login
-- SP 097/107 | Nhóm: Auth           | sp_Auth_VerifyRefreshToken | Tác dụng: Verify Refresh Token
-- SP 098/107 | Nhóm: Auth           | sp_Auth_RevokeRefreshToken | Tác dụng: Revoke Refresh Token (Thu hồi token cũ)
-- SP 099/107 | Nhóm: Auth           | sp_Auth_RevokeAllUserTokens | Tác dụng: Revoke All User Tokens (Logout khỏi tất cả thiết bị)
-- SP 100/107 | Nhóm: Auth           | sp_Auth_CleanupExpiredRefreshTokens | Tác dụng: cleanupexpiredrefreshtokens auth thuộc nhóm auth.
-- SP 101/107 | Nhóm: Auth           | sp_Auth_GetUserActiveTokens | Tác dụng: Get User Active Tokens (Xem các thiết bị đang đăng nhập)
-- SP 102/107 | Nhóm: Createvnpaytransaction | dbo.sp_CreateVNPayTransaction | Tác dụng: createvnpaytransaction createvnpaytransaction thuộc nhóm createvnpaytransaction.
-- SP 103/107 | Nhóm: Updatevnpaytransaction | dbo.sp_UpdateVNPayTransaction | Tác dụng: updatevnpaytransaction updatevnpaytransaction thuộc nhóm updatevnpaytransaction.
-- SP 104/107 | Nhóm: Getvnpaytransactionbyorderid | dbo.sp_GetVNPayTransactionByOrderID | Tác dụng: getvnpaytransactionbyorderid getvnpaytransactionbyorderid thuộc nhóm getvnpaytransactionbyorderid.
-- SP 105/113 | Nhóm: Getvnpaytransactionbytxnref | dbo.sp_GetVNPayTransactionByTxnRef | Tác dụng: getvnpaytransactionbytxnref getvnpaytransactionbytxnref thuộc nhóm getvnpaytransactionbytxnref.
-- SP 106/113 | Nhóm: Getvnpaytransactionhistory | dbo.sp_GetVNPayTransactionHistory | Tác dụng: getvnpaytransactionhistory getvnpaytransactionhistory thuộc nhóm getvnpaytransactionhistory.
-- SP 107/113 | Nhóm: Cancelvnpaytransaction | dbo.sp_CancelVNPayTransaction | Tác dụng: cancelvnpaytransaction cancelvnpaytransaction thuộc nhóm cancelvnpaytransaction.
-- SP 108/113 | Nhóm: SePay            | dbo.sp_InsertSePayTransaction | Tác dụng: Thêm giao dịch SePay mới
-- SP 109/113 | Nhóm: SePay            | dbo.sp_UpdateSePayTransactionStatus | Tác dụng: Cập nhật trạng thái giao dịch và đơn hàng
-- SP 110/113 | Nhóm: SePay            | dbo.sp_SePay_UpdatePaymentStatus | Tác dụng: Cập nhật trạng thái thanh toán đơn hàng
-- SP 111/113 | Nhóm: SePay            | dbo.sp_SePay_GetPaymentStatus | Tác dụng: Lấy trạng thái thanh toán của đơn hàng
-- SP 112/113 | Nhóm: SePay            | dbo.sp_GetSePayTransaction | Tác dụng: Lấy thông tin giao dịch SePay theo TransactionRef
-- SP 113/113 | Nhóm: SePay            | dbo.sp_GetSePayTransactionsByOrder | Tác dụng: Lấy danh sách giao dịch SePay của đơn hàng



-- ----------------------------------------------------------------------------
-- SP 001/107
-- Tên: sp_Auth_GoogleLogin
-- Nhóm chức năng: Auth
-- Tác dụng: Đăng nhập / Đăng ký bằng Google SSO
-- Dòng gốc: 566-628
-- ----------------------------------------------------------------------------


-----------------------------------------------------------
-- PHẦN 4: THỦ TỤC NGHIỆP VỤ (70 STORED PROCEDURES)
-----------------------------------------------------------

-- ========================
-- NHÓM: XÁC THỰC (AUTH)
-- ========================

-- SP 1: Đăng nhập / Đăng ký bằng Google SSO
CREATE PROCEDURE sp_Auth_GoogleLogin
   @Email       NVARCHAR(100),
    @FullName    NVARCHAR(100),
    @ProviderKey NVARCHAR(MAX),
    @AvatarURL   NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExistingUserID INT;
    DECLARE @ExistingProvider NVARCHAR(20);
    DECLARE @ExistingProviderKey NVARCHAR(MAX);

    SELECT
        @ExistingUserID = UserID,
        @ExistingProvider = LoginProvider,
        @ExistingProviderKey = ProviderKey
    FROM Users
    WHERE Email = @Email;

    IF @ExistingUserID IS NULL
    BEGIN
        INSERT INTO Users (Email, FullName, LoginProvider, ProviderKey, AvatarURL, Role)
        VALUES (@Email, @FullName, 'Google', @ProviderKey, @AvatarURL, 'Customer');
    END
    ELSE
    BEGIN
        IF @ExistingProvider = 'Local'
        BEGIN
            RAISERROR(N'Email nay da ton tai duoi dang tai khoan Local. Hay lien ket tai khoan truoc khi dang nhap bang Google.', 16, 1);
            RETURN;
        END

        IF @ExistingProvider = 'Google'
           AND @ExistingProviderKey IS NOT NULL
           AND @ExistingProviderKey <> @ProviderKey
        BEGIN
            RAISERROR(N'Tai khoan Google khong hop le cho email nay.', 16, 1);
            RETURN;
        END

        UPDATE Users
        SET ProviderKey = COALESCE(ProviderKey, @ProviderKey),
            AvatarURL   = ISNULL(@AvatarURL, AvatarURL),
            FullName    = ISNULL(@FullName, FullName)
        WHERE UserID = @ExistingUserID;
    END

    SELECT UserID, FullName, Email, Role, IsActive
    FROM Users
    WHERE Email = @Email;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 002/107
-- Tên: sp_Auth_Register
-- Nhóm chức năng: Auth
-- Tác dụng: Đăng ký tài khoản Local
-- Dòng gốc: 630-648
-- ----------------------------------------------------------------------------

-- SP 2: Đăng ký tài khoản Local
CREATE PROCEDURE sp_Auth_Register
    @FullName     NVARCHAR(100),
    @Email        NVARCHAR(100),
    @PasswordHash NVARCHAR(MAX),
    @PhoneNumber  NVARCHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
    BEGIN
        RAISERROR(N'Email này đã được sử dụng!', 16, 1);
        RETURN;
    END
    INSERT INTO Users (FullName, Email, PasswordHash, PhoneNumber, LoginProvider, Role)
    VALUES (@FullName, @Email, @PasswordHash, @PhoneNumber, 'Local', 'Customer');
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewUserID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 003/107
-- Tên: sp_Customer_AddToCart
-- Nhóm chức năng: Customer
-- Tác dụng: Thêm vào giỏ hàng (tránh tạo dòng rác, dùng UNIQUE constraint)
-- Dòng gốc: 650-680
-- ----------------------------------------------------------------------------


-- ========================
-- NHÓM: CUSTOMER
-- ========================

-- SP 3: Thêm vào giỏ hàng (tránh tạo dòng rác, dùng UNIQUE constraint)
CREATE PROCEDURE sp_Customer_AddToCart
    @UserID    INT,
    @ProductID INT,
    @Quantity  INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra sản phẩm còn hàng không
    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID AND IsActive = 1 AND StockQuantity >= @Quantity)
    BEGIN
        RAISERROR(N'Sản phẩm không tồn tại hoặc không đủ hàng trong kho!', 16, 1);
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM Cart WHERE UserID = @UserID AND ProductID = @ProductID)
    BEGIN
        UPDATE Cart SET Quantity = Quantity + @Quantity
        WHERE UserID = @UserID AND ProductID = @ProductID;
    END
    ELSE
    BEGIN
        INSERT INTO Cart (UserID, ProductID, Quantity)
        VALUES (@UserID, @ProductID, @Quantity);
    END
END;
GO


-- ----------------------------------------------------------------------------
-- SP 004/107
-- Tên: sp_Customer_UpdateCartItem
-- Nhóm chức năng: Customer
-- Tác dụng: Cập nhật / Xóa sản phẩm trong giỏ hàng
-- Dòng gốc: 682-695
-- ----------------------------------------------------------------------------

-- SP 4: Cập nhật / Xóa sản phẩm trong giỏ hàng
CREATE PROCEDURE sp_Customer_UpdateCartItem
    @CartID      INT,
    @UserID      INT,
    @NewQuantity INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @NewQuantity <= 0
        DELETE FROM Cart WHERE CartID = @CartID AND UserID = @UserID;
    ELSE
        UPDATE Cart SET Quantity = @NewQuantity WHERE CartID = @CartID AND UserID = @UserID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 005/107
-- Tên: sp_Customer_PlaceOrder
-- Nhóm chức năng: Customer
-- Tác dụng: [ĐÃ FIX: Tính TotalAmount có nhân Quantity - dòng 715-723 cũ bị thiếu * c.Quantity]
-- Dòng gốc: 697-869
-- ----------------------------------------------------------------------------

-- SP 5: Thanh toán (Checkout) - Xử lý Voucher đúng cả IsPercent + MaxDiscount
-- [ĐÃ FIX: Tính TotalAmount có nhân Quantity - dòng 715-723 cũ bị thiếu * c.Quantity]
CREATE OR ALTER PROCEDURE sp_Customer_PlaceOrder
    @UserID          INT,
    @ShippingAddress NVARCHAR(500),
    @PaymentMethod   NVARCHAR(50),
    @VoucherCode     NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TotalAmount DECIMAL(18,2);
        DECLARE @DiscountAmt DECIMAL(18,2) = 0;
        DECLARE @FinalAmount DECIMAL(18,2);

        -- ✅ FIX: Nhân với c.Quantity để tính đúng tổng tiền theo số lượng
        SELECT @TotalAmount = SUM(
            (CASE
                WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice
                ELSE p.Price
            END) * c.Quantity
        )
        FROM Cart c
        JOIN Products p ON c.ProductID = p.ProductID
        WHERE c.UserID = @UserID;

        IF @TotalAmount IS NULL OR @TotalAmount = 0
        BEGIN
            RAISERROR(N'Gio hang trong!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        IF @VoucherCode IS NOT NULL
        BEGIN
            DECLARE @VDiscount   DECIMAL(18,2);
            DECLARE @VIsPercent  BIT;
            DECLARE @VMaxDisc    DECIMAL(18,2);
            DECLARE @VMinOrder   DECIMAL(18,2);
            DECLARE @VMaxPerUser INT;
            DECLARE @UserUsedCount INT;

            SELECT
                @VDiscount   = DiscountAmount,
                @VIsPercent  = IsPercent,
                @VMaxDisc    = MaxDiscount,
                @VMinOrder   = MinOrderValue,
                @VMaxPerUser = MaxPerUser
            FROM Vouchers WITH (UPDLOCK, HOLDLOCK)
            WHERE VoucherCode = @VoucherCode
              AND IsActive = 1
              AND ExpiryDate >= GETDATE()
              AND UsageLimit > 0
              AND MinOrderValue <= @TotalAmount;

            IF @VDiscount IS NULL
            BEGIN
                RAISERROR(N'Ma giam gia khong hop le hoac khong du dieu kien!', 16, 1);
                ROLLBACK;
                RETURN;
            END

            SELECT @UserUsedCount = COUNT(*)
            FROM VoucherUsage WITH (UPDLOCK, HOLDLOCK)
            WHERE VoucherCode = @VoucherCode
              AND UserID = @UserID;

            IF @UserUsedCount >= @VMaxPerUser
            BEGIN
                RAISERROR(N'Ban da su dung het luot dung cua ma giam gia nay!', 16, 1);
                ROLLBACK;
                RETURN;
            END

            IF @VIsPercent = 1
            BEGIN
                SET @DiscountAmt = @TotalAmount * @VDiscount / 100.0;
                IF @VMaxDisc IS NOT NULL AND @DiscountAmt > @VMaxDisc
                    SET @DiscountAmt = @VMaxDisc;
            END
            ELSE
            BEGIN
                SET @DiscountAmt = @VDiscount;
            END

            UPDATE Vouchers
            SET UsageLimit = UsageLimit - 1
            WHERE VoucherCode = @VoucherCode
              AND UsageLimit > 0;

            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR(N'Ma giam gia da het luot su dung.', 16, 1);
                ROLLBACK;
                RETURN;
            END
        END

        SET @FinalAmount = @TotalAmount - @DiscountAmt;
        IF @FinalAmount < 0 SET @FinalAmount = 0;

        INSERT INTO Orders
        (
            UserID,
            TotalAmount,
            DiscountAmount,
            FinalAmount,
            VoucherCode,
            ShippingAddress,
            PaymentMethod,
            Status,
            PaymentStatus
        )
        VALUES
        (
            @UserID,
            @TotalAmount,
            @DiscountAmt,
            @FinalAmount,
            @VoucherCode,
            @ShippingAddress,
            @PaymentMethod,
            N'Chờ xác nhận',
            N'Chưa thanh toán'
        );

        DECLARE @NewOrderID INT = SCOPE_IDENTITY();

        INSERT INTO OrderDetails (OrderID, ProductID, Quantity, UnitPrice)
        SELECT
            @NewOrderID,
            c.ProductID,
            c.Quantity,
            CASE
                WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice
                ELSE p.Price
            END
        FROM Cart c
        JOIN Products p ON c.ProductID = p.ProductID
        WHERE c.UserID = @UserID;

        IF @VoucherCode IS NOT NULL
        BEGIN
            INSERT INTO VoucherUsage (VoucherCode, UserID, OrderID)
            VALUES (@VoucherCode, @UserID, @NewOrderID);
        END

        DELETE FROM Cart
        WHERE UserID = @UserID;

        INSERT INTO Notifications (UserID, Title, Message, Type, RelatedID)
        VALUES
        (
            @UserID,
            N'Đặt hàng thành công #' + CAST(@NewOrderID AS NVARCHAR(20)),
            N'Đơn hàng của bạn đang chờ xác nhận. Cảm ơn bạn đã mua sắm!',
            'Order',
            @NewOrderID
        );

        COMMIT;
        SELECT @NewOrderID AS NewOrderID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END;
GO


-- ----------------------------------------------------------------------------
-- SP 006/107
-- Tên: sp_Customer_AddReview
-- Nhóm chức năng: Customer
-- Tác dụng: Thêm đánh giá sản phẩm (chỉ khi đã mua và nhận hàng)
-- Dòng gốc: 871-900
-- ----------------------------------------------------------------------------

-- SP 6: Thêm đánh giá sản phẩm (chỉ khi đã mua và nhận hàng)
CREATE PROCEDURE sp_Customer_AddReview
    @UserID    INT,
    @ProductID INT,
    @Rating    INT,
    @Comment   NVARCHAR(MAX),
    @ImageURL  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Kiểm tra đã mua và nhận hàng thành công chưa
    IF NOT EXISTS (
        SELECT 1 FROM Orders o
        JOIN OrderDetails od ON o.OrderID = od.OrderID
        WHERE o.UserID = @UserID AND od.ProductID = @ProductID AND o.Status = N'Hoàn tất'
    )
    BEGIN
        RAISERROR(N'Chỉ khách hàng đã nhận hàng thành công mới được đánh giá!', 16, 1);
        RETURN;
    END
    -- Kiểm tra đã review chưa
    IF EXISTS (SELECT 1 FROM Reviews WHERE UserID = @UserID AND ProductID = @ProductID)
    BEGIN
        RAISERROR(N'Bạn đã đánh giá sản phẩm này rồi!', 16, 1);
        RETURN;
    END
    INSERT INTO Reviews (ProductID, UserID, Rating, Comment, ImageURL, IsApproved)
    VALUES (@ProductID, @UserID, @Rating, @Comment, @ImageURL, 0);
END;
GO


-- ----------------------------------------------------------------------------
-- SP 007/107
-- Tên: sp_Customer_GetOrderHistory
-- Nhóm chức năng: Customer
-- Tác dụng: Lấy lịch sử đơn hàng của khách
-- Dòng gốc: 902-923
-- ----------------------------------------------------------------------------

-- SP 7: Lấy lịch sử đơn hàng của khách
CREATE PROCEDURE sp_Customer_GetOrderHistory
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        o.OrderID,
        o.OrderDate,
        o.TotalAmount,
        o.DiscountAmount,
        o.FinalAmount,
        o.Status,
        o.PaymentMethod,
        o.PaymentStatus,
        o.ShippingAddress,
        o.VoucherCode
    FROM Orders o
    WHERE o.UserID = @UserID
    ORDER BY o.OrderDate DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 008/107
-- Tên: sp_Customer_GetOrderDetail
-- Nhóm chức năng: Customer
-- Tác dụng: Lấy chi tiết 1 đơn hàng (có danh sách sản phẩm)
-- Dòng gốc: 925-945
-- ----------------------------------------------------------------------------

-- SP 8: Lấy chi tiết 1 đơn hàng (có danh sách sản phẩm)
CREATE PROCEDURE sp_Customer_GetOrderDetail
    @OrderID INT,
    @UserID  INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Header đơn hàng
    SELECT o.OrderID, o.OrderDate, o.TotalAmount, o.DiscountAmount, o.FinalAmount,
           o.Status, o.PaymentMethod, o.PaymentStatus, o.ShippingAddress, o.VoucherCode
    FROM Orders o
    WHERE o.OrderID = @OrderID AND o.UserID = @UserID;
    -- Chi tiết sản phẩm
    SELECT od.DetailID, p.ProductName, p.SKU,
           (SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsDefault = 1) AS ImageURL,
           od.Quantity, od.UnitPrice, (od.Quantity * od.UnitPrice) AS LineTotal
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE od.OrderID = @OrderID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 009/107
-- Tên: sp_Customer_CreateWarrantyClaim
-- Nhóm chức năng: Customer
-- Tác dụng: Gửi yêu cầu bảo hành
-- Dòng gốc: 947-984
-- ----------------------------------------------------------------------------

-- SP 9: Gửi yêu cầu bảo hành
CREATE PROCEDURE sp_Customer_CreateWarrantyClaim
    @WarrantyCode NVARCHAR(50),
    @UserID       INT,
    @Description  NVARCHAR(MAX),
    @ImageURL     NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @WarrantyID INT;
    SELECT @WarrantyID = WarrantyID
    FROM ProductWarranties
    WHERE WarrantyCode = @WarrantyCode
      AND UserID = @UserID
      AND EndDate >= GETDATE()
      AND Status = N'Đang hiệu lực';

    IF @WarrantyID IS NULL
    BEGIN
        RAISERROR(N'Mã bảo hành không tồn tại, không thuộc về bạn, hoặc đã hết hạn!', 16, 1);
        RETURN;
    END

    INSERT INTO WarrantyClaims (WarrantyID, UserID, Description, ImageURL, Status)
    VALUES (@WarrantyID, @UserID, @Description, @ImageURL, N'Đang tiếp nhận');

    -- Đổi trạng thái phiếu bảo hành sang Đang xử lý
    UPDATE ProductWarranties SET Status = N'Đang xử lý'
    WHERE WarrantyID = @WarrantyID;

    -- Gửi thông báo
    INSERT INTO Notifications (UserID, Title, Message, Type, RelatedID)
    VALUES (@UserID,
            N'Yêu cầu bảo hành đã được tiếp nhận',
            N'Chúng tôi đã nhận yêu cầu bảo hành của bạn và sẽ phản hồi sớm nhất có thể.',
            'Warranty', SCOPE_IDENTITY());
END;
GO


-- ----------------------------------------------------------------------------
-- SP 010/107
-- Tên: sp_Chat_SaveMessage
-- Nhóm chức năng: Chat
-- Tác dụng: Lưu lịch sử chat AI
-- Dòng gốc: 986-998
-- ----------------------------------------------------------------------------

-- SP 10: Lưu lịch sử chat AI
CREATE PROCEDURE sp_Chat_SaveMessage
    @UserID    INT = NULL,
    @SessionID NVARCHAR(100),
    @UserMsg   NVARCHAR(MAX),
    @BotRes    NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO ChatMessages (UserID, SessionID, UserMessage, BotResponse)
    VALUES (@UserID, @SessionID, @UserMsg, @BotRes);
END;
GO


-- ----------------------------------------------------------------------------
-- SP 011/107
-- Tên: sp_Admin_ImportStock
-- Nhóm chức năng: Admin
-- Tác dụng: Nhập kho thủ công
-- Dòng gốc: 1000-1055
-- ----------------------------------------------------------------------------

-- ========================
-- [ĐÃ XÓA PHIÊN BẢN CŨ] sp_Admin_ManageUserRole (version cũ, chỉ kiểm tra 3 roles cứng)
-- Phiên bản hoàn chỉnh (kiểm tra RolePermissions động) được định nghĩa ở phần
-- "SP PHÂN QUYỀN STAFF CHI TIẾT" bên dưới → dbo.sp_Admin_ManageUserRole
-- ========================


-- ========================
-- NHÓM: ADMIN
-- ========================

-- SP 11: Nhập kho thủ công
CREATE PROCEDURE sp_Admin_ImportStock
   @ProductID     INT,
    @QuantityToAdd INT,
    @Note          NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @QuantityToAdd <= 0
    BEGIN
        RAISERROR(N'So luong nhap kho phai lon hon 0!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR(N'San pham khong ton tai!', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
    BEGIN TRY
        UPDATE Products
        SET StockQuantity = StockQuantity + @QuantityToAdd
        WHERE ProductID = @ProductID;

        DECLARE @NewQty INT;
        SELECT @NewQty = StockQuantity
        FROM Products
        WHERE ProductID = @ProductID;

        INSERT INTO InventoryLog (ProductID, ChangeQuantity, QuantityAfter, LogType, Note)
        VALUES (@ProductID, @QuantityToAdd, @NewQty, N'Nhap kho', @Note);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END;
GO


-- ----------------------------------------------------------------------------
-- SP 012/107
-- Tên: sp_Admin_UpdateOrderStatus
-- Nhóm chức năng: Admin
-- Tác dụng: Cập nhật trạng thái đơn hàng (có hoàn kho khi hủy đơn)
-- Dòng gốc: 1057-1125
-- ----------------------------------------------------------------------------

-- SP 12: Cập nhật trạng thái đơn hàng (có hoàn kho khi hủy đơn)
CREATE PROCEDURE sp_Admin_UpdateOrderStatus
    @OrderID   INT,
    @NewStatus NVARCHAR(50),
    @AdminNote NVARCHAR(255) = NULL
AS
BEGIN
    BEGIN TRAN;
    BEGIN TRY
        DECLARE @OldStatus NVARCHAR(50);
        DECLARE @UserID    INT;
        SELECT @OldStatus = Status, @UserID = UserID FROM Orders WHERE OrderID = @OrderID;

        IF @OldStatus = @NewStatus
        BEGIN
            COMMIT; RETURN;
        END

        -- Không cho chuyển từ trạng thái cuối
        IF @OldStatus IN (N'Hoàn tất', N'Đã hủy')
        BEGIN
            RAISERROR(N'Không thể thay đổi trạng thái đơn hàng đã hoàn tất hoặc đã hủy!', 16, 1);
            ROLLBACK; RETURN;
        END

        UPDATE Orders
        SET Status    = @NewStatus,
            AdminNote = ISNULL(@AdminNote, AdminNote),
            UpdatedAt = GETDATE()
        WHERE OrderID = @OrderID;

        -- Hoàn kho khi hủy đơn
        IF @NewStatus = N'Đã hủy'
        BEGIN
            UPDATE p
            SET p.StockQuantity = p.StockQuantity + od.Quantity,
                p.SoldCount     = p.SoldCount - od.Quantity,
                p.UpdatedAt     = GETDATE()
            FROM Products p
            JOIN OrderDetails od ON p.ProductID = od.ProductID
            WHERE od.OrderID = @OrderID;

            DECLARE @NewQty2 INT;
            INSERT INTO InventoryLog (ProductID, ChangeQuantity, QuantityAfter, LogType, RelatedOrderID, Note)
            SELECT od.ProductID, od.Quantity, p.StockQuantity, N'Hoàn trả',
                   @OrderID, N'Hủy đơn #' + CAST(@OrderID AS NVARCHAR(20)) + ISNULL(' - ' + @AdminNote, '')
            FROM OrderDetails od
            JOIN Products p ON od.ProductID = p.ProductID
            WHERE od.OrderID = @OrderID;

            -- Gửi thông báo hủy đơn cho khách
            INSERT INTO Notifications (UserID, Title, Message, Type, RelatedID)
            VALUES (@UserID,
                    N'Đơn hàng #' + CAST(@OrderID AS NVARCHAR(20)) + N' đã bị hủy',
                    ISNULL(N'Lý do: ' + @AdminNote, N'Đơn hàng của bạn đã bị hủy. Vui lòng liên hệ hỗ trợ.'),
                    'Order', @OrderID);

            -- Vô hiệu hóa phiếu bảo hành (nếu đã phát sinh)
            UPDATE ProductWarranties SET Status = N'Vô hiệu'
            WHERE OrderDetailID IN (SELECT DetailID FROM OrderDetails WHERE OrderID = @OrderID);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK; THROW;
    END CATCH
END;
GO


-- ----------------------------------------------------------------------------
-- SP 013/107
-- Tên: sp_Admin_ProcessWarrantyClaim
-- Nhóm chức năng: Admin
-- Tác dụng: Xử lý yêu cầu bảo hành
-- Dòng gốc: 1127-1200
-- ----------------------------------------------------------------------------

-- SP 13: Xử lý yêu cầu bảo hành
CREATE PROCEDURE sp_Admin_ProcessWarrantyClaim
    @ClaimID    INT,
    @NewStatus  NVARCHAR(50),
    @Resolution NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @UserID INT;
    DECLARE @WarrantyID INT;
    DECLARE @WarrantyEndDate DATETIME;

    SELECT
        @UserID = wc.UserID,
        @WarrantyID = wc.WarrantyID,
        @WarrantyEndDate = pw.EndDate
    FROM WarrantyClaims wc
    JOIN ProductWarranties pw ON pw.WarrantyID = wc.WarrantyID
    WHERE wc.ClaimID = @ClaimID;

    IF @WarrantyID IS NULL
    BEGIN
        RAISERROR(N'Yeu cau bao hanh khong ton tai!', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
    BEGIN TRY
        UPDATE WarrantyClaims
        SET Status     = @NewStatus,
            Resolution = @Resolution,
            ResolvedAt = CASE
                WHEN @NewStatus IN (N'Da hoan tra', N'Tu choi') THEN GETDATE()
                ELSE NULL
            END
        WHERE ClaimID = @ClaimID;

        IF @NewStatus IN (N'Da hoan tra', N'Tu choi')
        BEGIN
            UPDATE ProductWarranties
            SET Status = CASE
                WHEN @WarrantyEndDate >= GETDATE() THEN N'Dang hieu luc'
                ELSE N'Da het han'
            END
            WHERE WarrantyID = @WarrantyID;
        END
        ELSE
        BEGIN
            UPDATE ProductWarranties
            SET Status = N'Dang xu ly'
            WHERE WarrantyID = @WarrantyID;
        END

        INSERT INTO Notifications (UserID, Title, Message, Type, RelatedID)
        VALUES
        (
            @UserID,
            N'Cap nhat yeu cau bao hanh',
            N'Yeu cau bao hanh cua ban: ' + @NewStatus + N'. ' + ISNULL(@Resolution, N''),
            'Warranty',
            @ClaimID
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END;
GO


-- ----------------------------------------------------------------------------
-- SP 014/107
-- Tên: sp_Admin_UpsertBanner
-- Nhóm chức năng: Admin
-- Tác dụng: Quản lý Banner (Thêm mới hoặc Cập nhật)
-- Dòng gốc: 1202-1225
-- ----------------------------------------------------------------------------

-- SP 14: Quản lý Banner (Thêm mới hoặc Cập nhật)
CREATE PROCEDURE sp_Admin_UpsertBanner
    @BannerID    INT = NULL,
    @Title       NVARCHAR(200),
    @ImageURL    NVARCHAR(500),
    @LinkURL     NVARCHAR(500),
    @DisplayOrder INT,
    @StartDate   DATETIME = NULL,
    @EndDate     DATETIME = NULL,
    @IsActive    BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF @BannerID IS NULL
        INSERT INTO Banners (Title, ImageURL, LinkURL, DisplayOrder, StartDate, EndDate, IsActive)
        VALUES (@Title, @ImageURL, @LinkURL, @DisplayOrder, @StartDate, @EndDate, @IsActive);
    ELSE
        UPDATE Banners
        SET Title = @Title, ImageURL = @ImageURL, LinkURL = @LinkURL,
            DisplayOrder = @DisplayOrder, StartDate = @StartDate,
            EndDate = @EndDate, IsActive = @IsActive
        WHERE BannerID = @BannerID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 015/107
-- Tên: sp_Admin_GetRevenueReport
-- Nhóm chức năng: Admin
-- Tác dụng: Báo cáo doanh thu theo ngày (phục vụ vẽ biểu đồ)
-- Dòng gốc: 1227-1246
-- ----------------------------------------------------------------------------

-- SP 15: Báo cáo doanh thu theo ngày (phục vụ vẽ biểu đồ)
CREATE PROCEDURE sp_Admin_GetRevenueReport
    @StartDate DATETIME,
    @EndDate   DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        CAST(o.OrderDate AS DATE)        AS SalesDate,
        COUNT(o.OrderID)                  AS TotalOrders,
        SUM(o.FinalAmount)                AS Revenue,
        SUM(o.DiscountAmount)             AS TotalDiscount,
        AVG(o.FinalAmount)                AS AvgOrderValue
    FROM Orders o
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
      AND o.Status = N'Hoàn tất'
    GROUP BY CAST(o.OrderDate AS DATE)
    ORDER BY SalesDate DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 016/107
-- Tên: sp_Admin_GetLowStockAlert
-- Nhóm chức năng: Admin
-- Tác dụng: Cảnh báo sản phẩm sắp hết hàng
-- Dòng gốc: 1248-1259
-- ----------------------------------------------------------------------------

-- SP 16: Cảnh báo sản phẩm sắp hết hàng
CREATE PROCEDURE sp_Admin_GetLowStockAlert
    @Threshold INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SKU, ProductName, StockQuantity, SoldCount
    FROM Products
    WHERE StockQuantity <= @Threshold AND IsActive = 1
    ORDER BY StockQuantity ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 017/107
-- Tên: sp_Admin_ApproveReview
-- Nhóm chức năng: Admin
-- Tác dụng: Duyệt hoặc từ chối đánh giá sản phẩm
-- Dòng gốc: 1261-1270
-- ----------------------------------------------------------------------------

-- SP 17: Duyệt hoặc từ chối đánh giá sản phẩm
CREATE PROCEDURE sp_Admin_ApproveReview
    @ReviewID   INT,
    @IsApproved BIT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Reviews SET IsApproved = @IsApproved WHERE ReviewID = @ReviewID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 018/107
-- Tên: sp_Admin_GetTopSellingProducts
-- Nhóm chức năng: Admin
-- Tác dụng: Thống kê sản phẩm bán chạy
-- Dòng gốc: 1272-1295
-- ----------------------------------------------------------------------------

-- SP 18: Thống kê sản phẩm bán chạy
CREATE PROCEDURE sp_Admin_GetTopSellingProducts
    @TopN      INT = 10,
    @StartDate DATETIME = NULL,
    @EndDate   DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @StartDate = ISNULL(@StartDate, DATEADD(MONTH, -1, GETDATE()));
    SET @EndDate   = ISNULL(@EndDate, GETDATE());

    SELECT TOP (@TopN)
        p.ProductID, p.ProductName, p.SKU,
        SUM(od.Quantity)              AS TotalSold,
        SUM(od.Quantity * od.UnitPrice) AS TotalRevenue
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    JOIN Orders   o ON od.OrderID   = o.OrderID
    WHERE o.Status    = N'Hoàn tất'
      AND o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY p.ProductID, p.ProductName, p.SKU
    ORDER BY TotalSold DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 019/107
-- Tên: sp_Auth_LoginLocal
-- Nhóm chức năng: Auth
-- Tác dụng: AUTH
-- Dòng gốc: 1297-1327
-- ----------------------------------------------------------------------------

-- ============================================================
-- MISSING CRUD / QUERY PROCEDURES
-- Bo sung cac SP con thieu de hoan thien REST API
-- An toan de chay lai nhieu lan nhờ CREATE OR ALTER
-- Thu tu nhom: Auth -> Product -> Category -> Brand -> Cart -> Order
--              -> Banner -> Voucher -> User -> Address -> Chat -> Dashboard
-- ============================================================

-- ========================
-- AUTH
-- ========================

CREATE OR ALTER PROCEDURE sp_Auth_LoginLocal
    @Email        NVARCHAR(100),
    @PasswordHash NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        UserID,
        FullName,
        Email,
        Role,
        IsActive
    FROM Users
    WHERE Email = @Email
      AND PasswordHash = @PasswordHash
      AND LoginProvider = 'Local';
END;
GO


-- ----------------------------------------------------------------------------
-- SP 020/107
-- Tên: sp_Product_GetAll
-- Nhóm chức năng: Product
-- Tác dụng: PRODUCTS
-- Dòng gốc: 1329-1404
-- ----------------------------------------------------------------------------

-- ========================
-- PRODUCTS
-- ========================

CREATE OR ALTER PROCEDURE sp_Product_GetAll
    @CategoryID      INT = NULL,
    @BrandID         INT = NULL,
    @Keyword         NVARCHAR(255) = NULL,
    @MinPrice        DECIMAL(18, 2) = NULL,
    @MaxPrice        DECIMAL(18, 2) = NULL,
    @OnlyActive      BIT = 1,
    @SortBy          NVARCHAR(20) = N'Newest'
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.ProductID,
        p.CategoryID,
        c.CategoryName,
        p.BrandID,
        b.BrandName,
        p.SKU,
        p.ProductName,
        p.Price,
        p.DiscountPrice,
        CASE
            WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice
            ELSE p.Price
        END AS EffectivePrice,
        p.StockQuantity,
        p.SoldCount,
        p.Description,
        p.IsActive,
        p.WarrantyMonths,
        p.CreatedAt,
        p.UpdatedAt,
        img.ImageURL AS DefaultImageUrl,
        CAST(ISNULL(rv.AvgRating, 0) AS DECIMAL(3,2)) AS AvgRating,
        ISNULL(rv.ReviewCount, 0) AS ReviewCount
    FROM Products p
    LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
    LEFT JOIN Brands b ON p.BrandID = b.BrandID
    OUTER APPLY
    (
        SELECT TOP 1 ImageURL
        FROM ProductImages
        WHERE ProductID = p.ProductID
        ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC
    ) img
    OUTER APPLY
    (
        SELECT
            AVG(CAST(Rating AS DECIMAL(10, 2))) AS AvgRating,
            COUNT(*) AS ReviewCount
        FROM Reviews
        WHERE ProductID = p.ProductID
          AND IsApproved = 1
    ) rv
    WHERE (@OnlyActive = 0 OR p.IsActive = 1)
      AND (@CategoryID IS NULL OR p.CategoryID = @CategoryID)
      AND (@BrandID IS NULL OR p.BrandID = @BrandID)
      AND (@Keyword IS NULL OR p.ProductName LIKE N'%' + @Keyword + N'%' OR p.SKU LIKE N'%' + @Keyword + N'%')
      AND (@MinPrice IS NULL OR
           CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END >= @MinPrice)
      AND (@MaxPrice IS NULL OR
           CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END <= @MaxPrice)
    ORDER BY
        CASE WHEN @SortBy = N'PriceAsc' THEN CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END END ASC,
        CASE WHEN @SortBy = N'PriceDesc' THEN CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END END DESC,
        CASE WHEN @SortBy = N'BestSelling' THEN p.SoldCount END DESC,
        CASE WHEN @SortBy = N'NameAsc' THEN p.ProductName END ASC,
        CASE WHEN @SortBy = N'Newest' THEN p.ProductID END DESC,
        p.ProductID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 021/107
-- Tên: sp_Product_GetById
-- Nhóm chức năng: Product
-- Tác dụng: getbyid product thuộc nhóm product.
-- Dòng gốc: 1406-1470
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_GetById
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.ProductID,
        p.CategoryID,
        c.CategoryName,
        p.BrandID,
        b.BrandName,
        p.SKU,
        p.ProductName,
        p.Price,
        p.DiscountPrice,
        CASE
            WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice
            ELSE p.Price
        END AS EffectivePrice,
        p.StockQuantity,
        p.SoldCount,
        p.Description,
        p.IsActive,
        p.WarrantyMonths,
        p.CreatedAt,
        p.UpdatedAt,
        CAST(ISNULL(rv.AvgRating, 0) AS DECIMAL(3,2)) AS AvgRating,
        ISNULL(rv.ReviewCount, 0) AS ReviewCount
    FROM Products p
    LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
    LEFT JOIN Brands b ON p.BrandID = b.BrandID
    OUTER APPLY
    (
        SELECT
            AVG(CAST(Rating AS DECIMAL(10, 2))) AS AvgRating,
            COUNT(*) AS ReviewCount
        FROM Reviews
        WHERE ProductID = p.ProductID
          AND IsApproved = 1
    ) rv
    WHERE p.ProductID = @ProductID;

    SELECT
        ImageID,
        ProductID,
        ImageURL,
        AltText,
        SortOrder,
        IsDefault
    FROM ProductImages
    WHERE ProductID = @ProductID
    ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC;

    SELECT
        AttrID,
        ProductID,
        AttributeName,
        AttributeValue,
        SortOrder
    FROM ProductAttributes
    WHERE ProductID = @ProductID
    ORDER BY SortOrder ASC, AttrID ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 022/107
-- Tên: sp_Product_Create
-- Nhóm chức năng: Product
-- Tác dụng: create product thuộc nhóm product.
-- Dòng gốc: 1472-1546
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_Create
    @CategoryID     INT,
    @BrandID        INT,
    @SKU            NVARCHAR(50),
    @ProductName    NVARCHAR(255),
    @Price          DECIMAL(18, 2),
    @DiscountPrice  DECIMAL(18, 2) = 0,
    @StockQuantity  INT = 0,
    @Description    NVARCHAR(MAX) = NULL,
    @WarrantyMonths INT = 12,
    @IsActive       BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @CategoryID)
    BEGIN
        RAISERROR(N'Danh muc khong ton tai!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandID = @BrandID)
    BEGIN
        RAISERROR(N'Thuong hieu khong ton tai!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Products WHERE SKU = @SKU)
    BEGIN
        RAISERROR(N'SKU da ton tai!', 16, 1);
        RETURN;
    END

    IF @Price < 0 OR @DiscountPrice < 0 OR @StockQuantity < 0 OR @WarrantyMonths < 0
    BEGIN
        RAISERROR(N'Du lieu san pham khong hop le!', 16, 1);
        RETURN;
    END

    IF @DiscountPrice > @Price AND @DiscountPrice > 0
    BEGIN
        RAISERROR(N'Gia khuyen mai khong duoc lon hon gia goc!', 16, 1);
        RETURN;
    END

    INSERT INTO Products
    (
        CategoryID,
        BrandID,
        SKU,
        ProductName,
        Price,
        DiscountPrice,
        StockQuantity,
        Description,
        IsActive,
        WarrantyMonths
    )
    VALUES
    (
        @CategoryID,
        @BrandID,
        @SKU,
        @ProductName,
        @Price,
        @DiscountPrice,
        @StockQuantity,
        @Description,
        @IsActive,
        @WarrantyMonths
    );

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewProductID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 023/107
-- Tên: sp_Product_Update
-- Nhóm chức năng: Product
-- Tác dụng: update product thuộc nhóm product.
-- Dòng gốc: 1548-1616
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_Update
    @ProductID       INT,
    @CategoryID      INT,
    @BrandID         INT,
    @SKU             NVARCHAR(50),
    @ProductName     NVARCHAR(255),
    @Price           DECIMAL(18, 2),
    @DiscountPrice   DECIMAL(18, 2) = 0,
    @StockQuantity   INT,
    @Description     NVARCHAR(MAX) = NULL,
    @WarrantyMonths  INT = 12,
    @IsActive        BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR(N'San pham khong ton tai!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @CategoryID)
    BEGIN
        RAISERROR(N'Danh muc khong ton tai!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandID = @BrandID)
    BEGIN
        RAISERROR(N'Thuong hieu khong ton tai!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Products WHERE SKU = @SKU AND ProductID <> @ProductID)
    BEGIN
        RAISERROR(N'SKU da ton tai!', 16, 1);
        RETURN;
    END

    IF @Price < 0 OR @DiscountPrice < 0 OR @StockQuantity < 0 OR @WarrantyMonths < 0
    BEGIN
        RAISERROR(N'Du lieu san pham khong hop le!', 16, 1);
        RETURN;
    END

    IF @DiscountPrice > @Price AND @DiscountPrice > 0
    BEGIN
        RAISERROR(N'Gia khuyen mai khong duoc lon hon gia goc!', 16, 1);
        RETURN;
    END

    UPDATE Products
    SET CategoryID     = @CategoryID,
        BrandID        = @BrandID,
        SKU            = @SKU,
        ProductName    = @ProductName,
        Price          = @Price,
        DiscountPrice  = @DiscountPrice,
        StockQuantity  = @StockQuantity,
        Description    = @Description,
        WarrantyMonths = @WarrantyMonths,
        IsActive       = @IsActive,
        UpdatedAt      = GETDATE()
    WHERE ProductID = @ProductID;

    SELECT @ProductID AS UpdatedProductID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 024/107
-- Tên: sp_Product_Delete
-- Nhóm chức năng: Product
-- Tác dụng: delete product thuộc nhóm product.
-- Dòng gốc: 1618-1637
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_Delete
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR(N'San pham khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Products
    SET IsActive = 0,
        UpdatedAt = GETDATE()
    WHERE ProductID = @ProductID;

    SELECT @ProductID AS DeletedProductID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 025/107
-- Tên: sp_Product_GetReviews
-- Nhóm chức năng: Product
-- Tác dụng: getreviews product thuộc nhóm product.
-- Dòng gốc: 1639-1662
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_GetReviews
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.ReviewID,
        r.ProductID,
        r.UserID,
        u.FullName,
        u.AvatarURL,
        r.Rating,
        r.Comment,
        r.ImageURL,
        r.IsApproved,
        r.CreatedAt
    FROM Reviews r
    JOIN Users u ON r.UserID = u.UserID
    WHERE r.ProductID = @ProductID
      AND r.IsApproved = 1
    ORDER BY r.CreatedAt DESC, r.ReviewID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 026/107
-- Tên: sp_Category_GetAll
-- Nhóm chức năng: Category
-- Tác dụng: CATEGORIES
-- Dòng gốc: 1664-1697
-- ----------------------------------------------------------------------------

-- ========================
-- CATEGORIES
-- ========================

CREATE OR ALTER PROCEDURE sp_Category_GetAll
    @OnlyActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CategoryID,
        c.CategoryName,
        c.ParentID,
        p.CategoryName AS ParentCategoryName,
        c.IconURL,
        c.SortOrder,
        c.IsActive,
        COUNT(pr.ProductID) AS ProductCount
    FROM Categories c
    LEFT JOIN Categories p ON c.ParentID = p.CategoryID
    LEFT JOIN Products pr ON pr.CategoryID = c.CategoryID AND pr.IsActive = 1
    WHERE (@OnlyActive = 0 OR c.IsActive = 1)
    GROUP BY
        c.CategoryID,
        c.CategoryName,
        c.ParentID,
        p.CategoryName,
        c.IconURL,
        c.SortOrder,
        c.IsActive
    ORDER BY c.SortOrder ASC, c.CategoryName ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 027/107
-- Tên: sp_Category_Create
-- Nhóm chức năng: Category
-- Tác dụng: create category thuộc nhóm category.
-- Dòng gốc: 1699-1726
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Category_Create
    @CategoryName NVARCHAR(100),
    @ParentID     INT = NULL,
    @IconURL      NVARCHAR(500) = NULL,
    @SortOrder    INT = 0,
    @IsActive     BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @ParentID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @ParentID)
    BEGIN
        RAISERROR(N'Danh muc cha khong ton tai!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Categories WHERE CategoryName = @CategoryName AND ISNULL(ParentID, 0) = ISNULL(@ParentID, 0))
    BEGIN
        RAISERROR(N'Danh muc da ton tai!', 16, 1);
        RETURN;
    END

    INSERT INTO Categories (CategoryName, ParentID, IconURL, SortOrder, IsActive)
    VALUES (@CategoryName, @ParentID, @IconURL, @SortOrder, @IsActive);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewCategoryID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 028/107
-- Tên: sp_Category_Update
-- Nhóm chức năng: Category
-- Tác dụng: update category thuộc nhóm category.
-- Dòng gốc: 1728-1780
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Category_Update
    @CategoryID   INT,
    @CategoryName NVARCHAR(100),
    @ParentID     INT = NULL,
    @IconURL      NVARCHAR(500) = NULL,
    @SortOrder    INT = 0,
    @IsActive     BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @CategoryID)
    BEGIN
        RAISERROR(N'Danh muc khong ton tai!', 16, 1);
        RETURN;
    END

    IF @ParentID = @CategoryID
    BEGIN
        RAISERROR(N'Danh muc khong the la cha cua chinh no!', 16, 1);
        RETURN;
    END

    IF @ParentID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @ParentID)
    BEGIN
        RAISERROR(N'Danh muc cha khong ton tai!', 16, 1);
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Categories
        WHERE CategoryName = @CategoryName
          AND ISNULL(ParentID, 0) = ISNULL(@ParentID, 0)
          AND CategoryID <> @CategoryID
    )
    BEGIN
        RAISERROR(N'Danh muc da ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Categories
    SET CategoryName = @CategoryName,
        ParentID     = @ParentID,
        IconURL      = @IconURL,
        SortOrder    = @SortOrder,
        IsActive     = @IsActive
    WHERE CategoryID = @CategoryID;

    SELECT @CategoryID AS UpdatedCategoryID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 029/107
-- Tên: sp_Category_Delete
-- Nhóm chức năng: Category
-- Tác dụng: delete category thuộc nhóm category.
-- Dòng gốc: 1782-1800
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Category_Delete
    @CategoryID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryID = @CategoryID)
    BEGIN
        RAISERROR(N'Danh muc khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Categories
    SET IsActive = 0
    WHERE CategoryID = @CategoryID;

    SELECT @CategoryID AS DeletedCategoryID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 030/107
-- Tên: sp_Brand_GetAll
-- Nhóm chức năng: Brand
-- Tác dụng: BRANDS
-- Dòng gốc: 1802-1832
-- ----------------------------------------------------------------------------

-- ========================
-- BRANDS
-- ========================

CREATE OR ALTER PROCEDURE sp_Brand_GetAll
    @OnlyActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.BrandID,
        b.BrandName,
        b.LogoURL,
        b.Description,
        b.IsActive,
        b.CreatedAt,
        COUNT(p.ProductID) AS ProductCount
    FROM Brands b
    LEFT JOIN Products p ON p.BrandID = b.BrandID AND p.IsActive = 1
    WHERE (@OnlyActive = 0 OR b.IsActive = 1)
    GROUP BY
        b.BrandID,
        b.BrandName,
        b.LogoURL,
        b.Description,
        b.IsActive,
        b.CreatedAt
    ORDER BY b.BrandName ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 031/107
-- Tên: sp_Brand_Create
-- Nhóm chức năng: Brand
-- Tác dụng: create brand thuộc nhóm brand.
-- Dòng gốc: 1834-1854
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Brand_Create
    @BrandName   NVARCHAR(100),
    @LogoURL     NVARCHAR(500) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @IsActive    BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Brands WHERE BrandName = @BrandName)
    BEGIN
        RAISERROR(N'Thuong hieu da ton tai!', 16, 1);
        RETURN;
    END

    INSERT INTO Brands (BrandName, LogoURL, Description, IsActive)
    VALUES (@BrandName, @LogoURL, @Description, @IsActive);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewBrandID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 032/107
-- Tên: sp_Brand_Update
-- Nhóm chức năng: Brand
-- Tác dụng: update brand thuộc nhóm brand.
-- Dòng gốc: 1856-1887
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Brand_Update
    @BrandID      INT,
    @BrandName    NVARCHAR(100),
    @LogoURL      NVARCHAR(500) = NULL,
    @Description  NVARCHAR(MAX) = NULL,
    @IsActive     BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandID = @BrandID)
    BEGIN
        RAISERROR(N'Thuong hieu khong ton tai!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Brands WHERE BrandName = @BrandName AND BrandID <> @BrandID)
    BEGIN
        RAISERROR(N'Thuong hieu da ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Brands
    SET BrandName   = @BrandName,
        LogoURL     = @LogoURL,
        Description = @Description,
        IsActive    = @IsActive
    WHERE BrandID = @BrandID;

    SELECT @BrandID AS UpdatedBrandID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 033/107
-- Tên: sp_Brand_Delete
-- Nhóm chức năng: Brand
-- Tác dụng: delete brand thuộc nhóm brand.
-- Dòng gốc: 1889-1907
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Brand_Delete
    @BrandID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Brands WHERE BrandID = @BrandID)
    BEGIN
        RAISERROR(N'Thuong hieu khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Brands
    SET IsActive = 0
    WHERE BrandID = @BrandID;

    SELECT @BrandID AS DeletedBrandID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 034/107
-- Tên: sp_Customer_GetCart
-- Nhóm chức năng: Customer
-- Tác dụng: CART
-- Dòng gốc: 1909-1953
-- ----------------------------------------------------------------------------

-- ========================
-- CART
-- ========================

CREATE OR ALTER PROCEDURE sp_Customer_GetCart
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CartID,
        c.UserID,
        c.ProductID,
        p.SKU,
        p.ProductName,
        p.Price,
        p.DiscountPrice,
        CASE
            WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice
            ELSE p.Price
        END AS UnitPrice,
        c.Quantity,
        c.Quantity *
        CASE
            WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice
            ELSE p.Price
        END AS LineTotal,
        p.StockQuantity,
        p.IsActive,
        img.ImageURL AS DefaultImageUrl,
        c.AddedAt
    FROM Cart c
    JOIN Products p ON c.ProductID = p.ProductID
    OUTER APPLY
    (
        SELECT TOP 1 ImageURL
        FROM ProductImages
        WHERE ProductID = p.ProductID
        ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC
    ) img
    WHERE c.UserID = @UserID
    ORDER BY c.AddedAt DESC, c.CartID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 035/107
-- Tên: sp_Customer_CancelOrder
-- Nhóm chức năng: Customer
-- Tác dụng: ORDERS
-- Dòng gốc: 1955-2037
-- ----------------------------------------------------------------------------

-- ========================
-- ORDERS
-- ========================

CREATE OR ALTER PROCEDURE sp_Customer_CancelOrder
    @OrderID INT,
    @UserID  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OldStatus NVARCHAR(50);

    SELECT @OldStatus = Status
    FROM Orders
    WHERE OrderID = @OrderID
      AND UserID = @UserID;

    IF @OldStatus IS NULL
    BEGIN
        RAISERROR(N'Don hang khong ton tai hoac khong thuoc ve ban!', 16, 1);
        RETURN;
    END

    IF @OldStatus NOT IN (N'Chờ xác nhận', N'Đã xác nhận')
    BEGIN
        RAISERROR(N'Chi duoc huy don khi don dang cho xac nhan hoac da xac nhan!', 16, 1);
        RETURN;
    END

    BEGIN TRAN;
    BEGIN TRY
        UPDATE Orders
        SET Status    = N'Đã hủy',
            AdminNote = N'Khach hang tu huy don',
            UpdatedAt = GETDATE()
        WHERE OrderID = @OrderID
          AND UserID = @UserID;

        UPDATE p
        SET p.StockQuantity = p.StockQuantity + od.Quantity,
            p.SoldCount     = p.SoldCount - od.Quantity,
            p.UpdatedAt     = GETDATE()
        FROM Products p
        JOIN OrderDetails od ON p.ProductID = od.ProductID
        WHERE od.OrderID = @OrderID;

        INSERT INTO InventoryLog (ProductID, ChangeQuantity, QuantityAfter, LogType, RelatedOrderID, Note)
        SELECT
            od.ProductID,
            od.Quantity,
            p.StockQuantity,
            N'Hoàn trả',
            @OrderID,
            N'Khach hang huy don #' + CAST(@OrderID AS NVARCHAR(20))
        FROM OrderDetails od
        JOIN Products p ON od.ProductID = p.ProductID
        WHERE od.OrderID = @OrderID;

        UPDATE ProductWarranties
        SET Status = N'Vô hiệu'
        WHERE OrderDetailID IN (SELECT DetailID FROM OrderDetails WHERE OrderID = @OrderID);

        INSERT INTO Notifications (UserID, Title, Message, Type, RelatedID)
        VALUES
        (
            @UserID,
            N'Don hang #' + CAST(@OrderID AS NVARCHAR(20)) + N' da duoc huy',
            N'Yeu cau huy don cua ban da duoc ghi nhan.',
            'Order',
            @OrderID
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END;
GO


-- ----------------------------------------------------------------------------
-- SP 036/107
-- Tên: sp_Admin_GetOrders
-- Nhóm chức năng: Admin
-- Tác dụng: getorders admin thuộc nhóm admin.
-- Dòng gốc: 2039-2098
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Admin_GetOrders
    @Status    NVARCHAR(50) = NULL,
    @UserID    INT = NULL,
    @Keyword   NVARCHAR(100) = NULL,
    @DateFrom  DATETIME = NULL,
    @DateTo    DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderID,
        o.UserID,
        u.FullName,
        u.Email,
        o.OrderDate,
        o.TotalAmount,
        o.DiscountAmount,
        o.FinalAmount,
        o.VoucherCode,
        o.Status,
        o.PaymentMethod,
        o.PaymentStatus,
        o.ShippingAddress,
        o.AdminNote,
        o.UpdatedAt,
        COUNT(od.DetailID) AS ItemCount
    FROM Orders o
    JOIN Users u ON o.UserID = u.UserID
    LEFT JOIN OrderDetails od ON o.OrderID = od.OrderID
    WHERE (@Status IS NULL OR o.Status = @Status)
      AND (@UserID IS NULL OR o.UserID = @UserID)
      AND (@DateFrom IS NULL OR o.OrderDate >= @DateFrom)
      AND (@DateTo IS NULL OR o.OrderDate < DATEADD(DAY, 1, @DateTo))
      AND
      (
          @Keyword IS NULL
          OR CAST(o.OrderID AS NVARCHAR(20)) LIKE N'%' + @Keyword + N'%'
          OR u.FullName LIKE N'%' + @Keyword + N'%'
          OR u.Email LIKE N'%' + @Keyword + N'%'
      )
    GROUP BY
        o.OrderID,
        o.UserID,
        u.FullName,
        u.Email,
        o.OrderDate,
        o.TotalAmount,
        o.DiscountAmount,
        o.FinalAmount,
        o.VoucherCode,
        o.Status,
        o.PaymentMethod,
        o.PaymentStatus,
        o.ShippingAddress,
        o.AdminNote,
        o.UpdatedAt
    ORDER BY o.OrderDate DESC, o.OrderID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 037/107
-- Tên: sp_Admin_GetOrderDetail
-- Nhóm chức năng: Admin
-- Tác dụng: getorderdetail admin thuộc nhóm admin.
-- Dòng gốc: 2100-2149
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Admin_GetOrderDetail
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.OrderID,
        o.UserID,
        u.FullName,
        u.Email,
        u.PhoneNumber,
        o.OrderDate,
        o.TotalAmount,
        o.DiscountAmount,
        o.FinalAmount,
        o.VoucherCode,
        o.Status,
        o.PaymentMethod,
        o.PaymentStatus,
        o.ShippingAddress,
        o.AdminNote,
        o.UpdatedAt
    FROM Orders o
    JOIN Users u ON o.UserID = u.UserID
    WHERE o.OrderID = @OrderID;

    SELECT
        od.DetailID,
        od.OrderID,
        od.ProductID,
        p.ProductName,
        p.SKU,
        img.ImageURL AS DefaultImageUrl,
        od.Quantity,
        od.UnitPrice,
        od.Quantity * od.UnitPrice AS LineTotal
    FROM OrderDetails od
    JOIN Products p ON od.ProductID = p.ProductID
    OUTER APPLY
    (
        SELECT TOP 1 ImageURL
        FROM ProductImages
        WHERE ProductID = p.ProductID
        ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC
    ) img
    WHERE od.OrderID = @OrderID
    ORDER BY od.DetailID ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 038/107
-- Tên: sp_Admin_DeleteReview
-- Nhóm chức năng: Admin
-- Tác dụng: REVIEWS
-- Dòng gốc: 2151-2170
-- ----------------------------------------------------------------------------

-- ========================
-- REVIEWS
-- ========================

CREATE OR ALTER PROCEDURE sp_Admin_DeleteReview
    @ReviewID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Reviews WHERE ReviewID = @ReviewID)
    BEGIN
        RAISERROR(N'Danh gia khong ton tai!', 16, 1);
        RETURN;
    END

    DELETE FROM Reviews
    WHERE ReviewID = @ReviewID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 039/107
-- Tên: sp_Banner_GetActive
-- Nhóm chức năng: Banner
-- Tác dụng: BANNERS
-- Dòng gốc: 2172-2197
-- ----------------------------------------------------------------------------

-- ========================
-- BANNERS
-- ========================

CREATE OR ALTER PROCEDURE sp_Banner_GetActive
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        BannerID,
        Title,
        ImageURL,
        LinkURL,
        DisplayOrder,
        StartDate,
        EndDate,
        IsActive,
        CreatedAt
    FROM Banners
    WHERE IsActive = 1
      AND (StartDate IS NULL OR StartDate <= GETDATE())
      AND (EndDate IS NULL OR EndDate >= GETDATE())
    ORDER BY DisplayOrder ASC, BannerID ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 040/107
-- Tên: sp_Banner_Delete
-- Nhóm chức năng: Banner
-- Tác dụng: delete banner thuộc nhóm banner.
-- Dòng gốc: 2199-2217
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Banner_Delete
    @BannerID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Banners WHERE BannerID = @BannerID)
    BEGIN
        RAISERROR(N'Banner khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Banners
    SET IsActive = 0
    WHERE BannerID = @BannerID;

    SELECT @BannerID AS DeletedBannerID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 041/107
-- Tên: sp_Notification_GetByUser
-- Nhóm chức năng: Notification
-- Tác dụng: NOTIFICATIONS
-- Dòng gốc: 2219-2242
-- ----------------------------------------------------------------------------

-- ========================
-- NOTIFICATIONS
-- ========================

CREATE OR ALTER PROCEDURE sp_Notification_GetByUser
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        NotifID,
        UserID,
        Title,
        Message,
        Type,
        RelatedID,
        IsRead,
        CreatedAt
    FROM Notifications
    WHERE UserID = @UserID
    ORDER BY CreatedAt DESC, NotifID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 042/107
-- Tên: sp_Notification_MarkRead
-- Nhóm chức năng: Notification
-- Tác dụng: markread notification thuộc nhóm notification.
-- Dòng gốc: 2244-2262
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Notification_MarkRead
    @NotifID INT,
    @UserID  INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Notifications WHERE NotifID = @NotifID AND UserID = @UserID)
    BEGIN
        RAISERROR(N'Thong bao khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Notifications
    SET IsRead = 1
    WHERE NotifID = @NotifID
      AND UserID = @UserID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 043/107
-- Tên: sp_Customer_GetWarranties
-- Nhóm chức năng: Customer
-- Tác dụng: WARRANTY
-- Dòng gốc: 2264-2301
-- ----------------------------------------------------------------------------

-- ========================
-- WARRANTY
-- ========================

CREATE OR ALTER PROCEDURE sp_Customer_GetWarranties
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pw.WarrantyID,
        pw.OrderDetailID,
        od.OrderID,
        pw.ProductID,
        p.ProductName,
        p.SKU,
        img.ImageURL AS DefaultImageUrl,
        pw.StartDate,
        pw.EndDate,
        pw.WarrantyCode,
        pw.Status,
        od.Quantity,
        od.UnitPrice
    FROM ProductWarranties pw
    JOIN OrderDetails od ON pw.OrderDetailID = od.DetailID
    JOIN Products p ON pw.ProductID = p.ProductID
    OUTER APPLY
    (
        SELECT TOP 1 ImageURL
        FROM ProductImages
        WHERE ProductID = p.ProductID
        ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC
    ) img
    WHERE pw.UserID = @UserID
    ORDER BY pw.StartDate DESC, pw.WarrantyID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 044/107
-- Tên: sp_Admin_GetWarrantyClaims
-- Nhóm chức năng: Admin
-- Tác dụng: getwarrantyclaims admin thuộc nhóm admin.
-- Dòng gốc: 2303-2342
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Admin_GetWarrantyClaims
    @Status       NVARCHAR(50) = NULL,
    @UserID       INT = NULL,
    @WarrantyCode NVARCHAR(50) = NULL,
    @DateFrom     DATETIME = NULL,
    @DateTo       DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        wc.ClaimID,
        wc.WarrantyID,
        wc.UserID,
        u.FullName,
        u.Email,
        pw.WarrantyCode,
        pw.ProductID,
        p.ProductName,
        p.SKU,
        wc.ClaimDate,
        wc.Description,
        wc.ImageURL,
        wc.Status,
        wc.Resolution,
        wc.ResolvedAt,
        pw.StartDate AS WarrantyStartDate,
        pw.EndDate AS WarrantyEndDate
    FROM WarrantyClaims wc
    JOIN Users u ON wc.UserID = u.UserID
    JOIN ProductWarranties pw ON wc.WarrantyID = pw.WarrantyID
    JOIN Products p ON pw.ProductID = p.ProductID
    WHERE (@Status IS NULL OR wc.Status = @Status)
      AND (@UserID IS NULL OR wc.UserID = @UserID)
      AND (@WarrantyCode IS NULL OR pw.WarrantyCode = @WarrantyCode)
      AND (@DateFrom IS NULL OR wc.ClaimDate >= @DateFrom)
      AND (@DateTo IS NULL OR wc.ClaimDate < DATEADD(DAY, 1, @DateTo))
    ORDER BY wc.ClaimDate DESC, wc.ClaimID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 045/107
-- Tên: sp_User_GetProfile
-- Nhóm chức năng: User
-- Tác dụng: getprofile user thuộc nhóm user.
-- Dòng gốc: 2344-2375
-- ----------------------------------------------------------------------------













CREATE OR ALTER PROCEDURE sp_User_GetProfile
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        UserID,
        FullName,
        Email,
        PhoneNumber,
        AvatarURL,
        Role,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM Users
    WHERE UserID = @UserID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 046/107
-- Tên: sp_User_UpdateProfile
-- Nhóm chức năng: User
-- Tác dụng: updateprofile user thuộc nhóm user.
-- Dòng gốc: 2377-2401
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_User_UpdateProfile
    @UserID       INT,
    @FullName     NVARCHAR(100),
    @PhoneNumber  NVARCHAR(15) = NULL,
    @AvatarURL    NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR(N'Nguoi dung khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Users
    SET FullName    = @FullName,
        PhoneNumber = @PhoneNumber,
        AvatarURL   = @AvatarURL,
        UpdatedAt   = GETDATE()
    WHERE UserID = @UserID;

    SELECT @UserID AS UpdatedUserID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 047/107
-- Tên: sp_UserAddress_GetByUser
-- Nhóm chức năng: Useraddress
-- Tác dụng: USER ADDRESSES
-- Dòng gốc: 2403-2428
-- ----------------------------------------------------------------------------

-- ========================
-- USER ADDRESSES
-- ========================

CREATE OR ALTER PROCEDURE sp_UserAddress_GetByUser
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

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
    FROM UserAddresses
    WHERE UserID = @UserID
    ORDER BY IsDefault DESC, CreatedAt DESC, AddressID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 048/107
-- Tên: sp_UserAddress_Create
-- Nhóm chức năng: Useraddress
-- Tác dụng: create useraddress thuộc nhóm useraddress.
-- Dòng gốc: 2430-2474
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_UserAddress_Create
    @UserID        INT,
    @ReceiverName  NVARCHAR(100),
    @PhoneNumber   NVARCHAR(15),
    @Province      NVARCHAR(100),
    @District      NVARCHAR(100),
    @Ward          NVARCHAR(100),
    @DetailAddress NVARCHAR(255),
    @IsDefault     BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR(N'Nguoi dung khong ton tai!', 16, 1);
        RETURN;
    END

    INSERT INTO UserAddresses
    (
        UserID,
        ReceiverName,
        PhoneNumber,
        Province,
        District,
        Ward,
        DetailAddress,
        IsDefault
    )
    VALUES
    (
        @UserID,
        @ReceiverName,
        @PhoneNumber,
        @Province,
        @District,
        @Ward,
        @DetailAddress,
        @IsDefault
    );

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewAddressId;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 049/107
-- Tên: sp_UserAddress_Update
-- Nhóm chức năng: Useraddress
-- Tác dụng: update useraddress thuộc nhóm useraddress.
-- Dòng gốc: 2476-2509
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_UserAddress_Update
    @AddressID      INT,
    @UserID         INT,
    @ReceiverName   NVARCHAR(100),
    @PhoneNumber    NVARCHAR(15),
    @Province       NVARCHAR(100),
    @District       NVARCHAR(100),
    @Ward           NVARCHAR(100),
    @DetailAddress  NVARCHAR(255),
    @IsDefault      BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM UserAddresses WHERE AddressID = @AddressID AND UserID = @UserID)
    BEGIN
        RAISERROR(N'Dia chi khong ton tai hoac khong thuoc ve ban!', 16, 1);
        RETURN;
    END

    UPDATE UserAddresses
    SET ReceiverName  = @ReceiverName,
        PhoneNumber   = @PhoneNumber,
        Province      = @Province,
        District      = @District,
        Ward          = @Ward,
        DetailAddress = @DetailAddress,
        IsDefault     = @IsDefault
    WHERE AddressID = @AddressID
      AND UserID = @UserID;

    SELECT @AddressID AS UpdatedAddressId;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 050/107
-- Tên: sp_UserAddress_Delete
-- Nhóm chức năng: Useraddress
-- Tác dụng: delete useraddress thuộc nhóm useraddress.
-- Dòng gốc: 2511-2528
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_UserAddress_Delete
    @AddressID INT,
    @UserID    INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM UserAddresses WHERE AddressID = @AddressID AND UserID = @UserID)
    BEGIN
        RAISERROR(N'Dia chi khong ton tai hoac khong thuoc ve ban!', 16, 1);
        RETURN;
    END

    DELETE FROM UserAddresses
    WHERE AddressID = @AddressID
      AND UserID = @UserID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 051/107
-- Tên: sp_Product_AddImage
-- Nhóm chức năng: Product
-- Tác dụng: PRODUCT IMAGES
-- Dòng gốc: 2530-2562
-- ----------------------------------------------------------------------------

-- ========================
-- PRODUCT IMAGES
-- ========================

CREATE OR ALTER PROCEDURE sp_Product_AddImage
    @ProductID  INT,
    @ImageURL   NVARCHAR(500),
    @AltText    NVARCHAR(255) = NULL,
    @SortOrder  INT = 0,
    @IsDefault  BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR(N'San pham khong ton tai!', 16, 1);
        RETURN;
    END

    IF @IsDefault = 1
    BEGIN
        UPDATE ProductImages
        SET IsDefault = 0
        WHERE ProductID = @ProductID;
    END

    INSERT INTO ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault)
    VALUES (@ProductID, @ImageURL, @AltText, @SortOrder, @IsDefault);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewImageID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 052/107
-- Tên: sp_Product_UpdateImage
-- Nhóm chức năng: Product
-- Tác dụng: updateimage product thuộc nhóm product.
-- Dòng gốc: 2564-2599
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_UpdateImage
    @ImageID     INT,
    @ProductID   INT,
    @ImageURL    NVARCHAR(500),
    @AltText     NVARCHAR(255) = NULL,
    @SortOrder   INT = 0,
    @IsDefault   BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM ProductImages WHERE ImageID = @ImageID AND ProductID = @ProductID)
    BEGIN
        RAISERROR(N'Anh san pham khong ton tai!', 16, 1);
        RETURN;
    END

    IF @IsDefault = 1
    BEGIN
        UPDATE ProductImages
        SET IsDefault = 0
        WHERE ProductID = @ProductID
          AND ImageID <> @ImageID;
    END

    UPDATE ProductImages
    SET ImageURL  = @ImageURL,
        AltText   = @AltText,
        SortOrder = @SortOrder,
        IsDefault = @IsDefault
    WHERE ImageID = @ImageID
      AND ProductID = @ProductID;

    SELECT @ImageID AS UpdatedImageID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 053/107
-- Tên: sp_Product_DeleteImage
-- Nhóm chức năng: Product
-- Tác dụng: deleteimage product thuộc nhóm product.
-- Dòng gốc: 2601-2618
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_DeleteImage
    @ImageID   INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM ProductImages WHERE ImageID = @ImageID AND ProductID = @ProductID)
    BEGIN
        RAISERROR(N'Anh san pham khong ton tai!', 16, 1);
        RETURN;
    END

    DELETE FROM ProductImages
    WHERE ImageID = @ImageID
      AND ProductID = @ProductID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 054/107
-- Tên: sp_Product_AddAttribute
-- Nhóm chức năng: Product
-- Tác dụng: PRODUCT ATTRIBUTES
-- Dòng gốc: 2620-2644
-- ----------------------------------------------------------------------------

-- ========================
-- PRODUCT ATTRIBUTES
-- ========================

CREATE OR ALTER PROCEDURE sp_Product_AddAttribute
    @ProductID       INT,
    @AttributeName   NVARCHAR(100),
    @AttributeValue  NVARCHAR(255),
    @SortOrder       INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
    BEGIN
        RAISERROR(N'San pham khong ton tai!', 16, 1);
        RETURN;
    END

    INSERT INTO ProductAttributes (ProductID, AttributeName, AttributeValue, SortOrder)
    VALUES (@ProductID, @AttributeName, @AttributeValue, @SortOrder);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewAttributeID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 055/107
-- Tên: sp_Product_UpdateAttribute
-- Nhóm chức năng: Product
-- Tác dụng: updateattribute product thuộc nhóm product.
-- Dòng gốc: 2646-2671
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_UpdateAttribute
    @AttrID          INT,
    @ProductID       INT,
    @AttributeName   NVARCHAR(100),
    @AttributeValue  NVARCHAR(255),
    @SortOrder       INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM ProductAttributes WHERE AttrID = @AttrID AND ProductID = @ProductID)
    BEGIN
        RAISERROR(N'Thuoc tinh san pham khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE ProductAttributes
    SET AttributeName  = @AttributeName,
        AttributeValue = @AttributeValue,
        SortOrder      = @SortOrder
    WHERE AttrID = @AttrID
      AND ProductID = @ProductID;

    SELECT @AttrID AS UpdatedAttributeID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 056/107
-- Tên: sp_Product_DeleteAttribute
-- Nhóm chức năng: Product
-- Tác dụng: deleteattribute product thuộc nhóm product.
-- Dòng gốc: 2673-2690
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Product_DeleteAttribute
    @AttrID    INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM ProductAttributes WHERE AttrID = @AttrID AND ProductID = @ProductID)
    BEGIN
        RAISERROR(N'Thuoc tinh san pham khong ton tai!', 16, 1);
        RETURN;
    END

    DELETE FROM ProductAttributes
    WHERE AttrID = @AttrID
      AND ProductID = @ProductID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 057/107
-- Tên: sp_Voucher_GetAll
-- Nhóm chức năng: Voucher
-- Tác dụng: VOUCHERS
-- Dòng gốc: 2692-2718
-- ----------------------------------------------------------------------------

-- ========================
-- VOUCHERS
-- ========================

CREATE OR ALTER PROCEDURE sp_Voucher_GetAll
    @OnlyActive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        VoucherCode,
        Description,
        DiscountAmount,
        IsPercent,
        MaxDiscount,
        MinOrderValue,
        ExpiryDate,
        UsageLimit,
        MaxPerUser,
        IsActive,
        CreatedAt
    FROM Vouchers
    WHERE (@OnlyActive = 0 OR IsActive = 1)
    ORDER BY ExpiryDate ASC, VoucherCode ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 058/107
-- Tên: sp_Voucher_GetAvailable
-- Nhóm chức năng: Voucher
-- Tác dụng: getavailable voucher thuộc nhóm voucher.
-- Dòng gốc: 2720-2753
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Voucher_GetAvailable
    @UserID      INT,
    @OrderValue  DECIMAL(18, 2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.VoucherCode,
        v.Description,
        v.DiscountAmount,
        v.IsPercent,
        v.MaxDiscount,
        v.MinOrderValue,
        v.ExpiryDate,
        v.UsageLimit,
        v.MaxPerUser,
        UsedCount = ISNULL(vu.UsedCount, 0)
    FROM Vouchers v
    OUTER APPLY
    (
        SELECT COUNT(*) AS UsedCount
        FROM VoucherUsage
        WHERE VoucherCode = v.VoucherCode
          AND UserID = @UserID
    ) vu
    WHERE v.IsActive = 1
      AND v.ExpiryDate >= GETDATE()
      AND v.UsageLimit > 0
      AND v.MinOrderValue <= @OrderValue
      AND ISNULL(vu.UsedCount, 0) < v.MaxPerUser
    ORDER BY v.ExpiryDate ASC, v.VoucherCode ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 059/107
-- Tên: sp_Voucher_Create
-- Nhóm chức năng: Voucher
-- Tác dụng: create voucher thuộc nhóm voucher.
-- Dòng gốc: 2755-2817
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Voucher_Create
    @VoucherCode    NVARCHAR(20),
    @Description    NVARCHAR(255) = NULL,
    @DiscountAmount DECIMAL(18, 2),
    @IsPercent      BIT = 0,
    @MaxDiscount    DECIMAL(18, 2) = NULL,
    @MinOrderValue  DECIMAL(18, 2) = 0,
    @ExpiryDate     DATETIME,
    @UsageLimit     INT = 0,
    @MaxPerUser     INT = 1,
    @IsActive       BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Vouchers WHERE VoucherCode = @VoucherCode)
    BEGIN
        RAISERROR(N'Ma voucher da ton tai!', 16, 1);
        RETURN;
    END

    IF @DiscountAmount <= 0 OR @MinOrderValue < 0 OR @UsageLimit < 0 OR @MaxPerUser <= 0
    BEGIN
        RAISERROR(N'Du lieu voucher khong hop le!', 16, 1);
        RETURN;
    END

    IF @IsPercent = 1 AND @DiscountAmount > 100
    BEGIN
        RAISERROR(N'Voucher phan tram khong duoc vuot qua 100!', 16, 1);
        RETURN;
    END

    INSERT INTO Vouchers
    (
        VoucherCode,
        Description,
        DiscountAmount,
        IsPercent,
        MaxDiscount,
        MinOrderValue,
        ExpiryDate,
        UsageLimit,
        MaxPerUser,
        IsActive
    )
    VALUES
    (
        @VoucherCode,
        @Description,
        @DiscountAmount,
        @IsPercent,
        @MaxDiscount,
        @MinOrderValue,
        @ExpiryDate,
        @UsageLimit,
        @MaxPerUser,
        @IsActive
    );

    SELECT @VoucherCode AS NewVoucherCode;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 060/107
-- Tên: sp_Voucher_Update
-- Nhóm chức năng: Voucher
-- Tác dụng: update voucher thuộc nhóm voucher.
-- Dòng gốc: 2819-2866
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Voucher_Update
    @VoucherCode    NVARCHAR(20),
    @Description    NVARCHAR(255) = NULL,
    @DiscountAmount DECIMAL(18, 2),
    @IsPercent      BIT = 0,
    @MaxDiscount    DECIMAL(18, 2) = NULL,
    @MinOrderValue  DECIMAL(18, 2) = 0,
    @ExpiryDate     DATETIME,
    @UsageLimit     INT = 0,
    @MaxPerUser     INT = 1,
    @IsActive       BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Vouchers WHERE VoucherCode = @VoucherCode)
    BEGIN
        RAISERROR(N'Voucher khong ton tai!', 16, 1);
        RETURN;
    END

    IF @DiscountAmount <= 0 OR @MinOrderValue < 0 OR @UsageLimit < 0 OR @MaxPerUser <= 0
    BEGIN
        RAISERROR(N'Du lieu voucher khong hop le!', 16, 1);
        RETURN;
    END

    IF @IsPercent = 1 AND @DiscountAmount > 100
    BEGIN
        RAISERROR(N'Voucher phan tram khong duoc vuot qua 100!', 16, 1);
        RETURN;
    END

    UPDATE Vouchers
    SET Description    = @Description,
        DiscountAmount = @DiscountAmount,
        IsPercent      = @IsPercent,
        MaxDiscount    = @MaxDiscount,
        MinOrderValue  = @MinOrderValue,
        ExpiryDate     = @ExpiryDate,
        UsageLimit     = @UsageLimit,
        MaxPerUser     = @MaxPerUser,
        IsActive       = @IsActive
    WHERE VoucherCode = @VoucherCode;

    SELECT @VoucherCode AS UpdatedVoucherCode;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 061/107
-- Tên: sp_Voucher_Delete
-- Nhóm chức năng: Voucher
-- Tác dụng: delete voucher thuộc nhóm voucher.
-- Dòng gốc: 2868-2886
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Voucher_Delete
    @VoucherCode NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Vouchers WHERE VoucherCode = @VoucherCode)
    BEGIN
        RAISERROR(N'Voucher khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Vouchers
    SET IsActive = 0
    WHERE VoucherCode = @VoucherCode;

    SELECT @VoucherCode AS DeletedVoucherCode;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 062/107
-- Tên: sp_Admin_GetUsers
-- Nhóm chức năng: Admin
-- Tác dụng: ADMIN LISTS
-- Dòng gốc: 2888-2922
-- ----------------------------------------------------------------------------

-- ========================
-- ADMIN LISTS
-- ========================

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
        u.UpdatedAt
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


-- ----------------------------------------------------------------------------
-- SP 063/107
-- Tên: sp_Admin_UpdateUserStatus
-- Nhóm chức năng: Admin
-- Tác dụng: → dbo.sp_Admin_GetUserDetail
-- Dòng gốc: 2924-2951
-- ----------------------------------------------------------------------------

-- ========================
-- [ĐÃ XÓA PHIÊN BẢN CŨ] sp_Admin_GetUserDetail (version cũ, không JOIN RolePermissions)
-- Phiên bản hoàn chỉnh (JOIN RolePermissions để lấy RoleName + Description)
-- được định nghĩa ở phần "SP PHÂN QUYỀN STAFF CHI TIẾT" bên dưới
-- → dbo.sp_Admin_GetUserDetail
-- ========================

CREATE OR ALTER PROCEDURE sp_Admin_UpdateUserStatus
    @UserID    INT,
    @IsActive  BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR(N'Nguoi dung khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Users
    SET IsActive  = @IsActive,
        UpdatedAt = GETDATE()
    WHERE UserID = @UserID;

    SELECT @UserID AS UpdatedUserID;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 064/107
-- Tên: sp_Admin_GetBanners
-- Nhóm chức năng: Admin
-- Tác dụng: getbanners admin thuộc nhóm admin.
-- Dòng gốc: 2953-2971
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Admin_GetBanners
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        BannerID,
        Title,
        ImageURL,
        LinkURL,
        DisplayOrder,
        StartDate,
        EndDate,
        IsActive,
        CreatedAt
    FROM Banners
    ORDER BY IsActive DESC, DisplayOrder ASC, BannerID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 065/107
-- Tên: sp_Admin_GetReviews
-- Nhóm chức năng: Admin
-- Tác dụng: getreviews admin thuộc nhóm admin.
-- Dòng gốc: 2973-3007
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Admin_GetReviews
    @ProductID    INT = NULL,
    @IsApproved   BIT = NULL,
    @Keyword      NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.ReviewID,
        r.ProductID,
        p.ProductName,
        p.SKU,
        r.UserID,
        u.FullName,
        r.Rating,
        r.Comment,
        r.ImageURL,
        r.IsApproved,
        r.CreatedAt
    FROM Reviews r
    JOIN Products p ON r.ProductID = p.ProductID
    JOIN Users u ON r.UserID = u.UserID
    WHERE (@ProductID IS NULL OR r.ProductID = @ProductID)
      AND (@IsApproved IS NULL OR r.IsApproved = @IsApproved)
      AND
      (
          @Keyword IS NULL
          OR p.ProductName LIKE N'%' + @Keyword + N'%'
          OR p.SKU LIKE N'%' + @Keyword + N'%'
          OR u.FullName LIKE N'%' + @Keyword + N'%'
      )
    ORDER BY r.CreatedAt DESC, r.ReviewID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 066/107
-- Tên: sp_Chat_GetHistory
-- Nhóm chức năng: Chat
-- Tác dụng: CHAT / DASHBOARD
-- Dòng gốc: 3009-3030
-- ----------------------------------------------------------------------------

-- ========================
-- CHAT / DASHBOARD
-- ========================

CREATE OR ALTER PROCEDURE sp_Chat_GetHistory
    @SessionID NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MessageID,
        UserID,
        SessionID,
        UserMessage,
        BotResponse,
        CreatedAt
    FROM ChatMessages
    WHERE SessionID = @SessionID
    ORDER BY CreatedAt ASC, MessageID ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 067/107
-- Tên: sp_Admin_GetChatMessages
-- Nhóm chức năng: Admin
-- Tác dụng: getchatmessages admin thuộc nhóm admin.
-- Dòng gốc: 3032-3058
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Admin_GetChatMessages
    @UserID      INT = NULL,
    @SessionID   NVARCHAR(100) = NULL,
    @DateFrom    DATETIME = NULL,
    @DateTo      DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        cm.MessageID,
        cm.UserID,
        u.FullName,
        u.Email,
        cm.SessionID,
        cm.UserMessage,
        cm.BotResponse,
        cm.CreatedAt
    FROM ChatMessages cm
    LEFT JOIN Users u ON cm.UserID = u.UserID
    WHERE (@UserID IS NULL OR cm.UserID = @UserID)
      AND (@SessionID IS NULL OR cm.SessionID = @SessionID)
      AND (@DateFrom IS NULL OR cm.CreatedAt >= @DateFrom)
      AND (@DateTo IS NULL OR cm.CreatedAt < DATEADD(DAY, 1, @DateTo))
    ORDER BY cm.CreatedAt DESC, cm.MessageID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 068/107
-- Tên: sp_Dashboard_GetSummary
-- Nhóm chức năng: Dashboard
-- Tác dụng: getsummary dashboard thuộc nhóm dashboard.
-- Dòng gốc: 3060-3077
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_Dashboard_GetSummary
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        TotalUsers = (SELECT COUNT(*) FROM Users),
        ActiveUsers = (SELECT COUNT(*) FROM Users WHERE IsActive = 1),
        TotalProducts = (SELECT COUNT(*) FROM Products),
        ActiveProducts = (SELECT COUNT(*) FROM Products WHERE IsActive = 1),
        PendingOrders = (SELECT COUNT(*) FROM Orders WHERE Status = N'Chờ xác nhận'),
        ShippingOrders = (SELECT COUNT(*) FROM Orders WHERE Status = N'Đang giao'),
        CompletedOrders = (SELECT COUNT(*) FROM Orders WHERE Status = N'Hoàn tất'),
        LowStockProducts = (SELECT COUNT(*) FROM Products WHERE IsActive = 1 AND StockQuantity <= 5),
        OpenWarrantyClaims = (SELECT COUNT(*) FROM WarrantyClaims WHERE Status IN (N'Đang tiếp nhận', N'Đang sửa chữa')),
        UnreadNotifications = (SELECT COUNT(*) FROM Notifications WHERE IsRead = 0);
END;
GO


-- ----------------------------------------------------------------------------
-- SP 069/107
-- Tên: sp_Admin_GetInventoryLog
-- Nhóm chức năng: Admin
-- Tác dụng: ADMIN: INVENTORY LOG
-- Dòng gốc: 3079-3113
-- ----------------------------------------------------------------------------

-- ========================
-- ADMIN: INVENTORY LOG
-- ========================

CREATE OR ALTER PROCEDURE sp_Admin_GetInventoryLog
    @ProductId      INT = NULL,
    @LogType        NVARCHAR(50) = NULL,
    @RelatedOrderId INT = NULL,
    @DateFrom       DATETIME = NULL,
    @DateTo         DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        il.LogID,
        il.ProductID,
        p.ProductName,
        p.SKU,
        il.ChangeQuantity,
        il.QuantityAfter,
        il.LogType,
        il.RelatedOrderID,
        il.CreatedAt,
        il.Note
    FROM InventoryLog il
    JOIN Products p ON il.ProductID = p.ProductID
    WHERE (@ProductId IS NULL OR il.ProductID = @ProductId)
      AND (@LogType IS NULL OR il.LogType = @LogType)
      AND (@RelatedOrderId IS NULL OR il.RelatedOrderID = @RelatedOrderId)
      AND (@DateFrom IS NULL OR il.CreatedAt >= @DateFrom)
      AND (@DateTo IS NULL OR il.CreatedAt < DATEADD(DAY, 1, @DateTo))
    ORDER BY il.CreatedAt DESC, il.LogID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 070/107
-- Tên: sp_Admin_GetVoucherUsage
-- Nhóm chức năng: Admin
-- Tác dụng: ADMIN: VOUCHER USAGE
-- Dòng gốc: 3115-3150
-- ----------------------------------------------------------------------------

-- ========================
-- ADMIN: VOUCHER USAGE
-- ========================

CREATE OR ALTER PROCEDURE sp_Admin_GetVoucherUsage
    @UserId      INT = NULL,
    @VoucherCode NVARCHAR(20) = NULL,
    @OrderId     INT = NULL,
    @DateFrom    DATETIME = NULL,
    @DateTo      DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        vu.UsageID,
        vu.VoucherCode,
        v.Description AS VoucherDescription,
        vu.UserID,
        u.FullName,
        u.Email,
        vu.OrderID,
        o.FinalAmount,
        vu.UsedAt
    FROM VoucherUsage vu
    JOIN Vouchers v  ON vu.VoucherCode = v.VoucherCode
    JOIN Users u     ON vu.UserID = u.UserID
    LEFT JOIN Orders o ON vu.OrderID = o.OrderID
    WHERE (@UserId IS NULL OR vu.UserID = @UserId)
      AND (@VoucherCode IS NULL OR vu.VoucherCode = @VoucherCode)
      AND (@OrderId IS NULL OR vu.OrderID = @OrderId)
      AND (@DateFrom IS NULL OR vu.UsedAt >= @DateFrom)
      AND (@DateTo IS NULL OR vu.UsedAt < DATEADD(DAY, 1, @DateTo))
    ORDER BY vu.UsedAt DESC, vu.UsageID DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 071/107
-- Tên: sp_Admin_GetOrderDetails
-- Nhóm chức năng: Admin
-- Tác dụng: ADMIN: ORDER DETAILS LIST
-- Dòng gốc: 3152-3208
-- ----------------------------------------------------------------------------

-- ========================
-- [ĐÃ XÓA PHIÊN BẢN CŨ] sp_Admin_GetUserRoles (version cũ, không JOIN RolePermissions)
-- Phiên bản hoàn chỉnh (JOIN RolePermissions để lấy RoleName + Description + PermissionIsActive)
-- được định nghĩa ở phần "SP PHÂN QUYỀN STAFF CHI TIẾT" bên dưới
-- → dbo.sp_Admin_GetUserRoles
-- ========================

-- ========================
-- ADMIN: ORDER DETAILS LIST
-- ========================

CREATE OR ALTER PROCEDURE sp_Admin_GetOrderDetails
    @OrderId   INT = NULL,
    @ProductId INT = NULL,
    @UserId    INT = NULL,
    @DateFrom  DATETIME = NULL,
    @DateTo    DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        od.DetailID,
        od.OrderID,
        o.OrderDate,
        o.UserID,
        u.FullName,
        u.Email,
        od.ProductID,
        p.ProductName,
        p.SKU,
        img.ImageURL AS DefaultImageUrl,
        od.Quantity,
        od.UnitPrice,
        od.Quantity * od.UnitPrice AS LineTotal,
        o.Status,
        o.PaymentMethod,
        o.PaymentStatus
    FROM OrderDetails od
    JOIN Orders o   ON od.OrderID   = o.OrderID
    JOIN Users u    ON o.UserID     = u.UserID
    JOIN Products p ON od.ProductID = p.ProductID
    OUTER APPLY
    (
        SELECT TOP 1 ImageURL
        FROM ProductImages
        WHERE ProductID = p.ProductID
        ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC
    ) img
    WHERE (@OrderId IS NULL OR od.OrderID = @OrderId)
      AND (@ProductId IS NULL OR od.ProductID = @ProductId)
      AND (@UserId IS NULL OR o.UserID = @UserId)
      AND (@DateFrom IS NULL OR o.OrderDate >= @DateFrom)
      AND (@DateTo IS NULL OR o.OrderDate < DATEADD(DAY, 1, @DateTo))
    ORDER BY od.OrderID DESC, od.DetailID ASC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 072/107
-- Tên: sp_Brand_GetById
-- Nhóm chức năng: Brand
-- Tác dụng: BRAND: GET BY ID
-- Dòng gốc: 3210-3241
-- ----------------------------------------------------------------------------

-- ========================
-- CUSTOMER: ADD REVIEW
-- ========================
-- (SP da co san tu dau, them vay de de tra cuu)
-- sp_Customer_AddReview da duoc dinh nghia o dong 871

-- ========================
-- BRAND: GET BY ID
-- ========================

CREATE OR ALTER PROCEDURE sp_Brand_GetById
    @BrandId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.BrandID,
        b.BrandName,
        b.LogoURL,
        b.Description,
        b.IsActive,
        b.CreatedAt,
        COUNT(p.ProductID) AS ProductCount
    FROM Brands b
    LEFT JOIN Products p ON p.BrandID = b.BrandID AND p.IsActive = 1
    WHERE b.BrandID = @BrandId
    GROUP BY
        b.BrandID, b.BrandName, b.LogoURL,
        b.Description, b.IsActive, b.CreatedAt;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 073/107
-- Tên: sp_Category_GetById
-- Nhóm chức năng: Category
-- Tác dụng: CATEGORY: GET BY ID
-- Dòng gốc: 3243-3270
-- ----------------------------------------------------------------------------

-- ========================
-- CATEGORY: GET BY ID
-- ========================

CREATE OR ALTER PROCEDURE sp_Category_GetById
    @CategoryId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CategoryID,
        c.CategoryName,
        c.ParentID,
        p.CategoryName AS ParentCategoryName,
        c.IconURL,
        c.SortOrder,
        c.IsActive,
        COUNT(pr.ProductID) AS ProductCount
    FROM Categories c
    LEFT JOIN Categories p  ON c.ParentID     = p.CategoryID
    LEFT JOIN Products pr   ON pr.CategoryID  = c.CategoryID AND pr.IsActive = 1
    WHERE c.CategoryID = @CategoryId
    GROUP BY
        c.CategoryID, c.CategoryName, c.ParentID,
        p.CategoryName, c.IconURL, c.SortOrder, c.IsActive;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 074/107
-- Tên: sp_Notification_MarkAllRead
-- Nhóm chức năng: Notification
-- Tác dụng: NOTIFICATION: MARK ALL READ
-- Dòng gốc: 3272-3289
-- ----------------------------------------------------------------------------

-- ========================
-- NOTIFICATION: MARK ALL READ
-- ========================

CREATE OR ALTER PROCEDURE sp_Notification_MarkAllRead
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Notifications
    SET IsRead = 1
    WHERE UserID = @UserId
      AND IsRead = 0;

    SELECT @@ROWCOUNT AS UpdatedCount;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 075/107
-- Tên: sp_Notification_Delete
-- Nhóm chức năng: Notification
-- Tác dụng: NOTIFICATION: DELETE
-- Dòng gốc: 3291-3312
-- ----------------------------------------------------------------------------

-- ========================
-- NOTIFICATION: DELETE
-- ========================

CREATE OR ALTER PROCEDURE sp_Notification_Delete
    @NotifId INT,
    @UserId  INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Notifications WHERE NotifID = @NotifId AND UserID = @UserId)
    BEGIN
        RAISERROR(N'Thong bao khong ton tai hoac khong thuoc ve ban!', 16, 1);
        RETURN;
    END

    DELETE FROM Notifications
    WHERE NotifID = @NotifId
      AND UserID  = @UserId;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 076/107
-- Tên: sp_Warranty_GetByCode
-- Nhóm chức năng: Warranty
-- Tác dụng: WARRANTY: GET BY CODE
-- Dòng gốc: 3314-3352
-- ----------------------------------------------------------------------------

-- ========================
-- WARRANTY: GET BY CODE
-- ========================

CREATE OR ALTER PROCEDURE sp_Warranty_GetByCode
    @WarrantyCode NVARCHAR(50),
    @UserId       INT = NULL   -- NULL = admin, NOT NULL = validate ownership
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        pw.WarrantyID,
        pw.OrderDetailID,
        od.OrderID,
        pw.ProductID,
        p.ProductName,
        p.SKU,
        img.ImageURL AS DefaultImageUrl,
        pw.StartDate,
        pw.EndDate,
        pw.WarrantyCode,
        pw.Status,
        od.Quantity,
        od.UnitPrice
    FROM ProductWarranties pw
    JOIN OrderDetails od ON pw.OrderDetailID = od.DetailID
    JOIN Products p      ON pw.ProductID     = p.ProductID
    OUTER APPLY
    (
        SELECT TOP 1 ImageURL
        FROM ProductImages
        WHERE ProductID = p.ProductID
        ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC
    ) img
    WHERE pw.WarrantyCode = @WarrantyCode
      AND (@UserId IS NULL OR pw.UserID = @UserId);
END;
GO


-- ----------------------------------------------------------------------------
-- SP 077/107
-- Tên: sp_Auth_ChangePassword
-- Nhóm chức năng: Auth
-- Tác dụng: AUTH: CHANGE PASSWORD
-- Dòng gốc: 3354-3384
-- ----------------------------------------------------------------------------

-- ========================
-- AUTH: CHANGE PASSWORD
-- ========================

CREATE OR ALTER PROCEDURE sp_Auth_ChangePassword
    @UserId          INT,
    @OldPasswordHash NVARCHAR(256),
    @NewPasswordHash NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM Users
        WHERE UserID       = @UserId
          AND PasswordHash = @OldPasswordHash
          AND IsActive     = 1
    )
    BEGIN
        RAISERROR(N'Mat khau cu khong chinh xac hoac tai khoan khong ton tai!', 16, 1);
        RETURN;
    END

    UPDATE Users
    SET PasswordHash = @NewPasswordHash,
        UpdatedAt    = GETDATE()
    WHERE UserID = @UserId;

    SELECT @UserId AS UpdatedUserId;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 078/107
-- Tên: sp_Admin_SendNotification
-- Nhóm chức năng: Admin
-- Tác dụng: ADMIN: SEND NOTIFICATION TO USER
-- Dòng gốc: 3386-3411
-- ----------------------------------------------------------------------------

-- ========================
-- ADMIN: SEND NOTIFICATION TO USER
-- ========================

CREATE OR ALTER PROCEDURE sp_Admin_SendNotification
    @UserId    INT,
    @Title     NVARCHAR(200),
    @Message   NVARCHAR(1000),
    @Type      NVARCHAR(50),     -- 'Order' | 'Promotion' | 'System' | 'Warranty'
    @RelatedId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Users WHERE UserID = @UserId AND IsActive = 1)
    BEGIN
        RAISERROR(N'Nguoi dung khong ton tai hoac da bi vo hieu hoa!', 16, 1);
        RETURN;
    END

    INSERT INTO Notifications (UserID, Title, Message, Type, RelatedID, IsRead, CreatedAt)
    VALUES (@UserId, @Title, @Message, @Type, @RelatedId, 0, GETDATE());

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewNotifId;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 079/107
-- Tên: sp_Auth_CheckEmail
-- Nhóm chức năng: Auth
-- Tác dụng: AUTH: CHECK EMAIL EXISTS
-- Dòng gốc: 3413-3428
-- ----------------------------------------------------------------------------

-- ========================
-- AUTH: CHECK EMAIL EXISTS
-- ========================

CREATE OR ALTER PROCEDURE sp_Auth_CheckEmail
    @Email NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        CASE WHEN EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
             THEN 1 ELSE 0
        END AS [Exists];
END;
GO


-- ----------------------------------------------------------------------------
-- SP 080/107
-- Tên: dbo.sp_Admin_GetRolePermissions
-- Nhóm chức năng: Admin
-- Tác dụng: 1. Lấy danh sách quyền Staff đang hoạt động
-- Dòng gốc: 3584-3615
-- ----------------------------------------------------------------------------






/* =========================================================
   SP PHÂN QUYỀN STAFF CHI TIẾT
   Bản tương thích hơn: dùng RAISERROR thay cho THROW
   ========================================================= */


------------------------------------------------------------
-- 1. Lấy danh sách quyền Staff đang hoạt động
------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_Admin_GetRolePermissions
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        PermissionID,
        RoleCode,
        RoleName,
        Description,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM dbo.RolePermissions
    WHERE IsActive = 1
    ORDER BY PermissionID;
END
GO


-- ----------------------------------------------------------------------------
-- SP 081/107
-- Tên: dbo.sp_Admin_SetUserRoleAndPermissions
-- Nhóm chức năng: Admin
-- Tác dụng: 2. Cập nhật role chính và danh sách quyền chi tiết
-- Dòng gốc: 3617-3784
-- ----------------------------------------------------------------------------


------------------------------------------------------------
-- 2. Cập nhật role chính và danh sách quyền chi tiết
------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_Admin_SetUserRoleAndPermissions
    @AdminID   INT,
    @UserID    INT,
    @MainRole  NVARCHAR(20),
    @RoleCodes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        ----------------------------------------------------
        -- Kiểm tra Admin thực hiện
        ----------------------------------------------------
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Users
            WHERE UserID = @AdminID
              AND Role = N'Admin'
              AND IsActive = 1
        )
        BEGIN
            RAISERROR(N'Bạn không có quyền thực hiện thao tác này.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        ----------------------------------------------------
        -- Kiểm tra user cần cập nhật có tồn tại
        ----------------------------------------------------
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Users
            WHERE UserID = @UserID
        )
        BEGIN
            RAISERROR(N'Người dùng không tồn tại.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        ----------------------------------------------------
        -- Kiểm tra role chính hợp lệ
        ----------------------------------------------------
        IF @MainRole NOT IN (N'Admin', N'Staff', N'Customer')
        BEGIN
            RAISERROR(N'Role chính không hợp lệ. Chỉ được Admin, Staff hoặc Customer.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        ----------------------------------------------------
        -- Cập nhật role chính trong bảng Users
        ----------------------------------------------------
        UPDATE dbo.Users
        SET
            Role = @MainRole,
            UpdatedAt = GETDATE()
        WHERE UserID = @UserID;

        ----------------------------------------------------
        -- Nếu không phải Staff thì xóa toàn bộ quyền Staff
        ----------------------------------------------------
        IF @MainRole <> N'Staff'
        BEGIN
            DELETE FROM dbo.UserRoles
            WHERE UserID = @UserID;

            COMMIT TRANSACTION;

            SELECT
                @UserID AS UpdatedUserID,
                @MainRole AS MainRole,
                N'Cập nhật role thành công. User không phải Staff nên đã xóa quyền Staff chi tiết.' AS Message;

            RETURN;
        END

        ----------------------------------------------------
        -- Nếu là Staff thì phải có ít nhất 1 quyền chi tiết
        ----------------------------------------------------
        DECLARE @SelectedRoles TABLE
        (
            RoleCode NVARCHAR(20) NOT NULL PRIMARY KEY
        );

        INSERT INTO @SelectedRoles (RoleCode)
        SELECT DISTINCT LTRIM(RTRIM(value))
        FROM STRING_SPLIT(ISNULL(@RoleCodes, N''), N',')
        WHERE LTRIM(RTRIM(value)) <> N'';

        IF NOT EXISTS (SELECT 1 FROM @SelectedRoles)
        BEGIN
            RAISERROR(N'Staff phải có ít nhất 1 quyền chi tiết.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        ----------------------------------------------------
        -- Kiểm tra quyền chi tiết có tồn tại và đang active
        ----------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM @SelectedRoles sr
            LEFT JOIN dbo.RolePermissions rp
                ON sr.RoleCode = rp.RoleCode
               AND rp.IsActive = 1
            WHERE rp.RoleCode IS NULL
        )
        BEGIN
            RAISERROR(N'Tồn tại RoleCode không hợp lệ hoặc đã bị tắt.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        ----------------------------------------------------
        -- Xóa quyền cũ và thêm quyền mới
        ----------------------------------------------------
        DELETE FROM dbo.UserRoles
        WHERE UserID = @UserID;

        INSERT INTO dbo.UserRoles
        (
            UserID,
            RoleCode,
            AssignedAt,
            AssignedBy
        )
        SELECT
            @UserID,
            RoleCode,
            GETDATE(),
            @AdminID
        FROM @SelectedRoles;

        COMMIT TRANSACTION;

        SELECT
            @UserID AS UpdatedUserID,
            @MainRole AS MainRole,
            N'Cập nhật quyền Staff thành công.' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO


-- ----------------------------------------------------------------------------
-- SP 082/107
-- Tên: dbo.sp_Admin_ManageUserRole
-- Nhóm chức năng: Admin
-- Tác dụng: 3. Cấp hoặc thu hồi 1 quyền Staff cụ thể
-- Dòng gốc: 3786-3905
-- ----------------------------------------------------------------------------


------------------------------------------------------------
-- 3. Cấp hoặc thu hồi 1 quyền Staff cụ thể
------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_Admin_ManageUserRole
    @AdminID  INT,
    @UserID   INT,
    @RoleCode NVARCHAR(20),
    @Action   NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- Kiểm tra Admin
    --------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Users
        WHERE UserID = @AdminID
          AND Role = N'Admin'
          AND IsActive = 1
    )
    BEGIN
        RAISERROR(N'Bạn không có quyền thực hiện thao tác này.', 16, 1);
        RETURN;
    END

    --------------------------------------------------------
    -- Kiểm tra user phải là Staff
    --------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Users
        WHERE UserID = @UserID
          AND Role = N'Staff'
          AND IsActive = 1
    )
    BEGIN
        RAISERROR(N'Chỉ tài khoản Staff đang hoạt động mới được cấp quyền nghiệp vụ.', 16, 1);
        RETURN;
    END

    --------------------------------------------------------
    -- Kiểm tra RoleCode có tồn tại và active
    --------------------------------------------------------
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.RolePermissions
        WHERE RoleCode = @RoleCode
          AND IsActive = 1
    )
    BEGIN
        RAISERROR(N'RoleCode không hợp lệ hoặc đã bị tắt.', 16, 1);
        RETURN;
    END

    --------------------------------------------------------
    -- Cấp quyền
    --------------------------------------------------------
    IF @Action = N'GRANT'
    BEGIN
        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.UserRoles
            WHERE UserID = @UserID
              AND RoleCode = @RoleCode
        )
        BEGIN
            INSERT INTO dbo.UserRoles
            (
                UserID,
                RoleCode,
                AssignedAt,
                AssignedBy
            )
            VALUES
            (
                @UserID,
                @RoleCode,
                GETDATE(),
                @AdminID
            );
        END

        SELECT
            @UserID AS UserID,
            @RoleCode AS RoleCode,
            N'Cấp quyền thành công.' AS Message;

        RETURN;
    END

    --------------------------------------------------------
    -- Thu hồi quyền
    --------------------------------------------------------
    IF @Action = N'REVOKE'
    BEGIN
        DELETE FROM dbo.UserRoles
        WHERE UserID = @UserID
          AND RoleCode = @RoleCode;

        SELECT
            @UserID AS UserID,
            @RoleCode AS RoleCode,
            N'Thu hồi quyền thành công.' AS Message;

        RETURN;
    END

    --------------------------------------------------------
    -- Action không hợp lệ
    --------------------------------------------------------
    RAISERROR(N'Action không hợp lệ. Chỉ chấp nhận GRANT hoặc REVOKE.', 16, 1);
END
GO


-- ----------------------------------------------------------------------------
-- SP 083/107
-- Tên: dbo.sp_Admin_GetUserRoles
-- Nhóm chức năng: Admin
-- Tác dụng: 4. Lấy danh sách quyền đã cấp cho Staff
-- Dòng gốc: 3907-3944
-- ----------------------------------------------------------------------------


------------------------------------------------------------
-- 4. Lấy danh sách quyền đã cấp cho Staff
------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_Admin_GetUserRoles
    @UserId   INT = NULL,
    @RoleCode NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ur.UserRoleID,
        ur.UserID,
        u.FullName,
        u.Email,
        u.Role AS BaseRole,

        ur.RoleCode,
        rp.RoleName,
        rp.Description,
        rp.IsActive AS PermissionIsActive,

        ur.AssignedAt,
        ur.AssignedBy,
        ab.FullName AS AssignedByName
    FROM dbo.UserRoles ur
    INNER JOIN dbo.Users u
        ON ur.UserID = u.UserID
    LEFT JOIN dbo.RolePermissions rp
        ON ur.RoleCode = rp.RoleCode
    LEFT JOIN dbo.Users ab
        ON ur.AssignedBy = ab.UserID
    WHERE (@UserId IS NULL OR ur.UserID = @UserId)
      AND (@RoleCode IS NULL OR ur.RoleCode = @RoleCode)
    ORDER BY ur.AssignedAt DESC, ur.UserRoleID DESC;
END
GO


-- ----------------------------------------------------------------------------
-- SP 084/107
-- Tên: dbo.sp_Admin_GetUserPermissions
-- Nhóm chức năng: Admin
-- Tác dụng: 5. Xem quyền chi tiết của 1 user
-- Dòng gốc: 3946-3982
-- ----------------------------------------------------------------------------


------------------------------------------------------------
-- 5. Xem quyền chi tiết của 1 user
------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_Admin_GetUserPermissions
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.UserID,
        u.FullName,
        u.Email,
        u.Role AS MainRole,
        u.IsActive,

        ur.UserRoleID,
        ur.RoleCode,
        rp.RoleName,
        rp.Description,
        rp.IsActive AS PermissionIsActive,

        ur.AssignedAt,
        ur.AssignedBy,
        ab.FullName AS AssignedByName
    FROM dbo.Users u
    LEFT JOIN dbo.UserRoles ur
        ON u.UserID = ur.UserID
    LEFT JOIN dbo.RolePermissions rp
        ON ur.RoleCode = rp.RoleCode
    LEFT JOIN dbo.Users ab
        ON ur.AssignedBy = ab.UserID
    WHERE u.UserID = @UserID
    ORDER BY ur.RoleCode;
END
GO


-- ----------------------------------------------------------------------------
-- SP 085/107
-- Tên: dbo.sp_Admin_GetUserDetail
-- Nhóm chức năng: Admin
-- Tác dụng: 6. Nâng cấp sp_Admin_GetUserDetail để trả RoleName, Description
-- Dòng gốc: 3984-4049
-- ----------------------------------------------------------------------------


------------------------------------------------------------
-- 6. Nâng cấp sp_Admin_GetUserDetail để trả RoleName, Description
------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_Admin_GetUserDetail
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- Thông tin chính của user
    --------------------------------------------------------
    SELECT
        UserID,
        FullName,
        Email,
        PhoneNumber,
        AvatarURL,
        Role,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM dbo.Users
    WHERE UserID = @UserID;

    --------------------------------------------------------
    -- Danh sách quyền chi tiết
    --------------------------------------------------------
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

    --------------------------------------------------------
    -- Danh sách địa chỉ của user
    --------------------------------------------------------
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
END
GO


-- ----------------------------------------------------------------------------
-- SP 086/107
-- Tên: sp_Product_GetAllPaged
-- Nhóm chức năng: Product
-- Tác dụng: getallpaged product thuộc nhóm product.
-- Dòng gốc: 4051-4063, 4065-4156
-- ----------------------------------------------------------------------------


-----------------------------------------------------------
-- PHẦN BỔ SUNG: PAGINATION CHO CÁC API QUAN TRỌNG
-- Ngày cập nhật: 2024
-- Mục đích: Tối ưu hiệu năng khi dữ liệu lớn
-----------------------------------------------------------

-- ============================================================
-- SP: Lấy danh sách sản phẩm với phân trang
-- ============================================================
IF OBJECT_ID('sp_Product_GetAllPaged', 'P') IS NOT NULL
    DROP PROCEDURE sp_Product_GetAllPaged;
GO

CREATE PROCEDURE sp_Product_GetAllPaged
    @CategoryId  INT           = NULL,
    @BrandId     INT           = NULL,
    @Keyword     NVARCHAR(255) = NULL,
    @MinPrice    DECIMAL(18,2) = NULL,
    @MaxPrice    DECIMAL(18,2) = NULL,
    @OnlyActive  BIT           = 1,
    @SortBy      NVARCHAR(20)  = 'Newest',  -- 'Newest', 'PriceLowHigh', 'PriceHighLow', 'BestSelling', 'Name'
    @PageNumber  INT           = 1,
    @PageSize    INT           = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;
    IF @PageSize > 100 SET @PageSize = 100;  -- Giới hạn tối đa 100 items/page

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    ;WITH FilteredProducts AS
    (
        SELECT
            p.ProductID,
            p.CategoryID,
            c.CategoryName,
            p.BrandID,
            b.BrandName,
            p.SKU,
            p.ProductName,
            p.Price,
            p.DiscountPrice,
            CASE
                WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice
                ELSE p.Price
            END AS EffectivePrice,
            p.StockQuantity,
            p.SoldCount,
            p.Description,
            p.IsActive,
            p.WarrantyMonths,
            p.CreatedAt,
            p.UpdatedAt,
            (SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID AND IsDefault = 1) AS DefaultImageUrl,
            ISNULL((SELECT AVG(CAST(Rating AS DECIMAL(3,2))) FROM Reviews WHERE ProductID = p.ProductID AND IsApproved = 1), 0) AS AvgRating,
            (SELECT COUNT(*) FROM Reviews WHERE ProductID = p.ProductID AND IsApproved = 1) AS ReviewCount,
            COUNT(*) OVER() AS TotalRecords  -- Tổng số bản ghi (không phân trang)
        FROM Products p
        LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
        LEFT JOIN Brands b ON p.BrandID = b.BrandID
        WHERE
            (@CategoryId IS NULL OR p.CategoryID = @CategoryId)
            AND (@BrandId IS NULL OR p.BrandID = @BrandId)
            AND (@Keyword IS NULL OR p.ProductName LIKE '%' + @Keyword + '%' OR p.SKU LIKE '%' + @Keyword + '%')
            AND (@MinPrice IS NULL OR (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END) >= @MinPrice)
            AND (@MaxPrice IS NULL OR (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END) <= @MaxPrice)
            AND (@OnlyActive = 0 OR p.IsActive = 1)
    )
    SELECT
        ProductID,
        CategoryID,
        CategoryName,
        BrandID,
        BrandName,
        SKU,
        ProductName,
        Price,
        DiscountPrice,
        EffectivePrice,
        StockQuantity,
        SoldCount,
        Description,
        IsActive,
        WarrantyMonths,
        CreatedAt,
        UpdatedAt,
        DefaultImageUrl,
        AvgRating,
        ReviewCount,
        TotalRecords
    FROM FilteredProducts
    ORDER BY
        CASE WHEN @SortBy = 'Newest' THEN CreatedAt END DESC,
        CASE WHEN @SortBy = 'PriceLowHigh' THEN EffectivePrice END ASC,
        CASE WHEN @SortBy = 'PriceHighLow' THEN EffectivePrice END DESC,
        CASE WHEN @SortBy = 'BestSelling' THEN SoldCount END DESC,
        CASE WHEN @SortBy = 'Name' THEN ProductName END ASC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


-- ----------------------------------------------------------------------------
-- SP 087/107
-- Tên: sp_Orders_GetAdminOrdersPaged
-- Nhóm chức năng: Orders
-- Tác dụng: getadminorderspaged orders thuộc nhóm orders.
-- Dòng gốc: 4158-4163, 4165-4236
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Lấy danh sách đơn hàng Admin với phân trang
-- ============================================================
IF OBJECT_ID('sp_Orders_GetAdminOrdersPaged', 'P') IS NOT NULL
    DROP PROCEDURE sp_Orders_GetAdminOrdersPaged;
GO

CREATE PROCEDURE sp_Orders_GetAdminOrdersPaged
    @Status     NVARCHAR(50)  = NULL,
    @UserId     INT           = NULL,
    @Keyword    NVARCHAR(255) = NULL,
    @DateFrom   DATETIME      = NULL,
    @DateTo     DATETIME      = NULL,
    @PageNumber INT           = 1,
    @PageSize   INT           = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;
    IF @PageSize > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    ;WITH FilteredOrders AS
    (
        SELECT
            o.OrderID,
            o.UserID,
            u.FullName,
            u.Email,
            o.OrderDate,
            o.TotalAmount,
            o.DiscountAmount,
            o.FinalAmount,
            o.VoucherCode,
            o.Status,
            o.PaymentMethod,
            o.PaymentStatus,
            o.ShippingAddress,
            o.AdminNote,
            o.UpdatedAt,
            (SELECT COUNT(*) FROM OrderDetails WHERE OrderID = o.OrderID) AS ItemCount,
            COUNT(*) OVER() AS TotalRecords
        FROM Orders o
        JOIN Users u ON o.UserID = u.UserID
        WHERE
            (@Status IS NULL OR o.Status = @Status)
            AND (@UserId IS NULL OR o.UserID = @UserId)
            AND (@Keyword IS NULL OR u.FullName LIKE '%' + @Keyword + '%' OR u.Email LIKE '%' + @Keyword + '%' OR CAST(o.OrderID AS NVARCHAR) LIKE '%' + @Keyword + '%')
            AND (@DateFrom IS NULL OR o.OrderDate >= @DateFrom)
            AND (@DateTo IS NULL OR o.OrderDate <= @DateTo)
    )
    SELECT
        OrderID,
        UserID,
        FullName,
        Email,
        OrderDate,
        TotalAmount,
        DiscountAmount,
        FinalAmount,
        VoucherCode,
        Status,
        PaymentMethod,
        PaymentStatus,
        ShippingAddress,
        AdminNote,
        UpdatedAt,
        ItemCount,
        TotalRecords
    FROM FilteredOrders
    ORDER BY OrderDate DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


-- ----------------------------------------------------------------------------
-- SP 088/107
-- Tên: sp_Orders_GetUserHistoryPaged
-- Nhóm chức năng: Orders
-- Tác dụng: getuserhistorypaged orders thuộc nhóm orders.
-- Dòng gốc: 4238-4243, 4245-4295
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Lấy lịch sử đơn hàng của User với phân trang
-- ============================================================
IF OBJECT_ID('sp_Orders_GetUserHistoryPaged', 'P') IS NOT NULL
    DROP PROCEDURE sp_Orders_GetUserHistoryPaged;
GO

CREATE PROCEDURE sp_Orders_GetUserHistoryPaged
    @UserId     INT          = NULL,
    @Status     NVARCHAR(50) = NULL,
    @PageNumber INT          = 1,
    @PageSize   INT          = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;
    IF @PageSize > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    ;WITH FilteredOrders AS
    (
        SELECT
            o.OrderID,
            o.OrderDate,
            o.TotalAmount,
            o.DiscountAmount,
            o.FinalAmount,
            o.Status,
            o.PaymentMethod,
            o.PaymentStatus,
            (SELECT COUNT(*) FROM OrderDetails WHERE OrderID = o.OrderID) AS ItemCount,
            COUNT(*) OVER() AS TotalRecords
        FROM Orders o
        WHERE
            o.UserID = @UserId
            AND (@Status IS NULL OR o.Status = @Status)
    )
    SELECT
        OrderID,
        OrderDate,
        TotalAmount,
        DiscountAmount,
        FinalAmount,
        Status,
        PaymentMethod,
        PaymentStatus,
        ItemCount,
        TotalRecords
    FROM FilteredOrders
    ORDER BY OrderDate DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


-- ----------------------------------------------------------------------------
-- SP 089/107
-- Tên: sp_Reviews_GetAdminReviewsPaged
-- Nhóm chức năng: Reviews
-- Tác dụng: getadminreviewspaged reviews thuộc nhóm reviews.
-- Dòng gốc: 4297-4302, 4304-4362
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Lấy danh sách Reviews Admin với phân trang
-- ============================================================
IF OBJECT_ID('sp_Reviews_GetAdminReviewsPaged', 'P') IS NOT NULL
    DROP PROCEDURE sp_Reviews_GetAdminReviewsPaged;
GO

CREATE PROCEDURE sp_Reviews_GetAdminReviewsPaged
    @ProductId  INT           = NULL,
    @IsApproved BIT           = NULL,
    @Keyword    NVARCHAR(255) = NULL,
    @PageNumber INT           = 1,
    @PageSize   INT           = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;
    IF @PageSize > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    ;WITH FilteredReviews AS
    (
        SELECT
            r.ReviewID,
            r.ProductID,
            p.ProductName,
            p.SKU,
            r.UserID,
            u.FullName,
            r.Rating,
            r.Comment,
            r.ImageURL,
            r.IsApproved,
            r.CreatedAt,
            COUNT(*) OVER() AS TotalRecords
        FROM Reviews r
        JOIN Products p ON r.ProductID = p.ProductID
        JOIN Users u ON r.UserID = u.UserID
        WHERE
            (@ProductId IS NULL OR r.ProductID = @ProductId)
            AND (@IsApproved IS NULL OR r.IsApproved = @IsApproved)
            AND (@Keyword IS NULL OR p.ProductName LIKE '%' + @Keyword + '%' OR u.FullName LIKE '%' + @Keyword + '%' OR r.Comment LIKE '%' + @Keyword + '%')
    )
    SELECT
        ReviewID,
        ProductID,
        ProductName,
        SKU,
        UserID,
        FullName,
        Rating,
        Comment,
        ImageURL,
        IsApproved,
        CreatedAt,
        TotalRecords
    FROM FilteredReviews
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


-- ----------------------------------------------------------------------------
-- SP 090/107
-- Tên: sp_Reviews_GetByProductPaged
-- Nhóm chức năng: Reviews
-- Tác dụng: getbyproductpaged reviews thuộc nhóm reviews.
-- Dòng gốc: 4364-4369, 4371-4421
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Lấy danh sách Reviews của Product (Customer view) với phân trang
-- ============================================================
IF OBJECT_ID('sp_Reviews_GetByProductPaged', 'P') IS NOT NULL
    DROP PROCEDURE sp_Reviews_GetByProductPaged;
GO

CREATE PROCEDURE sp_Reviews_GetByProductPaged
    @ProductId  INT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 10;
    IF @PageSize > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    ;WITH FilteredReviews AS
    (
        SELECT
            r.ReviewID,
            r.ProductID,
            r.UserID,
            u.FullName,
            u.AvatarURL,
            r.Rating,
            r.Comment,
            r.ImageURL,
            r.CreatedAt,
            COUNT(*) OVER() AS TotalRecords
        FROM Reviews r
        JOIN Users u ON r.UserID = u.UserID
        WHERE
            r.ProductID = @ProductId
            AND r.IsApproved = 1  -- Chỉ lấy reviews đã duyệt
    )
    SELECT
        ReviewID,
        ProductID,
        UserID,
        FullName,
        AvatarURL,
        Rating,
        Comment,
        ImageURL,
        CreatedAt,
        TotalRecords
    FROM FilteredReviews
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


-- ----------------------------------------------------------------------------
-- SP 091/107
-- Tên: sp_Notifications_GetByUserPaged
-- Nhóm chức năng: Notifications
-- Tác dụng: getbyuserpaged notifications thuộc nhóm notifications.
-- Dòng gốc: 4423-4428, 4430-4478
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Lấy danh sách Notifications của User với phân trang
-- ============================================================
IF OBJECT_ID('sp_Notifications_GetByUserPaged', 'P') IS NOT NULL
    DROP PROCEDURE sp_Notifications_GetByUserPaged;
GO

CREATE PROCEDURE sp_Notifications_GetByUserPaged
    @UserId     INT = NULL,
    @IsRead     BIT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination parameters
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 20;
    IF @PageSize > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    ;WITH FilteredNotifications AS
    (
        SELECT
            NotifID,
            UserID,
            Title,
            Message,
            Type,
            RelatedID,
            IsRead,
            CreatedAt,
            COUNT(*) OVER() AS TotalRecords
        FROM Notifications
        WHERE
            UserID = @UserId
            AND (@IsRead IS NULL OR IsRead = @IsRead)
    )
    SELECT
        NotifID,
        UserID,
        Title,
        Message,
        Type,
        RelatedID,
        IsRead,
        CreatedAt,
        TotalRecords
    FROM FilteredNotifications
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


-- ----------------------------------------------------------------------------
-- SP 092/107
-- Tên: sp_Auth_ForgotPassword
-- Nhóm chức năng: Auth
-- Tác dụng: forgotpassword auth thuộc nhóm auth.
-- Dòng gốc: 4522-4527, 4529-4576
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Forgot Password - Tạo token reset
-- ============================================================
IF OBJECT_ID('sp_Auth_ForgotPassword', 'P') IS NOT NULL
    DROP PROCEDURE sp_Auth_ForgotPassword;
GO

CREATE PROCEDURE sp_Auth_ForgotPassword
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID INT;
    DECLARE @FullName NVARCHAR(100);
    DECLARE @IsActive BIT;

    -- Kiểm tra email tồn tại và active
    SELECT 
        @UserID = UserID,
        @FullName = FullName,
        @IsActive = IsActive
    FROM Users
    WHERE Email = @Email AND LoginProvider = 'Local';

    -- Nếu không tìm thấy hoặc không active → trả về NULL (không tiết lộ email có tồn tại hay không)
    IF @UserID IS NULL OR @IsActive = 0
    BEGIN
        -- FIXED: CAST NULL thành đúng kiểu dữ liệu để Dapper map đúng
        SELECT 
            CAST(NULL AS NVARCHAR(100)) AS ResetToken,
            CAST(NULL AS INT) AS UserID,
            CAST(NULL AS NVARCHAR(100)) AS FullName,
            CAST(NULL AS NVARCHAR(100)) AS Email,
            CAST(NULL AS DATETIME) AS ExpiresAt;
        RETURN;
    END

    -- Tạo token ngẫu nhiên (GUID)
    DECLARE @ResetToken NVARCHAR(100) = CAST(NEWID() AS NVARCHAR(100));
    DECLARE @ExpiresAt DATETIME = DATEADD(MINUTE, 15, GETDATE());

    -- Vô hiệu hóa các token cũ chưa dùng của user này
    UPDATE PasswordResetTokens
    SET IsUsed = 1
    WHERE UserID = @UserID AND IsUsed = 0;

    -- Tạo token mới
    INSERT INTO PasswordResetTokens (UserID, ResetToken, ExpiresAt, IsUsed)
    VALUES (@UserID, @ResetToken, @ExpiresAt, 0);

    -- Trả về thông tin để gửi email
    SELECT 
        @ResetToken AS ResetToken,
        @UserID AS UserID,
        @FullName AS FullName,
        @Email AS Email,
        @ExpiresAt AS ExpiresAt;
END
GO


-- ----------------------------------------------------------------------------
-- SP 093/107
-- Tên: sp_Auth_ResetPassword
-- Nhóm chức năng: Auth
-- Tác dụng: resetpassword auth thuộc nhóm auth.
-- Dòng gốc: 4578-4583, 4585-4662
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Reset Password - Đặt lại mật khẩu bằng token
-- ============================================================
IF OBJECT_ID('sp_Auth_ResetPassword', 'P') IS NOT NULL
    DROP PROCEDURE sp_Auth_ResetPassword;
GO

CREATE PROCEDURE sp_Auth_ResetPassword
    @ResetToken    NVARCHAR(100),
    @NewPasswordHash NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UserID INT;
        DECLARE @TokenID INT;
        DECLARE @ExpiresAt DATETIME;
        DECLARE @IsUsed BIT;

        -- Kiểm tra token hợp lệ
        SELECT 
            @TokenID = TokenID,
            @UserID = UserID,
            @ExpiresAt = ExpiresAt,
            @IsUsed = IsUsed
        FROM PasswordResetTokens WITH (UPDLOCK, HOLDLOCK)
        WHERE ResetToken = @ResetToken;

        -- Token không tồn tại
        IF @TokenID IS NULL
        BEGIN
            ROLLBACK;
            RAISERROR(N'Token không hợp lệ', 16, 1);
            RETURN;
        END

        -- Token đã được sử dụng
        IF @IsUsed = 1
        BEGIN
            ROLLBACK;
            RAISERROR(N'Token đã được sử dụng', 16, 1);
            RETURN;
        END

        -- Token đã hết hạn
        IF @ExpiresAt < GETDATE()
        BEGIN
            ROLLBACK;
            RAISERROR(N'Token đã hết hạn', 16, 1);
            RETURN;
        END

        -- Cập nhật mật khẩu mới
        UPDATE Users
        SET PasswordHash = @NewPasswordHash,
            UpdatedAt = GETDATE()
        WHERE UserID = @UserID;

        -- Đánh dấu token đã sử dụng
        UPDATE PasswordResetTokens
        SET IsUsed = 1
        WHERE TokenID = @TokenID;

        -- Vô hiệu hóa tất cả token khác của user này
        UPDATE PasswordResetTokens
        SET IsUsed = 1
        WHERE UserID = @UserID AND TokenID != @TokenID AND IsUsed = 0;

        COMMIT TRANSACTION;

        -- Trả về UserID để xác nhận thành công
        SELECT @UserID AS UpdatedUserId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END
GO


-- ----------------------------------------------------------------------------
-- SP 094/107
-- Tên: sp_Auth_VerifyResetToken
-- Nhóm chức năng: Auth
-- Tác dụng: verifyresettoken auth thuộc nhóm auth.
-- Dòng gốc: 4664-4669, 4671-4693
-- ----------------------------------------------------------------------------

-- ============================================================
-- SP: Verify Reset Token - Kiểm tra token có hợp lệ không
-- ============================================================
IF OBJECT_ID('sp_Auth_VerifyResetToken', 'P') IS NOT NULL
    DROP PROCEDURE sp_Auth_VerifyResetToken;
GO

CREATE PROCEDURE sp_Auth_VerifyResetToken
    @ResetToken NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.TokenID,
        t.UserID,
        u.Email,
        u.FullName,
        t.ExpiresAt,
        t.IsUsed,
        -- FIXED: CAST thành BIT để Dapper map thành bool
        CAST(
            CASE 
                WHEN t.IsUsed = 1 THEN 0
                WHEN t.ExpiresAt < GETDATE() THEN 0
                ELSE 1
            END 
        AS BIT) AS IsValid
    FROM PasswordResetTokens t
    JOIN Users u ON t.UserID = u.UserID
    WHERE t.ResetToken = @ResetToken;
END
GO


-- ----------------------------------------------------------------------------
-- SP 095/107
-- Tên: sp_Auth_CleanupExpiredPasswordTokens
-- Nhóm chức năng: Auth
-- Tác dụng: cleanupexpiredpasswordtokens auth thuộc nhóm auth.
-- Dòng gốc: 4703-4704, 4706-4718
-- ----------------------------------------------------------------------------
IF OBJECT_ID('sp_Auth_CleanupExpiredPasswordTokens', 'P') IS NOT NULL
    DROP PROCEDURE sp_Auth_CleanupExpiredPasswordTokens;
GO

CREATE PROCEDURE sp_Auth_CleanupExpiredPasswordTokens
AS
BEGIN
    SET NOCOUNT ON;

    -- Xóa token reset mật khẩu hết hạn hoặc đã dùng > 7 ngày
    DELETE FROM PasswordResetTokens
    WHERE (ExpiresAt < DATEADD(DAY, -7, GETDATE()))
       OR (IsUsed = 1 AND CreatedAt < DATEADD(DAY, -7, GETDATE()));

    SELECT @@ROWCOUNT AS DeletedCount;
END
GO


-- ----------------------------------------------------------------------------
-- SP 096/107
-- Tên: dbo.sp_Auth_CreateRefreshToken
-- Nhóm chức năng: Auth
-- Tác dụng: Tạo Refresh Token khi Login
-- Dòng gốc: 4763-4817
-- ----------------------------------------------------------------------------

-----------------------------------------------------------
-- SP 1: Tạo Refresh Token khi Login
-----------------------------------------------------------

CREATE PROCEDURE dbo.sp_Auth_CreateRefreshToken
    @UserID INT,
    @RefreshToken NVARCHAR(500),
    @ExpiresAt DATETIME,
    @DeviceInfo NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------
    -- Kiểm tra người dùng có tồn tại và đang hoạt động không
    -------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.Users 
        WHERE UserID = @UserID 
          AND IsActive = 1
    )
    BEGIN
        RAISERROR(N'Người dùng không tồn tại hoặc bị vô hiệu hóa!', 16, 1);
        RETURN;
    END

    -------------------------------------------------------
    -- Thêm refresh token mới
    -------------------------------------------------------
    INSERT INTO dbo.RefreshTokens
    (
        UserID,
        RefreshToken,
        ExpiresAt,
        CreatedAt,
        IsRevoked,
        DeviceInfo
    )
    VALUES
    (
        @UserID,
        @RefreshToken,
        @ExpiresAt,
        GETDATE(),
        0,
        @DeviceInfo
    );

    -------------------------------------------------------
    -- Trả về TokenID vừa tạo
    -------------------------------------------------------
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS TokenID;
END
GO


-- ----------------------------------------------------------------------------
-- SP 097/107
-- Tên: sp_Auth_VerifyRefreshToken
-- Nhóm chức năng: Auth
-- Tác dụng: Verify Refresh Token
-- Dòng gốc: 4819-4852
-- ----------------------------------------------------------------------------


-----------------------------------------------------------
-- SP 2: Verify Refresh Token
-----------------------------------------------------------

CREATE PROCEDURE sp_Auth_VerifyRefreshToken
    @RefreshToken NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        rt.TokenID,
        rt.UserID,
        rt.RefreshToken,
        rt.ExpiresAt,
        rt.IsRevoked,
        rt.RevokedAt,
        rt.ReplacedBy,
        u.FullName,
        u.Email,
        u.Role,
        u.IsActive,
        CASE 
            WHEN rt.IsRevoked = 1 THEN 0
            WHEN rt.ExpiresAt < GETDATE() THEN 0
            WHEN u.IsActive = 0 THEN 0
            ELSE 1
        END AS IsValid
    FROM RefreshTokens rt
    JOIN Users u ON rt.UserID = u.UserID
    WHERE rt.RefreshToken = @RefreshToken;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 098/107
-- Tên: sp_Auth_RevokeRefreshToken
-- Nhóm chức năng: Auth
-- Tác dụng: Revoke Refresh Token (Thu hồi token cũ)
-- Dòng gốc: 4854-4873
-- ----------------------------------------------------------------------------

-----------------------------------------------------------
-- SP 3: Revoke Refresh Token (Thu hồi token cũ)
-----------------------------------------------------------

CREATE PROCEDURE sp_Auth_RevokeRefreshToken
    @RefreshToken NVARCHAR(500),
    @ReplacedBy   NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE RefreshTokens
    SET IsRevoked = 1,
        RevokedAt = GETDATE(),
        ReplacedBy = @ReplacedBy
    WHERE RefreshToken = @RefreshToken;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 099/107
-- Tên: sp_Auth_RevokeAllUserTokens
-- Nhóm chức năng: Auth
-- Tác dụng: Revoke All User Tokens (Logout khỏi tất cả thiết bị)
-- Dòng gốc: 4875-4893
-- ----------------------------------------------------------------------------

-----------------------------------------------------------
-- SP 4: Revoke All User Tokens (Logout khỏi tất cả thiết bị)
-----------------------------------------------------------

CREATE PROCEDURE sp_Auth_RevokeAllUserTokens
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE RefreshTokens
    SET IsRevoked = 1,
        RevokedAt = GETDATE()
    WHERE UserID = @UserID
      AND IsRevoked = 0;
    
    SELECT @@ROWCOUNT AS RevokedCount;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 100/107
-- Tên: sp_Auth_CleanupExpiredRefreshTokens
-- Nhóm chức năng: Auth
-- Tác dụng: cleanupexpiredrefreshtokens auth thuộc nhóm auth.
-- Dòng gốc: 4895-4901, 4903-4914
-- ----------------------------------------------------------------------------

-----------------------------------------------------------
-- SP 5: Cleanup Expired Refresh Tokens (Dọn dẹp Refresh Token hết hạn)
-- [ĐÃ ĐỔI TÊN thành sp_Auth_CleanupExpiredRefreshTokens để tránh trùng với PasswordResetTokens cleanup]
-----------------------------------------------------------
IF OBJECT_ID('sp_Auth_CleanupExpiredRefreshTokens', 'P') IS NOT NULL
    DROP PROCEDURE sp_Auth_CleanupExpiredRefreshTokens;
GO

CREATE PROCEDURE sp_Auth_CleanupExpiredRefreshTokens
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xóa Refresh Token đã hết hạn > 30 ngày
    DELETE FROM RefreshTokens
    WHERE ExpiresAt < DATEADD(DAY, -30, GETDATE());
    
    SELECT @@ROWCOUNT AS DeletedCount;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 101/107
-- Tên: sp_Auth_GetUserActiveTokens
-- Nhóm chức năng: Auth
-- Tác dụng: Get User Active Tokens (Xem các thiết bị đang đăng nhập)
-- Dòng gốc: 4916-4939
-- ----------------------------------------------------------------------------

-----------------------------------------------------------
-- SP 6: Get User Active Tokens (Xem các thiết bị đang đăng nhập)
-----------------------------------------------------------

CREATE PROCEDURE sp_Auth_GetUserActiveTokens
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        TokenID,
        RefreshToken,
        CreatedAt,
        ExpiresAt,
        DeviceInfo,
        DATEDIFF(DAY, GETDATE(), ExpiresAt) AS DaysUntilExpiry
    FROM RefreshTokens
    WHERE UserID = @UserID
      AND IsRevoked = 0
      AND ExpiresAt > GETDATE()
    ORDER BY CreatedAt DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 102/107
-- Tên: dbo.sp_CreateVNPayTransaction
-- Nhóm chức năng: Createvnpaytransaction
-- Tác dụng: createvnpaytransaction createvnpaytransaction thuộc nhóm createvnpaytransaction.
-- Dòng gốc: 5131-5266
-- ----------------------------------------------------------------------------

/* -------------------------------------------------------
   5. STORED PROCEDURES
------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.sp_CreateVNPayTransaction
    @OrderID             INT,
    @UserID              INT = NULL,
    @vnp_TxnRef          NVARCHAR(100),
    @RequestedBankCode   NVARCHAR(50) = NULL,
    @vnp_Amount          BIGINT = NULL,
    @vnp_OrderInfo       NVARCHAR(500) = NULL,
    @vnp_IpAddr          NVARCHAR(50),
    @RequestUrl          NVARCHAR(MAX),
    @RequestData         NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FinalAmount DECIMAL(18,2);
    DECLARE @PaymentStatus NVARCHAR(50);
    DECLARE @OrderStatus NVARCHAR(50);
    DECLARE @OrderUserID INT;
    DECLARE @ExpectedAmount BIGINT;
    DECLARE @ResolvedOrderInfo NVARCHAR(500);

    BEGIN TRAN;
    BEGIN TRY
        SELECT
            @OrderUserID = UserID,
            @FinalAmount = FinalAmount,
            @PaymentStatus = PaymentStatus,
            @OrderStatus = Status
        FROM dbo.Orders WITH (UPDLOCK, HOLDLOCK)
        WHERE OrderID = @OrderID;

        IF @OrderUserID IS NULL
        BEGIN
            RAISERROR(N'Don hang khong ton tai!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        IF @UserID IS NOT NULL AND @OrderUserID <> @UserID
        BEGIN
            RAISERROR(N'Ban khong co quyen thanh toan don hang nay!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        IF @PaymentStatus = N'Đã thanh toán'
        BEGIN
            RAISERROR(N'Don hang nay da duoc thanh toan!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        IF @OrderStatus IN (N'Đã hủy', N'Hoàn tất')
        BEGIN
            RAISERROR(N'Khong the tao giao dich VNPay cho don hang da huy hoac da hoan tat!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        IF EXISTS (
            SELECT 1
            FROM dbo.VNPayTransactions
            WHERE OrderID = @OrderID
              AND Status IN (N'Pending', N'Success')
        )
        BEGIN
            RAISERROR(N'Don hang da co giao dich VNPay Pending/Success!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        SET @ExpectedAmount = CAST(ROUND(@FinalAmount * 100, 0) AS BIGINT);
        SET @ResolvedOrderInfo = ISNULL(@vnp_OrderInfo, N'Thanh toán đơn hàng #' + CAST(@OrderID AS NVARCHAR(20)));

        IF @vnp_Amount IS NOT NULL AND @vnp_Amount <> @ExpectedAmount
        BEGIN
            RAISERROR(N'So tien giao dich khong khop voi gia tri don hang!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        INSERT INTO dbo.VNPayTransactions
        (
            OrderID,
            vnp_TxnRef,
            vnp_Amount,
            vnp_OrderInfo,
            vnp_OrderType,
            RequestedBankCode,
            vnp_IpAddr,
            RequestUrl,
            RequestData,
            Status
        )
        VALUES
        (
            @OrderID,
            @vnp_TxnRef,
            @ExpectedAmount,
            @ResolvedOrderInfo,
            N'other',
            @RequestedBankCode,
            @vnp_IpAddr,
            @RequestUrl,
            @RequestData,
            N'Pending'
        );

        UPDATE dbo.Orders
        SET PaymentMethod = N'VNPay',
            UpdatedAt = GETDATE()
        WHERE OrderID = @OrderID;

        COMMIT;

        SELECT
            TransactionID,
            OrderID,
            vnp_TxnRef,
            vnp_Amount,
            RequestUrl,
            Status
        FROM dbo.VNPayTransactions
        WHERE vnp_TxnRef = @vnp_TxnRef;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END;
GO


-- ----------------------------------------------------------------------------
-- SP 103/107
-- Tên: dbo.sp_UpdateVNPayTransaction
-- Nhóm chức năng: Updatevnpaytransaction
-- Tác dụng: updatevnpaytransaction updatevnpaytransaction thuộc nhóm updatevnpaytransaction.
-- Dòng gốc: 5268-5494
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.sp_UpdateVNPayTransaction
    @vnp_TxnRef             NVARCHAR(100),
    @vnp_TransactionNo      NVARCHAR(100) = NULL,
    @vnp_BankCode           NVARCHAR(50) = NULL,
    @vnp_BankTranNo         NVARCHAR(100) = NULL,
    @vnp_CardType           NVARCHAR(50) = NULL,
    @vnp_PayDate            NVARCHAR(14) = NULL,
    @vnp_ResponseCode       NVARCHAR(10) = NULL,
    @vnp_TransactionStatus  NVARCHAR(10) = NULL,
    @vnp_SecureHash         NVARCHAR(500) = NULL,
    @ResponseData           NVARCHAR(MAX) = NULL,
    @Status                 NVARCHAR(50) = NULL,
    @IsValidSignature       BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TransactionID INT;
    DECLARE @OrderID INT;
    DECLARE @CurrentTxnStatus NVARCHAR(50);
    DECLARE @CurrentOrderStatus NVARCHAR(50);
    DECLARE @CurrentPaymentStatus NVARCHAR(50);
    DECLARE @CurrentIsStockReverted BIT;
    DECLARE @UserID INT;
    DECLARE @ResolvedStatus NVARCHAR(50);

    BEGIN TRAN;
    BEGIN TRY
        SELECT
            @TransactionID = t.TransactionID,
            @OrderID = t.OrderID,
            @CurrentTxnStatus = t.Status,
            @CurrentIsStockReverted = t.IsStockReverted,
            @UserID = o.UserID,
            @CurrentOrderStatus = o.Status,
            @CurrentPaymentStatus = o.PaymentStatus
        FROM dbo.VNPayTransactions t WITH (UPDLOCK, HOLDLOCK)
        JOIN dbo.Orders o WITH (UPDLOCK, HOLDLOCK) ON o.OrderID = t.OrderID
        WHERE t.vnp_TxnRef = @vnp_TxnRef;

        IF @TransactionID IS NULL
        BEGIN
            RAISERROR(N'Khong tim thay giao dich VNPay!', 16, 1);
            ROLLBACK;
            RETURN;
        END

        IF @IsValidSignature = 0
        BEGIN
            UPDATE dbo.VNPayTransactions
            SET ErrorMessage = N'Chu ky SecureHash khong hop le.',
                ResponseData = @ResponseData,
                CallbackReceivedAt = GETDATE(),
                vnp_SecureHash = @vnp_SecureHash
            WHERE TransactionID = @TransactionID;

            COMMIT;
            SELECT N'InvalidSignature' AS Result, @OrderID AS OrderID, @TransactionID AS TransactionID;
            RETURN;
        END

        IF @CurrentTxnStatus = N'Success' AND @CurrentPaymentStatus = N'Đã thanh toán'
        BEGIN
            UPDATE dbo.VNPayTransactions
            SET ResponseData = COALESCE(@ResponseData, ResponseData),
                CallbackReceivedAt = GETDATE(),
                VerifiedAt = GETDATE(),
                vnp_SecureHash = COALESCE(@vnp_SecureHash, vnp_SecureHash)
            WHERE TransactionID = @TransactionID;

            COMMIT;
            SELECT N'AlreadyProcessed' AS Result, @OrderID AS OrderID, @TransactionID AS TransactionID;
            RETURN;
        END

        SET @ResolvedStatus = CASE
            WHEN @Status IS NOT NULL THEN @Status
            WHEN @vnp_ResponseCode = '00' AND @vnp_TransactionStatus = '00' THEN N'Success'
            WHEN @vnp_ResponseCode = '24' THEN N'Cancelled'
            WHEN @vnp_ResponseCode = '11' THEN N'Expired'
            ELSE N'Failed'
        END;

        UPDATE dbo.VNPayTransactions
        SET vnp_TransactionNo = COALESCE(@vnp_TransactionNo, vnp_TransactionNo),
            vnp_BankCode = COALESCE(@vnp_BankCode, vnp_BankCode),
            vnp_BankTranNo = COALESCE(@vnp_BankTranNo, vnp_BankTranNo),
            vnp_CardType = COALESCE(@vnp_CardType, vnp_CardType),
            vnp_PayDate = COALESCE(@vnp_PayDate, vnp_PayDate),
            vnp_ResponseCode = COALESCE(@vnp_ResponseCode, vnp_ResponseCode),
            vnp_TransactionStatus = COALESCE(@vnp_TransactionStatus, vnp_TransactionStatus),
            vnp_SecureHash = COALESCE(@vnp_SecureHash, vnp_SecureHash),
            ResponseData = COALESCE(@ResponseData, ResponseData),
            Status = @ResolvedStatus,
            CallbackReceivedAt = GETDATE(),
            VerifiedAt = GETDATE()
        WHERE TransactionID = @TransactionID;

        IF @ResolvedStatus = N'Success'
        BEGIN
            UPDATE dbo.Orders
            SET PaymentMethod = N'VNPay',
                PaymentStatus = N'Đã thanh toán',
                UpdatedAt = GETDATE()
            WHERE OrderID = @OrderID
              AND PaymentStatus <> N'Đã thanh toán';

            UPDATE dbo.VNPayTransactions
            SET IsIpnProcessed = 1
            WHERE TransactionID = @TransactionID;

            IF NOT EXISTS (
                SELECT 1
                FROM dbo.Notifications
                WHERE UserID = @UserID
                  AND Type = 'Order'
                  AND RelatedID = @OrderID
                  AND Title = N'Thanh toán VNPay thành công'
            )
            BEGIN
                INSERT INTO dbo.Notifications (UserID, Title, Message, Type, RelatedID)
                VALUES
                (
                    @UserID,
                    N'Thanh toán VNPay thành công',
                    N'Đơn hàng #' + CAST(@OrderID AS NVARCHAR(20)) + N' đã được thanh toán thành công qua VNPay.',
                    'Order',
                    @OrderID
                );
            END
        END
        ELSE
        BEGIN
            IF @CurrentOrderStatus <> N'Đã hủy'
               AND @CurrentPaymentStatus <> N'Đã thanh toán'
               AND ISNULL(@CurrentIsStockReverted, 0) = 0
            BEGIN
                UPDATE p
                SET p.StockQuantity = p.StockQuantity + od.Quantity,
                    p.SoldCount = p.SoldCount - od.Quantity,
                    p.UpdatedAt = GETDATE()
                FROM dbo.Products p
                JOIN dbo.OrderDetails od ON od.ProductID = p.ProductID
                WHERE od.OrderID = @OrderID;

                INSERT INTO dbo.InventoryLog
                (
                    ProductID,
                    ChangeQuantity,
                    QuantityAfter,
                    LogType,
                    RelatedOrderID,
                    Note
                )
                SELECT
                    od.ProductID,
                    od.Quantity,
                    p.StockQuantity,
                    N'Hoàn trả',
                    @OrderID,
                    N'Hoàn kho do thanh toán VNPay thất bại/hủy cho đơn #' + CAST(@OrderID AS NVARCHAR(20))
                FROM dbo.OrderDetails od
                JOIN dbo.Products p ON p.ProductID = od.ProductID
                WHERE od.OrderID = @OrderID;

                UPDATE dbo.Orders
                SET Status = N'Đã hủy',
                    PaymentMethod = N'VNPay',
                    PaymentStatus = N'Chưa thanh toán',
                    AdminNote = ISNULL(AdminNote + N' | ', N'')
                                + N'VNPay '
                                + LOWER(@ResolvedStatus)
                                + N' - hệ thống tự hủy đơn.',
                    UpdatedAt = GETDATE()
                WHERE OrderID = @OrderID;

                UPDATE dbo.ProductWarranties
                SET Status = N'Vô hiệu'
                WHERE OrderDetailID IN (
                    SELECT DetailID
                    FROM dbo.OrderDetails
                    WHERE OrderID = @OrderID
                );

                UPDATE dbo.VNPayTransactions
                SET IsIpnProcessed = 1,
                    IsStockReverted = 1
                WHERE TransactionID = @TransactionID;

                IF NOT EXISTS (
                    SELECT 1
                    FROM dbo.Notifications
                    WHERE UserID = @UserID
                      AND Type = 'Order'
                      AND RelatedID = @OrderID
                      AND Title = N'Thanh toán VNPay không thành công'
                )
                BEGIN
                    INSERT INTO dbo.Notifications (UserID, Title, Message, Type, RelatedID)
                    VALUES
                    (
                        @UserID,
                        N'Thanh toán VNPay không thành công',
                        N'Đơn hàng #' + CAST(@OrderID AS NVARCHAR(20)) + N' đã bị hủy do giao dịch VNPay không thành công.',
                        'Order',
                        @OrderID
                    );
                END
            END
        END

        COMMIT;
        SELECT @ResolvedStatus AS Result, @OrderID AS OrderID, @TransactionID AS TransactionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        UPDATE dbo.VNPayTransactions
        SET ErrorMessage = ERROR_MESSAGE()
        WHERE vnp_TxnRef = @vnp_TxnRef;

        THROW;
    END CATCH
END;
GO


-- ----------------------------------------------------------------------------
-- SP 104/107
-- Tên: dbo.sp_GetVNPayTransactionByOrderID
-- Nhóm chức năng: Getvnpaytransactionbyorderid
-- Tác dụng: getvnpaytransactionbyorderid getvnpaytransactionbyorderid thuộc nhóm getvnpaytransactionbyorderid.
-- Dòng gốc: 5496-5531
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.sp_GetVNPayTransactionByOrderID
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TransactionID,
        t.OrderID,
        t.vnp_TxnRef,
        t.vnp_Amount,
        t.vnp_OrderInfo,
        t.RequestedBankCode,
        t.vnp_TransactionNo,
        t.vnp_BankCode,
        t.vnp_BankTranNo,
        t.vnp_CardType,
        t.vnp_PayDate,
        t.vnp_ResponseCode,
        t.vnp_TransactionStatus,
        t.Status,
        t.CreatedAt,
        t.UpdatedAt,
        t.CallbackReceivedAt,
        t.VerifiedAt,
        t.ErrorMessage,
        o.PaymentMethod,
        o.PaymentStatus,
        o.Status AS OrderStatus,
        o.FinalAmount
    FROM dbo.VNPayTransactions t
    JOIN dbo.Orders o ON o.OrderID = t.OrderID
    WHERE t.OrderID = @OrderID
    ORDER BY t.CreatedAt DESC;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 105/107
-- Tên: dbo.sp_GetVNPayTransactionByTxnRef
-- Nhóm chức năng: Getvnpaytransactionbytxnref
-- Tác dụng: getvnpaytransactionbytxnref getvnpaytransactionbytxnref thuộc nhóm getvnpaytransactionbytxnref.
-- Dòng gốc: 5533-5550
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.sp_GetVNPayTransactionByTxnRef
    @vnp_TxnRef NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.*,
        o.UserID,
        o.PaymentMethod,
        o.PaymentStatus,
        o.Status AS OrderStatus,
        o.FinalAmount
    FROM dbo.VNPayTransactions t
    JOIN dbo.Orders o ON o.OrderID = t.OrderID
    WHERE t.vnp_TxnRef = @vnp_TxnRef;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 106/107
-- Tên: dbo.sp_GetVNPayTransactionHistory
-- Nhóm chức năng: Getvnpaytransactionhistory
-- Tác dụng: getvnpaytransactionhistory getvnpaytransactionhistory thuộc nhóm getvnpaytransactionhistory.
-- Dòng gốc: 5552-5624
-- ----------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.sp_GetVNPayTransactionHistory
    @PageNumber INT = 1,
    @PageSize   INT = 20,
    @Status     NVARCHAR(50) = NULL,
    @FromDate   DATETIME = NULL,
    @ToDate     DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate pagination (nhất quán với các SP phân trang khác)
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize   < 1 SET @PageSize   = 20;
    IF @PageSize   > 100 SET @PageSize = 100;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    -- [ĐÃ FIX] Dùng COUNT(*) OVER() → trả 1 result set duy nhất (nhất quán với toàn hệ thống)
    ;WITH FilteredTxn AS
    (
        SELECT
            t.TransactionID,
            t.OrderID,
            t.vnp_TxnRef,
            t.vnp_Amount / 100.0        AS AmountVND,
            t.RequestedBankCode,
            t.vnp_TransactionNo,
            t.vnp_BankCode,
            t.vnp_ResponseCode,
            t.vnp_TransactionStatus,
            t.Status,
            t.CreatedAt,
            t.CallbackReceivedAt,
            o.FinalAmount,
            o.PaymentStatus,
            o.Status                    AS OrderStatus,
            o.UserID,
            u.FullName,
            u.Email,
            COUNT(*) OVER()             AS TotalRecords  -- ← gộp luôn vào 1 result set
        FROM dbo.VNPayTransactions t
        JOIN dbo.Orders o ON o.OrderID  = t.OrderID
        JOIN dbo.Users  u ON u.UserID   = o.UserID
        WHERE (@Status   IS NULL OR t.Status    = @Status)
          AND (@FromDate IS NULL OR t.CreatedAt >= @FromDate)
          AND (@ToDate   IS NULL OR t.CreatedAt <= @ToDate)
    )
    SELECT
        TransactionID,
        OrderID,
        vnp_TxnRef,
        AmountVND,
        RequestedBankCode,
        vnp_TransactionNo,
        vnp_BankCode,
        vnp_ResponseCode,
        vnp_TransactionStatus,
        Status,
        CreatedAt,
        CallbackReceivedAt,
        FinalAmount,
        PaymentStatus,
        OrderStatus,
        UserID,
        FullName,
        Email,
        TotalRecords
    FROM FilteredTxn
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 107/107
-- Tên: dbo.sp_CancelVNPayTransaction
-- Nhóm chức năng: Cancelvnpaytransaction
-- Tác dụng: cancelvnpaytransaction cancelvnpaytransaction thuộc nhóm cancelvnpaytransaction.
-- Dòng gốc: 5626-5643
-- ----------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE dbo.sp_CancelVNPayTransaction
    @vnp_TxnRef NVARCHAR(100),
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.sp_UpdateVNPayTransaction
        @vnp_TxnRef = @vnp_TxnRef,
        @vnp_ResponseCode = '24',
        @vnp_TransactionStatus = '02',
        @ResponseData = @Reason,
        @Status = N'Cancelled',
        @IsValidSignature = 1;
END;
GO


-- ----------------------------------------------------------------------------
-- SP 108/113
-- Tên: dbo.sp_InsertSePayTransaction
-- Nhóm chức năng: SePay
-- Tác dụng: Thêm giao dịch SePay mới
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_InsertSePayTransaction
    @OrderID INT,
    @UserID INT,
    @MerchantID NVARCHAR(50),
    @TransactionRef NVARCHAR(100),
    @Amount DECIMAL(15, 2),
    @Status NVARCHAR(50) = 'pending'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO dbo.SePayTransactions (OrderID, UserID, MerchantID, TransactionRef, Amount, Status)
        VALUES (@OrderID, @UserID, @MerchantID, @TransactionRef, @Amount, @Status);
        
        SELECT CAST(SCOPE_IDENTITY() AS INT) AS TransactionID;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- SP 109/113
-- Tên: dbo.sp_UpdateSePayTransactionStatus
-- Nhóm chức năng: SePay
-- Tác dụng: Cập nhật trạng thái giao dịch và đơn hàng
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_UpdateSePayTransactionStatus
    @TransactionRef NVARCHAR(100),
    @Status NVARCHAR(50),
    @ResponseData NVARCHAR(MAX) = NULL,
    @ErrorMessage NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE dbo.SePayTransactions
        SET 
            Status = @Status,
            UpdatedAt = GETUTCDATE(),
            ResponseData = ISNULL(@ResponseData, ResponseData),
            ErrorMessage = ISNULL(@ErrorMessage, ErrorMessage)
        WHERE TransactionRef = @TransactionRef;
        
        IF @Status = 'success' OR @Status = 'completed'
        BEGIN
            UPDATE dbo.Orders
            SET PaymentStatus = N'Đã thanh toán', Status = N'Chờ xác nhận'
            WHERE OrderID = (SELECT OrderID FROM dbo.SePayTransactions WHERE TransactionRef = @TransactionRef);
        END
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- ----------------------------------------------------------------------------
-- SP 110/113
-- Tên: dbo.sp_SePay_UpdatePaymentStatus
-- Nhóm chức năng: SePay
-- Tác dụng: Cập nhật trạng thái thanh toán đơn hàng (idempotent)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_SePay_UpdatePaymentStatus
    @OrderID INT,
    @PaymentStatus NVARCHAR(100) = N'Đã thanh toán',
    @NewStatus NVARCHAR(100) = N'Chờ xác nhận'
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Orders
    SET 
        PaymentStatus = @PaymentStatus,
        Status        = @NewStatus,
        UpdatedAt     = GETUTCDATE()
    WHERE OrderID = @OrderID
      AND PaymentStatus != N'Đã thanh toán';

    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

-- ----------------------------------------------------------------------------
-- SP 111/113
-- Tên: dbo.sp_SePay_GetPaymentStatus
-- Nhóm chức năng: SePay
-- Tác dụng: Lấy trạng thái thanh toán của đơn hàng
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_SePay_GetPaymentStatus
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        OrderID,
        PaymentStatus,
        Status,
        UpdatedAt
    FROM dbo.Orders
    WHERE OrderID = @OrderID;
END;
GO

-- ----------------------------------------------------------------------------
-- SP 112/113
-- Tên: dbo.sp_GetSePayTransaction
-- Nhóm chức năng: SePay
-- Tác dụng: Lấy thông tin giao dịch SePay theo TransactionRef
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetSePayTransaction
    @TransactionRef NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        TransactionID,
        OrderID,
        UserID,
        MerchantID,
        TransactionRef,
        Amount,
        Status,
        PaymentMethod,
        CreatedAt,
        UpdatedAt,
        ResponseData,
        ErrorMessage
    FROM dbo.SePayTransactions
    WHERE TransactionRef = @TransactionRef;
END;
GO

-- ----------------------------------------------------------------------------
-- SP 113/113
-- Tên: dbo.sp_GetSePayTransactionsByOrder
-- Nhóm chức năng: SePay
-- Tác dụng: Lấy danh sách giao dịch SePay của đơn hàng
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GetSePayTransactionsByOrder
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        TransactionID,
        OrderID,
        UserID,
        MerchantID,
        TransactionRef,
        Amount,
        Status,
        PaymentMethod,
        CreatedAt,
        UpdatedAt,
        ResponseData,
        ErrorMessage
    FROM dbo.SePayTransactions
    WHERE OrderID = @OrderID
    ORDER BY CreatedAt DESC;
END;
GO


-- ============================================================================
-- PHẦN 5: VIEW / PRINT / GHI CHÚ PHỤ TRỢ GIỮ NGUYÊN TỪ FILE GỐC
-- ============================================================================

-- [KIỂM TRA / THÔNG BÁO] Dòng gốc: 3568-3582


------------------------------------------------------------
-- 5. KIỂM TRA LẠI DANH SÁCH QUYỀN
------------------------------------------------------------
SELECT
    PermissionID,
    RoleCode,
    RoleName,
    Description,
    IsActive,
    CreatedAt,
    UpdatedAt
FROM dbo.RolePermissions
ORDER BY PermissionID;
GO

-- [KIỂM TRA / THÔNG BÁO] Dòng gốc: 4480-4486

-- ============================================================
-- HOÀN TẤT: Tất cả stored procedures đã được tạo/cập nhật
-- ============================================================
PRINT N'✓ Đã tạo/cập nhật tất cả stored procedures với pagination';
PRINT N'✓ Giới hạn PageSize tối đa: 100 items/page';
PRINT N'✓ Sử dụng COUNT(*) OVER() để lấy TotalRecords hiệu quả';
GO

-- [GHI CHÚ / HEADER CŨ] Dòng gốc: 4695-4701

-- ============================================================
-- SP: Cleanup Expired Password Reset Tokens - Xóa token reset mật khẩu hết hạn
-- [ĐÃ ĐỔI TÊN từ sp_Auth_CleanupExpiredTokens để tránh trùng với RefreshTokens cleanup]
-- ============================================================
IF OBJECT_ID('sp_Auth_CleanupExpiredTokens', 'P') IS NOT NULL
    DROP PROCEDURE sp_Auth_CleanupExpiredTokens;
GO

-- [KIỂM TRA / THÔNG BÁO] Dòng gốc: 4720-4732

-- ============================================================
-- HOÀN TẤT: Forgot Password / Reset Password
-- ============================================================
PRINT N'✓ Đã tạo bảng PasswordResetTokens';
PRINT N'✓ Đã tạo sp_Auth_ForgotPassword';
PRINT N'✓ Đã tạo sp_Auth_ResetPassword';
PRINT N'✓ Đã tạo sp_Auth_VerifyResetToken';
PRINT N'✓ Đã tạo sp_Auth_CleanupExpiredPasswordTokens';
PRINT N'';
PRINT N'📧 Tính năng Forgot Password đã sẵn sàng!';
PRINT N'⏱ Token hết hạn sau 15 phút';
PRINT N'🔒 Token chỉ dùng được 1 lần';
GO

-- [KIỂM TRA / THÔNG BÁO] Dòng gốc: 4979-4988

-----------------------------------------------------------
-- COMPLETION
-----------------------------------------------------------

PRINT '✅ Refresh Token feature đã được thêm thành công!';
PRINT '📊 Bảng: RefreshTokens';
PRINT '📝 Stored Procedures: 6';
PRINT '🔍 Indexes: 3';
PRINT '⚡ Triggers: 1';
GO

-- [VIEW / BỔ SUNG KHÁC] Dòng gốc: 5645-5673

/* -------------------------------------------------------
   6. OPTIONAL VIEW FOR ADMIN / REPORT
------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_VNPayTransactionSummary
AS
SELECT
    t.TransactionID,
    t.OrderID,
    t.vnp_TxnRef,
    t.vnp_Amount / 100.0 AS AmountVND,
    t.RequestedBankCode,
    t.vnp_BankCode,
    t.vnp_TransactionNo,
    t.vnp_ResponseCode,
    t.vnp_TransactionStatus,
    t.Status,
    t.CreatedAt,
    t.CallbackReceivedAt,
    DATEDIFF(SECOND, t.CreatedAt, t.CallbackReceivedAt) AS ProcessingSeconds,
    o.UserID,
    u.FullName,
    u.Email,
    o.FinalAmount,
    o.PaymentStatus,
    o.Status AS OrderStatus
FROM dbo.VNPayTransactions t
JOIN dbo.Orders o ON o.OrderID = t.OrderID
JOIN dbo.Users u ON u.UserID = o.UserID;
GO

-- [GHI CHÚ / HEADER CŨ] Dòng gốc: 5675-5730

/*
========================================================================
BACKEND API FLOW NEN IMPLEMENT
========================================================================
1. POST /api/vnpay/create-payment
   Input:
   - orderId
   - requestedBankCode (null | 'VNPAYQR')

   Server:
   - lay order theo user dang dang nhap
   - sinh vnp_TxnRef
   - tinh amount = FinalAmount * 100
   - build query VNPay:
       vnp_Version=2.1.0
       vnp_Command=pay
       vnp_TmnCode=...
       vnp_Amount=...
       vnp_CreateDate=...
       vnp_CurrCode=VND
       vnp_IpAddr=...
       vnp_Locale=vn
       vnp_OrderInfo=Thanh toán đơn hàng #...
       vnp_OrderType=other
       vnp_ReturnUrl=https://your-domain/api/vnpay/return
       vnp_TxnRef=...
       vnp_BankCode=VNPAYQR neu muon QR
   - ky hash
   - goi sp_CreateVNPayTransaction
   - tra paymentUrl

2. GET /api/vnpay/ipn
   - verify secure hash
   - goi sp_UpdateVNPayTransaction
   - return ma phan hoi dung format VNPay yeu cau

3. GET /api/vnpay/return
   - verify secure hash
   - co the goi sp_UpdateVNPayTransaction neu IPN chua den
   - redirect nguoi dung ve /paymentcomplete?orderId=...&status=...

4. GET /api/vnpay/transaction/{orderId}
   - goi sp_GetVNPayTransactionByOrderID

5. GET /api/admin/vnpay/transactions
   - goi sp_GetVNPayTransactionHistory

LUU Y PRODUCTION
- Khong dung localhost cho ReturnUrl/IPN khi go live.
- Bat HTTPS va domain public.
- ReturnUrl chi de hien thi; IPN moi la noi cap nhat chinh.
- Khong tru kho trong callback thanh cong vi kho da bi tru luc tao OrderDetails.
- Neu can QR de quet, uu tien VNPAYQR.
========================================================================
*/


-- ----------------------------------------------------------------------------
-- PHẦN BỔ SUNG: SEO ON-PAGE
-- ----------------------------------------------------------------------------
-- Thêm cột Slug vào bảng Products nếu chưa có
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Products') AND name = 'Slug')
BEGIN
    ALTER TABLE dbo.Products ADD Slug NVARCHAR(255) NULL;
END
GO

-- Hàm loại bỏ dấu tiếng Việt
CREATE OR ALTER FUNCTION dbo.fn_RemoveAccents (@str NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @accents NVARCHAR(150) = N'áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸÝĐ';
    DECLARE @noAccents NVARCHAR(150) = N'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    
    DECLARE @i INT = 1;
    WHILE @i <= LEN(@str)
    BEGIN
        DECLARE @c NVARCHAR(1) = SUBSTRING(@str, @i, 1);
        DECLARE @idx INT = CHARINDEX(@c, @accents COLLATE Latin1_General_CS_AS);
        IF @idx > 0
        BEGIN
            SET @str = STUFF(@str, @i, 1, SUBSTRING(@noAccents, @idx, 1));
        END
        SET @i = @i + 1;
    END
    RETURN @str;
END;
GO

-- Hàm tạo Slug từ tên sản phẩm
CREATE OR ALTER FUNCTION dbo.fn_GenerateSlug (@str NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    SET @str = LOWER(dbo.fn_RemoveAccents(@str));
    
    -- Thay thế ký tự đặc biệt bằng dấu cách
    DECLARE @i INT = 1;
    DECLARE @res NVARCHAR(MAX) = '';
    WHILE @i <= LEN(@str)
    BEGIN
        DECLARE @c NCHAR(1) = SUBSTRING(@str, @i, 1);
        IF (@c >= 'a' AND @c <= 'z') OR (@c >= '0' AND @c <= '9')
            SET @res = @res + @c;
        ELSE
            SET @res = @res + ' ';
        SET @i = @i + 1;
    END
    
    -- Xử lý khoảng trắng thừa và nối bằng dấu gạch ngang
    SET @res = LTRIM(RTRIM(@res));
    WHILE CHARINDEX('  ', @res) > 0
        SET @res = REPLACE(@res, '  ', ' ');
    SET @res = REPLACE(@res, ' ', '-');
    
    RETURN @res;
END;
GO

-- Stored Procedure lấy sản phẩm bằng Slug
CREATE OR ALTER PROCEDURE sp_Product_GetBySlug
    @Slug NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT;
    SELECT @ProductID = ProductID FROM dbo.Products WHERE Slug = @Slug;

    IF @ProductID IS NULL
    BEGIN
        SELECT TOP 0 
            ProductID, CategoryID, CategoryName, BrandID, BrandName,
            SKU, ProductName, Price, DiscountPrice, EffectivePrice,
            StockQuantity, SoldCount, Description, IsActive, WarrantyMonths,
            CreatedAt, UpdatedAt, AvgRating, ReviewCount
        FROM (
            SELECT 
                p.ProductID, p.CategoryID, c.CategoryName, p.BrandID, b.BrandName,
                p.SKU, p.ProductName, p.Price, p.DiscountPrice,
                p.Price AS EffectivePrice, p.StockQuantity, p.SoldCount, p.Description,
                p.IsActive, p.WarrantyMonths, p.CreatedAt, p.UpdatedAt,
                CAST(0 AS DECIMAL(3,2)) AS AvgRating, 0 AS ReviewCount
            FROM dbo.Products p
            LEFT JOIN dbo.Categories c ON p.CategoryID = c.CategoryID
            LEFT JOIN dbo.Brands b ON p.BrandID = b.BrandID
        ) t;
        
        SELECT TOP 0 ImageID, ProductID, ImageURL, AltText, SortOrder, IsDefault FROM dbo.ProductImages;
        SELECT TOP 0 AttrID, ProductID, AttributeName, AttributeValue, SortOrder FROM dbo.ProductAttributes;
        RETURN;
    END

    EXEC dbo.sp_Product_GetById @ProductID = @ProductID;
END;
GO

