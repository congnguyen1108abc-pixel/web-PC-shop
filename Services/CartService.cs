using PC_Store.DTOs.Cart;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class CartService : ICartService
{
    private readonly ICartRepository _repo;
    public CartService(ICartRepository repo) => _repo = repo;

    public Task AddToCartAsync(CartAddRequest request) => _repo.AddToCartAsync(request);
    public Task<IEnumerable<CartItem>> GetCartAsync(int userId) => _repo.GetCartAsync(userId);
    public Task UpdateCartItemAsync(CartUpdateRequest request) => _repo.UpdateCartItemAsync(request);
    public Task DeleteCartItemAsync(int cartId, int userId) => _repo.DeleteCartItemAsync(cartId, userId);
}
