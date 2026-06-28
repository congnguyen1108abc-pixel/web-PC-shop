using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Banners;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class BannerRepository : IBannerRepository
{
    private readonly IDbRepository _db;

    public BannerRepository(IDbRepository db) => _db = db;

    public Task<IEnumerable<BannerItem>> GetActiveAsync()
        => _db.QueryAsync<BannerItem>("sp_Banner_GetActive");

    public Task<IEnumerable<BannerItem>> GetAdminBannersAsync()
        => _db.QueryAsync<BannerItem>("sp_Admin_GetBanners");

    public Task UpsertAsync(UpsertBannerRequest request)
        => _db.ExecuteAsync("sp_Admin_UpsertBanner", new
        {
            request.BannerId, request.Title, request.ImageUrl, request.LinkUrl,
            request.DisplayOrder, request.StartDate, request.EndDate, request.IsActive
        });

    public async Task<int?> DeleteAsync(int bannerId)
    {
        var r = await _db.QuerySingleAsync<DeletedIdResult>("sp_Banner_Delete", new { BannerId = bannerId });
        return r?.DeletedBannerId;
    }

    private sealed record DeletedIdResult(int DeletedBannerId);
}
