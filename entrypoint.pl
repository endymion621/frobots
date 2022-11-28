#!/usr/bin/perl 

$ENV{HOME} = "/home/builder";
#$ENV{GOROOT} = $ENV{HOME}."/rootgo";
#$ENV{GOPATH} = $ENV{HOME}."/go";
#$ENV{PATH} = $ENV{GOPATH}."/bin:".ENV{GOROOT}."/bin:".$ENV{HOME}."/.cargo/bin:".$ENV{PATH};

open(my $fh,"<",$ENV{HOME}."/.profile") || die "failed: $!";
while(<$fh>){
	chomp($_);
	if($_=~m#^([^\=]+)\=(.*)$#){
		$ENV{$1}=$2;
	}
}
exec(@ARGV);

