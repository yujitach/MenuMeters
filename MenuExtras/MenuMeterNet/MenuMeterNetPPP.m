//
//  MenuMeterNetPPP.m
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

#import "MenuMeterNetPPP.h"


///////////////////////////////////////////////////////////////
//
//	PPP interface from Apple PPPLib
//
///////////////////////////////////////////////////////////////

// PPP local socket path
#define kPPPSocketPath	 	"/var/run/pppconfd\0"

// Typedef for PPP messages, from Apple PPPLib
struct ppp_msg_hdr {
    u_int16_t 		m_flags; 	// special flags
    u_int16_t 		m_type; 	// type of the message
    u_int32_t 		m_result; 	// error code of notification message
    u_int32_t 		m_cookie;	// user param
    u_int32_t 		m_link;		// link for this message
    u_int32_t 		m_len;		// len of the following data
};

// PPP command codes, also from Apple PPPLib
enum {
    PPP_VERSION = 1,
    PPP_STATUS,
    PPP_CONNECT,
    PPP_DISCONNECT = 5,
    PPP_GETOPTION,
    PPP_SETOPTION,
    PPP_ENABLE_EVENT,
    PPP_DISABLE_EVENT,
    PPP_EVENT,
    PPP_GETNBLINKS,
    PPP_GETLINKBYINDEX,
    PPP_GETLINKBYSERVICEID,
    PPP_GETLINKBYIFNAME,
    PPP_SUSPEND,
    PPP_RESUME
};

// And the PPP status struct
struct ppp_status {
    // connection stats
    u_int32_t 		status;
    union {
        struct connected {
            u_int32_t 		timeElapsed;
            u_int32_t 		timeRemaining;
            // bytes stats
            u_int32_t 		inBytes;
            u_int32_t 		inPackets;
            u_int32_t 		inErrors;
            u_int32_t 		outBytes;
            u_int32_t 		outPackets;
            u_int32_t 		outErrors;
        } run;
        struct disconnected {
            u_int32_t 		lastDiscCause;
        } disc;
        struct waitonbusy {
            u_int32_t 		timeRemaining;
        } busy;
    } s;
};

///////////////////////////////////////////////////////////////
//
//	Private methods
//
///////////////////////////////////////////////////////////////

@interface MenuMeterNetPPP (PrivateMethods)

- (uint32_t)pppconfdLinkCount;
- (NSData *)pppconfdExecMessage:(NSData *)message;

@end

///////////////////////////////////////////////////////////////
//
//	Singleton
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterNetPPP

static id gSharedPPP = nil;

+ (id)sharedPPP {

	// Do we have one?
	if (gSharedPPP != nil) {
		return gSharedPPP;
	}

	// Create it
	gSharedPPP = [[MenuMeterNetPPP alloc] init];
	return gSharedPPP;

} // sharedPPP

///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

- (id)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	// Establish or connection to the PPP socket
	pppconfdSocket = socket(AF_LOCAL, SOCK_STREAM, 0);
	struct sockaddr_un socketaddr = { 0, AF_LOCAL, kPPPSocketPath };
	if (connect(pppconfdSocket, (struct sockaddr *)&socketaddr, (socklen_t)sizeof(socketaddr))) {
		NSLog(@"MenuMeterNetPPP unable to establish socket for pppconfd. Abort.");
		[self release];
		return nil;
	}

	// Create the filehandle
	pppconfdHandle = [[NSFileHandle alloc] initWithFileDescriptor:pppconfdSocket];
	if (!pppconfdHandle) {
		NSLog(@"MenuMeterNetPPP unable to establish file handle for pppconfd. Abort.");
		[self release];
		return nil;
	}

	// Send on back
	return self;

} // init

- (void)dealloc {

	[pppconfdHandle release];
	close(pppconfdSocket);
	[super dealloc];

} // dealloc

///////////////////////////////////////////////////////////////
//
//	PPP status
//
///////////////////////////////////////////////////////////////

- (NSDictionary *)statusForInterfaceName:(NSString *)ifname {

	// Name in UTF-8
	NSData *ifnameData = [ifname dataUsingEncoding:NSUTF8StringEncoding];
#ifdef __LP64__
	if ([ifnameData length] > UINT_MAX) return nil;
#endif

	// Get the link id for the interface
	struct ppp_msg_hdr idMsg = { 0, PPP_GETLINKBYIFNAME, 0, 0, -1, (u_int32_t)[ifnameData length] };
	NSMutableData *idMsgData = [NSMutableData dataWithBytes:&idMsg length:sizeof(idMsg)];
	[idMsgData appendData:ifnameData];
	NSData *idReply = [self pppconfdExecMessage:idMsgData];
	uint32_t linkID = 0;
	if ([idReply length] != sizeof(uint32_t)) return nil;
	[idReply getBytes:&linkID];

	// Now get status of that link
	struct ppp_msg_hdr statusMsg = { 0, PPP_STATUS, 0, 0, linkID, 0 };
	NSData *statusReply = [self pppconfdExecMessage:[NSData dataWithBytes:&statusMsg length:sizeof(statusMsg)]];
	if ([statusReply length] != sizeof(struct ppp_status)) return nil;
	struct ppp_status *pppStatus = (struct ppp_status *)[statusReply bytes];
	if (pppStatus->status == PPP_RUNNING) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithUnsignedInt:pppStatus->status],
					@"status",
					[NSNumber numberWithUnsignedInt:pppStatus->s.run.inBytes],
					@"inBytes",
					[NSNumber numberWithUnsignedInt:pppStatus->s.run.outBytes],
					@"outBytes",
					[NSNumber numberWithUnsignedInt:pppStatus->s.run.timeElapsed],
					@"timeElapsed",
					[NSNumber numberWithUnsignedInt:pppStatus->s.run.timeRemaining],
					@"timeRemaining",
					nil];
	} else {
		return [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithUnsignedInt:pppStatus->status],
					@"status",
					nil];
	}

} // statusForInterfaceName

- (NSDictionary *)statusForServiceID:(NSString *)serviceID; {

	// Service in UTF-8
	NSData *serviceIDData = [serviceID dataUsingEncoding:NSUTF8StringEncoding];
#ifdef __LP64__
	if ([serviceIDData length] > UINT_MAX) return nil;
#endif

	// We get the link id for the service
	struct ppp_msg_hdr idMsg = { 0, PPP_GETLINKBYSERVICEID, 0, 0, -1, (u_int32_t)[serviceIDData length] };
	NSMutableData *idMsgData = [NSMutableData dataWithBytes:&idMsg length:sizeof(idMsg)];
	[idMsgData appendData:serviceIDData];
	NSData *idReply = [self pppconfdExecMessage:idMsgData];
	uint32_t linkID = 0;
	if ([idReply length] != sizeof(uint32_t)) return nil;
	[idReply getBytes:&linkID];

	// Now get status of that link
	struct ppp_msg_hdr statusMsg = { 0, PPP_STATUS, 0, 0, linkID, 0 };
	NSData *statusReply = [self pppconfdExecMessage:[NSData dataWithBytes:&statusMsg length:sizeof(statusMsg)]];
	if ([statusReply length] != sizeof(struct ppp_status)) return nil;
	struct ppp_status *pppStatus = (struct ppp_status *)[statusReply bytes];
	if (pppStatus->status == PPP_RUNNING) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInt:pppStatus->status],
				@"status",
				[NSNumber numberWithUnsignedInt:pppStatus->s.run.inBytes],
				@"inBytes",
				[NSNumber numberWithUnsignedInt:pppStatus->s.run.outBytes],
				@"outBytes",
				[NSNumber numberWithUnsignedInt:pppStatus->s.run.timeElapsed],
				@"timeElapsed",
				[NSNumber numberWithUnsignedInt:pppStatus->s.run.timeRemaining],
				@"timeRemaining",
				nil];
	} else {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInt:pppStatus->status],
				@"status",
				nil];
	}

} // statusForServiceID

///////////////////////////////////////////////////////////////
//
//	PPP control
//
///////////////////////////////////////////////////////////////

- (void)connectServiceID:(NSString *)serviceID {

	// Service in UTF-8
	NSData *serviceIDData = [serviceID dataUsingEncoding:NSUTF8StringEncoding];
#ifdef __LP64__
	if ([serviceIDData length] > UINT_MAX) return;
#endif

	// We get the link id for the service
	struct ppp_msg_hdr idMsg = { 0, PPP_GETLINKBYSERVICEID, 0, 0, -1, (u_int32_t)[serviceIDData length] };
	NSMutableData *idMsgData = [NSMutableData dataWithBytes:&idMsg length:sizeof(idMsg)];
	[idMsgData appendData:serviceIDData];
	NSData *idReply = [self pppconfdExecMessage:idMsgData];
	uint32_t linkID = 0;
	if ([idReply length] != sizeof(uint32_t)) return;
	[idReply getBytes:&linkID];

	// Connect the link
	struct ppp_msg_hdr connectMsg = { 0, PPP_CONNECT, 0, 0, linkID, 0 };
	[self pppconfdExecMessage:[NSData dataWithBytes:&connectMsg length:sizeof(connectMsg)]];

} // connectServiceID

- (void)disconnectServiceID:(NSString *)serviceID {

	// Service in UTF-8
	NSData *serviceIDData = [serviceID dataUsingEncoding:NSUTF8StringEncoding];
#ifdef __LP64__
	if ([serviceIDData length] > UINT_MAX) return;
#endif

	// We get the link id for the service
	struct ppp_msg_hdr idMsg = { 0, PPP_GETLINKBYSERVICEID, 0, 0, -1, (u_int32_t)[serviceIDData length] };
	NSMutableData *idMsgData = [NSMutableData dataWithBytes:&idMsg length:sizeof(idMsg)];
	[idMsgData appendData:serviceIDData];
	NSData *idReply = [self pppconfdExecMessage:idMsgData];
	uint32_t linkID = 0;
	if ([idReply length] != sizeof(uint32_t)) return;
	[idReply getBytes:&linkID];

	// Disconnect the link
	struct ppp_msg_hdr disconnectMsg = { 0, PPP_DISCONNECT, 0, 0, linkID, 0 };
	[self pppconfdExecMessage:[NSData dataWithBytes:&disconnectMsg length:sizeof(disconnectMsg)]];

} // disconnectServiceID

///////////////////////////////////////////////////////////////
//
//	Private Methods
//
///////////////////////////////////////////////////////////////

- (uint32_t)pppconfdLinkCount {

	// Message block and reply
	struct ppp_msg_hdr numlinkmsg = { 0, PPP_GETNBLINKS, 0, 0, -1, 0 };
	NSData *reply = [self pppconfdExecMessage:[NSData dataWithBytes:&numlinkmsg length:sizeof(numlinkmsg)]];
	// Size the reply
	if ([reply length] == sizeof(uint32_t)) {
		uint32_t retVal = 0;
		[reply getBytes:&retVal];
		return retVal;
	}
	// Fallthrough
	return 0;

} // pppconfdLinkCount

- (NSData *)pppconfdExecMessage:(NSData *)message {

	// Write the data
	[pppconfdHandle writeData:message];
	// Read back the reply headers
	NSData *header = [pppconfdHandle readDataOfLength:sizeof(struct ppp_msg_hdr)];
	if ([header length]) {
		struct ppp_msg_hdr *header_message = (struct ppp_msg_hdr *)[header bytes];
		if (header_message && header_message->m_len) {
			NSData *reply = [pppconfdHandle readDataOfLength:header_message->m_len];
			if ([reply length] && !header_message->m_result) {
				return reply;
			}
		}
	}

	// Get here we got nothing
	return nil;

} // pppconfdExecMessage

@end
