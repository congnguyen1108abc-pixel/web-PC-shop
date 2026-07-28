using PC_Store.DTOs.Cart;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class CartRepository : ICartRepository
{
    private readonly IDbRepository _db;

    public CartRepository(IDbRepository db) => _db = db;

    public Task AddToCartAsync(CartAddRequest request)
        => _db.ExecuteAsync("sp_Customer_AddToCart", new
        {
            request.UserId, request.ProductId, request.Quantity
        });

    public Task<IEnumerable<CartItem>> GetCartAsync(int userId)
        => _db.QueryAsync<CartItem>("sp_Customer_GetCart", new { UserId = userId });

    public Task UpdateCartItemAsync(CartUpdateRequest request)
        => _db.ExecuteAsync("sp_Customer_UpdateCartItem", new
        {
            request.CartId, request.UserId, request.NewQuantity
        });

    public Task DeleteCartItemAsync(int cartId, int userId)
        => _db.ExecuteAsync("sp_Customer_UpdateCartItem", new
        {
            CartId = cartId, UserId = userId, NewQuantity = 0
        });

    public Task ClearCartAsync(int userId)
        => _db.ExecuteRawAsync("DELETE FROM Cart WHERE UserID = @UserId", new { UserId = userId });
}
