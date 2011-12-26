    //
    //  VariableValue.m
    //  iHaxGamez
    //
    //  Created by Xiliang Chen on 11-12-18.
    //  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
    //

#import "VariableValue.h"

@implementation VariableValue

@synthesize type = _type, size = _size, maxSize = _maxSize, eightTimes = _eightTimes;

- (id)initWithStringValue:(NSString *)stringValue isTextType:(BOOL)textType {
    self = [super init];
    if (self) {
        
        _data[0] = NULL;
        _data[1] = NULL;
        
        static NSNumberFormatter *formatter = nil;
        if (!formatter)
            formatter = [[NSNumberFormatter alloc] init];
        if (!textType && [formatter numberFromString:stringValue]) {
            NSRange range = [stringValue rangeOfString:@"."];
            if (range.location == NSNotFound) {
                    // it is very unlikely user will search anything larger than signed long long max
                    // so this is the maximum interget value can be handled
                long long llValue = [stringValue longLongValue];
                _maxSize = sizeof(int64_t);
                _data[1] = malloc(_maxSize);
                memset(_data[1], 0, _maxSize);
                
                range = [stringValue rangeOfString:@"-"];
                if (range.location == NSNotFound) {
                        // assume it is unsigned for now
                        // unsigned can change to signed later but signed (negative) can never be unsigned
                    _type = VariableTypeUnsignedInteger;
                    
                        // prepare unsigned data
                    _data[0] = malloc(_maxSize);
                    memset(_data[0], 0, _maxSize);
                    if (llValue <= UINT8_MAX) {
                        _size = sizeof(uint8_t);
                        *(uint8_t *)_data[0] = (uint8_t)llValue;
                    } else if (llValue <= UINT16_MAX) {
                        _size = sizeof(uint16_t);
                        *(uint16_t *)_data[0] = (uint16_t)llValue;
                    } else if (llValue <= UINT32_MAX) {
                        _size = sizeof(uint32_t);
                        *(uint32_t *)_data[0] = (uint32_t)llValue;
                    } else {
                        _size = sizeof(uint64_t);
                        *(uint64_t *)_data[0] = (uint64_t)llValue;
                    }
                    _dataSize[0] = _size;
                    
                        // prepare signed data
                    if (llValue <= INT8_MAX) {
                        _dataSize[1] = sizeof(int8_t);
                        _data[1] = malloc(_dataSize[1]);
                        *(int8_t *)_data[1] = (int8_t)llValue;
                    } else if (llValue <= INT16_MAX) {
                        _dataSize[1] = sizeof(int16_t);
                        _data[1] = malloc(_dataSize[1]);
                        *(int16_t *)_data[1] = (int16_t)llValue;
                    } else if (llValue <= INT32_MAX) {
                        _dataSize[1] = sizeof(int32_t);
                        _data[1] = malloc(_dataSize[1]);
                        *(int32_t *)_data[1] = (int32_t)llValue;
                    } else {
                        _dataSize[1] = sizeof(int64_t);
                        _data[1] = malloc(_dataSize[1]);
                        *(int64_t *)_data[1] = (int64_t)llValue;
                    }
                    
                } else {    // negative value
                    _type = VariableTypeInteger;
                    
                    if (llValue >= INT8_MIN) {
                        _size = sizeof(int8_t);
                        _data[1] = malloc(_size);
                        *(int8_t *)_data[1] = (int8_t)llValue;
                    } else if (llValue >= INT16_MIN) {
                        _size = sizeof(int16_t);
                        _data[1] = malloc(_size);
                        *(int16_t *)_data[1] = (int16_t)llValue;
                    } else if (llValue >= INT32_MIN) {
                        _size = sizeof(int32_t);
                        _data[1] = malloc(_size);
                        *(int32_t *)_data[1] = (int32_t)llValue;
                    } else {
                        _size = sizeof(int64_t);
                        _data[1] = malloc(_size);
                        *(int64_t *)_data[1] = (int64_t)llValue;
                    }
                    _dataSize[1] = _size;
                }
                
                _data[2] = malloc(sizeof(float));
                *(float *)_data[2] = (float)llValue;
                _data[3] = malloc(sizeof(double));
                *(double *)_data[3] = (double)llValue;
                
            } else {
                double dValue = [stringValue doubleValue];
                _type = VariableTypeFloat;
                _size = sizeof(float);
                _maxSize = sizeof(double);
                
                _data[2] = malloc(_size);
                *(float *)_data[2] = (float)dValue;
                
                _data[3] = malloc(_maxSize);
                *(double *)_data[3] = dValue;
            }
            
        } else {
            if ([stringValue canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                _type = VariableTypeASCII;
                _size = [stringValue length] * sizeof(char);
                _maxSize = [stringValue length] * sizeof(unichar);
                
                _dataSize[0] = _size;
                size_t size = _size + sizeof(char);
                _data[0] = malloc(size);
                MASSERT_SOFT([stringValue getCString:_data[0] maxLength:size encoding:NSASCIIStringEncoding]);
            } else {
                _type = VariableTypeUnicode;
                _maxSize = _size = [stringValue length] * sizeof(unichar);
            }
            _dataSize[1] = _maxSize;
            size_t size = _maxSize + sizeof(unichar);
            _data[1] = malloc(size);
            MASSERT_SOFT([stringValue getCString:_data[1] maxLength:size encoding:NSUnicodeStringEncoding]);
        }
        if (VariableTypeIsNumeric(_type)) {
            MASSERT(_data[2] != NULL, @"float value not initilized");
            MASSERT(_data[3] != NULL, @"double value not initilized");
        }
    }
    return self;
}

- (id)initWithValue:(VariableValue *)value type:(VariableType)type {
    self = [super init];
    if (self) {
        _eightTimes = value->_eightTimes;
        _type = type;
        if (value.type != type) {
            switch (type) {
                case VariableTypeInteger:
                case VariableTypeUnicode:
                    _size = value->_dataSize[1];
                    break;
                case VariableTypeFloat:
                    _size = sizeof(float);
                    break;
                case VariableTypeDouble:
                    _size = sizeof(double);
                    break;
                default:
                    _size = value.size;
                    break;
            } 
        } else {
            _size = value.size;
        }
        _maxSize = value.maxSize;
        
        for (int i = 0; i < 2; i++)
            if (value->_data[i]) {
                _dataSize[i] = value->_dataSize[i];
                _data[i] = malloc(_dataSize[i]);
                memcpy(_data[i], value->_data[i], _dataSize[i]);
            }
        if (value->_data[2]) {
            _data[2] = malloc(sizeof(float));
            *(float *)_data[2] = *(float *)value->_data[2];
        }
        if (value->_data[3]) {
            _data[3] = malloc(sizeof(double));
            *(double *)_data[3] = *(double *)value->_data[3];
        }
        if (VariableTypeIsNumeric(_type)) {
            MASSERT(_data[2] != NULL, @"float value not initilized");
            MASSERT(_data[3] != NULL, @"double value not initilized");
        }
    }
    return self;
}

- (id)initWithData:(void *)data size:(size_t)size type:(VariableType)type {
    return [self initWithData:data size:size maxSize:size type:type];
}
- (id)initWithData:(void *)data size:(size_t)size maxSize:(size_t)maxSize type:(VariableType)type {
    MASSERT(maxSize >= size, @"max size (%lu) less than size (%lu)", maxSize, size);
    self = [super init];
    if (self) {
        _eightTimes = NO;
        _type = type;
        _size = size;
        _maxSize = maxSize;
        _data[0] = malloc(maxSize);
        memcpy(_data[0], data, maxSize);
        _data[1] = malloc(maxSize);
        memcpy(_data[1], data, maxSize);
        _dataSize[0] = _dataSize[1] = maxSize;
        if (VariableTypeIsNumeric(type)) {
            _data[2] = malloc(sizeof(float));
            memcpy(_data[2], data, sizeof(float));
            _data[3] = malloc(sizeof(double));
            memcpy(_data[3], data, sizeof(double));
        }
    }
    return self;
}

- (VariableValue *)eightTimesValue {
    if (_eightTimes)
        return self;
    VariableValue *value;
    switch (_type) {
        case VariableTypeUnsignedInteger:
        case VariableTypeInteger:
        {
            long long llValue = 0;
            memcpy(&llValue, _data[1], _dataSize[1]);
            llValue *= 8;
            value = [[VariableValue alloc] initWithData:&llValue size:sizeof(llValue) type:_type];
            break;
        }
        case VariableTypeFloat:
        {
            float fValue = *(float *)_data[2];
            fValue *= 8;
            value = [[VariableValue alloc] initWithData:&fValue size:sizeof(fValue) type:_type];
            break;
        }
        case VariableTypeDouble:
        {
            float dValue = *(double *)_data[3];
            dValue *= 8;
            value = [[VariableValue alloc] initWithData:&dValue size:sizeof(dValue) type:_type];
            break;
        }
        case VariableTypeASCII:
        case VariableTypeUnicode:
            return self;
    }
    value->_eightTimes = YES;
    return value;
}

- (void)dealloc {
    free(_data[0]);
    free(_data[1]);
    free(_data[2]);
    free(_data[3]);
}

#pragma mark -

- (void *)data {
    switch (_type) {
        case VariableTypeUnsignedInteger:
            MASSERT(_data[0], @"return a nil data");
            return _data[0];
        case VariableTypeInteger:
            MASSERT(_data[1], @"return a nil data");
            return _data[1];
        case VariableTypeFloat:
            MASSERT(_data[2], @"return a nil data");
            return _data[2];
        case VariableTypeDouble:
            MASSERT(_data[3], @"return a nil data");
            return _data[3];
        case VariableTypeASCII:
            MASSERT(_data[0], @"return a nil data");
            return _data[0];
        case VariableTypeUnicode:
            MASSERT(_data[1], @"return a nil data");
            return _data[1];
    }
}

#pragma mark -

- (BOOL)compareAtAddress:(void *)address minSize:(size_t)minSize maxSize:(size_t)maxSize matchedType:(VariableType *)matchedType {
    if (maxSize < _size || minSize > _maxSize)
        return NO;
    switch (_type) {
        case VariableTypeUnsignedInteger:
        case VariableTypeInteger:
            for (int i = 0; i < 2; i++) {
                size_t compareSize = MAX(minSize, _dataSize[i]);
                if (compareSize > maxSize)
                    continue;
                if (memcmp(_data[i], address, compareSize) == 0) {
                    if (matchedType)
                        *matchedType = i == 0 ? VariableTypeUnsignedInteger : VariableTypeInteger;
                    return YES;
                }
            }
                // continue to float checking
            
        case VariableTypeFloat:
            if (maxSize < sizeof(float))
                return NO;
            float fValue = *(float *)address;
            if (!isnan(fValue) && fabsf(fValue - *(float *)_data[2]) < 0.001) {
                if (matchedType)
                    *matchedType = VariableTypeFloat;
                return YES;
            }
            
                // continue to double checking
            
        case VariableTypeDouble:
            if (maxSize < sizeof(double))
                return NO;
            double dValue = *(double *)address;
            if (!isnan(dValue) && fabs(dValue - *(double *)_data[3]) < 0.001) {
                if (matchedType)
                    *matchedType = VariableTypeDouble;
                return YES;
            }
            return NO;
            
        case VariableTypeASCII:
        case VariableTypeUnicode:
            
            for (int i = 0; i < 2; i++) {
                if (_data[i]) {
                    if (memcmp(_data[i], address, _dataSize[i]) == 0) {
                        if (matchedType)
                            *matchedType = i == 0 ? VariableTypeASCII : VariableTypeUnicode;
                        return YES;
                    }
                }
            }
            return NO;
    }
    
    
    return NO;
}

@end