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
            BannerID = request.BannerId,
            Title = request.Title,
            ImageURL = request.ImageUrl,
            LinkURL = request.LinkUrl,
            DisplayOrder = request.DisplayOrder,
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            IsActive = request.IsActive
        });

    public async Task<int?> DeleteAsync(int bannerId)
    {
        var r = await _db.QuerySingleAsync<DeletedIdResult>("sp_Banner_Delete", new { BannerID = bannerId });
        return r?.DeletedBannerId;
    }

    private sealed record DeletedIdResult(int DeletedBannerId);
}
