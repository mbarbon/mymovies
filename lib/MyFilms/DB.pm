package MyFilms::DB;

use Moose;

use MyFilms::Film;
use MyFilms::Review;
use MyFilms::Projection;
use MyFilms::Card;

use KiokuDB;
use KiokuDB::Backend::DBI;
use Search::GIN::Extract::Callback;
use Search::GIN::Query::Manual;

has 'dir' => ( is => 'ro', isa => 'KiokuDB' );

sub BUILD {
    my( $self, $params ) = @_;
    my $gin_cb = Search::GIN::Extract::Callback->new
                     ( extract => sub {
                           my ( $obj, $extractor, @args ) = @_;

                           return $obj->gin_attributes;
                       } );
    my $dir = KiokuDB->new
                  ( backend => KiokuDB::Backend::DBI->new
                                   ( dsn     => 'dbi:SQLite:dbname=films.sqlite',
                                     create  => 1,
                                     extract => $gin_cb,
                                     ),
                    );

    $self->{dir} = $dir;
}

sub all_films {
    my( $self ) = @_;
    my $query = Search::GIN::Query::Manual->new
                    ( values => { type => 'film' },
                      );

    return $self->dir->search( $query )->all;
}

sub all_visible_films {
    my( $self ) = @_;
    my $query = Search::GIN::Query::Manual->new
                    ( values => { has_projections => 1 },
                      );

    return $self->dir->search( $query )->all;
}

1;
