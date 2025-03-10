#!/bin/bash

# Chaos testing script for DevBox development environment
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

print_warning() {
    echo -e "\e[93m[WARNING] $1\e[0m"
}

# Stop a service
stop_service() {
    local service=$1
    print_info "Stopping $service service..."
    cd "$PROJECT_ROOT/docker"
    docker-compose stop $service
    print_warning "$service service is now stopped"
}

# Start a service
start_service() {
    local service=$1
    print_info "Starting $service service..."
    cd "$PROJECT_ROOT/docker"
    docker-compose start $service
    print_success "$service service is now running"
}

# Simulate high CPU load
simulate_high_cpu() {
    local service=$1
    local duration=$2
    
    print_info "Simulating high CPU load on $service for $duration seconds..."
    
    docker_id=$(docker-compose -f "$PROJECT_ROOT/docker/docker-compose.yml" ps -q $service)
    
    if [ -z "$docker_id" ]; then
        print_error "Service $service is not running"
    fi
    
    # Run stress test
    docker exec $docker_id sh -c "apt-get update && apt-get install -y stress-ng && stress-ng --cpu 4 --timeout ${duration}s" &
    
    print_warning "High CPU load simulation in progress. Will stop after $duration seconds."
    sleep $duration
    print_success "High CPU load simulation completed"
}

# Simulate network latency
simulate_network_latency() {
    local service=$1
    local latency=$2
    local duration=$3
    
    print_info "Simulating ${latency}ms network latency on $service for $duration seconds..."
    
    docker_id=$(docker-compose -f "$PROJECT_ROOT/docker/docker-compose.yml" ps -q $service)
    
    if [ -z "$docker_id" ]; then
        print_error "Service $service is not running"
    fi
    
    # Install tc if not exists
    docker exec $docker_id sh -c "apt-get update && apt-get install -y iproute2" > /dev/null
    
    # Add latency
    docker exec $docker_id sh -c "tc qdisc add dev eth0 root netem delay ${latency}ms"
    
    print_warning "Network latency simulation in progress. Will stop after $duration seconds."
    sleep $duration
    
    # Remove latency
    docker exec $docker_id sh -c "tc qdisc del dev eth0 root" || true
    
    print_success "Network latency simulation completed"
}

# Simulate memory pressure
simulate_memory_pressure() {
    local service=$1
    local memory_mb=$2
    local duration=$3
    
    print_info "Simulating memory pressure (${memory_mb}MB) on $service for $duration seconds..."
    
    docker_id=$(docker-compose -f "$PROJECT_ROOT/docker/docker-compose.yml" ps -q $service)
    
    if [ -z "$docker_id" ]; then
        print_error "Service $service is not running"
    fi
    
    # Run memory stress test
    docker exec $docker_id sh -c "apt-get update && apt-get install -y stress-ng && stress-ng --vm 1 --vm-bytes ${memory_mb}M --timeout ${duration}s" &
    
    print_warning "Memory pressure simulation in progress. Will stop after $duration seconds."
    sleep $duration
    print_success "Memory pressure simulation completed"
}

# Display menu
show_menu() {
    echo ""
    echo "DevBox Chaos Testing Tool"
    echo "========================="
    echo "1. Stop a service"
    echo "2. Start a service"
    echo "3. Simulate high CPU load"
    echo "4. Simulate network latency"
    echo "5. Simulate memory pressure"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice: " choice
    
    case $choice in
        1)
            read -p "Enter service name (app, db, cache, web): " service
            stop_service $service
            show_menu
            ;;
        2)
            read -p "Enter service name (app, db, cache, web): " service
            start_service $service
            show_menu
            ;;
        3)
            read -p "Enter service name (app, db, cache, web): " service
            read -p "Enter duration in seconds: " duration
            simulate_high_cpu $service $duration
            show_menu
            ;;
        4)
            read -p "Enter service name (app, db, cache, web): " service
            read -p "Enter latency in milliseconds: " latency
            read -p "Enter duration in seconds: " duration
            simulate_network_latency $service $latency $duration
            show_menu
            ;;
        5)
            read -p "Enter service name (app, db, cache, web): " service
            read -p "Enter memory to consume in MB: " memory_mb
            read -p "Enter duration in seconds: " duration
            simulate_memory_pressure $service $memory_mb $duration
            show_menu
            ;;
        0)
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            show_menu
            ;;
    esac
}

# Main function
main() {
    print_info "DevBox Chaos Testing Tool"
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
    fi
    
    # Check if docker-compose environment is running
    cd "$PROJECT_ROOT/docker"
    if [ -z "$(docker-compose ps -q)" ]; then
        print_error "DevBox environment is not running. Please start it with 'docker-compose up -d' first."
    fi
    
    show_menu
}

# Run main function
main