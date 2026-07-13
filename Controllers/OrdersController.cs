using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;
using PC_Store.DTOs.Admin;
using PC_Store.Hubs;
using PC_Store.Services.Interfaces;
using Microsoft.Extensions.DependencyInjection;

namespace PC_Store.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public sealed class OrdersController : ControllerBase
{
    private readonly IOrderService _orders;
    private readonly INotificationPusher _pusher;

    public OrdersController(IOrderService orders, INotificationPusher pusher)
    {
        _orders = orders;
        _pusher = pusher;
    }

    [EnableRateLimiting("order")]  // 5 req / phút / IP — chặn spam đặt hàng
    [HttpPost("place")]
    public async Task<ActionResult> PlaceOrder(
        PlaceOrderRequest request,
        [FromServices] IUserService userService,
        [FromServices] IGhnService ghn,
        [FromServices] IServiceScopeFactory scopeFactory)
    {
        var id = await _orders.PlaceOrderAsync(request);

        if (id is null)
            return BadRequest(new { message = "Đặt hàng thất bại" });

        var orderId = id.Value;

        // ── Push real-time sau khi đặt hàng thành công ───────────────────────────
        await _pusher.PushToUserAsync(
            userId:    request.UserId,
            title:     $"Đặt hàng thành công #{orderId}",
            message:   "Đơn hàng của bạn đang chờ xác nhận. Cảm ơn bạn đã mua sắm!",
            type:      "Order",
            relatedId: orderId);

        await _pusher.PushToAdminAsync("NewOrder", new
        {
            orderId  = orderId,
            userId   = request.UserId,
            message  = $"Có đơn hàng mới #{orderId} cần xác nhận!"
        });

        // ── Tạo Đơn Hàng Giao Hàng Nhanh Sandbox ──────────────────────────────────
        try
        {
            var user = await userService.GetProfileAsync(request.UserId);
            var (orderHeader, _) = await _orders.GetDetailAsync(orderId, request.UserId);

            if (user != null && orderHeader != null)
            {
                var receiverName = user.FullName ?? "Khách hàng PC Store";
                var receiverPhone = user.PhoneNumber ?? "0345469863"; // Fallback phone if missing
                var codAmount = request.PaymentMethod.Equals("COD", StringComparison.OrdinalIgnoreCase) 
                    ? orderHeader.FinalAmount 
                    : 0;

                // Tạo đơn hàng vận chuyển ảo trên GHN Sandbox
                var trackingCode = await ghn.CreateShippingOrderAsync(
                    orderId: orderId,
                    toName: receiverName,
                    toPhone: receiverPhone,
                    toAddress: request.ShippingAddress,
                    toWardCode: request.ToWardCode,
                    toDistrictId: request.ToDistrictId,
                    codAmount: codAmount,
                    weightGrams: 2000 // Giả định kiện hàng 2kg
                );

                if (!string.IsNullOrEmpty(trackingCode))
                {
                    // Lưu mã vận đơn vào database
                    await _orders.UpdateOrderTrackingCodeAsync(orderId, trackingCode);
                    Console.WriteLine($"[GHN Success]: Created shipping order #{orderId} with tracking code: {trackingCode}");
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GHN Integration Error]: {ex.Message}");
        }

        // ── Chạy ngầm Tiến Trình Giao Hàng Mô Phỏng (Simulation) ──────────────────────
        _ = Task.Run(async () =>
        {
            try
            {
                // Bước 1: Chờ 30 giây rồi tự động xác nhận đơn hàng
                await Task.Delay(30_000);
                using (var scope = scopeFactory.CreateScope())
                {
                    var ordersService = scope.ServiceProvider.GetRequiredService<IOrderService>();
                    await ordersService.UpdateOrderStatusAsync(new UpdateOrderStatusRequest(
                        OrderId: orderId,
                        UserId: request.UserId,
                        NewStatus: "Đã xác nhận",
                        AdminNote: "Hệ thống tự động xác nhận đơn hàng"
                    ));
                }
                
                await _pusher.PushToUserAsync(
                    userId:    request.UserId,
                    title:     $"Đơn hàng #{orderId} đã được xác nhận",
                    message:   "Đơn hàng của bạn đã được xác nhận và đang đóng gói sản phẩm.",
                    type:      "Order",
                    relatedId: orderId);

                // Bước 2: Chờ thêm 30 giây rồi chuyển sang đang giao hàng
                await Task.Delay(30_000);
                using (var scope = scopeFactory.CreateScope())
                {
                    var ordersService = scope.ServiceProvider.GetRequiredService<IOrderService>();
                    await ordersService.UpdateOrderStatusAsync(new UpdateOrderStatusRequest(
                        OrderId: orderId,
                        UserId: request.UserId,
                        NewStatus: "Đang giao",
                        AdminNote: "Đơn hàng đã bàn giao cho shipper GHN"
                    ));
                }
                
                await _pusher.PushToUserAsync(
                    userId:    request.UserId,
                    title:     $"Đơn hàng #{orderId} đang được giao",
                    message:   "Shipper đang giao hàng. Bạn có thể theo dõi hành trình trên bản đồ!",
                    type:      "Order",
                    relatedId: orderId);

                // Bước 3: Chờ thêm 30 giây rồi chuyển sang hoàn tất giao hàng
                await Task.Delay(30_000);
                using (var scope = scopeFactory.CreateScope())
                {
                    var ordersService = scope.ServiceProvider.GetRequiredService<IOrderService>();
                    await ordersService.UpdateOrderStatusAsync(new UpdateOrderStatusRequest(
                        OrderId: orderId,
                        UserId: request.UserId,
                        NewStatus: "Hoàn tất",
                        AdminNote: "Đơn hàng đã giao thành công và nhận đủ tiền"
                    ));
                }
                
                await _pusher.PushToUserAsync(
                    userId:    request.UserId,
                    title:     $"Đơn hàng #{orderId} đã giao thành công",
                    message:   "Đơn hàng đã được giao thành công. Cảm ơn bạn đã tin dùng sản phẩm của HYPER CORE!",
                    type:      "Order",
                    relatedId: orderId);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Shipping Simulation Exception]: {ex.Message}");
            }
        });

        return Ok(new
        {
            message    = "Đặt hàng thành công",
            newOrderId = orderId
        });
    }

    [HttpGet("history/{userId:int}")]
    public async Task<ActionResult<PagedResult<OrderHistoryItem>>> GetHistory(
        int userId, 
        [FromQuery] string? status = null, 
        [FromQuery] int pageNumber = 1, 
        [FromQuery] int pageSize = 10)
    {
        var request = new UserOrderQueryRequest(userId, status, pageNumber, pageSize);
        var result = await _orders.GetHistoryAsync(request);
        return Ok(result);
    }

    [HttpGet("detail/{orderId:int}/user/{userId:int}")]
    public async Task<ActionResult> GetDetail(int orderId, int userId)
    {
        var (header, items) = await _orders.GetDetailAsync(orderId, userId);

        if (header is null)
            return NotFound(new { message = "Không tìm thấy đơn hàng" });

        return Ok(new
        {
            header,
            items
        });
    }

    [HttpPut("cancel")]
    public async Task<ActionResult> CancelOrder(OrderCancelRequest request)
    {
        await _orders.CancelOrderAsync(request);

        return Ok(new
        {
            message = "Hủy đơn hàng thành công"
        });
    }

    // ── PROXY ENDPOINTS CHO GHN MASTER DATA & FEE ─────────────────────────────

    [HttpGet("shipping/provinces")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProvinces([FromServices] IGhnService ghn)
    {
        var json = await ghn.GetProvincesJsonAsync();
        return Content(json, "application/json");
    }

    [HttpGet("shipping/districts")]
    [AllowAnonymous]
    public async Task<IActionResult> GetDistricts([FromQuery] int provinceId, [FromServices] IGhnService ghn)
    {
        var json = await ghn.GetDistrictsJsonAsync(provinceId);
        return Content(json, "application/json");
    }

    [HttpGet("shipping/wards")]
    [AllowAnonymous]
    public async Task<IActionResult> GetWards([FromQuery] int districtId, [FromServices] IGhnService ghn)
    {
        var json = await ghn.GetWardsJsonAsync(districtId);
        return Content(json, "application/json");
    }

    [HttpPost("shipping/fee")]
    [AllowAnonymous]
    public async Task<IActionResult> CalculateFee([FromBody] CalculateFeeRequest request, [FromServices] IGhnService ghn)
    {
        var fee = await ghn.CalculateShippingFeeAsync(request.ToDistrictId, request.ToWardCode, request.WeightGrams);
        return Ok(new { fee });
    }
}

public sealed record CalculateFeeRequest(int ToDistrictId, string ToWardCode, int WeightGrams);