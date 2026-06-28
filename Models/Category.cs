namespace PC_Store.Models;

public sealed record Category(
    int CategoryId,
    string CategoryName,
    int? ParentId,
    string? ParentCategoryName,
    string? IconUrl,
    int SortOrder,
    bool IsActive,
    int ProductCount);
