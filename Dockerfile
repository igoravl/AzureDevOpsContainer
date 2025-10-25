# Dockerfile for Azure DevOps Server Unattended Installation
# This Dockerfile expects the Azure DevOps Server ISO to be mounted on the Windows host

# Use Windows Server Core as base image
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Set shell to PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Build argument for the DVD drive letter where the ISO is mounted
ARG DVD_DRIVE=D:

# Create directories for Azure DevOps data
RUN New-Item -ItemType Directory -Force -Path 'C:\AzureDevOpsData\ApplicationTier\_fileCache' | Out-Null; \
    New-Item -ItemType Directory -Force -Path 'C:\AzureDevOpsData\Logs' | Out-Null

# Copy the configuration file
COPY azuredevops-config.json C:/AzureDevOpsData/

# Install Azure DevOps Server from the mounted ISO
# The DVD_DRIVE argument should point to the mounted ISO drive (e.g., D:)
RUN Write-Host 'Installing Azure DevOps Server...'; \
    $dvdDrive = $env:DVD_DRIVE; \
    if (-not (Test-Path \"$dvdDrive\\azuredevopsserver.exe\")) { \
        Write-Host \"ERROR: Azure DevOps Server installer not found at $dvdDrive\\azuredevopsserver.exe\"; \
        Write-Host 'Please ensure the ISO is mounted and the DVD_DRIVE build argument is correct.'; \
        exit 1; \
    }; \
    Start-Process -FilePath \"$dvdDrive\\azuredevopsserver.exe\" -ArgumentList '/quiet', '/norestart' -Wait -NoNewWindow; \
    Write-Host 'Azure DevOps Server installation completed.'

# Set environment variable for the DVD drive to be used during configuration
ENV DVD_DRIVE=${DVD_DRIVE}

# Expose the default Azure DevOps Server port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD powershell -command "try { \
        $response = Invoke-WebRequest -Uri 'http://localhost:8080/tfs' -UseBasicParsing -TimeoutSec 5; \
        if ($response.StatusCode -eq 200) { exit 0 } else { exit 1 } \
    } catch { exit 1 }"

# Copy startup script
COPY start-azuredevops.ps1 C:/Scripts/

# Set the working directory
WORKDIR C:/Scripts

# Start Azure DevOps Server
CMD ["powershell", "-File", "C:/Scripts/start-azuredevops.ps1"]
