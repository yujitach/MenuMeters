#!/usr/bin/perl
for $lang (<../MenuExtras/MenuMeterCPU/*.lproj>){
	($la)=($lang=~/([^\/]+)\.lproj/);
	mkdir "$la.lproj";
	unlink "$la.lproj/Localizable.strings";
	for $x(qw/CPU Disk Mem Net/){
		system(qq(cat ../MenuExtras/MenuMeter$x/$la.lproj/Localizable.strings >> $la.lproj/Localizable.strings));
	}
}