namespace PC_Store.DTOs.Orders;

public sealed record AdminOrderDetailQueryRequest(
    int? OrderId,
    int? ProductId,
    int? UserId,
    DateTime? DateFrom,
    DateTime? DateTo);

public sealed record AdminOrderDetailListItem(
    int DetailId,
    int OrderId,
    DateTime OrderDate,
    int UserId,
    string? FullName,
    string? Email,
    int ProductId,
    string ProductName,
    string SKU,
    string? DefaultImageUrl,
    int Quantity,
    decimal UnitPrice,
    decimal LineTotal,
    string Status,
    string PaymentMethod,
    string PaymentStatus);
