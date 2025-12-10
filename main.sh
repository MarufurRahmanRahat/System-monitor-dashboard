#!/bin/bash
# System Monitor Dashboard - Day 2 Enhanced Version
# Now includes: Process Management, IPC Demos

# Source the modules
source modules/process_mgr.sh 2>/dev/null || echo "Note: process_mgr.sh not found"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Create logs directory
mkdir -p logs

# [Previous functions from Day 1 - get_cpu_usage, get_memory_usage, etc.]
get_cpu_usage() {
    cpu_line=$(grep '^cpu ' /proc/stat)
    user=$(echo $cpu_line | awk '{print $2}')
    nice=$(echo $cpu_line | awk '{print $3}')
    system=$(echo $cpu_line | awk '{print $4}')
    idle=$(echo $cpu_line | awk '{print $5}')
    total=$((user + nice + system + idle))
    used=$((user + nice + system))
    if [ $total -gt 0 ]; then
        cpu_percent=$((used * 100 / total))
    else
        cpu_percent=0
    fi
    echo $cpu_percent
}

get_memory_usage() {
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_used=$((mem_total - mem_available))
    mem_percent=$((mem_used * 100 / mem_total))
    mem_total_gb=$(echo "scale=1; $mem_total/1024/1024" | bc)
    mem_used_gb=$(echo "scale=1; $mem_used/1024/1024" | bc)
    echo "$mem_percent $mem_used_gb $mem_total_gb"
}

create_progress_bar() {
    local percent=$1
    local bar_length=20
    local filled=$((percent * bar_length / 100))
    local empty=$((bar_length - filled))
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]"
}

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

# Enhanced dashboard with processes
display_enhanced_dashboard() {
    clear
    
    # Header
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         SYSTEM MONITOR DASHBOARD v2.0 (Enhanced)          ║${NC}"
    echo -e "${BLUE}║         $(date '+%Y-%m-%d %H:%M:%S')                              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System Resources
    cpu_percent=$(get_cpu_usage)
    cpu_color=$(get_color $cpu_percent)
    echo -e "${cpu_color}CPU Usage:${NC}     $(create_progress_bar $cpu_percent) ${cpu_color}${cpu_percent}%${NC}"
    
    read mem_percent mem_used mem_total <<< $(get_memory_usage)
    mem_color=$(get_color $mem_percent)
    echo -e "${mem_color}Memory:${NC}        $(create_progress_bar $mem_percent) ${mem_color}${mem_percent}%${NC} (${mem_used}GB / ${mem_total}GB)"
    
    # Process info
    echo ""
    echo -e "${CYAN}Processes:${NC}     $(get_process_count)"
    
    # Top processes
    get_top_processes
    
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop | Press 'd' for demo menu${NC}"
}

# Interactive menu
show_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              SYSTEM MONITOR - DEMO MENU                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "1. Live Monitor (Real-time)"
    echo "2. Process Creation Demo"
    echo "3. IPC (Inter-Process Communication) Demo"
    echo "4. Signal Handling Demo"
    echo "5. Process Tree View"
    echo "6. View Logs"
    echo "7. Exit"
    echo ""
    echo -n "Select option: "
    read choice
    
    case $choice in
        1)
            monitor_mode
            ;;
        2)
            demo_child_process
            echo ""
            read -p "Press Enter to continue..."
            show_menu
            ;;
        3)
            demo_ipc
            echo ""
            read -p "Press Enter to continue..."
            show_menu
            ;;
        4)
            demo_signals
            echo ""
            read -p "Press Enter to continue..."
            show_menu
            ;;
        5)
            show_process_tree
            echo ""
            read -p "Press Enter to continue..."
            show_menu
            ;;
        6)
            view_logs
            ;;
        7)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            sleep 1
            show_menu
            ;;
    esac
}

# Monitor mode
monitor_mode() {
    echo "Starting real-time monitor..."
    sleep 1
    
    while true; do
        display_enhanced_dashboard
        sleep 2
    done
}

# View logs
view_logs() {
    clear
    echo -e "${BLUE}════════ SYSTEM LOGS ════════${NC}"
    echo ""
    
    if [ -f logs/process.log ]; then
        echo -e "${CYAN}Process Logs:${NC}"
        tail -10 logs/process.log
        echo ""
    fi
    
    if [ -f logs/ipc.log ]; then
        echo -e "${CYAN}IPC Logs:${NC}"
        tail -10 logs/ipc.log
        echo ""
    fi
    
    read -p "Press Enter to continue..."
    show_menu
}

# Trap Ctrl+C
trap 'echo -e "\n${GREEN}Returning to menu...${NC}"; sleep 1; show_menu' INT

# Main entry point
main() {
    # Initialize
    mkdir -p logs
    
    echo -e "${GREEN}System Monitor Dashboard Starting...${NC}"
    sleep 1
    
    # Show menu
    show_menu
}

# Run
main
