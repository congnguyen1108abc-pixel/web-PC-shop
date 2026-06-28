namespace PC_Store.DTOs.Users;

public sealed record UserAddressCreateRequest(
    int UserId,
    string ReceiverName,
    string PhoneNumber,
    string Province,
    string District,
    string Ward,
    string DetailAddress,
    bool IsDefault);

public sealed record UserAddressUpdateRequest(
    int AddressId,
    int UserId,
    string ReceiverName,
    string PhoneNumber,
    string Province,
    string District,
    string Ward,
    string DetailAddress,
    bool IsDefault);

public sealed record UserAddressDeleteRequest(int AddressId, int UserId);

public sealed record UserAddressItem(
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
