require 'spec_helper'

describe Swagger::Diff::Specification do
  context 'with pet store specification' do
    let(:spec) do
      Swagger::Diff::Specification.new('spec/fixtures/petstore-with-external-docs.json')
    end

    it '#endpoints' do
      expect(spec.endpoints)
        .to eq(Set.new(['get /pets', 'post /pets', 'get /pets/{}', 'delete /pets/{}']))
    end

    it '#parsed_to_hash' do
      endpoint_hash = spec.instance_variable_get(:@endpoint_hash)
      expect(endpoint_hash.keys)
        .to eq(['get /pets', 'post /pets', 'get /pets/{}', 'delete /pets/{}'])
      expect(endpoint_hash['get /pets'].keys)
        .to eq(%w(description operationId externalDocs produces parameters responses))
      expect(endpoint_hash['get /pets']).not_to eq(endpoint_hash['post /pets'])
    end
  end

  describe '#parse_swagger' do
    it 'from file' do
      spec = Swagger::Diff::Specification.new('spec/fixtures/petstore.json')
      expect(spec.instance_variable_get(:@parsed)['swagger']).to eq('2.0')
    end

    it 'from JSON string' do
      contents = File.open('spec/fixtures/petstore.json', 'r').read
      spec = Swagger::Diff::Specification.new(contents)
      expect(spec.instance_variable_get(:@parsed)['swagger']).to eq('2.0')
    end

    it 'from YAML string' do
      contents = File.open('spec/fixtures/petstore.yaml', 'r').read
      spec = Swagger::Diff::Specification.new(contents)
      expect(spec.instance_variable_get(:@parsed)['swagger']).to eq('2.0')
    end

    it 'from Hash' do
      contents = File.open('spec/fixtures/petstore.json', 'r').read
      hash = JSON.parse(contents)
      spec = Swagger::Diff::Specification.new(hash)
      expect(spec.instance_variable_get(:@parsed)['swagger']).to eq('2.0')
    end

    it 'from URL' do
      VCR.use_cassette('petstore') do
        spec = Swagger::Diff::Specification.new('https://raw.githubusercontent.com/swagger-api/swagger-spec/master/examples/v2.0/json/petstore.json')
        expect(spec.instance_variable_get(:@parsed)['swagger']).to eq('2.0')
      end
    end

    it 'raises an exception if and unsupported format' do
      expect { Swagger::Diff::Specification.new('foo: bar:') }
        .to raise_error('Only filenames or raw or parsed strings of JSON or YAML are supported.')
    end
  end

  context 'with dummy specification' do
    let(:spec) do
      Swagger::Diff::Specification.new('spec/fixtures/dummy.v3.json')
    end

    it '#request_params' do
      expect(spec.request_params)
        .to eq('get /a/' => { required: Set.new,
                              all: Set.new(['limit (in: query, type: integer)']) },
               'post /a/' => { required: Set.new(%w(name description)),
                               all: Set.new(['name (in: body, type: string)',
                                             'description (in: body, type: string)',
                                             'untyped (in: body, type: Hash[string, *])']) },
               'get /a/{}' => { required: Set.new(['id']),
                                all: Set.new(['id (in: path, type: integer)']) },
               'patch /a/{}' => {
                 required: Set.new(['id']),
                 all: Set.new(['id (in: path, type: integer)',
                               'id (in: body, type: integer)',
                               'name (in: body, type: ["string", "null"])',
                               'obj/thing (in: body, type: integer)',
                               'obj/name (in: body, type: string)',
                               'obj/self/thing (in: body, type: integer)',
                               'obj/self/name (in: body, type: string)',
                               'obj/self/self (in: body, type: reference)',
                               'obj/self/selfs[]/thing (in: body, type: integer)',
                               'obj/self/selfs[]/name (in: body, type: string)',
                               'obj/self/selfs[]/self (in: body, type: reference)',
                               'obj/self/selfs[]/selfs[] (in: body, type: reference)',
                               'obj/selfs[]/thing (in: body, type: integer)',
                               'obj/selfs[]/name (in: body, type: string)',
                               'obj/selfs[]/self/thing (in: body, type: integer)',
                               'obj/selfs[]/self/name (in: body, type: string)',
                               'obj/selfs[]/self/self (in: body, type: reference)',
                               'obj/selfs[]/self/selfs[] (in: body, type: reference)',
                               'obj/selfs[]/selfs[] (in: body, type: reference)',
                               'str (in: body, type: string)']) },
               'put /a/{}' => { required: Set.new(%w(id name description)),
                                all: Set.new(['id (in: path, type: integer)',
                                              'name (in: body, type: string)',
                                              'description (in: body, type: string)',
                                              'untyped (in: body, type: Hash[string, *])']) },
               'post /b/' => { required: Set.new,
                               all: Set.new(['name (in: body, type: string)']) },
               'put /b/{}' => { required: Set.new(%w(id name description req)),
                                all: Set.new(['id (in: path, type: integer)',
                                              'name (in: body, type: string)',
                                              'description (in: body, type: string)',
                                              'untyped (in: body, type: Hash[string, *])',
                                              'req (in: body, type: string)',
                                              'opt (in: body, type: string)']) })
    end

    it '#response_attributes' do
      expect(spec.response_attributes)
        .to eq('get /a/' => { '200' => Set.new(['[]/id (in: body, type: integer)',
                                                '[]/name (in: body, type: string)']) },
               'post /a/' => { '200' => Set.new(['id (in: body, type: integer)',
                                                 'name (in: body, type: string)',
                                                 'description (in: body, type: string)',
                                                 'letters (in: body, type: string[])',
                                                 'attributes (in: body, type: Hash[string, string])']) },
               'get /a/{}' => { '200' => Set.new(['id (in: body, type: integer)',
                                                  'name (in: body, type: string)',
                                                  'description (in: body, type: string)',
                                                  'letters (in: body, type: string[])',
                                                  'attributes (in: body, type: Hash[string, string])']) },
               'put /a/{}' => { '200' => Set.new(['id (in: body, type: integer)',
                                                  'name (in: body, type: string)',
                                                  'description (in: body, type: string)',
                                                  'letters (in: body, type: string[])',
                                                  'attributes (in: body, type: Hash[string, string])']) },
               'patch /a/{}' => {
                 '200' => Set.new(['id (in: body, type: integer)',
                                   'name (in: body, type: string)',
                                   'obj/thing (in: body, type: integer)',
                                   'obj/name (in: body, type: string)',
                                   'obj/self/thing (in: body, type: integer)',
                                   'obj/self/name (in: body, type: string)',
                                   'obj/self/self (in: body, type: reference)',
                                   'obj/self/selfs[]/thing (in: body, type: integer)',
                                   'obj/self/selfs[]/name (in: body, type: string)',
                                   'obj/self/selfs[]/self (in: body, type: reference)',
                                   'obj/self/selfs[]/selfs[] (in: body, type: reference)',
                                   'obj/selfs[]/thing (in: body, type: integer)',
                                   'obj/selfs[]/name (in: body, type: string)',
                                   'obj/selfs[]/self/thing (in: body, type: integer)',
                                   'obj/selfs[]/self/name (in: body, type: string)',
                                   'obj/selfs[]/self/self (in: body, type: reference)',
                                   'obj/selfs[]/self/selfs[] (in: body, type: reference)',
                                   'obj/selfs[]/selfs[] (in: body, type: reference)',
                                   'objs[]/thing (in: body, type: integer)',
                                   'objs[]/name (in: body, type: string)',
                                   'objs[]/self/thing (in: body, type: integer)',
                                   'objs[]/self/name (in: body, type: string)',
                                   'objs[]/self/self (in: body, type: reference)',
                                   'objs[]/self/selfs[]/thing (in: body, type: integer)',
                                   'objs[]/self/selfs[]/name (in: body, type: string)',
                                   'objs[]/self/selfs[]/self (in: body, type: reference)',
                                   'objs[]/self/selfs[]/selfs[] (in: body, type: reference)',
                                   'objs[]/selfs[]/thing (in: body, type: integer)',
                                   'objs[]/selfs[]/name (in: body, type: string)',
                                   'objs[]/selfs[]/self/thing (in: body, type: integer)',
                                   'objs[]/selfs[]/self/name (in: body, type: string)',
                                   'objs[]/selfs[]/self/self (in: body, type: reference)',
                                   'objs[]/selfs[]/self/selfs[] (in: body, type: reference)',
                                   'objs[]/selfs[]/selfs[] (in: body, type: reference)',
                                   'str (in: body, type: string)']) },
               'post /b/' => { '200' => Set.new(['id (in: body, type: integer)',
                                                 'name (in: body, type: string)']) },
               'put /b/{}' => { '200' => Set.new(['id (in: body, type: integer)',
                                                  'name (in: body, type: string)',
                                                  'description (in: body, type: string)',
                                                  'letters (in: body, type: string[])',
                                                  'attributes (in: body, type: Hash[string, string])',
                                                  'key1 (in: body, type: integer)',
                                                  'key2 (in: body, type: string)']) })
    end
  end

  context 'with JSON' do
    let(:paths) { {} }
    let(:definitions) { {} }
    let(:parameters) { {} }
    let(:responses) { {} }
    let(:parsed) do
      { 'swagger' => '2.0',
        'info' => { 'title' => 'Swagger Fixture', 'version' => '1.0' },
        'paths' => paths,
        'definitions' => definitions,
        'parameters' => parameters,
        'responses' => responses }
    end
    let(:spec) { Swagger::Diff::Specification.new(parsed) }

    describe 'definitions' do
      let(:paths) do
        { '/a/' =>
          { 'get' =>
            { 'responses' =>
              { '200' =>
                { 'schema' => { '$ref' => '#/definitions/no_props' } } } } } }
      end
      let(:definitions) do
        { 'no_props' => { 'type' => 'object' } }
      end

      it 'can be parsed without properties' do
        expect { spec.response_attributes }.not_to raise_error
      end
    end

    describe 'formData' do
      let(:paths) do
        { '/a/' =>
          { 'post' =>
            { 'parameters' =>
              [{ 'name' => 'w',
                 'in' => 'formData',
                 'required' => false,
                 'type' => 'string' },
               { 'name' => 'x',
                 'in' => 'formData',
                 'required' => true,
                 'type' => 'string' }],
              'responses' =>
              { '204' => {} } } } }
      end

      it 'parses params' do
        expect(spec.request_params)
          .to eq('post /a/' => { required: Set.new(['x']),
                                 all: Set.new(['w (in: formData, type: string)',
                                               'x (in: formData, type: string)']) })
      end
    end

    describe 'parameters' do
      let(:paths) do
        { '/a/' =>
          { 'post' =>
            { 'parameters' =>
              [{ 'name' => 'body',
                 'in' => 'body',
                 'schema' =>
                 { 'items' => { '$ref' => '#/definitions/body' },
                   'type' => 'array' } }],
              'responses' => { '204' => {} } } } }
      end
      let(:definitions) do
        { 'body' => { 'type' => 'object',
                      'properties' => { 'b' => { 'type' => 'string' } } } }
      end

      it 'parses body params that are arrays' do
        expect(spec.request_params)
          .to eq('post /a/' => { required: Set.new,
                                 all: Set.new(['[]/b (in: body, type: string)']) })
      end
    end

    describe 'parameter refs' do
      let(:paths) do
        { '/a/{id}/b/{guid}' =>
          { 'get' =>
            { 'parameters' => [{ '$ref' => '#/parameters/id' },
                               { '$ref' => '#/parameters/guid' },
                               { '$ref' => '#/parameters/format' }],
              'responses' => { '204' => {} } } } }
      end
      let(:parameters) do
        { 'id' => { 'name' => 'id',
                    'in' => 'path',
                    'type' => 'integer',
                    'required' => true },
          'guid' => { 'name' => 'guid',
                      'in' => 'path',
                      'type' => 'string',
                      'required' => true },
          'format' => { 'name' => 'format',
                        'in' => 'query',
                        'type' => 'string',
                        'required' => false } }
      end

      it 'dereferences parameters' do
        expect(spec.request_params)
          .to eq('get /a/{}/b/{}' =>
                 { required: Set.new(%w(id guid)),
                   all: Set.new(['id (in: path, type: integer)',
                                 'guid (in: path, type: string)',
                                 'format (in: query, type: string)']) })
      end
    end

    describe 'shared parameters' do
      let(:paths) do
        { '/a/{id}' =>
          { 'get' =>
            { 'parameters' => [{ 'name' => 'foo',
                                 'in' => 'query',
                                 'required' => false,
                                 'type' => 'string' }],
              'responses' => { '204' => {} } },
            'delete' =>
            { 'responses' => { '204' => {} } },
            'parameters' => [{ '$ref' => '#/parameters/id' },
                             { '$ref' => '#/parameters/format' }] } }
      end
      let(:parameters) do
        { 'id' => { 'name' => 'id',
                    'in' => 'path',
                    'type' => 'integer',
                    'required' => true },
          'format' => { 'name' => 'format',
                        'in' => 'query',
                        'type' => 'string',
                        'required' => false } }
      end

      it 'are shared and merged' do
        expect(spec.request_params)
          .to eq('get /a/{}' =>
                 { required: Set.new(['id']),
                   all: Set.new(['foo (in: query, type: string)',
                                 'id (in: path, type: integer)',
                                 'format (in: query, type: string)']) },
                 'delete /a/{}' =>
                 { required: Set.new(['id']),
                   all: Set.new(['id (in: path, type: integer)',
                                 'format (in: query, type: string)']) })
      end
    end

    describe 'responses' do
      let(:paths) do
        { '/a/' =>
          { 'get' =>
            { 'responses' =>
              { '200' =>
                { 'schema' =>
                  { 'properties' =>
                    { 'b' => { 'type' => 'string' } } } },
                '201' =>
                { 'schema' =>
                  { 'allOf' =>
                    [{ '$ref' => '#/definitions/c' },
                     { '$ref' => '#/definitions/d' }] } },
                '202' =>
                { 'schema' =>
                  { 'type' => 'array',
                    'items' => { '$ref' => '#/definitions/e' } } },
                '203' =>
                { 'schema' =>
                  { 'type' => 'array',
                    'items' =>
                    { 'type' => 'object',
                      'additionalProperties' =>
                      { 'type' => 'string' } } } } } } } }
      end
      let(:definitions) do
        { 'c' => { 'type' => 'object',
                   'properties' => { 'cc' => { 'type' => 'string' } } },
          'd' => { 'type' => 'object',
                   'properties' => { 'dd' => { 'type' => 'string' } } },
          'e' => { 'type' => 'object',
                   'properties' => { 'ee' => { 'type' => 'string' } } } }
      end

      it 'parses without a $ref' do
        expect(spec.response_attributes)
          .to eq('get /a/' =>
                 { '200' => Set.new(['b (in: body, type: string)']),
                   '201' => Set.new(['cc (in: body, type: string)',
                                     'dd (in: body, type: string)']),
                   '202' => Set.new(['[]/ee (in: body, type: string)']),
                   '203' => Set.new(['[] (in: body, type: Hash[string, string])']) })
      end
    end

    describe 'response refs' do
      let(:paths) do
        { '/a/' =>
          { 'get' =>
            { 'responses' =>
              { '200' =>
                { '$ref' => '#/responses/200' } } } } }
      end
      let(:responses) do
        { '200' => { 'description' => 'A generic response',
                     'schema' => { 'required' => %w(id name),
                                   'properties' =>
                                   { 'id' => { 'type' => 'integer' },
                                     'name' => { 'type' => 'string' } } } } }
      end

      it 'dereferences responses' do
        expect(spec.response_attributes)
          .to eq('get /a/' =>
                 { '200' => Set.new(['id (in: body, type: integer)',
                                     'name (in: body, type: string)']) })
      end
    end

    describe 'external path item' do
      let(:paths) do
        { '/a/' => { '$ref' => '...' } }
      end

      it 'warns' do
        expect_any_instance_of(Swagger::Diff::Specification)
          .to receive(:warn).with('External definitions are not (yet) supported')
        spec
      end
    end
  end
end
