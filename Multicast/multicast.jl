using Distributed
using Plots

function B_sync_multicast(group, message, B_deliver)
  @sync for i in group
    remotecall(B_deliver, i, message)
  end
end

function B_async_multicast(group, message, B_deliver)
  @sync @distributed for i in group
    remotecall(B_deliver, i, message)
  end
end

addprocs(2)

group = workers()

syncTimes, asyncTimes = [], []
for i in 1:50
  push!(syncTimes, @elapsed B_sync_multicast(group, "Hi hi", println))
  push!(asyncTimes, @elapsed B_async_multicast(group, "Hi hi", println))
end

println("------------------------------------------")
println("------------------------------------------")

println("syncTimes: $syncTimes")
println("asyncTimes: $asyncTimes")

println("------------------------------------------")
println("------------------------------------------")

deleteat!(syncTimes, UnitRange(1, 5))
deleteat!(asyncTimes, UnitRange(1, 5))
syncTimes, asyncTimes = Array{Float64}(syncTimes), Array{Float64}(asyncTimes)
plot(1:45, [syncTimes, asyncTimes])
# plot(1:50, [syncTimes, asyncTimes])

read()