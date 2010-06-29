package MyFilms::Projection;

use Moose;

has 'cinema'        => ( is => 'ro', isa => 'Str' );
has 'hours'         => ( is => 'ro', isa => 'ArrayRef[Str]' );

sub gin_attributes {
    my( $self ) = @_;

    return { type  => 'projection',
             };
}

1;
