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
      * [Attach and Detach](#attach-and-detach)
      * [Acquire and Release](#acquire-and-release)
      * [File I/O with HDF5](#file-io-with-hdf5)
  * [Data Model](#data-model)
      * [Field Spaces](#field-spaces)
      * [Index Types](#index-types)
      * [Custom Index Types](#custom-index-types)
      * [Index Spaces](#index-spaces)
      * [Regions](#regions)
      * [Partitions](#partitions)
      * [Cross Products](#cross-products)
      * [Partition Operators](#partition-operators)
  * [Annotations](#annotations)
      * [Task Annotations](#task-annotations)
      * [Statement Annotations](#statement-annotations)
      * [Expression Annotations](#expression-annotations)
      * [Experimental Annotations](#experimental-annotations)
  * [Metaprogramming](#metaprogramming)
      * [Symbols](#symbols)
      * [Statement Quotes](#statement-quotes)
      * [Expressions Quotes](#expression-quotes)
      * [Task Generation](#task-generation)
  * [Foreign Function Interface](#foreign-function-interface)
      * [Calling the Legion C API](#calling-the-legion-c-api)
      * [Obtaining C API Handles from Regent Values](#obtaining-c-api-handles-from-regent-values)
      * [Importing C API Handles into Regent](#importing-c-api-handles-into-regent)
  * [Standard Library](#standard-library)

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

  * The method call operator `o:f()` does not automatically
    dereference Regent's `ptr` type.
  * Terra [macros](http://terralang.org/api.html#macro).
  * Terra [quotes](http://terralang.org/api.html#quote).

In general, use Terra's raw pointer types (`&T`) with caution. Regent
may execute tasks in a distributed environment, so a pointer created
in one task might not be valid in another. As long as pointers stay
within a task, it is ok to use raw pointers (and traditional C APIs
like `malloc` and `free`). The same principle applies to process-local
data such as file descriptors: they are ok to use within a task but
should not be passed between tasks.

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

### Restrictions on Copy Operations

The following restrictions apply to the source `S` and destination `D`
regions in a copy operations. Note that the restrictions depend on
which branch of the Legion runtime is being used.

On `master` branch: `D <= S`, that is, `D` must be a subregion of `S`.

On `nopaint` branch (and branches derived from `nopaint` such as
`control_replication`): `D` must contain a subset of the elements in
`S`, but is not otherwise required to be related. That is, it must be
valid to write the following code:

{% highlight regent %}
for i in D do
  D[i] = S[i]
end
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

## Attach and Detach

The attach and detach operations connect a region with an external
resource, like a file on disk. Attaching a region overwrites the
contents of the region and replaces it with the contents of the
external resource. Note that for external resources such as files,
attaching a region does **NOT** copy the contents of the file from
disk into memory. Instead the region should be thought of as a view
onto the contents of the on-disk file. Such a region is said to be
*restricted* and must be [acquired](#acquire-and-release) before it
can be used by a task.

For example, using an external HDF5 file:

{% highlight regent %}
-- Read fields x, y and z from my_file.h5 into the region r.
var filename = "my_file.h5"
attach(hdf5, r.{x, y, z}, filename, regentlib.file_read_write)
...
detach(hdf5, r.{x, y, z})
{% endhighlight %}

The detach operation is used to disassociate the region from an
attached resource once it is no longer being used. The contents of the
region are considered to be uninitialized following a detach
operation, and region is no longer restricted.

See below for detailed instructions on using [file I/O with
HDF5](#file-io-with-hdf5).

**Important:** attach and detach currently require that you **not use
the region within the task where you attach or detach**. If you
attempt to do so, the behavior is undefined. One way to guarantee that
you do this correctly is to require the task to be
[inner](#inner-optimization), though this is a more strict condition
than is required for correctness.

## Acquire and Release

A region which is restricted (e.g. due to an
[attach](#attach-and-detach) operation) cannot be copied, and
therefore cannot be directly accessed by a task if the original
contents are e.g. on disk. The acquire operation is used to indicate
that it is safe to make a copy of the region (e.g. into memory) so
that can be directly accessed by a task. After using acquire, the
region is no longer considered restricted.

The release operation guarantees that any copies of a region made
following an acquire operation are flushed back to their original
location (e.g. disk).

Note that if the original contents of the region are on disk, any
concurrent writes (e.g. by other processes running on the machine) to
the file on disk may or may not be seen by tasks. In order to safely
perform concurrent writes to the file, the region must be released
prior to any external writes being made, and only re-acquired after
the writes are complete. Similarly, any external process which reads
the file must wait until after the region is released. The user is
responsible for ensuring that the correct synchronization is used with
any external processes that perform concurrent access to the file.

{% highlight regent %}
acquire(r)
some_task(r)
release(r)
{% endhighlight %}

## File I/O with HDF5

Regent supports file I/O via the HDF5 file format. Support for HDF5
can be enabled by passing the `--hdf5` argument to `install.py` or
setting the environment variable `USE_HDF5=1`. Note that a **serial
build of HDF5 is required**, as parallel support in HDF5 depends on
MPI.

#### Creating an HDF5 File

Currently, Regent does not support creating HDF5 files directly. HDF5
files can be created either prior to running the Regent program, or
can be created by calling the HDF5 C API directly from inside
Regent. For an example of creating an HDF5 file in Regent, see [this
test program](https://github.com/StanfordLegion/legion/blob/stable/language/tests/hdf5/run_pass/attach_hdf5.rg).

#### Reading or Writing an Existing HDF5 File

To read or write an existing HDF5 file, the [attach
operation](#attach-and-detach) is used to connect the region to the
contents of the external file. Using attach effectively overwrites the
region, and any existing contents will be lost.

Following an attach operation, the region should be thought of as a
view onto the data stored on disk. Note that the contents of the file
are **NOT** automatically copied from disk into memory. The
[acquire](#acquire-and-release) operation is subsequently used to
permit the contents of the region to be copied into memory. In the
example below, the copy will be issued prior to executing `some_task`.

{% highlight regent %}
-- Read fields x, y and z from my_file.h5 into the region r.
var filename = "my_file.h5"
attach(hdf5, r.{x, y, z}, filename, regentlib.file_read_write)
acquire(r)
some_task(r)
release(r)
detach(hdf5, r.{x, y, z})
{% endhighlight %}

The value `regentlib.file_read_only` can be used with attach if the
file is to be read and not written.

The release and detach operations reverse the actions performed by
acquire and attach, respectively. For more information on the
semantics of these operations, see the documentation on [attach and
detach](#attach-and-detach) and [acquire and
release](#acquire-and-release) above.

More examples of using HDF5 file I/O can be found in the [test
suite](https://github.com/StanfordLegion/legion/tree/stable/language/tests/hdf5/run_pass).

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
choose right region to use as an argument to a field space. In these
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

## Index Types

Index types define points in an N dimensional space, and are used to
define the elements of [index spaces](#index-spaces). Regent supports
10 built-in index types: `ptr`, `int1d`, `int2d`, `int3d`, and so on
up to `int9d`. Note that `int4d` and above require additional flags at
compile-time and runtime (see below).

{% highlight regent %}
var x0 = ptr(0) -- Pointer to the first element of an index space.
var x1 = int1d(0) -- Index 0 in a 1-dimensional space.
var x2 = int2d({0, 0}) -- Index 0,0 in a 2-dimensional space.
var x3 = int3d({0, 0, 0}) -- Index 0,0,0 in a 3-dimensional space.
var x4 = int4d({0, 0, 0, 0}) -- Index 0,0,0,0 in a 4-dimensional space.
{% endhighlight %}

The fields of the build-in index types are called `x`, `y`, `z`, `w`,
`v`, `u`, `t`, `s`, and `r`, respectively (up to the maximum number of
dimensions of the particular index type).

{% highlight regent %}
var sum4 = x4.x + x4.y + x4.z + x4.w
{% endhighlight %}

When using `int4d` or above (or custom index types with 4 or more
dimensions), Regent must be compiled and run with additional flags as
shown below.

{% highlight bash %}
MAX_DIM=4 ./install.py
./regent.py your_file.rg -flegion-dim 4
{% endhighlight %}

## Custom Index Types

Custom index types can be defined in Regent with any number of
dimensions by defining a struct and passing it to the function
`index_type`.

{% highlight regent %}
struct i2 { x : int, y : int }
local i2d = index_type(i2, "i2d")
{% endhighlight %}

Note when creating custom index types with 4 or more dimensions, it is
important to ensure that Regent is compiled and run with the necessary
flags, shown above.

## Index Spaces

Index spaces are sets of indices, used most frequently to define the
set of keys in a [region](#regions). Index spaces may be unstructured
(i.e. indices are opaque pointers), or structured (i.e. indices are
N-dimensional points with an implied geometric relationship). Index
spaces of either type are created with a size (this is an
N-dimensional point for structured index spaces) and optional offset.

#### Creating an Unstructured Index Space

{% highlight regent %}
-- Unstructured space with 5 elements.
var i0 = ispace(ptr, 5)
{% endhighlight %}

#### Creating a Structured Index Space

{% highlight regent %}
-- Structured 1D space with 10 elements.
-- Elements range from 0 to 9 (inclusive).
var i1 = ispace(int1d, 10)

-- Structured 2D space of size 6x6, starting at 0,0.
-- Elements range from 0,0 to 5,5 (inclusive).
var i2 = ispace(int2d, {6, 6})

-- Same but offset by -1,-1.
-- Elements range from -1,-1 to 4,4 (inclusive).
var i2b = ispace(int2d, {6, 6}, {-1, -1})
{% endhighlight %}

#### Iterating an Index Space

{% highlight regent %}
for point in i0 do
  -- point is a ptr(i0).
end
for point in i1 do
  -- point is an int1d(i1).
end
for point in i2 do
  -- point is an int2d(i2).
end
{% endhighlight %}

#### Finding the Bounds of an Index Space

Currently this is only possible for structured index spaces:

{% highlight regent %}
i2.bounds -- Returns a rect2d.
i2.bounds.lo -- Returns lower corner of the rectangle.
i2.bounds.hi -- Returns upper corner.
{% endhighlight %}

#### Finding the Volume of an Index Space

{% highlight regent %}
i0.volume -- Returns 5.
i1.volume -- Returns 10.
i2.volume -- Returns 36.
{% endhighlight %}

## Regions

Regions are the cross-product between an index space and a field
space. The name of the region exists in the scope of the declaration,
so recursive data types may refer to the region being defined.

#### Creating a Region

{% highlight regent %}
var r0 = region(i0, int)                       -- A region of ints on index space i0.
var r1 = region(ispace(ptr, 5), list_node(r1)) -- A linked list with 5 elements.
var r2 = region(i2, grid_point)                -- A 2D region of grid_points.
{% endhighlight %}

#### Iterating a Region

{% highlight regent %}
for point in r0 do
  -- point is a ptr(int, r0).
end
for point in r1 do
  -- point is a ptr(list_node(r1), r1).
end
for point in r2 do
  -- point is a int2d(grid_point, r2).
end
{% endhighlight %}

#### Finding the Index Space of a Region

{% highlight regent %}
r0.ispace -- Returns i0.
r1.ispace -- Returns an anonymous unstructured index space of size 5.
r2.ispace -- Returns i2.
{% endhighlight %}

#### Finding the Bounds of a Region

{% highlight regent %}
r2.bounds -- Returns i2.bounds.
{% endhighlight %}

## Partitions

Partitions subdivide regions into subregions, in order to more
precisely specify the data used by tasks and to enable
parallelism. Partitions in Regent may be:

  * `disjoint` or `aliased`.
      * `disjoint` subregions are non-overlapping, and therefore can
        be safely modified in parallel.
      * `aliased` subregions are permitted to overlap, but can only be
        used in parallel with `reads` or `reduces` privileges.
      * A partition is `disjoint` **IFF** all of its subregions are
        mutually disjoint.
      * Several partition operators allow disjointness to be specified
        optionally; if it is not specified, it will be computed at
        runtime.
  * `complete` or `incomplete`.
      * `complete` partitions cover their parent region (i.e., the
        union of the all the subregions is equal to the parent
        region). This is useful for several optimizations, though it
        does not impact parallelism.
      * `incomplete` partitions do not cover their parent region.
      * Specifying completeness is always optional; if it is not
        specified, it will be computed at runtime.
  * Dense or sparse.
      * Dense subregions consist of a single contiguous rectangle of
        elements.
      * Sparse subregions may consist of arbitrary sets of elements
        within the original region.

Subregions should be thought of as views onto the original
region. They do not contain their own data but instead reference the
data contained by the parent region.

A given region can be partitioned multiple times, and the subregions
can be partitioned recursively into finer regions.

The subregions of a partition are identified by points in a special
index space called a *color space*. Subregions can be retrieved by
their color within the partition.

Regent provides a very expressive sub-language of [partition
operators](#partition-operators) for creating partitions, described in
more detail below.

#### Creating a Partition

{% highlight regent %}
var c0 = ispace(int1d, 3)
var p0 = partition(equal, r0, c0)
{% endhighlight %}

#### Iterating the Subregions of a Partition

{% highlight regent %}
for c in c0 do
  p0[c] -- Returns a subregion of r0 with color c.
end
{% endhighlight %}

#### Finding the Color Space of a Partition

{% highlight regent %}
p0.colors -- Returns c0.
{% endhighlight %}

#### Passing a Partition to a Task

To pass a partition to a task, declare the region which is the parent
of the partition first, so that the region variable can be used to
define the partition type:

{% highlight regent %}
task f(r : region(int), p : partition(disjoint, r, ispace(int1d)))
{% endhighlight %}

Note that `r` is referred to in the type of `p` so that the compiler
can determine what region `p` is a partition of.

## Partition Operators

#### Equal

Produces roughly equal subregions, one for each color in the supplied
color space. The resulting partition is guaranteed to be disjoint. If
the size of the color space is evenly divisible by the requested number
of subregions then they will be of equal size and contiguous---otherwise
the exact way in which the remaining elements are partitioned is unspecified.

{% highlight regent %}
var p = partition(equal, r, color_space)
{% endhighlight %}

Equal partitons are always disjoint and complete by construction, so
there is not need to specify this explicitly.

#### By Field

Partitions a region based on a coloring stored in a field of the
region. The resulting partition is guaranteed to be disjoint.

{% highlight regent %}
var p = partition(r.color_field, color_space)
{% endhighlight %}

Partitions by field are always disjoint by construction, so this need
not be specified. They are **NOT** always complete, as the color space
may not cover all of the values of the color field (and therefore some
points may not be inclued in the final partition). If the user wishes
to specify that the partition is complete (i.e., that all color field
values are in the color space), then this can be accomplished with an
optional `complete` keyword:

{% highlight regent %}
var p2 = partition(complete, r.color_field, color_space)
{% endhighlight %}

#### Image

Partitions a region by computing the image of each of the subregions
of a partition through the supplied (pointer-typed) field of a
region. The resulting partition is **NOT** guaranteed to be disjoint.

{% highlight regent %}
var p = image(parent_region, source_partition, data_region.field)
{% endhighlight %}

Disjointness and completeness can be specified via optional
`disjoint`/`complete` keywords:

{% highlight regent %}
var p2 = image(disjoint, parent_region, source_partition, data_region.field)
var p3 = image(disjoint, complete, parent_region, source_partition, data_region.field)
{% endhighlight %}

#### Preimage

Partitions a region by computing the preimage of each of the
subregions of a partition through the supplied (pointer-typed) field
of a region. The resulting partition is guaranteed to be disjoint
**IF** the supplied target partition is disjoint.

{% highlight regent %}
var p = preimage(parent_region, target_partition, data_region.field)
{% endhighlight %}

Disjointness and completeness can be specified via optional
`disjoint`/`complete` keywords:

{% highlight regent %}
var p2 = preimage(disjoint, parent_region, target_partition, data_region.field)
var p3 = preimage(disjoint, complete, parent_region, target_partition, data_region.field)
{% endhighlight %}

#### Union

Computes the zipped union of the subregions in the supplied
partitions. The resulting partition is **NOT** guaranteed to be
disjoint.

{% highlight regent %}
var p = lhs_partition | rhs_partition
{% endhighlight %}

This can be thought to be equivalent to setting each subregion `p[i]`
to be equal to `lhs_partition[i] | rhs_partition[i]`.

#### Intersection

Computes the zipped intersection of the subregions in the supplied
partitions. The resulting partition is guaranteed to be disjoint
**IF** either or both of the arguments are disjoint.

{% highlight regent %}
var p = lhs_partition & rhs_partition
{% endhighlight %}

This can be thought to be equivalent to setting each subregion `p[i]`
to be equal to `lhs_partition[i] & rhs_partition[i]`.

#### Difference

Computes the zipped difference of the subregions in the supplied
partitions. The resulting partition is guaranteed to be disjoint
**IF** the left-hand-side partition is disjoint.

{% highlight regent %}
var p = lhs_partition - rhs_partition
{% endhighlight %}

This can be thought to be equivalent to setting each subregion `p[i]`
to be equal to `lhs_partition[i] - rhs_partition[i]`.

## Cross Products

A cross product is defined by two or more partitions of the same underlying region
and creates intersections of the sub-regions of these partitions in a natural way.

Consider a general cross product of `N` partitions `cp = cross_product(p1, p2, ..., pN)`.
The expression `cp[i1][i2]...[iN]` returns a partition where each sub-region is
`p1[i1] & p2[i2] & ... & pN[iN]`, where `&` is the partition intersection operator.
Note that each index `iK` must be valid for the corresponding partition `pK`,
and that empty intersections are allowed.


{% highlight regent %}
var r = region(ispace(int1d), 10)
var p = partition(equal, r, ispace(int1d, 2))
var q = partition(equal, r, ispace(int1d, 5))
var cp = cross_product(p, q)
{% endhighlight %}


# Annotations

Annotations can be applied to tasks, statements, or expressions and
control the optimizations applied by the Regent compiler to the
code. Annotations come in two basic flavors:

  * `__demand` requests that the compiler throw an error if an
    optimization cannot be applied.
  * `__forbid` requires that the compiler not apply an optimization.

Note that in contrast to pragmas in languages like C++, annotations
cannot be used to force the compiler to optimize code when it is not
safe to do so. Instead, the effect of the `__demand` annotation is to
force the compiler to issue an error if a given optimization cannot be
applied. Thus, it is better to think of annotations as a defensive
programming feature that allows the programmer to sanity check that
the compiler is behaving as expected, rather than as a way to enable
or force optimizations.

In some cases, annotations labeled as "experimental" may deviate from
this behavior. These are described in a separate [section
below](#experimental-annotations).

## Task Annotations

#### Leaf Optimization

The `__leaf` annotation indicates that a task will not call any
subtasks, copies, fills, or create regions or partitions. In certain
cases such tasks can be executed more efficiently.

{% highlight regent %}
__demand(__leaf)
task f()
  ... -- This task will be marked as a leaf task.
end

__forbid(__leaf)
task g()
  ... -- This task will NOT be marked as a leaf task.
end
{% endhighlight %}

#### Inner Optimization

The `__inner` annotation indicates that a task will not directly
access the contents of any regions. In certain cases such tasks can be
executed more efficiently.

{% highlight regent %}
__demand(__inner)
task f()
  ... -- This task will be marked as a inner task.
end

__forbid(__inner)
task g()
  ... -- This task will NOT be marked as a inner task.
end
{% endhighlight %}

#### Idempotent Optimization

The `__idempotent` annotation indicates that a task will not perform
I/O or any other action with externally-visible side effects. (Writing
to regions is ok.) Currently this annotation has no effect, but will
be used to enable optimizations in the future.

{% highlight regent %}
__demand(__idempotent)
task f()
  ... -- This task will be marked as an idempotent task.
end

__forbid(__idempotent)
task g()
  ... -- This task will NOT be marked as an idempotent task.
end
{% endhighlight %}

#### Replicable Optimization

The `__replicable` annotation indicates that a task is *control
deterministic*, i.e. that all tasks (and other operations) are issued
with the same arguments. Idempotent tasks are replicable by
definition, but a task need not be idempotent to be
replicable. Currently this annotation has effect only in the
`control_replication` branch of Legion, where it enables dynamic
control replication.

{% highlight regent %}
__demand(__replicable)
task f()
  ... -- This task will be marked as an replicable task.
end

__forbid(__replicable)
task g()
  ... -- This task will NOT be marked as an replicable task.
end
{% endhighlight %}

#### Inline Optimization

The `__inline` annotation indicates that calls to the marked task must
(or must not) be inlined into the caller, and will cause the compiler
to issue an error if this is not possible.

{% highlight regent %}
__demand(__inline)
task f()
  ... -- The compiler will throw an error if it is not possible to inline this task.
end

__forbid(__inline)
task g()
  ... -- This task will NOT be inlined.
end
{% endhighlight %}

## Statement Annotations

#### Index Launch Optimization

The `__index_launch` annotation on a `for` loop indicates that the marked
loop must be converted into an index launch, and will cause the
compiler to issue an error if this is not possible. Index launches of
tasks can be analyzed in `O(1)` time instead of `O(N)` for `N` tasks.

{% highlight regent %}
__demand(__index_launch)
for i in is do
  f(p[i]) -- The compiler will throw an error if this loop cannot be converted into an index launch.
end

__forbid(__index_launch)
for i in is do
  f(p[i]) -- This loop will NOT be converted into an index launch.
end
{% endhighlight %}

#### Vectorization

The `__vectorize` annotation on a `for` loop indicates that the marked
loop must be vectorized, and will cause the compiler to issue an error
if this is not possible.

{% highlight regent %}
__demand(__vectorize)
for i in is do
  ... -- The compiler will throw an error if this loop cannot be vectorized.
end

__forbid(__vectorize)
for i in is do
  f(p[i]) -- This loop will NOT be vectorized.
end
{% endhighlight %}

## Expression Annotations

#### Inline Optimization

The `__inline` annotation on a task call expression indicates that the
marked call must (or must not) be inlined into the caller, and will
cause the compiler to issue an error if this is not possible. This
annotation overrides any `__inline` annotations on the called task.

{% highlight regent %}
__demand(__inline, f(...)) -- The compiler will throw an error if this call cannot be inlined.

__forbid(__inline, f(...)) -- This call will NOT be inlined.
{% endhighlight %}

## Experimental Annotations

#### SPMD Optimization

The `__spmd` annotation on a loop or block indicates that the marked
loop or block must be optimized with *static control replication*, an
optimization described [in this
paper](https://legion.stanford.edu/pdfs/cr2017.pdf). Control
replicated programs are substantially more scalable than non-control
replicated programs.

Currently the Regent compiler consider *only* statements marked with
this annotation for the optimization.

{% highlight regent %}
__demand(__spmd)
for t = 0, t_final do
  for i in is do
    f(p[i])
  end
  for i in is do
    g(q[i])
  end
end
{% endhighlight %}

This annotation can be used in conjunction with the `__trace`
optimization via `__demand(__spmd, __trace)`.

#### Trace Optimization

The `__trace` annotation on a loop indicates that the marked loop
should be traced. This is only possible when the sequence of tasks
called within the traced loop is identical on every trip through the
loop.

Currently the Regent compiler consider *only* statements marked with
this annotation for the optimization. The compiler does not currently
have the ability to check whether traced loops are valid (i.e., will
always execute the same sequence of tasks), so invalid loops will
result in a runtime error.

This annotation can be used in conjunction with the `__spmd`
optimization via `__demand(__spmd, __trace)`.

{% highlight regent %}
__demand(__trace)
for t = 0, t_final do
  for i in is do
    f(p[i])
  end
  for i in is do
    g(q[i])
  end
end
{% endhighlight %}

Note that this will traces the *inside* of the loop. That is, the
above code is more or less equivalent to:

{% highlight regent %}
for t = 0, t_final do
  begin_trace(...)
  for i in is do
    f(p[i])
  end
  for i in is do
    g(q[i])
  end
  end_trace(...)
end
{% endhighlight %}

If you would like to trace an arbitrary block of code (instead of a
loop), this can be accomplished with:

{% highlight regent %}
__demand(__trace)
do
  ...
end
{% endhighlight %}

#### CUDA Code Generation

The `__cuda` annotation on a task indicates that the marked task
should be considered for CUDA code generation. Any loops over regions
inside the marked task must not contain loop-carried dependencies
except for reductions via commutative and associative operators.

Currently the Regent compiler consider *only* statements marked with
this annotation for the optimization.

{% highlight regent %}
__demand(__cuda)
task h()
  ...
end
{% endhighlight %}

#### OpenMP Code Generation

The `__openmp` annotation on a `for` loop indicates that the marked
loop should be considered for OpenMP code generation. The loop must
not contain loop-carried dependencies except for reductions via
commutative and associative operators.

Currently the Regent compiler consider *only* statements marked with
this annotation for the optimization.

{% highlight regent %}
__demand(__openmp)
for i in is do
  ...
end
{% endhighlight %}

#### Auto-Parallelizer

The `__parallel` annotation on a task indicates that the task should
be considered for auto-parallelization. Any loops over regions inside
the marked task must not contain loop-carried dependencies except for
reductions via commutative and associative operators.

{% highlight regent %}
__demand(__parallel)
task h()
  ...
end
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

## Calling the Legion C API

In some cases, it can be useful to call to call Legion APIs
directly. These work the same as any other C function. As a
convenience, Regent exposes a standard set of headers via the variable
`regentlib.c`. This corresponds to the Legion header file
`legion_c.h`.

Certain Legion API calls may require a runtime and/or context. These
can be obtained in Regent via the operators `__runtime()` and
`__context()`. A full list of [operators to obtain C API object
handles](#operators-to-obtain-c-api-object-handles) is available
below.

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

## Obtaining C API Handles from Regent Values

  * `__runtime()` returns the Legion runtime (`legion_runtime_t`).
  * `__context()` returns the Legion context (`legion_context_t`).
  * `__physical(r.{f, g, ...})` returns an array of physical regions
    (`legion_physical_region_t`) for `r`, one per field, for fields `f`, `g`, etc. in the order
    that the fields are listed in the call.
  * `__fields(r.{f, g, ...})` returns an array of the field IDs
    (`legion_field_id_t`) of `r`, one per field, for fields `f`, `g`, etc. in the order
    that the fields are listed in the call.
  * `__raw(r)` returns the C API object handle that corresponds to the
    given object, e.g. a `legion_logical_region_t` for a region or
    `legion_logical_partition_t` for a partition.

## Importing C API Handles into Regent

The operators below can be used to import C API handles for objects
created in C/C++ so that they can be used in Regent.

**Important:** C API handles can only be imported once into
Regent. Subsequent attempts to import C API handles will fail. All
objects created by Regent are considered to be already imported and
thus cannot be imported again using this mechanism. These restrictions
guarantee that certain assumptions made by the Regent compiler are
not violated, and are critical to ensuring that Regent's type checker
and optimizer work correctly.

#### Importing Index Spaces

{% highlight regent %}
var is = __import_ispace(int3d, raw_ispace)
{% endhighlight %}

`raw_ispace` is of type `legion_index_space_t`.

#### Importing Regions

{% highlight regent %}
var r = __import_region(is, fs, raw_region, raw_field_id_array)
{% endhighlight %}

`raw_region` is of type `legion_logical_region_t`.

`raw_field_id_array` is of type `legion_field_id_t[N]` where `N` is
the number of fields in field space `fs`. Field IDs are enumerated in
the same order as listed in the original field space or struct. Note
that field spaces and structs in Regent are recursively flattened,
such that the field space `fs` below contains 3 fields (`center.x`,
`center.y` and `mass`).

{% highlight regent %}
struct vec2  { x : double, y : double }
fspace fs { center : vec2, mass : double }
{% endhighlight %}

#### Importing Partitions

{% highlight regent %}
var p_disjoint = __import_partition(disjoint, r, cs, raw_partition_disjoint)
var p_aliased = __import_partition(aliased, r, cs, raw_partition_aliased)
{% endhighlight %}

`raw_partition_*` are of type `legion_logical_partition_t`.

#### Importing Cross Products

{% highlight regent %}
var cp = __import_cross_product(p, q, colors, raw_cp)
{% endhighlight %}

`p` and `q` are partitions that define the cross product,
`colors` is a `uint` array containing a color for each dimension,
and `raw_cp` is of type `legion_terra_index_cross_product_t`.

#### Importing Futures

{% highlight regent %}
var f = __future(T, x)
{% endhighlight %}

`x` is of type `legion_future_t` and `f` will have type `T`. If `-ffuture 1` is enabled, this can be automatically optimized into a Regent future.

# Standard Library

See the [documentation for the standard library](/doc).
