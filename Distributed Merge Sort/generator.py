from random import randint

n = int(1e4)
a = [randint(-int(1e6), int(1e6)) for i in range(n)]
f = open("big4", "w")
print(n, file=f)
print(*a, file=f)
f.close()