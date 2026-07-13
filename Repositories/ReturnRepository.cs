using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class ReturnRepository : IReturnRepository
{
    private readonly IDbRepository _db;

    public ReturnRepository(IDbRepository db)
    {
        _db = db;
    }

    public async Task<int> CreateReturnRequestAsync(CustomerCreateReturnRequest request)
    {
        // SCOPE_IDENTITY() trả về decimal — dùng ExecuteScalarAsync<decimal>
        var newId = await _db.ExecuteScalarAsync<decimal>("sp_Customer_CreateReturnRequest", new
        {
            request.OrderId,
            request.UserId,
            request.Reason,
            request.EvidenceImages,
            request.RefundAmount,
            request.RefundBankName,
            request.RefundAccountNo,
            request.RefundAccountName,
            request.ReturnAddress,
            request.ReturnWardCode,
            request.ReturnDistrictId
        });
        return (int)newId;
    }

    public async Task<PagedResult<ReturnRequestListItem>> GetReturnRequestsAsync(string? status, int pageNumber, int pageSize)
    {
        var items = await _db.QueryAsync<ReturnRequestListItem>("sp_Admin_GetReturnRequestsPaged", new
        {
            Status = status,
            PageNumber = pageNumber,
            PageSize = pageSize
        });

        var itemsList = items.ToList();
        var totalRecords = itemsList.FirstOrDefault()?.TotalRecords ?? 0;

        return new PagedResult<ReturnRequestListItem>(
            items: itemsList,
            totalRecords: totalRecords,
            pageNumber: pageNumber,
            pageSize: pageSize
        );
    }

    public Task ProcessReturnRequestAsync(int returnId, string newStatus, string? adminNote)
        => _db.ExecuteAsync("sp_Admin_ProcessReturnRequest", new
        {
            ReturnID = returnId,
            NewStatus = newStatus,
            AdminNote = adminNote
        });

    public Task UpdateReturnTrackingCodeAsync(int returnId, string trackingCode)
        => _db.ExecuteAsync("sp_Admin_UpdateReturnTrackingCode", new
        {
            ReturnID = returnId,
            TrackingCode = trackingCode
        });

    public Task RestockInventoryAsync(int returnId, string? adminNote)
        => _db.ExecuteAsync("sp_Inventory_RestockOnReturn", new
        {
            ReturnID = returnId,
            AdminNote = adminNote
        });

    public Task CompleteRefundAsync(AdminCompleteRefundRequest request)
        => _db.ExecuteAsync("sp_Admin_CompleteRefund", new
        {
            ReturnID = request.ReturnId,
            request.PaymentMethod,
            request.TransactionNo,
            request.AdminNote
        });

}
