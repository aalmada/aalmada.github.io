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
---

As discussed in a prior post on [custom iterators with `yield` in C#](https://aalmada.github.io/posts/Building-custom-iterators-with-yield-in-csharp/), the combination of `IEnumerable<T>` and `yield` enables the creation of coroutines. Coroutines are commonly defined as [functions capable of pausing and resuming execution](https://en.wikipedia.org/wiki/Coroutine). Effectively, managing these entails employing state machines, easily implemented through the use of the `yield` keyword. However, a challenge arises when composing multiple reusable coroutines, a problem addressed by the concept of behavior trees.

Behavior trees, [with practical applications in game development and robotics](<https://en.wikipedia.org/wiki/Behavior_tree_(artificial_intelligence,_robotics_and_control)>), offer a modular and reusable approach to specifying agent or robot behavior. Originally designed for these fields, the concept extends to synchronously managing code execution across various computer science domains.

## Understanding Behavior Trees

Behavior trees are organized as collections of nodes arranged in a tree structure. Each node operates in one of three states: `Running`, `Succeeded`, or `Failed`. Consequently, a node is expected to yield an `IEnumerable<BehaviorStatus>`, where `BehaviorStatus` represents these states.

During each behavior step, the node should yield `Running`. It's recommended to keep these steps brief to ensure smooth progress of the application. Subsequently, the application invokes the `MoveNext()` method of the node enumerator to proceed to the next step. Once the behavior concludes, the node must return either `Succeeded` or `Failed`. At this point, the `MoveNext()` method of the node enumerator will no longer be called.

**Node Types:**

- **Composite Node:** A node with multiple children.
- **Decorator Node:** A node with a single child.
- **Leaf Node:** A node lacking children.

Composite and decorator nodes oversee the progression of behavior within their child nodes, offering control over execution flow and enhancing reusability. In contrast, leaf nodes trigger side effects, modifying the application state, and are usually tailored to specific application requirements.

By hierarchically composing modules in a tree structure, complex tasks can be constructed through their combinations. This hierarchical approach offers flexibility and scalability, enabling the creation of sophisticated behaviors and tasks with ease.

## Implementing Behavior Trees in C#

There are many ways for implementing behavior trees in C#. Below, I'll outline a minimalist yet versatile approach to implementing behavior trees based on `IEnumerable<T>` and the `yield` keyword.

> Note: For a deeper understanding of the yield keyword's functionality, refer to my other article titled ["Building Custom Iterators with 'yield' in C#"](https://aalmada.github.io/posts/Building-custom-iterators-with-yield-in-csharp/).

You can find the source code for the examples shown below on SharpLab, where you can also experiment with them. Click [here](https://sharplab.io/#v2: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=) to try it out.

### Defining Node States

To begin, let's define a type that represents the three possible states of a node:

```csharp
enum BehaviorStatus { Running, Succeeded, Failed };
```

### Implementing Leaf Nodes

Continuing our implementation, let's introduce some basic leaf nodes:

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

### Leaf Nodes with Side Effects

Leaf nodes can trigger side effects, such as console output:

```csharp
static IEnumerable<BehaviorStatus> WriteLine(string message)
{
    Console.WriteLine(message);

    yield return BehaviorStatus.Succeeded;
}
```

These nodes can also handle more intricate behaviors. For example, the next node prints a range of integers to the console, with each line outputted in a behavior step:

```csharp
static IEnumerable<BehaviorStatus> WriteLineRange(int start, int count)
{
    var value = start;
    var end = start + count;
    while(true)
    {
        Console.WriteLine(value);

        value++;
        if(value == end)
        {
            yield return BehaviorStatus.Succeeded;
            yield break;
        }
        yield return BehaviorStatus.Running;
    }
}
```

The node uses an infinite loop, yielding `Running` with each iteration. Execution halts until `MoveNext()` of the enumerator is called once more. Upon hitting the `value` upper limit, it yields `Succeed` and terminates the node's operation using a `yield break`.

It's worth mentioning that a `for` loop could have been employed instead, yielding `Succeeded` at every iteration and finally yielding `Succeeded` upon completion. It would be simpler however, this approach would require an extra `MoveNext()` call for termination determination. The behavior above promptly returns `Succeeded` after displaying the last value of the range on the console.

Leaf nodes can trigger many other types of side effect:

1. **File Operations:** Reading from or writing to files on disk.
2. **Network Communication:** Sending or receiving data over a network, such as HTTP requests.

3. **Database Operations:** Interacting with databases, such as executing queries or updates.

4. **User Interface Manipulation:** Modifying elements in a graphical user interface (GUI), like updating text or changing colors.

5. **Logging:** Logging events, errors, or other information to a log file or system.

6. **Hardware Control:** Interacting with hardware devices, such as sensors, actuators, or robotic arms.

7. **External System Integration:** Communicating with external systems, APIs, or services.

8. **Notification Delivery:** Sending notifications, emails, or messages to users or other systems.

9. **Sensor Data Processing:** Processing data from sensors, such as filtering, analyzing, or interpreting.

10. **External Environment Interaction:** Interacting with the physical or virtual environment outside the application, such as triggering events or actions in a simulation.

These are just a few examples, and the specific side effects can vary greatly depending on the requirements and context of the application using the behavior tree.

### Implementing Decorator Nodes

Decorator nodes have a single child node, which is passed as a method parameter. These nodes typically modify the behavior of their child node.

#### Invert

This node inverts the termination state of the child node:

```csharp
static IEnumerable<BehaviorStatus> Invert(IEnumerable<BehaviorStatus> child)
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
```

In this implementation, a `foreach` loop is used to iterate over the behavior of the child and obtain its status. During each iteration, if the child is in the `Running` state, the decorator remains in the `Running` state. However, if the child transitions to `Succeeded`, the decorator switches to `Failed`, and if the child transitions to `Failed`, the decorator switches to `Succeeded`.

#### Repeat

This node repeats the behavior of the child a given number of times, unless it fails:

```csharp
static IEnumerable<BehaviorStatus> Repeat(IEnumerable<BehaviorStatus> child, int count)
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

                case BehaviorStatus.Failed:
                    yield return BehaviorStatus.Failed;
                    yield break;
            }
        }
        yield return BehaviorStatus.Running;
    }
    yield return BehaviorStatus.Succeeded;
}
```

#### RepeatUntilFail

This node keeps repeating the behavior of the child until it fails, resulting in success. This is useful to keep this branch of the tree in an infinite loop until some condition:

```csharp
static IEnumerable<BehaviorStatus> RepeatUntilFail(IEnumerable<BehaviorStatus> child)
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

                case BehaviorStatus.Failed:
                    yield return BehaviorStatus.Succeeded;
                    yield break;
            }
        }
        yield return BehaviorStatus.Running;
    }
}
```

### Implementing Composite Nodes

Composite nodes manage multiple children, which are passed as a method parameter, and are responsible for controlling the execution flow among these child nodes.

#### Sequence

This node executes the behavior of its child nodes in sequence until all children succeed or one fails:

```csharp
static IEnumerable<BehaviorStatus> Sequence(IEnumerable<BehaviorStatus>[] children)
{
    foreach(var child in children)
    {
        foreach(var status in child)
        {
            switch(status)
            {
                case BehaviorStatus.Running:
                    yield return BehaviorStatus.Running;
                    break;

                case BehaviorStatus.Failed:
                    yield return BehaviorStatus.Failed;
                    yield break;
            }
         }
    }
    yield return BehaviorStatus.Succeeded;
}
```

#### Select

This node executes the behavior of its child nodes in sequence until one of the children succeeds. It fails if none of the children succeeds:

```csharp
static IEnumerable<BehaviorStatus> Select(IEnumerable<BehaviorStatus>[] children)
{
    foreach(var child in children)
    {
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
            }
         }
    }
    yield return BehaviorStatus.Failed;
}
```

#### ParallelAny

This node interleaves the execution of the children's behavior steps, giving the impression of parallel execution. It succeeds or fails when one of the children succeeds or fails, respectively:

```csharp
static IEnumerable<BehaviorStatus> ParallelAny(IEnumerable<BehaviorStatus>[] children)
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
                if(enumerator.MoveNext())
                {
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
```

#### ParallelAll

This node also interleaves the execution of the children's behavior steps, but it only succeeds after all children have succeeded. It fails if one of the children fails:

```csharp
class EnumeratorState
{
    public IEnumerator<BehaviorStatus> Instance;
    public bool MovedNext;
}

static IEnumerable<BehaviorStatus> ParallelAll(IEnumerable<BehaviorStatus>[] children)
{
    var enumerators = new EnumeratorState[children.Length];
    for (var index = 0; index < enumerators.Length && index < children.Length; index++)
        enumerators[index] = new EnumeratorState
            {
                Instance = children[index].GetEnumerator(),
                MovedNext = true
            };

    try
    {
        var counter = 0;
        while(true)
        {
            foreach(var enumerator in enumerators)
            {
                if (enumerator.MovedNext)
                {
                    var instance = enumerator.Instance;
                    if(instance.MoveNext())
                    {
                        switch(instance.Current)
                        {
                            case BehaviorStatus.Succeeded:
                                counter++;
                                if(counter == children.Length)
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
                    else
                    {
                        enumerator.MovedNext = false;
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
```

These composite nodes manage the execution flow among their children nodes, offering flexibility and control over the behavior tree's behavior.

### Defining and Executing a Tree

To define a behavior tree, compose the node methods as follows:

```csharp
var tree = Sequence([
    Repeat(
      WriteLine("repeat"), 3
    ),
    WriteLineRange(10, 5),
    WriteLine("done")
]);
```

The tree is lazily evaluated, meaning it's executed only when the status of the tree root is pulled. To do this, simply use a `foreach` loop:

```csharp
foreach (var _ in tree);
```

In Unity, you can use the following coroutine:

```csharp
IEnumerator Execute() => tree.GetEnumerator();
```

## Conclusions

Using `IEnumerable<T>` and the `yield` keyword in C# is essential for implementing behavior trees, enabling modular and efficient traversal of coroutines. These allow for the creation of behavior tree nodes that produce sequences of statuses, enhancing decoupling, flexibility, end reusability.

By leveraging these features, developers can create robust behavior trees tailored to various applications, improving software efficiency, maintainability and adaptability.
