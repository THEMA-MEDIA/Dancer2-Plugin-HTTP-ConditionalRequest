use Dancer2;
use lib '../lib';
use Dancer2::Plugin::HTTP::ConditionalRequest;

any '/conditional' => sub {
    http_conditional {
        etag            => "x",
        last_modified   => "Sat, 24 Oct 2015 20:28:20 GMT",
        required        => true
        } => sub {
        "Condition met to execute the request..."
    }
};

dance;