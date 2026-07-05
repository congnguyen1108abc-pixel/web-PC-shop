using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Users;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class UserService : IUserService
{
    private readonly IUserRepository _repo;
    public UserService(IUserRepository repo) => _repo = repo;

    public Task<UserProfileItem?> GetProfileAsync(int userId) => _repo.GetProfileAsync(userId);
    public Task<int?> UpdateProfileAsync(UpdateProfileRequest request) => _repo.UpdateProfileAsync(request);
    public Task<int?> UpdateBankAsync(UpdateBankRequest request) => _repo.UpdateBankAsync(request);
    public Task<IEnumerable<UserAddressItem>> GetAddressesAsync(int userId) => _repo.GetAddressesAsync(userId);
    public Task<int?> CreateAddressAsync(UserAddressCreateRequest request) => _repo.CreateAddressAsync(request);
    public Task<int?> UpdateAddressAsync(UserAddressUpdateRequest request) => _repo.UpdateAddressAsync(request);
    public Task DeleteAddressAsync(UserAddressDeleteRequest request) => _repo.DeleteAddressAsync(request);
    public Task<IEnumerable<AdminUserItem>> GetAdminUsersAsync(AdminUserQueryRequest request) => _repo.GetAdminUsersAsync(request);
    public Task<(AdminUserDetailHeader?, IEnumerable<AdminUserRoleItem>, IEnumerable<AdminUserAddressItem>)> GetAdminUserDetailAsync(int userId) => _repo.GetAdminUserDetailAsync(userId);
    public Task<int?> UpdateUserStatusAsync(UpdateUserStatusRequest request) => _repo.UpdateUserStatusAsync(request);
    public Task ManageUserRoleAsync(ManageUserRoleRequest request) => _repo.ManageUserRoleAsync(request);
    public Task<IEnumerable<UserRoleItem>> GetUserRolesAsync(UserRoleQueryRequest request) => _repo.GetUserRolesAsync(request);
}
