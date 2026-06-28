namespace PC_Store.Models;

public sealed record AuthUser(
    int UserId,
    string? FullName,
    string Email,
    string Role,
    bool IsActive);
