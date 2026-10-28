//
//  smc_reader.m
//  MenuMeters
//
//  Based on the Apple System Management Control (SMC) Tool, as also found
//  in smcFanControl and osx-cpu-temp, whose notice follows.
//  SMCHumanReadableDescriptions() below is modified from VirtualSMC; its
//  license is given there.
//
//  Apple System Management Control (SMC) Tool
//  Copyright (C) 2006 devnull
//  Portions Copyright (C) 2013 Michael Wilber
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
//  Changed 2026-10-27 by Joe Moreno: SMCOpen and SMCClose declared with
//  (void), so the project builds with Xcode 27.
//

#include <stdio.h>
#include "smc_reader.h"

static io_connect_t conn;

kern_return_t SMCOpen(void)
{
    kern_return_t result;
    io_iterator_t iterator;
    io_object_t   device;

    result = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(IO_SERVICE_NAME), &iterator);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceGetMatchingServices() = %08x\n", result);
        return result;
    }

    device = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (!device)
    {
        printf("Error: no SMC found\n");
        return kIOReturnNoDevice;
    }

    result = IOServiceOpen(device, mach_task_self(), 0, &conn);
    IOObjectRelease(device);
    if (result != kIOReturnSuccess)
    {
        printf("Error: IOServiceOpen() = %08x\n", result);
        return result;
    }

    return kIOReturnSuccess;
}

kern_return_t SMCClose(void)
{
    return IOServiceClose(conn);
}


kern_return_t SMCCall(int index, SMCKeyData *inputStructure, SMCKeyData *outputStructure)
{
    size_t   structureInputSize;
    size_t   structureOutputSize;

    structureInputSize = sizeof(SMCKeyData);
    structureOutputSize = sizeof(SMCKeyData);

    return IOConnectCallStructMethod(conn, index,
                                     inputStructure, structureInputSize,
                                     outputStructure, &structureOutputSize);
}

kern_return_t SMCReadKey(SMCCode key, SMCKeyValue *val)
{
    kern_return_t result;
    SMCKeyData  inputStructure = {};
    SMCKeyData  outputStructure = {};

    inputStructure.key = key;
    inputStructure.data8 = SMC_CMD_READ_KEYINFO;

    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    if (outputStructure.result != SMC_CALL_RESULT_SUCCESS)
    {
        return kIOReturnError;
    }

    val->info = outputStructure.keyInfo;

    inputStructure.keyInfo.dataSize = val->info.dataSize;
    inputStructure.data8 = SMC_CMD_READ_BYTES;

    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess)
    {
        return result;
    }
    if (outputStructure.result != SMC_CALL_RESULT_SUCCESS)
    {
        return kIOReturnError;
    }

    memcpy(val->key.code, key.code, sizeof(val->key.code));
    memcpy(val->bytes, outputStructure.bytes, sizeof(outputStructure.bytes));

    return kIOReturnSuccess;
}

kern_return_t SMCReadKeysCount(UInt32 *count)
{
    kern_return_t result;
    SMCKeyValue val = {};
    result = SMCReadKey(toSMCCode("#KEY"), &val);
    if (result == kIOReturnSuccess && val.info.dataType.type == SMC_DATATYPE_UINT32.type)
    {
        *count = UI32_TO_UINT32(val.bytes);
    }
    return result;
}

kern_return_t SMCReadKeyAtIndex(UInt32 index, SMCKeyValue *val)
{
    kern_return_t result;
    SMCKeyData  inputStructure = {};
    SMCKeyData  outputStructure = {};

    inputStructure.data32 = index;
    inputStructure.data8 = SMC_CMD_READ_INDEX;

    result = SMCCall(KERNEL_INDEX_SMC, &inputStructure, &outputStructure);
    if (result != kIOReturnSuccess)
    {
        return result;
    }

    if (outputStructure.result != SMC_CALL_RESULT_SUCCESS)
    {
        return kIOReturnError;
    }

    return SMCReadKey(outputStructure.key, val);
}

// modified from smc_dump_lib_keys
// in https://github.com/acidanthera/VirtualSMC/blob/master/Tools/smcread/smcread.c
// whose license is BSD 3-Clause "New" or "Revised" License
// https://github.com/acidanthera/VirtualSMC/blob/master/LICENSE.txt
//
// Copyright (c) 2017, vit9696
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include <dlfcn.h>

struct PlatformKeyDescriptions {
    char key[4];
    uint8_t index;
    char description[256];
    uint8_t len;
    uint16_t pad1;
    char type[4];
    uint32_t pad2; /* added in 10.13.4 */
} __attribute__((packed));

struct PlatformStructLookup {
    char branch[16];
    struct PlatformKeyDescriptions *descr[2];
    uint32_t descrn[2];
    uint32_t pad[2];
};

NSDictionary* SMCHumanReadableDescriptions(void) {
    void *smc_lib = dlopen("/usr/lib/libSMC.dylib", RTLD_LAZY);

    if (smc_lib) {
        struct PlatformStructLookup *lookup_arr = (struct PlatformStructLookup *)dlsym(smc_lib, "AccumulatorPlatformStructLookupArray");

/*        if (!lookup_arr) {
            // This library is normally in dyld shared cache, so we have to use DYLD_SHARED_REGION=avoid envvar.
            // As a more convenient workaround we currently compile with an overlapping segment.
            NSLog(@"Unable to solve AccumulatorPlatformStructLookupArray symbol, trying to brute-force...\n");

            uint8_t *start = (uint8_t *)dlsym(smc_lib, "SMCReadKey");
            uint8_t *ptr = start;
            char first[16] = "m87";
            while (ptr && memcmp(ptr, first, sizeof(first)) != 0) {
                //printf("%08X: %02X\n", ptr-start, ptr[0]);
                ptr++;
            }

            lookup_arr = (struct PlatformStructLookup *)ptr;
        } */
        NSMutableDictionary*dict=[NSMutableDictionary dictionary];
        if (lookup_arr) {
            bool stop = false;
            while (lookup_arr->branch[0] != '\0' && isascii(lookup_arr->branch[0]) && !stop) {
//                printf("Dumping keys for %.4s...\n", lookup_arr->branch);

                for (uint32_t i = 0; i < 2 && !stop; i++) {
  //                  printf(" Set %u has %u keys:\n", i, lookup_arr->descrn[i]);
                    for (uint32_t j = 0; j < lookup_arr->descrn[i]; j++) {
                        struct PlatformKeyDescriptions *key = &lookup_arr->descr[i][j];
                        if (key->pad1 != 0 || key->pad2 != 0) {
                            stop = true;
                            break;
                        }
                        /*
                        printf(" [%c%c%c%c] type [%c%c%c%c] %02X%02X%02X%02X len [%2u] idx [%3u]: %.256s\n",
                               key->key[3] == '\0' ? ' ' : key->key[3], key->key[2] == '\0' ? ' ' : key->key[2],
                               key->key[1] == '\0' ? ' ' : key->key[1], key->key[0] == '\0' ? ' ' : key->key[0],
                               key->type[3], key->type[2], key->type[1], key->type[0] == '\0' ? '?' : key->type[3],
                               key->type[3], key->type[2], key->type[1], key->type[0],
                               key->len, key->index, key->description);
                         */
                        char s[5]={key->key[3],key->key[2],key->key[1],key->key[0],0};
                        NSString*smcKey=[NSString stringWithUTF8String:s];
                        NSString*desc=[NSString stringWithUTF8String:key->description];
                        dict[smcKey]=desc;
                    }
                }

                lookup_arr++;
            }

            dlclose(smc_lib);
            return dict;
        } else {
            NSLog(@"Unable to locate lookup array in libSMC.dylib!");
            dlclose(smc_lib);
        }
    } else {
        NSLog(@"Unable to open libSMC.dylib!");
    }

    return nil;
}
