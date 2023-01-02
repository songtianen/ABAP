*----------------------------------------------------------------------*
***INCLUDE LMGD1O20.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  DPP_MARA_MFRNR  OUTPUT
*&---------------------------------------------------------------------*
*       This module checks if the manufacturer is blocked. If it is
*       blocked and the user doesn't have auditor authorization, the
*       manufacturer and the parts number is initialized
*----------------------------------------------------------------------*
MODULE dpp_mara_mfrnr OUTPUT.

** start_EoP_adaptation
** Read back internal guideline note 1998910 before starting delivering a correction
  IF NOT cl_vs_switch_check=>cmd_vmd_cvp_ilm_sfw_01( ) IS INITIAL AND
     NOT mara-mfrnr                                    IS INITIAL.
    INCLUDE erp_cvp_mm_i3_c_trx0003 IF FOUND.
  ENDIF.
** end_EoP_adaptation

ENDMODULE.
