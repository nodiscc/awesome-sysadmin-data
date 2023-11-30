# requirements: git bash make python3-pip python3-venv
SHELL := /bin/bash
MARKDOWN_REPOSITORY = awesome-foss/awesome-sysadmin
HTML_REPOSITORY = awesome-foss/awesome-sysadmin-html

.PHONY: install # install build tools in a virtualenv
install:
	python3 -m venv .venv
	source .venv/bin/activate && \
	pip3 install wheel && \
	pip3 install --force git+https://github.com/nodiscc/hecat.git@master

.PHONY: import # import data from original list at https://github.com/awesome-foss/awesome-sysadmin
import: install
	rm -rf awesome-sysadmin && git clone --depth=1 https://github.com/awesome-foss/awesome-sysadmin
	rm -rf tags/ software/ platforms/
	mkdir -p tags/ software/ platforms/
	source .venv/bin/activate && \
	hecat --config .hecat/import.yml

.PHONY: update_metadata # update metadata from project repositories/API
update_metadata: install
	source .venv/bin/activate && \
	hecat --config .hecat/update-metadata.yml

.PHONY: awesome_lint # check data against awesome-sysadmin guidelines
awesome_lint: install
	source .venv/bin/activate && \
	hecat --config .hecat/awesome-lint.yml

.PHONY: export_markdown # render markdown export from YAML data
export_markdown: install
	rm -rf awesome-sysadmin && git clone https://github.com/awesome-foss/awesome-sysadmin
	source .venv/bin/activate && \
	hecat --config .hecat/export.yml
	cd awesome-sysadmin && git diff --color=always

.PHONY: export_html # render HTML export from YAML data (https://awesome-sysadmin.net/)
export_html:
	rm -rf awesome-sysadmin-html/ html/
	#git clone https://github.com/$(HTML_REPOSITORY)
	mkdir awesome-sysadmin-html
	mkdir html && source .venv/bin/activate && hecat --config .hecat/export-html.yml
	sed -i 's|<a href="https://github.com/pradyunsg/furo">Furo</a>|<a href="https://github.com/nodiscc/hecat/">hecat</a>, <a href="https://www.sphinx-doc.org/">sphinx</a> and <a href="https://github.com/pradyunsg/furo">furo</a>. Content under <a href="https://github.com/awesome-sysadmin/awesome-sysadmin/blob/master/LICENSE">CC-BY-SA 3.0</a> license. <a href="https://github.com/awesome-foss/awesome-sysadmin-html">Source code</a>, <a href="https://github.com/awesome-sysadmin/awesome-sysadmin">raw data</a>.|' .venv/lib/python*/site-packages/furo/theme/furo/page.html
	source .venv/bin/activate && sphinx-build -b html -c .hecat/ html/md/ html/html/
	rm -rf html/html/.buildinfo html/html/objects.inv html/html/.doctrees awesome-sysadmin-html/*
	echo "# please do not scrape this site aggressively. Source code is available at https://github.com/awesome-foss/awesome-sysadmin-html. Raw data is available at https://github.com/awesome-sysadmin/awesome-sysadmin" >| html/html/robots.txt

.PHONY: push_markdown # commit and push changes to the markdown repository
push_markdown:
	$(eval COMMIT_HASH=$(shell git rev-parse --short HEAD))
	cd awesome-sysadmin && git remote set-url origin git@github.com:$(MARKDOWN_REPOSITORY)
	cd awesome-sysadmin && git config user.name awesome-sysadmin-bot && git config user.email github-actions@github.com
	cd awesome-sysadmin && git add . && (git diff-index --quiet HEAD || git commit -m "[bot] build markdown from awesome-sysadmin $(COMMIT_HASH)")
	cd awesome-sysadmin && git push -f

.PHONY: url_check # check URLs for dead links or other connection problems
url_check:
	source .venv/bin/activate && \
	hecat --config .hecat/url-check.yml

.PHONY: authors # update the AUTHORS file
authors:
	printf "Commits|Author\n-------|---------------------------------------------------\n" > AUTHORS
	git shortlog -sne | grep -v awesome-sysadmin-bot >> AUTHORS


.PHONY: push_html # commit and push changes to the HTML site repository (amend previous commit and force-push)
push_html:
	$(eval COMMIT_HASH=$(shell git rev-parse --short HEAD))
	mv html/html/* awesome-sysadmin-html/
	cd awesome-sysadmin-html/ && git remote set-url origin git@github.com:$(HTML_REPOSITORY)
	cd awesome-sysadmin-html/ && git config user.name awesome-sysadmin-bot && git config user.email github-actions@github.com
	cd awesome-sysadmin-html/ && git add . && (git diff-index --quiet HEAD || git commit --amend -m "[bot] build HTML from awesome-sysadmin $(COMMIT_HASH)")
	cd awesome-sysadmin-html/ && git push -f


.PHONY: clean # clean temporary files
clean:
	rm -rf awesome-sysadmin/ awesome-sysadmin-html/ html/ .venv/

.PHONY: help # generate list of targets with descriptions
help:
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1	\2/' | expand -t20
