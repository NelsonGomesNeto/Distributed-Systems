using Distributed
using Plots
using StatsPlots

iterations = 100
addprocs(15)

@everywhere function B_deliver(message)
  println(message)
  flush(stdout)
end

function B_sync_multicast(group, message, B_deliver)
  for i in group
    remotecall_fetch(B_deliver, i, message)
  end
end

function B_async_multicast(group, message, B_deliver)
  @sync for i in group
    remotecall(B_deliver, i, message)
  end
end

group = workers()

syncTimes = []
syncTotalTime = @elapsed for i in 1:iterations
  println("$i -----------------------------------")
  flush(stdout)
  push!(syncTimes, @elapsed B_sync_multicast(group, "Sync hi  -- $i", B_deliver))
end

asyncTimes = []
asyncTotalTime = @elapsed for i in 1:iterations
  println("$i -----------------------------------")
  flush(stdout)
  push!(asyncTimes, @elapsed B_async_multicast(group, "Async hi -- $i", B_deliver))
end

deleteat!(syncTimes, UnitRange(1, 10))
deleteat!(asyncTimes, UnitRange(1, 10))
syncTimes, asyncTimes = Array{Float64}(syncTimes), Array{Float64}(asyncTimes)

f = open("data B_multicast", "w")
println(f, "Sync total time: $syncTotalTime || Async total time: $asyncTotalTime")
println(f, "Sync: $syncTimes")
println(f, "Async: $asyncTimes")

# p = plot(1:length(syncTimes),
#          [syncTimes, asyncTimes],
#          title="Sync x Async B_multicast",
#          label=["Sync", "Async"],
#          xlabel="Runs",
#          ylabel="Time (s)")
p = boxplot(["Sync", "Async"],
            [syncTimes, asyncTimes],
            title="Sync x Async B_multicast",
            legend=false,
            ylabel="Time (s)")
savefig(p, "B_multicast")
