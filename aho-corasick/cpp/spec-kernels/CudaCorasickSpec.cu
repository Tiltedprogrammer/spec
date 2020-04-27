#include "../spec_match.hpp"
#include "ImpalaKernels.hpp"

#include <stack>

#define MANUAL_EXPAND_2( X )   { X ; X ; }
#define MANUAL_EXPAND_4( X )   { MANUAL_EXPAND_2( MANUAL_EXPAND_2( X ) )  }

//check pos < bdy
#define  SUBSEG_MATCH_NOTEX( j, match ) \
    pos = t_id + j * THREAD_BLOCK_SIZE;\
    if(pos < bdy){\
        inputChar = s_char[pos++];\
        /*"0x14ftypisom"*/\
        if (inputChar == 0x14){\
            inputChar = s_char[pos++];\
            if (inputChar == 'f'){\
                inputChar = s_char[pos++];\
                if (inputChar == 't'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'y') {\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'p'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'i') {\
                                inputChar = s_char[pos++];\
                                if (inputChar == 's') {\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'o'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 'm') {\
                                            match = 1;\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
            /*"0x18ftyp3gp5"*/\
        }else if (inputChar == 0x18){/*state # 37*/\
            inputChar = s_char[pos++];\
            if (inputChar == 'f'){\
                inputChar = s_char[pos++];\
                if (inputChar == 't') {\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'y') {\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'p') {\
                            inputChar = s_char[pos++];\
                            if (inputChar == '3') {\
                                inputChar = s_char[pos++];\
                                if (inputChar == 'g'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'p'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == '5'){\
                                            match = 2;\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
            /*0x1aE0xdf0xa30x93B0x820x88matroska*/\
        } else if(inputChar == 0x1a){ /*state # 45*/\
            inputChar = s_char[pos++];\
            if (inputChar == 'E'){\
               inputChar = s_char[pos++];\
               if (inputChar == 0xdf) {\
                inputChar = s_char[pos++];\
                if (inputChar == 0xa3) {\
                    inputChar = s_char[pos++];\
                    if (inputChar == 0x93){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'B'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 0x82) {\
                                inputChar = s_char[pos++];\
                                if (inputChar == 0x88) {\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'm'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 'a') {\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == 't'){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 'r') {\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == 'o') {\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == 's'){\
                                                            inputChar = s_char[pos++];\
                                                            if (inputChar == 'k'){\
                                                                inputChar = s_char[pos++];\
                                                                if (inputChar == 'a'){\
                                                                    match = 3;\
                                                                }\
                                                            }\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
               }\
            }\
        /*0x1f0x8b0x08*/\
        }else if (inputChar == 0x1f){ /*state #60*/\
            inputChar = s_char[pos++];\
            if (inputChar == 0x8b) {\
                inputChar = s_char[pos++];\
                if (inputChar == 0x08) {\
                    match = 4;\
                }\
            }\
        /*"%PDF"*/\
        }else if (inputChar == '%'){ /*state # 62*/\
            inputChar = s_char[pos++];\
            if (inputChar == 'P'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'D'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'F'){\
                        match = 5;\
                    }\
                }\
            }\
        /*"0x370x7a0xbc0xaf0x270x1c"*/\
        }else if (inputChar == 0x37){ /*state #65*/\
            inputChar = s_char[pos++];\
            if (inputChar == 0x7a){\
                inputChar = s_char[pos++];\
                if (inputChar == 0xbc) {\
                    inputChar = s_char[pos++];\
                    if (inputChar == 0xaf){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 0x27) {\
                            inputChar = s_char[pos++];\
                            if (inputChar == 0x1c){\
                                match = 6;\
                            }\
                        }\
                    }\
                }\
            }\
        /*"8BPS"*/\
        }else if (inputChar == '8'){ /*state #70*/\
            inputChar = s_char[pos++];\
            if (inputChar == 'B') {\
                inputChar = s_char[pos++];\
                if (inputChar == 'P'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'S') {\
                        match = 7;\
                    }\
                }\
            }\
        /*"<!doctyp"*/\
        }else if (inputChar == '<'){ /*state #73*/\
            inputChar = s_char[pos++];\
            if (inputChar == '!'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'd'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'o') {\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'c') {\
                            inputChar = s_char[pos++];\
                            if (inputChar == 't') {\
                                inputChar = s_char[pos++];\
                                if (inputChar == 'y') {\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'p') {\
                                        match = 8;\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        /*"CWS"*/\
        }else if (inputChar == 'C'){/*state #80*/\
            inputChar = s_char[pos++];\
            if (inputChar == 'W') {\
                inputChar = s_char[pos++];\
                if (inputChar == 'S'){\
                    match = 9;\
                }\
            }\
        /*FWS*/\
        }else if (inputChar == 'F'){/*state #82*/\
            inputChar = s_char[pos++];\
            if (inputChar == 'W') {\
                inputChar = s_char[pos++];\
                if (inputChar == 'S'){\
                    match = 10;\
                }\
            }\
        }else if (inputChar == 'G'){ /*state #84*/\
            inputChar = s_char[pos++];\
            if (inputChar == 'I'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'F'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == '8'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == '7'){ /*state #88*/\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'a'){\
                                match = 11;\
                            }\
                        } else if (inputChar == '9'){ /*state #89*/\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'a'){\
                                match = 12;\
                            }\
                        }\
                    }\
                }\
            }\
        }else if(inputChar == 'I'){ /*"state #90"*/\
            inputChar = s_char[pos++];\
            if (inputChar == ' ') {\
                inputChar = s_char[pos++];\
                if (inputChar == 'I'){\
                    match = 13;\
                }\
            }else if(inputChar == 'D'){\
                inputChar = s_char[pos++];\
                if (inputChar == '3'){\
                    match = 14;\
                }\
            }\
        }else if(inputChar == 'M'){\
            inputChar = s_char[pos++];\
            if (inputChar == 'Z'){\
                match = 15;\
            /*Microsoft Visual Studio Solution File*/\
            }else if(inputChar == 'i'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'c'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'r'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'o'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 's'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 'o'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'f'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 't'){\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == ' '){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 'V') {\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == 'i'){\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == 's'){\
                                                            inputChar = s_char[pos++];\
                                                            if (inputChar == 'u'){\
                                                                inputChar = s_char[pos++];\
                                                                if (inputChar == 'a'){\
                                                                    inputChar = s_char[pos++];\
                                                                    if (inputChar == 'l'){\
                                                                        inputChar = s_char[pos++];\
                                                                        if (inputChar == ' '){\
                                                                            inputChar = s_char[pos++];\
                                                                            if (inputChar == 'S'){\
                                                                                inputChar = s_char[pos++];\
                                                                                if (inputChar == 't'){\
                                                                                    inputChar = s_char[pos++];\
                                                                                    if (inputChar == 'u'){\
                                                                                        inputChar = s_char[pos++];\
                                                                                        if (inputChar == 'd'){\
                                                                                            inputChar = s_char[pos++];\
                                                                                            if (inputChar == 'i'){\
                                                                                                inputChar = s_char[pos++];\
                                                                                                if (inputChar == 'o'){\
                                                                                                    inputChar = s_char[pos++];\
                                                                                                    if (inputChar == ' '){\
                                                                                                        inputChar = s_char[pos++];\
                                                                                                        if (inputChar == 'S'){\
                                                                                                            inputChar = s_char[pos++];\
                                                                                                            if (inputChar == 'o'){\
                                                                                                                inputChar = s_char[pos++];\
                                                                                                                if (inputChar == 'l'){\
                                                                                                                    inputChar = s_char[pos++];\
                                                                                                                    if (inputChar == 'u'){\
                                                                                                                        inputChar = s_char[pos++];\
                                                                                                                        if (inputChar == 't'){\
                                                                                                                            inputChar = s_char[pos++];\
                                                                                                                            if (inputChar == 'i'){\
                                                                                                                                inputChar = s_char[pos++];\
                                                                                                                                if (inputChar == 'o'){\
                                                                                                                                    inputChar = s_char[pos++];\
                                                                                                                                    if (inputChar == 'n'){\
                                                                                                                                        inputChar = s_char[pos++];\
                                                                                                                                        if (inputChar == ' '){\
                                                                                                                                            inputChar = s_char[pos++];\
                                                                                                                                            if (inputChar == 'F'){\
                                                                                                                                                inputChar = s_char[pos++];\
                                                                                                                                                if (inputChar == 'i'){\
                                                                                                                                                    inputChar = s_char[pos++];\
                                                                                                                                                    if (inputChar == 'l'){\
                                                                                                                                                        inputChar = s_char[pos++];\
                                                                                                                                                        if (inputChar == 'e'){\
                                                                                                                                                            match = 16;\
                                                                                                                                                        }\
                                                                                                                                                    }\
                                                                                                                                                }\
                                                                                                                                            }\
                                                                                                                                        }\
                                                                                                                                   }\
                                                                                                                                }\
                                                                                                                            }\
                                                                                                                        }\
                                                                                                                    }\
                                                                                                                }\
                                                                                                            }\
                                                                                                        }\
                                                                                                    }\
                                                                                                }\
                                                                                            }\
                                                                                        }\
                                                                                    }\
                                                                                }\
                                                                            }\
                                                                        }\
                                                                    }\
                                                                }\
                                                            }\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if (inputChar == 'O'){\
            inputChar = s_char[pos++];\
            if (inputChar == 'P'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'L'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'D'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'a'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 't'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 'a'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'b'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 'a'){\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == 's'){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 'e'){\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == 'F'){\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == 'i'){\
                                                            inputChar = s_char[pos++];\
                                                            if (inputChar == 'l'){\
                                                                inputChar = s_char[pos++];\
                                                                if (inputChar == 'e'){\
                                                                    match = 17;\
                                                                }\
                                                            }\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if (inputChar == 'P'){\
            inputChar = s_char[pos++];\
            if (inputChar == 'A'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'G'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'E'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'D'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'U'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == '6'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == '4'){\
                                        match = 18;\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }else if (inputChar == 'K'){\
                inputChar = s_char[pos++];\
                if (inputChar == 0x03){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 0x04){\
                        match = 19;\
                    }\
                }else if (inputChar == 0x05){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 0x06){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'P'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'K'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 0x07){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 0x08){\
                                        match = 20;\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if (inputChar == 'R'){\
            inputChar = s_char[pos++];\
            if (inputChar == 'e'){\
                inputChar = s_char[pos++];\
                if (inputChar == 't'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'u'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'r'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'n'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == '-'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'P'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 'a'){\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == 't'){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 'h'){\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == ':'){\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == ' '){\
                                                            match = 21;\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if (inputChar == '['){\
            inputChar = s_char[pos++];\
            if (inputChar == 'W'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'i'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'n'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'd'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'o'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 'w'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 's'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == ' '){\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == 'L'){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 'a'){\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == 't'){\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == 'i'){\
                                                            inputChar = s_char[pos++];\
                                                            if (inputChar == 'n'){\
                                                                inputChar = s_char[pos++];\
                                                                if (inputChar == ' '){\
                                                                    match = 22;\
                                                                }\
                                                            }\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if (inputChar == 'f'){\
            inputChar = s_char[pos++];\
            if (inputChar == 't'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'y'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'p'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'M'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'S'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 'N'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'V'){\
                                        match = 23;\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
            /*0x7c0x4b0xc30x740xe10xc80x530xa40x790xb90x010x1d0xfc0x4f0xdd0x13*/\
        } else if (inputChar == 0x7c){\
            inputChar = s_char[pos++];\
            if (inputChar == 0x4b){\
                inputChar = s_char[pos++];\
                if (inputChar == 0xc3){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 0x74){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 0xe1){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 0xc8){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 0x53){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 0xa4){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 0x79){\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == 0xb9){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 0x01){\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == 0x1d){\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == 0xfc){\
                                                            inputChar = s_char[pos++];\
                                                            if (inputChar == 0x4f){\
                                                                inputChar = s_char[pos++];\
                                                                if (inputChar == 0xdd){\
                                                                    inputChar = s_char[pos++];\
                                                                    if (inputChar == 0x13){\
                                                                        match = 24;\
                                                                    }\
                                                                }\
                                                            }\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if (inputChar == 0x7e){\
            inputChar = s_char[pos++];\
            if (inputChar == 'E'){\
                inputChar = s_char[pos++];\
                if (inputChar == 'S'){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 'D'){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 'w'){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 0xf6){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 0x85){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == '>'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 0xbf){\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == 'j'){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 0xd2){\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == 0x11){\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == 'E'){\
                                                            inputChar = s_char[pos++];\
                                                            if (inputChar == 'a'){\
                                                                inputChar = s_char[pos++];\
                                                                if (inputChar == 's'){\
                                                                    inputChar = s_char[pos++];\
                                                                    if (inputChar == 'y'){\
                                                                        inputChar = s_char[pos++];\
                                                                        if (inputChar == ' '){\
                                                                            inputChar = s_char[pos++];\
                                                                            if (inputChar == 'S'){\
                                                                                inputChar = s_char[pos++];\
                                                                                if (inputChar == 't'){\
                                                                                    inputChar = s_char[pos++];\
                                                                                    if (inputChar == 'r'){\
                                                                                        inputChar = s_char[pos++];\
                                                                                        if (inputChar == 'e'){\
                                                                                            inputChar = s_char[pos++];\
                                                                                            if (inputChar == 'e'){\
                                                                                                inputChar = s_char[pos++];\
                                                                                                if (inputChar == 't'){\
                                                                                                    inputChar = s_char[pos++];\
                                                                                                    if (inputChar == ' '){\
                                                                                                        inputChar = s_char[pos++];\
                                                                                                        if(inputChar == 'D'){\
                                                                                                            inputChar = s_char[pos++];\
                                                                                                            if (inputChar == 'r'){\
                                                                                                                inputChar = s_char[pos++];\
                                                                                                                if (inputChar == 'a'){\
                                                                                                                    inputChar = s_char[pos++];\
                                                                                                                    if (inputChar == 'w'){\
                                                                                                                        match = 25;\
                                                                                                                    }\
                                                                                                                }\
                                                                                                            }\
                                                                                                        }\
                                                                                                    }\
                                                                                                }\
                                                                                            }\
                                                                                        }\
                                                                                    }\
                                                                                }\
                                                                            }\
                                                                        }\
                                                                    }\
                                                                }\
                                                            }\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if(inputChar == 0xbe){\
            inputChar = s_char[pos++];\
            if (inputChar == 0xba){\
                inputChar = s_char[pos++];\
                if (inputChar == 0xfe){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 0xca){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 0x0f){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 'P'){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 'a'){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 'l'){\
                                        inputChar = s_char[pos++];\
                                        if (inputChar == 'm'){\
                                            inputChar = s_char[pos++];\
                                            if (inputChar == 'S'){\
                                                inputChar = s_char[pos++];\
                                                if (inputChar == 'G'){\
                                                    inputChar = s_char[pos++];\
                                                    if (inputChar == ' '){\
                                                        inputChar = s_char[pos++];\
                                                        if (inputChar == 'D'){\
                                                            inputChar = s_char[pos++];\
                                                            if (inputChar == 'a'){\
                                                                inputChar = s_char[pos++];\
                                                                if (inputChar == 't'){\
                                                                    inputChar = s_char[pos++];\
                                                                    if (inputChar == 'a'){\
                                                                        match = 26;\
                                                                    }\
                                                                }\
                                                            }\
                                                        }\
                                                    }\
                                                }\
                                            }\
                                        }\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }else if (inputChar == 0xd0){\
            inputChar = s_char[pos++];\
            if (inputChar == 0xcf){\
                inputChar = s_char[pos++];\
                if (inputChar == 0x11){\
                    inputChar = s_char[pos++];\
                    if (inputChar == 0xe0){\
                        inputChar = s_char[pos++];\
                        if (inputChar == 0xa1){\
                            inputChar = s_char[pos++];\
                            if (inputChar == 0xb1){\
                                inputChar = s_char[pos++];\
                                if (inputChar == 0x1a){\
                                    inputChar = s_char[pos++];\
                                    if (inputChar == 0xe1){\
                                        match = 27;\
                                    }\
                                }\
                            }\
                        }\
                    }\
                }\
            }\
        }\
    }

__global__ void match_corasick_spec(const int* __restrict__ d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result) {
    
    int t_id = threadIdx.x;
    int gbid = blockIdx.y * gridDim.x + blockIdx.x;

    int start = gbid * THREAD_BLOCK_SIZE + t_id ;
    int pos;
    int inputChar;
    int match[4] = {0,0,0,0};
    __shared__ int s_input[ THREAD_BLOCK_SIZE + EXTRA_SIZE_PER_TB];
    
    unsigned char *s_char;
    
    if ( gbid > num_blocks_minus1 ){
        return ; // whole block is outside input stream
    }

    s_char = (unsigned char *)s_input;

    // read global data to shared memory
    if ( start < n_hat ){
        s_input[t_id] = d_input_string[start];
    }

    start += THREAD_BLOCK_SIZE ;
    if ( (start < n_hat) && (t_id < EXTRA_SIZE_PER_TB) ){
        s_input[t_id + THREAD_BLOCK_SIZE] = d_input_string[start];
    }
    __syncthreads();

    int bdy = input_size - ( gbid * THREAD_BLOCK_SIZE * 4 );
    
    int j = 0 ;

    MANUAL_EXPAND_4( SUBSEG_MATCH_NOTEX(j, match[j]) ; j++ ;)
    

    // write 4 results  match[0:3] to global d_match_result[0:input_size)
    // one thread block processes (BLOCKSIZE * 4) substrings
    start = gbid * (THREAD_BLOCK_SIZE * 4) + t_id ;

    if ( gbid < num_blocks_minus1 ){
        #pragma unroll
        for (int j = 0 ; j < 4 ; j++ ){
            d_match_result[start] = match[j];
            start += THREAD_BLOCK_SIZE;
        }
    }else{
        int j = 0 ;
        MANUAL_EXPAND_4( if (start>=input_size) return ; d_match_result[start] = match[j]; \
        j++ ; start += THREAD_BLOCK_SIZE ; )
    } 


}

// void construct_automaton(PFAC_handle_t handle,std::stack<std::pair<int,int>>& pfac_table, std::string& automaton){
//     if(pfac_table.empty()) return;
//     std::pair<int,int> p = pfac_table.top();
//     pfac_table.pop();
//     for(int i = 0; i < CHAR_SET; i++){
//         int new_state = handle->h_PFAC_table[p.second * CHAR_SET + i];
//         if(new_state != TRAP_STATE){
//             pfac_table.emplace(i,new_state);
//         }
//     }
//     automaton += "if(inputChar == " + std::to_string(p.first) + "){\n";
//     if(p.second < handle->initial_state){
//         automaton += "  match = " + std::to_string(p.second) + ";\n";
//     }
//     automaton += "  pos = pos + 1;\n"
//                  "  if(pos < bdy){\n"
//                  "      inputChar = s_char[pos];\n";
//     construct_automaton(handle,pfac_table,automaton);
//     automaton += "}\n}\n";
// }

void build_automaton(int ch,int state,int depth,PFAC_handle_t handle,std::string& automaton){
    
    if(depth){
        automaton += "else if(inputChar == " + std::to_string(ch) + "){\n";
        if(state < handle->initial_state){
            automaton += "  match = " + std::to_string(state) + ";\n";
        }
    }else {
        automaton += "if(inputChar == " + std::to_string(ch) + "){\n";
        if(state < handle->initial_state){
            automaton += "  match = " + std::to_string(state) + ";\n";
        }
    }
    std::vector<std::pair<int,int>> states;
    for(int i = 0; i < CHAR_SET; i++){
        int new_state = handle->h_PFAC_table[state * CHAR_SET + i];
        if(new_state != TRAP_STATE){
            states.emplace_back(i,new_state);
            // build_automaton(i,new_state,handle,automaton);
        }
    }
    if(!states.empty()){
        automaton += "  if(++pos < bdy){\n"
                     "      inputChar = s_char[pos];\n";
    }

    int depth_ = 0;
    for(auto p : states){
        build_automaton(p.first,p.second,depth_++,handle,automaton);
    }
    
    if(!states.empty()){
        automaton += "}\n";
    }
    automaton += "}\n";
   
}

void matchCorasickSpecWrapper(PFAC_handle_t handle,dim3 grid, dim3 block,const int* d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result){
    std::vector<std::string> vpatterns;
    
    for (int i = 0; i < handle->numOfPatterns; i++) {
        vpatterns.push_back(std::string(handle->rowPtr[i],handle->patternLen_table[i+1]));
    }

    std::string kernel;
    
    kernel += "naive_spec_manual\n";
    kernel += "__global__\n";
    kernel += "void match_naive_opt_spec_manual_corasick_jit(const int* __restrict__ d_input_string, int input_size, int n_hat, int num_blocks_minus1, int* d_match_result) {\n";
    kernel += "    const int THREAD_BLOCK_SIZE = " + std::to_string(THREAD_BLOCK_SIZE) + ";\n";
    kernel += "    const int EXTRA_SIZE_PER_TB = " + std::to_string(EXTRA_SIZE_PER_TB) + ";\n";
    kernel += "    int t_id = threadIdx.x;\n"
               "    int gbid = blockIdx.y * gridDim.x + blockIdx.x;\n"
               "    int start = gbid * THREAD_BLOCK_SIZE + t_id;\n"
               "    int inputChar;\n"
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
            //    "    int legal_size = (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4 > bdy ? bdy : (EXTRA_SIZE_PER_TB + THREAD_BLOCK_SIZE) * 4;\n"
               "    start = gbid * (THREAD_BLOCK_SIZE * 4) + t_id ;\n"
               "    for (int j = 0; j < 4; j++) {\n"
               "        int match = 0;\n"
               "        pos = t_id + j * THREAD_BLOCK_SIZE;\n"
               "        if (pos < bdy){\n"
               "            inputChar = s_char[pos];\n";
    // std::stack<std::pair<int,int>> states;
    std::string automaton;
    
    int depth_ = 0;
    for(int i = 0;i < CHAR_SET; i++){
        if(handle->h_PFAC_table[handle->initial_state * CHAR_SET + i] != TRAP_STATE){
            // states.emplace(i,handle->h_PFAC_table[handle->initial_state * CHAR_SET + i]);
            build_automaton(i,handle->h_PFAC_table[handle->initial_state * CHAR_SET + i],depth_++,handle,automaton);
        }
    }

    kernel += automaton;

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

    RUN((program.kernel("match_naive_opt_spec_manual_corasick_jit")
       .instantiate()
       .configure(grid, block)
       .launch(d_input_string,input_size,n_hat,num_blocks_minus1,d_match_result)))

    // RUN((match_corasick_spec<<<grid,block>>>(d_input_string,input_size,n_hat,num_blocks_minus1,d_match_result)))
}