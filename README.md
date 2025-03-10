# DevBox - Local Development Environment

DevBox is a comprehensive local development environment setup designed for DevOps engineers and developers. It provides a consistent, containerized environment that can be easily shared across team members and closely mimics production environments.

## Features

- **Docker-based containerization** with a complete stack including web server, application server, database, and cache
- **Vagrant VM option** for full virtualization when needed
- **Chaos engineering tools** to test resilience and failure scenarios
- **Easy setup and management** through simple shell scripts
- **Cross-platform compatibility** (works on Linux, macOS, and Windows)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/)
- [Vagrant](https://www.vagrantup.com/downloads) (optional, for VM-based environments)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (required if using Vagrant)

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/devbox.git
cd devbox
```

### 2. Run the setup script

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

This will guide you through setting up either a Docker-only or Vagrant+Docker environment.

### 3. Start the environment

For Docker-only setup:
```bash
cd docker
docker-compose up -d
```

For Vagrant setup:
```bash
cd vagrant
vagrant up
vagrant ssh
cd /vagrant/docker
docker-compose up -d
```

### 4. Access your applications

- Web application: http://localhost:8080
- API: http://localhost:5000
- Database: localhost:5432 (username/password in .env file)
- Redis: localhost:6379

## Project Structure

```
devbox/
├── docker/                  # Docker environment files
│   ├── app/                 # Application code
│   ├── nginx/               # Nginx configuration
│   ├── db/                  # Database initialization scripts
│   ├── docker-compose.yml   # Main Docker Compose configuration
│   └── .env                 # Environment variables
├── vagrant/                 # Vagrant environment files
│   └── Vagrantfile          # Vagrant configuration
├── scripts/                 # Utility scripts
│   ├── setup.sh             # Setup script
│   └── chaos.sh             # Chaos testing script
└── docs/                    # Documentation
```

## Testing Resilience

The project includes a chaos testing tool to simulate various failure scenarios:

```bash
chmod +x scripts/chaos.sh
./scripts/chaos.sh
```

This tool can:
- Stop/start services
- Simulate high CPU load
- Add network latency
- Create memory pressure

## Customization

### Adding New Services

To add a new service, edit the `docker-compose.yml` file and add your service configuration.

### Changing Default Settings

Environment variables can be modified in the `.env` file.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.