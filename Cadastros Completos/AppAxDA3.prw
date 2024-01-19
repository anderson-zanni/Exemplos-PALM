#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* Browse Veículos
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppAxDA3 DESCRIPTION ("Browse de Veículos - Palm")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL

   WSMETHOD GET DESCRIPTION ("Veiculos") WSSYNTAX "/MeliorAPP/v1/AppAxDA3" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token WSSERVICE AppAxDA3
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Private __cUserID := Self:USERID
   _cToken   := Self:TOKEN

   _cErro := ''

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
   EndIf
   _cCor      := AllTrim(_aToken[17])
   
   If !_lErro
      _cQueryDA3 := 'Select DA3_COD VEICULO, DA3_DESC MODELO, DA3_PLACA PLACA, DA3_MUNPLA MUNICIPIO, DA3_ATIVO ATIVO, DA3_ANOMOD ANOMOD, DA3_ANOFAB ANOFAB, DA3_CHASSI CHASSI, DA3_STATUS STATUS,'  //DA3_XKMATU
      _cQueryDA3 += "       (Select X5_DESCRI From "+RetSqlName('SX5')+" Where X5_TABELA = 'M6' And X5_CHAVE = DA3_MARVEI And D_E_L_E_T_ = '') MARCA,"
      _cQueryDA3 += "       (Select X5_DESCRI From "+RetSqlName('SX5')+" Where X5_TABELA = 'M7' And X5_CHAVE = DA3_CORVEI And D_E_L_E_T_ = '') COR"
      _cQueryDA3 += "	From "+RetSqlName('DA3')+' DA3  '
      _cQueryDA3 += "	Where " 
      _cQueryDA3 += "         DA3.D_E_L_E_T_ = ''"	
      _cQueryDA3 += "  Order By DA3_DESC"      
                  //u_Icone('incluir')
      _aCab   := {{'icons',{{u_Icone("incluir"),"/PALM/v1/AppAxDA3Add?OPER=INC",,"Incluir Veículo",.T.,.T.}}},;
                  'Veículo','Descrição','Placa','Município','Ano Mod/Fabric','Marca'}

      _aIconsBrw := {}
      AADD( _aIconsBrw , {'u_Icone(If(ATIVO =="1", "carroverde","carrovermelho"))',"'/PALM/v1/AppAxDA3Add?OPER=ALT&ID='+VEICULO",,"Alterar Veículo",.T.,.T.} )
      AADD( _aIconsBrw , {'u_Icone(If(STATUS =="D", "verde",IIF(STATUS=="B","amarelo","vermelho")))',"'/PALM/v1/AppAxDA3Add?OPER=ALT&ID='+VEICULO",,"Alterar Veículo",.T.,.T.} )
      AADD( _aIconsBrw , {'u_Icone("excluir")','"/PALM/v1/AppAxDA3Add?Oper=EXC&ID="+VEICULO','"Confirma excluir esse Veículo?"',"Excluir Veículo",.T.,.T.} )
      
      _aItens := {  {'icons', _aIconsBrw },;
                        {'text','AllTrim(VEICULO)'   , _cCor,,14,'left',.T.},;
                        {'text','AllTrim(MODELO)'    , _cCor,,14,'left',.T.},;
                        {'text','AllTrim(PLACA)'     , _cCor,,14,'left',.T.},;
                        {'text','AllTrim(MUNICIPIO)' , _cCor,,14,'left',.T.},;
                        {'text','ANOMOD+" | "+ANOFAB', _cCor,,14,'left',.T.},;
                        {'text','AllTrim(MARCA)'     , _cCor,,14,'right',.T.}}
      
      _cTab := u_JsonCmpTab(_cQueryDA3, _aCab,,,, _aItens,  ,,.F.,,.T.,.T.,.T.,,40,,,, {50,10,25,100},{2,3,5})
      _aCampos := {}
      aAdd(_aCampos, {'table',_cTab})    

      // Legenda
      _cQueryBrw := "Select 'azul.png' AZUL, 'amarelo.png' AMARELO, 'verde.png' VERDE, 'cinza.png' CINZA, 'laranja.png' LARANJA"+Chr(13)+Chr(10)
      _aCab   := {'','','','','',''}
      _aItens := {{'icons', {{'u_Icone("verde")',,,,.T.,.F.}}},   {'text','"Carro Disponível   "',      '',,14,'left',.T.},;
                  {'icons', {{'u_Icone("amarelo")',,,,.T.,.F.}}}, {'text','"Carro Bloqueado    "',      '',,14,'left',.T.},;
                  {'icons', {{'u_Icone("vermelho")',,,,.T.,.F.}}},{'text','"Carro Indisponível "',      '',,14,'left',.T.}}
      _cTab := u_JsonCmpTab(_cQueryBrw, _aCab,,,, _aItens,,,.F.,,.F.,.F.,.F.,0,30)
      aAdd(_aCampos, {'table',_cTab})    
      _cJson := u_JsonEdit("Cadastro de Veículos", '', "", _aCampos,,,)  // 1-Minuto de refresh
      MemoWrite('Edit.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.		
   EndIf

   If _lErro
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* Adiciona Veículo / Gravação
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppAxDA3Add DESCRIPTION UnEscape("Adiciona Veículos - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA OPER   As String //String que vamos receber via URL
   WSDATA ID     As String //String que vamos receber via URL
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION Unescape("Inclusão de Clientes") WSSYNTAX "/PALM/v1/AppAxDA3Add" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION Unescape("Inclusão de Clientes") WSSYNTAX "/PALM/v1/AppAxDA3Add" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,ID,DEVICEID WSSERVICE AppAxDA3Add
   Local _lRet	   := .T.
   Local _lErro   := .F.
   __cUserID      := Self:USERID
   _cToken        := Self:TOKEN
   _cErro         := ''
   _cOper         := Self:OPER
   _cID           := If(Empty(Self:ID),'', Self:ID)
   _lWeb          := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := _aToken[4]

   If _cOper <> 'INC'
      DA3->(DbSetOrder(1))
      DA3->(DbSeek(xFilial('DA3')+_cID))
      _cCodigo := AllTrim(DA3->DA3_COD)
      _cDesc   := AllTrim(DA3->DA3_DESC)
      _cPlaca  := AllTrim(DA3->DA3_PLACA)
      _cMunPla := AllTrim(DA3->DA3_MUNPLA)
      _cEstPla := AllTrim(DA3->DA3_ESTPLA)
      _cMarca  := DA3->DA3_MARVEI
      _cCor    := DA3->DA3_CORVEI
      _cAnoMod := AllTrim(DA3->DA3_ANOMOD)
      _cAnoFab := AllTrim(DA3->DA3_ANOFAB)
      _cChassi := AllTrim(DA3->DA3_CHASSI)
      _cRenava := AllTrim(DA3->DA3_RENAVA)
      //_dStatus := DA3->DA3_DATSTS
      _cStatus := DA3->DA3_STATUS
      _cAtivo  := DA3->DA3_ATIVO
  
   Else
      Conout('[PALM] Incluindo veiculo ')
      _cCodigo := RetCodCad()
      _cDesc   := ''
      _cPlaca  := ''
      _cMunPla := ''
      _cEstPla := ''
      _cMarca  := ''
      _cCor    := ''
      _cAnoMod := ''
      _cAnoFab := ''
      _cChassi := ''
      _cRenava := ''
      //_dStatus := Ctod('')
      _cStatus := ''
      _cAtivo  := "1"

   EndIf
   
   Conout('[PALM] '+ iif(_cOper == 'INC', 'Incluindo',iif(_cOper == 'ALT', 'Alterando','Excluíndo')) + ' Veiculo: '+_cCodigo)

   If !_lErro
      _cF3M6 := '/PALM/v1/AppConsPad'
      _cF3M6 += "?CMPRET="   + Escape("{'X5_CHAVE','X5_DESCRI'}")
      _cF3M6 += "&CMPBUSCA=" + Escape("X5_CHAVE+X5_DESCRI")
      _cF3M6 += "&QUERY="    + Escape("Select X5_CHAVE,X5_DESCRI From "+RetSqlName('SX5')+" Where X5_TABELA = 'M6' And D_E_L_E_T_ = ''")
      _cF3M6 += "&ORDEM="    + Escape("X5_CHAVE")

      _cF3M7 := '/PALM/v1/AppConsPad'
      _cF3M7 += "?CMPRET="   + Escape("{'X5_CHAVE','X5_DESCRI'}")
      _cF3M7 += "&CMPBUSCA=" + Escape("X5_CHAVE+X5_DESCRI")
      _cF3M7 += "&QUERY="    + Escape("Select X5_CHAVE,X5_DESCRI From "+RetSqlName('SX5')+" Where X5_TABELA = 'M7' And D_E_L_E_T_ = ''")
      _cF3M7 += "&ORDEM="    + Escape("X5_CHAVE")
      //_cGatilho := '/PALM/v1/AppGatilho'

      _aCampos := {}
      aAdd(_aCampos, {'textfield',   'DA3_COD'   , 'Código Veículo'    , 08, If(_lWeb,08, 33), .F., .T.,  _cCodigo,    'X',       '',  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_DESC'  , 'Modelo / Descrição', 30, If(_lWeb,25, 66), .T., .T.,  _cDesc,      'X',       '',  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_PLACA' , 'Placa'             , 08, If(_lWeb,08, 33), .T., .T.,  _cPlaca,     'X',       '',  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_MUNPLA', 'Município'         , 15, If(_lWeb,12, 50), .T., .T.,  _cMunPla,    'X',       '',  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_ESTPLA', 'UF'                , 02, If(_lWeb,04, 15), .T., .T.,  _cEstPla,    'X',       '',  "",{}})
      aAdd(_aCampos, {'search'   ,   'DA3_MARVEI', 'Marca do Veículo'  , 02, If(_lWeb,21,.F.), .T., .F.,  _cMarca,     'X',   _cF3M6,  "",{}})
      aAdd(_aCampos, {'search'   ,   'DA3_CORVEI', 'Cor do Veículo'    , 02, If(_lWeb,21,.F.), .T., .F.,  _cCor,       'X',   _cF3M7,  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_ANOMOD', 'Ano Modelo'        , 04, If(_lWeb,08, 25), .T., .T.,  _cAnoMod,    'X',       '',  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_ANOFAB', 'Ano Fabricaçao'    , 04, If(_lWeb,08, 25), .T., .T.,  _cAnoFab,    'X',       '',  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_CHASSI', 'Chassis'           , 20, If(_lWeb,12, 49), .T., .T.,  _cChassi,    'X',       '',  "",{}})
      aAdd(_aCampos, {'textfield',   'DA3_RENAVA', 'RENAVAM'           , 11, If(_lWeb,12,.F.), .T., .T.,  _cRenava,    'X',       '',  "",{}})
      aAdd(_aCampos, {'dropdown' ,   'DA3_ATIVO' , 'Ativo?'            , 01, If(_lWeb,10,.F.), .T., .F.,  _cAtivo,     'X',       '',  "",u_RetCBox('DA3_ATIVO')}) 
      aAdd(_aCampos, {'radio'    ,   'DA3_STATUS', 'Status do Veículo' , 01, If(_lWeb,30,.T.), .T., .T.,  _cStatus,    'X',       '',  "",{{'D','Disponível'},{'B','Bloqueado'},{'I','Indisponível'}}})
      aAdd(_aCampos, {'date'     ,   'DA3_DATSTS', 'Data Status'       , 10, If(_lWeb,10,.F.), .F., .F.,  dDatabase,   'X',       '',  "",{}})
      //If _cOper == 'ALT'
         //_aCab   := {'Status','Solicitante','Veículo','Placa', 'Observação'}
      //EndIf

      _cJson := u_JsonEdit('Consulta Veículo '+_cID, '', "/PALM/v1/AppAxDA3Add?Oper="+_cOper+"&ID="+_cID, _aCampos)
      Memowrite('edit.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.	
         
   Else
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,OPER,ID WSSERVICE AppAxDA3Add
   Local _lErro  := .F.
   Local cJSON   := Self:GetContent()
   __cUserID     := Self:USERID
   _cToken       := Self:TOKEN
   _cID          := Self:ID 
   _cOper        := Self:OPER

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf

   _cErro := ''
   oParseJSON := Nil
   ::SetContentType("application/json")
   FWJsonDeserialize((cJson),@oParseJSON)

   If _cOper == 'EXC'
      DA3->(DbSetOrder(1))
      If DA3->(DbSeek(xFilial('DA3')+_cID))
         DA3->(RecLock('DA3',.F.))
         DA3->(DbDelete())
         DA3->(MsUnlock())
      EndIf
      _cJson := u_JsonMsg('Exclusão OK!',"Exclusão de veículo realizada com sucesso!", "success", .T.,'1500',,"/PALM/v1/AppAxDA3")
      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson)) 
   else
      If _cOper == 'ALT'
         Conout('[PALM] Alterando veiculo - '+oParseJson:DA3_COD )
         DA3->(DbSeek(xFilial('DA3')+_cID))
         RecLock('DA3',.F.)
      Else
         Conout('[PALM] Incluindo veiculo - '+oParseJson:DA3_COD )
         RecLock('DA3',.T.)
         Replace DA3->DA3_FILIAL With xFilial('DA3')
         Replace DA3->DA3_COD    With oParseJson:DA3_COD
      EndIf   
      Replace DA3->DA3_DESC   With oParseJson:DA3_DESC
      Replace DA3->DA3_PLACA  With oParseJson:DA3_PLACA
      Replace DA3->DA3_MUNPLA With oParseJson:DA3_MUNPLA
      Replace DA3->DA3_ESTPLA With oParseJson:DA3_ESTPLA
      Replace DA3->DA3_MARVEI With oParseJson:DA3_MARVEI
      Replace DA3->DA3_CORVEI With oParseJson:DA3_CORVEI
      Replace DA3->DA3_ANOMOD With oParseJson:DA3_ANOMOD
      Replace DA3->DA3_ANOFAB With oParseJson:DA3_ANOFAB
      Replace DA3->DA3_CHASSI With oParseJson:DA3_CHASSI
      Replace DA3->DA3_RENAVA With oParseJson:DA3_RENAVA
      Replace DA3->DA3_DATSTS With dDatabase
      Replace DA3->DA3_STATUS With oParseJson:DA3_STATUS
      Replace DA3->DA3_ATIVO  With oParseJson:DA3_ATIVO
      DA3->(MsUnlock())

      If _cOper == 'ALT'
         _cJson := u_JsonMsg('Alteração OK!', "Veículo atualizado com sucesso!", "success", .T.,'1000',,"/PALM/v1/AppAxDA3")
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
      Else   
         _cJson := u_JsonMsg('Inclusão OK!',  "Veículo incluído com sucesso!",   "success", .T.,'1000',,"/PALM/v1/AppAxDA3")
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
      EndIf 

   EndIF  
   
Return .T.

Static Function RetCodCad()
   Local _cQuery := " "
   Local _cCod   := " "

   _cQuery := "Select Max(DA3_COD) Proximo From "+RetSqlName('DA3')+" Where D_E_L_E_T_ = ''"
   DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_DA3",.F.,.T.)
    If _DA3->(!Eof())
      _cCod := strzero(val(Soma1(_DA3->PROXIMO)),TAMSX3("DA3_COD")[1])
   else
      _cCod := Strzero("1",TAMSX3("DA3_COD")[1])
   Endif 
   _DA3->(DbCloseArea()) 

Return _cCod
