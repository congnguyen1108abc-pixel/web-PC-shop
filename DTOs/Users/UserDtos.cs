namespace PC_Store.DTOs.Users;

public sealed record UserProfileItem(
    int UserId,
    string? FullName,
    string Email,
    string? PhoneNumber,
    string? AvatarUrl,
    string Role,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    decimal TotalSpent,
    string MembershipTier,
    int LoyaltyDiscountUses,
    string? BankName,
    string? BankAccountNumber,
    string? BankAccountName);

public sealed record UpdateProfileRequest(
    int UserId,
    string FullName,
    string? PhoneNumber,
    string? AvatarUrl);

public sealed record UpdateBankRequest(
    int UserId,
    string? BankName,
    string? BankAccountNumber,
    string? BankAccountName);

public sealed record AdminUserQueryRequest(
    string? Role,
    bool? IsActive,
    string? Keyword);

public sealed record AdminUserItem(
    int UserId,
    string? FullName,
    string Email,
    string? PhoneNumber,
    string? AvatarUrl,
    string Role,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    decimal TotalSpent,
    string MembershipTier,
    int LoyaltyDiscountUses);

public sealed record AdminUserDetailHeader(
    int UserId,
    string? FullName,
    string Email,
    string? PhoneNumber,
    string? AvatarUrl,
    string Role,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    decimal TotalSpent,
    string MembershipTier,
    int LoyaltyDiscountUses);

public sealed record AdminUserRoleItem(
    int UserRoleId,
    int UserId,
    string RoleCode,
    DateTime AssignedAt,
    int? AssignedBy);

public sealed record AdminUserAddressItem(
    int AddressId,
    int UserId,
    string ReceiverName,
    string PhoneNumber,
    string Province,
    string District,
    string Ward,
    string DetailAddress,
    bool IsDefault,
    DateTime CreatedAt);

public sealed record UpdateUserStatusRequest(int UserId, bool IsActive);
