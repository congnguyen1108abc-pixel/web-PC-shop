using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Warranty;

namespace PC_Store.Services.Interfaces;

public interface IWarrantyService
{
    Task CreateClaimAsync(CreateWarrantyClaimRequest request);
    Task<IEnumerable<WarrantyItem>> GetWarrantiesAsync(int userId);
    Task<WarrantyItem?> GetByCodeAsync(string warrantyCode, int? userId);
    Task<IEnumerable<WarrantyClaimItem>> GetAdminClaimsAsync(WarrantyClaimQueryRequest request);
    Task ProcessClaimAsync(ProcessWarrantyClaimRequest request);
}

