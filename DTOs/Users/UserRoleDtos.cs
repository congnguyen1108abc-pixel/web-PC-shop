namespace PC_Store.DTOs.Users;

public sealed record UserRoleQueryRequest(
    int? UserId,
    string? RoleCode);

public sealed record UserRoleItem(
    int UserRoleId,
    int UserId,
    string? FullName,
    string? Email,
    string BaseRole,
    string RoleCode,
    DateTime AssignedAt,
    int? AssignedBy,
    string? AssignedByName);
