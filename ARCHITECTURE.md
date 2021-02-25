# Architecture

httpagent is built to make calling external APIs performant, robust, and
debuggable.

The main pieces of the setup are:

1. An httpagent (HTTP2 server) which has an endpoint which allows you to `POST` `Request`s
   which the server then makes to the external API.
2. A client which knows how to send requests to the httpagent.


## Flow

1. HA.request :get, url
2. Get a pool for the {scheme, host, port} via the Registry
   4. Send a request over this pool
      5. Check out a connection
      6. Make a request
      7. Check in the connection
      8. Return the response to the caller
   4. If a pool is not found, spawn a new pool and do the above

