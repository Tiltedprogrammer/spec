extern "C" {
__device__ inline int threadIdx_x() { return threadIdx.x; }
__device__ inline int threadIdx_y() { return threadIdx.y; }
__device__ inline int threadIdx_z() { return threadIdx.z; }
__device__ inline int blockIdx_x() { return blockIdx.x; }
__device__ inline int blockIdx_y() { return blockIdx.y; }
__device__ inline int blockIdx_z() { return blockIdx.z; }
__device__ inline int blockDim_x() { return blockDim.x; }
__device__ inline int blockDim_y() { return blockDim.y; }
__device__ inline int blockDim_z() { return blockDim.z; }
__device__ inline int gridDim_x() { return gridDim.x; }
__device__ inline int gridDim_y() { return gridDim.y; }
__device__ inline int gridDim_z() { return gridDim.z; }
__global__ void lambda_21950(int, int, int*, int*, int);

__global__ __launch_bounds__ (256 * 1 * 1) void lambda_21950(int _21953_26963, int _21954_26964, int* _21955_26965, int* _21956_26966, int _21957_26967) {
    int  t_id_26976;
    int pt_id_26976;
    int  blockIdx_y_26982;
    int pblockIdx_y_26982;
    int  gridDim_x_26988;
    int pgridDim_x_26988;
    int  blockIdx_x_26994;
    int pblockIdx_x_26994;
    int*  s_Input_27011;
    int* ps_Input_27011;
    int  lower_27038;
    int plower_27038;
    
    int start_27001_slot;
    int* start_27001;
    start_27001 = &start_27001_slot;
    int matching_27051_slot;
    int* matching_27051;
    matching_27051 = &matching_27051_slot;
    int state_27065_slot;
    int* state_27065;
    state_27065 = &state_27065_slot;
    int pos_27049_slot;
    int* pos_27049;
    pos_27049 = &pos_27049_slot;
    t_id_26976 = threadIdx_x();
    pt_id_26976 = t_id_26976;
    l26974: ;
        t_id_26976 = pt_id_26976;
        blockIdx_y_26982 = blockIdx_y();
        pblockIdx_y_26982 = blockIdx_y_26982;
    l26980: ;
        blockIdx_y_26982 = pblockIdx_y_26982;
        gridDim_x_26988 = gridDim_x();
        pgridDim_x_26988 = gridDim_x_26988;
    l26986: ;
        gridDim_x_26988 = pgridDim_x_26988;
        blockIdx_x_26994 = blockIdx_x();
        pblockIdx_x_26994 = blockIdx_x_26994;
    l26992: ;
        blockIdx_x_26994 = pblockIdx_x_26994;
        int _27003;
        _27003 = blockIdx_y_26982 * gridDim_x_26988;
        int b_id_27004;
        b_id_27004 = _27003 + blockIdx_x_26994;
        int _27005;
        _27005 = 256 * b_id_27004;
        int start_27006;
        start_27006 = _27005 + t_id_26976;
        *start_27001 = start_27006;
        __shared__ int reserver_s_Input_27011[384];
        ps_Input_27011 = reserver_s_Input_27011;
    l27009: ;
        s_Input_27011 = ps_Input_27011;
        bool _27012;
        _27012 = _21957_26967 < b_id_27004;
        if (_27012) goto l27013; else goto l27014;
    l27014: ;
        int _27015;
        _27015 = *start_27001;
        int _27016;
        _27016 = _27015;
        bool _27017;
        _27017 = _27016 < _21954_26964;
        if (_27017) goto l27018; else goto l27276;
    l27276: ;
        goto l27019;
    l27018: ;
        int* _27273;
        _27273 = s_Input_27011 + t_id_26976;
        int _27267;
        _27267 = *start_27001;
        int _27269;
        _27269 = _27267;
        int* _27270;
        _27270 = _21956_26966 + _27269;
        int _27271;
        _27271 = *_27270;
        int _27274;
        _27274 = _27271;
        *_27273 = _27274;
        goto l27019;
    l27019: ;
        int _27021;
        _27021 = *start_27001;
        int _27022;
        _27022 = _27021;
        int _27023;
        _27023 = 256 + _27022;
        bool _27024;
        _27024 = _27023 < _21954_26964;
        *start_27001 = _27023;
        if (_27024) goto l27025; else goto l27265;
    l27265: ;
        goto l27263;
    l27025: ;
        bool _27027;
        _27027 = t_id_26976 < 128;
        if (_27027) goto l27028; else goto l27262;
    l27262: ;
        goto l27263;
    l27263: ;
        goto l27029;
    l27028: ;
        int _27258;
        _27258 = 256 + t_id_26976;
        int* _27259;
        _27259 = s_Input_27011 + _27258;
        int* _27255;
        _27255 = _21956_26966 + _27023;
        int _27256;
        _27256 = *_27255;
        int _27260;
        _27260 = _27256;
        *_27259 = _27260;
        goto l27029;
    l27029: ;
        __syncthreads();
    l27034: ;
        unsigned char* c_Input_27054;
        c_Input_27054 = (unsigned char*)s_Input_27011;
        int _27045;
        _27045 = 1024 * b_id_27004;
        int bdy_27046;
        bdy_27046 = _21953_26963 - _27045;
        int _27251;
        _27251 = _27045 + t_id_26976;
        *start_27001 = _27251;
        plower_27038 = 0;
        goto l27036;
    l27036: ;
        lower_27038 = plower_27038;
        bool _27040;
        _27040 = lower_27038 < 4;
        if (_27040) goto l27041; else goto l27250;
    l27250: ;
        return ;
    l27041: ;
        int _27042;
        _27042 = 256 * lower_27038;
        int pos_27043;
        pos_27043 = t_id_26976 + _27042;
        bool _27047;
        _27047 = pos_27043 < bdy_27046;
        *pos_27049 = pos_27043;
        *matching_27051 = 0;
        if (_27047) goto l27048; else goto l27249;
    l27249: ;
        goto l27112;
    l27048: ;
        unsigned char* _27055;
        _27055 = c_Input_27054 + pos_27043;
        unsigned char _27056;
        _27056 = *_27055;
        unsigned char _27057;
        _27057 = _27056;
        *state_27065 = -1;
        int c_27058;
        union { int dst; unsigned char src; } uc_27058;
        uc_27058.src = _27057;
        c_27058 = uc_27058.dst;
        bool _27060;
        _27060 = c_27058 == 65;
        if (_27060) goto l27061; else goto l27240;
    l27240: ;
        bool _27241;
        _27241 = c_27058 == 66;
        if (_27241) goto l27242; else goto l27244;
    l27244: ;
        bool _27245;
        _27245 = c_27058 == 69;
        if (_27245) goto l27246; else goto l27248;
    l27248: ;
        goto l27062;
    l27246: ;
        *state_27065 = 10;
        goto l27062;
    l27242: ;
        *state_27065 = 7;
        goto l27062;
    l27061: ;
        *state_27065 = 6;
        goto l27062;
    l27062: ;
        int _27066;
        _27066 = *state_27065;
        int _27067;
        _27067 = _27066;
        bool _27068;
        _27068 = -1 != _27067;
        if (_27068) goto l27069; else goto l27236;
    l27236: ;
        goto l27110;
    l27069: ;
        int _27071;
        _27071 = *state_27065;
        int _27072;
        _27072 = _27071;
        bool _27073;
        _27073 = _27072 <= 4;
        if (_27073) goto l27074; else goto l27235;
    l27235: ;
        goto l27075;
    l27074: ;
        int _27231;
        _27231 = *state_27065;
        int _27233;
        _27233 = _27231;
        *matching_27051 = _27233;
        goto l27075;
    l27075: ;
        int _27225;
        _27225 = *pos_27049;
        int _27227;
        _27227 = _27225;
        int _27228;
        _27228 = 1 + _27227;
        *pos_27049 = _27228;
        goto l27077;
    l27077: ;
        int _27079;
        _27079 = *pos_27049;
        int _27080;
        _27080 = _27079;
        bool _27081;
        _27081 = _27080 < bdy_27046;
        if (_27081) goto l27082; else goto l27224;
    l27224: ;
        goto l27108;
    l27082: ;
        int _27084;
        _27084 = *pos_27049;
        int _27086;
        _27086 = _27084;
        unsigned char* _27087;
        _27087 = c_Input_27054 + _27086;
        unsigned char _27088;
        _27088 = *_27087;
        unsigned char _27095;
        _27095 = _27088;
        int _27096;
        union { int dst; unsigned char src; } u_27096;
        u_27096.src = _27095;
        _27096 = u_27096.dst;
        int _27090;
        _27090 = *state_27065;
        int tmp_state_27091;
        tmp_state_27091 = _27090;
        bool _27093;
        _27093 = tmp_state_27091 == 1;
        *state_27065 = -1;
        if (_27093) goto l27094; else goto l27158;
    l27158: ;
        bool _27159;
        _27159 = tmp_state_27091 == 2;
        if (_27159) goto l27160; else goto l27161;
    l27161: ;
        bool _27163;
        _27163 = tmp_state_27091 == 3;
        if (_27163) goto l27164; else goto l27165;
    l27165: ;
        bool _27166;
        _27166 = tmp_state_27091 == 4;
        if (_27166) goto l27167; else goto l27168;
    l27168: ;
        bool _27170;
        _27170 = tmp_state_27091 == 5;
        bool _27184;
        _27184 = _27096 == 69;
        bool _27178;
        _27178 = _27096 == 66;
        if (_27170) goto l27171; else goto l27189;
    l27189: ;
        bool _27190;
        _27190 = tmp_state_27091 == 6;
        if (_27190) goto l27191; else goto l27195;
    l27195: ;
        bool _27196;
        _27196 = tmp_state_27091 == 7;
        if (_27196) goto l27197; else goto l27202;
    l27202: ;
        bool _27206;
        _27206 = _27096 == 68;
        bool _27203;
        _27203 = tmp_state_27091 == 8;
        if (_27203) goto l27204; else goto l27211;
    l27211: ;
        bool _27212;
        _27212 = tmp_state_27091 == 9;
        if (_27212) goto l27213; else goto l27217;
    l27217: ;
        bool _27218;
        _27218 = tmp_state_27091 == 10;
        if (_27218) goto l27219; else goto l27223;
    l27223: ;
        goto l27102;
    l27219: ;
        if (_27206) goto l27220; else goto l27222;
    l27222: ;
        goto l27100;
    l27220: ;
        *state_27065 = 4;
        goto l27100;
    l27213: ;
        if (_27184) goto l27214; else goto l27216;
    l27216: ;
        goto l27100;
    l27214: ;
        *state_27065 = 3;
        goto l27100;
    l27204: ;
        if (_27206) goto l27207; else goto l27210;
    l27210: ;
        goto l27100;
    l27207: ;
        *state_27065 = 9;
        goto l27100;
    l27197: ;
        if (_27184) goto l27198; else goto l27201;
    l27201: ;
        goto l27100;
    l27198: ;
        *state_27065 = 8;
        goto l27100;
    l27191: ;
        if (_27178) goto l27192; else goto l27194;
    l27194: ;
        goto l27100;
    l27192: ;
        *state_27065 = 1;
        goto l27100;
    l27171: ;
        bool _27172;
        _27172 = _27096 == 65;
        if (_27172) goto l27173; else goto l27176;
    l27176: ;
        if (_27178) goto l27179; else goto l27182;
    l27182: ;
        if (_27184) goto l27185; else goto l27188;
    l27188: ;
        goto l27100;
    l27185: ;
        *state_27065 = 10;
        goto l27100;
    l27179: ;
        *state_27065 = 7;
        goto l27100;
    l27173: ;
        *state_27065 = 6;
        goto l27100;
    l27167: ;
        goto l27100;
    l27164: ;
        goto l27100;
    l27160: ;
        goto l27100;
    l27094: ;
        bool _27098;
        _27098 = _27096 == 71;
        if (_27098) goto l27099; else goto l27157;
    l27157: ;
        goto l27100;
    l27099: ;
        *state_27065 = 2;
        goto l27100;
    l27100: ;
        goto l27102;
    l27102: ;
        int _27104;
        _27104 = *state_27065;
        int _27105;
        _27105 = _27104;
        bool _27106;
        _27106 = _27105 == -1;
        if (_27106) goto l27107; else goto l27135;
    l27135: ;
        int _27136;
        _27136 = *state_27065;
        int _27137;
        _27137 = _27136;
        bool _27138;
        _27138 = _27137 <= 4;
        if (_27138) goto l27139; else goto l27152;
    l27152: ;
        goto l27140;
    l27139: ;
        int _27148;
        _27148 = *state_27065;
        int _27150;
        _27150 = _27148;
        *matching_27051 = _27150;
        goto l27140;
    l27140: ;
        int _27142;
        _27142 = *pos_27049;
        int _27144;
        _27144 = _27142;
        int _27145;
        _27145 = 1 + _27144;
        *pos_27049 = _27145;
        goto l27077;
    l27107: ;
        goto l27108;
    l27108: ;
        goto l27110;
    l27110: ;
        goto l27112;
    l27112: ;
        int _27114;
        _27114 = *start_27001;
        int _27115;
        _27115 = _27114;
        bool _27116;
        _27116 = _21953_26963 <= _27115;
        if (_27116) goto l27117; else goto l27119;
    l27119: ;
        int _27120;
        _27120 = *start_27001;
        int _27133;
        _27133 = 1 + lower_27038;
        int _27124;
        _27124 = _27120;
        int* _27125;
        _27125 = _21955_26965 + _27124;
        int _27122;
        _27122 = *matching_27051;
        int _27126;
        _27126 = _27122;
        *_27125 = _27126;
        int _27128;
        _27128 = *start_27001;
        int _27130;
        _27130 = _27128;
        int _27131;
        _27131 = 256 + _27130;
        *start_27001 = _27131;
        plower_27038 = _27133;
        goto l27036;
    l27117: ;
        return ;
    l27013: ;
        return ;
}

}