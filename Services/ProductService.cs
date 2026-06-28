using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Products;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class ProductService : IProductService
{
    private readonly IProductRepository _repo;
    private readonly ICacheService _cache;

    private const string CacheKeyPrefix = "products";
    private static readonly TimeSpan TopSellingCacheExpiration = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan ProductDetailCacheExpiration = TimeSpan.FromMinutes(5);

    public ProductService(IProductRepository repo, ICacheService cache)
    {
        _repo = repo;
        _cache = cache;
    }

    public Task<PagedResult<ProductListItem>> GetAllAsync(ProductQueryRequest request) => _repo.GetAllAsync(request);

    public async Task<(ProductDetailHeader?, IEnumerable<ProductImageItem>, IEnumerable<ProductAttributeItem>)> GetByIdAsync(int productId)
    {
        var cacheKey = $"{CacheKeyPrefix}:detail:{productId}";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: async () =>
            {
                var data = await _repo.GetByIdAsync(productId);
                // Wrap tuple in a class for caching (tuples can't be cached directly as class constraint)
                return new ProductDetailCache(data.Header, data.Images, data.Attributes);
            },
            expiration: ProductDetailCacheExpiration
        );

        if (result is null)
        {
            return (null, Enumerable.Empty<ProductImageItem>(), Enumerable.Empty<ProductAttributeItem>());
        }

        return (result.Header, result.Images, result.Attributes);
    }

    public async Task<(ProductDetailHeader?, IEnumerable<ProductImageItem>, IEnumerable<ProductAttributeItem>)> GetBySlugAsync(string slug)
    {
        var cacheKey = $"{CacheKeyPrefix}:detail:slug:{slug}";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: async () =>
            {
                var data = await _repo.GetBySlugAsync(slug);
                return new ProductDetailCache(data.Header, data.Images, data.Attributes);
            },
            expiration: ProductDetailCacheExpiration
        );

        if (result is null)
        {
            return (null, Enumerable.Empty<ProductImageItem>(), Enumerable.Empty<ProductAttributeItem>());
        }

        return (result.Header, result.Images, result.Attributes);
    }

    private void InvalidateDetailCache(int productId)
    {
        _cache.Remove($"{CacheKeyPrefix}:detail:{productId}");
        _cache.RemoveByPrefix($"{CacheKeyPrefix}:detail:slug");
    }

    public async Task<int?> CreateAsync(ProductCreateRequest request)
    {
        var result = await _repo.CreateAsync(request);

        if (result.HasValue)
        {
            // Invalidate top-selling and slug caches when creating new product
            _cache.RemoveByPrefix($"{CacheKeyPrefix}:detail:slug");
            _cache.RemoveByPrefix($"{CacheKeyPrefix}:top-selling");
        }

        return result;
    }

    public async Task<int?> UpdateAsync(ProductUpdateRequest request)
    {
        var result = await _repo.UpdateAsync(request);

        if (result.HasValue)
        {
            // Invalidate product detail and top-selling cache
            InvalidateDetailCache(request.ProductId);
            _cache.RemoveByPrefix($"{CacheKeyPrefix}:top-selling");
        }

        return result;
    }

    public async Task<int?> DeleteAsync(int productId)
    {
        var result = await _repo.DeleteAsync(productId);

        if (result.HasValue)
        {
            // Invalidate product detail and top-selling cache
            InvalidateDetailCache(productId);
            _cache.RemoveByPrefix($"{CacheKeyPrefix}:top-selling");
        }

        return result;
    }

    public Task<IEnumerable<ProductReviewItem>> GetReviewsAsync(int productId) => _repo.GetReviewsAsync(productId);

    public async Task<int?> AddImageAsync(ProductImageRequest request)
    {
        var result = await _repo.AddImageAsync(request);

        if (result.HasValue)
        {
            // Invalidate product detail cache
            InvalidateDetailCache(request.ProductId);
        }

        return result;
    }

    public async Task<int?> UpdateImageAsync(ProductImageUpdateRequest request)
    {
        var result = await _repo.UpdateImageAsync(request);

        if (result.HasValue)
        {
            // Invalidate product detail cache
            InvalidateDetailCache(request.ProductId);
        }

        return result;
    }

    public async Task DeleteImageAsync(ProductImageDeleteRequest request)
    {
        await _repo.DeleteImageAsync(request);

        // Invalidate product detail cache
        InvalidateDetailCache(request.ProductId);
    }

    public async Task<int?> AddAttributeAsync(ProductAttributeRequest request)
    {
        var result = await _repo.AddAttributeAsync(request);

        if (result.HasValue)
        {
            // Invalidate product detail cache
            InvalidateDetailCache(request.ProductId);
        }

        return result;
    }

    public async Task<int?> UpdateAttributeAsync(ProductAttributeUpdateRequest request)
    {
        var result = await _repo.UpdateAttributeAsync(request);

        if (result.HasValue)
        {
            // Invalidate product detail cache
            InvalidateDetailCache(request.ProductId);
        }

        return result;
    }

    public async Task DeleteAttributeAsync(ProductAttributeDeleteRequest request)
    {
        await _repo.DeleteAttributeAsync(request);

        // Invalidate product detail cache
        InvalidateDetailCache(request.ProductId);
    }

    public async Task<IEnumerable<TopSellingItem>> GetTopSellingAsync(TopSellingRequest request)
    {
        var cacheKey = $"{CacheKeyPrefix}:top-selling:{request.TopN}";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: () => _repo.GetTopSellingAsync(request),
            expiration: TopSellingCacheExpiration
        );

        return result ?? Enumerable.Empty<TopSellingItem>();
    }

    public Task<IEnumerable<InventoryLogItem>> GetInventoryLogAsync(InventoryLogQueryRequest request) => _repo.GetInventoryLogAsync(request);
    public Task<IEnumerable<LowStockItem>> GetLowStockAsync(LowStockAlertRequest request) => _repo.GetLowStockAsync(request);

    public async Task ImportStockAsync(ImportStockRequest request)
    {
        await _repo.ImportStockAsync(request);

        // Invalidate product detail cache when stock changes
        InvalidateDetailCache(request.ProductId);
    }

    // Helper class to cache product detail tuple
    private sealed class ProductDetailCache
    {
        public ProductDetailHeader? Header { get; }
        public IEnumerable<ProductImageItem> Images { get; }
        public IEnumerable<ProductAttributeItem> Attributes { get; }

        public ProductDetailCache(
            ProductDetailHeader? header,
            IEnumerable<ProductImageItem> images,
            IEnumerable<ProductAttributeItem> attributes)
        {
            Header = header;
            Images = images;
            Attributes = attributes;
        }
    }
}
