using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Orders;
using PC_Store.Services.Interfaces;
using PC_Store.Hubs;

namespace PC_Store.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public sealed class ReturnRequestsController : ControllerBase
{
    private readonly IReturnService _returnService;
    private readonly INotificationPusher _pusher;

    public ReturnRequestsController(IReturnService returnService, INotificationPusher pusher)
    {
        _returnService = returnService;
        _pusher = pusher;
    }

    [HttpPost("customer/request")]
    public async Task<ActionResult> CreateRequest(CustomerCreateReturnRequest request)
    {
        var returnId = await _returnService.CreateReturnRequestAsync(request);
        if (returnId <= 0)
        {
            return BadRequest(new { message = "Gửi yêu cầu đổi trả thất bại" });
        }

        // Push real-time notification to user
        await _pusher.PushToUserAsync(
            userId: request.UserId,
            title: "Gửi yêu cầu đổi trả thành công",
            message: $"Yêu cầu đổi trả đơn hàng #{request.OrderId} đang được xử lý.",
            type: "Return",
            relatedId: returnId
        );

        // Push real-time notification to admin ("Ting Ting" trigger)
        await _pusher.PushToAdminAsync("NewReturnRequest", new
        {
            returnId = returnId,
            orderId = request.OrderId,
            message = $"Có yêu cầu đổi trả mới cho đơn hàng #{request.OrderId}!"
        });

        return Ok(new { message = "Gửi yêu cầu đổi trả thành công", returnId });
    }

    [HttpGet("admin/list")]
    public async Task<ActionResult> GetList([FromQuery] string? status = null, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
    {
        var result = await _returnService.GetReturnRequestsAsync(status, pageNumber, pageSize);
        return Ok(result);
    }

    [HttpPost("admin/approve/{returnId:int}")]
    public async Task<ActionResult> ApproveRequest(int returnId, [FromBody] string? adminNote = null)
    {
        var success = await _returnService.ApproveReturnRequestAsync(returnId, adminNote);
        if (!success)
        {
            return BadRequest(new { message = "Không tìm thấy yêu cầu hoặc duyệt thất bại" });
        }
        return Ok(new { message = "Đã duyệt yêu cầu và đăng ký đơn thu hồi GHN thành công" });
    }

    [HttpPost("admin/reject")]
    public async Task<ActionResult> RejectRequest(AdminProcessReturnRequest request)
    {
        await _returnService.RejectReturnRequestAsync(request.ReturnId, request.AdminNote);
        return Ok(new { message = "Đã từ chối yêu cầu đổi trả" });
    }

    [HttpPost("admin/receive/{returnId:int}")]
    public async Task<ActionResult> ReceiveReturnedGoods(int returnId, [FromBody] string? adminNote = null)
    {
        await _returnService.RestockReturnRequestAsync(returnId, adminNote);
        return Ok(new { message = "Đã nhận lại hàng và hoàn kho thành công" });
    }

    [HttpPost("admin/refund")]
    public async Task<ActionResult> CompleteRefund(AdminCompleteRefundRequest request)
    {
        await _returnService.CompleteRefundAsync(request);
        return Ok(new { message = "Hoàn tất hoàn tiền cho khách hàng" });
    }
}
