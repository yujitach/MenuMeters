#ifndef smc_reader_h
#define smc_reader_h

#include <IOKit/IOKitLib.h>

#define IO_SERVICE_NAME       "AppleSMC"

#define KERNEL_INDEX_SMC      2

#define SMC_CMD_READ_BYTES    5
#define SMC_CMD_WRITE_BYTES   6
#define SMC_CMD_READ_INDEX    8
#define SMC_CMD_READ_KEYINFO  9
#define SMC_CMD_READ_PLIMIT   11
#define SMC_CMD_READ_VERS     12

#define toSMCCode(str)            (SMCCode){{str[3], str[2], str[1], str[0]}}

#define SMC_DATATYPE_FPE2         toSMCCode("fpe2")
#define SMC_DATATYPE_FDS          toSMCCode("{fds")
#define SMC_DATATYPE_UINT8        toSMCCode("ui8 ")
#define SMC_DATATYPE_UINT16       toSMCCode("ui16")
#define SMC_DATATYPE_UINT32       toSMCCode("ui32")
#define SMC_DATATYPE_SP78         toSMCCode("sp78")
#define SMC_DATATYPE_FLAG         toSMCCode("flag")
#define SMC_DATATYPE_HEX          toSMCCode("hex_")
#define SMC_DATATYPE_FLT          toSMCCode("flt ")
#define SMC_DATATYPE_CH8          toSMCCode("ch8*")
#define SMC_DATATYPE_MSS          toSMCCode("{mss")
#define SMC_DATATYPE_SI8          toSMCCode("si8 ")
#define SMC_DATATYPE_FP6A         toSMCCode("fp6a")
#define SMC_DATATYPE_FP88         toSMCCode("fp88")
#define SMC_DATATYPE_JST          toSMCCode("{jst")
#define SMC_DATATYPE_FP1F         toSMCCode("fp1f")
#define SMC_DATATYPE_SI16         toSMCCode("si16")
#define SMC_DATATYPE_ALP          toSMCCode("{alp")
#define SMC_DATATYPE_ALC          toSMCCode("{alc")
#define SMC_DATATYPE_ALI          toSMCCode("{ali")
#define SMC_DATATYPE_ALV          toSMCCode("{alv")

#define UI32_TO_UINT32(bytes)     (bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3])
#define UI16_TO_UINT32(bytes)     (bytes[0] << 8 | bytes[1])
#define UI8_TO_UINT32(bytes)      (bytes[0])
#define SP78_TO_CELSIUS(bytes)    (UI16_TO_UINT32(bytes) / 256.0F)
#define FPE2_TO_UINT32(bytes)     ((bytes[0] << 6) + (bytes[1] >> 2))
#define FLAG_TO_UINT32(bytes)     (bytes[0])

typedef union {
    UInt8               code[4];
    UInt32              type;
} SMCCode;

typedef struct {
    UInt8                 major;
    UInt8                 minor;
    UInt8                 build;
    SInt8                 reserved[1];
    UInt16                release;
} SMCKeyDataVersion;

typedef struct {
    UInt16                version;
    UInt16                length;
    UInt32                cpuPLimit;
    UInt32                gpuPLimit;
    UInt32                memPLimit;
} SMCKeyDataPLimitData;

typedef struct {
    UInt32                dataSize;
    SMCCode               dataType;
    UInt8                 dataAttributes;
} SMCKeyDataKeyInfo;

typedef UInt8             SMCBytes[32];

#define SMC_CALL_RESULT_SUCCESS 0
#define SMC_CALL_RESULT_ERROR 1
#define SMC_CALL_RESULT_NOT_FOUND 0x84

typedef struct {
    SMCCode                 key;
    SMCKeyDataVersion       vers;
    SMCKeyDataPLimitData    pLimitData;
    SMCKeyDataKeyInfo       keyInfo;
    UInt8                   result;
    UInt8                   status;
    UInt8                   data8;
    UInt32                  data32;
    SMCBytes                bytes;
} SMCKeyData;

typedef struct {
    SMCCode                 key;
    SMCKeyDataKeyInfo       info;
    SMCBytes                bytes;
} SMCKeyValue;

kern_return_t SMCOpen(void);
kern_return_t SMCClose(void);

kern_return_t SMCCall(int index, SMCKeyData *inputStructure, SMCKeyData *outputStructure);
kern_return_t SMCReadKey(SMCCode key, SMCKeyValue *val);
kern_return_t SMCReadKeysCount(UInt32 *count);
kern_return_t SMCReadKeyAtIndex(UInt32 index, SMCKeyValue *val);

#endif /* smc_reader_h */
