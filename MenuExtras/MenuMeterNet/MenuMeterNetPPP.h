//
//  MenuMeterNetPPP.h
//
// 	Talk to pppconfd
//
//	Copyright (c) 2002-2014 Alex Harper
//
// 	This file is part of MenuMeters.
//
// 	MenuMeters is free software; you can redistribute it and/or modify
// 	it under the terms of the GNU General Public License version 2 as
//  published by the Free Software Foundation.
//
// 	MenuMeters is distributed in the hope that it will be useful,
// 	but WITHOUT ANY WARRANTY; without even the implied warranty of
// 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// 	GNU General Public License for more details.
//
// 	You should have received a copy of the GNU General Public License
// 	along with MenuMeters; if not, write to the Free Software
// 	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#import <Cocoa/Cocoa.h>
#import <sys/socket.h>
#import <sys/un.h>
#import <stdio.h>
#import <unistd.h>

// PPP state machine from Apple PPPLib
enum {
    PPP_IDLE = 0,
    PPP_INITIALIZE,
    PPP_CONNECTLINK,
    PPP_STATERESERVED,
    PPP_ESTABLISH,
    PPP_AUTHENTICATE,
    PPP_CALLBACK,
    PPP_NETWORK,
    PPP_RUNNING,
    PPP_TERMINATE,
    PPP_DISCONNECTLINK,
    PPP_HOLDOFF,
    PPP_ONHOLD,
    PPP_WAITONBUSY
};


@interface MenuMeterNetPPP : NSObject {

	int					pppconfdSocket;
	NSFileHandle		*pppconfdHandle;

} // MenuMeterNetPPP

// Singleton
+ (id)sharedPPP;

// PPP status
- (NSDictionary *)statusForInterfaceName:(NSString *)ifname;
- (NSDictionary *)statusForServiceID:(NSString *)serviceID;

// PPP control
- (void)connectServiceID:(NSString *)serviceID;
- (void)disconnectServiceID:(NSString *)serviceID;

@end
