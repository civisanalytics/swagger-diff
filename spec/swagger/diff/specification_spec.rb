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
      expect(endpoint_hash['get /pets'].class).to eq(Swagger::V2::Operation)
      expect(endpoint_hash['get /pets']).not_to eq(endpoint_hash['post /pets'])
    end
  end

  describe '#parse_swagger' do
    it 'from file' do
      spec = Swagger::Diff::Specification.new('spec/fixtures/petstore.json')
      expect(spec.instance_variable_get(:@parsed).class).to eq(Swagger::V2::API)
    end

    it 'from JSON string' do
      contents = File.open('spec/fixtures/petstore.json', 'r').read
      spec = Swagger::Diff::Specification.new(contents)
      expect(spec.instance_variable_get(:@parsed).class).to eq(Swagger::V2::API)
    end

    it 'from YAML string' do
      contents = File.open('spec/fixtures/petstore.yaml', 'r').read
      spec = Swagger::Diff::Specification.new(contents)
      expect(spec.instance_variable_get(:@parsed).class).to eq(Swagger::V2::API)
    end

    it 'from Hash' do
      contents = File.open('spec/fixtures/petstore.json', 'r').read
      hash = JSON.parse(contents)
      spec = Swagger::Diff::Specification.new(hash)
      expect(spec.instance_variable_get(:@parsed).class).to eq(Swagger::V2::API)
    end

    it 'from URL' do
      VCR.use_cassette('petstore') do
        spec = Swagger::Diff::Specification.new('https://raw.githubusercontent.com/swagger-api/swagger-spec/master/examples/v2.0/json/petstore.json')
        expect(spec.instance_variable_get(:@parsed).class).to eq(Swagger::V2::API)
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

  describe 'formData' do
    let(:parsed) do
      { 'swagger' => '2.0',
        'info' => { 'title' => 'Swagger Fixture', 'version' => '1.0' },
        'paths' =>
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
          { '204' => {} } } } } }
    end
    let(:spec) do
      Swagger::Diff::Specification.new(parsed)
    end

    it 'parses params' do
      expect(spec.request_params)
        .to eq('post /a/' => { required: Set.new(['x']),
                               all: Set.new(['w (in: formData, type: string)',
                                             'x (in: formData, type: string)']) })
    end
  end

  describe 'definitions' do
    let(:parsed) do
      { 'swagger' => '2.0',
        'info' => { 'title' => 'Swagger Fixture', 'version' => '1.0' },
        'paths' =>
        { '/a/' =>
          { 'get' =>
            { 'responses' =>
              { '200' =>
                { 'schema' => { '$ref' => '#/definitions/no_props' } } } } } },
        'definitions' =>
        { 'no_props' => { 'type' => 'object' } } }
    end
    let(:spec) do
      Swagger::Diff::Specification.new(parsed)
    end

    it 'can be parsed without properties' do
      expect { spec.response_attributes }.not_to raise_error
    end
  end
end
