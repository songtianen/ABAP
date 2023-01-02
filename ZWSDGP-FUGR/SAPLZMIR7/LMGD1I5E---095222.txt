*----------------------------------------------------------------------*
*       Module  OKCODE_STEUERN                                         *
*----------------------------------------------------------------------*
MODULE OKCODE_STEUERN.

  IF NOT ST_BILDFLAG_OLD IS INITIAL AND
     ( RMMZU-OKCODE = FCODE_STFP OR
       RMMZU-OKCODE = FCODE_STPP OR
       RMMZU-OKCODE = FCODE_STNP OR
       RMMZU-OKCODE = FCODE_STLP  ).
    CLEAR RMMZU-OKCODE.
  ENDIF.
** change tc to 4.0 wk
*  if bildflag is initial.
  IF NOT FLG_TC IS INITIAL.
    ST_ERSTE_ZEILE = TC_STEUERN-TOP_LINE - 1.
    TC_STEUERN-LINES = ST_LINES.
    IF TC_STEUERN-TOP_LINE NE TC_STEUERN_TOP_LINE_BUF.
      PERFORM PARAM_SET.
    ENDIF.
  ENDIF.
*  endif.

  PERFORM OK_CODE_STEUERN.

ENDMODULE.                             " OKCODE_STEUERN
