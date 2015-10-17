# Dancer2-Plugin-HTTP-ConditionalRequest
Conditionally handling HTTP request based on eTag or Modification-Date,
according to RFC 7232

It can be used for telling clients/caches that they already have the current
version when using GET or preventing lost-updates with PUT:

    put '/my_resource/:id' => sub {
        ...
        # check stuff
        # - compute eTag from MD5
        # - use an external table
        # - find a last modification date
        ...
        http_conditional {
            eTag            => '2d5730a4c92b1061',
            LastModified    => "Tue, 15 Nov 1994 12:45:26 GMT", # HTTP Date
        } => sub {
            ...
            # do the real stuff, like updating
            ...
        }
    }

Alternatively:

    put '/my_resource/:id' => sub {
        ...
        # check stuff
        # - compute eTag from MD5
        # - use an external table
        # - find a last modification date
        ...
        http_last_modified "Tue, 15 Nov 1994 12:45:26 GMT"; # HTTP Date
        # exits immediatly if no corresponding validation headers are provided
        # Status: 428 (Precondition Required)
        ...
        # feel free to do some more stuff
        ...
        http_conditional => sub {
            ...
            # do the real stuff, like updating
            ...
        };
    };
    

The Dancer keyword introduced here: `http_conditional` will take either or both
arguments: `eTag` or `LastMod`, which are two validators according to RFC-7232.
Section 6 describes clearly how to evaluate the precedence of these validators.

Sending these validators with a GET request is used for caching and respond with
a status of 304 (Not Modified) when the client has a 'fresh' version.

When used with 'unsafe' methods that will cause updates, these validators can
prevent 'lost updates' and will respond with 412 (Precondition Failed) when
there might have happened an intermediate update.

To make clients obligated to send those header-fields, the config can be set to
be required. For the unsafe-methods when missing those headers, it will result
in a 428 (Precondition Required) conform the RFC-6585 (Additional HTTP Status
Codes). This will be set in the Dancer config file.

There is a lot of additional information in RFC-7232 about generating and
retrieving eTags or last-modification-dates. Unfortunately, for a GET method one
might have to retrieve and process the resource before being capable of
generating a eTag. Or one might have to go through a few pieces of underlying
data structures to find that last-modification date. Okay, one could skip the
'post-processing' like serialisation and one does no longer have to send the
data but only the status message 304 (Not Modified). Please read-up in the RFC
about those topics.
