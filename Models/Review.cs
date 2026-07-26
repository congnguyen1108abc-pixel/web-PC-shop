namespace PC_Store.Models;

public sealed record Review(
    int ReviewId,
    int ProductId,
    string ProductName,
    string SKU,
    int UserId,
    string FullName,
    int Rating,
    string? Comment,
    string? ImageUrl,
    bool IsApproved,
    DateTime CreatedAt,
    string? Sentiment);
