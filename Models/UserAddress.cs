namespace PC_Store.Models;

public sealed record UserAddress(
    int AddressId,
    int UserId,
    string ReceiverName,
    string PhoneNumber,
    string Province,
    string District,
    string Ward,
    string DetailAddress,
    bool IsDefault,
    DateTime CreatedAt);
