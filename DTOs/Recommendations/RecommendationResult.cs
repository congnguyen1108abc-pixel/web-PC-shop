namespace PC_Store.DTOs.Recommendations;

public sealed record RecommendationResult(
    int ProductId,
    string ProductName,
    string? Slug,
    string? ImageUrl,
    decimal Price,
    decimal DiscountPrice,
    decimal EffectivePrice,
    decimal AvgRating,
    int ReviewCount,
    int SoldCount,
    int StockQuantity,
    double Support,
    double Confidence,
    decimal Utility)
{
    public decimal DiscountPercent => Price > 0 && DiscountPrice > 0 && DiscountPrice < Price
        ? decimal.Round((1m - DiscountPrice / Price) * 100m, 0)
        : 0m;
}