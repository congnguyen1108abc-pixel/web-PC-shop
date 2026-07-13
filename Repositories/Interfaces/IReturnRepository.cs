using System.Collections.Generic;
using System.Threading.Tasks;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;

namespace PC_Store.Repositories.Interfaces;

public interface IReturnRepository
{
    Task<int> CreateReturnRequestAsync(CustomerCreateReturnRequest request);
    Task<PagedResult<ReturnRequestListItem>> GetReturnRequestsAsync(string? status, int pageNumber, int pageSize);
    Task ProcessReturnRequestAsync(int returnId, string newStatus, string? adminNote);
    Task UpdateReturnTrackingCodeAsync(int returnId, string trackingCode);
    Task RestockInventoryAsync(int returnId, string? adminNote);
    Task CompleteRefundAsync(AdminCompleteRefundRequest request);
}
