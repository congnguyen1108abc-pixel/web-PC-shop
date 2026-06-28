using PC_Store.DTOs.Categories;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class CategoryService : ICategoryService
{
    private readonly ICategoryRepository _repo;
    private readonly ICacheService _cache;

    private const string CacheKeyPrefix = "categories";
    private static readonly TimeSpan CacheExpiration = TimeSpan.FromMinutes(30);

    public CategoryService(ICategoryRepository repo, ICacheService cache)
    {
        _repo = repo;
        _cache = cache;
    }

    public async Task<IEnumerable<CategoryItem>> GetAllAsync(bool onlyActive)
    {
        var cacheKey = $"{CacheKeyPrefix}:all:{onlyActive}";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: () => _repo.GetAllAsync(onlyActive),
            expiration: CacheExpiration
        );

        return result ?? Enumerable.Empty<CategoryItem>();
    }

    public Task<CategoryItem?> GetByIdAsync(int categoryId) => _repo.GetByIdAsync(categoryId);

    public async Task<int?> CreateAsync(CategoryCreateRequest request)
    {
        var result = await _repo.CreateAsync(request);

        if (result.HasValue)
        {
            // Invalidate cache when creating new category
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }

    public async Task<int?> UpdateAsync(CategoryUpdateRequest request)
    {
        var result = await _repo.UpdateAsync(request);

        if (result.HasValue)
        {
            // Invalidate cache when updating category
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }

    public async Task<int?> DeleteAsync(int categoryId)
    {
        var result = await _repo.DeleteAsync(categoryId);

        if (result.HasValue)
        {
            // Invalidate cache when deleting category
            _cache.RemoveByPrefix(CacheKeyPrefix);
        }

        return result;
    }
}
