## --------------------------------------------------------------------------------------------------------------------

package Projectus::Email;

use lib '/home/andy/work/projectus/lib';
use Data::Dumper;
use Moose;
use Carp;
use MIME::Lite;
use Projectus::Cfg qw(get_cfg);
use base 'Exporter';
our @EXPORT_OK = qw(send_email);

## --------------------------------------------------------------------------------------------------------------------

sub send_email {
    my ($email) = @_;

    # we're going to try and fill most things in from the Config file,
    # else they should be defined in the incoming hash

    # the things we need:
    # * from
    # * to (required, a scalar or an array of addresses)
    # * cc (optional, a scalar or an array of addresses)
    # * bcc (optional, a scalar or an array of addresses)
    # * copy_self (optional default false, boolean, will copy 'from' address to the 'bcc' address(es))
    # * subject (optional, string, default 'No Subject')
    # * text (required, string)
    # * html (optional, string
    # * ToDo: attachments

    my $cfg = get_cfg();

    croak "No 'to' address provided" unless defined $email->{to};

    # get these out of the config if not given in $email
    foreach my $key ( qw(from copy_self subject) ) {
        next if defined $email->{$key};
        $email->{$key} = $cfg->param( "email_$key" )
            if $cfg->param( "email_$key" );
    }

    croak "No 'from' address provided" unless defined $email->{from};
    croak "No 'text' provided" unless defined $email->{text};

    # tidy up some inputs so we know what we have
    if ( ref $email->{to} ne 'ARRAY' ) {
        $email->{to} = [ $email->{to} ];
    }
    if ( defined $email->{cc} and ref $email->{cc} ne 'ARRAY' ) {
        $email->{cc} = [ $email->{cc} ];
    }
    if ( defined $email->{bcc} and ref $email->{bcc} ne 'ARRAY' ) {
        $email->{bcc} = [ $email->{bcc} ];
    }

    my $msg;
    if ( defined $email->{html} ) {
        $msg = MIME::Lite->new(
            Type    => 'multipart/alternative',
        );
        # attach the plain text
        $msg->attach(
            Type    => q{text/plain; utf-8},
            Data    => $email->{text},
        );
        $msg->attach(
            Type    => q{text/html; utf-8},
            Data    => $email->{html},
        );
    }
    else {
        # just send a normal text message
        $msg = MIME::Lite->new(
            Data     => $email->{text},
        );
    }

    # copy this email to self if wanted
    if ( $email->{copy_self} ) {
        push @{$email->{bcc}}, $email->{from};
    }

    # do the required headers
    foreach my $hdr ( qw(from subject) ) {
        $msg->add($hdr, $email->{$hdr} );
    }

    # do the headers which can be from lists
    foreach my $hdr ( qw( to cc bcc ) ) {
        next unless defined $email->{$hdr};
        $msg->add( $hdr, _flatten($email->{$hdr}) );
    }

    # ToDo: attachments
    # do any attachments we might have
    # foreach my $attachment ( @{$email->{attachments}} ) {
    #     $msg->attach( %$attachment );
    # }

    # put our own X-Mailer header on the email
    $msg->replace( q{x-mailer}, q{Projectus - http://search.cpan.org/dist/Projectus/} );

    # finally, send the message
    $msg->send();
}

sub _flatten {
    my ($thing) = @_;

    return unless defined $thing;

    if ( ref $thing eq 'ARRAY' ) {
        return join( ', ', @$thing );
    }
    elsif ( ref $thing ) {
        # not sure what to do with other references, so stringify it
        return "$thing";
    }

    # else, just a scalar
    return $thing;
}

## --------------------------------------------------------------------------------------------------------------------
__PACKAGE__->meta->make_immutable();
1;
## --------------------------------------------------------------------------------------------------------------------
