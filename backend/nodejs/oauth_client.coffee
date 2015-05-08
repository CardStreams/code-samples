# Example requires 'request' module, this was tested with version 2.51.0
request = require 'request'

###
@param [Object] options the options for generating the token
@option options [String] apiEndpoint the basic URL where the REST API can be reached (required)
@option options [String] app_id the id of the application for which the token has to be retrieved (required)
@option options [String] app_key the secret key for the authentication (required)
@option options [Array<String>] origins restrict usage of the token to the given origins (optional)
@option options [String] accessLevel token access level on all application streams "read" or "full" (optional).
  The default is to provide read-only access to all application streams.
@option options [Array<Array<String>>] streamAccess stream access specification, each member of the array
  must be provided in the form [streamId, accessLevel], where accessLevel can be one of "read" or "full".

@example Obtain a token providing full access to all streams only for code running in origin "cool.example.com"
  opts = {
    apiEndpoint: "https://api.lifestreams.com",
    app_id: "my_app_id",
    app_key: "MyAppSuperSecretKey",
    origins: [ "https://cool.example.com" ],
    accessLevel: "full"
  }
  oauth_client.getToken opts, (err, resp, body) ->
    return console.log "Error while generating token: #{err}" if err
    #
    token_info = JSON.parse(body)
    console.log "Got token: "
    console.log "  access token: #{token_info.access_token}"
    console.log "  expires in: #{token_info.expires_in} seconds"

@example Obtain a token allowing read only access to a couple streams, and full access to another one
  opts = {
    apiEndpoint: "https://api.lifestreams.com",
    app_id: "my_app_id",
    app_key: "MyAppSuperSecretKey",
    streamAccess: [ [ "<streamIdA>","read" ], [ "<streamIdB>" ], [ "<streamIdC>","full" ] ]
  }
  oauth_client.getToken opts, (err, resp, body) ->
    return console.log "Error while generating token: #{err}" if err
    # ... body.access_token gives read access to streams A and B, full access to stream C
###
getToken = (options, cb = (err, resp, body) ->) ->
  return cb new Error("apiEndpoint option is required") if not options?.apiEndpoint?
  return cb new Error("app_id option is required") if not options?.app_id?
  return cb new Error("app_key option is required") if not options?.app_key?
  return cb new Error("only one of accessLevel and streamAccess can be specified") if options.streamAccess? and options.accessLevel?

  # Build the scope string, based on the options passed
  scopes = []

  # Restrict token to work with javascript running in the given origins
  if options.origins? and options.origins.length > 0
    scopes = scopes.concat ("o;#{orig}" for orig in options.origins)

  # Access level on all streams
  if options.accessLevel?
    scopes.push "st;*;#{options.accessLevel}"

  # Access restricted to some specific streams
  if options.streamAccess
    scopes = scopes.concat ("st;#{stId};#{level || 'read'}" for [stId, level] in options.streamAccess)

  # Token generation magic (request to Lifestreams API)
  request.post {
    url: "#{options.apiEndpoint}/v1/oauth/token",
    headers:
      'X-Cardstreams-AppId': "#{options.app_id}"
      'X-Cardstreams-AppKey':"#{options.app_key}"
    form:
      grant_type: 'client_credentials'
      scope: scopes.join(" ") 
  }, cb

module.exports =
  getToken: getToken
