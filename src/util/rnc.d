//
// RNC decompression
//
// in/out buffers should have 8 redundant "safe bytes" at end.
//
// By Jon Skeet, 14 Oct 1997 - 22 Jul 2008
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//

module util.rnc;

import std.stdio;


// RNC error codes
public enum ErrorCode : int {
    FILE_IS_NOT_RNC = -1,
    HUF_DECODE_ERROR = -2,
    FILE_SIZE_MISMATCH =-3,
    PACKED_CRC_ERROR = -4,
    UNPACKED_CRC_ERROR = -5,
    HEADER_VAL_ERROR = -6,
    HUF_EXCEEDS_RANGE = -7
}

// RNC signature
private immutable int SIGNATURE_INT = 0x524E4301;

// Limit of the compressed & decompressed file sizes
private immutable int MAX_FILESIZE = 1 << 30;

// Length of the RNC file header, in bytes
private immutable int SIZEOF_RNC_HEADER = 18;


// Holds between 16 and 32 bits from packed buffer.
// It can be used to read up to 16 bits from input buffer.
// The buffer pointer is not in the struct, and it is increased
// to always pouint at start of the byte which wasn't read yet.
private struct bit_stream {
    uint bitbuf;
    uint bitcount;
}

private struct table_set {
    uint code;
    uint codelen;
    uint value;
}

// Huffman code table, used for decompression.
private struct huf_table {
    uint num;
    table_set[32] table;
}


// Reads 4-byte big-endian number from given buffer.
private int read_int32_be_buf(const ubyte* buff) {
    int l;

    l =  buff[3];
    l += buff[2] << 8;
    l += buff[1] << 16;
    l += buff[0] << 24;

    return l;
}

// Reads 2-byte big-endian number from given buffer.
private ushort read_int16_be_buf(const ubyte* buff) {
    int l;

    l = buff[1];
    l += buff[0] << 8;

    return cast(ushort)l;
}

// Reads 2-byte little-endian number from given buffer.
private ushort read_int16_le_buf(const ubyte* buff) {
    int l;

    l = buff[0];
    l += buff[1] << 8;

    return cast(ushort)l;
}

// Reads 1-byte number from given buffer.
private ubyte read_int8_buf (const ubyte* buff) {
    return buff[0];
}

// Return the uncompressed length of a packed data block.
// The packed buffer must be shorter than SIZEOF_RNC_HEADER.
public int get_length(const void *packed) {
    ubyte* p = cast(ubyte*)packed;

    if (read_int32_be_buf(p) != SIGNATURE_INT) {
		return ErrorCode.FILE_IS_NOT_RNC;
    }

    return read_int32_be_buf(p + 4);
}

// Decompress a packed data block
public int unpack(const void *packed, const void *unpacked) {
    ubyte* input = cast(ubyte*)packed;
    ubyte* output = cast(ubyte*)unpacked;
    ubyte* inputend;
    ubyte* outputend;
    uint ch_count;
    uint ret_len;
    uint inp_len;
	bit_stream bs;
    huf_table raw;
    huf_table dist;
    huf_table len;
    uint out_crc;

    // Read header
    if (read_int32_be_buf(input) != SIGNATURE_INT) {
       	return ErrorCode.HEADER_VAL_ERROR;
    }

    ret_len = read_int32_be_buf(input + 4);
    inp_len = read_int32_be_buf(input + 8);
    if ((ret_len > (MAX_FILESIZE)) || (inp_len > (MAX_FILESIZE))) {
        return ErrorCode.HEADER_VAL_ERROR;
    }

    // Set variables
    outputend = output + ret_len;
    inputend = input + SIZEOF_RNC_HEADER + inp_len;

    // Skip header
    input += SIZEOF_RNC_HEADER;

    // Check the packed-data CRC. Also save the unpacked-data CRC for later.
    if (calculate_crc(input, inputend - input) != read_int16_be_buf(input - 4)) {
    	return ErrorCode.PACKED_CRC_ERROR;
    }

    out_crc = read_int16_be_buf(input - 6);
    bitread_init(&bs, &input, inputend);

    // Discard first 2 bits
    bit_advance(&bs, 2, &input, inputend);

    // Process chunks
	while (output < outputend) {
		if (inputend - input < 6) {
			return ErrorCode.HUF_EXCEEDS_RANGE;
        }

		read_huftable(&raw,  &bs, &input, inputend);
		read_huftable(&dist, &bs, &input, inputend);
		read_huftable(&len,  &bs, &input, inputend);
		ch_count = bit_read(&bs, 0xFFFF, 16, &input, inputend);

		while (1) {
			int length, posn;

			length = huf_read(&raw, &bs, &input,inputend);
			if (length < 0) {
                return ErrorCode.HUF_DECODE_ERROR;
            }

			if (length) {
				while (length--) {
					if ((input >= inputend) || (output >= outputend))
						return ErrorCode.HUF_EXCEEDS_RANGE;

					*output++ = *input++;
				}
				bitread_fix(&bs, &input, inputend);
			}

			if (--ch_count <= 0) {
				break;
            }

			posn = huf_read(&dist, &bs, &input, inputend);
			if (posn == -1) {
				return ErrorCode.HUF_DECODE_ERROR;
            }

			length = huf_read(&len, &bs, &input,inputend);
			if (length < 0) {
				return ErrorCode.HUF_DECODE_ERROR;
            }

			posn += 1;
			length += 2;
			while (length--) {
				if (((cast(void*)output - posn) < unpacked) ||
                    ((output - posn) > outputend) ||
                    ((cast(void*)output) < unpacked) ||
                    ((output) > outputend)) {
					    return ErrorCode.HUF_EXCEEDS_RANGE;
                }

				output[0] = output[-posn];
				output++;
			}
		}
	}

    if (outputend != output) {
		return ErrorCode.FILE_SIZE_MISMATCH;
    }

    // Check the unpacked-data CRC
    if (calculate_crc(outputend - ret_len, ret_len) != out_crc) {
		return ErrorCode.UNPACKED_CRC_ERROR;
    }

    return ret_len;
}

// Read a Huffman table out of the bit stream and data stream given.
private static void read_huftable(huf_table* h, bit_stream* bs, ubyte** p, const ubyte* pend) {
    uint i, j, k, num;
    uint[32] leaflen;
    uint leafmax;

	// big-endian form of code
    uint codeb;


    num = bit_read(bs, 0x1F, 5, p, pend);
    if (!num) {
        return;
    }

    leafmax = 1;
    for (i = 0; i < num; i++) {
        leaflen[i] = bit_read (bs, 0x0F, 4, p, pend);
        if (leafmax < leaflen[i]) {
	        leafmax = leaflen[i];
        }
    }

    codeb = 0L;
    k = 0;
    for (i = 1; i <= leafmax; i++) {
		for (j = 0; j < num; j++) {
			if (leaflen[j] == i) {
				h.table[k].code = mirror(codeb, i);
				h.table[k].codelen = i;
				h.table[k].value = j;
				codeb++;
				k++;
			}
		}
		codeb <<= 1;
    }

    h.num = k;
}

// Read a value out of the bit stream using the given Huffman table.
private static uint huf_read(const huf_table* h, bit_stream* bs, ubyte** p, const ubyte* pend) {
    uint i;
    uint val;

    for (i = 0; i < h.num; i++) {
        uint mask = (1 << h.table[i].codelen) - 1;
        if (bit_peek(bs, mask) == h.table[i].code)
	        break;
    }

    if (i == h.num) {
        return -1;
    }
    bit_advance(bs, h.table[i].codelen, p, pend);

    val = h.table[i].value;
    if (val >= 2) {
	    val = 1 << (val - 1);
        val |= bit_read(bs, val - 1, h.table[i].value - 1, p, pend);
    }

    return val;
}

// Initialises a bit stream with the first two bytes of the packed data.
// Checks pend for proper buffer pointers range. The pend should point
// to the last readable byte in buffer.
// If buffer is exceeded, fills output (or part of output) with zeros.
private void bitread_init(bit_stream* bs, const ubyte** p, const ubyte* pend) {
    if (pend - (*p) >= 1) {
        bs.bitbuf = cast(uint)read_int16_le_buf(*p);
        bs.bitcount = 16;
    }
    else if (pend - (*p) >= 0) {
        bs.bitbuf = cast(uint)read_int8_buf(*p);
        bs.bitcount = 8;
    } else {
        bs.bitbuf = 0;
    }
}


// Fixes up a bit stream after literals have been read out of the
// data stream. Checks pend for proper buffer pointers range. The pend
// should pouint to the last readable byte in buffer.
private void bitread_fix (bit_stream* bs, const ubyte** p, const ubyte* pend) {
    bs.bitcount -= 16;
    if (bs.bitcount < 0) {
        bs.bitcount = 0;
    }

    // remove the top 16 bits
    bs.bitbuf &= (1 << bs.bitcount) - 1;

    // replace with what's at *p, or zeroes if nothing more to read
    if (pend - (*p) >= 1) {
        bs.bitbuf |= (read_int16_le_buf(*p) << bs.bitcount);
        bs.bitcount += 16;
    } else if (pend - (*p) >= 0) {
        bs.bitbuf |= (read_int8_buf(*p) << bs.bitcount);
        bs.bitcount += 8;
    }
}

// Returns some bits, masked with given bit mask.
private uint bit_peek (const bit_stream *bs, const uint mask) {
    return bs.bitbuf & mask;
}

// Advances the bit stream. Reads n bits from the bit_stream, then makes sure
// there are still at least 16 bits to read in next operation.
// The new bits are taken from buffer *p.
// Checks pend for proper buffer pointers range. The pend should point
// to the last readable byte in buffer.
private void bit_advance (bit_stream* bs, const uint n, ubyte** p, const ubyte* pend) {
	bs.bitbuf >>= n;
    bs.bitcount -= n;

    if (bs.bitcount < 16) {
        (*p) += 2;
        if (pend - (*p) >= 1) {
            bs.bitbuf |= (cast(uint)read_int16_le_buf(*p) << bs.bitcount);
            bs.bitcount += 16;
        } else if (pend - (*p) >= 0) {
            bs.bitbuf |= (cast(uint)read_int8_buf(*p) << bs.bitcount);
            bs.bitcount += 8;
        } else if (bs.bitcount < 0) {
            bs.bitcount = 0;
        }
    }
}

// Reads some bits and advances the bit stream.
// Works like the bit_peek and bit_advance routines combined.
private static uint bit_read (bit_stream* bs, const uint mask, const uint n, ubyte** p, const ubyte* pend) {
    uint result = bit_peek(bs, mask);
	bit_advance(bs, n, p, pend);

    return result;
}

// Mirror the bottom n bits of x.
private static uint mirror(uint x, const uint n) {
    uint top = 1 << (n - 1);
	uint bottom = 1;

    while (top > bottom) {
        uint mask = top | bottom;
        uint masked = x & mask;

        if (masked != 0 && masked != mask)
            x ^= mask;

        top >>= 1;
        bottom <<= 1;
    }

    return x;
}

// Calculate a CRC, the RNC way.
public int calculate_crc(const void *data, uint len) {
    ushort[256] crctab;
    short crctab_ready = 0;
    ushort val;
    uint i;
    uint j;
    ubyte* p = cast(ubyte*)data;

    // Compute CRC table
    if (crctab_ready == false) {
		for (i = 0; i < 256; i++) {
			val = cast(ushort)i;

			for (j = 0; j < 8; j++) {
				if (val & 1) {
					val = (val >> 1) ^ 0xA001;
                } else {
					val = (val >> 1);
                }
			}
			crctab[i] = val;
		}
		crctab_ready = 1;
    }

    val = 0;
    while (len--) {
	    val ^= *p++;
	    val = (val >> 8) ^ crctab[val & 0xFF];
    }

    return val;
}