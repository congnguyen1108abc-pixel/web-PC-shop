ALTER PROCEDURE [dbo].[sp_Product_GetAllPaged]
    @CategoryId INT = NULL,
    @BrandId INT = NULL,
    @Keyword NVARCHAR(100) = NULL,
    @MinPrice DECIMAL(18,2) = NULL,
    @MaxPrice DECIMAL(18,2) = NULL,
    @OnlyActive BIT = 1,
    @SortBy VARCHAR(50) = 'Newest',
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

    WITH FilteredProducts AS (
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
            -- EffectivePrice để sort và filter
            COALESCE(NULLIF(p.DiscountPrice, 0), p.Price) AS EffectivePrice,
            p.StockQuantity,
            p.SoldCount,
            p.Description,
            p.IsActive,
            p.WarrantyMonths,
            p.Slug,
            p.CreatedAt,
            p.UpdatedAt,
            -- Lấy ảnh mặc định
            (SELECT TOP 1 ImageUrl FROM ProductImages pi WHERE pi.ProductID = p.ProductID AND pi.IsDefault = 1) AS DefaultImageUrl,
            -- Lấy rating
            ISNULL((SELECT AVG(CAST(Rating AS DECIMAL(3,1))) FROM Reviews r WHERE r.ProductID = p.ProductID AND r.IsApproved = 1), 0) AS AvgRating,
            ISNULL((SELECT COUNT(*) FROM Reviews r WHERE r.ProductID = p.ProductID AND r.IsApproved = 1), 0) AS ReviewCount,
            -- Tính tổng số record
            COUNT(*) OVER() AS TotalRecords
        FROM Products p
        LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
        LEFT JOIN Brands b ON p.BrandID = b.BrandID
        WHERE 
            (@CategoryId IS NULL OR p.CategoryID = @CategoryId)
            AND (@BrandId IS NULL OR p.BrandID = @BrandId)
            AND (@Keyword IS NULL OR p.ProductName LIKE '%' + @Keyword + '%' OR p.SKU LIKE '%' + @Keyword + '%')
            AND (@MinPrice IS NULL OR COALESCE(NULLIF(p.DiscountPrice, 0), p.Price) >= @MinPrice)
            AND (@MaxPrice IS NULL OR COALESCE(NULLIF(p.DiscountPrice, 0), p.Price) <= @MaxPrice)
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
        Slug,
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
