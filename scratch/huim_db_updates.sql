-- ----------------------------------------------------------------------------
-- 1. BỔ SUNG CỘT CỦA BẢNG PRODUCTS & THIẾT LẬP GIÁ NHẬP
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'ImportPrice')
BEGIN
    ALTER TABLE Products ADD ImportPrice DECIMAL(18,2) DEFAULT 0;
END
GO

-- Cập nhật giá nhập mẫu cho các sản phẩm hiện có (khoảng 75% giá bán)
UPDATE Products
SET ImportPrice = CASE
    WHEN ISNULL(DiscountPrice, 0) > 0 THEN ROUND(DiscountPrice * 0.75, 0)
    ELSE ROUND(Price * 0.75, 0)
END
WHERE ImportPrice IS NULL OR ImportPrice = 0;
GO

-- ----------------------------------------------------------------------------
-- 2. TẠO BẢNG CHỨA KẾT QUẢ KHAI THÁC DỮ LIỆU
-- ----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HighUtilityItemsets')
BEGIN
    CREATE TABLE HighUtilityItemsets (
        ItemsetID INT PRIMARY KEY IDENTITY(1,1),
        ProductIDs NVARCHAR(500) NOT NULL,
        TotalUtility DECIMAL(18,2) NOT NULL,
        SupportCount INT NOT NULL,
        MinedAt DATETIME DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductRecommendations')
BEGIN
    CREATE TABLE ProductRecommendations (
        SourceProductID INT FOREIGN KEY REFERENCES Products(ProductID) ON DELETE CASCADE,
        RecommendedProductID INT FOREIGN KEY REFERENCES Products(ProductID),
        UtilityScore DECIMAL(18,2) NOT NULL,
        PRIMARY KEY (SourceProductID, RecommendedProductID)
    );
END
GO

-- ----------------------------------------------------------------------------
-- 3. STORED PROCEDURE: LẤY GỢI Ý SẢN PHẨM TRÊN TRANG CHỦ (HOMEPAGE RECOMMENDATIONS)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_Recommendations_GetForHomepage
    @TopN INT = 8
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Khai báo bảng tạm chứa kết quả gợi ý
    DECLARE @Result TABLE (
        ProductID INT,
        ProductName NVARCHAR(255),
        Price DECIMAL(18,2),
        DiscountPrice DECIMAL(18,2),
        Slug NVARCHAR(255),
        DefaultImageUrl NVARCHAR(500),
        Score DECIMAL(18,2)
    );

    -- Bước A: Lấy các sản phẩm có tổng lợi nhuận mang lại cao nhất từ các đơn hàng hoàn tất
    INSERT INTO @Result
    SELECT TOP (@TopN)
        p.ProductID,
        p.ProductName,
        p.Price,
        p.DiscountPrice,
        p.Slug,
        (SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID ORDER BY IsDefault DESC, SortOrder ASC) AS DefaultImageUrl,
        SUM((od.UnitPrice - ISNULL(p.ImportPrice, 0)) * od.Quantity) AS CumulativeProfit
    FROM OrderDetails od
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    WHERE o.Status = N'Hoàn tất'
    GROUP BY p.ProductID, p.ProductName, p.Price, p.DiscountPrice, p.Slug
    ORDER BY SUM((od.UnitPrice - ISNULL(p.ImportPrice, 0)) * od.Quantity) DESC;

    -- Bước B: Nếu chưa đủ TopN, lấy thêm các sản phẩm có biên lợi nhuận cao nhất (Price - ImportPrice) làm fallback
    IF (SELECT COUNT(*) FROM @Result) < @TopN
    BEGIN
        INSERT INTO @Result
        SELECT TOP (@TopN - (SELECT COUNT(*) FROM @Result))
            p.ProductID,
            p.ProductName,
            p.Price,
            p.DiscountPrice,
            p.Slug,
            (SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID ORDER BY IsDefault DESC, SortOrder ASC) AS DefaultImageUrl,
            (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END - ISNULL(p.ImportPrice, 0)) AS Score
        FROM Products p
        WHERE p.IsActive = 1
          AND p.ProductID NOT IN (SELECT ProductID FROM @Result)
        ORDER BY (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END - ISNULL(p.ImportPrice, 0)) DESC;
    END

    -- Trả về danh sách
    SELECT * FROM @Result ORDER BY Score DESC;
END;
GO

-- ----------------------------------------------------------------------------
-- 4. STORED PROCEDURE: LẤY GỢI Ý MUA CÙNG TRÊN TRANG CHI TIẾT (PRODUCT DETAIL RECOMMENDATIONS)
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_Recommendations_GetForProduct
    @ProductID INT,
    @TopN INT = 4
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Result TABLE (
        ProductID INT,
        ProductName NVARCHAR(255),
        Price DECIMAL(18,2),
        DiscountPrice DECIMAL(18,2),
        Slug NVARCHAR(255),
        DefaultImageUrl NVARCHAR(500),
        Score DECIMAL(18,2)
    );

    -- Bước A: Lấy gợi ý được khai thác từ thuật toán HUIM trong bảng ProductRecommendations
    INSERT INTO @Result
    SELECT TOP (@TopN)
        p.ProductID,
        p.ProductName,
        p.Price,
        p.DiscountPrice,
        p.Slug,
        (SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID ORDER BY IsDefault DESC, SortOrder ASC) AS DefaultImageUrl,
        r.UtilityScore
    FROM ProductRecommendations r
    JOIN Products p ON r.RecommendedProductID = p.ProductID
    WHERE r.SourceProductID = @ProductID AND p.IsActive = 1
    ORDER BY r.UtilityScore DESC;

    -- Bước B: Nếu thiếu, lấy thêm sản phẩm cùng danh mục có lợi nhuận biên cao nhất làm fallback
    IF (SELECT COUNT(*) FROM @Result) < @TopN
    BEGIN
        DECLARE @CategoryID INT;
        SELECT @CategoryID = CategoryID FROM Products WHERE ProductID = @ProductID;

        INSERT INTO @Result
        SELECT TOP (@TopN - (SELECT COUNT(*) FROM @Result))
            p.ProductID,
            p.ProductName,
            p.Price,
            p.DiscountPrice,
            p.Slug,
            (SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID ORDER BY IsDefault DESC, SortOrder ASC) AS DefaultImageUrl,
            (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END - ISNULL(p.ImportPrice, 0)) AS Score
        FROM Products p
        WHERE p.CategoryID = @CategoryID
          AND p.ProductID <> @ProductID
          AND p.IsActive = 1
          AND p.ProductID NOT IN (SELECT ProductID FROM @Result)
        ORDER BY (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END - ISNULL(p.ImportPrice, 0)) DESC;
    END

    -- Bước C: Nếu vẫn thiếu, lấy thêm sản phẩm bất kỳ có lợi nhuận cao nhất
    IF (SELECT COUNT(*) FROM @Result) < @TopN
    BEGIN
        INSERT INTO @Result
        SELECT TOP (@TopN - (SELECT COUNT(*) FROM @Result))
            p.ProductID,
            p.ProductName,
            p.Price,
            p.DiscountPrice,
            p.Slug,
            (SELECT TOP 1 ImageURL FROM ProductImages WHERE ProductID = p.ProductID ORDER BY IsDefault DESC, SortOrder ASC) AS DefaultImageUrl,
            (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END - ISNULL(p.ImportPrice, 0)) AS Score
        FROM Products p
        WHERE p.ProductID <> @ProductID
          AND p.IsActive = 1
          AND p.ProductID NOT IN (SELECT ProductID FROM @Result)
        ORDER BY (CASE WHEN ISNULL(p.DiscountPrice, 0) > 0 THEN p.DiscountPrice ELSE p.Price END - ISNULL(p.ImportPrice, 0)) DESC;
    END

    SELECT * FROM @Result ORDER BY Score DESC;
END;
GO
