RSpec::Matchers.define :be_compatible_with do |expected|
  match do |actual|
    diff = Swagger::Diff::Diff.new(expected, actual)
    diff.compatible?
  end

  failure_message do |actual|
    diff = Swagger::Diff::Diff.new(expected, actual)
    with = if File.exist?(expected)
             " with '#{expected}'"
           else
             ''
           end
    "expected Swagger to be compatible#{with}, found:\n#{diff.incompatibilities_message}"
  end

  failure_message_when_negated do
    "expected Swagger to be incompatible with '#{expected}'"
  end

  description do
    'be backwards-compatible with another specification'
  end
end
