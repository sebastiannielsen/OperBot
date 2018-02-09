#!/usr/bin/perl

$| = 1;
use CGI ':standard';

print "Content-Type: text/html\n\n";

$command = param('command');
$arg0 = param('arg0');
$arg1 = param('arg1');




if ($command eq "GHOST") {
  $arg0 = "-";
  $arg1 = "-";
}

if ($command eq "SETTOPIC") {
  $arg0 = "-";
}

if (($command eq "DEFCON")||($command eq "USERCMD")) {
  $arg1 = "-";
  unless (($arg0 eq "true")||($arg0 eq "false")) {
    $arg0 = "";
  }
}

if (($command eq "OP")||($command eq "HALFOP")||($command eq "VOICE")||($command eq "CLRUSER")||($command eq "OPBAN")||($command eq "OPUNBAN")||($command eq "CHANSERVDEL")||($command eq "CHANSERVAOP")||($command eq "CHANSERVVOP")||($command eq "CHANSERVHOP")||($command eq "CHANSERVPRT")) {
  $arg1 = "-";
}

$command =~ s/\|//sgi;
$arg0 =~ s/\|//sgi;
$arg1 =~ s/\|//sgi;

if ((length($command) > 0)&&(length($arg0) > 0)&&(length($arg1) > 0)) {

  if (($arg0 =~ m/^\@/)&&($command eq "OP")) {
    $command = "DEOP";
    $arg0 = substr($arg0, 1, length($arg0) - 1);
  }
  if (($arg0 =~ m/^\%/)&&($command eq "HALFOP")) {
    $command = "DEHALFOP";
    $arg0 = substr($arg0, 1, length($arg0) - 1);
  }
  if (($arg0 =~ m/^\+/)&&($command eq "VOICE")) {
    $command = "DEVOICE";
    $arg0 = substr($arg0, 1, length($arg0) - 1);
  }

  if ($arg0 =~ m/^[~+@%&]/) {
    if (($command eq "OP")||($command eq "HALFOP")||($command eq "VOICE")) {
      $command = "";
      $arg0 = "";
      $arg1 = "";
    }
  }
  unless ($command eq "MSG") {
    $arg0 =~ s/^[~+@%&]//;
  }

open(FILE, ">/var/secure_files/bot/prepare.txt");
print FILE $command."|".$arg0."|".$arg1."|".$ENV{'REMOTE_ADDR'}."|";
close(FILE);
chmod("0777","/var/secure_files/bot/prepare.txt");
chown(124,130,"/var/secure_files/bot/prepare.txt");
rename("/var/secure_files/bot/prepare.txt","/var/secure_files/bot/remote.txt");

  startagain:
  if (-e "/var/secure_files/bot/remote.txt") {
    sleep 1;
    goto startagain;
  }
}

open(CHATLOG, "/var/secure_files/bot/logchannel.txt");
flock(CHATLOG,1);
$chat = <CHATLOG>;
close(CHATLOG);
@chatentrys = split(/\|/, $chat);

$chandata = shift(@chatentrys);
@allnicks = split("!!",$chandata);
@allnicks = sort(@allnicks);

print "<form action='remote.cgi' method='post'>";
print "<select name='command'>";
print "<option value='GHOST'>Ghosta m&ouml;g som missbrukar mitt nick i #laidback</option>";
print "<option value='CHANSERVDEL'>Radera ChanServ-beh&ouml;righeter arg0=nick</option>";
print "<option value='CHANSERVPRT'>L&auml;gg till ChanServ-skydd arg0=nick</option>";
print "<option value='CHANSERVAOP'>L&auml;gg till ChanServ-OP arg0=nick</option>";
print "<option value='CHANSERVHOP'>L&auml;gg till ChanServ-HalfOP arg0=nick</option>";
print "<option value='CHANSERVVOP'>L&auml;gg till ChanServ-Voice arg0=nick</option>";
print "<option value='KICKBAN'>Kickbanna arg0=nick arg1=reason</option>";
print "<option value='KICK'>Kicka arg0=nick arg1=reason</option>";
print "<option value='CLRUSER'>Rensa anv&auml;ndare arg0=nick</option>";
print "<option value='VOICE'>V&auml;xla Voice arg0=nick</option>";
print "<option value='HALFOP'>V&auml;xla HalfOP arg0=nick</option>";
print "<option value='OP'>V&auml;xla OP arg0=nick</option>";
print "<option value='OPBAN'>OP-banna arg0=nick</option>";
print "<option value='OPUNBAN'>Ta bort OP-ban arg0=nick</option>";
print "<option value='SETTOPIC'>St&auml;ll in kanal-topic arg1=topic</option>";
print "<option value='DEFCON'>Defcon arg0=true/false</option>";
print "<option value='USERCMD'>Aktivera anv&auml;ndarkommandon arg0=true/false</option>";
print "</select> ";
print " arg0=<select name='arg0'>";
print "<option value='true'>** Aktivera **</option>";
print "<option value='false'>** Avaktivera **</option>";
foreach $user (@allnicks) {
  if (length($user) > 0) {
    print "<option value='".$user."'>".$user."</option>";
  }
}
print "</select>";
print " arg1=<input type='text' name='arg1' size='12'>";
print " <input type='submit' value='K&ouml;r'>";
print "</form> <a href='remote.cgi'>UPPDATERA</a><br><br>";


foreach $entry (@chatentrys) {
  $entry =~ s/</&lt;/sgi;
  $entry =~ s/>/&gt;/sgi;
  print $entry."<br>";
}

print "<br><br><form action='remote.cgi' method='post'>";
print "<input type='hidden' name='command' value='MSG'>";
print "<input type='hidden' name='arg1' value='-'>";
print "<input type='text' name='arg0' size='100' autocomplete='off'>";
print "<input type='submit' value='Skicka'>";
print "</form>";
