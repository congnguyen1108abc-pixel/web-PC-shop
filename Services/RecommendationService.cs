using PC_Store.DTOs.Recommendations;
using PC_Store.Repositories;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class RecommendationService : IRecommendationService
{
    private readonly RecommendationDAO _dao;
    private readonly AprioriAlgorithm _apriori;

    public RecommendationService(RecommendationDAO dao, AprioriAlgorithm apriori)
    {
        _dao = dao;
        _apriori = apriori;
    }

    public async Task<IReadOnlyList<RecommendationResult>> GetRecommendationsAsync(int productId, int topN = 8)
    {
        topN = Math.Clamp(topN, 1, 8);

        var transactions = await _dao.GetCompletedTransactionsAsync();
        if (transactions.Count == 0)
        {
            return Array.Empty<RecommendationResult>();
        }

        var totalTransactions = transactions.Count;
        var currentProductSupportCount = transactions.Count(transaction => transaction.ProductIds.Contains(productId));
        if (currentProductSupportCount == 0)
        {
            return Array.Empty<RecommendationResult>();
        }

        var minSupportCount = Math.Max(2, (int)Math.Ceiling(totalTransactions * 0.02m));
        var frequentItemsets = _apriori.FindFrequentItemsets(transactions, minSupportCount, maxItemsetSize: 3);

        var candidateIds = frequentItemsets
            .Where(itemset => itemset.Count == 2 && itemset.Contains(productId))
            .SelectMany(itemset => itemset)
            .Where(itemsetProductId => itemsetProductId != productId)
            .Distinct()
            .ToList();

        if (candidateIds.Count == 0)
        {
            return Array.Empty<RecommendationResult>();
        }

        var productRows = await _dao.GetProductsByIdsAsync(candidateIds);
        if (productRows.Count == 0)
        {
            return Array.Empty<RecommendationResult>();
        }

        var productLookup = productRows.ToDictionary(row => row.ProductId);
        var statsByProduct = candidateIds.ToDictionary(id => id, _ => new RecommendationStats());

        foreach (var candidateId in candidateIds)
        {
            var matchingTransactions = transactions.Where(transaction =>
                transaction.ProductIds.Contains(productId) && transaction.ProductIds.Contains(candidateId)).ToList();

            var pairCount = matchingTransactions.Count;
            if (pairCount < minSupportCount)
            {
                continue;
            }

            var support = (double)pairCount / totalTransactions;
            var confidence = (double)pairCount / currentProductSupportCount;
            var utility = matchingTransactions.Sum(transaction =>
                transaction.Items
                    .Where(item => item.ProductId == candidateId)
                    .Sum(item => item.Utility));

            var stats = statsByProduct[candidateId];
            stats.Support = Math.Max(stats.Support, support);
            stats.Confidence = Math.Max(stats.Confidence, confidence);
            stats.Utility += utility;
        }

        var results = candidateIds
            .Select(candidateId =>
            {
                if (!productLookup.TryGetValue(candidateId, out var row))
                {
                    return null;
                }

                var stats = statsByProduct[candidateId];
                if (stats.Utility <= 0)
                {
                    return null;
                }

                return new RecommendationResult(
                    ProductId: row.ProductId,
                    ProductName: row.ProductName,
                    Slug: row.Slug,
                    ImageUrl: string.IsNullOrWhiteSpace(row.ImageUrl) ? null : row.ImageUrl,
                    Price: row.Price,
                    DiscountPrice: row.DiscountPrice,
                    EffectivePrice: row.DiscountPrice > 0 && row.DiscountPrice < row.Price ? row.DiscountPrice : row.Price,
                    AvgRating: row.AvgRating,
                    ReviewCount: row.ReviewCount,
                    SoldCount: row.SoldCount,
                    StockQuantity: row.StockQuantity,
                    Support: stats.Support,
                    Confidence: stats.Confidence,
                    Utility: stats.Utility);
            })
            .Where(result => result is not null)
            .Select(result => result!)
            .OrderByDescending(result => result.Utility)
            .ThenByDescending(result => result.Confidence)
            .ThenByDescending(result => result.Support)
            .Take(topN)
            .ToList();

        return results;
    }

    private sealed class RecommendationStats
    {
        public double Support { get; set; }
        public double Confidence { get; set; }
        public decimal Utility { get; set; }
    }
}