#!/usr/local/bin/perl

use Net::Jabber qw(Client);
use URI::Encode;

#connection details
my $server = "server.name.tld";
my $port = "5222";
#username and password for authentication
my $username = "username";
my $password = "password";
#can be anything
my $resource = "bot";
#nickname in chatroom
my $nickname = "username";
#name of the multiuser chat room
my $MUCroom = "chatroom";

my $clnt = new Net::Jabber::Client;


$clnt->SetMessageCallBacks(
        groupchat => \&messageCB,
);

my $status = $clnt->Connect(hostname=>$server, port=>$port);

if (!defined($status)) {
        die "Jabber connect error ($!)\n";
}

my @result = $clnt->AuthSend(username=>$username,
        password=>$password,
        resource=>$resource);

if ($result[0] ne "ok") {
        die "Jabber auth error: @result\n";
}

#join the chatroom
$clnt->MUCJoin(
        room=>$MUCroom,
        server=>"conference.$server",
        nick=>$nickname
);

#announce ourselves
$clnt->RosterGet();
$clnt->PresenceSend();

#start listening for messages
while(defined($clnt->Process())) { }

$clnt->Disconnect();

sub messageCB {
        #getting some information from the message
        my $sid = shift;
        my $message = shift;
        my $fromJID = $message->GetFrom("jid");
        my $from = $fromJID->GetJID("full");
        my $text = $message->GetBody();

        if ( $from =~ /(\/.*)/ ) {
                $chatUser=$1;
                $chatUser =~ s/^.//;
        }


        #discard delayed messages since groupchat always sends a history
        if ( $message->GetXML() =~ /jabber\:x\:delay/ ){
                return;
        }

        #debug code to echo message to stdout
        #print "===\n";
        #print $chatUser . ": " . $text . "\n";
        #print "===\n";
        ############


        #look for hashtag
        if ( $text =~ /(#[a-z]*)/ ) {
                my $hashtag = $1;
                $hashtag =~ s/^.//;

				#create and send message in response to hashtag
                if ( $hashtag eq "hello" ){

                        my $msg = Net::Jabber::Message->new();
                        $msg->SetMessage(
                        "type" => "groupchat",
                        "to" => $MUCroom . '@conference.' . $server,
                        "body" => "Salutations!",
                        );
                        $clnt->Send($msg);
                }

        }

}
