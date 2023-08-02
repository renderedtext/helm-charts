PKG_LOCAL_DIR=.pkg
GIT_REPO_OWNER=renderedtext
GIT_REPO=helm-charts

helm.package:
	helm package charts/* -d $(PKG_LOCAL_DIR)

helm.lint:
	helm lint charts/*

helm.upload:
	cr upload \
		--owner $(GIT_REPO_OWNER) \
		--git-repo $(GIT_REPO) \
		--token $(GITHUB_TOKEN) \
		--package-path $(PKG_LOCAL_DIR) \
		--packages-with-index \
		--skip-existing \
		--push

helm.index:
	cr index \
		--owner $(GIT_REPO_OWNER) \
		--git-repo $(GIT_REPO) \
		--token $(GITHUB_TOKEN) \
		--package-path $(PKG_LOCAL_DIR) \
		--packages-with-index \
		--index-path . \
		--push

cr.install:
	curl -L -o /tmp/cr.tgz https://github.com/helm/chart-releaser/releases/download/v1.6.0/chart-releaser_1.6.0_linux_amd64.tar.gz
	tar -xv -C /tmp -f /tmp/cr.tgz
	mv /tmp/cr ~/bin/cr