#!/usr/local/bin/perl

use LWP::UserAgent;
use MIME::Entity;
use Email::Date::Format 'email_date';

package SebbeBot;
use base 'Bot::BasicBot';

$cachedtime = 0;
%cachedcontent = ();
@log = ();
$msgexpiry = 0;

%msg = ();
%hasnotwritten = ();
%ytlock = ();
%resultcache = ();
$armed = "false";

$ytkey = "ENTER_YOUR_YOUTUBE_API_KEY_HERE";
$mailsender = "ENTER_YOUR_MAILSENDER_ACCOUNT_HERE"; #example: "Boten Anna <mail\@example.org>"
$mailtarget = "ENTER_YOUR_MAILTARGET_ACCOUNT_HERE"; #example: "postmaster\@example.org"
$mailaccount = "ENTER_THE_USER_TO_RUN_DOVECOT_DELIVERY_AS"; #example: root


sub said {
  $self      = shift;
  $arguments = shift;    # Contains the message that the bot heard.
  $ua = LWP::UserAgent->new;
  $message = "";
  unless ($arguments->{channel} eq "msg") {
    if ($armed eq "true") {
      if ($self->pocoirc->is_channel_operator($arguments->{channel},'anna') != 1) {
        $self->say(channel => "msg", who => "ChanServ", body => "OP ".$arguments->{channel});
        push(@log, "*** N\xE5gon idiot som deoppade mig. Reoppar i ".$arguments->{channel});
        if ($#log > 40) {
          shift(@log);
        }
      }
    }

    $nickprefix = "";
    if ($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\~";
    }
    if ($self->pocoirc->is_channel_admin($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\&";
    }
    if ($self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\@";
    }
    if ($self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\%";
    }
    if ($self->pocoirc->has_channel_voice($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\+";
    }

    push(@log, "<".$nickprefix.$arguments->{who}."> ".$arguments->{body});
    if ($#log > 40) {
      shift(@log);
    }


    if (($arguments->{body} eq ".btc")||($arguments->{body} eq ".cc")||($arguments->{body} eq ".ltc")||($arguments->{body} eq ".xmr")||($arguments->{body} eq ".bch")) {
      if ($cachedtime < time) {
        $response = $ua->get('https://api.coinmarketcap.com/v1/ticker/?convert=SEK&limit=15');
        $rbody = $response->decoded_content;
        $rbody =~ s/\n//sgi;
        $rbody =~ s/\r//sgi;
        $rbody =~ s/\s//sgi;
        $rbody =~ s/\[\{\"id\":\"(.*)\}\]/$1/sgi;
        @coindata = split(/\},\{\"id\":\"/, $rbody);
        foreach $coin (@coindata) {
          if (($coin =~ m/^bitcoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
            $cachedcontent{'btc'} = "[BTC] \$".numprettify(int($1))." / ".numprettify(int($3))." kr";
          }
          if (($coin =~ m/^litecoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
            $cachedcontent{'ltc'} = "[LTC] \$".numprettify(int($1))." / ".numprettify(int($3))." kr";
          }
          if (($coin =~ m/^monero\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
            $cachedcontent{'xmr'} = "[XMR] \$".numprettify(int($1))." / ".numprettify(int($3))." kr";
          }
          if (($coin =~ m/^bitcoin-cash\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
            $cachedcontent{'bch'} = "[BCH] \$".numprettify(int($1))." / ".numprettify(int($3))." kr";
          }
        }
        $cachedtime = time + (30*60);
        $cached = "[live]";
      }
      else
      {
        $timeleft = $cachedtime - time;
        $timeleft + 60;
        $minutesleft = int($timeleft / 60);
        $cached = "[cachad ${minutesleft}m]";
      }
      if (($arguments->{body} eq ".btc")||($arguments->{body} eq ".cc")) {
        $message = $arguments->{who}.": $cachedcontent{'btc'} | $cachedcontent{'xmr'} | $cachedcontent{'ltc'} | $cachedcontent{'bch'} | $cached";
      }
      if ($arguments->{body} eq ".ltc") {
        $message = $arguments->{who}.": $cachedcontent{'ltc'} | $cachedcontent{'xmr'} | $cachedcontent{'btc'} | $cachedcontent{'bch'} | $cached";
      }
      if ($arguments->{body} eq ".xmr") {
        $message = $arguments->{who}.": $cachedcontent{'xmr'} | $cachedcontent{'btc'} | $cachedcontent{'ltc'} | $cachedcontent{'bch'} | $cached";
      }
      if ($arguments->{body} eq ".bch") {
        $message = $arguments->{who}.": $cachedcontent{'bch'} | $cachedcontent{'xmr'} | $cachedcontent{'ltc'} | $cachedcontent{'btc'} | $cached";
      }
    }

    if ($arguments->{body} eq ".per") {
      $response = $ua->get('https://perper.se');
      $rbody = $response->decoded_content;
      $rbody =~ s/\n//sgi;
      $rbody =~ s/\r//sgi;
      $perperline = "fail";
      if ($rbody =~ m/<p>([^<]*)<\/p>/s) {
        $perperline = $1;
        $perperline =~ s/&gt;/>/sgi;
        $perperline =~ s/&lt;/</sgi;
        $perperline =~ s/^[^<]*//;
      }
      if ($perperline eq "fail") {
        $message = $arguments->{who}.": Oj. perper.se verkar ligga nere.";
      }
      else
      {
        $message = $perperline;
      }
    }
    if ($arguments->{body} eq ".butkus") {
      $response = $ua->get('https://butkus.xyz/api/v1');
      $rbody = $response->decoded_content;
      $rbody =~ s/\n//sgi;
      $rbody =~ s/\r//sgi;
      $butkusline = "fail";
      if ($rbody =~ m/<pre>([^<]*)<\/pre>/s) {
        $butkusline = $1;
        $butkusline =~ s/&gt;/>/sgi;
        $butkusline =~ s/&lt;/</sgi;
        $butkusline =~ s/^[^<]*//;
      }
      if ($butkusline eq "fail") {
        $message = $arguments->{who}.": Oj. Butkus API verkar ligga nere.";
      }
      else
      {
        $message = $butkusline;
      }
    }
    if ($arguments->{body} =~ m/^\.best(\xE4|ä)m (.+)/) {
      $datatodecide = $2;
      if ((length($datatodecide) > 8)&&($datatodecide =~ m/\seller\s/si)) {
        $checkerstring = $datatodecide;
        $checkerstring =~ s/\xE4/a/sg;
        $checkerstring =~ s/\xE5/a/sg;
        $checkerstring =~ s/\xF6/o/sg;
        $checkerstring =~ s/\xC4/a/sg;
        $checkerstring =~ s/\xC5/a/sg;
        $checkerstring =~ s/\xD6/o/sg;
        $checkerstring =~ s/Ã¥/a/sg;
        $checkerstring =~ s/Ã¤/a/sg;
        $checkerstring =~ s/Ã¶/o/sg;
        $checkerstring =~ s/Ã…/a/sg;
        $checkerstring =~ s/Ã„/a/sg;
        $checkerstring =~ s/Ã–/o/sg;
        $checkerstring =~ s/0/o/sg;
        $checkerstring =~ s/1/l/sg;
        $checkerstring =~ s/2/z/sg;
        $checkerstring =~ s/3/e/sg;
        $checkerstring =~ s/4/a/sg;
        $checkerstring =~ s/5/s/sg;
        $checkerstring =~ s/6/b/sg;
        $checkerstring =~ s/7/t/sg;
        $checkerstring =~ s/8/b/sg;
        $checkerstring =~ s/9/q/sg;
        $checkerstring =~ s/\@/a/sg;
        $checkerstring =~ s/\$/s/sg;
        $checkerstring = lc($checkerstring);
        $checkerstring =~ s/[^abcdefghijklmnopqrstuvwxyz]*//sgi;
        if ($checkerstring =~ m/(spark|bann|kick|uteslut|utestang|exkommunicera|exkommunlcera|utstot|fordom|fordriv|fordrlv|klck|zlina|klina|glina|zline|kline|gline|zllna|kllna|gllna|zllne|kllne|gllne)/sgi) {
          $message = $arguments->{who}.": Nope, st\xE4ll vettigare fr\xE5gor \xE4n att slumpa ut att n\xE5gon ska bannas eller kickas.";
        }
        else
        {
          if (int($ytlock{$checkerstring}) < time) {
            $ytlock{$checkerstring} = time + 5*60;
            $datatodecide =~ s/[^a-zA-Z0-9åäöÅÄÖ\xE4\xE5\xF6\xC4\xC5\xD6\;\,\:\.\-\_\!\"\@\#\£\$\%\&\/\(\[\)\]\=\}\?\\\+\*\'\<\>\| ]*//sg;
            @allrandom = split(/\seller\s/si, $datatodecide);
            $randvalue = $allrandom[int(rand($#allrandom + 1))];
            $message = $arguments->{who}.": ".$randvalue;
          }
        }
      }
      else
      {
        $message = $arguments->{who}.": Kommandot m\xE5ste inneh\xE5lla minst 2 argument separerade med ordet \"eller\"";
      }
    }

    if ($arguments->{body} =~ m/flashback\.org\/(p|t|sp|u)(\d+)/i) {
      if (int($ytlock{$2}) < time) {
        $ytlock{$2} = time + 5*60;
        if (length($resultcache{$2}) > 1) {
          $message = $resultcache{$2};
        }
        else
        {       
          $response = $ua->get('https://www.flashback.org/'.$1.$2);
          $rbody = $response->decoded_content;
          $fbline = "fail";
          if ($rbody =~ m/<title>([^<]*)<\/title>/s) {
            $fbline = $1;
            if ($fbline eq "Flashback Forum") {
              $fbline = "fail"; # If thread is put in garbage bin we can't see the title. So instead of returning useless text, return nothing.
            }
            $fbline =~ s/\&auml\;/\xE4/sg;
            $fbline =~ s/\&aring\;/\xE5/sg;
            $fbline =~ s/\&ouml\;/\xF6/sg;
            $fbline =~ s/\&Auml\;/\xC4/sg;
            $fbline =~ s/\&Aring\;/\xC5/sg;
            $fbline =~ s/\&Ouml\;/\xD6/sg;
            $fbline =~ s/\&quot\;/\"/sg;
          }
          unless ($fbline eq "fail") {
            $resultcache{$2} = $fbline;
            $message = $fbline;
          }
        }
      }
    }


    if (($arguments->{body} =~ m/swehack\.org\/viewtopic\.php\?/i)&&($arguments->{body} =~ m/t=(\d+)/)) {
      if (int($ytlock{$1}) < time) {
        $ytlock{$1} = time + 5*60;
        if (length($resultcache{$1}) > 1) {
          $message = $resultcache{$1};
        }
        else
        {       
          $response = $ua->get('https://swehack.org/viewtopic.php?t='.$1);
          $rbody = $response->decoded_content;
          $sweline = "fail";
          if ($rbody =~ m/<title>([^<]*)<\/title>/s) {
            $sweline = $1;
            if (($sweline =~ m/swehack - Ett svenskt diskussionsforum om IT/)&&($sweline =~ m/(Information|Logga in)/)) {
              $sweline = "fail"; # Thread does not exist or are not accessible for guest, return nothing.
            }
            $sweline =~ s/\&auml\;/\xE4/sg;
            $sweline =~ s/\&aring\;/\xE5/sg;
            $sweline =~ s/\&ouml\;/\xF6/sg;
            $sweline =~ s/\&Auml\;/\xC4/sg;
            $sweline =~ s/\&Aring\;/\xC5/sg;
            $sweline =~ s/\&Ouml\;/\xD6/sg;
            $sweline =~ s/\&quot\;/\"/sg;
          }
          unless ($sweline eq "fail") {
            $resultcache{$1} = $sweline;
            $message = $sweline;
          }
        }
      }
    }


    if (($arguments->{body} =~ m/youtube\.com\/watch\?v=([a-zA-Z0-9-_]*)/i)||($arguments->{body} =~ m/youtu\.be\/([a-zA-Z0-9-_]*)/i)) {
      if (int($ytlock{$1}) < time) {
        $ytlock{$1} = time + 5*60;
        if (length($resultcache{$1}) > 1) {
          $message = $resultcache{$1};
        }
        else
        {       
          $response = $ua->get('https://www.googleapis.com/youtube/v3/videos?id='.$1.'&key='.$ytkey.'&fields=items(snippet(title),contentDetails(duration),statistics(viewCount))&part=snippet,contentDetails,statistics');
          $rbody = $response->decoded_content;
          $ytline = "fail";
          if ($rbody =~ m/^\{\n\s\"items\"\:\s\[\n\s\s\{\n\s\s\s\"snippet\"\:\s\{\n\s\s\s\s\"title\"\:\s\"(.*)\"\n\s\s\s\}\,\n\s\s\s\"contentDetails\"\:\s\{\n\s\s\s\s\"duration\"\:\s\"([PTHMS0123456789]*)\"\n\s\s\s\}\,\n\s\s\s\"statistics\"\:\s\{\n\s\s\s\s\"viewCount\"\:\s\"(\d*)\"\n\s\s\s\}\n\s\s\}\n\s\]\n\}$/s) {
            $duration = $2;
            $ytline = $1;
            $views = $3;
            $views = numprettify($views);
            $duration =~ s/^PT(\d+H)?(\d+M)?(\d+S)?$/$1:$2:$3/;
            $duration =~ s/[HMS]*//g;
            ($hours, $minutes, $seconds) = split(":", $duration);
            $hours = int($hours);
            $minutes = int($minutes);
            $seconds = int($seconds);
            if (int($hours) > 0) {
              if (int($minutes) < 10) {
                $minutes = "0".$minutes;
              }
              if (int($seconds) < 10) {
                $seconds = "0".$seconds;
              }
              $fulldur = "[".$hours.":".$minutes.":".$seconds."] ";
            }
            else
            {
              if (int($seconds) < 10) {
                $seconds = "0".$seconds;
              }
              $fulldur = "[".$minutes.":".$seconds."] ";
              if ($fulldur eq "[0:00] ") {
                $fulldur = "[S\xC4NDNING] ";
              }
            }
            $ytline =~ s/\\//sgi;
            $ytline =~ s/ä/\xE4/sg;
            $ytline =~ s/å/\xE5/sg;
            $ytline =~ s/ö/\xF6/sg;
            $ytline =~ s/Ä/\xC4/sg;
            $ytline =~ s/Å/\xC5/sg;
            $ytline =~ s/Ö/\xD6/sg;
            $ytline = $ytline . " - " . $fulldur . $views . " visningar";
          }
          unless ($ytline eq "fail") {
            $resultcache{$1} = $ytline;
            $message = $ytline;
          }
        }
      }
    }

    $opmessage = "false";
    if ($arguments->{body} eq ".help") {
      $message = $arguments->{who}.": Jag st\xF6djer: .help | .per | .butkus | .best\xE4m <val> | .morn | .cc (alias: .btc .xmr .ltc .bch)";
      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      $isowner = $self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who});
      $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
      if (($isop == 1)||($ishp == 1)) {
       $message = $message . "\n OP: .setwarn <nick> | .setkick <nick> | .status <nick> | .clruser <nick> | .clrall | .opmsg <msg>";
       $opmessage = "true";
      }
      if ($isowner == 1) {
       $message = $message . "\n \xC4GARE: .shutdown | .resetbot | .setnotwritten <nick> | .clrnotwritten <nick>";
       $opmessage = "true";
      }

    }
    if ($arguments->{body} eq ".morn") {
      $message = "Godmorgon ".$arguments->{who};
    }
    if (($arguments->{body} eq ".shutdown")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      $mailbody = "Hej. ".$arguments->{who}." beg\xE4rde ett avslut.\n";
      $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
      foreach $line (@log) {
        $mailbody = $mailbody . $line . "\n";
      }
      $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
      $maildate = email_date;
      $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => $mailsender, To => $mailtarget, Subject => "Avslut beg\xE4rt av ".$arguments->{who}." fr\xE5n ".$arguments->{channel}, Date => $maildate, Data => $mailbody);
      open MAIL, "| sudo -H -u ".$mailaccount." /usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"";
      $mime->print(\*MAIL);
      close MAIL;
      $self->shutdown("Avslut beg\xE4rt av ".$arguments->{who});
    }
    if (($arguments->{body} =~ m/^\.opmsg (.+)/)&&($self->pocoirc->is_channel_operator($arguments->{channel}, $arguments->{who}) == 1)) {
      if (($msgexpiry < time)||($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
        $msgexpiry = time + 60*60;
        $message = $1;
        $message =~ s/ä/\xE4/sg;
        $message =~ s/å/\xE5/sg;
        $message =~ s/ö/\xF6/sg;
        $message =~ s/Ä/\xC4/sg;
        $message =~ s/Å/\xC5/sg;
        $message =~ s/Ö/\xD6/sg;
        $mailbody = "Hej. En OP med namn ".$arguments->{who}." skickade dig ett ilmeddelande via OPMSG. Meddelandet \xE4r:\n";
        $mailbody = $mailbody . $message."\n\n";
        $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
        foreach $line (@log) {
          $mailbody = $mailbody . $line . "\n";
        }
        $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
        $maildate = email_date;
        $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => $mailsender, To => $mailtarget, Subject => "OP-meddelande fr\xE5n ".$arguments->{who}, Date => $maildate, Data => $mailbody);
        open MAIL, "| sudo -H -u ".$mailaccount." /usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"";
        $mime->print(\*MAIL);
        close MAIL;
        $message = $arguments->{who}.": Meddelande skickat!";
      }
      else
      {
        $message = $arguments->{who}.": .opmsg kan bara anv\xE4ndas en g\xE5ng i timmen!";
      }
    }
    if (($arguments->{body} eq ".resetbot")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      $lastclear = "0-0-0";
      $message = $arguments->{who}.": Rubbet rensat inkl cache!";
    }
    if (($arguments->{body} eq ".armprotection")&&($self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who}) == 1)&&($arguments->{who} eq "Sebastian")) {
      $armed = "true";
      $message = $arguments->{who}.": DeOP-skydd aktiverat!";
    }

    ( $day, $month, $year ) = (localtime)[3,4,5];
    $currentdate = $day."-".($month+1)."-".($year+1900);
    unless ($currentdate eq $lastclear) {
      $lastclear = $currentdate;
      %msg = ();
      %hasnotwritten = ();
      %ytlock = ();
      %resultcache = ();
      $cachedtime = 0;
      %cachedcontent = ();
      $msgexpiry = 0;
    }
    $hasnotwritten{$arguments->{who}} = 0;
    if (($self->pocoirc->is_channel_operator($arguments->{channel},'anna') == 1)||($self->pocoirc->is_channel_halfop($arguments->{channel},'anna') == 1)) {
      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
      $isad = $self->pocoirc->is_channel_admin($arguments->{channel},$arguments->{who});
      $isow = $self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who});
      $isv = $self->pocoirc->has_channel_voice($arguments->{channel},$arguments->{who});
      $ircop = $self->pocoirc->is_operator($arguments->{who});
      if (($isop == 1)||($ishp == 1)||($isad == 1)||($isow == 1)||($isv == 1)||($ircop == 1)) {
        $immunity = "true";
      }
      else
      {
        $immunity = "false";
      }
      if ($isow == 1) { #ONLY CHANNEL OWNER CAN EXECUTE THESE
        if ($arguments->{body} =~ m/^\.setnotwritten (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            $hasnotwritten{$user} = 1;
            $message = $arguments->{who}.": Satte hasnotwritten=1 p\xE5 $user.";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} =~ m/^\.clrnotwritten (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            $hasnotwritten{$user} = 0;
            $message = $arguments->{who}.": Satte hasnotwritten=0 p\xE5 $user.";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
      }

      if (($isop == 1)||($ishp == 1)) { # ONLY OPS/HALFOPS CAN EXECUTE THESE (INCLUDING OWNER)
        if ($arguments->{body} =~ m/^\.setwarn (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            $gethostname = $self->pocoirc->nick_long_form($user);
            ($fullname, $host) = split("\@", $gethostname);
            ($displayname, $realname) = split("\!", $fullname);
            $gethostname = substr($gethostname, length($gethostname) - 14, 14);
            $idnum = $gethostname;
            $idnum =~ s/\.//sgi;
            if ($gethostname eq ".4uh.b8obtf.IP") { # TOR .onion
              $idnum = $realname.$idnum;
            }
            $bucket = $msg{$idnum};
            unless ($bucket =~ m/:/) {
              $bucket = "0:0:0:0:0";
            }
            ($number, $exp, $lmsg, $kicked, $warned) = split(":", $bucket);
            $msg{$idnum} = $number.":".$exp.":".$lmsg.":".$kicked.":1";
            $message = $arguments->{who}.": Satte warned=1 p\xE5 $user.";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} =~ m/^\.setkick (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            $gethostname = $self->pocoirc->nick_long_form($user);
            ($fullname, $host) = split("\@", $gethostname);
            ($displayname, $realname) = split("\!", $fullname);
            $gethostname = substr($gethostname, length($gethostname) - 14, 14);
            $idnum = $gethostname;
            $idnum =~ s/\.//sgi;
            if ($gethostname eq ".4uh.b8obtf.IP") { # TOR .onion
              $idnum = $realname.$idnum;
            }
            $bucket = $msg{$idnum};
            unless ($bucket =~ m/:/) {
              $bucket = "0:0:0:0:0";
            }
            ($number, $exp, $lmsg, $kicked, $warned) = split(":", $bucket);
            $msg{$idnum} = $number.":".$exp.":".$lmsg.":1:".$warned;
            $message = $arguments->{who}.": Satte kicked=1 p\xE5 $user.";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} =~ m/^\.clruser (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            $gethostname = $self->pocoirc->nick_long_form($user);
            ($fullname, $host) = split("\@", $gethostname);
            ($displayname, $realname) = split("\!", $fullname);
            $gethostname = substr($gethostname, length($gethostname) - 14, 14);
            $idnum = $gethostname;
            $idnum =~ s/\.//sgi;
            if ($gethostname eq ".4uh.b8obtf.IP") { # TOR .onion
              $idnum = $realname.$idnum;
            }
            $msg{$idnum} = "0:0:0:0:0";
            $message = $arguments->{who}.": Rensade status p\xE5 $user.";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} =~ m/^\.status (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$user);
            $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$user);
            $isad = $self->pocoirc->is_channel_admin($arguments->{channel},$user);
            $isow = $self->pocoirc->is_channel_owner($arguments->{channel},$user);
            $isv = $self->pocoirc->has_channel_voice($arguments->{channel},$user);
            $ircop = $self->pocoirc->is_operator($user);
            if (($isop == 1)||($ishp == 1)||($isad == 1)||($isow == 1)||($isv == 1)||($ircop == 1)) {
              $immunity = "1";
            }
            else
            {
              $immunity = "0";
            }
            $gethostname = $self->pocoirc->nick_long_form($user);
            ($fullname, $host) = split("\@", $gethostname);
            ($displayname, $realname) = split("\!", $fullname);
            $gethostname = substr($gethostname, length($gethostname) - 14, 14);
            $idnum = $gethostname;
            $idnum =~ s/\.//sgi;
            if ($gethostname eq ".4uh.b8obtf.IP") { # TOR .onion
              $idnum = $realname.$idnum;
            }
            $bucket = $msg{$idnum};
            unless ($bucket =~ m/:/) {
              $bucket = "0:0:0:0:0";
            }
            ($number, $exp, $lmsg, $kicked, $warned) = split(":", $bucket);
            if ($hasnotwritten{$user} == 1) {
              $stat = "hasnotwritten=1";
            }
            else
            {
              $stat = "hasnotwritten=0";
            }
            $message = $arguments->{who}.": (".$idnum.") kicked=".$kicked." warned=".$warned." (".$user.") ".$stat." immunity=".$immunity." (OP=".int($isop)." HOP=".int($ishp)." ADM=".int($isad)." OWN=".int($isow)." VO=".int($isv)." IOP=".int($ircp).").";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} eq ".clrall") {
          %msg = ();
          $message = $arguments->{who}.": Rensade alla anv\xE4ndare.";
        }
      }

      if ($immunity eq "false") {
        $gethostname = $self->pocoirc->nick_long_form($arguments->{who});
        ($fullname, $host) = split("\@", $gethostname);
        ($displayname, $realname) = split("\!", $fullname);
        $gethostname = substr($gethostname, length($gethostname) - 14, 14);
        $idnum = $gethostname;
        $idnum =~ s/\.//sgi;
        if ($gethostname eq ".4uh.b8obtf.IP") { # TOR .onion
          $idnum = $realname.$idnum;
        }

        $checkerstring = $arguments->{body};
        $checkerstring =~ s/\.(btc|bch|ltc|xmr)/\.cc/sgi;
        $checkerstring =~ s/\.morn/\.help/sgi;
        $checkerstring =~ s/\.butkus/\.per/sgi;
        $checkerstring =~ s/\xE4/a/sg;
        $checkerstring =~ s/\xE5/a/sg;
        $checkerstring =~ s/\xF6/o/sg;
        $checkerstring =~ s/\xC4/a/sg;
        $checkerstring =~ s/\xC5/a/sg;
        $checkerstring =~ s/\xD6/o/sg;
        $checkerstring =~ s/0/o/sg;
        $checkerstring =~ s/1/l/sg;
        $checkerstring =~ s/2/z/sg;
        $checkerstring =~ s/3/e/sg;
        $checkerstring =~ s/4/a/sg;
        $checkerstring =~ s/5/s/sg;
        $checkerstring =~ s/6/b/sg;
        $checkerstring =~ s/7/t/sg;
        $checkerstring =~ s/8/b/sg;
        $checkerstring =~ s/9/q/sg;
        $checkerstring =~ s/\@/a/sg;
        $checkerstring =~ s/\$/s/sg;
        $checkerstring = lc($checkerstring); 
        $checkerstring =~ s/[^abcdefghijklmnopqrstuvwxyz]*//sgi;
        $checkerstring = substr($checkerstring, 0, 16);
        $bucket = $msg{$idnum};
        unless ($bucket =~ m/:/) {
          $bucket = "0:0:0:0:0";
        }
        ($number, $expiry, $lastmessage,$kicked,$warned) = split(":",$bucket);
       
        if ($expiry < time) {
          $newexpiry = time + 10;
          if ($lastmessage eq $checkerstring) {
            $msg{$idnum} = "2:".$newexpiry.":".$checkerstring.":".$kicked.":".$warned;
          }
          else
          {
            $msg{$idnum} = "1:".$newexpiry.":".$checkerstring.":".$kicked.":".$warned;
          }
        }
        else
        {
          if ($lastmessage eq $checkerstring) {
            $addnum = $number + 2;
          }
          else
          {
            $addnum = $number + 1;
          }
          $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":".$kicked.":".$warned;
          if (int($number) > 5) {
            if ($kicked eq "1") {
              if ($warned eq "1") {
                if ($gethostname eq ".4uh.b8obtf.IP") { # TOR .onion
                  $banname = $realname;
                }
                else
                {
                  $banname = "";
                }
                $self->mode($arguments->{channel}." +b *!*".$banname."\@*".$gethostname);
                $self->kick($arguments->{channel}, $arguments->{who}, "Du slutade inte spamma!");
                $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":1:1"; #We won't reset as there might be multiple users with same hostname in channel.
                $mailbody = "Hej. Jag bannade just nu en spammare med nicket ".$arguments->{who}." (host: ".$gethostname.") fr\xE5n ".$arguments->{channel}."\n";
                if (length($banname) > 0) {
                  $mailbody = $mailbody . "Anv\xE4ndaren \xE4r en TOR-anv\xE4ndare, s\xE5 jag bannade baserat p\xE5 realname ".$banname.".\n";
                }
                $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
                foreach $line (@log) {
                  $mailbody = $mailbody . $line . "\n";
                }
                $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";

                $maildate = email_date;
                $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From =>  From => $mailsender, To => $mailtarget, Subject => "Bannade ".$arguments->{who}." fr\xE5n ".$arguments->{channel}, Date => $maildate, Data => $mailbody);
                open MAIL, "| sudo -H -u ".$mailaccount." /usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"";
                $mime->print(\*MAIL);
                close MAIL;
              }
              else
              {
                $message = $arguments->{who}." ($gethostname): !!VARNING!! Om du forts\xE4tter att spamma kommer du att bli BANNAD!";
                $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":1:1";
              }
            }
            else
            {
              if ($warned eq "1") {
                $self->kick($arguments->{channel}, $arguments->{who}, "Sluta spamma!");
                $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":1:0";
                $mailbody = "Hej. Jag kickade just nu en spammare med nicket ".$arguments->{who}." (host: ".$gethostname.") fr\xE5n ".$arguments->{channel}."\n";
                $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
                foreach $line (@log) {
                  $mailbody = $mailbody . $line . "\n";
                }
                $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
                $maildate = email_date;
                $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => $mailsender, To => $mailtarget, Subject => "Kickade ".$arguments->{who}." fr\xE5n ".$arguments->{channel}, Date => $maildate, Data => $mailbody);
                open MAIL, "| sudo -H -u ".$mailaccount." /usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"";
                $mime->print(\*MAIL);
                close MAIL;
              }
              else
              {
                $message = $arguments->{who}." ($gethostname): !!VARNING!! Om du forts\xE4tter att spamma kommer du att bli kickad!";
                $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":0:1";
              }
            }# kicked check
          } # number check
        } #expiry check
      } #immunity check
    }     
  }
  if (length($message) > 0) {
    if ($opmesssage eq "false") {
      $message =~ s/\r//sgi;
      $message =~ s/\n//sgi;
      $message = substr($message,0,150);
    }
    push(@log, "<\@anna> $message");
    if ($#log > 40) {
      shift(@log);
    }
    return $message;
  }
  else
  {
    return undef;
  }
}

sub kicked {
  $self      = shift;
  $arguments = shift;
  push(@log, "*** ".$arguments->{who}." kickade ".$arguments->{kicked}." fr\xE5n ".$arguments->{channel});
  if ($#log > 40) {
    shift(@log);
  }
  unless ($arguments->{who} eq "anna") {
    if (($arguments->{kicked} eq "anna")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) != 1)&&($arguments->{who} ne "ChanServ")) {
      $self->say(channel => "msg", who => "ChanServ", body => "UNBAN ".$arguments->{channel});
      $self->say(channel => "msg", who => "ChanServ", body => "DEOP ".$arguments->{channel}." ".$arguments->{who});
      $self->join($arguments->{channel});
      $self->say(channel => $arguments->{channel}, body => $arguments->{who}.": Missbruka inte dina OP-funktioner!");
      push(@log, "<\@anna> ".$arguments->{who}.": Missbruka inte dina OP-funktioner!");
      if ($#log > 40) {
        shift(@log);
      }
      $mailbody = "Hej. Jag deoppade just nu en maktmissbrukande OP med namnet ".$arguments->{who}." fr\xE5n ".$arguments->{channel}." som kickade eller bannade mig (anna) utan anledning.\n";
      $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
      foreach $line (@log) {
        $mailbody = $mailbody . $line . "\n";
      }
      $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
      $maildate = email_date;
      $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => $mailsender, To => $mailtarget, Subject => "Deoppade bot-kickern ".$arguments->{who}." fr\xE5n ".$arguments->{channel}, Date => $maildate, Data => $mailbody);
      open MAIL, "| sudo -H -u ".$mailaccount." /usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"";
      $mime->print(\*MAIL);
      close MAIL;
    }
    else
    {
      if (($hasnotwritten{$arguments->{kicked}} == 1)&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) != 1)&&($self->pocoirc->is_channel_operator($arguments->{channel},'anna') == 1)&&($arguments->{who} ne "ChanServ")) {
        $self->mode($arguments->{channel}." -oh ".$arguments->{who});
        $self->say(channel => $arguments->{channel}, body => $arguments->{who}.": Missbruka inte dina OP-funktioner!");
        push(@log, "<\@anna> ".$arguments->{who}.": Missbruka inte dina OP-funktioner!");
        if ($#log > 40) {
          shift(@log);
        }
        $mailbody = "Hej. Jag deoppade just nu en maktmissbrukande OP med namnet ".$arguments->{who}." fr\xE5n ".$arguments->{channel}." som spamkickar ".$arguments->{kicked}." utan anledning.\n";
        $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
        foreach $line (@log) {
          $mailbody = $mailbody . $line . "\n";
        }
        $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
        $maildate = email_date;
        $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => $mailsender, To => $mailtarget, Subject => "Deoppade ".$arguments->{who}." fr\xE5n ".$arguments->{channel}, Date => $maildate, Data => $mailbody);
        open MAIL, "| sudo -H -u ".$mailaccount." /usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"";
        $mime->print(\*MAIL);
        close MAIL;
      }
    }
  }
  $hasnotwritten{$arguments->{kicked}} = 1;
}


sub numprettify {
  $number = $_[0];
  if ((length($number) > 3)&&(length($number) < 7)) {
    $number = substr($number, 0, length($number) - 3)." ".substr($number, length($number) - 3, 3);
  }
  else
  {
    if ((length($number) > 6)&&(length($number) < 10)) {
      $number = substr($number, 0, length($number) - 6)." ".substr($number, length($number) - 6, 3)." ".substr($number, length($number) - 3, 3);
    }
    else
    {
      if ((length($number) > 9)&&(length($number) < 13)) {
        $number = substr($number, 0, length($number) - 9)." ".substr($number, length($number) - 9, 3)." ".substr($number, length($number) - 6, 3)." ".substr($number, length($number) - 3, 3);
      }
      else
      {
        if (length($number) > 12) {
          $number = substr($number, 0, length($number) - 12)." ".substr($number, length($number) - 12, 3)." ".substr($number, length($number) - 9, 3)." ".substr($number, length($number) - 6, 3)." ".substr($number, length($number) - 3, 3);
        }
      }
    }
  }
  return $number;
}

package main;

$channelpassword = "ENTER_YOUR_NICKSERV_PASSWORD_HERE";

$bot = SebbeBot->new(
  server      => 'irc.swehack.org',
  port        => '6697',
  ssl         => 1,
  channels    => ['#laidback','#bot_test'],
  password    => $channelpassword,
  nick        => 'anna',
  name        => 'Sebastian Nielsen',
  ignore_list => ['NickServ','ChanServ'],
);
$bot->run();
