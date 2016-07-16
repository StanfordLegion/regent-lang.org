---
layout: page
title: Index Tasks
sidebar: false
highlight_first: false
permalink: /tutorial/02_index_tasks/index.html
---

## Final Code

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

task double(i : int, x : int)
  c.printf("Hello world from task %lld!\n", i)
  return 2*x
end

task main()
  var num_points = 4

  var total = 0
  __demand(__parallel)
  for i = 0, num_points do
    total += double(i, i + 10)
  end
  regentlib.assert(total == 92, "check failed")
end
regentlib.start(main)
{% endhighlight %}
