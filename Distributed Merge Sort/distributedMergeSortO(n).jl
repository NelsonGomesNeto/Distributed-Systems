using Distributed
using SharedArrays

addprocs(5)
# @everywhere workerPool = default_worker_pool()
@everywhere workerPool = WorkerPool(procs())
println("Finished creating worker pool ", workerPool)

@everywhere VERBOSE = true

n = parse(Int, readline())
println("Array size: ", n)
array = [parse(Int, x) for x in split(readline())]
useCount = [0 for i in procs()]
sharedUseCount = SharedArray(useCount)
sharedArray = SharedArray(array)
auxSharedArray = copy(array)
@sync for w in workers()
  @spawnat w array
  @spawnat w sharedArray
  @spawnat w auxSharedArray
  @spawnat w sharedUseCount
end

@everywhere function merge(lo, mid, hi)
  sharedUseCount[myid()] += 1
  sz, i, j = hi - lo + 1, lo, mid + 1
  # auxSharedArray = Array{Int, 1}(undef, sz)
  a = 0
  while a < sz
    if j > hi || (i <= mid && sharedArray[i] < sharedArray[j])
      auxSharedArray[lo + a] = sharedArray[i]
      i += 1
    else
      auxSharedArray[lo + a] = sharedArray[j]
      j += 1
    end
    a += 1
  end
  a = 0
  while a < sz
    sharedArray[lo + a] = auxSharedArray[lo + a]
    a += 1
  end
end

@everywhere function mergeSort(lo = 1, hi = n)
  # if VERBOSE println("Oxente (id: $(myid())), lo = $lo, hi = $hi, sharedArray = $sharedArray") end
  if VERBOSE println("Oxente (id: $(myid())), lo = $lo, hi = $hi") end
  sharedUseCount[myid()] += 1

  mid = (lo + hi) >> 1
  @sync begin
    # remotecall_fetch(mergeSort, workerPool, lo, mid)
    # remotecall_fetch(mergeSort, workerPool, mid + 1, hi)
    if lo < mid
      @spawnat workerPool mergeSort(lo, mid)
    end
    if mid + 1 < hi
      @spawnat workerPool mergeSort(mid + 1, hi)
    end
    # @spawn mergeSort(lo, mid)
    # @spawn mergeSort(mid + 1, hi)

  end
  # if lo < mid
  #   mergeSort(lo, mid)
  # end
  # if mid + 1 < hi
  #   mergeSort(mid + 1, hi)
  # end
  
  # @sync begin
  #   @spawnat workerPool
  # end
  merge(lo, mid, hi)
end

if VERBOSE println("Before : ", sharedArray) end
@time mergeSort()
if VERBOSE println("After  : ", sharedArray) end
println("Verdict: $(issorted(sharedArray))")
println("UseCount: $sharedUseCount")