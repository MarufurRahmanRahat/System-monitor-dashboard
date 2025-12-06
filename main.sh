#!/bin/bash

# Description: Real-time system monitoring tool
# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# Function to get CPU usage
get_cpu_usage() {
    # Read CPU stats from /proc/stat
    cpu_line=$(grep '^cpu ' /proc/stat)
    
    # Extract values
    user=$(echo $cpu_line | awk '{print $2}')
    nice=$(echo $cpu_line | awk '{print $3}')
    system=$(echo $cpu_line | awk '{print $4}')
    idle=$(echo $cpu_line | awk '{print $5}')
    
    # Calculate total and usage
    total=$((user + nice + system + idle))
    used=$((user + nice + system))
    
    # Calculate percentage
    if [ $total -gt 0 ]; then
        cpu_percent=$((used * 100 / total))
    else
        cpu_percent=0
    fi
    
    echo $cpu_percent
}


# Function to get Memory usage
get_memory_usage() {
    # Read from /proc/meminfo
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    
    # Calculate used memory
    mem_used=$((mem_total - mem_available))
    
    # Calculate percentage
    mem_percent=$((mem_used * 100 / mem_total))
    
    # Convert to GB
    mem_total_gb=$(echo "scale=1; $mem_total/1024/1024" | bc)
    mem_used_gb=$(echo "scale=1; $mem_used/1024/1024" | bc)
    
    echo "$mem_percent $mem_used_gb $mem_total_gb"
}


 Function to get Disk usage
get_disk_usage() {
    # Get disk usage for root partition
    disk_info=$(df -h / | tail -1)
    disk_used=$(echo $disk_info | awk '{print $3}')
    disk_total=$(echo $disk_info | awk '{print $2}')
    disk_percent=$(echo $disk_info | awk '{print $5}' | tr -d '%')
    
    echo "$disk_percent $disk_used $disk_total"
}

# Function to create progress bar
create_progress_bar() {
    local percent=$1
    local bar_length=20
    local filled=$((percent * bar_length / 100))
    local empty=$((bar_length - filled))
    
    # Create bar
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]"
}


# Function to get color based on percentage
get_color() {
    local percent=$1
    if [ $percent -lt 50 ]; then
        echo -e "${GREEN}"
    elif [ $percent -lt 80 ]; then
        echo -e "${YELLOW}"
    else
        echo -e "${RED}"
    fi
}


# Function to display dashboard
display_dashboard() {
    clear
    
    # Header
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           SYSTEM MONITOR DASHBOARD v1.0                    ║${NC}"
    echo -e "${BLUE}║           $(date '+%Y-%m-%d %H:%M:%S')                              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get CPU info
    cpu_percent=$(get_cpu_usage)
    cpu_color=$(get_color $cpu_percent)
    echo -e "${cpu_color}CPU Usage:${NC}     $(create_progress_bar $cpu_percent) ${cpu_color}${cpu_percent}%${NC}"
    echo ""
    
    # Get Memory info
    read mem_percent mem_used mem_total <<< $(get_memory_usage)
    mem_color=$(get_color $mem_percent)
    echo -e "${mem_color}Memory:${NC}        $(create_progress_bar $mem_percent) ${mem_color}${mem_percent}%${NC} (${mem_used}GB / ${mem_total}GB)"
    echo ""
    
    # Get Disk info
    read disk_percent disk_used disk_total <<< $(get_disk_usage)
    disk_color=$(get_color $disk_percent)
    echo -e "${disk_color}Disk Usage:${NC}    $(create_progress_bar $disk_percent) ${disk_color}${disk_percent}%${NC} (${disk_used} / ${disk_total})"
    echo ""
    
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
}


# Main loop
main() {
    echo "Starting System Monitor..."
    sleep 1
    
    # Infinite loop for real-time monitoring
    while true; do
        display_dashboard
        sleep 2  # Update every 2 seconds
    done
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${GREEN}Monitor stopped. Goodbye!${NC}"; exit 0' INT

# Run main function
main
