namespace PC_Store.Models;

public sealed record WarrantyInfo(
    int WarrantyId,
    int OrderDetailId,
    int OrderId,
    int ProductId,
    string ProductName,
    string SKU,
    string? DefaultImageUrl,
    DateTime StartDate,
    DateTime EndDate,
    string WarrantyCode,
    string Status,
    int Quantity,
    decimal UnitPrice);
