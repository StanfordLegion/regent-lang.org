---
layout: page
title: Logical Regions
sidebar: false
highlight_first: false
permalink: /tutorial/04_logical_regions/index.html
---

## Field spaces

Field spaces are sets of fields, and behave similarly to structs in C or Terra.

{% highlight regent %}
fspace fs {
  a : double,
  {b, c, d} : int, -- Multiple fields may be declared with a single type.
}
{% endhighlight %}

Field spaces may also be instantiated by casting an anonymous struct to the appropriate type.

{% highlight regent %}
task make_fs(w : double, x : int, y : int, z : int) : fs
  var obj = fs { a = w, b = x, c = y, d = z } -- Define a local variable of type fs.
  return obj
end
{% endhighlight %}

Field spaces differ from structs in that they may also take region-typed arguments.

{% highlight regent %}
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
{% endhighlight %}

## Index spaces

An index space (ispace) is a collection in index points. Regent has two kinds of index spaces: structured and unstructured.

An unstructured ispace is a collection of opaque points, useful for pointer data structures such as graphs, trees, linked lists, and unstructured meshes.

{% highlight regent %}
var unstructured_is = ispace(ptr, 1024) -- Create an ispace with 1024 elements.
{% endhighlight %}

A structured ispace is a (multi-dimensional) rectangle of points.

{% highlight regent %}
var i1 = ispace(int1d, 1024, 0) -- Create an ispace including the 1-dimensional ints from 0 to 1023.
var i2 = ispace(int2d, { x = 4, y = 4 }, { x = 1, y = 1 }) -- 2-dimensional 4x4 rectangle with indices starting at 1,1.
{% endhighlight %}

## Regions

Regions are the cross-product between an index space and a field space.

{% highlight regent %}
var unstructured_lr = region(unstructured_is, fs)
var structured_lr = region(structured_is, fs)
{% endhighlight %}

Note that you can create multiple regions with the same index space and field space. This is a new region, distinct from structured_lr above.

{% highlight regent %}
var other_structured_lr = region(structured_is, fs)
{% endhighlight %}

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
