using PC_Store.DTOs.Vouchers;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class VoucherService : IVoucherService
{
    private readonly IVoucherRepository _repo;
    private readonly ICacheService _cache;

    private const string CacheKeyPrefix = "vouchers";
    private static readonly TimeSpan CacheExpiration = TimeSpan.FromMinutes(10);

    public VoucherService(IVoucherRepository repo, ICacheService cache)
    {
        _repo = repo;
        _cache = cache;
    }

    public async Task<IEnumerable<VoucherItem>> GetAllAsync(VoucherQueryRequest request)
    {
        var cacheKey = $"{CacheKeyPrefix}:all:{request.OnlyActive}";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: () => _repo.GetAllAsync(request),
            expiration: CacheExpiration
        );

        return result ?? Enumerable.Empty<VoucherItem>();
    }

    public Task<IEnumerable<VoucherAvailableItem>> GetAvailableAsync(VoucherAvailableRequest request)
    {
        return _repo.GetAvailableAsync(request);
    }

    public async Task<string?> CreateAsync(VoucherCreateRequest request)
    {
        var result = await _repo.CreateAsync(request);

        if (result is not null)
        {
            // Invalidate cache when creating new voucher
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }

    public async Task<string?> UpdateAsync(VoucherUpdateRequest request)
    {
        var result = await _repo.UpdateAsync(request);

        if (result is not null)
        {
            // Invalidate cache when updating voucher
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }

    public async Task<string?> DeleteAsync(string voucherCode)
    {
        var result = await _repo.DeleteAsync(voucherCode);

        if (result is not null)
        {
            // Invalidate cache when deleting voucher
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }

    public Task<IEnumerable<VoucherUsageItem>> GetVoucherUsageAsync(VoucherUsageQueryRequest request) => _repo.GetVoucherUsageAsync(request);
}
