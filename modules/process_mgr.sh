#!/bin/bash
# Process Management Module
# Get top processes by CPU
get_top_processes() {
    echo -e "\n${BLUE}════════ TOP PROCESSES (CPU) ════════${NC}"
    printf "%-8s %-20s %-8s %-8s\n" "PID" "NAME" "CPU%" "MEM%"
    echo "────────────────────────────────────────────────"
    
    # Get top 5 processes
    ps aux --sort=-%cpu | head -6 | tail -5 | while read line; do
        pid=$(echo $line | awk '{print $2}')
        name=$(echo $line | awk '{print $11}' | cut -c1-20)
        cpu=$(echo $line | awk '{print $3}')
        mem=$(echo $line | awk '{print $4}')
        
        printf "%-8s %-20s %-8s %-8s\n" "$pid" "$name" "$cpu%" "$mem%"
    done
}


#Get total process count
get_process_count() {
    total=$(ps aux | wc -l)
    running=$(ps aux | grep -c " R ")
    sleeping=$(ps aux | grep -c " S ")
    
    echo "Total: $total | Running: $running | Sleeping: $sleeping"
}



# Create a demo child process (for process concept demonstration)
demo_child_process() {
    echo -e "\n${YELLOW}=== Process Creation Demo ===${NC}"
    echo "Creating child process..."
    
    # Create background process
    (
        echo "Child process started: PID $$"
        sleep 5
        echo "Child process completed: PID $$"
    ) &
    
    child_pid=$!
    echo "Parent process: PID $$"
    echo "Child process created: PID $child_pid"
    
    # Monitor child
    if ps -p $child_pid > /dev/null 2>&1; then
        echo "Child process is RUNNING"
    fi
    
    # Wait for child
    wait $child_pid
    echo "Child process TERMINATED"
    
    # Log to file (demonstrates file system)
    echo "[$(date)] Child process $child_pid completed" >> logs/process.log
}

# Demonstrate IPC using named pipes
demo_ipc() {
    echo -e "\n${YELLOW}=== Inter-Process Communication Demo ===${NC}"
    
    # Create named pipe
    pipe_name="/tmp/monitor_pipe_$$"
    mkfifo $pipe_name 2>/dev/null
    
    echo "Created pipe: $pipe_name"
    
    # Process 1: Writer (background)
    (
        echo "Process 1 (PID $$): Sending message..."
        echo "Hello from Process 1" > $pipe_name
        echo "Process 1 (PID $$): Message sent!"
    ) &
    
    sender_pid=$!
    
    # Small delay
    sleep 1
    
    # Process 2: Reader
    (
        echo "Process 2 (PID $$): Waiting for message..."
        message=$(cat $pipe_name)
        echo "Process 2 (PID $$): Received: '$message'"
    ) &
    
    receiver_pid=$!
    
    # Wait for both processes
    wait $sender_pid
    wait $receiver_pid
    
    # Cleanup
    rm -f $pipe_name
    
    echo -e "${GREEN}✓ IPC Demo completed successfully!${NC}"
    
    # Log IPC activity
    echo "[$(date)] IPC demo: Processes $sender_pid -> $receiver_pid" >> logs/ipc.log
}



# Demonstrate process signals
demo_signals() {
    echo -e "\n${YELLOW}=== Signal Handling Demo ===${NC}"
    
    # Create a long-running process
    (
        trap 'echo "Received SIGUSR1 signal!"; exit 0' SIGUSR1
        echo "Background process started: PID $$"
        sleep 30
    ) &
    
    bg_pid=$!
    echo "Created background process: PID $bg_pid"
    
    sleep 2
    echo "Sending SIGUSR1 signal to process $bg_pid..."
    kill -SIGUSR1 $bg_pid 2>/dev/null
    
    wait $bg_pid 2>/dev/null
    echo -e "${GREEN}✓ Signal handled successfully!${NC}"
}

# Show process tree
show_process_tree() {
    echo -e "\n${BLUE}════════ PROCESS TREE ════════${NC}"
    pstree -p $$ | head -10
}

# Export functions
export -f get_top_processes
export -f get_process_count
export -f demo_child_process
export -f demo_ipc
export -f demo_signals
export -f show_process_tree

