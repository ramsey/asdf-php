require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  command_name 'Unit Tests'
  minimum_coverage 70

  add_filter %r{^/test/}

  if ENV['CI']
    formatter SimpleCov::Formatter::CoberturaFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter
    ])
  end
end
