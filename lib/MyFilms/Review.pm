package MyFilms::Review;

use Moose;

has 'text'          => ( is => 'rw', isa => 'Maybe[Str]' );
has 'url'           => ( is => 'rw', isa => 'Str' );

sub gin_attributes { }

1;
