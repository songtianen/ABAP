************************************************************
* Include LMGD1FYY
************************************************************
FORM MAIN_PARAMETER_GET.

     CALL FUNCTION 'MAIN_PARAMETER_GET'
          IMPORTING
               NEUFLAG       =  NEUFLAG
               FLGNUMINT     =  FLGNUMINT
               FLGDARK       =  FLGDARK
*              flg_cad_aktiv =  flg_cad_aktiv mk/4.0A in RMMG2 integr.
               WRMMG1        =  RMMG1
               WRMMG2        =  RMMG2
               WRMMG1_REF    =  RMMG1_REF
               WRMMG1_BEZ    =  RMMG1_BEZ
               WRMMZU        =  RMMZU
               WT130M        =  T130M
               WT133S        =  T133S
               WT134         =  T134
               AKTVSTATUS    =  AKTVSTATUS
               TRANSSTATUS   =  TRANSTATUS
               SPERRMODUS    =  SPERRMODUS
               BILDSEQUENZ   =  BILDSEQUENZ
               BISSTATUS     =  BISSTATUS
               WT001W        =  T001W
               REF_BISSTATUS =  REF_BISSTATUS
               REF_MARA      =  RMARA
               REF_MAKT      =  RMAKT
               REF_MARC      =  RMARC
               REF_MARD      =  RMARD
               REF_MBEW      =  RMBEW
               REF_MVKE      =  RMVKE
               REF_MLGN      =  RMLGN
               REF_MLGT      =  RMLGT
               REF_MPGD      =  RMPGD
               REF_VPBME     =  RVPBME
               REF_MFHM      =  RMFHM
               REF_MPOP      =  RMPOP
               REF_MYMS      =  RMYMS
               T001_WAERS    =  T001-WAERS
               RT001_WAERS   =  *T001-WAERS
               T001_PERIV    =  T001-PERIV
          TABLES
               MTAB          =  PTAB
               RPTAB         =  RPTAB
               RED_STAT      =  RED_STAT
               BILDTAB       =  BILDTAB
               REFTAB        =  REFTAB
               REF_STEUERTAB =  RSTEUERTAB
               REF_STEUMMTAB =  RSTEUMMTAB
               REF_MEINH     =  RMEINH
               REF_KTEXT     =  RKTEXT.

ENHANCEMENT-POINT LMGD1F2E_01 SPOTS ES_LMGD1F2E INCLUDE BOUND.

ENDFORM.
