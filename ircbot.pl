#!/usr/bin/perl

package SebbeBot;

 use base 'Bot::BasicBot';
 use LWP::UserAgent;
 use MIME::Entity;
 use Email::Date::Format 'email_date';

@log = ();
%ytlock = ();
%msg = ();
%hasnotwritten = ();
%iswatched = ();
$defcon = "false";
$usercmd = "true";
$logchanged = "true";

%opban = ();
$opban{'areendopterygotes'} = 1; # Extremely non-grown person. Hope a LARGE caterpillar comes to his house and "accidentially"
                           # digs off his fiber cable so he is PERMANENTLY without internet. (a4r/drama)
$opban{'jjmj1u0baip'} = 1; # Same person as above (a4r/drama)
$opban{'bsocietyse'} = 1;  # Same person as above (a4r/drama)
$opban{'uhfos8d4eip'} = 1; # A person who likes to play with his OP functions when he is bored. (per)

@rafarray = ("jag vill känna långlivad organisk glädje och lyfta denna förbannelsen", "du måste stirra in i denna kuben och FÖRSTÅ","jag visar dig de otänkbra!!","jag är ett hungerigt barn","mitt liv är i förödelse","kompster", "skåda den starkaste mjuk öra någonsin","ok kompis det är bara du och jag", "han kommer bli en stark pojke","glad jlu", "välkommen till sceniskt räfland", "vi har tassar,vi har äpple", "vad mer kan man begära", "kryddig het räf", "förståeligt","den sista biten", "jag ser, i den vacker dröm","jag vaknar, och har glömt","någonting fattas", "inge tålamod","när jag var hälften som du, var jag så här liten","men dubbelt utav mig är inte som nu","hej, jag är spöke som är efter din själ", "kan vi bli vän", "det är för riskabelt", "okej nu är det bara du och jag", "jag representerar denna världens hopp", "förtälj om din vishet", "jag är faktiskt bara liten", "nu går vi och spökar en kamrat", "tystnad mina barn", "jag bringar er en fest", "vilken förtjusande melodi", "jag äger tre flöjter", "tuut", "jag flyter förbi med goda nyheter", "wow vad är det","jag har upptäckt meningen", "meningen till vad", "mysterium", "absolut icke", "???", "!!!", "löf i mund dialekt", "ånga i ansikte dialekt", "varför gör du detta mot mig", "har du övervägt läg1man1", "vad är läg1man1", "gratulationer", "jag spökar ditt förflutet", "jag spökar ditt nuvarande", "jag !! spökar nästan", "jag vill inte spräcka din bubbla men", "boop", "tjena vänner kolla in denna ljuvliga bläckfisgen", "håll denna vännen", "fantastiskt", "nu kan vi observera gatorn medans den förföljer sitt byte", "den kommer mumsa!!","mums", "låt oss diskutera alla våra kunskaper och planer", "vänta tyst!!", "å nej", "wow det finns så många vacker klänning", "vilken ska jag välja", "ursäkta, det inte okej, beep och boop passar inte", "är du ok", "fixa", "T A C K F Ö R A T T D U L O G G A D E I N", "det är det enda sättet att hitta marshmeln", "min skapare vi har funnit", "det är fantastiskt", "synnerligen, helt säkert", "ojsan vad är det där","nyoom", "ooooooooooooooooooooooooooooooooooooo", "det jag, jag är molnet, titta: fhu~", "fhu~", "låt mig berätta, vän, jag vet vad det","tassfluff", "vänta det är inte längre ok", "bort från mig hunde, jag är ASFALT", "är du någonlunda kylig vill du ha en halsduk", "denna är till dig", "jag är en riktig hiss!!", "ok farväl vän", "nyoom", "låt oss gifta oss!!","ok!!","vi är gifta nu!!","ja!!", "låt oss gå till djurparken!", "hurra!");
@lovea = ("pussar","slickar","gosar","smeker","lindar armarna om","kramar","klappar","myser","sniffar","nafsar","gnuggar","eskimåkysser");
@loveb = ("försiktigt","mjukt","hårt","lungt","hjärtfyllt","älskande","varmt","gulligt","lyckligt");
@morna = ("kaffe","senap","ärtor","jesus","MAMMA","köttbullar","aliens","små rymdgubbar","demoner","mina demoner","pers demoner","kebab","läsk","sockerdricka","citronbitare","potatos","potatosmos","kosttillskott","presenter","paket","sqli","horsepower","HORSEPOWER","stearinljus","böcker","husdjur","vinterjackan","tandborste","tandkräm","munskölj","toapapper","stekspade","elwisp","wisp","ostpizza","pizza");
@mornb = ("på taket","på stolen","under stolen","på datorn","på bänken","under skrivbordet","i chloe","hos grannen","i kaffekoppen","i kylen","på vinden","hos dem som frågar","i badrumsskåpet","i kyrkan","på förskolan","på dagis","hemma hos per","i skålen","i hallen","i blodomloppet","i flaskan","på toasitsen","under golvbrädorna","under mattan","på hårddisken","i fåtöljen","i tyskland","i sundsvall","hemma hos chloe","inuti per");

open(YTKEY, "./botkey.txt");
$botytkey = <YTKEY>;
close(YTKEY);
$botytkey =~ s/\n//sgi;
open(WKEY, "./wkey.txt");
$wkey = <WKEY>;
close(WKEY);
$wkey =~ s/\n//sgi;
open(GHOST, "./autoghost.txt");
$ghostpassword = <GHOST>;
close(GHOST);
$ghostpassword =~ s/\n//sgi;

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
  unless (($arguments->{channel} eq "msg")||($arguments->{who} eq "ChanServ")||($arguments->{who} eq "NickServ")) {

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
    $logchanged = "true";
    if ($#log > 40) {
      shift(@log);
    }
    if ($arguments->{body} =~ m/^\.opmsg (.+)/) {
      $message = do_opmsg($arguments->{who}, $1, ($self->pocoirc->is_channel_operator($arguments->{channel}, $arguments->{who})||$self->pocoirc->is_channel_halfop($arguments->{channel}, $arguments->{who})), $self->pocoirc->is_channel_owner($arguments->{channel}, $arguments->{who}));
    }

    $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
    $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
    if (($usercmd eq "true")||($isop == 1)||($ishp == 1)) {
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
      if ($arguments->{body} =~ m/^\.v(\xE4|ä)der (.+)/) {
        $message = do_weather($arguments->{who}, $2);
      }
      if ($arguments->{body} =~ m/^.pwdb ([_\-\@\!\+\.a-zA-Z0-9]*)/) {
        $email = $1;
        $email =~ s/\\//sgi;
        if (int($ytlock{$email}) < time) {
          $ytlock{$email} = time + 5*60;
          $hashoutput = "";
          $rawresults = `/var/secure_files/bot/brcompilation_hashed/query.sh \"$email\"`;
          $rawresults =~ s/\n/,/sgi;        
          if (length($rawresults) > 16) {
            $message = $arguments->{who}.": $email sha1: ".$rawresults;
          }
          else
          {
            $message = $arguments->{who}.": Tyv\xE4rr, jag hittade inga hashar f\xF6r $email i min databas.";
          }
        }
      }
      if ($arguments->{body} eq ".morn") {
        $message = "Godmorgon ".$arguments->{who}.", ".$morna[int(rand($#morna + 1))]." finns ".$mornb[int(rand($#mornb + 1))].".";
        $message =~ s/ä/\xE4/sg;
        $message =~ s/å/\xE5/sg;
        $message =~ s/ö/\xF6/sg;
        $message =~ s/Ä/\xC4/sg;
        $message =~ s/Å/\xC5/sg;
        $message =~ s/Ö/\xD6/sg;
      }
      if (($arguments->{body} eq ".r\xE4f")||($arguments->{body} eq ".räf")) {
        $message = $rafarray[int(rand($#rafarray + 1))];
        $message =~ s/ä/\xE4/sg;
        $message =~ s/å/\xE5/sg;
        $message =~ s/ö/\xF6/sg;
        $message =~ s/Ä/\xC4/sg;
        $message =~ s/Å/\xC5/sg;
        $message =~ s/Ö/\xD6/sg;
      }

      if ($arguments->{body} =~ m/^\.(\xE4|ä)lska (.+)/) {
        $qemessage = $lovea[int(rand($#lovea + 1))]." ".$2." ".$loveb[int(rand($#loveb + 1))]." <3";
        $qemessage =~ s/ä/\xE4/sg;
        $qemessage =~ s/å/\xE5/sg;
        $qemessage =~ s/ö/\xF6/sg;
        $qemessage =~ s/Ä/\xC4/sg;
        $qemessage =~ s/Å/\xC5/sg;
        $qemessage =~ s/Ö/\xD6/sg;
        $self->emote(channel => $arguments->{channel}, body => $qemessage);
        $qemessage = "";
        $message = "";
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
        $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
        $isowner = $self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who});
        $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
        $message = $arguments->{who}.": Jag st\xF6djer: .help | .cc (alias: .btc .xmr .ltc .bch .eth .xrp .doge) | .fetchlog | .pwdb <email> | .butkus | .per | .best\xE4m <val> | .lotto | .r\xE4f | .morn | .\xE4lska <namn> | .v\xE4der <stad>";
        if (($isop == 1)||($ishp == 1)) {
          $message = $message . "\n OP: .setwarn <nick> | .setkick <nick> | .status <nick> | .clruser <nick> | .clrall | .opmsg <msg> | .defcon | .usercmd | .qb <nick> | .qt <nick>";
          $opmessage = "true";
        }
        if ($isowner == 1) {
         $message = $message . "\n \xC4GARE: .shutdown | .resetbot | .setnotwritten <nick> | .clrnotwritten <nick> | .watch <namn> | .logtofile <text> | .opban <nick> | .opunban <nick>";
         $opmessage = "true";
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
          $checkerstring =~ s/å/a/sg;
          $checkerstring =~ s/ä/a/sg;
          $checkerstring =~ s/ö/o/sg;
          $checkerstring =~ s/Å/a/sg;
          $checkerstring =~ s/Ä/a/sg;
          $checkerstring =~ s/Ö/o/sg;
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
            if (int($ytlock{'BTM!_COMMAND'.$checkerstring}) < time) {
              $ytlock{'BTM!_COMMAND'.$checkerstring} = time + 5*60;
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

      if ($arguments->{body} eq ".fetchlog") {
        if (int($ytlock{'FETCHLOG!_COMMAND'}) < time) {
          if (int($ytlock{'FETCHLOG!_COMMAND'.$arguments->{who}}) < time) {
            $ytlock{'FETCHLOG!_COMMAND'} = time + 20;
            $ytlock{'FETCHLOG!_COMMAND'.$arguments->{who}} = time + 5*60;
            $message = $arguments->{who}.": Du har PM fr\xE5n mig med loggen!";
            $self->say(channel => "msg", who => $arguments->{who}, body => "H\xE4r kommer de 20 senaste meddelandena:");
            $i = 0;
            $max = 0;
            if ($#log > 18) {
              $max = $#log - 19;
            }
            foreach $msgline (@log) {
              $i++;
              if ($i > $max) {
                $self->say(channel => "msg", who => $arguments->{who}, body => $msgline);
              }
            }
          }
        }
      }
    }

    if (($arguments->{body} =~ m/^\.logtofile (.+)/)&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      open(LOGFILE, ">>logtofile.txt");
      print LOGFILE $1."\n";
      close(LOGFILE);
      $message = $arguments->{who}.": Loggade ".$1." till /var/secure_files/bot/logtofile.txt";
    }

    if (($arguments->{body} =~ m/^\.watch (.+)/)&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      if ($1 eq "all") {
        %iswatched = ();
        $message = $arguments->{who}.": Alla vaktningar borttagna!";
      }
      else
      { 
        if ($iswatched{$1} eq "1") {
          $iswatched{$1} = "0";
          $message = $arguments->{who}.": Slutade vakta efter ".$1.".";
        }
        else
        {
          $iswatched{$1} = "1";
          $message = $arguments->{who}.": Kommer ringa upp dig n\xE4r ".$1." joinar kanalen.";
        }
      }
    }


    if ($arguments->{body} eq ".usercmd") {
      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      $ishp = $self->pocoirc->is_channel_halfop($arguments->{channel},$arguments->{who});
      if (($isop == 1)||($ishp == 1)) {
        if ($usercmd eq "true") {
          $usercmd = "false";
          $message = $arguments->{who}.": Alla anv\xE4ndarkommandon \xE4r nu sp\xE4rrade.";       
        }
        else
        {
          $usercmd = "true";
          $message = $arguments->{who}.": Aktiverade alla anv\xE4ndarkommandon.";       
        }
      }
    }

    if ($arguments->{body} =~ m/^\.(qt|qb) (.+)/) {
      $isop = $self->pocoirc->is_channel_operator($arguments->{channel},$arguments->{who});
      if ($isop == 1) {
        $botban = lc($2);
        $cmd = $1;
        $botban =~ s/\@//sgi;
        $botban =~ s/\!//sgi;
        if (length($botban) > 0) {
          @allusers = $self->channel_list($arguments->{channel});
          if ($cmd eq "qt") {
            $self->mode($arguments->{channel}." +b ".$botban."*!".$botban."*\@*.4uh.b8obtf.IP");
            $dotor = "true";
          }
          else
          {
            $self->mode($arguments->{channel}." +b ".$botban."*!".$botban."*\@*");
            $dotor = "false";
          }
          $botfound = 0;
          foreach $usernick (@allusers) {
            $ufh = lc($self->pocoirc->nick_long_form($usernick));
            ($un, $uh) = split(/\@/, $ufh);
            ($bn, $bu) = split(/\!/, $un);
            unless (($usernick eq "Anna")||($usernick eq "Sebastian")||($usernick eq "chloe")) {
              if ((substr($bn,0,length($botban)) eq $botban)&&(substr($bu,0,length($botban)) eq $botban)) {
                if ($dotor eq "true") {
                  if ($uh =~ m/\.4uh\.b8obtf\.IP$/) {
                    $self->kick($arguments->{channel}, $usernick, "Inga spambottar h\xE4r, tack!");
                    $botfound++;
                  }
                }
                else
                {
                  $self->kick($arguments->{channel}, $usernick, "Inga spambottar h\xE4r, tack!");
                  $botfound++;
                }
              }
            }
          }
          $message = $arguments->{who}.": Hittade och bannade ".$botfound." spambottar i kanalen.";
        }
      }
    }

    if (($arguments->{body} eq ".shutdown")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      transmitmail("Hej. ".$arguments->{who}." beg\xE4rde ett avslut.\n");
      $self->shutdown("Avslut beg\xE4rt av ".$arguments->{who});
    }

    if (($arguments->{body} eq ".resetbot")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) == 1)) {
      $lastclear = "0-0-0";
      $message = $arguments->{who}.": Rubbet rensat inkl cache!";
    }

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
        if ($arguments->{body} =~ m/^\.opban (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($user));
            $opban{$uidn} = 1;
            $self->mode($arguments->{channel}." -voh ".$user);
            $message = $arguments->{who}.": OP-bannade ".$user.". (".$uidn.")";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} =~ m/^\.opunban (.+)/) {
          $user = $1;
          if ($self->pocoirc->is_channel_member($arguments->{channel},$user) == 1) {
            ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($user));
            $opban{$uidn} = 0;
            $message = $arguments->{who}.": Tog bort OP-ban p\xE5 ".$user.". (".$uidn.")";
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
            if ($opban{$uidn} == 1) {
              $message = $arguments->{who}.": Kan inte rensa status p\xE5 $user eftersom han \xE4r OP-bammad.";
            }
            else
            { 
              $msg{$uidn} = "0:0:0:0:0";
              $message = $arguments->{who}.": Rensade status p\xE5 $user.";
            }
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
            if ($opban{$uidn} == 1) {
             $opst = " opban=1";
            }
            else
            {
             $opst = " opban=0";
            }
            if ($defcon eq "true") {
              $warned = "1";
              $kicked = "1";
            }
            $message = $arguments->{who}.": (".$uidn.") kicked=".$kicked." warned=".$warned." tor=".$uist.$opst." (".$user.") ".$stat." immunity=".$immunity." (OP=".int($isop)." HOP=".int($ishp)." ADM=".int($isad)." OWN=".int($isow)." VO=".int($isv)." IOP=".int($ircop)." IGN=".int($ign).").";
          }
          else
          {
            $message = $arguments->{who}.": Nicket m\xE5ste finnas i kanalen.";
          }
        }
        if ($arguments->{body} eq ".clrall") {
          foreach $k (keys %msg) {
            unless ($opban{$k} == 1) {
              $msg{$k} = "";
            }
          }
          $message = $arguments->{who}.": Rensade alla anv\xE4ndare utom de som \xE4r OP-bannade.";
        }
        if ($arguments->{body} eq ".defcon") {
          if ($defcon eq "false") {
            $defcon = "true";
            $oldtopic = $self->topic($arguments->{channel});
            $self->mode($arguments->{channel}." +t");
            $self->topic($arguments->{channel}, "!! VARNING !! Undantagstillst\xE5nd r\xE5der. Ni som \xE4r anslutna via TOR, skriv inte utan inv\xE4nta voice fr\xE5n kanaloperat\xF6r innan ni skriver! Inga varningar kommer ges innan ban !!");
          }
          else
          {
            $defcon = "false";
            $self->mode($arguments->{channel}." -t");
            $self->topic($arguments->{channel}, $oldtopic);
          }
        }
      }

      if ($immunity eq "false") {
        ($istor, $idnum, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($arguments->{who}));
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
          if ($defcon eq "true") {
            $kicked = "1";
            $warned = "1";
          }
          if (int($number) > 4) {
            if ($kicked eq "1") {
              if ($warned eq "1") {
                $self->mode($arguments->{channel}." +b ".$banmask);
                $self->kick($arguments->{channel}, $arguments->{who}, "Du slutade inte spamma!");
                $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":1:1"; #We won't reset as there might be multiple users with same hostname in channel.
                $tempbody = "Bannade spammare ".$arguments->{who}." (host: ".$displayid.") fr\xE5n ".$arguments->{channel}."\n";
                if ($istor eq "1") {
                  $tempbody = $tempbody . "Anv\xE4ndaren \xE4r en TOR-anv\xE4ndare, s\xE5 jag bannade genom att anv\xE4nda ".$banmask." .\n";
                }
                transmitmail($tempbody."\n");
              }
              else
              {
                $message = $arguments->{who}." ($displayid): !!VARNING!! Om du forts\xE4tter att spamma kommer du att bli BANNAD!";
                $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":1:1";
              }
            }
            else
            {
              if ($warned eq "2") {
                $self->kick($arguments->{channel}, $arguments->{who}, "Sluta spamma!");
                $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":1:0";
                transmitmail("Kickade spammare ".$arguments->{who}." (host: ".$displayid.") fr\xE5n ".$arguments->{channel}."\n");
              }
              else
              {
                if ($warned eq "1") {
                  $message = $arguments->{who}." ($displayid): !!VARNING!! Om du forts\xE4tter att spamma kommer du att bli kickad!";
                  $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":0:2";
                }
                else
                {
                  $message = $arguments->{who}." ($displayid): !!VARNING!! Var sn\xE4ll och sluta spamma! V\xE4nta g\xE4rna n\xE5gra sekunder innan du skickar igen och ta det lite lungt.";
                  $msg{$idnum} = $number.":".$expiry.":".$checkerstring.":0:1";
                }
              }
            }# kicked check
          } # number check
        } #expiry check
      } #immunity 
  }
  if (length($message) > 0) {
    if ($opmessage eq "false") {
      $message =~ s/\r//sgi;
      $message =~ s/\n//sgi;
      $message = substr($message,0,250);
    }
    push(@log, $timestampprefix."] <\@Anna> $message");
    $logchanged = "true";
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

sub nick_change {
  ($self, $oldnick, $newnick) = @_;

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
  push(@log, $timestampprefix. "] *** ".$oldnick." bytte namn till ".$newnick);
  $logchanged = "true";
  if ($#log > 40) {
    shift(@log);
  }
  $hostname = $self->pocoirc->nick_long_form($newnick);
  ($istor, $idnum, $displayid, $banmask) = getidfromhost($hostname);
  ($nickreal, $hostpart) = split(/\@/, $hostname);
  if (lc($newnick) eq "chloe") {
    if ($hostpart ne "chloe.chloe") {
      $self->mode("#sebastian +b ".$banmask);
      $self->kick("#sebastian", $newnick, "Omoget att fakea chloe");
      transmitmail("Bannade omogen person som fakenickar chloe med host (".$hostpart.").\n");
    }
  }
  if (lc($newnick) eq "sebastian") {
    if (($hostpart ne "dns2.sebbe.eu")&&($hostpart ne "swehack-ep8.85g.agg3sg.IP")) {
      $self->mode("#sebastian +b ".$banmask);
      $self->say(channel => "msg", who => "NickServ", body => "GHOST sebastian ".$ghostpassword);
      transmitmail("Ghostade och bannade omogen person som fakenickar dig med host (".$hostpart.").\n");
    }
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
  $logchanged = "true";
  if ($#log > 40) {
    shift(@log);
  }
  unless ($arguments->{who} eq "Anna") {
    if (($arguments->{kicked} eq "Anna")&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) != 1)&&($arguments->{who} ne "ChanServ")) {
      $self->say(channel => "msg", who => "ChanServ", body => "UNBAN ".$arguments->{channel});
      $self->say(channel => "msg", who => "ChanServ", body => "DEOP ".$arguments->{channel}." ".$arguments->{who});
      $self->say(channel => "msg", who => "ChanServ", body => "ACCESS ".$arguments->{channel}." DEL ".$arguments->{who});
      $self->join($arguments->{channel});
      ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($arguments->{who}));
      $opban{$uidn} = 1;
      $self->say(channel => $arguments->{channel}, body => $arguments->{who}.": Missbruka inte dina OP-funktioner!");
      push(@log, $timestampprefix."] <\@Anna> ".$arguments->{who}.": Missbruka inte dina OP-funktioner!");
      $logchanged = "true";
      if ($#log > 40) {
        shift(@log);
      }
      transmitmail("OP-bannade maktgalen OP ".$arguments->{who}." fr\xE5n ".$arguments->{channel}." som kickar mig (Anna) utan anledning.\n");
    }
    else
    {
      if (($hasnotwritten{$arguments->{kicked}} == 1)&&($self->pocoirc->is_channel_owner($arguments->{channel},$arguments->{who}) != 1)&&($arguments->{who} ne "ChanServ")) {
        $self->mode($arguments->{channel}." -oh ".$arguments->{who});
        $self->say(channel => "msg", who => "ChanServ", body => "ACCESS ".$arguments->{channel}." DEL ".$arguments->{who});
        ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($arguments->{who}));
        $opban{$uidn} = 1;
        $self->say(channel => $arguments->{channel}, body => $arguments->{who}.": Missbruka inte dina OP-funktioner!");
        push(@log, $timestampprefix."] <\@Anna> ".$arguments->{who}.": Missbruka inte dina OP-funktioner!");
        $logchanged = "true";
        if ($#log > 40) {
          shift(@log);
        }
        transmitmail("OP-bannade maktgalen OP ".$arguments->{who}." fr\xE5n ".$arguments->{channel}." som spamkickar ".$arguments->{kicked}." utan anledning.\n");
      }
      else
      { # Manual kick from this OP was legit and according with the rules. Record this manual kick in the bot so if the user begins to spam as an
        # retaliation to the kick, the user will be banned faster.
        ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($arguments->{kicked}));
        $bucket = $msg{$uidn};
        unless ($bucket =~ m/:/) {
          $bucket = "0:0:0:0:0";
        }
        ($number, $exp, $lmsg, $kicked, $warned) = split(":", $bucket);
        if ($warned eq "2") {
          $msg{$uidn} = $number.":".$exp.":".$lmsg.":1:1";
        }
        else
        {
          $msg{$uidn} = $number.":".$exp.":".$lmsg.":1:".$warned;
        }
      }
    }
  }
  $hasnotwritten{$arguments->{kicked}} = 1;
  return undef;
}

sub mode_change {
  $self = shift;
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
  @operlist = @{ $arguments->{mode_operands} };
  $logchanged = "true";
  unless (($arguments->{who} eq "ChanServ")||($arguments->{who} eq "Anna")) {
    if ($self->pocoirc->is_channel_operator($arguments->{channel},'Anna') != 1) {
      $self->say(channel => "msg", who => "ChanServ", body => "OP ".$arguments->{channel});
      push(@log, $timestampprefix. "] *** N\xE5gon idiot som deoppade mig. Reoppar i ".$arguments->{channel});
      $logchanged = "true";
      if ($#log > 40) {
        shift(@log);
      }
    }
    foreach $oppeduser (@operlist) {
      $oppeduser =~ s/\!//sgi;
      $oppeduser =~ s/\@//sgi;
      if ($self->pocoirc->is_channel_member($arguments->{channel},$oppeduser) == 1) {      
        ($istor, $oppedid, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($oppeduser));
        if ($self->pocoirc->is_channel_operator($arguments->{channel},$oppeduser) == 1) {
          if ($opban{$oppedid} == 1) {
            $self->mode($arguments->{channel}." -o ".$oppeduser);
            push(@log, $timestampprefix. "] *** ".$arguments->{who}." f\xF6rs\xF6kte oppa den OP-bannade ".$oppeduser);
            $logchanged = "true";
            if ($#log > 40) {
              shift(@log);
            }
          }
        }
        if ($self->pocoirc->is_channel_halfop($arguments->{channel},$oppeduser) == 1) {
          if ($opban{$oppedid} == 1) {
            $self->mode($arguments->{channel}." -h ".$oppeduser);
            push(@log, $timestampprefix. "] *** ".$arguments->{who}." f\xF6rs\xF6kte halfoppa den OP-bannade ".$oppeduser);
            $logchanged = "true";
            if ($#log > 40) {
              shift(@log);
            }
          }
        }
        if ($self->pocoirc->has_channel_voice($arguments->{channel},$oppeduser) == 1) {
          if ($opban{$oppedid} == 1) {
            $self->mode($arguments->{channel}." -v ".$oppeduser);
            push(@log, $timestampprefix. "] *** ".$arguments->{who}." f\xF6rs\xF6kte voica den OP-bannade ".$oppeduser);
            $logchanged = "true";
            if ($#log > 40) {
              shift(@log);
            }
          }
        }
      }
    }
  }
}

sub chanjoin { # This function is called everytime someone joins
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
  push(@log, $timestampprefix. "] *** ".$arguments->{who}." joinade ".$arguments->{channel}.".");
  $logchanged = "true";
  if ($#log > 40) {
    shift(@log);
  }
  if ($iswatched{$arguments->{who}} eq "1") {
    $vct = time;
    transmitmail("Den vaktade personen ".$arguments->{who}." joinade ".$arguments->{channel}."\n");
    open(TMPFILE, ">/var/spool/asterisk/tmp/irc.".$vct.$$.".call");
    print TMPFILE "Channel: Local/s\@wakeup\n";
    print TMPFILE "Callerid: \"".$arguments->{who}." joinade din kanal!\" <0>\n";
    print TMPFILE "Application: Playback\n";
    print TMPFILE "Data: conf-hasjoin\n";
    close(TMPFILE);
    system("chmod 777 /var/spool/asterisk/tmp/irc.".$vct.$$.".call");
    rename("/var/spool/asterisk/tmp/irc.".$vct.$$.".call","/var/spool/asterisk/outgoing/irc.a".$vct.$$.".call");
    $self->say(channel => $arguments->{channel}, body => $arguments->{who}.": Ringer upp Sebastian p\xE5 hans telefon nu...");
  }

  $hostname = $self->pocoirc->nick_long_form($arguments->{who});
  ($istor, $idnum, $displayid, $banmask) = getidfromhost($hostname);
  ($nickreal, $hostpart) = split(/\@/, $hostname);
   if (lc($arguments->{who}) eq "chloe") {
    if ($hostpart ne "chloe.chloe") {
      $self->mode($arguments->{channel}." +b ".$banmask);
      $self->kick($arguments->{channel}, $arguments->{who}, "Omoget att fakenicka chloe");
      transmitmail("Bannade omogen person som fakenickar chloe med host (".$hostpart.").\n");
    }
  }
  if (lc($arguments->{who}) eq "sebastian") {
    if (($hostpart ne "dns2.sebbe.eu")&&($hostpart ne "swehack-ep8.85g.agg3sg.IP")) {
      $self->mode($arguments->{channel}." +b ".$banmask);
      $self->say(channel => "msg", who => "NickServ", body => "GHOST sebastian ".$ghostpassword);
      transmitmail("Ghostade och bannade omogen person som fakenickar dig med host (".$hostpart.").\n");
    }
  }
  return undef;
} 


sub tick {
  $self = shift;
  if (-e "/var/secure_files/bot/remote.txt") {
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
    open(CMD, "/var/secure_files/bot/remote.txt");
    $fetchcommand = <CMD>;
    close(CMD);
    $fetchcommand =~ s/\n//sgi;
    unlink("/var/secure_files/bot/remote.txt");
    ($command, $arg0, $arg1, $remoteip, $garbage) = split(/\|/,$fetchcommand);
    unless ($command eq "MSG") {
      $self->say(channel => "#sebastian", body => "[FJ\xC4RRSTYRNING] Fick ".$command." arg0=\"".$arg0."\" arg1=\"".$arg1."\" ifr\xE5n IP ".$remoteip);
      push(@log, $timestampprefix."] <\@Anna> [FJ\xC4RRSTYRNING] Fick ".$command." arg0=\"".$arg0."\" arg1=\"".$arg1."\" ifr\xE5n IP ".$remoteip);
      $logchanged = "true";
      if ($#log > 40) {
        shift(@log);
      }
    }
    if ($command eq "GHOST") {
      $self->say(channel => "msg", who => "NickServ", body => "GHOST sebastian ".$ghostpassword);
    }
    if ($command eq "KICKBAN") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        ($istor, $idnum, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($arg0));
        $self->mode("#sebastian +b ".$banmask);
        $self->kick("#sebastian", $arg0, $arg1);
      }
    }
    if ($command eq "KICK") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        $self->kick("#sebastian", $arg0, $arg1);
      }
    }
    if ($command eq "OP") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        ($istor, $idnum, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($arg0));
        unless ($opban{$idnum} == 1) {
          $self->mode("#sebastian +o ".$arg0);
        }
      }
    }
    if ($command eq "DEOP") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        $self->mode("#sebastian -o ".$arg0);
      }
    }
    if ($command eq "HALFOP") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        ($istor, $idnum, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($arg0));
        unless ($opban{$idnum} == 1) {
          $self->mode("#sebastian +h ".$arg0);
        }
      }
    }
    if ($command eq "DEHALFOP") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        $self->mode("#sebastian -h ".$arg0);
      }
    }
    if ($command eq "VOICE") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        ($istor, $idnum, $displayid, $banmask) = getidfromhost($self->pocoirc->nick_long_form($arg0));
        unless ($opban{$idnum} == 1) {
          $self->mode("#sebastian +v ".$arg0);
        }
      }
    }
    if ($command eq "DEVOICE") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        $self->mode("#sebastian -v ".$arg0);
      }
    }
    if ($command eq "CLRUSER") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($arg0));
        unless ($opban{$uidn} == 1) {
          $msg{$uidn} = "0:0:0:0:0";
        }
      }
    }
    if ($command eq "OPBAN") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($arg0));
        $opban{$uidn} = 1;
        $self->mode("#sebastian -voh ".$arg0);
      }
    }
    if ($command eq "OPUNBAN") {
      if ($self->pocoirc->is_channel_member("#sebastian",$arg0) == 1) {
        ($uist, $uidn, $udisp, $uban) = getidfromhost($self->pocoirc->nick_long_form($arg0));
        $opban{$uidn} = 0;
      }
    }

    if ($command eq "USERCMD") {
      if ($arg0 eq "true") {
        $usercmd = "true";
      }
      else
      {
        $usercmd = "false";
      }
    }
    if ($command eq "DEFCON") {
      if ($arg0 eq "true") {
        if ($defcon eq "false") {
          $defcon = "true";
          $oldtopic = $self->topic("#sebastian");
          $self->mode("#sebastian +t");
          $self->topic("#sebastian", "!! VARNING !! Undantagstillst\xE5nd r\xE5der. Ni som \xE4r anslutna via TOR, skriv inte utan inv\xE4nta voice fr\xE5n kanaloperat\xF6r innan ni skriver! Inga varningar kommer ges innan ban !!");
        }
      }
      else
      {
        if ($defcon eq "true") {
          $defcon = "false";
          $self->mode("#sebastian -t");
          $self->topic("#sebastian", $oldtopic);
        }
      }
    }
    if (($command eq "QB")||($command eq "QT")) {
        $arg1 = lc($arg1);
        $arg1 =~ s/\@//sgi;
        $arg1 =~ s/\!//sgi;
        if (length($arg1) > 0) {
          @allusers = $self->channel_list("#sebastian");
          if ($command eq "QT") {
            $self->mode("#sebastian +b ".$arg1."*!".$arg1."*\@*.4uh.b8obtf.IP");
            $dotor = "true";
          }
          else
          {
            $self->mode("#sebastian +b ".$arg1."*!".$arg1."*\@*");
            $dotor = "false";
          }
          foreach $usernick (@allusers) {
            $ufh = lc($self->pocoirc->nick_long_form($usernick));
            ($un, $uh) = split(/\@/, $ufh);
            ($bn, $bu) = split(/\!/, $un);
            unless (($usernick eq "Anna")||($usernick eq "Sebastian")||($usernick eq "chloe")) {
              if ((substr($bn,0,length($arg1)) eq $arg1)&&(substr($bu,0,length($arg1)) eq $arg1)) {
                if ($dotor eq "true") {
                  if ($uh =~ m/\.4uh\.b8obtf\.IP$/) {
                    $self->kick("#sebastian", $usernick, "Inga spambottar h\xE4r, tack!");
                  }
                }
                else
                {
                  $self->kick("#sebastian", $usernick, "Inga spambottar h\xE4r, tack!");
                }
              }
            }
          }
        }
    }
    if ($command eq "MSG") {
      $self->say(channel => "#sebastian", body => "[".$remoteip."]: ".$arg0);
      push(@log, $timestampprefix."] <\@Anna> [".$remoteip."]: ".$arg0);
      $logchanged = "true";
      if ($#log > 40) {
        shift(@log);
      }
    }
  }
  if ($logchanged eq "true") {
    $logchanged = "false";
    $channeldata = "";
    @allnicks = $self->pocoirc->channel_list("#sebastian");
    foreach $nick (@allnicks) {
      $nickprefix = "";
      if ($self->pocoirc->has_channel_voice("#sebastian",$nick) == 1) {
        $nickprefix = "\+";
      }
      if ($self->pocoirc->is_channel_halfop("#sebastian",$nick) == 1) {
        $nickprefix = "\%";
      }
      if ($self->pocoirc->is_channel_operator("#sebastian",$nick) == 1) {
        $nickprefix = "\@";
      }
      if ($self->pocoirc->is_channel_admin("#sebastian",$nick) == 1) {
        $nickprefix = "\&";
      }
      if ($self->pocoirc->is_channel_owner("#sebastian",$nick) == 1) {
        $nickprefix = "\~";
      }
      $fullnick = $nickprefix.$nick;
      $channeldata = $channeldata . $fullnick . "!!";
    }
    open(LOGCHANNEL, ">/var/secure_files/bot/logchannel.txt");
    flock(LOGCHANNEL,2);
    print LOGCHANNEL $channeldata . "|";
    foreach $entry (@log) {
      print LOGCHANNEL $entry."|";
    }
    close(LOGCHANNEL);
  }

  ( $day, $month, $year ) = (localtime)[3,4,5];
  $currentdate = $day."-".($month+1)."-".($year+1900);
  unless ($currentdate eq $lastclear) {
    $lastclear = $currentdate;
    foreach $k (keys %msg) {
      unless ($opban{$k} == 1) {
        $msg{$k} = "";
      }
    }
    %hasnotwritten = ();
    %ytlock = ();
  }
return 15;
}

sub chanpart { # This function is called everytime someone joins
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
  push(@log, $timestampprefix. "] *** ".$arguments->{who}." l\xE4mnade ".$arguments->{channel}.".");
  $logchanged = "true";
  if ($#log > 40) {
    shift(@log);
  }
  if ($iswatched{$arguments->{who}} eq "1") {
    transmitmail("Den vaktade personen ".$arguments->{who}." l\xE4mnade ".$arguments->{channel}."\n");
  }
  return undef;
}

sub userquit { # This function is called everytime someone joins
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
  push(@log, $timestampprefix. "] *** ".$arguments->{who}." l\xE4mnade ".$arguments->{channel}.".");
  $logchanged = "true";
  if ($#log > 40) {
    shift(@log);
  }
  if ($iswatched{$arguments->{who}} eq "1") {
    transmitmail("Den vaktade personen ".$arguments->{who}." l\xE4mnade ".$arguments->{channel}."\n");
  }
  return undef;
}

sub do_weather { # This function corresponds to the weather function
  $human = $_[0];
  $city = lc($_[1]);
  $city =~ s/Ä/\xE4/sg;
  $city =~ s/Å/\xE5/sg;
  $city =~ s/Ö/\xF6/sg;
  $city =~ s/\xC4/\xE4/sg;
  $city =~ s/\xC5/\xE5/sg;
  $city =~ s/\xD6/\xF6/sg;
  $city =~ s/ä/\xE4/sg;
  $city =~ s/å/\xE5/sg;
  $city =~ s/ö/\xF6/sg;
  $city =~ s/[^abcdefghijklmnopqrstuvwxyz\xE5\xE4\xF6]*//sg;
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
        $rawmess = $human.": Vädret i ".$cityname.": ".$descriptions.$temperature." *C, ".$windspeed." m/s, ".$humidity." \% luftfuktighet, ".$clouds." \% molntäcke, ".$pressure." hPa";
      }
      else
      {
        if ($rbody =~ m/(city|geocode)/) {
          $rawmess = $human.": Oj. Den staden verkar inte finnas.";
        }
        else
        {
          $rawmess = $human.": Oj. OpenWeatherMap verkar ligga nere.";
        }
      }
      $rawmess =~ s/ä/\xE4/sg;
      $rawmess =~ s/å/\xE5/sg;
      $rawmess =~ s/ö/\xF6/sg;
      $rawmess =~ s/Ä/\xC4/sg;
      $rawmess =~ s/Å/\xC5/sg;
      $rawmess =~ s/Ö/\xD6/sg;
      $ytlock{'DOWEATHER!_CACHE'.$city} = time + 3600;
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
      $ytlock{'OPMSG!_FUNCTION'} = time + 30*60;
      $inmessage =~ s/ä/\xE4/sg;
      $inmessage =~ s/å/\xE5/sg;
      $inmessage =~ s/ö/\xF6/sg;
      $inmessage =~ s/Ä/\xC4/sg;
      $inmessage =~ s/Å/\xC5/sg;
      $inmessage =~ s/Ö/\xD6/sg;
      transmitmail("OP-meddelande fr\xE5n ".$human." via OPMSG. Meddelandet \xE4r:\n".$inmessage."\n\n");
      $message = $human.": Meddelande skickat!";
    }
    else
    {
      $message = $human.": .opmsg kan bara anv\xE4ndas en g\xE5ng i halvtimmen!";
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
    if (int($ytlock{'CRYPTOCURRENCY!_CACHE'}) < time) {
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
      $timeleft = int($ytlock{'CRYPTOCURRENCY!_CACHE'}) - time;
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


sub transmitmail { #Sends a simple mail. Text in first argument. Log and the rest of text is included automatically.
  $mailbody = $_[0];
  $mailsubject = $_[0];
  $mailsubject =~ s/\n//sgi;
  $mailsubject = substr($mailsubject, 0, 75);
  $mailbody = $mailbody . "H\xE4r kommer loggen:\n\n";
  foreach $line (@log) {
    $mailbody = $mailbody . $line . "\n";
  }
  $mailbody = $mailbody . "\nMed v\xE4nliga h\xE4lsningar, Anna";
  $maildate = email_date;
  $mime = MIME::Entity->build(Type => "text/plain; charset=iso-8859-1", From => "Boten Anna <anna\@sebbe.eu>", To => "sebastian\@sebbe.eu", Subject => $mailsubject, Date => $maildate, Data => $mailbody);
  open(MAIL, "|/usr/lib/dovecot/deliver -c /etc/dovecot/dovecot.conf -m \"\"");
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
  if ((($partb eq "swehack-q25.4uh.b8obtf.IP")||($partb eq "127.0.0.1"))&&($defcon eq "false")) { # Host is TOR .onion node. To ban these, we need to rely on usernames instead.
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
  channels    => ['#sebastian'],
  password    => $bot_password,
  nick        => 'Anna',
  name        => 'Sebastian Nielsen',
  ignore_list => ['NickServ','ChanServ'],
);
$bot->run();
