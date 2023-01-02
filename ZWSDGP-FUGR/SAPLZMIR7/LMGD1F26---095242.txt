*---------------------------------------------------------------------*
*       FORM MARM_SET_SUB                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM MARM_SET_SUB.

  CALL FUNCTION 'MARM_SET_SUB'
       EXPORTING
            MATNR  = RMMG1-MATNR
       TABLES
            WMEINH = MEINH.

* AHE: 19.10.95
* zus. EANs werden immer zusammen mit den Mengeneinheiten behandelt;
  CALL FUNCTION 'MEAN_SET_SUB'
       EXPORTING
            MATNR  = RMMG1-MATNR
       TABLES
            WMEAN  = MEAN_ME_TAB.

ENDFORM.
