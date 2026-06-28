using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;
using PC_Store.Hubs;
using PC_Store.Services.Interfaces;

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
    public async Task<ActionResult> PlaceOrder(PlaceOrderRequest request)
    {
        var id = await _orders.PlaceOrderAsync(request);

        if (id is null)
            return BadRequest(new { message = "Đặt hàng thất bại" });

        // ── Push real-time sau khi đặt hàng thành công ───────────────────────────
        // Push cho khách hàng: thông báo đầu tiên ngay khi đặt xong
        await _pusher.PushToUserAsync(
            userId:    request.UserId,
            title:     $"Đầt hàng thành công #{id}",
            message:   "Don hàng của bạn đang chờ xác nhận. Cảm ơn bạn đã mua sắm!",
            type:      "Order",
            relatedId: (int)id);

        // Push cho Admin: có đơn hàng mới cần xử lý
        await _pusher.PushToAdminAsync("NewOrder", new
        {
            orderId  = id,
            userId   = request.UserId,
            message  = $"Có đơn hàng mới #{id} cần xác nhận!"
        });

        return Ok(new
        {
            message    = "Đặt hàng thành công",
            newOrderId = id
        });
    }

    [HttpGet("history/{userId:int}")]
    public async Task<ActionResult<PagedResult<OrderHistoryItem>>> GetHistory(int userId, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
    {
        var request = new UserOrderQueryRequest(userId, null, pageNumber, pageSize);
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
}