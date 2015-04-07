all:
#	vcs -full64 -v2005 -sverilog +verilog2001ext+.vp -O4 +incdir+./testbench.v ./*.v  -o ./simv
	iverilog  ./*.v ./../rtl/afifo.v ./../rtl/afifo_test.v -o ./simv
clean:
	rm -rf csrc simv simv.daidir ucli.key

run:
	./simv
