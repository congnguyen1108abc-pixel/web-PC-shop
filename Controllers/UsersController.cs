using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Users;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public sealed class UsersController : ControllerBase
{
    private readonly IUserService _users;

    public UsersController(IUserService users)
    {
        _users = users;
    }

    [HttpGet("profile/{userId:int}")]
    public async Task<ActionResult<UserProfileItem>> GetProfile(int userId)
    {
        var result = await _users.GetProfileAsync(userId);

        if (result is null)
            return NotFound(new { message = "Không tìm thấy thông tin người dùng" });

        return Ok(result);
    }

    [HttpPut("profile")]
    public async Task<ActionResult> UpdateProfile(UpdateProfileRequest request)
    {
        var id = await _users.UpdateProfileAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật thông tin thất bại" });

        return Ok(new
        {
            message = "Cập nhật thông tin thành công",
            updatedUserId = id
        });
    }

    [HttpPut("bank")]
    public async Task<ActionResult> UpdateBank(UpdateBankRequest request)
    {
        var id = await _users.UpdateBankAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật tài khoản ngân hàng thất bại" });

        return Ok(new
        {
            message = "Cập nhật tài khoản ngân hàng thành công",
            updatedUserId = id
        });
    }

    [HttpGet("addresses/{userId:int}")]
    public async Task<ActionResult<IEnumerable<UserAddressItem>>> GetAddresses(int userId)
    {
        var result = await _users.GetAddressesAsync(userId);
        return Ok(result);
    }

    [EnableRateLimiting("write")]  // 30 req / phút / IP — chặn spam tạo địa chỉ
    [HttpPost("addresses")]
    public async Task<ActionResult> CreateAddress(UserAddressCreateRequest request)
    {
        var id = await _users.CreateAddressAsync(request);

        if (id is null)
            return BadRequest(new { message = "Thêm địa chỉ thất bại" });

        return Ok(new
        {
            message = "Thêm địa chỉ thành công",
            newAddressId = id
        });
    }

    [HttpPut("addresses")]
    public async Task<ActionResult> UpdateAddress(UserAddressUpdateRequest request)
    {
        var id = await _users.UpdateAddressAsync(request);

        if (id is null)
            return BadRequest(new { message = "Cập nhật địa chỉ thất bại" });

        return Ok(new
        {
            message = "Cập nhật địa chỉ thành công",
            updatedAddressId = id
        });
    }

    [HttpDelete("addresses")]
    public async Task<ActionResult> DeleteAddress([FromBody] UserAddressDeleteRequest request)
    {
        await _users.DeleteAddressAsync(request);

        return Ok(new
        {
            message = "Xóa địa chỉ thành công"
        });
    }
}