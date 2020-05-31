#include "../spec_match.hpp"
#include "ImpalaKernels.hpp"


#define  SUBSEG_MATCH_NOTEX(j) \
    unsigned char s_char[37] = {0};\
    pos = t_id + j * THREAD_BLOCK_SIZE;\
    if (pos < bdy - 37 + 1){\
        _Pragma("unroll")\
        for(int i = 0; i < 37; i++){\
            s_char[i] = s_char_i[pos + i];\
        }\
        if ((s_char[0] == 0x14)\
                              & (s_char[1] == 'f')\
                              & (s_char[2] == 't')\
                              & (s_char[3] == 'y')\
                              & (s_char[4] == 'p')\
                              & (s_char[5] == 'i')\
                              & (s_char[6] == 's')\
                              & (s_char[7] == 'o')\
                              & (s_char[8] == 'm')){\
                              match = 1;}\
        if ((s_char[0] == 0x18)\
                              & (s_char[1] == 'f')\
                              & (s_char[2] == 't')\
                              & (s_char[3] == 'y')\
                              & (s_char[4] == 'p')\
                              & (s_char[5] == '3')\
                              & (s_char[6] == 'g')\
                              & (s_char[7] == 'p')\
                              & (s_char[8] == '5')){\
                              match = 2;}\
        if ((s_char[0] == 0x1a)\
                               & (s_char[1] == 'E')\
                               & (s_char[2] == 0xdf)\
                               & (s_char[3] == 0xa3)\
                               & (s_char[4] == 0x93)\
                               & (s_char[5] == 'B')\
                               & (s_char[6] == 0x82)\
                               & (s_char[7] == 0x88)\
                               & (s_char[8] == 'm')\
                               & (s_char[9] == 'a')\
                               & (s_char[10] == 't')\
                               & (s_char[11] == 'r')\
                               & (s_char[12] == 'o')\
                               & (s_char[13] == 's')\
                               & (s_char[14] == 'k')\
                               & (s_char[15] == 'a')){\
                               match = 3;}\
        if ((s_char[0] == 0x1f)\
                              & (s_char[1] == 0x8b)\
                              & (s_char[2] == 0x08)){\
                              match = 4;}\
        if ((s_char[0] == '%')\
                              & (s_char[1] == 'P')\
                              & (s_char[2] == 'D')\
                              & (s_char[3] == 'F')){\
                              match = 5;}\
        if ((s_char[0] == 0x37)\
                              & (s_char[1] == 0x7a)\
                              & (s_char[2] == 0xbc)\
                              & (s_char[3] == 0xaf)\
                              & (s_char[4] == 0x27)\
                              & (s_char[5] == 0x1c)){\
                              match = 6;}\
        if ((s_char[0] == '8')\
                              & (s_char[1] == 'B')\
                              & (s_char[2] == 'P')\
                              & (s_char[3] == 'S')){\
                              match = 7;}\
        if ((s_char[0] == '<')\
                              & (s_char[1] == '!')\
                              & (s_char[2] == 'd')\
                              & (s_char[3] == 'o')\
                              & (s_char[4] == 'c')\
                              & (s_char[5] == 't')\
                              & (s_char[6] == 'y')\
                              & (s_char[7] == 'p')){\
                              match = 8;}\
        if ((s_char[0] == 'C')\
                              & (s_char[1] == 'W')\
                              & (s_char[2] == 'S')){\
                              match = 9;}\
        if ((s_char[0] == 'F')\
                              & (s_char[1] == 'W')\
                              & (s_char[2] == 'S')){\
                              match = 10;}\
        if ((s_char[0] == 'G')\
                              & (s_char[1] == 'I')\
                              & (s_char[2 ] == 'F')\
                              & (s_char[3] == '8')\
                              & (s_char[4] == '7')\
                              & (s_char[5] == 'a')){\
                              match = 11;}\
        if ((s_char[0] == 'G')\
                              & (s_char[1] == 'I')\
                              & (s_char[2] == 'F')\
                              & (s_char[3] == '8')\
                              & (s_char[4] == '9')\
                              & (s_char[5] == 'a')){\
                              match = 12;}\
        if ((s_char[0] == 'I')\
                              & (s_char[1] == ' ')\
                              & (s_char[2] == 'I')){\
                              match = 13;}\
        if ((s_char[0] == 'I')\
                              & (s_char[1] == 'D')\
                              & (s_char[2] == '3')){\
                              match = 14;}\
        if ((s_char[0] == 'M')\
                              & (s_char[1] == 'Z')){\
                              match = 15;}\
        if ((s_char[0] == 'M')\
                               & (s_char[1] == 'i')\
                               & (s_char[2] == 'c')\
                               & (s_char[3] == 'r')\
                               & (s_char[4] == 'o')\
                               & (s_char[5] == 's')\
                               & (s_char[6] == 'o')\
                               & (s_char[7] == 'f')\
                               & (s_char[8] == 't')\
                               & (s_char[9] == ' ')\
                               & (s_char[10] == 'V')\
                               & (s_char[11] == 'i')\
                               & (s_char[12] == 's')\
                               & (s_char[13] == 'u')\
                               & (s_char[14] == 'a')\
                               & (s_char[15] == 'l')\
                               & (s_char[16] == ' ')\
                               & (s_char[17] == 'S')\
                               & (s_char[18] == 't')\
                               & (s_char[19] == 'u')\
                               & (s_char[20] == 'd')\
                               & (s_char[21] == 'i')\
                               & (s_char[22] == 'o')\
                               & (s_char[23] == ' ')\
                               & (s_char[24] == 'S')\
                               & (s_char[25] == 'o')\
                               & (s_char[26] == 'l')\
                               & (s_char[27] == 'u')\
                               & (s_char[28] == 't')\
                               & (s_char[29] == 'i')\
                               & (s_char[30] == 'o')\
                               & (s_char[31] == 'n')\
                               & (s_char[32] == ' ')\
                               & (s_char[33] == 'F')\
                               & (s_char[34] == 'i')\
                               & (s_char[35] == 'l')\
                               & (s_char[36] == 'e')){\
                               match = 16;}\
        if ((s_char[0] == 'O')\
                               & (s_char[1] == 'P')\
                               & (s_char[2] == 'L')\
                               & (s_char[3] == 'D')\
                               & (s_char[4] == 'a')\
                               & (s_char[5] == 't')\
                               & (s_char[6] == 'a')\
                               & (s_char[7] == 'b')\
                               & (s_char[8] == 'a')\
                               & (s_char[9] == 's')\
                               & (s_char[10] == 'e')\
                               & (s_char[11] == 'F')\
                               & (s_char[12] == 'i')\
                               & (s_char[13] == 'l')\
                               & (s_char[14] == 'e')){\
                               match = 17;}\
        if ((s_char[0] == 'P')\
                              & (s_char[1] == 'A')\
                              & (s_char[2] == 'G')\
                              & (s_char[3]  == 'E')\
                              & (s_char[4] == 'D')\
                              & (s_char[5] == 'U')\
                              & (s_char[6] == '6')\
                              & (s_char[7] == '4')){\
                              match = 18;}\
        if ((s_char[0] == 'P')\
                              & (s_char[1] == 'K')\
                              & (s_char[2] == 0x03)\
                              & (s_char[3] == 0x04)){\
                              match = 19;}\
        if ((s_char[0] == 'P')\
                              & (s_char[1] == 'K')\
                              & (s_char[2] == 0x05)\
                              & (s_char[3] == 0x06)\
                              & (s_char[4] == 'P')\
                              & (s_char[5] == 'K')\
                              & (s_char[6] == 0x07)\
                              & (s_char[7] == 0x08)){\
                              match = 20;}\
        if ((s_char[0] == 'R')\
                               & (s_char[1] == 'e')\
                               & (s_char[2] == 't')\
                               & (s_char[3] == 'u')\
                               & (s_char[4] == 'r')\
                               & (s_char[5] == 'n')\
                               & (s_char[6] == '-')\
                               & (s_char[7] == 'P')\
                               & (s_char[8] == 'a')\
                               & (s_char[9] == 't')\
                               & (s_char[10] == 'h')\
                               & (s_char[11] == ':')\
                               & (s_char[12] == ' ')){\
                               match = 21;}\
        if ((s_char[0] == '[')\
                               & (s_char[1] == 'W')\
                               & (s_char[2] == 'i')\
                               & (s_char[3] == 'n')\
                               & (s_char[4] == 'd')\
                               & (s_char[5] == 'o')\
                               & (s_char[6] == 'w')\
                               & (s_char[7] == 's')\
                               & (s_char[8] == ' ')\
                               & (s_char[9] == 'L')\
                               & (s_char[10] == 'a')\
                               & (s_char[11] == 't')\
                               & (s_char[12] == 'i')\
                               & (s_char[13] == 'n')\
                               & (s_char[14] == ' ')){\
                               match = 22;}\
        if ((s_char[0] == 'f')\
                        & (s_char[1] == 't')\
                        & (s_char[2] == 'y')\
                        & (s_char[3] == 'p')\
                        & (s_char[4] == 'M')\
                        & (s_char[5] == 'S')\
                        & (s_char[6] == 'N')\
                        & (s_char[7] == 'V')){\
                        match = 23;}\
        if ((s_char[0] == 0x7c)\
                               & (s_char[1] == 0x4b)\
                               & (s_char[2] == 0xc3)\
                               & (s_char[3] == 0x74)\
                               & (s_char[4] == 0xe1)\
                               & (s_char[5] == 0xc8)\
                               & (s_char[6] == 0x53)\
                               & (s_char[7] == 0xa4)\
                               & (s_char[8] == 0x79)\
                               & (s_char[9] == 0xb9)\
                               & (s_char[10] == 0x01)\
                               & (s_char[11] == 0x1d)\
                               & (s_char[12] == 0xfc)\
                               & (s_char[13] == 0x4f)\
                               & (s_char[14] == 0xdd)\
                               & (s_char[15] == 0x13)){\
                               match = 24;}\
        if ((s_char[0] == 0x7e)\
                               & (s_char[1] == 'E')\
                               & (s_char[2] == 'S')\
                               & (s_char[3] == 'D')\
                               & (s_char[4] == 'w')\
                               & (s_char[5] == 0xf6)\
                               & (s_char[6] == 0x85)\
                               & (s_char[7] == '>')\
                               & (s_char[8] == 0xbf)\
                               & (s_char[9] == 'j')\
                               & (s_char[10] == 0xd2)\
                               & (s_char[11] == 0x11)\
                               & (s_char[12] == 'E')\
                               & (s_char[13] == 'a')\
                               & (s_char[14] == 's')\
                               & (s_char[15] == 'y')\
                               & (s_char[16] == ' ')\
                               & (s_char[17] == 'S')\
                               & (s_char[18] == 't')\
                               & (s_char[19] == 'r')\
                               & (s_char[20] == 'e')\
                               & (s_char[21] == 'e')\
                               & (s_char[22] == 't')\
                               & (s_char[23] == ' ')\
                               & (s_char[24] == 'D')\
                               & (s_char[25] == 'r')\
                               & (s_char[26] == 'a')\
                               & (s_char[27] == 'w')){\
                               match = 25;}\
        if ((s_char[0] == 0xbe)\
                               & (s_char[1] == 0xba)\
                               & (s_char[2] == 0xfe)\
                               & (s_char[3] == 0xca)\
                               & (s_char[4] == 0x0f)\
                               & (s_char[5] == 'P')\
                               & (s_char[6] == 'a')\
                               & (s_char[7] == 'l')\
                               & (s_char[8] == 'm')\
                               & (s_char[9] == 'S')\
                               & (s_char[10] == 'G')\
                               & (s_char[11] == ' ')\
                               & (s_char[12] == 'D')\
                               & (s_char[13] == 'a')\
                               & (s_char[14] == 't')\
                               & (s_char[15] == 'a')){\
                               match = 26;}\
        if ((s_char[0] == 0xd0)\
                              & (s_char[1] == 0xcf)\
                              & (s_char[2] == 0x11)\
                              & (s_char[3] == 0xe0)\
                              & (s_char[4] == 0xa1)\
                              & (s_char[5] == 0xb1)\
                              & (s_char[6] == 0x1a)\
                              & (s_char[7] == 0xe1)){\
                              match = 27;}\
    }else if (pos < bdy){\
        if ((pos < bdy - 9 + 1) & (s_char_i[pos + 0] == 0x14)\
                              & (s_char_i[pos + 1] == 'f')\
                              & (s_char_i[pos + 2] == 't')\
                              & (s_char_i[pos + 3] == 'y')\
                              & (s_char_i[pos + 4] == 'p')\
                              & (s_char_i[pos + 5] == 'i')\
                              & (s_char_i[pos + 6] == 's')\
                              & (s_char_i[pos + 7] == 'o')\
                              & (s_char_i[pos + 8] == 'm')){\
                              match = 1;}\
        if ((pos < bdy - 9 + 1) & (s_char_i[pos + 0] == 0x18)\
                              & (s_char_i[pos + 1] == 'f')\
                              & (s_char_i[pos + 2] == 't')\
                              & (s_char_i[pos + 3] == 'y')\
                              & (s_char_i[pos + 4] == 'p')\
                              & (s_char_i[pos + 5] == '3')\
                              & (s_char_i[pos + 6] == 'g')\
                              & (s_char_i[pos + 7] == 'p')\
                              & (s_char_i[pos + 8] == '5')){\
                              match = 2;}\
        if ((pos < bdy - 16 + 1) & (s_char_i[pos + 0] == 0x1a)\
                               & (s_char_i[pos + 1] == 'E')\
                               & (s_char_i[pos + 2] == 0xdf)\
                               & (s_char_i[pos + 3] == 0xa3)\
                               & (s_char_i[pos + 4] == 0x93)\
                               & (s_char_i[pos + 5] == 'B')\
                               & (s_char_i[pos + 6] == 0x82)\
                               & (s_char_i[pos + 7] == 0x88)\
                               & (s_char_i[pos + 8] == 'm')\
                               & (s_char_i[pos + 10] == 't')\
                               & (s_char_i[pos + 11] == 'r')\
                               & (s_char_i[pos + 12] == 'o')\
                               & (s_char_i[pos + 13] == 's')\
                               & (s_char_i[pos + 14] == 'k')\
                               & (s_char_i[pos + 15] == 'a')){\
                               match = 3;}\
        if ((pos < bdy - 3 + 1) & (s_char_i[pos + 0] == 0x1f)\
                              & (s_char_i[pos + 1] == 0x8b)\
                              & (s_char_i[pos + 2] == 0x08)){\
                              match = 4;}\
        if ((pos < bdy - 4 + 1) & (s_char_i[pos + 0] == '%')\
                              & (s_char_i[pos + 1] == 'P')\
                              & (s_char_i[pos + 2] == 'D')\
                              & (s_char_i[pos + 3] == 'F')){\
                              match = 5;}\
        if ((pos < bdy - 6 + 1) & (s_char_i[pos + 0] == 0x37)\
                              & (s_char_i[pos + 1] == 0x7a)\
                              & (s_char_i[pos + 2] == 0xbc)\
                              & (s_char_i[pos + 3] == 0xaf)\
                              & (s_char_i[pos + 4] == 0x27)\
                              & (s_char_i[pos + 5] == 0x1c)){\
                              match = 6;}\
        if ((pos < bdy - 4 + 1) & (s_char_i[pos] == '8')\
                              & (s_char_i[pos + 1] == 'B')\
                              & (s_char_i[pos + 2] == 'P')\
                              & (s_char_i[pos + 3] == 'S')){\
                              match = 7;}\
        if ((pos < bdy - 8 + 1) & (s_char_i[pos] == '<')\
                              & (s_char_i[pos + 1] == '!')\
                              & (s_char_i[pos + 2] == 'd')\
                              & (s_char_i[pos + 3] == 'o')\
                              & (s_char_i[pos + 4] == 'c')\
                              & (s_char_i[pos + 5] == 't')\
                              & (s_char_i[pos + 6] == 'y')\
                              & (s_char_i[pos + 7] == 'p')){\
                              match = 8;}\
        if ((pos < bdy - 3 + 1) & (s_char_i[pos] == 'C')\
                              & (s_char_i[pos + 1] == 'W')\
                              & (s_char_i[pos + 2] == 'S')){\
                              match = 9;}\
        if ((pos < bdy - 3 + 1) & (s_char_i[pos] == 'F')\
                              & (s_char_i[pos + 1] == 'W')\
                              & (s_char_i[pos + 2] == 'S')){\
                              match = 10;}\
        if ((pos < bdy - 6 + 1) & (s_char_i[pos] == 'G')\
                              & (s_char_i[pos + 1] == 'I')\
                              & (s_char_i[pos + 2 ] == 'F')\
                              & (s_char_i[pos + 3] == '8')\
                              & (s_char_i[pos + 4] == '7')\
                              & (s_char_i[pos + 5] == 'a')){\
                              match = 11;}\
        if ((pos < bdy - 6 + 1) & (s_char_i[pos] == 'G')\
                              & (s_char_i[pos + 1] == 'I')\
                              & (s_char_i[pos + 2 ] == 'F')\
                              & (s_char_i[pos + 3] == '8')\
                              & (s_char_i[pos + 4] == '9')\
                              & (s_char_i[pos + 5] == 'a')){\
                              match = 12;}\
        if ((pos < bdy - 3 + 1) & (s_char_i[pos] == 'I')\
                              & (s_char_i[pos + 1] == ' ')\
                              & (s_char_i[pos + 2] == 'I')){\
                              match = 13;}\
        if ((pos < bdy - 3 + 1) & (s_char_i[pos] == 'I')\
                              & (s_char_i[pos + 1] == 'D')\
                              & (s_char_i[pos + 2] == '3')){\
                              match = 14;}\
        if ((pos < bdy - 2 + 1) & (s_char_i[pos] == 'M')\
                              & (s_char_i[pos + 1] == 'Z')){\
                              match = 15;}\
        if ((pos < bdy - 37 + 1) & (s_char_i[pos] == 'M')\
                               & (s_char_i[pos + 1] == 'i')\
                               & (s_char_i[pos + 2] == 'c')\
                               & (s_char_i[pos + 3] == 'r')\
                               & (s_char_i[pos + 4] == 'o')\
                               & (s_char_i[pos + 5] == 's')\
                               & (s_char_i[pos + 6] == 'o')\
                               & (s_char_i[pos + 7] == 'f')\
                               & (s_char_i[pos + 8] == 't')\
                               & (s_char_i[pos + 9] == ' ')\
                               & (s_char_i[pos + 10] == 'V')\
                               & (s_char_i[pos + 11] == 'i')\
                               & (s_char_i[pos + 12] == 's')\
                               & (s_char_i[pos + 13] == 'u')\
                               & (s_char_i[pos + 14] == 'a')\
                               & (s_char_i[pos + 15] == 'l')\
                               & (s_char_i[pos + 16] == ' ')\
                               & (s_char_i[pos + 17] == 'S')\
                               & (s_char_i[pos + 18] == 't')\
                               & (s_char_i[pos + 19] == 'u')\
                               & (s_char_i[pos + 20] == 'd')\
                               & (s_char_i[pos + 21] == 'i')\
                               & (s_char_i[pos + 22] == 'o')\
                               & (s_char_i[pos + 23] == ' ')\
                               & (s_char_i[pos + 24] == 'S')\
                               & (s_char_i[pos + 25] == 'o')\
                               & (s_char_i[pos + 26] == 'l')\
                               & (s_char_i[pos + 27] == 'u')\
                               & (s_char_i[pos + 28] == 't')\
                               & (s_char_i[pos + 29] == 'i')\
                               & (s_char_i[pos + 30] == 'o')\
                               & (s_char_i[pos + 31] == 'n')\
                               & (s_char_i[pos + 32] == ' ')\
                               & (s_char_i[pos + 33] == 'F')\
                               & (s_char_i[pos + 34] == 'i')\
                               & (s_char_i[pos + 35] == 'l')\
                               & (s_char_i[pos + 36] == 'e')){\
                               match = 16;}\
        if ((pos < bdy - 15 + 1) & (s_char_i[pos] == 'O')\
                               & (s_char_i[pos + 1] == 'P')\
                               & (s_char_i[pos + 2] == 'L')\
                               & (s_char_i[pos + 3] == 'D')\
                               & (s_char_i[pos + 4] == 'a')\
                               & (s_char_i[pos + 5] == 't')\
                               & (s_char_i[pos + 6] == 'a')\
                               & (s_char_i[pos + 7] == 'b')\
                               & (s_char_i[pos + 8] == 'a')\
                               & (s_char_i[pos + 9] == 's')\
                               & (s_char_i[pos + 10] == 'e')\
                               & (s_char_i[pos + 11] == 'F')\
                               & (s_char_i[pos + 12] == 'i')\
                               & (s_char_i[pos + 13] == 'l')\
                               & (s_char_i[pos + 14] == 'e')){\
                               match = 17;}\
        if ((pos < bdy - 8 + 1) & (s_char_i[pos] == 'P')\
                              & (s_char_i[pos + 1] == 'A')\
                              & (s_char_i[pos + 2] == 'G')\
                              & (s_char_i[pos + 3]  == 'E')\
                              & (s_char_i[pos + 4] == 'D')\
                              & (s_char_i[pos + 5] == 'U')\
                              & (s_char_i[pos + 6] == '6')\
                              & (s_char_i[pos + 7] == '4')){\
                              match = 18;}\
        if ((pos < bdy - 4 + 1) & (s_char_i[pos] == 'P')\
                              & (s_char_i[pos + 1] == 'K')\
                              & (s_char_i[pos + 2] == 0x03)\
                              & (s_char_i[pos + 3] == 0x04)){\
                              match = 19;}\
        if ((pos < bdy - 8 + 1) & (s_char_i[pos] == 'P')\
                              & (s_char_i[pos + 1] == 'K')\
                              & (s_char_i[pos + 2] == 0x05)\
                              & (s_char_i[pos + 3] == 0x06)\
                              & (s_char_i[pos + 4] == 'P')\
                              & (s_char_i[pos + 5] == 'K')\
                              & (s_char_i[pos + 6] == 0x07)\
                              & (s_char_i[pos + 7] == 0x08)){\
                              match = 20;}\
        if ((pos < bdy - 13 + 1) & (s_char_i[pos] == 'R')\
                               & (s_char_i[pos + 1] == 'e')\
                               & (s_char_i[pos + 2] == 't')\
                               & (s_char_i[pos + 3] == 'u')\
                               & (s_char_i[pos + 4] == 'r')\
                               & (s_char_i[pos + 5] == 'n')\
                               & (s_char_i[pos + 6] == '-')\
                               & (s_char_i[pos + 7] == 'P')\
                               & (s_char_i[pos + 8] == 'a')\
                               & (s_char_i[pos + 9] == 't')\
                               & (s_char_i[pos + 10] == 'h')\
                               & (s_char_i[pos + 11] == ':')\
                               & (s_char_i[pos + 12] == ' ')){\
                               match = 21;}\
        if ((pos < bdy - 15 + 1) & (s_char_i[pos] == '[')\
                               & (s_char_i[pos + 1] == 'W')\
                               & (s_char_i[pos + 2] == 'i')\
                               & (s_char_i[pos + 3] == 'n')\
                               & (s_char_i[pos + 4] == 'd')\
                               & (s_char_i[pos + 5] == 'o')\
                               & (s_char_i[pos + 6] == 'w')\
                               & (s_char_i[pos + 7] == 's')\
                               & (s_char_i[pos + 8] == ' ')\
                               & (s_char_i[pos + 9] == 'L')\
                               & (s_char_i[pos + 10] == 'a')\
                               & (s_char_i[pos + 11] == 't')\
                               & (s_char_i[pos + 12] == 'i')\
                               & (s_char_i[pos + 13] == 'n')\
                               & (s_char_i[pos + 14] == ' ')){\
                               match = 22;}\
        if ((pos < bdy - 8 + 1) & (s_char_i[pos] == 'f')\
                        & (s_char_i[pos + 1] == 't')\
                        & (s_char_i[pos + 2] == 'y')\
                        & (s_char_i[pos + 3] == 'p')\
                        & (s_char_i[pos + 4] == 'M')\
                        & (s_char_i[pos + 5] == 'S')\
                        & (s_char_i[pos + 6] == 'N')\
                        & (s_char_i[pos + 7] == 'V')){\
                        match = 23;}\
        if ((pos < bdy - 16 + 1) & (s_char_i[pos] == 0x7c)\
                               & (s_char_i[pos + 1] == 0x4b)\
                               & (s_char_i[pos + 2] == 0xc3)\
                               & (s_char_i[pos + 3] == 0x74)\
                               & (s_char_i[pos + 4] == 0xe1)\
                               & (s_char_i[pos + 5] == 0xc8)\
                               & (s_char_i[pos + 6] == 0x53)\
                               & (s_char_i[pos + 7] == 0xa4)\
                               & (s_char_i[pos + 8] == 0x79)\
                               & (s_char_i[pos + 9] == 0xb9)\
                               & (s_char_i[pos + 10] == 0x01)\
                               & (s_char_i[pos + 11] == 0x1d)\
                               & (s_char_i[pos + 12] == 0xfc)\
                               & (s_char_i[pos + 13] == 0x4f)\
                               & (s_char_i[pos + 14] == 0xdd)\
                               & (s_char_i[pos + 15] == 0x13)){\
                               match = 24;}\
        if ((pos < bdy - 28 + 1) & (s_char_i[pos] == 0x7e)\
                               & (s_char_i[pos + 1] == 'E')\
                               & (s_char_i[pos + 2] == 'S')\
                               & (s_char_i[pos + 3] == 'D')\
                               & (s_char_i[pos + 4] == 'w')\
                               & (s_char_i[pos + 5] == 0xf6)\
                               & (s_char_i[pos + 6] == 0x85)\
                               & (s_char_i[pos + 7] == '>')\
                               & (s_char_i[pos + 8] == 0xbf)\
                               & (s_char_i[pos + 9] == 'j')\
                               & (s_char_i[pos + 10] == 0xd2)\
                               & (s_char_i[pos + 11] == 0x11)\
                               & (s_char_i[pos + 12] == 'E')\
                               & (s_char_i[pos + 13] == 'a')\
                               & (s_char_i[pos + 14] == 's')\
                               & (s_char_i[pos + 15] == 'y')\
                               & (s_char_i[pos + 16] == ' ')\
                               & (s_char_i[pos + 17] == 'S')\
                               & (s_char_i[pos + 18] == 't')\
                               & (s_char_i[pos + 19] == 'r')\
                               & (s_char_i[pos + 20] == 'e')\
                               & (s_char_i[pos + 21] == 'e')\
                               & (s_char_i[pos + 22] == 't')\
                               & (s_char_i[pos + 23] == ' ')\
                               & (s_char_i[pos + 24] == 'D')\
                               & (s_char_i[pos + 25] == 'r')\
                               & (s_char_i[pos + 26] == 'a')\
                               & (s_char_i[pos + 27] == 'w')){\
                               match = 25;}\
        if ((pos < bdy - 16 + 1) & (s_char_i[pos] == 0xbe)\
                               & (s_char_i[pos + 1] == 0xba)\
                               & (s_char_i[pos + 2] == 0xfe)\
                               & (s_char_i[pos + 3] == 0xca)\
                               & (s_char_i[pos + 4] == 0x0f)\
                               & (s_char_i[pos + 5] == 'P')\
                               & (s_char_i[pos + 6] == 'a')\
                               & (s_char_i[pos + 7] == 'l')\
                               & (s_char_i[pos + 8] == 'm')\
                               & (s_char_i[pos + 9] == 'S')\
                               & (s_char_i[pos + 10] == 'G')\
                               & (s_char_i[pos + 11] == ' ')\
                               & (s_char_i[pos + 12] == 'D')\
                               & (s_char_i[pos + 13] == 'a')\
                               & (s_char_i[pos + 14] == 't')\
                               & (s_char_i[pos + 15] == 'a')){\
                               match = 26;}\
        if ((pos < bdy - 8 + 1) & (s_char_i[pos] == 0xd0)\
                              & (s_char_i[pos + 1] == 0xcf)\
                              & (s_char_i[pos + 2] == 0x11)\
                              & (s_char_i[pos + 3] == 0xe0)\
                              & (s_char_i[pos + 4] == 0xa1)\
                              & (s_char_i[pos + 5] == 0xb1)\
                              & (s_char_i[pos + 6] == 0x1a)\
                              & (s_char_i[pos + 7] == 0xe1)){\
                              match = 27;}\
    }\
    if (gbid < num_blocks_minus1) {\
        d_match_result[start] = match;\
        start += THREAD_BLOCK_SIZE;\
    }else {\
        if (start >= input_size){\
            return;\
        }\
        d_match_result[start] = match;\
        start += THREAD_BLOCK_SIZE;\
    }


__global__ void match_naive_opt_spec_manual_nu_bw(const int* __restrict__ d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result) {
    
    int t_id = threadIdx.x;
    int gbid = blockIdx.y * gridDim.x + blockIdx.x;

    int start = gbid * THREAD_BLOCK_SIZE + t_id ;
    int pos;
    int inputChar;
    __shared__ int s_input[ THREAD_BLOCK_SIZE + EXTRA_SIZE_PER_TB];
    
    unsigned char *s_char_i;
    
    if ( gbid > num_blocks_minus1 ){
        return ; // whole block is outside input stream
    }

    s_char_i = (unsigned char *)s_input;

    // read global data to shared memory
    if ( start < n_hat ){
        s_input[t_id] = d_input_string[start];
    }

    start += THREAD_BLOCK_SIZE ;
    if ( (start < n_hat) && (t_id < EXTRA_SIZE_PER_TB) ){
        s_input[t_id + THREAD_BLOCK_SIZE] = d_input_string[start];
    }
    __syncthreads();

    int bdy_ = input_size - ( gbid * THREAD_BLOCK_SIZE * 4 );
    int bdy = (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4 > bdy_ ? bdy_ : (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4;


    start = gbid * (THREAD_BLOCK_SIZE * 4) + t_id ;

    for (int j = 0; j < 4; j++) {
        
        int match = 0;
        SUBSEG_MATCH_NOTEX(j)
    
    }
    
    
}

void matchNaiveSpecManualOptNUBWWrapper(PFAC_handle_t handle,dim3 grid, dim3 block,const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result){
    
    std::vector<std::string> vpatterns;
    
    for (int i = 0; i < handle->numOfPatterns; i++) {
        vpatterns.push_back(std::string(handle->rowPtr[i],handle->patternLen_table[i+1]));
    }

    std::string kernel;
    
    kernel += "naive_spec_manual_bw\n";
    kernel += "__global__\n";
    kernel += "void match_naive_opt_spec_manual_nu_bw_jit(const int* __restrict__ d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result) {\n";
    kernel += "    const int THREAD_BLOCK_SIZE = " + std::to_string(THREAD_BLOCK_SIZE) + ";\n";
    kernel += "    const int EXTRA_SIZE_PER_TB = " + std::to_string(EXTRA_SIZE_PER_TB) + ";\n";
    kernel += "    int t_id = threadIdx.x;\n"
               "    int gbid = blockIdx.y * gridDim.x + blockIdx.x;\n"
               "    int start = gbid * THREAD_BLOCK_SIZE + t_id;\n"
               "    int pos;\n"
               "    __shared__ int s_input[ THREAD_BLOCK_SIZE + EXTRA_SIZE_PER_TB];\n"
               "    unsigned char *s_char;\n"
               "    if ( gbid > num_blocks_minus1 ){\n"
               "        return ;\n"
               "    }\n"
               "    s_char = (unsigned char *)s_input;\n"
               "    if ( start < n_hat ){\n"
               "        s_input[t_id] = d_input_string[start];\n"
               "    }\n"
               "    start += THREAD_BLOCK_SIZE ;\n"
               "    if ( (start < n_hat) && (t_id < EXTRA_SIZE_PER_TB) ){\n"
               "        s_input[t_id + THREAD_BLOCK_SIZE] = d_input_string[start];\n"
               "    }\n"
               "    __syncthreads();\n"
               "    int bdy = input_size - ( gbid * THREAD_BLOCK_SIZE * 4 );\n"
               "    int legal_size = (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4 > bdy ? bdy : (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4;\n"
               "    start = gbid * (THREAD_BLOCK_SIZE * 4) + t_id ;\n"
               "    for (int j = 0; j < 4; j++) {\n"
               "        int match = 0;\n"
               "        unsigned char prefetched_char[" + std::to_string(handle->maxPatternLen) + "] = {0};\n"
               "        pos = t_id + j * THREAD_BLOCK_SIZE;\n"
               "        if (pos < legal_size -" + std::to_string(handle->maxPatternLen) + " + 1){\n"
               "            #pragma unroll\n"
               "            for (int i = 0; i < " + std::to_string(handle->maxPatternLen) + "; i++){\n"
               "                prefetched_char[i] = s_char[pos + i];\n"
               "            }\n";
    for (int i = 0; i < vpatterns.size(); i++){
        auto pattern = vpatterns[i];
        std::string if_clause = "           if (";
        for (int j = 0; j < pattern.size() - 1; j++){
            if_clause += "(prefetched_char[" + std::to_string(j) + "] == " + std::to_string((int)((unsigned char)pattern[j])) + ") & ";
        }
        if_clause += "(prefetched_char[" + std::to_string(pattern.size() - 1) + "] == " + std::to_string((int)((unsigned char)pattern[pattern.size() - 1])) + ")){\n"
                     "              match = " + std::to_string(i + 1) + ";}\n";
        kernel += if_clause;
    }

    kernel += "} else if(pos < legal_size){\n";

    for (int i = 0; i < vpatterns.size(); i++){
        auto pattern = vpatterns[i];
        std::string if_clause = "           if ((pos < legal_size - " + std::to_string(pattern.size()) + " + 1) & ";
        for (int j = 0; j < pattern.size() - 1; j++){
            if_clause += "(s_char[pos + " + std::to_string(j) + "] == " + std::to_string((int)((unsigned char)pattern[j])) + ") & ";
        }
        if_clause += "(s_char[pos + " + std::to_string(pattern.size() - 1) + "] == " + std::to_string((int)((unsigned char)pattern[pattern.size() - 1])) + ")){\n"
                     "              match = " + std::to_string(i + 1) + ";}\n";
        kernel += if_clause;
    }
    kernel += "}\n"
              "if (gbid < num_blocks_minus1) {\n"
              "    d_match_result[start] = match;\n"
              "    start += THREAD_BLOCK_SIZE;\n"
              "}else {\n"
              "     if (start >= input_size){\n"
              "         return;\n"
              "     }\n"
              "     d_match_result[start] = match;\n"
              "     start += THREAD_BLOCK_SIZE;\n"
              "}\n";

    kernel += "}\n}\n";
    // std::cout << kernel << std::endl;

    static jitify::JitCache kernel_cache;
    jitify::Program program = kernel_cache.program(kernel);
    using jitify::reflection::type_of;

    auto kernel_instance = program.kernel("match_naive_opt_spec_manual_nu_bw_jit")
       .instantiate()
       .configure(grid, block);
    RUN(kernel_instance.launch(d_input_string,input_size,n_hat,num_blocks_minus1,d_match_result))

    // RUN((match_naive_opt_spec_manual_nu_bw<<<grid,block>>>(d_input_string,input_size,n_hat,num_blocks_minus1,d_match_result)))
}