# Dancer2-Plugin-HTTP-ConditionalRequest
Conditionally handling HTTP request based on eTag or Modification-Date, according to RFC 7232

Doing conditional GET request DWIM with Last Modifiacation Date:

    get => HTTP_ConditionalRequest sub {
        
        # check if it's a sensible request or bail out
        
        my $date_lastModification;
      
        # retrieve last modification date
        # - compute it from database dates
        # - use an external table
        
        http_conditional_lastModification($date_lastModification);
        
        # HTTP Conditional did not intercept so we continue our original method
        
        return $data;
    };

or preventing lost-updates with PUT and an eTag:

    put => HTTP_ConditionalRequest sub {
        
        # check if it's a sensibel request or bail out
        
        my $eTag;
        
        # retrieve eTag
        # - compute it from MD5
        # - use an external table
        
        http_conditional_eTag($eTag)'
        
        # HTTP Conditional did not intercept so we continue our original method
      
        # update database
       
       return;
    };

The two Dancer Keywords introduced do the right thing in their context. For example, in a GET and checking with a last modification date as above, the method will halt and return a 304 if the dates do match. I t would return a 428 if there was no If-Modified-Since header-field is found.

However, in a PUT or DELETE, it would have satisfied the 'If-Not-Modified-Since' header field and actually do the rest of the route.

In a GET route, the response headers must be set if they have been used to check the conditional, otherwise it will carp. How else would the client be able to make a next request if it doesn't have the values to check against.
