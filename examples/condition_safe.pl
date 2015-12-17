use Dancer2;
use lib '../lib';
use Dancer2::Plugin::HTTP::ConditionalRequest;

use DateTime;

my $sometime = DateTime->now;


any '/conditional' => sub {
    http_conditional {
        etag            => "x",
        last_modified   => $sometime,
        required        => true
        } => sub {
        "Condition met to execute the request..."
    }
};

dance;