using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Users;

namespace PC_Store.Repositories.Interfaces;

public interface IUserRepository
{
    Task<UserProfileItem?> GetProfileAsync(int userId);
    Task<int?> UpdateProfileAsync(UpdateProfileRequest request);
    Task<int?> UpdateBankAsync(UpdateBankRequest request);
    Task<IEnumerable<UserAddressItem>> GetAddressesAsync(int userId);
    Task<int?> CreateAddressAsync(UserAddressCreateRequest request);
    Task<int?> UpdateAddressAsync(UserAddressUpdateRequest request);
    Task DeleteAddressAsync(UserAddressDeleteRequest request);
    Task<IEnumerable<AdminUserItem>> GetAdminUsersAsync(AdminUserQueryRequest request);
    Task<(AdminUserDetailHeader? Header, IEnumerable<AdminUserRoleItem> Roles, IEnumerable<AdminUserAddressItem> Addresses)> GetAdminUserDetailAsync(int userId);
    Task<int?> UpdateUserStatusAsync(UpdateUserStatusRequest request);
    Task ManageUserRoleAsync(ManageUserRoleRequest request);
    Task<IEnumerable<UserRoleItem>> GetUserRolesAsync(UserRoleQueryRequest request);
}
