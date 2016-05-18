# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

* Added a [Code of Conduct](CODE_OF_CONDUCT.md)
* Added a matrix build of 2.0, 2.1, 2.2, and 2.3 to Travis

### Changed

* Bumped the Ruby version for development to 2.3.1
* Bumped the RuboCop version for development to 0.38

### Fixed

* [#27](https://github.com/civisanalytics/swagger-diff/pull/27)
  made the Ruby 2.0+ dependency explicit
* [#32](https://github.com/civisanalytics/swagger-diff/pull/32)
  replaced the Swagger parser

## [1.0.5] - 2015-11-16

### Fixed

* [#18](https://github.com/civisanalytics/swagger-diff/pull/18)
  parse non-ref parameter schemas (`allOf`, `properties`, and `items`)

## [1.0.4] - 2015-11-11

### Fixed

* [#14](https://github.com/civisanalytics/swagger-diff/pull/14)
  allow schema definitions without properties
* [#15](https://github.com/civisanalytics/swagger-diff/pull/15)
  parse non-ref response schemas (`allOf`, `properties`, and `items`)

## [1.0.3] - 2015-11-04

### Added

* Added a default Rake task to run Rubocop and RSpec
* Added [CONTRIBUTING.md](CONTRIBUTING.md)

### Fixed

* [#8](https://github.com/civisanalytics/swagger-diff/pull/8)
  fixed parsing of header and formData parameters
* [#10](https://github.com/civisanalytics/swagger-diff/pull/10)
  detect if a parameter's location (*i.e.*, `in` value) changes

## [1.0.2] - 2015-10-08

### Fixed

* [#3](https://github.com/civisanalytics/swagger-diff/pull/3)
  treat required elements in new child parameters as backwards-compatible

## [1.0.1] - 2015-10-01

### Fixed

* [#1](https://github.com/civisanalytics/swagger-diff/pull/1)
  added missing rspec-expectations dependency

## [1.0.0] - 2015-10-01 - [YANKED]

* Initial Release

[Unreleased]: https://github.com/civisanalytics/swagger-diff/compare/v1.0.5...HEAD
[1.0.5]: https://github.com/civisanalytics/swagger-diff/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/civisanalytics/swagger-diff/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/civisanalytics/swagger-diff/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/civisanalytics/swagger-diff/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/civisanalytics/swagger-diff/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/civisanalytics/swagger-diff/commit/0f6390eedef2428e78bbd816cbb14f724543f59b
