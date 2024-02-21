#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'

WSRESTFUL AppCfgBI02 DESCRIPTION UnEscape("Menus por usuários - PALM")
   WSDATA USERID  As String //Json Recebido no corpo da requição
   WSDATA TOKEN   As String //String que vamos receber via URL
   WSDATA OPER    As String
   WSDATA EMPRESA As String

   WSMETHOD GET DESCRIPTION Unescape("Menus por usuários - PALM") WSSYNTAX "/PALM/v1/AppCfgBI02" //Disponibilizamos um método do tipo GET
END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,EMPRESA WSSERVICE AppCfgBI02
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Private __cUserID := Self:USERID
   _cOper    := If(Empty(Self:OPER),'INI',Self:OPER)
   _cEmpresa := If(Empty(Self:EMPRESA),'',Self:EMPRESA)
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

      _cF3EMP := '/MeliorApp/v1/AppConsPad'
      _cF3EMP += "?CMPRET="   + Escape("{'IDEMPRESA','ALIAS'}")
      _cF3EMP += "&CMPBUSCA=" + Escape("IDEMPRESA+ALIAS")
      _cF3EMP += "&QUERY="    + Escape("Select IDEMPRESA, ALIAS From APPEMPRESAS Where ALIAS <> ''")
      _cF3EMP += "&ORDEM="    + Escape("ALIAS")   
      //_cF3SAI := NoAcento(_cF3SAI)

      _aCampos := {}
      If _cOper == 'INI'
         aAdd(_aCampos, {'search',      'EMPRESA',  'Selecionar Empresas',                300, .T., .T., .F.,  '',               'X',  _cF3EMP,  "", {},,,,,,,.T.})
         _cGatilho := '/MeliorApp/v1/AppGatCFG02'
         _cPesq    := ''
      Else
         _cF3USR := '/MeliorApp/v1/AppConsPad'
         _cF3USR += "?CMPRET="   + Escape("{'IDUSER','LOGIN'}")
         _cF3USR += "&CMPBUSCA=" + Escape("IDUSER+LOGIN")
         _cF3USR += "&QUERY="    + Escape("Select IDUSER, LOGIN From APPUSER Where IDEMPRESA = '"+_cEmpresa+"'")
         _cF3USR += "&ORDEM="    + Escape("LOGIN")   

         _cF3GRP := '/MeliorApp/v1/AppConsPad'
         _cF3GRP += "?CMPRET="   + Escape("{'IDGRUPO','NOMEGRUPO'}")
         _cF3GRP += "&CMPBUSCA=" + Escape("IDGRUPO+NOMEGRUPO")
         _cF3GRP += "&QUERY="    + Escape("Select IDGRUPO, NOMEGRUPO From APPGRUPOUSER Where IDEMPRESA = '"+_cEmpresa+"'")
         _cF3GRP += "&ORDEM="    + Escape("NOMEGRUPO")   

      _cQuery := "Select IDEMPRESA, ALIAS From APPEMPRESAS Where IDEMPRESA = '"+_cEmpresa+"'"
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_EMP",.F.,.T.)
      _cAlias := _EMP->ALIAS
      _EMP->(DbCloseArea())

         aAdd(_aCampos, {'textfield',          'EMPRESA',    'Empresa',                                    30, .T., .F., .F.,  _cEmpresa+' - '+_cAlias,   'X',  '',  "", {}})
         aAdd(_aCampos, {'multisearch',        'GRUPOS',     'Usuários dos Grupos (vazio p/todos)',       300, .F., .T., .F.,  '',   'X',  _cF3GRP,  "", {}})
         aAdd(_aCampos, {'multisearch',        'USUARIOS',   'Usuários (vazio p/todos)',                  300, .F., .T., .F.,  '',   'X',  _cF3USR,  "", {}})
         _cGatilho := ''
         _cPesq    := '/PALM/v1/AppCfgBI2Br'
      EndIf   

      If _cOper == 'INI'
         _cJson := u_JsonEdit('Filtro \nMenus X Usuários',  _cGatilho, _cPesq, _aCampos)
      Else
         _cJson := u_JsonFilter('Filtro \nMenus X Usuários', _cGatilho, _cPesq, _aCampos)
      EndIf   
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
WSRESTFUL AppCfgBI2Br DESCRIPTION "Consulta Menus X Usuários - PALM"
   WSDATA USERID     As String //Json Recebido no corpo da requição
   WSDATA TOKEN      As String //String que vamos receber via URL
   WSDATA GRUPOS     As String
   WSDATA USUARIOS   As String 
   WSDATA DEVICEID   As String
   WSDATA EMPRESA
   WSMETHOD GET DESCRIPTION "Consulta Menus X Usuários - PALM" WSSYNTAX "/PALM/v1/AppCfgBI2Br" //Disponibilizamos um método do tipo GET
END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,USUARIOS,GRUPOS,EMPRESA,DEVICEID  WSSERVICE AppCfgBI2Br
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Local _nI 
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cUsers   := If(EMpty(Self:USUARIOS) .Or. Self:USUARIOS=='null', '',      Self:USUARIOS)
   _cGrps    := If(EMpty(Self:GRUPOS) .Or. Self:GRUPOS=='null', '',        Self:GRUPOS)
   _cEmpresa := Left(Self:EMPRESA, 6)
   _cErro    := ''
   _lWeb     := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]
      SetRestFault(401, _cErro)
   EndIf
   _cAlias := _aToken[7]

   _cUsuarios := u_Search2Sql(_cUsers, 6)
   _cGrupos   := u_Search2Sql(_cGrps,  3)

   _T := GetMV('ME_PREF_RD',.F.,'ZZ1')
   _cQuery := "Select ALIAS, EMP.IDEMPRESA, LOGIN, NOME, Isnull(MODAL,'') MODAL, DATALOGIN, TIPOLOGIN, IDUSER, IDERP, IsNull(NOMEGRUPO, '') GRUPO, USR.IDMENU, USR.EMAIL"+Chr(13)+Chr(10)
   _cQuery += "	From APPEMPRESAS EMP, APPUSER USR"+Chr(13)+Chr(10)
   _cQuery += "   	Left outer join APPGRUPOUSER GRP On  GRP.IDGRUPO = USR.IDGRUPO and GRP.IDEMPRESA = USR.IDEMPRESA"+Chr(13)+Chr(10)
   _cQuery += "	Where EMP.IDEMPRESA = '"+_cEmpresa+"' And "
   If Len(_cUsers) > 2
      _cQuery += "      USR.IDUSER In ("+_cUsuarios+") And"+Chr(13)+Chr(10)
   EndIf   
   If Len(_cGrps) > 2
      _cQuery += "      USR.IDGRUPO In ("+_cGrupos+") And"+Chr(13)+Chr(10)
   EndIf   
   _cQuery += "		EMP.IDEMPRESA = USR.IDEMPRESA AND SENHA <> '!BLOQUEADO'"+Chr(13)+Chr(10)
   _cQuery += "		ORDER By ALIAS, LOGIN"+Chr(13)+Chr(10)
   DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_T",.F.,.T.)
   conout(_cQuery)

   _cMap   := '"Sequencia","Empresa","Login","Nome","Modalidade","Último Login","Tipo User","ID no ERP","ID User","Grupo","ID.Menu","Acesso","E-mail"'+Chr(13)+Chr(10)
   _nCount := 0
   Do While !_T->(EoF())
      _cTipo  := 'Usuário Protheus'
      _cModal := If(Empty(_T->MODAL),'Geral',_T->MODAL)

      _cMenus := _T->IDMENU
      If Empty(_cMenus) 
         If !Empty(_T->GRUPO)
            _cQuery := "Select IDMENU From APPGRUPOUSER Where IDGRUPO = '"+_T->GRUPO+"' And IDEMPRESA = '"+_cEmpresa+"'"
            DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_GRP",.F.,.T.)
            _cMnuGrupo := _GRP->IDMENU
            _GRP->(DbCloseARea())
            _aMenus := {AllTrim(_cMnuGrupo)}
         EndIf
         // Trata Menu do Grupo
      Else
         If !'###' $ _cMenus
            _aMenus := {AllTrim(_cMenus)}
         Else   
            _aMenus := Separa(_cMenus, '###')
         EndIf   
      EndIf

      For _nI := 1 To Len(_aMenus)
          _cQuery := "Select IDMENU, DESCRICAO, ORDEM, TITULO, ENDPOINT From APPMENU "
          _cQuery += "	Where IDMENU = '"+AllTrim(_aMenus[_nI])+"' And VISIVEL = 'S' "
          _cQuery += "	Order By ORDEM"
          DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_MNU",.F.,.T.)
          If _MNU->(EoF())
             _cMap += _T->('"'+AllTrim(Str(++_nCount))+'","'+ALIAS+'","'+LOGIN+'","'+NOME+'","'+_cModal+'","'+DtoC(StoD(DATALOGIN))+'","'+_cTipo+'","'+IDERP+'","'+IDUSER+'","'+GRUPO+'","SEM MENU RELACIONADO","","'+EMAIL+'"'+Chr(13)+Chr(10))
          Else
             Do While !_MNU->(EoF())
                If Empty(_MNU->ENDPOINT)
                   _cAcesso := '-> '+AllTrim(_MNU->TITULO)
                Else
                   _cAcesso := '    '+AllTrim(_MNU->TITULO)+' ['+AllTrim(_MNU->ENDPOINT)+']'
                EndIf   
                _cMap += _T->('"'+AllTrim(Str(++_nCount))+'","'+ALIAS+'","'+LOGIN+'","'+NOME+'","'+_cModal+'","'+DtoC(StoD(DATALOGIN))+'","'+_cTipo+'","'+IDERP+'","'+IDUSER+'","'+GRUPO+'","'+AllTrim(_MNU->IDMENU)+'-'+AllTrim(_MNU->DESCRICAO)+'","'+_cAcesso+'","'+EMAIL+'"'++Chr(13)+Chr(10))
                _MNU->(DbSkip())
             EndDo   
          EndIf   
          _MNU->(DbCloseARea())
      Next    
      _T->(DbSkip())
   EndDo
   _T->(DbCloseARea())

   FErase('\web\graficos\mapMENU.CSV')
   Memowrite('\web\graficos\mapMENU.CSV', EncodeUtf8(_cMap))

   If !_lErro
      _cTit  := "Consulta Menus X Usuários"
      _cUrl  := "http://server.palmapp.com.br:8090/graficos/palmpivotMENU.html"
      //_cUrl  := "http://server.palmapp.com.br:8092/graficos/palmpivotRDV.html"
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

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* Gatilho Menus X Usuário
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppGatCFG02 DESCRIPTION "Gatilho de Menus X Usuarios - Palm"
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA GRUPO  As String //String que vamos receber via URL

   WSMETHOD POST DESCRIPTION "Gatilho de Menus X Usuarios" WSSYNTAX "/PALM/v1/AppGatCFG02" //Disponibilizamos um método do tipo GET
END WSRESTFUL

WSMETHOD POST WSRECEIVE userID,token,GRUPO WSSERVICE AppGatCFG02
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cErro    := ''

   //Conout(cJSON)
   oParseJSON := Nil
   ::SetContentType("application/json")
   FWJsonDeserialize(DecodeUtf8(cJson),@oParseJSON)
   _cJson := ''

   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf

   If oParseJSON:TRIGGER == 'EMPRESA' 
      _cQuery := "Select IDEMPRESA, ALIAS From APPEMPRESAS Where IDEMPRESA = '"+oParseJson:valores:EMPRESA+"'"
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_EMP",.F.,.T.)
      _cEmp := _EMP->IDEMPRESA
      _EMP->(DbCloseArea())

      If Empty(_cEmp)
         _cJson := u_JsonMsg("Erro de Empresa", "A empresa selecionada não foi encontrada!", "alert", .F.,'5000')
      Else
         _cJson := u_JsonMsg("Empresa OK", "Carregando dados da empresa selecionada!", "success", .F.,'1000',,'/PALM/v1/AppCfgBI02?OPER=USER&EMPRESA='+_cEmp)
      EndIf   
      ::SetResponse(NoAcento(_cJSON))
      _lRet := .T.
   EndIf

   Return(_lRet)
//
