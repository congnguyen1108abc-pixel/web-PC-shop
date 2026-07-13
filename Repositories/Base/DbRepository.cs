using Dapper;
using System.Data;

namespace PC_Store.Repositories.Base;

public sealed class DbRepository : IDbRepository
{
    private readonly IDbConnection _connection;

    public DbRepository(IDbConnection connection)
    {
        _connection = connection;
    }

    public Task<IEnumerable<T>> QueryAsync<T>(string storedProcedure, object? parameters = null)
        => _connection.QueryAsync<T>(storedProcedure, parameters, commandType: CommandType.StoredProcedure);

    public Task<T?> QuerySingleAsync<T>(string storedProcedure, object? parameters = null)
        => _connection.QueryFirstOrDefaultAsync<T>(storedProcedure, parameters, commandType: CommandType.StoredProcedure);

    public Task<int> ExecuteAsync(string storedProcedure, object? parameters = null)
        => _connection.ExecuteAsync(storedProcedure, parameters, commandType: CommandType.StoredProcedure);

    public Task<T?> ExecuteScalarAsync<T>(string storedProcedure, object? parameters = null)
        => _connection.ExecuteScalarAsync<T>(storedProcedure, parameters, commandType: CommandType.StoredProcedure);

    public Task<SqlMapper.GridReader> QueryMultipleAsync(string storedProcedure, object? parameters = null)
        => _connection.QueryMultipleAsync(storedProcedure, parameters, commandType: CommandType.StoredProcedure);

    // Raw SQL - dùng CommandType.Text thay vì StoredProcedure
    public Task<int> ExecuteRawAsync(string sql, object? parameters = null)
        => _connection.ExecuteAsync(sql, parameters, commandType: CommandType.Text);

    public Task<T?> QuerySingleOrDefaultAsync<T>(string sql, object? parameters = null)
        => _connection.QueryFirstOrDefaultAsync<T>(sql, parameters, commandType: CommandType.Text);
}
