namespace PC_Store.Models;

public sealed record WarrantyClaimInfo(
    int ClaimId,
    int WarrantyId,
    int UserId,
    string? FullName,
    string? Email,
    string WarrantyCode,
    int ProductId,
    string ProductName,
    string SKU,
    DateTime ClaimDate,
    string Description,
    string? ImageUrl,
    string Status,
    string? Resolution,
    DateTime? ResolvedAt,
    DateTime WarrantyStartDate,
    DateTime WarrantyEndDate);
