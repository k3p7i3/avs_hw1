import os

last_test_number = int(input())
number = int(input())
test_size = int(input())

for i in range(last_test_number + 1, number + last_test_number + 1):
    open(f'tests/test{i}.txt', 'a').close()
    open(f'results/c/test{i}', 'a').close()
    os.system(f'../code tests/test{i}.txt results/c/test{i} --rand {test_size}')