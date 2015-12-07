---
layout: page
title: Language Reference
sidebar: false
highlight_first: false
permalink: /reference/index.html
---

# Frontmatter

Regent is implemented as a [Terra](http://terralang.org) language
extension. Every Regent source file must therefore start with:

{% highlight regent %}
import "regent"
{% endhighlight %}

This loads the Regent compiler and enables hooks to start Regent on
certain keywords (`task` and `fspace`).

# Execution Model

## Tasks

Tasks are the fundamental unit of execution in Regent. Tasks are
similar to functions in most other programming languages: tasks take
arguments and (optionally) return a value, and contain a body of
statements which compute the result of the task. Unlike traditional
functions, tasks must explicitly specify any interactions with the
calling context through *privileges*, *coherence modes*, and
*constraints*.

{% highlight regent %}
task f(a0 : t0, a1 : t1, ..., aN : tN)
  ...
end
task f(a0 : t0, a1 : t1, ..., aN : tN) : return_type
  ...
end
task f(a0 : t0, a1 : t1, ..., aN : tN) : return_type
where <privileges, coherence modes and constraints> do
  ...
end
{% endhighlight %}

## Privileges

Privileges how the task will interact with the arguments it is
passed. For example, `reads` is required in order to read from a
region taken as an argument, and `writes` is required to write a
region. Reductions allow the application of certain commutative
operators to regions. Note that privileges in general apply only to
container types such as regions, and not immediate arguments passed
by-value (such as `int`, `float`, and `ptr` data types).

{% highlight regent %}
reads(r)
writes(r)
reduces <op>(r) for op in +, *, -, /, min, max
{% endhighlight %}

## Coherence Modes

Coherence modes specify a task's expectations of isolation with
respect to sibling tasks. Regent supports four coherence modes:

{% highlight regent %}
exclusive(r)
atomic(r)
simultaneous(r)
relaxed(r)
{% endhighlight %}

  * `exclusive` mode (the default) guarrantees that the code will
    execute in a manner consistent with a sequential execution of the
    code.

  * `atomic` mode allows marked tasks to be reordered, similar to a
    transation-based system. However, only one task will run (on a
    given region) at a time.

  * `simultaneous` mode allows marked tasks to run concurrently as
    long as they use the same physical instance for all simultaneous
    regions. This guarrantees that the regions in question behave with
    shared memory semantics, as in pthreads, etc.

  * `relaxed` mode allows marked tasks to run concurrently with no
    restrictions. It is up to the user to provide appropriate
    synchronization.

## Constraints

Constraints specify the desired relationships between
regions. Constraints are checked at compile time and must be satisfied
by the caller. The supported constraints are disjointness (`*`) and
subregion (`<=`).

{% highlight regent %}
r * s
r <= s
{% endhighlight %}

## Copies

Copy operations copy the contents of one region to another (for all or
some subset of fields). The number and types of fields so named must
match.

{% highlight regent %}
copy(r, s)
copy(r.x, s.y)
copy(r.{x, y, z}, s.{u, v, w})
{% endhighlight %}

## Fills

Fill operations replace the contents of a region (for all or some
subset of fields) with a single specified value. The type of the value
must match the named fields.

{% highlight regent %}
fill(r, v)
fill(r.x, v)
fill(r.{x, y, z}, v)
{% endhighlight %}

# Data Model

## Field Spaces

{% highlight regent %}
fspace point {
  x : int,
  y : int,
}
{% endhighlight %}

## Index Spaces

{% highlight regent %}
var is = ispace(ptr, extent)
var is = ispace(ptr, extent, start)

fspace point { x : int, y : int }
local point2d = index_type(point)
var is = ispace(point2d, extent)
var is = ispace(point2d, extent, start)
{% endhighlight %}

## Regions

{% highlight regent %}
var r = region(is, fs)
var r = region(ispace(ptr, 5), fs)
var r = region(ispace(point2d, { x : 5, y : 6 }, { x : -1, y : -1 }), fs)
{% endhighlight %}

## Partitions

{% highlight regent %}
var p = partition(r.color_field, color_space)
{% endhighlight %}
