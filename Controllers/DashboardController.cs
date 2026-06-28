using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Admin;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/[controller]")]
public sealed class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboard;

    public DashboardController(IDashboardService dashboard)
    {
        _dashboard = dashboard;
    }

    [HttpGet("summary")]
    public async Task<ActionResult<DashboardSummary>> GetSummary()
    {
        var result = await _dashboard.GetSummaryAsync();

        if (result is null)
            return NotFound(new { message = "Không có dữ liệu dashboard" });

        return Ok(result);
    }
}