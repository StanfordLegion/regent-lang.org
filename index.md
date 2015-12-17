---
layout: page
title: Regent
show_title: false
sidebar: true
highlight_first: true
---

**Regent** is an implicit parallel programming language with
sequential semantics.

{% highlight regent %}
import "regent"

fspace point { x : int, y : int, z : int }

task inc(points : region(point))
where reads writes(points.{x, y, z}) do
  for x in points do
    x.{x, y, z} += 1
  end
end

task main()
  var points = region(ispace(ptr, 5), point)
  for i = 0, 5 do new(ptr(point, points)) end
  fill(points.{x, y, z}, 0)

  var colors = ispace(ptr, 3)
  var part = partition(equal, points, colors)

  for i in colors do
    inc(part[i])
  end
end
{% endhighlight %}
