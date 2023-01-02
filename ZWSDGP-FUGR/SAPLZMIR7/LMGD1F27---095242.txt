*---------------------------------------------------------------------*
*       FORM MAKT_SET_SUB                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM MAKT_SET_SUB.

  CALL FUNCTION 'MAKT_SET_SUB'
       EXPORTING
            WMAKT  = MAKT
            MATNR  = RMMG1-MATNR
       TABLES
            WKTEXT = KTEXT.

ENDFORM.
