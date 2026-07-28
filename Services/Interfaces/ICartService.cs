using PC_Store.DTOs.Cart;

namespace PC_Store.Services.Interfaces;

public interface ICartService
{
    Task AddToCartAsync(CartAddRequest request);
    Task<IEnumerable<CartItem>> GetCartAsync(int userId);
    Task UpdateCartItemAsync(CartUpdateRequest request);
    Task DeleteCartItemAsync(int cartId, int userId);
    Task ClearCartAsync(int userId);
}
