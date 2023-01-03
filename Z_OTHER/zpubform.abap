*&---------------------------------------------------------------------*
*& Modulpool  ZPUBFORM
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
PROGRAM ZPUBFORM.
TYPE-POOLS:ESP1,SLIS,CXTAB.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
DATA:BEGIN OF CS15_OUT OCCURS 0,
       TMATNR LIKE MARA-MATNR,                    "物料编码
       STUFE  LIKE STPOX-STUFE,                    "展开层级
       MATNR  LIKE MARA-MATNR,                     "上层物料编码
       STLALS LIKE MDMFDBID-NAME,                     "可选BOMs
     END OF CS15_OUT.
*BDC录屏
FORM BDC_DYNPRO  TABLES OUTBDCDATA STRUCTURE BDCDATA USING PROGRAM DYNPRO.
  CLEAR OUTBDCDATA.
  OUTBDCDATA-PROGRAM  = PROGRAM.
  OUTBDCDATA-DYNPRO   = DYNPRO.
  OUTBDCDATA-DYNBEGIN = 'X'.
  APPEND OUTBDCDATA.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
FORM BDC_FIELD TABLES OUTBDCDATA STRUCTURE BDCDATA USING FNAM FVAL.
  CLEAR OUTBDCDATA.
  OUTBDCDATA-FNAM = FNAM.
  OUTBDCDATA-FVAL = FVAL.
  APPEND OUTBDCDATA.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
FORM BDCFM TABLES OUTBDCDATA STRUCTURE BDCDATA
  OUTRET STRUCTURE BAPIRET2
USING TCODE MODE.
  DATA:OPT     TYPE CTU_PARAMS,
       MESSTAB TYPE TABLE OF BDCMSGCOLL WITH HEADER LINE.
  OPT-DISMODE = MODE.
  OPT-DEFSIZE = 'X'.
  OPT-UPDMODE = 'S'.
  OPT-RACOMMIT = 'X'.

  CALL TRANSACTION TCODE USING OUTBDCDATA OPTIONS FROM OPT MESSAGES INTO MESSTAB.
  PERFORM BDCTOBAPI TABLES MESSTAB OUTRET.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*跳转程序/视图/事务码(INTYPE=T/V/P/F-事务码/视图/程序/函数)
FORM CALLPROG USING INPUT INTYPE.
  DATA:TCODE            TYPE SY-TCODE,
       I_TAB            TYPE SE16N_TAB,
       VIEWNAME         TYPE DD02V-TABNAME,
       VIEWCLUSTER_NAME TYPE VCLDIR-VCLNAME.
  DATA:P_WB_REQUEST     TYPE REF TO CL_WB_REQUEST,
       P_WB_REQUEST_SET TYPE SWBM_WB_REQUEST_SET,
       P_OBJECT_NAME    TYPE SEU_OBJKEY.
  CLEAR:P_OBJECT_NAME,P_WB_REQUEST,P_WB_REQUEST_SET.

  CASE INTYPE.
    WHEN 'B'.
      I_TAB = INPUT.
      CALL FUNCTION 'SE16N_START'
        EXPORTING
          I_TAB              = I_TAB
          I_DISPLAY          = 'X'
          I_SINGLE_TABLE     = 'X'
          I_EXIT_SELFIELD_FB = 'X'.
    WHEN 'T'.
      TCODE = INPUT.
      CALL FUNCTION 'ABAP4_CALL_TRANSACTION'
        EXPORTING
          TCODE                   = TCODE
        EXCEPTIONS
          CALL_TRANSACTION_DENIED = 1
          TCODE_INVALID           = 2
          OTHERS                  = 3.
    WHEN 'V'.
      VIEWNAME = INPUT.
      VIEWCLUSTER_NAME = INPUT.
*判断是维护视图还是视图簇
      SELECT SINGLE COUNT(*)
        FROM TVDIR
        WHERE TABNAME = VIEWNAME.
      IF SY-SUBRC EQ 0.
        CALL FUNCTION 'VIEW_MAINTENANCE_CALL'
          EXPORTING
            ACTION                       = 'S'
            VIEW_NAME                    = VIEWNAME
          EXCEPTIONS
            CLIENT_REFERENCE             = 1
            FOREIGN_LOCK                 = 2
            INVALID_ACTION               = 3
            NO_CLIENTINDEPENDENT_AUTH    = 4
            NO_DATABASE_FUNCTION         = 5
            NO_EDITOR_FUNCTION           = 6
            NO_SHOW_AUTH                 = 7
            NO_TVDIR_ENTRY               = 8
            NO_UPD_AUTH                  = 9
            ONLY_SHOW_ALLOWED            = 10
            SYSTEM_FAILURE               = 11
            UNKNOWN_FIELD_IN_DBA_SELLIST = 12
            VIEW_NOT_FOUND               = 13
            MAINTENANCE_PROHIBITED       = 14
            OTHERS                       = 15.
        EXIT.
      ENDIF.
      SELECT SINGLE COUNT(*)
        FROM VCLDIR
        WHERE VCLNAME = VIEWCLUSTER_NAME.
      IF SY-SUBRC EQ 0.
        CALL FUNCTION 'VIEWCLUSTER_MAINTENANCE_CALL'
          EXPORTING
            VIEWCLUSTER_NAME             = VIEWCLUSTER_NAME
            MAINTENANCE_ACTION           = 'S'
          EXCEPTIONS
            CLIENT_REFERENCE             = 1
            FOREIGN_LOCK                 = 2
            VIEWCLUSTER_NOT_FOUND        = 3
            VIEWCLUSTER_IS_INCONSISTENT  = 4
            MISSING_GENERATED_FUNCTION   = 5
            NO_UPD_AUTH                  = 6
            NO_SHOW_AUTH                 = 7
            OBJECT_NOT_FOUND             = 8
            NO_TVDIR_ENTRY               = 9
            NO_CLIENTINDEP_AUTH          = 10
            INVALID_ACTION               = 11
            SAVING_CORRECTION_FAILED     = 12
            SYSTEM_FAILURE               = 13
            UNKNOWN_FIELD_IN_DBA_SELLIST = 14
            MISSING_CORR_NUMBER          = 15
            OTHERS                       = 16.
      ENDIF.

    WHEN 'P'.
      SUBMIT (INPUT) VIA SELECTION-SCREEN AND RETURN.
    WHEN 'F'.
      P_OBJECT_NAME = INPUT.

      CALL METHOD CL_WB_REQUEST=>CREATE_FROM_FCODE
        EXPORTING
          P_FCODE             = 'WB_EXEC'
          P_OBJECT_TYPE       = 'FF'
          P_OBJECT_NAME       = P_OBJECT_NAME
*         P_OBJECT_STATE      =
        RECEIVING
          P_WB_REQUEST        = P_WB_REQUEST
        EXCEPTIONS
          ILLEGAL_OBJECT_TYPE = 1
          ILLEGAL_OPERATION   = 2
          CANCELLED           = 3
          OTHERS              = 4.
      IF SY-SUBRC <> 0.
        MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
                   WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

      APPEND P_WB_REQUEST TO P_WB_REQUEST_SET.
      CLASS CL_WB_STARTUP DEFINITION LOAD.
      CALL METHOD CL_WB_STARTUP=>START
        EXPORTING
          P_WB_REQUEST_SET         = P_WB_REQUEST_SET
        EXCEPTIONS
          MANAGER_NOT_YET_RELEASED = 1.
  ENDCASE.

ENDFORM.                    "CALLPROG
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
* 设置后台JOB(单步骤，非周期单次JOB)
*传入程序名，约定日期时间（立即执行则不填）
FORM SETJOB TABLES INSELTAB STRUCTURE RSPARAMS
USING INREPID STARTDATE STARTTIME
CHANGING OUTFLAG TYPE BAPI_MTYPE.
  DATA:JOBNAME         LIKE TBTCJOB-JOBNAME,
       JOBNUMBER       LIKE TBTCJOB-JOBCOUNT,
       REPID           TYPE SY-CPROG,
       MSG             TYPE BAPI_MSG,
       WA_TBTCO        TYPE TBTCO,
       ANSWER          TYPE CHAR1,
       SELECTION_TABLE TYPE TABLE OF RSPARAMS WITH HEADER LINE.

  IF INREPID IS NOT INITIAL.
    SORT INSELTAB BY SELNAME.
*获取JOB号
    CONCATENATE INREPID '_SETJOB' INTO JOBNAME.
    REPID = INREPID.
    SELECT SINGLE *
    INTO WA_TBTCO
    FROM TBTCO
    WHERE JOBNAME = JOBNAME
    AND   STATUS IN ('R','S').
    IF SY-SUBRC = 0.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          TEXT_QUESTION = '存在通过本程序设定的活动中/已释放的后台JOB，是否继续？'
          TEXT_BUTTON_1 = '是'
          TEXT_BUTTON_2 = '否'
        IMPORTING
          ANSWER        = ANSWER.
      IF ANSWER NE '1'.
        MSG = '已取消设置JOB'.
        MESSAGE E000(OO) WITH MSG.
        OUTFLAG = 'E'.
        RETURN.
      ENDIF.
    ENDIF.
    CALL FUNCTION 'JOB_OPEN'
      EXPORTING
        JOBNAME          = JOBNAME
      IMPORTING
        JOBCOUNT         = JOBNUMBER
      EXCEPTIONS
        CANT_CREATE_JOB  = 1
        INVALID_JOB_DATA = 2
        JOBNAME_MISSING  = 3
        OTHERS           = 4.
    IF SY-SUBRC EQ 0.
*获取被调用程序选择屏幕
      CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
        EXPORTING
          CURR_REPORT     = REPID
        TABLES
          SELECTION_TABLE = SELECTION_TABLE
        EXCEPTIONS
          NOT_FOUND       = 1
          NO_REPORT       = 2
          OTHERS          = 3.
      IF INSELTAB[] IS NOT INITIAL.
        LOOP AT SELECTION_TABLE.
          READ TABLE INSELTAB WITH KEY SELNAME = SELECTION_TABLE-SELNAME BINARY SEARCH.
          IF SY-SUBRC = 0.
            SELECTION_TABLE-SIGN = INSELTAB-SIGN.
            SELECTION_TABLE-OPTION = INSELTAB-OPTION.
            SELECTION_TABLE-LOW = INSELTAB-LOW.
            SELECTION_TABLE-HIGH = INSELTAB-HIGH.
          ENDIF.
          MODIFY SELECTION_TABLE.
          CLEAR SELECTION_TABLE.
        ENDLOOP.
      ENDIF.

*JOB方式调用
      SUBMIT (REPID)
      WITH SELECTION-TABLE SELECTION_TABLE
      VIA JOB JOBNAME
      NUMBER  JOBNUMBER
      AND RETURN.
      IF SY-SUBRC = 0.
*释放
        IF STARTDATE IS NOT INITIAL AND STARTTIME IS NOT INITIAL.
          CALL FUNCTION 'JOB_CLOSE' "约定时间
            EXPORTING
              JOBCOUNT             = JOBNUMBER
              JOBNAME              = JOBNAME
              SDLSTRTDT            = STARTDATE
              SDLSTRTTM            = STARTTIME
            EXCEPTIONS
              CANT_START_IMMEDIATE = 1
              INVALID_STARTDATE    = 2
              JOBNAME_MISSING      = 3
              JOB_CLOSE_FAILED     = 4
              JOB_NOSTEPS          = 5
              JOB_NOTEX            = 6
              LOCK_FAILED          = 7
              OTHERS               = 8.
        ELSE.
          CALL FUNCTION 'JOB_CLOSE' "立即
            EXPORTING
              JOBCOUNT             = JOBNUMBER
              JOBNAME              = JOBNAME
              STRTIMMED            = 'X'
            EXCEPTIONS
              CANT_START_IMMEDIATE = 1
              INVALID_STARTDATE    = 2
              JOBNAME_MISSING      = 3
              JOB_CLOSE_FAILED     = 4
              JOB_NOSTEPS          = 5
              JOB_NOTEX            = 6
              LOCK_FAILED          = 7
              OTHERS               = 8.
        ENDIF.


        IF SY-SUBRC = 0.
          OUTFLAG = 'S'.
          CLEAR MSG.
          CONCATENATE '后台JOB' JOBNAME  JOBNUMBER '设置成功!'
          INTO MSG SEPARATED BY '/'.
          MESSAGE S000(OO) WITH MSG  DISPLAY LIKE 'S'.
        ELSE.
          OUTFLAG = 'E'.
        ENDIF.
      ELSE.
        OUTFLAG = 'E'.
      ENDIF.
    ELSE.
      OUTFLAG = 'E'.
    ENDIF.
  ELSE.
    OUTFLAG = 'E'.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*BDC消息转化为BAPIRET2结构
FORM BDCTOBAPI TABLES INMESSTAB STRUCTURE BDCMSGCOLL
  OUTBAPI STRUCTURE BAPIRET2.
  CALL FUNCTION 'CONVERT_BDCMSGCOLL_TO_BAPIRET2'
    TABLES
      IMT_BDCMSGCOLL = INMESSTAB
      EXT_RETURN     = OUTBAPI.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*展示消息*多条消息显示到窗口
FORM SHOWMSG TABLES INBAPI STRUCTURE BAPIRET2.
  CALL FUNCTION 'SUSR_DISPLAY_LOG'
    EXPORTING
      DISPLAY_IN_POPUP = 'X'
    TABLES
      IT_LOG_BAPIRET2  = INBAPI
    EXCEPTIONS
      PARAMETER_ERROR  = 1
      OTHERS           = 2.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*填入消息
FORM INMSG TABLES OUTMSG STRUCTURE BAPIRET2
USING  ID TYPE SY-MSGID
      TYPE TYPE SY-MSGTY
      NO
      MSG1
      MSG2
      MSG3
      MSG4.
  DATA:MSGID TYPE SY-MSGID,
       MSGNR TYPE SY-MSGNO,
       MSGV1 TYPE SY-MSGV1,
       MSGV2 TYPE SY-MSGV2,
       MSGV3 TYPE SY-MSGV3,
       MSGV4 TYPE SY-MSGV4.
  DATA:WA_RETURN TYPE BAPIRET2.
  CLEAR WA_RETURN.
  IF ID IS INITIAL.
    MSGID = 'OO'.
    MSGNR = 000.
  ELSE.
    MSGID = ID.
    MSGNR = NO.
  ENDIF.
  MSGV1 = MSG1.
  MSGV2 = MSG2.
  MSGV3 = MSG3.
  MSGV4 = MSG4.

  CALL FUNCTION 'BALW_BAPIRETURN_GET2'
    EXPORTING
      TYPE   = TYPE
      CL     = MSGID
      NUMBER = MSGNR
      PAR1   = MSGV1
      PAR2   = MSGV2
      PAR3   = MSGV3
      PAR4   = MSGV4
    IMPORTING
      RETURN = WA_RETURN
    EXCEPTIONS
      OTHERS = 1.

  APPEND WA_RETURN TO OUTMSG.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将消息号转化为文本（若不填写消息类，则转换系统消息）
FORM MSGTOTEXT USING ID NO MSG1 MSG2 MSG3 MSG4 CHANGING MSG.
  DATA:MSGID TYPE SY-MSGID,
       MSGNR TYPE SY-MSGNO,
       MSGV1 TYPE SY-MSGV1,
       MSGV2 TYPE SY-MSGV2,
       MSGV3 TYPE SY-MSGV3,
       MSGV4 TYPE SY-MSGV4.
  CLEAR MSG.
  IF ID IS NOT INITIAL.
    MSGID = ID.
    MSGNR = NO.
    MSGV1 = MSG1.
    MSGV2 = MSG2.
    MSGV3 = MSG3.
    MSGV4 = MSG4.
  ELSE.
    MSGID = SY-MSGID.
    MSGNR = SY-MSGNO.
    MSGV1 = SY-MSGV1.
    MSGV2 = SY-MSGV2.
    MSGV3 = SY-MSGV3.
    MSGV4 = SY-MSGV4.
  ENDIF.
  CALL FUNCTION 'MESSAGE_TEXT_BUILD'
    EXPORTING
      MSGID               = MSGID
      MSGNR               = MSGNR
      MSGV1               = MSGV1
      MSGV2               = MSGV2
      MSGV3               = MSGV3
      MSGV4               = MSGV4
    IMPORTING
      MESSAGE_TEXT_OUTPUT = MSG
    EXCEPTIONS
      OTHERS              = 1.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
FORM LOCKREPORT USING REPID.
  CALL FUNCTION 'ENQUEUE_ESRDIRE'
    EXPORTING
      NAME           = REPID
      _SCOPE         = '1'
    EXCEPTIONS
      FOREIGN_LOCK   = 1
      SYSTEM_FAILURE = 2
      OTHERS         = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*外部单位转化为内部（PC->ST,套->）
FORM TRANSUNIT_TO_INSIDE CHANGING MEINS.
  PERFORM TRANSDATA USING 'MARA' 'MEINS' 'IN' MEINS
  CHANGING MEINS.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*内部转化为外部
FORM TRANSUNIT_TO_OUTSIDE CHANGING MEINS.
  PERFORM TRANSDATA USING 'MARA' 'MEINS' 'OUT' MEINS
  CHANGING MEINS.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
FORM ADDZERO_MATNR CHANGING MATNR.
  PERFORM TRANSDATA USING 'MARA' 'MATNR' 'IN' MATNR
  CHANGING MATNR.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
FORM ADDZERO CHANGING INPUT.
  PERFORM TRANSDATA USING '' 'ZERO' 'IN' INPUT
  CHANGING INPUT.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
FORM DELZERO CHANGING INPUT.
  PERFORM TRANSDATA USING '' 'ZERO' 'OUT' INPUT
  CHANGING INPUT.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*内外码数值转换(字段为ZERO时，直接补0)
FORM TRANSDATA USING INTABNAM INDOMA INTYPE INPUT
CHANGING OUTPUT.
  DATA:WA_DD01L  TYPE DD01L,
       FMNAME    TYPE RS38L_FNAM,
       NAME      TYPE DDOBJNAME,
       DD03P_TAB TYPE STANDARD TABLE OF DD03P WITH HEADER LINE.

  CHECK INDOMA IS NOT INITIAL.
  CHECK INTYPE IS NOT INITIAL.
  CHECK INPUT IS NOT INITIAL.
  NAME = INTABNAM.

  CASE INDOMA.
    WHEN 'ZERO'.
      CASE INTYPE.
        WHEN 'IN'.
          FMNAME = 'CONVERSION_EXIT_ALPHA_INPUT'.
        WHEN 'OUT'.
          FMNAME = 'CONVERSION_EXIT_ALPHA_OUTPUT'.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    WHEN 'MEINS'.
      CASE INTYPE.
        WHEN 'IN'.
          FMNAME = 'CONVERSION_EXIT_CUNIT_INPUT'.
        WHEN 'OUT'.
          FMNAME = 'CONVERSION_EXIT_CUNIT_OUTPUT'.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    WHEN 'MATNR'.
      CASE INTYPE.
        WHEN 'IN'.
          FMNAME = 'CONVERSION_EXIT_MATN1_INPUT'.
        WHEN 'OUT'.
          FMNAME = 'CONVERSION_EXIT_MATN1_OUTPUT'.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
    WHEN OTHERS.
      CALL FUNCTION 'DDIF_TABL_GET'
        EXPORTING
          NAME          = NAME
        TABLES
          DD03P_TAB     = DD03P_TAB
        EXCEPTIONS
          ILLEGAL_INPUT = 1
          OTHERS        = 2.
      IF SY-SUBRC NE 0.
        MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
        WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      IF DD03P_TAB[] IS INITIAL.
        MESSAGE E000(OO) WITH '未获取到表结构'.
        RETURN.
      ENDIF.
      SORT DD03P_TAB BY TABNAME FIELDNAME.
      READ TABLE DD03P_TAB WITH KEY TABNAME = INTABNAM
      FIELDNAME = INDOMA
      BINARY SEARCH.
      IF SY-SUBRC NE 0.
        MESSAGE E000(OO) WITH '表中无此字段'.
        RETURN.
      ENDIF.
      SELECT SINGLE *
      INTO WA_DD01L
      FROM DD01L
      WHERE DOMNAME = DD03P_TAB-DOMNAME
      AND   AS4LOCAL = 'A'.
      IF SY-SUBRC NE 0.
        RETURN.
      ENDIF.

      CASE INTYPE.
        WHEN 'IN'.
          CONCATENATE 'CONVERSION_EXIT_'
          WA_DD01L-CONVEXIT
          '_INPUT'
          INTO FMNAME.
        WHEN 'OUT'.
          CONCATENATE 'CONVERSION_EXIT_'
          WA_DD01L-CONVEXIT
          '_OUTPUT'
          INTO FMNAME.
        WHEN OTHERS.
          RETURN.
      ENDCASE.
  ENDCASE.

  CALL FUNCTION FMNAME
    EXPORTING
      INPUT        = INPUT
    IMPORTING
      OUTPUT       = OUTPUT
    EXCEPTIONS
      LENGTH_ERROR = 1
      OTHERS       = 2.
  IF SY-SUBRC NE 0.
    MESSAGE ID SY-MSGID TYPE 'S' NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*字符串长度
FORM LENGTH USING LV_CHAR CHANGING LV_LEN.
  CALL METHOD CL_ABAP_LIST_UTILITIES=>DYNAMIC_OUTPUT_LENGTH
    EXPORTING
      FIELD = LV_CHAR
    RECEIVING
      LEN   = LV_LEN.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取表/结构
FORM GETFIELDCAT USING INTABNAME TYPE TABNAME CHANGING CT_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV.
  DATA:IT_DD03T  TYPE TABLE OF DD03T WITH HEADER LINE,
       IT_DD03L  TYPE TABLE OF DD03L WITH HEADER LINE,
       WA_FIELDN TYPE SLIS_FIELDCAT_ALV.
  REFRESH:IT_DD03T,IT_DD03L.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      I_PROGRAM_NAME         = SY-REPID
      I_STRUCTURE_NAME       = INTABNAME
    CHANGING
      CT_FIELDCAT            = CT_FIELDCAT
    EXCEPTIONS
      INCONSISTENT_INTERFACE = 1
      PROGRAM_ERROR          = 2
      OTHERS                 = 3.
  SELECT *
    INTO TABLE IT_DD03T
    FROM DD03T
    WHERE TABNAME = INTABNAME
    AND   DDLANGUAGE = SY-LANGU.

  IF SY-SUBRC NE 0.
    EXIT.
  ENDIF.
  SORT IT_DD03T BY FIELDNAME.
  LOOP AT CT_FIELDCAT INTO WA_FIELDN .
    IF WA_FIELDN-SELTEXT_L IS INITIAL
      OR WA_FIELDN-SELTEXT_M IS INITIAL
      OR WA_FIELDN-SELTEXT_S IS INITIAL.
      READ TABLE IT_DD03T WITH KEY FIELDNAME = WA_FIELDN-FIELDNAME BINARY SEARCH.
      IF SY-SUBRC EQ 0.
        WA_FIELDN-SELTEXT_L = IT_DD03T-DDTEXT.
        WA_FIELDN-SELTEXT_S = IT_DD03T-DDTEXT.
        WA_FIELDN-SELTEXT_M = IT_DD03T-DDTEXT.
      ENDIF.
    ENDIF.
    MODIFY CT_FIELDCAT FROM WA_FIELDN.
  ENDLOOP.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*输入表/结构名，将表头复制到剪切板,INLINE为想获取到的字段的位置(排除MANDT)
FORM STRUCTOCLIP USING INNAME INLINE TYPE I.
  DATA:NAME      TYPE DDOBJNAME,
       N         TYPE I,
       SUBRC     TYPE SY-SUBRC,
       DD03P_TAB TYPE TABLE OF DD03P WITH HEADER LINE,
       WA_DFIES  TYPE DFIES,
       WA_DD02L  TYPE DD02L,
       IT_CLIP   TYPE TABLE OF CHAR2048 WITH HEADER LINE.
  REFRESH:IT_CLIP,DD03P_TAB.
  CLEAR:IT_CLIP,NAME,WA_DFIES,WA_DD02L,N.
  IF INNAME IS NOT INITIAL.
    SELECT SINGLE *
    INTO WA_DD02L
    FROM DD02L
    WHERE TABNAME = INNAME."检查输入是否为表/结构名
    IF SY-SUBRC = 0.
*获得表/结构名
      NAME = INNAME.
      CALL FUNCTION 'DDIF_TABL_GET'
        EXPORTING
          NAME          = NAME
          LANGU         = SY-LANGU
        TABLES
          DD03P_TAB     = DD03P_TAB
        EXCEPTIONS
          ILLEGAL_INPUT = 1
          OTHERS        = 2.
      IF SY-SUBRC = 0.
        DELETE DD03P_TAB WHERE FIELDNAME EQ 'MANDT' OR FIELDNAME EQ '.INCLUDE'.
        N = LINES( DD03P_TAB ).
        IF N NE 0.
          IF INLINE = 0 OR INLINE > N."获取到某一字段的位置输出
          ELSE.
            N = INLINE.
          ENDIF.
*将结构输出到剪切板
          LOOP AT DD03P_TAB FROM 1 TO N.
            IF DD03P_TAB-SCRTEXT_S IS INITIAL
            AND DD03P_TAB-SCRTEXT_M IS INITIAL
            AND DD03P_TAB-SCRTEXT_L IS INITIAL
            AND DD03P_TAB-DDTEXT IS INITIAL.
              CALL 'C_DD_READ_FIELD'
              ID 'TYPE'      FIELD 'T'
              ID 'TABNAME'   FIELD NAME
              ID 'FIELDNAME' FIELD DD03P_TAB-FIELDNAME
              ID 'LANGUAGE'  FIELD SY-LANGU.
            ELSE.
              IF DD03P_TAB-DDTEXT IS NOT INITIAL.
                WA_DFIES-FIELDTEXT = DD03P_TAB-DDTEXT.
              ELSEIF DD03P_TAB-SCRTEXT_L IS NOT INITIAL.
                WA_DFIES-FIELDTEXT = DD03P_TAB-SCRTEXT_L.
              ELSEIF DD03P_TAB-SCRTEXT_M IS NOT INITIAL.
                WA_DFIES-FIELDTEXT = DD03P_TAB-SCRTEXT_M.
              ELSEIF DD03P_TAB-SCRTEXT_S IS NOT INITIAL.
                WA_DFIES-FIELDTEXT = DD03P_TAB-SCRTEXT_S.
              ENDIF.
            ENDIF.
            CONCATENATE IT_CLIP CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB WA_DFIES-FIELDTEXT INTO IT_CLIP.
            CLEAR DD03P_TAB.
          ENDLOOP.
          SHIFT IT_CLIP.
          APPEND IT_CLIP.
          CALL METHOD CL_GUI_FRONTEND_SERVICES=>CLIPBOARD_EXPORT
            IMPORTING
              DATA                 = IT_CLIP[]
            CHANGING
              RC                   = SUBRC
            EXCEPTIONS
              CNTL_ERROR           = 1
              ERROR_NO_GUI         = 2
              NOT_SUPPORTED_BY_GUI = 3
              OTHERS               = 4.
          IF SY-SUBRC = 0.
            MESSAGE S000(OO) WITH '已经把表头复制到剪贴板,可以打开一个Excel文件然后粘贴'.
          ELSE.
            MESSAGE E000(OO) WITH '复制到剪贴板失败'.
          ENDIF.
        ENDIF.
      ENDIF.
    ELSE.
      MESSAGE E000(OO) WITH '表/结构名不存在'.
    ENDIF.
  ELSE.
    MESSAGE E000(OO) WITH '请输入表/结构名'.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将ALV布局复制到剪切板,选择开始及结束粘贴的位置，若M=N=0，则复制全部
FORM ITABSTRUCTOCLIP USING FIELDTAB TYPE SLIS_T_FIELDCAT_ALV M TYPE I N TYPE I.
  DATA: WA_DFIES TYPE DFIES,
        SUBRC    TYPE SY-SUBRC,
        LINE     TYPE I,
        M1       TYPE I,
        N1       TYPE I,
        IT_CLIP  TYPE TABLE OF CHAR2048 WITH HEADER LINE,
        FIELDCAT TYPE SLIS_T_FIELDCAT_ALV,
        WA       TYPE SLIS_FIELDCAT_ALV.

  IF FIELDTAB[] IS NOT INITIAL.
*防止描述为空
    LOOP AT FIELDTAB INTO WA WHERE SELTEXT_L IS INITIAL
    AND SELTEXT_M IS INITIAL
    AND SELTEXT_S IS INITIAL.
      EXIT.
    ENDLOOP.
    IF SY-SUBRC = 0.
      RETURN.
    ENDIF.
    LINE = LINES( FIELDTAB ).
    IF M = 0 AND N = 0.
      M1 = 1.
      N1 = LINE.
    ELSE.
      IF M <= N AND M > 0 AND N <= LINE.
        M1 = M.
        N1 = N.
      ELSE.
        RETURN.
      ENDIF.
    ENDIF.
  ELSE.
    RETURN.
  ENDIF.

  LOOP AT FIELDTAB INTO WA FROM M1 TO N1.
    IF WA-SELTEXT_L IS NOT INITIAL.
      WA_DFIES-FIELDTEXT = WA-SELTEXT_L.
    ELSEIF WA-SELTEXT_M IS NOT INITIAL.
      WA_DFIES-FIELDTEXT = WA-SELTEXT_M.
    ELSEIF WA-SELTEXT_S IS NOT INITIAL.
      WA_DFIES-FIELDTEXT = WA-SELTEXT_S.
    ENDIF.
    CONCATENATE IT_CLIP CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB WA_DFIES-FIELDTEXT INTO IT_CLIP.
    CLEAR WA.
  ENDLOOP.

  SHIFT IT_CLIP.
  APPEND IT_CLIP.
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>CLIPBOARD_EXPORT
    IMPORTING
      DATA                 = IT_CLIP[]
    CHANGING
      RC                   = SUBRC
    EXCEPTIONS
      CNTL_ERROR           = 1
      ERROR_NO_GUI         = 2
      NOT_SUPPORTED_BY_GUI = 3
      OTHERS               = 4.
  IF SY-SUBRC = 0.
    MESSAGE S000(OO) WITH '已经把表头复制到剪贴板,可以打开一个Excel文件然后粘贴'.
  ELSE.
    MESSAGE E000(OO) WITH '复制到剪贴板失败'.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*BAPI结构赋值X（字段同名）
FORM SETBAPIX USING FS CHANGING FSX    .
  FIELD-SYMBOLS : <FS>,<FSX>.
  DATA: OUTFIELDCAT TYPE SLIS_T_FIELDCAT_ALV,
        WA_FIELD    TYPE SLIS_FIELDCAT_ALV.
  CLEAR:OUTFIELDCAT,WA_FIELD,FSX.

  PERFORM GETTABSTRU_SE11 USING FSX CHANGING OUTFIELDCAT.

  LOOP AT OUTFIELDCAT INTO WA_FIELD.
    ASSIGN COMPONENT WA_FIELD-FIELDNAME OF STRUCTURE FS TO <FS>.
    IF SY-SUBRC <> 0 .
      CONTINUE.
    ENDIF.
    IF <FS> IS NOT INITIAL.
      ASSIGN COMPONENT WA_FIELD-FIELDNAME OF STRUCTURE FSX TO <FSX>.
      IF SY-SUBRC <> 0 .
        EXIT.
      ENDIF.
*对于长度为1，但是不是赋值X的字段特殊处理
      IF WA_FIELD-ROLLNAME = 'BAPIUPDATE'.
        <FSX> = 'X'.
      ELSE.
        <FSX> = <FS>.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将字符串拆分到RANGE表,STR为字符串,FLAG为分割字符
FORM SPLITSTR TABLES OUTRANGE  USING INSTR  FLAG.
  DATA:IT_STR TYPE TABLE OF BAPI_MSG,
       WA_STR LIKE LINE OF IT_STR.
  DATA:RAN_STR TYPE BAPI_MSG.
  REFRESH:IT_STR.
  CLEAR:RAN_STR.

  IF FLAG IS NOT INITIAL AND INSTR IS NOT INITIAL.
    SPLIT INSTR AT FLAG INTO TABLE IT_STR.
    LOOP AT IT_STR INTO WA_STR.
      CLEAR:RAN_STR.
      IF WA_STR IS NOT INITIAL AND WA_STR NE FLAG.
        CONCATENATE 'IEQ' WA_STR INTO RAN_STR.
        APPEND RAN_STR TO OUTRANGE.
      ENDIF.
      CLEAR:WA_STR.
    ENDLOOP.
    SORT OUTRANGE.
  ENDIF.
ENDFORM.                    "SPLITSTR
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*BAPI 回滚或者执行
FORM BAPIRUN USING FLAG.
  CASE FLAG.
    WHEN 'X'.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'
        EXPORTING
          WAIT = 'X'.
      CALL FUNCTION 'RFC_CONNECTION_CLOSE'
        EXPORTING
          DESTINATION          = 'NONE'
        EXCEPTIONS
          DESTINATION_NOT_OPEN = 1
          OTHERS               = 2.
    WHEN SPACE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK' DESTINATION 'NONE'.
      CALL FUNCTION 'RFC_CONNECTION_CLOSE'
        EXPORTING
          DESTINATION          = 'NONE'
        EXCEPTIONS
          DESTINATION_NOT_OPEN = 1
          OTHERS               = 2.
    WHEN 'S'.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          WAIT = 'X'.
    WHEN 'E'.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ENDCASE.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*搜索帮助-年月
*PARAMETERS: P_MONTH LIKE ISELLIST-MONTH DEFAULT SY-DATUM+0(6).
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_MONTH.
FORM SELMONTH CHANGING C_MONTH TYPE KMONTH.
  CALL FUNCTION 'POPUP_TO_SELECT_MONTH'
    EXPORTING
      ACTUAL_MONTH               = SY-DATUM+0(6)
      LANGUAGE                   = SY-LANGU
      START_COLUMN               = 8
      START_ROW                  = 5
    IMPORTING
      SELECTED_MONTH             = C_MONTH
    EXCEPTIONS
      FACTORY_CALENDAR_NOT_FOUND = 1
      HOLIDAY_CALENDAR_NOT_FOUND = 2
      MONTH_NOT_FOUND            = 3
      OTHERS                     = 4.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*给字段加搜索帮助，NAME为要展示的字段，SCREENNAME为选择屏幕字段名称,DBNAME为要取数的数据库表
FORM F4HELP USING NAME SCREENNAME DBNAME.
  DATA:BEGIN OF IT_HELP OCCURS 0,
         HELP TYPE CHAR100,
       END OF IT_HELP.
  IF NAME IS NOT INITIAL AND SCREENNAME IS NOT INITIAL AND DBNAME IS NOT INITIAL.
    SELECT DISTINCT (NAME) INTO TABLE IT_HELP FROM (DBNAME).
    SORT IT_HELP BY HELP.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' "调用函数
      EXPORTING
        RETFIELD        = NAME  "搜索帮助内表要输出的的帮助字段名，注：要大写
        DYNPPROG        = SY-REPID
        DYNPNR          = SY-DYNNR
        DYNPROFIELD     = SCREENNAME "屏幕字段
        VALUE_ORG       = 'S'
      TABLES
        VALUE_TAB       = IT_HELP "存储搜索帮助内容的内表
      EXCEPTIONS
        PARAMETER_ERROR = 1
        NO_VALUES_FOUND = 2
        OTHERS          = 3.
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
      WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*给字段加搜索帮助，HELP 为传入的内表（可制作复合型搜索帮助），NAME为要展示的字段，SCREENNAME为选择屏幕字段名称
FORM F4HELPN TABLES HELP USING NAME SCREENNAME.
  IF NAME IS NOT INITIAL AND SCREENNAME IS NOT INITIAL AND HELP[] IS NOT INITIAL.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' "调用函数
      EXPORTING
        RETFIELD        = NAME  "搜索帮助内表要输出的的帮助字段名，注：要大写
        DYNPPROG        = SY-REPID
        DYNPNR          = SY-DYNNR
        DYNPROFIELD     = SCREENNAME "屏幕字段
        VALUE_ORG       = 'S'
      TABLES
        VALUE_TAB       = HELP "存储搜索帮助内容的内表
      EXCEPTIONS
        PARAMETER_ERROR = 1
        NO_VALUES_FOUND = 2
        OTHERS          = 3.
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
      WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*&---------------------------------------------------------------------*
*&      整数部分四舍五入
*&---------------------------------------------------------------------*
FORM ROUNDING CHANGING VALUE(PP).
  PP =: PP + '0.5',TRUNC( PP ).
ENDFORM.                    "Rounding
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将时间戳换算成秒
*GET TIME STAMP FIELD TIMESTAMPL2."TIMESTAMPL
FORM GETSECOND USING STAMP1 STAMP2 CHANGING SECOND.
  DATA: D1 TYPE D,
        D2 TYPE D,
        T1 TYPE T,
        T2 TYPE T,
        S1 TYPE P DECIMALS 6,
        S2 TYPE P DECIMALS 6.

  CONVERT TIME STAMP STAMP1 TIME ZONE SY-ZONLO INTO DATE D1 TIME T1.
  S1 = FRAC( STAMP1 ).

  CONVERT TIME STAMP STAMP2 TIME ZONE SY-ZONLO INTO DATE D2 TIME T2.
  S2 = FRAC( STAMP2 ).

  SECOND = ( ( D2 - D1 ) * 86400 ) + T2 - T1 + S2 - S1.
ENDFORM.                    "GETSECOND
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*金额转换为大写
FORM CONVERT_MONEY USING VAL2 CHANGING DXSTR.
  IF VAL2 IS NOT INITIAL.
    DATA: ZS(15).
    DATA: XS(15).
    DATA: STR(15).
    DATA: LEN TYPE I VALUE 0.
    DATA: CIS TYPE I VALUE 0.
    DATA: LIS TYPE I VALUE 0.
    DATA: SS(2).
    DATA: RR(1).
    DATA: STRR(15).
    DATA: CHANGE(30) TYPE C VALUE '1壹2贰3叁4肆5伍6陆7柒8捌9玖0零'.
*data DXSTR type STRING value ''.
    DATA VAL TYPE P DECIMALS 2 VALUE '907604001.00'.
    VAL = VAL2.

    CLEAR DXSTR.
    MOVE VAL TO STR.
    SHIFT STR LEFT  DELETING LEADING SPACE.
    SPLIT STR AT '.' INTO ZS XS.

    LEN = STRLEN( ZS ).
    CLEAR STRR.
    CIS = LEN - 1.
    DO LEN TIMES.
      MOVE ZS+CIS(1) TO RR.
      CONCATENATE STRR RR INTO STRR.
      CIS = CIS - 1.
    ENDDO.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
    CIS = 0.
    DO LEN TIMES.
      MOVE STRR+CIS(1) TO SS.
      IF SS <> 0.
        TRANSLATE SS USING CHANGE.
        CASE CIS.
          WHEN 0.
            CONCATENATE SS '圆'        INTO DXSTR.
          WHEN 1.
            CONCATENATE SS '拾'  DXSTR INTO DXSTR.
          WHEN 2.
            CONCATENATE SS '佰'  DXSTR INTO DXSTR.
          WHEN 3.
            CONCATENATE SS '仟'  DXSTR INTO DXSTR.
          WHEN 4.
            CONCATENATE SS '万'  DXSTR INTO DXSTR.
          WHEN 5.
            CONCATENATE SS '拾'  DXSTR INTO DXSTR.
          WHEN 6.
            CONCATENATE SS '佰'  DXSTR INTO DXSTR.
          WHEN 7.
            CONCATENATE SS '仟'  DXSTR INTO DXSTR.
          WHEN 8.
            CONCATENATE SS '亿'  DXSTR INTO DXSTR.
          WHEN 9.
            CONCATENATE SS '拾'  DXSTR INTO DXSTR.
          WHEN 10.
            CONCATENATE SS '百'  DXSTR INTO DXSTR.
          WHEN 11.
            CONCATENATE SS '仟'  DXSTR INTO DXSTR.
        ENDCASE.
      ELSEIF SS = 0 AND STRR+LIS(1) = 0.
        CASE CIS.
          WHEN 0.
            CONCATENATE '圆'  DXSTR INTO DXSTR.
          WHEN 4.
            CONCATENATE '万'  DXSTR INTO DXSTR.
          WHEN 8.
            CONCATENATE '亿'  DXSTR INTO DXSTR.
        ENDCASE.
      ELSEIF SS = 0 AND STRR+LIS(1) <> 0.
        TRANSLATE SS USING CHANGE.
        CASE CIS.
          WHEN 0.
            CONCATENATE '圆'  SS DXSTR INTO DXSTR.
          WHEN 4.
            CONCATENATE '万'  SS DXSTR INTO DXSTR.
          WHEN 8.
            CONCATENATE '亿'  SS DXSTR INTO DXSTR.
          WHEN OTHERS.
            CONCATENATE SS DXSTR INTO DXSTR.
        ENDCASE.
      ENDIF.
      LIS = CIS.
      CIS = CIS + 1.
    ENDDO.
    CLEAR SS.
    IF XS <> '00'.
      MOVE XS+0(1) TO SS. TRANSLATE SS USING CHANGE.
      IF SS <> '零'.
        CONCATENATE
        DXSTR SS '角' INTO DXSTR.
      ENDIF.
      MOVE XS+1(1) TO SS. TRANSLATE SS USING CHANGE.
      IF SS <> '零'.  CONCATENATE DXSTR SS '分' INTO DXSTR.  ENDIF.
    ELSE.
      CONCATENATE DXSTR '整' INTO DXSTR.
    ENDIF.
    REPLACE '零零零' WITH '零' INTO DXSTR.
    REPLACE '零零零' WITH '零' INTO DXSTR.
    REPLACE '零零零' WITH '零' INTO DXSTR.
    REPLACE '零零' WITH '零' INTO DXSTR.
    REPLACE '零零' WITH '零' INTO DXSTR.
    REPLACE '零零' WITH '零' INTO DXSTR.
    REPLACE '零万' WITH '万' INTO DXSTR.
    REPLACE '零元' WITH '元' INTO DXSTR.
    REPLACE '零亿' WITH '亿' INTO DXSTR.
    REPLACE '亿万' WITH '亿' INTO DXSTR.
    CONDENSE DXSTR NO-GAPS.
    IF DXSTR = '整'.  DXSTR = ''.  ENDIF.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取域值范围(DDTEXT)
FORM GETDOMAIN TABLES DOMAIN STRUCTURE DD07V
USING DOMNAME TYPE DOMNAME.
  REFRESH DOMAIN.
  CALL FUNCTION 'DD_DOMVALUES_GET'
    EXPORTING
      DOMNAME        = DOMNAME
      TEXT           = 'X'
    TABLES
      DD07V_TAB      = DOMAIN
    EXCEPTIONS
      WRONG_TEXTFLAG = 1
      OTHERS         = 2.
  SORT DOMAIN BY DOMVALUE_L.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取当前用户IP，电脑名
FORM GETIP CHANGING OUTIP.
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>GET_IP_ADDRESS
    RECEIVING
      IP_ADDRESS = OUTIP.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
**获取批次特性值
*FORM GETPCTX TABLES IT_VAL_TAB STRUCTURE API_VALI
*  IT_CHAR_TAB STRUCTURE API_CHAR
*  IT_ATT_TAB STRUCTURE API_CH_ATT
*USING MATNR TYPE MATNR
*      WERKS TYPE WERKS_D
*      CHARG TYPE CHARG_D."获取批次特性
*  DATA:INMATNR TYPE MATNR,
*       CHECKFLAG TYPE CHAR1.
*  CLEAR:INMATNR,CHECKFLAG,IT_VAL_TAB[],IT_CHAR_TAB[],IT_ATT_TAB[],IT_VAL_TAB,IT_CHAR_TAB,IT_ATT_TAB.
*  INMATNR = MATNR.
*  PERFORM TRANSDATA USING 'MARA' 'MATNR' 'IN' INMATNR
*  CHANGING INMATNR.
*  CALL FUNCTION 'QC01_BATCH_VALUES_READ'
*    EXPORTING
*      I_VAL_MATNR    = INMATNR
*      I_VAL_WERKS    = WERKS
*      I_VAL_CHARGE   = CHARG
*      I_LANGUAGE     = SY-LANGU
*      I_DATE         = SY-DATUM
*    TABLES
*      T_VAL_TAB      = IT_VAL_TAB
*      T_CHAR_TAB     = IT_CHAR_TAB
*      T_ATT_TAB      = IT_ATT_TAB
*    EXCEPTIONS
*      NO_CLASS       = 1
*      INTERNAL_ERROR = 2
*      NO_VALUES      = 3
*      NO_CHARS       = 4
*      OTHERS         = 5.
*********ADD BY DONGPZ BEGIN AT 09.12.2020 20:34:09
**数值类型去千分位
*  SORT IT_ATT_TAB BY ATNAM.
*  LOOP AT IT_VAL_TAB WHERE ATWRT IS NOT INITIAL .
*    CLEAR CHECKFLAG.
*    READ TABLE IT_ATT_TAB WITH KEY ATNAM = IT_VAL_TAB-ATNAM BINARY SEARCH.
*    IF SY-SUBRC EQ 0.
*      CASE IT_ATT_TAB-ATFOR.
*        WHEN 'NUM' OR 'CURR'.
*          PERFORM CHECKMENGE CHANGING IT_VAL_TAB-ATWRT CHECKFLAG.
*          IF CHECKFLAG = 'E'.
*            DELETE IT_VAL_TAB.
*            CONTINUE.
*          ENDIF.
*          MODIFY IT_VAL_TAB TRANSPORTING ATWRT.
*      ENDCASE.
*    ENDIF.
*    CLEAR IT_VAL_TAB.
*  ENDLOOP.
*********ADD BY DONGPZ END AT 09.12.2020 20:34:09
*ENDFORM.
*获取批次特性
FORM GETPCTX TABLES INTAB STRUCTURE MCHA OUTTAB
             USING P_INSTR.
  DATA:BEGIN OF IT_PCTXN OCCURS 0,
         WERKS TYPE WERKS_D,
         MATNR TYPE MATNR,
         CHARG TYPE CHARG_D,
         ATNAM TYPE ATNAM,
         ATWRT TYPE ATWRT,
       END OF IT_PCTXN,
       BEGIN OF IT_PCTZ OCCURS 0,
         MATNR TYPE MCHA-MATNR,
         WERKS TYPE MCHA-WERKS,
         CHARG TYPE MCHA-CHARG,
         ATINN TYPE CABN-ATINN,
         ATNAM TYPE CABN-ATNAM,
         ATFOR TYPE CABN-ATFOR,
         ATWRT TYPE AUSP-ATWRT,
         ATFLV TYPE AUSP-ATFLV,
         ATBEZ TYPE CABNT-ATBEZ,
       END OF IT_PCTZ,
       IT_VAL  TYPE TABLE OF API_VALI WITH HEADER LINE,
       IT_CHAR TYPE TABLE OF API_CHAR WITH HEADER LINE,
       IT_ATT  TYPE TABLE OF API_CH_ATT WITH HEADER LINE.
  DATA:E_CHAR_FIELD TYPE QSOLLWERTC,
       MATNR        TYPE MATNR,
       KLART        TYPE AUSP-KLART,
       LEN          TYPE QSTELLEN.
  RANGES:S_ATNAM FOR CABN-ATNAM.
  REFRESH:OUTTAB,IT_PCTXN,IT_PCTZ,S_ATNAM.
  CLEAR:KLART.

  DELETE INTAB WHERE WERKS IS INITIAL
                  OR MATNR IS INITIAL
                  OR CHARG IS INITIAL.
  IF INTAB[] IS INITIAL.
    RETURN.
  ENDIF.
  SORT INTAB BY WERKS MATNR CHARG.

  IF P_INSTR IS NOT INITIAL.
    PERFORM SPLITSTR(ZPUBFORM) TABLES S_ATNAM USING P_INSTR ','.
  ENDIF.
*根据物料找到类
  READ TABLE INTAB INDEX 1.
  MATNR = INTAB-MATNR.
  PERFORM ADDZERO_MATNR(ZPUBFORM) CHANGING MATNR.
  SELECT SINGLE KSSK~KLART
    INTO KLART
    FROM KSSK INNER JOIN INOB ON KSSK~OBJEK = INOB~CUOBJ
                             AND KSSK~KLART = INOB~KLART
    WHERE INOB~OBJEK = MATNR.
  SELECT MCHA~MATNR
         MCHA~WERKS
         MCHA~CHARG
         CABN~ATINN
         CABN~ATNAM
         CABN~ATFOR
         AUSP~ATWRT
         AUSP~ATFLV
    INTO TABLE IT_PCTZ
    FROM MCHA INNER JOIN AUSP ON MCHA~CUOBJ_BM = AUSP~OBJEK
                              AND KLART = KLART
              INNER JOIN CABN ON AUSP~ATINN = CABN~ATINN
    FOR ALL ENTRIES IN INTAB
    WHERE MCHA~MATNR = INTAB-MATNR
    AND   MCHA~CHARG = INTAB-CHARG
    AND   MCHA~WERKS = INTAB-WERKS
    AND   CABN~ATNAM IN S_ATNAM.
  IF SY-SUBRC EQ 0.
    SORT IT_PCTZ BY MATNR CHARG ATNAM.
    LOOP AT IT_PCTZ.
      CLEAR:LEN,E_CHAR_FIELD,IT_PCTZ,IT_PCTXN.
      CASE IT_PCTZ-ATFOR.
        WHEN 'DATE' OR 'CURR' OR 'NUM'.
          IF IT_PCTZ-ATFLV IS NOT INITIAL.
            IF IT_PCTZ-ATFOR EQ 'DATE'.
              LEN = 0.
            ELSE.
              LEN = 2.
            ENDIF.
            CALL FUNCTION 'QSS0_FLTP_TO_CHAR_CONVERSION'
              EXPORTING
                I_NUMBER_OF_DIGITS = LEN
                I_FLTP_VALUE       = IT_PCTZ-ATFLV
              IMPORTING
                E_CHAR_FIELD       = E_CHAR_FIELD.
            CONDENSE E_CHAR_FIELD NO-GAPS.
            PERFORM DELQFW(ZPUBFORM) CHANGING E_CHAR_FIELD.
            IT_PCTZ-ATWRT = E_CHAR_FIELD.
          ENDIF.
      ENDCASE.
      IT_PCTXN-WERKS = IT_PCTZ-WERKS.
      IT_PCTXN-MATNR = IT_PCTZ-MATNR.
      IT_PCTXN-CHARG = IT_PCTZ-CHARG.
      IT_PCTXN-ATNAM = IT_PCTZ-ATNAM.
      IT_PCTXN-ATWRT = IT_PCTZ-ATWRT.
      APPEND IT_PCTXN.
      MOVE-CORRESPONDING IT_PCTXN TO OUTTAB.
      APPEND OUTTAB.
    ENDLOOP.

  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取税码对应税率
FORM GETTAX USING INALAND INMWSKZ CHANGING OUTKBETR.
  DATA:T_FTAXP TYPE TABLE OF FTAXP WITH HEADER LINE.
  DATA:ALAND TYPE RF82T-LAND1,
       MWSKZ TYPE RF82T-MWSKZ.

  CHECK INMWSKZ IS NOT INITIAL.

  IF INALAND IS INITIAL.
    ALAND = 'CN'.
  ELSE.
    ALAND = INALAND.
    TRANSLATE ALAND TO UPPER CASE.
  ENDIF.

  SELECT SINGLE MWSKZ
  INTO MWSKZ
  FROM T007A
  WHERE MWSKZ = INMWSKZ.

  IF SY-SUBRC = 0.
    CALL FUNCTION 'GET_TAX_PERCENTAGE'
      EXPORTING
        ALAND   = ALAND
        DATAB   = SY-DATUM
        MWSKZ   = MWSKZ
        TXJCD   = ''
      TABLES
        T_FTAXP = T_FTAXP
      EXCEPTIONS
        OTHERS  = 1.
    IF SY-SUBRC = 0.
      READ TABLE T_FTAXP INDEX 1.
      OUTKBETR = T_FTAXP-KBETR / 1000.
    ELSE.
      MESSAGE E000(OO) WITH '请检查国家代码/税码'.
    ENDIF.
  ELSE.
    MESSAGE E000(OO) WITH '税码不存在'.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取长文本，ID可去表STXL查找(可用SE75+SPRO查看)，NAME看具体要求，OBJECT为表名
FORM GETLONGTEXT USING ID NAME OBJECT CHANGING LTEXT.
  DATA: TLINES   TYPE TABLE OF TLINE WITH HEADER LINE,
        TDNAME   TYPE THEAD-TDNAME,
        TDID     TYPE THEAD-TDID,
        P_STR    TYPE STRING,
        TDOBJECT TYPE THEAD-TDOBJECT.
  TDID = ID.
  TDNAME = NAME.
  TDOBJECT = OBJECT.

  IF TDID IS NOT INITIAL AND TDNAME IS NOT INITIAL AND TDOBJECT IS NOT INITIAL.
    SELECT SINGLE COUNT(*)
    FROM STXH
    WHERE TDNAME = TDNAME
    AND   TDID = TDID
    AND   TDOBJECT = TDOBJECT
    AND   TDSPRAS = SY-LANGU.
    IF SY-SUBRC = 0.
      CALL METHOD CL_ESO_EXTRACTION_TOOLS=>EXTRACT_LONG_TEXT_BY_ID
        EXPORTING
          IV_LANGU        = SY-LANGU
          IV_TEXT_ID      = TDID
          IV_NAME         = TDNAME
          IV_OBJECT       = TDOBJECT
        IMPORTING
          EV_SEARCH_TERMS = P_STR
        EXCEPTIONS
          OTHERS          = 1.
      IF SY-SUBRC = 0.
        LTEXT = P_STR.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取订单状态
FORM GETAUFNR_STATUS USING INPUT CHANGING OUTPUT .
  DATA:AUFNR TYPE AUFNR,
       OBJNR TYPE JEST-OBJNR,
       LINE  TYPE BSVX-STTXT.
  IF INPUT IS NOT INITIAL.
    AUFNR = INPUT.
    PERFORM TRANSDATA USING '' 'ZERO' 'IN' AUFNR
    CHANGING AUFNR.
    CONCATENATE 'OR' AUFNR INTO OBJNR.
    CALL FUNCTION 'STATUS_TEXT_EDIT'
      EXPORTING
        OBJNR            = OBJNR "AUFK中OBJNR
        SPRAS            = SY-LANGU
      IMPORTING
        LINE             = LINE
      EXCEPTIONS
        OBJECT_NOT_FOUND = 1.
    OUTPUT = LINE.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将内表存入INDX簇表(FLAG为X则产生唯一GUID)
FORM ITABTOINDX TABLES INTAB USING INFLAG CHANGING EXGUID.
  DATA:SRTFD   TYPE INDX-SRTFD,
       LV_GUID TYPE GUID_22,
       CXROOT  TYPE REF TO CX_ROOT,
       MSG     TYPE BAPI_MSG.
  CLEAR:LV_GUID.
  IF INTAB[] IS NOT INITIAL.
    IF INFLAG EQ 'X'.
      TRY .
          CALL METHOD CL_SYSTEM_UUID=>IF_SYSTEM_UUID_STATIC~CREATE_UUID_C22
            RECEIVING
              UUID = LV_GUID. "产生唯一GUID KEY值
        CATCH  CX_ROOT INTO CXROOT.
          MSG =  CXROOT->GET_TEXT( ).
          CONCATENATE 'E:' MSG INTO MSG.
      ENDTRY.
      IF MSG+0(1) NE 'E'.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.
    ELSE.
      LV_GUID = EXGUID.
    ENDIF.

    IF LV_GUID IS INITIAL.
      RETURN.
    ENDIF.

    SRTFD = LV_GUID.

    EXPORT INDXTAB = INTAB TO DATABASE INDX(DD) ID SRTFD.
    COMMIT WORK.
    EXGUID = LV_GUID.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将INDX簇表中数据取出(INGUID为唯一键值，DELFLAG为X时，取出数据后删除元数据)
FORM INDXTOITAB TABLES OUTTAB USING INGUID DELFLAG.
  IF INGUID IS NOT INITIAL.
    DATA:SRTFD TYPE INDX-SRTFD.
    SRTFD = INGUID.
    IMPORT INDXTAB = OUTTAB FROM DATABASE INDX(DD) ID SRTFD.
    IF SY-SUBRC = 0.
      IF DELFLAG = 'X'.
        DELETE FROM DATABASE INDX(DD) ID SRTFD.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将内表存入服务器（AL11-DIR_HOME）
FORM ITABTODATASET TABLES INTAB
USING  PREFIX REPLACE.
  DATA: LC_TDESCR TYPE REF TO CL_ABAP_TABLEDESCR,
        LC_SDESCR TYPE REF TO CL_ABAP_STRUCTDESCR.
  DATA: LT_COMP TYPE CL_ABAP_STRUCTDESCR=>COMPONENT_TABLE WITH HEADER LINE.
  DATA: LT_REP      TYPE TABLE OF CHAR10 WITH HEADER LINE , "需要替换为空的符号
        HTAB        TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB,
        CHARC       TYPE CHAR2048,
        CHARSTR     TYPE STRING,
        STR         TYPE STRING,
        APPFILE(60),
        INAME(40),
        P_AFILE     TYPE STRING,
        FTYPE .
  FIELD-SYMBOLS <FS_FLD> .

  CHECK INTAB[] IS NOT INITIAL.

  LC_TDESCR ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( INTAB[] ).
  LC_SDESCR ?= LC_TDESCR->GET_TABLE_LINE_TYPE( ).
  LT_COMP[] = LC_SDESCR->GET_COMPONENTS( ).""获取内表字段结构

  APPEND CL_ABAP_CHAR_UTILITIES=>CR_LF   TO LT_REP.
  APPEND CL_ABAP_CHAR_UTILITIES=>NEWLINE TO LT_REP.
  APPEND CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB TO LT_REP.

  INAME = CL_ABAP_SYST=>GET_INSTANCE_NAME( ).
  GET TIME.
  IF SY-TCODE IS INITIAL.
    CONCATENATE PREFIX SY-CPROG SY-DATUM SY-UZEIT INTO APPFILE SEPARATED BY '_'.
  ELSE.
    CONCATENATE PREFIX SY-TCODE SY-DATUM SY-UZEIT INTO APPFILE SEPARATED BY '_'.
  ENDIF.
  CONCATENATE APPFILE '.TXT' INTO APPFILE.

  MESSAGE S000(OO) WITH 'ItabToDataset'.
  OPEN DATASET APPFILE FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH WINDOWS LINEFEED.
  IF SY-SUBRC NE 0.
    MESSAGE E000(OO) WITH '打开文件失败'.
  ENDIF.

  LOOP AT LT_COMP.
    CONCATENATE STR HTAB LT_COMP-NAME INTO STR.
  ENDLOOP.
  IF SY-SUBRC = 0.
    SHIFT STR.
    TRANSFER STR TO APPFILE.
  ENDIF.

  LOOP AT INTAB.
    CLEAR STR.
    DO .
      ASSIGN COMPONENT SY-INDEX OF STRUCTURE INTAB TO <FS_FLD>.
      IF SY-SUBRC <> 0.
        EXIT.
      ENDIF.

      DESCRIBE FIELD <FS_FLD> TYPE FTYPE.
      CASE FTYPE.
        WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
          CHARC = ABS( <FS_FLD> ).
          CONDENSE CHARC NO-GAPS.
          IF <FS_FLD> < 0.
            CONCATENATE '-' CHARC INTO CHARC.
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'D' OR 'T'.
          IF <FS_FLD> IS INITIAL OR <FS_FLD> = ''.
            CHARC = ''.
          ELSE.
            WRITE <FS_FLD> TO CHARC .
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'X' OR 'y' OR 'g'.
          CHARSTR = <FS_FLD> .
        WHEN OTHERS.
          WRITE <FS_FLD> TO CHARC .
          IF REPLACE = 'X'.
            LOOP AT LT_REP.
              REPLACE ALL OCCURRENCES OF LT_REP IN CHARC WITH ''.
            ENDLOOP.
          ENDIF.
          CHARSTR = CHARC.
      ENDCASE.
      CONCATENATE STR HTAB CHARSTR INTO STR.
    ENDDO.
    SHIFT STR.
    TRANSFER STR TO APPFILE.
  ENDLOOP.

  CLOSE DATASET APPFILE.
  MESSAGE S000(OO) WITH '服务器:' INAME '文件：' APPFILE.
ENDFORM.                    "itabtodataset
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*数据库连接(Y为建立连接，N为关闭连接)
FORM CONNECT_DBCO USING DBCON_NAME
      DBCO_TYPE TYPE BAPI_MTYPE
CHANGING DBCO_MSG TYPE BAPI_MSG.
  DATA:CXROOT TYPE REF TO CX_ROOT,
       MSG    TYPE BAPI_MSG.
  CLEAR MSG.
  CASE DBCO_TYPE.
    WHEN 'Y'.
      TRY.
          EXEC SQL.
            CONNECT TO :DBCON_NAME
          ENDEXEC.
        CATCH  CX_ROOT INTO CXROOT.
          MSG =  CXROOT->GET_TEXT( ).
          CONCATENATE 'E:' MSG INTO DBCO_MSG.
      ENDTRY.
      IF DBCO_MSG+0(1) NE 'E'.
        CONCATENATE 'S:' '数据库连接成功！' INTO DBCO_MSG.
      ENDIF.
    WHEN 'N'.
      TRY.
          EXEC SQL.
            DISCONNECT :DBCON_NAME
          ENDEXEC.
        CATCH  CX_ROOT INTO CXROOT.
          MSG =  CXROOT->GET_TEXT( ).
          CONCATENATE 'E:' MSG INTO DBCO_MSG.
      ENDTRY.
      IF DBCO_MSG+0(1) NE 'E'.
        CONCATENATE 'S:' '数据库关闭连接成功！' INTO DBCO_MSG.
      ENDIF.
  ENDCASE.


ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*日期格式检验
FORM CHECKDATE CHANGING OUT__DATE.
  DATA:LS_PATTERN TYPE C LENGTH 500.
  IF OUT__DATE IS INITIAL
    OR OUT__DATE EQ SPACE.
    SY-SUBRC = 0.
    RETURN.
  ENDIF.
  "数据预处理
  REPLACE ALL OCCURRENCES OF `.` IN OUT__DATE WITH ``.
  REPLACE ALL OCCURRENCES OF `-` IN OUT__DATE WITH ``.
  REPLACE ALL OCCURRENCES OF `/` IN OUT__DATE WITH ``.

  CONCATENATE '(([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3})'
              '(((0[13578]|1[02])(0[1-9]|[12][0-9]|3[01]))|((0[469]|11)(0[1-9]|[12][0-9]|30))'
              '|(02(0[1-9]|[1][0-9]|2[0-8]))))|((([0-9]{2})(0[48]|[2468][048]|[13579][26])'
              '|((0[48]|[2468][048]|[3579][26])00))0229)'
              INTO LS_PATTERN.
  IF CL_ABAP_MATCHER=>MATCHES( PATTERN = LS_PATTERN
                               TEXT = OUT__DATE ) NE 'X'.
    SY-SUBRC = 4.
  ELSE.
    SY-SUBRC = 0.
  ENDIF.
ENDFORM.
*FORM CHECKDATE USING DATE.
*  DATA:INDATE TYPE SY-DATUM.
*  IF DATE IS NOT INITIAL.
*    IF STRLEN( DATE ) = 8.
*      IF DATE CN ' 0123456789'.
*        SY-SUBRC = 4..
*      ELSE.
*        INDATE = DATE.
*        CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
*          EXPORTING
*            DATE                      = INDATE
*          EXCEPTIONS
*            PLAUSIBILITY_CHECK_FAILED = 1
*            OTHERS                    = 2.
*      ENDIF.
*    ELSE.
*      SY-SUBRC = 4.
*    ENDIF.
*  ENDIF.
*ENDFORM.                    "CHECKDATE
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*数量判断（自动去千分位OUTFLAG= Y则为整数不带小数,Y+位数为整数带00，N+位数为带小数，E则格式不正确）
FORM CHECKMENGE CHANGING INMENGE OUTFLAG.
  DATA:MENGEC    TYPE BAPI_MSG,
       MENGE1    TYPE CHAR100,
       MENGE2    TYPE CHAR100,
       MENGE3    TYPE MENGE_D,
       MENGE4    TYPE CHAR100,
       LEN       TYPE I,
       MENGE(15) TYPE P DECIMALS 10,
       CXROOT    TYPE REF TO CX_ROOT,
       MSG       TYPE BAPI_MSG.
  CLEAR:LEN,MENGEC,MENGE1,MENGE2,MENGE3,MENGE4,
  OUTFLAG,MENGE,MSG.
  IF INMENGE IS NOT INITIAL.
    MENGEC = INMENGE.
    CONDENSE MENGEC NO-GAPS.
    TRY .
        MENGE = MENGEC.
      CATCH  CX_ROOT INTO CXROOT.
        MSG =  CXROOT->GET_TEXT( ).
        CONCATENATE 'E:' MSG INTO MSG.
    ENDTRY.
    IF MSG+0(1) EQ 'E'.
      OUTFLAG = 'E'.
    ELSE.
      "去千分位
      PERFORM DELQFW CHANGING MENGEC.
      SPLIT MENGEC AT '.' INTO MENGE1 MENGE2.
      INMENGE = MENGEC.
      MENGE3 = MENGE2.
      CONDENSE MENGE1 NO-GAPS.
      CONDENSE MENGE2 NO-GAPS.
      IF MENGE3 = 0.
        LEN = STRLEN( MENGE2 ).
        IF LEN = 0.
          OUTFLAG = 'Y'.
        ELSE.
          MENGE1 = LEN.
          CONDENSE MENGE1 NO-GAPS.
          CONCATENATE 'Y' MENGE1 INTO OUTFLAG.
        ENDIF.

      ELSE.
        LEN = STRLEN( MENGE2 ).
        MENGE1 = LEN.
        CONDENSE MENGE1 NO-GAPS.
        CONCATENATE 'N' MENGE1 INTO OUTFLAG.
      ENDIF.

    ENDIF.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*内表复制到剪切板
FORM ITABTOCLIP TABLES INTAB
USING HEADER REPLACE.
  DATA: LC_TDESCR TYPE REF TO CL_ABAP_TABLEDESCR,
        LC_SDESCR TYPE REF TO CL_ABAP_STRUCTDESCR,
        LT_COMP   TYPE CL_ABAP_STRUCTDESCR=>COMPONENT_TABLE WITH HEADER LINE.
  DATA: LT_CLIP TYPE TABLE OF CHAR30K WITH HEADER LINE.
  DATA: LT_REP  TYPE TABLE OF CHAR10 WITH HEADER LINE , "需要替换为空的符号
        HTAB    TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB,
        SUBRC   TYPE SY-SUBRC,
        CHARC   TYPE CHAR2048,
        CHARSTR TYPE STRING,
        STR     TYPE STRING,
        FTYPE .
  FIELD-SYMBOLS <FS_FLD> .

  LC_TDESCR ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( INTAB[] ).
  LC_SDESCR ?= LC_TDESCR->GET_TABLE_LINE_TYPE( ).
  LT_COMP[] = LC_SDESCR->GET_COMPONENTS( ).""获取内表字段结构

  APPEND CL_ABAP_CHAR_UTILITIES=>CR_LF   TO LT_REP.
  APPEND CL_ABAP_CHAR_UTILITIES=>NEWLINE TO LT_REP.
  APPEND CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB TO LT_REP.

  IF HEADER IS NOT INITIAL.
    LOOP AT LT_COMP.
      CONCATENATE STR HTAB LT_COMP-NAME INTO STR.
    ENDLOOP.
    IF SY-SUBRC = 0.
      SHIFT STR.
      APPEND STR TO LT_CLIP.
    ENDIF.
  ENDIF.

  LOOP AT INTAB.
    CLEAR STR.
    DO .
      ASSIGN COMPONENT SY-INDEX OF STRUCTURE INTAB TO <FS_FLD>.
      IF SY-SUBRC <> 0.
        EXIT.
      ENDIF.

      DESCRIBE FIELD <FS_FLD> TYPE FTYPE.
      CASE FTYPE.
        WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
          CHARC = ABS( <FS_FLD> ).
          CONDENSE CHARC NO-GAPS.
          IF <FS_FLD> < 0.
            CONCATENATE '-' CHARC INTO CHARC.
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'D' OR 'T'.
          IF <FS_FLD> IS INITIAL OR <FS_FLD> = ''.
            CHARC = ''.
          ELSE.
            WRITE <FS_FLD> TO CHARC .
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'X' OR 'y' OR 'g'.
          CHARSTR = <FS_FLD> .
        WHEN OTHERS.
          WRITE <FS_FLD> TO CHARC .
          IF REPLACE = 'X'.
            LOOP AT LT_REP.
              REPLACE ALL OCCURRENCES OF LT_REP IN CHARC WITH ''.
            ENDLOOP.
          ENDIF.
          CHARSTR = CHARC.
      ENDCASE.
      CONCATENATE STR HTAB CHARSTR INTO STR.
    ENDDO.
    SHIFT STR.
    APPEND STR TO LT_CLIP.
  ENDLOOP.

  CALL METHOD CL_GUI_FRONTEND_SERVICES=>CLIPBOARD_EXPORT
    IMPORTING
      DATA                 = LT_CLIP[]
    CHANGING
      RC                   = SUBRC
    EXCEPTIONS
      CNTL_ERROR           = 1
      ERROR_NO_GUI         = 2
      NOT_SUPPORTED_BY_GUI = 3
      OTHERS               = 4.
  IF SY-SUBRC <> 0 OR SUBRC <> 0.
    MESSAGE E000(OO) WITH '复制到剪贴板失败'.
  ELSE.
    MESSAGE S000(OO) WITH '已经把数据复制到剪贴板'.
  ENDIF.
ENDFORM.                    "itabtodataset
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*&---------------------------------------------------------------------*
*& 下载内表到本地TXT，如果传入本地路径为空则弹出保存对话框
*& 如果replace='X'，替换制表符、回车换行等为空
*&---------------------------------------------------------------------*
FORM ITABTOTXT TABLES INTAB
USING LOCALFILE HEADER REPLACE.
  DATA: ACTION TYPE I,
        LFILE  TYPE STRING,
        LPATH  TYPE STRING.
  DATA: LC_TDESCR TYPE REF TO CL_ABAP_TABLEDESCR,
        LC_SDESCR TYPE REF TO CL_ABAP_STRUCTDESCR,
        LT_COMP   TYPE CL_ABAP_STRUCTDESCR=>COMPONENT_TABLE WITH HEADER LINE.
  DATA: LT_DOWN TYPE TABLE OF CHAR30K WITH HEADER LINE.
  DATA: LT_REP  TYPE TABLE OF CHAR10 WITH HEADER LINE , "需要替换为空的符号
        HTAB    TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB,
        SUBRC   TYPE SY-SUBRC,
        CHARC   TYPE CHAR2048,
        CHARSTR TYPE STRING,
        STR     TYPE STRING,
        FTYPE .
  FIELD-SYMBOLS <FS_FLD> .

  IF LOCALFILE IS INITIAL.
    CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG
      EXPORTING
        WINDOW_TITLE         = '文件保存为'
        DEFAULT_FILE_NAME    = LFILE
        DEFAULT_EXTENSION    = 'TXT'
      CHANGING
        FILENAME             = LPATH
        PATH                 = LPATH
        FULLPATH             = LFILE
        USER_ACTION          = ACTION
      EXCEPTIONS
        CNTL_ERROR           = 1
        ERROR_NO_GUI         = 2
        NOT_SUPPORTED_BY_GUI = 3
*       INVALID_DEFAULT_FILE_NAME = 4
        OTHERS               = 5.
    CHECK ACTION = 0 .
    IF SY-SUBRC <> 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
      WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4  .
    ENDIF.
  ELSE.
    LFILE = LOCALFILE.
  ENDIF.

  LC_TDESCR ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( INTAB[] ).
  LC_SDESCR ?= LC_TDESCR->GET_TABLE_LINE_TYPE( ).
  LT_COMP[] = LC_SDESCR->GET_COMPONENTS( ).""获取内表字段结构

  APPEND CL_ABAP_CHAR_UTILITIES=>CR_LF   TO LT_REP.
  APPEND CL_ABAP_CHAR_UTILITIES=>NEWLINE TO LT_REP.
  APPEND CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB TO LT_REP.

  IF HEADER IS NOT INITIAL.
    LOOP AT LT_COMP.
      CONCATENATE STR HTAB LT_COMP-NAME INTO STR.
    ENDLOOP.
    IF SY-SUBRC = 0.
      SHIFT STR.
      APPEND STR TO LT_DOWN.
    ENDIF.
  ENDIF.

  LOOP AT INTAB.
    CLEAR STR.
    DO .
      ASSIGN COMPONENT SY-INDEX OF STRUCTURE INTAB TO <FS_FLD>.
      IF SY-SUBRC <> 0.
        EXIT.
      ENDIF.

      DESCRIBE FIELD <FS_FLD> TYPE FTYPE.
      CASE FTYPE.
        WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
          CHARC = ABS( <FS_FLD> ).
          CONDENSE CHARC NO-GAPS.
          IF <FS_FLD> < 0.
            CONCATENATE '-' CHARC INTO CHARC.
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'D' OR 'T'.
          IF <FS_FLD> IS INITIAL OR <FS_FLD> = ''.
            CHARC = ''.
          ELSE.
            WRITE <FS_FLD> TO CHARC .
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'X' OR 'y' OR 'g'.
          CHARSTR = <FS_FLD> .
        WHEN OTHERS.
          WRITE <FS_FLD> TO CHARC .
          IF REPLACE = 'X'.
            LOOP AT LT_REP.
              REPLACE ALL OCCURRENCES OF LT_REP IN CHARC WITH ''.
            ENDLOOP.
          ENDIF.
          CHARSTR = CHARC.
      ENDCASE.
      CONCATENATE STR HTAB CHARSTR INTO STR.
    ENDDO.
    SHIFT STR.
    APPEND STR TO LT_DOWN.
  ENDLOOP.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      FILENAME = LFILE
      FILETYPE = 'ASC'
      CODEPAGE = '8401'
    TABLES
      DATA_TAB = LT_DOWN
    EXCEPTIONS
      OTHERS   = 22.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4  .
  ELSE.
    MESSAGE S000(OO) WITH '文件下载到：' LFILE.
  ENDIF.

ENDFORM.                    "itabdownload
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将内表数据下载到EXCEL（可带标题）
*若要下载表数据，可配合GETTABDATA/GETFIELDCAT例程使用
*  PERFORM GETTABDATA(ZCPS_PUBLICFORM) TABLES IT_T023T USING 'T023T'.
*  PERFORM GETFIELDCAT(ZCPS_PUBLICFORM) USING 'T023T' CHANGING FIELDCAT.
FORM ITABTOEXCEL TABLES INTAB USING INFIELDCAT TYPE SLIS_T_FIELDCAT_ALV.
  DATA:DEFAULT_PATH     TYPE STRING,
       DEFAULT_FILENAME TYPE STRING,
       FULLPATH         TYPE STRING,
       ACCTION          TYPE I,
       ENCODE           TYPE ABAP_ENCOD,
       APPEND           TYPE C,
       RC               TYPE I,
       WA               TYPE SLIS_FIELDCAT_ALV.

  DATA:BEGIN OF FIELDNAMES OCCURS 0,
         NAME TYPE CHAR40,
       END OF FIELDNAMES.

  CONCATENATE 'DownLoad' SY-DATUM SY-UZEIT '.xls' INTO DEFAULT_FILENAME.
*获取默认桌面路径
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>GET_DESKTOP_DIRECTORY
    CHANGING
      DESKTOP_DIRECTORY    = DEFAULT_PATH
    EXCEPTIONS
      CNTL_ERROR           = 1
      ERROR_NO_GUI         = 2
      NOT_SUPPORTED_BY_GUI = 3
      OTHERS               = 4.
  IF SY-SUBRC = 0.
*弹出文件路径/文件名选择文件夹
    CALL FUNCTION 'GUI_FILE_SAVE_DIALOG'
      EXPORTING
        WINDOW_TITLE      = '导出文件'
        DEFAULT_EXTENSION = '.xls'
        DEFAULT_FILE_NAME = DEFAULT_FILENAME
        FILE_FILTER       = '*.XLS'
        INITIAL_DIRECTORY = DEFAULT_PATH
      IMPORTING
        FULLPATH          = FULLPATH
        USER_ACTION       = ACCTION.

    IF ACCTION NE 9.
*获取系统编码
      CALL METHOD CL_GUI_FRONTEND_SERVICES=>GET_SAPLOGON_ENCODING
        CHANGING
          FILE_ENCODING                 = ENCODE
          RC                            = RC
        EXCEPTIONS
          CNTL_ERROR                    = 1
          ERROR_NO_GUI                  = 2
          NOT_SUPPORTED_BY_GUI          = 3
          CANNOT_INITIALIZE_GLOBALSTATE = 4
          OTHERS                        = 5.

      IF ACCTION = 2.
        REFRESH FIELDNAMES.
        APPEND = 'X'.
      ELSE.
        APPEND = ''.
*获取标题
        LOOP AT INFIELDCAT INTO WA.
          IF WA-SELTEXT_L IS NOT INITIAL.
            FIELDNAMES-NAME = WA-SELTEXT_L.
          ELSEIF WA-SELTEXT_M IS NOT INITIAL.
            FIELDNAMES-NAME = WA-SELTEXT_M.
          ELSEIF WA-SELTEXT_S IS NOT INITIAL.
            FIELDNAMES-NAME = WA-SELTEXT_S.
          ENDIF.
          APPEND FIELDNAMES.
          CLEAR:WA,FIELDNAMES.
        ENDLOOP.
      ENDIF.
*下载表内容
      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          FILENAME   = FULLPATH
          FILETYPE   = 'DAT'
          APPEND     = APPEND
          CODEPAGE   = ENCODE
        TABLES
          DATA_TAB   = INTAB
          FIELDNAMES = FIELDNAMES.
      IF SY-SUBRC <> 0.
        MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
        WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*剪切板上传到内表
FORM CLIPTOITAB TABLES ITAB .
  CONSTANTS: SEPARATOR TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB.  "根据指定符号分割
  DATA: LT_CLIP TYPE TABLE OF CHAR2048 WITH HEADER LINE,
        LT_FLD  TYPE TABLE OF CHAR2048 WITH HEADER LINE.
  DATA: CXROOT TYPE REF TO CX_ROOT,
        EXCMSG TYPE        STRING,
        FTYPE .
  DATA: TABIX TYPE SY-TABIX,
        MOD   TYPE I.
  FIELD-SYMBOLS: <FS_FLD>,<FS_TAB> .

  ASSIGN ITAB TO <FS_TAB> .

  CALL METHOD CL_GUI_FRONTEND_SERVICES=>CLIPBOARD_IMPORT
    IMPORTING
      DATA                 = LT_CLIP[]
    EXCEPTIONS
      CNTL_ERROR           = 1
      ERROR_NO_GUI         = 2
      NOT_SUPPORTED_BY_GUI = 3
      OTHERS               = 4.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4  .
  ENDIF.
  CALL METHOD CL_GUI_CFW=>FLUSH .

  LOOP AT LT_CLIP.
    CLEAR: TABIX,LT_FLD[].
    SPLIT LT_CLIP AT SEPARATOR INTO TABLE LT_FLD.
    LOOP AT LT_FLD.
      TABIX = TABIX + 1.
      ASSIGN COMPONENT TABIX OF STRUCTURE <FS_TAB> TO <FS_FLD>.
      CHECK SY-SUBRC = 0.
      TRY .
          DESCRIBE FIELD <FS_FLD> TYPE FTYPE.
          CASE FTYPE.
            WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
              TRANSLATE LT_FLD USING ', '. "去掉科学计数法的逗号
              CONDENSE LT_FLD NO-GAPS.
            WHEN 'H' OR 'h'.
              CONTINUE.
          ENDCASE.
          <FS_FLD> = LT_FLD.
        CATCH  CX_ROOT INTO CXROOT.
          EXCMSG = CXROOT->GET_TEXT( ).
      ENDTRY.
    ENDLOOP.
    APPEND ITAB .
    CLEAR ITAB.
  ENDLOOP.
  IF EXCMSG IS NOT INITIAL.
    MESSAGE S000(OO) WITH '数据转换有错误发生，已经忽略'(M05) DISPLAY LIKE 'W'.
  ENDIF.
ENDFORM.                    "cliptoitab
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*上传TXT至内表
FORM TXTTOITAB TABLES OUTTAB USING INFILESTR.
  DATA:FIELDNAME TYPE STRING.
  IF INFILESTR IS NOT INITIAL.
    FIELDNAME = INFILESTR.
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        FILENAME            = FIELDNAME "如有乱码,把文本文件存为UTF-8格式
        FILETYPE            = 'ASC'
        HAS_FIELD_SEPARATOR = 'X'
      TABLES
        DATA_TAB            = OUTTAB
      EXCEPTIONS
        OTHERS              = 1.
    IF SY-SUBRC = 1.
      MESSAGE E000(OO) WITH '文件打开错误'.
    ENDIF.
  ELSE.
    MESSAGE E000(OO) WITH '文件路径不能为空'.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*上传EXCEL
*DATA: INTERN    TYPE TABLE OF ALSMEX_TABLINE WITH HEADER LINE.
FORM EXCELTOITAB TABLES OUTINTERN STRUCTURE ALSMEX_TABLINE
USING INFILEPATH TYPE LOCALFILE
      COL TYPE I.
*& 调用BAPI ALSM_EXCEL_TO_INTERNAL_TABLE 导入数据
  IF INFILEPATH IS NOT INITIAL AND COL > 1.
    CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
      EXPORTING
        FILENAME                = INFILEPATH
        I_BEGIN_COL             = 1
        I_BEGIN_ROW             = 2
        I_END_COL               = COL
        I_END_ROW               = 9999
      TABLES
        INTERN                  = OUTINTERN
      EXCEPTIONS
        INCONSISTENT_PARAMETERS = 1
        UPLOAD_OLE              = 2
        OTHERS                  = 3.
    IF OUTINTERN[] IS INITIAL.
      MESSAGE  '上载数据失败' TYPE 'E'.
      STOP.
    ENDIF.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*将通过ALSM_EXCEL_TO_INTERNAL_TABLE上传解析出来的数据拆成内表(鸡肋功能)
FORM EXCELDATATOITAB TABLES INEXCELTAB STRUCTURE ALSMEX_TABLINE OUTTAB.
  DATA:IT_FIELDCAT_LVC TYPE LVC_T_FCAT,
       WA_FIELDCAT_LVC TYPE LVC_S_FCAT,
       ITAB            TYPE REF TO DATA,
       WA              TYPE REF TO DATA,
       IT_FIELDCAT     TYPE SLIS_T_FIELDCAT_ALV,
       WA_INFIELDCAT   TYPE SLIS_FIELDCAT_ALV,
       CXROOT          TYPE REF TO CX_ROOT,
       OUTMSG          TYPE BAPI_MSG,
       TABIX           TYPE NUMC4,
       INDEX           TYPE NUMC4,
       FTYPE.
  FIELD-SYMBOLS:<ITAB>     TYPE TABLE,
                <WA>       TYPE ANY,
                <FS1>,
                <FS2>,
                <FS_VALUE> TYPE ANY.



  IF INEXCELTAB[] IS INITIAL .
    RETURN.
  ENDIF.
  SORT INEXCELTAB BY ROW COL.

  PERFORM GETTABSTRU USING OUTTAB CHANGING IT_FIELDCAT.

*获取布局结构
  LOOP AT IT_FIELDCAT INTO WA_INFIELDCAT.
    WA_FIELDCAT_LVC-FIELDNAME = WA_INFIELDCAT-FIELDNAME.
    WA_FIELDCAT_LVC-COLTEXT = WA_INFIELDCAT-FIELDNAME.
    WA_FIELDCAT_LVC-ROW_POS = SY-TABIX.
    WA_FIELDCAT_LVC-DATATYPE = 'CHAR'.
    CASE WA_INFIELDCAT-INTTYPE.
      WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
        WA_FIELDCAT_LVC-INTLEN = WA_INFIELDCAT-INTLEN * 2 - 1.
      WHEN OTHERS.
        IF WA_INFIELDCAT-INTLEN IS INITIAL.
          WA_FIELDCAT_LVC-INTLEN = '220'.
        ELSE.
          WA_FIELDCAT_LVC-INTLEN = WA_INFIELDCAT-INTLEN.
        ENDIF.
    ENDCASE.

    APPEND WA_FIELDCAT_LVC TO IT_FIELDCAT_LVC.
    CLEAR:WA_INFIELDCAT,WA_FIELDCAT_LVC.
  ENDLOOP.
*根据FIELDCAT生成内表
  CALL METHOD CL_ALV_TABLE_CREATE=>CREATE_DYNAMIC_TABLE
    EXPORTING
      IT_FIELDCATALOG = IT_FIELDCAT_LVC
    IMPORTING
      EP_TABLE        = ITAB.
*分配指针
  ASSIGN ITAB->* TO <ITAB>.
  CREATE DATA WA LIKE LINE OF <ITAB>.
  ASSIGN WA->* TO <WA>.
*将数据分配进内表
  LOOP AT INEXCELTAB.
    CONDENSE INEXCELTAB-VALUE NO-GAPS.
    READ TABLE IT_FIELDCAT_LVC INTO WA_FIELDCAT_LVC INDEX INEXCELTAB-COL.
    ASSIGN COMPONENT WA_FIELDCAT_LVC-FIELDNAME OF STRUCTURE <WA> TO <FS_VALUE>.
    IF SY-SUBRC = 0.
      <FS_VALUE> = INEXCELTAB-VALUE.
    ENDIF.
    AT END OF ROW.
      APPEND <WA> TO <ITAB>.
      CLEAR <WA>.
    ENDAT.
    CLEAR INEXCELTAB.
  ENDLOOP.
*传递内表值，数据转换出现错误则报错但不DUMP
*千分位本应去除，但考虑到上传的文本可能存在',''，所以直接报错
  LOOP AT <ITAB> INTO <WA>.
    CLEAR:OUTMSG,TABIX.
    TABIX = SY-TABIX.
*去千分位
    DO.
      CLEAR:INDEX,FTYPE.
      INDEX = SY-INDEX.
      ASSIGN COMPONENT INDEX OF STRUCTURE <WA> TO <FS1>.
      IF SY-SUBRC <> 0.
        EXIT.
      ENDIF.
      READ TABLE IT_FIELDCAT_LVC INTO WA_FIELDCAT_LVC INDEX INDEX.
      IF SY-SUBRC = 0.
        ASSIGN COMPONENT WA_FIELDCAT_LVC-FIELDNAME OF STRUCTURE OUTTAB TO <FS2>.
        IF SY-SUBRC = 0.
          DESCRIBE FIELD <FS2> TYPE FTYPE.
          CASE FTYPE.
            WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
              PERFORM DELQFW(ZPUBFORM) CHANGING <FS1>.
          ENDCASE.
        ENDIF.
      ENDIF.
    ENDDO.
    TRY .
        MOVE-CORRESPONDING <WA> TO OUTTAB.
      CATCH CX_ROOT INTO CXROOT .
        OUTMSG = CXROOT->GET_TEXT( ).
    ENDTRY.
    IF OUTMSG IS NOT INITIAL.
      CONCATENATE TABIX '行' OUTMSG INTO OUTMSG.
      MESSAGE E000(OO) WITH OUTMSG.
    ENDIF.
    APPEND OUTTAB.
    CLEAR:OUTTAB.
  ENDLOOP.
ENDFORM.
*根据本地EXCEL路径转化为SAP内表数据
FORM EXCELTOITABP TABLES P_OUTTAB
  USING P_INFILEPATH TYPE LOCALFILE
         P_COL TYPE I.
  DATA: IT_INTERN TYPE TABLE OF ALSMEX_TABLINE WITH HEADER LINE.
  REFRESH:IT_INTERN.
  PERFORM EXCELTOITAB(ZPUBFORM) TABLES IT_INTERN
    USING P_INFILEPATH P_COL.

  CHECK IT_INTERN[] IS NOT INITIAL.

  PERFORM EXCELDATATOITAB(ZPUBFORM) TABLES IT_INTERN P_OUTTAB.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR FILESTR .
*获取文件路径名称
FORM GETFILEROUTE USING INFILETYPE
CHANGING OUTFILESTR.
  DATA: RC         TYPE I,
        FILE_TABLE TYPE FILETABLE WITH HEADER LINE,
        FILETYPE   TYPE STRING.
  CASE INFILETYPE.
    WHEN 'EXCEL'.
      FILETYPE = '*.XLS'.
    WHEN 'TXT'.
      FILETYPE = '*.TXT'.
    WHEN OTHERS.
      CLEAR FILETYPE.
  ENDCASE.
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
    EXPORTING
      FILE_FILTER             = FILETYPE
      MULTISELECTION          = ''
    CHANGING
      FILE_TABLE              = FILE_TABLE[]
      RC                      = RC
    EXCEPTIONS
      FILE_OPEN_DIALOG_FAILED = 1
      CNTL_ERROR              = 2
      ERROR_NO_GUI            = 3
      NOT_SUPPORTED_BY_GUI    = 4
      OTHERS                  = 5.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ELSE.
    READ TABLE FILE_TABLE INDEX 1.
    OUTFILESTR = FILE_TABLE.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取文件夹名称
FORM GETFOLDER CHANGING FILENAME TYPE LOCALFILE .
  DATA:DIRPATH TYPE STRING.
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>DIRECTORY_BROWSE
    EXPORTING
      WINDOW_TITLE    = '选择目录'
      INITIAL_FOLDER  = 'D:\'
    CHANGING
      SELECTED_FOLDER = DIRPATH. "该参数为string类型
  FILENAME = DIRPATH.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取本地电脑文件EXCEL名称
*PARAMETERS:P_FILE LIKE RLGRAP-FILENAME.
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_FILE.
*PERFORM GETFILENAME CHANGING P_FILE.
FORM GETEXCELROUTE CHANGING FILENAME TYPE LOCALFILE.
  DATA: L_FILENAME LIKE RLGRAP-FILENAME.

  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
*     DEF_FILENAME     = ',*.XLSX,*.XLSX;,*.XLS,*.XLS;'
*     DEF_PATH         = ' '
      MASK             = ',*.XLS,*.XLS;,*.XLSX,*.XLSX;'
      MODE             = 'O'
*     TITLE            = ' '
    IMPORTING
      FILENAME         = L_FILENAME
*     RC               =
    EXCEPTIONS
      INV_WINSYS       = 1
      NO_BATCH         = 2
      SELECTION_CANCEL = 3
      SELECTION_ERROR  = 4
      OTHERS           = 5.
  IF SY-SUBRC = 0.
    FILENAME = L_FILENAME.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*EXCEL下载
FORM DOWNEXCEL USING OBJID FILENAME .
  DATA: LS_WWWDATA  TYPE WWWDATATAB,
        LS_MIME     TYPE W3MIME,
        LV_FILENAME TYPE STRING , "默认文件名
        LV_PATH     TYPE STRING VALUE 'C:\Documents\Desktop', "默认路径
        LV_FULLPATH TYPE STRING , "默认完全路径
        LV_OBJID    TYPE WWWDATATAB-OBJID , "上传的EXCEL时设置的对象名
        LV_MSG      TYPE CHAR100,
        LV_SUBRC    LIKE SY-SUBRC,
        LV_ROW      TYPE CHAR4,
        LV_ZS       TYPE CHAR5,
        LV_YX       TYPE CHAR5,
        GV_FILE     TYPE LOCALFILE. "文件完整路径
*& begin 获取模板文件路径并下载
  "打开保存文件对话框
  LV_OBJID = OBJID.
  LV_FILENAME = FILENAME.
  CONCATENATE 'C:\Documents\Desktop\' LV_FILENAME INTO LV_FULLPATH.
  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG
    EXPORTING
      WINDOW_TITLE         = LV_FILENAME "标题
      DEFAULT_EXTENSION    = 'xls' "文件类型
      DEFAULT_FILE_NAME    = LV_FILENAME "默认文件名
    CHANGING
      FILENAME             = LV_FILENAME "传出文件名
      PATH                 = LV_PATH "传出路径
      FULLPATH             = LV_FULLPATH "传出完全路径           =
    EXCEPTIONS
      CNTL_ERROR           = 1
      ERROR_NO_GUI         = 2
      NOT_SUPPORTED_BY_GUI = 3
*     INVALID_DEFAULT_FILE_NAME = 4
      OTHERS               = 5.
  IF SY-SUBRC <> 0.
    MESSAGE '调用文件保存对话框出错' TYPE 'E'.
  ELSE.
    "赋值文件完整路径
    GV_FILE = LV_FULLPATH.
    "检查模板是否已存在SAP中
    SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF LS_WWWDATA
    FROM WWWDATA
    WHERE SRTF2 = 0
    AND RELID = 'MI'"MIME类型
    AND OBJID = LV_OBJID.
    IF SY-SUBRC NE 0.
      CONCATENATE '模板' LV_OBJID '.xls不存在' INTO LV_MSG.
      MESSAGE LV_MSG TYPE 'E'.
    ELSE."模板文件存在则下载模板

      CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
        EXPORTING
          KEY         = LS_WWWDATA "对象
          DESTINATION = GV_FILE "完整下载路径
        IMPORTING
          RC          = LV_SUBRC.
*       CHANGING
*         TEMP        = TEMP
      IF LV_SUBRC NE 0.
        CONCATENATE '模板' LV_OBJID '.xls下载失败' INTO LV_MSG.
        MESSAGE LV_MSG TYPE 'E'.
      ENDIF.
    ENDIF.
  ENDIF.
*& end 获取模板文件路径并下载
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*获取打印名称打印开启
FORM PRINT_OPEN USING INFORMNAME
      INUCOMM
CHANGING FMNAME.
  DATA: CTRLPARAM     TYPE SSFCTRLOP,
        COMPPARAM     TYPE SSFCOMPOP,
        OUTOPTION     TYPE SSFCRESOP,
        FORMNAME      TYPE TDSFNAME,
        USER_SETTINGS TYPE TDBOOL.
  FORMNAME = INFORMNAME.

*打印
  CTRLPARAM-NO_OPEN   = 'X'.
  CTRLPARAM-NO_CLOSE  = 'X'.
  COMPPARAM-TDIEXIT   = 'X'.
  USER_SETTINGS = 'X'.

  CASE INUCOMM.
    WHEN 'PREVIEW'."只预览
      CTRLPARAM-NO_DIALOG = 'X'.
      CTRLPARAM-PREVIEW = 'X'.
      COMPPARAM-TDNOPRINT = 'X'.
    WHEN 'PDF'."下载PDF
      CTRLPARAM-GETOTF    = 'X'.
      CTRLPARAM-NO_DIALOG = 'X'.
      COMPPARAM-TDDEST    = 'LP01'.
      USER_SETTINGS = ''.
  ENDCASE.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      FORMNAME           = FORMNAME
    IMPORTING
      FM_NAME            = FMNAME
    EXCEPTIONS
      NO_FORM            = 1
      NO_FUNCTION_MODULE = 2
      OTHERS             = 3.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CALL FUNCTION 'SSF_OPEN'
    EXPORTING
      CONTROL_PARAMETERS = CTRLPARAM
      OUTPUT_OPTIONS     = COMPPARAM
      USER_SETTINGS      = USER_SETTINGS
    IMPORTING
      JOB_OUTPUT_OPTIONS = OUTOPTION
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*打印数据输入
FORM PRINT_INPUT TABLES INTAB USING INFMNAME INUCOMM.
  DATA: CTRLPARAM TYPE SSFCTRLOP,
        COMPPARAM TYPE SSFCOMPOP,
        FMNAME    TYPE TDSFNAME.
  FMNAME = INFMNAME.

  CTRLPARAM-NO_OPEN   = 'X'.
  CTRLPARAM-NO_CLOSE  = 'X'.
  COMPPARAM-TDIEXIT   = 'X'.

  IF INUCOMM = 'PDF'.
    CTRLPARAM-GETOTF    = 'X'.
    CTRLPARAM-NO_DIALOG = 'X'.
    COMPPARAM-TDDEST    = 'LP01'.
  ENDIF.

  CALL FUNCTION FMNAME
    EXPORTING
      CONTROL_PARAMETERS = CTRLPARAM
      OUTPUT_OPTIONS     = COMPPARAM
      USER_SETTINGS      = ''
    TABLES
      INTAB              = INTAB
    EXCEPTIONS
      FORMATTING_ERROR   = 1
      INTERNAL_ERROR     = 2
      SEND_ERROR         = 3
      USER_CANCELED      = 4
      OTHERS             = 5.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*打印关闭
FORM PRINT_CLOSE USING INUCOMM CHANGING FLAG.
  DATA:PDFTAB       TYPE TABLE OF TLINE WITH HEADER LINE,
       OUTPUTINFO   TYPE SSFCRESCL,
       BIN_FILESIZE TYPE I,
       FILENAME     TYPE STRING,
       PATH         TYPE STRING,
       FULLPATH     TYPE STRING,
       ACTION       TYPE I.
  CALL FUNCTION 'SSF_CLOSE'
    IMPORTING
      JOB_OUTPUT_INFO  = OUTPUTINFO
    EXCEPTIONS
      FORMATTING_ERROR = 1
      INTERNAL_ERROR   = 2
      SEND_ERROR       = 3
      OTHERS           = 4.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ELSE.
*判断是否已打印
    IF OUTPUTINFO-OUTPUTDONE = 'X'.
      FLAG = 'X'.
    ELSE.
      FLAG = ''.
    ENDIF.
**********************************
*PDF下载
    IF INUCOMM = 'PDF' AND OUTPUTINFO-OTFDATA[] IS NOT INITIAL.
      CLEAR PDFTAB[].
*
*      CALL FUNCTION 'DISPLAY_OTF'
** EXPORTING
**   CONTROL           = ' '
**   SHOW_DIALOG       = ' '
** IMPORTING
**   RESULT            =
*        TABLES
*          OTF = OUTPUTINFO-OTFDATA.

      CALL FUNCTION 'CONVERT_OTF'
        EXPORTING
          FORMAT                = 'PDF'
        IMPORTING
          BIN_FILESIZE          = BIN_FILESIZE
        TABLES
          OTF                   = OUTPUTINFO-OTFDATA
          LINES                 = PDFTAB
        EXCEPTIONS
          ERR_MAX_LINEWIDTH     = 1
          ERR_FORMAT            = 2
          ERR_CONV_NOT_POSSIBLE = 3
          OTHERS                = 4.

      CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG
        EXPORTING
          DEFAULT_FILE_NAME    = FILENAME
          WINDOW_TITLE         = '文件保存为'
          DEFAULT_EXTENSION    = 'PDF'
          FILE_FILTER          = '(*.PDF)|*.PDF|'
        CHANGING
          FILENAME             = FILENAME
          PATH                 = PATH
          FULLPATH             = FULLPATH
          USER_ACTION          = ACTION
        EXCEPTIONS
          CNTL_ERROR           = 1
          ERROR_NO_GUI         = 2
          NOT_SUPPORTED_BY_GUI = 3
          OTHERS               = 4.

      CHECK FULLPATH <> '' AND ACTION = 0 .

      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          BIN_FILESIZE = BIN_FILESIZE
          FILENAME     = FULLPATH
          FILETYPE     = 'BIN'
        TABLES
          DATA_TAB     = PDFTAB.
      IF SY-SUBRC <> 0.
        MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
        WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
    ENDIF.
**********************************
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*下载透明表结构
FORM DOWNDATABASE TABLES IT_OUT
                  USING TABLENAME DOWN.
  DATA:BEGIN OF OUTSTRUCTURE OCCURS 0,
         FIELDNAME    LIKE DFIES-FIELDNAME,  "Fieldname
         KEYFLAG(4),    "KEY
         ROLLNAME(12),   "Data Element
         DATATYPE(8),   "Data Type
         LENG(6),       "Length
         DECIMALS(6),   "Decimal Place
         FIELDTEXT    LIKE DFIES-FIELDTEXT,  "Short Description
         NUM          TYPE SY-TABIX,
       END OF OUTSTRUCTURE.
  DATA:ITAB     TYPE TABLE OF DFIES WITH HEADER LINE,
       FILEPATH LIKE RLGRAP-FILENAME.   "下载保存路径
  DATA:LV_PATH     TYPE STRING, " VALUE 'C:\Documents\Desktop', "默认路径
       LV_FULLPATH TYPE STRING , "默认完全路径
       LV_FILENAME TYPE STRING,
       FILENAMEN   TYPE LOCALFILE.

  CHECK TABLENAME IS NOT INITIAL.
  REFRESH:OUTSTRUCTURE.

  LV_FILENAME = TABLENAME.
  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      TABNAME        = TABLENAME
      LANGU          = SY-LANGU "这个可以改成别的语言,For Short Descriptions
    TABLES
      DFIES_TAB      = ITAB " like table dfies.
    EXCEPTIONS
      NOT_FOUND      = 1
      INTERNAL_ERROR = 2
      OTHERS         = 3.

  OUTSTRUCTURE-FIELDNAME = '字段'.  "Fieldname
  OUTSTRUCTURE-KEYFLAG = '主键'.    "KEY
  OUTSTRUCTURE-ROLLNAME = '数据元素'.   "Data Element
  OUTSTRUCTURE-DATATYPE = '数据类型'.   "Data Type
  OUTSTRUCTURE-LENG = '长度'.       "Length
  OUTSTRUCTURE-DECIMALS = '小数位'.  "Decimal Place
  OUTSTRUCTURE-FIELDTEXT = '短文本'.  "Short Description
  APPEND OUTSTRUCTURE.
  CLEAR OUTSTRUCTURE.

  LOOP AT ITAB.
    OUTSTRUCTURE-FIELDNAME = ITAB-FIELDNAME.
    OUTSTRUCTURE-KEYFLAG = ITAB-KEYFLAG.
    OUTSTRUCTURE-ROLLNAME = ITAB-ROLLNAME.
    OUTSTRUCTURE-DATATYPE = ITAB-DATATYPE.
    OUTSTRUCTURE-LENG = ITAB-LENG.
    OUTSTRUCTURE-DECIMALS = ITAB-DECIMALS.
    OUTSTRUCTURE-FIELDTEXT = ITAB-FIELDTEXT.
    APPEND OUTSTRUCTURE.
    CLEAR OUTSTRUCTURE.
  ENDLOOP.
  LOOP AT OUTSTRUCTURE.
    CLEAR IT_OUT.
    MOVE-CORRESPONDING OUTSTRUCTURE TO IT_OUT.
    APPEND IT_OUT.
  ENDLOOP.

  IF DOWN = 'X'.
    CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_SAVE_DIALOG
      EXPORTING
        WINDOW_TITLE         = LV_FILENAME "标题
        DEFAULT_EXTENSION    = 'xls' "文件类型
        DEFAULT_FILE_NAME    = LV_FILENAME "默认文件名
      CHANGING
        FILENAME             = LV_FILENAME "传出文件名
        PATH                 = LV_PATH "传出路径
        FULLPATH             = LV_FULLPATH "传出完全路径           =
      EXCEPTIONS
        CNTL_ERROR           = 1
        ERROR_NO_GUI         = 2
        NOT_SUPPORTED_BY_GUI = 3
*       INVALID_DEFAULT_FILE_NAME = 4
        OTHERS               = 5.

    FILEPATH = LV_FULLPATH.
    CALL FUNCTION 'WS_DOWNLOAD'
      EXPORTING
        FILENAME = FILEPATH
        FILETYPE = 'DAT'
      TABLES
        DATA_TAB = OUTSTRUCTURE.  "被下载的内表
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*下载源码
FORM DOWNCODE USING FILEPATH TYPE LOCALFILE"本地地址
      NAME "项目名称
      PACK TYPE DEVCLASS"包名
      OBJECT TYPE TROBJTYPE"程序类型
      PRONAME TYPE SOBJ_NAME"程序名称
      INCLUDE "INCLUDE名称
      PROTEXT"程序描述
CHANGING MSG TYPE BAPI_MSG.
  DATA:SOURCECODE TYPE STANDARD TABLE OF STRING WITH HEADER LINE, "CODELINE
       FILENAME   TYPE STRING,
       FILENAME1  TYPE STRING,
       FILENAME2  TYPE STRING,
       FILEPATHN  TYPE LOCALFILE,
       MESSAGE    TYPE BAPI_MSG,
       PROGRAM    TYPE SOBJ_NAME,
       LCX_ERROR  TYPE REF TO CX_ROOT.
  IF PRONAME IS NOT INITIAL AND INCLUDE IS NOT INITIAL.
    TRY .
        READ REPORT INCLUDE INTO SOURCECODE.
      CATCH CX_SY_READ_SRC_LINE_TOO_LONG INTO LCX_ERROR.
        MESSAGE = LCX_ERROR->GET_TEXT( ).
        SY-SUBRC = 4.
    ENDTRY.

    IF SY-SUBRC EQ 0.
      IF FILEPATH IS NOT INITIAL.
        FILEPATHN = FILEPATH.
      ELSE.
        FILEPATHN = 'C:\ABAP\'.
      ENDIF.
      CONCATENATE INCLUDE '-' PROTEXT '-' SY-UZEIT '.txt' INTO FILENAME1.
      CONCATENATE PACK '-' OBJECT INTO FILENAME2.
      CONCATENATE FILEPATHN
      NAME
      SY-DATUM
      SY-UZEIT+0(2)
      FILENAME2
      PRONAME
      FILENAME1
      INTO FILENAME
      SEPARATED BY '\'.
*      DATA:CODEPAGE TYPE ABAP_ENCODING,
*           RC TYPE I.
*      CALL METHOD CL_GUI_FRONTEND_SERVICES=>GET_SAPLOGON_ENCODING
*        CHANGING
*          FILE_ENCODING                 = CODEPAGE
*          RC                            = RC
*        EXCEPTIONS
*          CNTL_ERROR                    = 1
*          ERROR_NO_GUI                  = 2
*          NOT_SUPPORTED_BY_GUI          = 3
*          CANNOT_INITIALIZE_GLOBALSTATE = 4
*          others                        = 5.


      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          FILENAME                = FILENAME
*         CODEPAGE                = CODEPAGE
        TABLES
          DATA_TAB                = SOURCECODE
        EXCEPTIONS
          FILE_WRITE_ERROR        = 1
          NO_BATCH                = 2
          GUI_REFUSE_FILETRANSFER = 3
          INVALID_TYPE            = 4
          NO_AUTHORITY            = 5
          UNKNOWN_ERROR           = 6
          HEADER_NOT_ALLOWED      = 7
          SEPARATOR_NOT_ALLOWED   = 8
          FILESIZE_NOT_ALLOWED    = 9
          HEADER_TOO_LONG         = 10
          DP_ERROR_CREATE         = 11
          DP_ERROR_SEND           = 12
          DP_ERROR_WRITE          = 13
          UNKNOWN_DP_ERROR        = 14
          ACCESS_DENIED           = 15
          DP_OUT_OF_MEMORY        = 16
          DISK_FULL               = 17
          DP_TIMEOUT              = 18
          FILE_NOT_FOUND          = 19
          DATAPROVIDER_EXCEPTION  = 20
          CONTROL_FLUSH_ERROR     = 21
          OTHERS                  = 22.
      IF SY-SUBRC NE 0.
        DATA:ZMSG TYPE BAPI_MSG.
        PERFORM MSGTOTEXT USING '' '' '' '' '' ''
        CHANGING ZMSG.
      ENDIF.
    ELSE.
      MSG = MESSAGE.
      MESSAGE S000(OO) WITH MESSAGE DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*根据表名，用当前系统语言将表/视图中按筛选条件将数据取出，并针对主键排序
*主要用于取文本表，对于大的凭证表，请勿使用本程序
FORM GETTABDATA TABLES OUTTAB
USING INTABNAM
      INSELSTR .
  DATA: ITAB      TYPE REF TO DATA,
        WA        TYPE REF TO DATA,
        DOMNAME   TYPE DD03P-DOMNAME,
        FLAG      TYPE CHAR1,
        SELSTR    TYPE CHAR255,
        SORTSTR   TYPE CHAR255,
        WA_DD02L  TYPE DD02L,
        IT_TABLES TYPE TABLE OF EXP_TABLROWS WITH HEADER LINE, " DDCDIM WITH HEADER LINE,"
        DD03P_TAB TYPE TABLE OF DD03P WITH HEADER LINE.
  FIELD-SYMBOLS: <ITAB> TYPE TABLE.

  SELECT SINGLE *
  INTO WA_DD02L
  FROM DD02L
  WHERE TABNAME = INTABNAM
  AND   TABCLASS EQ 'TRANSP'.
  IF SY-SUBRC = 0.
*超过100万条数据的表不取数
    IT_TABLES-TABNAME = INTABNAM.
    APPEND IT_TABLES.
    CLEAR IT_TABLES.

    CALL FUNCTION 'EM_GET_NUMBER_OF_ENTRIES'
      TABLES
        IT_TABLES = IT_TABLES.
    READ TABLE IT_TABLES INDEX 1.
    IF IT_TABLES-TABROWS > 99999.
      RETURN.
    ENDIF.
*参照表获取内表
    CREATE DATA ITAB TYPE TABLE OF (INTABNAM).
    ASSIGN ITAB->* TO <ITAB>.
*获取表结构
    CALL FUNCTION 'DDIF_TABL_GET'
      EXPORTING
        NAME          = INTABNAM
        LANGU         = SY-LANGU
      TABLES
        DD03P_TAB     = DD03P_TAB
      EXCEPTIONS
        ILLEGAL_INPUT = 1
        OTHERS        = 2.
*按照语言筛选
    READ TABLE DD03P_TAB WITH KEY DATATYPE = 'LANG' KEYFLAG = 'X'.
    IF SY-SUBRC = 0.
      DOMNAME = DD03P_TAB-FIELDNAME.
      CONCATENATE DOMNAME  '=' 'SY-LANGU' INTO SELSTR SEPARATED BY SPACE.
      FLAG = 'X'.
    ENDIF.
*按照输入条件筛选
    IF INSELSTR IS NOT INITIAL.
      IF SELSTR IS INITIAL.
        SELSTR = INSELSTR.
      ELSE.
        CONCATENATE SELSTR 'AND' INSELSTR INTO SELSTR SEPARATED BY SPACE.
      ENDIF.
    ENDIF.
*按照主键排序(视图不排序)
    DELETE DD03P_TAB WHERE KEYFLAG NE 'X'
    OR DATATYPE EQ 'CLNT'
    OR DATATYPE EQ 'LANG'.
    LOOP AT DD03P_TAB.
      CONCATENATE SORTSTR DD03P_TAB-FIELDNAME INTO SORTSTR SEPARATED BY SPACE.
      CLEAR DD03P_TAB.
    ENDLOOP.

    SELECT *
    INTO TABLE <ITAB>
    FROM (INTABNAM)
    WHERE (SELSTR)
    ORDER BY (SORTSTR).

    OUTTAB[] = <ITAB>.
  ELSE.
    MESSAGE E000(OO) WITH '输入名称不是标准表/视图'.
    RETURN.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*SUBMIT程序获取ALV运行内容
"应传入程序名注意结构字段数据类型必须与ALV内表结构完全一致
FORM GETREPORTALV TABLES OUTTAB INSELTAB STRUCTURE RSPARAMS
USING INREPORT.
  DATA:CURR_REPORT TYPE RSVAR-REPORT,
       GT_RSPARAMS TYPE TABLE OF RSPARAMS WITH HEADER LINE,
       OUTMSG      TYPE BAPI_MSG,
       CXROOT      TYPE REF TO CX_ROOT,
       ITAB_ALV    TYPE REF TO DATA,
       WA_ALV      TYPE REF TO DATA.
  FIELD-SYMBOLS:<ITAB> TYPE TABLE,
                <WA>   TYPE ANY.
  IF INREPORT IS INITIAL.
    MESSAGE E000(OO) WITH '传入程序名及结构名为空'.
    RETURN.
  ENDIF.
  CURR_REPORT = INREPORT.
*获取程序选择屏幕值
  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
    EXPORTING
      CURR_REPORT     = CURR_REPORT
    TABLES
      SELECTION_TABLE = GT_RSPARAMS
    EXCEPTIONS
      NOT_FOUND       = 1
      NO_REPORT       = 2
      OTHERS          = 3.
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.
*填入选择屏幕值
  IF INSELTAB[] IS NOT INITIAL.
    SORT INSELTAB BY SELNAME.
    LOOP AT GT_RSPARAMS.
      READ TABLE INSELTAB WITH KEY SELNAME = GT_RSPARAMS-SELNAME BINARY SEARCH.
      IF SY-SUBRC = 0.
        GT_RSPARAMS-KIND = INSELTAB-KIND.
        GT_RSPARAMS-SIGN = INSELTAB-SIGN.
        GT_RSPARAMS-OPTION = INSELTAB-OPTION.
        GT_RSPARAMS-LOW = INSELTAB-LOW.
        GT_RSPARAMS-HIGH = INSELTAB-HIGH.
      ENDIF.
      MODIFY GT_RSPARAMS.
      CLEAR GT_RSPARAMS.
    ENDLOOP.
  ENDIF.

  CL_SALV_BS_RUNTIME_INFO=>SET( EXPORTING DISPLAY  = ABAP_FALSE
    METADATA = ABAP_FALSE
  DATA     = ABAP_TRUE ).
*调用程序(注意自开发程序中可编辑字段会使程序DUMP)
  SUBMIT (CURR_REPORT)
  WITH SELECTION-TABLE GT_RSPARAMS
  EXPORTING LIST TO MEMORY AND RETURN.
*根据结构动态创建内表及工作区
*  CREATE DATA ITAB_ALV TYPE TABLE OF (TABNAME).
*ASSIGN ITAB_ALV->* TO <ITAB>.
*  CREATE DATA WA_ALV LIKE LINE OF <ITAB>.
*  ASSIGN WA_ALV->* TO <WA>."对于有深层结构的结构，内表工作区分配有问题
*分配内存
  TRY .
*两种写法，GET_DATA需要明确知道结构，GET_DATA_REF不需要
*  CALL METHOD CL_SALV_BS_RUNTIME_INFO=>GET_DATA
*    IMPORTING
*      T_DATA = <ITAB>.
      CALL METHOD CL_SALV_BS_RUNTIME_INFO=>GET_DATA_REF
        IMPORTING
          R_DATA = ITAB_ALV.
    CATCH CX_ROOT INTO CXROOT .
      OUTMSG = CXROOT->GET_TEXT( ).
      CONCATENATE 'E:' OUTMSG INTO OUTMSG.
  ENDTRY.
  ASSIGN ITAB_ALV->* TO <ITAB>.
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.
*  CREATE DATA WA_ALV LIKE LINE OF <ITAB>.
*  ASSIGN WA_ALV->* TO <WA>."对于有深层结构的结构，内表工作区分配有问题
  CL_SALV_BS_RUNTIME_INFO=>CLEAR_ALL( ).
  IF OUTMSG+0(1) NE 'E'.
    LOOP AT <ITAB> ASSIGNING <WA>.
      MOVE-CORRESPONDING <WA> TO OUTTAB.
*      OUTTAB = <WA>.
      APPEND OUTTAB.
      CLEAR:OUTTAB.
    ENDLOOP.
  ELSE.
    MESSAGE E000(OO) WITH OUTMSG.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
**********BEGIN 08.05.2020 08:59:47********************************************
*公共取数部分
*根据用户名获取全名/函数FDM_CUST_USER_NAME_READ_SINGLE,但要有SU01权限
FORM GETNAME USING INUNAME CHANGING OUTNAME.
  DATA:PERSNUMBER TYPE ADRP-PERSNUMBER,
       NAME_LAST  TYPE ADRP-NAME_LAST,
       NAME_FIRST TYPE ADRP-NAME_FIRST.
  SELECT SINGLE ADRP~PERSNUMBER
                ADRP~NAME_LAST
                ADRP~NAME_FIRST
  INTO (PERSNUMBER,NAME_LAST,NAME_FIRST)
  FROM ADRP INNER JOIN USR21 ON ADRP~PERSNUMBER = USR21~PERSNUMBER
  WHERE USR21~BNAME = INUNAME.
  CONCATENATE NAME_LAST NAME_FIRST INTO OUTNAME.
ENDFORM.
*根据工厂获取公司代码，名称
FORM GET_WERKS_BUKRS TABLES OUT_WERKS_BUKRS .
  DATA:BEGIN OF REF_WERKS_BUKRS OCCURS 0,
         BUKRS TYPE T001-BUKRS,
         BUTXT TYPE T001-BUTXT,
         WERKS TYPE WERKS_D,
         NAME1 TYPE NAME1,
       END OF REF_WERKS_BUKRS.
  SELECT T001K~BUKRS
         T001~BUTXT
         T001W~WERKS
         T001W~NAME1
  INTO TABLE REF_WERKS_BUKRS
  FROM T001K INNER JOIN T001W ON T001K~BWKEY = T001W~BWKEY
             INNER JOIN T001 ON T001K~BUKRS = T001~BUKRS.
  LOOP AT REF_WERKS_BUKRS.
    CLEAR:OUT_WERKS_BUKRS.
    MOVE-CORRESPONDING REF_WERKS_BUKRS TO OUT_WERKS_BUKRS.
    APPEND OUT_WERKS_BUKRS.
  ENDLOOP.
ENDFORM.
*根据工厂获取公司
FORM GETBUKRS USING P_IN_WERKS CHANGING P_OUT_BUKRS.
  DATA:IT_WERKS_BUKRS TYPE TABLE OF CNV_PE_S4_S_WERKS_BUKRS"J_7LBAPI_CC_PLANT
        WITH HEADER LINE.
  CHECK P_IN_WERKS IS NOT INITIAL.
  REFRESH:IT_WERKS_BUKRS.
  SELECT T001W~WERKS
         T001K~BUKRS
  INTO TABLE IT_WERKS_BUKRS
  FROM T001K INNER JOIN T001W ON T001K~BWKEY = T001W~BWKEY
             INNER JOIN T001 ON T001K~BUKRS = T001~BUKRS
  WHERE T001W~WERKS = P_IN_WERKS.

  READ TABLE IT_WERKS_BUKRS INDEX 1.
  P_OUT_BUKRS = IT_WERKS_BUKRS-BUKRS.

ENDFORM.
*批次特性描述
FORM GETATNAM TABLES P_CABN STRUCTURE CABN.
  DATA:IT_CABNT TYPE TABLE OF CABNT WITH HEADER LINE.
  SELECT *
    INTO TABLE P_CABN
    FROM CABN
    WHERE ATNAM LIKE 'Z%'.
  IF SY-SUBRC EQ 0.
    SORT P_CABN BY ATINN.
    SELECT *
      INTO TABLE IT_CABNT
      FROM CABNT
      FOR ALL ENTRIES IN P_CABN
      WHERE ATINN = P_CABN-ATINN
      AND   SPRAS = SY-LANGU.
    SORT IT_CABNT BY ATINN.
    LOOP AT P_CABN.
      READ TABLE IT_CABNT WITH KEY ATINN = P_CABN-ATINN BINARY SEARCH.
      IF SY-SUBRC EQ 0.
        P_CABN-ATSCH = IT_CABNT-ATBEZ.
        MODIFY P_CABN TRANSPORTING ATSCH.
      ENDIF.
    ENDLOOP.
    SORT P_CABN BY ATNAM.
  ENDIF.
ENDFORM.
*公共取数部分
**********END 08.05.2020 08:59:47********************************************
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*跳转到标准功能，配合ALV热点事件
******************************************ME23N **************************************
FORM ME23N  USING    INEBELN.
  CHECK INEBELN IS NOT INITIAL.
  SET PARAMETER ID 'BES' FIELD INEBELN.
  CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_me23n
FORM ME53N  USING    INEBELN.
  CHECK INEBELN IS NOT INITIAL.
  SET PARAMETER ID 'BAN' FIELD INEBELN.
  CALL TRANSACTION 'ME53N' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_me23n
******************************************ME32K **************************************
FORM ME32K  USING    INEBELN.
  CHECK INEBELN IS NOT INITIAL.
  SET PARAMETER ID 'BES' FIELD INEBELN.
  CALL TRANSACTION 'ME32K' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_me32k
******************************************MM03 **************************************
FORM MM03  USING    INMATNR.
  CHECK INMATNR IS NOT INITIAL.
  SET PARAMETER ID 'MAT' FIELD INMATNR.
  CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_mm03
******************************************MB23 **************************************
FORM MB23  USING    INRSNUM.
  CHECK INRSNUM IS NOT INITIAL.
  SET PARAMETER ID 'RES' FIELD INRSNUM.
  CALL TRANSACTION 'MB23' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_mb23
******************************************ME33K **************************************
FORM ME33K  USING    INEBELN.
  CHECK INEBELN IS NOT INITIAL.
  SET PARAMETER ID 'CTR' FIELD INEBELN.
  CALL TRANSACTION 'ME33K' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_me33k
******************************************VL03N **************************************
FORM VL03N  USING    INVBELN .
  CHECK INVBELN IS NOT INITIAL.
  SET PARAMETER ID 'VL' FIELD INVBELN.
  CALL TRANSACTION 'VL03N' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_vl03n
******************************************VA03 **************************************
FORM VA03  USING    INVBELN.
  CHECK INVBELN IS NOT INITIAL.
  SET PARAMETER ID 'AUN' FIELD INVBELN.
  CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_va03
******************************************VA43 **************************************
FORM VA43  USING    INVBELN .
  CHECK INVBELN IS NOT INITIAL.
  SET PARAMETER ID 'KTN' FIELD INVBELN.
  CALL TRANSACTION 'VA43' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_va43
******************************************COR3**************************************
FORM COR3  USING    INAUFNR  .
  CHECK INAUFNR IS NOT INITIAL.
  SET PARAMETER ID 'BR1' FIELD INAUFNR.
  CALL TRANSACTION 'COR3' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_cor3
******************************************COR3**************************************
FORM BP  USING    INLIFNR  .
  CHECK INLIFNR IS NOT INITIAL.
  SET PARAMETER ID 'BPA' FIELD INLIFNR.
  CALL TRANSACTION 'BP' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_bp
******************************************COR3**************************************
FORM KS03  USING    INKOSTL INKOKRS .
  CHECK INKOSTL IS NOT INITIAL.
  CHECK INKOKRS IS NOT INITIAL.
  SET PARAMETER ID 'CAC' FIELD INKOKRS.
  SET PARAMETER ID 'KOS' FIELD INKOSTL.
  CALL TRANSACTION 'KS03' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_ks03
******************************************MIGO**************************************
FORM MIGO  USING    INMBLNR
      INMJAHR.
  CHECK INMBLNR IS NOT INITIAL.
  CALL FUNCTION 'MIGO_DIALOG'
    EXPORTING
      I_MBLNR             = INMBLNR
      I_MJAHR             = INMJAHR
    EXCEPTIONS
      ILLEGAL_COMBINATION = 1
      OTHERS              = 2.
ENDFORM.                    "frm_goto_migo_dialog
******************************************COR3**************************************
FORM CKM3N  USING  INMATNR INWERKS INBDTJ INPOPR .
  DATA OPT TYPE CTU_PARAMS.
  DATA NUMC(3) TYPE N.
  CHECK INMATNR IS NOT INITIAL.
  CHECK INWERKS IS NOT INITIAL.
  CHECK INBDTJ IS NOT INITIAL.
  CHECK INPOPR IS NOT INITIAL.
  NUMC = INPOPR.
  SET PARAMETER ID 'WRK' FIELD INWERKS.
  SET PARAMETER ID 'MAT' FIELD INMATNR.
  SET PARAMETER ID 'MLP' FIELD NUMC.
  SET PARAMETER ID 'MLJ' FIELD INBDTJ.
  CALL TRANSACTION 'CKM3N' AND SKIP FIRST SCREEN.
ENDFORM.                    "frm_goto_ckm3
*FB03 查看凭证，可直接跳转指定行
FORM FB03 USING INBELNR INGJAHR INBUKRS INBUZEI.
  DATA:BEGIN OF BUZTAB OCCURS 0,
         BUKRS TYPE BUKRS,
         BELNR TYPE BELNR_D,
         GJAHR TYPE GJAHR,
         BUZEI TYPE BSEG-BUZEI,
       END OF BUZTAB.
  REFRESH:BUZTAB.
  CLEAR:BUZTAB.

  CHECK INBELNR IS NOT INITIAL
  AND INGJAHR IS NOT INITIAL
  AND INBUKRS IS NOT INITIAL.
  IF INBUZEI IS INITIAL.
    SET PARAMETER ID 'BLN' FIELD INBELNR.
    SET PARAMETER ID 'GJR' FIELD INGJAHR.
    SET PARAMETER ID 'BUK' FIELD INBUKRS.
    CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
  ELSE.
    BUZTAB-BUKRS = INBUKRS.
    BUZTAB-BELNR = INBELNR.
    BUZTAB-GJAHR = INGJAHR.
    BUZTAB-BUZEI = INBUZEI.
    APPEND BUZTAB.
    CALL DIALOG 'RF_ZEILEN_ANZEIGE'
      EXPORTING
        BUZTAB FROM BUZTAB
        TCODE  FROM 'FB03'.
  ENDIF.
ENDFORM.
FORM CO03 USING INAUFNR.
  SET PARAMETER ID 'ANR' FIELD INAUFNR.
  CALL TRANSACTION 'CO03' AND SKIP FIRST SCREEN.
ENDFORM.
FORM KO03 USING INAUFNR.
  CHECK INAUFNR IS NOT INITIAL.
  SET PARAMETER ID 'ANR' FIELD INAUFNR.
  CALL TRANSACTION 'KO03' AND SKIP FIRST SCREEN.
ENDFORM.
FORM VF03 USING INVBELN.
  SET PARAMETER ID 'VF' FIELD INVBELN.
  CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
ENDFORM.
*单条跳转到VF01
FORM VF01  USING    INVBELN .
  CHECK INVBELN IS NOT INITIAL.
  SET PARAMETER ID 'VFR' FIELD INVBELN.
  CALL TRANSACTION 'VF01' AND SKIP FIRST SCREEN.
ENDFORM.
*跳转到SE16
FORM SE16 USING INTABNAME.
  CHECK INTABNAME IS NOT INITIAL.
  SELECT SINGLE COUNT(*)
  FROM DD02L
  WHERE TABNAME = INTABNAME
  AND   TABCLASS IN ('TRANSP','VIEW').
  IF SY-SUBRC = 0.
    SET PARAMETER ID 'DTB' FIELD INTABNAME.
    CALL TRANSACTION 'SE16' AND SKIP FIRST SCREEN .
  ENDIF.
ENDFORM.
*显示预制发票
FORM MIR4 USING INBELNR INGJAHR .
  CHECK INBELNR IS NOT INITIAL.
  CHECK INGJAHR IS NOT INITIAL.
  DATA F_MIR4_CHANGE LIKE BOOLE-BOOLE.
  SET PARAMETER ID 'RBN' FIELD INBELNR.
  SET PARAMETER ID 'GJR' FIELD INGJAHR.
*  SET PARAMETER ID 'RBS' FIELD 'A'.                         "#EC EXISTS
*  SET PARAMETER ID 'CHG' FIELD F_MIR4_CHANGE.
  CALL TRANSACTION 'MIR4' AND SKIP FIRST SCREEN.
ENDFORM.
*&---------------------------------------------------------------------*
*& 显示SD凭证，订单、交货单、发票等
*& C:订单
*& J:交货单
*& M:发票
*&---------------------------------------------------------------------*
FORM SHOW_SD_DOC USING INTYPE INVBELN INPOSNR.
  CALL FUNCTION 'SD_SALESDOCUMENT_DISPLAY'
    EXPORTING
      I_VBELN               = INTYPE
      I_POSNR               = INVBELN
      I_VBTYP               = INPOSNR
    EXCEPTIONS
      COMMUNICATION_FAILURE = 1
      SYSTEM_FAILURE        = 1
      NO_AUTHORITY          = 2
      OTHERS                = 3.
ENDFORM.                    "showso
*查看检验批
FORM QA03 USING P_PRUEFLOS.
  CHECK P_PRUEFLOS IS NOT INITIAL.
  SET PARAMETER ID 'QLS' FIELD P_PRUEFLOS.
  CALL TRANSACTION 'QA03' AND SKIP FIRST SCREEN.
ENDFORM.
FORM WB23 USING INTKONN.
  CHECK INTKONN IS NOT INITIAL.
  SET PARAMETER ID 'WKN' FIELD INTKONN.
  CALL TRANSACTION 'WB23' AND SKIP FIRST SCREEN.
ENDFORM.                                                    "WB23
FORM CO14 USING P_RUECK P_RMZHL.
  CHECK P_RUECK IS NOT INITIAL
  AND P_RMZHL IS NOT INITIAL.
  SET PARAMETER ID 'RCK' FIELD P_RUECK.
  SET PARAMETER ID 'RZL' FIELD P_RMZHL.
  CALL TRANSACTION 'CO14' AND SKIP FIRST SCREEN.
ENDFORM.
*标准功能模块化
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*ME15删除/取消采购信息记录
* 0-标准，1-可记账,2-寄售，3-分包合同，P-管道
*LOEKZ  1-删除整个采购信息记录，2-删除采购组织数据
*FLAG   Y-删除，N-取消删除
*MODE  N-后台，A-前台
FORM ME15 USING LIFNR
                MATNR
                EKORG
                WERKS
                ESOKZ
                LOEKZ
                FLAG
                MODE
CHANGING MSG.
  DATA: INBDCDATA LIKE BDCDATA    OCCURS 0 WITH HEADER LINE,
        INMESSTAB LIKE BDCMSGCOLL OCCURS 0 WITH HEADER LINE,
        RETURN    TYPE TABLE OF BAPIRET2 WITH HEADER LINE.
  REFRESH:INBDCDATA,INMESSTAB.
  CLEAR:INBDCDATA,INMESSTAB.

  PERFORM BDC_DYNPRO TABLES INBDCDATA      USING 'SAPMM06I' '0100'.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'BDC_CURSOR'
        'RM06I-NORMB'.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'BDC_OKCODE'
        '/00'.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'EINA-LIFNR'
        LIFNR.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'EINA-MATNR'
        MATNR.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'EINE-EKORG'
        EKORG.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'EINE-WERKS'
        WERKS.
  CASE ESOKZ.
    WHEN '0'.
      PERFORM BDC_FIELD TABLES INBDCDATA     USING 'RM06I-NORMB' 'X'.
    WHEN '1'.
    WHEN '2'.
      PERFORM BDC_FIELD TABLES INBDCDATA      USING 'RM06I-KONSI' 'X'.
    WHEN '3'.
      PERFORM BDC_FIELD TABLES INBDCDATA     USING 'RM06I-LOHNB' 'X'.
    WHEN 'P'.
      PERFORM BDC_FIELD TABLES INBDCDATA     USING 'RM06I-PIPEL' 'X'.
  ENDCASE.
  PERFORM BDC_DYNPRO TABLES INBDCDATA     USING 'SAPMM06I' '0104'.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'BDC_CURSOR'
        'EINE-LOEKZ'.
  PERFORM BDC_FIELD TABLES INBDCDATA      USING 'BDC_OKCODE'
        '=BU'.
  CASE FLAG.
    WHEN 'Y'.
      CASE LOEKZ.
        WHEN '1'.
          PERFORM BDC_FIELD TABLES INBDCDATA      USING 'EINA-LOEKZ'
                'X'.
        WHEN '2'.
          PERFORM BDC_FIELD TABLES INBDCDATA       USING 'EINE-LOEKZ'
                'X'.
      ENDCASE.
    WHEN 'N'.
      CASE LOEKZ.
        WHEN '1'.
          PERFORM BDC_FIELD TABLES INBDCDATA      USING 'EINA-LOEKZ'
                ''.
        WHEN '2'.
          PERFORM BDC_FIELD TABLES INBDCDATA      USING 'EINE-LOEKZ'
                ''.
      ENDCASE.
  ENDCASE.

  PERFORM BDCFM TABLES INBDCDATA RETURN  USING 'ME15' MODE.

  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    IF RETURN-MESSAGE IS INITIAL.
      PERFORM MSGTOTEXT USING RETURN-ID
            RETURN-NUMBER
            RETURN-MESSAGE_V1
            RETURN-MESSAGE_V2
            RETURN-MESSAGE_V3
            RETURN-MESSAGE_V4
      CHANGING RETURN-MESSAGE.
    ENDIF.
    CONCATENATE RETURN-MESSAGE MSG INTO MSG SEPARATED BY '/'.
    CLEAR RETURN.
  ENDLOOP.
  IF SY-SUBRC = 0.
    CONCATENATE 'E:' MSG INTO MSG.
  ELSE.
    CLEAR MSG.
    CONCATENATE 'S:' '处理成功' INTO MSG.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*凭证冲销(可冲销单行)
FORM MBST TABLES INITEM STRUCTURE BAPI2017_GM_ITEM_04
USING INMBLNR INMJAHR DATUM
CHANGING MESSAGE.
  DATA: GOODSMVT_HEADRET_MBST TYPE BAPI2017_GM_HEAD_RET,
        RETURN_MBST           TYPE TABLE OF BAPIRET2 WITH HEADER LINE,
        GOODSMVT_MATDOCITEM   TYPE TABLE OF BAPI2017_GM_ITEM_04 WITH HEADER LINE,
        GOODSMVT_PSTNG_DATE   TYPE SY-DATUM,
        MATDOCUMENTYEAR       TYPE BAPI2017_GM_HEAD_02-DOC_YEAR.
  CLEAR:GOODSMVT_HEADRET_MBST,RETURN_MBST[],RETURN_MBST.
  IF DATUM IS INITIAL.
    GOODSMVT_PSTNG_DATE = SY-DATUM.
  ELSE.
    GOODSMVT_PSTNG_DATE = DATUM.
  ENDIF.
  IF INMJAHR IS INITIAL.
    MATDOCUMENTYEAR = SY-DATUM+0(4).
  ELSE.
    MATDOCUMENTYEAR = INMJAHR.
  ENDIF.

  LOOP AT INITEM WHERE MATDOC_ITEM IS NOT INITIAL.
    GOODSMVT_MATDOCITEM-MATDOC_ITEM = INITEM-MATDOC_ITEM.
    APPEND GOODSMVT_MATDOCITEM.
    CLEAR:GOODSMVT_MATDOCITEM,INITEM.
  ENDLOOP.

  CALL FUNCTION 'BAPI_GOODSMVT_CANCEL' " DESTINATION 'NONE'
    EXPORTING
      MATERIALDOCUMENT    = INMBLNR
      MATDOCUMENTYEAR     = MATDOCUMENTYEAR
      GOODSMVT_PSTNG_DATE = GOODSMVT_PSTNG_DATE
      GOODSMVT_PR_UNAME   = SY-UNAME
    IMPORTING
      GOODSMVT_HEADRET    = GOODSMVT_HEADRET_MBST
    TABLES
      RETURN              = RETURN_MBST
      GOODSMVT_MATDOCITEM = GOODSMVT_MATDOCITEM
    EXCEPTIONS
      OTHERS              = 1.
  IF SY-SUBRC NE 0.
    PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN_MBST-MESSAGE.
    RETURN_MBST-TYPE = 'E'.
    APPEND RETURN_MBST.
    CLEAR RETURN_MBST.
  ENDIF.
  LOOP AT RETURN_MBST WHERE TYPE CA 'AEX'.
    IF RETURN_MBST-MESSAGE IS INITIAL.
      PERFORM MSGTOTEXT USING RETURN_MBST-ID
            RETURN_MBST-NUMBER
            RETURN_MBST-MESSAGE_V1
            RETURN_MBST-MESSAGE_V2
            RETURN_MBST-MESSAGE_V3
            RETURN_MBST-MESSAGE_V4
      CHANGING RETURN_MBST-MESSAGE.
    ENDIF.
    CONCATENATE RETURN_MBST-MESSAGE MESSAGE INTO MESSAGE SEPARATED BY '/'.
    CLEAR RETURN_MBST.
  ENDLOOP.
  IF SY-SUBRC = 0.
    CONCATENATE 'E:' MESSAGE INTO MESSAGE.
    ROLLBACK WORK.
  ELSE.
    COMMIT WORK AND WAIT.
    CONCATENATE 'S:' GOODSMVT_HEADRET_MBST-MAT_DOC '/'
    GOODSMVT_HEADRET_MBST-DOC_YEAR INTO MESSAGE.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*删除/冲销发票校验凭证
FORM MIR7_CANCEL_DELETE USING INBELNR
      INGJAHR
      INCODE
      INDATE
CHANGING OUTMSG.
  DATA:RETURN      TYPE TABLE OF BAPIRET2 WITH HEADER LINE,
       WA_RBKP     TYPE RBKP,
       POSTINGDATE TYPE SY-DATUM,
       BELNR       TYPE RE_BELNR,
       REASONCODE  TYPE STGRD.
  CLEAR:POSTINGDATE.
  POSTINGDATE = INDATE.
  IF POSTINGDATE IS INITIAL.
    POSTINGDATE = SY-DATUM.
  ENDIF.
  IF INCODE IS INITIAL.
    REASONCODE = '03'.
  ELSE.
    REASONCODE = INCODE.
  ENDIF.
*获取发票状态及存在性
  SELECT SINGLE *
  INTO  WA_RBKP
  FROM RBKP
  WHERE BELNR = INBELNR
  AND   GJAHR = INGJAHR.
  IF SY-SUBRC NE 0.
    OUTMSG = 'E:发票不存在'.
    EXIT.
  ENDIF.
  CASE WA_RBKP-RBSTAT.
    WHEN 'A' OR 'D'.
      CALL FUNCTION 'BAPI_INCOMINGINVOICE_DELETE' " DESTINATION 'NONE' "删除
        EXPORTING
          INVOICEDOCNUMBER = INBELNR
          FISCALYEAR       = INGJAHR
        TABLES
          RETURN           = RETURN
        EXCEPTIONS
          OTHERS           = 1.
      IF SY-SUBRC NE 0.
        PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
        RETURN-TYPE = 'E'.
        APPEND RETURN.
        CLEAR RETURN.
      ENDIF.
    WHEN '2'.
      CONCATENATE 'E:' INBELNR '发票已经删除' INTO OUTMSG.
      EXIT.
    WHEN '5'.
      IF WA_RBKP-STBLG IS NOT INITIAL.
        CONCATENATE 'E:' WA_RBKP-STBLG '发票已经冲销' INTO OUTMSG.
        EXIT.
      ENDIF.
      CALL FUNCTION 'BAPI_INCOMINGINVOICE_CANCEL' " DESTINATION 'NONE' "冲销
        EXPORTING
          INVOICEDOCNUMBER          = INBELNR
          FISCALYEAR                = INGJAHR
          REASONREVERSAL            = REASONCODE
        IMPORTING
          INVOICEDOCNUMBER_REVERSAL = BELNR
        TABLES
          RETURN                    = RETURN
        EXCEPTIONS
          OTHERS                    = 1.
      IF SY-SUBRC NE 0.
        PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
        RETURN-TYPE = 'E'.
        APPEND RETURN.
        CLEAR RETURN.
      ENDIF.
    WHEN OTHERS.
      OUTMSG = 'E:此功能只能用作删除/冲销发票'.
      EXIT.
  ENDCASE.

  LOOP AT RETURN WHERE TYPE CA 'AEX' .
    IF RETURN-MESSAGE IS INITIAL.
      PERFORM MSGTOTEXT USING RETURN-ID
            RETURN-NUMBER
            RETURN-MESSAGE_V1
            RETURN-MESSAGE_V2
            RETURN-MESSAGE_V3
            RETURN-MESSAGE_V4
      CHANGING RETURN-MESSAGE.
    ENDIF.
    CONCATENATE RETURN-MESSAGE OUTMSG INTO OUTMSG SEPARATED BY '/'.
    CLEAR RETURN.
  ENDLOOP.

  IF SY-SUBRC = 0.
    CONCATENATE 'E:' INBELNR OUTMSG INTO OUTMSG.
    ROLLBACK WORK.
  ELSE.
    CASE WA_RBKP-RBSTAT.
      WHEN 'A' OR 'D'.
        CONCATENATE 'S:' INBELNR '删除成功' INTO OUTMSG.
      WHEN '5'.
        CONCATENATE 'S:' BELNR '冲销成功' INTO OUTMSG.
    ENDCASE.
    COMMIT WORK AND WAIT.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*交货单过账冲销
FORM VBELVPOST USING INVBELV INTCODE INDATE
CHANGING OUTMSG.
  DATA: HEADER_DATA    LIKE  BAPIOBDLVHDRCON,
        HEADER_CONTROL LIKE  BAPIOBDLVHDRCTRLCON,
        DEADLINES      TYPE TABLE OF BAPIDLVDEADLN WITH HEADER LINE,
        T_MESG         TYPE TABLE OF MESG WITH HEADER LINE,
        RETURN         TYPE TABLE OF BAPIRET2 WITH HEADER LINE,
        BDCDATA        TYPE TABLE OF  BDCDATA WITH HEADER LINE.
  DATA: TZONE   LIKE  TZONREF-TZONE,
        TSTAMP  LIKE TZONREF-TSTAMPS,
        TSTAMPC TYPE CHAR20,
        VBELV   TYPE VBELN_VL,
        MSG     TYPE BAPI_MSG,
        DATUM   TYPE SY-DATUM,
        CXROOT  TYPE REF TO CX_ROOT.

  CLEAR:TSTAMP,TSTAMPC.
  PERFORM TRANSDATA USING '' 'ZERO' 'IN' INVBELV
  CHANGING VBELV.
  IF INDATE IS INITIAL.
    DATUM = SY-DATUM.
  ELSE.
    DATUM = INDATE.
  ENDIF.
  CASE INTCODE.
    WHEN 'VL02N'."过账
      HEADER_DATA-DELIV_NUMB     = VBELV.
      HEADER_CONTROL-DELIV_NUMB  = VBELV.  "交货单号
      HEADER_CONTROL-POST_GI_FLG = 'X'.   "过账状态
      HEADER_CONTROL-GDSI_DATE_FLG ='X'.
* WSHDRLFDAT    交货日期
*   WSHDRWADAT    发货日期（计划）
*   WSHDRWADTI    发货日期（实际）
*   WSHDRLDDAT    装载日期
*   WSHDRTDDAT    传输计划日期
*   WSHDRKODAT    捡配日期
      CLEAR:TZONE.
      SELECT SINGLE TZONESYS
        INTO TZONE
        FROM TTZCU.
      IF TZONE IS INITIAL.
        TZONE = 'UTF+8'.
      ENDIF.
      CONVERT DATE DATUM TIME SY-UZEIT INTO TIME STAMP TSTAMP TIME ZONE TZONE.
*      CONCATENATE DATUM SY-UZEIT INTO TSTAMPC.
*      PERFORM DELQFW CHANGING TSTAMPC.
      TSTAMP = TSTAMPC.
      DEADLINES-DELIV_NUMB =  VBELV.
      DEADLINES-TIMETYPE   = 'WSHDRWADTI'. " Goods issue date (actual)
      DEADLINES-TIMESTAMP_UTC = TSTAMP.
      DEADLINES-TIMEZONE = TZONE.
      APPEND DEADLINES.
      IF OUTMSG = 'BDC'."BAPI不卡信贷，故录屏，该函数使用功能方式可自由选择
        CLEAR OUTMSG.
        PERFORM BDC_DYNPRO(ZPUBFORM) TABLES BDCDATA      USING 'SAPMV50A' '4004'.
        PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA       USING 'BDC_CURSOR'
                                                               'LIKP-VBELN'.
        PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA       USING 'BDC_OKCODE'
                                                               '/00'.
        PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA       USING 'LIKP-VBELN'
                                                               VBELV.
        PERFORM BDC_DYNPRO(ZPUBFORM) TABLES BDCDATA      USING 'SAPMV50A' '1000'.
        PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA       USING 'BDC_OKCODE'
                                                               '=T\01'.
        PERFORM BDC_DYNPRO(ZPUBFORM) TABLES BDCDATA      USING 'SAPMV50A' '1000'.
        PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA       USING 'BDC_OKCODE'
                                                               '=WABU_T'.
        PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA       USING 'BDC_CURSOR'
                                                               'LIKP-WADAT_IST'.
        PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA       USING 'LIKP-WADAT_IST'
                                                               DATUM.
        SET UPDATE TASK LOCAL.
        PERFORM BDCFM(ZPUBFORM) TABLES BDCDATA RETURN USING 'VL02N' 'N'.
      ELSE.
        CLEAR OUTMSG.
        SET UPDATE TASK LOCAL.
        CALL FUNCTION 'BAPI_OUTB_DELIVERY_CONFIRM_DEC' " DESTINATION 'NONE'  " WS_DELIVERY_UPDATE 函数
          EXPORTING
            HEADER_DATA      = HEADER_DATA
            HEADER_CONTROL   = HEADER_CONTROL
            DELIVERY         = VBELV
          TABLES
            HEADER_DEADLINES = DEADLINES
            RETURN           = RETURN
          EXCEPTIONS
            OTHERS           = 1.
        IF SY-SUBRC NE 0.
          PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
          RETURN-TYPE = 'E'.
          APPEND RETURN.
          CLEAR RETURN.
        ENDIF.
      ENDIF.

    WHEN 'VL09'."冲销
      SET UPDATE TASK LOCAL.
      CALL FUNCTION 'WS_REVERSE_GOODS_ISSUE'
        EXPORTING
          I_VBELN                   = VBELV
          I_BUDAT                   = DATUM
          I_COUNT                   = '001'
          I_MBLNR                   = SPACE
          I_VBTYP                   = 'J'
          I_TCODE                   = 'VL09'
        TABLES
          T_MESG                    = T_MESG
        EXCEPTIONS
          ERROR_REVERSE_GOODS_ISSUE = 1
          ERROR_MESSAGE             = 2
          OTHERS                    = 3.

      IF SY-SUBRC NE 0.
        T_MESG-MSGTY = SY-MSGTY.
        T_MESG-ARBGB = SY-MSGID.
        T_MESG-TXTNR = SY-MSGNO.
        T_MESG-MSGV1 = SY-MSGV1.
        T_MESG-MSGV2 = SY-MSGV2.
        T_MESG-MSGV3 = SY-MSGV3.
        T_MESG-MSGV4 = SY-MSGV4.
        APPEND T_MESG.
        CLEAR T_MESG.
      ENDIF.
      LOOP AT T_MESG WHERE MSGTY CA 'AEX'.
        PERFORM INMSG TABLES RETURN USING T_MESG-ARBGB T_MESG-MSGTY
              T_MESG-TXTNR T_MESG-MSGV1
              T_MESG-MSGV2 T_MESG-MSGV3
              T_MESG-MSGV4.
        CLEAR T_MESG.
      ENDLOOP.
    WHEN OTHERS.
      OUTMSG = 'E:输入正确事物代码'.
      RETURN.
  ENDCASE.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    IF RETURN-MESSAGE IS INITIAL.
      PERFORM MSGTOTEXT USING RETURN-ID
            RETURN-NUMBER
            RETURN-MESSAGE_V1
            RETURN-MESSAGE_V2
            RETURN-MESSAGE_V3
            RETURN-MESSAGE_V4
      CHANGING RETURN-MESSAGE.
    ENDIF.
    CONCATENATE RETURN-MESSAGE OUTMSG INTO OUTMSG SEPARATED BY '/'.
    CLEAR RETURN.
  ENDLOOP.
  IF SY-SUBRC = 0.
    ROLLBACK WORK.
    CONCATENATE 'E:' OUTMSG INTO OUTMSG.
  ELSE.
    COMMIT WORK AND WAIT.
    CASE INTCODE.
      WHEN 'VL02N'.
        OUTMSG = 'S:交货单过账成功'.
        TRY .
            UPDATE LIKP SET VLSTK = SPACE ANZPK = '0' WHERE VBELN = VBELV.
          CATCH CX_ROOT INTO CXROOT .
            MSG = CXROOT->GET_TEXT( ).
            CONCATENATE 'E:' MSG INTO MSG.
        ENDTRY.
        IF MSG+0(1) EQ 'E'.
          ROLLBACK WORK.
        ELSE.
          COMMIT WORK AND WAIT.
        ENDIF.
      WHEN 'VL09'.
        OUTMSG = 'S:交货单冲销成功'.
    ENDCASE.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*冲销发票
FORM VF11 USING INVBELP CALCELDATE
CHANGING OUTMSG.
  DATA:BILLINGDOCUMENT TYPE BILL_DOC,
       BILLINGDATE     TYPE DATS,
       RETURN          TYPE TABLE OF BAPIRETURN1 WITH HEADER LINE,
       SUCCESS         TYPE TABLE OF BAPIVBRKSUCCESS WITH HEADER LINE.

  PERFORM TRANSDATA USING '' 'ZERO' 'IN' INVBELP
  CHANGING BILLINGDOCUMENT.

  IF CALCELDATE IS INITIAL.
    BILLINGDATE = SY-DATUM.
  ELSE.
    BILLINGDATE = CALCELDATE.
  ENDIF.
  SET UPDATE TASK LOCAL.
  CALL FUNCTION 'BAPI_BILLINGDOC_CANCEL1' "DESTINATION 'NONE'
    EXPORTING
      BILLINGDOCUMENT = BILLINGDOCUMENT
      BILLINGDATE     = BILLINGDATE
    TABLES
      RETURN          = RETURN
      SUCCESS         = SUCCESS
    EXCEPTIONS
      OTHERS          = 1.
  IF SY-SUBRC NE 0.
    PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
    RETURN-TYPE = 'E'.
    APPEND RETURN.
    CLEAR RETURN.
  ENDIF.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    IF RETURN-MESSAGE IS INITIAL.
      PERFORM MSGTOTEXT USING RETURN-ID
            RETURN-NUMBER
            RETURN-MESSAGE_V1
            RETURN-MESSAGE_V2
            RETURN-MESSAGE_V3
            RETURN-MESSAGE_V4
      CHANGING RETURN-MESSAGE.
    ENDIF.
    CONCATENATE RETURN-MESSAGE OUTMSG INTO OUTMSG SEPARATED BY '/'.
    CLEAR RETURN.
  ENDLOOP.
  IF SY-SUBRC = 0.
    ROLLBACK WORK.
    CONCATENATE 'E:' OUTMSG INTO OUTMSG.
  ELSE.
    COMMIT WORK AND WAIT.
    READ TABLE SUCCESS WITH KEY REF_DOC = BILLINGDOCUMENT.
    CONCATENATE 'S:' SUCCESS-BILL_DOC '发票冲销成功' INTO OUTMSG.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*删除SO/交货单
FORM DELVBELN USING INVBELN INTYPE CHANGING OUTMSG.
  DATA:VBELN            TYPE VBELN,
       ORDER_HEADER_INX TYPE BAPISDH1X,
       HEADER_DATA      TYPE TABLE OF BAPIOBDLVHDRCHG WITH HEADER LINE,
       HEADER_CONTROL   TYPE TABLE OF BAPIOBDLVHDRCTRLCHG WITH HEADER LINE,
       RETURN           TYPE TABLE OF BAPIRET2 WITH HEADER LINE.

  PERFORM TRANSDATA USING '' 'ZERO' 'IN' INVBELN
  CHANGING VBELN.

  CASE INTYPE.
    WHEN 'SO'.
      ORDER_HEADER_INX-UPDATEFLAG = 'D'.

      CALL FUNCTION 'BAPI_SALESORDER_CHANGE' "DESTINATION 'NONE'
        EXPORTING
          SALESDOCUMENT    = VBELN
          ORDER_HEADER_INX = ORDER_HEADER_INX
        TABLES
          RETURN           = RETURN
        EXCEPTIONS
          OTHERS           = 1.
      IF SY-SUBRC NE 0.
        PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
        RETURN-TYPE = 'E'.
        APPEND RETURN.
        CLEAR RETURN.
      ENDIF.
    WHEN 'DN'.
      HEADER_DATA-DELIV_NUMB = VBELN.
      HEADER_CONTROL-DLV_DEL = 'X'.

      CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE' " DESTINATION 'NONE'
        EXPORTING
          HEADER_DATA    = HEADER_DATA
          HEADER_CONTROL = HEADER_CONTROL
          DELIVERY       = VBELN
        TABLES
          RETURN         = RETURN
        EXCEPTIONS
          OTHERS         = 1.
      IF SY-SUBRC NE 0.
        PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
        RETURN-TYPE = 'E'.
        APPEND RETURN.
        CLEAR RETURN.
      ENDIF.
    WHEN OTHERS.
      OUTMSG = 'E:输入正确订单类型'.
      RETURN.
  ENDCASE.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    IF RETURN-MESSAGE IS INITIAL.
      PERFORM MSGTOTEXT USING RETURN-ID
            RETURN-NUMBER
            RETURN-MESSAGE_V1
            RETURN-MESSAGE_V2
            RETURN-MESSAGE_V3
            RETURN-MESSAGE_V4
      CHANGING RETURN-MESSAGE.
    ENDIF.
    CONCATENATE RETURN-MESSAGE OUTMSG INTO OUTMSG SEPARATED BY '/'.
    CLEAR RETURN.
  ENDLOOP.
  IF SY-SUBRC NE 0.
    CASE INTYPE.
      WHEN 'SO'.
        OUTMSG = 'S:销售订单删除成功'.
      WHEN 'DN'.
        OUTMSG = 'S:交货单删除成功'.
    ENDCASE.
    COMMIT WORK AND WAIT.
  ELSE.
    ROLLBACK WORK.
    CONCATENATE 'E:' OUTMSG INTO OUTMSG.
  ENDIF.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*VF02批准到会计
FORM VF02 USING INVBELP
CHANGING OUTMSG.
  DATA:WA_BKPF TYPE BKPF,
       VBELP   TYPE VBELN,
       BDCDATA TYPE TABLE OF BDCDATA WITH HEADER LINE,
       RETURN  TYPE TABLE OF BAPIRET2 WITH HEADER LINE.

  CLEAR OUTMSG.

  PERFORM TRANSDATA USING '' 'ZERO' 'IN' INVBELP
  CHANGING VBELP.

  SELECT SINGLE *
  INTO WA_BKPF
  FROM BKPF
  WHERE XBLNR = VBELP.
  IF SY-SUBRC = 0.
    CONCATENATE 'S' WA_BKPF-BUKRS WA_BKPF-GJAHR WA_BKPF-BELNR INTO OUTMSG SEPARATED BY ':'.
    RETURN.
  ENDIF.

  PERFORM BDC_DYNPRO TABLES BDCDATA      USING 'SAPMV60A' '0101'.
  PERFORM BDC_FIELD TABLES BDCDATA       USING 'BDC_CURSOR'
        'VBRK-VBELN'.
  PERFORM BDC_FIELD TABLES BDCDATA       USING 'BDC_OKCODE'
        '=FKFR'.
  PERFORM BDC_FIELD TABLES BDCDATA       USING 'VBRK-VBELN'
        VBELP.

  PERFORM BDCFM TABLES BDCDATA RETURN USING 'VF02' 'N'.

  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    IF RETURN-MESSAGE IS INITIAL.
      PERFORM MSGTOTEXT USING RETURN-ID
            RETURN-NUMBER
            RETURN-MESSAGE_V1
            RETURN-MESSAGE_V2
            RETURN-MESSAGE_V3
            RETURN-MESSAGE_V4
      CHANGING RETURN-MESSAGE.
    ENDIF.
    CONCATENATE RETURN-MESSAGE OUTMSG INTO OUTMSG SEPARATED BY '/'.
    CLEAR RETURN.
  ENDLOOP.
  IF OUTMSG IS NOT INITIAL.
    CONCATENATE 'E:' OUTMSG INTO OUTMSG.
    RETURN.
  ENDIF.

  SELECT SINGLE COUNT(*)
  FROM VBRK
  WHERE VBELN = VBELP
  AND   RFBSK = 'C'.
  IF SY-SUBRC NE 0.
    OUTMSG = 'E:没有产生会计凭证'.
    RETURN.
  ENDIF.
  SELECT SINGLE *
  INTO WA_BKPF
  FROM BKPF
  WHERE XBLNR = VBELP.
  IF SY-SUBRC NE 0.
    OUTMSG = 'E:没有产生会计凭证'.
    RETURN.
  ENDIF.
  CONCATENATE 'S' WA_BKPF-BUKRS WA_BKPF-GJAHR WA_BKPF-BELNR INTO OUTMSG SEPARATED BY ':'.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*审批销售订单
FORM CHANGESOSTATUS USING INVBELN
      P_STA1"原状态
      P_STA2"新状态
CHANGING OUTMSG.

  DATA:IT_TJ30 TYPE TABLE OF TJ30 WITH HEADER LINE,
       IT_JEST TYPE TABLE OF JEST WITH HEADER LINE,
       WA_JSTO TYPE JSTO.

  DATA:OBJNR          TYPE JEST-OBJNR,
       ESTAT_INACTIVE TYPE TJ30-ESTAT,
       ESTAT_ACTIVE   TYPE TJ30-ESTAT,
       STSMA          TYPE JSTO-STSMA,
       VBELN          TYPE VBELN,
       WA_VBAK        TYPE VBAK.

  PERFORM TRANSDATA USING '' 'ZERO' 'IN' INVBELN
  CHANGING VBELN.

  SELECT SINGLE *
  INTO WA_VBAK
  FROM VBAK
  WHERE VBELN = VBELN.
  IF SY-SUBRC NE 0.
    OUTMSG = 'E:销售订单不存在'.
    RETURN.
  ENDIF.
*取参数文件
  OBJNR = WA_VBAK-OBJNR.
  SELECT SINGLE *
  INTO WA_JSTO
  FROM JSTO
  WHERE OBJNR = OBJNR.
  IF SY-SUBRC NE 0.
    OUTMSG = 'E:状态参数文件不存在'.
    RETURN.
  ENDIF.
  STSMA = WA_JSTO-STSMA.
*取参数文件对应状态
  SELECT *
  INTO TABLE IT_TJ30
  FROM TJ30
  WHERE STSMA = STSMA.
  READ TABLE IT_TJ30 WITH KEY ESTAT = P_STA1.
  IF SY-SUBRC NE 0.
    CONCATENATE 'E:' '用户状态' P_STA1 '不存在' INTO OUTMSG.
    RETURN.
  ENDIF.
  READ TABLE IT_TJ30 WITH KEY ESTAT = P_STA2.
  IF SY-SUBRC NE 0.
    CONCATENATE 'E:' '用户状态' P_STA2 '不存在' INTO OUTMSG.
    RETURN.
  ENDIF.

  IF P_STA1 = P_STA2.
    OUTMSG = 'E:新旧状态不能相同'.
    RETURN.
  ENDIF.

  SELECT *
  INTO TABLE IT_JEST
  FROM JEST
  FOR ALL ENTRIES IN IT_TJ30
  WHERE STAT = IT_TJ30-ESTAT
  AND   OBJNR = WA_VBAK-OBJNR.
  IF SY-SUBRC = 0.
    LOOP AT IT_JEST WHERE INACT NE 'X'.
      IF P_STA2 = IT_JEST-STAT.
        OUTMSG = 'S:当前状态不需更改'.
        RETURN.
      ENDIF.
      CLEAR IT_JEST.
    ENDLOOP.
  ENDIF.

  ESTAT_INACTIVE = P_STA1.
  ESTAT_ACTIVE = P_STA2.

  CALL FUNCTION 'I_CHANGE_STATUS'
    EXPORTING
      OBJNR          = OBJNR
      ESTAT_INACTIVE = ESTAT_INACTIVE
      ESTAT_ACTIVE   = ESTAT_ACTIVE
      STSMA          = STSMA
    EXCEPTIONS
      CANNOT_UPDATE  = 1
      OTHERS         = 2.
  IF SY-SUBRC = 0.
    OUTMSG = 'S:审批成功'.
    COMMIT WORK AND WAIT.
  ELSE.
    PERFORM MSGTOTEXT USING '' '' '' '' '' ''
    CHANGING OUTMSG.
    CONCATENATE 'E:' '订单审批失败' OUTMSG  INTO OUTMSG .
    ROLLBACK WORK.
  ENDIF.

ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
**********************************
*ALV显示相关
*ALV布局(字段描述，字段名，去前导零，隐藏,跳转事件)
FORM INIT_FIELDCAT TABLES OUTFIELDCAT
USING FIELDNAME SELTEXT NOZERO NOOUT HOTSPOT EDIT.
  DATA:WA TYPE SLIS_FIELDCAT_ALV.
  WA-FIELDNAME = FIELDNAME.
  WA-SELTEXT_L = SELTEXT.
  WA-SELTEXT_M = SELTEXT.
  WA-SELTEXT_S = SELTEXT.
  WA-REPTEXT_DDIC = SELTEXT.
  WA-NO_OUT = NOOUT.
  WA-HOTSPOT = HOTSPOT.
  IF EDIT = 'X'.
    WA-EDIT = 'X'.
  ENDIF.
*对于数值，若有小数位但却为000，则隐藏
  CASE NOZERO.
    WHEN 'X'.
      WA-NO_ZERO = NOZERO.
    WHEN 'Y'.
      WA-NO_ZERO = 'X'.
      WA-QFIELDNAME = 'MEINS'.
  ENDCASE.
  CASE WA-FIELDNAME.
    WHEN 'CHBOX' OR 'XDBS'.
      WA-CHECKBOX = 'X'.
      WA-HOTSPOT = 'X'.
      WA-FIX_COLUMN = 'X'.
    WHEN 'ICON'.
      WA-FIX_COLUMN = 'X'.
    WHEN 'VBELN'.
      WA-REF_FIELDNAME = 'VBELN'.
      WA-REF_TABNAME = 'VBAK'.
    WHEN 'VBELV'.
      WA-REF_FIELDNAME = 'VBELN'.
      WA-REF_TABNAME = 'LIKP'.
    WHEN 'EBELN'.
      WA-REF_FIELDNAME = 'EBELN'.
      WA-REF_TABNAME = 'EKKO'.
    WHEN 'VBELP'.
      WA-REF_FIELDNAME = 'VBELN'.
      WA-REF_TABNAME = 'VBRK'.
    WHEN 'AUFNR'.
      WA-REF_FIELDNAME = 'AUFNR'.
      WA-REF_TABNAME = 'AUFK'.
    WHEN 'MATNR'.
      WA-REF_FIELDNAME = 'MATNR'.
      WA-REF_TABNAME = 'MARA'.
    WHEN 'MAKTX'.
      WA-REF_FIELDNAME = 'MAKTX'.
      WA-REF_TABNAME = 'MAKT'.
    WHEN 'MBLNR'.
      WA-REF_FIELDNAME = 'MBLNR'.
      WA-REF_TABNAME = 'MKPF'.
    WHEN 'BELNR'.
      WA-REF_FIELDNAME = 'BELNR'.
      WA-REF_TABNAME = 'BKPF'.
    WHEN 'KOSTL'.
      WA-REF_FIELDNAME = 'KOSTL'.
      WA-REF_TABNAME = 'CSKS'.
    WHEN 'MEINS' OR 'VRKME' OR 'GEWEI' OR 'BSTME'.
      WA-EDIT_MASK = '==CUNIT'.
    WHEN 'MENGE' OR 'SHMNG'.
      WA-DECIMALS_OUT = 3.
  ENDCASE.
  APPEND WA TO OUTFIELDCAT .
  CLEAR WA.
ENDFORM.
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*ALV函数"若要显示颜色，则在内表中添加COLOR字段，显示抬头页签，添加TOPPAGE字段
FORM ALVFM TABLES ALVITAB INFIELDCAT USING INGUI INCOMMAND.
  DATA:WA                       TYPE SLIS_FIELDCAT_ALV,
       OUTFIELDCAT              TYPE SLIS_T_FIELDCAT_ALV,
       I_CALLBACK_PROGRAM       TYPE SY-REPID,
       I_GRID_SETTINGS          TYPE LVC_S_GLAY,
       IS_VARIANT               TYPE DISVARIANT,
       HOTSPOTFLAG              TYPE CHAR1,
       EDITFLAG                 TYPE CHAR1,
       CHBOX                    TYPE CHAR1,
       SEL                      TYPE CHAR1,
       IS_LAYOUT                TYPE SLIS_LAYOUT_ALV,
       N                        TYPE I,
       COLORFLAG                TYPE CHAR1,
       I_CALLBACK_USER_COMMAND  TYPE CHAR30,
       TOPPAGE                  TYPE CHAR1,
       I_CALLBACK_PF_STATUS_SET TYPE CHAR30.
  CLEAR:SEL,CHBOX,N,TOPPAGE,COLORFLAG.

  PERFORM GETTABSTRU USING ALVITAB CHANGING OUTFIELDCAT.

  I_CALLBACK_PROGRAM = SY-CPROG.

  LOOP AT OUTFIELDCAT INTO WA .
    CASE WA-FIELDNAME.
      WHEN 'SEL' .
        SEL = 'X'.
      WHEN 'CHBOX'.
        CHBOX = 'X'.
      WHEN 'TOPPAGE'.
        TOPPAGE = 'X'.
      WHEN 'COLOR'.
        COLORFLAG = 'X'.
    ENDCASE.
    CLEAR WA.
  ENDLOOP.
  IF SEL = 'X' AND CHBOX NE 'X' .
    IS_LAYOUT-BOX_FIELDNAME = 'SEL'.
  ENDIF.
  IF COLORFLAG = 'X'.
    IS_LAYOUT-INFO_FIELDNAME = 'COLOR'.
  ENDIF.
  CLEAR WA.


  IF INCOMMAND IS NOT INITIAL.
    I_CALLBACK_USER_COMMAND = INCOMMAND.
  ELSE.
    I_CALLBACK_USER_COMMAND = 'USER_COMMAND'.
  ENDIF.
*GUI状态:INGUI为X则为默认GUI状态名称，不为空则赋值自定义
  IF INGUI IS NOT INITIAL.
    CASE INGUI.
      WHEN 'X'.
        I_CALLBACK_PF_STATUS_SET = 'SET_STATUS'.
      WHEN OTHERS.
        I_CALLBACK_PF_STATUS_SET = INGUI.
    ENDCASE.

  ENDIF.
  "针对字段超多报表，NO_OUT字段失效问题追加修复
  LOOP AT INFIELDCAT INTO WA.
    CASE WA-FIELDNAME.
      WHEN 'HANDLE'.
        IS_VARIANT-REPORT = I_CALLBACK_PROGRAM.
        IS_VARIANT-HANDLE = WA-SELTEXT_L.
    ENDCASE.

    IF WA-NO_OUT = 'X'.
      DELETE TABLE INFIELDCAT FROM WA.
    ENDIF.
    IF WA-HOTSPOT = 'X'.
      HOTSPOTFLAG = 'X'.
    ENDIF.
    IF WA-EDIT = 'X'.
      EDITFLAG = 'X'.
    ENDIF.
    CLEAR WA.
  ENDLOOP.
********ADD BY DONGPZ BEGIN AT 24.02.2021 17:02:59
*增加不同ALV的布局单独设定-加在FIELDCAT中
  IF IS_VARIANT-HANDLE IS INITIAL.
    IS_VARIANT-REPORT = I_CALLBACK_PROGRAM.
    IS_VARIANT-HANDLE = '1'.
  ENDIF.
********ADD BY DONGPZ END AT 24.02.2021 17:02:59
  "自适应宽度与斑马线
  IS_LAYOUT-ZEBRA = 'X'.
  IF EDITFLAG NE 'X'.
    IS_LAYOUT-COLWIDTH_OPTIMIZE = 'X'.
  ELSE.
    I_GRID_SETTINGS-EDT_CLL_CB = 'X'.
  ENDIF.

  IF INGUI IS NOT INITIAL.
*带自定义GUI状态
    IF TOPPAGE = 'X'.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          I_CALLBACK_PROGRAM       = I_CALLBACK_PROGRAM
          IT_FIELDCAT              = INFIELDCAT[]
          I_SAVE                   = 'A'
          IS_LAYOUT                = IS_LAYOUT
          I_GRID_SETTINGS          = I_GRID_SETTINGS
          IS_VARIANT               = IS_VARIANT
          I_CALLBACK_USER_COMMAND  = I_CALLBACK_USER_COMMAND
          I_CALLBACK_PF_STATUS_SET = I_CALLBACK_PF_STATUS_SET
          I_CALLBACK_TOP_OF_PAGE   = 'TOP_OF_PAGE'
        TABLES
          T_OUTTAB                 = ALVITAB
        EXCEPTIONS
          PROGRAM_ERROR            = 1
          OTHERS                   = 2.
    ELSE.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          I_CALLBACK_PROGRAM       = I_CALLBACK_PROGRAM
          IT_FIELDCAT              = INFIELDCAT[]
          I_SAVE                   = 'A'
          IS_LAYOUT                = IS_LAYOUT
          IS_VARIANT               = IS_VARIANT
          I_GRID_SETTINGS          = I_GRID_SETTINGS
          I_CALLBACK_USER_COMMAND  = I_CALLBACK_USER_COMMAND
          I_CALLBACK_PF_STATUS_SET = I_CALLBACK_PF_STATUS_SET
        TABLES
          T_OUTTAB                 = ALVITAB
        EXCEPTIONS
          PROGRAM_ERROR            = 1
          OTHERS                   = 2.
    ENDIF.
  ELSE.
    IF HOTSPOTFLAG = 'X'.
      "使用标准GUI状态，但配合点击跳转事件
      IF TOPPAGE = 'X'.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            I_CALLBACK_PROGRAM      = I_CALLBACK_PROGRAM
            IT_FIELDCAT             = INFIELDCAT[]
            I_SAVE                  = 'A'
            IS_LAYOUT               = IS_LAYOUT
            IS_VARIANT              = IS_VARIANT
            I_CALLBACK_USER_COMMAND = I_CALLBACK_USER_COMMAND
            I_CALLBACK_TOP_OF_PAGE  = 'TOP_OF_PAGE'
          TABLES
            T_OUTTAB                = ALVITAB
          EXCEPTIONS
            PROGRAM_ERROR           = 1
            OTHERS                  = 2.
      ELSE.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            I_CALLBACK_PROGRAM      = I_CALLBACK_PROGRAM
            IT_FIELDCAT             = INFIELDCAT[]
            I_SAVE                  = 'A'
            IS_LAYOUT               = IS_LAYOUT
            IS_VARIANT              = IS_VARIANT
            I_CALLBACK_USER_COMMAND = I_CALLBACK_USER_COMMAND
          TABLES
            T_OUTTAB                = ALVITAB
          EXCEPTIONS
            PROGRAM_ERROR           = 1
            OTHERS                  = 2.
      ENDIF.
    ELSE.
      IF TOPPAGE = 'X'.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            I_CALLBACK_PROGRAM     = I_CALLBACK_PROGRAM
            IT_FIELDCAT            = INFIELDCAT[]
            I_SAVE                 = 'A' "控制缺省/特定用户
            IS_LAYOUT              = IS_LAYOUT
            IS_VARIANT             = IS_VARIANT
            I_CALLBACK_TOP_OF_PAGE = 'TOP_OF_PAGE'
          TABLES
            T_OUTTAB               = ALVITAB
          EXCEPTIONS
            PROGRAM_ERROR          = 1
            OTHERS                 = 2.
      ELSE.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            I_CALLBACK_PROGRAM = I_CALLBACK_PROGRAM
            IT_FIELDCAT        = INFIELDCAT[]
            I_SAVE             = 'A' "控制缺省/特定用户
            IS_LAYOUT          = IS_LAYOUT
            IS_VARIANT         = IS_VARIANT
          TABLES
            T_OUTTAB           = ALVITAB
          EXCEPTIONS
            PROGRAM_ERROR      = 1
            OTHERS             = 2.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
**********************************
**********************************
*20200925
*&----------------------------------------------------------------------*
*&   FTP连接
*&----------------------------------------------------------------------*
*&  -->USER     FTP登录用户名
*&  -->PASS     密码
*&  -->HOST     FTP地址 端口(192.168.1.139 2121)
*&  -->RFCDES   SAPFTP:本机作为FTP客户端  SAPFTPA:SAP应用服务器作为FTP客户端
*&----------------------------------------------------------------------*
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
FORM FTP_CONNECT USING USER PASS HOST RFCDES
CHANGING HANDLE.
  DATA: SLEN            TYPE I,
        MI_KEY          TYPE I VALUE 26101957,
        RFC_DESTINATION TYPE RFCDES-RFCDEST.
  DATA: PWD(30).
  CLEAR HANDLE.

  SLEN = STRLEN( PASS ).
  CALL FUNCTION 'HTTP_SCRAMBLE'
    EXPORTING
      SOURCE      = PASS
      SOURCELEN   = SLEN
      KEY         = MI_KEY
    IMPORTING
      DESTINATION = PWD.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  IF RFCDES IS INITIAL.
    RFC_DESTINATION = 'SAPFTPA'.
  ELSE.
    RFC_DESTINATION = RFCDES.
  ENDIF.

  "新版本SAP需要在表SAPFTP_SERVERS维护IP和端口,否则出04202错误(用户XX没有访问计算机XX的权限)
  CALL FUNCTION 'FTP_CONNECT'
    EXPORTING
      USER            = USER
      PASSWORD        = PWD
      HOST            = HOST
      RFC_DESTINATION = RFC_DESTINATION
    IMPORTING
      HANDLE          = HANDLE
    EXCEPTIONS
      NOT_CONNECTED   = 1
      OTHERS          = 2.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.                    "ftp_connect
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
*执行FTP命令
FORM FTP_COMMAND TABLES RESULT
                 USING HANDLE COMTXT
                 CHANGING OUTMSG.
  DATA: COMMAND(256).
  DATA: DATA TYPE TABLE OF CHAR2048 WITH HEADER LINE.
  REFRESH RESULT.
  CLEAR:OUTMSG.

  COMMAND = COMTXT.
  CALL FUNCTION 'FTP_COMMAND'
    EXPORTING
      HANDLE        = HANDLE
      COMMAND       = COMMAND
    TABLES
      DATA          = DATA
    EXCEPTIONS
      TCPIP_ERROR   = 1
      COMMAND_ERROR = 2
      DATA_ERROR    = 3
      OTHERS        = 4.
  IF SY-SUBRC NE 0.
    PERFORM MSGTOTEXT USING '' '' '' '' '' '' CHANGING OUTMSG.
    CONCATENATE 'E:' OUTMSG INTO OUTMSG.
    RETURN.
  ENDIF.
  LOOP AT DATA.
    APPEND DATA TO RESULT.
  ENDLOOP.
ENDFORM.                    "FTP_COMMAND
*谨慎修改！！！擅自修改系统所有自开发程序功能及接口函数都将受到影响！！！
*& 不要改动参数个数与类型！！！注意全局变量的声明！！！
* ---------------------------------------------------------------------*
*  断开FTP连接
*----------------------------------------------------------------------*
FORM FTP_DISCONNECT USING HANDLE.
  CALL FUNCTION 'FTP_DISCONNECT'
    EXPORTING
      HANDLE = HANDLE
    EXCEPTIONS
      OTHERS = 1.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.                    "ftp_disconnect
* ---------------------------------------------------------------------*
*  把FTP的文本文件放入SAP内表
*----------------------------------------------------------------------*
*  -->TXTTAB     文本内表
*  -->FPATHFILE  FTP带路径的文件
*  -->ENCODE     编码
*----------------------------------------------------------------------*
FORM FTPTOITAB TABLES TXTTAB USING HANDLE FPATHFILE ENCODE  .
  DATA: BINTAB TYPE W3MIMETABTYPE,
        BLEN   TYPE I.
*  DATA:TXTTAB TYPE LVC_T_1022 WITH HEADER LINE  .

  CALL FUNCTION 'FTP_SERVER_TO_R3'
    EXPORTING
      HANDLE        = HANDLE
      FNAME         = FPATHFILE
    IMPORTING
      BLOB_LENGTH   = BLEN
    TABLES
      BLOB          = BINTAB
    EXCEPTIONS
      TCPIP_ERROR   = 1
      COMMAND_ERROR = 2
      DATA_ERROR    = 3
      OTHERS        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CALL FUNCTION 'SCMS_BINARY_TO_TEXT'
    EXPORTING
      INPUT_LENGTH  = BLEN
      ENCODING      = ENCODE
    IMPORTING
      OUTPUT_LENGTH = BLEN
    TABLES
      BINARY_TAB    = BINTAB
      TEXT_TAB      = TXTTAB
    EXCEPTIONS
      FAILED        = 1
      OTHERS        = 2.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.
*将信息集转为RANGE表
FORM GS03 TABLES OUTRANGE USING INSETNAME.
  DATA:BEGIN OF IT_RAN OCCURS 0,
         ZDM TYPE CHAR30,
       END OF IT_RAN.
  DATA:SELSTR     TYPE CHAR100,
       SETNAME    TYPE SETLEAF-SETNAME,
       IT_SETLEAF TYPE TABLE OF SETLEAF WITH HEADER LINE.
  FIELD-SYMBOLS:<FS> TYPE ANY.
  CHECK INSETNAME IS NOT INITIAL.
  REFRESH:IT_RAN, OUTRANGE.
  SETNAME = INSETNAME.
  TRANSLATE SETNAME TO UPPER CASE.
  SELECT *
  INTO TABLE IT_SETLEAF
  FROM SETLEAF
  WHERE SETNAME = SETNAME.
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.

  LOOP AT IT_SETLEAF.
    CLEAR:OUTRANGE.
    ASSIGN COMPONENT 'SIGN' OF STRUCTURE OUTRANGE TO <FS>.
    IF SY-SUBRC EQ 0.
      <FS> = IT_SETLEAF-VALSIGN.
    ENDIF.
    ASSIGN COMPONENT 'OPTION' OF STRUCTURE OUTRANGE TO <FS>.
    IF SY-SUBRC EQ 0.
      <FS> = IT_SETLEAF-VALOPTION.
    ENDIF.
    ASSIGN COMPONENT 'LOW' OF STRUCTURE OUTRANGE TO <FS>.
    IF SY-SUBRC EQ 0.
      <FS> = IT_SETLEAF-VALFROM.
    ENDIF.
    ASSIGN COMPONENT 'HIGH' OF STRUCTURE OUTRANGE TO <FS>.
    IF SY-SUBRC EQ 0.
      <FS> = IT_SETLEAF-VALTO.
    ENDIF.
    COLLECT OUTRANGE.
    CLEAR:OUTRANGE,IT_SETLEAF.
  ENDLOOP.
ENDFORM.
**********************************
" EDIT BY DONGPZ AT 10.10.2020 20:42:28
*灵活设置断点(SU3中参数值ESP='X')
FORM BREAK USING INUNAME.
  DATA:UNAME TYPE SY-UNAME.
  IF INUNAME IS INITIAL.
    UNAME = SY-UNAME.
  ELSE.
    UNAME = INUNAME.
  ENDIF.
  TRANSLATE UNAME TO UPPER CASE.

  SELECT SINGLE COUNT(*)
  FROM USR05
  WHERE BNAME = UNAME
  AND   PARID = 'ESP'
  AND   PARVA = 'X'.
  IF SY-SUBRC = 0.
    BREAK-POINT.
  ENDIF.
ENDFORM.
**********************************
**********************************************************************
"EDIT BY DONGPZ AT 27.10.2020 13:15:27
*去千分位
FORM DELQFW CHANGING INMENGE.
  PERFORM REPLACE(ZPUBFORM) USING ',' '' CHANGING INMENGE.
  CONDENSE INMENGE NO-GAPS.
ENDFORM.
*检查值域
FORM CHECKDOM USING INDOMAIN INVALUE.
  DATA:IT_DD07V TYPE TABLE OF DD07V WITH HEADER LINE,
       WA_DD01T TYPE DD01T,
       DOMMSG   TYPE BAPI_MSG.
  CHECK INVALUE IS NOT INITIAL.

  PERFORM GETDOMAIN(ZPUBFORM) TABLES IT_DD07V USING INDOMAIN.
  READ TABLE IT_DD07V WITH KEY DOMVALUE_L = INVALUE.
  IF SY-SUBRC NE 0.
    SELECT SINGLE *
    INTO WA_DD01T
    FROM DD01T
    WHERE DDLANGUAGE = SY-LANGU
    AND   AS4LOCAL = 'A'
    AND   DOMNAME = INDOMAIN.
    CONCATENATE WA_DD01T-DDTEXT INVALUE '不在可输入范围内' INTO DOMMSG.
    MESSAGE E000(OO) WITH DOMMSG." DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
**********************************************************************
********ADD BY DONGPZ BEGIN AT 30.10.2020 21:43:50
*根据内表/工作区获取内表字段名
FORM GETTABSTRU USING INWA CHANGING OUTFIELDCAT TYPE SLIS_T_FIELDCAT_ALV.
  DATA:CL_STRU  TYPE REF TO CL_ABAP_STRUCTDESCR,
       WA_FIELD TYPE SLIS_FIELDCAT_ALV,
       N        TYPE I.
  FIELD-SYMBOLS:<FS_COMP> TYPE ABAP_COMPDESCR.
  CLEAR:N,OUTFIELDCAT.

  CL_STRU ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( INWA ).

  LOOP AT CL_STRU->COMPONENTS ASSIGNING <FS_COMP>.
    WA_FIELD-FIELDNAME = <FS_COMP>-NAME.
    WA_FIELD-INTTYPE = <FS_COMP>-TYPE_KIND.
    WA_FIELD-INTLEN = <FS_COMP>-LENGTH.
    WA_FIELD-DECIMALS_OUT = <FS_COMP>-DECIMALS.
    APPEND WA_FIELD TO OUTFIELDCAT.
    CLEAR WA_FIELD.
  ENDLOOP.
ENDFORM.
*获取内表的DDIC结构--内表需参照SE11结构/表
FORM GETTABSTRU_SE11 USING INTAB CHANGING OUTFIELDCAT TYPE SLIS_T_FIELDCAT_ALV.
  DATA: LO_DESCR  TYPE REF TO CL_ABAP_STRUCTDESCR,
        IT_FIELDS TYPE DDFIELDS,
        WA_FIELDS TYPE DFIES,
        WA_FIELD  TYPE SLIS_FIELDCAT_ALV,
        TABNAME   TYPE TABNAME,
        ITAB      TYPE REF TO DATA,
        CXROOT    TYPE REF TO CX_ROOT,
        MSG       TYPE BAPI_MSG.
  FIELD-SYMBOLS: <ITAB> TYPE ANY.
  CLEAR:TABNAME.

  CREATE DATA ITAB LIKE INTAB.
  ASSIGN ITAB->* TO <ITAB>.

  LO_DESCR ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( <ITAB> ).
  IT_FIELDS = LO_DESCR->GET_DDIC_FIELD_LIST( P_LANGU = SY-LANGU
  P_INCLUDING_SUBSTRUCTRES = ABAP_TRUE ).
  LOOP AT IT_FIELDS INTO WA_FIELDS.
    MOVE-CORRESPONDING WA_FIELDS TO WA_FIELD.
    WA_FIELD-DECIMALS_OUT = WA_FIELDS-DECIMALS.
    APPEND WA_FIELD TO OUTFIELDCAT.
    CLEAR:WA_FIELD,WA_FIELDS.
  ENDLOOP.


ENDFORM.
********ADD BY DONGPZ END AT 30.10.2020 21:43:50
********ADD BY DONGPZ BEGIN AT 17.12.2020 09:35:43
*货币金额转换(TO 为目的金额)
FORM GETKURRF USING P_CURRFROM P_CURRTO
               CHANGING P_OUT_CURR.
  DATA:CURRENCY        TYPE TCURC-WAERS,
       LOCAL_CURRENCY  TYPE TCURC-WAERS,
       AMOUNT_EXTERNAL TYPE BAPICURR-BAPICURR,
       AMOUNT_INTERNAL TYPE TCURR-UKURS,
       LOCAL_AMOUNT    TYPE TCURR-UKURS.
  CLEAR:P_OUT_CURR,CURRENCY,LOCAL_CURRENCY,AMOUNT_EXTERNAL,
        AMOUNT_INTERNAL,LOCAL_AMOUNT.


  CURRENCY = P_CURRFROM.
  AMOUNT_EXTERNAL = 1.
  LOCAL_CURRENCY = P_CURRTO.
*** Conversion of Currency Amounts into Internal Data Format
  CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_INTERNAL'
    EXPORTING
      CURRENCY             = CURRENCY
      AMOUNT_EXTERNAL      = AMOUNT_EXTERNAL
      MAX_NUMBER_OF_DIGITS = 13
    IMPORTING
      AMOUNT_INTERNAL      = AMOUNT_INTERNAL.
*** Translate foreign currency amount to local currency
  CALL FUNCTION 'CONVERT_TO_LOCAL_CURRENCY'
    EXPORTING
      DATE             = SY-DATUM
      FOREIGN_AMOUNT   = AMOUNT_INTERNAL
      FOREIGN_CURRENCY = CURRENCY
      LOCAL_CURRENCY   = LOCAL_CURRENCY
      TYPE_OF_RATE     = 'M'
    IMPORTING
      LOCAL_AMOUNT     = LOCAL_AMOUNT
    EXCEPTIONS
      NO_RATE_FOUND    = 1
      OTHERS           = 2.

  P_OUT_CURR = LOCAL_AMOUNT.
ENDFORM.
********ADD BY DONGPZ END AT 17.12.2020 09:35:43
********ADD BY DONGPZ BEGIN AT 22.12.2020 21:08:24
*单个关闭/删除采购订单
FORM CLOSEPO TABLES P_IN_EKPO STRUCTURE EKPO
              CHANGING P_OUT_MSG.
  DATA:PURCHASEORDER TYPE BAPIMEPOHEADER-PO_NUMBER,
       POHEADER      TYPE BAPIMEPOHEADER,
       POHEADERX     TYPE BAPIMEPOHEADERX,
       INTYPE        TYPE CHAR30,
       RETURN        TYPE TABLE OF BAPIRET2 WITH HEADER LINE,
       POITEM        TYPE TABLE OF BAPIMEPOITEM WITH HEADER LINE,
       POITEMX       TYPE TABLE OF BAPIMEPOITEMX WITH HEADER LINE,
       IT_EKPON      TYPE TABLE OF EKPO WITH HEADER LINE.
  CASE P_OUT_MSG.
    WHEN 'DEL' OR 'CLOSE'.
    WHEN OTHERS.
      P_OUT_MSG = 'E:类型错误'.
      RETURN.
  ENDCASE.
  INTYPE = P_OUT_MSG.
  REFRESH:RETURN,POITEM,POITEMX,IT_EKPON.
  CLEAR:POHEADER,POHEADERX,POITEM,POITEMX,RETURN,P_OUT_MSG,PURCHASEORDER.

  DELETE P_IN_EKPO WHERE EBELN IS INITIAL OR EBELP IS INITIAL.
  IF P_IN_EKPO[] IS INITIAL.
    P_OUT_MSG = 'E:无数据'.
    RETURN.
  ENDIF.
  IT_EKPON[] = P_IN_EKPO[].
  SORT IT_EKPON BY EBELN.
  DELETE ADJACENT DUPLICATES FROM IT_EKPON COMPARING EBELN.
  IF LINES( IT_EKPON ) GT 1.
    P_OUT_MSG = 'E:一次输入一条PO'.
    RETURN.
  ENDIF.
  READ TABLE P_IN_EKPO INDEX 1.
  PURCHASEORDER = P_IN_EKPO-EBELN.
  POHEADER-PO_NUMBER = PURCHASEORDER.

  LOOP AT P_IN_EKPO.
    POITEM-PO_ITEM = P_IN_EKPO-EBELP.
    POITEMX-PO_ITEM = P_IN_EKPO-EBELP.
    POITEMX-PO_ITEMX = 'X'.
    CASE INTYPE.
      WHEN 'DEL'.
        POITEM-DELETE_IND = 'L'.
        POITEMX-DELETE_IND = 'X'.
      WHEN 'CLOSE'.
        POITEM-NO_MORE_GR = 'X'.
        POITEMX-NO_MORE_GR = 'X'.
    ENDCASE.
    APPEND:POITEM,POITEMX.
    CLEAR:POITEM,POITEMX.
  ENDLOOP.

  CALL FUNCTION 'BAPI_PO_CHANGE'
    EXPORTING
      PURCHASEORDER = PURCHASEORDER
      POHEADER      = POHEADER
    TABLES
      POITEM        = POITEM
      POITEMX       = POITEMX
      RETURN        = RETURN
    EXCEPTIONS
      OTHERS        = 1.
  IF SY-SUBRC NE 0.
    PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
    RETURN-TYPE = 'E'.
    APPEND RETURN.
    CLEAR RETURN.
  ENDIF.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE RETURN-MESSAGE P_OUT_MSG INTO P_OUT_MSG SEPARATED BY '/'.
  ENDLOOP.
  IF SY-SUBRC EQ 0.
    ROLLBACK WORK.
    CONCATENATE 'E:' P_OUT_MSG INTO P_OUT_MSG.
  ELSE.
    COMMIT WORK AND WAIT.
    P_OUT_MSG = 'S:成功'.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 22.12.2020 21:08:24
********ADD BY DONGPZ BEGIN AT 26.12.2020 13:07:11
*&---------------------------------------------------------------------*
*& 根据完整路径获取文件名和扩展名
*&---------------------------------------------------------------------*
FORM GETFILEEXT USING VALUE(FILEPATH)
                  CHANGING P_FILENAME P_FILEXT.
  CLEAR: P_FILENAME,P_FILEXT.
  CHECK FILEPATH IS NOT INITIAL.

  P_FILENAME = SUBSTRING_AFTER( VAL = FILEPATH SUB = '\' OCC = COUNT( VAL = FILEPATH SUB = '\' ) ).
  P_FILEXT = SUBSTRING_AFTER( VAL = FILEPATH SUB = '.' OCC = COUNT( VAL = FILEPATH SUB = '.' ) ).
ENDFORM.                    "GETFILEEXT
********ADD BY DONGPZ END AT 26.12.2020 13:07:11
********ADD BY DONGPZ BEGIN AT 30.12.2020 21:26:12
*将行纵向展示
FORM GETDETAIL USING P_INTAB P_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV.
  DATA:IT_FIELDCATALOG TYPE LVC_T_FCAT,
       IS_LAYOUT       TYPE LVC_S_LAYO,
       IT_DETAIL_TAB   TYPE LVC_T_DETA,
       WA_DETAIL_TAB   TYPE LVC_S_DETA,
       IT_DETAIL       TYPE LVC_T_DETM,
       WA_DETAIL       TYPE LVC_S_DETM,
       WA_FIELDCAT     TYPE SLIS_FIELDCAT_ALV,
       WA_FIELDCATALOG LIKE LINE OF IT_FIELDCATALOG.
  FIELD-SYMBOLS:<FS_VALUE> TYPE ANY.

  CLEAR:IT_FIELDCATALOG,WA_FIELDCATALOG,WA_FIELDCAT,WA_DETAIL_TAB.
*列名
  WA_FIELDCATALOG-FIELDNAME = 'COLUMNTEXT'.
  WA_FIELDCATALOG-REF_TABLE = 'LVC_S_DETA'.
  WA_FIELDCATALOG-KEY = 'X'.
  WA_FIELDCATALOG-OUTPUTLEN = 30.
  APPEND WA_FIELDCATALOG TO IT_FIELDCATALOG.
  CLEAR WA_FIELDCATALOG.

  WA_FIELDCATALOG-FIELDNAME = 'VALUE'.
  WA_FIELDCATALOG-REF_TABLE = 'LVC_S_DETA'.
  WA_FIELDCATALOG-KEY = 'X'.
  WA_FIELDCATALOG-OUTPUTLEN = 20.
  APPEND WA_FIELDCATALOG TO IT_FIELDCATALOG.
  CLEAR WA_FIELDCATALOG.
*将布局纵向
  LOOP AT P_FIELDCAT INTO WA_FIELDCAT.
    WA_DETAIL_TAB-COLUMNTEXT = WA_FIELDCAT-SELTEXT_L.
    ASSIGN COMPONENT WA_FIELDCAT-FIELDNAME OF STRUCTURE P_INTAB TO <FS_VALUE>.
    IF SY-SUBRC EQ 0.
      WA_DETAIL_TAB-VALUE = <FS_VALUE>.
    ENDIF.
    APPEND WA_DETAIL_TAB TO IT_DETAIL_TAB.
    CLEAR WA_DETAIL_TAB.
  ENDLOOP.


  WA_DETAIL-BLOCKINDEX = 1.
  WA_DETAIL-DETAILTAB = IT_DETAIL_TAB[].
  APPEND WA_DETAIL TO IT_DETAIL.

  CALL FUNCTION 'LVC_ITEM_DETAIL'
    EXPORTING
      IT_FIELDCATALOG = IT_FIELDCATALOG
      IS_LAYOUT       = IS_LAYOUT
    TABLES
      T_OUTTAB        = IT_DETAIL
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.
********ADD BY DONGPZ END AT 30.12.2020 21:26:12
********ADD BY DONGPZ BEGIN AT 01.01.2021 20:24:43
*对TABLE CONTROL结构进行动态排序-最多支持6列
FORM TCSORT USING P_INTAB P_TC P_SORTYPE.
  DATA:BEGIN OF IT_TABZDM OCCURS 0,
         ZDM1 TYPE CHAR30,
         ZDM2 TYPE CHAR30,
         ZDM3 TYPE CHAR30,
         ZDM4 TYPE CHAR30,
         ZDM5 TYPE CHAR30,
         ZDM6 TYPE CHAR30,
       END OF IT_TABZDM,
       TC_COLS TYPE SCXTAB_COLUMN,
       ROWSL   TYPE I.
  FIELD-SYMBOLS:<FS_TC>    TYPE SCXTAB_CONTROL,
                <FS_TAB>   TYPE STANDARD TABLE,
                <FS_VALUE>.
  CLEAR:IT_TABZDM,ROWSL,TC_COLS.
  ASSIGN P_TC TO <FS_TC>.
  ASSIGN P_INTAB TO <FS_TAB>.


  LOOP AT <FS_TC>-COLS INTO TC_COLS WHERE SELECTED = 'X'.
    ROWSL = ROWSL + 1.
    IF ROWSL GT 6.
      MESSAGE S000(OO) WITH '最多支持6列排序'.
      EXIT.
    ENDIF.
    ASSIGN COMPONENT ROWSL OF STRUCTURE IT_TABZDM TO <FS_VALUE>.
    IF SY-SUBRC EQ 0.
      <FS_VALUE> = TC_COLS-SCREEN-NAME.
      SPLIT <FS_VALUE> AT '-' INTO <FS_VALUE> <FS_VALUE>.
    ENDIF.
  ENDLOOP.
  IF SY-SUBRC NE 0.
    GET CURSOR FIELD IT_TABZDM-ZDM1.
    SPLIT IT_TABZDM-ZDM1 AT '-' INTO IT_TABZDM-ZDM1 IT_TABZDM-ZDM1.
  ENDIF.
  IF IT_TABZDM-ZDM1 IS NOT INITIAL.
    CASE P_SORTYPE.
      WHEN 'UP'.
        SORT <FS_TAB> BY (IT_TABZDM-ZDM1) (IT_TABZDM-ZDM2) (IT_TABZDM-ZDM3)
                 (IT_TABZDM-ZDM4) (IT_TABZDM-ZDM5) (IT_TABZDM-ZDM6).
      WHEN 'DOWN'.
        SORT <FS_TAB> DESCENDING BY (IT_TABZDM-ZDM1) (IT_TABZDM-ZDM2) (IT_TABZDM-ZDM3)
                                    (IT_TABZDM-ZDM4) (IT_TABZDM-ZDM5) (IT_TABZDM-ZDM6).
    ENDCASE.
  ELSE.
    MESSAGE S000(OO) WITH '请选中列/把光标定在某一列'.
  ENDIF.
ENDFORM.
*----------------------------------------------------------------------*
*  TC翻页功能
*P_TC_NAME以双引号传入TC名，GLINE为行数
*需在程序中使用，因需确定光标位置与屏幕
*----------------------------------------------------------------------*
FORM TCROLL USING P_OK P_TC_NAME P_GLINE .
  DATA:L_TC_NEW_TOP_LINE TYPE I,
       L_TC_NAME         LIKE FELD-NAME,
       L_TC_LINES_NAME   LIKE FELD-NAME,
       L_TC_FIELD_NAME   LIKE FELD-NAME,
       L_OK              TYPE SY-UCOMM.
  FIELD-SYMBOLS <FS_TC> TYPE CXTAB_CONTROL.

  CLEAR:L_OK.

  CASE P_OK.
    WHEN 'LAST'."上一页
      L_OK = 'P-'.
    WHEN 'NEXT'."下一页
      L_OK = 'P+'.
    WHEN 'TOP'."第一页
      L_OK = 'P--'.
    WHEN 'BOTTOM'."最后一页
      L_OK = 'P++'.
    WHEN OTHERS .
      RETURN.
  ENDCASE.

  ASSIGN (P_TC_NAME) TO <FS_TC>.
  IF <FS_TC>-LINES = 0.
    L_TC_NEW_TOP_LINE = 1.
  ELSE.
    CALL FUNCTION 'SCROLLING_IN_TABLE'
      EXPORTING
        ENTRY_ACT      = <FS_TC>-TOP_LINE
        ENTRY_FROM     = 1
        ENTRY_TO       = <FS_TC>-LINES
        LAST_PAGE_FULL = 'X'
        LOOPS          = P_GLINE
        OK_CODE        = L_OK
        OVERLAPPING    = 'X'
      IMPORTING
        ENTRY_NEW      = L_TC_NEW_TOP_LINE
      EXCEPTIONS
        OTHERS         = 0.
  ENDIF.


  GET CURSOR FIELD L_TC_FIELD_NAME AREA L_TC_NAME.
  IF SY-SUBRC = 0.
    IF L_TC_NAME = P_TC_NAME.
      SET CURSOR FIELD L_TC_FIELD_NAME LINE 1.
    ENDIF.
  ENDIF.

  <FS_TC>-TOP_LINE = L_TC_NEW_TOP_LINE.
ENDFORM.                              " tc_scroll
*----------------------------------------------------------------------*
*  搜索功能，选中需要搜索的列，或者光标放到需要搜索的列内。
*  点搜索/继续搜索按钮，或者使用快捷键Ctrl+F、Ctrl+G
*  搜索到后会把光标定位到当前行
*  如果是C类型数据，自动模糊搜索。其他数据类型精确搜索
*若TC内表为程序中定义的，则不需输入结构名
*需在程序中使用
*----------------------------------------------------------------------*
FORM TCSEARCH USING P_UCOMM TCNAME P_INTAB P_TABNAME.
  DATA: BEGIN OF FIELDS OCCURS 1.
          INCLUDE STRUCTURE SVAL.
  DATA: END OF FIELDS.
  DATA: RETURNCODE TYPE C.
  DATA: WA_DD03L LIKE DD03L.
  STATICS: S_FINDS TYPE STRING,
           S_COLNM TYPE STRING,
           S_INDEX TYPE I,
           SUBRC   TYPE I,
           TABIX   TYPE I,
           S_WHSTR TYPE STRING.
  DATA: WANAMELEN      TYPE I,
        FIELD_NAME     LIKE FELD-NAME,
        COLS           TYPE SCXTAB_COLUMN,
        WAFLDNAME(40),
        WAFLDNAME1(40),
        WAFLDTYPE.
  FIELD-SYMBOLS:<FS_TC>  TYPE                  SCXTAB_CONTROL,
                <FS_TAB> TYPE STANDARD TABLE.
  FIELD-SYMBOLS: <WA> ,<FIELD>.


  IF P_UCOMM IS INITIAL
    OR TCNAME IS INITIAL
    OR P_INTAB IS INITIAL.
    RETURN.
  ENDIF.


  ASSIGN TCNAME TO <FS_TC>.
  ASSIGN P_INTAB TO <FS_TAB>.
  IF <FS_TAB> IS NOT INITIAL.
    READ TABLE <FS_TAB> ASSIGNING <WA> INDEX 1.
  ENDIF.

  SUBRC = 1.
  IF P_UCOMM = 'SEARCH'.
    READ TABLE <FS_TC>-COLS WITH KEY SELECTED = 'X' INTO COLS.
    IF SY-SUBRC = 0.
      FIELD_NAME = COLS-SCREEN-NAME.
    ELSE.
      GET CURSOR FIELD FIELD_NAME.
      READ TABLE <FS_TC>-COLS WITH KEY SCREEN-NAME = FIELD_NAME INTO COLS.
    ENDIF.

    TABIX = SY-TABIX .
    SPLIT FIELD_NAME AT '-' INTO WAFLDNAME1 WAFLDNAME.
    ASSIGN COMPONENT WAFLDNAME OF STRUCTURE <WA> TO <FIELD>.
    DESCRIBE FIELD <FIELD> TYPE WAFLDTYPE.

*弹窗
    CLEAR:FIELDS,FIELDS[],WA_DD03L.

    IF P_TABNAME IS INITIAL.
      FIELDS-TABNAME = 'MAKT'.
      FIELDS-FIELDNAME = 'MAKTX'.
      FIELDS-FIELDTEXT = '输入'.
      APPEND FIELDS.
    ELSE.
      SPLIT FIELD_NAME AT '-' INTO WAFLDNAME1 FIELDS-FIELDNAME.
      SELECT SINGLE *
        INTO WA_DD03L
        FROM DD03L
        WHERE TABNAME = P_TABNAME
        AND FIELDNAME = FIELDS-FIELDNAME
        AND AS4LOCAL = 'A'.
      FIELDS-TABNAME =  P_TABNAME.
      FIELDS-FIELDTEXT = '输入'.
      APPEND FIELDS.
      IF WA_DD03L-REFTABLE IS NOT INITIAL.
        FIELDS-TABNAME = WA_DD03L-REFTABLE.
        FIELDS-FIELDNAME = WA_DD03L-REFFIELD.
        FIELDS-FIELD_ATTR = '04'.
        APPEND FIELDS.
      ENDIF.
    ENDIF.



    SUBRC = 1 .
    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
        POPUP_TITLE = '输入'
      IMPORTING
        RETURNCODE  = RETURNCODE
      TABLES
        FIELDS      = FIELDS.
    IF RETURNCODE = 'A'.
      RETURN.
    ELSE.
      READ TABLE FIELDS INDEX 1.
      S_FINDS = FIELDS-VALUE.
      SY-SUBRC = 0 .
    ENDIF.

    CHECK SY-SUBRC = 0 .
    IF WAFLDTYPE = 'C'. "如果是C类型的数据，则设置为模糊搜索
      CONCATENATE '*' S_FINDS '*' INTO S_FINDS.
      CONCATENATE WAFLDNAME ` CP ` `'` S_FINDS `'` INTO S_WHSTR.
    ELSE.
      CONDENSE S_FINDS.
      CONCATENATE WAFLDNAME ` = ` `'` S_FINDS `'` INTO S_WHSTR.
    ENDIF.
    LOOP AT <FS_TAB> ASSIGNING <WA> WHERE (S_WHSTR).
      <FS_TC>-TOP_LINE = SY-TABIX .

      S_INDEX = SY-TABIX + 1.
      S_COLNM = FIELD_NAME.
      SUBRC = 0 .
      EXIT.
    ENDLOOP.

  ELSE.
    CHECK S_COLNM IS NOT INITIAL AND S_FINDS IS NOT INITIAL.
    LOOP AT <FS_TAB> ASSIGNING <WA> FROM S_INDEX WHERE (S_WHSTR).
      <FS_TC>-TOP_LINE = SY-TABIX .
      S_INDEX = SY-TABIX + 1.
      SUBRC = 0 .
      EXIT.
    ENDLOOP.
  ENDIF.
  IF SUBRC = 1.
    MESSAGE S000(OO) WITH '没有符合条件的记录'.
  ENDIF.
ENDFORM.                    "tc_search
*TC选择功能
FORM TCSEL USING P_UCOMM P_TC P_INTAB P_MARKFLD.
  FIELD-SYMBOLS: <FS_TAB> TYPE STANDARD TABLE,
                 <FS_TC>  TYPE SCXTAB_CONTROL,
                 <WA> ,<FIELD>.
  DATA: VALUESTR,
        ENDTABIX TYPE I .

  ASSIGN P_TC TO <FS_TC>.
  ASSIGN P_INTAB TO <FS_TAB>.

  IF P_UCOMM = 'ALL'.
    VALUESTR = 'X'.
  ELSE.
    VALUESTR = ''.
  ENDIF.

  LOOP AT <FS_TAB> ASSIGNING <WA>  .
    ASSIGN COMPONENT P_MARKFLD OF STRUCTURE <WA> TO <FIELD>.
    IF SY-SUBRC = 0.
      <FIELD> = VALUESTR.
    ENDIF.
  ENDLOOP.

ENDFORM.                    "tc_mark
********ADD BY DONGPZ END AT 01.01.2021 20:24:43
********ADD BY DONGPZ BEGIN AT 28.01.2021 10:56:46
*确认弹窗
FORM CONFIRMACT USING P_QUESTION CHANGING P_ANSWER.
  DATA:TEXT_QUESTION TYPE BAPI_MSG.
  CLEAR :TEXT_QUESTION,P_ANSWER.
  IF P_QUESTION IS NOT INITIAL.
    TEXT_QUESTION = P_QUESTION.
  ELSE.
    TEXT_QUESTION = '请确认操作！'.
  ENDIF.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      TEXT_QUESTION  = TEXT_QUESTION
      TEXT_BUTTON_1  = '是'
      TEXT_BUTTON_2  = '否'
    IMPORTING
      ANSWER         = P_ANSWER
    EXCEPTIONS
      TEXT_NOT_FOUND = 1
      OTHERS         = 2.
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 28.01.2021 10:56:46
********ADD BY DONGPZ BEGIN AT 09.04.2021 16:46:42
*冲销会计凭证
FORM FB08 USING P_INBELNR
                P_INGJAHR
                P_INBUKRS
                P_INCODE
                P_INBUDAT
          CHANGING P_MSG.
  DATA:WA_BKPF    TYPE BKPF,
       REVERSAL   TYPE BAPIACREV,
       OBJ_TYPE   TYPE BAPIACREV-OBJ_TYPE,
       OBJ_KEY    TYPE BAPIACREV-OBJ_KEY,
       OBJ_SYS    TYPE BAPIACREV-OBJ_SYS,
       FB08RETURN TYPE TABLE OF BAPIRET2 WITH HEADER LINE.

  CHECK P_INBELNR IS NOT INITIAL
    AND P_INGJAHR IS NOT INITIAL
    AND P_INBUKRS IS NOT INITIAL.


  REFRESH:FB08RETURN.
  CLEAR:WA_BKPF,P_MSG,REVERSAL,OBJ_TYPE,OBJ_KEY,OBJ_SYS.
  SELECT SINGLE *
    INTO WA_BKPF
    FROM BKPF
    WHERE BUKRS = P_INBUKRS
    AND   BELNR = P_INBELNR
    AND   GJAHR = P_INGJAHR.
  IF SY-SUBRC NE 0.
    P_MSG = 'E:凭证不存在'.
    RETURN.
  ENDIF.

  REVERSAL-COMP_CODE = WA_BKPF-BUKRS.
*  REVERSAL-AC_DOC_NO  = WA_BKPF-BELNR.
  IF P_INCODE IS NOT INITIAL.
    REVERSAL-REASON_REV = P_INCODE.
  ELSE.
    REVERSAL-REASON_REV = '03'.
  ENDIF.
  REVERSAL-OBJ_TYPE = WA_BKPF-AWTYP.
  REVERSAL-OBJ_KEY = WA_BKPF-AWKEY.
  REVERSAL-OBJ_KEY_R = WA_BKPF-AWKEY.
  IF REVERSAL-REASON_REV = '03'.
    REVERSAL-PSTNG_DATE = WA_BKPF-BUDAT.
  ELSE.
    IF P_INBUDAT IS INITIAL.
      REVERSAL-PSTNG_DATE = SY-DATUM.
    ELSE.
      REVERSAL-PSTNG_DATE = P_INBUDAT.
    ENDIF.
  ENDIF.
  CALL FUNCTION 'OWN_LOGICAL_SYSTEM_GET'
    IMPORTING
      OWN_LOGICAL_SYSTEM = REVERSAL-OBJ_SYS.

  CALL FUNCTION 'BAPI_ACC_DOCUMENT_REV_CHECK'
    EXPORTING
      REVERSAL = REVERSAL
      BUS_ACT  = WA_BKPF-GLVOR
    TABLES
      RETURN   = FB08RETURN.
  LOOP AT FB08RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE FB08RETURN-MESSAGE P_MSG INTO P_MSG.
  ENDLOOP.
  IF SY-SUBRC EQ 0.
    CONCATENATE 'E:' P_MSG INTO P_MSG.
    RETURN.
  ENDIF.

  REFRESH:FB08RETURN.
  CLEAR:P_MSG.


  CALL FUNCTION 'BAPI_ACC_DOCUMENT_REV_POST'
    EXPORTING
      REVERSAL = REVERSAL
      BUS_ACT  = WA_BKPF-GLVOR
    IMPORTING
      OBJ_TYPE = OBJ_TYPE
      OBJ_KEY  = OBJ_KEY
      OBJ_SYS  = OBJ_SYS
    TABLES
      RETURN   = FB08RETURN.
*OBJ_KEY-凭证号+公司+年度
  LOOP AT FB08RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE FB08RETURN-MESSAGE P_MSG INTO P_MSG.
  ENDLOOP.
  IF SY-SUBRC NE 0
    AND OBJ_KEY IS NOT INITIAL.
    CONCATENATE 'S:' OBJ_KEY INTO P_MSG.
    COMMIT WORK AND WAIT .
  ELSE.
    CONCATENATE 'E:' P_MSG INTO P_MSG.
    ROLLBACK WORK.
  ENDIF.

ENDFORM.                                                    "FB08
********ADD BY DONGPZ END AT 09.04.2021 16:46:42
********ADD BY DONGPZ BEGIN AT 30.06.2021 13:19:50
*去除结构中字段中的空格
FORM DELSPACE CHANGING P_IN_STRU.
  FIELD-SYMBOLS:<FS_FLD> TYPE ANY.
  DATA:FTYPE   TYPE CHAR1,
       CHARSTR TYPE STRING,
       CHARC   TYPE CHAR2048.
  DO.
    CLEAR:FTYPE,CHARC.
    ASSIGN COMPONENT SY-INDEX OF STRUCTURE P_IN_STRU TO <FS_FLD>.
    IF SY-SUBRC NE 0.
      EXIT.
    ENDIF.
    IF <FS_FLD> IS INITIAL.
      CONTINUE.
    ENDIF.
*判断字段类型
    DESCRIBE FIELD <FS_FLD> TYPE FTYPE.
    CASE FTYPE.
      WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'."数值
      WHEN 'D' OR 'T'."DATS/TIMS
        CONDENSE <FS_FLD> NO-GAPS.
      WHEN 'X' OR 'y' OR 'g'."LRAW/STRING/XSTRING
      WHEN 'h' OR 'H'.
      WHEN OTHERS.
        CONDENSE <FS_FLD> NO-GAPS.
    ENDCASE.
  ENDDO.
ENDFORM.
********ADD BY DONGPZ END AT 30.06.2021 13:19:50
********ADD BY DONGPZ BEGIN AT 02.08.2021 10:40:40
*针对交货单/SO完全开票
FORM SDVF01 TABLES INVBELN STRUCTURE BAPIVBELN
          USING P_IN_DATUM
          CHANGING P_OUT_MSG.
  DATA:T_LIPS        TYPE TABLE OF LIPS WITH HEADER LINE,
       T_VBAK        TYPE TABLE OF VBAK WITH HEADER LINE,
       CREATORDATAIN TYPE BAPICREATORDATA,
       INTYPE        TYPE CHAR30,
       MSG           TYPE BAPI_MSG,
       DATUM1        TYPE SY-DATUM,
       RETURN        TYPE TABLE OF BAPIRET1 WITH HEADER LINE,
       SUCCESS       TYPE TABLE OF BAPIVBRKSUCCESS WITH HEADER LINE,
       BILLINGDATAIN TYPE TABLE OF BAPIVBRK WITH HEADER LINE.
  CLEAR:MSG, DATUM1.
  CASE P_OUT_MSG.
    WHEN 'DN' OR 'SO'.
    WHEN OTHERS.
      P_OUT_MSG = 'E:FAIL'.
  ENDCASE.

  INTYPE = P_OUT_MSG.

  REFRESH:BILLINGDATAIN,RETURN,SUCCESS.
  CLEAR:CREATORDATAIN,P_OUT_MSG,SUCCESS.

  CHECK INVBELN[] IS NOT INITIAL.
  LOOP AT INVBELN.
    PERFORM ADDZERO(ZPUBFORM) CHANGING INVBELN-VBELN.
    MODIFY INVBELN.
  ENDLOOP.
  SORT INVBELN BY VBELN.
  DATUM1 = P_IN_DATUM.
  IF DATUM1 IS INITIAL.
    DATUM1 = SY-DATUM.
  ENDIF.
  CREATORDATAIN-CREATED_BY = SY-UNAME.
  CREATORDATAIN-CREATED_ON = SY-DATUM.

  CASE INTYPE.
    WHEN 'SO'.
      SELECT *
        INTO TABLE T_VBAK
        FROM VBAK
        FOR ALL ENTRIES IN INVBELN
        WHERE VBELN = INVBELN-VBELN.
      LOOP AT T_VBAK.
        CLEAR:BILLINGDATAIN.
        BILLINGDATAIN-REF_DOC = T_VBAK-VBELN.
        BILLINGDATAIN-BILL_DATE = DATUM1.
        BILLINGDATAIN-REF_DOC_CA = 'C' .
        APPEND BILLINGDATAIN.
      ENDLOOP.
    WHEN 'DN'.
      SELECT *
        INTO TABLE T_LIPS
        FROM LIPS
        FOR ALL ENTRIES IN INVBELN
        WHERE VBELN = INVBELN-VBELN.
      SORT T_LIPS BY VBELN.
      LOOP AT T_LIPS.
        CLEAR:BILLINGDATAIN.
        BILLINGDATAIN-DOC_NUMBER = T_LIPS-VGBEL.
        BILLINGDATAIN-REF_DOC = T_LIPS-VBELN.
        BILLINGDATAIN-BILL_DATE = DATUM1.
        BILLINGDATAIN-REF_DOC_CA = 'J' .
        APPEND BILLINGDATAIN.
      ENDLOOP.
    WHEN OTHERS.
      P_OUT_MSG = 'E:FAIL'.
  ENDCASE.
  SET UPDATE TASK LOCAL.
  CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
    EXPORTING
      CREATORDATAIN = CREATORDATAIN
    TABLES
      BILLINGDATAIN = BILLINGDATAIN
      RETURN        = RETURN
      SUCCESS       = SUCCESS
    EXCEPTIONS
      OTHERS        = 1.
  IF SY-SUBRC NE 0.
    P_OUT_MSG = 'E:FAIL'.
    EXIT.
  ENDIF.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE RETURN-MESSAGE P_OUT_MSG INTO P_OUT_MSG.
  ENDLOOP.
  IF SY-SUBRC EQ 0.
    MSG = P_OUT_MSG.
    CONCATENATE 'E:' P_OUT_MSG INTO P_OUT_MSG.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
*若会计凭证失败，开票成功，返回销售发票
    READ TABLE SUCCESS INDEX 1.
    IF SUCCESS-BILL_DOC IS NOT INITIAL.
      DO 100 TIMES.
        SELECT SINGLE COUNT(*)
          FROM VBRK
          WHERE VBELN = SUCCESS-BILL_DOC.
        IF SY-SUBRC EQ 0.
          CLEAR P_OUT_MSG.
          CONCATENATE 'ES:' SUCCESS-BILL_DOC MSG
          INTO P_OUT_MSG.
          EXIT.
        ENDIF.
      ENDDO.
    ENDIF.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        WAIT = 'X'.
    READ TABLE SUCCESS INDEX 1.
    IF SUCCESS-BILL_DOC IS INITIAL.
      P_OUT_MSG = 'E:FAIL'.
    ELSE.
      CONCATENATE 'S:' SUCCESS-BILL_DOC INTO P_OUT_MSG.
    ENDIF.
  ENDIF.
ENDFORM.
*SO创建DN
FORM VL01N TABLES INVBAP STRUCTURE VBAP
            USING P_IN_VSTEL P_IN_DATUM
            CHANGING P_OUT_MSG.
  DATA:SALES_ORDER_ITEMS TYPE TABLE OF BAPIDLVREFTOSALESORDER WITH HEADER LINE,
       RETURN            TYPE TABLE OF BAPIRET2 WITH HEADER LINE,
       IT_VBELN          TYPE TABLE OF BAPIVBELN WITH HEADER LINE,
       SHIP_POINT        TYPE BAPIDLVCREATEHEADER-SHIP_POINT,
       DELIVERY          TYPE BAPISHPDELIVNUMB-DELIV_NUMB,
       DUE_DATE          TYPE BAPIDLVCREATEHEADER-DUE_DATE.
  CHECK INVBAP[] IS NOT INITIAL.
  IF P_OUT_MSG = 'X'."全量创建
    LOOP AT INVBAP.
      CLEAR:INVBAP-KWMENG,INVBAP-VRKME,INVBAP-POSNR.
      MODIFY INVBAP.
    ENDLOOP.
    SORT INVBAP BY VBELN.
    DELETE ADJACENT DUPLICATES FROM INVBAP COMPARING VBELN.
  ENDIF.
  CLEAR:P_OUT_MSG,DUE_DATE,SHIP_POINT,DELIVERY.
  REFRESH:RETURN,SALES_ORDER_ITEMS,IT_VBELN.

  IF P_IN_DATUM IS INITIAL.
    DUE_DATE = SY-DATUM.
  ELSE.
    DUE_DATE = P_IN_DATUM.
  ENDIF.
  SHIP_POINT = P_IN_VSTEL.
  LOOP AT INVBAP.
    CLEAR:SALES_ORDER_ITEMS.
    SALES_ORDER_ITEMS-REF_DOC = INVBAP-VBELN.
    SALES_ORDER_ITEMS-REF_ITEM = INVBAP-POSNR.
    SALES_ORDER_ITEMS-DLV_QTY = INVBAP-KWMENG.
    SALES_ORDER_ITEMS-SALES_UNIT = INVBAP-VRKME.
    APPEND SALES_ORDER_ITEMS.
  ENDLOOP.
  CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_SLS'
    EXPORTING
      SHIP_POINT        = SHIP_POINT
      DUE_DATE          = DUE_DATE
    IMPORTING
      DELIVERY          = DELIVERY
    TABLES
      SALES_ORDER_ITEMS = SALES_ORDER_ITEMS
      RETURN            = RETURN
    EXCEPTIONS
      OTHERS            = 1.
  IF SY-SUBRC NE 0.
    P_OUT_MSG = 'E:FAIL'.
    EXIT.
  ENDIF.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE RETURN-MESSAGE P_OUT_MSG INTO P_OUT_MSG.
  ENDLOOP.
  IF SY-SUBRC EQ 0.
    CONCATENATE 'E:' P_OUT_MSG INTO P_OUT_MSG.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    EXIT.
  ENDIF.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      WAIT = 'X'.

  IF DELIVERY IS INITIAL.
    P_OUT_MSG = 'E:FAIL'.
    EXIT.
  ENDIF.
  CONCATENATE 'S:' DELIVERY INTO P_OUT_MSG.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  itabtostr内表转为字符串
*&---------------------------------------------------------------------*
FORM ITABTOSTR TABLES INTAB
                CHANGING OUTSTR TYPE STRING.
  DATA: TAB      TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB,
        ENTER(2) TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>CR_LF,
        N        TYPE I.
  DATA: BEGIN OF HEADTAB OCCURS 0 ,
          LENGTH    TYPE I,
          DECIMALS  TYPE I,
          TYPE_KIND TYPE C,
          NAME(30)  TYPE C,
        END OF HEADTAB.
  DATA DESCR_REF TYPE REF TO CL_ABAP_STRUCTDESCR.
  FIELD-SYMBOLS: <COMP_WA> TYPE ABAP_COMPDESCR,
                 <F_FIELD> ,
                 <F_INTAB> TYPE ANY.
  DATA:STR   TYPE STRING,
       STR2  TYPE STRING,
       TEXT1 TYPE C.

  DESCR_REF ?= CL_ABAP_TYPEDESCR=>DESCRIBE_BY_DATA( INTAB ).
  LOOP AT DESCR_REF->COMPONENTS ASSIGNING <COMP_WA>.
    MOVE-CORRESPONDING <COMP_WA> TO HEADTAB.
    APPEND HEADTAB.
  ENDLOOP.

  DESCRIBE TABLE HEADTAB LINES N.

  LOOP AT INTAB ASSIGNING <F_INTAB>.
    DO N TIMES.
      ASSIGN COMPONENT SY-INDEX OF STRUCTURE <F_INTAB> TO <F_FIELD>.
      STR = <F_FIELD>.
      READ TABLE HEADTAB INDEX SY-INDEX.
      IF HEADTAB-TYPE_KIND = 'I' OR HEADTAB-TYPE_KIND = 'P'
                                 OR HEADTAB-TYPE_KIND = 'F'.
        SEARCH STR FOR '-'.
        IF SY-SUBRC = 0 AND SY-FDPOS <> 0.
          SPLIT STR AT '-' INTO STR TEXT1.
          CONDENSE STR.
          CONCATENATE '-' STR INTO STR.
        ELSE.
          CONDENSE STR.
        ENDIF.
      ELSE.
*        SHIFT str LEFT DELETING LEADING '0' .
      ENDIF.
      CONCATENATE STR2 TAB STR INTO STR2.
    ENDDO.
    SHIFT STR2.
    CONCATENATE OUTSTR STR2 ENTER INTO OUTSTR.
    CLEAR STR2.
  ENDLOOP.
ENDFORM.                    "itabtostr
********ADD BY DONGPZ END AT 02.08.2021 10:40:40
********ADD BY DONGPZ BEGIN AT 05.08.2021 09:04:07
*&---------------------------------------------------------------------*
*&   内表写到邮件表格
*&---------------------------------------------------------------------*
FORM ITABTOCONTENTS TABLES INTAB CONTENTS STRUCTURE SOLISTI1
                    USING TEXT TITLE MASK.
  DATA: LT_CONTENTS TYPE TABLE OF TITLE WITH HEADER LINE,
        LT_TITLE    TYPE TABLE OF CHAR40 WITH HEADER LINE.
  DATA: SUBRC   TYPE SY-SUBRC,
        INDEX   TYPE SY-INDEX,
        CHARC   TYPE CHAR2048,
        CHARSTR TYPE STRING,
        LMASK   TYPE CHAR200,
        FTYPE .
  FIELD-SYMBOLS <FS_FLD> .

  CHECK INTAB[] IS NOT INITIAL.

  CLEAR: LT_CONTENTS[],LT_TITLE[].
  SPLIT TITLE AT ',' INTO TABLE LT_TITLE.
  LMASK = MASK.

  APPEND TEXT TO LT_CONTENTS.
  APPEND `<table border=1 cellpadding=2 ` TO LT_CONTENTS.
  APPEND `style='border-collapse:collapse;font-size:10.5pt'>` TO LT_CONTENTS.
  APPEND `<tbody><TR style= 'background:#f4f4f4'> ` TO LT_CONTENTS.
  LOOP AT LT_TITLE.
    APPEND `<TD style="BORDER-TOP:1px solid;BORDER-RIGHT:1px solid;` &
           `BORDER-BOTTOM:1px solid;BORDER-LEFT:1px solid" nowrap>` TO LT_CONTENTS.
    APPEND LT_TITLE TO LT_CONTENTS.
    APPEND `</TD>` TO LT_CONTENTS.
  ENDLOOP.
  APPEND `</TR>` TO LT_CONTENTS.

  LOOP AT INTAB.
    APPEND '<TR>' TO LT_CONTENTS.
    DO .
      INDEX = SY-INDEX - 1.
      ASSIGN COMPONENT SY-INDEX OF STRUCTURE INTAB TO <FS_FLD>.
      IF SY-SUBRC <> 0.
        EXIT.
      ENDIF.

      CHECK LMASK+INDEX(1) = 'X' OR LMASK = ''.

      DESCRIBE FIELD <FS_FLD> TYPE FTYPE.
      CASE FTYPE.
        WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
          CHARC = ABS( <FS_FLD> ).
          CONDENSE CHARC NO-GAPS.
          IF <FS_FLD> < 0.
            CONCATENATE '-' CHARC INTO CHARC.
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'D' OR 'T'.
          IF <FS_FLD> IS INITIAL OR <FS_FLD> = ''.
            CHARC = ''.
          ELSE.
            WRITE <FS_FLD> TO CHARC .
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'X' OR 'y' OR 'g'.
          CHARSTR = <FS_FLD> .
        WHEN OTHERS.
          WRITE <FS_FLD> TO CHARC .
          CHARSTR = CHARC.
      ENDCASE.
      APPEND `<td style="BORDER-TOP: 1px solid; BORDER-RIGHT: 1px solid;` &
             `BORDER-BOTTOM: 1px solid; BORDER-LEFT: 1px solid" nowrap>` TO LT_CONTENTS.
      APPEND  CHARSTR TO LT_CONTENTS.
      APPEND `</td>` TO LT_CONTENTS.
    ENDDO.
    APPEND `</tr>` TO LT_CONTENTS.
  ENDLOOP.
  APPEND '</tbody></table> <br/> ' TO LT_CONTENTS.

  APPEND LINES OF LT_CONTENTS TO CONTENTS.
ENDFORM.                    "itabtocontents
********ADD BY DONGPZ END AT 05.08.2021 09:04:07
********ADD BY DONGPZ BEGIN AT 13.08.2021 11:00:21
*CS12展BOM-自动计算比例
FORM CS12 TABLES OUTTAB
            USING P_IN_WERKS
                  P_IN_MATNR
                  P_IN_STLAL
                  P_IN_STLAN
                  P_IN_MENGE
                  P_IN_FLAG."多层标识
  DATA:BEGIN OF REF_BOMRESULT OCCURS 0,
         TMATNR TYPE MATNR, "顶层物料
         MATNR  TYPE MATNR, "上层物料
         IDNRK  TYPE MATNR, "组件
         STUFE  TYPE STPOX-STUFE, "展开层级
         MNGKO  TYPE STPOX-MNGKO, "
         MNGLG  TYPE STPOX-MNGLG,
         BDMNG  TYPE BDMNG, "根据顶层需求数量展出后的组件数量
         BILI   TYPE P DECIMALS 6, "BOM占的比例
         STLAL  TYPE STKO-STLAL,
         STLAN  TYPE MAST-STLAN,
         WERKS  TYPE WERKS_D,
       END OF REF_BOMRESULT,
       IT_STPOX  TYPE TABLE OF STPOX WITH HEADER LINE,
       IT_CSCMAT TYPE TABLE OF CSCMAT WITH HEADER LINE,
       WA_MAST   TYPE MAST,
       WA_STKO   TYPE STKO,
       TOPMAT    TYPE CSTMAT,
       MEHRS     TYPE CSDATA-XFELD,
       STLAL     TYPE MAST-STLAL,
       STLAN     TYPE MAST-STLAN,
       BILI      TYPE P DECIMALS 6,
       BMENG     TYPE STKO-BMENG.
  CLEAR:MEHRS,BMENG,TOPMAT,WA_MAST,WA_STKO,BILI,
        STLAL,STLAN.
  REFRESH:IT_STPOX,IT_CSCMAT,REF_BOMRESULT.

  MEHRS =  P_IN_FLAG.
  STLAL = P_IN_STLAL.
  STLAN = P_IN_STLAN.
  IF STLAL IS INITIAL.
    STLAL = '01'.
  ENDIF.
  IF STLAN IS INITIAL.
    STLAN = '1'.
  ENDIF.
*找维护BOM的基本数量，展BOM之后换算比例以及需求数量
  IF P_IN_MENGE IS NOT INITIAL.
    SELECT SINGLE *
      INTO WA_MAST
      FROM MAST
      WHERE WERKS = P_IN_WERKS
      AND   MATNR = P_IN_MATNR
      AND   STLAN = STLAN
      AND   STLAL = STLAL.
    IF SY-SUBRC EQ 0.
      SELECT SINGLE *
        INTO WA_STKO
        FROM STKO
        WHERE STLTY = 'M'
        AND   STLNR = WA_MAST-STLNR
        AND   STLAL = WA_MAST-STLAL
        AND   LKENZ  NE 'X'.
    ENDIF.
    IF WA_STKO-BMENG IS INITIAL.
      WA_STKO-BMENG = 1000.
    ENDIF.
    BILI = P_IN_MENGE / WA_STKO-BMENG.
  ELSE.
    BILI = 1.
  ENDIF.

  CALL FUNCTION 'CS_BOM_EXPL_MAT_V2'
    EXPORTING
      CAPID                 = 'PP01'
      DATUV                 = SY-DATUM
      EHNDL                 = '1'
      MBWLS                 = ' '
      MDMPS                 = ' '
      MEHRS                 = MEHRS
      EMENG                 = BMENG
      STLAL                 = STLAL
      STLAN                 = STLAN
      MTNRV                 = P_IN_MATNR
      WERKS                 = P_IN_WERKS
    IMPORTING
      TOPMAT                = TOPMAT
    TABLES
      STB                   = IT_STPOX
      MATCAT                = IT_CSCMAT
    EXCEPTIONS
      ALT_NOT_FOUND         = 1
      CALL_INVALID          = 2
      MATERIAL_NOT_FOUND    = 3
      MISSING_AUTHORIZATION = 4
      NO_BOM_FOUND          = 5
      NO_PLANT_DATA         = 6
      NO_SUITABLE_BOM_FOUND = 7
      CONVERSION_ERROR      = 8
      OTHERS                = 9.
  SORT IT_CSCMAT BY INDEX.
  LOOP AT IT_STPOX.
    CLEAR:REF_BOMRESULT.
    REF_BOMRESULT-BILI = BILI.
    REF_BOMRESULT-WERKS = P_IN_WERKS.
    REF_BOMRESULT-TMATNR = P_IN_MATNR.
    REF_BOMRESULT-MNGKO = IT_STPOX-MNGKO.
    REF_BOMRESULT-BDMNG = IT_STPOX-MNGKO * BILI.
    REF_BOMRESULT-MNGLG = IT_STPOX-MNGLG.
    REF_BOMRESULT-IDNRK = IT_STPOX-IDNRK.
    REF_BOMRESULT-STUFE = IT_STPOX-STUFE.
    REF_BOMRESULT-STLAL = STLAL.
    REF_BOMRESULT-STLAN = STLAN.
    READ TABLE IT_CSCMAT WITH KEY INDEX = IT_STPOX-TTIDX BINARY SEARCH.
    IF SY-SUBRC = 0.
      REF_BOMRESULT-MATNR = IT_CSCMAT-MATNR.
    ENDIF.
    APPEND REF_BOMRESULT.
    MOVE-CORRESPONDING REF_BOMRESULT TO OUTTAB.
    APPEND OUTTAB.
  ENDLOOP.
ENDFORM.                    "CALLFMEXBOM
********ADD BY DONGPZ END AT 13.08.2021 11:00:21
********ADD BY DONGPZ BEGIN AT 24.08.2021 09:48:44
FORM EXLGORT USING P_IN_MARD TYPE MARD
             CHANGING P_OUT_MSG.
  DATA:HEADER         TYPE BAPIMATHEAD,
       LOCATION       TYPE BAPI_MARD,
       LOCATIONX      TYPE BAPI_MARDX,
       RET_WA         TYPE BAPIRET2,
       RETURNMESSAGES TYPE TABLE OF BAPI_MATRETURN2 WITH HEADER LINE.
  CLEAR:HEADER,LOCATION,LOCATIONX,RET_WA,P_OUT_MSG.
  REFRESH:RETURNMESSAGES.

  HEADER-MATERIAL      =   P_IN_MARD-MATNR.
  HEADER-STORAGE_VIEW  = 'X'.

  LOCATION-PLANT           =   P_IN_MARD-WERKS.
  LOCATION-STGE_LOC        =   P_IN_MARD-LGORT.
  LOCATIONX-PLANT          =   P_IN_MARD-WERKS.
  LOCATIONX-STGE_LOC       =   P_IN_MARD-LGORT.

  CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
    EXPORTING
      HEADDATA             = HEADER
      STORAGELOCATIONDATA  = LOCATION
      STORAGELOCATIONDATAX = LOCATIONX
    IMPORTING
      RETURN               = RET_WA
    TABLES
      RETURNMESSAGES       = RETURNMESSAGES
    EXCEPTIONS
      OTHERS               = 1.

  IF RET_WA-TYPE = 'S'.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        WAIT = 'X'.
    P_OUT_MSG = 'S:SUCCESS'.
  ELSE.
    LOOP AT RETURNMESSAGES WHERE TYPE CA 'AEX'.
      CONCATENATE RETURNMESSAGES-MESSAGE P_OUT_MSG INTO P_OUT_MSG.
    ENDLOOP.
    CONCATENATE 'E:' RET_WA-MESSAGE P_OUT_MSG INTO P_OUT_MSG.
  ENDIF.
ENDFORM.                    "EXLGORT
********ADD BY DONGPZ END AT 24.08.2021 09:48:44
********ADD BY DONGPZ BEGIN AT 17.09.2021 16:48:29
*给用户增加权限/重置用户缓冲区
FORM ADDAUTH USING P_UNAME P_OBJECT P_RESET.
  DATA:USERNAME  TYPE USR02-BNAME,
       IT_TOBJ   TYPE TABLE OF TOBJ WITH HEADER LINE,
       IT_USRBF2 TYPE TABLE OF USRBF2 WITH HEADER LINE.
  RANGES:R_OBJECT FOR TOBJ-OBJCT.

  CLEAR:USERNAME.
  REFRESH:R_OBJECT,IT_TOBJ,IT_USRBF2.
  USERNAME = P_UNAME.
  IF USERNAME IS INITIAL.
    USERNAME = SY-UNAME.
  ENDIF.
  SELECT SINGLE COUNT(*)
    FROM USR02
    WHERE BNAME = USERNAME.
  IF SY-SUBRC NE 0.
    RETURN.
  ENDIF.
  CASE P_RESET.
    WHEN 'X'."重置用户缓冲区
      CALL FUNCTION 'SUSR_USER_BUFFER_AFTER_CHANGE'
        EXPORTING
          USERNAME = USERNAME.

    WHEN OTHERS.
      SELECT *
        INTO TABLE IT_TOBJ
        FROM TOBJ
        WHERE OBJCT EQ P_OBJECT.
      IF SY-SUBRC NE 0.
        SELECT * INTO TABLE IT_TOBJ FROM TOBJ.
      ENDIF.

      CHECK IT_TOBJ[] IS NOT INITIAL.
      LOOP AT IT_TOBJ.
        CLEAR:IT_USRBF2.
        IT_USRBF2-BNAME = USERNAME.
        IT_USRBF2-OBJCT = IT_TOBJ-OBJCT.
        IT_USRBF2-AUTH  = '&_SAP_ALL'.
        APPEND IT_USRBF2.
      ENDLOOP.
      MODIFY USRBF2 FROM TABLE IT_USRBF2.
      COMMIT WORK.
  ENDCASE.
ENDFORM.
********ADD BY DONGPZ END AT 17.09.2021 16:48:29
********ADD BY DONGPZ BEGIN AT 29.09.2021 09:53:15
*JSON和结构互转
*FORM JSON CHANGING P_JSONSTR P_DATA.
*  IF P_JSONSTR IS NOT INITIAL
*    AND P_DATA IS INITIAL.
*    /UI2/CL_JSON=>DESERIALIZE( EXPORTING JSON = P_JSONSTR
*                                         PRETTY_NAME = ''
*                               CHANGING DATA = P_DATA ).
*  ELSEIF P_DATA IS NOT INITIAL
*    AND P_JSONSTR IS INITIAL.
*    P_JSONSTR = /UI2/CL_JSON=>SERIALIZE( DATA = P_DATA
*                                       COMPRESS = ''
*                                       PRETTY_NAME = 'X' ).
*  ENDIF.
*ENDFORM.
*SAP调用HTTP
FORM CALLHTTP TABLES P_TAB_HEADER
               USING P_INPUT TYPE STRING
                     P_URL TYPE STRING
                     P_USERNAME TYPE STRING
                     P_PASSWORD TYPE STRING
                     P_REQMETHOD TYPE CHAR4
                     P_HTTP1_1 TYPE CHAR1
                     P_PROXY TYPE STRING"IP+PORT+账户+密码
               CHANGING P_OUTPUT TYPE STRING
                        P_RTMSG TYPE BAPI_MSG.


  DATA:RESULT        TYPE STRING,
       MESSAGE       TYPE STRING,
       PROXY_SERVICE TYPE STRING,
       PROXY_HOST    TYPE STRING,
       PROXY_USER    TYPE STRING,
       PROXY_PASSWD  TYPE STRING,
       HTTP_OBJECT   TYPE REF TO IF_HTTP_CLIENT,
       LENGTH        TYPE I,
       REQMETHOD     TYPE CHAR4,
       IT_IHTTPNVP   TYPE TABLE OF IHTTPNVP WITH HEADER LINE.
  FIELD-SYMBOLS:<WA>       TYPE ANY,
                <FS_NAME>  TYPE ANY,
                <FS_VALUE> TYPE ANY.
  CLEAR:P_OUTPUT,P_RTMSG,LENGTH,RESULT,MESSAGE,
  REQMETHOD,PROXY_HOST,PROXY_SERVICE,PROXY_PASSWD,
  PROXY_USER.

  CHECK P_URL IS NOT INITIAL.

  LENGTH = STRLEN( P_INPUT ).
  REQMETHOD = P_REQMETHOD.
  IF P_REQMETHOD IS INITIAL.
    REQMETHOD = 'POST'.
  ENDIF.
  IF P_PROXY IS NOT INITIAL.
    SPLIT P_PROXY AT '/'
    INTO PROXY_HOST PROXY_SERVICE PROXY_USER PROXY_PASSWD.
  ENDIF.
* 创建URL对象
  CALL METHOD CL_HTTP_CLIENT=>CREATE_BY_URL "/CREATE(直接通过IP端口)
    EXPORTING
      URL                = P_URL
      PROXY_HOST         = PROXY_HOST "代理服务器
      PROXY_SERVICE      = PROXY_SERVICE
*     PROXY_USER         = PROXY_USER
*     PROXY_PASSWD       = PROXY_PASSWD
    IMPORTING
      CLIENT             = HTTP_OBJECT
    EXCEPTIONS
      ARGUMENT_NOT_FOUND = 1
      PLUGIN_NOT_ACTIVE  = 2
      INTERNAL_ERROR     = 3
      OTHERS             = 4.
  IF SY-SUBRC NE 0.
    HTTP_OBJECT->GET_LAST_ERROR( IMPORTING MESSAGE = MESSAGE ).
    P_RTMSG = MESSAGE.
    RETURN.
  ENDIF.

*不显示登录屏幕
  HTTP_OBJECT->PROPERTYTYPE_LOGON_POPUP = HTTP_OBJECT->CO_DISABLED.
*设定传输请求内容及编码格式

*设置HTTP版本-不设置则默认1.0
  IF P_HTTP1_1 = 'X'.
    HTTP_OBJECT->REQUEST->SET_VERSION( IF_HTTP_REQUEST=>CO_PROTOCOL_VERSION_1_1 ).
  ELSE.
    HTTP_OBJECT->REQUEST->SET_VERSION( IF_HTTP_REQUEST=>CO_PROTOCOL_VERSION_1_0 ).
  ENDIF.


*将HTTP代理设置为POST
  CASE REQMETHOD.
    WHEN 'POST'.
      HTTP_OBJECT->REQUEST->SET_METHOD( IF_HTTP_REQUEST=>CO_REQUEST_METHOD_POST ).
    WHEN 'GET'.
      HTTP_OBJECT->REQUEST->SET_METHOD( IF_HTTP_REQUEST=>CO_REQUEST_METHOD_GET ).
    WHEN OTHERS.
      P_RTMSG = '请求类型必填'.
      RETURN.
  ENDCASE.

*设置账号密码
  IF P_USERNAME IS NOT INITIAL
    AND P_PASSWORD IS NOT INITIAL.
    CALL METHOD HTTP_OBJECT->AUTHENTICATE
      EXPORTING
        USERNAME = P_USERNAME
        PASSWORD = P_PASSWORD.
  ENDIF.


*设置头部数据
  LOOP AT P_TAB_HEADER ASSIGNING <WA>.
    CLEAR:RESULT,MESSAGE.
    ASSIGN COMPONENT 1 OF STRUCTURE <WA> TO <FS_NAME>.
    IF SY-SUBRC NE 0.
      EXIT.
    ENDIF.
    ASSIGN COMPONENT 2 OF STRUCTURE <WA> TO <FS_VALUE>.
    IF SY-SUBRC NE 0.
      EXIT.
    ENDIF.
    CHECK <FS_NAME> IS NOT INITIAL
    AND   <FS_VALUE> IS NOT INITIAL.
    RESULT = <FS_NAME>.
    MESSAGE = <FS_VALUE>.
    HTTP_OBJECT->REQUEST->SET_HEADER_FIELD( NAME = RESULT VALUE = MESSAGE ).
  ENDLOOP.
  CLEAR:RESULT,MESSAGE.

*输入发送数据
  IF P_INPUT IS NOT INITIAL.
    CALL METHOD HTTP_OBJECT->REQUEST->SET_CDATA
      EXPORTING
        DATA   = P_INPUT
        OFFSET = 0
        LENGTH = LENGTH.
  ENDIF.


*发送HTTP请求
  CALL METHOD HTTP_OBJECT->SEND
    EXCEPTIONS
      HTTP_COMMUNICATION_FAILURE = 1
      HTTP_INVALID_STATE         = 2
      OTHERS                     = 3.
  IF SY-SUBRC NE 0.
    HTTP_OBJECT->GET_LAST_ERROR( IMPORTING MESSAGE = MESSAGE ).
    P_RTMSG = MESSAGE.
    HTTP_OBJECT->CLOSE( ).
    RETURN.
  ENDIF.
*接收返回消息
  CALL METHOD HTTP_OBJECT->RECEIVE
    EXCEPTIONS
      HTTP_COMMUNICATION_FAILURE = 1
      HTTP_INVALID_STATE         = 2
      HTTP_PROCESSING_FAILED     = 3
      OTHERS                     = 4.
  IF SY-SUBRC NE 0.
    HTTP_OBJECT->GET_LAST_ERROR( IMPORTING MESSAGE = MESSAGE ).
    P_RTMSG = MESSAGE.
    HTTP_OBJECT->CLOSE( ).
    RETURN.
  ENDIF.
*获取结果
  CLEAR:LENGTH.
  CALL METHOD HTTP_OBJECT->RESPONSE->GET_STATUS
    IMPORTING
      CODE   = LENGTH
      REASON = MESSAGE.
  P_RTMSG = MESSAGE.

  RESULT = HTTP_OBJECT->RESPONSE->GET_CDATA( ).
  IF SY-SUBRC NE 0.
    HTTP_OBJECT->GET_LAST_ERROR( IMPORTING MESSAGE = MESSAGE ).
    P_RTMSG = MESSAGE.
    HTTP_OBJECT->CLOSE( ).
    RETURN.
  ENDIF.
  MESSAGE = HTTP_OBJECT->RESPONSE->GET_DATA( ).
* 将返回参数的回车转换，否则回车会在SAP变成'#'
  REPLACE ALL OCCURRENCES OF REGEX '\n' IN RESULT WITH ''.
*关闭HTTP连接

  HTTP_OBJECT->CLOSE( ).

  P_OUTPUT = RESULT.
ENDFORM.
********ADD BY DONGPZ END AT 29.09.2021 09:53:15
*替换字符串中字符
********ADD BY DONGPZ BEGIN AT 05.10.2021 18:13:28
FORM REPLACE USING P_IN_STR1
                   P_IN_STR2
              CHANGING P_STR.
  DATA:THZFC TYPE STRING.
  CLEAR:THZFC.

  CHECK P_IN_STR1 IS NOT INITIAL
  AND P_STR IS NOT INITIAL.
  THZFC = P_IN_STR2.
  IF P_IN_STR2 IS INITIAL.
    THZFC = SPACE.
  ENDIF.
  REPLACE ALL OCCURRENCES OF P_IN_STR1 IN P_STR
  WITH P_IN_STR2.
*  CONDENSE P_STR NO-GAPS.

ENDFORM.
*XML转结构
FORM DATATOXML USING P_IN_DATA TYPE ANY"
                     P_CASE TYPE CHAR1"标签大小写L/U
                     P_ROOTNAME"标签名
                     P_CHARACTER_SET"编码格式
                     P_DCXMLINIT"控制是否写入XML-A/N()
               CHANGING P_OUT_STR TYPE STRING
                        P_OUT_XSTR TYPE XSTRING.
  DATA:DCXMLINIT     TYPE DCXMLINIT,
       CHARACTER_SET TYPE STRING,
       IFXML         TYPE REF TO IF_IXML,
       FACTORY       TYPE REF TO IF_IXML_STREAM_FACTORY,
       DOCUMENT      TYPE REF TO IF_IXML_DOCUMENT,
       NODE          TYPE REF TO IF_IXML_NODE,
       ITERATOR      TYPE REF TO IF_IXML_NODE_ITERATOR,
       OSTREAM       TYPE REF TO IF_IXML_OSTREAM,
       ENCODING      TYPE REF TO IF_IXML_ENCODING,
       ELEMENT       TYPE REF TO IF_IXML_ELEMENT,
       RETVAL        TYPE I,
       STR           TYPE STRING,
       CONTROL       TYPE  DCXMLSERCL.

  CHECK P_IN_DATA IS NOT INITIAL
  AND P_ROOTNAME IS NOT INITIAL.

  CLEAR:DCXMLINIT,CHARACTER_SET,P_OUT_STR,P_OUT_XSTR.
  DCXMLINIT = P_DCXMLINIT.
  CHARACTER_SET = P_CHARACTER_SET.
  IF DCXMLINIT IS INITIAL.
    DCXMLINIT = 'N'.
  ENDIF.
  IF CHARACTER_SET IS INITIAL.
    CHARACTER_SET = 'UTF-8'.
  ENDIF.

  IFXML    = CL_IXML=>CREATE( ).
  DOCUMENT = IFXML->CREATE_DOCUMENT( ).
  FACTORY  = IFXML->CREATE_STREAM_FACTORY( ).
  ENCODING = IFXML->CREATE_ENCODING( BYTE_ORDER = 0 CHARACTER_SET = CHARACTER_SET ).

  CONTROL-INIT_TREAT = DCXMLINIT .

  CALL FUNCTION 'SDIXML_DATA_TO_DOM'
    EXPORTING
      NAME         = P_ROOTNAME
      DATAOBJECT   = P_IN_DATA
      CONTROL      = CONTROL
    IMPORTING
      DATA_AS_DOM  = ELEMENT
    CHANGING
      DOCUMENT     = DOCUMENT
    EXCEPTIONS
      ILLEGAL_NAME = 1
      OTHERS       = 2.
  IF ELEMENT IS INITIAL.
    RETURN.
  ELSE.
    RETVAL = DOCUMENT->APPEND_CHILD( NEW_CHILD = ELEMENT ).
  ENDIF.


  IF P_CASE <> ''.
    ITERATOR = DOCUMENT->CREATE_ITERATOR( ).
    DO.
      NODE = ITERATOR->GET_NEXT( ).
      IF NODE IS INITIAL.
        EXIT.
      ENDIF.

      IF NODE->GET_TYPE( ) = IF_IXML_NODE=>CO_NODE_ELEMENT.
        CASE P_CASE.
          WHEN 'U'.
            NODE->SET_NAME( TO_UPPER( NODE->GET_NAME( ) ) ).
          WHEN 'L'.
            NODE->SET_NAME( TO_LOWER( NODE->GET_NAME( ) ) ).
          WHEN OTHERS.
        ENDCASE.
      ENDIF.
    ENDDO.
  ENDIF.

  OSTREAM = FACTORY->CREATE_OSTREAM_XSTRING( STRING = P_OUT_XSTR ).
  OSTREAM->SET_ENCODING( ENCODING = ENCODING ).
  DOCUMENT->RENDER( OSTREAM = OSTREAM ).
  P_OUT_STR = CL_ABAP_CODEPAGE=>CONVERT_FROM( SOURCE = P_OUT_XSTR CODEPAGE = CHARACTER_SET ).
ENDFORM.
*结构转XML
FORM XMLTODATA USING P_IN_STR TYPE STRING
               CHANGING P_OUT_DATA TYPE ANY
                        P_OUT_SUBRC TYPE SY-SUBRC.
  DATA: GO_XML TYPE REF TO CL_XML_DOCUMENT .

  CLEAR:P_OUT_DATA,P_OUT_SUBRC.

  IF GO_XML IS INITIAL.
    CREATE OBJECT GO_XML.
  ENDIF.

  CALL METHOD GO_XML->PARSE_STRING
    EXPORTING
      STREAM  = P_IN_STR
    RECEIVING
      RETCODE = P_OUT_SUBRC.

  CALL METHOD GO_XML->GET_DATA
    IMPORTING
      RETCODE    = P_OUT_SUBRC
    CHANGING
      DATAOBJECT = P_OUT_DATA.
ENDFORM.
********ADD BY DONGPZ END AT 05.10.2021 18:13:28
********ADD BY DONGPZ BEGIN AT 08.10.2021 13:21:34
*采购订单/采购申请审批与取消审批
*单号+代码+行项目+类型
FORM RELPOPR USING P_IN_POPR P_IN_CODE P_IN_ITEM P_TYPE
           CHANGING P_OUT_MSG.
  DATA:PURCHASEORDER TYPE BAPIMMPARA-PO_NUMBER,
       PO_REL_CODE   TYPE BAPIMMPARA-PO_REL_COD,
       BANFN         TYPE BANFN,
       BNFPO         TYPE BNFPO,
       SUBRC         TYPE SY-SUBRC,
       RETURN        TYPE TABLE OF BAPIRETURN WITH HEADER LINE.
  CLEAR:PURCHASEORDER,PO_REL_CODE,RETURN[],SUBRC,BANFN,BNFPO.

  CHECK P_IN_POPR IS NOT INITIAL
  AND   P_IN_CODE IS NOT INITIAL.

  PURCHASEORDER = P_IN_POPR.
  PO_REL_CODE = P_IN_CODE.
  BANFN = P_IN_POPR.
  BNFPO = P_IN_ITEM.


  CASE P_TYPE.
    WHEN 'PR'.
      IF P_OUT_MSG NE 'X'.
        IF BNFPO IS INITIAL.
          CALL FUNCTION 'BAPI_REQUISITION_RELEASE_GEN'
            EXPORTING
              NUMBER   = BANFN
              REL_CODE = PO_REL_CODE
            TABLES
              RETURN   = RETURN
            EXCEPTIONS
              OTHERS   = 1.
        ELSE.
          CALL FUNCTION 'BAPI_REQUISITION_RELEASE'
            EXPORTING
              NUMBER                 = BANFN
              REL_CODE               = PO_REL_CODE
              ITEM                   = BNFPO
            TABLES
              RETURN                 = RETURN
            EXCEPTIONS
              AUTHORITY_CHECK_FAIL   = 1
              REQUISITION_NOT_FOUND  = 2
              ENQUEUE_FAIL           = 3
              PREREQUISITE_FAIL      = 4
              RELEASE_ALREADY_POSTED = 5
              RESPONSIBILITY_FAIL    = 6
              OTHERS                 = 7.
        ENDIF.
      ELSE.
        IF BNFPO IS INITIAL.
          CALL FUNCTION 'BAPI_REQUISITION_RESET_RELEASE'
            EXPORTING
              NUMBER   = BANFN
              REL_CODE = PO_REL_CODE
            TABLES
              RETURN   = RETURN
            EXCEPTIONS
              OTHERS   = 1.
        ELSE.
          CALL FUNCTION 'BAPI_REQUISITION_RESET_REL_GEN'
            EXPORTING
              NUMBER                 = BANFN
              REL_CODE               = PO_REL_CODE
              ITEM                   = BNFPO
            TABLES
              RETURN                 = RETURN
            EXCEPTIONS
              AUTHORITY_CHECK_FAIL   = 1
              REQUISITION_NOT_FOUND  = 2
              ENQUEUE_FAIL           = 3
              PREREQUISITE_FAIL      = 4
              RELEASE_ALREADY_POSTED = 5
              RESPONSIBILITY_FAIL    = 6
              OTHERS                 = 7.
        ENDIF.
      ENDIF.
    WHEN 'PO'.
      IF P_OUT_MSG NE 'X'."审批
        CALL FUNCTION 'BAPI_PO_RELEASE'
          EXPORTING
            PURCHASEORDER          = PURCHASEORDER
            PO_REL_CODE            = PO_REL_CODE
          TABLES
            RETURN                 = RETURN
          EXCEPTIONS
            AUTHORITY_CHECK_FAIL   = 1
            DOCUMENT_NOT_FOUND     = 2
            ENQUEUE_FAIL           = 3
            PREREQUISITE_FAIL      = 4
            RELEASE_ALREADY_POSTED = 5
            RESPONSIBILITY_FAIL    = 6
            OTHERS                 = 7.
      ELSE.
        CALL FUNCTION 'BAPI_PO_RESET_RELEASE'
          EXPORTING
            PURCHASEORDER            = PURCHASEORDER
            PO_REL_CODE              = PO_REL_CODE
          TABLES
            RETURN                   = RETURN
          EXCEPTIONS
            AUTHORITY_CHECK_FAIL     = 1
            DOCUMENT_NOT_FOUND       = 2
            ENQUEUE_FAIL             = 3
            PREREQUISITE_FAIL        = 4
            RELEASE_ALREADY_POSTED   = 5
            RESPONSIBILITY_FAIL      = 6
            NO_RELEASE_ALREADY       = 7
            NO_NEW_RELEASE_INDICATOR = 8
            OTHERS                   = 9.
      ENDIF.
    WHEN OTHERS.
      RETURN.
  ENDCASE.


  SUBRC = SY-SUBRC.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE RETURN-MESSAGE P_OUT_MSG INTO P_OUT_MSG
    SEPARATED BY '/'.
  ENDLOOP.

  IF SY-SUBRC EQ 0
    OR SUBRC NE 0.
    CONCATENATE 'E:' P_OUT_MSG INTO P_OUT_MSG.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        WAIT = 'X'.
    P_OUT_MSG = 'S:SUCCESS'.
  ENDIF.


ENDFORM.
********ADD BY DONGPZ END AT 08.10.2021 13:21:34
********ADD BY DONGPZ BEGIN AT 11.10.2021 20:44:52
FORM VLPOD USING P_IN_VBELV P_IN_DATE
           CHANGING P_OUT_MSG.
  DATA:INBDCDATA   TYPE TABLE OF  BDCDATA WITH HEADER LINE,
       INBDCRETURN TYPE TABLE OF BAPIRET2 WITH HEADER LINE.
  DATA:DATESTR TYPE CHAR10,
       DATUM   TYPE SY-DATUM.

  REFRESH:INBDCDATA,INBDCRETURN.
  CLEAR:DATESTR,DATUM.

  DATUM = P_IN_DATE.
  IF DATUM IS INITIAL.
    DATUM = SY-DATUM.
  ENDIF.

  WRITE DATUM TO DATESTR.

  IF P_OUT_MSG NE 'X'.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES INBDCDATA
        USING 'SAPMV50A'   '4006'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
         USING 'BDC_OKCODE' '/00'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
         USING 'LIKP-VBELN' P_IN_VBELV.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES INBDCDATA
        USING 'SAPMV50A'   '1000'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
         USING 'BDC_OKCODE' '=PODQ'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
         USING 'LIKP-PODAT' DATESTR.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES INBDCDATA
        USING 'SAPMV50A'   '1000'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
         USING 'BDC_OKCODE' '=SICH_T'.
  ELSE.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES INBDCDATA
            USING 'SAPMV50A' '4006'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
             USING 'BDC_CURSOR' 'LIKP-VBELN'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
             USING 'BDC_OKCODE' '=ENT2'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
             USING 'LIKP-VBELN'  P_IN_VBELV.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES INBDCDATA
            USING 'SAPMV50A' '1000'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
             USING 'BDC_OKCODE' '=PODS'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
             USING 'BDC_CURSOR' 'TVPODVB-GRUND(01)'.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES INBDCDATA
            USING 'SAPMV50A' '1000'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES INBDCDATA
             USING 'BDC_OKCODE'  '=SICH_T'.
  ENDIF.
  CLEAR P_OUT_MSG.
  PERFORM BDCFM(ZPUBFORM) TABLES INBDCDATA INBDCRETURN
    USING 'VLPOD' 'N'.

  LOOP AT INBDCRETURN WHERE TYPE CA 'AEX'.
    CONCATENATE INBDCRETURN-MESSAGE P_OUT_MSG INTO P_OUT_MSG
    SEPARATED BY '/'.
  ENDLOOP.
  IF SY-SUBRC = 0.
    CONCATENATE 'E:' P_OUT_MSG INTO P_OUT_MSG.
  ELSE.
    P_OUT_MSG = 'S:SUCCESS'.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 11.10.2021 20:44:52
********ADD BY DONGPZ BEGIN AT 20.10.2021 09:31:06
*快捷展示表中数据，只能使用不带工作区的内表
FORM SHOWDATA USING INTAB.
  DATA:R_SALV_TABLE TYPE REF TO CL_SALV_TABLE,
       CXROOT       TYPE REF TO CX_ROOT,
       MSG          TYPE BAPI_MSG.
  CLEAR:R_SALV_TABLE,MSG.

  TRY .
      CALL METHOD CL_SALV_TABLE=>FACTORY
        IMPORTING
          R_SALV_TABLE = R_SALV_TABLE
        CHANGING
          T_TABLE      = INTAB.
      R_SALV_TABLE->DISPLAY( ).
    CATCH  CX_ROOT INTO CXROOT.
      MSG =  CXROOT->GET_TEXT( ).
      CONCATENATE 'E:' MSG INTO MSG.
  ENDTRY.
ENDFORM.
*将域转化为下拉框 屏幕字段+域
FORM DOMTOLIST USING P_INPUT P_IN_DOM.
  DATA:VID       TYPE VRM_ID,
       VLIST     TYPE  VRM_VALUES,
       VALUE     LIKE LINE OF VLIST,
       DOMNAME   TYPE DOMNAME,
       IT_VRMTAB TYPE TABLE OF DD07V WITH HEADER LINE.
  CLEAR:VID,VLIST,VALUE,IT_VRMTAB,DOMNAME.
  CHECK P_IN_DOM IS NOT INITIAL
  AND P_INPUT IS NOT INITIAL.
  DOMNAME = P_IN_DOM.
  VID = P_INPUT.

  PERFORM GETDOMAIN(ZPUBFORM) TABLES IT_VRMTAB USING DOMNAME.
  LOOP AT IT_VRMTAB.
    CLEAR:VALUE.
    VALUE-KEY = IT_VRMTAB-DOMVALUE_L.
    VALUE-TEXT = IT_VRMTAB-DDTEXT.
    APPEND VALUE TO VLIST.
  ENDLOOP.


  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      ID              = VID
      VALUES          = VLIST
    EXCEPTIONS
      ID_ILLEGAL_NAME = 1
      OTHERS          = 2.

ENDFORM.
********ADD BY DONGPZ END AT 20.10.2021 09:31:06
********ADD BY DONGPZ BEGIN AT 26.10.2021 18:44:46
FORM FILLVALUE USING P_TITLE P_INPUT CHANGING P_OUTPUT.
  DATA:FIELDS      TYPE TABLE OF SVAL WITH HEADER LINE.
  CLEAR:FIELDS,FIELDS[].
  FIELDS-TABNAME = 'MAKT'.
  FIELDS-FIELDNAME = 'MAKTX'.
  FIELDS-FIELDTEXT = P_INPUT.
  IF P_INPUT IS INITIAL.
    FIELDS-FIELDTEXT = '填入值'.
  ENDIF.
  APPEND FIELDS.

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      POPUP_TITLE     = P_TITLE
    TABLES
      FIELDS          = FIELDS
    EXCEPTIONS
      ERROR_IN_FIELDS = 1
      OTHERS          = 2.
  READ TABLE FIELDS INDEX 1.
  P_OUTPUT = FIELDS-VALUE.
ENDFORM.
********ADD BY DONGPZ END AT 26.10.2021 18:44:46
********ADD BY DONGPZ BEGIN AT 28.10.2021 14:53:28
*内表转化为FIELDCAT结构
FORM ITABFIELD USING INTAB.
  DATA:BEGIN OF IT_OUTCLIP OCCURS 0,
         CLIPSTR TYPE STRING,
       END OF IT_OUTCLIP.
  DATA:IT_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV,
       WA_FIELDCAT TYPE SLIS_FIELDCAT_ALV.
  DATA:STR1 TYPE BAPI_MSG,
       STR2 TYPE BAPI_MSG.

  REFRESH:IT_FIELDCAT,IT_OUTCLIP.

  PERFORM GETTABSTRU(ZPUBFORM) USING INTAB CHANGING IT_FIELDCAT.
  DELETE IT_FIELDCAT WHERE INTTYPE = 'h' OR INTTYPE = 'u'
  OR FIELDNAME = 'MANDT' .

  LOOP AT IT_FIELDCAT INTO WA_FIELDCAT.
    CLEAR:STR1,STR2,IT_OUTCLIP.
    CONCATENATE `'` WA_FIELDCAT-FIELDNAME `'` INTO STR1.
    DO 5 TIMES.
      CONCATENATE `''` STR2 INTO STR2 SEPARATED BY SPACE.
    ENDDO.
    AT LAST.
      CONCATENATE STR1 STR2 '.' INTO IT_OUTCLIP-CLIPSTR
      SEPARATED BY SPACE.
      APPEND IT_OUTCLIP.
      EXIT.
    ENDAT.
    CONCATENATE STR1 STR2 ',' INTO IT_OUTCLIP-CLIPSTR
    SEPARATED BY SPACE.
    APPEND IT_OUTCLIP.
  ENDLOOP.
  IF IT_OUTCLIP[] IS NOT INITIAL.
    PERFORM ITABTOCLIP(ZPUBFORM) TABLES IT_OUTCLIP USING '' ''.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 28.10.2021 14:53:28
*内表转化为下拉框
FORM ITABTOLIST TABLES INTAB USING P_INPUT.
  DATA:VID   TYPE VRM_ID,
       VLIST TYPE  VRM_VALUES,
       VALUE LIKE LINE OF VLIST.
  FIELD-SYMBOLS:<FS> TYPE ANY,
                <WA> TYPE ANY.

  CLEAR:VID,VLIST,VALUE.
  CHECK P_INPUT IS NOT INITIAL.
  VID = P_INPUT.

  LOOP AT INTAB ASSIGNING <WA>.
    CLEAR:VALUE.
    ASSIGN COMPONENT 1 OF STRUCTURE <WA> TO <FS>.
    IF SY-SUBRC EQ 0.
      VALUE-KEY = <FS>.
    ENDIF.
    ASSIGN COMPONENT 2 OF STRUCTURE <WA> TO <FS>.
    IF SY-SUBRC EQ 0.
      VALUE-TEXT = <FS>.
    ENDIF.
    APPEND VALUE TO VLIST.
  ENDLOOP.


  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      ID              = VID
      VALUES          = VLIST
    EXCEPTIONS
      ID_ILLEGAL_NAME = 1
      OTHERS          = 2.
ENDFORM.
********ADD BY DONGPZ BEGIN AT 17.11.2021 13:55:34
*删除SO/DN-按行删除
FORM DELVBELNP TABLES P_IN_TAB STRUCTURE LIPS_KEY
               USING  P_IN_TYPE
               CHANGING OUTMSG.
  DATA:TAB_VBELN        TYPE TABLE OF BAPIVBELN WITH HEADER LINE,
       VBELN            TYPE VBELN,
       ORDER_HEADER_INX TYPE BAPISDH1X,
       TECHN_CONTROL    TYPE BAPIDLVCONTROL,
       TAB_LIPS         TYPE TABLE OF LIPS WITH HEADER LINE,
       ITEM_DATA        TYPE TABLE OF BAPIOBDLVITEMCHG WITH HEADER LINE,
       HEADER_DATA      TYPE  BAPIOBDLVHDRCHG,
       HEADER_CONTROL   TYPE BAPIOBDLVHDRCTRLCHG,
       ORDER_ITEM_INX   TYPE TABLE OF BAPISDITMX WITH HEADER LINE,
       ORDER_ITEM_IN    TYPE TABLE OF BAPISDITM WITH HEADER LINE,
       ITEM_CONTROL     TYPE TABLE OF BAPIOBDLVITEMCTRLCHG WITH HEADER LINE,
       RETURN           TYPE TABLE OF BAPIRET2 WITH HEADER LINE.
  REFRESH:TAB_VBELN,RETURN,ORDER_ITEM_INX,
  ORDER_ITEM_IN,TAB_LIPS,ITEM_DATA,ITEM_CONTROL.
  CLEAR:TAB_VBELN,ORDER_HEADER_INX,VBELN,TECHN_CONTROL,HEADER_DATA,
  HEADER_CONTROL.

  CHECK P_IN_TAB[] IS NOT INITIAL.

  LOOP AT P_IN_TAB.
    CLEAR:TAB_VBELN.
    PERFORM ADDZERO(ZPUBFORM) CHANGING P_IN_TAB-VBELN.
    TAB_VBELN-VBELN = P_IN_TAB-VBELN.
    COLLECT TAB_VBELN.
    MODIFY P_IN_TAB.
  ENDLOOP.
  IF LINES( TAB_VBELN ) NE 1.
    RETURN.
  ENDIF.
  READ TABLE TAB_VBELN INDEX 1.
  VBELN = TAB_VBELN-VBELN.
  IF OUTMSG EQ 'X'."按行删除
    CLEAR OUTMSG.
    CASE P_IN_TYPE.
      WHEN 'SO'.
        ORDER_HEADER_INX-UPDATEFLAG = 'U'.

        LOOP AT P_IN_TAB.
          CLEAR:ORDER_ITEM_INX.
          ORDER_ITEM_INX-ITM_NUMBER = P_IN_TAB-POSNR.
          ORDER_ITEM_IN-ITM_NUMBER = P_IN_TAB-POSNR.
          ORDER_ITEM_INX-UPDATEFLAG = 'D'.
          APPEND:ORDER_ITEM_IN, ORDER_ITEM_INX.
        ENDLOOP.
        SET UPDATE TASK LOCAL.
        CALL FUNCTION 'BAPI_SALESORDER_CHANGE' "DESTINATION 'NONE'
          EXPORTING
            SALESDOCUMENT    = VBELN
            ORDER_HEADER_INX = ORDER_HEADER_INX
          TABLES
            ORDER_ITEM_IN    = ORDER_ITEM_IN
            ORDER_ITEM_INX   = ORDER_ITEM_INX
            RETURN           = RETURN
          EXCEPTIONS
            OTHERS           = 1.
        IF SY-SUBRC NE 0.
          PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
          RETURN-TYPE = 'E'.
          APPEND RETURN.
          CLEAR RETURN.
        ENDIF.
      WHEN 'DN'.
        SELECT *
          INTO TABLE TAB_LIPS
          FROM LIPS
          WHERE VBELN = VBELN.
        IF SY-SUBRC NE 0.
          RETURN.
        ENDIF.
        SORT TAB_LIPS BY POSNR.

        HEADER_DATA-DELIV_NUMB = VBELN.
        HEADER_CONTROL-DELIV_NUMB = VBELN.

        LOOP AT P_IN_TAB.
          CLEAR:ITEM_DATA, TAB_LIPS.
          READ TABLE TAB_LIPS WITH KEY POSNR = P_IN_TAB-POSNR BINARY SEARCH.
          IF SY-SUBRC NE 0.
            CONTINUE.
          ENDIF.
          ITEM_DATA-DELIV_NUMB = TAB_LIPS-VBELN.
          ITEM_DATA-DELIV_ITEM = TAB_LIPS-POSNR.
          ITEM_DATA-MATERIAL = TAB_LIPS-MATNR.
          ITEM_DATA-BATCH = TAB_LIPS-CHARG.
          ITEM_DATA-DLV_QTY = TAB_LIPS-LFIMG.
          ITEM_DATA-DLV_QTY_IMUNIT = TAB_LIPS-LFIMG.
          ITEM_DATA-FACT_UNIT_NOM = TAB_LIPS-UMVKZ.
          ITEM_DATA-FACT_UNIT_DENOM = TAB_LIPS-UMVKN.

          ITEM_CONTROL-DELIV_NUMB = TAB_LIPS-VBELN.
          ITEM_CONTROL-DELIV_ITEM = TAB_LIPS-POSNR.
          ITEM_CONTROL-DEL_ITEM = 'X'.

          APPEND :ITEM_CONTROL,ITEM_DATA.
        ENDLOOP.
        CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE' " DESTINATION 'NONE'
          EXPORTING
            HEADER_DATA    = HEADER_DATA
            HEADER_CONTROL = HEADER_CONTROL
            TECHN_CONTROL  = TECHN_CONTROL
            DELIVERY       = VBELN
          TABLES
            RETURN         = RETURN
            ITEM_DATA      = ITEM_DATA
            ITEM_CONTROL   = ITEM_CONTROL
          EXCEPTIONS
            OTHERS         = 1.
        IF SY-SUBRC NE 0.
          PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' '' CHANGING RETURN-MESSAGE.
          RETURN-TYPE = 'E'.
          APPEND RETURN.
          CLEAR RETURN.
        ENDIF.
      WHEN OTHERS.
        OUTMSG = 'E:输入正确订单类型'.
        RETURN.
    ENDCASE.
    LOOP AT RETURN WHERE TYPE CA 'AEX'.
      IF RETURN-MESSAGE IS INITIAL.
        PERFORM MSGTOTEXT(ZPUBFORM)  USING RETURN-ID
              RETURN-NUMBER
              RETURN-MESSAGE_V1
              RETURN-MESSAGE_V2
              RETURN-MESSAGE_V3
              RETURN-MESSAGE_V4
        CHANGING RETURN-MESSAGE.
      ENDIF.
      CONCATENATE RETURN-MESSAGE OUTMSG INTO OUTMSG SEPARATED BY '/'.
      CLEAR RETURN.
    ENDLOOP.
    IF SY-SUBRC NE 0.
      CASE P_IN_TYPE.
        WHEN 'SO'.
          OUTMSG = 'S:销售订单删除成功'.
        WHEN 'DN'.
          OUTMSG = 'S:交货单删除成功'.
      ENDCASE.
      COMMIT WORK AND WAIT.
    ELSE.
      ROLLBACK WORK.
      CONCATENATE 'E:' OUTMSG INTO OUTMSG.
    ENDIF.
  ELSE."整单删除
    PERFORM DELVBELN(ZPUBFORM) USING VBELN
                                     P_IN_TYPE
                             CHANGING OUTMSG.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 17.11.2021 13:55:34
********ADD BY DONGPZ BEGIN AT 19.11.2021 13:25:37
*负号提前
FORM SHIFTSIGN CHANGING INSTR.
  DATA:LEN   TYPE I,
       CFLAG TYPE CHAR10.
  CLEAR:CFLAG,LEN.

  CHECK INSTR IS NOT INITIAL.

  LEN = STRLEN( INSTR ) - 1.
  IF LEN > 0 AND INSTR CO ' 0123456789,.-' AND INSTR+LEN(1) = '-' .
    TRANSLATE INSTR USING '- '.
    TRANSLATE INSTR USING ', '.
    CONCATENATE '-' INSTR INTO INSTR.
    CONDENSE INSTR NO-GAPS.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 19.11.2021 13:25:37
********ADD BY DONGPZ BEGIN AT 09.03.2022 16:33:50
*根据OBJNR号批量获取状态及文本
FORM GETSTATUS TABLES P_TAB_OBJNR STRUCTURE BAPIOBJNR
                      P_OUTSTA
               USING P_INACT.
  DATA BEGIN OF IT_OUTOBJNR OCCURS 0.
  INCLUDE TYPE BAPIOBJNR.
  DATA:STA  TYPE BAPI_MSG,
       TEXT TYPE BAPI_MSG,
       END OF IT_OUTOBJNR.
  DATA:BEGIN OF IT_JEST_TJ02T OCCURS 0,
         OBJNR TYPE JEST-OBJNR,
         STAT  TYPE JEST-STAT,
         INACT TYPE JEST-INACT,
         TXT04 TYPE TJ02T-TXT04,
         TXT30 TYPE TJ02T-TXT30,
       END OF IT_JEST_TJ02T.
  DATA:TABIXOBJNR TYPE SY-TABIX.

  CLEAR:IT_JEST_TJ02T[],IT_OUTOBJNR[].
  DELETE P_TAB_OBJNR WHERE OBJNR IS INITIAL.
  CHECK P_TAB_OBJNR[] IS NOT INITIAL.
  SORT P_TAB_OBJNR BY OBJNR.
  SELECT JEST~OBJNR
         JEST~STAT
         JEST~INACT
         TJ02T~TXT04
         TJ02T~TXT30
    INTO TABLE IT_JEST_TJ02T
    FROM JEST INNER JOIN TJ02T ON JEST~STAT = TJ02T~ISTAT
                              AND TJ02T~SPRAS = SY-LANGU
    FOR ALL ENTRIES IN P_TAB_OBJNR
    WHERE JEST~OBJNR = P_TAB_OBJNR-OBJNR.
  IF P_INACT = 'X'.
  ELSE.
    DELETE IT_JEST_TJ02T WHERE INACT = 'X'.
  ENDIF.
  SORT IT_JEST_TJ02T BY OBJNR.
  LOOP AT P_TAB_OBJNR.
    CLEAR:IT_OUTOBJNR.
    READ TABLE IT_JEST_TJ02T WITH KEY OBJNR = P_TAB_OBJNR BINARY SEARCH.
    IF SY-SUBRC EQ 0.
      TABIXOBJNR = SY-TABIX.
      IT_OUTOBJNR-OBJNR = P_TAB_OBJNR-OBJNR.
      LOOP AT IT_JEST_TJ02T FROM TABIXOBJNR.
        IF P_TAB_OBJNR-OBJNR NE IT_JEST_TJ02T-OBJNR.
          EXIT.
        ENDIF.
        CONCATENATE IT_JEST_TJ02T-STAT IT_OUTOBJNR-STA
        INTO IT_OUTOBJNR-STA SEPARATED BY '/'.
        CONCATENATE IT_JEST_TJ02T-TXT04 IT_OUTOBJNR-TEXT
        INTO IT_OUTOBJNR-TEXT SEPARATED BY '/'.
      ENDLOOP.
      APPEND IT_OUTOBJNR.
      MOVE-CORRESPONDING IT_OUTOBJNR TO P_OUTSTA.
      APPEND P_OUTSTA.
    ENDIF.
  ENDLOOP.
ENDFORM.
********ADD BY DONGPZ END AT 09.03.2022 16:33:50
********ADD BY DONGPZ BEGIN AT 20.03.2022 17:57:05
*获取MM/SD价格，V是SD，M是MM
FORM GETPRICEINFO TABLES OUTTAB
                   USING P_IN_KAPPL P_IN_KSCHL.
  DATA:BEGIN OF IT_OUTTAB OCCURS 0,
         KSCHL TYPE T685-KSCHL,
         KRECH TYPE T685A-KRECH,
         KOTAB TYPE T681-KOTAB,
         KOLNR TYPE T682I-KOLNR,
         ZAEHK TYPE T682Z-ZAEHK,
         ZIFNA TYPE T682Z-ZIFNA,
         QUSTR TYPE T682Z-QUSTR,
         QUFNA TYPE T682Z-QUFNA,
         VTEXT TYPE T685T-VTEXT,
         GSTXT TYPE TMC1T-GSTXT,
       END OF IT_OUTTAB.
  REFRESH:IT_OUTTAB,OUTTAB.
  CHECK P_IN_KAPPL IS NOT INITIAL
  AND P_IN_KSCHL IS NOT INITIAL.
  SELECT T685~KSCHL
         T685A~KRECH
         T681~KOTAB
         T682I~KOLNR
         T682Z~ZAEHK
         T682Z~ZIFNA
         T682Z~QUSTR
         T682Z~QUFNA
         T685T~VTEXT
         TMC1T~GSTXT
    INTO TABLE IT_OUTTAB
    FROM T682 INNER JOIN T685  ON T682~KVEWE = T685~KVEWE AND
                                  T682~KAPPL = T685~KAPPL AND
                                  T682~KOZGF = T685~KOZGF
              INNER JOIN T685A ON T685~KAPPL = T685A~KAPPL AND
                                  T685~KSCHL = T685A~KSCHL
              INNER JOIN T685T ON T685~KVEWE = T685T~KVEWE AND
                                  T685~KAPPL = T685T~KAPPL AND
                                  T685~KSCHL = T685T~KSCHL AND
                                  T685T~SPRAS = SY-LANGU
              INNER JOIN T682I ON T682~KVEWE = T682I~KVEWE AND
                                  T682~KAPPL = T682I~KAPPL AND
                                  T682~KOZGF = T682I~KOZGF
              INNER JOIN T682Z ON T682I~KVEWE = T682Z~KVEWE AND
                                  T682I~KAPPL = T682Z~KAPPL AND
                                  T682I~KOZGF = T682Z~KOZGF AND
                                  T682I~KOLNR = T682Z~KOLNR
              INNER JOIN T681  ON T682I~KVEWE = T681~KVEWE AND
                                  T682I~KOTABNR = T681~KOTABNR
              INNER JOIN TMC1T ON T681~KOTAB = TMC1T~GSTRU AND
                                  TMC1T~SPRAS = SY-LANGU
    WHERE T682~KVEWE = 'A'
      AND T682~KAPPL EQ P_IN_KAPPL
      AND T682Z~QUFNA NE ''
      AND T685~KSCHL = P_IN_KSCHL
      AND T685~KSCHL LIKE 'Z%'.
  LOOP AT IT_OUTTAB.
    CLEAR:OUTTAB.
    MOVE-CORRESPONDING IT_OUTTAB TO OUTTAB.
    APPEND OUTTAB.
  ENDLOOP.
ENDFORM.
********ADD BY DONGPZ END AT 20.03.2022 17:57:05
********ADD BY DONGPZ BEGIN AT 21.03.2022 15:54:37
*批量账期MMPV，若日期不填，则开到当前日期
FORM MMPV USING P_IN_BUKRS P_IN_DATUM CHANGING OUTMSG.
  DATA:BDCDATA   TYPE TABLE OF  BDCDATA WITH HEADER LINE,
       BDCRETURN TYPE TABLE OF BAPIRET2 WITH HEADER LINE.
  DATA:WA_MARV TYPE MARV,
       FRDAT   TYPE SY-DATUM,
       DATUM   TYPE SY-DATUM,
       TODAT   TYPE SY-DATUM.
  REFRESH:BDCDATA,BDCRETURN.
  CLEAR:WA_MARV,FRDAT,DATUM,TODAT,OUTMSG.
  TODAT = P_IN_DATUM.
  IF TODAT IS INITIAL.
    TODAT = SY-DATUM.
  ENDIF.
  SELECT SINGLE *
    INTO WA_MARV
    FROM MARV
    WHERE BUKRS = P_IN_BUKRS.
  IF SY-SUBRC NE 0.
    OUTMSG = '不存在物料帐数据'.
    EXIT.
  ENDIF.
  IF TODAT+0(4) NE WA_MARV-LFGJA
    OR TODAT+4(2) NE WA_MARV-LFMON.
  ELSE.
    OUTMSG = 'S:执行成功'.
    EXIT.
  ENDIF.
  CONCATENATE WA_MARV-LFGJA WA_MARV-LFMON '01' INTO FRDAT.
  FRDAT = FRDAT + 32.
  CONCATENATE FRDAT(6) '01' INTO DATUM.

  WHILE DATUM(6) LE TODAT(6).
    REFRESH:BDCDATA,BDCRETURN.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES BDCDATA
            USING 'RMMMPERI' '1000'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA
             USING 'BDC_OKCODE'    '=ONLI'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA
             USING 'I_VBUKR'       P_IN_BUKRS.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA
             USING 'I_BBUKR'       P_IN_BUKRS.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA
             USING 'I_DATUM'       DATUM.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES BDCDATA
          USING 'SAPMSSY0' '0120'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA
             USING 'BDC_OKCODE'    '=&F03'.
    PERFORM BDC_DYNPRO(ZPUBFORM) TABLES BDCDATA
            USING 'RMMMPERI' '1000'.
    PERFORM BDC_FIELD(ZPUBFORM) TABLES BDCDATA
             USING 'BDC_OKCODE'    '/EE'.
    SET UPDATE TASK LOCAL.
    PERFORM BDCFM(ZPUBFORM) TABLES BDCDATA BDCRETURN
                            USING 'MMPV' 'N'.
    DATUM = DATUM + 32.
    DATUM+6(2) = '01'.
    LOOP AT BDCRETURN WHERE TYPE CA 'AEX'.
      CONCATENATE BDCRETURN-MESSAGE OUTMSG INTO OUTMSG
      SEPARATED BY '/'.
    ENDLOOP.
    IF SY-SUBRC = 0.
      EXIT.
    ELSE.
    ENDIF.
  ENDWHILE.
  CLEAR:WA_MARV.
  SELECT SINGLE *
    INTO WA_MARV
    FROM MARV
    WHERE BUKRS = P_IN_BUKRS.
  IF TODAT+0(4) NE WA_MARV-LFGJA
    OR TODAT+4(2) NE WA_MARV-LFMON.
    CONCATENATE 'E:MMPV失败:' OUTMSG INTO OUTMSG.
  ELSE.
    OUTMSG = 'S:执行成功'.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 21.03.2022 15:54:37
********ADD BY DONGPZ BEGIN AT 23.03.2022 20:58:51
*清空数据库
FORM TRUNCATE USING P_TABNAM CHANGING OUTMSG.
  DATA: SQL_CON  TYPE REF TO CL_SQL_CONNECTION,
        SQL_STMT TYPE REF TO CL_SQL_STATEMENT,
        SQL_STR  TYPE STRING,
        CXROOT   TYPE REF TO CX_ROOT.
  CLEAR:OUTMSG,SQL_STR.
  SELECT SINGLE COUNT(*)
    FROM DD02L
    WHERE TABNAME = P_TABNAM
    AND   TABCLASS = 'TRANSP'
    AND   TABNAME LIKE 'Z%'.
  IF SY-SUBRC NE 0.
    OUTMSG = 'E:只能清空自建表'.
    EXIT.
  ENDIF.
  CONCATENATE 'TRUNCATE TABLE' P_TABNAM INTO SQL_STR SEPARATED BY SPACE.
  TRY .
      SQL_CON = CL_SQL_CONNECTION=>GET_CONNECTION( ).
      SQL_STMT = SQL_CON->CREATE_STATEMENT( ).
      SQL_STMT->EXECUTE_DDL( STATEMENT = SQL_STR ).
    CATCH  CX_ROOT INTO CXROOT.
      OUTMSG =  CXROOT->GET_TEXT( ).
      CONCATENATE 'E:' OUTMSG INTO OUTMSG.
  ENDTRY.
  IF OUTMSG+0(1) NE 'E'.
    COMMIT WORK.
  ELSE.
    ROLLBACK WORK.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 23.03.2022 20:58:51
********ADD BY DONGPZ BEGIN AT 25.03.2022 17:24:45
*取工单对应的成本中心、工作中心
FORM GETPPKOSTL TABLES P_TAB_AUFNR STRUCTURE AUFNR_PRE
                       OUTTAB.
  DATA:BEGIN OF IT_AUFNR_KOSTL OCCURS 0,
         AUFNR TYPE AUFNR,
         AUFPL TYPE AFKO-AUFPL,
         ARBID TYPE AFVC-ARBID,
         KOSTL TYPE KOSTL,
         ARBPL TYPE CRHD-ARBPL,
       END OF IT_AUFNR_KOSTL,
       BEGIN OF IT_CRHD OCCURS 0,
         OBJTY TYPE CRHD-OBJTY,
         OBJID TYPE CRHD-OBJID,
         ARBPL TYPE CRHD-ARBPL,
       END OF IT_CRHD,
       BEGIN OF IT_OBJID OCCURS 0,
         OBJID TYPE CRCO-OBJID,
       END OF IT_OBJID,
       TABIX TYPE SY-TABIX.
  REFRESH:OUTTAB,IT_AUFNR_KOSTL,IT_OBJID,IT_CRHD.
  DELETE P_TAB_AUFNR WHERE AUFNR IS INITIAL.
  CHECK P_TAB_AUFNR[] IS NOT INITIAL.

  LOOP AT P_TAB_AUFNR.
    PERFORM ADDZERO(ZPUBFORM) CHANGING P_TAB_AUFNR-AUFNR.
    MODIFY P_TAB_AUFNR.
  ENDLOOP.
  SORT P_TAB_AUFNR BY AUFNR.
  SELECT AFKO~AUFNR
         AFKO~AUFPL
         AFVC~ARBID
         CRCO~KOSTL
    INTO TABLE IT_AUFNR_KOSTL
    FROM AFKO INNER JOIN AFVC ON AFKO~AUFPL = AFVC~AUFPL
              INNER JOIN CRCO ON AFVC~ARBID = CRCO~OBJID
    FOR ALL ENTRIES IN P_TAB_AUFNR
    WHERE AFKO~AUFNR = P_TAB_AUFNR-AUFNR.
  IF SY-SUBRC NE 0.
    EXIT.
  ENDIF.
  SORT IT_AUFNR_KOSTL BY AUFNR AUFPL ARBID KOSTL.
  DELETE ADJACENT DUPLICATES FROM IT_AUFNR_KOSTL
  COMPARING ALL FIELDS.
  LOOP AT IT_AUFNR_KOSTL.
    CLEAR:IT_OBJID.
    IT_OBJID-OBJID = IT_AUFNR_KOSTL-ARBID.
    COLLECT IT_OBJID.
  ENDLOOP.
  IF IT_OBJID[] IS NOT INITIAL.
    SORT IT_OBJID BY OBJID.
    SELECT OBJTY
           OBJID
           ARBPL
      INTO TABLE IT_CRHD
      FROM CRHD
      FOR ALL ENTRIES IN IT_OBJID
      WHERE OBJID = IT_OBJID-OBJID.
    SORT IT_CRHD BY OBJID.
  ENDIF.

  LOOP AT P_TAB_AUFNR.
    CLEAR:OUTTAB,TABIX.
    MOVE-CORRESPONDING P_TAB_AUFNR TO OUTTAB.
    READ TABLE IT_AUFNR_KOSTL WITH KEY AUFNR = P_TAB_AUFNR-AUFNR BINARY SEARCH.
    IF SY-SUBRC EQ 0.
      TABIX = SY-TABIX.
      LOOP AT IT_AUFNR_KOSTL FROM TABIX.
        IF P_TAB_AUFNR-AUFNR NE IT_AUFNR_KOSTL-AUFNR.
          EXIT.
        ENDIF.
        MOVE-CORRESPONDING IT_AUFNR_KOSTL TO OUTTAB.
        READ TABLE IT_CRHD WITH KEY OBJID = IT_AUFNR_KOSTL-ARBID BINARY SEARCH.
        IF SY-SUBRC EQ 0.
          MOVE-CORRESPONDING IT_CRHD TO OUTTAB.
        ENDIF.
        APPEND OUTTAB.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.
********ADD BY DONGPZ END AT 25.03.2022 17:24:45
********ADD BY DONGPZ BEGIN AT 29.03.2022 09:25:10
*获取STMS传输路径
FORM TMSROUTE CHANGING OUTWA.
  DATA:BEGIN OF WA_TRANSROUTIN,
         DEV        TYPE SYSYSID,
         QAS        TYPE SYSYSID,
         PRD        TYPE SYSYSID,
         TRANSLAYER TYPE TCERELE-TRANSLAYER,
         RFCDES     TYPE TMSCDES-RFCDES,
       END OF WA_TRANSROUTIN,
       IT_TMSCDES TYPE TABLE OF TMSCDES WITH HEADER LINE,
       IT_TCESYST TYPE TABLE OF TCESYST WITH HEADER LINE,
       IT_TCEDELI TYPE TABLE OF TCEDELI WITH HEADER LINE,
       IT_TCERELE TYPE TABLE OF TCERELE WITH HEADER LINE.
  DATA:DESSTR TYPE TMSCDES-RFCDES.

  CLEAR:IT_TCERELE,IT_TCESYST,IT_TCEDELI,WA_TRANSROUTIN,
  DESSTR,OUTWA,IT_TMSCDES.
  SELECT * INTO TABLE IT_TCESYST FROM TCESYST.
  SORT IT_TCESYST BY VERSION DESCENDING.

  READ TABLE IT_TCESYST WITH KEY SYSNAME = SY-SYSID.
  IF IT_TCESYST IS NOT INITIAL."存储QAS路径
    SELECT SINGLE *
      INTO IT_TCERELE
      FROM TCERELE
      WHERE VERSION = IT_TCESYST-VERSION
      AND   INTSYS = IT_TCESYST-SYSNAME
      AND   TRANSLAYER = IT_TCESYST-TRANSLAYER.
    IF SY-SUBRC EQ 0."存储PRD传输路径
      SELECT SINGLE *
        INTO IT_TCEDELI
        FROM TCEDELI
        WHERE VERSION = IT_TCERELE-VERSION
        AND   FROMSYSTEM = IT_TCERELE-CONSYS.
    ENDIF.
    SELECT * INTO TABLE IT_TMSCDES FROM TMSCDES.
    CONCATENATE 'TMSSUP@' IT_TCERELE-CONSYS INTO DESSTR.
    LOOP AT IT_TMSCDES.
      SEARCH IT_TMSCDES-RFCDES FOR DESSTR.
      IF SY-SUBRC EQ 0.
        EXIT.
      ENDIF.
    ENDLOOP.
    WA_TRANSROUTIN-DEV = IT_TCESYST-SYSNAME.
    WA_TRANSROUTIN-QAS = IT_TCERELE-CONSYS.
    WA_TRANSROUTIN-PRD = IT_TCEDELI-TOSYSTEM.
    WA_TRANSROUTIN-TRANSLAYER = IT_TCESYST-TRANSLAYER.
    WA_TRANSROUTIN-RFCDES = IT_TMSCDES-RFCDES.
    MOVE-CORRESPONDING WA_TRANSROUTIN TO OUTWA.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 29.03.2022 09:25:10
********ADD BY DONGPZ BEGIN AT 01.04.2022 10:26:12
*创建删除批次
FORM CREATECHARG USING P_IN_WERKS
                     P_IN_MATNR
                     P_IN_CHARG
                     P_IN_LGORT
               CHANGING OUTMSG.
  DATA:MATERIAL             TYPE BAPIBATCHKEY-MATERIAL,
       BATCH                TYPE BAPIBATCHKEY-BATCH,
       PLANT                TYPE BAPIBATCHKEY-PLANT,
       BATCHSTORAGELOCATION TYPE BAPIBATCHSTOLOC-STGE_LOC,
       RETURN               TYPE TABLE OF BAPIRET2 WITH HEADER LINE.
  CLEAR:OUTMSG,MATERIAL,BATCH,PLANT,BATCHSTORAGELOCATION.
  REFRESH:RETURN.
  MATERIAL = P_IN_MATNR.
  BATCH = P_IN_CHARG.
  PLANT = P_IN_WERKS.
  BATCHSTORAGELOCATION = P_IN_LGORT.
  PERFORM ADDZERO(ZPUBFORM) CHANGING MATERIAL.
  CALL FUNCTION 'BAPI_BATCH_CREATE'
    EXPORTING
      MATERIAL             = MATERIAL
      BATCH                = BATCH
      PLANT                = PLANT
      BATCHSTORAGELOCATION = BATCHSTORAGELOCATION
    TABLES
      RETURN               = RETURN
    EXCEPTIONS
      OTHERS               = 1.
  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE RETURN-MESSAGE OUTMSG INTO OUTMSG
    SEPARATED BY '/'.
  ENDLOOP.
  IF SY-SUBRC = 0.
    CONCATENATE 'E:' OUTMSG INTO OUTMSG.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        WAIT = 'X'.
    OUTMSG =  ' S:SUCCESS'.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 01.04.2022 10:26:12
********ADD BY DONGPZ BEGIN AT 02.04.2022 14:13:09
*MSC2N更新批次特性
FORM MSC2N TABLES INTAB STRUCTURE
            RCPS_SRCH_ATT_CLS_VAL
           USING P_IN_WERKS
                 P_IN_MATNR TYPE MATNR
                 P_IN_CHARG
           CHANGING OUTMSG.
  DATA: E_OBJEK             TYPE  CUOBN,
        E_OBTAB             TYPE  TABELLE,
        E_KLART             TYPE  KLASSENART,
        E_CLASS             TYPE  KLASSE_D,
        LONGBS              TYPE CHAR1,
        IT_FUPARAREF        TYPE TABLE OF FUPARAREF WITH HEADER LINE,
        RETURN              TYPE TABLE OF BAPIRET2 WITH HEADER LINE,
        ALLOCVALUESNUMNEW   TYPE TABLE OF BAPI1003_ALLOC_VALUES_NUM  WITH HEADER LINE,
        ALLOCVALUESCHARNEW  TYPE TABLE OF BAPI1003_ALLOC_VALUES_CHAR WITH HEADER LINE,
        ALLOCVALUESCURRNEW  TYPE TABLE OF BAPI1003_ALLOC_VALUES_CURR WITH HEADER LINE,
        ALLOCVALUESCHARNEWN TYPE TABLE OF BAPI1003_ALLOC_VALUES_CHAR WITH HEADER LINE..
  DATA:I_MATNR TYPE MATNR.
  FIELD-SYMBOLS:<FS_MSC2N> TYPE ANY.
  REFRESH:ALLOCVALUESNUMNEW,ALLOCVALUESCHARNEW,ALLOCVALUESCHARNEWN,
  ALLOCVALUESCHARNEWN,RETURN,IT_FUPARAREF.
  CLEAR:OUTMSG,I_MATNR,E_OBJEK,E_OBTAB,E_CLASS,E_KLART,LONGBS.
  IF INTAB[] IS INITIAL
    OR P_IN_MATNR IS INITIAL
    OR P_IN_WERKS IS INITIAL
    OR P_IN_CHARG IS INITIAL.
    EXIT.
  ENDIF.
  I_MATNR = P_IN_MATNR.
  PERFORM ADDZERO_MATNR(ZPUBFORM) CHANGING I_MATNR.
  SELECT *
    INTO TABLE IT_FUPARAREF
    FROM FUPARAREF
    WHERE FUNCNAME = 'BAPI_OBJCL_GETDETAIL'.
  READ TABLE IT_FUPARAREF WITH KEY PARAMETER = 'OBJECTKEY_LONG'
                                   PARAMTYPE = 'I'.
  IF SY-SUBRC EQ 0.
    LONGBS = 'X'.
  ENDIF.
**获得批次编号
  CALL FUNCTION 'VB_BATCH_2_CLASS_OBJECT'
    EXPORTING
      I_MATNR = I_MATNR
      I_CHARG = P_IN_CHARG
      I_WERKS = P_IN_WERKS
    IMPORTING
      E_OBJEK = E_OBJEK            "对应objectkey
      E_OBTAB = E_OBTAB                "对应objecttable
      E_KLART = E_KLART                " 对应classtype
      E_CLASS = E_CLASS.                "对应classnum
*获得特性值
  IF LONGBS = 'X'.
    CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
      EXPORTING
*       OBJECTKEY        = E_OBJEK
        OBJECTTABLE      = E_OBTAB
        CLASSNUM         = E_CLASS
        CLASSTYPE        = E_KLART
        UNVALUATED_CHARS = 'X'
        OBJECTKEY_LONG   = E_OBJEK
      TABLES
        ALLOCVALUESNUM   = ALLOCVALUESNUMNEW
        ALLOCVALUESCHAR  = ALLOCVALUESCHARNEW
        ALLOCVALUESCURR  = ALLOCVALUESCURRNEW
        RETURN           = RETURN
      EXCEPTIONS
        OTHERS           = 1.
  ELSE.
    CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
      EXPORTING
        OBJECTKEY        = E_OBJEK
        OBJECTTABLE      = E_OBTAB
        CLASSNUM         = E_CLASS
        CLASSTYPE        = E_KLART
        UNVALUATED_CHARS = 'X'
*       OBJECTKEY_LONG   = E_OBJEK
      TABLES
        ALLOCVALUESNUM   = ALLOCVALUESNUMNEW
        ALLOCVALUESCHAR  = ALLOCVALUESCHARNEW
        ALLOCVALUESCURR  = ALLOCVALUESCURRNEW
        RETURN           = RETURN
      EXCEPTIONS
        OTHERS           = 1.
  ENDIF.

  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE RETURN-MESSAGE OUTMSG
    INTO OUTMSG SEPARATED BY '/'.
  ENDLOOP.
  IF SY-SUBRC EQ 0.
    EXIT.
  ENDIF.
  REFRESH:RETURN.
  CLEAR:OUTMSG.
  SORT INTAB BY ATNAM.
  SORT ALLOCVALUESCHARNEW BY CHARACT.
  LOOP AT INTAB.
    CLEAR:ALLOCVALUESCHARNEW,ALLOCVALUESCHARNEWN.
    READ TABLE ALLOCVALUESCHARNEW WITH KEY CHARACT = INTAB-ATNAM BINARY SEARCH.
    IF SY-SUBRC NE 0.
      ALLOCVALUESCHARNEWN-CHARACT = INTAB-ATNAM.
      ALLOCVALUESCHARNEWN-VALUE_CHAR = INTAB-ATWRT.
      ALLOCVALUESCHARNEWN-VALUE_NEUTRAL = INTAB-ATWRT.
      APPEND ALLOCVALUESCHARNEWN.
    ENDIF.
  ENDLOOP.
  LOOP AT ALLOCVALUESCHARNEW.
    READ TABLE INTAB WITH KEY ATNAM = ALLOCVALUESCHARNEW-CHARACT BINARY SEARCH.
    IF SY-SUBRC = 0.
      ALLOCVALUESCHARNEW-VALUE_CHAR = INTAB-ATWRT.
      ALLOCVALUESCHARNEW-VALUE_NEUTRAL = INTAB-ATWRT.
      MODIFY ALLOCVALUESCHARNEW.
    ENDIF.
    CLEAR ALLOCVALUESCHARNEW.
  ENDLOOP.
  IF ALLOCVALUESCHARNEWN[] IS NOT INITIAL.
    APPEND LINES OF ALLOCVALUESCHARNEWN TO ALLOCVALUESCHARNEW.
  ENDIF.
  IF LONGBS = 'X'.
    LOOP AT ALLOCVALUESCHARNEW.
      ASSIGN COMPONENT 'VALUE_NEUTRAL_LONG'
      OF STRUCTURE ALLOCVALUESCHARNEW TO <FS_MSC2N>.
      IF SY-SUBRC EQ 0.
        <FS_MSC2N> = ALLOCVALUESCHARNEW-VALUE_CHAR.
      ENDIF.
      ASSIGN COMPONENT 'VALUE_CHAR_LONG'
      OF STRUCTURE ALLOCVALUESCHARNEW TO <FS_MSC2N>.
      IF SY-SUBRC EQ 0.
        <FS_MSC2N> = ALLOCVALUESCHARNEW-VALUE_CHAR.
      ENDIF.
    ENDLOOP.
  ENDIF.
  LOOP AT ALLOCVALUESCHARNEW.

  ENDLOOP.
  IF LONGBS = 'X'.
    CALL FUNCTION 'BAPI_OBJCL_CHANGE'
      EXPORTING
*       OBJECTKEY          = E_OBJEK
        OBJECTTABLE        = E_OBTAB
        CLASSNUM           = E_CLASS
        CLASSTYPE          = E_KLART
        STATUS             = '1'
        STANDARDCLASS      = 'X'
        KEYDATE            = SY-DATUM
        OBJECTKEY_LONG     = E_OBJEK
      TABLES
        ALLOCVALUESNUMNEW  = ALLOCVALUESNUMNEW
        ALLOCVALUESCHARNEW = ALLOCVALUESCHARNEW
        ALLOCVALUESCURRNEW = ALLOCVALUESCURRNEW
        RETURN             = RETURN
      EXCEPTIONS
        OTHERS             = 1.
  ELSE.
    CALL FUNCTION 'BAPI_OBJCL_CHANGE'
      EXPORTING
        OBJECTKEY          = E_OBJEK
        OBJECTTABLE        = E_OBTAB
        CLASSNUM           = E_CLASS
        CLASSTYPE          = E_KLART
        STATUS             = '1'
        STANDARDCLASS      = 'X'
        KEYDATE            = SY-DATUM
*       OBJECTKEY_LONG     = E_OBJEK
      TABLES
        ALLOCVALUESNUMNEW  = ALLOCVALUESNUMNEW
        ALLOCVALUESCHARNEW = ALLOCVALUESCHARNEW
        ALLOCVALUESCURRNEW = ALLOCVALUESCURRNEW
        RETURN             = RETURN
      EXCEPTIONS
        OTHERS             = 1.
  ENDIF.

  LOOP AT RETURN WHERE TYPE CA 'AEX'.
    CONCATENATE RETURN-MESSAGE OUTMSG
    INTO OUTMSG SEPARATED BY '/'.
  ENDLOOP.
  IF SY-SUBRC EQ 0.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    CONCATENATE 'E:' OUTMSG INTO OUTMSG.
    EXIT.
  ENDIF.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      WAIT = 'X'.
  OUTMSG = 'S:批次特性维护成功'.
ENDFORM.
********ADD BY DONGPZ END AT 02.04.2022 14:13:09
********ADD BY DONGPZ BEGIN AT 26.04.2022 15:26:07
*CS15反查BOM
FORM CS15 TABLES INTAB STRUCTURE ATPMP
                OUTTAB STRUCTURE CS15_OUT USING P_IN_MATNR.
  REFRESH:CS15_OUT,OUTTAB.
  PERFORM SEARCHBOM TABLES INTAB USING P_IN_MATNR 0.
  OUTTAB[] = CS15_OUT[].
  SORT OUTTAB BY TMATNR STUFE.
ENDFORM.
FORM SEARCHBOM TABLES INTAB STRUCTURE ATPMP USING TOPMATNR VALUE(CJ) TYPE HISTU  .
  DATA:TOPMAT  TYPE MC29S,
       DATUB   TYPE RC29L-DATUB,
       WULTB   TYPE TABLE OF STPOV WITH HEADER LINE,
       MATCAT  TYPE TABLE OF CSCMAT WITH HEADER LINE,
       TM_BASE LIKE TABLE OF ATPMP WITH HEADER LINE,
       EQUICAT TYPE TABLE OF CSCEQUI WITH HEADER LINE,
       KNDCAT  TYPE TABLE OF CSCKND WITH HEADER LINE,
       STDCAT  TYPE TABLE OF CSCSTD WITH HEADER LINE,
       TPLCAT  TYPE TABLE OF CSCTPL WITH HEADER LINE,
       PRJCAT  TYPE TABLE OF CSCPRJ WITH HEADER LINE,
       STLALS  TYPE STRING.
  DATUB = '19000101'.
  CJ = CJ + 1.
  LOOP AT INTAB.
    CALL FUNCTION 'CS_WHERE_USED_MAT'
      EXPORTING
        DATUB                      = DATUB
        DATUV                      = SY-DATUM
        MATNR                      = INTAB-MATNR
        WERKS                      = INTAB-WERKS
      IMPORTING
        TOPMAT                     = TOPMAT
      TABLES
        WULTB                      = WULTB
        EQUICAT                    = EQUICAT
        KNDCAT                     = KNDCAT
        MATCAT                     = MATCAT
        STDCAT                     = STDCAT
        TPLCAT                     = TPLCAT
        PRJCAT                     = PRJCAT
      EXCEPTIONS
        CALL_INVALID               = 1
        MATERIAL_NOT_FOUND         = 2
        NO_WHERE_USED_REC_FOUND    = 3
        NO_WHERE_USED_REC_SELECTED = 4
        NO_WHERE_USED_REC_VALID    = 5
        OTHERS                     = 6.
    IF WULTB[] IS INITIAL AND INTAB-MATNR = TOPMATNR.
      CLEAR CS15_OUT.
    ENDIF.
    LOOP AT WULTB.
      CLEAR CS15_OUT.
      IF WULTB-VWALT IS INITIAL.
        SELECT SINGLE STLAL INTO WULTB-VWALT FROM MAST WHERE MATNR = WULTB-MATNR AND WERKS = WULTB-WERKS.
      ENDIF.
      CONCATENATE STLALS ',' WULTB-VWALT  INTO STLALS.
      CS15_OUT-MATNR = WULTB-MATNR.
      CS15_OUT-TMATNR = TOPMATNR.
      CS15_OUT-STUFE = CJ.
      AT END OF MATNR.
        CLEAR:TM_BASE,TM_BASE[].
        IF STLALS IS NOT INITIAL.
          STLALS = STLALS+1.
          CS15_OUT-STLALS = STLALS.
        ENDIF.
        STLALS = ''.
        APPEND CS15_OUT.
        TM_BASE-MATNR = WULTB-MATNR.
        TM_BASE-WERKS = INTAB-WERKS.
        APPEND TM_BASE.
        PERFORM SEARCHBOM TABLES TM_BASE USING TOPMATNR CJ.
      ENDAT.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    "searchbom
********ADD BY DONGPZ END AT 26.04.2022 15:26:07
********ADD BY DONGPZ BEGIN AT 01.06.2022 09:39:39
FORM FBRA USING P_BUKRS P_BELNR P_GJAHR"重置
                P_BUDAT P_STGRD"取消过账
          CHANGING P_OUTMSG.
  DATA:STGRD TYPE BKPF-STGRD,
       BUKRS TYPE BKPF-BUKRS,
       BELNR TYPE BKPF-BELNR,
       GJAHR TYPE BKPF-GJAHR,
       BUDAT TYPE BKPF-BUDAT.
  CLEAR:P_OUTMSG,STGRD,BUKRS,BELNR,GJAHR,BUDAT.
  STGRD = P_STGRD.
  BUKRS = P_BUKRS.
  BELNR = P_BELNR.
  GJAHR = P_GJAHR.
  BUDAT = P_BUDAT.
  IF STGRD IS INITIAL.
    STGRD = '01'.
  ENDIF.
*冲销
  IF P_BUDAT IS NOT INITIAL.
    CALL FUNCTION 'CALL_FB08'
      EXPORTING
        I_BUKRS      = BUKRS
        I_BELNR      = BELNR
        I_GJAHR      = GJAHR
        I_STGRD      = STGRD
        I_BUDAT      = BUDAT
        I_XSIMU      = 'X'
      EXCEPTIONS
        NOT_POSSIBLE = 1
        OTHERS       = 2.
    IF SY-SUBRC NE 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 INTO P_OUTMSG.
      CONCATENATE 'E:' P_OUTMSG INTO P_OUTMSG.
      EXIT.
    ENDIF.
  ENDIF.
*FBRA重置清账
  CALL FUNCTION 'CALL_FBRA'
    EXPORTING
      I_BUKRS      = BUKRS
      I_AUGBL      = BELNR
      I_GJAHR      = GJAHR
    EXCEPTIONS
      NOT_POSSIBLE = 1
      OTHERS       = 2.
  IF SY-SUBRC NE 0.
    ROLLBACK WORK.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 INTO P_OUTMSG.
    CONCATENATE 'E:' P_OUTMSG INTO P_OUTMSG.
    EXIT.
  ENDIF.
  COMMIT WORK AND WAIT.
  IF P_BUDAT IS NOT INITIAL.
    CALL FUNCTION 'CALL_FB08'
      EXPORTING
        I_BUKRS      = BUKRS
        I_BELNR      = BELNR
        I_GJAHR      = GJAHR
        I_UPDATE     = 'S'
        I_STGRD      = STGRD
        I_BUDAT      = BUDAT
      EXCEPTIONS
        NOT_POSSIBLE = 1
        OTHERS       = 2.
    IF SY-SUBRC NE 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4 INTO P_OUTMSG.
      CONCATENATE 'E:重置清账成功但冲销会计凭证失败' P_OUTMSG INTO P_OUTMSG.
    ELSE.
      P_OUTMSG = 'S:重置清账且冲销成功'.
    ENDIF.
  ELSE.
    P_OUTMSG = 'S:重置清账成功'.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 01.06.2022 09:39:39
********ADD BY DONGPZ BEGIN AT 08.06.2022 20:54:44
*统计某个内表中某个字段值出现了多少次
FORM SHOWCOUNT TABLES INTAB USING P_FIELDNAM P_VALUE P_SHOW
                            CHANGING P_COUNT.
  DATA:IT_INTAB TYPE REF TO DATA,
       WA_INTAB TYPE REF TO DATA.
  DATA:COUNT TYPE POSNR.
  FIELD-SYMBOLS:<FS_INTAB> TYPE TABLE,
                <FS_WA>    TYPE ANY,
                <FS1>      TYPE ANY,
                <FS2>      TYPE ANY.
  CHECK P_FIELDNAM IS NOT INITIAL.
  CLEAR:COUNT,P_COUNT.

  CREATE DATA IT_INTAB LIKE TABLE OF INTAB.
  ASSIGN IT_INTAB->* TO <FS_INTAB>.
  CREATE DATA WA_INTAB LIKE LINE OF <FS_INTAB>.
  ASSIGN WA_INTAB->* TO <FS_WA>.
  APPEND LINES OF INTAB TO <FS_INTAB>.
  ASSIGN COMPONENT P_FIELDNAM OF STRUCTURE <FS_WA> TO <FS1>.
  IF SY-SUBRC NE 0.
    EXIT.
  ENDIF.
  LOOP AT <FS_INTAB> INTO <FS_WA>.
    ASSIGN COMPONENT P_FIELDNAM OF STRUCTURE <FS_WA> TO <FS1>.
    IF SY-SUBRC EQ 0.
      IF <FS1> = P_VALUE.
        ADD 1 TO COUNT.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF COUNT IS INITIAL.
    EXIT.
  ENDIF.
  IF P_SHOW = 'X'.
    MESSAGE I000(OO) WITH '共选中' COUNT '条数据' .
  ELSE.
    P_COUNT = COUNT.
  ENDIF.
ENDFORM.
********ADD BY DONGPZ END AT 08.06.2022 20:54:44
*&---------------------------------------------------------------------*
*&      Form  itabtoclip_alv
*&---------------------------------------------------------------------*
FORM ITABTOCLIP_ALV TABLES ITAB USING WITHHEADER.
  DATA: FLDCAT  TYPE SLIS_T_FIELDCAT_ALV WITH HEADER LINE,
        MARKED  TYPE SLIS_T_FIELDCAT_ALV WITH HEADER LINE,
        ENTRIES TYPE SLIS_T_FILTERED_ENTRIES WITH HEADER LINE.
  DATA: CHARC   TYPE CHAR256,
        CHARSTR TYPE STRING,
        FTYPE .
  DATA: HTAB TYPE C VALUE CL_ABAP_CHAR_UTILITIES=>HORIZONTAL_TAB .
  DATA: LT_CLIP TYPE TABLE OF CHAR2048 WITH HEADER LINE .
  FIELD-SYMBOLS <FS_FLD>.

  CALL FUNCTION 'REUSE_ALV_GRID_LAYOUT_INFO_GET'
    IMPORTING
      ET_FIELDCAT         = FLDCAT[]
      ET_MARKED_COLUMNS   = MARKED[]
      ET_FILTERED_ENTRIES = ENTRIES[]
    EXCEPTIONS
      NO_INFOS            = 1
      PROGRAM_ERROR       = 2
      OTHERS              = 3.
  IF MARKED[] IS INITIAL.
    MARKED[] = FLDCAT[].
    DELETE MARKED WHERE NO_OUT = 'X' OR TECH = 'X'.
  ENDIF.
  SORT ENTRIES.

  CHECK MARKED[] IS NOT INITIAL.
  CHECK ITAB[] IS NOT INITIAL.

  IF WITHHEADER IS NOT INITIAL.
    LOOP AT MARKED.
      CONCATENATE LT_CLIP HTAB MARKED-SELTEXT_L INTO LT_CLIP.
    ENDLOOP.
    IF SY-SUBRC = 0.
      SHIFT LT_CLIP.
      APPEND LT_CLIP.
    ENDIF.
  ENDIF.

  LOOP AT ITAB.
    READ TABLE ENTRIES WITH KEY TABLE_LINE = SY-TABIX BINARY SEARCH.
    CHECK SY-SUBRC <> 0 .

    CLEAR LT_CLIP.
    LOOP AT MARKED.
      ASSIGN COMPONENT MARKED-FIELDNAME OF STRUCTURE ITAB TO <FS_FLD>.
      CHECK SY-SUBRC = 0.

      DESCRIBE FIELD <FS_FLD> TYPE FTYPE.
      CASE FTYPE.
        WHEN 'I' OR 'P' OR 'F' OR 'a' OR 'e' OR 'b' OR 's'.
          CHARC = ABS( <FS_FLD> ).
          CONDENSE CHARC NO-GAPS.
          IF <FS_FLD> < 0.
            CONCATENATE '-' CHARC INTO CHARC.
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'D' OR 'T'.
          IF <FS_FLD> IS INITIAL OR <FS_FLD> = ''.
            CHARC = ''.
          ELSE.
            WRITE <FS_FLD> TO CHARC .
          ENDIF.
          CHARSTR = CHARC.
        WHEN 'X' OR 'y' OR 'g'.
          CHARSTR = <FS_FLD> .
        WHEN OTHERS.
          WRITE <FS_FLD> TO CHARC .
          CHARSTR = CHARC.
      ENDCASE.
      CONCATENATE LT_CLIP HTAB CHARSTR INTO LT_CLIP.
    ENDLOOP.
    SHIFT LT_CLIP.
    APPEND LT_CLIP.
  ENDLOOP.

  CHECK LT_CLIP[] IS NOT INITIAL.
  CALL FUNCTION 'CLPB_EXPORT'
    TABLES
      DATA_TAB   = LT_CLIP
    EXCEPTIONS
      CLPB_ERROR = 01.
  IF SY-SUBRC = 0.
    MESSAGE S000(OO) WITH '已经导出到剪贴板'.
  ELSE.
    MESSAGE E000(OO) WITH '导出到剪贴板错误'.
  ENDIF.
ENDFORM.                    "itabtoclip_alv
*&---------------------------------------------------------------------*
*&      Form  send_sap_user
*&发送SAP快件
*&---------------------------------------------------------------------*
FORM SO01 TABLES MAIL_BODY STRUCTURE SOLISTI1
                  RECV_USER STRUCTURE SSCRUSER
                   USING SUBJECT.
  DATA: LR_EMAIL  TYPE REF TO CL_BCS.
  DATA: LR_BODY   TYPE REF TO CL_DOCUMENT_BCS.
  DATA: LR_SENDER TYPE REF TO CL_SAPUSER_BCS.
  DATA: LR_RECVER TYPE REF TO IF_RECIPIENT_BCS.
  DATA: LR_CXROOT TYPE REF TO CX_ROOT.
  DATA: L_RESULT  TYPE OS_BOOLEAN.
  DATA: L_EXMSG   TYPE STRING.
  DATA: BCS_EXCEPTION      TYPE REF TO CX_BCS.

  TRY.
      LR_EMAIL = CL_BCS=>CREATE_PERSISTENT( ).
      LR_BODY = CL_DOCUMENT_BCS=>CREATE_DOCUMENT(
                                   I_TYPE = 'HTM'
                                   I_TEXT = MAIL_BODY[]
                                   I_SUBJECT = SUBJECT ).
      LR_EMAIL->SET_DOCUMENT( LR_BODY ).

      LR_SENDER = CL_SAPUSER_BCS=>CREATE( SY-UNAME ).
      LR_EMAIL->SET_SENDER( LR_SENDER ).

      LOOP AT RECV_USER.
        LR_RECVER = CL_SAPUSER_BCS=>CREATE( RECV_USER-UNAME ).
        LR_EMAIL->ADD_RECIPIENT( I_RECIPIENT = LR_RECVER I_EXPRESS = 'X' ).
      ENDLOOP.

      LR_EMAIL->SET_SEND_IMMEDIATELY( 'X' ).
      L_RESULT = LR_EMAIL->SEND( I_WITH_ERROR_SCREEN = '' ).
      IF L_RESULT = 'X'.
        COMMIT WORK.
      ENDIF.
    CATCH CX_BCS INTO BCS_EXCEPTION. " cx_root INTO lr_cxroot.
      L_EXMSG = BCS_EXCEPTION->GET_TEXT( ).
  ENDTRY.
ENDFORM.                    "send_sap_user
********ADD BY DONGPZ BEGIN AT 22.08.2022 11:24:14
*保存长文本
FORM SAVETEXT USING ID NAME OBJECT P_TEXT
                   CHANGING P_MSG.
  CLEAR:P_MSG.
  CHECK P_TEXT IS NOT INITIAL
     AND ID IS NOT INITIAL
     AND NAME IS NOT INITIAL
     AND OBJECT IS NOT INITIAL.
  DATA:BEGIN OF TEXT_STREAM OCCURS 0,
         TEXT TYPE CHAR2048,
       END OF TEXT_STREAM,
       HEADER TYPE THEAD,
       LINES  TYPE TABLE OF TLINE WITH HEADER LINE.
  CLEAR:HEADER,LINES[],TEXT_STREAM[],P_MSG.



  HEADER-TDNAME = NAME.
  HEADER-TDID = ID.
  HEADER-TDOBJECT = OBJECT.
  HEADER-TDSPRAS = SY-LANGU.
*切割文本
  CLEAR TEXT_STREAM.
  TEXT_STREAM-TEXT = P_TEXT.
  APPEND TEXT_STREAM.
  CALL FUNCTION 'CONVERT_STREAM_TO_ITF_TEXT'
    TABLES
      TEXT_STREAM = TEXT_STREAM
      ITF_TEXT    = LINES.

  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      HEADER          = HEADER
      SAVEMODE_DIRECT = 'X'
    TABLES
      LINES           = LINES
    EXCEPTIONS
      ID              = 1
      LANGUAGE        = 2
      NAME            = 3
      OBJECT          = 4
      OTHERS          = 5.
  IF SY-SUBRC EQ 0.
    COMMIT WORK AND WAIT.
    P_MSG = 'S:SUCCESS'.
  ELSE.
    PERFORM MSGTOTEXT(ZPUBFORM) USING '' '' '' '' '' ''
          CHANGING P_MSG.
    CONCATENATE 'E:' P_MSG INTO P_MSG.
  ENDIF.

ENDFORM.
********ADD BY DONGPZ END AT 22.08.2022 11:24:14
********ADD BY DONGPZ BEGIN AT 13.10.2022 11:13:46
*获取销售订单的定价过程
FORM GETKALSM USING P_IN_VBAK TYPE VBAK
                    P_KSCHL
              CHANGING P_KALSM.
  DATA:WA_VBAK TYPE VBAK.
  CLEAR:P_KALSM,WA_VBAK.
  CHECK P_IN_VBAK IS NOT INITIAL.
  IF P_IN_VBAK-VBELN IS NOT INITIAL.
    WA_VBAK-VBELN = P_IN_VBAK-VBELN.
    PERFORM ADDZERO(ZPUBFORM) CHANGING WA_VBAK-VBELN.
    SELECT SINGLE *
      INTO WA_VBAK
      FROM VBAK
      WHERE VBELN = WA_VBAK-VBELN.
  ELSE.
    WA_VBAK = P_IN_VBAK.
  ENDIF.
  PERFORM ADDZERO(ZPUBFORM) CHANGING WA_VBAK-KUNNR.
  SELECT SINGLE T683V~KALSM
    INTO P_KALSM
    FROM T683V INNER JOIN KNVV ON T683V~VKORG = KNVV~VKORG
                              AND T683V~VTWEG = KNVV~VTWEG
                              AND T683V~SPART = KNVV~SPART
                              AND T683V~KALKS = KNVV~KALKS
               INNER JOIN TVAK ON T683V~KALVG = TVAK~KALVG
    WHERE T683V~KARTV = P_KSCHL
    AND   T683V~VKORG = WA_VBAK-VKORG
    AND   T683V~VTWEG = WA_VBAK-VTWEG
    AND   T683V~SPART = WA_VBAK-SPART
    AND   TVAK~AUART =  WA_VBAK-AUART
    AND   KNVV~KUNNR =  WA_VBAK-KUNNR.
ENDFORM.
********ADD BY DONGPZ END AT 13.10.2022 11:13:46
********ADD BY DONGPZ BEGIN AT 28.10.2022 08:23:59
*OO-ALV相关
FORM CALLALV TABLES INTAB
              USING P_ALVGRID TYPE REF TO CL_GUI_ALV_GRID
                   P_FIELDCAT TYPE LVC_T_FCAT
                   P_HANDLE.
  DATA: WA_LAYOUTC TYPE LVC_S_LAYO,
        IT_EF1C    TYPE UI_FUNCTIONS,
        VARIANTC   TYPE DISVARIANT.
  CLEAR: IT_EF1C[],WA_LAYOUTC,VARIANTC.
*LAYOUT
  WA_LAYOUTC-CWIDTH_OPT = 'X'.
  WA_LAYOUTC-ZEBRA      = 'X'.
*布局
  VARIANTC-REPORT = SY-REPID.
  VARIANTC-HANDLE = P_HANDLE.

  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_COPY_ROW      TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_DELETE_ROW    TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_APPEND_ROW    TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_INSERT_ROW    TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_MOVE_ROW      TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_CUT           TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_PASTE         TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_PASTE_NEW_ROW TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_COPY          TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_LOC_UNDO          TO IT_EF1C.
  APPEND CL_GUI_ALV_GRID=>MC_FC_REFRESH          TO IT_EF1C.

*ALV展示
  CALL METHOD P_ALVGRID->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      I_SAVE                        = 'A'
      IS_LAYOUT                     = WA_LAYOUTC
      IS_VARIANT                    = VARIANTC
      IT_TOOLBAR_EXCLUDING          = IT_EF1C[]
    CHANGING
      IT_OUTTAB                     = INTAB[]
      IT_FIELDCATALOG               = P_FIELDCAT
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC NE 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
               WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.
FORM REFRESHALV USING P_ALVGRID TYPE REF TO CL_GUI_ALV_GRID.
  DATA:IS_STABLEB TYPE LVC_S_STBL.
  IS_STABLEB-ROW = 'X'.
  IS_STABLEB-COL = 'X'.
  IF P_ALVGRID IS NOT INITIAL.
    CALL METHOD P_ALVGRID->REFRESH_TABLE_DISPLAY
      EXPORTING
        IS_STABLE = IS_STABLEB.
  ENDIF.
ENDFORM.                    " REFRESHALV
FORM FILLFIELDCAT TABLES P_FIELDCAT STRUCTURE LVC_S_FCAT
                   USING P_FIELDNAME P_TEXT P_TAB P_FIELD.
  DATA:WA_FIELDCAT TYPE LVC_S_FCAT.
  CLEAR:WA_FIELDCAT.
  WA_FIELDCAT-FIELDNAME = P_FIELDNAME.
  WA_FIELDCAT-SCRTEXT_M = P_TEXT.
  WA_FIELDCAT-SCRTEXT_L = P_TEXT.
  WA_FIELDCAT-COLTEXT = P_TEXT.
  WA_FIELDCAT-SCRTEXT_S = P_TEXT.
  WA_FIELDCAT-REF_TABLE = P_TAB.
  WA_FIELDCAT-REF_FIELD = P_FIELD.
  IF P_FIELD IS INITIAL.
    WA_FIELDCAT-REF_FIELD = P_FIELDNAME.
  ENDIF.
  IF P_FIELD = 'N'.
    CLEAR:WA_FIELDCAT-REF_FIELD.
  ENDIF.
  CASE P_FIELDNAME.
    WHEN 'CHBOX'.
      WA_FIELDCAT-HOTSPOT   = 'X'.
      WA_FIELDCAT-EDIT   = 'X'.
      WA_FIELDCAT-CHECKBOX   = 'X'.
      WA_FIELDCAT-FIX_COLUMN   = 'X'.
  ENDCASE.

  APPEND WA_FIELDCAT TO P_FIELDCAT.
ENDFORM.                    "FILLFIELDCAT
********ADD BY DONGPZ END AT 28.10.2022 08:23:59
********ADD BY DONGPZ BEGIN AT 04.11.2022 13:57:59