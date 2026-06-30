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
        try
        {
            await _reviews.AddAsync(request);

            return Ok(new
            {
                message = "Đánh giá của bạn đã được đăng thành công!"
            });
        }
        catch (Microsoft.Data.SqlClient.SqlException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Xóa đánh giá (chấp nhận Admin hoặc người dùng tự xóa).
    /// </summary>
    [Authorize]
    [HttpDelete("{reviewId:int}")]
    public async Task<ActionResult> Delete(int reviewId)
    {
        try
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var isAdmin = User.IsInRole("Admin");

            if (!isAdmin && string.IsNullOrEmpty(userIdClaim))
            {
                return Unauthorized(new { message = "Vui lòng đăng nhập!" });
            }

            int? userIdFilter = isAdmin ? null : int.Parse(userIdClaim!);

            await _reviews.DeleteAsync(reviewId, userIdFilter);

            return Ok(new
            {
                message = "Xóa đánh giá thành công"
            });
        }
        catch (Microsoft.Data.SqlClient.SqlException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Chỉnh sửa đánh giá (chỉ người dùng tự sửa).
    /// </summary>
    [Authorize]
    [HttpPut("{reviewId:int}")]
    public async Task<ActionResult> Update(int reviewId, [FromBody] UpdateReviewRequest request)
    {
        try
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim))
            {
                return Unauthorized(new { message = "Vui lòng đăng nhập!" });
            }

            int userId = int.Parse(userIdClaim);
            await _reviews.UpdateAsync(reviewId, userId, request.Rating, request.Comment, request.ImageUrl);

            return Ok(new
            {
                message = "Chỉnh sửa đánh giá thành công!"
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}