---
layout: post
read_time: true
show_date: true
title: "Enumeration in .NET - Count()"
date: 2018-06-09
img_path: /assets/img/posts/20180609
image: Giraffe.jpeg
tags: [development, .net, csharp]
category: development
---

## Count()

On [my previous article](https://aalmada.github.io/posts/Enumeration-in-dotnet/), I analysed the usage of `IEnumerable` strictly based on its contract. [It was brought to my attention](https://twitter.com/jonaskulhanek/status/1005102953831727105) that LINQ, short for "[LINQ to Objects](https://learn.microsoft.com/en-us/dotnet/csharp/linq/query-a-collection-of-objects)", optimizes some of the described scenarios, possibly breaking some of my assumptions. It’s a good point and I did some more research.

[Checking the implementation of the `Count()` extension method in LINQ](https://github.com/dotnet/corefx/blob/70ec0ad490754fa64ab06dde1d1f10e4d36a83a9/src/System.Linq/src/System/Linq/Count.cs#L12), we can see that it handles differently the case where the `IEnumerable` instance also implements `ICollection` or one other internal interface. This optimization is tricky and let me explain why.

First, this optimization is based on knowledge of the existence of other interfaces. It works with the current framework as all its collections implement `ICollection`, but who knows what interfaces and collections will be added in the future? `IReadOnlyCollection` was added to the framework after LINQ and it looks like they didn’t update this code. What about third-party libraries?

Second, the use of LINQ operators breaks the optimization. Let’s see…

The following code benchmarks the `Count()` extension method applied to an `IEnumerable`, a filtered `IEnumerable`, an `ICollection` and a filtered `ICollection`, for 0, 10 and 100 elements:

```csharp
using BenchmarkDotNet.Attributes;
using System.Collections.Generic;
using System.Linq;

namespace EnumerationBenchmarks
{
    [MemoryDiagnoser]
    public class CountBenchmarks
    {
        IEnumerable<int> enumerable;
        IEnumerable<int> filteredEnumerable;
        IEnumerable<int> collection;
        IEnumerable<int> filteredCollection;

        [Params(0, 10, 100)]
        public int ItemsCount { get; set; }

        [GlobalSetup]
        public void Setup()
        {
            enumerable = MyRange(0, ItemsCount);

            filteredEnumerable = enumerable
                .Where(_ => true);

            collection = enumerable
                .ToList();

            filteredCollection = collection
                .Where(_ => true);
        }

        [Benchmark]
        public int Enumerable_Count() =>
            enumerable.Count();

        [Benchmark]
        public int FilteredEnumerable_Count() =>
            filteredEnumerable.Count();

        [Benchmark]
        public int Collection_Count() =>
            collection.Count();

        [Benchmark]
        public int FilteredCollection_Count() =>
            filteredCollection.Count();

        static IEnumerable<int> MyRange(int start, int count)
        {
            var end = start + count;
            for (var value = start; value < end; value++)
                yield return value;
        }
    }
}
```

> NOTE: I initially used `Enumerable.Range()` for the `IEnumerable` instance but the results where not what I expected. It turns out [it implements the internal interface that is optimized in `Count()`](https://github.com/dotnet/corefx/blob/70ec0ad490754fa64ab06dde1d1f10e4d36a83a9/src/System.Linq/src/System/Linq/Range.cs#L31). The method `MyRange()`, implemented at the bottom, returns a pure `IEnumerable` instance.

The results of the benchmark were the following:

```
BenchmarkDotNet v0.13.12, macOS Sonoma 14.3 (23D56) [Darwin 23.3.0]
Apple M1, 1 CPU, 8 logical and 8 physical cores
.NET SDK 8.0.100
  [Host]     : .NET 8.0.0 (8.0.23.53103), Arm64 RyuJIT AdvSIMD
  DefaultJob : .NET 8.0.0 (8.0.23.53103), Arm64 RyuJIT AdvSIMD
```

| Method                   | ItemsCount | Mean       | Error     | StdDev    | Gen0   | Allocated |
|------------------------- |----------- |-----------:|----------:|----------:|-------:|----------:|
| **Enumerable_Count**         | **0**          |  **22.629 ns** | **0.0165 ns** | **0.0146 ns** | **0.0089** |      **56 B** |
| FilteredEnumerable_Count | 0          |  21.174 ns | 0.0976 ns | 0.0815 ns | 0.0089 |      56 B |
| Collection_Count         | 0          |   2.920 ns | 0.0025 ns | 0.0023 ns |      - |         - |
| FilteredCollection_Count | 0          |   9.021 ns | 0.0142 ns | 0.0118 ns |      - |         - |
| **Enumerable_Count**         | **10**         |  **54.165 ns** | **0.1742 ns** | **0.1629 ns** | **0.0089** |      **56 B** |
| FilteredEnumerable_Count | 10         |  56.801 ns | 0.1018 ns | 0.0850 ns | 0.0089 |      56 B |
| Collection_Count         | 10         |   2.934 ns | 0.0359 ns | 0.0336 ns |      - |         - |
| FilteredCollection_Count | 10         |  26.009 ns | 0.0593 ns | 0.0526 ns |      - |         - |
| **Enumerable_Count**         | **100**        | **393.815 ns** | **1.0288 ns** | **0.9120 ns** | **0.0086** |      **56 B** |
| FilteredEnumerable_Count | 100        | 396.215 ns | 1.0694 ns | 1.0003 ns | 0.0086 |      56 B |
| Collection_Count         | 100        |   2.961 ns | 0.0020 ns | 0.0016 ns |      - |         - |
| FilteredCollection_Count | 100        | 180.376 ns | 0.3111 ns | 0.2429 ns |      - |         - |

As expected, `Enumerable_Count` allocates on the heap and its mean time increases directly with the number of elements, which is all bad.

[Also expected from the `Count()` implementation](https://github.com/dotnet/corefx/blob/70ec0ad490754fa64ab06dde1d1f10e4d36a83a9/src/System.Linq/src/System/Linq/Count.cs#L12), `Collection_Count` is much faster than `Enumerable_Count`, doesn’t allocate on the heap and has constant mean time whatever number of elements, which is all great.

What it’s important here is that, although `FilteredCollection_Count` was created as a collection, its mean time increases directly with the number of elements. It’s a smoother increase than with `FilteredEnumerable_Count` but still a complexity of O(n).

## Conclusions

When you have a method with an `IEnumerable` argument, it’s assumed you have no idea how it was created. You should not expect `Count()` to have any complexity other than O(n).

If you can optimize the algorithm given more capabilities, make it explicit by using other interfaces like `IReadOnlyCollection`, `IReadOnlyList`, `IReadOnlyDictionary` or any other that makes sense.

> The optimization seems to be misleading.

If you follow the rules from [my previous article](https://aalmada.github.io/posts/Enumeration-in-dotnet/), you won’t have any surprises…
