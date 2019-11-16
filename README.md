# MenuMeters
My fork of MenuMeters for El Capitan, Sierra, High Sierra, Mojave and Catalina.

# Usage:
If you just want to use it, please go to http://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/ or https://github.com/yujitach/MenuMeters/releases and download the binary. The detailed installation instruction is given in the former.

# Other versions:
There are further forks of my version of MenuMeters, which implement more features. You might want to try them out:

- https://github.com/emcrisostomo/MenuMeters which has DMG installers 
- https://gitlab.com/axet/MenuMeters which has new features in the CPU meter, etc.

If you'd like your version mentioned here, please tell me at the issues page.

# Background:

It's a great utility originally developed at http://www.ragingmenace.com/software/menumeters/ .
The original version does not work on El Capitan and later, due to the fact that SystemUIServer doesn't load Menu Extras not signed by Apple any longer.

I'm making here a minimal modification so that it runs as a faceless app, putting NSStatusItem's instead of NSMenuExtra's.
Since then, many people contributed pull requests, most of which have been incorporated.

More recently, starting from Catalina, MenuMeters was changed from a preference pane within System Preferences to an independent app. This is due to an increasing amount of security features imposed by Apple on preference panes running within System Preferences, which made it too cumbersome to develop MenuMeters as a preference pane.

# To hack:
Clone the git repo, open MenuMeters.xcodeproj, and build the target *MenuMeters*. This will create an independent app which runs outside of System Preferences. 
