using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class GhnService : IGhnService
{
    private readonly HttpClient _http;
    private readonly string _token;
    private readonly string _shopId;
    private readonly string _baseUrl;

    public GhnService(HttpClient http, IConfiguration config)
    {
        _http = http;
        var section = config.GetSection("GHN");
        _token = section["Token"] ?? throw new ArgumentNullException("GHN Token is missing");
        _shopId = section["ShopId"] ?? throw new ArgumentNullException("GHN ShopId is missing");
        _baseUrl = section["BaseUrl"] ?? "https://dev-online-gateway.ghn.vn/shiip/public-api/";
    }

    public async Task<decimal> CalculateShippingFeeAsync(int toDistrictId, string toWardCode, int weightGrams)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Post, new Uri(new Uri(_baseUrl), "v2/shipping-order/fee"));
            request.Headers.Add("Token", _token);
            request.Headers.Add("ShopId", _shopId);

            var body = new
            {
                service_type_id = 2, // Hàng nhẹ/tiêu chuẩn
                insurance_value = 0,
                coupon = (string?)null,
                from_district_id = 1458, // Quận Bình Tân, TP.HCM (Aeon Mall)
                to_district_id = toDistrictId,
                to_ward_code = toWardCode,
                height = 15,
                length = 15,
                width = 15,
                weight = weightGrams
            };

            request.Content = JsonContent.Create(body);
            var response = await _http.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                var errorText = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"[GHN Calculate Fee Error]: {response.StatusCode} - {errorText}");
                return 25000; // Giá cước mặc định nếu API lỗi
            }

            var result = await response.Content.ReadFromJsonAsync<GhnResponse<GhnFeeResult>>();
            return result?.Data?.Total ?? 25000;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GHN Calculate Fee Exception]: {ex.Message}");
            return 25000;
        }
    }

    public async Task<string?> CreateShippingOrderAsync(int orderId, string toName, string toPhone, string toAddress, string toWardCode, int toDistrictId, decimal codAmount, int weightGrams)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Post, new Uri(new Uri(_baseUrl), "v2/shipping-order/create"));
            request.Headers.Add("Token", _token);
            request.Headers.Add("ShopId", _shopId);

            var body = new
            {
                payment_type_id = 1, // 1: Cửa hàng trả phí ship, 2: Người mua trả phí ship
                note = $"Don hang PC Store #{orderId}",
                required_note = "CHOXEMHANGKHONGTHU", // Cho xem hàng không cho thử
                from_name = "HYPERCORE",
                from_phone = "0345469863",
                from_address = "80 Đường Số 28, Bình Trị Đông B",
                from_ward_code = "21910",
                from_district_id = 1458,
                to_name = toName,
                to_phone = toPhone,
                to_address = toAddress,
                to_ward_code = toWardCode,
                to_district_id = toDistrictId,
                cod_amount = (int)codAmount,
                weight = weightGrams,
                length = 15,
                width = 15,
                height = 15,
                service_type_id = 2,
                items = new[]
                {
                    new
                    {
                        name = "Linh kien may tinh PC Store",
                        code = "PC_Store_Item",
                        quantity = 1,
                        price = 100000
                    }
                }
            };

            request.Content = JsonContent.Create(body);
            var response = await _http.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                var errorText = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"[GHN Create Order Error]: {response.StatusCode} - {errorText}");
                return null;
            }

            var result = await response.Content.ReadFromJsonAsync<GhnResponse<GhnCreateOrderResult>>();
            return result?.Data?.OrderCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GHN Create Order Exception]: {ex.Message}");
            return null;
        }
    }

    public async Task<string?> CreateReturnOrderAsync(int returnId, string customerName, string customerPhone, string customerAddress, string customerWardCode, int customerDistrictId, int weightGrams)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Post, new Uri(new Uri(_baseUrl), "v2/shipping-order/create"));
            request.Headers.Add("Token", _token);
            request.Headers.Add("ShopId", _shopId);

            var body = new
            {
                payment_type_id = 1, // Shop trả phí ship
                note = $"Thu hoi don hang tu yeu cau #{returnId}",
                required_note = "CHOXEMHANGKHONGTHU",
                from_name = customerName,
                from_phone = customerPhone,
                from_address = customerAddress,
                from_ward_code = customerWardCode,
                from_district_id = customerDistrictId,
                to_name = "HYPERCORE",
                to_phone = "0345469863",
                to_address = "80 Đường Số 28, Bình Trị Đông B",
                to_ward_code = "21910",
                to_district_id = 1458,
                cod_amount = 0, // Đơn trả về không COD
                weight = weightGrams,
                length = 15,
                width = 15,
                height = 15,
                service_type_id = 2,
                items = new[]
                {
                    new
                    {
                        name = "Linh kien may tinh PC Store (Thu hoi)",
                        code = "PC_Store_Return",
                        quantity = 1,
                        price = 0
                    }
                }
            };

            request.Content = JsonContent.Create(body);
            var response = await _http.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                var errorText = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"[GHN Create Return Order Error]: {response.StatusCode} - {errorText}");
                return null;
            }

            var result = await response.Content.ReadFromJsonAsync<GhnResponse<GhnCreateOrderResult>>();
            return result?.Data?.OrderCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GHN Create Return Order Exception]: {ex.Message}");
            return null;
        }
    }

    public async Task<string?> GetOrderTrackingDetailAsync(string trackingCode)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Post, new Uri(new Uri(_baseUrl), "v2/shipping-order/detail"));
            request.Headers.Add("Token", _token);
            request.Content = JsonContent.Create(new { order_code = trackingCode });

            var response = await _http.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                var errorText = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"[GHN Get Order Detail Error]: {response.StatusCode} - {errorText}");
                return null;
            }

            using var doc = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync());
            if (doc.RootElement.TryGetProperty("data", out var dataNode) &&
                dataNode.TryGetProperty("status", out var statusNode))
            {
                return statusNode.GetString();
            }
            return null;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[GHN Get Order Detail Exception]: {ex.Message}");
            return null;
        }
    }

    public async Task<string> GetProvincesJsonAsync()
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Get, new Uri(new Uri(_baseUrl), "master-data/province"));
            request.Headers.Add("Token", _token);
            var response = await _http.SendAsync(request);
            return await response.Content.ReadAsStringAsync();
        }
        catch (Exception ex)
        {
            return $"{{\"code\": 500, \"message\": \"{ex.Message}\", \"data\": []}}";
        }
    }

    public async Task<string> GetDistrictsJsonAsync(int provinceId)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Post, new Uri(new Uri(_baseUrl), "master-data/district"));
            request.Headers.Add("Token", _token);
            request.Content = JsonContent.Create(new { province_id = provinceId });
            var response = await _http.SendAsync(request);
            return await response.Content.ReadAsStringAsync();
        }
        catch (Exception ex)
        {
            return $"{{\"code\": 500, \"message\": \"{ex.Message}\", \"data\": []}}";
        }
    }

    public async Task<string> GetWardsJsonAsync(int districtId)
    {
        try
        {
            var request = new HttpRequestMessage(HttpMethod.Post, new Uri(new Uri(_baseUrl), "master-data/ward"));
            request.Headers.Add("Token", _token);
            request.Content = JsonContent.Create(new { district_id = districtId });
            var response = await _http.SendAsync(request);
            return await response.Content.ReadAsStringAsync();
        }
        catch (Exception ex)
        {
            return $"{{\"code\": 500, \"message\": \"{ex.Message}\", \"data\": []}}";
        }
    }

    private sealed class GhnResponse<T>
    {
        [JsonPropertyName("code")]
        public int Code { get; set; }

        [JsonPropertyName("message")]
        public string? Message { get; set; }

        [JsonPropertyName("data")]
        public T? Data { get; set; }
    }

    private sealed class GhnFeeResult
    {
        [JsonPropertyName("total")]
        public decimal Total { get; set; }
    }

    private sealed class GhnCreateOrderResult
    {
        [JsonPropertyName("order_code")]
        public string? OrderCode { get; set; }
    }
}
