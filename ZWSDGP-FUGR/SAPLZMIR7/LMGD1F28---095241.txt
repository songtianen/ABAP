*---------------------------------------------------------------------*
*       FORM MLAN_GET_SUB                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM MLAN_GET_SUB.

  CALL FUNCTION 'MLAN_GET_SUB'
       TABLES
            WSTEUERTAB = STEUERTAB
            XSTEUERTAB = DSTEUERTAB
            YSTEUERTAB = LSTEUERTAB
            WSTEUMMTAB = STEUMMTAB
            XSTEUMMTAB = DSTEUMMTAB
            YSTEUMMTAB = LSTEUMMTAB.

ENDFORM.
