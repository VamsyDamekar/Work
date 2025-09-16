#!/bin/bash
# Start MySQL Exporter
# Ensure mysqld_exporter binary is in PATH or provide full path

./mysqld_exporter --config.my-cnf=../mysql/my.cnf

#Make executable:
chmod +x scripts/start_exporter.sh
