using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Banners;
using PC_Store.DTOs.Chat;
using PC_Store.DTOs.Notifications;
using PC_Store.DTOs.Orders;
using PC_Store.DTOs.Products;
using PC_Store.DTOs.Reviews;
using PC_Store.DTOs.Users;
using PC_Store.DTOs.Vouchers;
using PC_Store.DTOs.Warranty;
using PC_Store.Hubs;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/[controller]")]
public sealed class AdminController : ControllerBase
{
    private readonly IUserService _users;
    private readonly IProductService _products;
    private readonly IOrderService _orders;
    private readonly IWarrantyService _warranty;
    private readonly IBannerService _banners;
    private readonly IDashboardService _dashboard;
    private readonly IVoucherService _vouchers;
    private readonly IReviewService _reviews;
    private readonly IChatService _chat;
    private readonly INotificationService _notifications;
    private readonly INotificationPusher _pusher;
    private readonly IHighUtilityMiningService _mining;

    public AdminController(
        IUserService users,
        IProductService products,
        IOrderService orders,
        IWarrantyService warranty,
        IBannerService banners,
        IDashboardService dashboard,
        IVoucherService vouchers,
        IReviewService reviews,
        IChatService chat,
        INotificationService notifications,
        INotificationPusher pusher,
        IHighUtilityMiningService mining)
    {
        _users         = users;
        _products      = products;
        _orders        = orders;
        _warranty      = warranty;
        _banners       = banners;
        _dashboard     = dashboard;
        _vouchers      = vouchers;
        _reviews       = reviews;
        _chat          = chat;
        _notifications = notifications;
        _pusher        = pusher;
        _mining        = mining;
    }

    // ── Users ─────────────────────────────────────────────────────────────────

    [HttpPost("user-role")]
    public async Task<ActionResult> ManageUserRole(ManageUserRoleRequest request)
    {
        await _users.ManageUserRoleAsync(request);
        return Ok(new { message = "Cập nhật vai trò người dùng thành công" });
    }

    [HttpGet("users")]
    public async Task<ActionResult<IEnumerable<AdminUserItem>>> GetUsers(
        [FromQuery] AdminUserQueryRequest request)
    {
        var result = await _users.GetAdminUsersAsync(request);
        return Ok(result);
    }

    [HttpGet("users/{userId:int}")]
    public async Task<ActionResult> GetUserDetail(int userId)
    {
        var (header, roles, addresses) = await _users.GetAdminUserDetailAsync(userId);

        if (header is null)
            return NotFound(new { message = "Không tìm thấy người dùng" });

        return Ok(new
        {
            header,
            roles,
            addresses
        });
    }

    [HttpPut("users/status")]
    public async Task<ActionResult> UpdateUserStatus(UpdateUserStatusRequest request)
    {
        var id = await _users.UpdateUserStatusAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật trạng thái người dùng thất bại" });

        return Ok(new
        {
            message = "Cập nhật trạng thái người dùng thành công",
            updatedUserId = id
        });
    }

    [HttpGet("user-roles")]
    public async Task<ActionResult<IEnumerable<UserRoleItem>>> GetUserRoles(
        [FromQuery] UserRoleQueryRequest request)
    {
        var result = await _users.GetUserRolesAsync(request);
        return Ok(result);
    }

    // ── Products ──────────────────────────────────────────────────────────────

    [HttpPost("import-stock")]
    public async Task<ActionResult> ImportStock(ImportStockRequest request)
    {
        await _products.ImportStockAsync(request);
        return Ok(new { message = "Nhập kho thành công" });
    }

    [HttpGet("inventory-log")]
    public async Task<ActionResult<IEnumerable<InventoryLogItem>>> GetInventoryLog(
        [FromQuery] InventoryLogQueryRequest request)
    {
        var result = await _products.GetInventoryLogAsync(request);
        return Ok(result);
    }

    [HttpGet("low-stock")]
    public async Task<ActionResult<IEnumerable<LowStockItem>>> GetLowStock(
        [FromQuery] LowStockAlertRequest request)
    {
        var result = await _products.GetLowStockAsync(request);
        return Ok(result);
    }

    [HttpGet("top-selling")]
    public async Task<ActionResult<IEnumerable<TopSellingItem>>> GetTopSelling(
        [FromQuery] TopSellingRequest request)
    {
        var result = await _products.GetTopSellingAsync(request);
        return Ok(result);
    }

    // ── Orders ────────────────────────────────────────────────────────────────
    // Chỉ Admin được cập nhật trạng thái đơn hàng vì class này đã khóa [Authorize(Roles = "Admin")]

    [HttpPut("order-status")]
    public async Task<ActionResult> UpdateOrderStatus(UpdateOrderStatusRequest request)
    {
        await _orders.UpdateOrderStatusAsync(request);

        // ── Push real-time khi Admin đổi trạng thái đơn ────────────────────────────
        // Xác định thông báo theo trạng thái mới
        var (title, message) = request.NewStatus switch
        {
            "Đã xác nhận"  => ($"Đơn hàng #{request.OrderId} đã được xác nhận",
                                   "Chúng tôi đang chuẩn bị hàng cho bạn."),
            "Đang giao"     => ($"Đơn hàng #{request.OrderId} đang được giao",
                                   "Shipper đã nhận hàng và đang giao đến bạn."),
            "Hoàn tất"     => ($"Đơn hàng #{request.OrderId} đã giao thành công",
                                   "Cảm ơn bạn đã mua sắm! Hãy để lại đánh giá nhé."),
            "Đã hủy"       => ($"Đơn hàng #{request.OrderId} đã bị hủy",
                                   string.IsNullOrEmpty(request.AdminNote)
                                       ? "Don hàng của bạn đã bị hủy. Vui lòng liên hệ hỗ trợ."
                                       : $"Lý do: {request.AdminNote}"),
            _                => ($"Đơn hàng #{request.OrderId} cập nhật trạng thái",
                                   $"Trạng thái mới: {request.NewStatus}")
        };

        // Push cho khách hàng biết đơn đã đổi trạng thái
        await _pusher.PushToUserAsync(
            userId:    request.UserId,
            title:     title,
            message:   message,
            type:      "Order",
            relatedId: request.OrderId);

        // Push cho tất cả Admin biết đơn đã được xử lý
        await _pusher.PushToAdminAsync("OrderUpdated", new
        {
            orderId   = request.OrderId,
            newStatus = request.NewStatus
        });

        return Ok(new { message = "Cập nhật trạng thái đơn hàng thành công" });
    }

    [HttpGet("orders")]
    public async Task<ActionResult<IEnumerable<AdminOrderListItem>>> GetOrders(
        [FromQuery] AdminOrderQueryRequest request)
    {
        var result = await _orders.GetAdminOrdersAsync(request);
        return Ok(result);
    }

    [HttpGet("orders/{orderId:int}")]
    public async Task<ActionResult> GetOrderDetail(int orderId)
    {
        var (header, items) = await _orders.GetAdminOrderDetailAsync(orderId);

        if (header is null)
            return NotFound(new { message = "Không tìm thấy đơn hàng" });

        return Ok(new
        {
            header,
            items
        });
    }

    [HttpGet("order-details")]
    public async Task<ActionResult<IEnumerable<AdminOrderDetailListItem>>> GetOrderDetails(
        [FromQuery] AdminOrderDetailQueryRequest request)
    {
        var result = await _orders.GetAdminOrderDetailsAsync(request);
        return Ok(result);
    }

    // ── Warranty ──────────────────────────────────────────────────────────────

    [HttpPut("warranty-claim")]
    public async Task<ActionResult> ProcessWarrantyClaim(ProcessWarrantyClaimRequest request)
    {
        await _warranty.ProcessClaimAsync(request);
        return Ok(new { message = "Xử lý yêu cầu bảo hành thành công" });
    }

    [HttpGet("warranty-claims")]
    public async Task<ActionResult<IEnumerable<WarrantyClaimItem>>> GetWarrantyClaims(
        [FromQuery] WarrantyClaimQueryRequest request)
    {
        var result = await _warranty.GetAdminClaimsAsync(request);
        return Ok(result);
    }

    // ── Banners ───────────────────────────────────────────────────────────────

    [HttpPost("banner")]
    public async Task<ActionResult> UpsertBanner(UpsertBannerRequest request)
    {
        await _banners.UpsertAsync(request);
        return Ok(new { message = "Lưu banner thành công" });
    }

    [HttpGet("banners")]
    public async Task<ActionResult<IEnumerable<BannerItem>>> GetBanners()
    {
        var result = await _banners.GetAdminBannersAsync();
        return Ok(result);
    }

    [HttpDelete("banner/{bannerId:int}")]
    public async Task<ActionResult> DeleteBanner(int bannerId)
    {
        var id = await _banners.DeleteAsync(bannerId);

        if (id is null)
            return BadRequest(new { message = "Xóa banner thất bại" });

        return Ok(new
        {
            message = "Xóa banner thành công",
            deletedBannerId = id
        });
    }

    // ── Dashboard ─────────────────────────────────────────────────────────────

    [HttpGet("dashboard")]
    public async Task<ActionResult<DashboardSummary>> GetDashboardSummary()
    {
        var result = await _dashboard.GetSummaryAsync();

        if (result is null)
            return NotFound(new { message = "Không có dữ liệu dashboard" });

        return Ok(result);
    }

    [HttpGet("revenue-report")]
    public async Task<ActionResult<IEnumerable<RevenueReportItem>>> GetRevenueReport(
        [FromQuery] RevenueReportRequest request)
    {
        var result = await _dashboard.GetRevenueReportAsync(request);
        return Ok(result);
    }

    // ── Vouchers ──────────────────────────────────────────────────────────────

    [HttpGet("voucher-usage")]
    public async Task<ActionResult<IEnumerable<VoucherUsageItem>>> GetVoucherUsage(
        [FromQuery] VoucherUsageQueryRequest request)
    {
        var result = await _vouchers.GetVoucherUsageAsync(request);
        return Ok(result);
    }

    // ── Reviews ───────────────────────────────────────────────────────────────

    [HttpGet("reviews")]
    public async Task<ActionResult<IEnumerable<AdminReviewItem>>> GetReviews(
        [FromQuery] AdminReviewQueryRequest request)
    {
        var result = await _reviews.GetAdminReviewsAsync(request);
        return Ok(result);
    }

    [HttpDelete("reviews/{reviewId:int}")]
    public async Task<ActionResult> DeleteReview(int reviewId)
    {
        return BadRequest(new { message = "Admin không có quyền xóa đánh giá, chỉ được ẩn đi!" });
    }

    [HttpPut("review")]
    public async Task<ActionResult> ApproveReview(ApproveReviewRequest request)
    {
        await _reviews.ApproveAsync(request);
        return Ok(new { message = "Duyệt đánh giá thành công" });
    }

    // ── Chat ──────────────────────────────────────────────────────────────────

    [HttpGet("chat-messages")]
    public async Task<ActionResult<IEnumerable<AdminChatItem>>> GetChatMessages(
        [FromQuery] AdminChatQueryRequest request)
    {
        var result = await _chat.GetAdminMessagesAsync(request);
        return Ok(result);
    }

    // ── Notifications ─────────────────────────────────────────────────────────

    [HttpPost("notification")]
    public async Task<ActionResult> SendNotification(AdminSendNotificationRequest request)
    {
        await _notifications.SendNotificationAsync(request);

        // ── Push real-time đến từng user được chọn ───────────────────────────────────
        var pushTasks = request.UserIds.Select(uid =>
            _pusher.PushToUserAsync(
                userId:  uid,
                title:   request.Title,
                message: request.Message,
                type:    "System"));

        await Task.WhenAll(pushTasks);

        return Ok(new
        {
            message = $"Đã gửi thông báo đến {request.UserIds.Length} người dùng."
        });
    }

    [HttpPost("run-mining")]
    public async Task<ActionResult> RunMining([FromQuery] decimal minUtil = 1000000)
    {
        var result = await _mining.RunMiningAsync(minUtil);
        return Ok(result);
    }

    [HttpGet("mined-itemsets")]
    public async Task<ActionResult> GetMinedItemsets()
    {
        var result = await _mining.GetMinedItemsetsAsync();
        return Ok(result);
    }
}