using System.Diagnostics;
using PC_Store.Repositories.Base;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services
{
    public sealed class FlatTransactionItem
    {
        public int OrderID { get; set; }
        public int ProductID { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal ImportPrice { get; set; }
    }

    internal sealed class ItemUtility
    {
        public int ProductID { get; }
        public int Quantity { get; }
        public decimal ProfitPerUnit { get; }
        public decimal Utility => Quantity * ProfitPerUnit;

        public ItemUtility(int productId, int quantity, decimal profitPerUnit)
        {
            ProductID = productId;
            Quantity = quantity;
            ProfitPerUnit = profitPerUnit;
        }
    }

    internal sealed class Transaction
    {
        public int OrderId { get; }
        public List<ItemUtility> Items { get; }
        public decimal TransactionUtility { get; }
        public HashSet<int> ItemIds { get; }

        public Transaction(int orderId, List<ItemUtility> items)
        {
            OrderId = orderId;
            Items = items;
            TransactionUtility = items.Sum(x => x.Utility);
            ItemIds = new HashSet<int>(items.Select(x => x.ProductID));
        }

        public bool Contains(HashSet<int> itemset) => itemset.IsSubsetOf(ItemIds);

        public decimal GetUtility(HashSet<int> itemset)
        {
            decimal sum = 0;
            foreach (var item in Items)
            {
                if (itemset.Contains(item.ProductID))
                {
                    sum += item.Utility;
                }
            }
            return sum;
        }
    }

    public sealed class HighUtilityMiningService : IHighUtilityMiningService
    {
        private readonly IDbRepository _db;

        public HighUtilityMiningService(IDbRepository db)
        {
            _db = db;
        }

        public async Task<MiningReportSummary> RunMiningAsync(decimal minUtil)
        {
            var stopwatch = Stopwatch.StartNew();

            try
            {
                // 1. Đọc tất cả các sản phẩm bán được trong các đơn hàng đã Hoàn tất
                var flatItems = await _db.QueryAsync<FlatTransactionItem>("sp_Admin_GetFlatCompletedTransactions");
                var transactions = flatItems
                    .GroupBy(x => x.OrderID)
                    .Select(g => new Transaction(
                        g.Key,
                        g.Select(x => new ItemUtility(x.ProductID, x.Quantity, x.UnitPrice - x.ImportPrice)).ToList()
                    ))
                    .ToList();

                if (transactions.Count == 0)
                {
                    return new MiningReportSummary(0, 0, stopwatch.Elapsed.TotalMilliseconds, "Không có đơn hàng 'Hoàn tất' nào để khai thác dữ liệu.");
                }

                // 2. PHẦN 1: KHAI THÁC LỢI ÍCH CAO (TWO-PHASE HUIM - APRIORI BASED)
                // Phase 1: Tìm các ứng viên có TWU >= minUtil
                var candidates = MineCandidates(transactions, minUtil);

                // Phase 2: Xác thực các ứng viên để tìm ra HUI thực sự (Tổng lợi nhuận thực tế >= minUtil)
                var highUtilityItemsets = new List<(HashSet<int> Itemset, decimal ActualUtility, int Support)>();
                foreach (var candidate in candidates)
                {
                    decimal actualUtility = 0;
                    int support = 0;

                    foreach (var tx in transactions)
                    {
                        if (tx.Contains(candidate))
                        {
                            actualUtility += tx.GetUtility(candidate);
                            support++;
                        }
                    }

                    if (actualUtility >= minUtil)
                    {
                        highUtilityItemsets.Add((candidate, actualUtility, support));
                    }
                }

                // 3. LƯU KẾT QUẢ VÀO CƠ SỞ DỮ LIỆU
                // Clear dữ liệu cũ
                await _db.ExecuteRawAsync("DELETE FROM ProductRecommendations;");
                await _db.ExecuteRawAsync("DELETE FROM HighUtilityItemsets;");

                // Lưu các tập HUI
                foreach (var hui in highUtilityItemsets)
                {
                    var itemsetStr = string.Join(",", hui.Itemset.OrderBy(x => x));
                    await _db.ExecuteRawAsync(
                        "INSERT INTO HighUtilityItemsets (ProductIDs, TotalUtility, SupportCount) VALUES (@ProductIDs, @TotalUtility, @SupportCount)",
                        new { ProductIDs = itemsetStr, TotalUtility = hui.ActualUtility, SupportCount = hui.Support }
                    );
                }

                // Phân rã các tập HUI kích thước >= 2 để sinh các cặp gợi ý sản phẩm (Source -> Recommended)
                var recommendationsMap = new Dictionary<(int Source, int Rec), decimal>();

                foreach (var hui in highUtilityItemsets.Where(x => x.Itemset.Count >= 2))
                {
                    var list = hui.Itemset.ToList();
                    for (int i = 0; i < list.Count; i++)
                    {
                        for (int j = 0; j < list.Count; j++)
                        {
                            if (i == j) continue;

                            var pair = (Source: list[i], Rec: list[j]);
                            // Nếu cặp này đã tồn tại, giữ lại cặp có điểm lợi nhuận lớn hơn
                            if (recommendationsMap.TryGetValue(pair, out var existingUtility))
                            {
                                if (hui.ActualUtility > existingUtility)
                                {
                                    recommendationsMap[pair] = hui.ActualUtility;
                                }
                            }
                            else
                            {
                                recommendationsMap[pair] = hui.ActualUtility;
                            }
                        }
                    }
                }

                // Lưu các cặp gợi ý vào bảng ProductRecommendations
                foreach (var rec in recommendationsMap)
                {
                    await _db.ExecuteRawAsync(
                        "INSERT INTO ProductRecommendations (SourceProductID, RecommendedProductID, UtilityScore) VALUES (@Source, @Rec, @Score)",
                        new { Source = rec.Key.Source, Rec = rec.Key.Rec, Score = rec.Value }
                    );
                }

                stopwatch.Stop();
                return new MiningReportSummary(
                    ScannedTransactions: transactions.Count,
                    TotalHighUtilityItemsets: highUtilityItemsets.Count,
                    ExecutionTimeMs: stopwatch.Elapsed.TotalMilliseconds,
                    StatusMessage: $"Đã chạy xong thuật toán Apriori-HUIM thành công! Tìm thấy {highUtilityItemsets.Count} tập mục lợi ích cao và tạo ra {recommendationsMap.Count} cặp gợi ý sản phẩm."
                );
            }
            catch (Exception ex)
            {
                stopwatch.Stop();
                return new MiningReportSummary(0, 0, stopwatch.Elapsed.TotalMilliseconds, $"Lỗi thực thi: {ex.Message}");
            }
        }

        public async Task<IEnumerable<MinedItemsetItem>> GetMinedItemsetsAsync()
        {
            // 1. Fetch all products to construct a lookup map
            var productsRaw = await _db.QueryAsync<ProductLookupItem>("sp_Admin_GetProductLookup");
            var productLookup = productsRaw.ToDictionary(p => p.ProductID, p => p.ProductName);

            // 2. Fetch all mined itemsets from the database
            var dbItemsets = await _db.QueryAsync<DbMinedItemset>("sp_Admin_GetMinedItemsets");

            var result = new List<MinedItemsetItem>();
            foreach (var dbItem in dbItemsets)
            {
                var idStrings = dbItem.ProductIDs.Split(',');
                var resolvedNamesList = new List<string>();
                foreach (var idStr in idStrings)
                {
                    if (int.TryParse(idStr, out var id) && productLookup.TryGetValue(id, out var name))
                    {
                        resolvedNamesList.Add(name);
                    }
                    else
                    {
                        resolvedNamesList.Add($"Sản phẩm #{idStr}");
                    }
                }

                result.Add(new MinedItemsetItem(
                    ItemsetID: dbItem.ItemsetID,
                    ProductNames: string.Join(" + ", resolvedNamesList),
                    TotalUtility: dbItem.TotalUtility,
                    SupportCount: dbItem.SupportCount
                ));
            }

            return result;
        }

        private sealed class ProductLookupItem
        {
            public int ProductID { get; set; }
            public string ProductName { get; set; } = null!;
        }

        private sealed class DbMinedItemset
        {
            public int ItemsetID { get; set; }
            public string ProductIDs { get; set; } = null!;
            public decimal TotalUtility { get; set; }
            public int SupportCount { get; set; }
        }

        private List<HashSet<int>> MineCandidates(List<Transaction> transactions, decimal minUtil)
        {
            var allCandidates = new List<HashSet<int>>();

            // 1. Tìm các tập 1-itemset có TWU >= minUtil
            var itemTwuMap = new Dictionary<int, decimal>();
            foreach (var tx in transactions)
            {
                foreach (var itemId in tx.ItemIds)
                {
                    if (itemTwuMap.ContainsKey(itemId))
                        itemTwuMap[itemId] += tx.TransactionUtility;
                    else
                        itemTwuMap[itemId] = tx.TransactionUtility;
                }
            }

            var frequent1 = itemTwuMap
                .Where(x => x.Value >= minUtil)
                .Select(x => x.Key)
                .OrderBy(x => x)
                .ToList();

            var currentFrequentSet = frequent1.Select(item => new HashSet<int> { item }).ToList();
            allCandidates.AddRange(currentFrequentSet);

            int k = 2;
            while (currentFrequentSet.Count > 0)
            {
                // Sinh ứng viên k-itemsets bằng cách join L_{k-1} với chính nó
                var nextCandidates = GenerateCandidates(currentFrequentSet, k);
                if (nextCandidates.Count == 0) break;

                // Tính TWU của các ứng viên
                var candidateTwuMap = new Dictionary<HashSet<int>, decimal>(HashSetEqualityComparer.Instance);
                foreach (var c in nextCandidates)
                {
                    candidateTwuMap[c] = 0;
                    foreach (var tx in transactions)
                    {
                        if (tx.Contains(c))
                        {
                            candidateTwuMap[c] += tx.TransactionUtility;
                        }
                    }
                }

                // Lọc các ứng viên có TWU >= minUtil
                currentFrequentSet = candidateTwuMap
                    .Where(x => x.Value >= minUtil)
                    .Select(x => x.Key)
                    .ToList();

                if (currentFrequentSet.Count > 0)
                {
                    allCandidates.AddRange(currentFrequentSet);
                }

                k++;
            }

            return allCandidates;
        }

        private List<HashSet<int>> GenerateCandidates(List<HashSet<int>> previousLevel, int k)
        {
            var candidates = new List<HashSet<int>>();
            var orderedLists = previousLevel.Select(s => s.OrderBy(x => x).ToList()).ToList();

            for (int i = 0; i < orderedLists.Count; i++)
            {
                for (int j = i + 1; j < orderedLists.Count; j++)
                {
                    var list1 = orderedLists[i];
                    var list2 = orderedLists[j];

                    // Điều kiện Join: k-2 phần tử đầu giống nhau
                    bool canJoin = true;
                    for (int m = 0; m < k - 2; m++)
                    {
                        if (list1[m] != list2[m])
                        {
                            canJoin = false;
                            break;
                        }
                    }

                    if (canJoin)
                    {
                        var newSet = new HashSet<int>(list1);
                        newSet.Add(list2[k - 2]); // Thêm phần tử cuối của list2 vào

                        // Pruning (Cắt tỉa Apriori): Mọi tập con kích thước k-1 phải có trong previousLevel
                        if (AllSubsetsFrequent(newSet, previousLevel))
                        {
                            candidates.Add(newSet);
                        }
                    }
                }
            }

            return candidates;
        }

        private bool AllSubsetsFrequent(HashSet<int> candidate, List<HashSet<int>> previousLevel)
        {
            var list = candidate.ToList();
            // Sinh tất cả tập con kích thước k-1 bằng cách lần lượt bỏ đi 1 phần tử
            for (int i = 0; i < list.Count; i++)
            {
                var subset = new HashSet<int>(list);
                subset.Remove(list[i]);

                bool found = false;
                foreach (var p in previousLevel)
                {
                    if (p.SetEquals(subset))
                    {
                        found = true;
                        break;
                    }
                }
                if (!found) return false;
            }
            return true;
        }
    }

    // Helper comparer để so sánh các HashSet trong Dictionary
    internal sealed class HashSetEqualityComparer : IEqualityComparer<HashSet<int>>
    {
        public static HashSetEqualityComparer Instance { get; } = new HashSetEqualityComparer();

        public bool Equals(HashSet<int>? x, HashSet<int>? y)
        {
            if (x == null && y == null) return true;
            if (x == null || y == null) return false;
            return x.SetEquals(y);
        }

        public int GetHashCode(HashSet<int> obj)
        {
            int hash = 0;
            foreach (var item in obj)
            {
                hash ^= item.GetHashCode();
            }
            return hash;
        }
    }
}
