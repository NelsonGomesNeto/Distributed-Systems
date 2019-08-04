using Distributed

if nprocs() > 1
  rmprocs(workers())
end
addprocs(3)
@everywhere leader = 2
@everywhere election_running = false

@everywhere function simulated_workload()
  return(round(rand() * 100) / 100)
end

@everywhere function notify_workload_to_master(worker_id, workers_workload)
  @spawnat 1 println("Workload from Worker $worker_id: $workers_workload")
end

@everywhere function notify_election_to_master(worker_id)
  @spawnat 1 println("New leader elected! Worker $worker_id")
end

@everywhere function notify_workload_to_worker(worker_id, worker_workload)
  # println("$worker_id <- $worker_workload")
  workers_workload[worker_id - 1] = worker_workload
end

@everywhere election_verification()
  if workers_workload[leader] >= 0.8 && workers_workload[my_id] < 0.8
    election_running = true
  end
end

@everywhere function work()
  while true
    workers_workload[my_id - 1] = simulated_workload()
    
    @sync for w in workers()
      if w != my_id
        remotecall_fetch(notify_workload_to_worker, w, my_id, workers_workload[my_id - 1])
      end
    end

    sleep(2)
    remotecall_fetch(notify_workload_to_master, 1, my_id, workers_workload)
    election_verification()
  end
end
    
@everywhere function initialize_worker()
  global workers_workload = [0.0 for w in workers()]
  global my_id = myid()
  work()
end

@sync for w in workers()
  @spawnat w initialize_worker()
end
