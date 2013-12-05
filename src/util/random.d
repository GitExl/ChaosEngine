module util.random;

// Table of random values as used by the game. See ACHAOS 0x26C6.
static private ubyte[] RANDOM_DATA = [
    0xDF, 0x0A, 0xD2, 0xB8, 0x15, 0x9B, 0x60, 0xF6, 0xAD, 0x46, 0xE7, 0x5B, 0x85, 0xC1, 0x8C, 0x9B, 0x4E, 0xD2, 0x40, 0x24,
    0xC9, 0xDB, 0x48, 0x47, 0x1F, 0xCC, 0xD6, 0x44, 0x35, 0xF2, 0x4F, 0x83, 0xA5, 0x50, 0xEA, 0x74, 0xBD, 0x63, 0x40, 0x47,
    0x0E, 0xAB, 0x72, 0x3B, 0x5A, 0x2B, 0x0B, 0x6C, 0xEF, 0xB7, 0x4D, 0x08, 0xAA, 0x64, 0x1D, 0x03, 0x41, 0x89, 0x95, 0x3D, 
    0xA5, 0xC4, 0xD2, 0x2C, 0xFC, 0x51, 0x9A, 0xD7, 0xE3, 0x75, 0xB1, 0x4D, 0xFD, 0x95, 0x25, 0x74, 0x33, 0x4F, 0x04, 0xA6, 
    0x55, 0xF6, 0x96, 0x19, 0x5E, 0xEF, 0x9A, 0x12, 0x58, 0xD4, 0x59, 0x5B, 0x68, 0x86, 0xDD, 0xC6, 0x47, 0x1B, 0xC5, 0xC1, 
    0x0C, 0x9A, 0x4C, 0xCD, 0x33, 0x00, 0x66, 0xCC, 0x64, 0x60, 0x88, 0xD0, 0xB1, 0x03, 0x69, 0xD9, 0x85, 0xBD, 0x85, 0x84, 
    0x13, 0x2E, 0x83, 0x62, 0xCA, 0x59, 0x47, 0x41, 0x11, 0xA4, 0x6A, 0x1D, 0x0F, 0x58, 0xCE, 0x4C, 0x34, 0x00, 0x69, 0xD2, 
    0x77, 0x93, 0x15, 0x51, 0xCD, 0x3D, 0x15, 0xA4, 0x73, 0x2F, 0x45, 0xE8, 0x5B, 0x86, 0xC3, 0x92, 0xAA, 0x79, 0x46, 0x7F, 
    0x8A, 0x13, 0x3B, 0x9D, 0xB0, 0x9A, 0x95, 0x5F, 0xE8, 0x8E, 0xED, 0xF6, 0xC6, 0x78, 0x7C, 0xE9, 0xCA, 0x66, 0x61, 0x8E, 
    0xDE, 0xD9, 0x6F, 0x91, 0x01, 0x24, 0x4A, 0xDC, 0x4C, 0x51, 0x3B, 0x18, 0xA7, 0x7F, 0x4C, 0x96, 0xC5, 0xB7, 0xF8, 0x5E, 
    0xAC, 0x15, 0x83, 0x30, 0x66, 0x2D, 0x26, 0xA6, 0x98, 0x7D, 0x2B, 0x50, 0xF6, 0x8C, 0x05, 0x22, 0x4F, 0xE3, 0x65, 0x91, 
    0xED, 0xFD, 0xD4, 0xA3, 0xEF, 0x25, 0x28, 0x9A, 0x85, 0x3E, 0x86, 0x89, 0x1E, 0x4F, 0xDB, 0x55, 0x61, 0x6D, 0x9D, 0x15, 
    0x65, 0xF4, 0xB3, 0x4E, 0x03, 0xA3, 0x4D, 0xE1, 0x5D, 0x7C, 0xB3, 0x5E, 0x22, 0x01, 0x46, 0x8F, 0xAA, 0x72, 0x38, 0x54, 
    0x19, 0xDA, 0xE7, 0x82, 0xD3, 0xAB, 0xFD, 0x50, 0x9B, 0xD6, 0xE2, 0x71, 0xA7, 0x31, 0xB1, 0xC5, 0xEC, 0x63, 0x9E, 0x03, 
    0x43, 0x8D, 0xA0, 0x5B, 0xF6, 0xA3, 0x32, 0xAB, 0xBA, 0xCB, 0x0B, 0xAD, 0x70, 0x3B, 0x56, 0x23, 0xF2, 0x2B, 0x3A, 0xCA, 
    0x09, 0xA6, 0x5E, 0x09, 0xCE, 0xAE, 0xF8, 0x4D, 0x8A, 0xAF, 0x72, 0x42, 0x69, 0x56, 0x7E, 0xA9, 0x4E, 0xEE, 0x79, 0xCE, 
    0x8E, 0xB8, 0x8D, 0x8A, 0x2F, 0x73, 0x44, 0x6F, 0x67, 0xAD, 0x28, 0xAA, 0xA4, 0x9C, 0x81, 0x3B, 0x79, 0x68, 0xC2, 0x54, 
    0x2C, 0x01, 0x5B, 0xB8, 0x26, 0xBD, 0xC6, 0x06, 0x99, 0x3E, 0xAE, 0xD8, 0x0C, 0xC9, 0xAB, 0xE9, 0x28, 0x23, 0x96, 0x73, 
    0x12, 0x0A, 0x39, 0x86, 0x7F, 0x0A, 0x12, 0x39, 0x96, 0x9F, 0x6A, 0x13, 0xFB, 0x1D, 0x30, 0x9B, 0x96, 0x62, 0xF1, 0xA7, 
    0x31, 0xB0, 0xC3, 0xE7, 0x54, 0x76, 0x95, 0x16, 0x57, 0xDA, 0x63, 0x7A, 0xBB, 0x6B, 0x4C, 0x6E, 0x74, 0xC5, 0x72, 0x6E, 
    0xC1, 0x5E, 0x3F, 0x3B, 0xF4, 0x5F, 0xA7, 0x0C, 0x67, 0xE6, 0x9B, 0x02, 0x3A, 0x78, 0x65, 0xBA, 0x3F, 0xF2, 0x62, 0xA8, 
    0x15, 0x7B, 0x21, 0x39, 0xB5, 0xDC, 0x23, 0xFF, 0x45, 0x88, 0x9A, 0x44, 0xBC, 0x00, 0x79, 0xF2, 0xD7, 0x93, 0xD5, 0xD1, 
    0x4D, 0x3D, 0x14, 0xA2, 0x6C, 0x1C, 0x10, 0x58, 0xD1, 0x52, 0x47, 0x32, 0xF2, 0x49, 0x76, 0x7F, 0xEA, 0xD3, 0x7B, 0x9D, 
    0x31, 0x9D, 0x9C, 0x72, 0x1C, 0x1C, 0x71, 0x1A, 0x16, 0x61, 0xEE, 0x9E, 0x18, 0x6D, 0x0A, 0xEE, 0xF1, 0xBE, 0x5E, 0x38, 
    0x2D, 0xCA, 0xEE, 0x71, 0xBE, 0x5F, 0x3B, 0x35, 0xE0, 0x2A, 0x14, 0x7D, 0x22, 0x3E, 0xC1, 0xFE, 0x7F, 0xFA, 0xF2, 0xD9, 
    0x97, 0xE1, 0xF1, 0xA5, 0x2D, 0xA4, 0xA3, 0x8E, 0x63, 0xE2, 0x8B, 0xDB
];

static private ushort randomIndex;

public ubyte getRandomUByte() {
    return RANDOM_DATA[(randomIndex += 1) & 0x1FF];
}

public ushort getRandomUShort() {
    return (RANDOM_DATA[(randomIndex += 1) & 0x1FF] + (RANDOM_DATA[(randomIndex += 1) & 0x1FF] << 8));
}

public uint getRandomUInt() {
    return (RANDOM_DATA[(randomIndex += 1) & 0x1FF] + (RANDOM_DATA[(randomIndex += 1) & 0x1FF] << 8) + (RANDOM_DATA[(randomIndex += 1) & 0x1FF] << 16) + (RANDOM_DATA[(randomIndex += 1) & 0x1FF] << 24));
}