#!/bin/bash
# modules/security.sh
# Security and Error Detection Module

# Check system security status
check_security_status() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              SECURITY STATUS CHECK                         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Current user info
    echo -e "${CYAN}Current User:${NC}"
    echo "  Username: $(whoami)"
    echo "  UID: $(id -u)"
    echo "  Groups: $(groups)"
    echo ""
    
    # Check for root processes from non-root users
    echo -e "${CYAN}Security Check - Root Processes:${NC}"
    root_count=$(ps aux | grep "^root" | wc -l)
    echo "  Total root processes: $root_count"
    
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "  ${RED}⚠️  WARNING: Running as root!${NC}"
    else
        echo -e "  ${GREEN}✓ Running as non-root user (Safe)${NC}"
    fi
    echo ""
    
    # Check for suspicious processes
    echo -e "${CYAN}Checking for suspicious activity...${NC}"
    suspicious=0
    
    # Check for processes with unusual nice values
    abnormal_nice=$(ps -eo pid,ni,comm | awk '$2 < -10 || $2 > 15' | wc -l)
    if [ $abnormal_nice -gt 1 ]; then
        echo -e "  ${YELLOW}⚠️  Found $abnormal_nice processes with unusual priorities${NC}"
        suspicious=$((suspicious + 1))
    fi
    
    if [ $suspicious -eq 0 ]; then
        echo -e "  ${GREEN}✓ No suspicious activity detected${NC}"
    fi
    echo ""
    
    # Log security check
    echo "[$(date)] Security check: User=$(whoami), Root processes=$root_count, Suspicious=$suspicious" >> logs/security.log
}

# File permission checker
check_file_permissions() {
    local file=$1
    
    echo -e "\n${CYAN}Checking file permissions: $file${NC}"
    
    if [ ! -e "$file" ]; then
        echo -e "${RED}✗ File does not exist${NC}"
        return 1
    fi
    
    # Get file info
    perms=$(stat -c "%a" "$file" 2>/dev/null)
    owner=$(stat -c "%U" "$file" 2>/dev/null)
    
    echo "  Permissions: $perms"
    echo "  Owner: $owner"
    echo "  Current user: $(whoami)"
    
    # Check if readable
    if [ -r "$file" ]; then
        echo -e "  ${GREEN}✓ Readable${NC}"
    else
        echo -e "  ${RED}✗ Not readable${NC}"
    fi
    
    # Check if writable
    if [ -w "$file" ]; then
        echo -e "  ${GREEN}✓ Writable${NC}"
    else
        echo -e "  ${YELLOW}! Not writable${NC}"
    fi
    
    # Check if executable
    if [ -x "$file" ]; then
        echo -e "  ${GREEN}✓ Executable${NC}"
    else
        echo -e "  ${YELLOW}! Not executable${NC}"
    fi
    
    # Log permission check
    echo "[$(date)] Permission check: $file | Perms=$perms | Owner=$owner" >> logs/security.log
}

# Validate command before execution (security feature)
validate_command() {
    local cmd=$1
    
    echo -e "\n${CYAN}Validating command: $cmd${NC}"
    
    # Blacklist of dangerous commands
    local blacklist=(
        "rm -rf /"
        "mkfs"
        "dd if=/dev/zero"
        ":(){:|:&};:"  # Fork bomb
        "chmod 777"
    )
    
    # Check against blacklist
    for dangerous in "${blacklist[@]}"; do
        if [[ "$cmd" == *"$dangerous"* ]]; then
            echo -e "${RED}✗ BLOCKED: Dangerous command detected!${NC}"
            echo "  Reason: Contains '$dangerous'"
            echo "[$(date)] SECURITY: Blocked command: $cmd" >> logs/security.log
            return 1
        fi
    done
    
    echo -e "${GREEN}✓ Command validated${NC}"
    return 0
}

# Monitor and detect errors
monitor_errors() {
    echo -e "\n${YELLOW}=== Error Detection Monitor ===${NC}"
    echo "Monitoring system for errors (10 seconds)..."
    echo ""
    
    # Monitor dmesg for kernel errors
    echo -e "${CYAN}Checking kernel messages:${NC}"
    recent_errors=$(dmesg -T 2>/dev/null | tail -20 | grep -i "error\|fail\|warn" | wc -l)
    
    if [ $recent_errors -gt 0 ]; then
        echo -e "  ${YELLOW}⚠️  Found $recent_errors recent error/warning messages${NC}"
        dmesg -T 2>/dev/null | tail -5 | grep -i "error\|fail\|warn"
    else
        echo -e "  ${GREEN}✓ No recent kernel errors${NC}"
    fi
    echo ""
    
    # Check for failed processes in logs
    if [ -f logs/error.log ]; then
        echo -e "${CYAN}Application errors:${NC}"
        error_count=$(wc -l < logs/error.log)
        echo "  Total errors logged: $error_count"
        
        if [ $error_count -gt 0 ]; then
            echo "  Recent errors:"
            tail -3 logs/error.log | sed 's/^/    /'
        fi
    fi
    
    echo ""
    echo "[$(date)] Error monitor: Kernel errors=$recent_errors" >> logs/security.log
}

# Demonstrate error handling
demo_error_handling() {
    echo -e "\n${YELLOW}=== Error Handling Demo ===${NC}"
    echo ""
    
    # Create a task that will fail
    echo "Starting task that will intentionally fail..."
    
    (
        echo "Task started (PID $$)"
        sleep 2
        echo "Simulating error..."
        exit 1  # Exit with error code
    ) &
    
    task_pid=$!
    
    # Monitor the task
    wait $task_pid
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ Task failed with exit code: $exit_code${NC}"
        echo "[$(date)] ERROR: Task PID $task_pid failed with code $exit_code" >> logs/error.log
        
        # Error recovery
        echo ""
        echo "Initiating error recovery..."
        sleep 1
        echo -e "${GREEN}✓ Error logged and handled${NC}"
    else
        echo -e "${GREEN}✓ Task completed successfully${NC}"
    fi
}

# Process crash detector
detect_process_crash() {
    local pid=$1
    local process_name=$2
    
    echo -e "\n${CYAN}Monitoring process: $process_name (PID: $pid)${NC}"
    
    # Monitor for a few seconds
    for i in {1..5}; do
        if ! kill -0 $pid 2>/dev/null; then
            echo -e "${RED}✗ Process crashed!${NC}"
            echo "[$(date)] CRASH: Process $process_name (PID $pid) terminated unexpectedly" >> logs/error.log
            
            # Could implement auto-restart here
            echo "  Would normally trigger auto-restart..."
            return 1
        fi
        echo "  Check $i/5: Process alive"
        sleep 1
    done
    
    echo -e "${GREEN}✓ Process stable${NC}"
    return 0
}

# Show security logs
show_security_logs() {
    echo -e "\n${BLUE}════════ SECURITY LOGS ════════${NC}"
    echo ""
    
    if [ -f logs/security.log ]; then
        echo -e "${CYAN}Recent security events:${NC}"
        tail -10 logs/security.log
    else
        echo "No security logs available yet."
    fi
    echo ""
    
    if [ -f logs/error.log ]; then
        echo -e "${RED}Recent errors:${NC}"
        tail -10 logs/error.log
    else
        echo "No error logs available yet."
    fi
}

export -f check_security_status
export -f check_file_permissions
export -f validate_command
export -f monitor_errors
export -f demo_error_handling
export -f detect_process_crash
export -f show_security_logs
