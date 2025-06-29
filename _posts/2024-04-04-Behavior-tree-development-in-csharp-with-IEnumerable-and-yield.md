---
layout: post
read_time: true
show_date: true
title: "Behavior Tree Development in C# with IEnumerable<T> and Yield"
date: 2024-04-04
img_path: /assets/img/posts/20240404
image: Obidos.jpg
tags: [development, .net, csharp, yield]
category: development
meta_description: "A practical guide to building behavior trees in C# using IEnumerable<T> and yield, with examples for game AI and robotics."
---

Coroutines are commonly defined as [functions capable of pausing and resuming execution](https://en.wikipedia.org/wiki/Coroutine). Managing these requires employing state machines, easily implemented through the use of the `yield` keyword. However, a challenge arises when composing multiple reusable coroutines, a problem addressed by the concept of behavior trees.

Behavior trees, [with practical applications in game development and robotics](<https://en.wikipedia.org/wiki/Behavior_tree_(artificial_intelligence,_robotics_and_control)>), offer a modular and reusable approach to specifying agent or robot behavior. Commonly used in these fields, the concept extends to synchronously managing code execution across various computer science domains.

## Understanding Behavior Trees

Behavior trees are composed of nodes arranged in a tree structure. Each node acts as a pull stream, initiating processing whenever it's pulled, representing a behavioral step. During each step, if additional processing is needed, it yields `Running`. Once no further processing is necessary, it yields either `Succeeded` if the node completed its task successfully, or `Failed` if not.

![Behavior node stream](BehaviorNodeStream.png)

### Node Classifications

Behavior tree nodes are commonly classified into three main types:

- **Composite Nodes:** Nodes containing multiple children.
- **Decorator Nodes:** Nodes with a single child.
- **Leaf Nodes:** Nodes devoid of children.

![Behavior node types](BehaviorTree.png)

Composite and decorator nodes manage the execution flow within their child nodes, controlling how behaviors are executed and enhancing the reusability of behavior tree components. Meanwhile, leaf nodes handle specific operations, including:

1. **File Operations:** Reading from or writing to files on disk.
2. **Network Communication:** Sending or receiving data over a network, such as HTTP requests.
3. **Database Operations:** Interacting with databases, executing queries, or updates.
4. **User Interface Manipulation:** Modifying elements in a GUI, such as updating text or changing colors.
5. **Logging:** Recording events, errors, or other information to a log file or system.
6. **Hardware Control:** Interacting with hardware devices like sensors, actuators, or robotic arms.
7. **External System Integration:** Communicating with external systems, APIs, or services.
8. **Notification Delivery:** Sending notifications, emails, or messages to users or other systems.
9. **Sensor Data Processing:** Analyzing or interpreting data from sensors.
10. **External Environment Interaction:** Triggering events or actions in the physical or virtual environment outside the application.

These examples represent only a subset of potential operations, with specific implementations varying greatly based on the application's requirements and context within the behavior tree.

Through hierarchical composition in a tree-like structure, complex tasks can be constructed by combining simpler modules. This hierarchical approach offers flexibility and scalability, making it easier to create intricate behaviors and tasks.

## Implementing Behavior Trees in C#

There are multiple ways to implement behavior trees in C#. In this section, I'll describe a minimal approach that takes advantage of the capability of the `yield` keyword to construct state machines.

> **Note:** For a deeper exploration of the `yield` keyword's functionalities, you may refer to my other article titled ["Building Custom Iterators with 'yield' in C#"](https://aalmada.github.io/posts/Building-custom-iterators-with-yield-in-csharp/).

### Node Status Definition

Let's start by defining a type that encapsulates the three possible statuses of a node:

```csharp
enum BehaviorStatus
{
  Running,
  Succeeded,
  Failed
};
```

### Node Definitions

In C#, pull streams can be produced using either an enumerable or an enumerator, both conveniently implemented with the `yield` keyword. The choice between an enumerator and an enumerable depends on the specific requirements of the implementation.

Nodes function as pull streams, represented as an enumerator `IEnumerator<BehaviorStatus>`. Each behavioral step is initiated by invoking `MoveNext()` on this enumerator. If `MoveNext()` returns `true`, the current behavior status can be accessed via the `Current` property of the enumerator. However, a return value of `false` indicates that no further behavior statuses will be provided.

In cases where the behavior node operates until a termination status is reached, using an enumerator is adequate. However, certain scenarios require the repetition of child behavior. Enumerators generated by `yield` lack an implementation of the `Reset()` method, leading to a `NotSupportedException`. On the other hand, invoking `GetEnumerator()` on an enumerable produced using `yield` returns a new enumerator instance, initialized to its initial state. This enables the node behavior to be repeated.

Considering these aspects, the behavior tree implementation presented in this article relies on methods returning `IEnumerable<BehaviorStatus>`. This also has the advantage that `foreach` can be used to both pull the node status and also dispose its enumerator.

### Implementing Leaf Nodes

Let's introduce some basic leaf nodes:

```csharp
static IEnumerable<BehaviorStatus> Succeed()
{
    yield return BehaviorStatus.Succeeded;
}

static IEnumerable<BehaviorStatus> Fail()
{
    yield return BehaviorStatus.Failed;
}
```

These nodes straightforwardly yield either `Succeeded` or `Failed` status, showcasing the fundamental principles of this approach. Each node is a method returning `IEnumerable<BehaviorStatus>` and employing the `yield` keyword to produce the status.

Leaf nodes frequently cause side effects. Consider this example, which outputs to the console:

```csharp
static IEnumerable<BehaviorStatus> WriteLine(string message)
{
    Console.WriteLine(message);

    yield return BehaviorStatus.Succeeded;
}
```

Leaf nodes can also handle more intricate behaviors lasting for multiple behavioral steps. For instance, the following node prints a range of integers to the console, with each line outputted in a behavioral step:

```csharp
static IEnumerable<BehaviorStatus> WriteLineRange(int start, int count)
{
    ArgumentOutOfRangeException.ThrowIfNegative(count);
    return GetEnumerable(start, count);

    static IEnumerable<BehaviorStatus> GetEnumerable(int start, int count)
    {
        var end = start + count;
        for(var value = start; value < end; value++)
        {
            Console.WriteLine(value);

            if(value < end - 1)
                yield return BehaviorStatus.Running;
        }
        yield return BehaviorStatus.Succeeded;
    }
}
```

> To ensure parameter validation happens during tree definition rather than the initial behavioral step, this method separates the yielding code into an internal method. For more details, refer to [my other article](https://aalmada.github.io/posts/Building-custom-iterators-with-yield-in-csharp/#lazy-evaluation) explaining this.

> The examples provided here use parameter validation methods introduced in .NET 8. For older versions, appropriate equivalent code must be used.

The node validates the parameters and then initiates a `for` loop, yielding `Running` with each iteration, pausing until the next behavioral step. Upon reaching the upper limit of `value`, it yields `Succeeded`.

> These two nodes provide valuable insights into the behavior of a tree. [Feel free to experiment with the provided code in SharpLab](https://sharplab.io/#gist:a1edba42d27df7524b9f13c5e9fdfd34). Modify the tree definition and observe the resulting output.

### Implementing Decorator Nodes

Decorator nodes contain a single child node, passed as a method parameter, and typically modify the behavior of this child node.

#### Invert

The `Invert` node reverses the termination status of the child node:

```csharp
static IEnumerable<BehaviorStatus> Invert(IEnumerable<BehaviorStatus> child)
{
    ArgumentNullException.ThrowIfNull(child);
    return GetEnumerable(child);

    static IEnumerable<BehaviorStatus> GetEnumerable(IEnumerable<BehaviorStatus> child)
    {
        foreach(var status in child)
        {
            switch(status)
            {
                case BehaviorStatus.Running:
                    yield return BehaviorStatus.Running;
                    break;
                case BehaviorStatus.Succeeded:
                    yield return BehaviorStatus.Failed;
                    yield break;
                case BehaviorStatus.Failed:
                    yield return BehaviorStatus.Succeeded;
                    yield break;
            }
        }
    }
}
```

This node validates the parameters and then employs a `for` loop to track the number of repetitions. Within this loop, it iterates over the child's behavior using a `foreach` loop to acquire its status. It reacts to each status yielded by the child as follows:

This node uses a `foreach` loop to iterate over the child's behavior and acquire its status. It responds to each status yielded by the child as follows:

- If the child yields `Running`, this node yields the same, ensuring the child's behavior continues to be executed.
- If the child yields `Succeeded` or `Failed`, this node yields the opposite status, effectively reversing the termination status. It uses `yield break` in both cases to terminate the behavioral stream.

#### Repeat

The `Repeat` node executes the behavior of the child a specified number of times, unless it fails:

```csharp
static IEnumerable<BehaviorStatus> Repeat(IEnumerable<BehaviorStatus> child, int count)
{
    ArgumentNullException.ThrowIfNull(child);
    ArgumentOutOfRangeException.ThrowIfNegative(count);
    return GetEnumerable(child, count);

    static IEnumerable<BehaviorStatus> GetEnumerable(IEnumerable<BehaviorStatus> child, int count)
    {
        for(var counter = 0; counter < count; counter++)
        {
            foreach(var status in child)
            {
                switch(status)
                {
                    case BehaviorStatus.Running:
                        yield return BehaviorStatus.Running;
                        break;

                    case BehaviorStatus.Succeeded:
                        goto childSucceeded;

                    case BehaviorStatus.Failed:
                        yield return BehaviorStatus.Failed;
                        yield break;
                }
            }
            childSucceeded:
            if(counter < count - 1)
                yield return BehaviorStatus.Running;
        }
        yield return BehaviorStatus.Succeeded;
    }
}
```

- If the child yields `Running`, this node yields the same, ensuring the child's behavior continues to be executed and repeated.
- If the child yields `Succeeded`, this node exits the `foreach` loop and, if it's not the last repetition, yields `Running`, pausing before the next repetition. When another iteration of the `for` loop occurs, the `foreach` loop calls `GetEnumerator()` again, creating a new enumerator instance to repeat the behavior.
- If the child yields `Failed`, this node yields the same, terminating the behavior with a failure status.

It yields `Succeeded` when all repetitions have been completed successfuly.

> The `goto` statement often sparks debate, but hear me out. Unfortunately, the `break` keyword can't be used to break the `foreach` loop when inside a `switch`. To address this, we have a few options: we can unfold the `foreach` into a `while` loop with a termination flag, expand the `switch` into multiple `if` statements, or resort to using a `goto`. The choice is yours; pick your preferred solution.

#### RepeatUntilFail

The `RepeatUntilFail` node continuously repeats the behavior of the child until it fails, resulting in success. This is particularly useful for maintaining this branch of the tree in an infinite loop until a certain condition is met:

```csharp
static IEnumerable<BehaviorStatus> RepeatUntilFail(IEnumerable<BehaviorStatus> child)
{
    ArgumentNullException.ThrowIfNull(child);
    return GetEnumerable(child);

    static IEnumerable<BehaviorStatus> GetEnumerable(IEnumerable<BehaviorStatus> child)
    {
        while(true)
        {
            foreach(var status in child)
            {
                switch(status)
                {
                    case BehaviorStatus.Running:
                        yield return BehaviorStatus.Running;
                        break;

                    case BehaviorStatus.Succeeded:
                        goto childSucceeded;

                    case BehaviorStatus.Failed:
                        yield return BehaviorStatus.Succeeded;
                        yield break;
                }
            }
            childSucceeded:
            yield return BehaviorStatus.Running;
        }
    }
}
```

This node validates the parameters and then uses an infinite `while` loop to continually repeat the behavior. Within this loop, it iterates over the child's behavior using a `foreach` loop to acquire its status. It responds to each status yielded by the child as follows:

- If the child yields `Running` or `Succeeded`, this node yields `Running`, ensuring the child's behavior continues to be executed and repeated.
- If the child yields `Failed`, this node yields `Succeeded` followed by `yield break`, terminating the repetitions with success.

### Implementing Composite Nodes

Composite nodes oversee multiple children, which are passed as a method parameter, and are tasked with managing the execution flow among these child nodes.

#### Sequence

The `Sequence` node executes the behavior of its child nodes sequentially until all children succeed or one fails:

```csharp
static IEnumerable<BehaviorStatus> Sequence(IEnumerable<BehaviorStatus>[] children)
{
    ArgumentNullException.ThrowIfNull(children);
    return GetEnumerable(children);

    static IEnumerable<BehaviorStatus> GetEnumerable(IEnumerable<BehaviorStatus>[] children)
    {
        for(var index = 0; index < children.Length; index++)
        {
            var child = children[index];
            foreach(var status in child)
            {
                switch(status)
                {
                    case BehaviorStatus.Running:
                        yield return BehaviorStatus.Running;
                        break;

                    case BehaviorStatus.Succeeded:
                        goto childSucceeded;

                    case BehaviorStatus.Failed:
                        yield return BehaviorStatus.Failed;
                        yield break;
                }
            }
            childSucceeded:
            if(index < children.Length - 1)
                yield return BehaviorStatus.Running;
        }
        yield return BehaviorStatus.Succeeded;
    }
}
```

This node validates the parameters and then uses a `for` loop to iterate over the children nodes. Within this loop, it uses a `foreach` loop to step through the behavior of each child and acquire its status. It responds to each status yielded by the child as follows:

- If the child yields `Running`, this node yields the same, ensuring the child's behavior continues to be executed.
- If the child yields `Succeeded`, this node exits the `foreach` loop and, if it's not the last child, yields `Running`, pausing before moving to the next child.
- If the child yields `Failed`, this node yields the same followed by `yield break`, terminating the behavior with failure.

Upon completing all children, it yields `Succeeded`.

#### Select

The `Select` node executes the behavior of its child nodes sequentially until one of the children succeeds. It fails if none of the children succeeds:

```csharp
static IEnumerable<BehaviorStatus> Select(IEnumerable<BehaviorStatus>[] children)
{
    ArgumentNullException.ThrowIfNull(children);
    return GetEnumerable(children);

    static IEnumerable<BehaviorStatus> GetEnumerable(IEnumerable<BehaviorStatus>[] children)
    {
        for(var index = 0; index < children.Length; index++)
        {
            var child = children[index];
            foreach(var status in child)
            {
                switch(status)
                {
                    case BehaviorStatus.Running:
                        yield return BehaviorStatus.Running;
                        break;

                    case BehaviorStatus.Succeeded:
                        yield return BehaviorStatus.Succeeded;
                        yield break;

                    case BehaviorStatus.Failed:
                        goto childFailed;
                }
            }
            childFailed:
            if(index < children.Length - 1)
                yield return BehaviorStatus.Running;
        }
        yield return BehaviorStatus.Failed;
    }
}
```

This node is very similar to the `Sequence` node but with the handling of `Succeeded` and `Failed` statuses swapped.

#### ParallelAny

The `ParallelAny` node interleaves the execution of the children's behavior steps, giving the impression of parallel execution. It succeeds or fails when one of the children succeeds or fails, respectively:

```csharp
static IEnumerable<BehaviorStatus> ParallelAny(IEnumerable<BehaviorStatus>[] children)
{
    ArgumentNullException.ThrowIfNull(children);
    return GetEnumerable(children);

    static IEnumerable<BehaviorStatus> GetEnumerable(IEnumerable<BehaviorStatus>[] children)
    {
        var enumerators = new IEnumerator<BehaviorStatus>[children.Length];
        for (var index = 0; index < enumerators.Length && index < children.Length; index++)
            enumerators[index] = children[index].GetEnumerator();

        try
        {
            while(true)
            {
                foreach(var enumerator in enumerators)
                {
                    enumerator.MoveNext();
                    switch(enumerator.Current)
                    {
                        case BehaviorStatus.Succeeded:
                            yield return BehaviorStatus.Succeeded;
                            yield break;

                        case BehaviorStatus.Failed:
                            yield return BehaviorStatus.Failed;
                            yield break;
                    }
                }
                yield return BehaviorStatus.Running;
            }
        }
        finally
        {
            foreach(var enumerator in enumerators)
                enumerator.Dispose();
        }
    }
}
```

This node validates the parameters and stores the enumerators of all its children in an array. It then enters an infinite `while` loop. Within this loop, it iterates through the enumerators array, advancing their respective behaviors by calling `MoveNext()`. It responds to each status yielded by the child as follows:

- If the child yields `Succeeded` or `Failed`, this node yields the same followed by `yield break`, terminating the behavior with the same outcome as the first child that terminates.

It yields `Running` only after advancing one step on all of its children. Finally, it disposes of all stored enumerators.

#### ParallelAll

The `ParallelAll` node interleaves the execution of the children's behavior steps, similar to ParallelAny, but it only succeeds after all children have succeeded. It fails if one of the children fails:

```csharp
class BehaviorEnumerator
{
    public required IEnumerator<BehaviorStatus> Instance { get; init; }
    public bool Succeeded { get; set; } = false;
}

static IEnumerable<BehaviorStatus> ParallelAll(IEnumerable<BehaviorStatus>[] children)
{
    ArgumentNullException.ThrowIfNull(children);
    return GetEnumerable(children);

    static IEnumerable<BehaviorStatus> GetEnumerable(IEnumerable<BehaviorStatus>[] children)
    {
        var enumerators = new BehaviorEnumerator[children.Length];
        for (var index = 0; index < enumerators.Length && index < children.Length; index++)
            enumerators[index] = new BehaviorEnumerator { Instance = children[index].GetEnumerator() };

        try
        {
            var succeededCounter = 0;
            while(true)
            {
                foreach(var enumerator in enumerators)
                {
                    if(!enumerator.Succeeded)
                    {
                        enumerator.Instance.MoveNext();
                        switch(enumerator.Instance.Current)
                        {
                            case BehaviorStatus.Succeeded:
                                enumerator.Succeeded = true;
                                succeededCounter++;
                                if(succeededCounter == children.Length)
                                {
                                    yield return BehaviorStatus.Succeeded;
                                    yield break;
                                }
                                break;
                            case BehaviorStatus.Failed:
                                yield return BehaviorStatus.Failed;
                                yield break;
                        }
                    }
                }
                yield return BehaviorStatus.Running;
            }
        }
        finally
        {
            foreach(var enumerator in enumerators)
                enumerator.Instance.Dispose();
        }
    }
}
```

Similar to `ParallelAny`, this node requires storing the enumerators of all its children. In this case, each enumerator also has a flag indicating if the respective node has already succeeded.

The node validates the parameters and stores the enumerators' information in an array. It then enters an infinite `while` loop. Within this loop, it iterates through the enumerators array. If the enumerator hasn't succeeded yet, it steps its respective behavior by calling `MoveNext()`. It responds to each status yielded by the child as follows:

- If it yields `Succeeded`, the flag of this enumerator is updated to `true`, and a counter of enumerators that succeeded is incremented. If the counter equals the number of children, meaning all have succeeded, the node yields `Succeeded`.
- If it yields `Failed`, the node yields `Failed` followed by `yield break`, terminating the behavior with failure.

It only yields `Running` after advancing one step on all its children. Finally, it disposes of all the stored enumerators.

### Defining and Executing a Tree

To define a behavior tree, compose the node methods. Here's an example:

```csharp
var root = ParallelAll([
        Invert(
          Repeat(
            WriteLineRange(0, 4),
            2
          )
        ),
        WriteLineRange(10, 10),
    ]);
```

The tree employs lazy evaluation, meaning it's executed only when the root's status is pulled. For testing purposes, this can be achieved simply using a `foreach` loop:

```csharp
foreach(var _ in root);
```

Coroutines and behavior trees are commonly utilized to execute steps at specific moments in the application's lifecycle, such as before rendering a frame in a game engine. Here's a possible implementation:

```csharp
using(var enumerator = root.GetEnumerator())
{
    while(true)
    {
        // Step through the behavior tree
        if(!enumerator.MoveNext())
          throw new Exception("Unexpected termination of pull stream");

        // Handle termination of the behavior tree
        switch(enumerator.Current)
        {
            case BehaviorStatus.Succeeded:
                // Perform actions here
                break;

            case BehaviorStatus.Failed:
                // Perform actions here
                break;
        }

        // Render frame here
    }
}
```

In Unity, achieving this requires using a coroutine:

```csharp
IEnumerator Execute(IEnumerable<BehaviorStatus> root)
{
    foreach(var status in root)
    {
        switch(status)
        {
            case BehaviorStatus.Running:
                yield return null;
                break;

            case BehaviorStatus.Succeeded:
                yield break;

            case BehaviorStatus.Failed:
                // Perform actions here
                break;
        }
    }
}
```

## Conclusions

The combination of reusable composite and decorator nodes, orchestrating the logic, alongside input and output leaf nodes, facilitates the construction of intricate behaviors with minimal coupling. Employing `IEnumerable<T>` and the `yield` keyword in C# proves useful for implementing behavior trees, enabling modular and streamlined traversal of coroutines. This approach enhances decoupling, flexibility, and reusability by allowing the creation of behavior tree nodes that yield sequences of statuses.

By leveraging these capabilities, developers can craft robust behavior trees tailored for diverse applications, thereby improving software efficiency, maintainability, and adaptability. Feel free to experiment with [the provided example in SharpLab](https://sharplab.io/#gist:a1edba42d27df7524b9f13c5e9fdfd34). Experiment with altering the tree definition and observe the resulting output.
