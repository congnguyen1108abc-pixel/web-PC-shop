using PC_Store.DTOs.Cart;

namespace PC_Store.Repositories.Interfaces;

public interface ICartRepository
{
    Task AddToCartAsync(CartAddRequest request);
    Task<IEnumerable<CartItem>> GetCartAsync(int userId);
    Task UpdateCartItemAsync(CartUpdateRequest request);
    Task DeleteCartItemAsync(int cartId, int userId);
}
