# Workaround for Swagger::V2::SecurityScheme[1] incorrectly specifying
# required fields. maxlinc is right: the Swagger specification[2] is
# misleading. Fixed Fields suggests many parameters are required that are not
# required by Swagger's official validator[3]. Working around this by removing
# them from the array of required properties.
#
# [1] https://github.com/swagger-rb/swagger-rb/blob/v0.2.3/lib/swagger/v2/security_scheme.rb#L9-L11
# [2] http://swagger.io/specification/#securityDefinitionsObject
# [3] https://github.com/swagger-api/validator-badge

OAUTH2_PARAMS = [:flow, :authorizationUrl, :scopes]

Swagger::V2::SecurityScheme.required_properties.reject! do |k, _|
  OAUTH2_PARAMS.include?(k)
end
