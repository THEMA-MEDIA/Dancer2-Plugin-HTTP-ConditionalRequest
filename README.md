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
            etag            => '2d5730a4c92b1061',
            last_modified   => "Tue, 15 Nov 1994 12:45:26 GMT", # HTTP Date
            required        => false,
        } => sub {
            ...
            # do the real stuff, like updating
            ...
        }
    };

 
From the specs and documentation, eTags are stronger validators than the Date
Last-Modified. In the above described example, it has two validators provided
that can be used to check the conditional request. If the client did set a eTag
conditional in 'If-Matched' or 'If-None-Matched', it will try to match that. If
not, it will try to match against the Date Last-Modified with either the
'If-Modified-Since' or 'If-Unmodified-Since'.
The optional 'required' turns the API into a strict mode. Running under 'strict'
ensures that the client will provided either the eTag or Date-Modified validator
for un-safe requests. If not provided when required, it will return a response
with status 428 (Precondition Required).
 
Sending these validators with a GET request is used for caching and respond with
a status of 304 (Not Modified) when the client has a 'fresh' version.

When used with 'unsafe' methods that will cause updates, these validators can
prevent 'lost updates' and will respond with 412 (Precondition Failed) when
there might have happened an intermediate update.

There is a lot of additional information in RFC-7232 about generating and
retrieving eTags or last-modification-dates. Unfortunately, for a GET method one
might have to retrieve and process the resource before being capable of
generating a eTag. Or one might have to go through a few pieces of underlying
data structures to find that last-modification date. Okay, one could skip the
'post-processing' like serialisation and one does no longer have to send the
data but only the status message 304 (Not Modified). Please read-up in the RFC
about those topics.
