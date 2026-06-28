using PC_Store.DTOs.Brands;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class BrandRepository : IBrandRepository
{
    private readonly IDbRepository _db;

    public BrandRepository(IDbRepository db) => _db = db;

    public Task<IEnumerable<BrandItem>> GetAllAsync(bool onlyActive)
        => _db.QueryAsync<BrandItem>("sp_Brand_GetAll", new { OnlyActive = onlyActive });

    public Task<BrandItem?> GetByIdAsync(int brandId)
        => _db.QuerySingleAsync<BrandItem>("sp_Brand_GetById", new { BrandId = brandId });

    public async Task<int?> CreateAsync(BrandCreateRequest request)
    {
        var r = await _db.QuerySingleAsync<NewIdResult>("sp_Brand_Create", new
        {
            request.BrandName, request.LogoUrl, request.Description, request.IsActive
        });
        return r?.NewBrandId;
    }

    public async Task<int?> UpdateAsync(BrandUpdateRequest request)
    {
        var r = await _db.QuerySingleAsync<UpdatedIdResult>("sp_Brand_Update", new
        {
            request.BrandId, request.BrandName, request.LogoUrl, request.Description, request.IsActive
        });
        return r?.UpdatedBrandId;
    }

    public async Task<int?> DeleteAsync(int brandId)
    {
        var r = await _db.QuerySingleAsync<DeletedIdResult>("sp_Brand_Delete", new { BrandId = brandId });
        return r?.DeletedBrandId;
    }

    private sealed record NewIdResult(int NewBrandId);
    private sealed record UpdatedIdResult(int UpdatedBrandId);
    private sealed record DeletedIdResult(int DeletedBrandId);
}
