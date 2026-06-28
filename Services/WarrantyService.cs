using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Warranty;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class WarrantyService : IWarrantyService
{
    private readonly IWarrantyRepository _repo;
    public WarrantyService(IWarrantyRepository repo) => _repo = repo;

    public Task CreateClaimAsync(CreateWarrantyClaimRequest request) => _repo.CreateClaimAsync(request);
    public Task<IEnumerable<WarrantyItem>> GetWarrantiesAsync(int userId) => _repo.GetWarrantiesAsync(userId);
    public Task<WarrantyItem?> GetByCodeAsync(string warrantyCode, int? userId) => _repo.GetByCodeAsync(warrantyCode, userId);
    public Task<IEnumerable<WarrantyClaimItem>> GetAdminClaimsAsync(WarrantyClaimQueryRequest request) => _repo.GetAdminClaimsAsync(request);
    public Task ProcessClaimAsync(ProcessWarrantyClaimRequest request) => _repo.ProcessClaimAsync(request);
}
