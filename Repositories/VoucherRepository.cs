using PC_Store.DTOs.Vouchers;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class VoucherRepository : IVoucherRepository
{
    private readonly IDbRepository _db;
    public VoucherRepository(IDbRepository db) => _db = db;

    public Task<IEnumerable<VoucherItem>> GetAllAsync(VoucherQueryRequest request)
        => _db.QueryAsync<VoucherItem>("sp_Voucher_GetAll", new { OnlyActive = request.OnlyActive });

    public Task<IEnumerable<VoucherAvailableItem>> GetAvailableAsync(VoucherAvailableRequest request)
        => _db.QueryAsync<VoucherAvailableItem>("sp_Voucher_GetAvailable", new { request.UserId, request.OrderValue });

    public async Task<string?> CreateAsync(VoucherCreateRequest request)
    {
        var r = await _db.QuerySingleAsync<NewCodeResult>("sp_Voucher_Create", new
        {
            request.VoucherCode, request.Description, request.DiscountAmount, request.IsPercent,
            request.MaxDiscount, request.MinOrderValue, request.ExpiryDate,
            request.UsageLimit, request.MaxPerUser, request.IsActive
        });
        return r?.NewVoucherCode;
    }

    public async Task<string?> UpdateAsync(VoucherUpdateRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedCodeResult>("sp_Voucher_Update", new
        {
            request.VoucherCode, request.Description, request.DiscountAmount, request.IsPercent,
            request.MaxDiscount, request.MinOrderValue, request.ExpiryDate,
            request.UsageLimit, request.MaxPerUser, request.IsActive
        });
        return r?.UpdatedVoucherCode;
    }

    public async Task<string?> DeleteAsync(string voucherCode)
    {
        var r = await _db.QuerySingleAsync<DeletedCodeResult>("sp_Voucher_Delete", new { VoucherCode = voucherCode });
        return r?.DeletedVoucherCode;
    }

    public Task<IEnumerable<VoucherUsageItem>> GetVoucherUsageAsync(VoucherUsageQueryRequest request)
        => _db.QueryAsync<VoucherUsageItem>("sp_Admin_GetVoucherUsage", new
        {
            request.UserId, request.VoucherCode, request.OrderId, request.DateFrom, request.DateTo
        });

    private sealed record NewCodeResult(string NewVoucherCode);
    private sealed record UpdatedCodeResult(string UpdatedVoucherCode);
    private sealed record DeletedCodeResult(string DeletedVoucherCode);
}
