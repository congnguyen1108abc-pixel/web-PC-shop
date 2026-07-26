namespace PC_Store.DTOs.Vouchers;

public sealed record VoucherQueryRequest(bool OnlyActive = false);

public sealed record VoucherAvailableRequest(int UserId, decimal OrderValue);

public sealed record VoucherCreateRequest(
    string VoucherCode,
    string? Description,
    decimal DiscountAmount,
    bool IsPercent,
    decimal? MaxDiscount,
    decimal MinOrderValue,
    DateTime ExpiryDate,
    int UsageLimit,
    int MaxPerUser,
    bool IsActive,
    DateTime? StartDate);

public sealed record VoucherUpdateRequest(
    string VoucherCode,
    string? Description,
    decimal DiscountAmount,
    bool IsPercent,
    decimal? MaxDiscount,
    decimal MinOrderValue,
    DateTime ExpiryDate,
    int UsageLimit,
    int MaxPerUser,
    bool IsActive,
    DateTime? StartDate);

public sealed record VoucherDeleteRequest(string VoucherCode);

public sealed record VoucherItem(
    string VoucherCode,
    string? Description,
    decimal DiscountAmount,
    bool IsPercent,
    decimal? MaxDiscount,
    decimal MinOrderValue,
    DateTime ExpiryDate,
    int UsageLimit,
    int MaxPerUser,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? StartDate);

public sealed record VoucherAvailableItem(
    string VoucherCode,
    string? Description,
    decimal DiscountAmount,
    bool IsPercent,
    decimal? MaxDiscount,
    decimal MinOrderValue,
    DateTime ExpiryDate,
    int UsageLimit,
    int MaxPerUser,
    int UsedCount,
    DateTime? StartDate);
