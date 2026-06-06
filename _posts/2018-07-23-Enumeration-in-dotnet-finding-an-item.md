---
layout: post
read_time: true
show_date: true
title: "Enumeration in .NET - Finding an item"
date: 2018-07-23
img_path: /assets/img/posts/20180723
image: Eagle.jpeg
tags: [development, .net, csharp]
category: development
redirect_from: /Enumeration-in-dotnet-finding-an-item.html
meta_description: "Learn how to efficiently find items in .NET collections using First(), Single(), and related LINQ methods. This article covers performance considerations, pitfalls, and best practices for searching enumerables."
---

## Finding an item

I already mentioned in the first article of this series that `IEnumerable`:

- doesn’t allow random access.
- doesn’t give access to any other collection information.

This implies high costs when trying to find an item. This article focus on the methods `First()` and `Single()`, commonly used to search for an item, and how its real cost can be hidden.

## First() and Single()

`First()` and `Single()` are extension methods for `IEnumerable<T>` that return the first element of a sequence. The sequence is usually filtered using an `Where()` operation and we are interested only in the first item.

Both methods throw an exception when the sequence is empty. `Single()` also throws an exception if the sequence contains more than one element. Their implementation is very simple:

```csharp
public static T First<T>(this IEnumerable<T> enumerable)
{
    using(var enumerator = enumerable.GetEnumerator())
    {
        if(!enumerator.MoveNext())
          throw new InvalidOperationException("Sequence contains no elements");

        return enumerator.Current;
    }
}

public static T Single<T>(this IEnumerable<T> enumerable)
{
    using(var enumerator = enumerable.GetEnumerator())
    {
        if(!enumerator.MoveNext())
          throw new InvalidOperationException("Sequence contains no elements");

        var first = enumerator.Current;

        if(enumerator.MoveNext())
          throw new InvalidOperationException("Sequence contains more than one element");

        return first;
    }
}
```

> NOTE: The LINQ implementation contains optimizations for certain scenarios but I’m not going to consider them. As I explained in a [previous article](https://aalmada.github.io/posts/Enumeration-in-dotnet-Count/), these are misleading.

Both methods get an instance of `IEnumerator` and call `MoveNext()`. If it returns `false`, it means it’s empty so, they throw an `InvalidOperationException`, otherwise, `First()` simply returns the value.

`Single()` calls `MoveNext()` a second time to check if there are more elements, throwing an `InvalidOperationException` if it returns `true`.

## FirstOrDefault() and SingleOrDefault()

Throwing an exception is a very expensive operation. `FirstOrDefault()` and `SingleOrDefault()` are alternatives that return the default value when the sequence is empty. Checking if the returned value is the default is much cheaper than catching the exception.

> If empty sequences are an expected result then you should call `FirstOrDefault()` or `SingleOrDefault()` instead.

Their implementation is very similar to the previous methods but returning default instead of throwing:

```csharp
public static T FirstOrDefault<T>(this IEnumerable<T> enumerable)
{
    using(var enumerator = enumerable.GetEnumerator())
    {
        if(!enumerator.MoveNext())
          return default;

        return enumerator.Current;
    }
}

public static T SingleOrDefault<T>(this IEnumerable<T> enumerable)
{
    using(var enumerator = enumerable.GetEnumerator())
    {
        if(!enumerator.MoveNext())
          return default;

        var first = enumerator.Current;

        if(enumerator.MoveNext())
          throw new InvalidOperationException("Sequence contains more than one element");

        return first;
    }
}
```

None of the methods loops through the sequence which means they have O(1) complexity. This should be good but, not so quickly…

## Where()

All the methods from above have a second overload that requires a predicate function. This is a more efficient equivalent to calling `Where()` followed by any of the previous methods as only one enumerator is created. The predicate argument is the filter function that would have been passed to the `Where()` method. [Check at SharpLab.io for a working code example which shows that both options have the same behavior](https://sharplab.io/#v2:C4LgTgrgdgPgAgBgARwIwG4CwAoRLUB0AMgJZQCOW2OcAzPgGwoBM+A7EjgN45J8r00TOABZ8ADgAUASk7Z+SLgt4L+aAJySAolAgBbAKZgAhgCMANgYIAlY1ADmByQgA0SVAmkrVP3z4IA6gAWRk66eqZGSAC8AHxI4ZFgSPEArF7yfll+BABiJGAAzsAA8mAAIgYAZsYQ5sAy0lR+3qoa2uFGZpY2do7Obh7SBK3ZY0j5RaUV1bX1kolRcQn6SSlI6U2tAL4420A==).

Their implementations can be the following:

```csharp
public static T First<T>(this IEnumerable<T> enumerable, Func<T, bool> predicate)
{
    using(var enumerator = enumerable.GetEnumerator())
    {
        while(enumerator.MoveNext())
        {
            var current = enumerator.Current;
            if (predicate(current))
                return current;
        }
        throw new InvalidOperationException("Sequence contains no elements");
    }
}

public static T Single<T>(this IEnumerable<T> enumerable, Func<T, bool> predicate)
{
    using(var enumerator = enumerable.GetEnumerator())
    {
        while(enumerator.MoveNext())
        {
            var current = enumerator.Current;
            if (predicate(current))
            {
                // found first, keep going until end or find second
                while (enumerator.MoveNext())
                {
                    if (predicate(enumerator.Current))
                        throw new InvalidOperationException("Sequence contains more than one element");
                }
                return current;
            }
        }
        throw new InvalidOperationException("Sequence contains no elements");
    }
}
```

The methods now have to loop through the sequence until `predicate()` returns `true`. `Single()` has to keep going through the sequence to find if there’s a second item that makes `predicate()` return `true`.

These methods have a O(n) complexity. For `First()`, n is the position of the first item for which predicate() returns `true`, while for `Single()`, n is the position of the second item for which `predicate()` returns `true`. Worst case scenario for both, n is the length of the sequence.

Searching for an element with an unique identifier, is the usual scenario for using `Single()`. Actually, this is the worst case scenario. Even if the element is the first one on the sequence, it will go up til the end of the sequence just to prove that it’s unique…

> When using `Single()` or `SingleOrDefault()`, you may be paying a huge performance penalty to validate data when you simply want to query it. Unless you are unit testing, you should validate it elsewhere.

This is the same complexity for when using the first version of these methods after an `Where()` operation. Each call to `MoveNext()` is possibly hiding many `MoveNext()` calls upstream. This is why it’s not enough to analyze complexity looking solely into the extension method implementation, generating some misconceptions on the performance of these methods.

> `First()`, `Single()`, `FirstOrDefault()` and `SingleOrDefault()`, most of the time are associated with an `Where()` operation. The resulting complexity is O(n). That’s the expected complexity of searching for an item on an `IEnumerable`.

> NOTE: These rules may not apply when using `IQueryable` as these operations will be performed by more efficient engines with indices and query plans, e.g. in a database.

## Conclusions

To avoid O(n) complexity when getting an item, you should consider data structures that supply more efficient methods to find the elements. The Dictionary is commonly used but there are many more options. Search on the web for “data structures and algorithms” to learn more about the alternatives.

You should only need to check if the query returns more than one value during development or testing. If it should return just one value and it doesn't, then there's either an issue either with the data or with the query. You may use `Single()` or `SingleOrDefault()` to perform these tests. You should not use them in production because they considerably impact performance of the application to detect.
