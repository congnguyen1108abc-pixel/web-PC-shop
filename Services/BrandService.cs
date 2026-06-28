using PC_Store.DTOs.Brands;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class BrandService : IBrandService
{
    private readonly IBrandRepository _repo;
    private readonly ICacheService _cache;

    private const string CacheKeyPrefix = "brands";
    private static readonly TimeSpan CacheExpiration = TimeSpan.FromMinutes(30);

    public BrandService(IBrandRepository repo, ICacheService cache)
    {
        _repo = repo;
        _cache = cache;
    }

    public async Task<IEnumerable<BrandItem>> GetAllAsync(bool onlyActive)
    {
        var cacheKey = $"{CacheKeyPrefix}:all:{onlyActive}";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: () => _repo.GetAllAsync(onlyActive),
            expiration: CacheExpiration
        );

        return result ?? Enumerable.Empty<BrandItem>();
    }

    public Task<BrandItem?> GetByIdAsync(int brandId) => _repo.GetByIdAsync(brandId);

    public async Task<int?> CreateAsync(BrandCreateRequest request)
    {
        var result = await _repo.CreateAsync(request);

        if (result.HasValue)
        {
            // Invalidate cache when creating new brand
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }

    public async Task<int?> UpdateAsync(BrandUpdateRequest request)
    {
        var result = await _repo.UpdateAsync(request);

        if (result.HasValue)
        {
            // Invalidate cache when updating brand
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }

    public async Task<int?> DeleteAsync(int brandId)
    {
        var result = await _repo.DeleteAsync(brandId);

        if (result.HasValue)
        {
            // Invalidate cache when deleting brand
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }
}
