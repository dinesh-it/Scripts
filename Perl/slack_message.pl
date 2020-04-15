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
# The OAuth token should have chat.write and users.read scopes enabled

use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;
use JSON::XS qw/decode_json encode_json/;
use Getopt::Long;

my ($title, $message, $footer, $json, $color, @users, $help, $debug, $code);
my $user_cache_file = '/tmp/slack_users_list.json';
$color = '#ff4d4d';

GetOptions (
    "title=s" => \$title,
    "message=s" => \$message,
    "footer=s" => \$footer,
    "json=s" => \$json,
    "color=s" => \$color,
    "user=s" => \@users,
    "block" => \$code,
    "debug" => \$debug,
    "help" => \$help,
);

if($help) {
    help();
}

sub help {
    print 'Send message to slack as a user
        Set slack OAuth token in the env SLACK_OAUTH_TOKEN
        token should have chat.write and users.read scopes enabled

        --message -m    - Text message to be sent or read from stdin
                          you can use this script with pipe (|) in that case this option can be ignored

                            eg: echo "some text" | ./slack_message.pl -u user_name

                          if this option is ignored and also not piped, 
                          then script will be waiting for user input in STDIN
                          hit Ctrl-D once composed the message to be sent

        --user -u       - User name to whom this message to be sent to (multiple values accepted)
                          You can mention direct usernames/channels with @/# respectively
                          Names without @/# will be matched with user.list available for given token

                            eg: ./slack_message.pl -u user -u "@username" -u "#channelname" -m "some message"

        --title -t      - Title for your message in attachment (optional)
        --block -b      - Send message as a code block (optional)
        --footer -f     - Footer text message in attachment (optional)
        --color -c      - CSS Color code for the attachment (optional, default #ff4d4d(red))
        --json -j       - your custom json string which will be sent as it is in the Content (optional)
        --debug -d      - Print response received from slack on each step
        --help -h       - Prints this help message and exit
    ';
    print "\n";
    exit;
}

if(!$ENV{SLACK_OAUTH_TOKEN}) {
    die "please set OAuth slack user/bot token at env SLACK_OAUTH_TOKEN\n";
}

if(@users && !$message) {
    while (<>) {
        $message .= $_;
    }
    chomp $message;
}

$message = "```$message```" if($code);

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

    # Read from user.list cache
    if(-f $user_cache_file) {
        print "Trying to get user.list from cache file $user_cache_file\n" if($debug);
        open my $fh, "<$user_cache_file" or die "Unable to open cache file $user_cache_file: $!";
        my $file_content = '';
        while (<$fh>) {
            $file_content .= $_;
        }
        close $fh;
        if($file_content) {
            print "Returning user.list from cache\n" if($debug);
            return decode_json($file_content);
        }
    }

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
        $names->{real_user_names}->{$member->{profile}->{real_name_normalized}} = $member->{id};
        $names->{display_names}->{$member->{profile}->{display_name_normalized}} = $member->{id};
    }

    $names->{_cache_create_epoch} = time;

    print "Trying to write user.list to cache file $user_cache_file\n" if($debug);
    open my $fh, ">$user_cache_file" or die "Unable to open cache file $user_cache_file: $!";
    print $fh encode_json($names);
    close $fh;
    print "$user_cache_file created\n" if($debug);

    return $names;
}

sub get_slack_user_id {
    my $real_user_name = shift;

    $real_user_name = lc($real_user_name);

    ReTryUsers:
    if(!$slack_users) {
        $slack_users = get_users();
        if($debug) {
            print "Users list\n";
            print Dumper($slack_users);
        }
    }

    my $user_id;

    # Try an exact match first
    $user_id = $slack_users->{$real_user_name} if($slack_users->{$real_user_name});

    # RegEx search on slack usernames
    $user_id = _get_user_id($real_user_name, $slack_users) if(!defined $user_id);
    $user_id = _get_user_id($real_user_name, $slack_users->{real_user_names}) if(!defined $user_id);
    $user_id = _get_user_id($real_user_name, $slack_users->{display_names}) if(!defined $user_id);

    if(defined $user_id and $user_id ne 'MUL') {
        return $user_id;
    }

    # Refresh the cache if name not found and also cache is older than 24 hours
    if($slack_users and $slack_users->{_cache_create_epoch} < (time - 86400)) {
        unlink $user_cache_file;
        undef $slack_users;
        goto ReTryUsers;
    }

    print "No users matching $real_user_name\n";
    return undef;
}

sub _get_user_id {
    my ($u, $us) = @_;

    my @sel_users = grep(/$u/i, keys %{$us});

    if(@sel_users == 1) {
        print "Found slack user id $us->{$sel_users[0]} with username $sel_users[0] for given user $u\n";
        return $us->{$sel_users[0]};
    }

    if(@sel_users > 1) {
        print "Multiple match found for username $u - (@sel_users)\n";
        return 'MUL';
    }

    return undef;
}

sub send_message {
    my ($user) = @_;

    my $su_id;
    if($user =~ /^(#|@)/) {
        $su_id = $user;
    }
    else {
        $su_id = get_slack_user_id($user);
    }

    if(!$su_id) {
        return;
    }

    my $json_ref = {};
    if($json) {
        $json_ref = decode_json($json);
    }

    my $attachment = {
        'attachments' => [{
                color => $color,
                text => $message,
            }]
    };

    if($title) {
        $attachment->{attachments}[0]{title} = $title;
    }

    if($footer) {
        $attachment->{attachments}[0]{footer} = $footer;
    }

    my $linenum = $message =~ tr/\n//;

    if(!$title && !$footer && ($linenum < 50 || length($message) < 900)) {
        delete $attachment->{attachments};
        $attachment->{text} = $message;
    }

    my $body = {
        channel => "$su_id",
        as_user => 1,
        link_names => 1,
        %{$attachment},
        %{$json_ref},
    };

    my $json_body = encode_json($body);
    print "Sending message to slack user id: $su_id ($user)\n";
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

