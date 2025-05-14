#!/bin/bash
set -e

# Update and install dependencies
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq

# Install Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
DOCKER_COMPOSE_VERSION="v2.20.3"
curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory and initialization directories
mkdir -p /opt/pgeonui
mkdir -p /opt/pgeonui/initdb

# Create docker-compose.yml from template
cat > /opt/pgeonui/docker-compose.yml << 'EOF'
${docker_compose_content}
EOF

# Create init.sql in the initdb directory
cat > /opt/pgeonui/initdb/init.sql << 'EOF'
${init_sql_content}
EOF

# Create .env file with environment variables
cat > /opt/pgeonui/.env << EOF
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
POSTGRES_DB=${postgres_db}
APP_DOCKER_IMAGE=${app_docker_image}
EOF

# Create systemd service for Docker Compose
cat > /etc/systemd/system/pgeonui.service << EOF
[Unit]
Description=PGeonUI Docker Compose Application
Requires=docker.service
After=docker.service

[Service]
WorkingDirectory=/opt/pgeonui
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
Restart=always
RestartSec=10s
Type=simple
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable pgeonui.service
systemctl start pgeonui.service

echo "Setup completed successfully!"
