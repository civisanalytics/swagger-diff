require 'spec_helper'

describe Swagger::Diff::Diff do
  let(:compat_diff) do
    Swagger::Diff::Diff.new('spec/fixtures/petstore.json',
                            'spec/fixtures/petstore-with-external-docs.json')
  end
  let(:incompat_diff) do
    Swagger::Diff::Diff.new('spec/fixtures/dummy.v1.json',
                            'spec/fixtures/dummy.v2.json')
  end

  it '.initialize' do
    expect { compat_diff }.not_to raise_error
  end

  describe '#changes' do
    let(:compat) do
      {
        new_endpoints: ['delete /pets/{}', 'get /pets/{}', 'post /pets'],
        new_request_params: {
          'get /pets' => ['new request param: tags (in: query, type: array)',
                          'new request param: limit (in: query, type: integer)']
        },
        new_response_attributes: {},
        removed_endpoints: [],
        removed_request_params: {},
        removed_response_attributes: {}
      }
    end
    let(:incompat) do
      {
        new_endpoints: [],
        removed_endpoints: ['post /b/', 'put /a/{}'],
        new_request_params: {
          'post /a/' => ['new request param: extra (in: body, type: string)'],
          'patch /a/{}' => ['new request param: name (in: body, type: string)',
                            'new request param: obj/thing (in: body, type: string)',
                            'new request param: obj/str (in: body, type: string)'],
          'put /b/{}' => ['new request param: extra (in: body, type: string)'],
          'post /c/' => ['new request param: new/a (in: body, type: string)',
                         'new request param: new/b (in: body, type: string)']
        },
        removed_request_params: {
          'get /a/' => ['missing request param: limit (in: query, type: integer)'],
          'post /a/' => ['new required request param: extra'],
          'patch /a/{}' => ['missing request param: name (in: body, type: ["string", "null"])',
                            'missing request param: obj/thing (in: body, type: integer)',
                            'missing request param: str (in: body, type: string)'],
          'put /b/{}' => ['new required request param: extra'],
          'post /c/' => ['new required request param: existing/b']
        },
        new_response_attributes: {
          'patch /a/{}' => ['new attribute for 200 response: obj/thing (in: body, type: string)',
                            'new attribute for 200 response: obj/str (in: body, type: string)',
                            'new attribute for 200 response: objs[]/thing (in: body, type: string)',
                            'new attribute for 200 response: objs[]/str (in: body, type: string)']
        },
        removed_response_attributes: {
          'post /a/' => ['missing attribute from 200 response: description (in: body, type: string)'],
          'get /a/{}' => ['missing attribute from 200 response: description (in: body, type: string)'],
          'patch /a/{}' => ['missing attribute from 200 response: obj/thing (in: body, type: integer)',
                            'missing attribute from 200 response: objs[]/thing (in: body, type: integer)'],
          'put /b/{}' => ['missing attribute from 200 response: description (in: body, type: string)'],
          'get /c/' => ['missing attribute from 200 response: []/name (in: body, type: string)',
                        'missing 201 response']
        }
      }
    end

    it { expect(compat_diff.changes).to eq(compat) }
    it { expect(incompat_diff.changes).to eq(incompat) }
  end

  describe '#changes_message' do
    let(:compat) do
      '- new endpoints
  - delete /pets/{}
  - get /pets/{}
  - post /pets
- new request params
  - get /pets
    - new request param: tags (in: query, type: array)
    - new request param: limit (in: query, type: integer)
'
    end
    let(:incompat) do
      '- removed endpoints
  - post /b/
  - put /a/{}
- new request params
  - patch /a/{}
    - new request param: name (in: body, type: string)
    - new request param: obj/thing (in: body, type: string)
    - new request param: obj/str (in: body, type: string)
  - post /a/
    - new request param: extra (in: body, type: string)
  - post /c/
    - new request param: new/a (in: body, type: string)
    - new request param: new/b (in: body, type: string)
  - put /b/{}
    - new request param: extra (in: body, type: string)
- removed request params
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
- new response attributes
  - patch /a/{}
    - new attribute for 200 response: obj/thing (in: body, type: string)
    - new attribute for 200 response: obj/str (in: body, type: string)
    - new attribute for 200 response: objs[]/thing (in: body, type: string)
    - new attribute for 200 response: objs[]/str (in: body, type: string)
- removed response attributes
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
'
    end

    it { expect(compat_diff.changes_message).to eq(compat) }
    it { expect(incompat_diff.changes_message).to eq(incompat) }
  end

  describe '#compatible?' do
    it { expect(compat_diff.compatible?).to be true }
    it { expect(incompat_diff.compatible?).to be false }
  end

  it '#incompatibilities' do
    expect(incompat_diff.incompatibilities)
      .to eq(endpoints: ['post /b/', 'put /a/{}'],
             request_params: {
               'get /a/' => ['missing request param: limit (in: query, type: integer)'],
               'post /a/' => ['new required request param: extra'],
               'patch /a/{}' => [
                 'missing request param: name (in: body, type: ["string", "null"])',
                 'missing request param: obj/thing (in: body, type: integer)',
                 'missing request param: str (in: body, type: string)'
               ],
               'put /b/{}' => ['new required request param: extra'],
               'post /c/' => ['new required request param: existing/b']
             },
             response_attributes: {
               'post /a/' => ['missing attribute from 200 response: description (in: body, type: string)'],
               'get /a/{}' => ['missing attribute from 200 response: description (in: body, type: string)'],
               'patch /a/{}' => ['missing attribute from 200 response: obj/thing (in: body, type: integer)',
                                 'missing attribute from 200 response: objs[]/thing (in: body, type: integer)'],
               'put /b/{}' => ['missing attribute from 200 response: description (in: body, type: string)'],
               'get /c/' => ['missing attribute from 200 response: []/name (in: body, type: string)',
                             'missing 201 response']
             })
  end

  describe '#incompatibilities_message' do
    let(:incompat_msg) do
      '- missing endpoints
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
'
    end

    it { expect(compat_diff.incompatibilities_message).to eq('') }
    it { expect(incompat_diff.incompatibilities_message).to eq(incompat_msg) }
  end

  describe '#missing_endpoints' do
    it { expect(compat_diff.send(:missing_endpoints)).to eq(Set.new) }

    it do
      expect(incompat_diff.send(:missing_endpoints))
        .to eq(Set.new(['put /a/{}', 'post /b/']))
    end
  end

  describe '#endpoints_compatible?' do
    it { expect(compat_diff.send(:endpoints_compatible?)).to be true }
    it { expect(incompat_diff.send(:endpoints_compatible?)).to be false }
  end

  describe '#requests_compatible?' do
    it { expect(compat_diff.send(:requests_compatible?)).to be true }
    it { expect(incompat_diff.send(:requests_compatible?)).to be false }
  end

  describe '#responses_compatible?' do
    it { expect(compat_diff.send(:responses_compatible?)).to be true }
    it { expect(incompat_diff.send(:responses_compatible?)).to be false }
  end

  context 'with JSON' do
    let(:old_paths) { {} }
    let(:old_definitions) { {} }
    let(:old_parsed) do
      { 'swagger' => '2.0',
        'info' => { 'title' => 'Swagger Fixture', 'version' => '1.0' },
        'paths' => old_paths,
        'definitions' => old_definitions }
    end
    let(:new_paths) { {} }
    let(:new_definitions) { {} }
    let(:new_parsed) do
      { 'swagger' => '2.0',
        'info' => { 'title' => 'Swagger Fixture', 'version' => '1.0' },
        'paths' => new_paths,
        'definitions' => new_definitions }
    end
    let(:diff) { Swagger::Diff::Diff.new(old_parsed, new_parsed) }

    describe '#changes' do
      describe 'endpoint' do
        let(:paths) do
          { '/a/' =>
            { 'get' =>
              { 'responses' =>
                { '204' => {} } } } }
        end

        describe 'added' do
          let(:new_paths) { paths }

          it { expect(diff.changes[:new_endpoints]).to eq(['get /a/']) }
        end

        describe 'removed' do
          let(:old_paths) { paths }

          it { expect(diff.changes[:removed_endpoints]).to eq(['get /a/']) }
        end
      end

      describe 'parameters' do
        let(:new_paths) do
          { '/a/' =>
            { 'get' =>
              { 'parameters' => new_parameters,
                'responses' => { '204' => {} } } } }
        end
        let(:old_paths) do
          { '/a/' =>
            { 'get' =>
              { 'parameters' => old_parameters,
                'responses' => { '204' => {} } } } }
        end
        let(:new_parameters) { [] }
        let(:old_parameters) { [] }

        describe 'new, optional' do
          let(:new_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => false,
               'type' => 'string' }]
          end

          it do
            expect(diff.changes[:new_request_params])
              .to eq('get /a/' => ['new request param: x (in: query, type: string)'])
          end
        end

        describe 'new, required' do
          let(:new_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => true,
               'type' => 'string' }]
          end

          it do
            expect(diff.changes[:new_request_params])
              .to eq('get /a/' => ['new request param: x (in: query, type: string)'])
          end
        end

        describe 'removed optional' do
          let(:old_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => false,
               'type' => 'string' }]
          end

          it do
            expect(diff.changes[:removed_request_params])
              .to eq('get /a/' => ['missing request param: x (in: query, type: string)'])
          end
        end

        describe 'removed required' do
          let(:old_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => true,
               'type' => 'string' }]
          end

          it do
            expect(diff.changes[:removed_request_params])
              .to eq('get /a/' => ['missing request param: x (in: query, type: string)'])
          end
        end

        describe 'made optional required' do
          let(:new_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => true,
               'type' => 'string' }]
          end
          let(:old_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => false,
               'type' => 'string' }]
          end

          it do
            expect(diff.changes[:removed_request_params])
              .to eq('get /a/' => ['new required request param: x'])
          end
        end

        describe 'made required optional' do
          let(:new_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => false,
               'type' => 'string' }]
          end
          let(:old_parameters) do
            [{ 'name' => 'x',
               'in' => 'query',
               'required' => true,
               'type' => 'string' }]
          end

          it do
            expect(diff.changes[:new_request_params])
              .to eq('get /a/' => ['x is no longer required'])
          end
        end
      end

      describe 'response code' do
        let(:removed_paths) do
          { '/a/' =>
            { 'get' =>
              { 'responses' =>
                { '200' => {} } } } }
        end
        let(:added_paths) do
          { '/a/' =>
            { 'get' =>
              { 'responses' =>
                { '200' => {},
                  '204' => {} } } } }
        end

        describe 'added' do
          let(:new_paths) { added_paths }
          let(:old_paths) { removed_paths }

          it do
            expect(diff.changes[:new_response_attributes])
              .to eq('get /a/' => ['new 204 response'])
          end
        end

        describe 'removed' do
          let(:new_paths) { removed_paths }
          let(:old_paths) { added_paths }

          it do
            expect(diff.changes[:removed_response_attributes])
              .to eq('get /a/' => ['missing 204 response'])
          end
        end
      end

      describe 'response attribute' do
        let(:new_paths) do
          { '/a/' =>
            { 'get' =>
              { 'responses' =>
                { '200' =>
                  { 'schema' =>
                    { '$ref' => '#/definitions/200' } } } } } }
        end
        let(:old_paths) { new_paths }
        let(:added_definitions) do
          { '200' => { 'type' => 'object',
                       'required' => [],
                       'properties' =>
                       { 'id' => { 'type' => 'integer' },
                         'name' => { 'type' => 'string' } } } }
        end
        let(:removed_definitions) do
          { '200' => { 'type' => 'object',
                       'required' => [],
                       'properties' =>
                       { 'id' => { 'type' => 'integer' } } } }
        end

        describe 'added' do
          let(:new_definitions) { added_definitions }
          let(:old_definitions) { removed_definitions }

          it do
            expect(diff.changes[:new_response_attributes])
              .to eq('get /a/' => ['new attribute for 200 response: name (in: body, type: string)'])
          end
        end

        describe 'removed' do
          let(:new_definitions) { removed_definitions }
          let(:old_definitions) { added_definitions }

          it do
            expect(diff.changes[:removed_response_attributes])
              .to eq('get /a/' => ['missing attribute from 200 response: name (in: body, type: string)'])
          end
        end
      end
    end
  end
end
