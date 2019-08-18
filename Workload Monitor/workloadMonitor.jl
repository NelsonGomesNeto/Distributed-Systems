using Distributed

# Adds workers
rmprocs(workers())
addprocs(10)

# Sets workload from worker_id to workload
@everywhere function set_workload(worker_id, workload)
    workloads[worker_id] = workload
end

# Notifies all other workers of my new workload
@everywhere function notify_my_workload_to_all_workers()
    for w in workers()
        if w != myid()
            remotecall(set_workload, w, myid(), workloads[myid()])
        end
    end
end

# Sets leader to new_leader and clears election variables
@everywhere function set_leader(new_leader)
    global leader = new_leader
    global participating = false
    global current_election = -1
    global current_election_workload = 1
end

# Circularly notifies that the new_leader was elected and finishes the election
@everywhere function finish_election(new_leader)
    set_leader(new_leader)

    if myid() == new_leader
        remotecall(println, 1, "New leader elected! Worker $new_leader")
        return
    end

    remotecall(finish_election, next_worker, new_leader)
end

# Circularly notifies that the new_leader wants to be a leader
@everywhere function elect(new_leader, new_leader_workload)
    # All workers were notified and agreed with the election
    if new_leader == myid()
        remotecall(finish_election, next_worker, new_leader)
        return
    end

    # There's another election happening and this new election request isn't
    # better than the current election if so, we discard this request
    if participating && (new_leader_workload > current_election_workload || (new_leader_workload == current_election_workload && new_leader <= current_election))
        return
    end
    
    # Thinks a new election should be enrolled where he is the new_leader
    if workloads[myid()] < new_leader_workload || (workloads[myid()] == new_leader_workload && myid() > new_leader)
        new_leader, new_leader_workload = myid(), workloads[myid()]
    end

    # Marks that it's participating in the election and saves the current election parameters
    global participating = true
    global current_election = new_leader
    global current_election_workload = new_leader_workload

    # Notifies the next worker about the election
    remotecall(elect, next_worker, new_leader, new_leader_workload)
end

# Checks if the eligibility conditions were meet, if so: enrolls the election
@everywhere function try_election()
    if participating
        return
    end

    if workloads[leader] >= 0.8 && workloads[myid()] < 0.8
        # println("Stared election")
        global participating = true
        remotecall(elect, next_worker, myid(), workloads[myid()])
    end
end

# Simulates the worker work
@everywhere function work()
    while true
        workloads[myid()] = round(rand(), digits = 1) # updates my workload

        notify_my_workload_to_all_workers()

        sleep(2)

        remotecall(println, 1, "Workload from Worker $(myid()): $([workloads[w] for w in sorted_workers])")

        try_election()
    end
end

# Initializes worker variables, election variables and starts its work
@everywhere function initialize_worker()
    global workloads = Dict([w => 0.0 for w in workers()])

    global sorted_workers = sort(workers())
    global next_worker = sorted_workers[findfirst(x -> x == myid(), sorted_workers) % length(sorted_workers) + 1]

    global leader = sorted_workers[1]
    global participating = false
    global current_election = -1
    global current_election_workload = 1

    work()
end

# Initializes all workers and sends them to work
@sync for w in workers()
    @spawnat w initialize_worker()
end