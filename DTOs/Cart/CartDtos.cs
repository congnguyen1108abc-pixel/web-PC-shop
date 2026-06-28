namespace PC_Store.DTOs.Cart;

public sealed record CartAddRequest(int UserId, int ProductId, int Quantity);

public sealed record CartUpdateRequest(int CartId, int UserId, int NewQuantity);
