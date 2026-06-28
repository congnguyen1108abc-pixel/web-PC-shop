using PC_Store.DTOs.Categories;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class CategoryRepository : ICategoryRepository
{
    private readonly IDbRepository _db;

    public CategoryRepository(IDbRepository db) => _db = db;

    public Task<IEnumerable<CategoryItem>> GetAllAsync(bool onlyActive)
        => _db.QueryAsync<CategoryItem>("sp_Category_GetAll", new { OnlyActive = onlyActive });

    public Task<CategoryItem?> GetByIdAsync(int categoryId)
        => _db.QuerySingleAsync<CategoryItem>("sp_Category_GetById", new { CategoryId = categoryId });

    public async Task<int?> CreateAsync(CategoryCreateRequest request)
    {
        var r = await _db.QuerySingleAsync<NewIdResult>("sp_Category_Create", new
        {
            request.CategoryName, request.ParentId, request.IconUrl, request.SortOrder, request.IsActive
        });
        return r?.NewCategoryId;
    }

    public async Task<int?> UpdateAsync(CategoryUpdateRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedIdResult>("sp_Category_Update", new
        {
            request.CategoryId, request.CategoryName, request.ParentId, request.IconUrl, request.SortOrder, request.IsActive
        });
        return r?.UpdatedCategoryId;
    }

    public async Task<int?> DeleteAsync(int categoryId)
    {
        var r = await _db.QuerySingleAsync<DeletedIdResult>("sp_Category_Delete", new { CategoryId = categoryId });
        return r?.DeletedCategoryId;
    }

    private sealed record NewIdResult(int NewCategoryId);
    private sealed record UpdatedIdResult(int UpdatedCategoryId);
    private sealed record DeletedIdResult(int DeletedCategoryId);
}
