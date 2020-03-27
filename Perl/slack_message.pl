#!/usr/bin/env perl

#
# slack_message.pl
#
# Developed by Dinesh Dharmalingam 
#
# Changelog:
# 2020-03-25 - created
#
# Script to send message to slack user in your workspace
# User needs to generate a OAuth token to use this script

use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON::XS qw/decode_json encode_json/;
use Getopt::Long;

my ($title, $message, $footer, $json, $color, @users, $help, $debug, $token);
$color = '#ff4d4d';

GetOptions (
    "title=s" => \$title,
    "message=s" => \$message,
    "footer=s" => \$footer,
    "json=s" => \$json,
    "color=s" => \$color,
    "user=s" => \@users,
    "debug" => \$debug,
    "help" => \$help,
);

if($help) {
    help();
}

sub help {
    print 'Send message to slack as a user

        --message -m    - Text message to be sent
        --footer -f     - Footer text message in attachment (optional)
        --title -t      - Title for your message in attachment (optional)
        --color -c      - CSS Color code for the attachment (optional, default #ff4d4d(red))
        --json -j       - your custom json string which will be sent as it is in the Content (optional)
        --user -u       - User name to send this message (multiple values accepted)
        --debug -d      - Print response received from slack on each step
        --help -h       - Prints this help message and exit
    ';
    print "\n";
    exit;
}

if(!$ENV{SLACK_OAUTH_TOKEN}) {
    die "please set OAuth slack user/bot token at env SLACK_OAUTH_TOKEN\n";
}

if((!$message and !$json) or !@users) {
    print "\nRequired params missing, (--message or --json) and --user required\n\n";
    help();
}

foreach my $u (@users) {
    send_message($u);
}

my $ua;
sub set_ua {
    return $ua if($ua);
    my $bot_token = $ENV{SLACK_OAUTH_TOKEN};
    $ua = LWP::UserAgent->new;
    $ua->default_header('Authorization' => "Bearer $bot_token");
}

my $slack_users;
sub get_users {
    my $users_read = 'https://slack.com/api/users.list';

    set_ua();
    $ua->default_header('Content-Type' => "application/x-www-form-urlencoded");

    my $res = $ua->get($users_read);

    if(!$res->is_success) {
        my $error = $res->decoded_content || $res->status_line;
        print "Failed to fetch users from slack.\n";
        print "Error: " . $error . "\n" if($debug);
        return {};
    }

    my $result = decode_json($res->decoded_content);

    my $members = $result->{members};

    my $names = {};
    foreach my $member (@{$members}) {
        $names->{$member->{name}} = $member->{id};
    }

    print Dumper($names) if($debug);
    $slack_users = $names;
    return $names;
}

sub get_slack_user_id {
    my $real_user_name = shift;

    $real_user_name = lc($real_user_name);

    if(!$slack_users) {
        $slack_users = get_users();
    }

    my @users = keys %{$slack_users};

    my @sel_users = ($real_user_name) if($slack_users->{$real_user_name});

    # Do an exact match
    if(!@sel_users) {
        @sel_users = grep(/$real_user_name/i, @users);
    }

    if(@sel_users == 1) {
        print "Found slack user id $slack_users->{$sel_users[0]} with username $sel_users[0] for given user $real_user_name\n";
        return $slack_users->{$sel_users[0]};
    }

    if(@sel_users > 1) {
        print "Multiple match found for username $real_user_name - (@sel_users)\n";
    }else {
        print "No users matching $real_user_name\n";
    }
    return undef;
}

sub send_message {
    my ($user) = @_;

    my $su_id = get_slack_user_id($user);

    if(!$su_id) {
        return;
    }

    my $json_ref = {};
    if($json) {
        $json_ref = decode_json($json);
    }

    my $attachment = [{
            color => $color,
            text => $message,
        }];

    if($title) {
        $attachment->[0]->{title} = $title;
    }

    if($footer) {
        $attachment->[0]->{footer} = $footer;
    }

    if(!$title && !$footer) {
        $attachment->[0]->{pretext} = $message;
        delete $attachment->[0]->{text};
    }

    my $body = {
        channel => "$su_id",
        as_user => 1,
        link_names => 1,
        attachments => $attachment,
        #%{$json_ref},
    };

    my $json_body = encode_json($body);
    print "Sending message to slack user id: $su_id\n";
    print "Content: $json_body\n" if($debug);

    my $post_msg = 'https://slack.com/api/chat.postMessage';
    set_ua();
    $ua->default_header('Content-Type' => "application/json");

    my $resp = $ua->post($post_msg, Content => $json_body);

    if($resp->is_success) {
        my $resp_data = decode_json($resp->decoded_content);
        if($resp_data->{ok}) {
            print "SENT SUCCESS\n"; 
            print "Response: " . $resp->decoded_content . "\n" if($debug);
            return 1;
        }
    }
    my $error = $resp->decoded_content || $resp->status_line;
    print "FAILED\n";
    print "Response: " . $error . "\n" if($debug);
    return;
}

