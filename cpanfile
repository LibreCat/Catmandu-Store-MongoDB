requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Exception', '0.32';
  requires 'Test::More', '1.001003';
  requires 'Test::Warn', 0;
  requires 'Test::Pod', 0;
  requires 'Software::License','0.103010';
};

requires 'Catmandu', '0.9205';
requires 'JSON::MaybeXS', '1.003005';
requires 'MongoDB', '1.0.0';
requires 'Moo','1.006000';
