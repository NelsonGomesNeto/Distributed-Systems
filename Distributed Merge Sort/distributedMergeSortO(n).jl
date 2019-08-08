using Distributed
using SharedArrays

# The memory problem I was facing was because every recursion must store at least 3 integers
# And there will be multiple branchces

addprocs(3)
@everywhere workerPool = WorkerPool(procs()) # Change from global to pass it by parameter
println("Finished creating worker pool ", workerPool)

@everywhere VERBOSE = false

n = parse(Int, readline())
println("Array size: ", n)
array = [parse(Int, x) for x in split(readline())]
sharedArray = SharedArray(array)

auxArray = copy(array)
sharedAuxArray = SharedArray(array)

useCount = [0 for i in procs()]
sharedUseCount = SharedArray(useCount)


@everywhere function merge(auxArray, array, lo, mid, hi)
  # sharedUseCount[myid()] += 1
  sz, i, j = hi - lo + 1, lo, mid + 1
  # sharedAuxArray = Array{Int, 1}(undef, sz)
  a = 0
  while a < sz
    if j > hi || (i <= mid && array[i] < array[j])
      auxArray[lo + a] = array[i]
      i += 1
    else
      auxArray[lo + a] = array[j]
      j += 1
    end
    a += 1
  end
  a = 0
  while a < sz
    array[lo + a] = auxArray[lo + a]
    a += 1
  end
end

@everywhere function mergeSort(auxArray, array, lo = 1, hi = n)
  if VERBOSE println("Oxente (id: $(myid())), lo = $lo, hi = $hi, array = $array") end
  # if VERBOSE println("Oxente (id: $(myid())), lo = $lo, hi = $hi") end
  # sharedUseCount[myid()] += 1

  mid = (lo + hi) >> 1
  # @sync begin
  #   # remotecall_fetch(mergeSort, workerPool, lo, mid)
  #   # remotecall_fetch(mergeSort, workerPool, mid + 1, hi)
  #   if lo < mid
  #     @spawnat 1 mergeSort(auxArray, array, lo, mid)
  #   end
  #   if mid + 1 < hi
  #     @spawnat 1 mergeSort(auxArray, array, mid + 1, hi)
  #   end
  #   # @spawn mergeSort(lo, mid)
  #   # @spawn mergeSort(mid + 1, hi)

  # end
  if lo < mid
    mergeSort(auxArray, array, lo, mid)
  end
  if mid + 1 < hi
    mergeSort(auxArray, array, mid + 1, hi)
  end
  
  @sync begin
    @spawnat workerPool merge(auxArray, array, lo, mid, hi)
  end
  # merge(auxArray, array, lo, mid, hi)
end

if VERBOSE println("Before : ", sharedArray) end
@time mergeSort(sharedAuxArray, sharedArray)
if VERBOSE println("After  : ", sharedArray) end
println("Verdict: $(issorted(sharedArray))")
println("UseCount: $sharedUseCount")