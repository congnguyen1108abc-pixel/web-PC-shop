using Microsoft.Extensions.Caching.Memory;
using PC_Store.Services.Interfaces;
using System.Collections.Concurrent;

namespace PC_Store.Services;

/// <summary>
/// In-memory cache service implementation using IMemoryCache.
/// Provides caching functionality with expiration and invalidation support.
/// </summary>
public sealed class CacheService : ICacheService
{
    private readonly IMemoryCache _cache;
    private readonly ILogger<CacheService> _logger;

    // Track all cache keys for prefix-based removal
    private static readonly ConcurrentDictionary<string, byte> _cacheKeys = new();

    public CacheService(IMemoryCache cache, ILogger<CacheService> logger)
    {
        _cache = cache;
        _logger = logger;
    }

    public async Task<T?> GetOrCreateAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan expiration) where T : class
    {
        // Try to get from cache
        if (_cache.TryGetValue(key, out T? cachedValue))
        {
            _logger.LogDebug("Cache HIT: {Key}", key);
            return cachedValue;
        }

        _logger.LogDebug("Cache MISS: {Key}", key);

        // Cache miss - create new value
        var value = await factory();

        if (value is not null)
        {
            // Store in cache with expiration
            var cacheOptions = new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = expiration,
                // Remove from tracking when evicted
                PostEvictionCallbacks =
                {
                    new PostEvictionCallbackRegistration
                    {
                        EvictionCallback = (key, value, reason, state) =>
                        {
                            _cacheKeys.TryRemove(key.ToString() ?? string.Empty, out _);
                            _logger.LogDebug("Cache EVICTED: {Key}, Reason: {Reason}", key, reason);
                        }
                    }
                }
            };

            _cache.Set(key, value, cacheOptions);
            _cacheKeys.TryAdd(key, 0);

            _logger.LogInformation("Cache SET: {Key}, Expiration: {Expiration}", key, expiration);
        }

        return value;
    }

    public void Remove(string key)
    {
        _cache.Remove(key);
        _cacheKeys.TryRemove(key, out _);
        _logger.LogInformation("Cache REMOVED: {Key}", key);
    }

    public void RemoveByPrefix(string prefix)
    {
        var keysToRemove = _cacheKeys.Keys
            .Where(k => k.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            .ToList();

        foreach (var key in keysToRemove)
        {
            Remove(key);
        }

        _logger.LogInformation("Cache REMOVED by prefix: {Prefix}, Count: {Count}", prefix, keysToRemove.Count);
    }

    public void Clear()
    {
        foreach (var key in _cacheKeys.Keys.ToList())
        {
            _cache.Remove(key);
        }

        _cacheKeys.Clear();
        _logger.LogWarning("Cache CLEARED: All entries removed");
    }
}
