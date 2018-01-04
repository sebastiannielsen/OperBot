#!/usr/local/bin/perl

use LWP::UserAgent;
use MIME::Entity;
use Email::Date::Format 'email_date';


package SebbeBot;
use base 'Bot::BasicBot';

@log = ();
%ytlock = ();

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
    if ($#log > 20) {
      shift(@log);
    }


    if (($arguments->{body} eq ".btc")||($arguments->{body} eq ".cc")||($arguments->{body} eq ".ltc")||($arguments->{body} eq ".xmr")||($arguments->{body} eq ".bch")||($arguments->{body} eq ".xrp")||($arguments->{body} eq ".eth")||($arguments->{body} eq ".doge")) {
      $message = do_cryptocurrency($arguments->{body});
    }

    if ($arguments->{body} =~ m/flashback\.org\/(p|t|sp|u)(\d+)/i) {
      $message = do_flashback($1.$2);
    }

    if (($arguments->{body} =~ m/swehack\.org\/viewtopic\.php\?/i)&&($arguments->{body} =~ m/(t=|p=)(\d+)/)) {
      $message = do_swehack($1.$2);
    }

    if (($arguments->{body} =~ m/youtube\.com\/watch\?[^v]*v=([a-zA-Z0-9-_]*)/i)||($arguments->{body} =~ m/youtu\.be\/([a-zA-Z0-9-_]*)/i)) {
      $message = do_youtube($1);
    }


    $opmessage = "false";
    if ($arguments->{body} eq ".help") {
      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
      $message = $arguments->{who}.": Jag st\xF6djer: .help | .cc (alias: .btc .xmr .ltc .bch .eth .xrp .doge) | .fetchlog";
      if (($isop == 1)||($ishp == 1)) {
       $message = $message . "\n OP:: .shutdown | .resetbot";
       $opmessage = "true";
      }
    }

    if ($arguments->{body} eq ".fetchlog") {
      if (int($ytlock{'FETCHLOG!_COMMAND'}) < time) {
        if (int($ytlock{'FETCHLOG!_COMMAND'.$arguments->{who}}) < time) {
          $ytlock{'FETCHLOG!_COMMAND'} = time + 20;
          $ytlock{'FETCHLOG!_COMMAND'.$arguments->{who}} = time + 5*60;
          $message = $arguments->{who}.": Du har PM fr\xE5n mig med loggen!";
          $self->say(channel => "msg", who => $arguments->{who}, body => "H\xE4r kommer de 20 senaste meddelandena:");
          foreach $msgline (@log) {
            $self->say(channel => "msg", who => $arguments->{who}, body => $msgline);
          }
        }
      }
    }

    if (($arguments->{body} eq ".shutdown")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      $self->shutdown("Avslut beg\xE4rt av ".$arguments->{who});
    }

    if (($arguments->{body} eq ".resetbot")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      $lastclear = "0-0-0";
      $message = $arguments->{who}.": Rubbet rensat inkl cache!";
    }

    ( $day, $month, $year ) = (localtime)[3,4,5];
    $currentdate = $day."-".($month+1)."-".($year+1900);
    unless ($currentdate eq $lastclear) {
      $lastclear = $currentdate;
      %ytlock = ();
    }

  }
  if (length($message) > 0) {
    if ($opmesssage eq "false") {
      $message =~ s/\r//sgi;
      $message =~ s/\n//sgi;
      $message = substr($message,0,150);
    }
    push(@log, $timestampprefix."] <SebbeBot> $message");
    if ($#log > 20) {
      shift(@log);
    }
    return $message;
  }
  else
  {
    return undef;
  }
}

sub kicked { # This function is called everytime ANYONE is kicked in the channel.
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
  if ($#log > 20) {
    shift(@log);
  }
}

sub do_youtube { # This function is called anytime a Youtube URL is encountered.
  $ytid = $_[0];
  if (int($ytlock{'YT!'.$ytid}) < time) {
    $ytlock{'YT!'.$ytid} = time + 5*60;
    if (length($ytlock{'YTC!'.$ytid}) > 1) {
      $message = $ytlock{'YTC!'.$ytid};
    }
    else
    {
      $response = $ua->get('https://www.googleapis.com/youtube/v3/videos?id='.$ytid.'&key='.$botytkey.'&fields=items(snippet(title),contentDetails(duration),statistics(viewCount,likeCount,dislikeCount))&part=snippet,contentDetails,statistics');
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
        $ytlock{'YTC!'.$ytid} = $ytline;
        $message = $ytline;
      }
    }
  }
  return $message;
}


sub do_swehack { # This function is called anytime a Swehack forum URL is encountered.
  $threadid = $_[0];
  if (int($ytlock{'SH!'.$threadid}) < time) {
    $ytlock{'SH!'.$threadid} = time + 5*60;
    if (length($ytlock{'SHC!'.$threadid}) > 1) {
      $message = $ytlock{'SHC!'.$threadid};
    }
    else
    {
      $response = $ua->get('https://swehack.org/viewtopic.php?'.$threadid);
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
        $ytlock{'SHC!'.$threadid} = $sweline;
        $message = $sweline;
      }
    }
  }
  return $message;
}

sub do_flashback { # This function is called anytime a Flashback forum URL is encountered.
  $threadid = $_[0];
  if (int($ytlock{'FB!'.$threadid}) < time) {
    $ytlock{'FB!'.$threadid} = time + 5*60;
    if (length($ytlock{'FBC!'.$threadid}) > 1) {
      $message = $ytlock{'FBC!'.$threadid};
    }
    else
    {
      $response = $ua->get('https://www.flashback.org/'.$threadid);
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
        $ytlock{'FBC!'.$threadid} = $fbline;
        $message = $fbline;
      }
    }
  }
  return $message;
}


sub do_cryptocurrency { # This function is called everytime somebody requests information about cryptocurrency.
$inmess = $_[0];
  if (int($ytlock{'CRYPTOCURRENCY!_FETCH'}) < time) {
    $ytlock{'CRYPTOCURRENCY!_FETCH'} = time + 5*60;
    if ($ytlock{'CRYPTOCURRENCY!_CACHE'} < time) {
      $response = $ua->get('https://api.coinmarketcap.com/v1/ticker/?convert=SEK&limit=40');
      $rbody = $response->decoded_content;
      $rbody =~ s/\n//sgi;
      $rbody =~ s/\r//sgi;
      $rbody =~ s/\s//sgi;
      $rbody =~ s/\[\{\"id\":\"(.*)\}\]/$1/sgi;
      @coindata = split(/\},\{\"id\":\"/, $rbody);
      foreach $coin (@coindata) {
        if (($coin =~ m/^bitcoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
          $ytlock{'CC!_btc'} = "[BTC] \$".numprettify($1)." / ".numprettify($3)." kr";
        }
        if (($coin =~ m/^litecoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
          $ytlock{'CC!_ltc'} = "[LTC] \$".numprettify($1)." / ".numprettify($3)." kr";
        }
        if (($coin =~ m/^monero\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
          $ytlock{'CC!_xmr'} = "[XMR] \$".numprettify($1)." / ".numprettify($3)." kr";
        }
        if (($coin =~ m/^bitcoin-cash\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
          $ytlock{'CC!_bch'} = "[BCH] \$".numprettify($1)." / ".numprettify($3)." kr";
        }
        if (($coin =~ m/^ethereum\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
          $ytlock{'CC!_eth'} = "[ETH] \$".numprettify($1)." / ".numprettify($3)." kr";
        }
        if (($coin =~ m/^ripple\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
          $ytlock{'CC!_xrp'} = "[XRP] \$".numprettify($1)." / ".numprettify($3)." kr";
        }
        if (($coin =~ m/^dogecoin\"/)&&($coin =~ m/\"price_usd\":\"([^\"]*)\"(.*)\"price_sek\":\"([^\"]*)\"/)) {
          $ytlock{'CC!_doge'} = "[DOGE] \$".numprettify($1)." / ".numprettify($3)." kr";
        }
      }
      $ytlock{'CRYPTOCURRENCY!_CACHE'} = time + (30*60);
      $cached = "[live]";
    }
    else
    {
      $timeleft = $ytlock{'CRYPTOCURRENCY!_CACHE'} - time;
      $timeleft + 120;
      $minutesleft = int($timeleft / 60);
      $cached = "[cachad ${minutesleft}m]";
    }
    if (($inmess eq ".btc")||($inmess eq ".cc")) {
      $message = "$ytlock{'CC!_btc'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_doge'} | $cached";
    }
    if ($inmess eq ".ltc") {
      $message = "$ytlock{'CC!_ltc'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_doge'} | $cached";
    }
    if ($inmess eq ".xmr") {
      $message = "$ytlock{'CC!_xmr'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_doge'} | $cached";
    }
    if ($inmess eq ".bch") {
      $message = "$ytlock{'CC!_bch'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_doge'} | $cached";
    }
    if ($inmess eq ".eth") {
      $message = "$ytlock{'CC!_eth'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_doge'} | $cached";
    }
    if ($inmess eq ".xrp") {
      $message = "$ytlock{'CC!_xrp'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_doge'} | $cached";
    }
    if ($inmess eq ".doge") {
      $message = "$ytlock{'CC!_doge'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_xrp'} | $cached";
    }
  }
  return $message;
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
  nick        => 'SebbeBot',
  name        => 'Sebastian Nielsen',
  ignore_list => ['NickServ','ChanServ','JuliaBot'],
);
$bot->run();
