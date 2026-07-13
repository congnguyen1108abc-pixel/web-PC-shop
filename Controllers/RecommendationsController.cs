using Microsoft.AspNetCore.Mvc;
using PC_Store.Repositories.Base;

namespace PC_Store.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public sealed class RecommendationsController : ControllerBase
    {
        private readonly IDbRepository _db;

        public RecommendationsController(IDbRepository db)
        {
            _db = db;
        }

        public sealed record RecommendedProductItem(
            int ProductId,
            string ProductName,
            decimal Price,
            decimal DiscountPrice,
            string Slug,
            string? DefaultImageUrl,
            decimal Score,
            decimal AvgRating,
            int ReviewCount
        );

        [HttpGet("homepage")]
        public async Task<ActionResult<IEnumerable<RecommendedProductItem>>> GetHomepageRecommendations([FromQuery] int topN = 8)
        {
            var result = await _db.QueryAsync<RecommendedProductItem>("sp_Recommendations_GetForHomepage", new { TopN = topN });
            return Ok(result);
        }

        [HttpGet("product/{productId:int}")]
        public async Task<ActionResult<IEnumerable<RecommendedProductItem>>> GetProductRecommendations(int productId, [FromQuery] int topN = 4)
        {
            var result = await _db.QueryAsync<RecommendedProductItem>("sp_Recommendations_GetForProduct", new { ProductID = productId, TopN = topN });
            return Ok(result);
        }
    }
}
