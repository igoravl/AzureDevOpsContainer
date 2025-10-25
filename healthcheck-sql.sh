#!/bin/bash
# SQL Server health check script
# This script checks if SQL Server is accessible without exposing credentials in process list

# The password is passed via environment variable, not command line
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi
