import os
test_number = int(input())

for i in range(1, test_number + 1):
    open(f'results/c/test{i}.txt', 'a').close()
    open(f'results/asm/test{i}.txt', 'a').close()
    open(f'results/optimized/test{i}.txt', 'a').close()
    os.system(f'../code tests/test{i}.txt results/c/test{i}.txt')
    os.system(f'../code tests/test{i}.txt results/asm/test{i}.txt')
    os.system(f'../code tests/test{i}.txt results/optimized/test{i}.txt')