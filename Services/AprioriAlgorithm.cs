using PC_Store.DTOs.Recommendations;

namespace PC_Store.Services;

public sealed class AprioriAlgorithm
{
    public IReadOnlyList<HashSet<int>> FindFrequentItemsets(
        IReadOnlyList<Transaction> transactions,
        int minSupportCount,
        int maxItemsetSize = 3)
    {
        if (transactions.Count == 0 || minSupportCount < 1 || maxItemsetSize < 1)
        {
            return Array.Empty<HashSet<int>>();
        }

        var transactionSets = transactions
            .Select(transaction => transaction.ProductIds.ToHashSet())
            .Where(set => set.Count > 0)
            .ToList();

        if (transactionSets.Count == 0)
        {
            return Array.Empty<HashSet<int>>();
        }

        var allFrequentItemsets = new List<HashSet<int>>();
        var currentLevel = FindFrequentSingletons(transactionSets, minSupportCount);
        allFrequentItemsets.AddRange(currentLevel);

        for (var size = 2; size <= maxItemsetSize && currentLevel.Count > 0; size++)
        {
            var candidates = GenerateCandidates(currentLevel, size);
            if (candidates.Count == 0)
            {
                break;
            }

            var nextLevel = new List<HashSet<int>>();
            foreach (var candidate in candidates)
            {
                var supportCount = transactionSets.Count(transaction => candidate.IsSubsetOf(transaction));
                if (supportCount >= minSupportCount)
                {
                    nextLevel.Add(candidate);
                }
            }

            if (nextLevel.Count == 0)
            {
                break;
            }

            allFrequentItemsets.AddRange(nextLevel);
            currentLevel = nextLevel;
        }

        return allFrequentItemsets;
    }

    private static List<HashSet<int>> FindFrequentSingletons(
        IReadOnlyList<HashSet<int>> transactionSets,
        int minSupportCount)
    {
        var counts = new Dictionary<int, int>();

        foreach (var transaction in transactionSets)
        {
            foreach (var item in transaction)
            {
                counts[item] = counts.TryGetValue(item, out var count) ? count + 1 : 1;
            }
        }

        return counts
            .Where(pair => pair.Value >= minSupportCount)
            .Select(pair => new HashSet<int> { pair.Key })
            .ToList();
    }

    private static List<HashSet<int>> GenerateCandidates(IReadOnlyList<HashSet<int>> previousLevel, int targetSize)
    {
        var previousKeys = previousLevel
            .Select(ToKey)
            .ToHashSet(StringComparer.Ordinal);

        var candidateMap = new Dictionary<string, HashSet<int>>(StringComparer.Ordinal);

        for (var i = 0; i < previousLevel.Count; i++)
        {
            for (var j = i + 1; j < previousLevel.Count; j++)
            {
                var merged = previousLevel[i].Union(previousLevel[j]).ToHashSet();
                if (merged.Count != targetSize)
                {
                    continue;
                }

                if (!AllSubsetsFrequent(merged, previousKeys))
                {
                    continue;
                }

                candidateMap[ToKey(merged)] = merged;
            }
        }

        return candidateMap.Values.ToList();
    }

    private static bool AllSubsetsFrequent(HashSet<int> candidate, ISet<string> previousKeys)
    {
        foreach (var removed in candidate)
        {
            var subset = candidate.Where(item => item != removed).ToHashSet();
            if (!previousKeys.Contains(ToKey(subset)))
            {
                return false;
            }
        }

        return true;
    }

    private static string ToKey(IEnumerable<int> items)
        => string.Join("-", items.OrderBy(item => item));
}