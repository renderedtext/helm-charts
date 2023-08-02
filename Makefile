GIT_REPO_OWNER=renderedtext
GIT_REPO=helm-charts
GIT_USER_EMAIL=lpinheiro@renderedtext.com
GIT_USER_NAME=Lucas Pinheiro

helm.package:
	cr package charts/*

helm.lint:
	helm lint charts/*

helm.upload:
	cr upload \
		--owner $(GIT_REPO_OWNER) \
		--git-repo $(GIT_REPO) \
		--token $$GITHUB_TOKEN \
		--skip-existing

helm.index:
	git config --global user.email "$(GIT_USER_EMAIL)"
	git config --global user.name "$(GIT_USER_NAME)"
	git remote set-url origin https://github.com/$(GIT_REPO_OWNER)/$(GIT_REPO)
	cr index \
		--owner $(GIT_REPO_OWNER) \
		--git-repo $(GIT_REPO) \
		--token $$GITHUB_TOKEN \
		--index-path . \
		--push

cr.install:
	curl -L -o /tmp/cr.tgz https://github.com/helm/chart-releaser/releases/download/v1.6.0/chart-releaser_1.6.0_linux_amd64.tar.gz
	tar -xv -C /tmp -f /tmp/cr.tgz
	sudo mv /tmp/cr /usr/local/bin/cr
