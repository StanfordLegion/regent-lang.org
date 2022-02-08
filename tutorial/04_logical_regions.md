---
layout: page
title: Logical Regions
sidebar: false
highlight_first: false
permalink: /tutorial/04_logical_regions/index.html
---

We now come to one of the central abstractions for data in Regent,
*logical regions* (or just "regions" for short). As hinted in earlier
tutorials, regions allow mutable data to be used (safely) within
Regent. Idiomatic Regent programs usually store most or all of their
data in regions.

At their most basic, regions are like arrays of structs in a language
like C. The main differences are that regions are not fixed to a
single memory allocation, but can seamlessly move around a distributed
machine, be copied down to the GPU, etc. In most cases, this happens
without any specific user intervention, and users need only be
concerned with what data is placed in regions and how that data is
used.

Regions consist of a *field space* (like a C struct) and an *index
space*. The latter doesn't have a first-class analog in C, but is
conceptually the set of indices used to refer to elements within a
region (like indices in an array). Each of these components is
described in more detail below.

## Field Spaces

A field space (fspace) works much like a struct in C. The following
code declares a field space with four fields:

{% highlight regent %}
fspace fs {
  a : double,
  b : int,
  c : int,
  d : int,
}
{% endhighlight %}

As a convenience, multiple, consecutive fields with the same type may
be collapsed into a single line. The code below is identical to the
version above:

{% highlight regent %}
fspace fs {
  a : double,
  {b, c, d} : int, -- Multiple fields may be declared with a single type.
}
{% endhighlight %}

In Regent code, `fs` names a type (the type of the field space), and
can be instantiated to create values of this type. For example, the
following code defines a variable `x` of type `fs`:

{% highlight regent %}
var x = fs { a = 3.14, b = 4, c = 5, c = 6 }
{% endhighlight %}

Values of field spaces can be used like any other type: they can be
passed (by-value) to tasks, returned from tasks, modified, etc. To
access the individual elements of a field space, use the `.` (dot)
operator.

{% highlight regent %}
task sum_fs(x : fs)
  return x.a + x.b + x.c + x.d
end

task update_fs(x : fs)
  var y = x
  y.a += 1.25
  y.b = y.c * y.d
  return y
end
{% endhighlight %}

There is also a syntax to unpack multiple values of a field space at
the same time. The example below creates 4 new variables, `a`, `b`,
`c`, and `d` with the values of `x.a`, `x.b`, `x.c`, and `x.d`.

{% highlight regent %}
var {a, b, c, d} = x -- where x is of type fs
{% endhighlight %}

This syntax also supports creating variables with different names, if
that is desired. In the code below, `x_a` and so on name the new
variables, `a` etc. name the fields of the field space to be unpacked.

{% highlight regent %}
var {x_a = a, x_b = b, x_c = c, x_d = d} = x -- where x is of type fs
{% endhighlight %}

## Index Spaces

An index space (ispace) is a collection of index points. This is most
directly analogous to the set of valid array indices for an array in
C. While the latter is not a first-class feature of C, index spaces
are first-class objects in Regent and can be created dynamically,
passed to tasks and returned from tasks.

The example below creates a 1-D index space with 1024 elements. This
would be similar to `int[1024]` in C, except an index space refers to
the set of valid indices only and contains no actual data.

{% highlight regent %}
var is = ispace(int1d, 1024)
{% endhighlight %}

Index spaces can be passed to and returned from tasks:

{% highlight regent %}
task take_is(is : ispace(int1d))
end

task make_is(n : int)
  var is = ispace(int1d, n)
  return is
end
{% endhighlight %}

Index spaces can also be iterated. The code below executes 1024
iterations, for the values `0` through `1023`.

{% highlight regent %}
var is = ispace(int1d, 1024)
for x in is do
  -- x takes the values 0, ... 1023
end
{% endhighlight %}

### Index Space Bounds

One notable difference between index spaces and C arrays is that index
spaces need not start at 0. The following index space contains the
elements, `-1`, `0`, `1`, ... `10`.

{% highlight regent %}
var is = ispace(int1d, 12, -1)
{% endhighlight %}

In its most general form, the arguments to the `ispace` operator are
as follows:

 1. The type of the index (e.g., `int1d`).

 2. The extent (size) of the index space (e.g., `12` indicates it
    contains 12 elements).

 3. The offset (start) of the index space (e.g., `-1` indicates the
    first element starts at index &minus;1).

Index spaces support two operators, `.bounds` and `.volume`, to
retrieve the bounding rectangle and volume of the index space,
respectively.

{% highlight regent %}
is.bounds -- returns rect1d { lo = int1d(-1), hi = int1d(10) }
is.volume -- returns 12
{% endhighlight %}

### Multi-dimensional Index Spaces

Index spaces are not restricted to 1 dimension. Regent supports up to
9 dimensions, though for dimensions above 3, Regent must be recompiled
with the appropriate support (set `MAX_DIM=N` when building). Regent
provides a set of built-in index types for each of these dimensions:
`int1d`, `int2d`, `int3d`, etc. up to `int9d` (if compiled with the
right support).

`int1d` is a special case in that it corresponds directly into an
`int`. For the other cases, each `intNd` is actually a field space
with `N` fields. These fields always take the following ordering: `x`,
`y`, `z`, `w`, `v`, `u`, `t`, `s`, `r`.

Because `intNd` types are field spaces, their elements can be accessed
with the usual field space syntax.

{% highlight regent %}
task sum_coordinates(i : int4d)
  return i.x + i.y + i.z + i.w
end

task make_coordinate(a : int, b : int, c : int, d : int)
  -- field names are matched positionally when unspecified
  return int4d { a, b, c, d }
end
{% endhighlight %}

Index spaces can be created from multi-dimensional index types. In
this case, the extent specifies the upper-rectangular corner of a
bounding box, and the offset shifts the box by the specified
amount. The offset is zero by default. Some examples are shown below:

{% highlight regent %}
var is1 = ispace(int1d, 10) -- [0, 1, ... 9]
var is2 = ispace(int2d, {4, 4}) -- [{0, 0}, {0, 1}, ... {0, 3}, ... {3, 3}]
var is3 = ispace(int3d, {5, 5, 5}, {1, 2, 3}) -- [{1, 2, 3}, ... {5, 6, 7}]
{% endhighlight %}

### "Unstructured" Index Spaces

For historical reasons, Regent supports a notion of an "unstructured"
index space via the index type `ptr`. It is functionally equivalent to
`int1d` in all respects and is being maintained for backwards
compatibility only. Most programs can use `int1d` instead with no
negative consequences.

### Sparse Index Spaces

In general, index spaces need not be dense rectangles. Regent does not
provide a syntax to directly create a sparse index space, but they can
be created via partitioning, a feature discussed in a later tutorial.

## Regions

Regions take a field space and an index space and put them together to
get a data structure that is similar to an array in C. Here's an
example, using the `fs` field space from earlier:

{% highlight regent %}
var r = region(ispace(int1d, 10), fs)
{% endhighlight %}

The index space may either be specified inline (as above) or
out-of-line. The latter allows multiple regions to be created with the
same index space (and the same or different field space).

{% highlight regent %}
var is = ispace(int1d, 10)
var s = region(is, fs)
var t = region(is, fs)
var u = region(is, int)
{% endhighlight %}

Like index spaces, regions can be iterated. One difference is that
when regions are iterated, the iteration ranges over pointers to the
elements of the region. The `@` (dereference) operator may be used on
pointers to access (read or write) the corresponding region
element. In the following loop, each element of the region `i` is
assigned the value `i+1`.

{% highlight regent %}
var r = region(ispace(int1d, 10), int)
for x in r do
  @x = int(x) + 1
end
{% endhighlight %}

In the case where the region's field space is not a primitive type
(i.e., not `int`, `double`, `float`, etc.), the `.` (dot) operator can
be used to implicitly dereference a pointer.

{% highlight regent %}
var r = region(ispace(int1d, 10), fs)
for x in r do
  x.a = 3.14
  x.b = 2
  x.c = x.b + int(x)
  x.d = x.c * x.c
end
{% endhighlight %}

### Region Typing and Assignment

Unlike other types, region variables in Regent *cannot* be assigned a
new value. This is a type error. Every region created in a region
program is given a unique type, and even if it seems compatible,
cannot be mixed with any other region in the program.

{% highlight regent %}
var is = ispace(int1d, 10)
var s = region(is, fs)
var t = region(is, fs)
s = t -- ERROR: type mismatch between region(...) and region(...)
{% endhighlight %}

These error messages can sometimes be confusing to read. To help
disambiguate the regions in an error message, use the `-fdebug 1`
flag. With the example above, this would produce something like:

{% highlight regent %}
s = t -- ERROR: type mismatch between region#1(...) and region#2(...)
{% endhighlight %}

### Region Arguments

Despite the restrictions on region assignment, regions *can* be passed
to tasks. For example, the task:

{% highlight regent %}
task take_region(r : region(ispace(int1d), fs))
end
{% endhighlight %}

Can be called as:

{% highlight regent %}
take_region(r)
{% endhighlight %}

Assuming `r` has a compatible type.

Note that regions *do* allow mutation through task arguments (in fact,
they are the only type in Regent that permits this). However, in order
to do this, tasks must explicitly declare the privileges (`reads`,
`writes`, etc.) they intend to use for their region arguments. As
written, `task_region` declares no privileges on `r` and thus would be
unable to either read or write its contents. Privileges and region
access are discussed in a future tutorial.

## Final Code

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

fspace fs {
  a : double,
  {b, c, d} : int,
}

task make_fs(w : double, x : int, y : int, z : int) : fs
  var obj = fs { a = w, b = x, c = y, d = z }
  return obj
end

fspace point {
  {x, y} : double
}

fspace edge(r : region(point)) {
 left: ptr(point, r),
 right: ptr(point, r),
}

task make_edge(points : region(point), a : ptr(point, points), b : ptr(point, points))
  return [edge(points)] { left = a, right = b }
end

task main()
  var unstructured_is = ispace(ptr, 1024)

  var structured_is = ispace(int1d, 1024, 0)

  var unstructured_lr = region(unstructured_is, fs)
  var structured_lr = region(structured_is, fs)

  var no_clone_lr = region(structured_is, fs)
end
regentlib.start(main)
{% endhighlight %}
