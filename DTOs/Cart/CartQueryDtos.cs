namespace PC_Store.DTOs.Cart;

public sealed record CartItem(
    int CartId,
    int UserId,
    int ProductId,
    string SKU,
    string ProductName,
    decimal Price,
    decimal DiscountPrice,
    decimal UnitPrice,
    int Quantity,
    decimal LineTotal,
    int StockQuantity,
    bool IsActive,
    string? DefaultImageUrl,
    DateTime AddedAt);
