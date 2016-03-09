# Workaround for Swagger::V2::SecurityScheme[1] incorrectly specifying
# required fields. maxlinc is right: the Swagger specification[2] is
# misleading. Fixed Fields suggests many parameters are required that are not
# required by Swagger's official validator[3]. Working around this by removing
# them from the array of required properties.
#
# [1] https://github.com/swagger-rb/swagger-rb/blob/v0.2.3/lib/swagger/v2/security_scheme.rb#L9-L11
# [2] http://swagger.io/specification/#securityDefinitionsObject
# [3] https://github.com/swagger-api/validator-badge

OAUTH2_PARAMS = [:flow, :authorizationUrl, :scopes].freeze

Swagger::V2::SecurityScheme.required_properties.reject! do |k, _|
  OAUTH2_PARAMS.include?(k)
end

# Workaround for Swagger::V2::Operation[1] not including deprecated. Patching
# pending a merge/release of #11[2].
#
# [1] https://github.com/swagger-rb/swagger-rb/blob/master/lib/swagger/v2/operation.rb
# [2] https://github.com/swagger-rb/swagger-rb/pull/12/files

module Swagger
  module V2
    class Operation
      field :deprecated, String
    end
  end
end
