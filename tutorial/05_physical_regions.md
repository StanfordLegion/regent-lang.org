---
layout: page
title: Physical Regions
sidebar: false
highlight_first: false
permalink: /tutorial/05_physical_regions/index.html
---

Regent provides two distinct syntaxes for accessing regions.

## Iteration over regions

The loop below iterates over pointers to the elements in the region. The loop index type (which is optional and shown only for
pedagogical purposes) records both the type that the pointer points to and the region that it points to.

{% highlight regent %}
var is = ispace(int1d, 1024)
var input_lr = region(is, input)

for input_ptr : int1d(input, input_lr) in input_lr do
  (@input_ptr).x = c.drand48() -- The dereference operator @ is used to access the element.
  input_ptr.y = c.drand48() -- The dereference operator is also optional.
end
{% endhighlight %}

## Iteration over ispaces

The loop below iterates over points in the index space, and is functionally equivalent to the example above. Since the loop variable is typed on the index space rather than a region, the index access operator [] must be used to access the respective regions.

{% highlight regent %}
var is = ispace(int1d, 1024)
var input_lr = region(is, input)

for i : int1d(is) in is do -- the type declaration here too is optional
  input_lr[i].x = c.drand48()
  input_lr[i].y = c.drand48()
end
{% endhighlight %}
