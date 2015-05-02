<?php

// NOTICE!! This example has been tested with pecl_http == 2.4.3

/*

Example usage:

<?php
require 'oauth_client.php';

$options = [
  "apiEndpoint" => "https://api.cardstreams.io",
  "app_id" => "... your app id ...",
  "app_key" => "... your app key ...",
  "origins" => [ "my.domain.com", "*.wildcard.domain.com" ],
  "timelineAccess" => [ [ "55452c0f70ce262000000015", "read" ], [ "55452c2170ce262000000017", "full" ] ]
];

$result = getToken($options);
echo $result['access_token'];
?>

*/

function getToken(array $options) {

  // Build array of scopes based on the options passed to the function
  $scopes = array();

  // Restrict token to work with javascript running in the given origins
  if (isset($options['origins']) && is_array($options['origins'])) {
    foreach ($options['origins'] as $orig) {
      $scopes[] = "o;{$orig}";
    }
  }

  // Access level on all timelines
  if (isset($options['accessLevel']) && $options['accessLevel']) {
    $scopes[] = "tl;*;" . $options['accessLevel'];
  }

  // Access restricted to some specific timelines
  if (isset($options['timelineAccess']) && is_array($options['timelineAccess'])) {
    foreach ($options['timelineAccess'] as $tlAcc) {
      $tlId = $tlAcc[0];
      $level = 'read';
      if (isset($tlAcc[1])) {
        $level = $tlAcc[1];
      }
      $scopes[] = "tl;" . $tlId . ";" . $level;
    }
  }

  // url-encoded body
  $body = new http\Message\Body();
  $body->append(
    new http\QueryString([
      "grant_type" => "client_credentials",
      "scope" => implode(' ', $scopes)
    ])
  );

  // Build request with the appropriate headers and specified endpoint
  $request = new http\Client\Request("POST",
    $options["apiEndpoint"] . "/v1/oauth/token",
    [
      "X-Cardstreams-AppId" => $options["app_id"],
      "X-Cardstreams-AppKey" => $options["app_key"],
      "Content-Type" => "application/x-www-form-urlencoded"
    ],
    $body
  );
  $request->setOptions([ "timeout" => 10 ]);

  // Enqueue and send request
  $client = new http\Client;
  $client->enqueue($request)->send();

  // Pop the last retrieved response and print results
  $response = $client->getResponse();
  printf("%s returned '%s' (%d)\n",
      $response->getTransferInfo("effective_url"),
      $response->getInfo(),
      $response->getResponseCode()
  );

  // Return decoded json response if the transfer was successful. The token will be found
  // under the key "access_token"
  if ($response->getResponseCode() == 200) {
    return json_decode($response->body->toString(), true);
  } else {
    return NULL;
  }

}

?>
