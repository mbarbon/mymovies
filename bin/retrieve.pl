#!/usr/bin/perl -w

use strict;

use MyFilms::DB;
use WWW::Filmup;
use WWW::Trovacinema;

use Search::GIN::Query::Manual;
use LWP::UserAgent;

binmode STDOUT, ':utf8';
STDOUT->autoflush( 1 );

my $db = MyFilms::DB->new;
my $dir = $db->dir;
my $scope = $dir->new_scope;

my $ua = LWP::UserAgent->new;
my $fu = WWW::Filmup->new;
my $tc = WWW::Trovacinema->new;

print "Retrieving Trovacinema data\n";
my $tc_res = $ua->get( $tc->start_url );
my $tc_data = $tc->scrape_films( $tc_res );

foreach my $film ( $db->all_visible_films ) {
    $film->projections( [] );
    $dir->store( $film );
}

foreach my $film_data ( @{$tc_data->{films}} ) {
    utf8::upgrade( $film_data->{title} );
    my $title = lc $film_data->{title};
    my $query = Search::GIN::Query::Manual->new( values => { title => $title } );
    my @films = $dir->search( $query )->all;
    ( my $card_title = $title ) =~ s/\(3d\)//g;

    die if @films > 1;

    my @projections;
    foreach my $projection_data ( @{$film_data->{cinemas}} ) {
        my $projection = MyFilms::Projection->new
                             ( { cinema => $projection_data->{cinema},
                                 hours  => $projection_data->{hours},
                                 } );
        push @projections, $projection;
    }

    my $film;
    if( @films ) {
        print "Updating ", $title, "\n";
        $film = $films[0];

        $film->projections( \@projections );
    } else {
        print "Adding ", $title, "\n";

        $film = MyFilms::Film->new
                    ( { title       => $title,
                        projections => \@projections,
                        } );
    }

    if( !$film->tc_card ) {
        my $url = $film_data->{url}->abs( $tc->url )->as_string;
        my $tc_card = MyFilms::TCCard->new( { url => $url } );

        $film->tc_card( $tc_card );
    }

    if( !$film->tc_card->synopsis ) {
        print "  Retrieving TrovaCinema film card\n";
        my $card_res = $ua->get( $film->tc_card->url );
        my $card_data = $tc->scrape_card( $card_res );

        $film->tc_card->synopsis( $card_data->{synopsis} );
    }

    if( !$film->card ) {
        print "  Searching film card\n";
        my $search_url = $fu->search_film_card( $card_title );
        my $search_res = $ua->get( $search_url );
        my $search_data = $fu->scrape_search( $search_res );

        foreach my $entry ( @{$search_data->{result}} ) {
            next unless lc( $entry->{title} ) eq lc( $card_title );
            print "  Adding film card\n";
            $film->card( MyFilms::Card->new
                             ( { url => $entry->{url}->abs( $fu->url )->as_string,
                                 } ) );
            last;
        }
    }

    if( $film->card && !$film->review ) {
        print "  Retrieving card page\n";
        my $card_res = $ua->get( $film->card->url );
        my $card_data = $fu->scrape_card( $card_res );
        my %review_links = @{$card_data->{links}};
        my $review_url = $review_links{review};

        if( $review_url ) {
            print "  Adding review\n";
            $film->review( MyFilms::Review->new
                               ( { url => $review_url->abs( $fu->url )->as_string,
                                   } ) );
        }
    }

    if( $film->review && !$film->review->text ) {
        print "  Retrieving review page\n";
        my $review_res = $ua->get( $film->review->url );
        my $review_data = $fu->scrape_review( $review_res );

        $film->review->text( $review_data->{review} );
    }

    print "  Storing the film\n";
    $dir->store( $film );
}
