namespace PC_Store.Models;

public sealed record ProductImage(
    int ImageId,
    int ProductId,
    string ImageUrl,
    string? AltText,
    int SortOrder,
    bool IsDefault);
