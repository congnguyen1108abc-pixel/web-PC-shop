using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Banners;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class BannerService : IBannerService
{
    private readonly IBannerRepository _repo;
    private readonly ICacheService _cache;

    private const string CacheKeyPrefix = "banners";
    private static readonly TimeSpan CacheExpiration = TimeSpan.FromMinutes(15);

    public BannerService(IBannerRepository repo, ICacheService cache)
    {
        _repo = repo;
        _cache = cache;
    }

    public async Task<IEnumerable<BannerItem>> GetActiveAsync()
    {
        var cacheKey = $"{CacheKeyPrefix}:active";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: () => _repo.GetActiveAsync(),
            expiration: CacheExpiration
        );

        return result ?? Enumerable.Empty<BannerItem>();
    }

    public async Task<IEnumerable<BannerItem>> GetAdminBannersAsync()
    {
        var cacheKey = $"{CacheKeyPrefix}:admin";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: () => _repo.GetAdminBannersAsync(),
            expiration: CacheExpiration
        );

        return result ?? Enumerable.Empty<BannerItem>();
    }

    public async Task UpsertAsync(UpsertBannerRequest request)
    {
        await _repo.UpsertAsync(request);

        // Invalidate cache when upserting banner
        _cache.RemoveByPrefix(CacheKeyPrefix);
    }

    public async Task<int?> DeleteAsync(int bannerId)
    {
        var result = await _repo.DeleteAsync(bannerId);

        if (result.HasValue)
        {
            // Invalidate cache when deleting banner
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }
}
