---
Author: liualexiang
Title: 返回list最大升序子序列的长度
---

# 返回 list 中升序序列的最大长度



## 使用迭代遍历来返回

```python
num=[1,5,2,4,3]

num = [1,5,2]

def L(num, i):

    if i == len(num) -1: # the last element
        return 1
    max_len = 1
    for j in range(i+1, len(num)):
        if num[i] < num[j]:
            max_len = max(max_len, L(num,j) + 1)
    return max_len


def length_of_LIS(num):
    return max(L(num,i) for i in range(len(num)))

print(length_of_LIS(num))
```



## 生成100个数字，并观察计算时长

```python
import time,random

def timeit(f):
    """generate a timeit decorator for calculating the function time"""
    def cal(nums):
        s_time = time.time()
        result = f(nums)
        durations = time.time() - s_time
        print(durations)
        return result
    return cal


def generate_list(n):
    """Generates a list of N numbers which is between 100 and 999"""
    return [ num for num in random.choices(range(100,1000), k =n ) ]
nums = generate_list(100)
print(nums)

def L(nums, i):
    """ return the max length of current sub_list beginning from index i"""
    if i == len(nums)-1:
        return 1
    max_length = 1
    for j in range(i+1, len(nums)):
        if nums[j] > nums[i]:
            max_length = max(max_length, L(nums,j)+1)
    return max_length

@timeit
def get_LL(nums):
    """ return the max length of all sub_list"""
    # max_lengths=[]
    # for i in range(0,len(nums)):
    #     max_lengths.append(L(nums,i))
    # return max(max_lengths)
    return max(L(nums,i) for i in range(len(nums)))

print(get_LL(nums))


```

