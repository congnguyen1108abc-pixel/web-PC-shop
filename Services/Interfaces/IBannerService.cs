using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Banners;

namespace PC_Store.Services.Interfaces;

public interface IBannerService
{
    Task<IEnumerable<BannerItem>> GetActiveAsync();
    Task<IEnumerable<BannerItem>> GetAdminBannersAsync();
    Task UpsertAsync(UpsertBannerRequest request);
    Task<int?> DeleteAsync(int bannerId);
}
