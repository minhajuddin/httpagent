# Architecture

httpagent is built to make calling external APIs performant, robust, and
debuggable.

The main pieces of the setup are:

1. An httpagent (HTTP2 server) which has an endpoint which allows you to `POST` `Request`s
   which the server then makes to the external API.
2. A client which knows how to send requests to the httpagent.
