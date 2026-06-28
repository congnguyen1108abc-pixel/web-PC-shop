namespace PC_Store.DTOs.Warranty;

public sealed record CreateWarrantyClaimRequest(
    string WarrantyCode,
    int UserId,
    string Description,
    string? ImageUrl);
