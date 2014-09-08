
BIN ?= q
PREFIX ?= /usr/local

$(BIN): install
	@:

install:
	install q.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)

