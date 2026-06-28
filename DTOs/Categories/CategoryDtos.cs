namespace PC_Store.DTOs.Categories;

public sealed record CategoryCreateRequest(
    string CategoryName,
    int? ParentId,
    string? IconUrl,
    int SortOrder,
    bool IsActive);

public sealed record CategoryUpdateRequest(
    int CategoryId,
    string CategoryName,
    int? ParentId,
    string? IconUrl,
    int SortOrder,
    bool IsActive);

public sealed record CategoryDeleteRequest(int CategoryId);

public sealed record CategoryItem(
    int CategoryId,
    string CategoryName,
    int? ParentId,
    string? ParentCategoryName,
    string? IconUrl,
    int SortOrder,
    bool IsActive,
    int ProductCount);
