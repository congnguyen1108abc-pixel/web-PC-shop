namespace PC_Store.Models;

public sealed record UserProfile(
    int UserId,
    string? FullName,
    string Email,
    string? PhoneNumber,
    string? AvatarUrl,
    string Role,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt);
