#!/bin/bash
# modules/scheduler.sh
# Process Scheduling and Resource Accounting

# Demonstrate process priorities
demo_priority_scheduling() {
    echo -e "\n${YELLOW}=== Priority Scheduling Demo ===${NC}"
    echo "Creating 3 processes with different priorities..."
    echo ""
    
    # High priority process
    nice -n -10 bash -c '
        echo "HIGH Priority Process (PID $$, Nice: -10) - Started"
        for i in {1..5}; do
            echo "  HIGH: Working... $i/5"
            sleep 0.5
        done
        echo "HIGH Priority Process - Completed"
    ' &
    high_pid=$!
    
    # Normal priority process
    bash -c '
        echo "NORMAL Priority Process (PID $$, Nice: 0) - Started"
        for i in {1..5}; do
            echo "  NORMAL: Working... $i/5"
            sleep 0.5
        done
        echo "NORMAL Priority Process - Completed"
    ' &
    normal_pid=$!
    
    # Low priority process
    nice -n 19 bash -c '
        echo "LOW Priority Process (PID $$, Nice: 19) - Started"
        for i in {1..5}; do
            echo "  LOW: Working... $i/5"
            sleep 0.5
        done
        echo "LOW Priority Process - Completed"
    ' &
    low_pid=$!
    
    echo ""
    echo -e "${CYAN}Process Priorities:${NC}"
    ps -o pid,ni,cmd -p $high_pid,$normal_pid,$low_pid
    
    # Wait for all
    wait $high_pid $normal_pid $low_pid
    
    echo ""
    echo -e "${GREEN}✓ All processes completed${NC}"
    echo -e "Note: High priority (-10) gets more CPU time"
    
    # Log scheduling activity
    echo "[$(date)] Priority scheduling demo: PIDs $high_pid,$normal_pid,$low_pid" >> logs/scheduler.log
}

# Resource accounting for a process
track_process_resources() {
    local pid=$1
    local task_name=$2
    
    # Get initial stats
    start_time=$(date +%s)
    
    echo -e "\n${CYAN}Tracking resources for: $task_name (PID: $pid)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Monitor while process runs
    while kill -0 $pid 2>/dev/null; do
        cpu=$(ps -p $pid -o %cpu | tail -1)
        mem=$(ps -p $pid -o %mem | tail -1)
        echo -ne "CPU: ${cpu}% | Memory: ${mem}%\r"
        sleep 1
    done
    
    echo ""
    
    # Calculate duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Log to accounting file
    echo "[$(date)] Task: $task_name | PID: $pid | Duration: ${duration}s | CPU: ${cpu}% | Mem: ${mem}%" >> logs/accounting.log
    
    echo -e "${GREEN}✓ Resource tracking complete${NC}"
    echo "Duration: ${duration} seconds"
}

# Generate resource accounting report
generate_accounting_report() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            RESOURCE ACCOUNTING REPORT                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -f logs/accounting.log ]; then
        echo "No accounting data available yet."
        return
    fi
    
    # Count total tasks
    total_tasks=$(wc -l < logs/accounting.log)
    echo -e "${CYAN}Total Tasks Tracked:${NC} $total_tasks"
    echo ""
    
    # Show recent tasks
    echo -e "${CYAN}Recent Tasks:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -5 logs/accounting.log
    echo ""
    
    # Calculate average duration (if available)
    if [ $total_tasks -gt 0 ]; then
        avg_duration=$(grep "Duration:" logs/accounting.log | awk -F'Duration: | s' '{sum+=$2; count++} END {if(count>0) print sum/count; else print 0}')
        echo -e "${CYAN}Average Task Duration:${NC} ${avg_duration}s"
    fi
}

# Demonstrate round-robin style execution
demo_round_robin() {
    echo -e "\n${YELLOW}=== Round-Robin Task Execution Demo ===${NC}"
    echo "Simulating round-robin scheduling with 3 tasks..."
    echo ""
    
    # Create task queue
    tasks=("Task-A" "Task-B" "Task-C")
    
    for round in {1..3}; do
        echo -e "${CYAN}Round $round:${NC}"
        for task in "${tasks[@]}"; do
            echo "  Executing $task (time slice: 1s)"
            sleep 1
        done
        echo ""
    done
    
    echo -e "${GREEN}✓ Round-robin simulation complete${NC}"
    echo "[$(date)] Round-robin demo completed" >> logs/scheduler.log
}

# Show current system scheduling info
show_scheduling_info() {
    echo -e "\n${BLUE}════════ SYSTEM SCHEDULING INFO ════════${NC}"
    echo ""
    
    echo -e "${CYAN}CPU Scheduler:${NC}"
    cat /proc/sys/kernel/sched_child_runs_first 2>/dev/null || echo "CFS (Completely Fair Scheduler)"
    echo ""
    
    echo -e "${CYAN}Process Priorities (Nice values):${NC}"
    ps -eo pid,ni,comm --sort=-ni | head -10
    echo ""
    
    echo -e "${CYAN}CPU Scheduling Stats:${NC}"
    cat /proc/schedstat 2>/dev/null | head -5 || echo "Stats not available"
}

# Demo task with resource tracking
demo_task_with_tracking() {
    echo -e "\n${YELLOW}=== Task Execution with Resource Tracking ===${NC}"
    
    # Start a sample task in background
    (
        echo "Sample task starting..."
        for i in {1..10}; do
            echo "Processing... $i/10"
            # Some CPU work
            bc <<< "scale=1000; 4*a(1)" > /dev/null
            sleep 0.5
        done
        echo "Sample task completed"
    ) &
    
    task_pid=$!
    
    # Track it
    track_process_resources $task_pid "Sample Task"
}

export -f demo_priority_scheduling
export -f track_process_resources
export -f generate_accounting_report
export -f demo_round_robin
export -f show_scheduling_info
export -f demo_task_with_tracking