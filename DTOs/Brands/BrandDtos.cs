namespace PC_Store.DTOs.Brands;

public sealed record BrandCreateRequest(
    string BrandName,
    string? LogoUrl,
    string? Description,
    bool IsActive);

public sealed record BrandUpdateRequest(
    int BrandId,
    string BrandName,
    string? LogoUrl,
    string? Description,
    bool IsActive);

public sealed record BrandDeleteRequest(int BrandId);

public sealed record BrandItem(
    int BrandId,
    string BrandName,
    string? LogoUrl,
    string? Description,
    bool IsActive,
    DateTime CreatedAt,
    int ProductCount);
