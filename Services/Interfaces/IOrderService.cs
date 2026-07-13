using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;

namespace PC_Store.Services.Interfaces;

public interface IOrderService
{
    Task<int?> PlaceOrderAsync(PlaceOrderRequest request);
    Task<PagedResult<OrderHistoryItem>> GetHistoryAsync(UserOrderQueryRequest request);
    Task<(OrderDetailHeader? Header, IEnumerable<OrderDetailItem> Items)> GetDetailAsync(int orderId, int userId);
    Task CancelOrderAsync(OrderCancelRequest request);
    Task<PagedResult<AdminOrderListItem>> GetAdminOrdersAsync(AdminOrderQueryRequest request);
    Task<(AdminOrderHeader? Header, IEnumerable<AdminOrderDetailItem> Items)> GetAdminOrderDetailAsync(int orderId);
    Task UpdateOrderStatusAsync(UpdateOrderStatusRequest request);
    Task<IEnumerable<AdminOrderDetailListItem>> GetAdminOrderDetailsAsync(AdminOrderDetailQueryRequest request);
    Task UpdateOrderTrackingCodeAsync(int orderId, string trackingCode);
}
