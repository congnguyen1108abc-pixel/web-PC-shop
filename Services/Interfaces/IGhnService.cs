using System.Threading.Tasks;

namespace PC_Store.Services.Interfaces;

public interface IGhnService
{
    Task<decimal> CalculateShippingFeeAsync(int toDistrictId, string toWardCode, int weightGrams);
    Task<string?> CreateShippingOrderAsync(int orderId, string toName, string toPhone, string toAddress, string toWardCode, int toDistrictId, decimal codAmount, int weightGrams);
    Task<string?> CreateReturnOrderAsync(int returnId, string customerName, string customerPhone, string customerAddress, string customerWardCode, int customerDistrictId, int weightGrams);
    Task<string?> GetOrderTrackingDetailAsync(string trackingCode);
    Task<string> GetProvincesJsonAsync();
    Task<string> GetDistrictsJsonAsync(int provinceId);
    Task<string> GetWardsJsonAsync(int districtId);
}
