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
                              all: Set.new(['limit (type: integer)']) },
               'post /a/' => { required: Set.new(%w(name description)),
                               all: Set.new(['name (type: string)',
                                             'description (type: string)',
                                             'untyped (type: Hash[string, *])']) },
               'get /a/{}' => { required: Set.new(['id']),
                                all: Set.new(['id (type: integer)']) },
               'patch /a/{}' => {
                 required: Set.new(['id']),
                 all: Set.new(['id (type: integer)',
                               'name (type: ["string", "null"])',
                               'obj/thing (type: integer)',
                               'obj/name (type: string)',
                               'obj/self/thing (type: integer)',
                               'obj/self/name (type: string)',
                               'obj/self/self (type: reference)',
                               'obj/self/selfs[]/thing (type: integer)',
                               'obj/self/selfs[]/name (type: string)',
                               'obj/self/selfs[]/self (type: reference)',
                               'obj/self/selfs[]/selfs[] (type: reference)',
                               'obj/selfs[]/thing (type: integer)',
                               'obj/selfs[]/name (type: string)',
                               'obj/selfs[]/self/thing (type: integer)',
                               'obj/selfs[]/self/name (type: string)',
                               'obj/selfs[]/self/self (type: reference)',
                               'obj/selfs[]/self/selfs[] (type: reference)',
                               'obj/selfs[]/selfs[] (type: reference)',
                               'str (type: string)']) },
               'put /a/{}' => { required: Set.new(%w(id name description)),
                                all: Set.new(['id (type: integer)',
                                              'name (type: string)',
                                              'description (type: string)',
                                              'untyped (type: Hash[string, *])']) },
               'post /b/' => { required: Set.new,
                               all: Set.new(['name (type: string)']) },
               'put /b/{}' => { required: Set.new(%w(id name description req)),
                                all: Set.new(['id (type: integer)',
                                              'name (type: string)',
                                              'description (type: string)',
                                              'untyped (type: Hash[string, *])',
                                              'req (type: string)',
                                              'opt (type: string)']) })
    end

    it '#response_attributes' do
      expect(spec.response_attributes)
        .to eq('get /a/' => { '200' => Set.new(['[]/id (type: integer)',
                                                '[]/name (type: string)']) },
               'post /a/' => { '200' => Set.new(['id (type: integer)',
                                                 'name (type: string)',
                                                 'description (type: string)',
                                                 'letters (type: string[])',
                                                 'attributes (type: Hash[string, string])']) },
               'get /a/{}' => { '200' => Set.new(['id (type: integer)',
                                                  'name (type: string)',
                                                  'description (type: string)',
                                                  'letters (type: string[])',
                                                  'attributes (type: Hash[string, string])']) },
               'put /a/{}' => { '200' => Set.new(['id (type: integer)',
                                                  'name (type: string)',
                                                  'description (type: string)',
                                                  'letters (type: string[])',
                                                  'attributes (type: Hash[string, string])']) },
               'patch /a/{}' => {
                 '200' => Set.new(['id (type: integer)',
                                   'name (type: string)',
                                   'obj/thing (type: integer)',
                                   'obj/name (type: string)',
                                   'obj/self/thing (type: integer)',
                                   'obj/self/name (type: string)',
                                   'obj/self/self (type: reference)',
                                   'obj/self/selfs[]/thing (type: integer)',
                                   'obj/self/selfs[]/name (type: string)',
                                   'obj/self/selfs[]/self (type: reference)',
                                   'obj/self/selfs[]/selfs[] (type: reference)',
                                   'obj/selfs[]/thing (type: integer)',
                                   'obj/selfs[]/name (type: string)',
                                   'obj/selfs[]/self/thing (type: integer)',
                                   'obj/selfs[]/self/name (type: string)',
                                   'obj/selfs[]/self/self (type: reference)',
                                   'obj/selfs[]/self/selfs[] (type: reference)',
                                   'obj/selfs[]/selfs[] (type: reference)',
                                   'objs[]/thing (type: integer)',
                                   'objs[]/name (type: string)',
                                   'objs[]/self/thing (type: integer)',
                                   'objs[]/self/name (type: string)',
                                   'objs[]/self/self (type: reference)',
                                   'objs[]/self/selfs[]/thing (type: integer)',
                                   'objs[]/self/selfs[]/name (type: string)',
                                   'objs[]/self/selfs[]/self (type: reference)',
                                   'objs[]/self/selfs[]/selfs[] (type: reference)',
                                   'objs[]/selfs[]/thing (type: integer)',
                                   'objs[]/selfs[]/name (type: string)',
                                   'objs[]/selfs[]/self/thing (type: integer)',
                                   'objs[]/selfs[]/self/name (type: string)',
                                   'objs[]/selfs[]/self/self (type: reference)',
                                   'objs[]/selfs[]/self/selfs[] (type: reference)',
                                   'objs[]/selfs[]/selfs[] (type: reference)',
                                   'str (type: string)']) },
               'post /b/' => { '200' => Set.new(['id (type: integer)',
                                                 'name (type: string)']) },
               'put /b/{}' => { '200' => Set.new(['id (type: integer)',
                                                  'name (type: string)',
                                                  'description (type: string)',
                                                  'letters (type: string[])',
                                                  'attributes (type: Hash[string, string])',
                                                  'key1 (type: integer)',
                                                  'key2 (type: string)']) })
    end
  end
end
