#!/opt/local/bin/perl -W
use strict;
use warnings;
use Data::Dump qw(dump);
use POSIX qw(strftime);
use Getopt::Long;

open( FILE, "</Users/venkatesh/Dropbox/Finances/Toronto/mapping.conf" )
    or die( "Can't open file mapping.conf $!" );

my @lines = <FILE>;
close FILE;
my @t = localtime;
my $isMonthly = scalar($t[3] eq "01" || $t[3] eq "1");
my $isWeekly = scalar($t[6] eq "1");
my $dryrun = 0;
my $forcerun = 0;
GetOptions("dry" => \$dryrun,
    "force" => \$forcerun);
foreach my $line (@lines) {
    if($line =~ /^#/) {
        next;
    }
    chomp($line);
    if(!($forcerun)) {
    if($line =~ /weekly/gi && !$isWeekly) {
        next;
    }
    if($line =~ /monthly/gi && !$isMonthly) {
        next;
    }
    }
    $line =~ s/\s*$//g;
    #Aakash[0] aakash-DqAhuueba[1] akaash.nitd@gmail.com[2]
    my @splitWords = split(/ +/, $line);
    my $name = lc($splitWords[0]);
    my $timestamp = time;
    #TODO pretty filename. gowtham-10-nov.txt
    my $filenameLastPart = $splitWords[1]."/".$name."-".$timestamp.".txt";
    my $filename = "/Users/venkatesh/Dropbox/Public/liabilities-finance/".$filenameLastPart;
    my $urlname = "https://dl.dropboxusercontent.com/u/4854847/liabilities-finance/".$filenameLastPart;
    my $commandname = (split(/-/,$splitWords[1]))[0];
    my $command = "/opt/local/bin/ledger -f /Users/venkatesh/Dropbox/Finances/Toronto/finance.ldg reg ^liabilities:$commandname -w 180";
    if(!($dryrun)) {
        $command .=  " > $filename";
    } else {
        print "\n\n".uc($name)."\n";
        print "===================================================================\n";
        system($command);
        next;
    }
    system($command);
    if(!($? eq "0")) {
        print "Failed runCommand, sending mail\n";
        system("echo \"Failed runCommand in runDaily.pl\\\n$filename\" | mail -s \"Failed runCommand\" \"venkatesh88\@gmail.com\"");
        next;
    }
    my $value = readpipe("tail -n 1 $filename");
    chomp($value);
    $value = (split(/\$/, $value))[2];
    if(!($dryrun) && ($value<0 || $value>5)) {
    &SendMail(ucfirst($name), $splitWords[2], $urlname, $value);
    }
    sleep 5;
}

sub SendMail{
    #to, urlname 
    my $name = shift;
    my $to = shift;
    my $urlname = shift;
    my $value = shift;
    my ($body, $subject) = ("", "");
    my $prettyDate = strftime( "%d-%m-%Y", localtime);
    $body = "Hi $name!\r\n\r\r\n";
    if($value<0) {
        $value = -1 * $value;
        $subject = "I owe you!";
        $body .= "Seems like I owe you \\\$$value. I'll give you the money whenever you require me to!\r\nDetailed report in the link below:\r\n";
    } else {
        $subject = "You owe me!";
        $body .= "Seems like you owe me \\\$$value. You can give me the money at your own leisure!\r\nDetailed report in the link below:\r\n";
    }
    $subject .= " $prettyDate";
    $body .= $urlname."\r\n\r\n";
    $body .= "Cheers,\r\nVenkatesh Nandakumar\r\n";
    $body .= "\r\n\r\nP.S If you're receiving this for the first time, you'll be glad to know that you can change the frequency of these mails by replying STOP, DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY on-top of the reply-mail.\r\n";
    system("echo \"$body\" | mail -s \"$subject\" \"$to\"");
}

exit 0;
