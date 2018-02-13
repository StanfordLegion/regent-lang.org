---
layout: page
title: Language Reference
sidebar: false
highlight_first: false
permalink: /reference/index.html
---

  * [Frontmatter](#frontmatter)
  * [Lua/Terra Compatibility](#luaterra-compatibility)
      * [Unsupported Terra Features](#unsupported-terra-features)
  * [Execution Model](#execution-model)
      * [Tasks](#tasks)
      * [Top-Level Task](#top-level-task)
      * [Privileges](#privileges)
      * [Coherence Modes](#coherence-modes)
      * [Constraints](#constraints)
      * [Copies](#copies)
      * [Fills](#fills)
  * [Data Model](#data-model)
      * [Field Spaces](#field-spaces)
      * [Index Spaces](#index-spaces)
      * [Regions](#regions)
      * [Partitions](#partitions)
  * [Metaprogramming](#metaprogramming)
      * [Symbols](#symbols)
      * [Statement Quotes](#statement-quotes)
      * [Expressions Quotes](#expression-quotes)
      * [Task Generation](#task-generation)
  * [Foreign Function Interface](#foreign-function-interface)
      * [Legion C API](#legion-c-api)

# Frontmatter

Regent is implemented as a [Terra](http://terralang.org) language
extension. Every Regent source file must therefore start with:

{% highlight regent %}
import "regent"
{% endhighlight %}

This loads the Regent compiler and enables hooks to start Regent on
certain keywords (`task` and `fspace`).

# Lua/Terra Compatibility

The top-level of a Regent source file executes in a Lua/Terra context,
and Lua, Terra, and Regent constructs can be freely mixed at this
level. For example:

{% highlight regent %}
local x = 5 -- Define a Lua variable (constant from the perspective of Regent).
function make_fg(z) -- Define a Lua function.
  local terra f(y : int) -- Define a local Terra function.
    return x + y + z
  end
  local task g(y : int) -- Define a local Regent task.
    return x + f(y) + z -- Call the local Terra function.
  end
  return f, g
end
local a, b = make_fb(10) -- Call the Lua function to create
local c, d = make_fb(20) -- specialized versions of the functions.
{% endhighlight %}

Most [Terra](http://terralang.org) language features can also be used
in Regent tasks, and compilation of Regent programs proceeds similarly
to Terra. For example, Lua variables referenced in Regent tasks are
specialized prior to type checking, and are effectively constant from
the perspective of Regent.

## Unsupported Terra Features

The following Terra features are not supported in Regent:

  * The address-of operator `&`.
  * The method call operator `o:f()` does not automatically
    dereference Regent's `ptr` type.
  * Terra [macros](http://terralang.org/api.html#macro).
  * Terra [quotes](http://terralang.org/api.html#quote).

In general, use Terra's raw pointer types (`&T`) with caution. Regent
may execute tasks in a distributed environment, so a pointer created
in one task might not be valid in another. As long as pointers stay
within a task, it is ok to use raw pointers (and traditional C APIs
like `malloc` and `free`).

# Execution Model

## Tasks

Tasks are the fundamental unit of execution in Regent. Tasks are
similar to functions in most other programming languages: tasks take
arguments and (optionally) return a value, and contain a body of
statements which execute top-to-bottom. Unlike traditional functions,
tasks must explicitly specify any interactions with the calling
context through *privileges*, *coherence modes*, and *constraints*.

{% highlight regent %}
-- Task with inferred return type.
task f(a0 : t0, a1 : t1, ..., aN : tN)
  ...
end

-- Task with explicit return type.
task f(a0 : t0, a1 : t1, ..., aN : tN) : return_type
  ...
end

-- Task with privileges, coherence modes, and constraints.
task f(a0 : t0, a1 : t1, ..., aN : tN) : return_type
where ... do
  ...
end
{% endhighlight %}

## Top-level Task

Regent programs execute in a top-level Lua/Terra context, but Regent
tasks cannot be called from Lua/Terra. Instead, a Regent program may
begin execution of tasks by calling `regentlib.start` with a task
argument. This task becomes the top-level task in the Regent program,
and may call other tasks as desired.

{% highlight regent %}
task main()
  ...
end
regentlib.start(main)
{% endhighlight %}

The call does not return, and is typically placed at the end of a
Regent source file. At this time, the runtime is not reentrant, so
even if the call did return, it would still not be possible to launch
another top-level task.

## Privileges

Privileges describe how a task interacts with [region](#region)-typed
arguments. For example, `reads` is required in order to read from a
region argument, and `writes` is required to modify a
region. Reductions allow the application of certain commutative
operators to regions. Note that privileges in general apply only to
region-typed, and not immediate arguments passed by-value (such as
`int`, `float`, and `ptr` data types).

{% highlight regent %}
reads(r)
writes(r)
reduces <op>(r) -- for op in +, *, -, /, min, max
{% endhighlight %}

Privileges are most frequently seen in the `where` clause of a
[task](#tasks).

## Coherence Modes

Coherence modes specify a task's expectations of isolation with
respect to sibling tasks on the marked regions. Regent supports four
coherence modes:

{% highlight regent %}
exclusive(r)
atomic(r)
simultaneous(r)
relaxed(r)
{% endhighlight %}

The modes behave as follows:

  * `exclusive` mode (the default) guarantees that tasks will execute
    in a manner that preserves the original sequential semantics of
    the code.

  * `atomic` mode allows tasks to be reordered in a manner that
    preserves serializability, similar to a transaction-based
    system. Atomicity is provided at the level of a task.

  * `simultaneous` mode allows tasks to run concurrently as long as
    they use the same physical instance for all simultaneous
    regions. This guarantees that the regions in question behave with
    shared memory semantics, similar to pthreads, etc.

  * `relaxed` mode allows marked tasks to run concurrently with no
    restrictions.

Coherence modes are most frequently seen in the `where` clause of a
[task](#tasks).

## Constraints

Constraints specify the desired relationships between
regions. Constraints are checked at compile time and must be satisfied
by the caller. The supported constraints are disjointness (`*`) and
subregion (`<=`).

{% highlight regent %}
r * s  -- r and s are disjoint.
r <= s -- r is a subregion of s.
{% endhighlight %}

Constraints are most frequently seen in the `where` clause of a
[task](#tasks) or [field space](#field-spaces).

## Copies

Copy operations copy the contents of one region to another (for all or
some subset of fields). The number and types of fields so named must
match.

{% highlight regent %}
copy(r, s)                     -- Copy all fields.
copy(r.x, s.y)                 -- Copy field x to y.
copy(r.{x, y, z}, s.{u, v, w}) -- Copy fields x, y, z to fields u, v, w.
{% endhighlight %}

## Fills

Fill operations replace the contents of a region (for all or some
subset of fields) with a single specified value. The type of the value
must match the named fields.

{% highlight regent %}
fill(r, v)           -- Fill r with v.
fill(r.x, v)         -- Fill field x of r with v.
fill(r.{x, y, z}, v) -- Fill fields x, y, z of r with v.
{% endhighlight %}

# Data Model

## Field Spaces

Field spaces are sets of fields, and behave similarly to Terra
structs. For example, field spaces may be instantiated by casting an
anonymous struct to the appropriate type.

{% highlight regent %}
fspace point {
  x : int,
  y : int,
}

task make_point(a : int, b : int) : point
  var p = point { x = a, y = b } -- Define a local variable of type point.
  return p
end
{% endhighlight %}

Field spaces differ from structs in that they may take region-typed
arguments. Such arguments are useful for declaring recursive data
types. References to field spaces with arguments must be escaped.

{% highlight regent %}
fspace point {
  {x, y} : double -- Multiple fields may be declared with a single type.
}

fspace edge(r : region(point)) {
  left: ptr(point, r),
  right: ptr(point, r),
}

task make_edge(points : region(point), a : ptr(point, points), b : ptr(point, points))
  return [edge(points)] { left = a, right = b }
end
{% endhighlight %}

In the presence of [partitions](#partitions), it can be difficult to
choose right region to use as an arugment to a field space. In these
cases, it can be helpful to use the `wild` operator (which matches any
region) in the declaration of the field space. Note that this
currently exposes unsoundness in the type system; the user is
responsible for making sure that the right regions are used when the
field space is actually instantiated. (For those interested in the
type theory behind this, see the [DPL
paper](http://legion.stanford.edu/pdfs/dpl2016.pdf).)

For example, a quad-tree implementation might feature the following
field space declaration:

{% highlight regent %}
fspace quad(r : region(quad(wild))) {
  val: double,
  ne: ptr(quad(wild), r),
  nw: ptr(quad(wild), r),
  se: ptr(quad(wild), r),
  sw: ptr(quad(wild), r),
}
{% endhighlight %}

## Index Spaces

Index spaces are sets of indices, used most frequently to define the
set of keys in a [region](#regions). Index spaces may be unstructured
(i.e. indices are opaque pointers), or structured (i.e. indices are
N-dimensional points with an implied geometric
relationship). Unstructured index spaces are created with a maximum
size and are initially empty. Structured index spaces are created with
an extent and optional start, and are pre-allocated.

{% highlight regent %}
-- Unstructured:
var i0 = ispace(ptr, 5) -- Empty unstructured space with room for 5 elements.

-- Structured:
var i1 = ispace(int1d, 10) -- 1-dimensional space with 10 elements.
-- 2-dimensional 4x4 rectangle with indices starting at 1,1.
var i2 = ispace(int2d, { x = 4, y = 4 }, { x = 1, y = 1 })
{% endhighlight %}

## Regions

Regions are the cross-product between an index space and a field
space. The name of the region exists in the scope of the declaration,
so recursive data types may refer to the region being defined.

{% highlight regent %}
var r0 = region(i0, int)                       -- A region of ints on i0.
var r1 = region(ispace(ptr, 5), list_node(r1)) -- A linked list with 5 elements.
var r2 = region(ispace(int1d, 10, 3), point)   -- A 1D vector of points.
{% endhighlight %}

## Partitions

Partitions subdivide regions into subregions. Several partitioning
operators are described below. Note that not all partitions are
disjoint: some partitions, such as the image operator, may be aliased.

### Equal

Produces roughly equal subregions, one for each color in the supplied
color space. The resulting partition is guaranteed to be disjoint. If
the size of the color space is evenly divisable by the requested number
of subregions then they will be of equal size and contiguous---otherwise
the exact way in which the remaining elements are partitioned is unspecified.

{% highlight regent %}
var p = partition(equal, r, color_space)
{% endhighlight %}

### By Field

Partitions a region based on a coloring stored in a field of the
region. The resulting partition is guaranteed to be disjoint.

{% highlight regent %}
var p = partition(r.color_field, color_space)
{% endhighlight %}

### Image

Partitions a region by computing the image of each of the subregions
of a partition through the supplied (pointer-typed) field of a
region. The resulting partition is **NOT** guaranteed to be disjoint.

{% highlight regent %}
var p = image(parent_region, source_partition, data_region.field)
{% endhighlight %}

### Preimage

Partitions a region by computing the preimage of each of the
subregions of a partition through the supplied (pointer-typed) field
of a region. The resulting partition is guaranteed to be disjoint
**IF** the supplied target partition is disjoint.

{% highlight regent %}
var p = preimage(parent_region, target_partition, data_region.field)
{% endhighlight %}

### Union

Computes the zipped union of the subregions in the supplied
partitions. The resulting partition is **NOT** guaranteed to be
disjoint.

{% highlight regent %}
var p = lhs_partition | rhs_partition
{% endhighlight %}

### Intersection

Computes the zipped intersection of the subregions in the supplied
partitions. The resulting partition is guaranteed to be disjoint
**IF** either or both of the arguments are disjoint.

{% highlight regent %}
var p = lhs_partition & rhs_partition
{% endhighlight %}

### Difference

Computes the zipped difference of the subregions in the supplied
partitions. The resulting partition is guaranteed to be disjoint
**IF** the left-hand-side partition is disjoint.

{% highlight regent %}
var p = lhs_partition - rhs_partition
{% endhighlight %}

# Metaprogramming

Regent supports [Terra-style
metaprogramming](http://terralang.org/getting-started.html#meta-programming). Metaprogramming
can be used to accomplish a variety of purposes:

  * Field spaces with input-dependent sets of fields
  * Index spaces with input-dependent dimensionality
  * Tasks with input-dependent arguments, privileges, and/or contents

More generally, Regent can be used as a full-featured code generator
for Legion, in the same way that Terra is used (by Regent itself) as a
code generator for LLVM.

For the most part, these features work the same as in Terra. (For
example, types are still Lua expressions, and quotes can still be
inserted with the escape operator `[]`.) Regent-specific features are
described below.

## Symbols

A symbol can be used as a variable or task parameter. To generate a
fresh, unique symbol, call:

{% highlight regent %}
regentlib.newsymbol(int, "name")
{% endhighlight %}

## Statement Quotes

Regent provides an `rquote` operator which is analogous to Terra's
`quote` feature.

{% highlight regent %}
rquote
  var x = 5
  return x + 1
end
{% endhighlight %}

## Expression Quotes

Regent provides an `rexpr` operator which is analogous to Terra's
`` ` ``. (Unfortunately, Regent is not able to overload punctuation
operators at this time, making this somewhat more verbose than Terra.)

{% highlight regent %}
repxr 40 + 2 end
{% endhighlight %}

## Task Generation

The example below shows how to generate a simple type-parametric task.

{% highlight regent %}
local function make_increment_task(param_type, by_value)
  local x = regentlib.newsymbol(param_type, "x")
  local inc = rexpr x + by_value end
  local task t([x])
    return [inc]
  end
  return t
end
local inc_int_by_1 = make_increment_task(int, 1)
local inc_double_by_pi = make_increment_task(double, 3.14)
{% endhighlight %}

To inspect the contents of generated tasks, invoke Regent with the
flag `-fpretty 1`. On the code above, this produces the following
output.

{% highlight text %}
task t($x : int32) : int32
-- leaf (true), inner (false), idempotent (false)
  return ($x+1)
end
config options  true    false
task t($x : double) : double
-- leaf (true), inner (false), idempotent (false)
  return ($x+3.14)
end
{% endhighlight %}

This can also be used to determine what optimizations are being
triggered. (For example, leaf optimization is enabled on the tasks
above.)

# Foreign Function Interface

Regent code can call C functions via Terra's foreign function
interface (FFI). For example, the following snippet calls the C standard
library function `printf`:

{% highlight regent %}
local c = terralib.includec("stdio.h")

task hello()
  c.printf("hello!\n")
end
{% endhighlight %}

For more information on Terra's FFI, please see the
[FFI documentation](http://terralang.org/api.html#using-c-inside-terra).

## Legion C API

In some cases, it can be useful to call to call Legion APIs
directly. These work the same as any other C function. As a
convenience, Regent exposes a standard set of headers via the variable
`regentlib.c`. This corresponds to the Legion header file
`legion_c.h`.

Certain Legion API calls may require a runtime and/or context. These
can be obtained in Regent via the operators `__runtime()` and
`__context()`.

For example, the following code calls a Legion execution fence:

{% highlight regent %}
local c = regentlib.c

task a()
  c.printf("this task will run first\n")
end
task b()
  c.printf("this task will run second\n")
end

task main()
  a()
  -- Force a and b to be serialized by inserting a fence.
  -- Note: The fence will *NOT* block the main task.
  c.legion_runtime_issue_execution_fence(__runtime(), __context())
  b()
end
{% endhighlight %}

At this time, the best source of documentation on the C API is the
[source code of the `legion_c.h` header
file](https://github.com/StanfordLegion/legion/blob/master/runtime/legion/legion_c.h). Note
that in most cases, the functions of the C API correspond one-to-one
with the C++ API, so most C APIs are documented simply by pointing to
the corresponding methods in `legion.h`.
