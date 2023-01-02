*----------------------------------------------------------------------*
***INCLUDE LMGD1OV0 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  SET_MATERIAL_FIXED  OUTPUT
*&---------------------------------------------------------------------*
* TF 4.6C Materialfixierung
*----------------------------------------------------------------------*
MODULE set_material_fixed OUTPUT.

*Fixationflag
  IF mara-matfi = 'X'.
    gv_icon_name = icon_locked.
    gv_icon_info = text-500.
    gv_add_stdinf = 'X'.
    CALL FUNCTION 'ICON_CREATE'
         EXPORTING
              name                  = gv_icon_name
              text                  = ' '
              info                  = gv_icon_info
              add_stdinf            = gv_add_stdinf
         IMPORTING
              result                = material_fixed
         EXCEPTIONS
              icon_not_found        = 1
              outputfield_too_short = 2
              OTHERS                = 3.
  ENDIF.

ENDMODULE.                             " SET_MATERIAL_FIXED  OUTPUT

ENHANCEMENT-POINT LMGD1OV0_01 SPOTS ES_LMGD1OV0 STATIC INCLUDE BOUND.

"{ Begin ENHO DIMP_GENERAL_LMGD1OV0 IS-A DIMP_GENERAL }
*&---------------------------------------------------------------------*
*&      Module  PREPARE_VARID  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE PREPARE_VARID OUTPUT.
  data: gv_guid type guid_16.
  data: gv_guid_ref type guid_16.
*<Begin of REM_MATERAILID>
*  data: gv_materialid like materialid.
*<End of REM_MATERAILID>

  if gv_varid_aktyp = space.
    sub_prog_varid = sy-repid.
    sub_dynp_varid = '0001'.
    exit.
  else.
    sub_prog_varid = 'SAPLBZID'.
    sub_dynp_varid = '1002'.
  endif.

  if mara-varid is initial and gv_varid_aktyp <> 'A'.
    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        EV_GUID_16       = gv_guid.
  else.
     gv_guid = rmara-varid.
  endif.

  gv_guid_ref = mara-varid.

  CALL FUNCTION 'BZID_TRANSMIT_GUID_NEW'
       EXPORTING
            appl               = '0001'
            AKTYP              = gv_varid_aktyp
            REF_GUID           = gv_guid_ref
       changing
            guid               = gv_guid
       EXCEPTIONS
            AKT_APPL_NOT_FOUND = 1
            OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDMODULE.                 " PREPARE_VARID  OUTPUT

"{ End ENHO DIMP_GENERAL_LMGD1OV0 IS-A DIMP_GENERAL }

ENHANCEMENT-POINT LMGD1OV0_02 SPOTS ES_LMGD1OV0 STATIC INCLUDE BOUND.


"{ Begin ENHO DIMP_GENERAL_LMGD1OV0 IS-A DIMP_GENERAL }
*&---------------------------------------------------------------------*
*&      Module  PREPARE_FELDAUSWAHL_VARID  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE PREPARE_FELDAUSWAHL_VARID OUTPUT.
  loop at screen.
    if screen-name = 'VARIABLE_OBJEKTID'.
      screen-input = 1.
      screen-active = 1.
      screen-output = 0.
      screen-required = 0.
      screen-intensified = 0.
      modify screen.
    endif.
  endloop.
ENDMODULE.                 " PREPARE_FELDAUSWAHL_VARID  OUTPUT

"{ End ENHO DIMP_GENERAL_LMGD1OV0 IS-A DIMP_GENERAL }


ENHANCEMENT-POINT LMGD1OV0_03 SPOTS ES_LMGD1OV0 STATIC INCLUDE BOUND.

"{ Begin ENHO DIMP_GENERAL_LMGD1OV0 IS-A DIMP_GENERAL }
*&---------------------------------------------------------------------*
*&      Module  SET_FELDAUSWAHL_VARID  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE SET_FELDAUSWAHL_VARID OUTPUT.
*TF Variable Objektidentifikation/46C2==================================
  read table fauswtab with key fname = 'VARIABLE_OBJEKTID'.
  if sy-subrc = 0.
    if fauswtab-kzinp = 0 or t130m-verar = 'PL'.
      gv_varid_aktyp = 'A'.
    else.
      gv_varid_aktyp = t130m-aktyp.
    endif.
    if fauswtab-kzinv = 1.
      gv_varid_aktyp = space.
    endif.
  endif.
*TF Variable Objektidentifikation/46C2==================================
ENDMODULE.                 " SET_FELDAUSWAHL_VARID  OUTPUT

"{ End ENHO DIMP_GENERAL_LMGD1OV0 IS-A DIMP_GENERAL }

ENHANCEMENT-POINT LMGD1OV0_04 SPOTS ES_LMGD1OV0 STATIC INCLUDE BOUND.

ENHANCEMENT-POINT LMGD1OV0_05 SPOTS ES_LMGD1OV0 STATIC INCLUDE BOUND.


ENHANCEMENT-POINT LMGD1OV0_06 SPOTS ES_LMGD1OV0 STATIC INCLUDE BOUND.
