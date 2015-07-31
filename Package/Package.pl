#!/usr/bin/perl
#
#	Packaging script
#
#	Copyright (c) 2003-2014 Alex Harper
#

use strict;
use Cwd;


# Project Builder automatic variables
my $buildDir = $ENV{BUILT_PRODUCTS_DIR};
my $buildConfig = $ENV{CONFIGURATION};
my $buildConfigTmpDir = $ENV{CONFIGURATION_TEMP_DIR};

# Packaging settings
my $product = $ENV{PRODUCT_NAME};
my $version = $ENV{PRODUCT_VERSION};
my $imageDS = $ENV{IMAGE_DSSTORE};

# Installation items
my @packageItems = ();
foreach my $srcItem (map { $ENV{$_} } grep(/^PACKAGE_SOURCE_ITEM/, keys(%ENV))) {
	push @packageItems, $ENV{SRCROOT} . "/" . $srcItem;
}
foreach my $buildItem (map { $ENV{$_} } grep(/^PACKAGE_BUILD_ITEM/, keys(%ENV))) {
	push @packageItems, $ENV{BUILT_PRODUCTS_DIR} . "/" . $buildItem;
}

# Resource fork maintenace
my @rsrcforkItems = ();
foreach my $srcItem (map { $ENV{$_} } grep(/^RSRCFORK_SOURCE_ITEM/, keys(%ENV))) {
	push @packageItems, $ENV{SRCROOT} . "/" . $srcItem;
	push @rsrcforkItems, $ENV{SRCROOT} . "/" . $srcItem;
}
foreach my $buildItem (map { $ENV{$_} } grep(/^RSRCFORK_BUILD_ITEM/, keys(%ENV))) {
	push @packageItems, $ENV{BUILT_PRODUCTS_DIR} . "/" . $buildItem;
	push @rsrcforkItems, $ENV{BUILT_PRODUCTS_DIR} . "/" . $buildItem;
}

# Extra kill items
my @killItems = map { $ENV{$_} } grep(/^KILL_ITEM/, keys(%ENV));

# Build a source archive?
my $sourceArchive = !exists($ENV{NOSOURCEARCHIVE});

# Sanity
if (!($product && $version)) {
	die "Missing package name or version.\n";
} else {
	print "Packaging \"$product $version\"...\n";
}
if (! -d $buildDir) {
	die "Bad BUILT_PRODUCTS_DIR \"$buildDir\".\n";
}
if (! $buildConfig) {
	die "Missing CONFIGURATION.\n";
}
if (! -d $buildConfigTmpDir) {
	die "Bad CONFIGURATION_TEMP_DIR \"$buildConfigTmpDir\"\n";
}
if (!scalar(@packageItems)) {
	die "Nothing to package.\n";
}

# Nib strip
my $stripnibs = 1;
if (exists($ENV{STRIP_NIBS})) {
	$stripnibs = $ENV{STRIP_NIBS};
} else {
	if ($version =~ /b\d+$/) {
		print "Product version $version appears to be a beta, skipping nib strip.\n";
		$stripnibs = 0;
	}
}

# Clean old dmgs and tar.gz
opendir(BUILDDIR, $buildDir) || die "Can't read build directory \"$buildDir\".\n";
while (my $dirItem = readdir(BUILDDIR)) {
	if (($dirItem =~ /\.dmg$/) ||  ($dirItem =~ /\.tar$/) ||
		($dirItem =~ /\.tar.gz$/) || ($dirItem =~ /\.tgz$/)) {
		system("rm", "-r", "$buildDir/$dirItem");
		if ($?) {
			die "Failed to clean item \"$dirItem\". Error: $?\n";
		}
	}
}
closedir(BUILDDIR);

# End of clean
if ($ENV{ACTION} eq "clean") {
	exit 0;
}

# Begin actual packaging, clean out anything old
my $packageDir = "$buildConfigTmpDir/Packaging/";
if (-e $packageDir) {
	system("rm", "-r", "$packageDir");
	if ($?) {
		die "Unable to remove previous package temp \"$packageDir\". Error $?\n";
	}
}

# Construct paths for source and DMG content
my $packageContentDir = "$packageDir/$product/";
my $packageSourceDir = "$packageDir/$product $version Source/";

if (!(mkdir($packageDir) && mkdir($packageContentDir) && mkdir($packageSourceDir))) {
	die "Unable to create packaging dirs.\n";
}

# Start actual Packaging

# Copy non-resource bin files into temp
foreach my $itemPath (@packageItems) {
	if (! -e $itemPath) {
		die "Package item \"$itemPath\" not found.\n";
	}
	if (! grep { $_ eq $itemPath } @rsrcforkItems) {
		system("cp", "-r", $itemPath, $packageContentDir);
		if ($?) {
			die "Failed to copy package item \"$itemPath\" to temp. Error: $?\n";
		}
	}
}

# Fix permissions
system("/usr/bin/find", "-d", $packageContentDir, "-type", "f", "-exec", "/bin/chmod", "u+w,go-w", "{}", ";");
system("/usr/bin/find", "-d", $packageContentDir, "-type", "d", "-exec", "/bin/chmod", "0755", "{}", ";");

# Now strip the resources from all the bin files
system("/usr/bin/find", "-d", $packageContentDir, "-type", "f", "-exec", "/Developer/Tools/SplitForks", "-s", "{}", ";");
if ($?) {
	die "Failed to strip resource forks from packaging dir. Error: $?\n";
}
system("/usr/bin/find", "-d", $packageContentDir, "-name", "\"._*\"", "-delete");
if ($?) {
	die "Failed to strip AppleDouble files from packaging dir. Error: $?\n";
}

# Now copy the resource fork files
foreach my $itemPath (@packageItems) {
	if (! -e $itemPath) {
		die "Package item \"$itemPath\" not found.\n";
	}
	if (grep { $_ eq $itemPath } @rsrcforkItems) {
		system("/Developer/Tools/CpMac -r \"$itemPath\" \"$packageContentDir\"");
		if ($?) {
			die "Failed to copy package item \"$itemPath\" to temp. Error: $?\n";
		}
	}
}

# Fix permissions (again)
system("/usr/bin/find", "-d", $packageContentDir, "-type", "f", "-exec", "/bin/chmod", "u+w,go-w", "{}", ";");
system("/usr/bin/find", "-d", $packageContentDir, "-type", "d", "-exec", "/bin/chmod", "0755", "{}", ";");

# Copy source files into temp
my $sourcesDir = cwd();
if ($sourceArchive) {
	if (!opendir(SOURCEDIR, $sourcesDir)) {
		die "Can't list source dir \"$sourcesDir\".\n";
	}
	my @sourcesList = readdir(SOURCEDIR);
	closedir(SOURCEDIR);
	foreach my $sourceItem (@sourcesList) {
		if (($sourceItem ne ".") && ($sourceItem ne "..") && ($sourceItem ne "build")) {
			system("cp", "-r", "$sourcesDir/$sourceItem", $packageSourceDir);
			if ($?) {
				die "Failed to copy item \"$sourceItem\" from dir \"$sourcesDir\". Error: $?\n";
			}
		}
	}
	# Correct source permissions before we tar (or split)
	system("/usr/bin/find", "-d", $packageSourceDir, "-type", "f", "-exec", "/bin/chmod", "u+w,go-w", "{}", ";");
	system("/usr/bin/find", "-d", $packageSourceDir, "-type", "d", "-exec", "/bin/chmod", "0755", "{}", ";");
	# Now strip the resources from everything
	system("/usr/bin/find", "-d", $packageSourceDir, "-type", "f", "-exec", "/Developer/Tools/SplitForks", "-s", "{}", ";");
	if ($?) {
		die "Failed to strip resource forks from sources. Error: $?\n";
	}
	system("/usr/bin/find", "-d", $packageSourceDir, "-name", "._*", "-delete");
	if ($?) {
		die "Failed to strip AppleDouble files from temp sources. Error: $?\n";
	}
}


# Clean the dirs
system("/usr/bin/find", "-d", $packageDir, "-name", ".DS_Store", "-delete");
if ($?) {
	die "Clean of .DS_Store failed for package dir. Error: $?\n";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "*.pbxuser", "-delete");
if ($?) {
	die "Clean of .pbxuser failed for package dir. Error: $?\n";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "project.xcworkspace", "-exec", "rm", "-r", "{}", ";");
if ($?) {
	die "Clean of project.xcworkspace dirs failed for package dir. Error: $?\n";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "xcuserdata", "-exec", "rm", "-r", "{}", ";");
if ($?) {
	die "Clean of xcuserdata dirs failed for package dir. Error: $?\n";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "*.mode*", "-delete");
if ($?) {
	die "Clean of .mode* failed for package dir. Error: $?\n";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "pbdevelopment.plist", "-delete");
if ($?) {
	die "Clean of pbdevelopment.plist failed for package dir. Error: $?\n";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "CVS", "-exec", "rm", "-r", "{}", ";");
if ($?) {
	die "Clean of CVS dirs failed for package dir. Error: $?\n";
}

# Strip nibs if needed (from product dir only)
if ($stripnibs) {
	system("/usr/bin/find", "-d", $packageContentDir, "-path", "*.nib/classes.nib", "-delete");
	if ($?) {
		die "Strip nib \"classes.nib\" failed. Error: $?\n";
	}
	system("/usr/bin/find", "-d", $packageContentDir, "-path", "*.nib/info.nib", "-delete");
	if ($?) {
		die "Strip nib \"info.nib\" failed. Error: $?\n";
	}
	system("/usr/bin/find", "-d", $packageContentDir, "-path", "*.nib/data.dependency", "-delete");
	if ($?) {
		die "Strip nib \"data.dependency\" failed. Error: $?\n";
	}
}

# Do extra kills
foreach my $killItem (@killItems) {
	system("/usr/bin/find", "-d", $packageDir, "-name", $killItem, "-exec", "rm", "-r", "{}", ";");
	if ($?) {
		die "Item kill of \"$killItem\" failed for temp dir. Error: $?\n";
	}
}

# Fix text and RTF types to prevent other apps from stealing them when LaunchServices
# loses its mind (*sigh*)
system("/usr/bin/find", "-d", $packageDir, "-name", "*.rtf", "-exec", "/Developer/Tools/SetFile", "-c", "ttxt", "-t", "RTF ", "{}", ";");
if ($?) {
	die "RTF file type/creator fixup failed";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "*.rtfd", "-exec", "/Developer/Tools/SetFile", "-c", "ttxt", "-t", "RTF ", "{}", ";");
if ($?) {
	die "RTFD file type/creator fixup failed";
}
system("/usr/bin/find", "-d", $packageDir, "-name", "*.txt", "-exec", "/Developer/Tools/SetFile", "-c", "ttxt", "-t", "TEXT", "{}", ";");
if ($?) {
	die "Text file type/creator fixup failed";
}

# Add the DS_Store
if ($imageDS) {
	if (! -e $imageDS) {
		die "Failed to find base DS_Store \"$imageDS\". Error: $?\n";
	}
	system("cp", $imageDS, "$packageContentDir/.DS_Store");
	if ($?) {
		die "Failed to copy image DS_Store. Error: $?\n";
	}
}


# Configuration name only appears for non-release
my $dmgFileName = "$product.dmg";
my $dmgVolName = "$product $version";
if ($buildConfig ne "Release") {
	$dmgFileName = "$product" . "_" . $buildConfig . ".dmg";
	$dmgVolName = "$product $version $buildConfig";
}

# Build the disk image
system("/usr/bin/hdiutil", "create", "-srcfolder", $packageContentDir, "-volname",
		$dmgVolName, "$buildDir/$dmgFileName");
if ($?) {
	die "Failed to create disk image. Error: $?\n";
}

# Tarball sources
if ($sourceArchive) {
	my $oldDir = cwd();
	if (!chdir($packageDir)) {
		die "Failed to chdir to \"$packageDir\" for tarball.\n";
	}
	system("tar", "-cvf", "$buildDir/$product.tar", "$product $version Source");
	if ($?) {
		die "Failed to tarball \"$packageSourceDir\". Error: $?\n";
	}
	if (!chdir($oldDir)){
		die "Failed to restore dir \"$oldDir\" after tar.\n";
	}
	# Compress
	system("/usr/bin/gzip", "$buildDir/$product.tar");
	if ($?) {
		die "Failed to gzip \"$buildDir/$product.tar\". Error: $?\n";
	}
}

# Clean exit
exit 0;
