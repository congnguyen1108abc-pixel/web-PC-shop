namespace PC_Store.DTOs.Orders;

public sealed record OrderCancelRequest(int OrderId, int UserId);

public sealed record AdminOrderQueryRequest(
    string? Status,
    int? UserId,
    string? Keyword,
    DateTime? DateFrom,
    DateTime? DateTo,
    int PageNumber = 1,
    int PageSize = 10)
{
    /// <summary>Validate và normalize pagination parameters</summary>
    public AdminOrderQueryRequest Normalize()
    {
        var pageNum = PageNumber < 1 ? 1 : PageNumber;
        var pageSize = PageSize < 1 ? 10 : (PageSize > 100 ? 100 : PageSize);
        
        return this with { PageNumber = pageNum, PageSize = pageSize };
    }
};

public sealed record AdminOrderListItem(
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

public sealed record AdminOrderHeader(
    int OrderId,
    int UserId,
    string? FullName,
    string? Email,
    string? PhoneNumber,
    DateTime OrderDate,
    decimal TotalAmount,
    decimal DiscountAmount,
    decimal ShippingFee,
    decimal FinalAmount,
    string? VoucherCode,
    string Status,
    string PaymentMethod,
    string PaymentStatus,
    string ShippingAddress,
    string? AdminNote,
    DateTime? UpdatedAt,
    string? ShippingTrackingCode);

public sealed record AdminOrderDetailItem(
    int DetailId,
    int OrderId,
    int ProductId,
    string ProductName,
    string SKU,
    string? DefaultImageUrl,
    int Quantity,
    decimal UnitPrice,
    decimal LineTotal);
