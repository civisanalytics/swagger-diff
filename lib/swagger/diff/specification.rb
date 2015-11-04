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
        definitions = @parsed.definitions
        idx = ref.rindex('/')
        key = ref[idx + 1..-1]
        ret = {}
        if definitions[key].allOf
          definitions[key].allOf.each do |schema|
            if schema['$ref']
              merge_refs!(ret, refs(schema['$ref'], prefix))
            else
              merge_refs!(ret, properties(schema.properties, schema.required, prefix))
            end
          end
        else
          merge_refs!(ret,
                      properties(definitions[key].properties,
                                 definitions[key].required, prefix))
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
          { all: ["#{key} (type: reference)"] }
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
          ret[:all].add("#{key} (type: #{schema.type}#{'[]' if list})")
        end
        ret
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
              # Swagger 2.0 doesn't appear to support non-string keys[1]. If
              # this changes, this will need to be updated.
              # [1] https://github.com/swagger-api/swagger-spec/issues/299
              # TODO: this doesn't handle hashes of objects.
              type = if schema.additionalProperties &&
                        schema.additionalProperties.type
                       schema.additionalProperties.type
                     else
                       '*'
                     end
              ret[:all].add("#{prefix}#{name} (type: Hash[string, #{type}])")
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
            ret[:all].add("#{param.name} (type: #{param.type})")
          end
        end
        ret
      end

      def response_attributes_inner(endpoint)
        ret = {}
        endpoint.responses.each do |code, response|
          if response.schema
            if response.schema.include?('type') && response.schema.type == 'array'
              ref = response.schema.items['$ref']
              prefix = '[]/'
            else
              ref = response.schema['$ref']
              prefix = ''
            end
            ret[code] = refs(ref, prefix)[:all]
          else
            ret[code] = Set.new
          end
        end
        ret
      end
    end
  end
end
