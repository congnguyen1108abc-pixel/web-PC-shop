using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Warranty;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class WarrantyRepository : IWarrantyRepository
{
    private readonly IDbRepository _db;
    public WarrantyRepository(IDbRepository db) => _db = db;

    public Task CreateClaimAsync(CreateWarrantyClaimRequest request)
        => _db.ExecuteAsync("sp_Customer_CreateWarrantyClaim", new
        {
            request.WarrantyCode, request.UserId, request.Description, request.ImageUrl
        });

    public Task<IEnumerable<WarrantyItem>> GetWarrantiesAsync(int userId)
        => _db.QueryAsync<WarrantyItem>("sp_Customer_GetWarranties", new { UserId = userId });

    public Task<WarrantyItem?> GetByCodeAsync(string warrantyCode, int? userId)
        => _db.QuerySingleAsync<WarrantyItem>("sp_Warranty_GetByCode", new { WarrantyCode = warrantyCode, UserId = userId });

    public Task<IEnumerable<WarrantyClaimItem>> GetAdminClaimsAsync(WarrantyClaimQueryRequest request)
        => _db.QueryAsync<WarrantyClaimItem>("sp_Admin_GetWarrantyClaims", new
        {
            request.Status, request.UserId, request.WarrantyCode, request.DateFrom, request.DateTo
        });

    public Task ProcessClaimAsync(ProcessWarrantyClaimRequest request)
        => _db.ExecuteAsync("sp_Admin_ProcessWarrantyClaim", new
        {
            request.ClaimId, request.NewStatus, request.Resolution
        });
}
