build-docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/matplotcheck.rst
	rm -f docs/modules.rst
	$(MAKE) sphinx-autodoc
	$(MAKE) -C docs clean
	$(MAKE) -C docs doctest
	$(MAKE) -C docs html
	$(MAKE) -C docs linkcheck

sphinx-autodoc:
	sphinx-apidoc -H "API reference" --no-headings --force --module-first -d 6 -o docs/ matplotcheck matplotcheck/tests
preview-docs:
	sphinx-autobuild --pre-build 'make sphinx-autodoc' docs docs/_build/html --watch matplotcheck --ignore "docs/gallery_vignettes"