*-----------------------------------------------------------------------
FORM MAKT_GET_SUB.

  CALL FUNCTION 'MAKT_GET_SUB'
       IMPORTING
            WMAKT  = MAKT
            XMAKT  = *MAKT
            YMAKT  = LMAKT
       TABLES
            WKTEXT = KTEXT
            XKTEXT = DKTEXT
            YKTEXT = LKTEXT.
ENDFORM.
