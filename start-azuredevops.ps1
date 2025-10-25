# Start-AzureDevOps.ps1
# Startup script for Azure DevOps Server container

Write-Host "Starting Azure DevOps Server container..."

# Wait for SQL Server to be ready
$sqlReady = $false
$maxAttempts = 30
$attempt = 0

Write-Host "Waiting for SQL Server to be ready..."
while (-not $sqlReady -and $attempt -lt $maxAttempts) {
    $attempt++
    try {
        # Test SQL Server connection
        $connectionString = "Server=sqlserver;Database=master;User Id=sa;Password=$env:SA_PASSWORD;TrustServerCertificate=True;"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        $connection.Close()
        $sqlReady = $true
        Write-Host "SQL Server is ready!"
    }
    catch {
        Write-Host "Attempt $attempt/$maxAttempts - SQL Server not ready yet, waiting 10 seconds..."
        Start-Sleep -Seconds 10
    }
}

if (-not $sqlReady) {
    Write-Host "ERROR: SQL Server did not become ready in time."
    exit 1
}

# Check if Azure DevOps Server is already configured
$configPath = "C:\Program Files\Azure DevOps Server 2022\Tools\TfsConfig.exe"
if (-not (Test-Path $configPath)) {
    $configPath = "C:\Program Files\Azure DevOps Server 2020\Tools\TfsConfig.exe"
}
if (-not (Test-Path $configPath)) {
    $configPath = "C:\Program Files\Microsoft Team Foundation Server 2018\Tools\TfsConfig.exe"
}

if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: TfsConfig.exe not found. Azure DevOps Server may not be installed correctly."
    exit 1
}

Write-Host "Found TfsConfig at: $configPath"

# Check if already configured
$configStatus = & $configPath setup /status
if ($LASTEXITCODE -eq 0) {
    Write-Host "Azure DevOps Server is already configured."
} else {
    Write-Host "Configuring Azure DevOps Server using unattended installation..."
    
    # Run unattended configuration
    $configFile = "C:\AzureDevOpsData\azuredevops-config.json"
    
    # Update the config file with SQL Server password if provided
    if ($env:SA_PASSWORD) {
        $config = Get-Content $configFile | ConvertFrom-Json
        $config | Add-Member -NotePropertyName "SqlServerInstance" -NotePropertyValue "sqlserver" -Force
        $config | Add-Member -NotePropertyName "SqlAuthUserName" -NotePropertyValue "sa" -Force
        $config | Add-Member -NotePropertyName "SqlAuthPassword" -NotePropertyValue $env:SA_PASSWORD -Force
        $config | ConvertTo-Json -Depth 10 | Set-Content $configFile
    }
    
    $result = & $configPath setup /install /configfile:$configFile /unattend
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Azure DevOps Server configuration failed with exit code $LASTEXITCODE"
        Write-Host "Configuration result: $result"
        exit 1
    }
    
    Write-Host "Azure DevOps Server configuration completed successfully!"
}

# Start the Azure DevOps Server services
Write-Host "Starting Azure DevOps Server services..."
Get-Service -Name "VSS*", "Azure*", "TFS*" -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Running' } | Start-Service

Write-Host "Azure DevOps Server is running!"
Write-Host "Access the server at http://localhost:8080/tfs"

# Keep the container running
while ($true) {
    Start-Sleep -Seconds 60
    
    # Check if services are still running
    $services = Get-Service -Name "VSS*", "Azure*", "TFS*" -ErrorAction SilentlyContinue
    $stoppedServices = $services | Where-Object { $_.Status -ne 'Running' }
    
    if ($stoppedServices) {
        Write-Host "WARNING: Some Azure DevOps services have stopped. Attempting to restart..."
        $stoppedServices | ForEach-Object {
            Write-Host "Restarting service: $($_.Name)"
            Start-Service $_.Name -ErrorAction SilentlyContinue
        }
    }
}
