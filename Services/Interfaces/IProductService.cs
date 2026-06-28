using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Products;

namespace PC_Store.Services.Interfaces;

public interface IProductService
{
    Task<PagedResult<ProductListItem>> GetAllAsync(ProductQueryRequest request);
    Task<(ProductDetailHeader? Header, IEnumerable<ProductImageItem> Images, IEnumerable<ProductAttributeItem> Attributes)> GetByIdAsync(int productId);
    Task<(ProductDetailHeader? Header, IEnumerable<ProductImageItem> Images, IEnumerable<ProductAttributeItem> Attributes)> GetBySlugAsync(string slug);
    Task<int?> CreateAsync(ProductCreateRequest request);
    Task<int?> UpdateAsync(ProductUpdateRequest request);
    Task<int?> DeleteAsync(int productId);
    Task<IEnumerable<ProductReviewItem>> GetReviewsAsync(int productId);
    Task<int?> AddImageAsync(ProductImageRequest request);
    Task<int?> UpdateImageAsync(ProductImageUpdateRequest request);
    Task DeleteImageAsync(ProductImageDeleteRequest request);
    Task<int?> AddAttributeAsync(ProductAttributeRequest request);
    Task<int?> UpdateAttributeAsync(ProductAttributeUpdateRequest request);
    Task DeleteAttributeAsync(ProductAttributeDeleteRequest request);
    Task<IEnumerable<TopSellingItem>> GetTopSellingAsync(TopSellingRequest request);
    Task<IEnumerable<InventoryLogItem>> GetInventoryLogAsync(InventoryLogQueryRequest request);
    Task<IEnumerable<LowStockItem>> GetLowStockAsync(LowStockAlertRequest request);
    Task ImportStockAsync(ImportStockRequest request);
}
