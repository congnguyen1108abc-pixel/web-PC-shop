using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Banners;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class BannersController : ControllerBase
{
    private readonly IBannerService _banners;

    public BannersController(IBannerService banners)
    {
        _banners = banners;
    }

    // ── Public APIs ───────────────────────────────────────────────────────────
    // Trang chủ cần lấy banner mà không cần đăng nhập.

    [AllowAnonymous]
    [HttpGet("active")]
    public async Task<ActionResult<IEnumerable<BannerItem>>> GetActive()
    {
        var result = await _banners.GetActiveAsync();
        return Ok(result);
    }

    // ── Banner Management APIs ────────────────────────────────────────────────
    // Chỉ Admin được xem toàn bộ, thêm/cập nhật/xóa banner.

    [Authorize(Roles = "Admin")]
    [HttpGet("admin")]
    public async Task<ActionResult<IEnumerable<BannerItem>>> GetAdminBanners()
    {
        var result = await _banners.GetAdminBannersAsync();
        return Ok(result);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<ActionResult> Upsert([FromBody] UpsertBannerRequest request)
    {
        await _banners.UpsertAsync(request);

        return Ok(new
        {
            message = request.BannerId is null
                ? "Thêm banner thành công"
                : "Cập nhật banner thành công"
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{bannerId:int}")]
    public async Task<ActionResult> Delete(int bannerId)
    {
        var id = await _banners.DeleteAsync(bannerId);

        if (id is null)
            return NotFound(new { message = "Không tìm thấy banner" });

        return Ok(new
        {
            message = "Xóa banner thành công",
            deletedBannerId = id
        });
    }
}