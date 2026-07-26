namespace PC_Store.DTOs.Products;

public sealed record ProductQueryRequest(
    int? CategoryId,
    int? BrandId,
    string? Keyword,
    decimal? MinPrice,
    decimal? MaxPrice,
    bool OnlyActive = true,
    string SortBy = "Newest",
    int PageNumber = 1,
    int PageSize = 10)
{
    /// <summary>Validate và normalize pagination parameters</summary>
    public ProductQueryRequest Normalize()
    {
        var pageNum = PageNumber < 1 ? 1 : PageNumber;
        var pageSize = PageSize < 1 ? 10 : (PageSize > 100 ? 100 : PageSize);
        
        return this with { PageNumber = pageNum, PageSize = pageSize };
    }
};

public sealed record ProductCreateRequest(
    int CategoryId,
    int BrandId,
    string SKU,
    string ProductName,
    decimal Price,
    decimal DiscountPrice,
    decimal CostPrice,
    int StockQuantity,
    string? Description,
    int WarrantyMonths,
    bool IsActive);

public sealed record ProductUpdateRequest(
    int ProductId,
    int CategoryId,
    int BrandId,
    string SKU,
    string ProductName,
    decimal Price,
    decimal DiscountPrice,
    decimal CostPrice,
    int StockQuantity,
    string? Description,
    int WarrantyMonths,
    bool IsActive);

public sealed record ProductImageRequest(
    int ProductId,
    string ImageUrl,
    string? AltText,
    int SortOrder,
    bool IsDefault);

public sealed record ProductImageUpdateRequest(
    int ImageId,
    int ProductId,
    string ImageUrl,
    string? AltText,
    int SortOrder,
    bool IsDefault);

public sealed record ProductImageDeleteRequest(int ImageId, int ProductId);

public sealed record ProductAttributeRequest(
    int ProductId,
    string AttributeName,
    string AttributeValue,
    int SortOrder);

public sealed record ProductAttributeUpdateRequest(
    int AttrId,
    int ProductId,
    string AttributeName,
    string AttributeValue,
    int SortOrder);

public sealed record ProductAttributeDeleteRequest(int AttrId, int ProductId);

public sealed record ProductListItem(
    int ProductId,
    int CategoryId,
    string? CategoryName,
    int BrandId,
    string? BrandName,
    string SKU,
    string ProductName,
    decimal Price,
    decimal DiscountPrice,
    decimal CostPrice,
    decimal EffectivePrice,
    int StockQuantity,
    int SoldCount,
    string? Description,
    bool IsActive,
    int WarrantyMonths,
    string? Slug,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    string? DefaultImageUrl,
    decimal AvgRating,
    int ReviewCount);

public sealed record ProductDetailHeader
{
    public int ProductId { get; init; }
    public int CategoryId { get; init; }
    public string? CategoryName { get; init; }
    public int BrandId { get; init; }
    public string? BrandName { get; init; }
    public string SKU { get; init; } = null!;
    public string ProductName { get; init; } = null!;
    public decimal Price { get; init; }
    public decimal DiscountPrice { get; init; }
    public decimal CostPrice { get; init; }
    public decimal EffectivePrice { get; init; }
    public int StockQuantity { get; init; }
    public int SoldCount { get; init; }
    public string? Description { get; init; }
    public bool IsActive { get; init; }
    public int WarrantyMonths { get; init; }
    public string? Slug { get; init; }
    public DateTime CreatedAt { get; init; }
    public DateTime? UpdatedAt { get; init; }
    public decimal AvgRating { get; init; }
    public int ReviewCount { get; init; }
}

public sealed record ProductImageItem(
    int ImageId,
    int ProductId,
    string ImageUrl,
    string? AltText,
    int SortOrder,
    bool IsDefault);

public sealed record ProductAttributeItem(
    int AttrId,
    int ProductId,
    string AttributeName,
    string AttributeValue,
    int SortOrder);

public sealed record ProductReviewItem(
    int ReviewId,
    int ProductId,
    int UserId,
    string? FullName,
    string? AvatarUrl,
    int Rating,
    string? Comment,
    string? ImageUrl,
    bool IsApproved,
    DateTime CreatedAt);
