namespace PC_Store.Models;

public sealed record Voucher(
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
    DateTime CreatedAt);
