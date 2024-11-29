.NOTINTERMEDIATE:

PYSVGs=$(subst _dot.py,_py.svg,$(shell find docs/ -name "*_dot.py"))
PLOTLYHTMLs=$(subst .py,.html,$(shell find docs/ -name "*_plotly.py"))
doc: $(shell find . -name "*.md") ${PYSVGs} ${PLOTLYHTMLs}
	mdbook build

%_py.dot: %_dot.py docs/builders/images/common.py
	python3 $<
%.svg: %.dot
	dot -Tsvg $< -o $@
	# css can only recognize intrinsic size in px
	# https://developer.mozilla.org/en-US/docs/Glossary/Intrinsic_Size
	sed -i 's/\([0-9]\+\)pt/\1px/g' $@
%_plotly.html: %_plotly.py
	python3 $<
./docs/benchmarks/spec2006/table_plotly.html: ./docs/benchmarks/table_common.py
./docs/benchmarks/openblas/table_plotly.html: ./docs/benchmarks/table_common.py
