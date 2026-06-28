namespace PC_Store.Models;

public sealed record Brand(
    int BrandId,
    string BrandName,
    string? LogoUrl,
    string? Description,
    bool IsActive,
    DateTime CreatedAt,
    int ProductCount);
