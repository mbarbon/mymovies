package WWW::Filmup;

use Moose;
use Web::Scraper;
use URI;
use namespace::autoclean;

sub new {
    my( $class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    $self->{scrape_search} = scraper {
        process 'dl', 'result[]' => scraper {
            process 'dt>a', url => '@href', 'title' => sub {
                my $elem = shift;
                my $text = $elem->as_text;

                $text =~ s/^.*\sscheda:\s+(.*?)\s*$/$1/i;

                return $text;
            };
        };
    };

    $self->{scrape_card} = scraper {
        process 'a.filmup', 'links[]' => sub {
            my $elem = shift;
            my $text = $elem->as_text;

            if( $text eq 'Recensione' ) {
                return ( review => URI->new( $elem->attr( 'href' ) ) );
            }

            return;
        };
    };

    $self->{scrape_review} = scraper {
        process 'td>font', 'review' => sub {
            my $elem = shift;
            my @items = $elem->content_list;

            my $text = '';
            my $skipped_title = 0;
            foreach my $item ( @items ) {
                if( !$skipped_title && ref $item && $item->tag eq 'b' ) {
                    $skipped_title = 1;
                    next;
                }
                next unless $skipped_title;
                if( ref $item ) {
                    next if $item->tag eq 'a';
                    $text .= $item->as_HTML;
                } else {
                    $text .= $item;
                }
            }

            return unless $skipped_title;

            $text =~ s{^(\s*<br />\s*)+}{}g;
            $text =~ s{(\s*<br />\s*)+$}{}g;

            return $text;
        };
    };

    return $self;
}

sub url { 'http://filmup.leonardo.it' }

sub search_film_card {
    my( $self, $title ) = @_;
    my $uri = URI->new( 'http://filmup.leonardo.it/cgi-bin/search.cgi' );

    $uri->query_form( fmt => 'long',
                      m   => 'all',
                      ps  => 10,
                      q   => $title,
                      sy  => 0,
                      ul  => '%/sc_%',
                      wf  => 2221,
                      wm  => 'wrd',
                      x   => 10,
                      y   => 9,
                      s   => 'SRPD',
                      su  => 'title',
                      );

    return $uri;
}

sub scrape_search {
    my( $self, $html ) = @_;
    my $data = $self->{scrape_search}->scrape( $html );

    return $data;
}

sub scrape_card {
    my( $self, $html ) = @_;
    my $data = $self->{scrape_card}->scrape( $html );

    return $data;
}

sub scrape_review {
    my( $self, $html ) = @_;
    my $data = $self->{scrape_review}->scrape( $html );

    return $data;
}

1;
