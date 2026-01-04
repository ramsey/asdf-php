#!/usr/bin/env bats

@test "help.overview" {
	help-overview() {
		load '../../bin/help.overview'
	}

	help-overview
}
