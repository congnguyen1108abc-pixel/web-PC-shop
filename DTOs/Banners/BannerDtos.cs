namespace PC_Store.DTOs.Banners;

public sealed record BannerItem(
    int BannerId,
    string Title,
    string ImageUrl,
    string? LinkUrl,
    int DisplayOrder,
    DateTime? StartDate,
    DateTime? EndDate,
    bool IsActive,
    DateTime CreatedAt);

public sealed record BannerDeleteRequest(int BannerId);
