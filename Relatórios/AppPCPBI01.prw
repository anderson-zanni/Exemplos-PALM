#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'

WSRESTFUL AppPCPBI01 DESCRIPTION UnEscape("Pivot Table - PCP - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA DEVICEID   As String //String que vamos receber via URL

   WSMETHOD GET DESCRIPTION Unescape("Pivot Table - PCP - PALM") WSSYNTAX "/PALM/v1/AppPCPBI01" //Disponibilizamos um método do tipo GET
END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,DEVICEID WSSERVICE AppPCPBI01
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Private __cUserID := Self:USERID
   _lWeb       := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)
   _cToken   := Self:TOKEN
   _cErro := ''
   If Type('__cUserID') <> 'C'
      _lErro := .T.
      _cErro += ' Variavel "userID" nao informada!'   
   EndIf
   If !_lErro .and. Type('_cToken') <> 'C'
      _lErro := .T.
      _cErro += ' Token de validacao nao informada!'   
   EndIf

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf

   If !_lErro
      _cGatilho := '/MeliorApp/v1/AppGatilho'

      _cF3SAI := '/MeliorApp/v1/AppConsPad'
      _cF3SAI += "?CMPRET="   + Escape("{'AI_USER','AI_XNOME'}")
      _cF3SAI += "&CMPBUSCA=" + Escape("AI_USER+AI_XNOME")
      _cF3SAI += "&QUERY="    + Escape("Select AI_USER, AI_XNOME From "+RetSqlName('SAI')+" Where AI_FILIAL = '"+xFilial('SAI')+"' And D_E_L_E_T_ = ''")
      _cF3SAI += "&ORDEM="    + Escape("AI_XNOME")   

      _cQueryBrw := "Select CODIGO, ORDEM, NOME, LOC_PROC, CORHEXA, ICONE, ATIVO, VISIVEL, OPERACAO, OBSERVACAO, STAT_ICONE"+Chr(13)+Chr(10)
      _cQueryBrw += "	From APPPLANTAS "+Chr(13)+Chr(10)
      _cQueryBrw += "	Where VISIVEL = 'S' And ATIVO = 'S'"+Chr(13)+Chr(10)
      _cQueryBrw += "	Order By CODIGO"+Chr(13)+Chr(10)
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryBrw),"_PLANTA",.F.,.T.)      
      _aOperacao := {}
      Do While !EoF()
         _PLANTA->(aAdd(_aOperacao, {OPERACAO,  OPERACAO+" - "+AllTrim(NOME)}))
         _PLANTA->(DbSkip())
      EndDo
      _PLANTA->(DbCloseArea())      

     // _aOperacao          := {{"1","Pago pelo Fornecedor"},{"2","Financiado ao Comprador"}}
      _cOperacao := ""
      _aCampos := {}
      
      aAdd(_aCampos, {'date',        'DATA_DE',   'Data Inicial PCP',                  10, .F., .T., .F.,  (dDataBase-07),   'X',  '',  "", {}})
      aAdd(_aCampos, {'date',        'DATA_ATE',  'Data Final PCP',                    10, .F., .T., .F.,  (dDataBase),      'X',  '',  "", {}})
      aAdd(_aCampos, {'dropdown',    'OPERACAO',  'Operação',                          02,      If(_lWeb,45,.F.), .T., .F., _cOperacao,      'X',  '',  '', _aOperacao}) 

      //_cJson := u_JsonFilter('Filtro de Produtos', _cGatilho, '/meliorApp/v1/AppCD01Brw', _aCampos)
      _cJson := u_JsonFilter('Filtro \nConsulta PCP', _cGatilho, Escape('/PALM/v1/AppPCPBI1Br'), _aCampos)
      MemoWrite('Filter.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.		
   EndIf

   If _lErro
      SetRestFault(400, _cErro)
      //Conout(_cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppCD01Brw - Browse de Produtos
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppPCPBI1Br DESCRIPTION "Consulta PCP - PALM"
   WSDATA USERID     As String //Json Recebido no corpo da requição
   WSDATA TOKEN      As String //String que vamos receber via URL
   WSDATA DATA_DE    As String
   WSDATA DATA_ATE   As String 
   WSDATA DEVICEID   As String
   WSDATA OPERACAO       As String
   WSMETHOD GET DESCRIPTION "Consulta PCP - PALM" WSSYNTAX "/PALM/v1/AppPCPBI1Br" //Disponibilizamos um método do tipo GET
END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,DATA_DE,DATA_ATE,OPERACAO,DEVICEID  WSSERVICE AppPCPBI1Br
   Local _lRet		  := .T.
   Local _lErro      := .F.
   __cUserID   := Self:USERID
   _cToken     := Self:TOKEN
   _dIni     := CtoD(Self:DATA_DE)
   _dFim     := CtoD(Self:DATA_ATE)
   _cOperacao  := If(EMpty(Self:OPERACAO), '',      Self:OPERACAO)
   _cErro := ''
   _lWeb     := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

   If !_lWeb
   EndIf

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]
      SetRestFault(401, _cErro)
   EndIf
   _cAlias := _aToken[7]
   //_cUserSql := u_Search2Sql(_cSolics, 6)
  
   _cQuery := " SELECT SUBSTRING(CBH_DTINI,1,4) Ano,SUBSTRING(CBH_DTINI,5,2) Mes,CBH_OPERAC OPERACAO,NOME,SUBSTRING(CBH_DTINI,7,2) DIA,SUM(CBH_QEPREV) CBH_QEPREV "
   _cQuery += "         ,CBH_OP,CB1_NOME,B1_DESC  " 
   _cQuery += "    FROM "+RetSqlName("CBH")+" CBH "
   _cQuery += " INNER JOIN APPPLANTAS ON OPERACAO=CBH_OPERAC" 
   _cQuery += " LEFT JOIN "+RetSqlName("CB1")+" CB1 ON CBH_OPERAD=CB1_CODOPE AND CB1.D_E_L_E_T_='' "
   _cQuery += " INNER JOIN "+RetSqlName("SC2")+" SC2 ON  SC2.D_E_L_E_T_='' AND CBH_OP=C2_NUM+C2_ITEM+C2_SEQUEN "
   _cQuery += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON  SB1.D_E_L_E_T_='' AND B1_COD=C2_PRODUTO "

   _cQuery += " WHERE CBH.D_E_L_E_T_='' AND CBH_DTINI BETWEEN '"+DTOS(_dIni)+"' AND '"+DTOS(_dFim)+"' "
   If !Empty(_cOperacao)
      _cQuery += " And CBH_OPERAC='"+_cOperacao+"' "
   EndIf
   _cQuery += " GROUP By SUBSTRING(CBH_DTINI,1,4),SUBSTRING(CBH_DTINI,5,2),SUBSTRING(CBH_DTINI,7,2) ,CBH_OPERAC,NOME,CBH_OP,CB1_NOME  ,B1_DESC"



   DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_TMP",.F.,.T.)
   conout(_cQuery)

   _cMap := '"Operacao","Desc Operacao","Quantidade","Ano","Mes","Dia","OP","Desc Produto","Operador"'+Chr(13)+Chr(10)
   Do While !_TMP->(EoF())

      _cMap += '"'+_TMP->OPERACAO+'","'+_TMP->NOME+'",'+AllTrim(Str(_TMP->CBH_QEPREV))+',"'+_TMP->ANO+'","'+_TMP->MES+'","'+_TMP->DIA+'","'+_TMP->CBH_OP+'","'+_TMP->B1_DESC+'","'+_TMP->CB1_NOME+'"'+Chr(13)+Chr(10)

      _TMP->(DbSkip())
   EndDo
   _TMP->(DbCloseARea())

   FErase('\web\graficos\mapPCP.CSV')
   Memowrite('\web\graficos\mapPCP.CSV', EncodeUtf8(_cMap))

   If !_lErro
      _cTit  := "Consulta PCP Operacoes"
      _cHttp := GetMV('APP_HTTP',.F.,"http://132.226.254.65:5534")
      _cUrl  := _cHttp+"/graficos/palmpivotPCP.html"
      _cJSON := U_JsonWView(_cTit, '', _cUrl, .T.)
      Memowrite('WebView.json', _cJson)
      Conout(_cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      Return .T.	
   Else
      Conout('Erro')
   EndIf

   If _lErro
      SetRestFault(400, _cErro)
      //Conout(_cErro)
      _lRet := .F.
   EndIf

   Return _lRet
//
