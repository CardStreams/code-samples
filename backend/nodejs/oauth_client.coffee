# Example requires 'request' module, this was tested with version 2.51.0
request = require 'request'

###
@param [Object] options the options for generating the token
@option options [String] apiEndpoint the basic URL where the REST API can be reached (required)
@option options [String] app_id the id of the application for which the token has to be retrieved (required)
@option options [String] app_key the secret key for the authentication (required)
@option options [Array<String>] origins restrict usage of the token to the given origins (optional)
@option options [String] accessLevel token access level on all application timelines "read" or "full" (optional).
  The default is to provide read-only access to all application timelines.
@option options [Array<Array<String>>] timelineAccess timeline access specification, each member of the array
  must be provided in the form [timelineId, accessLevel], where accessLevel can be one of "read" or "full".

@example Obtain a token providing full access to all timelines only for code running in origin "cool.example.com"
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

@example Obtain a token allowing read only access to a couple timelines, and full access to another one
  opts = {
    apiEndpoint: "https://api.lifestreams.com",
    app_id: "my_app_id",
    app_key: "MyAppSuperSecretKey",
    timelineAccess: [ [ "<timelineIdA>","read" ], [ "<timelineIdB>" ], [ "<timelineIdC>","full" ] ]
  }
  oauth_client.getToken opts, (err, resp, body) ->
    return console.log "Error while generating token: #{err}" if err
    # ... body.access_token gives read access to timelines A and B, full access to timeline C
###
getToken = (options, cb = (err, resp, body) ->) ->
  return cb new Error("apiEndpoint option is required") if not options?.apiEndpoint?
  return cb new Error("app_id option is required") if not options?.app_id?
  return cb new Error("app_key option is required") if not options?.app_key?
  return cb new Error("only one of accessLevel and timelineAccess can be specified") if options.timelineAccess? and options.accessLevel?

  # Build the scope string, based on the options passed
  scopes = []

  # Restrict token to work with javascript running in the given origins
  if options.origins? and options.origins.length > 0
    scopes = scopes.concat ("o;#{orig}" for orig in options.origins)

  # Access level on all timelines
  if options.accessLevel?
    scopes.push "tl;*;#{options.accessLevel}"

  # Access restricted to some specific timelines
  if options.timelineAccess
    scopes = scopes.concat ("tl;#{tlId};#{level || 'read'}" for [tlId, level] in options.timelineAccess)

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
