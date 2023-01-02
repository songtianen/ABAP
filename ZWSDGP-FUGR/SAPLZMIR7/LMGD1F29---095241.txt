*---------------------------------------------------------------------*
*       FORM MARM_GET_SUB                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM MARM_GET_SUB.

  CALL FUNCTION 'MARM_GET_SUB'
       TABLES
            WMEINH = MEINH
            XMEINH = DMEINH
            YMEINH = LMEINH.

* AHE: 19.10.95
* zus. EANs werden immer zusammen mit den Mengeneinheiten behandelt;
  CALL FUNCTION 'MEAN_GET_SUB'
       TABLES
            WMEAN  = MEAN_ME_TAB
            XMEAN  = DMEAN_ME_TAB
            YMEAN  = LMEAN_ME_TAB.

ENDFORM.
