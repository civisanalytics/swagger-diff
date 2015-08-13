module Swagger
  module Diff
    class Diff
      def initialize(old, new)
        @new_specification = Swagger::Diff::Specification.new(new)
        @old_specification = Swagger::Diff::Specification.new(old)
      end

      def compatible?
        endpoints_compatible? && requests_compatible? && responses_compatible?
      end

      def incompatibilities
        { endpoints: missing_endpoints.to_a.sort,
          request_params: incompatible_request_params,
          response_attributes: incompatible_response_attributes }
      end

      def incompatibilities_message
        msg = ''
        if incompatibilities[:endpoints]
          msg += incompatibilities_message_endpoints(incompatibilities[:endpoints])
        end
        if incompatibilities[:request_params]
          msg += incompatibilities_message_params(incompatibilities[:request_params])
        end
        if incompatibilities[:response_attributes]
          msg += incompatibilities_message_attributes(incompatibilities[:response_attributes])
        end
        msg
      end

      private

      def incompatibilities_message_endpoints(endpoints)
        if endpoints.empty?
          ''
        else
          msg = "- missing endpoints\n"
          endpoints.each do |endpoint|
            msg += "  - #{endpoint}\n"
          end
          msg
        end
      end

      def incompatibilities_message_inner(typestr, collection)
        if collection.nil? || collection.empty?
          ''
        else
          msg = "- incompatible #{typestr}\n"
          collection.sort.each do |endpoint, attributes|
            msg += "  - #{endpoint}\n"
            attributes.each do |attribute|
              msg += "    - #{attribute}\n"
            end
          end
          msg
        end
      end

      def incompatibilities_message_params(params)
        incompatibilities_message_inner('request params', params)
      end

      def incompatibilities_message_attributes(attributes)
        incompatibilities_message_inner('response attributes', attributes)
      end

      def missing_endpoints
        @old_specification.endpoints - @new_specification.endpoints
      end

      def incompatible_request_params
        ret = {}
        incompatible_request_params_enumerator.each do |key, val|
          ret[key] ||= []
          ret[key] << val
        end
        ret
      end

      def incompatible_request_params_enumerator
        Enumerator.new do |yielder|
          @old_specification.request_params.each do |key, old_params|
            new_params = @new_specification.request_params[key]
            next if new_params.nil?
            (new_params[:required] - old_params[:required]).each do |req|
              yielder << [key, "new required request param: #{req}"]
            end
            (old_params[:all] - new_params[:all]).each do |req|
              yielder << [key, "missing request param: #{req}"]
            end
          end
        end.lazy
      end

      def incompatible_response_attributes
        ret = {}
        incompatible_response_attributes_enumerator.each do |key, val|
          ret[key] ||= []
          ret[key] << val
        end
        ret
      end

      def incompatible_response_attributes_enumerator
        Enumerator.new do |yielder|
          @old_specification.response_attributes.each do |key, old_attributes|
            new_attributes = @new_specification.response_attributes[key]
            next if new_attributes.nil?
            old_attributes.keys.each do |code|
              if new_attributes.key?(code)
                (old_attributes[code] - new_attributes[code]).each do |resp|
                  yielder << [key, "missing attribute from #{code} response: #{resp}"]
                end
              else
                yielder << [key, "missing #{code} response"]
              end
            end
          end
        end.lazy
      end

      def endpoints_compatible?
        missing_endpoints.empty?
      end

      def requests_compatible?
        incompatible_request_params_enumerator.none?
      end

      def responses_compatible?
        incompatible_response_attributes_enumerator.none?
      end
    end
  end
end
