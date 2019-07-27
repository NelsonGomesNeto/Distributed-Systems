using Distributed
using SharedArrays

addprocs(10)
@everywhere workerPool = WorkerPool(workers())
println("Finished creating worker pool ", workerPool)

@everywhere function merge(left, right)
  sz, i, j = length(left) + length(right), 1, 1
  result = Array{Int, 1}(undef, sz)
  for a = 1 : sz
    if j > length(right) || (i <= length(left) && left[i] < right[j])
      result[a] = left[i]
      i += 1
    else
      result[a] = right[j]
      j += 1
    end
  end
  return(result)
end

@everywhere function mergeSort(array, lo = 1, hi = length(array))
  # println("Oxente ", lo, " ", hi, " ")
  if lo == hi return([array[lo]]) end
  mid = (lo + hi) >> 1
  left, right = [], []
  @sync begin
    left = remotecall_fetch(mergeSort, workerPool, array, lo, mid)
    right = remotecall_fetch(mergeSort, workerPool, array, mid + 1, hi)
  end
  # mergeSort(array, lo, mid)
  # mergeSort(array, mid + 1, hi)
  # println(left, " ", right)
  array = merge(left, right)
  # println(lo, " ", hi, " | ", array)
  return(array)
end

n = parse(Int, readline())
println("Array size: ", n)
array = [parse(Int, x) for x in split(readline())]
println("Before : ", array)
sortedArray = mergeSort(array)
println("After  : ", sortedArray)
println("Verdict: ", issorted(sortedArray))