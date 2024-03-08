---
layout: post
read_time: true
show_date: true
title: "Measuring .NET Performance: Unleashing the Power of BenchmarkDotNet"
date: 2024-03-08
img_path: /assets/img/posts/20240308
image: BelaVista.jpg
tags: [development, .net, csharp, benchmarking]
category: development
---

As a software engineer, I regard performance as a crucial metric for assessing the quality of my code. In my [previous article](https://aalmada.github.io/posts/Performance-optimizations/), I emphasized how performance impacts user behavior, costs, and the environment. Let's break it down:

1. **Mobile Apps**: Well-performing mobile apps consume **less battery**, leading to a better user experience.
2. **Realtime Apps**: When realtime apps perform optimally, they achieve **higher refresh rates**, ensuring smoother interactions.
3. **Cloud Apps**: Efficiently performing cloud apps require **fewer resources**, which translates to **lower costs** and faster response times.
4. **Resource Efficiency**: Using fewer resources results in **smaller data centers**, reduced energy consumption, and a **healthier environment**.

Here's the bottom line: Neglecting performance is a disservice.

## Just-In-Time (JIT) Compiler

The compiler plays a crucial role in translating human-readable code into a format that machines can understand and execute. During this process, the compiler has the freedom to reinterpret instructions for more efficient execution.

Typically, this translation occurs at compile time, which happens just once before the execution time or runtime. However, certain development frameworks, like .NET, follow a two-stage compilation process:

1. **Human-Readable to Intermediate Language**: Initially, there's a compilation from human-readable code to an intermediate language. This step occurs on the developer's machine or during continuous integration.
2. **Just-In-Time (JIT) Compilation**: The JIT compiler converts the intermediate language into the specific machine language of the execution environment before the code is executed. This dynamic compilation allows the code to be optimized for the specific hardware it runs on.

But here's the twist: achieving the best optimization takes time. To avoid impacting application startup time, the JIT compiler typically applies only the most obvious optimizations initially. However, .NET has evolved to perform optimizations beyond startup. It dynamically tracks frequently executed code segments and may replace them with more efficient alternatives during execution.

Now, why is this relevant? When measuring performance in .NET, relying solely on a timer won't cut it. [BenchmarkDotNet](https://benchmarkdotnet.org/) is a powerful benchmarking tool for .NET. It takes all these intricacies into account when assessing the performance of any code segment. So, if you're serious about performance, think beyond the stopwatch—think BenchmarkDotNet!

## Setting Up a Benchmarking Project

To get started with BenchmarkDotNet, follow these steps:

1. **Create a Console Application Project**: Start by setting up a new console application project. This will be the base for your benchmarking tasks.

2. **Add BenchmarkDotNet as a Dependency**: You can find BenchmarkDotNet on [NuGet](https://www.nuget.org/packages/BenchmarkDotNet/). Incorporate it into your project by adding it as a dependency.

3. **Modify the `Program.cs`**: BenchmarkDotNet can dynamically locate benchmarks in the project using the `BenchmarkSwitcher` class. Modify the `Program.cs` file as follows:

```csharp
using BenchmarkDotNet.Running;

public class Program
{
    public static void Main(string[] args)
        => BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args);
}
```

If you're using C# 10 or newer, you can leverage [top-level statements](https://learn.microsoft.com/en-us/dotnet/csharp/tutorials/top-level-statements) and simplify to:

```csharp
using BenchmarkDotNet.Running;

BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args);
```

These lines locate all benchmarks in the assembly containing the `Program` class and present a menu, allowing you to choose which ones to execute.

## Including a Benchmark

To include benchmarks, create a class with methods decorated with the `BenchmarkAttribute`. You can have as many of these classes as you wish, and they will be listed as additional options in the starting menu.

For instance, let's examine comparing the performance of iterating a `List<T>` versus iterating it using `CollectionsMarshal.AsSpan()`. This method accepts a `List<T>` as input and returns its internal array as a `Span<T>`. We aim to assess potential performance enhancements.

Here's a concise example:

```csharp
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using BenchmarkDotNet.Attributes;

public class ListBenchmarks
{
    readonly List<int> list = Enumerable.Range(0, 1_000).ToList();

    [Benchmark(Baseline = true)]
    public int Foreach()
    {
        var sum = 0;
        foreach (var item in list)
            sum += item;
        return sum;
    }

    [Benchmark]
    public int Foreach_AsSpan()
    {
        var sum = 0;
        foreach (var item in CollectionsMarshal.AsSpan(list))
            sum += item;
        return sum;
    }
}
```

Key points to note:

- The `list` field comprises a read-only list containing 1,000 elements. It's initialized here using `Range()` and `ToList()` to ensure that initialization doesn't affect the benchmarks.
- The benchmark comprises two methods. One iterates directly over the `List<int>`, while the other employs `CollectionsMarshal.AsSpan()` and iterates over the resulting `Span<int>`.
- Both methods are marked with the `[Benchmark]` attribute.
- The first method designates the `Baseline` property of the attribute as `true`, indicating it as the baseline for comparison.
- JIT compiler behavior may lead to the removal of unused code. Therefore, it's essential to have a result and return it. These benchmarks calculate the sum of the items and return it. While this affects execution time, it's comparable across both scenarios and can be disregarded for comparison purposes.

## Running the Benchmarks

Since this project generates an executable, running the benchmarks is straightforward - just execute the executable. However, ensure that it's compiled in Release mode and without a debugger attached. If you prefer using the command line, simply enter:

```bash
dotnet run -c:Release
```

Upon execution, you'll encounter a menu displaying all available benchmarks along with instructions on how to execute one or multiple benchmarks simultaneously.

During benchmark execution, you'll notice it automatically runs through multiple stages and performs multiple executions per stage. Should you wish to customize any of these settings, refer to the [jobs documentation](https://benchmarkdotnet.org/articles/configs/jobs.html).

## Results

BenchmarkDotNet automatically filters out outlier results and notifies you if the distribution is not normal. Once all benchmarks have run, it presents detailed statistical outcomes, enabling further evaluation of result validity. Keep in mind that benchmark performance may be influenced by resource constraints such as memory or CPU time.

Additionally, it provides information on the versions of BenchmarkDotNet and .NET used, along with hardware system characteristics:

```
BenchmarkDotNet v0.13.8, macOS Sonoma 14.4 (23E214) [Darwin 23.4.0]
Apple M1, 1 CPU, 8 logical and 8 physical cores
.NET SDK 8.0.201
  [Host]     : .NET 8.0.2 (8.0.224.6711), Arm64 RyuJIT AdvSIMD
  DefaultJob : .NET 8.0.2 (8.0.224.6711), Arm64 RyuJIT AdvSIMD
```

Furthermore, it furnishes a tabulated view of results for each benchmark:

| Method         |     Mean |   Error |  StdDev | Ratio |
| -------------- | -------: | ------: | ------: | ----: |
| Foreach        | 474.7 ns | 0.79 ns | 0.74 ns |  1.00 |
| Foreach_AsSpan | 340.3 ns | 0.39 ns | 0.30 ns |  0.72 |

This table showcases the mean, error, and standard deviation of all considered execution times.

The `Ratio` column indicates the ratio of mean times between the baseline benchmark and each benchmark being compared. In this case, utilizing `AsSpan()` takes only 0.72 times the time compared to not using it.

Additionally, you can find the results saved as markdown files on your hard drive. On macOS, they're stored within the `BenchmarkDotNet.Artifacts/results` directory. On Windows, you'll typically find them in the `bin/Release/net8.0/BenchmarkDotNet.Artifacts/results` directory, where `net8.0` may vary depending on the version used.

For additional report formats, consult the [exporters documentation](https://benchmarkdotnet.org/articles/configs/exporters.html).

## Memory Usage Analysis

In addition to measuring the time taken for a particular operation, it may be crucial to benchmark the amount of memory allocated on the heap. These allocations can impose pressure on the garbage collector, impacting the application's performance even after the operation has completed.

You can include memory consumption information in the results by simply applying the `MemoryDiagnoserAttribute` to the benchmarking class:

```csharp
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using BenchmarkDotNet.Attributes;

[MemoryDiagnoser]
public class ListBenchmarks
{
    readonly List<int> list = Enumerable.Range(0, 1_000).ToList();

    [Benchmark(Baseline = true)]
    public int Foreach()
    {
        var sum = 0;
        foreach (var item in list)
            sum += item;
        return sum;
    }

    [Benchmark]
    public int Foreach_IEnumerable()
    {
        var sum = 0;
        foreach (var item in (IEnumerable<int>)list)
            sum += item;
        return sum;
    }

    [Benchmark]
    public int Foreach_AsSpan()
    {
        var sum = 0;
        foreach (var item in CollectionsMarshal.AsSpan(list))
            sum += item;
        return sum;
    }
}
```

An additional benchmark has been added to illustrate the usage of the `MemoryDiagnoserAttribute`. The results will now display memory consumption information:

| Method              |       Mean |   Error |  StdDev | Ratio |   Gen0 | Allocated | Alloc Ratio |
| ------------------- | ---------: | ------: | ------: | ----: | -----: | --------: | ----------: |
| Foreach             |   474.9 ns | 0.69 ns | 0.57 ns |  1.00 |      - |         - |          NA |
| Foreach_IEnumerable | 2,125.0 ns | 4.56 ns | 3.81 ns |  4.47 | 0.0038 |      40 B |          NA |
| Foreach_AsSpan      |   340.2 ns | 0.15 ns | 0.13 ns |  0.72 |      - |         - |          NA |

The added benchmark `Foreach_IEnumerable()` casts the `List<T>` to `IEnumerable<T>`. You can observe that this version allocates memory on the heap and is much slower. As explained in a [previous article](https://aalmada.github.io/posts/Leveraging-csharp-foreach-loop/), when using `foreach`, it calls the method `GetEnumerator()` to retrieve an instance of the list enumerator. The difference lies in the fact that when calling directly from `List<T>`, it gets a value-typed enumerator allocated on the stack, while calling it from `IEnumerable<T>` retrieves a reference-typed enumerator allocated on the heap. As elaborated in [another article](https://aalmada.github.io/posts/Value-type-vs-reference-type-enumerables/), the reference-typed enumerator is significantly slower than the value-typed one due to the invocation of virtual functions.

The `foreach` loop on `Span<T>` does not employ an enumerator; instead, it utilizes the indexer.

## Varying Parameters

Currently, the benchmark only evaluates iteration performance for a list containing 1,000 elements. However, performance can exhibit non-linear behavior. It's crucial to benchmark across various data sizes. BenchmarkDotNet facilitates this through the use of the `ParamsAttribute`. When applied to a property within the benchmark class, this attribute passes values to the property, executing benchmarks for each value.

Suppose we wish to benchmark for both a small list of 10 items and a large list of 1,000 items. Here's how it's done:

```csharp
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using BenchmarkDotNet.Attributes;

public class ListBenchmarks
{
    List<int> list;

    [Params(10, 1_000)]
    public int Count { get; set; }

    [GlobalSetup]
    public void GlobalSetup()
    {
        list = Enumerable.Range(0, Count).ToList();
    }

    [Benchmark(Baseline = true)]
    public int Foreach()
    {
        var sum = 0;
        foreach (var item in list)
            sum += item;
        return sum;
    }

    [Benchmark]
    public int Foreach_AsSpan()
    {
        var sum = 0;
        foreach (var item in CollectionsMarshal.AsSpan(list))
            sum += item;
        return sum;
    }
}
```

Here, a `Count` property has been introduced with the `ParamsAttribute` containing a list of two values. You can extend this with as many values as necessary.

The `list` field can no longer be initialized inline. Instead, a method with the `GlobalSetupAttribute` has been added, which executes before benchmark execution.

You'll observe that the resulting table now contains a column with the same name as the property, with lines added for each value in the `ParamsAttribute` list.

| Method         | Count    |           Mean |         Error |        StdDev |    Ratio |
| -------------- | -------- | -------------: | ------------: | ------------: | -------: |
| **Foreach**    | **10**   |  **10.585 ns** | **0.0775 ns** | **0.0725 ns** | **1.00** |
| Foreach_AsSpan | 10       |       4.264 ns |     0.0134 ns |     0.0104 ns |     0.40 |
|                |          |                |               |               |          |
| **Foreach**    | **1000** | **481.003 ns** | **5.0947 ns** | **4.7656 ns** | **1.00** |
| Foreach_AsSpan | 1000     |     341.624 ns |     2.2913 ns |     2.1432 ns |     0.71 |

It's noteworthy that the ratio when using `AsSpan` is much better for a small list.

Please note that in many cases, benchmarks may indicate worse performance for small data collections but better performance for large data collections. In such cases, it's essential to examine the `Mean` column. While it may show a slightly higher mean for small data cases, it may show a significantly smaller mean for large data cases.

## Benchmark Categories

It can be beneficial to run different benchmarks and observe the results in a unified table. BenchmarkDotNet supports categories for this purpose.

To utilize categories, use the `GroupBenchmarksByAttribute` to specify grouping benchmarks by category. Then, apply the `BenchmarkCategoryAttribute` to each benchmark method to indicate its category.
Note that one baseline per category is permitted.

You can also include the `CategoriesColumn` to add a `Categories` column to the results table. If desired, you can remove unnecessary columns using the `HideColumnsAttribute`.

Let's apply this feature to understand how the item type affects performance. We'll now have two lists with different types and methods that operate on these lists, with categories specified for each method:

```csharp
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Columns;
using BenchmarkDotNet.Configs;

[GroupBenchmarksBy(BenchmarkLogicalGroupRule.ByCategory)]
[CategoriesColumn]
[HideColumns(Column.Error)]
public class ListBenchmarks
{
    List<int> listInt;
    List<float> listSingle;

    [Params(10, 1_000)]
    public int Count { get; set; }

    [GlobalSetup]
    public void GlobalSetup()
    {
        var source = Enumerable.Range(0, Count);
        listInt = source.ToList();
        listSingle = source.Select(value => (float)value).ToList();
    }

    [BenchmarkCategory("Int")]
    [Benchmark(Baseline = true)]
    public int Foreach_Int()
    {
        var sum = 0;
        foreach (var item in listInt)
            sum += item;
        return sum;
    }

    [BenchmarkCategory("Int")]
    [Benchmark]
    public int Foreach_AsSpan_Int()
    {
        var sum = 0;
        foreach (var item in CollectionsMarshal.AsSpan(listInt))
            sum += item;
        return sum;
    }

    [BenchmarkCategory("Single")]
    [Benchmark(Baseline = true)]
    public float Foreach_Single()
    {
        var sum = 0.0f;
        foreach (var item in listSingle)
            sum += item;
        return sum;
    }

    [BenchmarkCategory("Single")]
    [Benchmark]
    public float Foreach_AsSpan_Single()
    {
        var sum = 0.0f;
        foreach (var item in CollectionsMarshal.AsSpan(listSingle))
            sum += item;
        return sum;
    }
}
```

The results will now be organized as follows:

| Method                | Categories | Count    |           Mean |        StdDev |    Ratio |
| --------------------- | ---------- | -------- | -------------: | ------------: | -------: |
| **Foreach_Int**       | **Int**    | **10**   |  **11.227 ns** | **0.0511 ns** | **1.00** |
| Foreach_AsSpan_Int    | Int        | 10       |       4.245 ns |     0.0049 ns |     0.38 |
|                       |            |          |                |               |          |
| **Foreach_Int**       | **Int**    | **1000** | **474.122 ns** | **0.2225 ns** | **1.00** |
| Foreach_AsSpan_Int    | Int        | 1000     |     343.179 ns |     0.2129 ns |     0.72 |
|                       |            |          |                |               |          |
| **Foreach_Single**    | **Single** | **10**   |   **6.083 ns** | **0.0056 ns** | **1.00** |
| Foreach_AsSpan_Single | Single     | 10       |       4.190 ns |     0.0035 ns |     0.69 |
|                       |            |          |                |               |          |
| **Foreach_Single**    | **Single** | **1000** | **908.171 ns** | **0.2079 ns** | **1.00** |
| Foreach_AsSpan_Single | Single     | 1000     |     878.469 ns |     6.2301 ns |     0.97 |

In this setup, you can observe how the item type influences performance across different data types.

## Comparing .NET Versions

Understanding how the performance of a particular feature has evolved between two or more versions of .NET can be insightful. This comparison can be achieved by configuring multiple jobs.

You can set up the configuration in the `Program.cs` file as follows:

```csharp
using BenchmarkDotNet.Columns;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Reports;
using BenchmarkDotNet.Running;
using BenchmarkDotNet.Environments;
using BenchmarkDotNet.Jobs;

var config = DefaultConfig.Instance
    .WithSummaryStyle(SummaryStyle.Default.WithRatioStyle(RatioStyle.Trend))
    .HideColumns(Column.RatioSD)
    .AddJob(Job.Default.WithRuntime(CoreRuntime.Core60))
    .AddJob(Job.Default.WithRuntime(CoreRuntime.Core80));

BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args, config);
```

This configuration defines two jobs with different runtimes. Please note that the host runtime must support the others. This means that in the `.csproj` file, you must set `TargetFramework` to be the same as or older than the oldest runtime of the jobs.

Additionally, the configuration sets the style of the `Ratio` column to `Trend` and hides the `RatioSD` column.

The results will now look like this:

| Method                | Runtime      | Categories | Count    |           Mean |        StdDev |        Ratio |
| --------------------- | ------------ | ---------- | -------- | -------------: | ------------: | -----------: |
| **Foreach_Int**       | **.NET 6.0** | **Int**    | **10**   |  **12.436 ns** | **0.0626 ns** | **baseline** |
| Foreach_AsSpan_Int    | .NET 6.0     | Int        | 10       |      10.205 ns |     0.0310 ns | 1.22x faster |
|                       |              |            |          |                |               |              |
| Foreach_Int           | .NET 8.0     | Int        | 10       |      11.274 ns |     0.0900 ns |     baseline |
| Foreach_AsSpan_Int    | .NET 8.0     | Int        | 10       |       4.351 ns |     0.0509 ns | 2.59x faster |
|                       |              |            |          |                |               |              |
| **Foreach_Int**       | **.NET 6.0** | **Int**    | **1000** | **954.474 ns** | **5.4475 ns** | **baseline** |
| Foreach_AsSpan_Int    | .NET 6.0     | Int        | 1000     |     573.550 ns |     2.8059 ns | 1.66x faster |
|                       |              |            |          |                |               |              |
| Foreach_Int           | .NET 8.0     | Int        | 1000     |     475.787 ns |     1.2944 ns |     baseline |
| Foreach_AsSpan_Int    | .NET 8.0     | Int        | 1000     |     343.222 ns |     1.8132 ns | 1.39x faster |
|                       |              |            |          |                |               |              |
| **Foreach_Single**    | **.NET 6.0** | **Single** | **10**   |  **12.500 ns** | **0.0681 ns** | **baseline** |
| Foreach_AsSpan_Single | .NET 6.0     | Single     | 10       |       4.588 ns |     0.0276 ns | 2.72x faster |
|                       |              |            |          |                |               |              |
| Foreach_Single        | .NET 8.0     | Single     | 10       |       6.463 ns |     0.0395 ns |     baseline |
| Foreach_AsSpan_Single | .NET 8.0     | Single     | 10       |       4.205 ns |     0.0107 ns | 1.54x faster |
|                       |              |            |          |                |               |              |
| **Foreach_Single**    | **.NET 6.0** | **Single** | **1000** | **959.066 ns** | **4.0759 ns** | **baseline** |
| Foreach_AsSpan_Single | .NET 6.0     | Single     | 1000     |     879.594 ns |     4.9575 ns | 1.09x faster |
|                       |              |            |          |                |               |              |
| Foreach_Single        | .NET 8.0     | Single     | 1000     |     913.371 ns |     2.9861 ns |     baseline |
| Foreach_AsSpan_Single | .NET 8.0     | Single     | 1000     |     872.459 ns |     0.7513 ns | 1.05x faster |

This setup repeats the benchmarks for each runtime. Notably, the `Ratio` column now features an easier-to-read style.

## Environment variables

Specific environmental variables can have an impact on performance. Running different jobs with varied environmental variable values can produce diverse results. This aspect is particularly crucial when benchmarking code utilizing SIMD vectorization. For detailed guidance on benchmarking such code, please consult my [other article](https://aalmada.github.io/posts/Unit-testing-and-benchmarking-SIMD-in-dotnet/).
