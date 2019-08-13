using Distributed
using Plots
using StatsPlots

z = 1.96 # 95% confidence level

iterations = 100
addprocs(10)

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
  @sync @distributed for i in group
    remotecall(B_deliver, i, message)
  end
end

group = workers()

syncTimes = []
for i in 1:iterations
  println("$i -----------------------------------")
  flush(stdout)
  push!(syncTimes, @elapsed B_sync_multicast(group, "Sync hi  -- $i", B_deliver))
end

asyncTimes = []
for i in 1:iterations
  println("$i -----------------------------------")
  flush(stdout)
  push!(asyncTimes, @elapsed B_async_multicast(group, "Async hi -- $i", B_deliver))
end

syncTimes, asyncTimes = Array{Float64}(syncTimes), Array{Float64}(asyncTimes)
sort!(syncTimes), sort!(asyncTimes)
deleteat!(syncTimes, UnitRange(length(syncTimes) - 10, length(syncTimes)))
deleteat!(asyncTimes, UnitRange(length(asyncTimes) - 10, length(asyncTimes)))
syncTotalTime, asyncTotalTime = sum(syncTimes), sum(asyncTimes)
syncMeanTime, asyncMeanTime = syncTotalTime / length(syncTimes), asyncTotalTime / length(asyncTimes)
syncStdTime, asyncStdTime = z * syncMeanTime / sqrt(length(syncTimes)), z * asyncMeanTime / sqrt(length(asyncTimes))

f = open("data B_multicast", "w")
println(f, "Sync total time: $syncTotalTime || Async total time: $asyncTotalTime")
println(f, "Sync mean time: $syncMeanTime || Async mean time: $asyncMeanTime")
println(f, "Sync std time: $syncStdTime || Async std time: $asyncStdTime")
println(f, "Sync: $syncTimes")
println(f, "Async: $asyncTimes")

# p = plot(1:length(syncTimes),
#          [syncTimes, asyncTimes],
#          title="Sync x Async B_multicast",
#          label=["Sync", "Async"],
#          xlabel="Runs",
#          ylabel="Time (s)")
p = groupedbar(["Sync", "Async"],
               [syncMeanTime asyncMeanTime],
               yerr=[syncStdTime asyncStdTime],
               group=["Sync", "Async"],
               title="Sync x Async B_multicast",
               ylabel="Time (seconds)",
               bar_width=0.7)
savefig(p, "B_multicast")
