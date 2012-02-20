use warnings;
use strict;

=head1 NAME

BarnOwl::Message::Twitter

=head1 DESCRIPTION

=cut

package BarnOwl::Message::Twitter;
use base qw(BarnOwl::Message);

sub context { return "twitter"; }
sub service { return (shift->{"service"} || "http://twitter.com"); }
sub account { return shift->{"account"}; }
sub retweeted_by { shift->{retweeted_by}; }
sub subcontext { 
    my $self = shift;
    return $self->retweeted_by || $self->sender;
    ## Alternative:
    # $self->account eq "twitter" ? undef : $self->account;
}
sub long_sender {
    my $self = shift;
    $self->service =~ m#^\s*(.*?://.*?)/.*$#;
    my $service = $1 || $self->service;
    my $long = $service . '/' . $self->sender;
    if ($self->retweeted_by) {
        $long = "(retweeted by " . $self->retweeted_by . ") $long";
    }
    return $long;
}

sub replycmd {
    my $self = shift;
    if($self->is_private) {
        return $self->replysendercmd;
    } elsif(exists($self->{status_id})) {
        return BarnOwl::quote('twitter-atreply', $self->sender, $self->{status_id}, $self->account);
    } else {
        return BarnOwl::quote('twitter-atreply', $self->sender, $self->account);
    }
}

sub replysendercmd {
    my $self = shift;
    return BarnOwl::quote('twitter-direct', $self->sender, $self->account);
}

sub smartfilter {
    my $self = shift;
    my $inst = shift;
    my $filter;

    my $blame = $self->retweeted_by || $self->sender;
    $filter = "twitter-via-" . $blame;
    BarnOwl::command("filter", $filter,
		     qw{type ^twitter$ and ( sender}, "^\Q$blame\E\$",
		     qw{or retweeted_by}, "^\Q$blame\E\$", qw{)});
    return $filter;
}

1;
