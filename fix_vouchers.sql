ALTER TABLE Vouchers ADD StartDate DATETIME NULL;
GO

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
        CreatedAt,
        StartDate
    FROM Vouchers
    WHERE (@OnlyActive = 0 OR IsActive = 1)
    ORDER BY ExpiryDate ASC, VoucherCode ASC;
END;
GO

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
        v.StartDate,
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
      AND (v.StartDate IS NULL OR v.StartDate <= GETDATE())
      AND v.ExpiryDate >= GETDATE()
      AND v.UsageLimit > 0
      AND v.MinOrderValue <= @OrderValue
      AND ISNULL(vu.UsedCount, 0) < v.MaxPerUser
    ORDER BY v.ExpiryDate ASC, v.VoucherCode ASC;
END;
GO

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
    @IsActive       BIT = 1,
    @StartDate      DATETIME = NULL
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
        IsActive,
        StartDate
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
        @IsActive,
        ISNULL(@StartDate, GETDATE())
    );

    SELECT @VoucherCode AS NewVoucherCode;
END;
GO

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
    @IsActive       BIT = 1,
    @StartDate      DATETIME = NULL
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
        IsActive       = @IsActive,
        StartDate      = ISNULL(@StartDate, StartDate)
    WHERE VoucherCode = @VoucherCode;

    SELECT @VoucherCode AS UpdatedVoucherCode;
END;
GO
