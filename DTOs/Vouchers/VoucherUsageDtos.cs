namespace PC_Store.DTOs.Vouchers;

public sealed record VoucherUsageQueryRequest(
    int? UserId,
    string? VoucherCode,
    int? OrderId,
    DateTime? DateFrom,
    DateTime? DateTo);

public sealed record VoucherUsageItem(
    int UsageId,
    string VoucherCode,
    string? VoucherDescription,
    int UserId,
    string? FullName,
    string? Email,
    int? OrderId,
    decimal? FinalAmount,
    DateTime UsedAt);
