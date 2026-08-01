using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.Repositories.Base;
using PC_Store.DTOs.Products;

namespace PC_Store.Controllers;

[Route("api/[controller]")]
[ApiController]
public class GamingGearController : ControllerBase
{
    private readonly IDbRepository _db;

    public GamingGearController(IDbRepository db)
    {
        _db = db;
    }

    [AllowAnonymous]
    [HttpGet("categories")]
    public async Task<ActionResult> GetCategories()
    {
        var sql = @"
            SELECT 
                pa.AttributeValue AS [name],
                COUNT(p.ProductID) AS [count]
            FROM Products p
            JOIN Categories c ON p.CategoryID = c.CategoryID
            JOIN ProductAttributes pa ON p.ProductID = pa.ProductID
            WHERE c.CategoryName LIKE N'%Gaming Gear%' 
              AND pa.AttributeName = 'ProductType'
              AND p.IsActive = 1
            GROUP BY pa.AttributeValue
            ORDER BY [count] DESC
        ";
        var result = await _db.QueryRawAsync<dynamic>(sql);
        return Ok(result);
    }

    [AllowAnonymous]
    [HttpGet("products")]
    public async Task<ActionResult> GetProducts([FromQuery] string subcategory)
    {
        if (string.IsNullOrWhiteSpace(subcategory))
            return BadRequest(new { message = "Subcategory is required" });

        var sql = @"
            SELECT 
                p.ProductID,
                p.CategoryID,
                c.CategoryName,
                p.BrandID,
                b.BrandName,
                p.SKU,
                p.ProductName,
                p.Price,
                p.DiscountPrice,
                p.CostPrice,
                CAST(
                    CASE 
                        WHEN activePromo.DiscountType = 'Percentage' THEN p.Price * (1.0 - activePromo.DiscountValue / 100.0)
                        WHEN activePromo.DiscountType = 'FixedAmount' THEN CASE WHEN p.Price - activePromo.DiscountValue < 0 THEN 0 ELSE p.Price - activePromo.DiscountValue END
                        ELSE COALESCE(NULLIF(p.DiscountPrice, 0), p.Price)
                    END AS DECIMAL(18,2)
                ) AS EffectivePrice,
                p.StockQuantity,
                p.SoldCount,
                p.Description,
                p.IsActive,
                p.WarrantyMonths,
                p.Slug,
                p.CreatedAt,
                p.UpdatedAt,
                (SELECT TOP 1 ImageUrl FROM ProductImages pi WHERE pi.ProductID = p.ProductID AND pi.IsDefault = 1) AS DefaultImageUrl,
                ISNULL((SELECT AVG(CAST(Rating AS DECIMAL(3,1))) FROM Reviews r WHERE r.ProductID = p.ProductID AND r.IsApproved = 1), 0) AS AvgRating,
                ISNULL((SELECT COUNT(*) FROM Reviews r WHERE r.ProductID = p.ProductID AND r.IsApproved = 1), 0) AS ReviewCount,
                pa.AttributeValue AS ProductType
            FROM Products p
            JOIN Categories c ON p.CategoryID = c.CategoryID
            LEFT JOIN Brands b ON p.BrandID = b.BrandID
            JOIN ProductAttributes pa ON p.ProductID = pa.ProductID
            OUTER APPLY (
                SELECT TOP 1 pp.DiscountType, pp.DiscountValue
                FROM ProductPromotions pp
                WHERE pp.ProductID = p.ProductID
                  AND pp.Status = 'Active'
                  AND pp.StartDate <= GETDATE()
                  AND pp.EndDate >= GETDATE()
                ORDER BY pp.CreatedAt DESC
            ) activePromo
            WHERE c.CategoryName LIKE N'%Gaming Gear%' 
              AND pa.AttributeName = 'ProductType'
              AND LOWER(pa.AttributeValue) = LOWER(@SubCategory)
              AND p.IsActive = 1
        ";
        var items = await _db.QueryRawAsync<dynamic>(sql, new { SubCategory = subcategory });
        return Ok(new { items });
    }
}
