#define ENCODE(var) [coder encodeValueOfObjCType: @encode(typeof(var)) at: &(var)];
#define DECODE(var) [coder decodeValueOfObjCType: @encode(typeof(var)) at: &(var)];
