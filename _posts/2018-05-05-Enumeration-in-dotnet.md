---
layout: post
read_time: true
show_date: true
title: "Enumeration in .NET"
date: 2018-05-05
img_path: /assets/img/posts/20180505
image: Paintball.jpeg
tags: [development, .net, csharp]
category: development
---

All .NET developers know and use [`IEnumerable`](https://docs.microsoft.com/en-us/dotnet/api/system.collections.generic.ienumerable-1) but when reviewing code I’ve found that many fall into the same pitfalls, resulting in applications with easily avoidable performance issues.

`IEnumerable` is very useful and hard to avoid. In this article I will explore some of its nuances so you can make a better use of its features.

> NOTE: This article contains links to [SharpLab](https://sharplab.io/) where you can test the code examples. Click on the links and change the code at will to get a better grasp of the concepts explained here.

## IEnumerable and IEnumerator

Enumeration in .NET is based on two very simple interfaces: `IEnumerable` and `IEnumerator`. There is a non-generic and a generic version for each but lets now focus only on their roles.

> `IEnumerable` is simply a factory of `IEnumerators` — Its only method `GetEnumerator()`, returns a new instance of an object that implements `IEnumerator`.

> `IEnumerator` performs the enumeration — The method `MoveNext()` advances the enumeration to the next position and the `Current` property returns the value for that position. The `Reset()` method is provided for COM interoperability and it may not be supported by the collection.

Given these interfaces, these are some important points to highlight:

- They don’t allow collection mutations. Only read operations.
- They don’t allow random access. Only sequential enumeration.
- They don’t give access to any other collection information. Only allow enumeration and that’s all.

In this article I will explore further the consequences of these.

> NOTE: Each `IEnumerator` from the same `IEnumerable` should be independent and be able to have different enumeration positions. If not, when enumerating more than once on the same `IEnumerable` will result in different value sequences. I’ve found some providers that don’t respect this rule. Beware of this as some of the rules I mention here may not work correctly in those cases.

## Enumerating

The simplest way to enumerate is to use a `foreach` loop. Lets start with a simple method that takes an `IEnumerable<int>` and outputs all its items to the console:

```csharp
public void Enumerate(IEnumerable<int> enumerable) 
{
    foreach (var item in enumerable)
    {
        Console.WriteLine(item);
    }
}
```

[You can check at SharpLab that, in reality, the above code is expanded to a while loop](https://sharplab.io/#v2:D4AQDABCCMDcCwAocVoBYHIMxQEwQGEIBvJCcqHENCAUQDsBXAWwFMAnAQwBdWAKGFgA8AS3rcAfBFZM2XAEYAbVgEoISAJClEFXRABmAe3atOAYwAWEPgDdO7CCN7NH9abI6clqsnvLa/PxgATj4nVmYVTECIAF9fcnjEWKA===). Focusing on the enumeration, we can resume it to this:

```csharp
public void Enumerate(IEnumerable<int> enumerable) 
{
    using(var enumerator = enumerable.GetEnumerator())
    {
        while(enumerator.MoveNext())
        {
            var item = enumerator.Current;
            Console.WriteLine(item);
        }
    }
}
```

Notice that, first a new instance of an `IEnumerator` is created. Next, it starts a `while` loop calling `MoveNext()`, stopping when `false` is returned. When it’s `true`, the `Current` property returns the new value.

The generic version of `IEnumerable` implements `IDisposable` so the `using` keyword is used to take care of that.

This is very simple but lets now focus on the nuances…

## Count() vs. Any()

It’s good practice to validate arguments and avoid unnecessary computation, so I’ve found the following very often:

```csharp
public static double? Average(this IEnumerable<int> enumerable) 
{
    if(enumerable.Count() == 0)
        return null;

    var sum = 0;
    foreach (var value in enumerable)
        sum += value;

    return sum / (double)enumerable.Count();
}
```

It uses the `Count()` extension method to check if the enumerable is empty and exits early. Unfortunately this does way more computation than most expect…

From the highlighted points on the enumeration interfaces, we already know that these can only enumerate sequentially and ha

```csharp
public static int MyCount<T>(this IEnumerable<T> enumerable) 
{
    var count = 0;
    using(var enumerator = enumerable.GetEnumerator())
    {
        while (enumerator.MoveNext())
            count++;
    }
    return count;
}
```

Notice that it has to enumerate all the items, counting the number of times `MoveNext()` returns `true`. As a consequence, `Count()` has a complexity of O(n).

This means the previous code example is enumerating the collection three times. First to check if it’s empty, second to calculate the sum and third to get the number of items.

> NOTE: LINQ uses an optimization where, if the collection implements `ICollection`, it simply calls the `Count` property. The issue is that many enumerables don’t implement it. To avoid any surprise, I always assume they don’t.

There is a better solution. `Any()` is an extension method that returns true if the enumerable contains at least one element; otherwise false. `Any()` implementation looks something like this:

```csharp
public static bool MyAny<T>(this IEnumerable<T> enumerable) 
{
  using (var enumerator = enumerable.GetEnumerator())
  {
      return enumerator.MoveNext();
  }
}
```

Notice that it creates an instance of `IEnumerator` and then calls `MoveNext()` only once. There is no loop! `Any()` has a complexity of O(1).

You should always use `Any()` to check if an enumerable is empty:

```csharp
public void DoSomething<T>(IEnumerable<T> enumerable) 
{
    if (!enumerable.Any())
        return;

    // do something here
}
```

Usually, you don’t even need to check if it’s empty. The `foreach` doesn’t enter the loop in that case. Here’s an implementation of `Average()` that creates one single instance of `IEnumerator` and enumerates the collection only once:

```csharp
public static double? Average(this IEnumerable<int> enumerable) 
{
    var sum = 0;
    var count = 0;
    foreach (var value in enumerable)
    {
        sum += value;
        count++;
    }
    
    if(count == 0)
        return null;

    return sum / (double)count;
}
```

> If required, always use `Any()` to find if an `IEnumerable` contains any element.

## Count() vs. Count

Sometimes finding if an enumerable is empty is not enough. You may need to get the actual number of items.

`Count()` is an extension method for the `IEnumerable` interface while `Count` is a property of the `IReadOnlyCollection` interface. When using them, the only noticeably difference is the existence or absence of the parentheses, but their behavior is very different.

`IReadOnlyCollection` is implemented by most collection in the .NET framework. These keep the count value as a private field or can easily calculate it from other private fields allowing `Count` to have a complexity of O(1).

`IReadOnlyCollection` derives from `IEnumerable` and just adds the `Count` readonly property. `IReadOnlyList` and `IReadOnlyDictionary` both derive from `IReadOnlyCollection` and add random access.

If you return one of these, instead of the usual `IEnumerable`, the callers will be able to both enumerate and efficiently perform other supported operations, while maintaining immutability. You can return other collection interfaces or types if required.

```csharp
public static IReadOnlyList<int> MyRange(int start, int count)
{
    if (count < 0)
        throw new ArgumentOutOfRangeException(nameof(count));

    var range = new List<int>(); // List<int> implements IReadOnlyList<int>
    var end = start + count;
    for (int value = start; value < end; value++)
    {
        range.Add(value);
    }
    return range;
}
```

You can add one more `Average()` extension method for `IReadOnlyCollection` that takes advantage of availability of the `Count` property and guaranteeing that the method will not mutate the collection. It improves performance by not creating the instance of `IEnumerator` and not calling `MoveNext()` when the collection is empty:

```csharp
public static double? Average(this IReadOnlyCollection<int> enumerable) 
{
    if (enumerable.Count == 0)
        return null;
    
    var sum = 0;
    foreach (var value in enumerable)
        sum += value;
    
    return sum / (double)enumerable.Count;
}
```

> NOTE: Although `ICollection` should derive from `IReadOnlyCollection`, for historical reasons and to maintain backwards compatibility, it doesn’t. So, you cannot pass an `ICollection` to this method. To fully support all scenarios, you should have one more extension method for `ICollection`. On the other hand, this causes ambiguity problems for collections that implement both interfaces, forcing you to cast to one of them.

> Always expose the highest admissible level interface of the returned collection, and consume the lowest admissible level interface. `IEnumerable`, `IReadOnlyCollection`, `IReadOnlyList` and `IReadOnlyDictionary` maintain immutability.

## Yield

The implementation of `MyRange()`, found above, fills a list with all the range values and then returns it. This is inefficient and it’s an issue as it can fill up memory. The solution is to use the `yield` keyword.

```csharp
public static IEnumerable<int> MyRange(int start, int count)
{
    if (count < 0)
        throw new ArgumentOutOfRangeException(nameof(count));

    var end = start + count;
    for (int value = start; value < end; value++)
    {
        yield return value;
    }
}
```

In this case, the compiler automatically generates an implementation of `IEnumerable` that enumerates the values without allocating a collection in memory. [You can check at SharpLab the code generated that supports this behavior](https://sharplab.io/#v2:D4AQDABCCMDcCwAocVoBYGKSAzKgbFAEyoDsEA3khDVHjITDgDwCWAdgC4B8EAsgE8ASgEN2AcwCmACg6cIAZ04iATpwA0EORADGAewCuXAJTVaVRLStaAZhGn6j85hDCnL1z5wAWKvQHcIdklAgEEVcQMAW0kuAHkDTjibUQlJAFEADx1JAAdOVj12aXYRGL0bB0MTY0wzTwA3VQhYgBMIAF5FZTUIAGpdas5MTxobPRV7bSaAGwNJTu7VYYhZ+YgXNthVkTnJPr73Ucp649RoKHI1yRHRgF9Th8Q7oA===).

In the code example above, the method validates the argument count and throws an exception if it’s less than zero. You would expect it to be thrown immediately after the method is called. It doesn’t. It’s only thrown after the first call to `MoveNext()`. [Go to SharpLab and play with the count value to visualize this behavior](https://sharplab.io/#v2:C4LgTgrgdgPgAgBgARwIwG4CwAoRLUAsW2OcAzCgEz4DsSA3jksyhWgGwoH4AcAFAEomLRthbikAYwD2UAM7AkASyiKFAQzCKAvEgCsxCSxnzFKxTOg6kAWgzCjDiWgCcfAEQBhMAFN1wFQBzJB8oCABbHzB1ACMAGx93AWIncQA3TRCwyOj4nyRdAFkATwAldShAnz4NLQAaKWkrZKRUljbmVw9vPwDKrIio/2kwJJSxIxQEPgywAZzhud1QwdyEgDoAcR9gAFFsoeARwSEJo1FJpABILvcAZWBNPuCVhYDZMZwOiQB3AAslAk+K9DiN1oVpGkfAA5HwAD2AJ2+4huqDcIOiRzA608EDAvlUyWR7TOElRbncADEVEo5H8fAATeaHJQfImk8QAXyc3NJTnI+E4aDIAB5zAA+JAlcqVarmJC1YANeWWQlOC6TW4AKiQ+2AUUZSEiwD+0gZnw5JMuSgAZkg+KrFCKkAhTpdxCawNIfkgoD4fQBBMCBQaqADyEGAYZtMqquzhkh8AAd3lA+FB1JFpDaHU1CezvtqkA8nkEkHFpNIkxbLt9ZlkmbpFUgANSNKyGSY2kb2+UZOIQfJNx5adBIfuDpDO0IMscTnwtltuyYa934VAoOjzztGXmFtEeHX7BmGitVmssXmcoA).

To have the intended behavior, we need to split the method into two parts:

- immediate for validation,
- lazy for enumeration.

This can be done using a local function:

```csharp
public static IEnumerable<int> MyRange(int start, int count)
{
    if (count < 0)
        throw new ArgumentOutOfRangeException(nameof(count));

    return RangeEnumeration(start, start + count);

    // static local function to avoid closures
    static IEnumerable<int> RangeEnumeration(int start, int end)
    {
        for (var value = start; value < end; value++)
        {
            yield return value;
        }
    }
}
```

[Check at SharpLab to see that now the exception is thrown immediately](https://sharplab.io/#v2:C4LgTgrgdgPgAgJgIwFgBQcAMACOSAsA3OunAMy4K5IDs2A3uts5Qky42i99gMYD2UAM7BsASyiiRAQzCiAvNgCsxLj2YDhoiaIHQF2ALRJV65u3V4AnAAoARAGEwAU2nAJAc2zOoEALbOYNIARgA2znYAlKoWPABust6+AUFhztiKALIAngBK0lAezjYycgA0fPz60bHctSzW9k6u7oVJ/oFu/GBRMWqWmDYJYO0pXSOKPh2p4QB0AOLOwACiyZ3A3TaRkfXMnGbYAJCNdgDKwLKtXlNj7oK9JP0H2ADuABZi4TY3692zmfw4s4AHLOAAewC2OyeB2OSFsPyCGzAswcEDALkkNRhZl2RxOADEJGIhG9nAATUbrMT3bEHAC+sUZaFisXI1AAbNQyAAeHQAPmwOXyhWKOmwpWAFXFeixsX2ZhOACpsKtgIEKdgAsA3vxyQ8ceZDeIAGbYGyy0Q87CYaHPFg6sD8F7YKDOF0AQTAHg6kgA8hBgH6TSKisswbxnAAHO5QGxQaQBfgmi1VLHYvFwOih5yraZuGlxyUVSXYADUlWqfQOeC5eF5AuwObzt0LNnFxfEkiS5LtZk4hxr8PsKvOl082FC/H4UYNBzx3BN3XNw2wCVCEHSiklhDX0g36WtPnJu/Xm7LZb79oV9u4eCQuDoZ+cplvzLxcNsdhVq3JmqnM5zmYzLcMy9JAA=).

Lazy evaluation is the ability to “[only execute code when needed and only as many times as required regardless of where in the execution pipeline the code sits](https://blogs.msdn.microsoft.com/pedram/2007/06/02/lazy-evaluation-in-c/)”. You should take advantage of this to minimize resource usage when generating enumerables.

> Use yield when generating enumerables.

## Composition

I’ve found way too often the use of `ToList()` or `ToArray()` when developers want to reuse the result of a LINQ expression:

```csharp
var numbers = Enumerable.Range(start, count)
    .ToList();

var evenNumbers = numbers
    .Where(number => (number & 0x01) == 0)
    .ToList();

var oddNumbers = numbers
    .Where(number => (number & 0x01) != 0)
    .ToList();

Console.WriteLine("Even Numbers:");
foreach(var number in evenNumbers)
    Console.WriteLine(number);

Console.WriteLine("Odd Numbers:");
foreach(var number in oddNumbers)
    Console.WriteLine(number);
```

This results in unnecessary memory allocation and copying of all the enumeration values into it. This results in a big performance penalty. You should only use these methods when it’s strictly necessary to cache the values and it’s guaranteed that they always fit in memory.

LINQ expressions can be reused, maintaining the lazy evaluation behavior:

```csharp
var numbers = Enumerable.Range(start, count);
        
var evenNumbers = numbers
    .Where(number => (number & 0x01) == 0);

var oddNumbers = numbers
    .Where(number => (number & 0x01) != 0);

Console.WriteLine("Even Numbers:");
foreach(var number in evenNumbers)
    Console.WriteLine(number);

Console.WriteLine("Odd Numbers:");
foreach(var number in oddNumbers)
    Console.WriteLine(number);
```

[You can see it working at SharpLab](https://sharplab.io/#v2:C4LgTgrgdgPgAgBgARwIwG4CwAoRLUAsWuyaAdADICWUAjsTnAMz4BsKATPgOxI4DeOJMJQs07OAXwAOABQBKPthFJBylSIDGAeygBnYEhqGDAQzCGAvEgTENW3QaNRDO6FaSpbQkT/sA3cyQoCABbACMAUzA9JGsAURDQ6NNwgBtIsgAlUygAc0jZMwsAGiQ3F3k7eyUapECwJEj/SKgAOTComLjgzui9PzqkMgB1AAtowqSuuIA+JFlp6KQAMhsADwRURUtrBCrBlUORBqRtABNzjoj+nqWY4/tRibApvsbLecX31Y2txQAhHsDup7I98ABOWQAIniLSgSGuXT0IGhILqADNtK9TJoxrJTvdnE14Uj+vJwSo0FD7uiauDqTCAPKXRHvFFo6r2LE4vEEoJEmhnS5kmIU0FDRm0rlIAC+gxwsqAA).

> Use composition to reuse expressions, maintaining lazy evaluation.

## null vs. Enumerable.Empty&lt;T&gt;()

I’ve seen many instances where developers return `null` when they really mean that it’s empty. It’s important to understand that these have two very different meanings:

- `null` — an invalid state where the `IEnumerable` instance hasn’t been created,
- empty — a valid state where the enumeration contains no values.

Returning `null` breaks the use of the `foreach` and method composition. [You can see at SharpLab how badly it behaves](https://sharplab.io/#v2:C4LgTgrgdgPgAgBgARwIwG4CwAoRLUAsWuyaAdADICWUAjsTnAMz4BsKATPgOxI4DeOJMJQs07OAXwAOABQBKPthFJBylSIBuAQzBIdAGwgBTAM5IAvEgCyATwCiUCAFtjYbQCMDxhUI3+yAHUACzcfQxNLAD59bSNjJBiEeWJ/YT9/ADMAezBjbQBjYNkdPQiEmlj403kMtOE0AE4SuJMUuoBfOrrmNnwmAB4aYBi7Rxc3T29fdWE1erheJwMDVJEu7A6gA).

You must return an empty enumeration. The `System.Linq` namespace contains a `Enumerable.Empty<T>()` static method that returns exactly that; an `IEnumerable` implementation that generates `IEnumerator` implementations where the method `MoveNext()` always returns `false`.

Here is an example of how to use it:

```csharp
public static IEnumerable<int> MyEnumerable(int count)
{
    if(count <= 0)
        return Enumerable.Empty<int>();

    return Enumerable.Range(0, count);
}
```

[You can see it working at SharpLab](https://sharplab.io/#v2:C4LgTgrgdgPgAgBgARwIwG4CwAoRLUAsWuyaAdADICWUAjsTnAMz4BsKATPgOxI4DeOJMJQs07OAXwAOABQBKPthFJBylSIBmAezABTAIYBjABayAbgbBJLAGwh6kNJAFkAngFEoEALZ6wBgBGtnqyALSo8vJCGrFoAJwWBvZ68sQqAL4xwtmibPhMADw0wAB8rp7efgHBoSVIRtrQwNHqwmqxwlSaso3NSIUAvEgIrZ0acLxevv5BIWQePgAOwG7FUGUKDG0TU1WztWQASgZQAOahCAA0DU0bablZ2BlAA=).

When using `yield`, you can exit the enumeration using `yield break` and, if no value was returned until then, it results in an empty enumeration:

```csharp
public static IEnumerable<int> MyEnumerable(int count)
{
    if (count <= 0)
        yield break;

    for (var value = 0; value < count; value++)
        yield return value;
}
```

[You can see it working at SharpLab](https://sharplab.io/#v2:C4LgTgrgdgPgAgBgARwIwG4CwAoRLUAsW2OcAzPgGwoBM+A7EjgN45LsoVrVwH4AcACgCUTbByStxEjgDMA9mACmAQwDGAC0EA3FWCS6ANhCVIAllCQBZAJ4BRKBAC2SsCoBGhpYIC0qYcJsMsFoAJw6KsZKwsQSAL5B7ImcVPhkADwWwAB81vaOLm6e3llIavLQwIHS7FLB7GaySILllUjpALxICNX1MmioSO7KKgDWxMkSCvoR+kYmSF0I6AaRC+llFVDAK/NKANT7vX0cAyiMe7EcCdhxQA==).

> Never return a `null` enumerable. Use `Enumerable.Empty<T>()` or `yield break` instead.

## IQueryable

The `System.Linq` namespace, also known as “LINQ to Objects”, contains many extension methods for `IEnumerable`. Not having random access enumeration support, means that full scans are required to find elements and that memory allocations with value copies are required in operations like ordering or grouping.

Databases have engines optimized for these operations and support much larger amounts of data. `IQueryable` is an enumeration interface that converts the LINQ expression tree into something equivalent that a database can process. The execution of the query is delegated to the database. `IQueryable` derives from `IEnumerable` so the result can be enumerated just like we’ve been doing until now.

The .NET drivers for databases usually support `IQueryable` and I’m going to show a couple of examples, but there are other providers like LinqToExcel, LinqToTwitter, LinqToCsv, LINQ-to-BigQuery, LINQ-to-GameObject-for-Unity, ElasticLINQ, GpuLinq and many more.

### Entity Framework Core

The Entity Framework (EF) is an object-relational mapping (ORM) that includes “LINQ-to-SQL”, meaning it supports LINQ queries on a SQL database engine.

The following is an example based on the database model defined in the “Entity Framework Core Quick Overview” article. It applies a LINQ query on the Blogs property, that is of type `DbSet<Blog>`.

```csharp
using (var db = new BloggingContext())
{
    var blogs = db.Blogs
        .Where(blog => blog.Rating > 3)
        .OrderByDescending(blog => blog.Rating)
        .Take(5)
        .Select(blog => blog.Url);

    Console.WriteLine(blogs.ToSql());
    Console.WriteLine();

    foreach (var blog in blogs)
    {
        Console.WriteLine(blog);
    }
}
```

`DbSet<T>` implements the `IQueryable` interface which, in this case, converts the LINQ expression tree to SQL. The `ToSql()` method, used on line 9, returns the generated string that will be sent to the database. The example above outputs the following:

```sql
SELECT TOP(5) [blog].[Url]
FROM [Blogs] AS [blog]
WHERE [blog].[Rating] > 3
ORDER BY [blog].[Rating] DESC
```

Notice that it’s equivalent to the LINQ query defined in the code. This means it will be fully performed by the database engine. The `foreach` just has to enumerate the result returned. No filtering, projection, ordering or element counting is performed directly by LINQ operators.

> NOTE: You can get the `ToSql()` extension method from a gist by Rion Williams ([updated versions are down the comments](https://gist.github.com/rionmonster/2c59f449e67edf8cd6164e9fe66c545a)).

Now imagine that you want to apply LINQ operators to the query result. Don’t use `ToList()` or `ToArray()`. Use `AsEnumerable()` instead. It will keep the lazy evaluation, without memory usage.

The following example performs a projection on the results, formatting the string that will be written to the console:

```csharp
using (var db = new BloggingContext())
{
    var blogs = db.Blogs
        .Where(blog => blog.Rating > 3)
        .OrderByDescending(blog => blog.Rating)
        .Take(5)
        .Select(blog => blog.Url);

    Console.WriteLine(blogs.ToSql());
    Console.WriteLine();

    var urls = blogs
        .AsEnumerable()
        .Select(url => $"URL: {url}");

    foreach (var url in urls)
    {
        Console.WriteLine(url);
    }
}
```

This is particularly useful with NOSQL databases as they usually support a limited set of operations defined in LINQ. You should still design the data model to execute the query as much as possible by the database engine.

### DataStax C# Driver for Apache Cassandra

This driver supports `IQueryable` through the `CqlQuery<T>` class. In this case, it converts the LINQ expression tree to CQL, the query language used by Cassandra.

The following code is based on a data model similar to the one from the previous example and applies a query on the `blogs_by_rating` table. The mapping is defined by the attributes on the `BlogByRating` class located at the bottom.

```csharp
class Program
{
    static async Task Main(string[] args)
    {
        var clusterBuilder = Cluster.Builder()
            .AddContactPoint("localhost")
            .WithPort(9042);

        using (var cluster = clusterBuilder.Build())
        using (var session = cluster.Connect("blogging"))
        {
            var blogsTable = new Table<BlogByRating>(session);

            var blogs = blogsTable
                .Where(blog => blog.Rating == 3)
                .Select(blog => blog.Url);

            Console.WriteLine(blogs);
            Console.WriteLine();

            foreach (var blog in await blogs.ExecuteAsync())
            {
                Console.WriteLine(blog);
            }
        }

        Console.ReadLine();
    }

    [Table("blogs_by_rating")]
    class BlogByRating
    {
        [PartitionKey]
        [Column("id")]
        public int Id { get; private set; }

        [Column("url")]
        public string Url { get; private set; }

        [Column("rating")]
        public int Rating { get; private set; }
    }
}
```

The method `CqlQuery<T>.ToString()` returns the CQL query that is sent to the database. The line 18 of the code above, outputs the following:

```sql
SELECT "url" FROM "blogs_by_rating" WHERE "rating" = ?
```

The question mark indicates it uses a prepared statement. It means it will be reused and the values bound when called.

The methods `CqlQueryBase.Execute()` and `CqlQueryBase.ExecuteAsync()` return `IEnumerable` so you can use LINQ operators directly without the need of `AsEnumerable()`.

> NOTE: This driver is one of those cases mentioned above where enumerating more than once result in different value sequences. This is due to how `GetEnumerator()` is implemented where resulting `IEnumerator` instances share state. In this case, you may have to use `ToList()` to keep the sequence in memory or call `Execute()` before each enumeration to get a new `IEnumerable` instance.

> Execute as much as possible of the query within the `IQueryable`. If required, use `AsEnumerable()` to maintain lazy evaluation.

## Conclusion

As a summary, these are the conclusions for each of the points focused above:

- If required, always use `Any()` to find if an `IEnumerable` contains any element.

- Always expose the highest admissible level interface of the returned collection, and consume the lowest admissible level interface. `IEnumerable`, `IReadOnlyCollection`, `IReadOnlyList` and `IReadOnlyDictionary` maintain immutability.

- Use `yield` when generating enumerables.

- Use composition to reuse expressions, maintaining lazy evaluation.

- Never return a `null` enumerable. Use `Enumerable.Empty<T>()` or `yield break` instead.

- Execute as much as possible of the query within the `IQueryable`. If required, use `AsEnumerable()` to maintain lazy evaluation.

I hope you liked this article and find it useful. Share it with your team.

> NOTE: This article focused on the client side of the enumeration. If you want to implement `IEnumerable`, you can find some tips in my other article “[How to use Span<T> and Memory<T>](https://aalmada.github.io/posts/How-to-use-Span-and-Memory/)”. If you want to implement `IQueryable`, check the open-source project [Relinq](https://github.com/re-motion/Relinq).











