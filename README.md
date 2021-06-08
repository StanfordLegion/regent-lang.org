Homepage of [Regent](regent-lang.org).

# Getting Started Instructions

Install Pandoc:

```
wget https://github.com/jgm/pandoc/releases/download/2.14.0.1/pandoc-2.14.0.1-linux-amd64.tar.gz
tar xfz pandoc-2.14.0.1-linux-amd64.tar.gz
export PATH="$PWD/pandoc-2.14.0.1-linux-amd64/bin:$PATH"
```

Install RVM:

```
\curl -sSL https://get.rvm.io | bash -s stable --ruby
source $HOME/.rvm/scripts/rvm
```

Install Ruby dependencies:

```
bundle install
```

Build:

```
make github
```
