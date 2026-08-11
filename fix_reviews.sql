ALTER TABLE Reviews ADD Sentiment NVARCHAR(50) NULL;
GO

CREATE OR ALTER PROCEDURE sp_Customer_AddReview
    @UserID    INT,
    @ProductID INT,
    @Rating    INT,
    @Comment   NVARCHAR(MAX),
    @ImageURL  NVARCHAR(500) = NULL,
    @Sentiment NVARCHAR(50) = NULL
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
    -- IsApproved = 1: Tự động đăng ngay, admin có thể ẩn đi nếu xấu
    INSERT INTO Reviews (ProductID, UserID, Rating, Comment, ImageURL, IsApproved, Sentiment)
    VALUES (@ProductID, @UserID, @Rating, @Comment, @ImageURL, 1, @Sentiment);
END;
GO

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
            r.Sentiment,
            COUNT(*) OVER() AS TotalRecords
        FROM Reviews r
        JOIN Users u ON r.UserID = u.UserID
        WHERE
            r.ProductID = @ProductId
            AND r.IsApproved = 1  -- Chỉ lấy reviews đang hiển thị (admin có thể ẩn review xấu)
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
        Sentiment,
        TotalRecords
    FROM FilteredReviews
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO

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
            r.Sentiment,
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
        Sentiment,
        TotalRecords
    FROM FilteredReviews
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
