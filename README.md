# AzureDevOpsContainer

Run Azure DevOps Server with Docker Compose using unattended installation.

## Overview

This repository provides a Docker-based setup for running Azure DevOps Server with SQL Server using unattended installation. It follows the Microsoft documentation for [unattended installation of Azure DevOps Server](https://learn.microsoft.com/en-us/azure/devops/server/install/unattended?view=azure-devops-2022).

## Prerequisites

1. **Windows Host with Docker Desktop** - Azure DevOps Server requires Windows containers
2. **Azure DevOps Server ISO** - Download from Microsoft's website
3. **Docker Desktop** configured for Windows containers
4. **Sufficient Resources**:
   - At least 8GB RAM
   - 50GB+ disk space
   - Multi-core processor

## Setup Instructions

### 1. Download Azure DevOps Server ISO

Download the Azure DevOps Server ISO from Microsoft's official download page.

### 2. Mount the ISO

On Windows, right-click the ISO file and select "Mount". Note the drive letter assigned (e.g., D:, E:, F:).

### 3. Configure the Build

Option 1: Using environment variables file (recommended)

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and set your values
# SA_PASSWORD=YourSecurePassword123!
# DVD_DRIVE=E:
```

Option 2: Edit `docker-compose.yml` directly and update the `DVD_DRIVE` argument:

```yaml
azuredevops:
  build:
    args:
      DVD_DRIVE: "E:"  # Change this to your mounted drive letter
```

### 4. Configure SQL Server Password

**IMPORTANT**: Before proceeding, you must set a strong, secure password.

Option 1: Using .env file (recommended)

```bash
# Edit .env and set a strong password
# DO NOT use the default placeholder password!
SA_PASSWORD=Your$ecureP@ssw0rd123
```

Option 2: Edit `docker-compose.yml` directly and update the `SA_PASSWORD`:

```yaml
environment:
  - SA_PASSWORD=Your$ecureP@ssw0rd123  # Change to a secure password
```

**Important**: The password must meet SQL Server complexity requirements:
- At least 8 characters
- Contains uppercase and lowercase letters
- Contains numbers
- Contains special characters

### 5. Build and Run

```bash
# Build the Azure DevOps Server image
docker-compose build

# Start the services
docker-compose up -d

# View logs
docker-compose logs -f azuredevops
```

### 6. Access Azure DevOps Server

Once the containers are running and configured:

- Azure DevOps Server: http://localhost:8080/tfs
- SQL Server: localhost:1433

The initial startup may take several minutes as Azure DevOps Server configures itself.

## Configuration

### Azure DevOps Configuration File

The `azuredevops-config.json` file contains the unattended installation configuration. You can customize:

- **Port**: Default is 8080
- **Virtual Directory**: Default is `/tfs`
- **Database Settings**: Configured to use the SQL Server container
- **Features**: SMTP, Reporting, Search, and Analysis are disabled by default

### Customizing the Configuration

Edit `azuredevops-config.json` before building the Docker image to customize the installation:

```json
{
  "InstallSqlExpress": "False",
  "UseIntegratedAuth": "False",
  "SqlInstance": "sqlserver",
  "DatabaseLabel": "AzureDevOps",
  "SiteBindings": [
    {
      "Protocol": "http",
      "Port": "8080"
    }
  ]
}
```

## Architecture

The setup consists of two containers:

1. **SQL Server Container** (Linux)
   - Microsoft SQL Server 2022 Developer Edition
   - Stores Azure DevOps databases
   - Persistent volume for data storage

2. **Azure DevOps Server Container** (Windows)
   - Windows Server Core base image
   - Azure DevOps Server installed from ISO
   - Configured via unattended installation
   - Persistent volume for application data

## Volumes

- `sqlserver-data`: SQL Server database files
- `azuredevops-data`: Azure DevOps application data and file cache

## Troubleshooting

### Container fails to build

- Ensure the ISO is mounted and the drive letter in `docker-compose.yml` is correct
- Verify Docker Desktop is set to Windows container mode
- Check available disk space

### SQL Server connection issues

- Verify the SA_PASSWORD is the same in both service configurations
- Check that the SQL Server container is healthy: `docker-compose ps`
- Review SQL Server logs: `docker-compose logs sqlserver`

### Azure DevOps Server not accessible

- Wait for the initial configuration to complete (check logs)
- Verify services are running: `docker exec azuredevops-server powershell Get-Service -Name "VSS*"`
- Check firewall settings on the host

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Just Azure DevOps
docker-compose logs -f azuredevops

# Just SQL Server
docker-compose logs -f sqlserver
```

## Stopping and Removing

```bash
# Stop services
docker-compose stop

# Stop and remove containers (data volumes are preserved)
docker-compose down

# Remove everything including volumes (WARNING: This deletes all data)
docker-compose down -v
```

## Security Considerations

**CRITICAL**: This setup is designed for development and testing purposes. Follow these security best practices:

1. **Change ALL default passwords immediately**
   - Never use placeholder passwords like "CHANGE_ME_TO_SECURE_PASSWORD!123"
   - Use a password manager to generate strong, unique passwords
   - SQL Server password must be at least 8 characters with uppercase, lowercase, numbers, and special characters

2. **Protect sensitive credentials**
   - Never commit the `.env` file to version control (it's in `.gitignore`)
   - Store passwords securely using secret management tools in production
   - The healthcheck script reads passwords from environment variables to avoid process list exposure

3. **Use HTTPS in production**
   - Update the configuration to use SSL/TLS certificates
   - Never expose Azure DevOps Server over HTTP in production environments

4. **Restrict network access appropriately**
   - Use firewall rules to limit who can access the containers
   - Consider using Docker network isolation for additional security

5. **Regular backups**
   - Implement automated backups of the SQL Server data volume
   - Test backup restoration procedures regularly

6. **Keep images updated**
   - Regularly update base images for security patches
   - Monitor security advisories for Azure DevOps Server and SQL Server

7. **Review and audit**
   - Enable logging and monitor access to Azure DevOps Server
   - Regularly review user permissions and access controls

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Azure DevOps Server Unattended Installation Documentation](https://learn.microsoft.com/en-us/azure/devops/server/install/unattended?view=azure-devops-2022)
- [Azure DevOps Server Requirements](https://learn.microsoft.com/en-us/azure/devops/server/requirements?view=azure-devops-2022)
- [Docker Documentation](https://docs.docker.com/)
