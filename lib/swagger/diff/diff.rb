module Swagger
  module Diff
    class Diff
      def initialize(old, new)
        @new_specification = Swagger::Diff::Specification.new(new)
        @old_specification = Swagger::Diff::Specification.new(old)
      end

      def changes
        @changes ||= {
          new_endpoints: new_endpoints.to_a.sort,
          removed_endpoints: missing_endpoints.to_a.sort,
          new_request_params: new_or_changed_request_params,
          removed_request_params: incompatible_request_params,
          new_response_attributes: new_or_changed_response_attributes,
          removed_response_attributes: incompatible_response_attributes
        }
      end

      def changes_message
        changed_endpoints_message + changed_params_message + changed_attrs_message
      end

      def compatible?
        endpoints_compatible? && requests_compatible? && responses_compatible?
      end

      def incompatibilities
        @incompatibilities ||= {
          endpoints: missing_endpoints.to_a.sort,
          request_params: incompatible_request_params,
          response_attributes: incompatible_response_attributes
        }
      end

      def incompatibilities_message
        msg = ''
        msg += endpoints_message('missing', incompatibilities[:endpoints]) if incompatibilities[:endpoints]
        msg += params_message('incompatible', incompatibilities[:request_params]) if incompatibilities[:request_params]
        if incompatibilities[:response_attributes]
          msg += attributes_message('incompatible', incompatibilities[:response_attributes])
        end
        msg
      end

      private

      def changed_endpoints_message
        msg = ''
        msg += endpoints_message('new', changes[:new_endpoints]) if changes[:new_endpoints]
        msg += endpoints_message('removed', changes[:removed_endpoints]) if changes[:removed_endpoints]
        msg
      end

      def changed_params_message
        msg = ''
        msg += params_message('new', changes[:new_request_params]) if changes[:new_request_params]
        msg += params_message('removed', changes[:removed_request_params]) if changes[:removed_request_params]
        msg
      end

      def changed_attrs_message
        msg = ''
        msg += attributes_message('new', changes[:new_response_attributes]) if changes[:new_response_attributes]
        if changes[:removed_response_attributes]
          msg += attributes_message('removed', changes[:removed_response_attributes])
        end
        msg
      end

      def endpoints_message(type, endpoints)
        if endpoints.empty?
          ''
        else
          msg = "- #{type} endpoints\n"
          endpoints.each do |endpoint|
            msg += "  - #{endpoint}\n"
          end
          msg
        end
      end

      def inner_message(nature, type, collection)
        if collection.nil? || collection.empty?
          ''
        else
          msg = "- #{nature} #{type}\n"
          collection.sort.each do |endpoint, attributes|
            msg += "  - #{endpoint}\n"
            attributes.each do |attribute|
              msg += "    - #{attribute}\n"
            end
          end
          msg
        end
      end

      def params_message(type, params)
        inner_message(type, 'request params', params)
      end

      def attributes_message(type, attributes)
        inner_message(type, 'response attributes', attributes)
      end

      def missing_endpoints
        @old_specification.endpoints - @new_specification.endpoints
      end

      def new_endpoints
        @new_specification.endpoints - @old_specification.endpoints
      end

      def incompatible_request_params
        ret = {}
        incompatible_request_params_enumerator.each do |key, val|
          ret[key] ||= []
          ret[key] << val
        end
        ret
      end

      def new_or_changed_request_params
        enumerator = changed_request_params_enumerator(
          @new_specification,
          @old_specification,
          '%{req} is no longer required',
          'new request param: %{req}')
        ret = {}
        enumerator.each do |key, val|
          ret[key] ||= []
          ret[key] << val
        end
        ret
      end

      def new_child?(req, old)
        idx = req.rindex('/')
        return false unless idx
        key = req[0..idx]
        !old.any? { |param| param.start_with?(key) }
      end

      def changed_request_params_enumerator(from, to, req_msg, missing_msg)
        Enumerator.new do |yielder|
          from.request_params.each do |key, old_params|
            new_params = to.request_params[key]
            next if new_params.nil?
            (new_params[:required] - old_params[:required]).each do |req|
              next if new_child?(req, old_params[:all])
              yielder << [key, req_msg % { req: req }]
            end
            (old_params[:all] - new_params[:all]).each do |req|
              yielder << [key, missing_msg % { req: req }]
            end
          end
        end.lazy
      end

      def incompatible_request_params_enumerator
        changed_request_params_enumerator(
          @old_specification,
          @new_specification,
          'new required request param: %{req}',
          'missing request param: %{req}')
      end

      def incompatible_response_attributes
        ret = {}
        incompatible_response_attributes_enumerator.each do |key, val|
          ret[key] ||= []
          ret[key] << val
        end
        ret
      end

      def new_or_changed_response_attributes
        enumerator = changed_response_attributes_enumerator(
          @new_specification,
          @old_specification,
          'new attribute for %{code} response: %{resp}',
          'new %{code} response')
        ret = {}
        enumerator.each do |key, val|
          ret[key] ||= []
          ret[key] << val
        end
        ret
      end

      def changed_response_attributes_enumerator(from, to, attr_msg, code_msg)
        Enumerator.new do |yielder|
          from.response_attributes.each do |key, old_attributes|
            new_attributes = to.response_attributes[key]
            next if new_attributes.nil?
            old_attributes.keys.each do |code|
              if new_attributes.key?(code)
                (old_attributes[code] - new_attributes[code]).each do |resp|
                  yielder << [key, attr_msg % { code: code, resp: resp }]
                end
              else
                yielder << [key, code_msg % { code: code }]
              end
            end
          end
        end.lazy
      end

      def incompatible_response_attributes_enumerator
        changed_response_attributes_enumerator(
          @old_specification,
          @new_specification,
          'missing attribute from %{code} response: %{resp}',
          'missing %{code} response')
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
