package MyFilms::TCCard;

use Moose;

has 'url'           => ( is => 'rw', isa => 'Str' );
has 'synopsis'      => ( is => 'rw', isa => 'Maybe[Str]' );

sub gin_attributes { }

1;
