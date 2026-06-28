using PC_Store.DTOs.Vouchers;

namespace PC_Store.Services.Interfaces;

public interface IVoucherService
{
    Task<IEnumerable<VoucherItem>> GetAllAsync(VoucherQueryRequest request);
    Task<IEnumerable<VoucherAvailableItem>> GetAvailableAsync(VoucherAvailableRequest request);
    Task<string?> CreateAsync(VoucherCreateRequest request);
    Task<string?> UpdateAsync(VoucherUpdateRequest request);
    Task<string?> DeleteAsync(string voucherCode);
    Task<IEnumerable<VoucherUsageItem>> GetVoucherUsageAsync(VoucherUsageQueryRequest request);
}
