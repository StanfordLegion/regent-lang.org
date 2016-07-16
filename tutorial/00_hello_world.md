---
layout: page
title: Hello World
sidebar: false
highlight_first: false
permalink: /tutorial/00_hello_world/index.html
---

{% highlight regent %}
import "regent"

local c = terralib.includec("stdio.h")

task hello_world()
  c.printf("Hello World!\n")
end

task main()
  hello_world()
end
regentlib.start(main)
{% endhighlight %}
