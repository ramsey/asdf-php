fmt:
	shfmt --write .
.PHONY: fmt

fmt-check:
	shfmt --diff .
.PHONY: fmt-check

lint:
	shellcheck --shell=bash --exclude=SC1091 --external-sources --source-path="bin:lib" bin/* lib/*.bash test/bin/*.bats test/lib/*.bats
.PHONY: lint

test:
	bats test/bin test/lib
.PHONY: test

coverage:
	rm -rf ./coverage/
	bashcov -- bats test/bin test/lib
.PHONY: coverage
