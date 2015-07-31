# MenuMeters
my fork of MenuMeters

It's a great utility being developed by http://www.ragingmenace.com/software/menumeters/ .
As shown there (as of July 2015) the original version doesn't work on El Capitan Beta. 
The basic reason is that SystemUIServer doesn't load Menu Extras not signed by Apple. 

I'm making here a minimal modification so that it runs as a faceless app, putting NSStatusItem's instead of NSMenuExtra's.
