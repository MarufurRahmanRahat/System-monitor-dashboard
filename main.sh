#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  SYSTEM MONITOR DASHBOARD - COMPLETE VERSION
#  Covers: Process, IPC, Scheduling, Accounting, File System,
#          Security, Error Detection
# ═══════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Initialize
mkdir -p logs demos
LOG_FILE="logs/system.log"
ERROR_LOG="logs/error.log"
SECURITY_LOG="logs/security.log"
ACCOUNTING_LOG="logs/accounting.log"

# ═══════════════════════════════════════════════════════════════
# SYSTEM MONITORING FUNCTIONS
# ═══════════════════════════════════════════════════════════════

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}'
}

get_memory_info() {
    free -m | awk 'NR==2{printf "%d %d %d", $3*100/$2, $3, $2}'
}

get_disk_info() {
    df -h / | awk 'NR==2{printf "%s %s %s", substr($5,1,length($5)-1), $3, $2}'
}

create_bar() {
    local percent=$1
    local width=25
    local filled=$((percent * width / 100))
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%$((width - filled))s" | tr ' ' '░'
    printf "]"
}

get_status_color() {
    local val=$1
    [ $val -lt 50 ] && echo "$GREEN" || [ $val -lt 80 ] && echo "$YELLOW" || echo "$RED"
}

# ═══════════════════════════════════════════════════════════════
# PROCESS MANAGEMENT
# ═══════════════════════════════════════════════════════════════

show_top_processes() {
    echo -e "${CYAN}Top Processes by CPU:${NC}"
    printf "%-8s %-25s %-8s %-8s\n" "PID" "NAME" "CPU%" "MEM%"
    echo "───────────────────────────────────────────────────────"
    ps aux --sort=-%cpu | awk 'NR>1 && NR<=6 {printf "%-8s %-25s %-8s %-8s\n", $2, substr($11,1,25), $3"%", $4"%"}'
}

demo_process_lifecycle() {
    echo -e "\n${YELLOW}╔═══ DEMO 1: Process Lifecycle ═══╗${NC}"
    echo ""
    
    # Create child process
    (
        echo "[Child] Process created: PID $$"
        echo "[Child] State: Running"
        sleep 3
        echo "[Child] Executing task..."
        sleep 2
        echo "[Child] Task completed"
    ) &
    
    child_pid=$!
    echo "[Parent] Created child process: PID $child_pid"
    echo "[Parent] Monitoring child..."
    
    # Monitor child state
    sleep 1
    if ps -p $child_pid > /dev/null; then
        state=$(ps -o state= -p $child_pid)
        echo "[Parent] Child state from /proc: $state"
    fi
    
    wait $child_pid
    echo "[Parent] Child process terminated"
    echo -e "${GREEN}✓ Process lifecycle complete${NC}"
    
    echo "[$(date)] Process demo: PID $child_pid lifecycle" >> $LOG_FILE
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# INTER-PROCESS COMMUNICATION
# ═══════════════════════════════════════════════════════════════

demo_ipc_pipes() {
    echo -e "\n${YELLOW}╔═══ DEMO 2: Inter-Process Communication (Pipes) ═══╗${NC}"
    echo ""
    
    PIPE="/tmp/demo_pipe_$$"
    mkfifo $PIPE
    echo "Created named pipe: $PIPE"
    echo ""
    
    # Sender process
    (
        sleep 1
        echo "[Sender PID $$] Preparing message..."
        message="Hello from Process $$"
        echo "$message" > $PIPE
        echo "[Sender] Message sent: '$message'"
    ) &
    sender=$!
    
    # Receiver process
    (
        echo "[Receiver PID $$] Waiting for message..."
        message=$(cat $PIPE)
        echo "[Receiver] Message received: '$message'"
    ) &
    receiver=$!
    
    wait $sender $receiver
    rm -f $PIPE
    
    echo ""
    echo -e "${GREEN}✓ IPC demonstration complete${NC}"
    echo "[$(date)] IPC demo: $sender -> $receiver via pipe" >> $LOG_FILE
    read -p "Press Enter to continue..."
}

demo_signals() {
    echo -e "\n${YELLOW}╔═══ DEMO 3: Signal Handling ═══╗${NC}"
    echo ""
    
    (
        trap 'echo "[Process $$] Received SIGUSR1!"; exit 0' SIGUSR1
        echo "[Process $$] Started, waiting for signal..."
        sleep 30
    ) &
    
    target=$!
    echo "Target process: PID $target"
    sleep 2
    
    echo "Sending SIGUSR1 signal..."
    kill -SIGUSR1 $target
    wait $target 2>/dev/null
    
    echo -e "${GREEN}✓ Signal handled successfully${NC}"
    echo "[$(date)] Signal demo: SIGUSR1 sent to $target" >> $LOG_FILE
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# SCHEDULING
# ═══════════════════════════════════════════════════════════════

demo_scheduling() {
    echo -e "\n${YELLOW}╔═══ DEMO 4: Process Scheduling (Priority) ═══╗${NC}"
    echo ""
    
    echo "Creating processes with different priorities..."
    echo ""
    
    # High priority
    nice -n -5 bash -c '
        echo "[HIGH -5] PID $$ started"
        sleep 3
        echo "[HIGH -5] Completed"
    ' 2>/dev/null &
    high=$!
    
    # Normal priority
    bash -c '
        echo "[NORMAL 0] PID $$ started"
        sleep 3
        echo "[NORMAL 0] Completed"
    ' &
    norm=$!
    
    # Low priority
    nice -n 10 bash -c '
        echo "[LOW +10] PID $$ started"
        sleep 3
        echo "[LOW +10] Completed"
    ' &
    low=$!
    
    echo ""
    echo -e "${CYAN}Priority Information:${NC}"
    ps -o pid,ni,comm -p $high,$norm,$low 2>/dev/null
    
    wait $high $norm $low 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✓ Scheduling demonstration complete${NC}"
    echo "Note: Higher priority (lower nice value) gets more CPU time"
    echo "[$(date)] Scheduling demo: PIDs $high,$norm,$low" >> $LOG_FILE
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# RESOURCE ACCOUNTING
# ═══════════════════════════════════════════════════════════════

demo_accounting() {
    echo -e "\n${YELLOW}╔═══ DEMO 5: Resource Accounting ═══╗${NC}"
    echo ""
    
    echo "Starting resource-intensive task..."
    
    # CPU-intensive task
    (
        for i in {1..1000000}; do
            echo "scale=100; 4*a(1)" | bc -l > /dev/null 2>&1
        done
    ) &
    
    task_pid=$!
    start=$(date +%s)
    
    echo "Tracking resources for PID $task_pid..."
    echo ""
    
    # Monitor resources
    for i in {1..5}; do
        if kill -0 $task_pid 2>/dev/null; then
            cpu=$(ps -p $task_pid -o %cpu --no-headers 2>/dev/null || echo "0")
            mem=$(ps -p $task_pid -o %mem --no-headers 2>/dev/null || echo "0")
            echo "  Sample $i: CPU=${cpu}% MEM=${mem}%"
            sleep 1
        fi
    done
    
    wait $task_pid 2>/dev/null
    end=$(date +%s)
    duration=$((end - start))
    
    echo ""
    echo "Task Duration: ${duration}s"
    echo "[$(date)] Accounting: PID $task_pid | Duration: ${duration}s" >> $ACCOUNTING_LOG
    echo -e "${GREEN}✓ Resource accounting complete${NC}"
    read -p "Press Enter to continue..."
}

show_accounting_report() {
    echo -e "\n${BLUE}╔════════ RESOURCE ACCOUNTING REPORT ════════╗${NC}"
    echo ""
    
    if [ -f $ACCOUNTING_LOG ]; then
        total=$(wc -l < $ACCOUNTING_LOG)
        echo "Total tasks tracked: $total"
        echo ""
        echo "Recent tasks:"
        tail -5 $ACCOUNTING_LOG
    else
        echo "No accounting data available."
    fi
    
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# FILE SYSTEM
# ═══════════════════════════════════════════════════════════════

demo_filesystem() {
    echo -e "\n${YELLOW}╔═══ DEMO 6: File System Operations ═══╗${NC}"
    echo ""
    
    echo -e "${CYAN}Reading from /proc filesystem:${NC}"
    echo "  Current process: PID $$"
    echo "  Status file: /proc/$$/status"
    
    # Read process status
    if [ -r /proc/$$/status ]; then
        echo ""
        echo "Process information from /proc:"
        grep -E "Name|State|Pid|PPid|VmSize|VmRSS" /proc/$$/status | sed 's/^/  /'
    fi
    
    echo ""
    echo -e "${CYAN}File System Usage:${NC}"
    df -h / | awk 'NR==2{printf "  Root: %s used of %s (%s)\n", $3, $2, $5}'
    
    echo ""
    echo -e "${CYAN}Creating test file:${NC}"
    test_file="logs/test_$$.txt"
    echo "Test data $(date)" > $test_file
    echo "  Created: $test_file"
    echo "  Permissions: $(stat -c %a $test_file)"
    echo "  Owner: $(stat -c %U $test_file)"
    
    echo "[$(date)] Filesystem demo: created $test_file" >> $LOG_FILE
    echo -e "${GREEN}✓ File system demo complete${NC}"
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# SECURITY & PROTECTION
# ═══════════════════════════════════════════════════════════════

demo_security() {
    echo -e "\n${YELLOW}╔═══ DEMO 7: Security & Protection ═══╗${NC}"
    echo ""
    
    echo -e "${CYAN}Current User Context:${NC}"
    echo "  Username: $(whoami)"
    echo "  UID: $(id -u)"
    echo "  GID: $(id -g)"
    
    if [ $(id -u) -eq 0 ]; then
        echo -e "  ${RED}⚠️  WARNING: Running as root!${NC}"
    else
        echo -e "  ${GREEN}✓ Running as regular user${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Permission Check:${NC}"
    test_script="demos/test.sh"
    echo "#!/bin/bash" > $test_script
    echo "echo 'Test script'" >> $test_script
    
    if [ -x $test_script ]; then
        echo "  $test_script: Executable"
    else
        echo "  $test_script: Not executable (setting +x)"
        chmod +x $test_script
    fi
    
    echo ""
    echo -e "${CYAN}Command Validation:${NC}"
    dangerous_cmd="rm -rf /"
    echo "  Testing: '$dangerous_cmd'"
    
    if [[ "$dangerous_cmd" == *"rm -rf /"* ]]; then
        echo -e "  ${RED}✗ BLOCKED: Dangerous command!${NC}"
        echo "[$(date)] SECURITY: Blocked dangerous command" >> $SECURITY_LOG
    fi
    
    echo ""
    echo -e "${GREEN}✓ Security checks complete${NC}"
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# ERROR DETECTION & LOGGING
# ═══════════════════════════════════════════════════════════════

demo_error_handling() {
    echo -e "\n${YELLOW}╔═══ DEMO 8: Error Detection & Handling ═══╗${NC}"
    echo ""
    
    echo "Starting task that will fail..."
    
    (
        echo "[Task PID $$] Starting..."
        sleep 2
        echo "[Task PID $$] Simulating error..."
        exit 1
    ) &
    
    task=$!
    wait $task
    code=$?
    
    if [ $code -ne 0 ]; then
        echo -e "${RED}✗ Task failed with code: $code${NC}"
        echo "[$(date)] ERROR: Task $task failed (code $code)" >> $ERROR_LOG
        
        echo ""
        echo "Error recovery initiated..."
        sleep 1
        echo -e "${GREEN}✓ Error logged successfully${NC}"
    fi
    
    echo ""
    echo "Error log entries:"
    tail -3 $ERROR_LOG 2>/dev/null || echo "  No errors logged yet"
    
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# REAL-TIME MONITOR
# ═══════════════════════════════════════════════════════════════

live_monitor() {
    while true; do
        clear
        echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║        SYSTEM MONITOR - REAL-TIME DASHBOARD               ║${NC}"
        echo -e "${BLUE}║        $(date '+%Y-%m-%d %H:%M:%S')                              ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # CPU
        cpu=$(get_cpu_usage)
        color=$(get_status_color $cpu)
        echo -e "${color}CPU:${NC}    $(create_bar $cpu) ${color}${cpu}%${NC}"
        
        # Memory
        read mem_p mem_u mem_t <<< $(get_memory_info)
        color=$(get_status_color $mem_p)
        echo -e "${color}Memory:${NC} $(create_bar $mem_p) ${color}${mem_p}%${NC} (${mem_u}MB/${mem_t}MB)"
        
        # Disk
        read disk_p disk_u disk_t <<< $(get_disk_info)
        color=$(get_status_color $disk_p)
        echo -e "${color}Disk:${NC}   $(create_bar $disk_p) ${color}${disk_p}%${NC} (${disk_u}/${disk_t})"
        
        echo ""
        show_top_processes
        
        echo ""
        echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}Press Ctrl+C to return to menu${NC}"
        
        sleep 2
    done
}

# ═══════════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════════

show_main_menu() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          SYSTEM MONITOR - DEMONSTRATION MENU               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Real-Time Monitoring:${NC}"
    echo "  1. Live System Monitor"
    echo ""
    echo -e "${CYAN}OS Concept Demonstrations:${NC}"
    echo "  2. Process Lifecycle"
    echo "  3. Inter-Process Communication (IPC)"
    echo "  4. Signal Handling"
    echo "  5. Process Scheduling"
    echo "  6. Resource Accounting"
    echo "  7. File System Operations"
    echo "  8. Security & Protection"
    echo "  9. Error Detection & Handling"
    echo ""
    echo -e "${CYAN}Reports:${NC}"
    echo "  10. View Logs"
    echo "  11. Accounting Report"
    echo ""
    echo "  0. Exit"
    echo ""
    echo -n "Select option: "
}

view_logs() {
    clear
    echo -e "${BLUE}╔════════ SYSTEM LOGS ════════╗${NC}"
    echo ""
    
    for log in $LOG_FILE $ERROR_LOG $SECURITY_LOG; do
        if [ -f $log ]; then
            echo -e "${CYAN}$(basename $log):${NC}"
            tail -5 $log
            echo ""
        fi
    done
    
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════
# MAIN PROGRAM
# ═══════════════════════════════════════════════════════════════

trap 'echo -e "\n${YELLOW}Returning to menu...${NC}"; sleep 1; return 2>/dev/null || main' INT

main() {
    echo "[$(date)] System Monitor started" >> $LOG_FILE
    
    while true; do
        show_main_menu
        read choice
        
        case $choice in
            1) live_monitor ;;
            2) demo_process_lifecycle ;;
            3) demo_ipc_pipes ;;
            4) demo_signals ;;
            5) demo_scheduling ;;
            6) demo_accounting ;;
            7) demo_filesystem ;;
            8) demo_security ;;
            9) demo_error_handling ;;
            10) view_logs ;;
            11) show_accounting_report ;;
            0) echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
        esac
    done
}

# Start the program
main
