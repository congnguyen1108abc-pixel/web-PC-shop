using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Users;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class UserRepository : IUserRepository
{
    private readonly IDbRepository _db;

    public UserRepository(IDbRepository db) => _db = db;

    public Task<UserProfileItem?> GetProfileAsync(int userId)
        => _db.QuerySingleAsync<UserProfileItem>("sp_User_GetProfile", new { UserId = userId });

    public async Task<int?> UpdateProfileAsync(UpdateProfileRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedIdResult>("sp_User_UpdateProfile", new
        {
            request.UserId, request.FullName, request.PhoneNumber, request.AvatarUrl
        });
        return r?.UpdatedUserId;
    }

    public async Task<int?> UpdateBankAsync(UpdateBankRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedIdResult>("sp_User_UpdateBank", new
        {
            request.UserId, request.BankName, request.BankAccountNumber, request.BankAccountName
        });
        return r?.UpdatedUserId;
    }

    public Task<IEnumerable<UserAddressItem>> GetAddressesAsync(int userId)
        => _db.QueryAsync<UserAddressItem>("sp_UserAddress_GetByUser", new { UserId = userId });

    public async Task<int?> CreateAddressAsync(UserAddressCreateRequest request)
    {
        var r = await _db.QuerySingleAsync<NewAddrResult>("sp_UserAddress_Create", new
        {
            request.UserId, request.ReceiverName, request.PhoneNumber,
            request.Province, request.District, request.Ward, request.DetailAddress, request.IsDefault
        });
        return r?.NewAddressId;
    }

    public async Task<int?> UpdateAddressAsync(UserAddressUpdateRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedAddrResult>("sp_UserAddress_Update", new
        {
            request.AddressId, request.UserId, request.ReceiverName, request.PhoneNumber,
            request.Province, request.District, request.Ward, request.DetailAddress, request.IsDefault
        });
        return r?.UpdatedAddressId;
    }

    public Task DeleteAddressAsync(UserAddressDeleteRequest request)
        => _db.ExecuteAsync("sp_UserAddress_Delete", new { request.AddressId, request.UserId });

    public Task<IEnumerable<AdminUserItem>> GetAdminUsersAsync(AdminUserQueryRequest request)
        => _db.QueryAsync<AdminUserItem>("sp_Admin_GetUsers", new
        {
            request.Role, request.IsActive, request.Keyword
        });

    public async Task<(AdminUserDetailHeader? Header, IEnumerable<AdminUserRoleItem> Roles, IEnumerable<AdminUserAddressItem> Addresses)> GetAdminUserDetailAsync(int userId)
    {
        await using var multi = await _db.QueryMultipleAsync("sp_Admin_GetUserDetail", new { UserId = userId });
        var header = await multi.ReadFirstOrDefaultAsync<AdminUserDetailHeader>();
        var roles = await multi.ReadAsync<AdminUserRoleItem>();
        var addresses = await multi.ReadAsync<AdminUserAddressItem>();
        return (header, roles, addresses);
    }

    public async Task<int?> UpdateUserStatusAsync(UpdateUserStatusRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedIdResult>("sp_Admin_UpdateUserStatus", new
        {
            request.UserId, request.IsActive
        });
        return r?.UpdatedUserId;
    }

    public Task ManageUserRoleAsync(ManageUserRoleRequest request)
    {
        if (request.Action == "SET_ROLES" || request.RoleCode == "Admin" || request.RoleCode == "Customer" || request.RoleCode == "Staff")
        {
            return _db.ExecuteAsync("sp_Admin_SetUserRoleAndPermissions", new
            {
                AdminID = request.AdminId,
                UserID = request.UserId,
                MainRole = request.RoleCode,
                RoleCodes = request.RoleCodes
            });
        }
        else
        {
            return _db.ExecuteAsync("sp_Admin_ManageUserRole", new
            {
                request.AdminId, request.UserId, request.RoleCode, request.Action
            });
        }
    }


    public Task<IEnumerable<UserRoleItem>> GetUserRolesAsync(UserRoleQueryRequest request)
        => _db.QueryAsync<UserRoleItem>("sp_Admin_GetUserRoles", new
        {
            request.UserId, request.RoleCode
        });

    private sealed record UpdatedIdResult(int UpdatedUserId);
    private sealed record NewAddrResult(int NewAddressId);
    private sealed record UpdatedAddrResult(int UpdatedAddressId);
}
