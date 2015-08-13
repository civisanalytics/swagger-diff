# Swagger::Diff

[![Build Status](https://travis-ci.org/civisanalytics/swagger-diff.svg?branch=master)](https://travis-ci.org/civisanalytics/swagger-diff)

![Swagger::Diff in action](swagger-diff.gif)

> You can tell me by the way I walk - Genesis

Swagger::Diff is a utility for comparing two different
[Swagger](http://swagger.io/) specifications.
Its intended use is to determine whether a newer API specification is
backwards-compatible with an older API specification.
It provides both an [RSpec](http://rspec.info/) matcher and helper functions
that can be used directly.
Specifications are considered backwards compatible if:

- all path and verb combinations in the old specification are present in the
  new one
- no request parameters are required in the new specification that were not
  required in the old one
- all request parameters in the old specification are present in the new one
- all request parameters in the old specification have the same type in the
  new one
- all response attributes in the old specification are present in the new one
- all response attributes in the old specification have the same type in the new
  one

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'swagger-diff'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install swagger-diff

## Usage

Swagger::Diff uses the [Swagger](https://github.com/swagger-rb/swagger-rb) gem
to parse Swagger specifications.
Specifications can be any
[supported format](https://github.com/swagger-rb/swagger-rb/tree/v0.2.3#parsing):

- the path to a file containing a Swagger specification.
  This may be local (*e.g.*, `/path/to/swagger.json`) or remote (*e.g.*,
  `http://host.domain/swagger.yml`)
- a Hash containing a parsed Swagger specification (*e.g.*, the output of
  `JSON.parse`)
- a string of JSON containing Swagger specification
- a string of YAML containing Swagger specification

### RSpec

```ruby
expect(<new>).to be_compatible_with(<old>)
```

If `new` is incompatible with `old`, the spec will fail and print a list of
backwards-incompatibilities.

### Direct Invocation

If you are not using RSpec, you can directly invoke the comparison function:

```ruby
diff = Swagger::Diff::Diff.new(<old>, <new>)
diff.compatible?
```

It will return `true` if `new` is compatible with `old`, `false` otherwise.
`#incompatibilities` will return a hash containing the incompatible endpoints,
request parameters, and response attributes; *e.g.*,

```ruby
{ endpoints: ['put /a/{}'],
  request_params: {
    'get /a/' => ['missing request param: limit (type: integer)'],
    'post /a/' => ['new required request param: extra'],
    'put /b/{}' => ['new required request param: extra']
  },
  response_attributes: {
    'post /a/' => ['missing attribute from 200 response: description (type: string)'],
    'get /a/{}' => ['missing attribute from 200 response: description (type: string)'],
    'put /b/{}' => ['missing attribute from 200 response: description (type: string)']
  }
}
```

### Command-Line

It also includes a command-line version:

```bash
$ swagger-diff <old> <new>
```

`swagger-diff` will print a list of any backwards-incompatibilities `new` has
when compared to `old`.

## Gem Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/civisanalytics/swagger-diff/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Swagger::Diff is released under the [BSD 3-Clause License](LICENSE.txt).
