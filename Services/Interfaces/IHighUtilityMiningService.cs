using PC_Store.DTOs.Admin;

namespace PC_Store.Services.Interfaces
{
    public interface IHighUtilityMiningService
    {
        Task<MiningReportSummary> RunMiningAsync(decimal minUtil);
        Task<IEnumerable<MinedItemsetItem>> GetMinedItemsetsAsync();
    }

    public sealed record MiningReportSummary(
        int ScannedTransactions,
        int TotalHighUtilityItemsets,
        double ExecutionTimeMs,
        string StatusMessage
    );

    public sealed record MinedItemsetItem(
        int ItemsetID,
        string ProductNames,
        decimal TotalUtility,
        int SupportCount
    );
}
