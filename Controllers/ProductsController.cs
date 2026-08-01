using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Products;
using PC_Store.DTOs.Recommendations;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ProductsController : ControllerBase
{
    private readonly IProductService _products;
    private readonly IRecommendationService _recommendations;

    public ProductsController(IProductService products, IRecommendationService recommendations)
    {
        _products = products;
        _recommendations = recommendations;
    }

    // ── Public APIs ───────────────────────────────────────────────────────────
    // Người chưa đăng nhập vẫn được xem sản phẩm.

    [AllowAnonymous]
    [HttpGet("top-selling")]
    public async Task<ActionResult<IEnumerable<TopSellingItem>>> GetTopSelling(
        [FromQuery] TopSellingRequest request)
    {
        var result = await _products.GetTopSellingAsync(request);
        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet]
    public async Task<ActionResult<PagedResult<ProductListItem>>> GetAll(
        [FromQuery] ProductQueryRequest request)
    {
        var result = await _products.GetAllAsync(request);
        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet("{productId:int}")]
    public async Task<ActionResult> GetById(int productId)
    {
        var (header, images, attributes) = await _products.GetByIdAsync(productId);

        if (header is null)
            return NotFound(new { message = "Không tìm thấy sản phẩm" });

        return Ok(new
        {
            header,
            images,
            attributes
        });
    }

    [AllowAnonymous]
    [HttpGet("slug/{slug}")]
    public async Task<ActionResult> GetBySlug(string slug)
    {
        var (header, images, attributes) = await _products.GetBySlugAsync(slug);

        if (header is null && int.TryParse(slug, out int id))
        {
            (header, images, attributes) = await _products.GetByIdAsync(id);
        }

        if (header is null)
            return NotFound(new { message = "Không tìm thấy sản phẩm" });

        return Ok(new
        {
            header,
            images,
            attributes
        });
    }

    [AllowAnonymous]
    [HttpGet("{productId:int}/reviews")]
    public async Task<ActionResult<IEnumerable<ProductReviewItem>>> GetReviews(int productId)
    {
        var result = await _products.GetReviewsAsync(productId);
        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet("{productId:int}/recommendations")]
    public async Task<ActionResult<IEnumerable<RecommendationResult>>> GetRecommendations(int productId, [FromQuery] int topN = 8)
    {
        try
        {
            var result = await _recommendations.GetRecommendationsAsync(productId, topN);
            return Ok(result);
        }
        catch
        {
            return Ok(Array.Empty<RecommendationResult>());
        }
    }

    [AllowAnonymous]
    [HttpGet("gaming/product-types")]
    public ActionResult GetGamingProductTypes()
    {
        // Return a predefined list of Gaming Gear product types
        var productTypes = new[]
        {
            new { Code = "Mouse", Name = "Chuột" },
            new { Code = "Keyboard", Name = "Bàn phím" },
            new { Code = "Headset", Name = "Tai nghe" },
            new { Code = "Monitor", Name = "Màn hình" },
            new { Code = "Speaker", Name = "Loa" },
            new { Code = "Microphone", Name = "Micro" },
            new { Code = "Webcam", Name = "Webcam" },
            new { Code = "Chair", Name = "Ghế Gaming" },
            new { Code = "MousePad", Name = "Mouse Pad" },
            new { Code = "Controller", Name = "Tay cầm" },
            new { Code = "Other", Name = "Phụ kiện" }
        };
        
        return Ok(productTypes);
    }

    // ── Product Management APIs ───────────────────────────────────────────────
    // Chỉ Admin hoặc Staff được thêm/sửa/xóa sản phẩm.

    [Authorize(Roles = "Admin,Staff")]
    [HttpPost]
    public async Task<ActionResult> Create([FromBody] ProductCreateRequest request)
    {
        var id = await _products.CreateAsync(request);

        if (id is null)
            return BadRequest(new { message = "Thêm sản phẩm thất bại" });

        return Ok(new
        {
            message = "Thêm sản phẩm thành công",
            newProductId = id
        });
    }

    [Authorize(Roles = "Admin,Staff")]
    [HttpPut]
    public async Task<ActionResult> Update([FromBody] ProductUpdateRequest request)
    {
        var id = await _products.UpdateAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật sản phẩm thất bại" });

        return Ok(new
        {
            message = "Cập nhật sản phẩm thành công",
            updatedProductId = id
        });
    }

    [Authorize(Roles = "Admin,Staff")]
    [HttpDelete("{productId:int}")]
    public async Task<ActionResult> Delete(int productId)
    {
        try
        {
            var id = await _products.DeleteAsync(productId);

            if (id is null)
                return BadRequest(new { message = "Xóa sản phẩm thất bại" });

            return Ok(new
            {
                message = "Xóa sản phẩm thành công",
                deletedProductId = id
            });
        }
        catch (Microsoft.Data.SqlClient.SqlException ex)
        {
            if (ex.Message.Contains("khong ton tai"))
                return NotFound(new { message = "Sản phẩm không tồn tại" });
            
            return BadRequest(new { message = "Xóa sản phẩm thất bại: " + ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi hệ thống: " + ex.Message });
        }
    }

    // ── Product Images Management APIs ────────────────────────────────────────
    // Chỉ Admin hoặc Staff được quản lý ảnh sản phẩm.

    [Authorize(Roles = "Admin,Staff")]
    [HttpPost("images")]
    public async Task<ActionResult> AddImage([FromBody] ProductImageRequest request)
    {
        var id = await _products.AddImageAsync(request);

        if (id is null)
            return BadRequest(new { message = "Thêm ảnh sản phẩm thất bại" });

        return Ok(new
        {
            message = "Thêm ảnh sản phẩm thành công",
            newImageId = id
        });
    }

    [Authorize(Roles = "Admin,Staff")]
    [HttpPut("images")]
    public async Task<ActionResult> UpdateImage([FromBody] ProductImageUpdateRequest request)
    {
        var id = await _products.UpdateImageAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật ảnh sản phẩm thất bại" });

        return Ok(new
        {
            message = "Cập nhật ảnh sản phẩm thành công",
            updatedImageId = id
        });
    }

    [Authorize(Roles = "Admin,Staff")]
    [HttpDelete("images")]
    public async Task<ActionResult> DeleteImage([FromBody] ProductImageDeleteRequest request)
    {
        await _products.DeleteImageAsync(request);

        return Ok(new
        {
            message = "Xóa ảnh sản phẩm thành công"
        });
    }

    // ── Product Attributes Management APIs ────────────────────────────────────
    // Chỉ Admin hoặc Staff được quản lý thuộc tính sản phẩm.

    [Authorize(Roles = "Admin,Staff")]
    [HttpPost("attributes")]
    public async Task<ActionResult> AddAttribute([FromBody] ProductAttributeRequest request)
    {
        var id = await _products.AddAttributeAsync(request);

        if (id is null)
            return BadRequest(new { message = "Thêm thuộc tính sản phẩm thất bại" });

        return Ok(new
        {
            message = "Thêm thuộc tính sản phẩm thành công",
            newAttributeId = id
        });
    }

    [Authorize(Roles = "Admin,Staff")]
    [HttpPut("attributes")]
    public async Task<ActionResult> UpdateAttribute([FromBody] ProductAttributeUpdateRequest request)
    {
        var id = await _products.UpdateAttributeAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật thuộc tính sản phẩm thất bại" });

        return Ok(new
        {
            message = "Cập nhật thuộc tính sản phẩm thành công",
            updatedAttributeId = id
        });
    }

    [Authorize(Roles = "Admin,Staff")]
    [HttpDelete("attributes")]
    public async Task<ActionResult> DeleteAttribute([FromBody] ProductAttributeDeleteRequest request)
    {
        await _products.DeleteAttributeAsync(request);

        return Ok(new
        {
            message = "Xóa thuộc tính sản phẩm thành công"
        });
    }
}