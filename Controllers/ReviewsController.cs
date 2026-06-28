using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Reviews;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviews;

    public ReviewsController(IReviewService reviews)
    {
        _reviews = reviews;
    }

    /// <summary>
    /// Lấy danh sách đánh giá của 1 sản phẩm đã duyệt (có phân trang).
    /// API public: người chưa đăng nhập vẫn xem được review.
    /// </summary>
    [HttpGet("product/{productId:int}")]
    public async Task<ActionResult<PagedResult<CustomerReviewItem>>> GetByProduct(int productId, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
    {
        var result = await _reviews.GetByProductAsync(productId, pageNumber, pageSize);
        return Ok(result);
    }

    /// <summary>
    /// Khách hàng gửi đánh giá.
    /// Cần đăng nhập.
    /// </summary>
    [Authorize]
    [EnableRateLimiting("write")]  // 30 req / phút / IP — chặn spam gửi đánh giá
    [HttpPost]
    public async Task<ActionResult> Add([FromBody] AddReviewRequest request)
    {
        await _reviews.AddAsync(request);

        return Ok(new
        {
            message = "Đánh giá của bạn đã được gửi và đang chờ duyệt."
        });
    }

    /// <summary>
    /// Admin xóa đánh giá.
    /// Chỉ Admin được phép xóa.
    /// </summary>
    [Authorize(Roles = "Admin")]
    [HttpDelete("{reviewId:int}")]
    public async Task<ActionResult> Delete(int reviewId)
    {
        await _reviews.DeleteAsync(reviewId);

        return Ok(new
        {
            message = "Xóa đánh giá thành công"
        });
    }
}