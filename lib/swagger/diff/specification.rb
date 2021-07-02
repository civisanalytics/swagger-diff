module Swagger
  module Diff
    class Specification
      def initialize(spec)
        @spec = spec
        @parsed = parse_swagger(spec)
        validate_swagger
        @endpoint_hash = parsed_to_hash(@parsed)
        @deprecated_endpoints_hash = parsed_to_deprecated_hash(@parsed)
      end

      def endpoints
        @endpoint_hash.keys.to_set
      end

      def deprecated_endpoints
        @deprecated_endpoints_hash.keys.to_set
      end

      def request_params
        @request_params ||= begin
                              ret = {}
                              @endpoint_hash.each do |key, endpoint|
                                ret[key] = request_params_inner(params_or_nil(endpoint))
                              end
                              ret
                            end
      end

      def response_attributes
        @response_attributes ||= begin
                                   ret = {}
                                   @endpoint_hash.each do |key, endpoint|
                                     ret[key] = response_attributes_inner(endpoint)
                                   end
                                   ret
                                 end
      end

      private

      def merge_refs!(h1, h2)
        h2.each do |k, v|
          if h1.include?(k)
            h1[k] += h1[k].merge(v)
          else
            h1[k] = v
          end
        end
      end

      def params_or_nil(endpoint)
        endpoint && endpoint['parameters'] || nil
      end

      def parse_swagger(swagger)
        if swagger.is_a? Hash
          swagger
        else
          if File.exist?(swagger) || swagger[0..7] =~ %r{^https?://}
            swagger = open(swagger).read
          end
          begin
            JSON.parse(swagger)
          rescue JSON::ParserError
            begin
              YAML.load(swagger)
            rescue Psych::SyntaxError
              raise 'Only filenames or raw or parsed strings of JSON or YAML are supported.'
            end
          end
        end
      end

      def parsed_to_hash(parsed)
        ret = {}
        verbs = Set['get', 'put', 'post', 'delete', 'options', 'head', 'patch']
        parsed['paths'].each do |path, items|
          # TODO: this doesn't handle external definitions ($ref).
          warn 'External definitions are not (yet) supported' if items.key?('$ref')
          (verbs & items.keys).each do |verb|
            if items['parameters']
              if items[verb]['parameters']
                items[verb]['parameters'].concat(items['parameters'])
              else
                items[verb]['parameters'] = items['parameters']
              end
            end
            ret["#{verb} #{parsed['basePath']}#{path.gsub(/{.*?}/, '{}')} operationId:#{items[verb]['operationId']}"] = items[verb]
          end
        end
        ret
      end

      def parsed_to_deprecated_hash(parsed)
        ret = {}
        verbs = Set['get', 'put', 'post', 'delete', 'options', 'head', 'patch']
        parsed['paths'].each do |path, items|
          # TODO: this doesn't handle external definitions ($ref).
          warn 'External definitions are not (yet) supported' if items.key?('$ref')
          (verbs & items.keys).each do |verb|
            if items[verb]['deprecated']
              ret["#{verb} #{parsed['basePath']}#{path.gsub(/{.*?}/, '{}')} operationId:#{items[verb]['operationId']}"] = items[verb]
            end
          end
        end
        ret
      end

      # Parses a $ref into a flat list of parameters, recursively if necessary.
      #
      # Returns a hash with 2 keys where the value is a set of flattened
      # parameter definitions (i.e., all parameters, including nested
      # parameters, are included in a single set).
      def refs(ref, prefix = '')
        defs = if ref[0..12] == '#/parameters/'
                 @parsed['parameters']
               elsif ref[0..11] == '#/responses/'
                 @parsed['responses']
               elsif ref[0..13] == '#/definitions/'
                 @parsed['definitions']
               else
                 warn "Unsupported ref '#{ref}' (expected definitions, parameters, or responses)"
                 {}
               end
        idx = ref.rindex('/')
        key = ref[idx + 1..-1]
        schema(defs.fetch(key, {}), prefix)
      end

      def all_of!(definitions, prefix, ret)
        definitions.each do |s|
          if s['$ref']
            merge_refs!(ret, refs(s['$ref'], prefix))
          else
            merge_refs!(ret, schema(s, prefix))
          end
        end
        ret
      end

      def array?(definition)
        definition['type'] && definition['type'] == 'array' && definition['items']
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      def schema(definition, prefix = '')
        ret = { required: Set.new, all: Set.new }
        if definition['allOf']
          all_of!(definition['allOf'], prefix, ret)
        elsif definition['$ref']
          merge_refs!(ret, refs(definition['$ref'], prefix))
        elsif definition['properties']
          merge_refs!(ret,
                      properties(definition['properties'],
                                 definition['required'], prefix))
        elsif array?(definition)
          merge_refs!(ret, schema(definition['items'], "#{prefix}[]/"))
        elsif definition['type'] == 'object'
          ret[:all].add(hash_property(definition, prefix))
        elsif definition['in']
          merge_refs!(ret,
                      properties_for_param(prefix, definition))
        elsif definition['schema']
          merge_refs!(ret, schema(definition['schema']))
        end
        ret
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/AbcSize

      def nested(ref, prefix, name, list = false)
        # Check for cycles by testing whether name was already added to
        # prefix.
        key = "#{prefix}#{name}#{'[]' if list}"
        if prefix == "#{name}/" || prefix =~ %r{/#{name}(\[\])?/}
          # Anonymizing the reference in case the name changed (e.g.,
          # generated Swagger).
          { all: ["#{key} (in body type reference)"] }
        else
          refs(ref, "#{key}/")
        end
      end

      def properties_for_param(prefix, definition)
        required = if definition['required']
                     [definition['name']]
                   else
                     []
                   end
        properties_for_ref(prefix, definition['name'], definition, required)
      end

      # rubocop:disable Metrics/ParameterLists
      def add_property(ret, prefix, name, schema, required, list)
        key = "#{prefix}#{name}"
        ret[:required].add(key) if required && required.include?(name)
        loc = if schema['in']
                schema['in']
              else
                'body'
              end
        ret[:all].add("#{key} (in #{loc} type #{schema['type']}#{'[]' if list})")
      end
      # rubocop:enable Metrics/ParameterLists

      def properties_for_ref(prefix, name, schema, required, list = false)
        ret = { required: Set.new, all: Set.new }
        if schema['$ref']
          merge_refs!(ret, nested(schema['$ref'], prefix, name, list))
        elsif schema['properties']
          prefix = "#{name}#{'[]' if list}/"
          merge_refs!(ret, properties(schema['properties'], schema['required'], prefix))
        else
          add_property(ret, prefix, name, schema, required, list)
        end
        ret
      end

      def hash_property(definition, prefix, name = '')
        # Swagger 2.0 doesn't appear to support non-string keys[1]. If
        # this changes, this will need to be updated.
        # [1] https://github.com/swagger-api/swagger-spec/issues/299
        # TODO: this doesn't handle hashes of objects.
        key = if name == ''
                # Remove the trailing slash, if present and no name was
                # specified (a prefix will always either be blank or end in a
                # trailing slash).
                prefix[0..-2]
              else
                "#{prefix}#{name}"
              end
        type = if definition['additionalProperties'] &&
                  definition['additionalProperties']['type']
                 definition['additionalProperties']['type']
               else
                 '*'
               end
        "#{key} (in body type Hash[string, #{type}])"
      end

      def properties(properties, required, prefix = '')
        ret = { required: Set.new, all: Set.new }
        properties.each do |name, schema|
          if schema['type'] == 'array'
            merge_refs!(ret, properties_for_ref(prefix, name, schema['items'], required, true))
          elsif schema['type'] == 'object' || schema['properties']
            if schema['allOf']
              # TODO: handle nested allOfs.
            elsif schema['properties']
              merge_refs!(ret, properties(schema['properties'], required, "#{prefix}#{name}/"))
            else
              ret[:all].add(hash_property(schema, prefix, name))
            end
          else
            merge_refs!(ret, properties_for_ref(prefix, name, schema, required))
          end
        end
        ret
      end

      def request_params_inner(params)
        ret = { required: Set.new, all: Set.new }
        return ret if params.nil?
        params.each do |param|
          if param['in'] == 'body'
            merge_refs!(ret, schema(param['schema']))
          elsif param['$ref']
            merge_refs!(ret, schema(param))
          else
            ret[:required].add(param['name']) if param['required']
            ret[:all].add("#{param['name']} (in #{param['in']} type #{param['type']})")
          end
        end
        ret
      end

      def response_attributes_inner(endpoint)
        ret = {}
        endpoint['responses'].each do |code, response|
          ret[code] = if response['schema']
                        schema(response['schema'])[:all]
                      elsif response['$ref']
                        schema(response)[:all]
                      else
                        Set.new
                      end
        end
        ret
      end

      def schema_for(type)
        File.join(
          File.expand_path(File.join('..', '..', '..', '..'), __FILE__),
          'schema', type, 'schema.json'
        )
      end

      def validate_swagger
        json_schema = File.open(schema_for('json')) do |json_schema_file|
          JSON::Schema.new(
            JSON.parse(json_schema_file.read),
            Addressable::URI.parse('http://json-schema.org/draft-04/schema#')
          )
        end
        JSON::Validator.add_schema(json_schema)
        errors = JSON::Validator.fully_validate(schema_for('oai'), JSON.dump(@parsed))
        return if errors.empty?
        spec = if @spec.to_s.length > 80
                 "#{@spec.to_s[0..74]} ..."
               else
                 @spec
               end
        warn "#{spec} is not a valid Swagger specification:\n\n#{errors.join("\n")}"
      end
    end
  end
end
