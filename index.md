---
layout: page
title: Regent
show_title: false
sidebar: true
highlight_first: true
---

**Regent** is an implicitly parallel programming language with
sequential semantics.

{% highlight regent %}
import "regent"

fspace point { x : int, y : int, z : int, c : int }

task inc(r : region(point))
where reads writes(r.{x, y, z}) do
  for x in r do
    x.{x, y, z} += 1
  end
end

task main()
  var r = region(ispace(ptr, 5), point)
  for i = 0, 5 do new(ptr(point, r)) end
  fill(r.{x, y, z, c}, 0)

  var i = 0
  for x in r do
    x.c = i
    i += i
  end

  var colors = ispace(ptr, c, 0)
  var p = partition(r.c, colors)

  for i in colors do
    inc(p[i])
  end
end
{% endhighlight %}
