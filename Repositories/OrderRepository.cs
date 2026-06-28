using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class OrderRepository : IOrderRepository
{
    private readonly IDbRepository _db;

    public OrderRepository(IDbRepository db) => _db = db;

    public async Task<int?> PlaceOrderAsync(PlaceOrderRequest request)
    {
        var r = await _db.QuerySingleAsync<NewIdResult>("sp_Customer_PlaceOrder", new
        {
            request.UserId, request.ShippingAddress, request.PaymentMethod, request.VoucherCode
        });
        return r?.NewOrderId;
    }

    public async Task<PagedResult<OrderHistoryItem>> GetHistoryAsync(UserOrderQueryRequest request)
    {
        var normalized = request.Normalize();
        
        var items = await _db.QueryAsync<OrderHistoryItemWithTotal>("sp_Orders_GetUserHistoryPaged", new
        {
            normalized.UserId, normalized.Status, normalized.PageNumber, normalized.PageSize
        });

        var itemsList = items.ToList();
        var totalRecords = itemsList.FirstOrDefault()?.TotalRecords ?? 0;

        return new PagedResult<OrderHistoryItem>(
            items: itemsList.Select(x => new OrderHistoryItem(
                x.OrderId, x.OrderDate, x.TotalAmount, x.DiscountAmount,
                x.FinalAmount, x.Status, x.PaymentMethod, x.PaymentStatus, x.ItemCount
            )),
            totalRecords: totalRecords,
            pageNumber: normalized.PageNumber,
            pageSize: normalized.PageSize
        );
    }

    public async Task<(OrderDetailHeader? Header, IEnumerable<OrderDetailItem> Items)> GetDetailAsync(int orderId, int userId)
    {
        await using var multi = await _db.QueryMultipleAsync("sp_Customer_GetOrderDetail", new { OrderId = orderId, UserId = userId });
        var header = await multi.ReadFirstOrDefaultAsync<OrderDetailHeader>();
        var items = await multi.ReadAsync<OrderDetailItem>();
        return (header, items);
    }

    public Task CancelOrderAsync(OrderCancelRequest request)
        => _db.ExecuteAsync("sp_Customer_CancelOrder", new { request.OrderId, request.UserId });

    public async Task<PagedResult<AdminOrderListItem>> GetAdminOrdersAsync(AdminOrderQueryRequest request)
    {
        var normalized = request.Normalize();
        
        var items = await _db.QueryAsync<AdminOrderListItemWithTotal>("sp_Orders_GetAdminOrdersPaged", new
        {
            normalized.Status, normalized.UserId, normalized.Keyword,
            normalized.DateFrom, normalized.DateTo,
            normalized.PageNumber, normalized.PageSize
        });

        var itemsList = items.ToList();
        var totalRecords = itemsList.FirstOrDefault()?.TotalRecords ?? 0;

        return new PagedResult<AdminOrderListItem>(
            items: itemsList.Select(x => new AdminOrderListItem(
                x.OrderId, x.UserId, x.FullName, x.Email, x.OrderDate,
                x.TotalAmount, x.DiscountAmount, x.FinalAmount, x.VoucherCode,
                x.Status, x.PaymentMethod, x.PaymentStatus, x.ShippingAddress,
                x.AdminNote, x.UpdatedAt, x.ItemCount
            )),
            totalRecords: totalRecords,
            pageNumber: normalized.PageNumber,
            pageSize: normalized.PageSize
        );
    }

    public async Task<(AdminOrderHeader? Header, IEnumerable<AdminOrderDetailItem> Items)> GetAdminOrderDetailAsync(int orderId)
    {
        await using var multi = await _db.QueryMultipleAsync("sp_Admin_GetOrderDetail", new { OrderId = orderId });
        var header = await multi.ReadFirstOrDefaultAsync<AdminOrderHeader>();
        var items = await multi.ReadAsync<AdminOrderDetailItem>();
        return (header, items);
    }

    public Task UpdateOrderStatusAsync(UpdateOrderStatusRequest request)
        => _db.ExecuteAsync("sp_Admin_UpdateOrderStatus", new
        {
            request.OrderId, request.NewStatus, request.AdminNote
        });

    public Task<IEnumerable<AdminOrderDetailListItem>> GetAdminOrderDetailsAsync(AdminOrderDetailQueryRequest request)
        => _db.QueryAsync<AdminOrderDetailListItem>("sp_Admin_GetOrderDetails", new
        {
            request.OrderId, request.ProductId, request.UserId, request.DateFrom, request.DateTo
        });

    private sealed record NewIdResult(int NewOrderId);

    // Helper records để nhận TotalRecords từ SQL
    private sealed record OrderHistoryItemWithTotal(
        int OrderId, DateTime OrderDate, decimal TotalAmount, decimal DiscountAmount,
        decimal FinalAmount, string Status, string PaymentMethod, string PaymentStatus,
        int ItemCount, int TotalRecords);

    private sealed record AdminOrderListItemWithTotal(
        int OrderId, int UserId, string? FullName, string? Email, DateTime OrderDate,
        decimal TotalAmount, decimal DiscountAmount, decimal FinalAmount, string? VoucherCode,
        string Status, string PaymentMethod, string PaymentStatus, string ShippingAddress,
        string? AdminNote, DateTime? UpdatedAt, int ItemCount, int TotalRecords);
}
