using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Vouchers;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class VouchersController : ControllerBase
{
    private readonly IVoucherService _vouchers;

    public VouchersController(IVoucherService vouchers)
    {
        _vouchers = vouchers;
    }

    // ── Admin APIs ────────────────────────────────────────────────────────────
    // Chỉ Admin được xem toàn bộ voucher, thêm, sửa, xóa voucher.

    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<ActionResult<IEnumerable<VoucherItem>>> GetAll(
        [FromQuery] VoucherQueryRequest request)
    {
        var result = await _vouchers.GetAllAsync(request);
        return Ok(result);
    }

    // ── Customer APIs ─────────────────────────────────────────────────────────
    // User phải đăng nhập mới xem voucher có thể dùng cho đơn hàng của mình.

    [Authorize]
    [HttpGet("available")]
    public async Task<ActionResult<IEnumerable<VoucherAvailableItem>>> GetAvailable(
        [FromQuery] VoucherAvailableRequest request)
    {
        var result = await _vouchers.GetAvailableAsync(request);
        return Ok(result);
    }

    // ── Voucher Management APIs ───────────────────────────────────────────────
    // Chỉ Admin được thêm/sửa/xóa voucher.

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<ActionResult> Create([FromBody] VoucherCreateRequest request)
    {
        var code = await _vouchers.CreateAsync(request);

        if (code is null)
            return BadRequest(new { message = "Thêm voucher thất bại" });

        return Ok(new
        {
            message = "Thêm voucher thành công",
            newVoucherCode = code
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpPut]
    public async Task<ActionResult> Update([FromBody] VoucherUpdateRequest request)
    {
        var code = await _vouchers.UpdateAsync(request);

        if (code is null)
            return BadRequest(new { message = "Cập nhật voucher thất bại" });

        return Ok(new
        {
            message = "Cập nhật voucher thành công",
            updatedVoucherCode = code
        });
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete("{voucherCode}")]
    public async Task<ActionResult> Delete(string voucherCode)
    {
        var code = await _vouchers.DeleteAsync(voucherCode);

        if (code is null)
            return BadRequest(new { message = "Xóa voucher thất bại" });

        return Ok(new
        {
            message = "Xóa voucher thành công",
            deletedVoucherCode = code
        });
    }
}