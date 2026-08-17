#include <math.h>
/*
// truncation
double bit_trunc(double dfFLT, int  nTRUNC_BITS)
{
    if(nTRUNC_BITS < 0){
        return dfFLT;
    }
    else if (nTRUNC_BITS == 0){
        return (double) floor(dfFLT);
    }
    double dfPWR, dfINT_TMP, dfFLT_TMP, dfTRUNC_NUM;

    dfINT_TMP = (double) floor(dfFLT);
    dfFLT_TMP = dfFLT - dfINT_TMP;
    dfPWR =(double) pow(2.0,(double) nTRUNC_BITS);
    dfFLT_TMP = (double) floor(dfFLT_TMP * dfPWR);
    dfFLT_TMP /= dfPWR;
    dfTRUNC_NUM = dfINT_TMP + dfFLT_TMP;
    return(dfTRUNC_NUM);
}	// end of trunc
*/
double bit_trunc(double dfFLT, int nTRUNC_BITS)
{
    if (nTRUNC_BITS < 0) return dfFLT;
    if (nTRUNC_BITS == 0) return floor(dfFLT);
    double dfPWR = pow(2.0, (double)nTRUNC_BITS);
    return floor(dfFLT * dfPWR) / dfPWR;   // ???????????? ??????? floor(v) ????
}