# Deploy locally
.PHONY: local
local: ldoc build
	@echo "Result is in _site"

# Deploy to GitHub
.PHONY: github
github: local
	@if [ -d _deploy ]; then git -C _deploy pull --ff-only; else git clone -b gh-pages git@github.com:StanfordLegion/regent-lang.org.git _deploy; fi

	@if ! git -C _deploy diff-index --quiet --cached HEAD --; then echo "The _deploy directory has staged (uncommitted) files, please resolve"; exit 1; fi
	@if ! git -C _deploy diff-files --quiet; then echo "The _deploy directory has dirty files, please resolve"; exit 1; fi
	@if git -C _deploy ls-files --others --error-unmatch . 1> /dev/null 2> /dev/null; then echo "The _deploy directory has untracked files, please resolve"; exit 1; fi

	rsync --recursive --delete \
	--exclude .git \
	--exclude .nojekyll \
	--exclude CNAME \
	_site/ _deploy/

	git -C _deploy add -A .
	git -C _deploy commit --message "Deploy $(shell date)."
	git -C _deploy push

.PHONY: ldoc
ldoc: legion
	cd _legion/language && luarocks/install/bin/ldoc .
	rm -rf doc
	mv _legion/language/doc .

.PHONY: legion
legion:
	@if [ -d _legion ]; then git -C _legion pull --ff-only; else git clone -b master https://gitlab.com/StanfordLegion/legion.git _legion; fi
	@if [ ! -d _legion/language/terra ]; then _legion/language/install.py --rdir=auto; fi

.PHONY: build
build:
	bundle exec jekyll build

.PHONY: serve
serve: ldoc
	bundle exec jekyll serve --watch
