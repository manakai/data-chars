use strict;
use warnings;
use Path::Tiny;
use lib path (__FILE__)->parent->child ('lib')->stringify;
use lib glob path (__FILE__)->parent->child ('modules', '*', 'lib')->stringify;
use JSON::PS;

my $Data = {};

{
  ## <https://wiki.suikawiki.org/n/%E5%88%B6%E5%BE%A1%E6%96%87%E5%AD%97>
  my $in = q{
,ABBR1,ABBR2,NAME,IR001,IR007,IR026,IR036,IR040,IR048,IR056,IR067,IR073,IR074,IR077,IR104,IR105,IR106,IR107,IR124,IR130,IR132,IR133,IR134,IR135,IR136,IR140,ESC+,UCS
,ACK,,ACKNOWLEDGE,,06,06,,,,,,,06,,,,,,,06,,,,,,06,,06
,APA,,ACTIVE POSITION ADDRESS,,,,,,,,,,,,,,,,,,,,1F,,,,,
,APB,,ACTIVE POSITION BACKWARD,,,,,,,,,,,,,,,,,,08,,08,08,,,,
,APD,,ACTIVE POSITION DOWN,,,,,,,,,,,,,,,,,,0A,,0A,0A,,,,
,APF,,ACTIVE POSITION FORWARD,,,,,,,,,,,,,,,,,,09,,09,09,,,,
,APH,,ACTIVE POSITION HOME,,,,,,,,,,,,,,,,,,1E,,1E,1E,,,,
,APR,,ACTIVE POSITION RETURN,,,,,,,,,,,,,,,,,,0D,,0D,0D,,,,
,APS,,ACTIVE POSITION SET,,,,,,,,,,,,,,,,,,1C,,,1C,,,,
,APU,,ACTIVE POSITION UP,,,,,,,,,,,,,,,,,,0B,,0B,0B,,,,
,ABK,,ALPHA BLACK,,,,,,,80,,,,,,,,,,,,,,,,,,
,ANB,,ALPHA BLUE,,,,,,,84,,,,,,,,,,,,,,,,,,
,ANC,,ALPHA CYAN,,,,,,,86,,,,,,,,,,,,,,,,,,
,ANG,,ALPHA GREEN,,,,,,,82,,,,,,,,,,,,,,,,,,
,ANM,,ALPHA MAGENTA,,,,,,,85,,,,,,,,,,,,,,,,,,
,ANR,,ALPHA RED,,,,,,,81,,,,,,,,,,,,,,,,,,
,ANW,,ALPHA WHITE,,,,,,,87,,,,,,,,,,,,,,,,,,
,ANY,,ALPHA YELLOW,,,,,,,83,,,,,,,,,,,,,,,,,,
,APC,,APPLICATION PROGRAM COMMAND,,,,,,,,,,,9F,,,,,,,,,,,,,,9F
,COL,,BACKGROUND OR FOREGROUND COLOR,,,,,,,,,,,,,,,,,,,90,,,,,,
,,BS,BACKSPACE,,08,08,,,,,,,08,,,,08,,,08,,,,,,08,,08
,BEL,,BELL,07,07,,07,,,,,,07,,,,,,,07,07,,,07,,07,,07
,BBD,,BLACK BACKGROUND,,,,,,,9C,,,,,,,,,,,,,,,,,,
,BKB,,BLACK BACKGROUND,,,,,,,,,90,,,,,,,,,,,,,,,,
,BKF,,BLACK FOREGROUND,,,,,,,,,80,,,,,,,,,,80,,,,,,
,BSTA,,BLINK START,,,,,,,,,,,,,,,,,,,,,,8E,,,
,BSTO,,BLINK STOP,,,,,,,,,,,,,,,,,,,,,,9E,,,
,BLB,,BLUE BACKGROUND,,,,,,,,,94,,,,,,,,,,,,,,,,
,BLF,,BLUE FOREGROUND,,,,,,,,,84,,,,,,,,,,84,,,,,,
,BPH,,BREAK PERMITTED HERE,,,,,,,,,,,,,,,,,,,,,,,,,82
,CAN,,CANCEL CHARACTER,18,,,18,,,,,,18,,,,,,,18,18,,18,18,,18,,18
,CCH,,CANCEL CHARACTER,,,,,,,,,,,94,,,,,,,,,,,,,,94
,,CR,CARRIAGE RETURN,,,,,,,,,,0D,,,,0D,,,0D,,,,,,0D,,0D
,HTS,,CHARACTER TABULATION SET,,,,,,,,,,,,,,,,,,,,,,,,,88
,HTJ,,CHARACTER TABULATION WITH JUSTIFICATION,,,,,,,,,,,,,,,,,,,,,,,,,89
,CS,,CLEAR SCREEN,,,,,,,,,,,,,,,,,,0C,,0C,0C,,,,
,CUS,,CLOSE-UP FOR SORTING,,,,,87,,,87,,,,,,,,87,,,,,,,,,
,CMD,,CODING METHOD DELIMITER,,,,,,,,,,,,,,,,,,,,,,,,64,
,CDY,,CONCEAL DISPLAY,,,,,,,98,,98,,,,,,,,,,,,,,,,
,CDC,,CONCEAL DISPLAY CONTROL,,,,,,,,,,,,,,,,,,,92,,,,,,
,CSI,,CONTROL SEQUENCE INTRODUCER,,,,,,,9B,,9B,,9B,,,,9B,,,,,,,,,,9B
,COF,,CURSOR OFF,,,,,,,,,,,,,,,,,,,8F,14,,9D,,,
,CON,,CURSOR ON,,,,,,,,,,,,,,,,,,,8E,11,,,,,
,CNB,,CYAN BACKGROUND,,,,,,,,,96,,,,,,,,,,,,,,,,
,CNF,,CYAN FOREGROUND,,,,,,,,,86,,,,,,,,,,86,,,,,,
,DLE,,DATA LINKING ESCAPE,,10,10,,,,,,,10,,,,,,,10,,,,,,10,,10
,DEFD,,DEFINE DRCS,,,,,,,,,,,,,,,,,,,,,,83,,,
,DEPM,,DEFINE MACRO,,,,,,,,,,,,,,,,,,,,,,80,,,
,DEFP,,DEFINE P-MACRO,,,,,,,,,,,,,,,,,,,,,,81,,,
,DEFX,,DEFINE TEXTURE,,,,,,,,,,,,,,,,,,,,,,84,,,
,DEFT,,DEFINE TRANSMIT-MACRO,,,,,,,,,,,,,,,,,,,,,,82,,,
,DEL,,DELETE,,,,,,,,,,,,,,,,,,,,,,,,,7F
,DC4,,DEVICE CONTROL FOUR,14,14,14,14,,,,,,14,,,,,,,14,,,,,,14,,14
,DC1,,DEVICE CONTROL ONE,11,11,,11,,,,,,11,,,,,,,11,,,,,,11,,11
,DCS,,DEVICE CONTROL STRING,,,,,,,,,,,90,,,,,,,,,,,,,,90
,DC3,,DEVICE CONTROL THREE,13,13,,13,,,,,,13,,,,,,,13,,,,,,13,,13
,DC2,,DEVICE CONTROL TWO,12,12,,12,,,,,,12,,,,,,,12,,,,,,12,,12
,DMI,,DISABLE MANUAL INPUT,,,,,,,,,,,,,,,,,,,,,,,,60,
,DBH,,DOUBLE HEIGHT,,,,,,,8D,,8D,,,,,,,,,,,,,8D,,,
,DBS,,DOUBLE SIZE,,,,,,,8F,,8F,,,,,,,,,,,,,8F,,,
,DBW,,DOUBLE WIDTH,,,,,,,8E,,8E,,,,,,,,,,,,,,,,
,EDC4,,EDC FOUR,,,,,,,,,,,,,,,,,,,,,,94,,,
,EDC1,,EDC ONE,,,,,,,,,,,,,,,,,,,,,,91,,,
,EDC3,,EDC THREE,,,,,,,,,,,,,,,,,,,,,,93,,,
,EDC2,,EDC TWO,,,,,,,,,,,,,,,,,,,,,,92,,,
,EAB,,EMBEDING ANNOTATION BEGINNING,,,,,91,,,91,,,,,,,,91,,,,,,,,,
,EAE,,EMBEDING ANNOTATION END,,,,,92,,,92,,,,,,,,92,,,,,,,,,
,EMI,,ENABLE MANUAL INPUT,,,,,,,,,,,,,,,,,,,,,,,,62,
,END,,END,,,,,,,,,,,,,,,,,,,,,,85,,,
,EBX,,END BOX,,,,,,,8A,,8A,,,,,,,,,,,,,,,,
,EPA,,END OF GUARDED AREA,,,,,,,,,,,97,,,,,,,,,,,,,,97
,ECD,,END OF INSTRUCTION,,0B,0B,,,,,,,,,,,,,,,,,,,,,,
,,EM,END OF MEDIUM,19,19,19,19,,,,,,19,,,,,,,19,,,,,,,,19
,ESA,,END OF SELECTED AREA,,,,,,,,,,,87,,,,,,,,,,,,,,87
,ETX,,END OF TEXT,,03,03,,,,,,,03,,,,,,,03,,,,,,03,,03
,EOT,,END OF TRANSMISSION,,04,04,,,,,,,04,,,,,,,04,,,,,,04,,04
,ETB,,END OF TRANSMISSION BLOCK,,17,17,,,,,,,17,,,,,,,17,,,,,,17,,17
,ENQ,,ENQUIRY,,05,05,,,,,,,05,,,,,,,05,,,,,,05,,05
,ESC,,ESCAPE,1B,1B,1B,1B,,1B,,,,1B,,1B,,1B,,,1B,1B,,1B,1B,,1B,,1B
,FIL,,FIL CHARACTER,,,,,8A,,,,,,,,,,,,,,,,,,,,
,,FS,FILE SEPARATOR,,,,,,,,,,1C,,,,,,,1C,,,,,,,,1C
,FLC,,FLASH CURSOR,,,,,,,,,,,,,,,,,,,,,,9B,,,
,FSH,,FLASHING,,,,,,,88,,88,,,,,,,,,,,,,,,,
,FLC,,FLASHING CONTROL,,,,,,,,,,,,,,,,,,,91,,,,,,
,FT1,,FONT 1,,,,,,11,,,,,,,,,,,,,,,,,,,
,FT2,,FONT 2,,,,,,12,,,,,,,,,,,,,,,,,,,
,FT3,,FONT 3,,,,,,13,,,,,,,,,,,,,,,,,,,
,,FF,FORM FEED,,,,,,,,,,0C,,,,0C,,,0C,,,,,,0C,,0C
,FE0(BS),,FORMAT EFFECTOR 0 (BACKSPACE),08,,,08,,,,,,,,,,,,,,,,,,,,,08
,FE1(HT),,FORMAT EFFECTOR 1 (HORISONTAL TABULATION),09,,,09,,,,,,,,,,,,,,,,,,,,,09
,FE2(LF),,FORMAT EFFECTOR 2 (LINE FEED),0A,,,0A,,,,,,,,,,,,,,,,,,,,,0A
,FE3(VT),,FORMAT EFFECTOR 3 (VERTICAL TABULATION),0B,,,0B,,,,,,,,,,,,,,,,,,,,,0B
,FE4(FF),,FORMAT EFFECTOR 4 (FORM FEED),0C,,,0C,,,,,,,,,,,,,,,,,,,,,0C
,FE5(CR),,FORMAT EFFECTOR 5 (CARRIAGE RETURN),0D,,,0D,,,,,,,,,,,,,,,,,,,,,0D
,FO,,FORMATTING,,09,09,,,,,,,,,,,,,,,,,,,,,,
,GRB,,GREEN BACKGROUND,,,,,,,,,92,,,,,,,,,,,,,,,,
,GRF,,GREEN FOREGROUND,,,,,,,,,82,,,,,,,,,,82,,,,,,
,,GS,GROUP SEPARATOR,,,,,,1D,,,,1D,,,,,,,1D,,,,,,,,1D
,HMS,,HOLD MOSAIC,,,,,,,9E,,,,,,,,,,,,,,,,,,
,,HT,HORIZONTAL TABULATION,,,,,,,,,,09,,,,,,,09,,,,,,09,,09
,HTS,,HORIZONTAL TABULATION SET,,,,,,,,,,,88,,,,,,,,,,,,,,88
,HTJ,,HORIZONTAL TABULATION WITH JUSTIFICATION,,,,,,,,,,,89,,,,,,,,,,,,,,89
,ISI,,IDENTIFICATION NUMBER-IN-CONTEXT INDICATOR,,,,,8C,,,,,,,,,,,,,,,,,,,,
,IND,,INDEX,,,,,,,,,,,84,,,,,,,,,,,,,,
,INC,,INDICATOR FOR NON-STANDARD CHARACTER,,,,,99,,,,,,,,,,,,,,,,,,,,
,IS1,,INFORMATION SEPARATOR 1,,,,,,,,,,,,,,,,,,,,,,,1F,,0F
,IS1(US),,INFORMATION SEPARATOR 1 (UNIT SEPARATOR),1F,,,1F,,,,,,,,,,,,,,,,,,,,,0F
,IS2,,INFORMATION SEPARATOR 2,,,,,,,,,,,,,,,,,,,,,,,1E,,0E
,IS2(RS),,INFORMATION SEPARATOR 2 (RECODE SEPARATOR),1E,,,1E,,,,,,,,,,,,,,,,,,,,,0E
,IS3,,INFORMATION SEPARATOR 3,,,,,,,,,,,,,,,,,,,,,,,1D,,0D
,IS3(GS),,INFORMATION SEPARATOR 3 (GROUP SEPARATOR),1D,,,1D,,,,,,,,,,,,,,,,,,,,,0D
,IS4,,INFORMATION SEPARATOR 4,,,,,,,,,,,,,,,,,,,,,,,1C,,0C
,IS4(FS),,INFORMATION SEPARATOR 4 (FILE SEPARATOR),1C,,,,,,,,,,,,,,,,,,,,,,,,0C
,INT,,INTERRUPT,,,,,,,,,,,,,,,,,,,,,,,,61,
,ISB,,ITEM SPECIFICATION BEGINNING,,,,,93,,,,,,,,,,,,,,,,,,,,
,ISE,,ITEM SPECIFICATION END,,,,,94,,,,,,,,,,,,,,,,,,,,
,IPO,,IVERTED POLARITY,,,,,,,,,9D,,,,,,,,,,,,,,,,
,,JT,JUSTIFY,,1F,1F,,,,,,,,,,,,,,,,,,,,,,
,KWB,,KEYWORD BEGINNING,,,,,9C,,,9C,,,,,,,,9C,,,,,,,,,
,KWE,,KEYWORD END,,,,,9D,,,9D,,,,,,,,9D,,,,,,,,,
,,KW,KILL WORD,,18,18,,,,,,,,,,,,,,,,,,,,,,
,,LF,LINE FEED,,0A,0A,,,,,,,0A,,,,0A,,,0A,,,,,,0A,,0A
,VTS,,LINE TABULATION SET,,,,,,,,,,,,,,,,,,,,,,,,,8A
,LS1,,LOCKING SHIFT ONE,,,,,,,,,,,,,,0E,,,0E,,,0E,,,,,0E
,LS3,,LOCKING SHIFT THREE,,,,,,,,,,,,,,,,,,,,,,,,6F,
,LS3R,,LOCKING SHIFT THREE RIGHT,,,,,,,,,,,,,,,,,,,,,,,,7C,
,LS2,,LOCKING SHIFT TWO,,,,,,,,,,,,,,,,,,,,,,,,6E,
,LS2R,,LOCKING SHIFT TWO RIGHT,,,,,,,,,,,,,,,,,,,,,,,,7D,
,LS0,,LOCKING SHIFT ZERO,,,,,,,,,,,,,,0F,,,0F,,,0F,,,,,0F
,,LR,LOWER RAIL,,0F,,,,,,,,,,,,,,,,,,,,,,,
,MGF,,MAGENDA FOREGROUND,,,,,,,,,85,,,,,,,,,,85,,,,,,
,MGB,,MAGENTA BACKGROUND,,,,,,,,,95,,,,,,,,,,,,,,,,
,MSZ,,MEDIUM SIZE,,,,,,,,,,,,,,,,,,,89,,,,,,
,METX,,MEDIUM TEXT,,,,,,,,,,,,,,,,,,,,,,8B,,,
,,MW,MESSAGE WAITING,,,,,,,,,,,95,,,,,,,,,,,,,,95
,MBK,,MOSAIC BKACK,,,,,,,90,,,,,,,,,,,,,,,,,,
,MSB,,MOSAIC BLUE,,,,,,,94,,,,,,,,,,,,,,,,,,
,MSC,,MOSAIC CYAN,,,,,,,96,,,,,,,,,,,,,,,,,,
,MSG,,MOSAIC GREN,,,,,,,92,,,,,,,,,,,,,,,,,,
,MSM,,MOSAIC MAGENTA,,,,,,,95,,,,,,,,,,,,,,,,,,
,MSR,,MOSAIC RED,,,,,,,91,,,,,,,,,,,,,,,,,,
,MSW,,MOSAIC WHITE,,,,,,,97,,,,,,,,,,,,,,,,,,
,MSY,,MOSAIC YELLOW,,,,,,,93,,,,,,,,,,,,,,,,,,
,NAK,,NEGATIVE ACKNOWLEDGE,,15,15,,,,,,,15,,,,,,,15,,,,,,15,,15
,NBD,,NEW BACKGROUND,,,,,,,9D,,,,,,,,,,,,,,,,,,
,NEL,NL,NEXT LINE,,,,,,,,,,,85,,,,,,,,,,,,,,85
,NBH,,NO BREAK HERE,,,,,,,,,,,,,,,,,,,,,,,,,83
,NSB,,NON-SORTING CHARACTER(S) BEGINNING,,,,,88,,,88,,,,,,,,88,,,,,,,,,
,NSE,,NON-SORTING CHARACTER(S) END,,,,,89,,,89,,,,,,,,89,,,,,,,,,
,NPO,,NORMAL POLARITY,,,,,,,,,9C,,,,,,,,,,,,,,,,
,NSZ,,NORMAL SIZE,,,,,,,,,,,,,,,,,,,8A,,,,,,
,NOTX,,NORMAL TEXT,,,,,,,,,,,,,,,,,,,,,,8C,,,
,NORV,,NORMAL VIDEO,,,,,,,,,,,,,,,,,,,,,,89,,,
,NSR,,NOW SELECTIVE RESET,,,,,,,,,,,,,,,,,,1F,,,1F,,,,
,NUL,,NULL,00,00,00,00,,,,,,00,,,,,,,00,,,00,,,00,,00
,OSC,,OPERATING SYSTEM COMMAND,,,,,,,,,,,9D,,,,,,,,,,,,,,9D
,OSC,,OPTIONAL SYLLABICATION CONTROL,,,,,8D,,,,,,,,,,,,,,,,,,,,
,PLD,,PARTIAL LINE DOWN,,,,,,,,,,,8B,,,,8B,8B,,,,,,,,,8B
,PLU,,PARTIAL LINE UP,,,,,,,,,,,8C,,,,8C,8C,,,,,,,,,8C
,PSB,,PERMUTATION STRING BEGINNING,,,,,9E,,,9E,,,,,,,,9E,,,,,,,,,
,PSE,,PERMUTATION STRING END,,,,,9F,,,9F,,,,,,,,9F,,,,,,,,,
,P-MACRO,,PHOTO MACRO,,,,,,,,,,,,,,,,,,,95,,,,,,
,,PM,PRIVACY MESSAGE,,,,,,,,,,,9E,,,,,,,,,,,,,,9E
,PU1,,PRIVATE USE ONE,,,,,,,,,,,91,,,,,,,,,,,,,,91
,PU2,,PRIVATE USE TWO,,,,,,,,,,,92,,,,,,,,,,,,,,92
,PRO,,PROTECT,,,,,,,,,,,,,,,,,,,,,,90,,,
,PRT,,PROTECTED,,,,,,,,,,,,,,,,,,,9F,,,,,,
,,QC,QUAD CENTURE,,1D,1D,,,,,,,,,,,,,,,,,,,,,,
,,QL,QUAD LEFT,,0D,0D,,,,,,,,,,,,,,,,,,,,,,
,,QR,QUAD RIGHT,,1E,1E,,,,,,,,,,,,,,,,,,,,,,
,,RS,RECODE SEPARATOR,,,,,,1E,,,,1E,,,,,,,1E,,,,,,,,1E
,RDB,,RED BACKGROUND,,,,,,,,,91,,,,,,,,,,,,,,,,
,RDF,,RED FOREGROUND,,,,,,,,,81,,,,,,,,,,81,,,,,,
,RMS,,RELEASE MOSAIC,,,,,,,9F,,,,,,,,,,,,,,,,,,
,REP,,REPEAT,,,,,,,,,,,,,,,,,,,,,,86,,,
,RPT,,REPEAT,,,,,,,,,,,,,,,,,,,,12,,,,,
,RPC,,REPEAT CONTROL,,,,,,,,,,,,,,,,,,,98,,,,,,
,REPE,,REPEAT TO END OF LINE,,,,,,,,,,,,,,,,,,,,,,87,,,
,RIS,,RESET TO INITIAL STATE,,,,,,,,,,,,,,,,,,,,,,,,63,
,,RI,REVERSE INDEX,,,,,,,,,,,8D,,,,,,,,,,,,,,8E
,,RI,REVERSE LINE FEED,,,,,,,,,,,,,,,,,,,,,,,,,8E
,REVV,,REVERSE VIDEO,,,,,,,,,,,,,,,,,,,,,,88,,,
,SCOF,,SCROLL OFF,,,,,,,,,,,,,,,,,,,,,,98,,,
,SCON,,SCROLL ON,,,,,,,,,,,,,,,,,,,,,,97,,,
,SSB,,SECONDARY SORTING VALUE BEGINNING,,,,,,,,97,,,,,,,,97,,,,,,,,,
,SSE,,SECONDARY SORTING VALUE END,,,,,,,,98,,,,,,,,98,,,,,,,,,
,SDS,,SERVICE DELIMITER CHARACTER,,,,,,,,,,,,,,,,,,,,,1A,,,,
,STS,,SET TRANSMIT STATE,,,,,,,,,,,93,,,,,,,,,,,,,,93
,,SI,SHIFT IN,0F,,0F,0F,,,,,,0F,,,,,,,,,,,0F,,0F,,0F
,,SO,SHIFT OUT,0E,,0E,0E,,,,,,0E,,,,,,,,,,,0E,,0E,,0E
,SCI,,SINGLE CHARACTER INTRODUCER,,,,,,,,,,,,,,,,,,,,,,,,,9A
,SS3,,SINGLE SHIFT THREE,,,,,8F,,,,,,8F,,8F,1D,,,,1D,,1D,1D,,,,8F
,SS2,,SINGLE SHIFT TWO,,,,1C,8E,,,,,,8E,,8E,19,,,,19,,19,19,,19,,8E
,NSZ,,SINGLE SIZE,,,,,,,8C,,8C,,,,,,,,,,,,,,,,
,SZX,,SIZE CONTROL,,,,,,,,,,,,,,,,,,,8B,,,,,,
,SSZ,,SMALL SIZE,,,,,,,,,,,,,,,,,,,88,,,,,,
,SMTX,,SMALL TEXT,,,,,,,,,,,,,,,,,,,,,,8A,,,
,SGCI,,SINGLE GRAPHIC CHARACTER INTRODUCER,,,,,,,,,,,,,,,,,,,,,,,,,
,SIB,,SORTING INTERPOLATION BEGINNING,,,,,,,,95,,,,,,,,95,,,,,,,,,
,SIE,,SORTING INTERPOLATION END,,,,,,,,96,,,,,,,,96,,,,,,,,,
,SBX,,START BOX,,,,,,,8B,,8B,,,,,,,,,,,,,,,,
,SPL,,START LINING,,,,,,,,,,,,,,,,,,,99,,,,,,
,STL,,START LINING,,,,,,,9A,,9A,,,,,,,,,,,,,,,,
,SPA,,START OF GUARDED AREA,,,,,,,,,,,96,,,,,,,,,,,,,,96
,SOH,,START OF HEADING,,01,01,,,,,,,01,,,,,,,01,,,,,,01,,01
,SCD,,START OF INSTRUCTION,,0C,0C,,,,,,,,,,,,,,,,,,,,,,
,SSA,,START OF SELECTED AREA,,,,,,,,,,,86,,,,,,,,,,,,,,86
,SOS,,START OF STRING,,,,,,,,,,,,,,,,,,,,,,,,,98
,STX,,START OF TEXT,,02,02,,,,,,,02,,,,,,,02,,,,,,02,,02
,STD,,STEADY,,,,,,,89,,89,,,,,,,,,,,,,,,,
,STC,,STEADY CURSOR,,,,,,,,,,,,,,,,,,,,,,9C,,,
,SCD,,STOP CONCEAL,,,,,,,,,9F,,,,,,,,,,,,,,,,
,SPL,,STOP LINING,,,,,,,99,,99,,,,,,,,,,,,,,,,
,STL,,STOP LINING,,,,,,,,,,,,,,,,,,,9A,,,,,,
,,ST,STRING TERMINATOR,,,,,,,,,,,9C,,,,,,,,,,,,,,9C
,SUB,,SUBSTITUTE,1A,1A,1A,1A,,,,,,1A,,,,1A,,,1A,,,,,,,,1A
,,SS,SUPER SHIFT,,1C,1C,,,,,,,,,,,,,,,,,,,,,,
,SYN,,SYNCHRONOUS IDLE,,16,16,,,,,,,16,,,,,,,16,,,,,,16,,16
,TCI,,TAG-IN-CONTEXT INDICATOR,,,,,8B,,,,,,,,,,,,,,,,,,,,
,TC1(SOH),,TRANSMISSION CONTROL CHARACTER 1 (START OF HEADING),01,,,01,,,,,,,,,,,,,,,,,,,,,01
,TC10(ETB),,TRANSMISSION CONTROL CHARACTER 10 (END OF TRANSMISSION BLOCK),17,,,17,,,,,,,,,,,,,,,,,,,,,
,TC2(STX),,TRANSMISSION CONTROL CHARACTER 2 (START OF TEXT),02,,,02,,,,,,,,,,,,,,,,,,,,,02
,TC3(ETX),,TRANSMISSION CONTROL CHARACTER 3 (END OF TEXT),03,,,03,,,,,,,,,,,,,,,,,,,,,03
,TC4(EOT),,TRANSMISSION CONTROL CHARACTER 4 (END OF TRANSMISSION),04,,,04,,,,,,,,,,,,,,,,,,,,,04
,TC5(ENQ),,TRANSMISSION CONTROL CHARACTER 5 (ENQUIRY),05,,,05,,,,,,,,,,,,,,,,,,,,,05
,TC6(ACK),,TRANSMISSION CONTROL CHARACTER 6 (ACKNOWLEDGE),06,,,06,,,,,,,,,,,,,,,,,,,,,06
,TC7(DLE),,TRANSMISSION CONTROL CHARACTER 7 (DATA LINK ESCAPE),10,,,10,,,,,,,,,,,,,,,,,,,,,10
,TC8(NAK),,TRANSMISSION CONTROL CHARACTER 8 (NOGATIVE ACKNOWLEDGE),15,,,15,,,,,,,,,,,,,,,,,,,,,15
,TC9(SYN),,TRANSMISSION CONTROL CHARACTER 9 (SYNCHRONUS IDLE),16,,,16,,,,,,,,,,,,,,,,,,,,,16
,TRB,,TRANSPARENT BACKGROUND,,,,,,,,,9E,,,,,,,,,,,,,,,,
,USTA,,UNDERLINE START,,,,,,,,,,,,,,,,,,,,,,99,,,
,USTO,,UNDERLINE STOP,,,,,,,,,,,,,,,,,,,,,,9A,,,
,,US,UNIT SEPARATOR,,,,,,,,,,1F,,,,,,,1F,,,,,,,,1F
,UNP,,UNPROTECT,,,,,,,,,,,,,,,,,,,,,,9F,,,
,UNP,,UNPROTECTED,,,,,,,,,,,,,,,,,,,9E,,,,,,
,,UR,UPPER RAIL,,0E,,,,,,,,,,,,,,,,,,,,,,,
,,VT,VERTICAL TABULATION,,,,,,,,,,0B,,,,,,,0B,,,,,,0B,,0B
,VTS,,VERTICAL TABULATION SET,,,,,,,,,,,8A,,,,,,,,,,,,,,8A
,WHB,,WHITE BACKGROUND,,,,,,,,,97,,,,,,,,,,,,,,,,
,WHF,,WHITE FOREGROUND,,,,,,,,,87,,,,,,,,,,87,,,,,,
,WWOF,,WORD WRAP OFF,,,,,,,,,,,,,,,,,,,,,,96,,,
,WWON,,WORD WRAP ON,,,,,,,,,,,,,,,,,,,,,,95
,YLB,,YELLOW BACKGROUND,,,,,,,,,93,,,,,,,,,,,,,
,YLF,,YELLOW FOREGROUND,,,,,,,,,83,,,,,,,,,,83,,,

  };

  my $lines = [];
  for (split /\x0D?\x0A/, $in) {
    my @line = split /,/, $_, -1;
    shift @line;
    next unless @line;
    push @$lines, \@line;
  }
  my $header = shift @$lines;
  for my $line (@$lines) {
    my $v = {};
    for (0..$#$line) {
      $v->{$header->[$_]} = $line->[$_];
    }
    my $ctrl = $Data->{controls}->{$v->{NAME}} = {};
    $ctrl->{name} = $v->{NAME} if length $v->{NAME};
    $ctrl->{abbr} = $v->{ABBR1} if length $v->{ABBR1};
    $ctrl->{abbr2} = $v->{ABBR2} if length $v->{ABBR2};

    for my $key (keys %$v) {
      next if {NAME => 1, ABBR1 => 1, ABBR2 => 1}->{$key};
      my $w = $v->{$key};
      next if not length $w;
      die "Bad code |$w|" unless $w =~ /\A[0-9A-F]{2}\z/;
      my $x = hex $w;
      $Data->{sets}->{$key}->[$x] = $ctrl->{name};
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
