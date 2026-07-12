using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Products;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class ProductRepository : IProductRepository
{
    private readonly IDbRepository _db;

    public ProductRepository(IDbRepository db) => _db = db;

    public async Task<PagedResult<ProductListItem>> GetAllAsync(ProductQueryRequest request)
    {
        // Normalize pagination parameters
        var normalized = request.Normalize();
        
        var items = await _db.QueryAsync<ProductListItemWithTotal>("sp_Product_GetAllPaged", new
        {
            CategoryId = normalized.CategoryId,
            BrandId = normalized.BrandId,
            Keyword = normalized.Keyword,
            MinPrice = normalized.MinPrice,
            MaxPrice = normalized.MaxPrice,
            OnlyActive = normalized.OnlyActive,
            SortBy = normalized.SortBy,
            PageNumber = normalized.PageNumber,
            PageSize = normalized.PageSize
        });

        var itemsList = items.ToList();
        var totalRecords = itemsList.FirstOrDefault()?.TotalRecords ?? 0;

        return new PagedResult<ProductListItem>(
            items: itemsList.Select(x => new ProductListItem(
                x.ProductId, x.CategoryId, x.CategoryName, x.BrandId, x.BrandName,
                x.SKU, x.ProductName, x.Price, x.DiscountPrice, x.EffectivePrice,
                x.StockQuantity, x.SoldCount, x.Description, x.IsActive,
                x.WarrantyMonths, x.Slug, x.CreatedAt, x.UpdatedAt, x.DefaultImageUrl,
                x.AvgRating, x.ReviewCount
            )),
            totalRecords: totalRecords,
            pageNumber: normalized.PageNumber,
            pageSize: normalized.PageSize
        );
    }

    public async Task<(ProductDetailHeader? Header, IEnumerable<ProductImageItem> Images, IEnumerable<ProductAttributeItem> Attributes)> GetByIdAsync(int productId)
    {
        await using var multi = await _db.QueryMultipleAsync("sp_Product_GetById", new { ProductId = productId });
        var header = await multi.ReadFirstOrDefaultAsync<ProductDetailHeader>();
        var images = await multi.ReadAsync<ProductImageItem>();
        var attributes = await multi.ReadAsync<ProductAttributeItem>();
        return (header, images, attributes);
    }

    public async Task<(ProductDetailHeader? Header, IEnumerable<ProductImageItem> Images, IEnumerable<ProductAttributeItem> Attributes)> GetBySlugAsync(string slug)
    {
        await using var multi = await _db.QueryMultipleAsync("sp_Product_GetBySlug", new { Slug = slug });
        var header = await multi.ReadFirstOrDefaultAsync<ProductDetailHeader>();
        var images = await multi.ReadAsync<ProductImageItem>();
        var attributes = await multi.ReadAsync<ProductAttributeItem>();
        return (header, images, attributes);
    }

    public async Task<int?> CreateAsync(ProductCreateRequest request)
    {
        var r = await _db.QuerySingleAsync<NewIdResult>("sp_Product_Create", new
        {
            request.CategoryId, request.BrandId, request.SKU, request.ProductName,
            request.Price, request.DiscountPrice, request.StockQuantity,
            request.Description, request.WarrantyMonths, request.IsActive
        });
        return r?.NewProductId;
    }

    public async Task<int?> UpdateAsync(ProductUpdateRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedIdResult>("sp_Product_Update", new
        {
            request.ProductId, request.CategoryId, request.BrandId, request.SKU, request.ProductName,
            request.Price, request.DiscountPrice, request.StockQuantity,
            request.Description, request.WarrantyMonths, request.IsActive
        });
        return r?.UpdatedProductId;
    }

    public async Task<int?> DeleteAsync(int productId)
    {
        var r = await _db.QuerySingleAsync<DeletedIdResult>("sp_Product_Delete", new { ProductId = productId });
        return r?.DeletedProductId;
    }

    public Task<IEnumerable<ProductReviewItem>> GetReviewsAsync(int productId)
        => _db.QueryAsync<ProductReviewItem>("sp_Product_GetReviews", new { ProductId = productId });

    public async Task<int?> AddImageAsync(ProductImageRequest request)
    {
        var r = await _db.QuerySingleAsync<NewImageIdResult>("sp_Product_AddImage", new
        {
            request.ProductId, request.ImageUrl, request.AltText, request.SortOrder, request.IsDefault
        });
        return r?.NewImageId;
    }

    public async Task<int?> UpdateImageAsync(ProductImageUpdateRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedImageIdResult>("sp_Product_UpdateImage", new
        {
            request.ImageId, request.ProductId, request.ImageUrl, request.AltText, request.SortOrder, request.IsDefault
        });
        return r?.UpdatedImageId;
    }

    public Task DeleteImageAsync(ProductImageDeleteRequest request)
        => _db.ExecuteAsync("sp_Product_DeleteImage", new { request.ImageId, request.ProductId });

    public async Task<int?> AddAttributeAsync(ProductAttributeRequest request)
    {
        var r = await _db.QuerySingleAsync<NewAttrIdResult>("sp_Product_AddAttribute", new
        {
            request.ProductId, request.AttributeName, request.AttributeValue, request.SortOrder
        });
        return r?.NewAttributeId;
    }

    public async Task<int?> UpdateAttributeAsync(ProductAttributeUpdateRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedAttrIdResult>("sp_Product_UpdateAttribute", new
        {
            request.AttrId, request.ProductId, request.AttributeName, request.AttributeValue, request.SortOrder
        });
        return r?.UpdatedAttributeId;
    }

    public Task DeleteAttributeAsync(ProductAttributeDeleteRequest request)
        => _db.ExecuteAsync("sp_Product_DeleteAttribute", new { request.AttrId, request.ProductId });

    public Task<IEnumerable<TopSellingItem>> GetTopSellingAsync(TopSellingRequest request)
        => _db.QueryAsync<TopSellingItem>("sp_Admin_GetTopSellingProducts", new
        {
            request.TopN, request.StartDate, request.EndDate
        });

    public Task<IEnumerable<InventoryLogItem>> GetInventoryLogAsync(InventoryLogQueryRequest request)
        => _db.QueryAsync<InventoryLogItem>("sp_Admin_GetInventoryLog", new
        {
            request.ProductId, request.LogType, request.RelatedOrderId, request.DateFrom, request.DateTo
        });

    public Task<IEnumerable<LowStockItem>> GetLowStockAsync(LowStockAlertRequest request)
        => _db.QueryAsync<LowStockItem>("sp_Admin_GetLowStockAlert", new { request.Threshold });

    public Task ImportStockAsync(ImportStockRequest request)
        => _db.ExecuteAsync("sp_Admin_ImportStock", new
        {
            request.ProductId, request.QuantityToAdd, request.Note
        });

    private sealed record NewIdResult(int NewProductId);
    private sealed record UpdatedIdResult(int UpdatedProductId);
    private sealed record DeletedIdResult(int DeletedProductId);
    private sealed record NewImageIdResult(int NewImageId);
    private sealed record UpdatedImageIdResult(int UpdatedImageId);
    private sealed record NewAttrIdResult(int NewAttributeId);
    private sealed record UpdatedAttrIdResult(int UpdatedAttributeId);

    // Helper record để nhận TotalRecords từ SQL
    private sealed record ProductListItemWithTotal
    {
        public int ProductId { get; init; }
        public int CategoryId { get; init; }
        public string? CategoryName { get; init; }
        public int BrandId { get; init; }
        public string? BrandName { get; init; }
        public string SKU { get; init; } = null!;
        public string ProductName { get; init; } = null!;
        public decimal Price { get; init; }
        public decimal DiscountPrice { get; init; }
        public decimal EffectivePrice { get; init; }
        public int StockQuantity { get; init; }
        public int SoldCount { get; init; }
        public string? Description { get; init; }
        public bool IsActive { get; init; }
        public int WarrantyMonths { get; init; }
        public string? Slug { get; init; }
        public DateTime CreatedAt { get; init; }
        public DateTime? UpdatedAt { get; init; }
        public string? DefaultImageUrl { get; init; }
        public decimal AvgRating { get; init; }
        public int ReviewCount { get; init; }
        public int TotalRecords { get; init; }
    }
}
