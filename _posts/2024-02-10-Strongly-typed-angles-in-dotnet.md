---
layout: post
read_time: true
show_date: true
title: "Exploring the Power of Strong Typing in .NET Angle Representation"
date: 2024-02-10
img_path: /assets/img/posts/20240210
image: Alcazar.jpg
tags: [development, .net, csharp, math]
category: development
---

Angles can be represented in various units, such as degrees, radians, gradians, or revolutions. Degrees can be further divided into minutes and seconds. 

While radians are commonly preferred in many math libraries, some use degrees, but almost always represented by a primitive floating-point type, potentially leading to confusion and runtime errors. Typically, these libraries force the use of either `float` or `double`.

I strongly advocate for the adoption of strongly typed programming languages to catch errors at compile time. The utilization of generics empowers developers to select the type and precision that aligns best with their requirements. Additionally, I prioritize performance and aim to build abstraction layers that don't compromise efficiency.

For years, I've had the vision of developing a generic geometry library for .NET rooted in these principles. The recent improvements in .NET 7 have at last made this ambition achievable. The project includes a specialized package for angles, named `NetFabric.Numerics.Angle`. This package seamlessly integrates into any project, eliminating the need for extensive geometric object implementations.

## NetFabric.Numerics.Angle

This package presents the `Angle<TUnits, T>` type, characterized by two generic parameters. These parameters enable the specification of angle units and the internal type, defining the supported precision. This succinct definition streamlines the creation of strongly-typed local variables, method parameters, and return types.

To create angles, you can use the following syntax:

```csharp
var degreesDoubleAngle = new Angle<Degrees, double>(45.0);
var radiansFloatAngle = new Angle<Radians, float>(1.57f);
var gradiansDecimalAngle = new Angle<Gradians, decimal>(200.0m);
var revolutionsHalfAngle = new Angle<Revolutions, Half>((Half)0.25);
```

Methods can then specify whether they support any type of angle or only angles in specific units. For instance, `Min()` takes two angles of the same units and internal type, returning an angle in the same units and internal type:

```csharp
public static Angle<TUnits, T> Min<TUnits, T>(Angle<TUnits, T> left, Angle<TUnits, T> right)
    where TUnits : IAngleUnits
    where T : struct, IFloatingPoint<T>, IMinMaxValue<T>
    => new(T.Min(left.Value, right.Value));
```

The `Sin()` method can only accept angles in radians of any floating-point type that fulfills its requirements:

```csharp
public static T Sin<T>(Angle<Radians, T> angle)
    where T : struct, IFloatingPoint<T>, IMinMaxValue<T>, ITrigonometricFunctions<T>
    => T.Sin(angle.Value);
```

Conversely, `Asin()` returns an angle in radians:

```csharp
public static Angle<Radians, T> Asin<T>(T sin)
  where T : struct, IFloatingPoint<T>, IMinMaxValue<T>, ITrigonometricFunctions<T>
  => sin < -T.One || sin > T.One
      ? Throw.ArgumentOutOfRangeException<Angle<Radians, T>>(nameof(sin), sin, "The sine value must be in the range [-1, 1].")
      : new(T.Asin(sin));
```

> NOTE: This package extensively utilizes generic math, a feature introduced in .NET 7. For more information about this feature, check out my other article "[Generic math in .NET](https://aalmada.github.io/posts/Generic-math-in-dotnet/)."

The package provides an extensive collection of methods and operators, for example, math operations and angle classification. Check it's [documentation site](https://netfabric.github.io/NetFabric.Numerics/) for the full list of operation.

## Angle Conversion

This package provides comprehensive methods for converting both angle units and internal types.

### Unit Conversion
To convert angle units, utilize one of the static methods below:
- `ToDegrees()`
- `ToRadians()`
- `ToGradians()`
- `ToRevolutions()`

### Internal Type Conversion
For converting the internal type, choose one of the static methods in line with generic math conventions:
- `CreateChecked()`
- `CreateSaturating()`
- `CreateTruncating()`

Here's an example of using these methods in C#:

```csharp
// Instantiate an angle in degrees and radians
Angle<Degrees, double> degreesAngle = new Angle<Degrees, double>(45.0f);
Angle<Radians, double> radiansAngle = new Angle<Radians, double>(Math.PI);

// Convert to single precision
Angle<Radians, float> singleRadiansAngle = Angle.CreateChecked<float>(radiansAngle);

// Convert to revolutions
Angle<Revolutions, float> singleRevolutionsAngle = Angle.ToRevolutions(singleRadiansAngle);
```

Ensure to leverage these methods for precise and efficient angle conversions in your code.

## Angle Reduction

Angles display a cyclic behavior, circling back to their initial value after completing a full revolution, resembling a complete circle. When comparing two instances of the Angle class, it's vital to understand that, for performance reasons, this periodic nature is not inherently considered.

However, if your comparison demands recognition of this periodicity, it is advisable to utilize the static method `Reduce()`. This method yields an instance of the type `AngleReduced<TUnits, T>`. Similar to an `Angle<TUnits, T>`, this type is guaranteed to be in its reduced form. The use of this type facilitates compile-time validation, ensuring that the angle can be safely employed in methods explicitly requiring a reduced angle.

This approach saves computational time, as methods no longer need to proactively reduce the angle or even check its value. The explicit call to `Reduce()` also makes developers aware of its computational cost, allowing for thoughtful code design to prevent unnecessary and repetitive calls.

## Spans of angles

## Performance

## Conclusions






