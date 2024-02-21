#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'

WSRESTFUL AppJUR01 DESCRIPTION UnEscape("Registro Disciplinar - MeliorApp")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA DEVICEID  As String //String que vamos receber via URL

   WSMETHOD GET DESCRIPTION Unescape("Registro Disciplinar") WSSYNTAX "/PALM/v1/AppJUR01" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,DEVICEID WSSERVICE AppJUR01
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Private __cUserID := Self:USERID
   _lWeb     := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

   _cToken   := Self:TOKEN
   _cErro := ''

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]
      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := AllTRim(_aToken[4])
   _cAlias    := AllTrim(_aToken[7])

   Conout('[PALM] Registro Disciplinares - Filtro: '+_cNomeUser)
   If !_lErro
      _aCampos := {}

      _cF3SA1 := '/PALM/v1/AppConsPad'
      _cF3SA1 += "?CMPRET="   + Escape("{'A1_COD','A1_NREDUZ'}")
      _cF3SA1 += "&CMPBUSCA=" + Escape("A1_COD+A1_NREDUZ")
      _cF3SA1 += "&QUERY="    + Escape("Select Top 200 A1_COD, A1_NREDUZ, A1_NOME From "+RetSqlName('SA1')+" Where D_E_L_E_T_ = ''")
      _cF3SA1 += "&ORDEM="    + Escape("A1_NREDUZ") 

      aAdd(_aCampos, {'date',       'DATA_DE',   'Ocorrência Inicial',                  10, If(_lWeb,10,.F.), .T., .T.,  (dDataBase-60),      'X',  '',  "", {}})
      aAdd(_aCampos, {'date',       'DATA_ATE',  'Ocorrência Final',                    10, If(_lWeb,10,.F.), .T., .T.,  (dDataBase),         'X',  '',  "", {}})
      aAdd(_aCampos, {'multisearch','CLIENTES',  'Filtrar Associados (Vazio p/ todos)',200, If(_lWeb,34,.T.), .T., .F.,  '',                  'X',  _cF3SA1,"", {}})
      aAdd(_aCampos, {'radio',      'TIPO',      'Tipo de Registro',                     1, If(_lWeb,25,.T.), .T., .T.,  'T',                 'X',     '',  "", {{'A','Aberto'},{'P','Pendentes'},{'T','Todos'}}})      

      _cJson := u_JsonFilter(If(_lWeb,'Filtro de Registros de infrações Disciplinares','Filtro de Registros Disciplinares'), '', '/PALM/v1/AppJur01Brw', _aCampos)

      MemoWrite('Filter.json', _cJson)
      ::SetResponse(EncodeUtf8(_cJSON))
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
/* AppJUR01BRW - Browse de Registros Disciplinares
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppJur01BRW DESCRIPTION UnEscape("Browse de Registros Disciplinares - PALM")
   WSDATA USERID   As String //Json Recebido no corpo da requição
   WSDATA TOKEN    As String //String que vamos receber via URL
   WSDATA DEVICEID As String //String que vamos receber via URL
   WSDATA DATA_DE  As String //String que vamos receber via URL
   WSDATA DATA_ATE As String //String que vamos receber via URL
   WSDATA CLIENTES As String //String que vamos receber via URL
   WSDATA TIPO     As String //String que vamos receber via URL

   WSMETHOD GET DESCRIPTION Unescape("Browse de Registros Disciplinares - PALM") WSSYNTAX "/PALM/v1/AppJur01BRW" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,DEVICEID,DATA_DE,DATA_ATE,CLIENTES,TIPO WSSERVICE AppJur01BRW
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Private __cUserID := Self:USERID
   Private _dIni     := If(Empty(Self:DATA_DE),  ((dDataBase-90)), CtoD(Self:DATA_DE))
   Private _dFim     := If(Empty(Self:DATA_ATE), ((dDataBase)),    CtoD(Self:DATA_ATE))
   Private _cCliente := If(Empty(Self:CLIENTES), '', Self:CLIENTES)
   Private _cTipo    := If(Empty(Self:TIPO), 'T', Self:TIPO)
   Private _aCampos := {}
	_lWeb     := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)
   _cToken   := Self:TOKEN
   _cErro := ''

   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cAlias     := ALlTrim(_aToken[7])
   _cNomeUser  := _aToken[4]
   _cGrupo     := AllTrim(_aToken[11])


   Conout('[PALM] Registro Disciplinares - Browse: '+_cNomeUser)
   If !_lErro
      _cQuerySZ0 := "Select Z4_REGISTR REGISTRO, Z4_DATA DTOCORRE, Z4_HORA HROCORRE, Z4_AREA AREA, Z4_LOCAL CODLOCAL, Z4_DTREG DTREG, Z4_HRREG HRREG, Z2_DESC TIPO, Z3_DESC SUBTIPO, Z4_DESC DESCRICAO, Z4_DETALHE DETALHE,"+Chr(13)+Chr(10)
      _cQuerySZ0 += "       Z4_REVISAO REVISAO, Z4_ACAO ACAO, Z4_COMISSA COMISSAO, Z4_STATUS STATUS, Z4_USER, A1_NOME"+Chr(13)+Chr(10)
      _cQuerySZ0 += "	From "+RetSqlName('SZ4')+" SZ4"+Chr(13)+Chr(10)
      _cQuerySZ0 += "	Inner Join "+RetSqlName('SA1')+" SA1 On A1_COD     = Z4_SOCIO And SA1.D_E_L_E_T_  = ''"+Chr(13)+Chr(10)
      _cQuerySZ0 += "	Inner Join "+RetSqlName('SZ0')+" SZ0 On Z0_CODLOC  = Z4_LOCAL And SZ0.D_E_L_E_T_  = ''"+Chr(13)+Chr(10)
      _cQuerySZ0 += "	Inner Join "+RetSqlName('SZ2')+" SZ2 On Z2_CODIGO  = Z4_TIPO And SZ2.D_E_L_E_T_  = ''"+Chr(13)+Chr(10)
      _cQuerySZ0 += "	Inner Join "+RetSqlName('SZ3')+" SZ3 On Z3_SUBTIPO = Z4_SUBTIPO And Z3_TIPO = Z4_TIPO And SZ3.D_E_L_E_T_  = ''"+Chr(13)+Chr(10)
      _cQuerySZ0 += "    Where Z4_DATA Between '"+DtoS(_dIni)+"' And '"+DtoS(_dFim)+"' And "+Chr(13)+Chr(10)
      If _cTipo <> 'T'
         If _cTipo == 'A'
            _cQuerySZ0 += "      Z4_STATUS In ('A',' ') And "+Chr(13)+Chr(10)
         Else
            _cQuerySZ0 += "      Z4_STATUS = '"+_cTipo+"' And "+Chr(13)+Chr(10)
         EndIf   
      EndIf
      _cQuerySZ0 += "   		  SZ4.D_E_L_E_T_ = '' "+Chr(13)+Chr(10)
      _cQuerySZ0 += "   Order By Z4_DATA, Z4_HORA"+Chr(13)+Chr(10)
      //conout(_cQuerySZ0)
      _aCampos:= {}
      // STATUS
      // ' '=Iniciado 'P'=Pendente/Andamento  'E'=Encerrado
      _aCab   := {{'icons',{{u_Icone("incluir"),"/PALM/v1/AppJur01Add?OPER=LIMPAR",,"Incluir registro",.T.,.T.,,.T.}}},;
                    '', 'Número\nRegistro','Associado','Usuário\nAbertura','Data\nOcorrência','Descrição','Área','Última\nInteração',''}
      _aItens := {{'icons',{{'u_Icone(If(STATUS=="E","verde",If(STATUS="P","amarelopisca","cinza")))','"PALM/v1/AppJUR01Add?OPER=ALT&ID="+REGISTRO',,'If(STATUS=="E","Registro Finalizado",If(STATUS="P","Registro com interação","Registro ainda\nsem interação"))',.T.,.F.,,.T.},;
                              {'"http://server.palmapp.com.br:8090/imagens/'+_cAlias+'/"+Z4_USER+".jpg"', '','','',.F.,.F.}}},;
                  {'icons',{{"If(Z4_USER=='"+__cUserID+"'.and.STATUS$' ',  u_Icone('excluir'),'')", '"/PALM/v1/AppJur01Add?OPER=EXC&ID="+REGISTRO','Excluir registro?','Excluir registro',.F.,.T.,,.T.},;
                            {"If("+If(_cGrupo=='CONSELHO','.T.','.F.')+".and.STATUS$' .P',u_Icone('alterapreto'),'')", '"/PALM/v1/AppJur01Int?OPER=LIMPAR&ID="+REGISTRO',,'Interagir no registro',.T.,.T.,,.T.}}},;                              
                  {'text','AllTrim(REGISTRO)','',,14,'left',.T.},;
                  {'text','AllTrim(A1_NOME)','',,14,'left',.T.},;
                  {'text','AllTrim(UsrFullName(Z4_USER))','',,14,'left',.T.},;
                  {'text','DtoC(STOD(DTOCORRE))+"-"+HROCORRE','',,14,'left',.T.},;
                  {'text','ALLTRIM(DESCRICAO)','',,14,'left',.T.},;
                  {'text','AREA','',,14,'left',.T.},;
                  {'text','u_RetAcao(ACAO)','',,14,'left',.T.},;
                  {'icons',{{'(_cHist:=u_HistChat(REGISTRO), If(!Empty(_cHist), u_Icone("mensagem"),""))',,,'""+_cHist',.T.,.T.,,}}}}

       _cTab := u_JsonCmpTab(_cQuerySZ0, _aCab,,,, _aItens,,,.F.,,.T.,.T.,.T.,,,,,,{25,50,100},)
      
      aAdd(_aCampos, {'table', _cTab})
      _cJson := u_JsonEdit('Consulta Registros Disciplinares', '',, _aCampos)
      MemoWrite('Edit.json', _cJson)
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
/* AppJUR01Add - Inclui/Altera Registros Disciplinares
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppJur01Add DESCRIPTION UnEscape("Edicao de Registro Disciplinar - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA OPER   As String //String que vamos receber via URL
   WSDATA ID     As String //String que vamos receber via URL
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION Unescape("Edicao de Registro Disciplinar") WSSYNTAX "/PALM/v1/AppJur01Add" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION Unescape("Edicao de Registro Disciplinar") WSSYNTAX "/PALM/v1/AppJur01Add" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,ID,DEVICEID WSSERVICE AppJur01Add
   Local _lRet	   := .T.
   Local _lErro   := .F.
   Local _nI
   __cUserID      := Self:USERID
   _cToken        := Self:TOKEN
   _cErro         := ''
   _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   _cID           := If(Empty(Self:ID), '', Self:ID)
   _lWeb          := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cAlias     := ALlTrim(_aToken[7])
   _cNomeUser  := _aToken[4]
   _cUserID    := _aToken[6]
   _cIDEmpresa := _aToken[10]
   _cEmail     := _aToken[12]
   _cCor       := _aToken[17]
   _cGrupo     := ALlTrim(_aToken[11])
   If _cOper == 'LIMPAR'
      _cOper := 'INC'
      u_VarTemp()
   EndIf

   // Variável lógica que define a edição...
   _lE := .T.
   If _cOper $ 'ALT'
      SZ4->(DbSetOrder(1))
      SZ4->(DbSeek(xFilial('SZ4')+_cID))   
      _lE := (__cUserID == SZ4->Z4_USER .and. SZ4->Z4_STATUS==' ')
      _cAnexo1   := u_CampoX64('SZ4', xFilial('SZ4')+_cID+'_01')
      _cAnexo2   := u_CampoX64('SZ4', xFilial('SZ4')+_cID+'_02')
      _cAnexo3   := u_CampoX64('SZ4', xFilial('SZ4')+_cID+'_03')
      _cAnexoPDF := u_CampoX64('SZ4', xFilial('SZ4')+_cID+'_PDF')
      _cCodLoc   := SZ4->Z4_LOCAL
      _cTipoReg  := SZ4->Z4_TIPOREG
      _cArea     := SZ4->Z4_AREA
      _cLocal    := AllTrim(SZ4->Z4_DESC)
      _dDOcorre  := SZ4->Z4_DATA
      _cHOcorre  := SZ4->Z4_HORA
      _cTpOcorre := SZ4->Z4_TIPO
      _cSbOcorre := SZ4->Z4_SUBTIPO
      _cObs      := AllTrim(SZ4->Z4_OBJETO)
      _cDetalhe  := AllTrim(SZ4->Z4_DETALHE)
      _cSocio    := SZ4->Z4_SOCIO
      _cEnvolvi  := SZ4->Z4_ENVOLVI   
      _cDataReg  := DtoC(SZ4->Z4_DTREG)+' - '+SZ4->Z4_HRREG
   Else
      _cAnexo1   := ''
      _cAnexo2   := ''
      _cAnexo3   := ''
      _cAnexoPDF := ''
      _cDataReg  := DtoC(dDataBase)+' - '+Left(Time(),5)
      _cCodLoc   := u_RetVarTmp('Z4_CODLOC')
      _cTipoReg  := u_RetVarTmp('Z4_TPREG')
      _cArea     := u_RetVarTmp('Z4_AREA')
      _cLocal    := u_RetVarTmp('Z4_DESC')
      _dDOcorre  := CtoD(u_RetVarTmp('Z4_DATA'))
      _cHOcorre  := u_RetVarTmp('Z4_HORA')
      _cTpOcorre := u_RetVarTmp('Z4_TIPO')
      _cSbOcorre := u_RetVarTmp('Z4_SUBTIPO')
      _cObs      := u_RetVarTmp('Z4_OBJETOS')
      _cDetalhe  := AllTrim(u_RetVarTmp('Z4_DETALHE'))
      _cSocio    := u_RetVarTmp('Z4_SOCIO')
      _cEnvolvi  := u_RetVarTmp('Z4_ENVOLVI')
   EndIf
   If Empty(_dDOcorre)
      _dDOcorre := dDataBase
      _cHOcorre := Left(Time(),5)
      _cAnexo1   := ''
      _cAnexo2   := ''
      _cAnexo3   := ''
      _cAnexoPDF := ''
   EndIf

   Conout('[PALM] Edicao de Registro Disciplinar - Usuario '+_cNomeUser)
   If !_lErro

      _cF3SZ0 := '/PALM/v1/AppConsPad'
      _cF3SZ0 += "?CMPRET="   + Escape("{'Z0_CODLOC','Z0_DESC'}")
      _cF3SZ0 += "&CMPBUSCA=" + Escape("Z0_CODLOC+Z0_DESC")
      _cF3SZ0 += "&QUERY="    + Escape("Select Top 200 Z0_CODLOC, Z0_DESC From "+RetSqlName('SZ0')+" Where D_E_L_E_T_ = ''")
      _cF3SZ0 += "&ORDEM="    + Escape("Z0_CODLOC") 

      _cF3SZ2 := '/PALM/v1/AppConsPad'
      _cF3SZ2 += "?CMPRET="   + Escape("{'Z2_CODIGO','Z2_DESC'}")
      _cF3SZ2 += "&CMPBUSCA=" + Escape("Z2_CODIGO+Z2_DESC")
      _cF3SZ2 += "&QUERY="    + Escape("Select Top 200 Z2_CODIGO, Z2_DESC From "+RetSqlName('SZ2')+" Where D_E_L_E_T_ = ''")
      _cF3SZ2 += "&ORDEM="    + Escape("Z2_CODIGO") 

      _cF3SZ3 := '/PALM/v1/AppConsPad'
      _cF3SZ3 += "?CMPRET="   + Escape("{'Z3_SUBTIPO','Z3_DESC'}")
      _cF3SZ3 += "&CMPBUSCA=" + Escape("Z3_SUBTIPO+Z3_DESC")
      _cF3SZ3 += "&QUERY="    + Escape("Select Top 200 Z3_SUBTIPO, Z3_DESC From "+RetSqlName('SZ3')+" Where D_E_L_E_T_ = '' and Z3_TIPO ='"+_cTpOcorre+"'")
      _cF3SZ3 += "&ORDEM="    + Escape("Z3_SUBTIPO") 

      _cF3SA1 := '/PALM/v1/AppConsPad'
      _cF3SA1 += "?CMPRET="   + Escape("{'A1_COD','A1_NREDUZ'}")
      _cF3SA1 += "&CMPBUSCA=" + Escape("A1_COD+A1_LOJA+A1_NREDUZ")
      _cF3SA1 += "&QUERY="    + Escape("Select Top 100 A1_COD, A1_LOJA, A1_NREDUZ From "+RetSqlName('SA1')+" Where A1_FILIAL = '"+xFilial('SA1')+"' And D_E_L_E_T_ = '' And A1_MSBLQL <> '1'")
      _cF3SA1 += "&ORDEM="    + Escape("A1_NREDUZ")

      _aCampos := {}
      If _cOper == 'ALT'
         _cQuerySZ6 := "Select Z6_CODIGO REGISTRO, Z6_DATA, Z6_HORA, Z6_DETALHE, Z6_USER, Z6_INTERA, Z6_TIPO"+Chr(13)+Chr(10)
         _cQuerySZ6 += "	From "+RetSqlName('SZ6')+" SZ6"+Chr(13)+Chr(10)
         _cQuerySZ6 += "    Where Z6_CODIGO = '"+SZ4->Z4_REGISTR+"' And"+Chr(13)+Chr(10)
         _cQuerySZ6 += "   		  SZ6.D_E_L_E_T_ = '' And Z6_TIPO in ('R','P')"+Chr(13)+Chr(10)
         _cQuerySZ6 += "   Order By Z6_DATA Desc, Z6_HORA Desc"+Chr(13)+Chr(10)      
         DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuerySZ6),"_SZ6",.F.,.T.)
         
         If !Empty(_SZ6->REGISTRO)
            aAdd(_aCampos, {'label',   'l02',   '               Interações apontadas ness registro disciplinar:',16,70,0.1,,,,,,,,,,,_cCor})
            _aCab   := {'',{'icons',{{If(SZ4->Z4_STATUS<>'E'.and._cGrupo=='CONSELHO',u_Icone('incluir'),''),"/PALM/v1/AppJur01Int?OPER=LIMPAR&ID="+SZ4->Z4_REGISTR,,'Incluir interação',,.T.}}},'Data','Hora', 'Interação', 'Detalhamento','Instância'}
            _aItens := {{'icons',{{'"http://server.palmapp.com.br:8090/imagens/ecp/"+Z6_USER+".jpg"','','','',,.F.}}},;
                        'AllTrim(UsrFullName(Z6_USER))','DtoC(StoD(Z6_DATA))','Z6_HORA','If(Z6_INTERA=="F","Finalização",If(Z6_INTERA=="Q","Questionamento",If(Z6_INTERA$"DF","Defesa/Prova","Interação Simples")))',;
                        {'text','AllTrim(Z6_DETALHE)',     'If(Z6_TIPO=="P","A8150D","057D18")',,12,'left',.F.},;
                        {'text','If(Z6_TIPO=="P","Processo","Registro")',     'If(Z6_TIPO=="P","A8150D","057D18")',,12,'left',.F.}}}
            _cTab := u_JsonCmpTab(_cQuerySZ6, _aCab,,,, _aItens,,,.F.,,.T.,.F.,.T.,,30,,,,,,If(_lWeb,100,100))
            //_cTab := u_JsonCmpTab(_aHist, _aCab,,,, _aItens,  ,,.F.,,.T.,.T.,.T.,,40,,,, {50,10,25,100},{2,3,5})
            aAdd(_aCampos, {'table',_cTab})   
            aAdd(_aCampos, {'divider'})      
         EndIf
         _SZ6->(DbCloseARea())
      EndIf

      _cGatilho := ''
      aAdd(_aCampos, {'textfield',       'DATAHORA',    'Data e Hora do Registro',     20,  If(_lWeb,12,.T.), .F., .F.,  _cDataReg,  'X',     '',  "", {}})
      aAdd(_aCampos, {'radio',           'Z4_TPREG',    'Tipo de Registro',            01,  If(_lWeb,30,.T.), _lE, .T.,  _cTipoReg,    'X',     '',  "", {{'O','Ocorrência'},{'C','Comunicação'},{'R','Representação'}}})
      aAdd(_aCampos, {'search',          'Z4_SOCIO',    'Associado',                   06,  If(_lWeb,20,.T.), _lE, .T.,  _cSocio,      'X',     _cF3SA1,  "", {},,,,,,,.T.})
      aAdd(_aCampos, {'multisearch',     'Z4_ENVOLVI',  'Demais envolvidos',          200,  If(_lWeb,37,.T.), _lE, .T.,  _cEnvolvi,    'X',     _cF3SA1,  "", {}})

      _aWrap := {{'icons',{{'http://server.palmapp.com.br:8090/imagens/localizacao.png',"",,"",.T.,.T.,15}}},;
                  '  Localização da Ocorrência'}      
      aAdd(_aCampos, {'wrapper_ini', 'WLOC',      {'C0C0C0', 4, 'C0C0C0', .T., _aWrap,,If(_lWeb,366,Nil)},,If(_lWeb,30,100),'center'})
      aAdd(_aCampos, {'radio',      'Z4_AREA',     'Área',                        01,  If(_lWeb,40,.T.), _lE, .T.,  _cArea   ,    'X',     '',  "", {{'A','A'},{'B','B'},{'C','C'},{'D','D'}}})
      aAdd(_aCampos, {'search',     'Z4_CODLOC',   'Código do Local',             03,  If(_lWeb,60,.T.), _lE, .T.,  _cCodLoc,     'X',     _cF3SZ0,  "", {},,,,,,,.T.})
      aAdd(_aCampos, {'image',  'IMG01', 'Solicitado...', ,100,'0.0',,,,,,,,"http://server.palmapp.com.br:8090/imagens/ecp/locais/local"+If(Empty(_cCodLoc),".png",AllTrim(_cCodLoc)+".gif"),280,700}) 
      If _cCodLoc == '999'
         //aAdd(_aCampos, {'textfield',    'Z4_DESCLOC',  'Local do Registro',           50,  If(_lWeb,44,.T.), .F., .F.,  _cLocal,               'X',     '',  "", {}})
      EndIf   
      aAdd(_aCampos, {'wrapper_end'})

      _aWrap := {{'icons',{{'http://server.palmapp.com.br:8090/imagens/apontamentos.png',"",,"",.T.,.T.,15}}},;
                  '  Complemento da Ocorrência'}      
      aAdd(_aCampos, {'wrapper_ini', 'WCOMP',      {'C0C0C0', 4, 'C0C0C0', .T., _aWrap,,If(_lWeb,366,Nil)},,If(_lWeb,70,100),'center'})
      aAdd(_aCampos, {'date',            'Z4_DATA',     'Data Ocorrência',             10,  If(_lWeb,15,.F.), _lE, .T.,  _dDOcorre,     'X',     '',  "", {}})
      aAdd(_aCampos, {'time',            'Z4_HORA',     'Hora Ocorrência',             05,  If(_lWeb,12,.F.), _lE, .T.,  _cHOcorre,     'X',     '',  "", {}})
      aAdd(_aCampos, {'textfield',       'Z4_DESC',     'Descrição de Ocorrência',    120,  If(_lWeb,73,.T.), _lE, .T.,  _cLocal,       'X',     '',  "", {}})
      aAdd(_aCampos, {'search',          'Z4_TIPO',     'Tipo de Ocorrência',          03,  If(_lWeb,50,.T.), _lE, .T.,  _cTpOcorre,    'X',     _cF3SZ2,  "", {},,,,,,,.T.})
      aAdd(_aCampos, {'search',          'Z4_SUBTIPO',  'SubTipo de Ocorrência',       03,  If(_lWeb,50,.T.), _lE, .T.,  _cSbOcorre,    'X',     _cF3SZ3,  "", {}})
      aAdd(_aCampos, {'textfield',       'Z4_DETALHE',  'Exposição Sucinta dos fatos',600,  If(_lWeb,.T.,.T.),_lE, .F.,  _cDetalhe,     'X',     '',  "", {},.T.})
      aAdd(_aCampos, {'textfield',       'Z4_OBJETO',   'Objetos apreendidos ou que devem ser descritos',250,  If(_lWeb,.T.,.T.), _lE, .F.,  _cObs,        'X',     '',  "", {},.T.})
      aAdd(_aCampos, {'wrapper_end'})

      If !Empty(_cSocio)
         _aHist := {{'catraca',  '02/09/23','09:13', 'Saída do clube',                 'Catraca 01', 'Sem ressalvas'},;
                    {'academia', '02/09/23','07:10', 'Entrada na academia do clube',   'Catraca 13', 'Sem ressalvas'},;
                    {'lanche',   '02/09/23','07:10', 'Consumo na lanchonete academia', 'Caixa 01',   'Sem ressalvas'},;
                    {'catraca',  '02/09/23','06:57', 'Acesso ao clube',                'Catraca 01', 'Sem ressalvas'},;
                    {'academia', '01/09/23','12:35', 'Entrada na academia do clube',   'Catraca 13', 'Sem ressalvas'},;
                    {'catraca',  '01/09/23','13:58', 'Saída do clube',                 'Catraca 01', 'Sem ressalvas'},;
                    {'icondeletar','30/08/23','10:00', 'Registro - Indisciplina na Piscina', 'Piscina', 'Associado xingou e distratou outras pessoas'}}
         SA1->(DbSetOrder(1))
         SA1->(DbSeek(xFilial('SA1')+_cSocio))
         _aWrap := {{'icons',{{'http://server.palmapp.com.br:8090/imagens/calendario.png',"",,"",.T.,.T.,15}}},;
                     '  Histórico do Associado '+AllTrim(SA1->A1_NREDUZ)}      
         aAdd(_aCampos, {'wrapper_ini', 'WHIST',      {'C0C0C0', 4, 'C0C0C0', .T., _aWrap,,If(_lWeb,Nil,Nil)},,If(_lWeb,70,100),'center'})       
         
         _cQueryCJ := "Select A1_COD, A1_NOME, A1_NREDUZ, A1_DTNASC, A1_BAIRRO, A1_END, A1_MUN" +Chr(13)+Chr(10)
         _cQueryCJ += "	From "+RetSqlName('SA1')+" SA1 "    +Chr(13)+Chr(10)
         _cQueryCJ += "	Where A1_MSBLQL <> '1' And"+Chr(13)+Chr(10)
         _cQueryCJ += "		SA1.D_E_L_E_T_ = '' And  A1_COD = '"+_cSocio+"'"+Chr(13)+Chr(10)
         _aIcone := {{'icons', {{'"http://server.palmapp.com.br:8090/imagens/ecp/"+A1_COD+".jpg"',,,'',.T.,.T.,If(_lWeb,120,80)}}}}
         //_aLinha2 := {{'text','AllTrim(A1_NOME)',  '"377CBE"',,18,'center',.T.}} 
         _aLinha1 := {{'text','AllTrim(A1_NOME)',  '"377CBE"',,18,'center',.T.}} 
         _aLinha2 := {{'text','AllTrim(A1_END)',  '"377CBE"',,14,'center',.T.}} 
         _aLinha3 := {{'text','AllTrim(A1_BAIRRO)',  '"377CBE"',,14,'center',.T.}} 
         _aLinha4 := {{'text','AllTrim(A1_MUN)',  '"377CBE"',,14,'center',.T.}} 
         _aLinha5 := {{'text','"Sócio desde Maio/2015"',  '"377CBE"',,14,'center',.T.}} 
         _cCard := u_JsonCard(_cQueryCJ, {{50,{_aIcone}},{50,{_aLinha1,_alinha2,_aLinha3,_aLinha4,_aLinha5}}}, 'AllTrim(A1_COD)', '', '""' ,If(_lWeb,35,100),'')
         MemoWrite('Card.json', _cCard)
         aAdd(_aCampos, {'card',_cCard}) 
         
         _aCab   := {'','Data','Hora', 'Tipo ocorrência', 'Dispositivo', 'Observação'}
         _aItens := {{'icons',{{'u_Icone(_cQueryBRW[_nQ,1])','','','',,.T.}}},;
                     '_cQueryBRW[_nQ,2]','_cQueryBRW[_nQ,3]','_cQueryBRW[_nQ,4]','_cQueryBRW[_nQ,5]','_cQueryBRW[_nQ,6]'}
         _cTab := u_JsonCmpTab(_aHist, _aCab,,,, _aItens,,,.F.,,.T.,.F.,.T.,,30,,,,,,If(_lWeb,65,100))
         //_cTab := u_JsonCmpTab(_aHist, _aCab,,,, _aItens,  ,,.F.,,.T.,.T.,.T.,,40,,,, {50,10,25,100},{2,3,5})
         aAdd(_aCampos, {'table',_cTab})
         aAdd(_aCampos, {'wrapper_end'})

         _aWrap := {{'icons',{{'http://server.palmapp.com.br:8090/imagens/foto.png',"",,"",.T.,.T.,15}}},;
                     '  Anexos (Fotos/PDF)'}      
         aAdd(_aCampos, {'wrapper_ini', 'WIMAGE',      {'C0C0C0', 4, 'C0C0C0', .T., _aWrap,,If(_lWeb,Nil,Nil)},,If(_lWeb,30,100),'center'})       
         aAdd(_aCampos, {'attachment_image','ANEXO1',  'Imagem 01',                80,     .T., _lE,.F.,   _cAnexo1,                 'X',       '',  "Pode-se anexar imagens do item a ser solicitado, especificações via arquivos DOC ou PDF.",{}})
         aAdd(_aCampos, {'attachment_image','ANEXO2',  'Imagem 02',                80,     .T., _lE,.F.,   _cAnexo2,                 'X',       '',  "Pode-se anexar imagens do item a ser solicitado, especificações via arquivos DOC ou PDF.",{}})
         aAdd(_aCampos, {'attachment_image','ANEXO3',  'Imagem 03',                80,     .T., _lE,.F.,   _cAnexo3,                 'X',       '',  "Pode-se anexar imagens do item a ser solicitado, especificações via arquivos DOC ou PDF.",{}})
         aAdd(_aCampos, {'attachment',      'ANEXOPDF','Anexo PDF',                80,     .T., _lE,.F.,   _cAnexoPDF,               'X',       '',  "Pode-se anexar imagens do item a ser solicitado, especificações via arquivos DOC ou PDF.",{}})
         aAdd(_aCampos, {'label',     'l02',    '',20,.T.,,,,,,,,,,,,})
         
         aAdd(_aCampos, {'wrapper_end'})
      EndIf
      aAdd(_aCampos, {'textfield',   'Z4_REGISTRO',  'Solicitação',                    09,      .F., .F., .F.,  _cID,      'X',  '',  '', {},,,,,,,,,,.F.})  //,,,,,,,.T.})

      _cGrava   := ''
      If !Empty(_cSocio+_cLocal+_cTpOcorre+_cSbOcorre+_cCodLoc+_cArea+_cTipoReg) .and. (_cOper == 'INC' .Or. __cUserID == SZ4->Z4_USER)
         _cGrava := '/PALM/v1/AppJur01Add?OPER='+_cOper+'&ID='+SZ4->Z4_REGISTR
      EndIf
      _cConf    := If(_cOper=='ALT','Confirma a atualização do registro?','Confirma a inclusão do registro?')
      _cJson := u_JsonEdit('Registro Disciplinar '+If(_cOper=='ALT',SZ4->Z4_REGISTR,''),'/PALM/v1/AppJur01Gat', _cGrava, _aCampos,, _cConf,,_cOper<>'INC',,SZ4->Z4_REGISTR,,,.T.) //,,_cID,_cApiChat)
      Memowrite('edit.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.	        
   Else
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,OPER,ID WSSERVICE AppJur01Add
   //Local _lRet		  := .T.
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cID      := Self:ID 
   _cOper    := Self:OPER

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := _aToken[4]
   _cAlias    := (AllTrim(_aToken[7]))

   _cErro := ''
   oParseJSON := Nil
   ::SetContentType("application/json")
   FWJsonDeserialize((cJson),@oParseJSON)

   If _cOper == 'EXC'
      SZ4->(DbSetOrder(1))
      SZ4->(DbSeek(xFilial('SZ4')+_cID))
      RecLock('SZ4', .F.)
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+SZ4->Z4_REGISTR+"_01'"
      _nRet := TCSQLEXEC( _cUpd)
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+SZ4->Z4_REGISTR+"_02'"
      _nRet := TCSQLEXEC( _cUpd)
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+SZ4->Z4_REGISTR+"_03'"
      _nRet := TCSQLEXEC( _cUpd)
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+SZ4->Z4_REGISTR+"_PDF'"
      _nRet := TCSQLEXEC( _cUpd)
      SZ4->(DbDelete())
      SZ4->(MsUnlock())

      _cJson := u_JsonMsg('Exclusão OK!',  "Exclusão do registro "+_cID+" realizado com sucesso!",  "success", .F.,'2000',,"/PALM/v1/APPJur01")
      //Enviar e-mail de abertura do Chamado...

      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson))
      Return .T.
   EndIf

   If _cOper == 'INC'
      _cQuery := "Select Max(Z4_REGISTR) NextNum From "+RetSqlName('SZ4')+" "
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_SZ4",.F.,.T.)
      _cNextNum := Soma1(_SZ4->NextNum)
      _SZ4->(DbCloseArea())

      RecLock('SZ4', .T.)
      Replace SZ4->Z4_FILIAL  With xFilial('SZ4')
      Replace SZ4->Z4_REGISTR With _cNextNum
      Conout('[PALM] Incluindo dados do Registro Disciplinar - '+_cNextNum)

      _cQueryChat := "Select Isnull(Max(IDMSG),'0000000000') ULTID"
      _cQueryChat += "  From APPCHAT"
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryChat),"_CHAT",.F.,.T.)
      _cIDChat := Soma1(_CHAT->ULTID)
      _CHAT->(DBCloseArea())
      _cUpd := "Insert Into APPCHAT (CHAVE, IDMSG,   DATAMSG,                HORAMSG,            USERMSG,         NOMEUSER,         USERPARA, LIDAPOR, DELETED, MENSAGEM)"
      _cUpd += " Values ('"+_cNextNum+"', '"+_cIdChat+"', '"+DtoS(dDataBase)+"', '"+Left(Time(),5)+"', '"+__cUserID+"', '"+_cNomeUser+"', '',       '',      '',      'Inclui o registro disciplinar...')"
      TcSqlExec(_cUpd)
   Else
      Conout('[PALM] Atualizando dados do Chamado - '+_cId)
      SZ4->(DbSetOrder(1))
      If SZ4->(DbSeek(xFilial('SZ4')+_cID))
         RecLock('SZ4', .F.)
      EndIf

      _cNextNum := _cID
      _cQueryChat := "Select Isnull(Max(IDMSG),'0000000000') ULTID"
      _cQueryChat += "  From APPCHAT"
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryChat),"_CHAT",.F.,.T.)
      _cIDChat := Soma1(_CHAT->ULTID)
      _CHAT->(DBCloseArea())

      _cUpd := "Insert Into APPCHAT (CHAVE, IDMSG,   DATAMSG,                HORAMSG,            USERMSG,         NOMEUSER,         USERPARA, LIDAPOR, DELETED, MENSAGEM)"
      _cUpd += " Values ('"+SZ4->Z4_REGISTR+"', '"+_cIdChat+"', '"+DtoS(dDataBase)+"', '"+Left(Time(),5)+"', '"+__cUserID+"', '"+_cNomeUser+"', '',       '',      '',      'Atualizei o registro disciplinar...')"
      TcSqlExec(_cUpd)
   EndIf

   Replace SZ4->Z4_AREA    With oParseJson:Z4_AREA
   Replace SZ4->Z4_LOCAL   With oParseJson:Z4_CODLOC
   Replace SZ4->Z4_DATA    With CtoD(oParseJson:Z4_DATA)
   Replace SZ4->Z4_HORA    With oParseJson:Z4_HORA
   Replace SZ4->Z4_DTREG   With dDataBase
   Replace SZ4->Z4_HRREG   With Left(Time(),5)
   Replace SZ4->Z4_TIPO    With oParseJson:Z4_TIPO
   Replace SZ4->Z4_SUBTIPO With oParseJson:Z4_SUBTIPO
   Replace SZ4->Z4_DESC    With oParseJson:Z4_DESC
   Replace SZ4->Z4_DETALHE With oParseJson:Z4_DETALHE
   //Replace SZ4->Z4_REVISAO With oParseJson:Z4_REVISAO
   //Replace SZ4->Z4_ACAO    With oParseJson:Z4_
   Replace SZ4->Z4_STATUS  With ''
   Replace SZ4->Z4_USER    With __cUserID
   Replace SZ4->Z4_SOCIO   With oParseJson:Z4_SOCIO
   Replace SZ4->Z4_ENVOLVI With oParseJson:Z4_ENVOLVI
   Replace SZ4->Z4_TIPOREG With oParseJson:Z4_TPREG
   Replace SZ4->Z4_OBJETO  With oParseJson:Z4_OBJETO
   SZ4->(MsUnlock())

   If Type('oParseJSON:ANEXO1') == 'C' 
      _cAnexo1 := oParseJSON:ANEXO1
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+_cNextNum+"_01'"
      _nRet := TCSQLEXEC( _cUpd)
      _cUpd := "Insert Into APPIMAGEM (TABELA, CHAVE, IMAGEM) Values ('SZ4', '"+xFilial('SZ4')+_cNextNum+"_01', '"+_cAnexo1+"')""
      _nRet := TCSQLEXEC( _cUpd)
   EndIf
   If Type('oParseJSON:ANEXO2') == 'C'
      _cAnexo2 := oParseJSON:ANEXO2
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+_cNextNum+"_02'"
      _nRet := TCSQLEXEC( _cUpd)
      _cUpd := "Insert Into APPIMAGEM (TABELA, CHAVE, IMAGEM) Values ('SZ4', '"+xFilial('SZ4')+_cNextNum+"_02', '"+_cAnexo2+"')""
      _nRet := TCSQLEXEC( _cUpd)
   EndIf
   If Type('oParseJSON:ANEXO3') == 'C'
      _cAnexo3 := oParseJSON:ANEXO3
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+_cNextNum+"_03'"
      _nRet := TCSQLEXEC( _cUpd)
      _cUpd := "Insert Into APPIMAGEM (TABELA, CHAVE, IMAGEM) Values ('SZ4', '"+xFilial('SZ4')+_cNextNum+"_03', '"+_cAnexo3+"')""
      _nRet := TCSQLEXEC( _cUpd)
   EndIf
   If Type('oParseJSON:ANEXOPDF') == 'C'
      _cAnexoPDF := oParseJSON:ANEXOPDF
      _cUpd := "Delete APPIMAGEM Where TABELA = 'SZ4' And CHAVE = '"+xFilial('SZ4')+_cNextNum+"_PDF'"
      _nRet := TCSQLEXEC( _cUpd)
      _cUpd := "Insert Into APPIMAGEM (TABELA, CHAVE, IMAGEM) Values ('SZ4', '"+xFilial('SZ4')+_cNextNum+"_PDF', '"+_cAnexoPDF+"')""
      _nRet := TCSQLEXEC( _cUpd)
   EndIf   

   _cJson := u_JsonMsg('Registro OK!',  If(_cOper=="INC","Inclusão","Atualização")+" do registro "+SZ4->Z4_REGISTR+" realizada com sucesso!",  "success", .T.,'2000',,"/PALM/v1/AppJUR01Brw")
   //Enviar e-mail de abertura do Chamado...

   ::setStatus(200)
   ::setResponse(EncodeUTF8(_cJson))
   Return .T.
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppJUR01Add - Inclui/Altera Registros Disciplinares
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppJur01Int DESCRIPTION UnEscape("Edicao de Registro Disciplinar - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA OPER   As String //String que vamos receber via URL
   WSDATA ID     As String //String que vamos receber via URL
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION Unescape("Edicao de Registro Disciplinar") WSSYNTAX "/PALM/v1/AppJur01Int" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION Unescape("Edicao de Registro Disciplinar") WSSYNTAX "/PALM/v1/AppJur01Int" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,ID,DEVICEID WSSERVICE AppJur01Int
   Local _lRet	   := .T.
   Local _lErro   := .F.
   Local _nI
   __cUserID      := Self:USERID
   _cToken        := Self:TOKEN
   _cErro         := ''
   _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   _cID           := If(Empty(Self:ID), '', Self:ID)
   _lWeb          := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cAlias     := ALlTrim(_aToken[7])
   _cNomeUser  := _aToken[4]
   _cUserID    := _aToken[6]
   _cIDEmpresa := _aToken[10]
   _cEmail     := _aToken[12]

   If _cOper == 'LIMPAR'
      _cOper := 'INC'
      u_VarTemp()
   EndIf

   // Variável lógica que define a edição...
   _cZ6Intera := u_RetVarTmp('Z6_INTERA')
   _cZ6Detalhe:= u_RetVarTmp('Z6_DETALHE')
   _cAnexoZ6  := ''
   _cAnxPDFZ6 := ''
   SZ4->(DbSetOrder(1))
   SZ4->(DbSeek(xFilial('SZ4')+_cID))  

   Conout('[PALM] Interação de Registro Disciplinar - Usuario '+_cNomeUser)
   If !_lErro
      _cGatilho := ''
      _aCampos := {}
      aAdd(_aCampos, {'radio',           'Z6_INTERA',   'Tipo de Interação',           01,  If(_lWeb,50,.T.), .T., .T.,  _cZ6Intera ,  'X',     '',  "", {{'F','Tomar ação específica'},{'I','Interação Simples'},{'Q','Questionamento'},{'D','Defesa'},{'P','Prova'}},,,,,,,.T.})
      aAdd(_aCampos, {'textfield',       'Z6_DETALHE',  'Detalhamento da Interação',  250,  If(_lWeb,50,.T.), .T., .F.,  _cZ6Detalhe,  'X',     '',  "", {},.T.})
      If _cZ6Intera == 'F'
         _cZ6Acao := ''
         _aAcao := {{'1','Instaurar processo disciplinar'},;
                     {'2','Convocar para entrevista'},;
                     {'3','Arquivar Ocorrência'},;
                     {'4','Enviar para área COM/RP'},;
                     {'5','Enviar para conselho deliberativo'},;
                     {'6','Convocar para conciliação'},;
                     {'7','Cancelar registro'},;
                     {'8','Enviar este registro para revisão'},;
                     {'9','Enviar carta - Ouvidoria'}}
         aAdd(_aCampos, {'radio',           'Z6_ACAO',   'Qual ação será tomada?', 01,  If(_lWeb,20,.T.), .T., .T.,  _cZ6Acao ,  'X',     '',  "", _aAcao})
      EndIf
      aAdd(_aCampos, {'attachment_image','ANEXOZ6',     'Imagem de Interação',         80,  If(_lWeb,40,.T.), .T.,.F.,   _cAnexoZ6,                 'X',       '',  "Pode-se anexar imagens do item a ser solicitado, especificações via arquivos DOC ou PDF.",{}})
      aAdd(_aCampos, {'attachment',      'ANEXOPDFZ6',  'Anexo PDF - Interção',        80,  If(_lWeb,39,.T.), .T.,.F.,   _cAnxPDFZ6,               'X',       '',  "Pode-se anexar imagens do item a ser solicitado, especificações via arquivos DOC ou PDF.",{}})
      aAdd(_aCampos, {'divider'})

      aAdd(_aCampos, {'textfield',   'Z4_REGISTRO',  'Solicitação',                    09,      .F., .F., .F.,  _cID,      'X',  '',  '', {},,,,,,,,,,.F.})  //,,,,,,,.T.})
      _cGrava   := '/PALM/v1/AppJur01Int?ID='+SZ4->Z4_REGISTR
      _cConf    := 'Confirma registrar essa interação?'
      //_cJson := u_JsonEdit('Interação no Registro Disciplinar '+SZ4->Z4_REGISTR,'/PALM/v1/AppJur01Gat', _cGrava, _aCampos,, _cConf,,.T.,,SZ4->Z4_REGISTR,,,.T.) //,,_cID,_cApiChat)
      _cJson := u_JsonEdit('Interação no Registro Disciplinar '+SZ4->Z4_REGISTR,'/PALM/v1/AppJur01Gat', _cGrava, _aCampos,, _cConf,,,,,,,.T.) //,,_cID,_cApiChat)
      Memowrite('edit.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.	        
   Else
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,OPER,ID WSSERVICE AppJur01Int
   //Local _lRet		  := .T.
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cID      := Self:ID 
   _cOper    := Self:OPER

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := _aToken[4]
   _cAlias    := (AllTrim(_aToken[7]))

   _cErro := ''
   oParseJSON := Nil
   ::SetContentType("application/json")
   FWJsonDeserialize((cJson),@oParseJSON)
   SZ4->(DbSetOrder(1))
   SZ4->(DbSeek(xFilial('SZ4')+_cID))  

   _cQueryChat := "Select Isnull(Max(IDMSG),'0000000000') ULTID"
   _cQueryChat += "  From APPCHAT"
   DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryChat),"_CHAT",.F.,.T.)
   _cIDChat := Soma1(_CHAT->ULTID)
   _CHAT->(DBCloseArea())

   RecLock('SZ6', .T.)
   Replace SZ6->Z6_FILIAL  With xFilial('SZ6')
   Replace SZ6->Z6_CODIGO  With SZ4->Z4_REGISTR
   Replace SZ6->Z6_TIPO    With 'R'
   Replace SZ6->Z6_USER    With __cUserID
   Replace SZ6->Z6_DATA    With dDataBase
   Replace SZ6->Z6_HORA    With Left(Time(),5)
   Replace SZ6->Z6_DETALHE With oParseJson:Z6_DETALHE
   Replace SZ6->Z6_INTERA  With oParseJson:Z6_INTERA
   SZ6->(MsUnlock())

   _aIntera := {{'F','Tomar ação específica'},{'I','Interação Simples'},{'Q','Questionamento'},{'D','Defesa'},{'P','Prova'}}
   _nPos    := aScan(_aIntera, {|_x| _x[1]==oParseJson:Z6_INTERA})
   _cMsg := _aIntera[_nPos,2]+' - '+AllTrim(oParseJson:Z6_DETALHE)
   If oParseJson:Z6_INTERA == 'F'

      _aAcao := {{'1','instaurei processo disciplinar numero '+SZ4->Z4_REGISTR+'/'+StrZero(Year(dDataBase),4)},;
                  {'2','convoquei os envolvidos para entrevista'},;
                  {'3','arquivei a ocorrência'},;
                  {'4','enviei para área COM/RP'},;
                  {'5','enviei pata conselho deliberativo'},;
                  {'6','convoquei para conciliação'},;
                  {'7','providenciei o cancelamento'},;
                  {'8','enviei para revisão'},;
                  {'9','enviei uma carta - Ouvidoria'}}
      _nPos := aScan(_aAcao, {|_x| _x[1] == oParseJson:Z6_ACAO})
      _cMsg := 'Finalizei o registro e '+_aAcao[_nPos, 2]
      _cUpd := "Insert Into APPCHAT (CHAVE, IDMSG,   DATAMSG,                HORAMSG,            USERMSG,         NOMEUSER,         USERPARA, LIDAPOR, DELETED, MENSAGEM)"
      _cUpd += " Values ('"+SZ4->Z4_REGISTR+"', '"+_cIdChat+"', '"+DtoS(dDataBase)+"', '"+Left(Time(),5)+"', '"+__cUserID+"', '"+_cNomeUser+"', '',       '',      '',      '"+_cMsg+"')"
      TcSqlExec(_cUpd)
      _cIDChat := Soma1(_cIDChat)
      RecLock('SZ4', .F.)
      SZ4->Z4_STATUS = 'E'
      SZ4->Z4_ACAO   = oParseJson:Z6_ACAO
      SZ4->(MsUnlock())

      // Abre Processo
      If oParseJson:Z6_ACAO == '1'
         RecLock('SZ5', .T.)
         Replace SZ5->Z5_FILIAL  With xFilial('SZ5')
         Replace SZ5->Z5_PROCESS With SZ4->Z4_REGISTR
         Replace SZ5->Z5_REGISTR With SZ4->Z4_REGISTR
         Replace SZ5->Z5_DETINI  With AllTrim(oParseJson:Z6_DETALHE)
         Replace SZ5->Z5_USER    With __cUserID
         Replace SZ5->Z5_DATA    With dDataBase
         Replace SZ5->Z5_HORA    With Left(Time(),5)
         Replace SZ5->Z5_COMISS  With GetMV('APP_COMPRO',.F.,'002')
         SZ5->(MsUnlock())

         _cMsg := 'Inclui o Processo baseado na continuidade do Registro '+SZ4->Z4_REGISTR
         _cUpd := "Insert Into APPCHAT (CHAVE, IDMSG,   DATAMSG,                HORAMSG,            USERMSG,         NOMEUSER,         USERPARA, LIDAPOR, DELETED, MENSAGEM)"
         _cUpd += " Values ('SZ5_"+SZ4->Z4_REGISTR+"', '"+_cIdChat+"', '"+DtoS(dDataBase)+"', '"+Left(Time(),5)+"', '"+__cUserID+"', '"+_cNomeUser+"', '',       '',      '',      '"+_cMsg+"')"
         TcSqlExec(_cUpd)
      EndIf   
   Else  
      RecLock('SZ4', .F.)
      SZ4->Z4_STATUS = 'P'
      SZ4->(MsUnlock())

      _cUpd := "Insert Into APPCHAT (CHAVE, IDMSG,   DATAMSG,                HORAMSG,            USERMSG,         NOMEUSER,         USERPARA, LIDAPOR, DELETED, MENSAGEM)"
      _cUpd += " Values ('"+SZ4->Z4_REGISTR+"', '"+_cIdChat+"', '"+DtoS(dDataBase)+"', '"+Left(Time(),5)+"', '"+__cUserID+"', '"+_cNomeUser+"', '',       '',      '',      '"+_cMsg+"')"
      TcSqlExec(_cUpd)
   EndIf

   _cJson := u_JsonMsg('Interação OK!',  "Interação no registro "+SZ4->Z4_REGISTR+" realizada com sucesso!",  "success", .T.,'2000',,"/PALM/v1/AppJUR01Brw")
   //Enviar e-mail de abertura do Chamado...

   ::setStatus(200)
   ::setResponse(EncodeUTF8(_cJson))
   Return .T.
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* Gatilho de todas as Abas
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppJur01Gat DESCRIPTION "Gatilho - PALM"
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA GRUPO  As String //String que vamos receber via URL

   WSMETHOD POST DESCRIPTION "Gatilho" WSSYNTAX "/PALM/v1/AppJur01Gat" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD POST WSRECEIVE userID,token,GRUPO WSSERVICE AppJur01Gat
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cGrupo   := GRUPO
   _cErro    := ''

   //Conout(cJSON)
   oParseJSON := Nil
   ::SetContentType("application/json")
   FWJsonDeserialize((cJson),@oParseJSON)
   //VarInfo('Json', oParseJson)
   _cJson := ''
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := _aToken[4]
   _cCodOpe := __cUserID // _CB1->CB1_CODOPE

   If !_lErro
      If oParseJSON:TRIGGER $ 'Z4_CODLOC.Z4_TIPO.Z4_SOCIO'
         u_VarTemp(oParseJSON)     
         _cJson := '{"refresh":"/PALM/v1/APPJUR01Add?OPER=INC"}'
      ElseIf oParseJson:TRIGGER $ 'Z6_INTERA'
         u_VarTemp(oParseJSON)     
         _cJson := '{"refresh":"/PALM/v1/APPJUR01Int?OPER=ALT&ID='+oParseJson:valores:Z4_REGISTRO+'"}'
      EndIf
      //conout(_cJSON)
      ::setStatus(200)
      ::SetResponse(encodeUtf8(_cJSON))
      Return .T.
      
   EndIf

   If _lErro
      SetRestFault(401, _cErro)
      //Conout(_cErro)
      _lRet := .F.
   Else
      //conout(_cJSon)
      ::setStatus(200)
      ::SetResponse(NoAcento(_cJSON))
      lRet := .T.		   
   EndIf

   Return(_lRet)
//

User Function HistChat(_cId)
   _cQueryChat := "Select CHAVE, IDMSG, DATAMSG, HORAMSG, USERMSG, NOMEUSER, USERPARA, LIDAPOR, MENSAGEM "
   _cQueryChat += "  From APPCHAT Where CHAVE = '"+_cId+"' ANd DELETED = ''"
   _cQueryChat += "  Order By CHAVE, DATAMSG, HORAMSG, IDMSG"
   DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryChat),"_CHAT",.F.,.T.)
 
   _cHist := ''
   Do While !_CHAT->(EoF())
      _cHist += AllTrim(NOMEUSER)+' ('+DtoC(StoD(DATAMSG))+'-'+HORAMSG+'): '+AllTrim(MENSAGEM)+'\n'
      _CHAT->(DbSkip())
   EndDo

   _CHAT->(DbCloseARea())

   Return _cHist
//

User Function RetAcao(_cCod)
   _cRet := ''
   _aAcao := {{'1','Instaurado processo disciplinar'},;
               {'2','Convocado para entrevista'},;
               {'3','Ocorrência arquivada'},;
               {'4','Enviado para área COM/RP'},;
               {'5','Enviado para conselho deliberativo'},;
               {'6','Convocado para conciliação'},;
               {'7','Registro cancelado'},;
               {'8','Enviado para revisão'},;
               {'9','Enviada carta - Ouvidoria'}}
   _nPos := aScan(_aAcao, {|_x| _x[1]==_cCod})
   If _nPos > 0
      _cRet := _aAcao[_nPos, 2]
   EndIf            
   Return _cRet
//
