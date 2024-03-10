---
layout: post
read_time: true
show_date: true
title: "Unit testing and benchmarking SIMD in .NET"
date: 2024-02-20
img_path: /assets/img/posts/20240220
image: Alcantara.jpg
tags: [development, .net, csharp, simd, intrinsics, unit testing, benchmarking]
category: development
redirect_from: /Unit-testing-and-benchmarking-SIMD-in-dotnet.html
---

Single Instruction, Multiple Data (SIMD) is a technique used in computer architecture that allows for parallel processing on multiple data elements simultaneously. I've touched on the advantages of SIMD and its implementation in .NET in a [previous article](https://aalmada.github.io/posts/SIMD-in-dotnet/).

The performance of SIMD depends on the hardware that the application is running on. Except for a few specific scenarios, developers must ensure that their applications can function in any situation. This includes operating on systems that either don't support SIMD, or support 128-bit, 256-bit, or even 512-bit SIMD. Consequently, to achieve comprehensive coverage during unit testing, it’s crucial to conduct tests across all these diverse systems. Additionally, it’s necessary to perform performance tests on these systems to check if the application is using the system’s capabilities effectively. Even if you don't directly use SIMD, your dependencies may make use of it.

However, this doesn't mean that these tests have to be carried out on separate physical systems. These features can be disabled via software by modifying environment variables. This article mainly focuses on identifying the variables that need to be modified and how to do so during local unit testing, continuous integration pipeline testing, and performance testing.

# Environment Variables

.NET provides the ability to disable hardware features using the environment variables listed below:

- `DOTNET_EnableHWIntrinsic` - Toggles SIMD support.
- `DOTNET_EnableAVX2` - Toggles 256-bit SIMD support.
- `DOTNET_EnableAVX512F` - Toggles 512-bit SIMD support.

You can enable these features by setting the variables to `1` and disable them by setting to `0`. By default, the value is set to `1`.

The following settings correspond to the given scenarios:

- No SIMD:
  - `DOTNET_EnableHWIntrinsic` - `0`
- Support 128-bit SIMD:
  - `DOTNET_EnableHWIntrinsic` - `1`
  - `DOTNET_EnableAVX2` - `0`
  - `DOTNET_EnableAVX512F` - `0`
- Support up to 256-bit SIMD:
  - `DOTNET_EnableHWIntrinsic` - `1`
  - `DOTNET_EnableAVX2` - `1`
  - `DOTNET_EnableAVX512F` - `0`
- Support up to 512-bit SIMD:
  - `DOTNET_EnableHWIntrinsic` - `1`
  - `DOTNET_EnableAVX2` - `1`
  - `DOTNET_EnableAVX512F` - `1`

Keep in mind that these variables only provide the option to disable features. If you aim to test the application with 512-bit SIMD, it's necessary for the hardware to support it. You can only force the application to use a lower bit SIMD or even turn off all SIMD.

Keep in mind that `Vector<T>` will consistently utilize the maximum bit count available, while the availability of `Vector128<T>`, `Vector256<T>`, and `Vector512<T>` depends on the supported bit count and may be enabled or disabled accordingly.

# Unit Testing

There are various methods to execute unit tests in .NET. In this section, I will discuss the ones that I have used and successfully configured to handle multiple scenarios.

## Utilizing a `.runsettings` File to Configure Unit Tests

A `.runsettings` file can be employed to control how unit tests are run. This allows for [the adjustment of various settings](https://learn.microsoft.com/en-us/visualstudio/test/configure-unit-tests-by-using-a-dot-runsettings-file), including environment variables.

You can create multiple `.runsettings` files for different configurations. I typically generate the following files and place them within the repository folder structure:

**\_Scalar.runsettings**

```xml
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
    <RunConfiguration>
        <EnvironmentVariables>
            <DOTNET_EnableHWIntrinsic>0</DOTNET_EnableHWIntrinsic>
        </EnvironmentVariables>
    </RunConfiguration>
</RunSettings>
```

**\_Vector128.runsettings**

```xml
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
    <RunConfiguration>
        <EnvironmentVariables>
            <DOTNET_EnableHWIntrinsic>1</DOTNET_EnableHWIntrinsic>
            <DOTNET_EnableAVX2>0</DOTNET_EnableAVX2>
            <DOTNET_EnableAVX512F>0</DOTNET_EnableAVX512F>
        </EnvironmentVariables>
    </RunConfiguration>
</RunSettings>
```

**\_Vector256.runsettings**

```xml
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
    <RunConfiguration>
        <EnvironmentVariables>
            <DOTNET_EnableHWIntrinsic>1</DOTNET_EnableHWIntrinsic>
            <DOTNET_EnableAVX512F>0</DOTNET_EnableAVX512F>
        </EnvironmentVariables>
    </RunConfiguration>
</RunSettings>
```

**\_Vector512.runsettings**

```xml
<?xml version="1.0" encoding="utf-8"?>
<RunSettings>
    <RunConfiguration>
        <EnvironmentVariables>
            <DOTNET_EnableHWIntrinsic>1</DOTNET_EnableHWIntrinsic>
        </EnvironmentVariables>
    </RunConfiguration>
</RunSettings>
```

I append a suffix `_` to the file names just to make it easier to locate them in a list of files.

In the following sections, I will explain how to utilize these files in various development environments.

## Visual Studio

Visual Studio has the capability to automatically detect a `.runsettings` file and utilize it when executing unit tests. However, in instances where multiple `.runsettings` files are present, manual selection of the desired file is required.

To do this in the IDE, navigate to `Test > Configure Run Settings > Select Solution Wide runsettings File`, and then choose the `.runsettings` file with the settings you wish to apply.

You can now execute the unit tests using the settings from the selected file.

## Command Line

You can run the unit tests from the command line by using the `dotnet test` command. This comes in handy when working with Visual Studio Code or when configuring continuous integration pipelines.

The `dotnet test` command permits the configuration of environment variables using the `--environment` option or its shorter form `-e`. Here's an example of how it can be used to support 128-bit SIMD:

```bash
dotnet test -e:DOTNET_EnableAVX2=0 -e:DOTNET_EnableAVX512F=0
```

The `dotnet test` command can also accommodates the use of `.runsettings` files with the `--settings` option or its abbreviated form `-s`. Here's the equivalent example using a setting file:

```bash
dotnet test -s:_Vector128.runsettings
```

# Performance Testing

For .NET performance testing, I consistently utilize [BenchmarkDotNet](https://benchmarkdotnet.org/). It's a tool that not only provides precise results but is also user-friendly.

BenchmarkDotNet introduces the concept of jobs, which allows you to run the same benchmarks under varying conditions and compare their performance. While there are numerous ways to configure these jobs, my preferred method is to define a configuration class:

```csharp
using BenchmarkDotNet.Columns;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Jobs;
using BenchmarkDotNet.Reports;
using System.Runtime.Intrinsics;

class VectorizationConfig : ManualConfig
{
    public VectorizationConfig()
    {
        _ = WithSummaryStyle(SummaryStyle.Default.WithRatioStyle(RatioStyle.Trend));
        _ = HideColumns(Column.EnvironmentVariables, Column.RatioSD, Column.Error);
        _ = AddJob(Job.Default.WithId("Scalar")
            .WithEnvironmentVariable("DOTNET_EnableHWIntrinsic", "0")
            .AsBaseline());
        if (Vector128.IsHardwareAccelerated)
        {
            _ = AddJob(Job.Default.WithId("Vector128")
                    .WithEnvironmentVariable("DOTNET_EnableAVX2", "0")
                    .WithEnvironmentVariable("DOTNET_EnableAVX512F", "0"));
        }
        if (Vector256.IsHardwareAccelerated)
        {
            _ = AddJob(Job.Default.WithId("Vector256")
                .WithEnvironmentVariable("DOTNET_EnableAVX512F", "0"));
        }
        if (Vector512.IsHardwareAccelerated)
        {
            _ = AddJob(Job.Default.WithId("Vector512"));
        }
    }
}
```

> Note: If you're intrigued about why I use the discards in this code, you might find my other article "[Defensive Coding in C#: A Closer Look at Unchecked Return Value Discards](https://aalmada.github.io/posts/A-closer-look-at-unchecked-return-value-discards/)" interesting.

This class adds a job named `Scalar` that executes the benchmarks with SIMD disabled and sets it as the baseline. If the hardware supports 128-bit SIMD, it adds a job named `Vector128`, and similarly for 256-bit and 512-bit SIMD.

You can then use this class in conjunction with the `ConfigAttribute`. Simply add `[Config(typeof(VectorizationConfig))]` to your benchmarking classes. The advantage of this approach is that you can apply this attribute to only those benchmarks that you wish to test under multiple SIMD scenarios.

For example:

```csharp
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Configs;
using System.Numerics.Tensors;

namespace NetFabric.Numerics.Tensors.Benchmarks;

[Config(typeof(VectorizationConfig))]
[GroupBenchmarksBy(BenchmarkLogicalGroupRule.ByCategory)]
[CategoriesColumn]
public class SumBenchmarks
{
    int[]? arrayInt;
    float[]? arrayFloat;

    [Params(5, 100)]
    public int Count { get; set; }

    [GlobalSetup]
    public void GlobalSetup()
    {
        arrayInt = new int[Count];
        arrayFloat = new float[Count];

        var random = new Random(42);
        for(var index = 0; index < Count; index++)
        {
            arrayInt[index] = random.Next(10);
            arrayFloat[index] = random.Next(10);
        }
    }

    [BenchmarkCategory("Int")]
    [Benchmark(Baseline = true)]
    public int Baseline_Int()
        => Baseline.Sum<int>(arrayInt!);

    [BenchmarkCategory("Int")]
    [Benchmark]
    public int LINQ_Int()
        => Enumerable.Sum(arrayInt!);

    [BenchmarkCategory("Int")]
    [Benchmark]
    public int System_Int()
        => TensorPrimitives.Sum<int>(arrayInt!);

    [BenchmarkCategory("Int")]
    [Benchmark]
    public int NetFabric_Int()
        => TensorOperations.Sum<int>(arrayInt!);

    [BenchmarkCategory("Float")]
    [Benchmark(Baseline = true)]
    public float Baseline_Float()
        => Baseline.Sum<float>(arrayFloat!);

    [BenchmarkCategory("Float")]
    [Benchmark]
    public float System_Float()
        => TensorPrimitives.Sum(arrayFloat!);

    [BenchmarkCategory("Float")]
    [Benchmark]
    public float NetFabric_Float()
        => TensorOperations.Sum<float>(arrayFloat!);
}
```

Outputs the following:

```
BenchmarkDotNet v0.13.12, Windows 11 (10.0.22631.3007/23H2/2023Update/SunValley3)
AMD Ryzen 9 7940HS w/ Radeon 780M Graphics, 1 CPU, 16 logical and 8 physical cores
.NET SDK 8.0.101
  [Host]    : .NET 8.0.1 (8.0.123.58001), X64 RyuJIT AVX-512F+CD+BW+DQ+VL+VBMI
  Scalar    : .NET 8.0.1 (8.0.123.58001), X64 RyuJIT
  Vector128 : .NET 8.0.1 (8.0.123.58001), X64 RyuJIT AVX
  Vector256 : .NET 8.0.1 (8.0.123.58001), X64 RyuJIT AVX2
  Vector512 : .NET 8.0.1 (8.0.123.58001), X64 RyuJIT AVX-512F+CD+BW+DQ+VL+VBMI
```

| Method             | Job        | Categories | Count   |          Mean |        StdDev |        Ratio |
| ------------------ | ---------- | ---------- | ------- | ------------: | ------------: | -----------: |
| **Baseline_Float** | **Scalar** | **Float**  | **5**   |  **1.856 ns** | **0.0284 ns** | **baseline** |
| LINQ_Float         | Scalar     | Float      | 5       |      2.765 ns |     0.0696 ns | 1.49x slower |
| System_Float       | Scalar     | Float      | 5       |      1.820 ns |     0.0235 ns | 1.02x faster |
| NetFabric_Float    | Scalar     | Float      | 5       |      1.734 ns |     0.0292 ns | 1.07x faster |
| Baseline_Float     | Vector128  | Float      | 5       |      1.810 ns |     0.0304 ns | 1.03x faster |
| LINQ_Float         | Vector128  | Float      | 5       |      2.745 ns |     0.0475 ns | 1.48x slower |
| System_Float       | Vector128  | Float      | 5       |      3.286 ns |     0.0605 ns | 1.77x slower |
| NetFabric_Float    | Vector128  | Float      | 5       |      1.908 ns |     0.0242 ns | 1.03x slower |
| Baseline_Float     | Vector256  | Float      | 5       |      1.790 ns |     0.0287 ns | 1.04x faster |
| LINQ_Float         | Vector256  | Float      | 5       |      2.661 ns |     0.0502 ns | 1.43x slower |
| System_Float       | Vector256  | Float      | 5       |      2.318 ns |     0.0145 ns | 1.25x slower |
| NetFabric_Float    | Vector256  | Float      | 5       |      1.921 ns |     0.0251 ns | 1.04x slower |
| Baseline_Float     | Vector512  | Float      | 5       |      1.820 ns |     0.0176 ns | 1.02x faster |
| LINQ_Float         | Vector512  | Float      | 5       |      2.759 ns |     0.0537 ns | 1.49x slower |
| System_Float       | Vector512  | Float      | 5       |      2.313 ns |     0.0381 ns | 1.25x slower |
| NetFabric_Float    | Vector512  | Float      | 5       |      1.896 ns |     0.0266 ns | 1.02x slower |
|                    |            |            |         |               |               |              |
| **Baseline_Float** | **Scalar** | **Float**  | **100** | **38.293 ns** | **0.2998 ns** | **baseline** |
| LINQ_Float         | Scalar     | Float      | 100     |     59.372 ns |     0.8637 ns | 1.55x slower |
| System_Float       | Scalar     | Float      | 100     |     38.491 ns |     0.5265 ns | 1.01x slower |
| NetFabric_Float    | Scalar     | Float      | 100     |     12.650 ns |     0.1233 ns | 3.03x faster |
| Baseline_Float     | Vector128  | Float      | 100     |     38.962 ns |     0.3469 ns | 1.02x slower |
| LINQ_Float         | Vector128  | Float      | 100     |     58.546 ns |     0.6409 ns | 1.53x slower |
| System_Float       | Vector128  | Float      | 100     |      6.212 ns |     0.1246 ns | 6.17x faster |
| NetFabric_Float    | Vector128  | Float      | 100     |      7.835 ns |     0.1275 ns | 4.89x faster |
| Baseline_Float     | Vector256  | Float      | 100     |     38.674 ns |     0.4669 ns | 1.01x slower |
| LINQ_Float         | Vector256  | Float      | 100     |     58.555 ns |     0.7268 ns | 1.53x slower |
| System_Float       | Vector256  | Float      | 100     |      4.528 ns |     0.0678 ns | 8.46x faster |
| NetFabric_Float    | Vector256  | Float      | 100     |      5.540 ns |     0.0867 ns | 6.91x faster |
| Baseline_Float     | Vector512  | Float      | 100     |     38.833 ns |     0.6120 ns | 1.01x slower |
| LINQ_Float         | Vector512  | Float      | 100     |     59.147 ns |     0.8935 ns | 1.54x slower |
| System_Float       | Vector512  | Float      | 100     |      5.140 ns |     0.0444 ns | 7.44x faster |
| NetFabric_Float    | Vector512  | Float      | 100     |      5.351 ns |     0.0591 ns | 7.16x faster |
|                    |            |            |         |               |               |              |
| **Baseline_Int**   | **Scalar** | **Int**    | **5**   |  **1.837 ns** | **0.0382 ns** | **baseline** |
| LINQ_Int           | Scalar     | Int        | 5       |      1.858 ns |     0.0413 ns | 1.01x slower |
| System_Int         | Scalar     | Int        | 5       |      1.617 ns |     0.0285 ns | 1.14x faster |
| NetFabric_Int      | Scalar     | Int        | 5       |      1.906 ns |     0.0245 ns | 1.04x slower |
| Baseline_Int       | Vector128  | Int        | 5       |      1.811 ns |     0.0337 ns | 1.01x faster |
| LINQ_Int           | Vector128  | Int        | 5       |      1.819 ns |     0.0339 ns | 1.01x faster |
| System_Int         | Vector128  | Int        | 5       |      3.489 ns |     0.0671 ns | 1.90x slower |
| NetFabric_Int      | Vector128  | Int        | 5       |      2.133 ns |     0.0365 ns | 1.16x slower |
| Baseline_Int       | Vector256  | Int        | 5       |      1.822 ns |     0.0278 ns | 1.01x faster |
| LINQ_Int           | Vector256  | Int        | 5       |      1.803 ns |     0.0343 ns | 1.02x faster |
| System_Int         | Vector256  | Int        | 5       |      2.323 ns |     0.0208 ns | 1.27x slower |
| NetFabric_Int      | Vector256  | Int        | 5       |      2.510 ns |     0.0252 ns | 1.37x slower |
| Baseline_Int       | Vector512  | Int        | 5       |      1.826 ns |     0.0226 ns | 1.01x faster |
| LINQ_Int           | Vector512  | Int        | 5       |      2.021 ns |     0.0268 ns | 1.10x slower |
| System_Int         | Vector512  | Int        | 5       |      2.111 ns |     0.0266 ns | 1.15x slower |
| NetFabric_Int      | Vector512  | Int        | 5       |      2.510 ns |     0.0232 ns | 1.37x slower |
|                    |            |            |         |               |               |              |
| **Baseline_Int**   | **Scalar** | **Int**    | **100** | **27.237 ns** | **0.2286 ns** | **baseline** |
| LINQ_Int           | Scalar     | Int        | 100     |     28.539 ns |     0.5145 ns | 1.05x slower |
| System_Int         | Scalar     | Int        | 100     |     28.771 ns |     0.4149 ns | 1.06x slower |
| NetFabric_Int      | Scalar     | Int        | 100     |     11.610 ns |     0.1033 ns | 2.35x faster |
| Baseline_Int       | Vector128  | Int        | 100     |     26.946 ns |     0.3698 ns | 1.01x faster |
| LINQ_Int           | Vector128  | Int        | 100     |      8.458 ns |     0.0746 ns | 3.22x faster |
| System_Int         | Vector128  | Int        | 100     |      5.594 ns |     0.0676 ns | 4.87x faster |
| NetFabric_Int      | Vector128  | Int        | 100     |      6.485 ns |     0.1132 ns | 4.20x faster |
| Baseline_Int       | Vector256  | Int        | 100     |     26.840 ns |     0.3518 ns | 1.01x faster |
| LINQ_Int           | Vector256  | Int        | 100     |      5.974 ns |     0.0593 ns | 4.56x faster |
| System_Int         | Vector256  | Int        | 100     |      4.477 ns |     0.0561 ns | 6.09x faster |
| NetFabric_Int      | Vector256  | Int        | 100     |      5.802 ns |     0.0658 ns | 4.69x faster |
| Baseline_Int       | Vector512  | Int        | 100     |     27.199 ns |     0.1354 ns | 1.00x faster |
| LINQ_Int           | Vector512  | Int        | 100     |      5.869 ns |     0.0614 ns | 4.64x faster |
| System_Int         | Vector512  | Int        | 100     |      4.434 ns |     0.0766 ns | 6.14x faster |
| NetFabric_Int      | Vector512  | Int        | 100     |      5.564 ns |     0.0544 ns | 4.90x faster |
|                    |            |            |         |               |               |              |
