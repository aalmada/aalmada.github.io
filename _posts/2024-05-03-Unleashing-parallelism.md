---
layout: post
read_time: true
show_date: true
title: "Unleashing Parallelism: A Guide to Efficient Span Processing with SIMD and Threading in C#"
date: 2024-05-03
img_path: /assets/img/posts/20240503
image: InfanteSanto.jpg
tags:
  [development, .net, csharp, performance, span, simd, parallel, benchmarking]
category: development
---

Modern CPUs offer three types of parallel processing. This article outlines several steps for leveraging all three to process large data sets as efficiently as possible.

## Base Implementation

To illustrate, let's implement a method that adds elements from one span to corresponding elements of another span and stores the result in a destination span. This operation is commonly encountered when working with tensors, frequently used in deep learning.

```csharp
static void For<T>(ReadOnlySpan<T> left, ReadOnlySpan<T> right, Span<T> destination)
    where T : struct, IAdditionOperators<T, T, T>
{
    for (var index = 0; index < left.Length; index++)
        destination[index] = left[index] + right[index];
}
```

This method employs a `for` loop to iterate over the spans and perform element-wise addition using generic math, allowing it to work with any scalar type.

> For a deeper understanding of generic math, refer to my other article ["Generic math in .NET"](https://aalmada.github.io/posts/Generic-math-in-dotnet/).

The method is named `For` so that its performance can be compared in the benchmarks to the next steps of the implementation.

## Bounds Checking Elimination

By default, C# implements bounds checking to ensure that accesses to spans remain within their boundaries, thereby enhancing code robustness at the expense of performance.

Using [SharpLab](https://sharplab.io/#v2:EYLgxg9gTgpgtADwGwBYA0AXEBDAzgWwB8ABAJgEYBYAKGIAYACY8gOgDkBXfGKASzFwBuGvQYBlABbYoABwAy2YCwBKHAHYZe3YdRoBtAFK8MAcRhqe/ABQYAnjJgQAZld4aAlO4C6I8kiYoDABi0AA8ACoAfFbKMNgAJgDyagA2tmIy2GoRkQwpME4YaAyxCclpGVk5DHwA5hJF4pnZUQzxMLiaatiaEGruNAxDDADuEjwwDOEMIAydUBxgjQCSAILx8ca8fYkOUD3QuBHF4SeRNADeg8NO0AxWAG7SDG7tCAwAvAx0gi9qbwxQnkChgWHJzLUMBJfq8YAgANTwgbUYaotodLo9bZqPSwhBeT7Awq4/5wgnwmq8eoYElvLw6AC+NCAA===), we can observe that the assembly code genrated by the JIT compiler includes bounds checking to verify whether the index falls within the span's bounds. If it exceeds the bounds, an exception is thrown.

```nasm
L0000: push rsi
L0001: push rbx
L0002: sub rsp, 0x28
L0006: mov rax, [rcx]
L0009: mov ecx, [rcx+8]
L000c: xor r10d, r10d
L000f: test ecx, ecx
L0011: jle short L003c
L0013: cmp r10d, [r8+8]
L0017: jae short L0043 ;bounds check
L0019: mov r9, [r8]
L001c: mov r11d, r10d
L001f: mov ebx, [rax+r11*4]
L0023: cmp r10d, [rdx+8]
L0027: jae short L0043 ;bounds check
L0029: mov rsi, [rdx]
L002c: add ebx, [rsi+r11*4]
L0030: mov [r9+r11*4], ebx
L0034: inc r10d
L0037: cmp r10d, ecx
L003a: jl short L0013
L003c: add rsp, 0x28
L0040: pop rbx
L0041: pop rsi
L0042: ret
L0043: call 0x00007ff88e200da0 ;throws exception
L0048: int3
```

To manually eliminate bounds checking, we can use `MemoryMarshal.GetReference()` along with `Unsafe.Add()`.

```csharp
static void For_GetReference<T>(ReadOnlySpan<T> left, ReadOnlySpan<T> right, Span<T> destination)
    where T : struct, IAdditionOperators<T, T, T>
{
    ref var leftRef = ref MemoryMarshal.GetReference(left);
    ref var rightRef = ref MemoryMarshal.GetReference(right);
    ref var destinationRef = ref MemoryMarshal.GetReference(destination);

    var end = left.Length;
    for (var index = 0; index < end; index++)
        Unsafe.Add(ref destinationRef, index) = Unsafe.Add(ref leftRef, index) + Unsafe.Add(ref rightRef, index);
}
```

The method `MemoryMarshal.GetReference()` retrieves a reference to the start of the span. To access its elements, we use `Unsafe.Add()` with the `index` as the offset from the beginning.

Using [SharpLab](https://sharplab.io/#v2:EYLgxg9gTgpgtADwGwBYA0AXEBDAzgWwB8ABAJgEYBYAKGIAYACY8gOgDkBXfGKASzFwBuGvSasAShwB2GXtxYBhCPgAOvADY8AyjwBu/GEJGNmLSTLkwWASRk8IKnVH1hDw2oy0ALbFBUAZbGAzaVludxoAbQApXgwAcRgpHn4ACgwATxUYCAAzVN4ZAEoigF0RciQmFAYAMWgAfUSMcRhcniTXAB4AFQA+VNbsABMAeSl1DK0VbClevoZNXIw0BiGxiamZuf6GPgBzLxWGadn5hmHDWSlsWQgpIpoGZ4YAdy8Ohh6GEAZcDCgHDAx2sAEFhsM4rx7qNslBbtBcL1Vj0UX0aABvJ4vWC5Bi6XyLNotNoMAC8e1JAFkYPhoBkqb5cD51Cxmq12rApK5UksMEV3C9KXiCVA9rxDiS8RTcQwaXSoAymSy2TApR1uTBUgcjgLsc9ZaKLldCrdoVIOeThXLafTGVBmdhWey2hqeZd/qa7g9BS8jUlhla+Sx/El9hgvL7nrloAxUkbCpcEFa6IIGImYMmugwA2mMwgANQFx7UIVCgCqUlw2HaLHBw21pI91zN9w5q3zRStlertfrjbxfPb6akSa7BYYPZrVn7sp1Uo7o8zeuoAF8aEA==) to examine the generated assembly code, we can see that it's much simpler and there are no bounds checking.

```nasm
L0000: mov rax, [rcx]
L0003: mov rdx, [rdx]
L0006: mov r8, [r8]
L0009: mov ecx, [rcx+8]
L000c: xor r10d, r10d
L000f: test ecx, ecx
L0011: jle short L0037
L0013: nop [rax+rax]
L0018: nop [rax+rax]
L0020: movsxd r9, r10d
L0023: mov r11d, [rax+r9*4]
L0027: add r11d, [rdx+r9*4]
L002b: mov [r8+r9*4], r11d
L002f: inc r10d
L0032: cmp r10d, ecx
L0035: jl short L0020
L0037: ret
```

The benchmarks below conclusively demonstrate the significantly improved efficiency of this code.

So far, parallelization hasn't been employed. The primary aim was to establish an efficient baseline that we can enhance exclusively through parallelization techniques.

## CPU Branching and Parallelization

In my previous article on [CPU branching and parallelization](https://aalmada.github.io/posts/CPU-branching-and-parallelization/), I discussed how modern CPUs use hardware-level mechanisms for automatic parallelization, leveraging available registers and execution units. By consolidating multiple operations within a single `for` loop iteration, the CPU can efficiently exploit these capabilities, resulting in enhanced performance and reduced overhead from logical branching. This approach significantly improves execution speed and resource utilization, especially in scenarios involving repetitive computations or data processing tasks.

```csharp
static void For_GetReference_4<T>(ReadOnlySpan<T> left, ReadOnlySpan<T> right, Span<T> destination, int index = 0)
    where T : struct, IAdditionOperators<T, T, T>
{
    ref var leftRef = ref MemoryMarshal.GetReference(left);
    ref var rightRef = ref MemoryMarshal.GetReference(right);
    ref var destinationRef = ref MemoryMarshal.GetReference(destination);

    var end = left.Length - 3;
    for (; index < end; index += 4)
    {
        Unsafe.Add(ref destinationRef, index) = Unsafe.Add(ref leftRef, index) + Unsafe.Add(ref rightRef, index);
        Unsafe.Add(ref destinationRef, index + 1) = Unsafe.Add(ref leftRef, index + 1) + Unsafe.Add(ref rightRef, index + 1);
        Unsafe.Add(ref destinationRef, index + 2) = Unsafe.Add(ref leftRef, index + 2) + Unsafe.Add(ref rightRef, index + 2);
        Unsafe.Add(ref destinationRef, index + 3) = Unsafe.Add(ref leftRef, index + 3) + Unsafe.Add(ref rightRef, index + 3);
    }

    switch (left.Length - index)
    {
        case 3:
            Unsafe.Add(ref destinationRef, index) = Unsafe.Add(ref leftRef, index) + Unsafe.Add(ref rightRef, index);
            Unsafe.Add(ref destinationRef, index + 1) = Unsafe.Add(ref leftRef, index + 1) + Unsafe.Add(ref rightRef, index + 1);
            Unsafe.Add(ref destinationRef, index + 2) = Unsafe.Add(ref leftRef, index + 2) + Unsafe.Add(ref rightRef, index + 2);
            break;
        case 2:
            Unsafe.Add(ref destinationRef, index) = Unsafe.Add(ref leftRef, index) + Unsafe.Add(ref rightRef, index);
            Unsafe.Add(ref destinationRef, index + 1) = Unsafe.Add(ref leftRef, index + 1) + Unsafe.Add(ref rightRef, index + 1);
            break;
        case 1:
            Unsafe.Add(ref destinationRef, index) = Unsafe.Add(ref leftRef, index) + Unsafe.Add(ref rightRef, index);
            break;
    }
}
```

This method optimizes performance by processing four operations per loop iteration. Since the span's length may not be a multiple of 4, the remaining operations are handled after the loop. To minimize logical branching, a `switch` statement is used to handle the cases where 3, 2, or 1 operations are remaining.

> The `index` start value is passed in as a parameter as it will be useful for the next steps.

The benchmarks below conclusively demonstrate the significantly improved efficiency of this code.

## SIMD

As detailed in my earlier article [Single Instruction, Multiple Data (SIMD) in .NET](https://aalmada.github.io/posts/SIMD-in-dotnet/), .NET furnishes developers with two distinct APIs for SIMD operations. I prefer using `Vector<T>`, found in the `System.Numerics` namespace, due to its simplicity, support for all native scalar types, and suitability for this particular scenario.

```csharp
static void For_SIMD<T>(ReadOnlySpan<T> left, ReadOnlySpan<T> right, Span<T> destination)
    where T : struct, IAdditionOperators<T, T, T>
{
    var indexSource = 0;

    if (Vector.IsHardwareAccelerated && Vector<T>.IsSupported)
    {
        var leftVectors = MemoryMarshal.Cast<T, Vector<T>>(left);
        var rightVectors = MemoryMarshal.Cast<T, Vector<T>>(right);
        var destinationVectors = MemoryMarshal.Cast<T, Vector<T>>(destination);

        ref var leftVectorsRef = ref MemoryMarshal.GetReference(leftVectors);
        ref var rightVectorsRef = ref MemoryMarshal.GetReference(rightVectors);
        ref var destinationVectorsRef = ref MemoryMarshal.GetReference(destinationVectors);

        var endVectors = leftVectors.Length;
        for (var indexVector = 0; indexVector < endVectors; indexVector++)
        {
            Unsafe.Add(ref destinationVectorsRef, indexVector) = Unsafe.Add(ref leftVectorsRef, indexVector) + Unsafe.Add(ref rightVectorsRef, indexVector);
        }

        indexSource = leftVectors.Length * Vector<T>.Count;
    }

    For_GetReference_4(left, right, destination, indexSource);
}
```

The method verifies whether SIMD is supported by the hardware and whether the data type is compatible with this API. If both conditions are met, it employs the `MemoryMarshal.Cast<TFrom, TTo>()` method to convert the `Span<T>` into a `Span<Vector<T>>` without copying its contents. Operations performed on `Vector<T>` are automatically optimized to utilize SIMD capabilities.

Now, it merely needs to execute operations on the elements of the spans of vectors, leveraging `MemoryMarshal.GetReference()` and `Unsafe.Add()` to eliminate bounds checking.

Once more, there may be remaining elements that don't align with a complete `Vector<T>`. In such cases, we can utilize the previously defined `For_GetReference_4()` method, passing the index of the first element to process.

The benchmarks below conclusively demonstrate the significantly improved efficiency of this code.

## Tensors

As evident from the complexity of the code, implementing and maintaining such operations for each function can be burdensome. Thankfully, there are libraries available that streamline this process by utilizing value-type delegates.

[System.Numerics.Tensors](https://www.nuget.org/packages/System.Numerics.Tensors) is a NuGet library developed and maintained by the .NET team. It incorporates many of the operations discussed above that can be performed on spans. For example, addition operations can be invoked as follows:

```csharp
TensorPrimitives.Add<int>(sourceInt32, otherInt32, resultInt32);
```

[NetFabric.Numerics.Tensors](https://netfabric.github.io/NetFabric.Numerics.Tensors/articles/intro.html), an alternative developed by me, arose from the initial limitations of System.Numerics.Tensors regarding native scalar types. While `System.Numerics.Tensors` is set to support these types in future releases, `NetFabric.Numerics.Tensors` currently offers broader support and facilitates the development of custom operations.

Similarly, it supports addition operations, which can be called as follows:

```csharp
TensorOperations.Add<int>(sourceInt32!, otherInt32!, resultInt32!);
```

## Multi-core CPUs

Most modern CPUs provide multiple cores. The code as implemented previoulsy will make use of only one of the cores. The operation that we are implementing is highly parallelizable as there are no element dependencies. The spans can be sliced and each slice processed by a different core.

`Parallel.For` is commonly used in .NET to parallelize operations.

```csharp
static void Parallel_For<T>(T[] left, T[] right, T[] destination)
    where T : struct, IAdditionOperators<T, T, T>
{
    Parallel.For(0, left.Length, index => destination[index] = left[index] + right[index]);
}
```

In this scenario, the issue arises from the fact that a lambda expression is passed as a parameter and applied to each element. As a result, SIMD cannot be used. An alternative approach involves applying the lambda expression to slices of the spans, requiring a different strategy.

```csharp
static void Parallel_Invoke_System_Numerics_Tensors<T>(ReadOnlyMemory<T> left, ReadOnlyMemory<T> right, Memory<T> destination)
    where T : struct, IAdditionOperators<T, T, T>
{
    const int minChunkCount = 4;
    const int minChunkSize = 1_000;

    var coreCount = Environment.ProcessorCount;

    if (coreCount >= minChunkCount && left.Length > minChunkCount * minChunkSize)
        ParallelApply(left, right, destination, coreCount);
    else
        TensorPrimitives.Add(left.Span, right.Span, destination.Span);

    static void ParallelApply(ReadOnlyMemory<T> left, ReadOnlyMemory<T> right, Memory<T> destination, int coreCount)
    {
        var totalSize = left.Length;
        var chunkSize = int.Max(totalSize / coreCount, minChunkSize);

        var actions = GC.AllocateArray<Action>(totalSize / chunkSize);
        var start = 0;
        for (var index = 0; index < actions.Length; index++)
        {
            var length = (index == actions.Length - 1)
                ? totalSize - start
                : chunkSize;

            var leftSlice = left.Slice(start, length);
            var rightSlice = right.Slice(start, length);
            var destinationSlice = destination.Slice(start, length);
            actions[index] = () => TensorPrimitives.Add(leftSlice.Span, rightSlice.Span, destinationSlice.Span);

            start += length;
        }
        Parallel.Invoke(actions);
    }
}
```

Multi-threading can significantly boost performance when processing large datasets. However, the overhead of managing threads may outweigh the benefits for smaller datasets. To address this, the code introduces two constants: `minChunkSize`, which sets the minimum data size per thread, and `minChunkCount`, determining the minimum number of threads to use.

Please note that the method parameters are now of type `Memory<T>` instead of `Span<T>`. This change is due to the fact that `Span<T>` is a `ref struct`, meaning it is a value type that can only exist on the stack. It cannot be boxed. The creation of closures for the actions requires the use of reference types, which `Memory<T>` provides.

The internal method `ParallelApply()` orchestrates the threading logic. It's invoked only if the CPU core count equals or exceeds the minimum thread count and if the span length contains sufficient data to fill the minimum number of threads with the minimum number of elements. Otherwise, the single-threaded `TensorPrimitives.Add()` method provided by `System.Numerics.Tensors` is used.

Internally, `ParallelApply()` leverages `Parallel.Invoke()` to execute actions concurrently. It generates a maximum number of actions equal to the CPU core count, slicing the spans so that each action handles a distinct portion. However, it may generate fewer actions than cores if there isn't enough data to warrant additional threads. Each action then calls the `TensorPrimitives.Add()` method on its assigned slice.

Our latest implementation fully leverages modern CPU parallelization techniques. This integration optimizes performance by employing SIMD operations, threading, and efficient data processing strategies. This approach accelerates processing speed and resource use, making it ideal for handling demanding computational tasks.

> Alternatively, you can use the `TensorOperations.Add()` method from the `NetFabric.Numerics.Tensors` library. I am actively enhancing this library to seamlessly integrate multi-threading support, simplifying the utilization of multi-threading for any span operation.

## Benchmarks

By leveraging [BenchmarkDotNet](https://benchmarkdotnet.org/), we precisely quantify the performance enhancements achieved at each implementation stage. You can access the benchmarks [here](https://github.com/aalmada/ParallelSimd) to review the complete code and execute them on your own system to validate the results.

Below are the benchmark results obtained on the following system configuration:

```
BenchmarkDotNet v0.13.12, Windows 11 (10.0.22631.3447/23H2/2023Update/SunValley3)
AMD Ryzen 9 7940HS w/ Radeon 780M Graphics, 1 CPU, 16 logical and 8 physical cores
.NET SDK 9.0.100-preview.3.24204.13
  [Host]    : .NET 9.0.0 (9.0.24.17209), X64 RyuJIT AVX-512F+CD+BW+DQ+VL+VBMI
  Scalar    : .NET 9.0.0 (9.0.24.17209), X64 RyuJIT
  Vector128 : .NET 9.0.0 (9.0.24.17209), X64 RyuJIT AVX
  Vector256 : .NET 9.0.0 (9.0.24.17209), X64 RyuJIT AVX2
  Vector512 : .NET 9.0.0 (9.0.24.17209), X64 RyuJIT AVX-512F+CD+BW+DQ+VL+VBMI

OutlierMode=DontRemove  MemoryRandomization=True
```

The benchmarks were conducted for both `int` and `float` types, using spans containing 111,111 elements. This a large enough to make multi-threading usefull and it's an odd number so that all code paths are executed.

Additionally, benchmarks were performed under various SIMD availability scenarios: Scalar (SIMD unavailable), 128-bit SIMD, 256-bit SIMD, and 512-bit SIMD.

> Explore my other article, ["Unit Testing and Benchmarking SIMD in .NET"](https://aalmada.github.io/posts/Unit-testing-and-benchmarking-SIMD-in-dotnet/), for deeper insights into how this process functions.

| Method                        | Job       | Categories | Count  |      Mean |    StdDev |    Median |        Ratio |   Gen0 | Allocated | Alloc Ratio |
| ----------------------------- | --------- | ---------- | ------ | --------: | --------: | --------: | -----------: | -----: | --------: | ----------: |
| Int32_For                     | Scalar    | Int32      | 111111 | 41.420 μs | 2.0507 μs | 40.827 μs |     baseline |      - |         - |          NA |
| Int32_For_GetReference        | Scalar    | Int32      | 111111 | 45.204 μs | 1.5323 μs | 44.780 μs | 1.09x slower |      - |         - |          NA |
| Int32_For_GetReference4       | Scalar    | Int32      | 111111 | 31.513 μs | 0.9492 μs | 31.354 μs | 1.33x faster |      - |         - |          NA |
| Int32_For_SIMD                | Scalar    | Int32      | 111111 | 31.612 μs | 0.9873 μs | 31.481 μs | 1.33x faster |      - |         - |          NA |
| Int32_System_Numerics_Tensor  | Scalar    | Int32      | 111111 | 32.421 μs | 0.5159 μs | 32.528 μs | 1.29x faster |      - |         - |          NA |
| Int32_Parallel_For            | Scalar    | Int32      | 111111 | 46.724 μs | 3.6772 μs | 46.217 μs | 1.14x slower | 0.5493 |    4880 B |          NA |
| Int32_Parallel_Invoke         | Scalar    | Int32      | 111111 | 10.456 μs | 0.2746 μs | 10.516 μs | 4.03x faster | 0.5951 |    4994 B |          NA |
| Int32_Parallel_Invoke_SIMD    | Scalar    | Int32      | 111111 | 10.341 μs | 0.2540 μs | 10.344 μs | 4.03x faster | 0.5951 |    5045 B |          NA |
| Int32_For                     | Vector128 | Int32      | 111111 | 39.906 μs | 0.3442 μs | 39.849 μs | 1.05x faster |      - |         - |          NA |
| Int32_For_GetReference        | Vector128 | Int32      | 111111 | 44.182 μs | 0.3725 μs | 44.229 μs | 1.06x slower |      - |         - |          NA |
| Int32_For_GetReference4       | Vector128 | Int32      | 111111 | 30.396 μs | 0.3119 μs | 30.383 μs | 1.38x faster |      - |         - |          NA |
| Int32_For_SIMD                | Vector128 | Int32      | 111111 | 12.678 μs | 1.0770 μs | 12.541 μs | 3.29x faster |      - |         - |          NA |
| Int32_System_Numerics_Tensor  | Vector128 | Int32      | 111111 | 11.937 μs | 2.9772 μs | 11.275 μs | 3.61x faster |      - |         - |          NA |
| Int32_Parallel_For            | Vector128 | Int32      | 111111 | 49.473 μs | 1.6099 μs | 49.377 μs | 1.19x slower | 0.5493 |    4826 B |          NA |
| Int32_Parallel_Invoke         | Vector128 | Int32      | 111111 | 10.831 μs | 0.1759 μs | 10.805 μs | 3.87x faster | 0.5951 |    4992 B |          NA |
| Int32_Parallel_Invoke_SIMD    | Vector128 | Int32      | 111111 |  6.214 μs | 0.0856 μs |  6.226 μs | 6.75x faster | 0.5417 |    4536 B |          NA |
| Int32_For                     | Vector256 | Int32      | 111111 | 41.040 μs | 1.0313 μs | 40.985 μs | 1.02x faster |      - |         - |          NA |
| Int32_For_GetReference        | Vector256 | Int32      | 111111 | 44.586 μs | 0.6762 μs | 44.652 μs | 1.07x slower |      - |         - |          NA |
| Int32_For_GetReference4       | Vector256 | Int32      | 111111 | 31.356 μs | 0.5204 μs | 31.378 μs | 1.34x faster |      - |         - |          NA |
| Int32_For_SIMD                | Vector256 | Int32      | 111111 | 10.755 μs | 0.2100 μs | 10.739 μs | 3.89x faster |      - |         - |          NA |
| Int32_System_Numerics_Tensor  | Vector256 | Int32      | 111111 | 11.326 μs | 1.6550 μs | 11.022 μs | 3.77x faster |      - |         - |          NA |
| Int32_Parallel_For            | Vector256 | Int32      | 111111 | 41.164 μs | 0.7934 μs | 40.924 μs | 1.02x faster | 0.5493 |    4942 B |          NA |
| Int32_Parallel_Invoke         | Vector256 | Int32      | 111111 | 10.103 μs | 0.2397 μs | 10.139 μs | 4.13x faster | 0.5951 |    5021 B |          NA |
| Int32_Parallel_Invoke_SIMD    | Vector256 | Int32      | 111111 |  5.587 μs | 0.1010 μs |  5.559 μs | 7.51x faster | 0.5417 |    4506 B |          NA |
| Int32_For                     | Vector512 | Int32      | 111111 | 39.403 μs | 0.7315 μs | 39.303 μs | 1.06x faster |      - |         - |          NA |
| Int32_For_GetReference        | Vector512 | Int32      | 111111 | 43.781 μs | 0.6366 μs | 43.905 μs | 1.05x slower |      - |         - |          NA |
| Int32_For_GetReference4       | Vector512 | Int32      | 111111 | 31.453 μs | 0.9483 μs | 31.375 μs | 1.33x faster |      - |         - |          NA |
| Int32_For_SIMD                | Vector512 | Int32      | 111111 | 10.582 μs | 0.3608 μs | 10.456 μs | 3.95x faster |      - |         - |          NA |
| Int32_System_Numerics_Tensor  | Vector512 | Int32      | 111111 | 11.351 μs | 0.7147 μs | 11.324 μs | 3.68x faster |      - |         - |          NA |
| Int32_Parallel_For            | Vector512 | Int32      | 111111 | 41.070 μs | 0.8726 μs | 41.126 μs | 1.02x faster | 0.5493 |    4915 B |          NA |
| Int32_Parallel_Invoke         | Vector512 | Int32      | 111111 | 10.042 μs | 0.1468 μs |  9.995 μs | 4.17x faster | 0.5951 |    5019 B |          NA |
| Int32_Parallel_Invoke_SIMD    | Vector512 | Int32      | 111111 |  5.604 μs | 0.1048 μs |  5.620 μs | 7.47x faster | 0.5417 |    4500 B |          NA |
|                               |           |            |        |           |           |           |              |        |           |             |
| Single_For                    | Scalar    | Single     | 111111 | 34.365 μs | 0.5454 μs | 34.402 μs |     baseline |      - |         - |          NA |
| Single_For_GetReference       | Scalar    | Single     | 111111 | 25.741 μs | 0.4834 μs | 25.673 μs | 1.34x faster |      - |         - |          NA |
| Single_For_GetReference4      | Scalar    | Single     | 111111 | 24.754 μs | 0.2640 μs | 24.759 μs | 1.39x faster |      - |         - |          NA |
| Single_For_SIMD               | Scalar    | Single     | 111111 | 24.919 μs | 0.2662 μs | 24.873 μs | 1.38x faster |      - |         - |          NA |
| Single_System_Numerics_Tensor | Scalar    | Single     | 111111 | 24.337 μs | 0.3864 μs | 24.388 μs | 1.41x faster |      - |         - |          NA |
| Single_Parallel_For           | Scalar    | Single     | 111111 | 40.225 μs | 0.9705 μs | 40.129 μs | 1.17x slower | 0.5493 |    4895 B |          NA |
| Single_Parallel_Invoke        | Scalar    | Single     | 111111 |  8.873 μs | 0.1662 μs |  8.839 μs | 3.87x faster | 0.5798 |    4920 B |          NA |
| Single_Parallel_Invoke_SIMD   | Scalar    | Single     | 111111 |  8.878 μs | 0.1184 μs |  8.858 μs | 3.87x faster | 0.5951 |    4946 B |          NA |
| Single_For                    | Vector128 | Single     | 111111 | 34.610 μs | 0.8964 μs | 34.502 μs | 1.01x slower |      - |         - |          NA |
| Single_For_GetReference       | Vector128 | Single     | 111111 | 25.786 μs | 0.3613 μs | 25.759 μs | 1.33x faster |      - |         - |          NA |
| Single_For_GetReference4      | Vector128 | Single     | 111111 | 24.948 μs | 0.4087 μs | 25.093 μs | 1.38x faster |      - |         - |          NA |
| Single_For_SIMD               | Vector128 | Single     | 111111 | 11.545 μs | 0.3195 μs | 11.408 μs | 3.00x faster |      - |         - |          NA |
| Single_System_Numerics_Tensor | Vector128 | Single     | 111111 | 11.834 μs | 1.4373 μs | 11.189 μs | 3.00x faster |      - |         - |          NA |
| Single_Parallel_For           | Vector128 | Single     | 111111 | 41.137 μs | 0.7078 μs | 41.019 μs | 1.20x slower | 0.5493 |    4945 B |          NA |
| Single_Parallel_Invoke        | Vector128 | Single     | 111111 |  8.801 μs | 0.1852 μs |  8.760 μs | 3.90x faster | 0.5951 |    4959 B |          NA |
| Single_Parallel_Invoke_SIMD   | Vector128 | Single     | 111111 |  5.759 μs | 0.1627 μs |  5.740 μs | 5.96x faster | 0.5493 |    4580 B |          NA |
| Single_For                    | Vector256 | Single     | 111111 | 34.603 μs | 0.4754 μs | 34.639 μs | 1.01x slower |      - |         - |          NA |
| Single_For_GetReference       | Vector256 | Single     | 111111 | 25.683 μs | 0.3307 μs | 25.708 μs | 1.34x faster |      - |         - |          NA |
| Single_For_GetReference4      | Vector256 | Single     | 111111 | 24.840 μs | 0.3187 μs | 24.710 μs | 1.38x faster |      - |         - |          NA |
| Single_For_SIMD               | Vector256 | Single     | 111111 | 10.808 μs | 0.2226 μs | 10.799 μs | 3.18x faster |      - |         - |          NA |
| Single_System_Numerics_Tensor | Vector256 | Single     | 111111 | 11.331 μs | 0.8926 μs | 11.241 μs | 3.03x faster |      - |         - |          NA |
| Single_Parallel_For           | Vector256 | Single     | 111111 | 40.993 μs | 1.8325 μs | 40.735 μs | 1.18x slower | 0.5493 |    4940 B |          NA |
| Single_Parallel_Invoke        | Vector256 | Single     | 111111 |  8.816 μs | 0.1297 μs |  8.799 μs | 3.90x faster | 0.5951 |    4960 B |          NA |
| Single_Parallel_Invoke_SIMD   | Vector256 | Single     | 111111 |  5.579 μs | 0.1175 μs |  5.567 μs | 6.15x faster | 0.5417 |    4526 B |          NA |
| Single_For                    | Vector512 | Single     | 111111 | 34.520 μs | 0.5822 μs | 34.358 μs | 1.00x slower |      - |         - |          NA |
| Single_For_GetReference       | Vector512 | Single     | 111111 | 25.769 μs | 0.3657 μs | 25.700 μs | 1.33x faster |      - |         - |          NA |
| Single_For_GetReference4      | Vector512 | Single     | 111111 | 24.979 μs | 0.2496 μs | 24.966 μs | 1.38x faster |      - |         - |          NA |
| Single_For_SIMD               | Vector512 | Single     | 111111 | 10.849 μs | 0.2199 μs | 10.853 μs | 3.17x faster |      - |         - |          NA |
| Single_System_Numerics_Tensor | Vector512 | Single     | 111111 | 11.599 μs | 0.3649 μs | 11.631 μs | 2.95x faster |      - |         - |          NA |
| Single_Parallel_For           | Vector512 | Single     | 111111 | 41.344 μs | 1.2447 μs | 40.946 μs | 1.20x slower | 0.5493 |    4932 B |          NA |
| Single_Parallel_Invoke        | Vector512 | Single     | 111111 |  8.909 μs | 0.1620 μs |  8.879 μs | 3.86x faster | 0.5951 |    4949 B |          NA |
| Single_Parallel_Invoke_SIMD   | Vector512 | Single     | 111111 |  5.552 μs | 0.1235 μs |  5.537 μs | 6.19x faster | 0.5417 |    4531 B |          NA |

## Conclusions

The benchmarks demonstrate an improvement at each stage of the implementation. While parallelization on the CPU requires more complex code, it results in enhanced efficiency.

The complexity can be reduced by using libraries like [System.Numerics.Tensors](https://www.nuget.org/packages/System.Numerics.Tensors) or [NetFabric.Numerics.Tensors](https://www.nuget.org/packages/NetFabric.Numerics.Tensors), which make use of value-type delegates so that code similar to that shown in this article can be reused.

Despite the CPU large number of cores used, the performance gains from multi-threading appear limited and I do not yet understand why.

Feedback and suggestions for improving the article's content are appreciated.
