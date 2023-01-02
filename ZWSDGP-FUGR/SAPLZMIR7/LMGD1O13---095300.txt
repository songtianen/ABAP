*&---------------------------------------------------------------------*
*&      Module  ORG_BEZEICHNUNGEN_LESEN  OUTPUT
*&---------------------------------------------------------------------*
* Nachlesen Texte zu den Org-Ebenen aus zentralem Puffer               *
*----------------------------------------------------------------------*
MODULE ORG_BEZEICHNUNGEN_LESEN OUTPUT.

  CALL FUNCTION 'MAIN_PARAMETER_GET_ORG_TEXTE'
       IMPORTING
            WRMMG1_BEZ = RMMG1_BEZ.

ENDMODULE.                             " ORG_BEZEICHNUNGEN_LESEN  OUTPUT
