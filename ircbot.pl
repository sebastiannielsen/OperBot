#!/usr/bin/perl

package SebbeBot;

 use base 'Bot::BasicBot';
 use LWP::UserAgent;
 use MIME::Entity;
 use Email::Date::Format 'email_date';
 use MIME::Base64::URLSafe;

%ytlock = ();
%msg = ();

$usercmd = "true";
$tutprogress = "false";
$logtoggle = 0;

@oldurls = ();

%chlang = ('#hackit' => '1','#english' => '1');

@outmsgs = ("Aktiverade debugloggning:Activated debug log",
"Avaktiverade debugloggning:Deactivated debug logging",
"Skapade tutorial:Created tutorial",
". Skriv hela tutorialen i PM till mig. N\xE4r du \xE4r f\xE4rdig, skriv .tutstop h\xE4r i kanalen.:. Write the whole tutorial in PM to me. When you are done, write .tutstop here in channel.",
"Du har redan en tutorial aktiverad. Skriv .tutstop n\xE4r du \xE4r f\xE4rdig med den.:You already have a tutorial in progress. Write .tutstop when you are done with it.",
"Avslutade tutorial.:Finished tutorial.",
"Du har ingen tutorial aktiverad. Skriv .tutstart <titel> om du vill starta en.:Theres no tutorial in progress. Write .tutstart <title> if you want to start one.",
"Kan inte skicka/lista tutorials just nu, v\xE4nta tills oper \xE4r f\xE4rdig med sin tutorial.:Couldn't send/list tutorials right now, wait until oper is complete with its tutorial.",
"H\xE4r kommer listan p\xE5 alla tutorials som finns inlagda:Here is the list with all tutorials",
"Skickade tutorial-listan till dig i PM.:Sent the list to you in PM.",
"H\xE4r kommer:Here is",
"Skickade dig f\xF6ljande i PM:Sent the following in PM",
"Raderade tutorial:Deleted tutorial",
"Du efterfr\xE5gade en tutorial som inte finns:You asked for a tutorial that doesn't exist",
"Kan inte radera tutorials just nu, v\xE4nta tills oper \xE4r f\xE4rdig med sin tutorial.:Can't delete tutorials right now, wait until oper is done with its tutorial.",
"Anv\xE4ndaren finns ej i kanalen.:User isn't present in channel",
"Alla anv\xE4ndarkommandon \xE4r nu sp\xE4rrade.:All user commands are now disabled.",
"Alla anv\xE4ndarkommandon \xE4r nu akriverade.:All user commands are now enabled.",
"Jag sa \xE5t dig att sluta spamma!:I told you to stop spamming!",
"TIPS - Skicka g\xE4rna f\xE5 men l\xE4ngre meddelanden ist\xE4llet, f\xF6r det kan uppfattas som spam att skicka m\xE5nga korta meddelanden p\xE5 kort tid.:HINT - Try sending fewer but longer messages instead, because it can look spammy to send lots of short messages in a short time.",
"!!VARNING!! Om du forts\xE4tter att spamma kommer du att bli fr\xE5nkopplad fr\xE5n servern!:!!WARNING!! If you continue spamming, I will disconnect you from the server!",
"Du har redan blivit utsparkad en g\xE5nng idag, sluta spamma, annars kommer jag att banna dig!:You have already been kicked one time today, stop spamming, else I will ban you from the server!",
" !*!*!*! SISTA VARNINGEN !*!*!*! Om du inte slutar att spamma kommer du bli bannad fr\xE5n hela servern i 48 timmar !: !*!*!*! LAST WARNING !*!*!*! If you don't stop spamming, you will be banned from the whole server for 48 hours !",
"Jag st\xF6djer:I support",
"Oj. Den staden verkar inte finnas.:Oops. That city doesn't seem to exist.",
"Oj. OpenWeatherMap verkar ligga nere.:Oops. OpenWeatherMap seems to be down.",
"Meddelande skickat, dessutom ringer jag upp Sebastian p\xF6 telefonen!:Message sent, also I call Sebastian on the phone!",
".opmsg kan bara anv\xE4ndas en g\xE5ng var sjÃ¤tte timme!:.opmsg can only be used once per 6th hour!",
"Kanalspr\xE5k sattes till SVENSKA!:Channel language has been set to ENGLISH!"
);


open(YTKEY, "./botkey.txt");
$botytkey = <YTKEY>;
close(YTKEY);
$botytkey =~ s/\n//sgi;
open(WKEY, "./wkey.txt");
$wkey = <WKEY>;
close(WKEY);
$wkey =~ s/\n//sgi;
open(CCKEY, "./cckey.txt");
$cckey = <CCKEY>;
close(CCKEY);
$cckey =~ s/\n//sgi;



sub said {
  $self      = shift;
  $arguments = shift;    # Contains the message that the bot heard.

  if ($arguments->{channel} eq "msg") {
    if (($tutprogress eq "true")&&($self->pocoirc->is_operator($arguments->{who}))) {
      print TUTORIAL $arguments->{body}."\n";
    }
    goto skipall;
  }

  if ($arguments->{channel} eq "#bot") {
    if ($arguments->{who} eq "ChanServ") {
      @chandata = split(" ", $arguments->{body});
      if (($chandata[0] eq "\2CHANCREATE\2:")&&($chandata[1] eq "Channel")&&($chandata[3] eq "created")&&($chandata[4] eq "by")) {
        $self->join($chandata[2]);
	$self->mode($chandata[2]." +o Anna");
      }
      goto skipall;
    }
  }

  $ua = LWP::UserAgent->new;
  $message = "";


    if (($arguments->{body} eq ".lang")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}))) {
      if ($chlang{$arguments->{channel}} == 1) {
	$chlang{$arguments->{channel}} = 0;
      }
      else
      {
        $chlang{$arguments->{channel}} = 1;
      }
        $message = $arguments->{who} . ": ".domsg(28,$arguments->{channel});
    }


    if (($arguments->{body} eq ".logtoggle")&&($self->pocoirc->is_operator($arguments->{who}))) {
      if ($logtoggle == 0) {
        $logtoggle = 1;
	$message = $arguments->{who} . ": ".domsg(0,$arguments->{channel});
      }
      else
      {
        $logtoggle = 0;
	$message = $arguments->{who} . ": ".domsg(1,$arguments->{channel});
      }
    }

    if ($logtoggle == 1) {
    open(CHLOG, ">>chanlog.txt");
    print CHLOG $arguments->{who}.": ".$arguments->{body}."\n";
    close(CHLOG);
    }

    if ($arguments->{body} =~ m/(https?:\/\/|www\.)([-a-z0-9+&\@#\/\%=~_|\$?!:,.]*)/si) {
      $fullurl = $1.$2;
      unless ($fullurl =~ m/^https?:\/\//) {
        $fullurl = "http://".$fullurl;
      }
      if ($fullurl =~ m/^https?:\/\/([0-9a-z_\-.])+\/?([-a-z0-9+&\@#\/\%=~_|\$?!:,.]*)$/si) {
        push(@oldurls, $fullurl);
        if ($#oldurls > 4) {
          shift(@oldurls);
        }
      }
    }

    if ($arguments->{body} =~ m/^\.opmsg (.+)/) {
      $message = do_opmsg($arguments->{who}, $1, ($self->pocoirc->is_channel_operator($arguments->{channel}, $arguments->{who})||$self->pocoirc->is_channel_halfop($arguments->{channel}, $arguments->{who})), $self->pocoirc->is_channel_owner($arguments->{channel}, $arguments->{who}));
    }

    if (($arguments->{body} =~ m/^\.tutstart (.*)/)&&($self->pocoirc->is_operator($arguments->{who}))) {
      if ($tutprogress eq "false") {
 	     open(TUTORIAL, ">/var/secure_files/bot/tut/".MIME::Base64::URLSafe::encode($1));
             $tutprogress = "true";
	     $message = $arguments->{who}.": ".domsg(2,$arguments->{channel}).$1.domsg(3,$arguments->{channel});
      }
      else
      {
	     $message = $arguments->{who}.": ".domsg(4,$arguments->{channel});
      }
    }

    if (($arguments->{body} eq ".tutstop")&&($self->pocoirc->is_operator($arguments->{who}))) {
      if ($tutprogress eq "true") {	
	     close(TUTORIAL);
             $tutprogress = "false";
	     $message = $arguments->{who}.": ".domsg(5,$arguments->{channel});
      }
      else
      {
	     $message = $arguments->{who}.": ".domsg(6,$arguments->{channel});
      }
    }
    if ($arguments->{body} eq ".tutlist") {
      if ($tutprogress eq "true") {
	     $message = $arguments->{who}.": ".domsg(7,$arguments->{channel});
      }
      else
      {
	    @tutlist = ();
	    opendir(TUTHANDLE, "/var/secure_files/bot/tut");
    	    while (readdir TUTHANDLE) {
	    $file = $_;
	    unless (($file eq "..")||($file eq ".")) {
		push(@tutlist, $file);
            }
   	   }
      	   closedir TUTHANDLE;
	   @tutlist = sort(@tutlist);
	   $t = 1;
           $self->say(channel => "msg", who => $arguments->{who}, body => domsg(8,$arguments->{channel}).":");
	   foreach $k (@tutlist) {
             $self->say(channel => "msg", who => $arguments->{who}, body => $t.": ".MIME::Base64::URLSafe::decode($k));
             $t++;
	   } 
           $message = $arguments->{who}.": ".domsg(9,$arguments->{channel});
      }
    }
    if ($arguments->{body} =~ m/\.tut (\d+)/) {
      if ($tutprogress eq "true") {
	     $message = $arguments->{who}.": ".domsg(7,$arguments->{channel});
      }
      else
      {
	    $tut = $1;
	    @tutlist = ();
	    opendir(TUTHANDLE, "/var/secure_files/bot/tut");
    	    while (readdir TUTHANDLE) {
	    $file = $_;
	    unless (($file eq "..")||($file eq ".")) {
		push(@tutlist, $file);
            }
   	   }
      	   closedir TUTHANDLE;
	   @tutlist = sort(@tutlist);

	   if ((int($tut) > 0)&&(int($tut) < scalar(@tutlist) + 1)) {
           $self->say(channel => "msg", who => $arguments->{who}, body => domsg(10,$arguments->{channel}).": ".MIME::Base64::URLSafe::decode($tutlist[int($tut) - 1]));
	   open(TUTREAD, "/var/secure_files/bot/tut/".$tutlist[int($tut) - 1]);
	   @tutcontent = <TUTREAD>;
           close(TUTREAD);
	   foreach $tcontent (@tutcontent) {
           $self->say(channel => "msg", who => $arguments->{who}, body => $tcontent);
           }
           $message = $arguments->{who}.": ".domsg(11,$arguments->{channel}).": ".MIME::Base64::URLSafe::decode($tutlist[int($tut) - 1]);
           }
           else
           {
	   $message = $arguments->{who}.": ".domsg(13,$arguments->{channel}).": ".$tut;
           }
      }
    }

    if (($arguments->{body} =~ m/\.deltut (\d+)/)&&($self->pocoirc->is_operator($arguments->{who}))) {
      if ($tutprogress eq "true") {
	     $message = $arguments->{who}.": ".domsg(14,$arguments->{channel});
      }
      else
      {
	    $tut = $1;
	    @tutlist = ();
	    opendir(TUTHANDLE, "/var/secure_files/bot/tut");
    	    while (readdir TUTHANDLE) {
	    $file = $_;
	    unless (($file eq "..")||($file eq ".")) {
		push(@tutlist, $file);
            }
   	   }
      	   closedir TUTHANDLE;
	   @tutlist = sort(@tutlist);

	   if ((int($tut) > 0)&&(int($tut) < scalar(@tutlist) + 1)) {
	   unlink("/var/secure_files/bot/tut/".$tutlist[int($tut) - 1]);
           $message = $arguments->{who}.": ".domsg(12,$arguments->{channel}).": ".MIME::Base64::URLSafe::decode($tutlist[int($tut) - 1]).".";
           }
           else
           {
          $message = $arguments->{who}.": ".domsg(13,$arguments->{channel}).": ".$tut;
           }
      }
    }

    if (($arguments->{body} =~ m/\.r (.+) (#.+)/)&&($self->pocoirc->is_operator($arguments->{who}))) {
	$user = $1;
	$channel = $2;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
	    $self->kick($arguments->{channel},$user, "REDIRECT: ".$channel);
	    $self->quote("SAJOIN ".$user." ".$channel);
          }
	  else
	  {
	    $message = $arguments->{who}.": ".domsg(15,$arguments->{channel});
          }
    }


    $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
    $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
    if (($usercmd eq "true")||($isop == 1)||($ishp == 1)) {

      if ($arguments->{body} eq ".oldurls") {
        if (int($ytlock{'ALLURLS!_COMMAND'}) < time) {
          $ytlock{'ALLURLS!_COMMAND'} = time + 5*60;
          $allurls = "";
          foreach $url (@oldurls) {
            $allurls = $allurls . " " . $url;
          }
          $message = $arguments->{who}.": ".$allurls;
        }
      }
      if (($arguments->{body} eq ".btc")||($arguments->{body} eq ".cc")||($arguments->{body} eq ".ltc")||($arguments->{body} eq ".xmr")||($arguments->{body} eq ".bch")||($arguments->{body} eq ".xrp")||($arguments->{body} eq ".eth")||($arguments->{body} eq ".nebl")) {
        $message = do_cryptocurrency($arguments->{body});
      }
      if (($arguments->{body} =~ m/youtube\.com\/watch\?[^v]*v=([a-zA-Z0-9-_]*)/i)||($arguments->{body} =~ m/youtu\.be\/([a-zA-Z0-9-_]*)/i)) {
        $message = do_youtube($1);
      }
      if ($arguments->{body} =~ m/^\.v(\xE4|Ã¤)der (.+)/) {
        $message = do_weather($arguments->{who}, $2, $argument->{channel});
      }

      if ($arguments->{body} eq ".lotto") {
        @lottoarray = (1..35);
        $lottonumbers = "";
        for ($i = 0; $i < 7; $i++) {
          $lottonumbers = $lottonumbers . ", " . splice(@lottoarray, int(rand($#lottoarray + 1)), 1); 
        }
        $lottonumbers =~ s/^,\s//;
        $message = $arguments->{who}.": [ ".$lottonumbers." ]";
      }

      $opmessage = "false";
      if ($arguments->{body} eq ".help") {
        $servadm = $self->pocoirc->is_operator($arguments->{who});
        $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
        $isowner = $self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who});
        $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
        $message = $arguments->{who}.": ".domsg(23,$arguments->{channel}).": .help | .cc (alias: .btc .xmr .ltc .bch .eth .xrp .nebl) | .lotto | .v\xE4der <stad> | .oldurls | .tutlist | .tut <number>";
        if (($isop == 1)||($ishp == 1)) {
          $message = $message . "\n OP: .status <nick> | .opmsg <msg> | .usercmd | .r <user> <channel>";
          $opmessage = "true";
        }
        if ($servadm == 1) {
         $message = $message . "\n SERVADM: .tutstart <title> | .tutstop | .deltut <number>";
        }

      }

    }
    if ($arguments->{body} eq ".usercmd") {
      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
      if (($isop == 1)||($ishp == 1)) {
        if ($usercmd eq "true") {
          $usercmd = "false";
          $message = $arguments->{who}.": ".domsg(16,$arguments->{channel});       
        }
        else
        {
          $usercmd = "true";
          $message = $arguments->{who}.": ".domsg(17,$arguments->{channel});       
        }
      }
    }

      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
      $ircop = $self->pocoirc->is_operator($arguments->{who});
      $ign = $self->ignore_nick($arguments->{who});
      if (($ircop == 1)||($ign == 1)) {
        $immunity = "true";
      }
      else
      {
        $immunity = "false";
      }

      if (($isop == 1)||($ishp == 1)||($ircop == 1)) { # ONLY OPS/HALFOPS/IRCOPS CAN EXECUTE THESE (INCLUDING OWNER)
        if ($arguments->{body} =~ m/^\.status (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$user);
            $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$user);
            $ircop = $self->pocoirc->is_operator($user);
            $ign = $self->ignore_nick($user);
            if (($ircop == 1)||($ign == 1)) {
              $immunity = "1";
            }
            else
            {
              $immunity = "0";
            }
            ($uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($user));
            $bucket = $msg{$uidn};
            unless ($bucket =~ m/:/) {
              $bucket = "0:0:0:0:0";
            }
            ($number, $exp, $lmsg, $kicked, $warned) = split(":", $bucket);
            $message = $arguments->{who}.": (".$uidn.") killed=".$kicked." warned=".$warned." (".$user.") ".$stat." immunity=".$immunity." (OP=".int($isop)." HOP=".int($ishp)." IOP=".int($ircop)." IGN=".int($ign).").";
          }
          else
          {
           $message = $arguments->{who}.": ".domsg(15,$arguments->{channel});
          }
        }
      }

      if ($immunity eq "false") {
        ($idnum, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($arguments->{who}));
        $checkerstring = $arguments->{body};
        $checkerstring =~ s/\xE4/a/sg;
        $checkerstring =~ s/\xE5/a/sg;
        $checkerstring =~ s/\xF6/o/sg;
        $checkerstring =~ s/\xC4/a/sg;
        $checkerstring =~ s/\xC5/a/sg;
        $checkerstring =~ s/\xD6/o/sg;
        $checkerstring =~ s/\.(btc|bch|ltc|xmr|eth|xrp)/\.cc/sgi;
        $checkerstring =~ s/\.butkus/\.per/sgi;
        $checkerstring =~ s/\.raf/\.per/sgi;
        $checkerstring =~ s/\.vader/\.per/sgi;
        $checkerstring =~ s/\.alska/\.bestam/sgi;
        $checkerstring =~ s/\.lotto/\.per/sgi;      
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
        ($number, $expiry, $lastmessage, $kicked, $warned) = split(":",$bucket);

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
          $number = int($number);
          $number++;
          if ($lastmessage eq $checkerstring) {
            $number++;
          }
          $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":".$kicked.":".$warned;
          if (int($number) > 7) {
            if ($kicked eq "1") {
              if ($warned eq "2") {
                $self->quote("ZLINE ".$arguments->{who}." 48h ".domsg(18,$arguments->{channel}));
                $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":1:2";
                transmitmail("Z-linade spammare ".$arguments->{who}." (host: ".$displayid.") \n");
              }
              else
              {
                if ($warned eq "1") {
                  $message = $arguments->{who}." ($displayid): ".domsg(22,$arguments->{channel});
                  $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":1:2";
                }
                else
                {
                  $message = $arguments->{who}." ($displayid): ".domsg(21,$arguments->{channel});
                  $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":1:1";
                }
              }
            }
            else
            {
              if ($warned eq "2") {
                $self->quote("KILL ".$arguments->{who}." ".domsg(18,$arguments->{channel}));
                $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":1:0";
                transmitmail("Fr\xE5nkopplade spammare ".$arguments->{who}." (host: ".$displayid.") \n");
              }
              else
              {
                if ($warned eq "1") {
                  $message = $arguments->{who}." ($displayid): ".domsg(20,$arguments->{channel});
                  $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":0:2";
                }
                else
                {
                  $message = $arguments->{who}." ($displayid): ".domsg(19,$arguments->{channel});
                  $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":0:1";
                }
              }
            }# kicked check
          } # number check
        } #expiry check
      } #immunity 
  if (length($message) > 0) {
    if ($opmessage eq "false") {
      $message =~ s/\r//sgi;
      $message =~ s/\n//sgi;
      $message = substr($message,0,250);
    }
    return $message;
  }
  else
  {
    return undef;
  }
  skipall:
  return undef;
}

sub do_weather { # This function corresponds to the weather function
  $human = $_[0];
  $city = lc($_[1]);
  $chan = $_[2];
  $city =~ s/Ã„/\xE4/sg;
  $city =~ s/Ã…/\xE5/sg;
  $city =~ s/Ã–/\xF6/sg;
  $city =~ s/\xC4/\xE4/sg;
  $city =~ s/\xC5/\xE5/sg;
  $city =~ s/\xD6/\xF6/sg;
  $city =~ s/Ã¤/\xE4/sg;
  $city =~ s/Ã¥/\xE5/sg;
  $city =~ s/Ã¶/\xF6/sg;
  $city =~ s/\s/+/sg;
  $city =~ s/[^abcdefghijklmnopqrstuvwxyz\xE5\xE4\xF6+]*//sg;
  $rawmess = "";
  if (int($ytlock{'DOWEATHER!_FETCH'}) < time) {
    $ytlock{'DOWEATHER!_FETCH'} = time + 20;
    if (int($ytlock{'DOWEATHER!_CACHE'.$city}) < time) {
      $response = $ua->get('http://api.openweathermap.org/data/2.5/weather?q='.$city.'&appid='.$wkey.'&lang=se&units=metric');
      $rbody = $response->decoded_content;
      $descriptions = "";
      $clouds = "N/A";
      $temperature = "N/A";
      $pressure = "N/A";
      $windspeed = "N/A";
      $cityname = "N/A";
      $success = "false";
      if ($rbody =~ m/\"weather\"\:\[([^\]]*)\]/) {
        $success = "true";
        $wdata = $1;
        if ($wdata =~ m/\},\{/) {
          @allweathers = split(/\},\{/, $wdata);
          foreach $weather (@allweathers) {
            if ($weather =~ m/"description":"([^"]*)"/) {
              $wname = $1;
              $descriptions = $descriptions . $wname . ", ";
            }
          }
        }
        else
        {
          if ($wdata =~ m/"description":"([^"]*)"/) {
            $wname = $1;
            $descriptions = $descriptions . $wname . ", ";
          }
        }
      }
      if ($rbody =~ m/\{"temp":([0123456789.-]*),"pressure":([0123456789.]*),"humidity":([0123456789.]*),/) {
        $temperature = $1;
        $pressure = $2;
        $humidity = $3;
      }
      if ($rbody =~ m/\{"speed":([0123456789.-]*),/) {
        $windspeed = $1;
      }
      if ($rbody =~ m/\"clouds\":\{\"all\":([0123456789.]*)\}/) {
        $clouds = $1;
      }
      if ($rbody =~ m/,"name":"([^"]*)",/) {
        $cityname = $1;
      }
      if ($success eq "true") {
        $rawmess = $human.": VÃ¤dret i ".$cityname.": ".$descriptions.$temperature." *C, ".$windspeed." m/s, ".$humidity." \% luftfuktighet, ".$clouds." \% molntÃ¤cke, ".$pressure." hPa";
      }
      else
      {
        if ($rbody =~ m/(city|geocode)/) {
          $rawmess = $human.": ".domsg(24,$chan);
        }
        else
        {
          $rawmess = $human.": ".domsg(25,$chan);
        }
      }
      $rawmess =~ s/Ã¤/\xE4/sg;
      $rawmess =~ s/Ã¥/\xE5/sg;
      $rawmess =~ s/Ã¶/\xF6/sg;
      $rawmess =~ s/Ã„/\xC4/sg;
      $rawmess =~ s/Ã…/\xC5/sg;
      $rawmess =~ s/Ã–/\xD6/sg;
      $ytlock{'DOWEATHER!_CACHE'.$city} = time + 1800;
      $ytlock{'DOWEATHER!_CACHECONTENT'.$city} = $rawmess;
      $rawmess = $rawmess . " [live]";
    }
    else
    {
      $rawmess = $ytlock{'DOWEATHER!_CACHECONTENT'.$city};
      $rawmess = $rawmess . " [cachad]";
    }
  }
  return $rawmess;
}

sub do_opmsg { # This function corresponds to .opmsg
  $human = $_[0];
  $inmessage = $_[1];
  $isop = $_[2];
  $isown = $_[3];
  if ($isop == 1) {
    if ((int($ytlock{'OPMSG!_FUNCTION'}) < time)||($isown == 1)) {
      $ytlock{'OPMSG!_FUNCTION'} = time + 360*60;
      $inmessage =~ s/Ã¤/\xE4/sg;
      $inmessage =~ s/Ã¥/\xE5/sg;
      $inmessage =~ s/Ã¶/\xF6/sg;
      $inmessage =~ s/Ã„/\xC4/sg;
      $inmessage =~ s/Ã…/\xC5/sg;
      $inmessage =~ s/Ã–/\xD6/sg;
      transmitmail("OP-meddelande fr\xE5n ".$human." via OPMSG. Meddelandet \xE4r:\n".$inmessage."\n\n");
      open(TMPFILE, ">/var/spool/asterisk/tmp/irc.".$vct.$$.".call");
      print TMPFILE "Channel: Local/s\@wakeup\n";
      print TMPFILE "Callerid: \"".$arguments->{who}.": KOLLA MEJLEN!\" <0>\n";
      print TMPFILE "Application: Playback\n";
      print TMPFILE "Data: vm-nytt&vm-message\n";
      close(TMPFILE);
      system("chmod 777 /var/spool/asterisk/tmp/irc.".$vct.$$.".call");
      rename("/var/spool/asterisk/tmp/irc.".$vct.$$.".call","/var/spool/asterisk/outgoing/irc.a".$vct.$$.".call");
      $message = $human.": ".domsg(26,$arguments->{channel});
    }
    else
    {
      $message = $human.": ".domsg(27,$arguments->{channel});
    }
  }
  return $message;
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
        $ytline =~ s/Ã¤/\xE4/sg;
        $ytline =~ s/Ã¥/\xE5/sg;
        $ytline =~ s/Ã¶/\xF6/sg;
        $ytline =~ s/Ã„/\xC4/sg;
        $ytline =~ s/Ã…/\xC5/sg;
        $ytline =~ s/Ã–/\xD6/sg;
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


sub do_cryptocurrency { # This function is called everytime somebody requests information about cryptocurrency.
$inmess = $_[0];
  if (int($ytlock{'CRYPTOCURRENCY!_FETCH'}) < time) {
    $ytlock{'CRYPTOCURRENCY!_FETCH'} = time + 5*60;
    if (int($ytlock{'CRYPTOCURRENCY!_CACHE'}) < time) {
      $response = $ua->get('https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH,BCH,XMR,LTC,XRP,NEBL&tsyms=USD,SEK&api_key='.$cckey);
      $rbody = $response->decoded_content;
      $rbody =~ s/^\{\"//si;
      $rbody =~ s/\}\}$//si;
      @coindata = split(/\}\,\"/, $rbody);
      foreach $coin (@coindata) {
        $coin =~ s/^([A-Z]*)\"\:\{\"USD\"\:([0-9.]*)\,\"SEK\"\:([0-9.]*)$/$1-$2-$3/si;
        ($coinname, $usdprice, $sekprice) = split("-",$coin);

        if ($coinname eq "BTC") {
          $ytlock{'CC!_btc'} = "[BTC] \$".numprettify($usdprice)." / ".numprettify($sekprice)." kr";
        }
        if ($coinname eq "LTC") {
          $ytlock{'CC!_ltc'} = "[LTC] \$".numprettify($usdprice)." / ".numprettify($sekprice)." kr";
        }
        if ($coinname eq "XMR") {
          $ytlock{'CC!_xmr'} = "[XMR] \$".numprettify($usdprice)." / ".numprettify($sekprice)." kr";
        }
        if ($coinname eq "BCH") {
          $ytlock{'CC!_bch'} = "[BCH] \$".numprettify($usdprice)." / ".numprettify($sekprice)." kr";
        }
        if ($coinname eq "ETH") {
          $ytlock{'CC!_eth'} = "[ETH] \$".numprettify($usdprice)." / ".numprettify($sekprice)." kr";
        }
        if ($coinname eq "XRP") {
          $ytlock{'CC!_xrp'} = "[XRP] \$".numprettify($usdprice)." / ".numprettify($sekprice)." kr";
        }
        if ($coinname eq "NEBL") {
          $ytlock{'CC!_nebl'} = "[NEBL] \$".numprettify($usdprice)." / ".numprettify($sekprice)." kr";
        }
      }
      $ytlock{'CRYPTOCURRENCY!_CACHE'} = time + (30*60);
      $cached = "[cryptocompare.com live]";
    }
    else
    {
      $timeleft = int($ytlock{'CRYPTOCURRENCY!_CACHE'}) - time;
      $timeleft + 120;
      $minutesleft = int($timeleft / 60);
      $cached = "[cryptocompare.com cachad ${minutesleft}m]";
    }
    if (($inmess eq ".btc")||($inmess eq ".cc")) {
      $message = "$ytlock{'CC!_btc'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_nebl'} | $cached";
    }
    if ($inmess eq ".ltc") {
      $message = "$ytlock{'CC!_ltc'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_nebl'} | $cached";
    }
    if ($inmess eq ".xmr") {
      $message = "$ytlock{'CC!_xmr'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_nebl'} | $cached";
    }
    if ($inmess eq ".bch") {
      $message = "$ytlock{'CC!_bch'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_nebl'} | $cached";
    }
    if ($inmess eq ".eth") {
      $message = "$ytlock{'CC!_eth'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_xrp'} | $ytlock{'CC!_nebl'} | $cached";
    }
    if ($inmess eq ".xrp") {
      $message = "$ytlock{'CC!_xrp'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_nebl'} | $cached";
    }
    if ($inmess eq ".nebl") {
      $message = "$ytlock{'CC!_nebl'} | $ytlock{'CC!_xmr'} | $ytlock{'CC!_ltc'} | $ytlock{'CC!_btc'} | $ytlock{'CC!_eth'} | $ytlock{'CC!_bch'} | $ytlock{'CC!_xrp'} | $cached";
    }
  }
  return $message;
}


sub transmitmail { #Sends a simple mail. Text in first argument. Log and the rest of text is included automatically.
  $mailbody = $_[0];
  $mailsubject = $_[0];
  $mailsubject =~ s/\n//sgi;
  $mailsubject = substr($mailsubject, 0, 75);
  $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
  $maildate = email_date;
  $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => "Boten Anna <anna\@sebbe.eu>", To => "sebastian\@sebbe.eu", Subject => $mailsubject, Date => $maildate, Data => $mailbody);
  open(MAIL, "|/usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"");
  $mime->print(\*MAIL);
  close MAIL;
}

sub getidfromhost { 
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
  $banmask = "*!*\@*".$partbb;
  $idnum = $partbb; #Counting spam can be done normally.
  $idnum = lc($idnum);
  $idnum =~ s/[^a-z0-9]*//sgi;
  $displayid = $partbb;
  return ($idnum, $displayid, $banmask);
}

sub numprettify { # This function visually prettifies a float. This by rounding off to 3 decimals if the integer is lower than 10, else it strips off decimals completely. And then adding spaces each 3rd digit.
  $number = $_[0];
  if (($number =~ m/\./)&&(int($number) < 10)) {
    ($numinteger, $numdecimal) = split(/\./, $number);
    $number = $numinteger;
    $numdecimal = substr($numdecimal, 0, 2);
    if (length($numdecimal) == 1) {
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

sub domsg() {
$msgid = $_[0];
$channel = $_[1];
@msgset = split(":",$outmsgs[$msgid]);
$langindex = $chlang{$channel};
return $msgset[$langindex];
}

package main;

#Flood protection disabled for PM's. There is already a flood protection for public messages.
$bot = SebbeBot->new(
  server      => '127.0.0.1',
  port        => '6667',
  flood       => 1,
  channels    => ['#sebastian','#bot','#english','#hackit'],
  nick        => 'Anna',
  name        => 'Sebastian Nielsen',
  ignore_list => ['NickServ','ChanServ'],
);
$bot->run();
