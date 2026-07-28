using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Warranty;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public sealed class WarrantyController : ControllerBase
{
    private readonly IWarrantyService _warranty;

    public WarrantyController(IWarrantyService warranty)
    {
        _warranty = warranty;
    }

    /// <summary>
    /// Khách hàng tạo yêu cầu bảo hành.
    /// Cần đăng nhập.
    /// </summary>
    [EnableRateLimiting("write")]  // 30 req / phút / IP — chặn spam bảo hành
    [HttpPost("claim")]
    public async Task<ActionResult> CreateClaim(CreateWarrantyClaimRequest request)
    {
        await _warranty.CreateClaimAsync(request);

        return Ok(new
        {
            message = "Tạo yêu cầu bảo hành thành công"
        });
    }

    /// <summary>
    /// Lấy danh sách phiếu bảo hành của user.
    /// Cần đăng nhập.
    /// </summary>
    [HttpGet("user/{userId:int}")]
    public async Task<ActionResult<IEnumerable<WarrantyItem>>> GetWarranties(int userId)
    {
        var result = await _warranty.GetWarrantiesAsync(userId);
        return Ok(result);
    }

    /// <summary>
    /// Tra cứu phiếu bảo hành theo mã.
    /// Cần đăng nhập để tránh lộ thông tin bảo hành.
    /// </summary>
    [HttpGet("{warrantyCode}")]
    public async Task<ActionResult<WarrantyItem>> GetByCode(
        string warrantyCode,
        [FromQuery] int? userId = null)
    {
        var result = await _warranty.GetByCodeAsync(warrantyCode, userId);

        if (result is null)
            return NotFound(new { message = "Không tìm thấy phiếu bảo hành." });

        return Ok(result);
    }

    /// <summary>
    /// Tra cứu bảo hành công khai theo SĐT hoặc SKU / Serial Number
    /// </summary>
    [AllowAnonymous]
    [HttpGet("lookup")]
    public async Task<ActionResult<IEnumerable<WarrantyItem>>> Lookup([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
            return BadRequest(new { message = "Vui lòng nhập số điện thoại hoặc mã SKU / Serial." });

        var results = await _warranty.PublicLookupAsync(query.Trim());
        return Ok(results);
    }
}