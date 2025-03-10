#!/bin/bash

# Setup script for DevBox development environment
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Print colored output
print_info() {
    echo -e "\e[96m[INFO] $1\e[0m"
}

print_success() {
    echo -e "\e[92m[SUCCESS] $1\e[0m"
}

print_error() {
    echo -e "\e[91m[ERROR] $1\e[0m"
    exit 1
}

# Check required tools
check_requirements() {
    print_info "Checking required tools..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker: https://docs.docker.com/get-docker/"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose: https://docs.docker.com/compose/install/"
    fi
    
    if [[ "$USE_VM" == "true" ]] && ! command -v vagrant &> /dev/null; then
        print_error "Vagrant is not installed. Please install Vagrant: https://www.vagrantup.com/downloads"
    fi
    
    print_success "All required tools are installed."
}

# Setup Docker environment
setup_docker() {
    print_info "Setting up Docker environment..."
    
    cd "$PROJECT_ROOT/docker"
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env 2>/dev/null || echo "Creating default .env file"
        cat > .env << EOF
# Web settings
WEB_PORT=8080

# App settings
APP_PORT=5000

# Database settings
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=devdb
DB_PORT=5432

# Redis settings
REDIS_PORT=6379
EOF
    fi
    
    # Create default nginx config if it doesn't exist
    if [ ! -f nginx/conf/default.conf ]; then
        mkdir -p nginx/conf
        cat > nginx/conf/default.conf << EOF
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /api {
        proxy_pass http://app:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    fi
    
    # Create default index.html
    mkdir -p nginx/html
    if [ ! -f nginx/html/index.html ]; then
        cat > nginx/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>DevBox - Local Development Environment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
        }
        .status {
            padding: 20px;
            background-color: #f5f5f5;
            border-radius: 4px;
            margin: 20px 0;
        }
        .status div {
            margin: 10px 0;
        }
        .healthy {
            color: green;
        }
        .unhealthy {
            color: red;
        }
    </style>
</head>
<body>
    <h1>DevBox - Local Development Environment</h1>
    <p>Welcome to your local development environment!</p>
    
    <div class="status">
        <h2>System Status</h2>
        <div id="status">Loading...</div>
    </div>

    <script>
        // Simple status check
        async function checkStatus() {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                
                let statusHtml = '';
                for (const [service, status] of Object.entries(data)) {
                    const statusClass = status.includes('healthy') ? 'healthy' : 'unhealthy';
                    statusHtml += \`<div><strong>\${service}:</strong> <span class="\${statusClass}">\${status}</span></div>\`;
                }
                
                document.getElementById('status').innerHTML = statusHtml;
            } catch (error) {
                document.getElementById('status').innerHTML = \`<div class="unhealthy">Error connecting to API: \${error.message}</div>\`;
            }
        }
        
        checkStatus();
        setInterval(checkStatus, 5000);
    </script>
</body>
</html>
EOF
    fi
    
    print_success "Docker environment set up successfully."
}

# Setup Vagrant environment if needed
setup_vagrant() {
    if [[ "$USE_VM" == "true" ]]; then
        print_info "Setting up Vagrant environment..."
        cd "$PROJECT_ROOT/vagrant"
        vagrant up
        print_success "Vagrant environment set up successfully."
    fi
}

# Main setup process
main() {
    print_info "Starting DevBox setup..."
    
    # Check if VM should be used
    read -p "Do you want to use a virtual machine for development? (y/N): " use_vm_choice
    if [[ "$use_vm_choice" =~ ^[Yy]$ ]]; then
        USE_VM="true"
    else
        USE_VM="false"
    fi
    
    check_requirements
    setup_docker
    setup_vagrant
    
    if [[ "$USE_VM" == "true" ]]; then
        print_success "Setup complete! To access your environment:"
        echo "1. Run 'cd vagrant && vagrant ssh' to enter the VM"
        echo "2. Inside the VM, run 'cd /vagrant/docker && docker-compose up -d'"
    else
        print_success "Setup complete! To start your environment:"
        echo "Run 'cd docker && docker-compose up -d'"
    fi
    
    echo "Your environment will be available at:"
    echo "- Web: http://localhost:8080"
    echo "- API: http://localhost:5000"
}

# Run main function
main