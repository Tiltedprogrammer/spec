/*
 *  Copyright 2011 Chen-Hsiung Liu, Lung-Sheng Chien, Cheng-Hung Lin,and Shih-Chieh Chang
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

// final states are ordered first
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include <vector>
#include <algorithm>

using namespace std ;

#include "../include/PFAC_P.h"

#define  PFAC_TABLE_MAP( i , j )   (i)*CHAR_SET + (j)

struct patternEle{
    char *patternString;
    int patternID;
};

struct pattern_cmp_functor{

    // pattern *s and *t are terminated by character '\n'
    // strict weak ordering
    // return true if the first argument goes before the second argument
    bool operator()( patternEle pattern_s, patternEle pattern_t ){
        unsigned s_char, t_char ;
        bool s_end, t_end ;
        char *s_sweep = pattern_s.patternString;
        char *t_sweep = pattern_t.patternString;

        while(1){
            s_char = *s_sweep++ ;
            t_char = *t_sweep++ ;
            s_end = ('\n' == s_char) ;
            t_end = ('\n' == t_char) ;

            if ( s_end || t_end ){ break ; }

            if (s_char < t_char){
                return true ;
            }else if ( s_char > t_char ){
                return false ;
            }
        }

        if ( s_end == t_end ){ // pattern s is the same as pattern t, the order is don't care
            return true ;
        }else if ( s_end ){ // pattern s is prefix of pattern t
            return true ;
        }else{
            return false ; // pattern t is prefix of pattern s
        }
    }

} ; 

/*
void printStringEndNewLine( char *s, FILE* fp )
{
    if ( '\n' == *s ) { return ; }
    fprintf(fp,"%c", '\"');
    while( 1 ){
        int ch = (unsigned char) *s++ ;
        if ( '\n' == ch ){ break ;}
        if ( (32 <= ch) && (126 >= ch) ){
            fprintf(fp,"%c", ch );
        }else{
            fprintf(fp,"%2.2x", ch );
        }
    }
    fprintf(fp,"%c", '\"');
}
*/


void printString( char *s, const int n, FILE* fp )
{
    fprintf(fp,"%c", '\"');
    for( int i = 0 ; i < n ; i++){
        int ch = (unsigned char) s[i] ;
        if ( (32 <= ch) && (126 >= ch) ){
            fprintf(fp,"%c", ch );
        }else{
            fprintf(fp,"%2.2x", ch );
        }        
    }
    fprintf(fp,"%c", '\"');
}



/*
 *  parse pattern file "patternFileName",
 *  (1) store all patterns in "patternPool" and
 *  (2) reorder the patterns according to lexicographic order and store
 *      reordered pointer in "rowPtr"
 *  (3) record original pattern ID in "patternID_table = *patternID_table_ptr"
 *  (4) record pattern length in "patternLen_table = *patternLen_table_ptr"
 *
 *  (5) *pattern_num_ptr = number of patterns
 *  (6) *max_state_num_ptr = estimation (upper bound) of total states in PFAC DFA
 *
 */
PFAC_status_t parsePatternFile( char *patternfilename,
    char ***rowPtr, char **valPtr, int **patternID_table_ptr, int **patternLen_table_ptr,
    int *max_state_num_ptr, int *pattern_num_ptr )
{
    if ( NULL == patternfilename ){
        return PFAC_STATUS_INVALID_PARAMETER ;
    }
    if ( NULL == rowPtr ){
        return PFAC_STATUS_INVALID_PARAMETER ;
    }
    if ( NULL == valPtr ){
        return PFAC_STATUS_INVALID_PARAMETER ;
    }
    if ( NULL == patternID_table_ptr ){
        return PFAC_STATUS_INVALID_PARAMETER ;
    }
    if ( NULL == patternLen_table_ptr ){
        return PFAC_STATUS_INVALID_PARAMETER ;
    }
    if ( NULL == max_state_num_ptr ){
        return PFAC_STATUS_INVALID_PARAMETER ;
    }
    if ( NULL == pattern_num_ptr ){
        return PFAC_STATUS_INVALID_PARAMETER ;
    }

    FILE* fpin = fopen(patternfilename, "rb");
    if (fpin == NULL) {
        PFAC_PRINTF("Error: Open pattern file %s failed.", patternfilename );
        return PFAC_STATUS_FILE_OPEN_ERROR ;
    }

    // step 1: find size of the file
    // obtain file size
    fseek (fpin , 0 , SEEK_END);
    int file_size = ftell (fpin);
    rewind (fpin);

    // step 2: allocate a buffer to contains all patterns
    *valPtr = (char*)malloc(sizeof(char)*file_size ) ;
    if ( NULL == *valPtr ){
        return PFAC_STATUS_ALLOC_FAILED ;
    }

    // copy the file into the buffer
    file_size = fread (*valPtr, 1, file_size, fpin);
    fclose(fpin);

    char *buffer = *valPtr ;
    vector< struct patternEle > rowIdxArray ;
    vector<int>  patternLenArray ;
    int len ;

    struct patternEle pEle;

    pEle.patternString = buffer ;
    pEle.patternID = 1 ;
 
    rowIdxArray.push_back(pEle) ;
    len = 0 ;
    for( int i = 0 ; i < file_size ; i++){
        if ( '\n' == buffer[i] ){
            if ( (i > 0) && ('\n' != buffer[i-1]) ){ // non-empty line
                patternLenArray.push_back(len);
                pEle.patternString = buffer + i + 1; // start of next pattern
                pEle.patternID = rowIdxArray.size()+1; // ID of next pattern
                rowIdxArray.push_back(pEle) ;
            }
            len = 0 ;
        }else{
            len++ ;
        }
    }

    *pattern_num_ptr = rowIdxArray.size() - 1 ;
    *max_state_num_ptr = file_size + 1 ;

    // rowIdxArray.size()-1 = number of patterns
    // sort patterns by lexicographic order
    sort(rowIdxArray.begin(), rowIdxArray.begin()+*pattern_num_ptr, pattern_cmp_functor() ) ;

    *rowPtr = (char**) malloc( sizeof(char*)*rowIdxArray.size() ) ;
    *patternID_table_ptr = (int*) malloc( sizeof(int)*rowIdxArray.size() ) ;
    // suppose there are k patterns, then size of patternLen_table is k+1
    // because patternLen_table[0] is useless, valid data starts from
    // patternLen_table[1], up to patternLen_table[k]
    *patternLen_table_ptr = (int*) malloc( sizeof(int)*rowIdxArray.size() ) ;
    if ( ( NULL == *rowPtr ) ||
         ( NULL == *patternID_table_ptr ) ||
         ( NULL == *patternLen_table_ptr ) )
    {
        return PFAC_STATUS_ALLOC_FAILED ;
    }

    // step 5: compute f(final state) = patternID
    for( int i = 0 ; i < (rowIdxArray.size()-1) ; i++){
        (*rowPtr)[i] = rowIdxArray[i].patternString ;
        (*patternID_table_ptr)[i] = rowIdxArray[i].patternID ; // pattern number starts from 1
    }

    // although patternLen_table[0] is useless, in order to avoid errors from valgrind
    // we need to initialize patternLen_table[0]
    (*patternLen_table_ptr)[0] = 0 ;
    for( int i = 0 ; i < (rowIdxArray.size()-1) ; i++){
        // pattern (*rowPtr)[i] is terminated by character '\n'
        // pattern ID starts from 1, so patternID = i+1
        (*patternLen_table_ptr)[i+1] = patternLenArray[i] ;
    }

    return PFAC_STATUS_SUCCESS ;
}


int lookup(vector< vector<TableEle> > &table, const int state, const int ch )
{
    if (state >= table.size() ) { return TRAP_STATE ;}
    for(int j = 0 ; j < table[state].size() ; j++){
        TableEle ele = table[state][j];
        if ( ch == ele.ch ){
            return ele.nextState ;	
        }	
    }
    return TRAP_STATE ;
}

/*
 *  Given k = pattern_number patterns in rowPtr[0:k-1] with lexicographic order and
 *  patternLen_table[1:k], patternID_table[0:k-1]
 *
 *  user specified a initial state "initial_state",
 *  construct
 *  (1) PFAC_table: DFA of PFAC with k final states labeled from 1:k
 *
 *  WARNING: initial_state = k+1
 */
PFAC_status_t create_PFACTable_spaceDriven(const char** rowPtr, const int *patternLen_table, const int *patternID_table,
    const int max_state_num,
    const int pattern_num, const int initial_state, const int baseOfUsableStateID, 
    int *state_num_ptr,
    vector< vector<TableEle> > &PFAC_table )
{
    int state ;
    int state_num ;

    PFAC_table.clear();
    PFAC_table.reserve( max_state_num );
    vector< TableEle > empty_row ;
    for(int i = 0 ; i < max_state_num ; i++){   
        PFAC_table.push_back( empty_row );
    }
    
    PFAC_PRINTF("initial state : %d\n", initial_state);

    state = initial_state; // state is current state
    //state_num = initial_state + 1; // state_num: usable state
    state_num = baseOfUsableStateID ;

    for ( int p_idx = 0 ; p_idx < pattern_num ; p_idx++ ) {
        char *pos = (char*) rowPtr[p_idx] ;
        int  patternID = patternID_table[p_idx];
        int  len = patternLen_table[patternID] ;

/*
        printf("pid = %d, length = %d, ", patternID, len );
        printStringEndNewLine( pos, stdout );
        printf("\n");
*/

        for( int offset = 0 ; offset < len  ; offset++ ){
            int ch = (unsigned char) pos[offset];
            assert( '\n' != ch ) ;

            if ( (len-1) == offset ) { // finish reading a pattern
                TableEle ele ;
                ele.ch = ch ;
                ele.nextState = patternID ; // patternID is id of final state
                PFAC_table[state].push_back(ele); //PFAC_table[ PFAC_TABLE_MAP(state,ch) ] = patternID; 
                state = initial_state;
            }
            else {
                int nextState = lookup(PFAC_table, state, ch );
                if (TRAP_STATE == nextState ) {
                    TableEle ele ;
                    ele.ch = ch ;
                    ele.nextState = state_num ;
                    PFAC_table[state].push_back(ele); // PFAC_table[PFAC_TABLE_MAP(state,ch)] = state_num;
                    state = state_num; // go to next state
                    state_num = state_num + 1; // next available state
                }
                else {
                    // match prefix of previous pattern
                    // state = PFAC_table[PFAC_TABLE_MAP(state,ch)]; // go to next state
                    state = nextState ;
                }
            }

            if (state_num > max_state_num) {
                PFAC_PRINTF("Error: State number overflow, state no=%d, max_state_num=%d\n", state_num, max_state_num );
                return PFAC_STATUS_INTERNAL_ERROR ;
            }
        }  // while
    }  // for each pattern

    PFAC_PRINTF("The number of state is %d\n", state_num);

    *state_num_ptr = state_num ;

    return PFAC_STATUS_SUCCESS ;
}




int dump_reorderPattern(char** rowPtr, int *patternID_table, int *patternLen_table,
    const int pattern_num, char *fileName )
{
    if ( NULL == rowPtr ){
        return -1 ;
    }
    if ( NULL == patternID_table ){
        return -1 ;
    }
    if ( NULL == patternLen_table ){
        return -1 ;
    }
    if ( NULL == fileName ) {
        return -1 ;
    }

    FILE *fp = fopen( fileName, "w") ;
    if( NULL == fp ) {
        return -1 ;
    }

    fprintf(fp, "#### [original pattern ID]: [ordered patterns] \n");
    for ( int fs = 0 ; fs < pattern_num ; fs++) {
        char *pos = rowPtr[fs] ;
        int patternID = patternID_table[fs] ;
        int len = patternLen_table[patternID] ;
        fprintf(fp, "%6d :", patternID);
        //printStringEndNewLine( pos, fp ) ;
        printString( pos, len, fp );
        fprintf(fp,"\n");
    }

    vector< char* >  original_patterns( pattern_num ) ;
    for ( int fs = 0 ; fs < pattern_num ; fs++) {
        int patternID = patternID_table[fs] ;
        original_patterns[patternID-1] = rowPtr[fs] ;
    }

    fprintf(fp, "#### [original pattern ID], [length of patterns]:[patterns] \n");
    for ( int i = 0 ; i < pattern_num ; i++) {
        // patternLen_table[0] is useless because patternID starts from 1
        char *pos = original_patterns[i] ;
        int patternID = i+1 ;
        int len = patternLen_table[patternID] ;
        fprintf(fp, "%5d, %5d :", patternID, len );
        //printStringEndNewLine( pos, fp ) ;
        printString( pos, len, fp );
        fprintf(fp,"\n");
    }

    fclose(fp) ;

    return 0 ;
}
