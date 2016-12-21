requires "Dancer2" => "0";
requires "Dancer2::Plugin" => "0";

require "DateTime::Format::HTTP" => "0";

on "test" => sub {
    require "Test::More" => "0";
}

