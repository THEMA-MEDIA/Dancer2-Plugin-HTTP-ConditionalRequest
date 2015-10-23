package Dancer2::Plugin::HTTP::ConditionalRequest;

use warnings;
use strict;

use Carp;
use Dancer2::Plugin;

use HTTP::Date;

register http_last_modified => sub {
    $_[0]->log( warning =>
        "http_last_modified: missing date" )
        unless  $_[1];
    $_[0]->header('Last-Modified' => $_[1]);
    return;
};

register http_etag => sub {
    $_[0]->log( warning =>
        "http_etag: missing token" )
        unless  $_[1];
    $_[0]->header('ETag' => $_[1]);
    return;
};

register http_conditional => sub {
    my $dsl     = shift;
    my $coderef = pop;
    my $args;
    
    return sub {
        unless ( $coderef && ref $coderef eq 'CODE' ) {
            return sub {
               warn "http_conditional: missing CODE-REF";
            };
        }
        
        # RFC 7232 Hypertext Transfer Protocol (HTTP/1.1): Conditional Requests
        #
        # Section 6. Precedence
        #
        # When more than one conditional request header field is present in a
        # request, the order in which the fields are evaluated becomes
        # important.  In practice, the fields defined in this document are
        # consistently implemented in a single, logical order, since "lost
        # update" preconditions have more strict requirements than cache
        # validation, a validated cache is more efficient than a partial
        # response, and entity tags are presumed to be more accurate than date
        # validators.
        
STEP_1:
        # When recipient is the origin server and If-Match is present,
        # evaluate the If-Match precondition:
        
        # if true, continue to step 3
        
        # if false, respond 412 (Precondition Failed) unless it can be
        # determined that the state-changing request has already
        # succeeded (see Section 3.1)
        
        if ( $dsl->request->header('If-Match') ) {
            if ( $dsl->request->header('If-Match') eq $args->{eTag} ) {
                goto STEP_3;
            } else {
                $dsl->status(412); # Precondition Failed
                return;
            }
        }
        
STEP_2:
        # When recipient is the origin server, If-Match is not present, and
        # If-Unmodified-Since is present, evaluate the If-Unmodified-Since
        # precondition:
        
        # if true, continue to step 3
        
        # if false, respond 412 (Precondition Failed) unless it can be
        # determined that the state-changing request has already
        # succeeded (see Section 3.4)
        
        if ( $dsl->request->header('If-Unmodified-Since') ) {
            my $rqst_date = HTTP::Date::str2time(
                $dsl->request->header('If-Unmodified-Since')
            );
            my $last_date = HTTP::Date::str2time(
                $args->{LastModified}
            );
            
            if ( $rqst_date > $last_date ) {
                goto STEP_3;
            } else {
                $dsl->status(412); # Precondition Failed
                return;
            }
        }
    
STEP_3:
        # When If-None-Match is present, evaluate the If-None-Match
        # precondition:
        
        # if true, continue to step 5
        
        # if false for GET/HEAD, respond 304 (Not Modified)
        
        # if false for other methods, respond 412 (Precondition Failed)
        
        if ( $dsl->request->header('If-None-Match') ) {
            if ( $dsl->request->header('If-None-Match') ne $args->{eTag} ) {
                goto STEP_5;
            } else {
                if (
                    $dsl->request->method eq 'GET'
                    or
                    $dsl->request->method eq 'HEAD'
                ) {
                    $dsl->status(304); # Not Modified
                    return;
                } else {
                    $dsl->status(412); # Precondition Failed
                    return;
                }
            }
        }
    
STEP_4:
        # When the method is GET or HEAD, If-None-Match is not present, and
        # If-Modified-Since is present, evaluate the If-Modified-Since
        # precondition:
        
        # if true, continue to step 5
        
        # if false, respond 304 (Not Modified)
    
        if (
            ($dsl->request->method eq 'GET' or $dsl->request->method eq 'HEAD')
            and
            not $dsl->request->header('If-None-Match')
            and
            $dsl->request->header('If-Modified-Since')
        ) {
            my $rqst_date = HTTP::Date::str2time(
                $dsl->request->header('If-Modified-Since')
            );
            my $last_date = HTTP::Date::str2time(
                $args->{LastModified}
            );
    
            if ( $rqst_date < $last_date ) {
                goto STEP_5;
            } else {
                $dsl->status(304); # Not Modified
                return;
            }
        }
        
STEP_5:
        # When the method is GET and both Range and If-Range are present,
        # evaluate the If-Range precondition:
        
        # if the validator matches and the Range specification is
        # applicable to the selected representation, respond 206
        # (Partial Content) [RFC7233]
        
        # TODO
    
STEP_6:
        # Otherwise,
        
        # all conditions are met, so perform the requested action and
        # respond according to its success or failure.
        
        return $coderef->($dsl);
        
        # TODO: RFC-6585 - Status 428 (Precondition Required)
        #       
        #       For a GET, it would be totaly safe to return a fresh response,
        #       however, for unsafe methods it could be required that the client
        #       does provide the eTag or DateModified validators.
        #       
        #       setting     the pluging config with something like: required => 1
        #       might be a nice way to handle it for the entire app, turning it
        #       into a strict modus. 
    }
};

# RFC 7231 HTTP/1.1 Semantics and Content
# section 4.2.1 Common Method Properties - Safe Methods#
# http://tools.ietf.org/html/rfc7231#section-4.2.1
# there is a patch for Dancer2 it self
register http_method_is_safe => sub {
    return (
        $_[0]->request->method eq 'GET'       ||
        $_[0]->request->method eq 'HEAD'      ||
        $_[0]->request->method eq 'OPTIONS'   ||
        $_[0]->request->method eq 'TRACE'
    );
};

on_plugin_import {
    my $dsl = shift;
    my $app = $dsl->app;
};

register_plugin;

1;
