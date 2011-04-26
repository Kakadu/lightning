include Makefile.include
all:
	$(MAKE) -C src

install: 
	$(OCAMLFIND) install lightning META src/lightning.cmxa src/lightning.a src/liblightning.a src/*.cmi src/*.mli 

clean: 
	$(MAKE) -C src clean

