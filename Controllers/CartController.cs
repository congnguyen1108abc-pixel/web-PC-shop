using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Cart;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public sealed class CartController : ControllerBase
{
    private readonly ICartService _cart;

    public CartController(ICartService cart)
    {
        _cart = cart;
    }

    [EnableRateLimiting("write")]  // 30 req / phút / IP — chặn spam thêm giỏ hàng
    [HttpPost("add")]
    public async Task<ActionResult> AddToCart(CartAddRequest request)
    {
        await _cart.AddToCartAsync(request);
        return Ok(new { message = "Thêm vào giỏ hàng thành công" });
    }

    [HttpGet("user/{userId:int}")]
    public async Task<ActionResult<IEnumerable<CartItem>>> GetCart(int userId)
    {
        var result = await _cart.GetCartAsync(userId);
        return Ok(result);
    }

    [HttpPut("item")]
    public async Task<ActionResult> UpdateCartItem(CartUpdateRequest request)
    {
        await _cart.UpdateCartItemAsync(request);
        return Ok(new { message = "Cập nhật giỏ hàng thành công" });
    }

    [HttpPatch("item")]
    public async Task<ActionResult> PatchCartItem(CartUpdateRequest request)
    {
        await _cart.UpdateCartItemAsync(request);
        return Ok(new { message = "Cập nhật một phần giỏ hàng thành công" });
    }

    [HttpDelete("item/{cartId:int}/user/{userId:int}")]
    public async Task<ActionResult> DeleteCartItem(int cartId, int userId)
    {
        await _cart.DeleteCartItemAsync(cartId, userId);
        return Ok(new { message = "Xóa sản phẩm khỏi giỏ hàng thành công" });
    }

    [HttpDelete("clear/user/{userId:int}")]
    public async Task<ActionResult> ClearCart(int userId)
    {
        await _cart.ClearCartAsync(userId);
        return Ok(new { message = "Xóa toàn bộ giỏ hàng thành công" });
    }
}