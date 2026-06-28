using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Categories;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categories;

    public CategoriesController(ICategoryService categories)
    {
        _categories = categories;
    }

    // ── Public APIs ───────────────────────────────────────────────────────────
    // Người chưa đăng nhập vẫn được xem danh mục.

    [AllowAnonymous]
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryItem>>> GetAll(
        [FromQuery] bool onlyActive = true)
    {
        var result = await _categories.GetAllAsync(onlyActive);
        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet("{categoryId:int}")]
    public async Task<ActionResult<CategoryItem>> GetById(int categoryId)
    {
        var result = await _categories.GetByIdAsync(categoryId);

        if (result is null)
            return NotFound(new { message = "Không tìm thấy danh mục" });

        return Ok(result);
    }

    // ── Category Management APIs ──────────────────────────────────────────────
    // Chỉ Admin được thêm/sửa/xóa danh mục.

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CategoryCreateRequest request)
    {
        var id = await _categories.CreateAsync(request);

        if (id is null)
            return BadRequest(new { message = "Thêm danh mục thất bại" });

        return Ok(new
        {
            message = "Thêm danh mục thành công",
            newCategoryId = id
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut]
    public async Task<ActionResult> Update([FromBody] CategoryUpdateRequest request)
    {
        var id = await _categories.UpdateAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật danh mục thất bại" });

        return Ok(new
        {
            message = "Cập nhật danh mục thành công",
            updatedCategoryId = id
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{categoryId:int}")]
    public async Task<ActionResult> Delete(int categoryId)
    {
        var id = await _categories.DeleteAsync(categoryId);

        if (id is null)
            return BadRequest(new { message = "Xóa danh mục thất bại" });

        return Ok(new
        {
            message = "Xóa danh mục thành công",
            deletedCategoryId = id
        });
    }
}