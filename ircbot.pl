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
$armed = 0;

open(YTKEY, "./botkey.txt");
$botytkey = <YTKEY>;
close(YTKEY);
$botytkey =~ s/\n//sgi;


sub said {
  $self      = shift;
  $arguments = shift;    # Contains the message that the bot heard.
  $ua = LWP::UserAgent->new;
  $message = "";
  ( $seclog, $minlog, $hourlog ) = (localtime)[0,1,2];
  if (length($seclog) == 1) {
    $seclog = "0".$seclog;
  }
  if (length($minlog) == 1) {
    $minlog = "0".$minlog;
  }
  if (length($hourlog) == 1) {
    $hourlog = "0".$hourlog;
  }
  $timestampprefix = "[".$hourlog.":".$minlog.":".$seclog;
  unless (($arguments->{channel} eq "msg")||($arguments->{who} eq "JuliaBot")||($arguments->{who} eq "ChanServ")||($arguments->{who} eq "NickServ")) {
    if ($armed > 9) {
      if ($self->pocoirc->is_channel_operator($arguments->{channel},'anna') != 1) {
        $self->say(channel => "msg", who => "ChanServ", body => "OP ".$arguments->{channel});
        push(@log, $timestampprefix. "] *** N\xE5gon idiot som deoppade mig. Reoppar i ".$arguments->{channel});
        if ($#log > 40) {
          shift(@log);
        }
      }
    }
    $hasnotwritten{$arguments->{who}} = 0;
    $nickprefix = "";
    if ($self->pocoirc->has_channel_voice($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\+";
    }
    if ($self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\%";
    }
    if ($self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\@";
    }
    if ($self->pocoirc->is_channel_admin($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\&";
    }
    if ($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1) {
      $nickprefix = "\~";
    }

    push(@log, $timestampprefix . "] <".$nickprefix.$arguments->{who}."> ".$arguments->{body});
    if ($#log > 40) {
      shift(@log);
    }


    if (($arguments->{body} eq ".btc")||($arguments->{body} eq ".cc")||($arguments->{body} eq ".ltc")||($arguments->{body} eq ".xmr")||($arguments->{body} eq ".bch")||($arguments->{body} eq ".xrp")||($arguments->{body} eq ".eth")||($arguments->{body} eq ".doge")) {
      if (int($ytlock{'CRYPTOCURRENCY_FETCH'}) < time) {
        $ytlock{'CRYPTOCURRENCY_FETCH'} = time + 5*60;
        if ($cachedtime < time) {
          $response = $ua->get('https://api.coinmarketcap.com/v1/ticker/?convert=SEK&limit=40');
          $rbody = $response->decoded_content;
          $rbody =~ s/\n//sgi;
          $rbody =~ s/\r//sgi;
          $rbody =~ s/\s//sgi;
          $rbody =~ s/\[\{\"id\":\"(.*)\}\]/$1/sgi;
          @coindata = split(/\},\{\"id\":\"/, $rbody);
          foreach $coin (@coindata) {
            if (($coin =~ m/^bitcoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
              $cachedcontent{'btc'} = "[BTC] \$".numprettify($1)." / ".numprettify($3)." kr";
            }
            if (($coin =~ m/^litecoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
              $cachedcontent{'ltc'} = "[LTC] \$".numprettify($1)." / ".numprettify($3)." kr";
            }
            if (($coin =~ m/^monero\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
              $cachedcontent{'xmr'} = "[XMR] \$".numprettify($1)." / ".numprettify($3)." kr";
            }
            if (($coin =~ m/^bitcoin-cash\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
              $cachedcontent{'bch'} = "[BCH] \$".numprettify($1)." / ".numprettify($3)." kr";
            }
            if (($coin =~ m/^ethereum\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
              $cachedcontent{'eth'} = "[ETH] \$".numprettify($1)." / ".numprettify($3)." kr";
            }
            if (($coin =~ m/^ripple\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
              $cachedcontent{'xrp'} = "[XRP] \$".numprettify($1)." / ".numprettify($3)." kr";
            }
            if (($coin =~ m/^dogecoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
              $cachedcontent{'doge'} = "[DOGE] \$".numprettify($1)." / ".numprettify($3)." kr";
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
          $message = "$cachedcontent{'btc'} | $cachedcontent{'xmr'} | $cachedcontent{'ltc'} | $cachedcontent{'bch'} | $cachedcontent{'eth'} | $cachedcontent{'xrp'} | $cachedcontent{'doge'} | $cached";
        }
        if ($arguments->{body} eq ".ltc") {
          $message = "$cachedcontent{'ltc'} | $cachedcontent{'xmr'} | $cachedcontent{'btc'} | $cachedcontent{'bch'} | $cachedcontent{'eth'} | $cachedcontent{'xrp'} | $cachedcontent{'doge'} | $cached";
        }
        if ($arguments->{body} eq ".xmr") {
          $message = "$cachedcontent{'xmr'} | $cachedcontent{'btc'} | $cachedcontent{'ltc'} | $cachedcontent{'bch'} | $cachedcontent{'eth'} | $cachedcontent{'xrp'} | $cachedcontent{'doge'} | $cached";
        }
        if ($arguments->{body} eq ".bch") {
          $message = "$cachedcontent{'bch'} | $cachedcontent{'xmr'} | $cachedcontent{'ltc'} | $cachedcontent{'btc'} | $cachedcontent{'eth'} | $cachedcontent{'xrp'} | $cachedcontent{'doge'} | $cached";
        }
        if ($arguments->{body} eq ".eth") {
          $message = "$cachedcontent{'eth'} | $cachedcontent{'xmr'} | $cachedcontent{'ltc'} | $cachedcontent{'btc'} | $cachedcontent{'bch'} | $cachedcontent{'xrp'} | $cachedcontent{'doge'} | $cached";
        }
        if ($arguments->{body} eq ".xrp") {
          $message = "$cachedcontent{'xrp'} | $cachedcontent{'xmr'} | $cachedcontent{'ltc'} | $cachedcontent{'btc'} | $cachedcontent{'eth'} | $cachedcontent{'bch'} | $cachedcontent{'doge'} | $cached";
        }
        if ($arguments->{body} eq ".doge") {
          $message = "$cachedcontent{'doge'} | $cachedcontent{'xmr'} | $cachedcontent{'ltc'} | $cachedcontent{'btc'} | $cachedcontent{'eth'} | $cachedcontent{'bch'} | $cachedcontent{'xrp'} | $cached";
        }
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
          $response = $ua->get('https://www.googleapis.com/youtube/v3/videos?id='.$1.'&key='.$botytkey.'&fields=items(snippet(title),contentDetails(duration),statistics(viewCount,likeCount,dislikeCount))&part=snippet,contentDetails,statistics');
          $rbody = $response->decoded_content;
          $ytline = "fail";
          if ($rbody =~ m/^\{\n\s\"items\"\:\s\[\n\s\s\{\n\s\s\s\"snippet\"\:\s\{\n\s\s\s\s\"title\"\:\s\"(.*)\"\n\s\s\s\}\,\n\s\s\s\"contentDetails\"\:\s\{\n\s\s\s\s\"duration\"\:\s\"([PTHMS0123456789]*)\"\n\s\s\s\}\,\n\s\s\s\"statistics\"\:\s\{\n\s\s\s\s\"viewCount\"\:\s\"(\d*)\"\,\n\s\s\s\s\"likeCount\"\:\s\"(\d*)\"\,\n\s\s\s\s\"dislikeCount\"\:\s\"(\d*)\"\n\s\s\s\}\n\s\s\}\n\s\]\n\}$/s) {
            $duration = $2;
            $ytline = $1;
            $views = $3;
            $likes = $4;
            $dislikes = $5;
            if (int($likes) == 0) {
              $likes = 1;
            }
            $percentage = int((int($likes) / int(int($likes) + int($dislikes)))*100);
            $views = numprettify($views);
            $duration =~ s/^PT(\d+H)?(\d+M)?(\d+S)?$/$1:$2:$3/;
            $duration =~ s/[HMS]*//g;
            ($hours, $minutes, $seconds) = split(":", $duration);
            $hours = int($hours);
            $minutes = int($minutes);
            $seconds = int($seconds);
            $subject = " visningar";
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
                $subject = " tittare";
              }
            }
            $ytline =~ s/\\//sgi;
            $ytline =~ s/ä/\xE4/sg;
            $ytline =~ s/å/\xE5/sg;
            $ytline =~ s/ö/\xF6/sg;
            $ytline =~ s/Ä/\xC4/sg;
            $ytline =~ s/Å/\xC5/sg;
            $ytline =~ s/Ö/\xD6/sg;
            $ytline = $ytline . " - " . $fulldur . $views . $subject . " (Gillas: ".$percentage."\%)";
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
      $message = $arguments->{who}.": Jag st\xF6djer: .help | .cc (alias: .btc .xmr .ltc .bch .eth .xrp .doge) | .fetchlog";
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

    if ($arguments->{body} eq ".fetchlog") {
      if (int($ytlock{'FETCHLOG_COMMAND'}) < time) {
        if (int($ytlock{'FETCHLOG_COMMAND'.$arguments->{who}}) < time) {
          $ytlock{'FETCHLOG_COMMAND'} = time + 20;
          $ytlock{'FETCHLOG_COMMAND'.$arguments->{who}} = time + 5*60;
          $message = $arguments->{who}.": Du har PM fr\xE5n mig med loggen!";
          $self->say(channel => "msg", who => $arguments->{who}, body => "H\xE4r kommer de 20 senaste meddelandena:");
          $i = 0;
          foreach $msgline (@log) {
            if ($i < 20) {
              $self->say(channel => "msg", who => $arguments->{who}, body => $msgline);
              $i++;
            }
            else
            {
              last;
            }
          }
        }
      }
    }

    if (($arguments->{body} eq ".shutdown")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      transmitmail("Hej. ".$arguments->{who}." beg\xE4rde ett avslut.\n");
      $self->shutdown("Avslut beg\xE4rt av ".$arguments->{who});
    }
    $opmsgallowed = "false";
    if ($self->pocoirc->is_channel_operator($arguments->{channel}, $arguments->{who}) == 1) {
      $opmsgallowed = "true";
    }
    if ($arguments->{who} eq "topcat") {
      $opmsgallowed = "true";
    }

    if (($arguments->{body} =~ m/^\.opmsg (.+)/)&&($opmsgallowed eq "true")) {
      if (($msgexpiry < time)||($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
        $msgexpiry = time + 60*60;
        $inmessage = $1;
        $inmessage =~ s/ä/\xE4/sg;
        $inmessage =~ s/å/\xE5/sg;
        $inmessage =~ s/ö/\xF6/sg;
        $inmessage =~ s/Ä/\xC4/sg;
        $inmessage =~ s/Å/\xC5/sg;
        $inmessage =~ s/Ö/\xD6/sg;
        transmitmail("OP-meddelande fr\xE5n ".$arguments->{who}." via OPMSG. Meddelandet \xE4r:\n".$inmessage);
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
    if ($armed < 10) {
      $armed++;
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

    if (($self->pocoirc->is_channel_operator($arguments->{channel},'anna') == 1)||($self->pocoirc->is_channel_halfop($arguments->{channel},'anna') == 1)) {
      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
      $isad = $self->pocoirc->is_channel_admin($arguments->{channel},$arguments->{who});
      $isow = $self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who});
      $isv = $self->pocoirc->has_channel_voice($arguments->{channel},$arguments->{who});
      $ircop = $self->pocoirc->is_operator($arguments->{who});
      $ign = $self->ignore_nick($arguments->{who});
      if (($isop == 1)||($ishp == 1)||($isad == 1)||($isow == 1)||($isv == 1)||($ircop == 1)||($ign == 1)) {
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
            ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($user));
            $bucket = $msg{$uidn};
            unless ($bucket =~ m/:/) {
              $bucket = "0:0:0:0:0";
            }
            ($number, $exp, $lmsg, $kicked, $warned) = split(":", $bucket);
            if (int($warned) > 0) {
              $msg{$uidn} = $number.":".$exp.":".$lmsg.":0:2";
              if ($kicked eq "1") {
                $message = $arguments->{who}.": Satte kicked=0, warned=2 p\xE5 $user.";
              }
              else
              {
                $message = $arguments->{who}.": Satte warned=2 p\xE5 $user.";
              }
            }
            else
            {
              $msg{$uidn} = $number.":".$exp.":".$lmsg.":".$kicked.":1";
              $message = $arguments->{who}.": Satte warned=1 p\xE5 $user.";
            }
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} =~ m/^\.setkick (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($user));
            $bucket = $msg{$uidn};
            unless ($bucket =~ m/:/) {
              $bucket = "0:0:0:0:0";
            }
            ($number, $exp, $lmsg, $kicked, $warned) = split(":", $bucket);
            if ($warned eq "2") {
              $msg{$uidn} = $number.":".$exp.":".$lmsg.":1:1";
              $message = $arguments->{who}.": Satte kicked=1, warned=1 p\xE5 $user.";
            }
            else
            {
              $msg{$uidn} = $number.":".$exp.":".$lmsg.":1:".$warned;
              $message = $arguments->{who}.": Satte kicked=1 p\xE5 $user.";
            }
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} =~ m/^\.clruser (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($user));
            $msg{$uidn} = "0:0:0:0:0";
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
            $ign = $self->ignore_nick($user);
            if (($isop == 1)||($ishp == 1)||($isad == 1)||($isow == 1)||($isv == 1)||($ircop == 1)||($ign == 1)) {
              $immunity = "1";
            }
            else
            {
              $immunity = "0";
            }
            ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($user));
            $bucket = $msg{$uidn};
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
            $message = $arguments->{who}.": (".$uidn.") kicked=".$kicked." warned=".$warned." tor=".$uist." (".$user.") ".$stat." immunity=".$immunity." (OP=".int($isop)." HOP=".int($ishp)." ADM=".int($isad)." OWN=".int($isow)." VO=".int($isv)." IOP=".int($ircop)." IGN=".int($ign).").";
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
        ($istor, $idnum, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($arguments->{who}));

        $checkerstring = $arguments->{body};
        $checkerstring =~ s/\.(btc|bch|ltc|xmr|eth|xrp)/\.cc/sgi;
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
                $self->mode($arguments->{channel}." +b ".$banmask);
                $self->kick($arguments->{channel}, $arguments->{who}, "Du slutade inte spamma!");
                $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":1:1"; #We won't reset as there might be multiple users with same hostname in channel.
                $tempbody = "Bannade spammare ".$arguments->{who}." (host: ".$displayid.") fr\xE5n ".$arguments->{channel}."\n";
                if ($istor eq "1") {
                  $tempbody = $tempbody . "Anv\xE4ndaren \xE4r en TOR-anv\xE4ndare, s\xE5 jag bannade genom att anv\xE4nda ".$banmask." .\n";
                }
                transmitmail($tempbody."\n");
              }
              else
              {
                $message = $arguments->{who}." ($displayid): !!VARNING!! Om du forts\xE4tter att spamma kommer du att bli BANNAD!";
                $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":1:1";
              }
            }
            else
            {
              if ($warned eq "2") {
                $self->kick($arguments->{channel}, $arguments->{who}, "Sluta spamma!");
                $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":1:0";
                transmitmail("Kickade spammare ".$arguments->{who}." (host: ".$displayid.") fr\xE5n ".$arguments->{channel}."\n");
              }
              else
              {
                if ($warned eq "1") {
                  $message = $arguments->{who}." ($displayid): !!VARNING!! Om du forts\xE4tter att spamma kommer du att bli kickad!";
                  $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":0:2";
                }
                else
                {
                  $message = $arguments->{who}." ($displayid): !!VARNING!! Var sn\xE4ll och sluta spamma!!";
                  $msg{$idnum} = $addnum.":".$expiry.":".$checkerstring.":0:1";
                }
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
    push(@log, $timestampprefix."] <\@anna> $message");
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
  ( $seclog, $minlog, $hourlog ) = (localtime)[0,1,2];
  if (length($seclog) == 1) {
    $seclog = "0".$seclog;
  }
  if (length($minlog) == 1) {
    $minlog = "0".$minlog;
  }
  if (length($hourlog) == 1) {
    $hourlog = "0".$hourlog;
  }
  $timestampprefix = "[".$hourlog.":".$minlog.":".$seclog;
  push(@log, $timestampprefix. "] *** ".$arguments->{who}." kickade ".$arguments->{kicked}." fr\xE5n ".$arguments->{channel});
  if ($#log > 40) {
    shift(@log);
  }
  unless ($arguments->{who} eq "anna") {
    if (($arguments->{kicked} eq "anna")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) != 1)&&($arguments->{who} ne "ChanServ")) {
      $self->say(channel => "msg", who => "ChanServ", body => "UNBAN ".$arguments->{channel});
      $self->say(channel => "msg", who => "ChanServ", body => "DEOP ".$arguments->{channel}." ".$arguments->{who});
      $self->join($arguments->{channel});
      $self->say(channel => $arguments->{channel}, body => $arguments->{who}.": Missbruka inte dina OP-funktioner!");
      push(@log, $timestampprefix."] <\@anna> ".$arguments->{who}.": Missbruka inte dina OP-funktioner!");
      if ($#log > 40) {
        shift(@log);
      }
      transmitmail("Deoppade maktgalen OP ".$arguments->{who}." fr\xE5n ".$arguments->{channel}." som kickar mig (anna) utan anledning.\n");
    }
    else
    {
      if (($hasnotwritten{$arguments->{kicked}} == 1)&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) != 1)&&($self->pocoirc->is_channel_operator($arguments->{channel},'anna') == 1)&&($arguments->{who} ne "ChanServ")&&($arguments->{kicked} ne "JuliaBot")) {
        $self->mode($arguments->{channel}." -oh ".$arguments->{who});
        $self->say(channel => $arguments->{channel}, body => $arguments->{who}.": Missbruka inte dina OP-funktioner!");
        push(@log, $timestampprefix."] <\@anna> ".$arguments->{who}.": Missbruka inte dina OP-funktioner!");
        if ($#log > 40) {
          shift(@log);
        }
        transmitmail("Deoppade maktgalen OP ".$arguments->{who}." fr\xE5n ".$arguments->{channel}." som spamkickar ".$arguments->{kicked}." utan anledning.\n");
      }
    }
  }
  $hasnotwritten{$arguments->{kicked}} = 1;
}

sub transmitmail { #Sends a simple mail. Text in first argument. Log and the rest of text is included automatically.
  $mailbody = $_[0];
  $mailsubject = $_[0];
  $mailsubject =~ s/\n//sgi;
  $mailsubject = substr($mailsubject, 0, 50);
  $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
  foreach $line (@log) {
    $mailbody = $mailbody . $line . "\n";
  }
  $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
  $maildate = email_date;
  $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => "Boten Anna <anna\@sebbe.eu>", To => "sebastian\@sebbe.eu", Subject => $mailsubject, Date => $maildate, Data => $mailbody);
  open(MAIL, "| sudo -H -u server /usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"");
  $mime->print(\*MAIL);
  close MAIL;
}

sub getidfromhost { #This function calculates if a user is the .onion TOR endpoint, an unique ID-number to use during spam counting, an displayed ID using in warnings, and a banmask to be used if such a user needs to be banned.
  $fullhost = $_[0];
  ($parta, $partb) = split(/\@/, $fullhost);
  ($partaa, $partab) = split(/\!/, $parta);
  ($partba, @tpartbb) = split(/\./, $partb);
  $partbb = "";
  foreach $pp (@tpartbb) {
    $partbb = $partbb. "." . $pp;
  }
  if ($partbb =~ m/^\.[^.]*$/) {
    $partbb = $partb; # If a user has a rhost like mycompany.com with cloak disabled (-x) we risk banning the whole .com domain. This avoids it.
  }
  if (($partb eq "swehack-q25.4uh.b8obtf.IP")||($partb eq "127.0.0.1")) { # Host is TOR .onion node. To ban these, we need to rely on usernames instead.
     $banmask = "*!*".$partab."\@*".$partbb;
     $istor = "1";
     $idnum = $partab.$partbb; #Counting spam must also be done differently so 2 TOR users discussing things does not trigger the spam kick/ban system.
  }
  else
  {  # Host is NOT tor onion node. Ban normally.
     $banmask = "*!*\@*".$partbb;
     $istor = "0";
     $idnum = $partbb; #Counting spam can be done normally.
  }
  $idnum = lc($idnum);
  $idnum =~ s/[^a-z0-9]*//sgi;
  $displayid = $partbb;
  return ($istor, $idnum, $displayid, $banmask);
}

sub numprettify { # This function visually prettifies a float. This by rounding off to 3 decimals if the integer is lower than 10, else it strips off decimals completely. And then adding spaces each 3rd digit.
  $number = $_[0];
  if (($number =~ m/\./)&&(int($number) < 10)) {
    ($numinteger, $numdecimal) = split(/\./, $number);
    $number = $numinteger;
    $numdecimal = substr($numdecimal, 0, 3);
    if (length($numdecimal) == 1) {
      $numdecimal = $numdecimal . "0";
    }
    if (length($numdecimal) == 2) {
      $numdecimal = $numdecimal . "0";
    }
  }
  else
  {
    $numdecimal = "";
    $number = int($number);
  }
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
  if (length($numdecimal) > 0) {
    return $number.",".$numdecimal;
  }
  else
  {
    return $number;
  }
}

package main;

open(TXT, "./botpassword.txt");
$bot_password = <TXT>;
close(TXT);
$bot_password =~ s/\n//sgi;

#Flood protection disabled for PM's. There is already a flood protection for public messages.
$bot = SebbeBot->new(
  server      => 'irc.swehack.org',
  port        => '6697',
  ssl         => 1,
  flood       => 1,
  channels    => ['#laidback','#bot_test'],
  password    => $bot_password,
  nick        => 'anna',
  name        => 'Sebastian Nielsen',
  ignore_list => ['NickServ','ChanServ','JuliaBot'],
);
$bot->run();
