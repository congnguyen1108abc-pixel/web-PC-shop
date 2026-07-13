# Stop any dotnet processes running the store dll
Get-Process | Where-Object { $_.ProcessName -eq "dotnet" -or $_.ProcessName -eq "PC_Store" } | ForEach-Object {
    try {
        Stop-Process -Id $_.Id -Force
        Write-Output "Stopped process: $($_.ProcessName) (ID: $($_.Id))"
    } catch {
        Write-Warning "Could not stop process $($_.Id): $_"
    }
}
