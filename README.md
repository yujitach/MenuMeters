# MenuMeters
My fork of MenuMeters for El Capitan, Sierra, High Sierra and Mojave.

# Usage:
If you just want to use it, please go to http://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/ or https://github.com/yujitach/MenuMeters/releases and download the binary. The detailed installation instruction is given in the former.

Note: as written there, you might need to log out and log in (or maybe to reboot) once to enable the new version.

# Other versions:
There are further forks of my version of MenuMeters, which implement more features. You might want to try them out:

- https://github.com/emcrisostomo/MenuMeters which has DMG installers 
- https://gitlab.com/axet/MenuMeters which has new features in the CPU meter, etc.

If you'd like your version mentioned here, please tell me at the issues page.

# Background:

It's a great utility being developed by http://www.ragingmenace.com/software/menumeters/ .
As shown there (as of July 2015) the original version doesn't work on El Capitan Beta. 
The basic reason is that SystemUIServer doesn't load Menu Extras not signed by Apple. 
I'm making here a minimal modification so that it runs as a faceless app, putting NSStatusItem's instead of NSMenuExtra's.

I contacted the author but haven't received the reply. To help people who's missing MenuMeters on El Capitan Beta, I decided to make the git repo public. 

# To hack:
Clone the git repo, open MenuMeters.xcodeproj, and build the target *PrefPane*. This should install the pref pane in your *~/Library/PreferencePanes/*. (You might need to remove the older version of MenuMeters by yourself.)
