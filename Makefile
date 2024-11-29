.NOTINTERMEDIATE:

PYSVGs=$(subst _dot.py,_py.svg,$(shell find docs/ -name "*_dot.py"))
doc: $(shell find . -name "*.md") ${PYSVGs}
	mdbook build

%_py.dot: %_dot.py docs/builders/images/common.py
	python3 $<
%.svg: %.dot
	dot -Tsvg $< -o $@
	# css can only recognize intrinsic size in px
	# https://developer.mozilla.org/en-US/docs/Glossary/Intrinsic_Size
	sed -i 's/\([0-9]\+\)pt/\1px/g' $@
