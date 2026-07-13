using System;
using System.Linq;
using System.Threading.Tasks;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Orders;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class ReturnService : IReturnService
{
    private readonly IReturnRepository _repo;
    private readonly IOrderRepository _orderRepo;
    private readonly IGhnService _ghn;

    public ReturnService(IReturnRepository repo, IOrderRepository orderRepo, IGhnService ghn)
    {
        _repo = repo;
        _orderRepo = orderRepo;
        _ghn = ghn;
    }

    public Task<int> CreateReturnRequestAsync(CustomerCreateReturnRequest request)
        => _repo.CreateReturnRequestAsync(request);

    public Task<PagedResult<ReturnRequestListItem>> GetReturnRequestsAsync(string? status, int pageNumber, int pageSize)
        => _repo.GetReturnRequestsAsync(status, pageNumber, pageSize);

    public async Task<bool> ApproveReturnRequestAsync(int returnId, string? adminNote)
    {
        // Lấy thông tin yêu cầu đổi trả
        var result = await _repo.GetReturnRequestsAsync(null, 1, 1000);
        var req = result.Items.FirstOrDefault(x => x.ReturnId == returnId);
        if (req == null) return false;

        // Tạo đơn vận chuyển thu hồi ảo trên GHN Sandbox
        var trackingCode = await _ghn.CreateReturnOrderAsync(
            returnId: returnId,
            customerName: req.FullName,
            customerPhone: "0345469863", // Số điện thoại liên hệ shipper lấy hàng
            customerAddress: req.ReturnAddress ?? "Địa chỉ thu hồi hàng",
            customerWardCode: req.ReturnWardCode ?? "21910",
            customerDistrictId: req.ReturnDistrictId ?? 1458,
            weightGrams: 2000
        );

        if (!string.IsNullOrEmpty(trackingCode))
        {
            // Cập nhật trạng thái đổi trả thành 'Picking' và lưu mã vận đơn trả
            await _repo.UpdateReturnTrackingCodeAsync(returnId, trackingCode);
            await _repo.ProcessReturnRequestAsync(returnId, "Picking", adminNote);
            return true;
        }

        // Nếu tạo đơn GHN lỗi, vẫn duyệt đơn đổi trả dưới dạng Approved thủ công
        await _repo.ProcessReturnRequestAsync(returnId, "Approved", adminNote);
        return true;
    }

    public Task RejectReturnRequestAsync(int returnId, string? adminNote)
        => _repo.ProcessReturnRequestAsync(returnId, "Rejected", adminNote);

    public Task RestockReturnRequestAsync(int returnId, string? adminNote)
        => _repo.RestockInventoryAsync(returnId, adminNote);

    public Task CompleteRefundAsync(AdminCompleteRefundRequest request)
        => _repo.CompleteRefundAsync(request);
}
