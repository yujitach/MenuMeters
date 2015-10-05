# MenuMeters
my fork of MenuMeters for El Capitan

# Usage:
If you just want to use it, please go to http://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/ and download the binary there. Note: as written there, you might need to log out and log in (or maybe to reboot) once to enable the new version.

# Background:

It's a great utility being developed by http://www.ragingmenace.com/software/menumeters/ .
As shown there (as of July 2015) the original version doesn't work on El Capitan Beta. 
The basic reason is that SystemUIServer doesn't load Menu Extras not signed by Apple. 
I'm making here a minimal modification so that it runs as a faceless app, putting NSStatusItem's instead of NSMenuExtra's.

I contacted the author but haven't received the reply. To help people who's missing MenuMeters on El Capitan Beta, I decided to make the git repo public. 

# To hack:
Clone the git repo, open MenuMeters.xcodeproj, and build the target *PrefPane*. This should install the pref pane in your *~/Library/PreferencePanes/*. (You might need to remove the older version of MenuMeters by yourself.)
