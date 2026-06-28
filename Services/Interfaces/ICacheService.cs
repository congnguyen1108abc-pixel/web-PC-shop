namespace PC_Store.Services.Interfaces;

/// <summary>
/// Cache service interface for managing in-memory cache operations.
/// Provides methods to get, set, and invalidate cached data.
/// </summary>
public interface ICacheService
{
    /// <summary>
    /// Get cached value or create new one if not exists.
    /// </summary>
    /// <typeparam name="T">Type of cached data</typeparam>
    /// <param name="key">Cache key</param>
    /// <param name="factory">Factory function to create data if cache miss</param>
    /// <param name="expiration">Cache expiration time</param>
    /// <returns>Cached or newly created data</returns>
    Task<T?> GetOrCreateAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan expiration) where T : class;

    /// <summary>
    /// Remove a specific cache entry by key.
    /// </summary>
    /// <param name="key">Cache key to remove</param>
    void Remove(string key);

    /// <summary>
    /// Remove all cache entries that start with the given prefix.
    /// Useful for invalidating related cache entries.
    /// </summary>
    /// <param name="prefix">Key prefix to match</param>
    void RemoveByPrefix(string prefix);

    /// <summary>
    /// Clear all cache entries.
    /// Use with caution in production.
    /// </summary>
    void Clear();
}
