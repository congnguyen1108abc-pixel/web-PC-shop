namespace PC_Store.DTOs.Warranty;

public sealed record WarrantyItem(
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
