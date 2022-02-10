---
layout: page
title: "Regent: a Language for Implicit Task-based Parallelism"
show_title: false
sidebar: true
highlight_first: true
---

**Regent** is a language for implicit task-based parallelism.

Regent automatically discovers parallelism in programs composed of
*tasks*, or functions. Tasks execute sequentially. Behind the scenes,
Regent looks at the arguments to tasks, along with the ways tasks
touch their arguments (read, write, etc.) to determine which tasks can
execute in parallel. That means you can write code like this:

{% highlight regent %}
-- Launch a task with some data.
a(data) -- writes data

-- Launch three b tasks.
-- Each data_part is a view onto a different piece of the original data.
for i = 0, 3 do
  task_b(data_part[i]) -- reads/writes the field x of data
end

-- Launch c task.
c(data) -- reads/writes the field y of data

-- Launch three d tasks.
for i = 0, 3 do
  d(data_part[i]) -- reads data
end
{% endhighlight %}

And Regent will automatically discover that this parallelism is
available:

<img src="{{ site.baseurl }}/images/frontpage.svg" class="center-block">

<p class="lead">Interested in learning more? <a href="install">Install Regent</a> and checkout the <a href="tutorial">tutorials</a>.</p>
