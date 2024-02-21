#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'
#include 'fileio.ch' 


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppAxDA4 - Browse de Recursos
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppAxDA4 DESCRIPTION ("Cadastro de Condutores - PALM")
   WSDATA USERID     As String //Json Recebido no corpo da requição
   WSDATA TOKEN      As String //String que vamos receber via URL
   WSDATA DEVICEID   As String //String que vamos receber via URL

   WSMETHOD GET DESCRIPTION ("Cadastro de Condutores - PALM") WSSYNTAX "/PALM/v1/AppAxDA4" 
   END WSRESTFUL
   
WSMETHOD GET WSRECEIVE userID,token,DEVICEID WSSERVICE AppAxDA4
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

   Conout('[PALM] Cadastro de Condutores - Usuario '+_cNomeUser)
   _aCampos := {}
   If !_lErro
      // Mostra Perguntas do Checklist
      _cQueryBrw := "Select DA4_COD, DA4_NOME, DA4_TIPMOT, DA4_NREDUZ, DA4_CGC, DA4_NUMCNH, DA4_DTVCNH, DA4_STATUS, DA4_MAT, DA4_TEL"+Chr(13)+Chr(10)
      _cQueryBrw += "	From "+RetSqlName('DA4')+" DA4 "+Chr(13)+Chr(10)
      _cQueryBrw += "	Where D_E_L_E_T_ = ''"+Chr(13)+Chr(10)
      _cQueryBrw += "   Order By DA4_NOME "

                  //u_Icone('incluir')
      _aCab   := {{'icons',{{u_Icone("incluir"),"/PALM/v1/AppAxDA4Add?OPER=LIMPAR",,"Incluir Condutor",.T.,.T.}}},;
                  'Código','Nome','Celular','Tipo'}

      _aIconsBrw := {}
      AADD( _aIconsBrw , {'u_Icone("alterar")','"/PALM/v1/AppAxDA4Add?Oper=ALT&ID="+DA4_COD',,"Alterar condutor",.T.,.F.} )
      AADD( _aIconsBrw , {'u_Icone("excluir")','"/PALM/v1/AppAxDA4Add?Oper=EXC&ID="+DA4_COD','"Confirma excluir esse motorista?"',"Excluir motorista",.F.,.T.} )
      
      _aItens := {  {'icons', _aIconsBrw },;
                        {'text','AllTrim(DA4_COD)', _cCor,,14,'left',.T.},;
                        {'text','AllTrim(StrTran(DA4_NOME, Chr(9),""))', _cCor,,14,'left',.T.},;
                        {'text','AllTrim(StrTran(DA4_TEL ,Chr(9),""))',_cCor,,14,'left',.T.},;
                        {'text','u_RetDescBx("DA4_TIPMOT", DA4_TIPMOT)',  _cCor,,14,'left',.T.}}
      
      _cTab := u_JsonCmpTab(_cQueryBrw, _aCab,,,, _aItens,  ,,.F.,,.T.,.T.,.T.,,30,,,, {50,10,25,100},{2,3,5})
      aAdd(_aCampos, {'table',_cTab})      
      _cJson := u_JsonEdit("Cadastro de Condutores", '', "", _aCampos,,,)  // 1-Minuto de refresh
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
/* AppAxDA4Add - Edita Recurso
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppAxDA4Add DESCRIPTION UnEscape("Edição de Recurso - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA OPER   As String //String que vamos receber via URL
   WSDATA ID     As String //String que vamos receber via URL
   WSDATA APIRET As String //String que vamos receber via URL
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION Unescape("Edição de Recurso") WSSYNTAX "/PALM/v1/AppAxDA4Add" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION Unescape("Edição de Recurso") WSSYNTAX "/PALM/v1/AppAxDA4Add" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,ID,DEVICEID WSSERVICE AppAxDA4Add
   Local _lRet	   := .T.
   Local _lErro   := .F.
   Private __cUserID      := Self:USERID
   Private _cToken        := Self:TOKEN
   Private _cErro         := ''
   Private _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   Private _cID           := If(Empty(Self:ID), '', (Self:ID))
   Private _cAPIRET       := If(Empty(Self:APIRET), '/PALM/v1/AppAxDA4', (Self:APIRET))
   Private _lWeb          := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)

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
   _cCor      := _aToken[17]

   Conout('[PALM] Edicao de Condutor - Usuario '+_cNomeUser)
   If !_lErro
      If _cOper == 'LIMPAR'
         u_VarTemp()
         _cOper := 'INC'
      EndIf
      
      If _cOper == 'INC'
         _cQuery := "Select Max(DA4_COD) Proximo From "+RetSqlName('DA4')+" Where D_E_L_E_T_ = ''"
         DbUseArea(.T.,"TOPCONN",TcGenQry(,,_cQuery),"_DA4",.F.,.T.)
         _cCod := Soma1(_DA4->PROXIMO)
         _DA4->(DbCloseArea())      
         _lE := .T.
         // Abaixo recuperamos as variáveis de memória
         _cNome   := AllTrim(u_RetVarTmp('DA4_NOME'))
         _cNReduz := AllTrim(u_RetVarTmp('DA4_NREDUZ'))
         _cTipo   := AllTrim(u_RetVarTmp('DA4_TIPMOT'))
         _cEnd    := AllTrim(u_RetVarTmp('DA4_END'))
         _cBairro := AllTrim(u_RetVarTmp('DA4_BAIRRO'))
         _cMun    := AllTrim(u_RetVarTmp('DA4_MUN'))
         _cEST    := AllTrim(u_RetVarTmp('DA4_EST'))
         _cCEP    := AllTrim(u_RetVarTmp('DA4_CEP'))
         _cCGC    := AllTrim(u_RetVarTmp('DA4_CGC'))
         _cFone   := AllTrim(u_RetVarTmp('DA4_TEL'))
         _cRG     := AllTrim(u_RetVarTmp('DA4_RG'))
         _cRGOrgao:= AllTrim(u_RetVarTmp('DA4_RGORG'))
         _cRGUF   := AllTrim(u_RetVarTmp('DA4_RGEST'))
         _dRGEmis := CtoD(AllTrim(u_RetVarTmp('DA4_RGDT')))
         _cCNHMun := AllTrim(u_RetVarTmp('DA4_MUNCNH'))
         _cCNHNum := AllTrim(u_RetVarTmp('DA4_NUMCNH'))
         _dCNHDt  := CtoD(AllTrim(u_RetVarTmp('DA4_DTECNH')))
         _dCNHVen := CtoD(AllTrim(u_RetVarTmp('DA4_DTVCNH')))
         _cCNHEST := AllTrim(u_RetVarTmp('DA4_ESTCNH'))
         _cCNHCat := AllTrim(u_RetVarTmp('DA4_CATCNH'))
         _cCNHAnx := ''
         _cMat    := AllTrim(u_RetVarTmp('DA4_MAT'))
         If Empty(_cTipo)
            _cTipo := '2'
         EndIf
      Else
         DA4->(DbSetOrder(1))
         DA4->(DbSeek(xFilial('DA4')+_cID))
         _lE := .T.
         _cCod    := AllTrim(DA4->DA4_COD)
         _cNome   := AllTrim(DA4->DA4_NOME)
         _cNReduz := AllTrim(DA4->DA4_NREDUZ)
         _cTipo   := AllTrim(DA4->DA4_TIPMOT)
         _cEnd    := AllTrim(DA4->DA4_END)
         _cBairro := AllTrim(DA4->DA4_BAIRRO)
         _cMun    := AllTrim(DA4->DA4_MUN)
         _cEST    := AllTrim(DA4->DA4_EST)
         _cCEP    := AllTrim(DA4->DA4_CEP)
         _cCGC    := AllTrim(DA4->DA4_CGC)
         _cFone   := AllTrim(DA4->DA4_TEL)
         _cRG     := AllTrim(DA4->DA4_RG)
         _cRGOrgao:= AllTrim(DA4->DA4_RGORG)
         _cRGUF   := AllTrim(DA4->DA4_RGEST)
         _dRGEmis := (DA4->DA4_RGDT)
         _dCNHDt  := (DA4->DA4_DTECNH)
         _dCNHVen := (DA4->DA4_DTVCNH)
         _cCNHMun := AllTrim(DA4->DA4_MUNCNH)
         _cCNHNum := AllTrim(DA4->DA4_NUMCNH)
         _cCNHEST := AllTrim(DA4->DA4_ESTCNH)
         _cCNHCat := AllTrim(DA4->DA4_CATCNH)
         _cMat    := AllTrim(DA4->DA4_MAT)
         _cCNHAnx := ''
      EndIf

      _aCampos := {}   
      _cF3SRA := '/PALM/v1/AppConsPad'
      _cF3SRA += "?CMPRET="   + Escape("{'RA_MAT','RA_NOME'}")
      _cF3SRA += "&CMPBUSCA=" + Escape("RA_MAT")
      _cF3SRA += "&QUERY="    + Escape("Select Top 100 RA_MAT, RA_NOME From " + RetSqlName('SRA') + " Where D_E_L_E_T_ = '' And RA_SITFOLH <> 'D' ")
      _cF3SRA += "&ORDEM="    + Escape("RA_NOME")

      _cF3T12 := '/PALM/v1/AppConsPad'
      _cF3T12 += "?CMPRET="   + Escape("{'AllTrim(X5_CHAVE)','X5_DESCRI'}")
      _cF3T12 += "&CMPBUSCA=" + Escape("X5_CHAVE")
      _cF3T12 += "&QUERY="    + Escape("Select X5_CHAVE, X5_DESCRI From " + RetSqlName('SX5') + " Where D_E_L_E_T_ = '' And X5_TABELA = '12'")
      _cF3T12 += "&ORDEM="    + Escape("X5_DESCRI")

      _cF3CC2 := '/PALM/v1/AppConsPad'
      _cF3CC2 += "?CMPRET="   + Escape("{'CC2_MUN','CC2_CODMUN'}")
      _cF3CC2 += "&CMPBUSCA=" + Escape("CC2_MUN")
      _cF3CC2 += "&QUERY="    + Escape("Select Top 100 CC2_CODMUN, CC2_EST, CC2_MUN From " + RetSqlName('CC2') + " Where D_E_L_E_T_ = '' And CC2_EST = '"+_cEST+"'")
      _cF3CC2 += "&ORDEM="    + Escape("CC2_MUN")

      _cF3CNH := '/PALM/v1/AppConsPad'
      _cF3CNH += "?CMPRET="   + Escape("{'CC2_MUN','CC2_CODMUN'}")
      _cF3CNH += "&CMPBUSCA=" + Escape("CC2_MUN")
      _cF3CNH += "&QUERY="    + Escape("Select Top 100 CC2_CODMUN, CC2_EST, CC2_MUN From " + RetSqlName('CC2') + " Where D_E_L_E_T_ = '' And CC2_EST = '"+_cCNHEST+"'")
      _cF3CNH += "&ORDEM="    + Escape("CC2_MUN")

      _aTipoMot := {{'1','Funcionário'},{'2','Terceiro'}}
      //_aTipoMot := {{'1','Funcionário'},{'3','Terceiro'},{'2','Motorista'}}
      aAdd(_aCampos, {'label',   'lCondutor', 'Dados do Condutor',16,.T.,,,,,,,,,,,,_cCor})
      aAdd(_aCampos, {'textfield',      'DA4_COD' ,    'Código' ,           TAMSX3("DA4_COD")[1],    If(_lWeb,08, 20), .F., .T.,  _cCod,      'X',    ,  "", {}})
      aAdd(_aCampos, {'radio',          'DA4_TIPMOT',  'Tipo do Condutor',  TAMSX3("DA4_TIPMOT")[1], If(_lWeb,30,.T.), _lE, .F.,  _cTipo,       'X',  '',  '', _aTipoMot,,,,,,,.T.})
      IF _cTipo == '1'
         aAdd(_aCampos, {'search',      'DA4_MAT',     'Matrícula Funcionário',                  06, If(_lWeb,30,.T.), _lE, .T.,  _cMat     ,   'X',   _cF3SRA, "", {},,,,,,,.T.})
      EndIf 
      aAdd(_aCampos, {'textfield',      'DA4_NOME',    'Nome do Condutor',  TAMSX3("DA4_NOME")[1],   If(_lWeb,31, .T.), _lE, .T.,  _cNome,       'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'DA4_NREDUZ',  'Nome reduzido',     TAMSX3("DA4_NREDUZ")[1], If(_lWeb,30,.T.), _lE, .T.,  _cNReduz,     'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'DA4_END',     'Endereço',          TAMSX3("DA4_END")[1],    If(_lWeb,54,.T.), _lE, .T.,  _cEnd,        'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'DA4_BAIRRO',  'Bairro',            TAMSX3("DA4_BAIRRO")[1], If(_lWeb,25,.F.), _lE, .F.,  _cBairro,     'X',    ,  "", {}})
      aAdd(_aCampos, {'search',         'DA4_EST',     'UF',                TAMSX3("DA4_EST")[1],    If(_lWeb,20,.F.), _lE, .F.,  _cEST,        'X',    _cF3T12,  '', {},,,,,,,.T.})
      aAdd(_aCampos, {'search',         'DA4_MUN',     'Município',         TAMSX3("DA4_MUN")[1],    If(_lWeb,22,.F.), _lE, .F.,  _cMun,        'X',    _cF3CC2  , '' , {}})
      aAdd(_aCampos, {'textfield',      'DA4_CEP',     'CEP',               TAMSX3("DA4_CEP")[1],    If(_lWeb,10,.F.), _lE, .F.,  _cCEP,        'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'DA4_CGC',     'CPF/CNPJ',          TAMSX3("DA4_CGC")[1],    If(_lWeb,12,.F.), _lE, .T.,  _cCGC,        'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'DA4_TEL',     'Celular',           TAMSX3("DA4_TEL")[1],    If(_lWeb,12,.F.), _lE, .F.,  _cFone,       'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'DA4_RG',      'RG',                TAMSX3("DA4_RG")[1],     If(_lWeb,10,.F.), _lE, .T.,  _cRG,         'X',    ,  "", {}})
      aAdd(_aCampos, {'textfield',      'DA4_RGORG',   'Orgão Emissor',     TAMSX3("DA4_RGORG")[1],  If(_lWeb,08,.F.), _lE, .T.,  _cRGOrgao,    'X',    ,  "", {}})
      aAdd(_aCampos, {'search',         'DA4_RGEST',   'UF',                TAMSX3("DA4_RGEST")[1],  If(_lWeb,15,.F.), _lE, .T.,  _cRGUF,       'X',   _cF3T12 ,  '', {}})
      aAdd(_aCampos, {'date',           'DA4_RGDT',    'Emissão',           TAMSX3("DA4_RGDT")[1],   If(_lWeb,09,.F.), _lE, .T.,  _dRGEmis,     'X',    ,  "", {}})
      aAdd(_aCampos, {'divider'})
      aAdd(_aCampos, {'label',   'lCNH', 'Dados do CNH',16,.T.,,,,,,,,,,,,_cCor})
      aAdd(_aCampos, {'textfield',      'DA4_NUMCNH',  'CNH',               TAMSX3("DA4_NUMCNH")[1], If(_lWeb,10,.F.), _lE, .T.,  _cCNHNum,     'X',    ,  "", {}})
      aAdd(_aCampos, {'date',           'DA4_DTECNH',  'Expedição',         TAMSX3("DA4_DTECNH")[1], If(_lWeb,08,.F.), _lE, .T.,  _dCNHDt,      'X',    ,  "", {}})
      aAdd(_aCampos, {'date',           'DA4_DTVCNH',  'Validade',          TAMSX3("DA4_DTVCNH")[1], If(_lWeb,08,.F.), .T., .T.,  _dCNHVen,     'X',    ,  "", {}})
      aAdd(_aCampos, {'search',         'DA4_ESTCNH',  'UF',                TAMSX3("DA4_ESTCNH")[1], If(_lWeb,20,.F.), _lE, .T.,  _cCNHEST,     'X',    _cF3T12,  "", {},,,,,,,.T.})
      aAdd(_aCampos, {'search',         'DA4_MUNCNH',  'Município',         TAMSX3("DA4_MUNCNH")[1], If(_lWeb,20,.F.), _lE, .T.,  _cCNHMun,     'X',    _cF3CNH,  "", {}})
      aAdd(_aCampos, {'radio',          'DA4_CATCNH',  'Categoria',                              01, If(_lWeb,20,.F.), .T., .T.,  _cCNHCat,     'X',    ,  "", {{'A','A'},{'B','B'},{'C','C'},{'D','D'},{'E','E'}}})
      aAdd(_aCampos, {'attachment_image',  'ANEXOCNH',    'Anexar Foto CNH',                    80, If(_lWeb,.F.,.T.), _lE,.T.,  _cCNHAnx,     'X',       '',  "",{}})
      
      aAdd(_aCampos, {'textfield',   'APIRET',  'Solicitação',                    09,      .F., .F., .F.,  _cApiRet,      'X',  '',  '', {},,,,,,,,,,.F.})  //,,,,,,,.T.})
      _cJson := u_JsonEdit(If(_cOper=='INC','Incluir','Edita')+' Condutor','/PALM/v1/AppAxDA4Gat', "/PALM/v1/AppAxDA4Add?OPER="+_cOper+'&ID='+_cID, _aCampos,,'Confirma atualizar os dados do condutor?',,,,,,,.T.)
      MemoWrite('Edit.json', _cJson)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.	        
   Else
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,OPER,ID WSSERVICE AppAxDA4Add
   Local _lErro      := .F.
   Local cJSON 	   := Self:GetContent()
   Private __cUserID := Self:USERID
   Private _cToken   := Self:TOKEN
   Private _cID      := If(Empty(Self:ID), '',(Self:ID))
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

   If _cOper == 'EXC'
      Conout('[PALM] Excluindo Motorista '+_cID)

      DA4->(DbSetOrder(1))
      If DA4->(DbSeek(xFilial('DA4')+_cID))
         DA4->(RecLock('DA4',.F.))
         DA4->(DbDelete())
         DA4->(MsUnlock())
      EndIf
      _cJson := u_JsonMsg('Exclusão OK!',"Exclusão de motorista realizada com sucesso!", "success", .T.,'1500',,"/PALM/v1/AppAxDA4")
      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson))
      Return .T.      
   EndIf

   _cJson := ''
   If CtoD(oParseJson:DA4_DTVCNH) < dDataBase
      _cJson := u_JsonMsg('Erro de CNH!',  "A CNH está vencida!",   "alert", .F.,'3000',,)
   EndIf
   If !Empty(_cJson)
      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson))
      Return .T.
   EndIf

   If _cOper == 'INC'
      Conout('[PALM] Incluindo Condutor - '+oParseJson:DA4_NOME )
      RecLock('DA4',.T.)
      Replace DA4->DA4_FILIAL With xFilial('DA4')
      Replace DA4->DA4_COD    With oParseJson:DA4_COD
      Replace DA4->DA4_NOME   With oParseJson:DA4_NOME
      Replace DA4->DA4_TIPMOT With oParseJson:DA4_TIPMOT
      If oParseJson:DA4_TIPMOT == '1'
         Replace DA4->DA4_MAT    With oParseJson:DA4_MAT
      EndIF
   Else
      Conout('[PALM] Alterando Condutor - '+oParseJson:DA4_NOME )
      DA4->(DbSeek(xFilial('DA4')+_cID))
      RecLock('DA4',.F.)
   EndIf   
   //CONOUT("VERIFICAR CONTEUDO DA4_MUN: " + oParseJson:DA4_MUN)
   //CONOUT( "TESTE_RetVarTmp_DA4_MUN_INCLUSAO: "+ AllTrim(u_RetVarTmp('DA4_MUN')) )
   //CONOUT("VERIFICAR CONTEUDO DA4_MUNCNH: " + oParseJson:DA4_MUNCNH)
   //CONOUT( "TESTE_RetVarTmp_DA4_DA4_MUNCNH: "+ AllTrim(u_RetVarTmp('DA4_MUNCNH')) )
   
   Replace DA4->DA4_NREDUZ With oParseJson:DA4_NREDUZ
   Replace DA4->DA4_END    With oParseJson:DA4_END
   Replace DA4->DA4_BAIRRO With oParseJson:DA4_BAIRRO
   Replace DA4->DA4_MUN    With oParseJson:DA4_MUN
   Replace DA4->DA4_EST    With oParseJson:DA4_EST
   Replace DA4->DA4_CEP    With oParseJson:DA4_CEP
   Replace DA4->DA4_CGC    With oParseJson:DA4_CGC
   Replace DA4->DA4_TEL    With oParseJson:DA4_TEL
   Replace DA4->DA4_RG     With oParseJson:DA4_RG
   Replace DA4->DA4_RGORG  With oParseJson:DA4_RGORG
   Replace DA4->DA4_RGEST  With oParseJson:DA4_RGEST
   Replace DA4->DA4_RGDT   With CtoD(oParseJson:DA4_RGDT)
   Replace DA4->DA4_DTECNH With CtoD(oParseJson:DA4_DTECNH)
   Replace DA4->DA4_DTVCNH With CtoD(oParseJson:DA4_DTVCNH)
   Replace DA4->DA4_NUMCNH With oParseJson:DA4_NUMCNH
   Replace DA4->DA4_ESTCNH With oParseJson:DA4_ESTCNH
   Replace DA4->DA4_CATCNH With oParseJson:DA4_CATCNH
   Replace DA4->DA4_MUNCNH With oParseJson:DA4_MUNCNH
    
   DA4->(MsUnlock())
   
   // Limpa as variáveis de memória
   u_VarTemp()

   If _cOper == 'ALT'
      _cJson := u_JsonMsg('Alteração OK!', "Condutor atualizado com sucesso!", "success", .T.,'1000',,"/PALM/v1/AppAxDA4")
   Else   
      If 'AXDA4' $ Upper (oParseJson:APIRET)
         _cJson := u_JsonMsg('Inclusão OK!',  "Condutor incluído com sucesso!",   "success", .T.,'1000',,"/PALM/v1/AppAxDA4")
      Else
         _cJson := u_JsonMsg('Inclusão OK!',  "Condutor incluído com sucesso!",   "success", .T.,'1000',,"")
      EndIf   
   EndIf   
   ::setStatus(200)
   ::setResponse(EncodeUTF8(_cJson))
   Return .T.
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* Gatilho 
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppAxDA4Gat DESCRIPTION "Gatilho do Cadastro de Condutor - PALM"
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA GRUPO  As String //String que vamos receber via URL

   WSMETHOD POST DESCRIPTION "Gatilho do Cadastro de Operador" WSSYNTAX "/PALM/v1/AppAxDA4Gat" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD POST WSRECEIVE userID,token,GRUPO WSSERVICE AppAxDA4Gat
   Local _lRet		 := .T.
   Local _lErro    := .F.
   Local cJSON 	 := Self:GetContent()
   Private __cUserID := Self:USERID
   Private _cToken   := Self:TOKEN
   Private _cErro    := ''

   oParseJSON := Nil
   ::SetContentType("application/json")
   //FWJsonDeserialize(DecodeUtf8(cJson),@oParseJSON)
   FWJsonDeserialize(cJSON,@oParseJSON)

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
      
      If oParseJSON:TRIGGER $ 'DA4_EST.DA4_TIPMOT.DA4_ESTCNH'
         u_VarTemp(oParseJson)
         _cJson := u_JsonRefresh("/PALM/v1/AppAxDA4Add?OPER=INC&APIRET="+oParseJson:valores:APIRET)
      Endif
      If oParseJSON:TRIGGER $ 'DA4_MAT' 

         // Registramos as variáveis de memória para retornar com o Refresh
         u_VarTemp(oParseJson)
         SRA->(DbSetOrder(1))
         If SRA->(DbSeek(xFilial('SRA')+oParseJson:valores:DA4_MAT))
            _cJson := '{'
            _cJson += '   "DA4_NOME":  "'+SRA->RA_NOME+'",'
            _cJson += '   "DA4_NREDUZ":"'+SRA->RA_NOME+'",'
            _cJson += '   "DA4_MAT":"'   +SRA->RA_MAT+'",'
            _cJson += '   "DA4_CGC":   "'+SRA->RA_CIC+'",'
            _cJson += '   "DA4_RG":    "'+SRA->RA_RG+'",'
            _cJson += '   "DA4_RGDT":  "'+DtoC(SRA->RA_DTRGEXP)+'",'
            _cJson += '   "DA4_RGEST": "'+SRA->RA_RGUF+'",'
            _cJson += '   "DA4_RGORG": "'+SRA->RA_RGORG+'",'
            _cJson += '   "DA4_END":   "'+SRA->RA_ENDEREC+'",'
            _cJson += '   "DA4_BAIRRO":"'+SRA->RA_BAIRRO+'",'
            _cJson += '   "DA4_MUN":   "'+SRA->RA_MUNICIP+'",'
            _cJson += '   "DA4_NUMCNH":"'+SRA->RA_HABILIT+'",'
            _cJson += '   "DA4_ESTCNH":"'+SRA->RA_UFCNH  +'",'
            _cJson += '   "DA4_MUNCNH":"'+SRA->RA_MUNICIP+'",'
            _cJson += '   "DA4_CATCNH":"'+SRA->RA_CATCNH+'",'
            _cJson += '   "DA4_DTECNH":"'+DtoC(SRA->RA_DTEMCNH)+'",'
            _cJson += '   "DA4_DTVCNH":"'+DtoC(SRA->RA_DTVCCNH)+'",'
            _cJson += '   "DA4_EST":   "'+SRA->RA_ESTADO+'"'
            _cJson += '}'
         Else
            _cJson := '{}'
         EndIf   
      ElseIf oParseJSON:TRIGGER $ 'DA4_DTVCNH'
         If CtoD(oParseJson:valores:DA4_DTVCNH) < dDataBase
            _cJson := u_JsonMsg('Erro de CNH!',  "A CNH está vencida!",   "alert", .F.,'3000',,)
         EndIf
      Endif

   EndIf
   
   ::setStatus(200)
   ::SetResponse(EncodeUTF8(_cJSON))
   lRet := .T.		

   Return(_lRet)
