using PC_Store.DTOs.Brands;

namespace PC_Store.Services.Interfaces;

public interface IBrandService
{
    Task<IEnumerable<BrandItem>> GetAllAsync(bool onlyActive);
    Task<BrandItem?> GetByIdAsync(int brandId);
    Task<int?> CreateAsync(BrandCreateRequest request);
    Task<int?> UpdateAsync(BrandUpdateRequest request);
    Task<int?> DeleteAsync(int brandId);
}

