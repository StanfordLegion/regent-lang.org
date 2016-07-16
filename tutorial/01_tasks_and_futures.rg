---
layout: page
title: Tasks and Futures
sidebar: false
highlight_first: false
permalink: /tutorial/01_tasks_and_futures/index.html
---

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

task fibonacci(n : int) : int
  if n == 0 then return 0 end
  if n == 1 then return 1 end

  var f1 = fibonacci(n - 1)
  var f2 = fibonacci(n - 2)

  return f1 + f2
end

task print_result(n : int, result : int)
  c.printf("Fibonacci(%d) = %d\n", n, result)
end

task main()
  var num_fibonacci = 7
  for i = 0, num_fibonacci do
    print_result(i, fibonacci(i))
  end
end
regentlib.start(main)
{% endhighlight %}
