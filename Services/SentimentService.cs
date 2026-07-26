using Google.GenAI;
using PC_Store.Repositories.Base;

namespace PC_Store.Services
{
    public interface ISentimentService
    {
        Task<string> AnalyzeSentimentWithGeminiAsync(string comment);
        Task<int> BatchAnalyzePendingReviewsAsync();
        Task UpdateSentimentAsync(int reviewId, string sentiment);
    }

    public class SentimentService : ISentimentService
    {
        private readonly Client _client;
        private readonly IDbRepository _db;

        public SentimentService(string apiKey, IDbRepository db)
        {
            _client = new Client(apiKey: apiKey);
            _db = db;
        }

        public async Task<string> AnalyzeSentimentWithGeminiAsync(string comment)
        {
            if (string.IsNullOrWhiteSpace(comment))
                return "Trung lập";

            try
            {
                var prompt = $"Hãy phân tích sắc thái của đánh giá sau đây bằng tiếng Việt. Trả về đúng 1 trong 3 nhãn: \"Tích cực\", \"Tiêu cực\" hoặc \"Trung lập\". Không giải thích, không trả về thêm từ nào khác.\nĐánh giá: \"{comment}\"";

                var response = await _client.Models.GenerateContentAsync(
                    model: "gemini-2.5-flash",
                    contents: prompt
                );

                var sentiment = response?.Text?.Trim() ?? "Trung lập";
                
                // Cleanup common Gemini response patterns (quotes, etc.)
                sentiment = sentiment.Replace("\"", "").Replace("'", "").Replace(".", "").Trim();
                
                if (sentiment.Contains("Tích cực") || sentiment.Contains("Positive"))
                    return "Tích cực";
                if (sentiment.Contains("Tiêu cực") || sentiment.Contains("Negative"))
                    return "Tiêu cực";
                if (sentiment.Contains("Trung lập") || sentiment.Contains("Neutral"))
                    return "Trung lập";

                return "Trung lập";
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Sentiment Gemini Error] {ex.Message}");
                return "Trung lập";
            }
        }

        public async Task<int> BatchAnalyzePendingReviewsAsync()
        {
            var pendingReviews = await _db.QueryRawAsync<dynamic>(
                "SELECT ReviewID, Comment FROM Reviews WHERE Sentiment IS NULL OR Sentiment = ''"
            );

            int updatedCount = 0;
            foreach (var r in pendingReviews)
            {
                string comment = r.Comment ?? "";
                string sentiment = await AnalyzeSentimentWithGeminiAsync(comment);
                
                await _db.ExecuteRawAsync(
                    "UPDATE Reviews SET Sentiment = @Sentiment WHERE ReviewID = @ReviewId",
                    new { Sentiment = sentiment, ReviewId = r.ReviewID }
                );
                updatedCount++;
            }
            return updatedCount;
        }

        public Task UpdateSentimentAsync(int reviewId, string sentiment)
        {
            return _db.ExecuteRawAsync(
                "UPDATE Reviews SET Sentiment = @Sentiment WHERE ReviewID = @ReviewId",
                new { Sentiment = sentiment, ReviewId = reviewId }
            );
        }
    }
}
