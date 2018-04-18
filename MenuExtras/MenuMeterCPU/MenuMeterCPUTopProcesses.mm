//
//  MenuMeterCPUTopProcesses.mm
//
// 	Reader object for top CPU hogging process list
//
//  Copyright (c) 2018 Hofi
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

#import "MenuMeterCPUTopProcesses.h"
#import "MenuMeterCPU.h"
#include <sysexits.h>
#include <string>
#include <sstream>


///////////////////////////////////////////////////////////////
//
//    Process info item key strings
//
///////////////////////////////////////////////////////////////

NSString* const kProcessListItemPIDKey           = @"processID";
NSString* const kProcessListItemProcessNameKey   = @"processName";
NSString* const kProcessListItemProcessPathKey   = @"processPath";
NSString* const kProcessListItemUserIDKey        = @"userID";
NSString* const kProcessListItemUserNameKey      = @"userName";
NSString* const kProcessListItemCPUKey           = @"cpuPercent";

///////////////////////////////////////////////////////////////
//
//    Private categories
//
///////////////////////////////////////////////////////////////

@interface MenuMeterCPUTopProcesses ()

@property (atomic, retain) NSArray* processes;
@property (atomic, assign) BOOL shouldUpdate;

@end

///////////////////////////////////////////////////////////////
//
//	init/dealloc
//
///////////////////////////////////////////////////////////////

@implementation MenuMeterCPUTopProcesses

- (id)init {

	// Allow super to init
	self = [super init];
	if (!self) {
		return nil;
	}

    self.processes = [self updateRunningProcessesByCPUUsage];
    
	// Send on back
	return self;

} // init

- (void)dealloc {

} // dealloc

- (void)doUpdateProcessList {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^() {
        NSArray* processes = [self updateRunningProcessesByCPUUsage];
        
        @synchronized (self) {
            if (self.shouldUpdate) {
                self.processes = processes;

                [self performSelectorOnMainThread:@selector(doUpdateProcessList) withObject:nil waitUntilDone:NO];
            }
        }
    });
    
} // doUpdateProcessList

- (void)startUpdateProcessList {
    
    self.shouldUpdate = YES;
    
    [self doUpdateProcessList];
    
} // startUpdateProcessList

- (void)stopUpdateProcessList {
    
    self.shouldUpdate = NO;
    
} // stopUpdateProcessList

- (NSArray *)runningProcessesByCPUUsage:(NSUInteger)maxItem {
    
    @synchronized (self) {
        NSMutableArray* processes = [NSMutableArray arrayWithCapacity:maxItem];

        for (NSUInteger i = 0; i < maxItem; ++i)
            [processes addObject:[self.processes[i] copy]];
        
        return [NSArray arrayWithArray:processes];
    }
    
} // runningProcessesByCPUUsage:
    
///////////////////////////////////////////////////////////////
//
//    Process CPU info
//
//    Ways tried to get CPU usage / process
//          - sysctl
//              returning list of struct kinfo_proc, each of them has a member struct extern_proc kp_proc
//              kp_proc has 3 members that refers to cpu usage, but none of them is the one we need here
//          - kernel functions like it can be seen in source of top
//              works fine, but needs elevated priviledge
//          - can call ps or top from command line and parse the output
//              works fine even for user space apps, but
//                  - ps never displays kernel_task :/
//                  - ps has no max displayed process count param, provides always a full process list  :/
//                  - slow, top should be run with -l 2 params to get cpu samples and the shortest run time is one sec this way :/
//                  - top does not display full executable names or pathes
//
///////////////////////////////////////////////////////////////

- (NSArray *)updateRunningProcessesByCPUUsage {
    
    NSUInteger maxItem = kCPUrocessCountMax;
    NSArray* result = nil;
    NSMutableArray* processes = [NSMutableArray arrayWithCapacity:maxItem];
    NSString* output = nil;
    NSString* error = nil;
    NSTask* task = [NSTask new];
    
    task.launchPath = @"/bin/bash";
    // -c mode
    //    Set event counting mode to mode.  The supported modes are
    //
    //    a       Accumulative mode.  Count events cumulatively, starting at the launch of top.  Calculate CPU usage and CPU time since the launch of top.
    //
    //    d       Delta mode.  Count events relative to the previous sample.  Calculate CPU usage since the previous sample.  This mode by default disables
    //            the memory object map reporting.  The memory object map reporting may be re-enabled with the -r option or the interactive r command.
    //
    //    e       Absolute mode.  Count events using absolute counters.
    //
    //    n       Non-event mode (default).  Calculate CPU usage since the previous sample.
    //
    task.arguments = @[ @"-c", [NSString stringWithFormat:@"/usr/bin/top -s 0 -l 2 -c e -stats pid,cpu,time,mem,uid,user,command -o cpu -n %ld", maxItem] ];
    
    // Output of the task:
    //    Processes: 468 total, 4 running, 3 stuck, 461 sleeping, 2394 threads
    //    2017/10/08 22:54:53
    //    Load Avg: 2.36, 2.70, 2.69
    //    CPU usage: 4.62% user, 17.59% sys, 77.77% idle
    //    SharedLibs: 212M resident, 68M data, 43M linkedit.
    //    MemRegions: 249844 total, 6961M resident, 120M private, 2880M shared.
    //    PhysMem: 16G used (2297M wired), 171M unused.
    //    VM: 2091G vsize, 1092M framework vsize, 2534922(0) swapins, 2806330(0) swapouts.
    //    Swap: 770M + 1278M free.
    //    Purgeable: 339M 65236(0) pages purged.
    //    Networks: packets: 17698924/10G in, 19957766/14G out.
    //    Disks: 16239072/115G read, 10103470/102G written.
    //
    //    PID COMMAND     %CPU TIME     MEM    UID USER
    //    0   kernel_task 0.0  02:24:41 1578M+ 0   root
    //    Further process info lines repeated till the end of process list ...
    //
    // This above will be repeated once again
    //
    if ([self executeTask:task result1:&output result2:&error separateOutput:YES] == EX_OK && output.length) {
        std::istringstream input(output.UTF8String);
        std::string nextLine;
        
        // skip the not perfect result of first run process list (cpu% always 0)
        for (int i = 0; i < 2; ++i) {
            while (std::getline(input, nextLine)) {
                if (nextLine.find("PID") != std::string::npos && nextLine.find("COMMAND") != std::string::npos && nextLine.find("%CPU") != std::string::npos) {
                    break;
                }
            }
        }

        std::stringstream line;
        
        while (std::getline(input, nextLine)) {
            int dwUID = 0;
            unsigned int dwPID = 0;
            double fCpu = 0.0;
            char architecture = 0;
            std::string mem, time, user, cmd, stat;

            line = std::stringstream(nextLine);
            // scan the line
            line >> std::skipws >> dwPID >> std::noskipws >> architecture >> std::skipws >> fCpu >> time >> mem >> dwUID >> user;
            // scan remaining part, the (TODO: later full) command line
            std::getline(line, cmd);

            if (false == line.fail()) {
                NSString* commandStr = [self normalizedCommand:[NSString stringWithUTF8String:cmd.c_str()]];
                NSString* displayName = commandStr;//[self getAppDisplayNameForPath:commandStr];
                
                NSDictionary* entry = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithUnsignedInt:dwPID], kProcessListItemPIDKey,
                                       //commandStr, kProcessListItemProcessPathKey,
                                       displayName.length ? displayName : [commandStr lastPathComponent], kProcessListItemProcessNameKey,
                                       [NSNumber numberWithInt:dwUID], kProcessListItemUserIDKey,
                                       [NSString stringWithUTF8String:user.c_str()], kProcessListItemUserNameKey,
                                       [NSNumber numberWithDouble:fCpu], kProcessListItemCPUKey,
                                       nil];
                
                [processes addObject:entry];
            }
            else
                NSLog(@"MenuMeterCPU, error parsing executeShellCommand output: %s", nextLine.c_str());
        }
        
        result = [[processes sortedArrayUsingFunction:processesSortByCPUUsageComparator context:nil] subarrayWithRange:NSMakeRange(0, MIN(maxItem, processes.count))];
    }
    else
        NSLog(@"MenuMeterCPU, executeShellCommand returned none zero result: %@ (%@)", output, error);
    
    
    return result;
    
} // runningProcessesByCPUUsage:

///////////////////////////////////////////////////////////////
//
//	Utility
//
///////////////////////////////////////////////////////////////

- (NSBundle *)enclosingBundleForPath:(NSString *)path
{
    NSBundle* bundle = nil;
    NSArray* components = [path pathComponents];
    
    if (components.count > 2) {
        for (NSUInteger ndx = components.count - 1; ndx > 0; --ndx) {
            if ([components[ndx] isEqualToString:@"Contents"]) {
                NSArray* bundlePathElements = [components subarrayWithRange:NSMakeRange(0, ndx)];
                NSString* bundlePath = [NSString pathWithComponents:bundlePathElements];
                NSBundle* candidateBundle = nil;
                
                if ((candidateBundle = [NSBundle bundleWithPath:bundlePath]) != nil) {
                    if ([[[candidateBundle executablePath] lastPathComponent] isEqualToString:components.lastObject]) {
                        bundle = candidateBundle;
                        break;
                    }
                }
            }
        }
    }
    return bundle;
    
} // enclosingBundleForPath:

- (NSString *)getAppDisplayNameForPath:(NSString *)pathValue
{
    NSString* valueString = [pathValue lastPathComponent];
    NSBundle* bundle = [self enclosingBundleForPath:pathValue];
    
    if (bundle) {
        NSString* displayName = [[bundle localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
        
        if (displayName.length)
        valueString = displayName;
        else {
            displayName = [[bundle infoDictionary] objectForKey:@"CFBundleDisplayName"];
            if (displayName.length)
            valueString = displayName;
        }
    }
    return valueString;
    
} // getAppDisplayNameForPath:

- (NSString *)normalizedCommand:(NSString *)name
{
    NSString* result = name;

    // remove leading/trailing whitespaces
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // remove login shell prefixes
    for (int i = 0; i < 2; ++i) {
        if (name.length > 0) {
            result = [result stringByReplacingOccurrencesOfString:@"-" withString:@"" options:0 range:NSMakeRange(0, 1)];
        }
    }
    
    // continue other clean up here
    
    return result;
    
} // normalizedCommand:

NSInteger processesSortByCPUUsageComparator(id proc1, id proc2, void *context) {
    
    double v1 = [proc1[kProcessListItemCPUKey] doubleValue];
    double v2 = [proc2[kProcessListItemCPUKey] doubleValue];
    
    if (v1 > v2)
        return NSOrderedAscending;
    else if (v1 < v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
    
} // processesSortByCPUUsageComparator:

- (int)executeTask:(NSTask*)task result1:(NSString**)result1 result2:(NSString**)result2 separateOutput:(BOOL)separateOutput
{
    NSData* resultData1 = (result1 ? [NSData data] : nil);
    NSData* resultData2 = (result2 ? [NSData data] : nil);;
    int terminationStatus = [self executeTask:task resultData1:&resultData1 resultData2:&resultData2 separateOutput:separateOutput];
    
    NSString* output1 = nil;
    NSString* output2 = nil;
    if (resultData1)
        output1 = [[NSString alloc] initWithData:resultData1 encoding:NSUTF8StringEncoding];
    if (resultData2)
        output2 = [[NSString alloc] initWithData:resultData2 encoding:NSUTF8StringEncoding];
    
    if (result1)
        *result1 = output1;
    if (result2)
        *result2 = output2;
    
    return terminationStatus;
    
} // executeTask:result1:result2:separateOutput:

- (int) executeTask:(NSTask*)task
        resultData1:(NSData**)resultData1
        resultData2:(NSData**)resultData2
     separateOutput:(BOOL)separateOutput
{
    NSPipe* pipe1 = [NSPipe pipe];
    NSPipe* pipe2 = [NSPipe pipe];
    NSFileHandle* fileHandle1 = [pipe1 fileHandleForReading];
    NSFileHandle* fileHandle2 = [pipe2 fileHandleForReading];
    NSData* data1 = nil;
    NSData* data2 = nil;
    int terminationStatus = -1;
    
    task.standardOutput = pipe1;
    task.standardError = (separateOutput ? pipe2 : pipe1);
    
    @try {
        [task launch]; // Raises an NSInvalidArgumentException if the launch path has not been set or is invalid or if it fails to create a process.
        
        // NOTE: Synchronously reads the available data up to the end of file or maximum number of bytes.
        //       This method invokes readDataOfLength: as part of its implementation.
        //       The data available through the receiver up to maximum size that can be represented by an NSData object or,
        //       if a communications channel, until an end-of-file indicator is returned.
        //
        //       The size of the NSData data is subject to a theoretical limit of about 8 exabytes (1 EB = 10¹⁸ bytes; in practice,
        //       the limit should not be a factor).
        data1 = [fileHandle1 readDataToEndOfFile];
        if (separateOutput)
            data2 = [fileHandle2 readDataToEndOfFile];
        
        [task waitUntilExit];
        terminationStatus = [task terminationStatus];
    }
    @catch (NSException* exception) {
        NSLog(@"MenuMeterCPU, executeTask exception during NSTask launch: %s", exception.description.UTF8String);
        //output = exception.description;
    }
    
    //if (resultData1 == nil)
    //    NSLog(@"MenuMeterCPU, executeTask std Output:\n%@", data1 ? [[[NSString alloc] initWithData:data1 encoding:NSUTF8StringEncoding] ah_autorelease] : @"");
    //if (resultData2 == nil)
    //    NSLog(@"MenuMeterCPU, executeTask std Error:\n%@", data2 ? [[[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding] ah_autorelease] : @"");
    //if (resultData1 == nil || resultData2 == nil)
    //    NSLog(@"MenuMeterCPU, executeTask termination status: %d", [task terminationStatus]);
    
    if (resultData1)
        *resultData1 = data1;
    if (resultData2)
        *resultData2 = data2;
    
    return terminationStatus;
    
} // executeTask:resultData1:resultData2:separateOutput:

@end
