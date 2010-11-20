package MyFilms::Wx::UrlList;

use strict;
use base 'Wx::Dialog';

use Wx qw(:sizer :dialog);
use Wx::Perl::PubSub qw(:local);

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, -1, 'Select URL' );

    $self->{url} = Wx::TextCtrl->new( $self, -1, '' );
    $self->{list} = Wx::ListBox->new( $self, -1 );

    my $ok = Wx::Button->new( $self, -1, 'OK' );
    my $cancel = Wx::Button->new( $self, -1, 'Cancel' );

    subscribe( $ok, 'Clicked', $self, '_Ok' );
    subscribe( $cancel, 'Clicked', $self, '_Cancel' );
    subscribe( $self->{list}, 'ItemSelected', $self, '_ItemSelected' );

    my $top = Wx::GridBagSizer->new;
    $top->Add( $self->{url}, Wx::GBPosition->new( 0, 0 ),
               Wx::GBSpan->new( 1, 2 ), wxALL|wxEXPAND, 10 );
    $top->Add( $self->{list}, Wx::GBPosition->new( 1, 0 ),
               Wx::GBSpan->new( 1, 2 ), wxALL|wxEXPAND, 10 );
    $top->Add( $ok, Wx::GBPosition->new( 2, 0 ),
               Wx::GBSpan->new( 1, 1 ), wxALL|wxALIGN_RIGHT, 10 );
    $top->Add( $cancel, Wx::GBPosition->new( 2, 1 ),
               Wx::GBSpan->new( 1, 1 ), wxALL|wxALIGN_LEFT, 10 );
    $top->AddGrowableCol( 0 );
    $top->AddGrowableCol( 1 );
    $top->AddGrowableRow( 1 );

    $self->SetWindowStyleFlag( $self->GetWindowStyleFlag | wxRESIZE_BORDER );
    $self->SetSize( [500, 400] );
    $self->SetSizer( $top );

    return $self;
}

sub _Ok { $_[0]->EndModal( 1 ) }
sub _Cancel { $_[0]->EndModal( 0 ) }

sub _ItemSelected {
    my( $self, $index ) = @_;

    $self->{url}->SetValue( $self->{urls}->[$index]->{url} );
}

sub SetUrls {
    my( $self, $url, $urls ) = @_;

    $self->{url}->SetValue( $url );
    $self->{urls} = $urls;
    $self->{list}->Clear;

    for my $e ( @$urls ) {
        $self->{list}->Append( $e->{title} );
    }
}

sub GetUrl {
    my( $self ) = @_;

    return $self->{url}->GetValue;
}

1;
