using System.Threading.Tasks;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;

namespace PC_Store.Services.Interfaces;

public interface IReturnService
{
    Task<int> CreateReturnRequestAsync(CustomerCreateReturnRequest request);
    Task<PagedResult<ReturnRequestListItem>> GetReturnRequestsAsync(string? status, int pageNumber, int pageSize);
    Task<bool> ApproveReturnRequestAsync(int returnId, string? adminNote);
    Task RejectReturnRequestAsync(int returnId, string? adminNote);
    Task RestockReturnRequestAsync(int returnId, string? adminNote);
    Task CompleteRefundAsync(AdminCompleteRefundRequest request);
}
