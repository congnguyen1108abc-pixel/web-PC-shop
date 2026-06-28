using PC_Store.DTOs.Categories;

namespace PC_Store.Services.Interfaces;

public interface ICategoryService
{
    Task<IEnumerable<CategoryItem>> GetAllAsync(bool onlyActive);
    Task<CategoryItem?> GetByIdAsync(int categoryId);
    Task<int?> CreateAsync(CategoryCreateRequest request);
    Task<int?> UpdateAsync(CategoryUpdateRequest request);
    Task<int?> DeleteAsync(int categoryId);
}

