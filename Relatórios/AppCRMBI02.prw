#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'

WSRESTFUL AppCRMBI02 DESCRIPTION UnEscape("Pivot Table - Projetos - PALM")
WSDATA USERID As String //Json Recebido no corpo da requição
WSDATA TOKEN  As String //String que vamos receber via URL

WSMETHOD GET DESCRIPTION Unescape("Pivot Table- Projetos  - PALM") WSSYNTAX "/PALM/v1/AppCRMBI02" //Disponibilizamos um método do tipo GET
END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token WSSERVICE AppCRMBI02
Local _lRet		  := .T.
Local _lErro      := .F.
Private __cUserID := Self:USERID
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
EndIf

If !_lErro
   // Valida  User
   /*
   PswOrder(1)      
   If !(  PswSeek(__cUserId, .T.) )
      _lErro := .T.
      _cErro += ' Usuario nao encontrado!'
   EndIf
   */
   _cGatilho := '/MeliorApp/v1/AppGatilho'
   //_cGatilho += "?CMPRET="   + Escape("{{'C1_DESCRI','B1_DESC'},{'C1_UM','B1_UM'},{'C1_SEGUM','B1_SEGUM'},{'C1_CONTA','B1_CONTA'},{'C1_CC','B1_CC'},{'C1_ITEMCTA','B1_ITEMCC'},{'C1_CLVL','B1_CLVL'}}")
   _cGatilho += "?CMPRET="   + Escape("{{'COD_DE','B1_COD'},{'COD_ATE','B1_COD'},{'DESC_DE','B1_DESC'},{'DESC_ATE','B1_DESC'}}")
   _cGatilho += "&CMPBUSCA=" + Escape("B1_CODBAR")
   _cGatilho += "&QUERY="    + Escape("Select B1_COD, B1_DESC From "+RetSqlName('SB1')+" Where B1_FILIAL = '"+xFilial('SB1')+"' And D_E_L_E_T_ = ''")

   _cF3SB1A := '/MeliorApp/v1/AppConsPad'
   _cF3SB1A += "?CMPRET="   + Escape("{'B1_COD','B1_DESC'}")
   _cF3SB1A += "&CMPBUSCA=" + Escape("B1_COD+B1_DESC")
   _cF3SB1A += "&QUERY="    + Escape("Select Top 100 B1_DESC, B1_COD From "+RetSqlName('SB1')+" Where B1_FILIAL = '"+xFilial('SB1')+"' And D_E_L_E_T_ = '' And B1_TIPO = 'PA'")
   _cF3SB1A += "&ORDEM="    + Escape("B1_DESC")   
   _cF3SB1A := NoAcento(_cF3SB1A)

   _cF3SA3 := '/MeliorApp/v1/AppConsPad'
   _cF3SA3 += "?CMPRET="   + Escape("{'A3_COD','A3_NOME'}")
   _cF3SA3 += "&CMPBUSCA=" + Escape("A3_COD+A3_NOME")
   _cF3SA3 += "&QUERY="    + Escape("Select A3_NOME, A3_COD From "+RetSqlName('SA3')+" Where D_E_L_E_T_ = ''")
   _cF3SA3 += "&ORDEM="    + Escape("A3_NOME")
   _cF3SA3 := NoAcento(_cF3SA3)

   _aCampos := {}
   aAdd(_aCampos, {'search',      'COD_DE',    'Produto Acabado Inicial',   TAMSX3("B1_COD")[1],     .T., .T., .F.,  Space(TAMSX3("B1_COD")[1]),       'X',  _cF3SB1A,  "", {}})
   aAdd(_aCampos, {'search',      'COD_ATE',   'Produto Acabado Final',     TAMSX3("B1_COD")[1],     .T., .T., .F.,  'ZZZZZZZZZZ',       'X',  _cF3SB1A,  "", {}})
   aAdd(_aCampos, {'divider'})
   aAdd(_aCampos, {'date',        'DATA_DE',   'Data Projeto Inicial',   10, .F., .T., .F.,  (dDataBase-30),      'X',  '',  "", {}})
   aAdd(_aCampos, {'date',        'DATA_ATE',  'Data Projeto Final',     10, .F., .T., .F.,  (dDataBase),      'X',  '',  "", {}})
   aAdd(_aCampos, {'divider'})
   aAdd(_aCampos, {'dropdown',    'UNIDADE',   'Unidade de Negócio',         06, .T., .T., .F.,  '',       'X',  '',  "", {{'1000','BAKERY'},{'2000','DAIRY'},{'3000','SPECIALTIES'},{'9999','OUTROS'},{'XXXX','TODOS'}}})
   aAdd(_aCampos, {'multisearch', 'VENDEDORES','Vendedores',                300, .T., .T., .F.,  '',       'X',  _cF3SA3,  "", {}})

   //_cJson := u_JsonFilter('Filtro de Produtos', _cGatilho, '/meliorApp/v1/AppCD01Brw', _aCampos)
   _cJson := u_JsonFilter('Filtro de Projetos', _cGatilho, Escape('/PALM/v1/AppCRMBI2Brw'), _aCampos)
   MemoWrite('Filter.json', _cJson)
   ::SetResponse(NoAcento(_cJSON))
   lRet := .T.		
EndIf

If _lErro
   SetRestFault(400, _cErro)
   //Conout(_cErro)
   _lRet := .F.
EndIf

Return(_lRet)


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppCD01Brw - Browse de Produtos
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCRMBI2Brw DESCRIPTION UnEscape("consulta Produto com foto - MeliorApp")
WSDATA USERID As String //Json Recebido no corpo da requição
WSDATA TOKEN  As String //String que vamos receber via URL
WSDATA COD_DE    As String
WSDATA COD_ATE   As String
WSDATA DATA_DE   As String
WSDATA DATA_ATE  As String 
WSDATA UNIDADE   As String 
WSDATA VENDEDORES As String 
WSMETHOD GET DESCRIPTION Unescape("Consulta Produto com foto") WSSYNTAX "/PALM/v1/AppCRMBI2Brw" //Disponibilizamos um método do tipo GET
END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,COD_DE,COD_ATE,DATA_DE,DATA_ATE,UNIDADE,VENDEDORES  WSSERVICE AppCRMBI2Brw
Local _lRet		  := .T.
Local _lErro      := .F.
Local __cUserID   := Self:USERID
Local _cToken     := Self:TOKEN
_dIni := CtoD(Self:DATA_DE)
_dFim := CtoD(Self:DATA_ATE)
_cProdIni := Self:COD_DE
_cProdFim := Self:COD_ATE
_cUnid := If(EMpty(Self:UNIDADE), '', Self:UNIDADE)
If Empty(_cProdIni); _cProdIni := ''; EndIf
If Empty(_cProdFim); _cProdFim := 'ZZZZZZZZZZZZZ'; EndIf
_cErro := ''

// Valida token
/*
_aToken := u_ValidToken(_cToken)
If !_aToken[1] 
   _lErro := .T.
   _cErro += _aToken[2]

   SetRestFault(401, _cErro)
EndIf
_cAlias := _aToken[7]
*/

_cQuery := "Select AD1_FILIAL, AD1_NROPOR, AD1_PROSPE, AD1_LOJPRO, AD1_CODCLI, AD1_LOJCLI, AD1_CANAL, ADK_NOME, AD1_MOEDA, AD1_VEND, AD1_DATA, AD1_STAGE, AD1_PROVEN,"
_cQuery += "	ADJ_PROD, B1_DESC, ADJ_QUANT, ADJ_PRUNIT, ADJ_VALOR, AD1_RCFECH, SubString(AD1_DATA,5,2) As MES, A3_NOME"
_cQuery += "	From "+RetSqlName('AD1')+" AD1"
_cQuery += "	Inner Join "+RetSqlName('ADJ')+" ADJ On ADJ_FILIAL=AD1_FILIAL And ADJ_NROPOR=AD1_NROPOR And ADJ_REVISA=AD1_REVISA And ADJ.D_E_L_E_T_ = ''			"
_cQuery += "	Inner Join "+RetSqlName('SB1')+" SB1 On B1_COD=ADJ_PROD And SB1.D_E_L_E_T_ = '' "
_cQuery += "	Inner Join "+RetSqlName('ADK')+" ADK On ADK_COD=AD1_CANAL And ADK.D_E_L_E_T_ = ''"
_cQuery += "   Inner Join "+RetSqlName('SA3')+" SA3 On A3_COD = AD1_VEND And SA3.D_E_L_E_T_ = '' "
_cQuery += "	Where AD1_CANAL <> 'XXXXX' And "
_cQuery += "	   AD1_DATA Between '"+DtoS(_dIni)+"' And '"+DtoS(_dFim)+"' And"
_cQuery += "		AD1.D_E_L_E_T_ = ''"
DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_AD1",.F.,.T.)
//conout(_cQuery)

_cMap := '"PROJETO","PRODUTO","DESCRICAO","EMISSAO", "QUANTIDADE", "PRC.UNITARIO", "TOTAL", "VENDEDOR", "UNIDADE", "MES", "PROSPECT", "CLIENTE"'+Chr(13)+Chr(10)
Do While !EoF()
   If !Empty(_AD1->AD1_PROSPE)
      SUS->(DbSeek(xFilial('SUS')+_AD1->(AD1_PROSPE+AD1_LOJPRO)))
      _cCliente  := ''
      _cProspect := AllTrim(SUS->US_NREDUZ)
   Else
      SA1->(DbSeek(xFilial('SA1')+_AD1->(AD1_CODCLI+AD1_LOJCLI)))
      _cCliente  := AllTrim(SA1->A1_NREDUZ)
      _cProspect := ''
   EndIf
   _cMap += '"'+_AD1->AD1_NROPOR+'","'+AllTrim(_AD1->ADJ_PROD)+'","'+AllTrim(NoAcento(_AD1->B1_DESC))+'","'+DtoC(StoD(_AD1->AD1_DATA))+'",'+AllTrim(Str(_AD1->ADJ_QUANT))+','+AllTrim(Str(_AD1->ADJ_PRUNIT))+','+;
            AllTrim(Str(_AD1->ADJ_VALOR))+','+AllTrim(_AD1->A3_NOME)+','+AllTrim(_AD1->ADK_NOME)+','+_AD1->MES+','+_cProspect+','+_cCliente+Chr(13)+Chr(10)
   _AD1->(DbSkip())
EndDo
_AD1->(DbCloseARea())

FErase('\web\graficos\mapPRJ.CSV')
Memowrite('\web\graficos\mapPRJ.CSV', _cMap)

If !_lErro
   _cTit  := "Consulta dados de Projetos"
   _cUrl  := "http://200.155.14.162:8087/graficos/palmpivotPRJ.html"
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
