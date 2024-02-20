---
layout: post
read_time: true
show_date: true
title: "Unit testing a Roslyn Analyzer"
date: 2020-05-03
img_path: /assets/img/posts/20200503
image: PracaComercio.jpg
tags: [development, .net, csharp, roslyn, analyzer, unit testing]
category: development
---

I’ve been writing here many stories about enumeration in .NET. I know it’s hard to remember everything, specially when developing large projects with several other developers. I decided to develop [NetFabric.Hyperlinq.Analyzer](https://github.com/NetFabric/NetFabric.Hyperlinq.Analyzer) that peer reviews the code while it’s typed. I actually use it myself to develop [NetFabric.Hyperlinq](https://github.com/NetFabric/NetFabric.Hyperlinq).

The easiest way to start developing an analyzer is to use [the template available with Visual Studio](https://docs.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/tutorials/how-to-write-csharp-analyzer-code-fix). One of its great features is that it also generates the unit testing project.

```csharp
        [TestMethod]
        public void TestMethod2()
        {
            var test = @"
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using System.Diagnostics;
    namespace ConsoleApplication1
    {
        class TypeName
        {   
        }
    }";
            var expected = new DiagnosticResult
            {
                Id = "Analyzer1",
                Message = String.Format("Type name '{0}' contains lowercase letters", "TypeName"),
                Severity = DiagnosticSeverity.Warning,
                Locations =
                    new[] {
                            new DiagnosticResultLocation("Test0.cs", 11, 15)
                        }
            };

            VerifyCSharpDiagnostic(test, expected);

            var fixtest = @"
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using System.Diagnostics;
    namespace ConsoleApplication1
    {
        class TYPENAME
        {   
        }
    }";
            VerifyCSharpFix(test, fixtest);
        }
```

Notice that it applies the analyzer and the code fixer to source code strings. I find this approach to have several disadvantages:

- It doesn’t allow syntax color coding and [IntelliSense](https://code.visualstudio.com/docs/editor/intellisense). These make it so much easier to visualize and write the code.
- No compiler errors are generated. The code doesn’t have to compile correctly for the analyzer to run but, it’s good to have the compiler’s help.
- It’s not possible to use the [Syntax Visualizer](https://docs.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/syntax-visualizer) on the strings. This tool is essential in development of diagnostic analyzers.

An workaround is to have another project and copy/paste the source between files. I find this to be too cumbersome.

# Adding the test sources to the unit tests project

I came up with this idea while developing another project that I spun-off from the analyzer. The [NetFabric.CodeAnalysis](https://github.com/NetFabric/NetFabric.CodeAnalysis) repository is used to generate two NuGet packages:

- [NetFabric.CodeAnalysis](https://www.nuget.org/packages/NetFabric.CodeAnalysis/) — contains the logic used by the analyzer to check if a type is an enumerable. It covers more scenarios than just checking if it implements IEnumerable or IAsyncEnumerable.
- [NetFabric.Reflection](https://www.nuget.org/packages/NetFabric.Reflection/) — contains the exact same logic but for [reflection](https://docs.microsoft.com/en-us/dotnet/framework/reflection-and-codedom/reflection). It’s used by my fluent assertions library [NetFabric.Assertive](https://github.com/NetFabric/NetFabric.Assertive).

These packages are used on different contexts (*compile time* vs. *run time*) but have the exact same functionality so I wanted to use the same testing data. This means a lot less code to maintain…

For the case of the analyzer, I added a folder TestData to my unit testing project. Inside of it, I added a folder tree for each diagnostic analyzer with source files split into tests with or without diagnostics reported:

![Folder structure](SolutionExplorer.png)

Once the files are added, they become part of the project and are compiled just like any other source file. One thing you’ll have to worry about now is naming conflicts. To avoid this, I use namespaces with the base name equal to the diagnostic identifier, which should be unique by definition.

# Using the source files for unit testing

The classes `DiagnosticVerifier` and `CodeFixVerifier` used to validate the diagnostics are prepared to receive source strings. We now need to change the testing code to use the files.

I like to use [xUnit](https://xunit.net/) but you can use any other unit testing framework:

```csharp
public class AssignmentBoxingTests : DiagnosticVerifier
{
    protected override DiagnosticAnalyzer GetCSharpDiagnosticAnalyzer() =>
        new AssignmentBoxingAnalyzer();

    [Theory]
    [InlineData("TestData/HLQ001/NoDiagnostic/FieldDeclaration.cs")]
    [InlineData("TestData/HLQ001/NoDiagnostic/FieldDeclaration.Async.cs")]
    [InlineData("TestData/HLQ001/NoDiagnostic/PropertyDeclaration.cs")]
    [InlineData("TestData/HLQ001/NoDiagnostic/PropertyDeclaration.Async.cs")]
    [InlineData("TestData/HLQ001/NoDiagnostic/VariableDeclaration.cs")]
    [InlineData("TestData/HLQ001/NoDiagnostic/VariableDeclaration.Async.cs")]
    public void Verify_NoDiagnostics(string path)
    {
        VerifyCSharpDiagnostic(File.ReadAllText(path));
    }

    [Theory]
    [InlineData("TestData/HLQ001/Diagnostic/EqualsValueClause/FieldDeclaration.cs", "OptimizedEnumerable`1", "IEnumerable`1", 8, 9)]
    [InlineData("TestData/HLQ001/Diagnostic/EqualsValueClause/FieldDeclaration.Async.cs", "OptimizedAsyncEnumerable`1", "IAsyncEnumerable`1", 8, 9)]
    [InlineData("TestData/HLQ001/Diagnostic/EqualsValueClause/PropertyDeclaration.cs", "OptimizedEnumerable`1", "IEnumerable`1", 8, 9)]
    [InlineData("TestData/HLQ001/Diagnostic/EqualsValueClause/PropertyDeclaration.Async.cs", "OptimizedAsyncEnumerable`1", "IAsyncEnumerable`1", 8, 9)]
    [InlineData("TestData/HLQ001/Diagnostic/EqualsValueClause/VariableDeclaration.cs", "OptimizedEnumerable`1", "IEnumerable`1", 10, 13)]
    [InlineData("TestData/HLQ001/Diagnostic/EqualsValueClause/VariableDeclaration.Async.cs", "OptimizedAsyncEnumerable`1", "IAsyncEnumerable`1", 11, 13)]
    [InlineData("TestData/HLQ001/Diagnostic/SimpleAssignment/FieldDeclaration.cs", "OptimizedEnumerable`1", "IEnumerable`1", 12, 13)]
    [InlineData("TestData/HLQ001/Diagnostic/SimpleAssignment/FieldDeclaration.Async.cs", "OptimizedAsyncEnumerable`1", "IAsyncEnumerable`1", 12, 13)]
    [InlineData("TestData/HLQ001/Diagnostic/SimpleAssignment/PropertyDeclaration.cs", "OptimizedEnumerable`1", "IEnumerable`1", 12, 13)]
    [InlineData("TestData/HLQ001/Diagnostic/SimpleAssignment/PropertyDeclaration.Async.cs", "OptimizedAsyncEnumerable`1", "IAsyncEnumerable`1", 12, 13)]
    [InlineData("TestData/HLQ001/Diagnostic/SimpleAssignment/VariableDeclaration.cs", "OptimizedEnumerable`1", "IEnumerable`1", 12, 13)]
    [InlineData("TestData/HLQ001/Diagnostic/SimpleAssignment/VariableDeclaration.Async.cs", "OptimizedAsyncEnumerable`1", "IAsyncEnumerable`1", 13, 13)]
    public void Verify_Diagnostics(string path, string type, string @interface, int line, int column)
    {
        var expected = new DiagnosticResult
        {
            Id = "HLQ001",
            Message = $"'{type}' has a value type enumerator. Assigning it to '{@interface}' causes boxing of the enumerator.",
            Severity = DiagnosticSeverity.Warning,
            Locations = new[] {
                new DiagnosticResultLocation("Test0.cs", line, column)
            },
        };

        VerifyCSharpDiagnostic(File.ReadAllText(path), expected);
    }
}
```

Notice that each test method is used to test multiple scenarios. I only set two methods per diagnostic, one for no diagnostics reported and another for a single reported diagnostic. The path to the file and any other required information is passed as a parameter.

Notice also the use of `File.ReadAllText(path)` so that the file is loaded and its content used for the validation.

Having simple tests that report only one diagnostic makes it easier to debug. There won’t be multiple threads running at the same time.

# Relative paths

It’s important that the build and tests can be executed anywhere the repository is cloned into. Including any continuous-integration agent.

I added the following to the unit tests `.csproj` file:

```xml
<ItemGroup>
  <Compile Update="TestData\**\*.cs">
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </Compile>
</ItemGroup>
```

This copies all the `.cs` files under the `TestData` folder, maintaining the folder structure and still compiling during build. This allows the use of relative paths for the test source code files.

# Excluding files

I found two reasons to have source files excluded from the build:

- The source doesn’t have to compile correctly for the analyzer to be run. It’s important that unit tests include these scenarios.
- The fixed source files used to test the code fixers may not have enough changes to avoid naming collisions.

In Visual Studio, you can exclude each of these files by right-clicking of them in the *Solution Explorer* and then clicking on *Exclude From Project+.

Alternatively, you can use a naming pattern and set a rule. I add a `.Fix` to the end of the name of the files used to test the code fixer and I add the following to the `.csproj` file:

```xml
  <ItemGroup>
    <Compile Remove="TestData\**\*.Fix.cs" />
  </ItemGroup>

  <ItemGroup>
    <Content Include="TestData\**\*.Fix.cs">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </Content>
  </ItemGroup>
``` 

This guarantees that the `.Fix.cs` files are not compiled but still copied on build.

Please note that after this, when a new file is added, Visual Studio will override these settings for this new file. You’ll have to delete what’s added to the `.csproj` file.

# Sharing code

The test verifiers create an internal project where the source strings are added as documents:

- The `VerifyCSharpDiagnostic` method has an overload that accepts an array of strings. These are all added to the internal project and the analyzer run on all of them.
- The `VerifyCSharpFix` method only accepts one string. The analyzer and the code fixer are run on it and the result compared to the other string parameter.

I wanted to be able to share auxiliary code between tests. For example, share the enumerable definitions I use in most of the testing scenarios. Neither the verifiers allow this scenario so, I tweaked a bit their implementation to fit my requirements. You can copy them from my repository.

I now can pass an array of strings to either verifiers but the analyzer is only run on the first one:

```csharp
public class RefEnumerationVariableAnalyzerTests : CodeFixVerifier
{
    protected override DiagnosticAnalyzer GetCSharpDiagnosticAnalyzer() 
        => new RefEnumerationVariableAnalyzer();

    protected override CodeFixProvider GetCSharpCodeFixProvider()
        => new RefEnumerationVariableCodeFixProvider();

    [Theory]
    [InlineData("TestData/HLQ004/NoDiagnostic/NoRef.cs")]
    [InlineData("TestData/HLQ004/NoDiagnostic/Ref.cs")]
    [InlineData("TestData/HLQ004/NoDiagnostic/RefReadOnly.cs")]
    public void Verify_NoDiagnostics(string path)
    {
        var paths = new[]
        {
            path,
            "TestData/TestType.cs",
            "TestData/Enumerable.cs",
            "TestData/HLQ004/RefEnumerables.cs",
        };
        var sources = paths.Select(path => File.ReadAllText(path)).ToArray();

        VerifyCSharpDiagnostic(sources);
    }

    [Theory]
    [InlineData("TestData/HLQ004/Diagnostic/Ref.cs", "ref", "TestData/HLQ004/Diagnostic/Ref.Fix.cs", 7, 22)]
    [InlineData("TestData/HLQ004/Diagnostic/RefReadOnly.cs", "ref readonly", "TestData/HLQ004/Diagnostic/RefReadOnly.Fix.cs", 9, 22)]
    public void Verify_Diagnostics(string path, string message, string fix, int line, int column)
    {
        var paths = new[]
        {
            path,
            "TestData/TestType.cs",
            "TestData/Enumerable.cs",
            "TestData/HLQ004/RefEnumerables.cs",
        };
        var sources = paths.Select(path => File.ReadAllText(path)).ToArray();
        var expected = new DiagnosticResult
        {
            Id = "HLQ004",
            Message = $"The enumerator returns a reference to the item. Add '{message}' to the item type.",
            Severity = DiagnosticSeverity.Warning,
            Locations = new[] {
                new DiagnosticResultLocation("Test0.cs", line, column)
            },
        };

        VerifyCSharpDiagnostic(sources, expected);

        VerifyCSharpFix(sources, File.ReadAllText(fix));
    }
}
```

# Conclusion

It’s possible to take advantage of the IDE tools to develop the source code used to test an analyzer.

You can always access the source code in [my analyzer repository](https://github.com/NetFabric/NetFabric.Hyperlinq.Analyzer) to check on any detail that I missed.

I hope you found this information useful.



