#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppAxSZ2 - Browse de Recursos
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppAxSZ2 DESCRIPTION ("Cadastro de Recursos - PALM")
   WSDATA USERID     As String //Json Recebido no corpo da requição
   WSDATA TOKEN      As String //String que vamos receber via URL
   WSDATA DEVICEID   As String //String que vamos receber via URL


   WSMETHOD GET DESCRIPTION ("Cadastro de Operador - PALM") WSSYNTAX "/PALM/v1/AppAxSZ2" 
   END WSRESTFUL
   

WSMETHOD GET WSRECEIVE userID,token,DEVICEID WSSERVICE AppAxSZ2
   Local _lRet		   := .T.
   Local _lErro      := .F.
   Private __cUserID := Self:USERID
   Private _cToken   := Self:TOKEN
   Private _cErro    := ''
   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := ALlTrim(_aToken[4])
   _cGrupo    := AllTrim(_aToken[11])
   _cCor      := AllTrim(_aToken[17])

   Conout('[PALM] Cadastro de Recursos - Usuario '+_cNomeUser)
   _aCampos := {}
   If !_lErro
      // Mostra Perguntas do Checklist
      _cQueryBrw := "Select Z2_CODREC, Z2_NOMREC, Z2_COR, Z2_CELULAR, Z2_CARGO, Z2_STATUS"+Chr(13)+Chr(10)
      _cQueryBrw += "	From "+RetSqlName('SZ2')+" SZ2 "+Chr(13)+Chr(10)
      _cQueryBrw += "	Where D_E_L_E_T_ = ''"+Chr(13)+Chr(10)
      _cQueryBrw += "   Order By Z2_NOMREC "

                  //u_Icone('incluir')
      _aCab   := {{'icons',{{"","/PALM/v1/AppAxSZ2Add?OPER=INC",,"Incluir Recurso",.T.,.T.}}},;
                  'Status','Código','Nome','Celular','Cargo'}

      _aIconsBrw := {}
      Private _aCor   := {{'Branco','FFFFFF'},{'Verde','AEE3A3'},{'Vermelho','DB928F'},{'Laranja','DBA97B'},{'Amarelo','E0DF96'},{'Marrom','B37F5B'},{'Azul','A5ADD4'},{'Cinza','ACADB0'},{'Pink','CF99CB'},{'Roxo','7d4879'}, {'branco',''}}

      AADD( _aIconsBrw , {'u_Icone((_nPos:=aScan(_aCor, {|_x| _x[2]==AllTrim(Z2_COR)}), _aCor[_nPos,1]))','"/PALM/v1/AppAxSZ2Add?Oper=ALT&ID="+Z2_CODREC',,"Alterar Recurso",.T.,.F.} )
      AADD( _aIconsBrw , {'"http://server.palmapp.com.br:8090/imagens/tsm/"+Z2_CODREC+".jpg"','"/PALM/v1/AppAxSZ2Add?Oper=ALT&ID="+Z2_CODREC',,"Alterar recurso",.T.,.F.} )
      
      _aItens := {  {'icons', _aIconsBrw },;
                        {'text','If(Z2_STATUS=="1","Ativo","Inativo")', _cCor,,14,'left',.T.},;
                        {'text','AllTrim(Z2_CODREC)', _cCor,,14,'left',.T.},;
                        {'text','AllTrim(StrTran(Z2_NOMREC, Chr(9),""))', _cCor,,14,'left',.T.},;
                        {'text','AllTrim(StrTran(Z2_CELULAR,Chr(9),""))',_cCor,,14,'left',.T.},;
                        {'text','AllTrim(Z2_CARGO)',  _cCor,,14,'left',.T.}}
      
      _cTab := u_JsonCmpTab(_cQueryBrw, _aCab,,,, _aItens,  ,,.F.,,.T.,.T.,.T.,,30,,,, {50,10,25,100},{2,3,5})

      aAdd(_aCampos, {'table',_cTab})      
      _cJson := u_JsonEdit("Cadastro de Recursos", '', "", _aCampos,,,)  // 1-Minuto de refresh
      MemoWrite('Edit.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.	        
   Else
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)   
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppAxSZ2Add - Edita Recurso
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppAxSZ2Add DESCRIPTION UnEscape("Edição de Recurso - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA OPER   As String //String que vamos receber via URL
   WSDATA ID     As String //String que vamos receber via URL
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION Unescape("Edição de Recurso") WSSYNTAX "/PALM/v1/AppAxSZ2Add" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION Unescape("Edição de Recurso") WSSYNTAX "/PALM/v1/AppAxSZ2Add" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,ID,DEVICEID WSSERVICE AppAxSZ2Add
   Local _lRet	   := .T.
   Local _lErro   := .F.
   Local _nI 
   Private __cUserID      := Self:USERID
   Private _cToken        := Self:TOKEN
   Private _cErro         := ''
   Private _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   Private _cID          := If(Empty(Self:ID), '', (Self:ID))
   Private _lWeb          := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

   VarInfo('ID',_cID)

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := _aToken[4]
   _cGrupo    := AllTrim(_aToken[11])

   If _cOper == 'EXC'
      Conout('[PALM] Excluindo Recurso !')

      SZ2->(DbSeek(xFilial('SZ2')+_cID))
      RecLock('SZ2',.F.)
      SZ2->(DbDelete())
      SZ2->(MsUnlock())

      _cJson := u_JsonMsg('Exclusão OK!',"Exclusão de Recurso realizada com sucesso!", "success", .T.,'1500',,"/PALM/v1/AppAxSZ2")
      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson))
      Return .T.      
   EndIf

   Conout('[PALM] Edicao de Recurso  - Usuario '+_cNomeUser+' - Operacao : '+_cOper)
   If !_lErro
      SZ2->(DbSetOrder(1))
      SZ2->(DbSeek(xFilial('SZ2')+_cID))

      _aCampos := {}   
      _aCores := {}
      _aCor   := {{'Branco','FFFFFF'},{'Verde','AEE3A3'},{'Vermelho','DB928F'},{'Laranja','DBA97B'},{'Amarelo','E0DF96'},{'Marrom','B37F5B'},{'Azul','A5ADD4'},{'Cinza','ACADB0'},{'Pink','CF99CB'},{'Roxo','7d4879'}}
      For _nI := 1 To Len(_aCor)
          aAdd(_aCores, {_aCor[_nI,2], _aCor[_nI,1],    'https://api.palmapp.com.br/imagens/'+_aCor[_nI,1]+'.png'})
      Next
      aAdd(_aCampos, {'textfield',      'Z2_CODREC' , 'Código' ,          06, If(_lWeb,10, 20), .F., .T.,  SZ2->Z2_CODREC,      'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'Z2_NOMREC',  'Nome do Recurso',  50, If(_lWeb,54, 79), .F., .T.,  SZ2->Z2_NOMREC,      'X',   ,  "", {}})
      aAdd(_aCampos, {'radio',          'Z2_STATUS',  'Situação do Recurso',1,If(_lWeb,15,.F.), .T., .F.,  SZ2->Z2_STATUS,       'X',     '',  "", {{'1','Ativo'},{'2','Inativo'}}})      
      aAdd(_aCampos, {'dropdown_image', 'Z2_COR',     'Cor da Agenda',    06, If(_lWeb,20,.F.), .T., .F.,  AllTrim(SZ2->Z2_COR),'X',  '',  '', _aCores})
      aAdd(_aCampos,  {'divider'})
      
      _cJson := u_JsonEdit('Edita recurso',, "/PALM/v1/AppAxSZ2Add?OPER="+_cOper+'&ID='+_cID, _aCampos,,'Confirma atualizar os dados do recurso?')
      MemoWrite('Edit.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.	        
   Else
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,OPER,ID WSSERVICE AppAxSZ2Add
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   Private __cUserID := Self:USERID
   Private _cToken   := Self:TOKEN
   Private _cID       := If(Empty(Self:ID), '',(Self:ID))
   Private _cOper    := Self:OPER

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

   Conout('[PALM] Atualizando recurso - '+oParseJson:Z2_NOMREC )
   SZ2->(DbSeek(xFilial('SZ2')+_cID))
   RecLock('SZ2',.F.)
   Replace SZ2->Z2_COR    With oParseJson:Z2_COR 
   Replace SZ2->Z2_STATUS With oParseJson:Z2_STATUS
   SZ2->(MsUnlock())

   // Atualiza cores das agendas futuras...
   _cUpd := "Update "+RetSqlName('SZD')+" Set ZD_COR = '"+SZ2->Z2_COR +"' Where ZD_CODPRO = '"+SZ2->Z2_CODREC+"' And ZD_DATA >= '"+DtoS(dDataBase+1)+"'"
   TcSqlExec(_cUpd)
   Conout()

   If _cOper == 'ALT'
      _cJson := u_JsonMsg('Alteração OK!', "Recurso atualizado com sucesso!", "success", .T.,'1000',,"/PALM/v1/AppAxSZ2")
   Else   
      _cJson := u_JsonMsg('Inclusão OK!',  "Recurso incluído com sucesso!",   "success", .T.,'1000',,"/PALM/v1/AppAxSZ2")
   EndIf   
   ::setStatus(200)
   ::setResponse(EncodeUTF8(_cJson))
   Return .T.
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* Gatilho 
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCB1Gat DESCRIPTION "Gatilho do Cadastro de Operador - PALM"
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA GRUPO  As String //String que vamos receber via URL

   WSMETHOD POST DESCRIPTION "Gatilho do Cadastro de Operador" WSSYNTAX "/PALM/v1/AppCB1Gat" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD POST WSRECEIVE userID,token,GRUPO WSSERVICE AppCB1Gat
   Local _lRet		 := .T.
   Local _lErro    := .F.
   Local cJSON 	 := Self:GetContent()
   Private __cUserID := Self:USERID
   Private _cToken   := Self:TOKEN
   Private _cErro    := ''

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
   _cNomeUser := _aToken[4]

   If !_lErro

      If oParseJSON:TRIGGER == 'SELECAO'
         
         
         _cJson := u_JsonMsg("Pesquisando", "Processando dados!", 'success',.F. ,'0',,'/PALM/v1/AppAxCB1Add?OPER=INC&SELECAO='+_cSelecao)

      Endif

   EndIf
   
   ::setStatus(200)
   ::SetResponse(EncodeUTF8(_cJSON))
   lRet := .T.		

   Return(_lRet)
//
