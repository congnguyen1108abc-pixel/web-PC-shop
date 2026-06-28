namespace PC_Store.DTOs.Orders;

/// <summary>
/// Query request cho lịch sử đơn hàng của user (Customer)
/// </summary>
public sealed record UserOrderQueryRequest(
    int UserId,
    string? Status = null,
    int PageNumber = 1,
    int PageSize = 10)
{
    /// <summary>Validate và normalize pagination parameters</summary>
    public UserOrderQueryRequest Normalize()
    {
        var pageNum = PageNumber < 1 ? 1 : PageNumber;
        var pageSize = PageSize < 1 ? 10 : (PageSize > 100 ? 100 : PageSize);
        
        return this with { PageNumber = pageNum, PageSize = pageSize };
    }
};

public sealed record PlaceOrderRequest(
    int UserId,
    string ShippingAddress,
    string PaymentMethod,
    string? VoucherCode);

public sealed record OrderHistoryItem(
    int OrderId,
    DateTime OrderDate,
    decimal TotalAmount,
    decimal DiscountAmount,
    decimal FinalAmount,
    string Status,
    string PaymentMethod,
    string PaymentStatus,
    int ItemCount);

public class OrderDetailHeader
{
    public int OrderId { get; set; }
    public int UserId { get; set; }
    public DateTime OrderDate { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal FinalAmount { get; set; }
    public string? VoucherCode { get; set; }
    public string Status { get; set; } = string.Empty;
    public string PaymentMethod { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty;
    public string ShippingAddress { get; set; } = string.Empty;
    public DateTime? UpdatedAt { get; set; }
}

public class OrderDetailItem
{
    public int DetailId { get; set; }
    public int OrderId { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string SKU { get; set; } = string.Empty;
    public string? DefaultImageUrl { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}
