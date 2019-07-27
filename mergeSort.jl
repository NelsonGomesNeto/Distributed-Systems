auxArray = Array{Int, 1}(undef, Int(1e6))

function merge(array, lo, mid, hi)
  sz, i, j = hi - lo + 1, lo, mid + 1
  for a = 1 : sz
    if j > hi || (i <= mid && array[i] < array[j])
      auxArray[a] = array[i]
      i += 1
    else
      auxArray[a] = array[j]
      j += 1
    end
  end
  for a = 1 : sz
    array[lo + a - 1] = auxArray[a]
  end
end

function mergeSort(array, lo = 1, hi = length(array))
  if lo == hi return end
  mid = (lo + hi) >> 1
  mergeSort(array, lo, mid)
  mergeSort(array, mid + 1, hi)
  merge(array, lo, mid, hi)
end

n = parse(Int, readline())
println("Array size: ", n)
array = [parse(Int, x) for x in split(readline())]
println("Before: ", array)
mergeSort(array)
println("After : ", array)