package WWW::Trovacinema;

use Moose;
use Web::Scraper;
use namespace::autoclean;

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    $self->{scrape_movies} = scraper {
        process 'div.searchRes-group', 'films[]' => scraper {
            process 'span.filmName', 'no_film' => sub { return 1 };
            process 'a.filmName', 'title' => 'TEXT';
            process 'a.filmName', 'url' => sub {
                    my $elem = shift;

                    return URI->new( $elem->attr( 'href' ) );
            };
            process 'div.resultLineFilm', 'cinemas[]' => scraper {
                process 'p.cineName', 'cinema' => 'TEXT';
                process 'span.res-hours', 'hours' => sub {
                    my $elem = shift;
                    my $text = $elem->as_text;

                    return [ split ' ', $text ];
                };
            };
        };
    };

    return $self;
}

sub url { 'http://trovacinema.repubblica.it/' }
sub start_url { 'http://trovacinema.repubblica.it/programmazione-cinema/citta/firenze/fi/film' }

sub scrape_films {
    my( $self, $html ) = @_;
    my $data = $self->{scrape_movies}->scrape( $html );

    return { films => [ grep !$_->{no_film}, @{$data->{films}} ] };
}

1;
