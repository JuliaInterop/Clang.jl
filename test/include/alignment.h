#include <stdint.h>
#include <stddef.h>

enum UA_NodeIdType {
    UA_NODEIDTYPE_NUMERIC    = 0, /* In the binary encoding, this can also
                                   * become 1 or 2 (two-byte and four-byte
                                   * encoding of small numeric nodeids) */
    UA_NODEIDTYPE_STRING     = 3,
    UA_NODEIDTYPE_GUID       = 4,
    UA_NODEIDTYPE_BYTESTRING = 5
};

typedef struct {
    uint32_t data1;
    uint16_t data2;
    uint16_t data3;
    uint8_t data4[8];
} UA_Guid;

typedef struct {
    size_t length;
    uint8_t *data;
} UA_String;

typedef struct {
    uint16_t namespaceIndex;
    enum UA_NodeIdType identifierType;
    union {
        uint32_t     numeric;
        UA_String     string;
        UA_Guid       guid;
        UA_String byteString;
    } identifier;
} UA_NodeId;

typedef struct {
    UA_String locale;
    UA_String text;
} UA_LocalizedText;

typedef struct {
    UA_String name;
    UA_LocalizedText description;
    uint16_t fieldFlags;
    uint8_t builtInType;
    UA_NodeId dataType;
    int32_t valueRank;
    size_t arrayDimensionsSize;
    void *arrayDimensions;
    uint32_t maxStringLength;
    UA_Guid dataSetFieldId;
    size_t propertiesSize;
    void *properties;
} UA_FieldMetaData;