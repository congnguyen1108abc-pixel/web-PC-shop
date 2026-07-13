using Dapper;
using System.Data;

namespace PC_Store.Repositories.Base;

public interface IDbRepository
{
    Task<IEnumerable<T>> QueryAsync<T>(string storedProcedure, object? parameters = null);
    Task<T?> QuerySingleAsync<T>(string storedProcedure, object? parameters = null);
    Task<int> ExecuteAsync(string storedProcedure, object? parameters = null);
    Task<T?> ExecuteScalarAsync<T>(string storedProcedure, object? parameters = null);
    Task<SqlMapper.GridReader> QueryMultipleAsync(string storedProcedure, object? parameters = null);

    // Raw SQL (không qua Stored Procedure)
    Task<int> ExecuteRawAsync(string sql, object? parameters = null);
    Task<T?> QuerySingleOrDefaultAsync<T>(string sql, object? parameters = null);
}
