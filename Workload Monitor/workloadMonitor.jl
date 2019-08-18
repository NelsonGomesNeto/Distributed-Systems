using Distributed

rmprocs(workers())
addprocs(10)

@everywhere function simulated_workload()
    return(round(rand(), digits = 1))
end

@everywhere function set_workload(worker_id, workload)
    workloads[worker_id] = workload
end

@everywhere function notify_my_workload_to_all_workers()
    for w in workers()
        if w != myid()
            remotecall_fetch(set_workload, w, myid(), workloads[myid()])
        end
    end
end

@everywhere function set_leader(new_leader)
    global leader = new_leader
    global participating = false
    global current_election = -1
    global current_election_workload = 1
end

@everywhere function finish_election()
    for w in sorted_workers
        remotecall_fetch(set_leader, w, myid())
    end
    @sync remotecall_fetch(println, 1, "New leader elected! Worker $(myid())")
end

@everywhere function elect(new_leader, new_leader_workload)
    if new_leader == myid()
        finish_election()
        return
    end

    if participating && (new_leader_workload > current_election_workload || (new_leader_workload == current_election_workload && new_leader <= current_election))
        return
    end
    
    # Thinks a new election should be enrolled where he is the leader
    if workloads[myid()] < new_leader_workload || (workloads[myid()] == new_leader_workload && myid() > new_leader)
        new_leader, new_leader_workload = myid(), workloads[myid()]
    end
    global participating = true
    global current_election = new_leader
    global current_election_workload = new_leader_workload

    remotecall_fetch(elect, next_worker(), new_leader, new_leader_workload)
end

@everywhere function next_worker()
    position = findfirst(x -> x == myid(), sorted_workers)
    position = position % length(sorted_workers) + 1
    return(sorted_workers[position])
end

@everywhere function election_verification()
    if participating
        return
    end
    if workloads[leader] >= 0.8 && workloads[myid()] < 0.8
        println("Stared election")
        global participating = true
        remotecall_fetch(elect, next_worker(), myid(), workloads[myid()])
    end
end

@everywhere function work()
    while true
        workloads[myid()] = simulated_workload()
        
        notify_my_workload_to_all_workers()
        
        sleep(2)
        
        remotecall_fetch(println, 1, "Workload from Worker $(myid()): $([workloads[w] for w in sorted_workers]) || $participating || $leader")
        
        election_verification()
    end
end

@everywhere function initialize_worker()
    # Each worker will have its own view of all workers workload
    global workloads = Dict([w => 0.0 for w in workers()])
#     global workloads = [0.0 for w in workers()]
    global sorted_workers = sort(workers())
    global leader = sorted_workers[1]
    global participating = false
    global current_election = -1
    global current_election_workload = 1
    work()
end

@sync for w in workers()
    @spawnat w initialize_worker()
end