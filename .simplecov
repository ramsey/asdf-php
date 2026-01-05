require "simplecov"
require "simplecov-cobertura"
require "simplecov-html"

SimpleCov.start do
  command_name "test:unit"
  coverage_dir "coverage"
  minimum_coverage 70
  add_filter "/test/"
  track_files "{bin,lib}/**/*"
  formatters = [
    SimpleCov::Formatter::CoberturaFormatter,
    SimpleCov::Formatter::HTMLFormatter,
  ]
end
