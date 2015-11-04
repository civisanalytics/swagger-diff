require 'spec_helper'

describe RSpec::Matchers do
  describe 'be_compatible_with' do
    it do
      expect('spec/fixtures/petstore-with-external-docs.json')
        .to be_compatible_with('spec/fixtures/petstore.json')
    end

    it do
      expect('spec/fixtures/dummy.v2.json')
        .not_to be_compatible_with('spec/fixtures/dummy.v1.json')
    end

    it 'should raise Exception with details when incompatible' do
      msg = <<-EOM
expected Swagger to be compatible with 'spec/fixtures/dummy.v1.json', found:
- missing endpoints
  - post /b/
  - put /a/{}
- incompatible request params
  - get /a/
    - missing request param: limit (in: query, type: integer)
  - patch /a/{}
    - missing request param: name (in: body, type: ["string", "null"])
    - missing request param: obj/thing (in: body, type: integer)
    - missing request param: str (in: body, type: string)
  - post /a/
    - new required request param: extra
  - post /c/
    - new required request param: existing/b
  - put /b/{}
    - new required request param: extra
- incompatible response attributes
  - get /a/{}
    - missing attribute from 200 response: description (in: body, type: string)
  - get /c/
    - missing attribute from 200 response: []/name (in: body, type: string)
    - missing 201 response
  - patch /a/{}
    - missing attribute from 200 response: obj/thing (in: body, type: integer)
    - missing attribute from 200 response: objs[]/thing (in: body, type: integer)
  - post /a/
    - missing attribute from 200 response: description (in: body, type: string)
  - put /b/{}
    - missing attribute from 200 response: description (in: body, type: string)
      EOM
      expect do
        expect('spec/fixtures/dummy.v2.json')
          .to be_compatible_with('spec/fixtures/dummy.v1.json')
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, msg)
    end

    it 'should raise Exception without contents when incompatible' do
      msg = 'expected Swagger to be compatible, found:'
      expected = File.open('spec/fixtures/dummy.v1.json').read
      expect do
        expect('spec/fixtures/dummy.v2.json').to be_compatible_with(expected)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, /#{msg}/)
    end

    it 'should raise Exception when not incompatible' do
      msg = "expected Swagger to be incompatible with 'spec/fixtures/petstore.json'"
      expect do
        expect('spec/fixtures/petstore-with-external-docs.json')
          .not_to be_compatible_with('spec/fixtures/petstore.json')
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError, msg)
    end
  end
end
