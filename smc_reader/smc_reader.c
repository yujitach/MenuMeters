#include <stdio.h>
#include "smc_reader.h"

static io_connect_t conn;

kern_return_t SMCOpen()
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

kern_return_t SMCClose()
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
    SMCKeyData  inputStructure = {0, 0};
    SMCKeyData  outputStructure = {0, 0};

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
    SMCKeyValue val = {0, 0};
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
    SMCKeyData  inputStructure = {0, 0};
    SMCKeyData  outputStructure = {0, 0};

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

