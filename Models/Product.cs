namespace PC_Store.Models;

public sealed record Product(
    int ProductId,
    int CategoryId,
    string? CategoryName,
    int BrandId,
    string? BrandName,
    string SKU,
    string ProductName,
    decimal Price,
    decimal DiscountPrice,
    decimal EffectivePrice,
    int StockQuantity,
    int SoldCount,
    string? Description,
    bool IsActive,
    int WarrantyMonths,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    string? DefaultImageUrl,
    decimal AvgRating,
    int ReviewCount);
