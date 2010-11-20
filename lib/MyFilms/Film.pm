package MyFilms::Film;

use Moose;

has 'title'         => ( is => 'rw', isa => 'Str' );
has 'projections'   => ( is => 'rw', isa => 'ArrayRef[MyFilms::Projection]' );
has 'review'        => ( is => 'rw', isa => 'Maybe[MyFilms::Review]' );
has 'card'          => ( is => 'rw', isa => 'Maybe[MyFilms::Card]' );
has 'tc_card'       => ( is => 'rw', isa => 'Maybe[MyFilms::TCCard]' );
has 'card_entries'  => ( is => 'rw', isa => 'Maybe[ArrayRef[HashRef]]' );

sub has_projections { return @{$_[0]->projections} ? 1 : 0 }

sub gin_attributes {
    my( $self ) = @_;

    return { title           => $self->title,
             type            => 'film',
             has_projections => $self->has_projections,
             };
}

1;
