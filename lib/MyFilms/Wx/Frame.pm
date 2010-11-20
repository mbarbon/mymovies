package MyFilms::Wx::Frame;

use strict;
use base 'Wx::Frame';

use MyFilms::DB;
use Wx qw(:sizer);
use Wx::Perl::PubSub qw(:local);
use MyFilms::Wx::UrlList;

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( undef, -1, 'My Films' );

    $self->{db} = MyFilms::DB->new;
    $self->{list} = Wx::ListBox->new( $self, -1 );
    $self->{text} = Wx::HtmlWindow->new( $self, -1 );
    $self->{phase} = "";
    $self->{process} = undef;

    $self->CreateStatusBar;

    my $delete = Wx::Button->new( $self, -1, 'Delete' );
    my $update_url = Wx::Button->new( $self, -1, 'Add URL' );
    my $reload = Wx::Button->new( $self, -1, 'Reload list' );

    $self->{update_url} = $update_url;

    my $ts = Wx::BoxSizer->new( wxHORIZONTAL );
    my $ds = Wx::BoxSizer->new( wxVERTICAL );
    my $bs = Wx::BoxSizer->new( wxHORIZONTAL );

    $bs->Add( $delete );
    $bs->Add( $update_url );
    $bs->Add( $reload );

    $ds->Add( $bs );
    $ds->Add( $self->{text}, 1, wxEXPAND );

    $ts->Add( $self->{list}, 0, wxEXPAND|wxALL, 10 );
    $ts->Add( $ds, 1, wxEXPAND|wxALL, 10 );

    $self->SetSize( [1000, 600] );
    $self->SetSizer( $ts );

    subscribe( $self->{list}, 'ItemSelected', $self, '_ItemSelected' );
    subscribe( $delete, 'Clicked', $self, '_DeleteItem' );
    subscribe( $update_url, 'Clicked', $self, '_UpdateCardURL' );
    subscribe( $reload, 'Clicked', $self, '_Reload' );

    $self->_LoadFilms;

    return $self;
}

sub _LoadFilms {
    my( $self ) = @_;

    $self->{films} = [ sort { $a->title cmp $b->title }
                            $self->{db}->all_visible_films ];

    $self->{list}->Clear;
    foreach my $film ( @{$self->{films}} ) {
        $self->{list}->Append( $film->title );
    }
}

sub _ItemSelected {
    my( $self, $index ) = @_;
    my $film = $self->{films}->[$index];
    my $text = '';

    foreach my $projection ( @{$film->projections} ) {
        $text .= $projection->cinema . ': ' . join ' ', @{$projection->hours};
        $text .= "<br />\n";
    }

    if( $film->tc_card && $film->tc_card->synopsis ) {
        $text .= "<br />\n";
        $text .= $film->tc_card->synopsis;
        $text .= "<br />\n";
    }

    if( $film->review && $film->review->text ) {
        $text .= "<br />\n";
        $text .= $film->review->text;
        $text .= "<br />\n";
    }

    $text =~ s/\x{92}/'/g;
    $self->{text}->SetPage( $text );

    $self->{update_url}->SetLabel( $film->card && $film->card->url ? 'Update URL' : 'Add URL' );
}

sub _DeleteItem {
    my( $self ) = @_;
    my $index = $self->{list}->GetSelection;

    my $scope = $self->{db}->dir->new_scope;
    $self->{list}->Delete( $index );
    $self->{db}->dir->delete( $self->{films}->[$index] );
    splice @{$self->{films}}, $index, 1;
}

sub _UpdateCardURL {
    my( $self ) = @_;
    my $index = $self->{list}->GetSelection;
    my $film = $self->{films}->[$index];

    my $old_url = $film->card ? $film->card->url : '';
    my $choose = MyFilms::Wx::UrlList->new( $self );

    $choose->SetUrls( $old_url, $film->card_entries || [] );

    return unless $choose->ShowModal;

    my $new_url = $choose->GetUrl;

    if( $new_url ) {
        $film->card( MyFilms::Card->new ) unless $film->card;
        $film->card->url( $new_url );
        $film->review( undef );

        my $scope = $self->{db}->dir->new_scope;
        $self->{db}->dir->store( $film );
    }
}

sub _Reload {
    my( $self ) = @_;

    if( $self->{process} ) {
        $self->{process}->TerminateProcess;

        return;
    }

    require Wx::Perl::ProcessStream;

    my $process = Wx::Perl::ProcessStream::Process->new
                      ( "$^X -Ilib bin/retrieve.pl", 'Update', $self );

    Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_STDOUT( $self, '_NewLine' );
    Wx::Perl::ProcessStream::EVT_WXP_PROCESS_STREAM_EXIT( $self, '_Complete' );

    $self->{process} = $process;
    $process->Run;
}

sub _NewLine {
    my( $self, $event ) = @_;
    my $line = $event->GetLine;

    if( $line =~ /^\s+(.*)$/ ) {
        $self->SetStatusText( $self->{phase} . ": " . $1 );
    } else {
        $self->{phase} = $line;
        $self->SetStatusText( $self->{phase} );
    }
}

sub _Complete {
    my( $self, $event ) = @_;

    $self->{phase} = "";
    $self->SetStatusText( "Reloading complete" );
    $event->GetProcess->Destroy;

    $self->{process} = undef;
    $self->_LoadFilms();
}

1;
