# Change Log

## 1.0.3 (2015-11-04)

### Changes

* Added a default Rake task to run Rubocop and RSpec
* Added [CONTRIBUTING.md](CONTRIBUTING.md)

### Bugs Fixed

* [#8](https://github.com/civisanalytics/swagger-diff/pull/8)
  fixed parsing of header and formData parameters
* [#10](https://github.com/civisanalytics/swagger-diff/pull/10)
  detect if a parameter's location (*i.e.*, `in` value) changes

## 1.0.2 (2015-10-08)

### Bugs Fixed

* [#3](https://github.com/civisanalytics/swagger-diff/pull/3)
  treat required elements in new child parameters as backwards-compatible

## 1.0.1 (2015-10-01)

### Bugs Fixed

* [#1](https://github.com/civisanalytics/swagger-diff/pull/1)
  added missing rspec-expectations dependency

## 1.0.0 (2015-10-01)

* Initial Release
