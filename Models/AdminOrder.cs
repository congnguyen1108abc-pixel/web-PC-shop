namespace PC_Store.Models;

public sealed record AdminOrder(
    int OrderId,
    int UserId,
    string? FullName,
    string? Email,
    DateTime OrderDate,
    decimal TotalAmount,
    decimal DiscountAmount,
    decimal FinalAmount,
    string? VoucherCode,
    string Status,
    string PaymentMethod,
    string PaymentStatus,
    string ShippingAddress,
    string? AdminNote,
    DateTime? UpdatedAt,
    int ItemCount);
