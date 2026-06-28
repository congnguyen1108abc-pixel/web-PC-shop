using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class OrderService : IOrderService
{
    private readonly IOrderRepository _repo;
    public OrderService(IOrderRepository repo) => _repo = repo;

    public Task<int?> PlaceOrderAsync(PlaceOrderRequest request) => _repo.PlaceOrderAsync(request);
    public Task<PagedResult<OrderHistoryItem>> GetHistoryAsync(UserOrderQueryRequest request) => _repo.GetHistoryAsync(request);
    public Task<(OrderDetailHeader?, IEnumerable<OrderDetailItem>)> GetDetailAsync(int orderId, int userId) => _repo.GetDetailAsync(orderId, userId);
    public Task CancelOrderAsync(OrderCancelRequest request) => _repo.CancelOrderAsync(request);
    public Task<PagedResult<AdminOrderListItem>> GetAdminOrdersAsync(AdminOrderQueryRequest request) => _repo.GetAdminOrdersAsync(request);
    public Task<(AdminOrderHeader?, IEnumerable<AdminOrderDetailItem>)> GetAdminOrderDetailAsync(int orderId) => _repo.GetAdminOrderDetailAsync(orderId);
    public Task UpdateOrderStatusAsync(UpdateOrderStatusRequest request) => _repo.UpdateOrderStatusAsync(request);
    public Task<IEnumerable<AdminOrderDetailListItem>> GetAdminOrderDetailsAsync(AdminOrderDetailQueryRequest request) => _repo.GetAdminOrderDetailsAsync(request);
}
