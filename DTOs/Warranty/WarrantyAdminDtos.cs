namespace PC_Store.DTOs.Warranty;

public sealed record WarrantyClaimQueryRequest(
    string? Status,
    int? UserId,
    string? WarrantyCode,
    DateTime? DateFrom,
    DateTime? DateTo);

public sealed record WarrantyClaimItem(
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
