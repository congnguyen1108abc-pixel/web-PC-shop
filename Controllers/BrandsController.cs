using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Brands;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class BrandsController : ControllerBase
{
    private readonly IBrandService _brands;

    public BrandsController(IBrandService brands)
    {
        _brands = brands;
    }

    // ── Public APIs ───────────────────────────────────────────────────────────
    // Người chưa đăng nhập vẫn được xem thương hiệu.

    [AllowAnonymous]
    [HttpGet]
    public async Task<ActionResult<IEnumerable<BrandItem>>> GetAll(
        [FromQuery] bool onlyActive = true)
    {
        var result = await _brands.GetAllAsync(onlyActive);
        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet("{brandId:int}")]
    public async Task<ActionResult<BrandItem>> GetById(int brandId)
    {
        var result = await _brands.GetByIdAsync(brandId);

        if (result is null)
            return NotFound(new { message = "Không tìm thấy thương hiệu" });

        return Ok(result);
    }

    // ── Brand Management APIs ─────────────────────────────────────────────────
    // Chỉ Admin được thêm/sửa/xóa thương hiệu.

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<ActionResult> Create([FromBody] BrandCreateRequest request)
    {
        var id = await _brands.CreateAsync(request);

        if (id is null)
            return BadRequest(new { message = "Thêm thương hiệu thất bại" });

        return Ok(new
        {
            message = "Thêm thương hiệu thành công",
            newBrandId = id
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut]
    public async Task<ActionResult> Update([FromBody] BrandUpdateRequest request)
    {
        var id = await _brands.UpdateAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật thương hiệu thất bại" });

        return Ok(new
        {
            message = "Cập nhật thương hiệu thành công",
            updatedBrandId = id
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{brandId:int}")]
    public async Task<ActionResult> Delete(int brandId)
    {
        var id = await _brands.DeleteAsync(brandId);

        if (id is null)
            return BadRequest(new { message = "Xóa thương hiệu thất bại" });

        return Ok(new
        {
            message = "Xóa thương hiệu thành công",
            deletedBrandId = id
        });
    }
}