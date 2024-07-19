use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Math::BigInt;

my @data = qw(
  0           0
  〇          0
  零          0
  1           1
  一          1
  弌          1
  壹          1
  壱          1
  2           2
  二          2
  弍          2
  貳          2
  貮          2
  弐          2
  贰          2
  3           3
  弎          3
  參          3
  参          3
  叁          3
  叄          3
  4           4
  四          4
  亖          4
  肆          4
  5           5
  五          5
  伍          5
  6           6
  六          6
  陸          6
  陆          6
  7           7
  七          7
  柒          7
  漆          7
  質          7
  8           8
  八          8
  捌          8
  9           9
  九          9
  玖          9
  10          10
  十          10
  一十        10
  拾          10
  二拾        20
  廿          20
  卄          20
  廾          20
  卅          30
  丗          30
  卌          40
  𠦜          40
  壹貳        12
  十五        15
  二二        22
  二十二      22
  22          22
  二十        20
  三十        30
  四十        40
  二百        200
  二二二二二二百 error
  百          100
  陌          100
  佰          100
  百十        110
  百百        error
  皕          200
  一皕        error
  二皕        error
  皕百        error
  皕廿        220
  一万皕      10200
  皕萬        2000000
  一百        100
  一百一十一  111
  一百一一    error
  一一百一    error
  一百一一一  error
  二百        200
  三百        300
  四陌        400
  陸佰        600
  千          1000
  阡          1000
  仟          1000
  一千        1000
  千五百      1500
  二千        2000
  三千        3000
  千二千      error
  弌万        10000
  万          error
  萬          error
  五万        50000
  一萬        10000
  百万        1000000
  ニ          error
  二こ        error
  二零零      200
  零三二二    322
  零二二      22
  零二        2
  零零零三    3
  零零零零    0
  零零零三二  32
  零百二      2
  百二        102
  百拾        110
  壱百壱拾    110
  壱壱零      110
  百二二      error
  百二二二    error
  百二百      error
  百二十二    122
  一二三      123
  二千二百    2200
  二千二二百  error
  二百二千    error
  二万二百二千 error
  二万千      21000
  二万千二    21002
  零万二千    2000
  零千        0
  二千万      20000000
  二百二十二万 2220000
  444万412    4440412
  廿万        200000
  廿二        22
  廿廿        error
  三廿        error
  百廿        120
  廿千廿      error
  廿百        error
  廿千廿百    error
  廿千一百    error
  阡弐        1002
  仟壱拾      1010
  零卌        error
  億          error
  兆          error
  京          error
  五京        50000000000000000
  五億        500000000
  五億五十五万 500550000
  八三〇五四万 830540000
  五十億三千  5000003000
  五十五億六十万 5500600000
  五十五万億六十六億 error
  三兆        3000000000000
  四京        40000000000000000
  五京        50000000000000000
  壹貳叄四五六 123456
  １２３４５万 123450000
  ６７８９０万 678900000
  120万8千    1208000
  1億200万    102000000
  五十万五千億 error
  12万12345   error
  12345万21   123450021
  1百万       1000000
  123百万     123000000
  1億23百万   123000000
  14百万124万 error
  14百万4万   error
  卅有二      32
  七十有六    76
  二十有五万  250000
  4.5百万     4500000
  4.5佰萬     4500000
  4千         4000
  4阡         4000
  4千24       4024
  千24        1024
  0千24       24
  4阡24       4024
  4千4        4004
  千4         1004
  0千4        4
  4千41十     error
  4千234      4234
  8千6佰      8600
  7千24百     error
  4千二十五33 error
  4千24万23   40240023
  8百21       error
  8百5        805
  3000.1億    300010000000
  1兆8,000億  1800000000000
  1兆80,00億  error
  1兆800,0億  error
  1兆8000,億  error
  1,555       1555
  1,555万     15550000
  1，555万    15550000
  21,555万    215550000
  1215,55万   error
  15,55       error
  15,55万     error
  1.234       1.234
  12.45兆     12450000000000
  4.00万      40000
  4．00万     40000
  4..0        error
  10.2        10.2
  .313        error
  .42万       error
  三四        34
  一二十      error
  五六十      error
  四十五六    error
  五六万      560000
  零点五      error
  45亿        4500000000
  一百零八    108
  一万零八百  10800
  一万零八百零五 10805
  一万零零七百 error
  一万零八千  error
  一万零千    10000
  一万四千零五十 14050
  一万四千零五百 error
  一万四千零零六 14006
  10亿零817万5288 1008175288
  有          error
  有三        error
  零十有六    6
  4333千      4333000
  4,333千     4333000
  4,333.12千  4333120
  1,234,333千 1234333000
  1234333千   1234333000
  1,234,333千2 1234333002
  三・五億    350000000
  3・5億      350000000
  1,234兆5,678億9,012万3,456 1234567890123456
  六垓五京    600050000000000000000
  六穣五𥝱    60005000000000000000000000000
  六穰五秭    60005000000000000000000000000
  五秭六穰    error
  七千八穰    70080000000000000000000000000000
  四百又三    403
  四又        error
);
push @data,
    '4 222千' => '4222000',
    '1兆8 000億' => '1800000000000',
    '1 555万' => '15550000',
    "1\x{A0}555万" => '15550000',
    "1\x{2009}555万" => '15550000',
    "1\x{202F}555万" => '15550000',
    '21 555万' => '215550000',
    "3\x{B7}5万" => '350000000';

my $Data = {'' => undef};

while (@data) {
  my $input = shift @data;
  my $expected = shift @data;
  if ($expected eq 'error') {
      $Data->{$input} = undef;
  } else {
    my $v = Math::BigInt->new ($expected);
    if ($v < 2**32 or $expected =~ /\./) {
      $Data->{$input} = 0+$expected;
    } else {
      $Data->{$input} = $v;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
