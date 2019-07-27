using Distributed

addprocs(2)
@everywhere workerPool = WorkerPool(workers())
println("Finished creating worker pool ", workerPool)
@everywhere using SharedArrays

@everywhere function merge(lo, mid, hi)
  sz, i, j = hi - lo + 1, lo, mid + 1
  auxArray = Array{Int, 1}(undef, sz)
  for a = 1 : sz
    if j > hi || (i <= mid && sharedArray[i] < sharedArray[j])
      auxArray[a] = sharedArray[i]
      i += 1
    else
      auxArray[a] = sharedArray[j]
      j += 1
    end
  end
  for a = 1 : sz
    sharedArray[lo + a - 1] = auxArray[a]
  end
end

@everywhere function mergeSort(lo = 1, hi = 6)
  println("Oxente ", lo, " ", hi, " ", sharedArray)
  if lo == hi return end
  mid = (lo + hi) >> 1
  @sync begin
    remotecall_fetch(mergeSort, workerPool, lo, mid)
    remotecall_fetch(mergeSort, workerPool, mid + 1, hi)
  end
  # mergeSort(lo, mid)
  # mergeSort(mid + 1, hi)
  # println(left, " ", right)
  merge(lo, mid, hi)
  # println(lo, " ", hi, " | ", array)
end

n = parse(Int, readline())
println("Array size: ", n)
array = [parse(Int, x) for x in split(readline())]
@everywhere sharedArray = SharedArray{Int, 1}(6, pids = workers());
sharedArray[:] = array[:]
println("Before : ", sharedArray)
mergeSort()
println("After  : ", sharedArray)
println("Verdict: ", issorted(sharedArray))