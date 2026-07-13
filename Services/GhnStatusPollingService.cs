using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;
using PC_Store.DTOs.Orders;
using PC_Store.DTOs.Admin;

namespace PC_Store.Services;

public sealed class GhnStatusPollingService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<GhnStatusPollingService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromSeconds(30); // Tần suất quét: 30 giây phục vụ test nhanh

    public GhnStatusPollingService(IServiceScopeFactory scopeFactory, ILogger<GhnStatusPollingService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("GHN Status Polling Service starting...");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await PollStatusesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred during GHN status polling.");
            }

            await Task.Delay(Interval, stoppingToken);
        }

        _logger.LogInformation("GHN Status Polling Service stopping...");
    }

    private async Task PollStatusesAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var orderRepo = scope.ServiceProvider.GetRequiredService<IOrderRepository>();
        var returnRepo = scope.ServiceProvider.GetRequiredService<IReturnRepository>();
        var orderService = scope.ServiceProvider.GetRequiredService<IOrderService>();
        var returnService = scope.ServiceProvider.GetRequiredService<IReturnService>();
        var ghn = scope.ServiceProvider.GetRequiredService<IGhnService>();

        // ── 1. ĐỒNG BỘ ĐƠN HÀNG CHIỀU ĐI (SHIPPING ORDERS) ──
        // Lấy danh sách đơn hàng Đang giao
        var adminOrdersResult = await orderRepo.GetAdminOrdersAsync(new AdminOrderQueryRequest(
            Status: "Đang giao",
            UserId: null,
            Keyword: null,
            DateFrom: null,
            DateTo: null,
            PageNumber: 1,
            PageSize: 100
        ));

        foreach (var order in adminOrdersResult.Items)
        {
            // Lấy thông tin mã vận đơn thực tế
            var detail = await orderRepo.GetDetailAsync(order.OrderId, order.UserId);
            var detailHeader = detail.Header;
            if (detailHeader == null || string.IsNullOrEmpty(detailHeader.ShippingTrackingCode)) continue;

            var ghnStatus = await ghn.GetOrderTrackingDetailAsync(detailHeader.ShippingTrackingCode);
            if (string.IsNullOrEmpty(ghnStatus)) continue;

            _logger.LogInformation($"[GHN Poller] Order #{order.OrderId} - GHN Status: {ghnStatus}");

            if (ghnStatus.Equals("delivered", StringComparison.OrdinalIgnoreCase))
            {
                // Giao hàng thành công -> Cập nhật thành Hoàn tất (tự động cập nhật PaymentStatus = Paid trong UpdateOrderStatusAsync)
                _logger.LogInformation($"[GHN Poller] Auto completing Order #{order.OrderId} (Delivered by GHN)");
                await orderService.UpdateOrderStatusAsync(new UpdateOrderStatusRequest(
                    OrderId: order.OrderId,
                    UserId: order.UserId,
                    NewStatus: "Hoàn tất",
                    AdminNote: "GHN xác nhận đã giao hàng thành công."
                ));
            }
            else if (ghnStatus.Equals("returning", StringComparison.OrdinalIgnoreCase))
            {
                // Đang chuyển hoàn
                _logger.LogWarning($"[GHN Poller] Order #{order.OrderId} is returning (Returning by GHN)");
                await orderService.UpdateOrderStatusAsync(new UpdateOrderStatusRequest(
                    OrderId: order.OrderId,
                    UserId: order.UserId,
                    NewStatus: "Đang chuyển hoàn",
                    AdminNote: "Đơn hàng giao thất bại, đang chuyển hoàn về kho."
                ));
            }
            else if (ghnStatus.Equals("returned", StringComparison.OrdinalIgnoreCase))
            {
                // Đã chuyển hoàn thành công -> Hủy đơn và hoàn trả tồn kho
                _logger.LogWarning($"[GHN Poller] Order #{order.OrderId} was returned (Returned by GHN). Restocking...");
                await orderService.UpdateOrderStatusAsync(new UpdateOrderStatusRequest(
                    OrderId: order.OrderId,
                    UserId: order.UserId,
                    NewStatus: "Đã hủy",
                    AdminNote: "Đơn hàng đã được chuyển hoàn về kho thành công."
                ));
            }
        }

        // ── 2. ĐỒNG BỘ ĐƠN HÀNG CHIỀU VỀ (RETURN REQUESTS) ──
        // Lấy danh sách yêu cầu đổi trả đang đi thu hồi hàng ('Picking')
        var returnRequestsResult = await returnRepo.GetReturnRequestsAsync("Picking", 1, 100);
        foreach (var req in returnRequestsResult.Items)
        {
            if (string.IsNullOrEmpty(req.ReturnTrackingCode)) continue;

            var ghnStatus = await ghn.GetOrderTrackingDetailAsync(req.ReturnTrackingCode);
            if (string.IsNullOrEmpty(ghnStatus)) continue;

            _logger.LogInformation($"[GHN Poller] Return Request #{req.ReturnId} - GHN Status: {ghnStatus}");

            if (ghnStatus.Equals("delivered", StringComparison.OrdinalIgnoreCase) || 
                ghnStatus.Equals("returned", StringComparison.OrdinalIgnoreCase))
            {
                // Shipper đã lấy hàng và trả về kho thành công -> Nhận hàng hoàn & cộng trả tồn kho
                _logger.LogInformation($"[GHN Poller] Auto receiving returned goods for Return Request #{req.ReturnId}");
                await returnService.RestockReturnRequestAsync(req.ReturnId, "Đã nhận lại sản phẩm hoàn trả thành công từ shipper GHN.");
            }
        }
    }
}
