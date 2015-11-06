module Swagger
  module Diff
    class Specification
      def initialize(spec)
        @spec = spec
        @parsed = parse_swagger(spec)
        @endpoint_hash = parsed_to_hash(@parsed)
      end

      def endpoints
        @endpoint_hash.keys.to_set
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
        endpoint && endpoint.parameters || nil
      end

      def parse_swagger(swagger)
        if swagger.is_a? Hash
          Swagger.build(swagger)
        elsif File.exist?(swagger)
          Swagger.load(swagger)
        else
          swagger = open(swagger).read if swagger[0..7] =~ %r{^https?://}
          begin
            JSON.parse(swagger)
          rescue JSON::ParserError
            begin
              YAML.load(swagger)
            rescue Psych::SyntaxError
              raise 'Only filenames or raw or parsed strings of JSON or YAML are supported.'
            else
              Swagger.build(swagger, format: :yaml)
            end
          else
            Swagger.build(swagger, format: :json)
          end
        end
      end

      def parsed_to_hash(parsed)
        ret = {}
        parsed.operations.each do |endpoint|
          ret["#{endpoint.verb} #{endpoint.path.gsub(/{.*?}/, '{}')}"] = endpoint
        end
        ret
      end

      # Parses a $ref into a flat list of parameters, recursively if necessary.
      #
      # Returns a hash with 2 keys where the value is a set of flattened
      # parameter definitions (i.e., all parameters, including nested
      # parameters, are included in a single set).
      def refs(ref, prefix = '')
        idx = ref.rindex('/')
        key = ref[idx + 1..-1]
        schema(@parsed.definitions[key], prefix)
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
        definition.type && definition.type == 'array' && definition.items
      end

      def schema(definition, prefix = '')
        ret = { required: Set.new, all: Set.new }
        if definition.allOf
          all_of!(definition.allOf, prefix, ret)
        elsif definition['$ref']
          merge_refs!(ret, refs(definition['$ref'], prefix))
        elsif definition.properties
          merge_refs!(ret,
                      properties(definition.properties,
                                 definition.required, prefix))
        elsif array?(definition)
          merge_refs!(ret, schema(definition.items, "#{prefix}[]/"))
        elsif definition.type == 'object'
          ret[:all].add(hash_property(definition, prefix))
        end
        ret
      end

      def nested(ref, prefix, name, list = false)
        # Check for cycles by testing whether name was already added to
        # prefix.
        key = "#{prefix}#{name}#{'[]' if list}"
        if prefix == "#{name}/" || prefix =~ %r{/#{name}(\[\])?/}
          # Anonymizing the reference in case the name changed (e.g.,
          # generated Swagger).
          { all: ["#{key} (in: body, type: reference)"] }
        else
          refs(ref, "#{key}/")
        end
      end

      def properties_for_ref(prefix, name, schema, required, list = false)
        key = "#{prefix}#{name}"
        ret = { required: Set.new, all: Set.new }
        if schema.key?('$ref')
          merge_refs!(ret, nested(schema['$ref'], prefix, name, list))
        else
          ret[:required].add(key) if required && required.include?(name)
          ret[:all].add("#{key} (in: body, type: #{schema.type}#{'[]' if list})")
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
        type = if definition.additionalProperties &&
                  definition.additionalProperties.type
                 definition.additionalProperties.type
               else
                 '*'
               end
        "#{key} (in: body, type: Hash[string, #{type}])"
      end

      def properties(properties, required, prefix = '')
        ret = { required: Set.new, all: Set.new }
        properties.each do |name, schema|
          if schema.type == 'array'
            merge_refs!(ret, properties_for_ref(prefix, name, schema.items, required, true))
          elsif schema.type == 'object'
            if schema.allOf
              # TODO: handle nested allOfs.
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
          if param.in == 'body'
            merge_refs!(ret, refs(param.schema['$ref']))
          else
            ret[:required].add(param.name) if param.required
            ret[:all].add("#{param.name} (in: #{param.in}, type: #{param.type})")
          end
        end
        ret
      end

      def response_attributes_inner(endpoint)
        ret = {}
        endpoint.responses.each do |code, response|
          if response.schema
            ret[code] = schema(response.schema)[:all]
          else
            ret[code] = Set.new
          end
        end
        ret
      end
    end
  end
end
