$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZWlkZW50aWZpZXIiOiIzIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvbmFtZSI6IkFkbWluaXN0cmF0b3IiLCJlbWFpbCI6ImFkbWluQHBjc3RvcmUuY29tIiwiaHR0cDovL3NjaGVtYXMueG1sc29hcC5vcmcvd3MvMjAwNS8wNS9pZGVudGl0eS9jbGFpbXMvZW1haWxhZGRyZXNzIjoiYWRtaW5AcGNzdG9yZS5jb20iLCJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dzLzIwMDgvMDYvaWRlbnRpdHkvY2xhaW1zL3JvbGUiOiJBZG1pbiIsImp0aSI6IjcyNTU0YTQ5LWI3YTEtNGQxYi1hZjE4LWQ0YmFhM2IzMmY1YiIsImV4cCI6MTc4MzI4MzQzMywiaXNzIjoiUENfU3RvcmUiLCJhdWQiOiJQQ19TdG9yZSJ9.YnMDLq3g_TK2GpfXST_46t_4drPIA_4YdEwCtcnKq5M"

$headers = @{
    "Authorization" = "Bearer $token"
}

try {
    $res = Invoke-WebRequest -Uri "http://localhost:5187/api/Admin/users?PageSize=100" -Headers $headers -Method Get
    Write-Output "Status: $($res.StatusCode)"
    Write-Output "Body: $($res.Content)"
} catch {
    Write-Output "Error status: $($_.Exception.Response.StatusCode.Value__)"
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $responseBody = $reader.ReadToEnd()
    Write-Output "Error Response: $responseBody"
}
