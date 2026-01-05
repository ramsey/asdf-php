require "simplecov"
require "simplecov-cobertura"
require "simplecov-html"

SimpleCov.command_name "bats"
SimpleCov.minimum_coverage 70
SimpleCov.add_filter "/test/"
SimpleCov.formatters = [
  SimpleCov::Formatter::CoberturaFormatter,
  SimpleCov::Formatter::HTMLFormatter,
]
SimpleCov.start
