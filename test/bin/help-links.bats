#!/usr/bin/env bats

@test "help.links" {
	help-links() {
		load '../../bin/help.links'
	}

	help-links
}
