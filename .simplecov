require "simplecov"
require "simplecov-cobertura"
require "simplecov-html"

SimpleCov.start do
  command_name "test:unit"
  minimum_coverage 70
  add_filter "/test/"
  formatters = [
    SimpleCov::Formatter::CoberturaFormatter,
    SimpleCov::Formatter::HTMLFormatter,
  ]
end
