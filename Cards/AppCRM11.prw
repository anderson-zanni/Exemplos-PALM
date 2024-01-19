#Include 'protheus.ch'
#Include "TopConn.ch"
#Include 'parmtype.ch'
#Include 'RestFul.ch'
#Include 'FWMVCDEF.ch'
#Include 'fileio.ch'

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppCRM11 - CRM
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCRM11 DESCRIPTION ("Oportunidades de Venda - PALM")
   WSDATA USERID    As String //Json Recebido no corpo da requição
   WSDATA TOKEN     As String //String que vamos receber via URL
   WSDATA DEVICEID  As String 
   WSDATA OPER      As String 
   WSDATA TIPO      As String 
   WSDATA PARCEIRO  As String
   WSDATA VENDEDOR  As String
   WSDATA DATA_ATE  As String

   WSMETHOD GET DESCRIPTION ("Oportunidades de Venda - PALM") WSSYNTAX "/PALM/v1/AppCRM11" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,DEVICEID,Oper,TIPO WSSERVICE AppCRM11
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Local _nI
   Private __cUserID := Self:USERID
   _dBase     := If(Empty(Self:DATA_ATE), dDataBase + 90, CtoD(Self:DATA_ATE))
   _cVend     := If(Empty(Self:VENDEDOR), '', StrTran(StrTran(Self:VENDEDOR,'['),']'))
   _cParc     := If(Empty(Self:PARCEIRO), '', StrTran(StrTran(Self:PARCEIRO,'['),']'))
	_lWeb      := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)
   _cToken    := Self:TOKEN

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cNomeUser := _aToken[4]
   _cAlias    := AllTrim(_aToken[7])
   _cGrupoApp := AllTrim(_aToken[11])

   Conout('[PALM] Propostas de Vendas -> Usuario: '+_cNomeUser)

   If !_lErro
      _aProcVen  := {}
      _cQueryAC2 := "Select AC2_XQUAD, AC2_STAGE, AC2_XCOR, AC2_XURL"+Chr(13)+Chr(10)
      _cQueryAC2 += "	From "+RetSqlName('AC2')+Chr(13)+Chr(10)
      _cQueryAC2 += "	Where AC2_XQUAD <> '' And AC2_XPALM = 'S' And AC2_PROVEN = '000001'"+Chr(13)+Chr(10)
      _cQueryAC2 += "   Order By AC2_STAGE"+Chr(13)+Chr(10)
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryAC2),"_AC2",.F.,.T.)
      Do While !EoF()
         _AC2->(aAdd(_aProcVen, {AllTrim(AC2_XQUAD), AC2_XCOR, AllTrim(AC2_XURL), AC2_STAGE}))
         _AC2->(DbSkip())
      EndDo
      _AC2->(DbCloseARea())

      _aCampos := {}
      _cF3SA3 := '/PALM/v1/AppConsPad'
      _cF3SA3 += "?CMPRET="   + Escape("{'A3_COD','A3_NOME'}")
      _cF3SA3 += "&CMPBUSCA=" + Escape("A3_COD+A3_NOME")
      _cF3SA3 += "&QUERY="    + Escape("Select Top 100 A3_COD, A3_NOME From "+RetSqlName('SA3')+" Where D_E_L_E_T_ = ''")
      _cF3SA3 += "&ORDEM="    + Escape("A3_NOME") 

      _cF3SA1 := '/PALM/v1/AppConsPad'
      _cF3SA1 += "?CMPRET="   + Escape("{'A1_CGC','A1_NOME'}")
      _cF3SA1 += "&CMPBUSCA=" + Escape("A1_CGC+A1_NOME")
      _cF3SA1 += "&QUERY="    + Escape("Select Top 100 A1_CGC,A1_COD, A1_NOME From "+RetSqlName('SA1')+" Where D_E_L_E_T_ = ''")
      _cF3SA1 += "&ORDEM="    + Escape("A1_NOME") 

      SA3->(DbSetOrder(1))
      SA3->(DbSeek(xFilial('SA3')+__cUserID))
      // Parâmetro que define cargos de gerente amarrados ao SA3
      _cGerente := GetMV('APP_CRGGER',.F.,'000002')
      _lGerente := .F.
      If SA3->A3_CARGO $ _cGerente
         _lGerente := .T.
      Else
         _aVend := {SA3->A3_COD}   
      EndIf

      _aParc := Separa(_cParc, ',')
      _aVend := Separa(_cVend, ',')
      If _lWeb
         aAdd(_aCampos, {'label',  'l01',  '',  16, 29})
         aAdd(_aCampos, {'multisearch',          'CLIENTES',  'Filtrar Clientes',                     200,  If(_lWeb,30,.T.), _lGerente, .F.,  _aParc,    'X',  _cF3SA1,"", {},,,,,,,.T.})
         aAdd(_aCampos, {'multisearch',          'VENDEDOR',  'Filtrar Vendedores',                   200,  If(_lWeb,30,.T.), _lGerente, .F.,  _aVend,    'X',  _cF3SA3,"", {},,,,,,,.T.})
         aAdd(_aCampos, {'date',                 'DATA_ATE',  'Fechamento até',                        10,  If(_lWeb,10,.T.), .T., .F.,  _dBase,    'X',  '',  "", {},,,,,,,.T.})
      Else
      EndIf
      _nTam := 99.8 / Len(_aProcVen)
      _nSobra := 99-(Len(_aProcVen)*Int(_nTam))
      For _nI := 1 To Len(_aProcVen)
         If _nI == 1
            _aWrap := {{'icons',{{u_Icone('incluir'),'/PALM/v1/AppCRM11Add',,,.T.,.T.}}},;
                        ' '+_aProcVen[_nI, 1]}      
         Else
            _aWrap := {{'icons',{{If(!Empty(_aProcVen[_nI, 3]),_aProcVen[_nI, 3],""),,,,.T.,.T.}}},;
                        ' '+_aProcVen[_nI, 1]}      
         EndIf
         aAdd(_aCampos, {'wrapper_ini', 'W'+_aProcVen[_nI, 4],      {_aProcVen[_nI, 2], 4, _aProcVen[_nI, 2], _lWeb, _aWrap,,If(_lWeb,730,400)},,If(_lWeb, Int(_nTam)+(If(_nSobra>0,1,0)), .T.),'center'})
         _nSobra--
         _cQueryAD1 := "Select AD1_NROPOR, AD1_REVISA, AD1_DATA, AD1_HORA, AD1_USER, AD1_DTINI, AD1_DTFIM, AD1_PROSPE, AD1_LOJPRO, US_NOME, AD1_CODCLI, AD1_LOJCLI, A1_NOME, AD1_PROVEN, AD1_STAGE, "  +Chr(13)+Chr(10)
         _cQueryAD1 += "	AD1_DESCRI, AD1_RCFECH, AD1_RCREAL, A3_NOME, A3_NREDUZ, AD1_STATUS, AD1_XREJ1"  +Chr(13)+Chr(10)
         _cQueryAD1W := "	From "+RetSqlName('AD1')+" AD1"  +Chr(13)+Chr(10)
         _cQueryAD1W += "	Left Outer Join "+RetSqlName('SA1')+" SA1 On A1_COD = AD1_CODCLI And A1_LOJA = AD1_LOJCLI And SA1.D_E_L_E_T_ = '' "  +Chr(13)+Chr(10)
         _cQueryAD1W += "	Left Outer Join "+RetSqlName('SUS')+" SUS On US_COD = AD1_PROSPE And US_LOJA = AD1_LOJPRO And SUS.D_E_L_E_T_ = '' "  +Chr(13)+Chr(10)
         _cQueryAD1W += "	Inner Join "+RetSqlName('AD2')+" AD2 On AD2_NROPOR = AD1_NROPOR And AD2_REVISA = AD1_REVISA And AD2.D_E_L_E_T_ = '' "  +Chr(13)+Chr(10)
         _cQueryAD1W += "     	And AD2.R_E_C_N_O_ in (Select TOP 1 R_E_C_N_O_ From "+RetSqlName('AD2')+" Where AD2_NROPOR = AD1_NROPOR And AD2_REVISA = AD1_REVISA And D_E_L_E_T_ = '')"+Chr(13)+Chr(10)
         _cQueryAD1W += "	Left Outer Join "+RetSqlName('SA3')+" SA3 On A3_COD = AD2_VEND And SA3.D_E_L_E_T_ = '' "  +Chr(13)+Chr(10)
         If !Empty(_cParc)
            _cParcs := u_Search2Sql(_cParc, 6)
            _cQueryAD1W += " And A3_XPARCE in ("+_cParcs+")"
         EndIf
         If !Empty(_cVend)
            _cVends := u_Search2Sql(_cVend, 6)
            _cQueryAD1W += " And A3_COD in ("+_cVends+")"
         EndIf
         _cQueryAD1W += "	Where AD1.D_E_L_E_T_ = '' And AD1_STAGE = '"+_aProcVen[_nI, 4]+"' And AD1_DTFIM <= '"+DtoS(_dBase)+"'"  +Chr(13)+Chr(10)
         _cQueryAD1 += _cQueryAD1W
         Conout(_cQueryAD1)

         // Sumariza Totais dos valores para apresentação...
         _cQueryAD1T := "Select Sum(AD1_RCFECH) RECORRE, Sum(AD1_RCREAL) UNICO "+_cQueryAD1W+"  Group By AD1_PROVEN"
         DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryAD1T),"_AD1",.F.,.T.)
         aAdd(_aCampos, {'label',  'Tot1',  'Total R$ '+AllTrim(Transform(_AD1->RECORRE, "@E 9,999,999.99")),  14, 100,,,0.2})
         _AD1->(DbCloseArea())

         _aLinha1 := {{'text','AllTrim(AD1_DESCRI)','',,14,'left',.T.}, {'text','"   ["+AllTrim(AD1_NROPOR)+"]"','',,14,'left',.T.} } 
         _aLinha2 := {{'text','If(Empty(A1_NOME),AllTrim(US_NOME), AllTrim(A1_NOME))','',,12,'left',.F.}} 
         _aLinha3 := {{'icons', {{'"http://server.palmapp.com.br:8090/imagens/admmel/"+AD1_USER+".jpg"',,,'AllTrim(A3_NREDUZ)',.T.,.F.,12}}},;
                      {'text','"R$ "+AllTrim(Transform(AD1_RCFECH, "@E 9,999,999.99"))',     '',,12,'left',.F.},;
                      {'icons', {{'"http://server.palmapp.com.br:8090/imagens/docs.png"','"PALM/v1/AppCRM11Imp?NROPOR="+AD1_NROPOR+"&REV="+AD1_REVISA',,'"Imprimir Proposta"',.T.,.T.,15}}},;
                      {'text','"    "+If(AD1_STATUS=="9","...em aprovação",If(AD1_STATUS=="F","Aprovada",If(!Empty(AD1_XREJ1),"Rejeitada","")))',     '',,12,'right',.F.}}
         _aIcone := {{'icons', {{'""',,,'',.T.,.T.,30}}}}
         _cCard := u_JsonCard(_cQueryAD1, {{90,{_aLinha1,_aLinha2,_aLinha3}},{10,{_aIcone}}}, 'AD1_NROPOR', '"/PALM/v1/AppCRM11Add?ID="+AD1_NROPOR', 'If(AD1_STATUS=="9","FFFFE0",If(AD1_STATUS=="F","C1D9CA",If(!Empty(AD1_XREJ1),"FDAE9C","")))' ,,'')
         //_aCab   := {'','','Veiculo','Solicit'}
         //_cTab := u_JsonCmpTab(_cQueryDA3, _aCab,,,, _aItens,,,.F.,,.F.,.F.,.F.,30,35,,)

         MemoWrite('Card.json', _cCard)
         aAdd(_aCampos, {'card',_cCard})               
         aAdd(_aCampos, {'wrapper_end'})
      Next       

      //Grava Filtro para recuperar após inclusão/alteração
      //Memowrite('AppCRM11_'+__cUserID+'.FIL', DtoC(_dInicio)+';'+DtoC(_dFim)+';'+_cProdIni+';'+_cProdFim)
      //_cJson := u_JsonBrwC(_cQueryAD1, 'Projetos', 'PALM/v1/AppCRM11Add', _aAcoesBrw, _cId, _cItTit, _cItSub, _cItImage, _alinhas, _cItUrlTap, _aAcao1, _aAcao2,,,,,'PROJETOS',38,.T.,'Clique no <+> para incluir uma novo projeto...',30000,_aOpcoes)
      
      _cJson := u_JsonEdit('Propostas', '/PALM/v1/AppCRM11Gat', '', _aCampos,,,10000,,,,,,)
      MemoWrite('Edit.json', _cJson)
      ::SetResponse(EncodeUtf8(_cJSON))
      Return .T.
   EndIf

   If _lErro
      SetRestFault(400, _cErro)
      //Conout(_cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppCRM11Add - Detalhes do Contrato
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCRM11Add DESCRIPTION ("Manutenção de Oportunidades - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA ID     As String
   WSDATA OPER   As String
   WSDATA TIPO   As String  
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION "Manutenção de Oportunidades - PALM" WSSYNTAX "/PALM/v1/AppCRM11Add" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION "Manutenção de Oportunidades - PALM" WSSYNTAX "/PALM/v1/AppCRM11Add" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,ID,DEVICEID,OPER,TIPO WSSERVICE AppCRM11Add
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Local _nT
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cID      := If(Empty(Self:ID), '', Self:ID)
   _cOper    := If(Empty(Self:OPER), '', Self:OPER)
   _cTipo    := If(Empty(Self:TIPO), 'PROPOSTA', Self:TIPO)
   _lWeb     := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)
   _cErro := ''

   AD1->(DbSetOrder(1))
   AD1->(DbSeek(xFilial('AD1')+_cID))

   If !_lErro
      // Valida token
      _aToken := u_ValidToken(_cToken)
      If !_aToken[1] 
         _lErro := .T.
         _cErro += _aToken[2]

         SetRestFault(401, _cErro)
         Return .F.
      EndIf
      _cAlias    := AllTrim(_aToken[7])
      _cUserApp  := AllTrim(_aToken[8])
      _cNomeUser := _aToken[4]
      _cCor      := _aToken[17]
      
      Conout('[PALM] Detalhe da Proposta -> Usuario: '+_cNomeUser+' NUM: '+_cID)

      _cGatilho := '/PALM/v1/AppCRM11Gat'
      _cF3SA1 := '/PALM/v1/AppConsPad'
      _cF3SA1 += "?CMPRET="   + Escape("{'A1_CGC','A1_NREDUZ'}")
      _cF3SA1 += "&CMPBUSCA=" + Escape("A1_CGC+A1_NREDUZ")
      _cF3SA1 += "&QUERY="    + Escape("Select Top 100 A1_CGC,A1_COD, A1_LOJA, A1_NREDUZ From "+RetSqlName('SA1')+" Where A1_FILIAL = '"+xFilial('SA1')+"' And D_E_L_E_T_ = '' And A1_MSBLQL <> '1'")
      _cF3SA1 += "&ORDEM="    + Escape("A1_NREDUZ")

      _cF3SUS := '/PALM/v1/AppConsPad'
      _cF3SUS += "?CMPRET="   + Escape("{'US_CGC','US_NREDUZ'}")
      _cF3SUS += "&CMPBUSCA=" + Escape("US_CGC+US_NREDUZ")
      _cF3SUS += "&QUERY="    + Escape("Select Top 100 US_CGC, US_COD, US_LOJA, US_NREDUZ From "+RetSqlName('SUS')+" Where US_FILIAL = '"+xFilial('SUS')+"' And D_E_L_E_T_ = ''")
      _cF3SUS += "&ORDEM="    + Escape("US_NREDUZ")

      _cF3SM0 := '/PALM/v1/AppConsPad'
      _cF3SM0 += "?CMPRET="   + Escape("{'M0_CODFIL','M0_FILIAL'}")
      _cF3SM0 += "&CMPBUSCA=" + Escape("M0_CODFIL+M0_FILIAL")
      _cF3SM0 += "&QUERY="    + Escape("Select M0_CODIGO, M0_CODFIL, M0_FILIAL, M0_NOME, M0_SIZEFIL From SYS_COMPANY Where D_E_L_E_T_ = ''")
      _cF3SM0 += "&ORDEM="    + Escape("M0_CODFIL")

      AC2->(DbSetOrder(1))
      AC2->(DbSeek(xFilial('AC2')))
      _nPerc    := 0
      _aProcVen := {}
      Do While !AC2->(EoF()) .and. AC2->AC2_FILIAL == xFilial('AC2')
         _nPerc    := _nPerc + AC2->AC2_RELEVA 
         _cProAnt  := AC2->AC2_PROVEN
         aAdd(_aProcVen, {AC2->AC2_PROVEN+AC2->AC2_STAGE, AllTrim(AC2->AC2_DESCRI)+' ('+AllTrim(Str(_nPerc))+'%)'})
         AC2->(DbSkip())
         If _cProAnt <> AC2->AC2_PROVEN
            _nPerc := 0
         EndIf
      EndDo

      _lV := .F.
      If _cOper == 'VIEW' .or. (!Empty(_cID) .and. AD1->AD1_STATUS $ '9.F.2')
         _lV := .T.
      EndIf

      If Empty(_cID)
         _l           := .T.
         _cOportunid  := ''
         _cRev        := ''
         _cTpPipe     := 'C'
         _cDescricao  := ''
         _cProspect   := ''
         _cCliente    := ''
         _dInicio     := dDataBase
         _cHrInicio   := Left(Time(),5)
         _cProcesso   := _aProcVen[1,1]
         _cEstagio    := ''
         _cObserva    := ''
         _cStatusM    := ''
         _dFecha      := dDataBase+30
         _cPrior      := '1'
         _cTemp       := '1'
         _cUnidade    := '000001'
         _cStatus     := ''
         _cMensal     := 0
         _cFIxo       := 0
         _cMoeda      := '1'
         _cCGC        := ''
         _cEnd        := ''
         _cBai        := ''
         _cMun        := ''
         _cUF         := ''
         _cCEP        := ''
         _cxEnd       := ''
         _cxNum       := ''
         _cxBai       := ''
         _cxMun       := ''
         _cxUF        := ''
         _cxCEP       := ''
         _cEmail      := ''
         _cCEI        := ''
         _cObs        := ''
         _cObsNF      := ''
      Else
         _l           := .F.
         _cOportunid  := AD1->AD1_NROPOR
         _cRev        := AD1->AD1_REVISA
         _cDescricao  := AD1->AD1_DESCRI
         _cProspect   := If(!Empty(AD1->AD1_PROSPE),AD1->AD1_PROSPE+'.'+AD1->AD1_LOJPRO+' '+Posicione('SUS',1,xFilial('SUS')+AD1->(AD1_PROSPE+AD1_LOJPRO), 'US_NOME'), '')
         _cCliente    := If(!Empty(AD1->AD1_CODCLI),AD1->AD1_CODCLI+'.'+AD1->AD1_LOJCLI+' '+Posicione('SA1',1,xFilial('SA1')+AD1->(AD1_CODCLI+AD1_LOJCLI), 'A1_NOME'),'')
         _dInicio     := AD1->AD1_DTINI
         _cHrInicio   := AD1->AD1_HORA
         _cProcesso   := AD1->AD1_PROVEN+AD1->AD1_STAGE
         _cEstagio    := AD1->AD1_STAGE
         _cObserva    := StrTran(StrTran(AD1->AD1_OBSPRO, '"',''), Chr(13)+CHr(10), '\n')
         //_cStatusM    := AD1->AD1_XSTATUS
         _dFecha      := AD1->AD1_DTFIM
         _cPrior      := AD1->AD1_PRIOR
         _cTemp       := AD1->AD1_FEELIN
         _cUnidade    := AD1->AD1_CANAL
         _cStatus     := AD1->AD1_STATUS //StrTran(StrTran(AD1->AD1_XCOMEN, '"',''), Chr(13)+CHr(10), '\n')
         _cMensal     := AD1->AD1_RCFECH
         _cFixo       := AD1->AD1_RCREAL
         _cxEnd       := AllTrim(AD1->AD1_XEND)
         _cxNum       := AllTrim(AD1->AD1_XNUM)
         _cxBai       := AllTrim(AD1->AD1_XBAIR)
         _cxMun       := AllTrim(AD1->AD1_XMUN)
         _cxUF        := AD1->AD1_XUF
         _cxCEP       := AD1->AD1_XCEP
         _cMoeda      := AllTrim(Str(AD1->AD1_MOEDA))
         _cEmail      := AllTrim(AD1->AD1_XEMAIL)
         _cCEI        := AllTrim(AD1->AD1_XCEI)
         _cObs        := AllTrim(AD1->AD1_XOBS)
         _cObsNF      := AllTrim(AD1->AD1_XOBSNF)
         //_cUsina      := AllTrim(AD1->AD1_XUSINA)
         If !Empty(_cProspect)
            _cCGC        := AllTrim(SUS->US_CGC)
            _cEnd        := AllTrim(SUS->US_END)
            _cBai        := AllTrim(SUS->US_BAIRRO)
            _cMun        := AllTrim(SUS->US_MUN)
            _cUF         := SUS->US_EST
            _cCEP        := SUS->US_CEP
         Else
            _cCGC        := AllTrim(SA1->A1_CGC)
            _cEnd        := AllTrim(SA1->A1_END)
            _cBai        := AllTrim(SA1->A1_BAIRRO)
            _cMun        := AllTrim(SA1->A1_MUN)
            _cUF         := SA1->A1_EST
            _cCEP        := SA1->A1_CEP
         EndIf
      EndIf

      //              1            2             3                                  4     5    6    7    8                      9       10      11 
      _aCampos := {}
      aAdd(_aCampos, {'textfield', 'AD1_NROPOR',   'Proposta',                    06,   If(_lWeb,15,30), .F., .F.,  _cOportunid,   'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'AD1_REVISA',   'Rev',                        02,   If(_lWeb,09,25), .F., .F.,  _cRev,         'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'AD1_DESCRI',   'Descrição da Proposta/Obra',      254,   If(_lWeb,75,.T.),!_lV, .T.,  _cDescricao,   'X',     '',  "",{}})
      If Empty(_cID)
         aAdd(_aCampos, {'search',    'AD1_PROSPE',   'Código do Prospect',         08,   If(_lWeb,30,.T.), _l , .F.,  _cProspect,    'X',     _cF3SUS,  "",{},"/PALM/v1/AppCRM01Add?OPER=INC"," + Adicionar Prospect",,,,,.T.})
         aAdd(_aCampos, {'search',    'AD1_CODCLI',   'Código do Cliente',          08,   If(_lWeb,30,.T.), _l , .F.,  _cCliente,     'X',     _cF3SA1,  "",{},,,,,,,.T.})
      Else   
         If !Empty(_cProspect)
            aAdd(_aCampos, {'textfield',    'AD1_PROSPE',   'Prospect da Proposta',        100,   If(_lWeb,60,.T.), _l , .F.,  _cProspect,    'X',     '',  "",{}})
         Else   
            aAdd(_aCampos, {'textfield',    'AD1_CODCLI',   'Cliente da Proposta',         100,   If(_lWeb,60,.T.), _l , .T.,  _cCliente,     'X',     '',  "",{}})
         EndIf   
      EndIf   
      aAdd(_aCampos, {'textfield', 'AD1_OBSPRO',   'Observações',               300,   If(_lWeb,39,.T.),!_lV, .F.,  _cObserva,     'X',     '',  "",{},.T.})
      //aAdd(_aCampos, {'search',    'AD1_XUSINA',   'Usina Inicial',              12,   If(_lWeb,20,.T.),!_lV ,.T.,  _cUsina,       'X',     _cF3SM0,  "",{}})

      aAdd(_aCampos, {'date',      'AD1_DTINIC',   'Data Início',                10,   If(_lWeb,12,.F.), _l , .T.,  _dInicio,      'X',     '',  "",{}})
      aAdd(_aCampos, {'time',      'AD1_HOINIC',   'Hora Início',                05,   If(_lWeb,10,.F.), _l , .F.,  _cHrInicio,    'X',     '',  "",{}})
      aAdd(_aCampos, {'dropdown',  'AD1_PRIOR',    'Prioridade',                 01,   If(_lWeb,16,.F.),!_lV, .F.,  _cPrior,       'X',     '',  "",{{'1','Baixa'},{'2','Média'},{'3','Alta'}}})
      aAdd(_aCampos, {'dropdown',  'AD1_FEELIN',   'Temperatura',                01,   If(_lWeb,16,.F.),!_lV, .F.,  _cTemp,        'X',     '',  "",{{'1','Baixa'},{'2','Média'},{'3','Alta'}}})
      aAdd(_aCampos, {'date',      'AD1_DTFIM',    'Fechamento',                 10,   If(_lWeb,15,.F.), _l , .F.,  _dFecha,       'X',     '',  "",{}})
      _lS := .T.
      If _cStatus $ '9.2.F'
         _lS := .F.
      EndIf
      If Empty(_cID)
         _lS := .F.
         _cStatus := '1'
      EndIf   
      aAdd(_aCampos, {'radio',     'AD1_STATUS',   'Status da Proposta',         01,   If(_lWeb,30,.T.), _lS, .F.,  _cStatus,      'X',     '',  "",{{'1','Em negociação'},{'9','Aprovado (Contrato)'},{'2','Perdido'}}})
      aAdd(_aCampos, {'divider'})
      aAdd(_aCampos, {'label',     'LAB_CLIENTE',   'Dados do cliente/prospect',16,.T.,,,,,,,,,,,,_cCor})
      aAdd(_aCampos, {'textfield', 'A1_CGC',     'CPF',                    50,   If(_lWeb,08,.F.),.F., .F.,   _cCGC,     'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'A1_CEP',     'CEP',                    08,   If(_lWeb,07,.F.),.F., .F.,   _cCEP,     'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'A1_END',     'Endereço',               50,   If(_lWeb,34,.T.),.F., .F.,   _cEnd,     'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'A1_COMP',    'Complemento',            20,   If(_lWeb,15,.F.),.F., .F.,   '',        'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'A1_BAIRRO',  'Bairro',                 30,   If(_lWeb,15,.F.),.F., .F.,   _cBai,     'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'A1_MUN',     'Município',              30,   If(_lWeb,15,.F.),.F., .F.,   _cMun,     'X',     '',  "",{}})
      aAdd(_aCampos, {'textfield', 'A1_UF',      'UF',                     02,   If(_lWeb,04,.F.),.F., .F.,   _cUF,      'X',     '',  "",{}})

      //aAdd(_aCampos, {'divider'})
      aAdd(_aCampos, {'folder_ini', 'Folder',,,.T. })
      aAdd(_aCampos, {'folder_01',  'Dados de Entrega','DCDCDC'})
      //aAdd(_aCampos, {'label',     'LAB_OBRA',   'Dados da Obra',16,.T.,,,,,,,,,,,,_cCor})
      aAdd(_aCampos, {'radio',     'ENDCLI',     'Considerar endereço ado Cliente?',  01,   If(_lWeb,10,.T.),!_lV, .F., 'N',        'X',     '',  "",{{'S','Sim'},{'N','Não'}},,,,,,,.T.})
      aAdd(_aCampos, {'textfield', 'AD1_XCEP',   'CEP',                         08,   If(_lWeb,07,.F.),!_lV, .F.,  _cxCEP,     'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XEND',   'Endereço',                    50,   If(_lWeb,25,.T.),!_lV, .F.,  _cxEnd,     'X',     '',  "",{},.T.})
      aAdd(_aCampos, {'textfield', 'AD1_XNUM',   'Número',                      10,   If(_lWeb,07,.F.),!_lV, .F.,  _cxNum,     'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XCOMP',  'Complemento',                 20,   If(_lWeb,15,.F.),!_lV, .F.,  '',         'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XBAIR',  'Bairro',                      30,   If(_lWeb,15,.F.),!_lV, .F.,  _cxBai,     'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XMUN',   'Município',                   30,   If(_lWeb,15,.F.),!_lV, .F.,  _cxMun,     'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XUF',    'UF',                          02,   If(_lWeb,04,.F.),!_lV, .F.,  _cxUF,      'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XCEI',   'Num.CEI/CNO',                 20,   If(_lWeb,20,.T.),!_lV, .F.,  _cCEI,      'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XEMAIL', 'E-mail Obra',                100,   If(_lWeb,80,.T.),!_lV, .F.,  _cEmail,    'X',     '',  "",{},})
      aAdd(_aCampos, {'textfield', 'AD1_XOBS',   'Observações do Contrato',   1000,   If(_lWeb,.F.,.T.),!_lV,.F.,  _cObs,      'X',     '',  "",{},.T.})
      aAdd(_aCampos, {'textfield', 'AD1_XOBSNF', 'Observações da Nota Fiscal',1000,   If(_lWeb,.F.,.T.),!_lV,.F.,  _cObsNF,    'X',     '',  "",{},.T.})

      If !Empty(_cID)
         // Produtos
            //aAdd(_aCampos, {'folder_ini', 'Folder',,,.T. })
            aAdd(_aCampos, {'folder_02',  'Produtos','DCDCDC'})
            _cQueryBrw  := "Select ADJ_NROPOR, ADJ_REVISA, ADJ_ITEM, ADJ_PROD, ADJ_QUANT, ADJ_PRUNIT, ADJ_VALOR, B1_DESC, ADJ_XTIPO, ADJ.R_E_C_N_O_ As RECADJ, ADJ_XSEG, ADJ_XTER, ADJ_XQUA, ADJ_XQUI, ADJ_XSEX"+Chr(13)+Chr(10)
            _cQueryBrwW := "	From "+RetSqlName('ADJ')+" ADJ"+Chr(13)+Chr(10)
            _cQueryBrwW += "	Inner Join "+RetSqlName('SB1')+" SB1 On B1_COD = ADJ_PROD And SB1.D_E_L_E_T_ = ''"+Chr(13)+Chr(10)
            _cQueryBrwW += "	Where ADJ.D_E_L_E_T_ = '' And ADJ_NROPOR = '"+AD1->AD1_NROPOR+"' And ADJ_REVISA = '"+AD1->AD1_REVISA+"' and ADJ_XTIPO='V'"+Chr(13)+Chr(10)
            _cQueryBrwT := "Select Sum(ADJ_VALOR) TOTAL "+_cQUeryBrwW
      		DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryBrwT),"_ADJ",.F.,.T.)
            _nProdutos := _ADJ->TOTAL
            _ADJ->(DbCloseArea())
            _cQueryBrw := _cQUeryBrw + _cQueryBrwW+"	Order By ADJ_ITEM"                        +Chr(13)+Chr(10)
            _aCab   := {{'icons',{{If(_lV,'','http://server.palmapp.com.br:8090/imagens/iconnovo.png'),"/PALM/v1/AppCRM11APr?OPER=INC&TIPO=V&NROPOR="+AD1->AD1_NROPOR+"&REVISAO="+AD1->AD1_REVISA,,"Incluir Produto",.T.,.T.,15}}},;
                        'Item','Produto','Qtde','Unitário R$','Total R$','Qtd.Entrega\nSegunda','Qtd.Entrega\nTerça','Qtd.Entrega\nQuarta','Qtd.Entrega\nQuinta','Qtd.Entrega\nSexta'}
            _aIconsBrw := {}
            AADD( _aIconsBrw , {'If(_lV,"",u_Icone("alterar"))','"/PALM/v1/AppCRM11Apr?Oper=ALT&REC="+Alltrim(Str(RECADJ))',,'Alterar Item',.T.}  )
            AADD( _aIconsBrw , {'If(_lV,"",u_Icone("Excluir"))', '"/PALM/v1/AppCRM11Apr?Oper=EXC&REC="+Alltrim(Str(RECADJ))','Confirma excluir esse Item?','Excluir Item',.F.} )
            _aItens := {{'icons',_aIconsBrw },;              
                     {'text','ADJ_ITEM','',,14,'left',.T.},;
                     {'text','AllTrim(ADJ_PROD)+"-"+AllTrim(B1_DESC)','',,14,'left',.T.},;
                     {'text','Transform(ADJ_QUANT, "@E 999,999,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_PRUNIT,"@E 999,999,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_VALOR, "@E 999,999,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_XSEG,  "@E 9,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_XTER,  "@E 9,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_XQUA,  "@E 9,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_XQUI,  "@E 9,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_XSEX,  "@E 9,999.99")','1D2B64',,14,'right',.T.}}

            _cTab := u_JsonCmpTab(_cQueryBrw, _aCab,,,, _aItens,16,,.F.,,.F.,.F.,.T.,,30,,.F.,'ADJ_PROD',,{2,3,4})
            aAdd(_aCampos, {'table', _cTab})
         // FINAL PRODUTO
         //            
         // COMODATO
            aAdd(_aCampos, {'folder_03',  'Comodato','DCDCDC'})
            _cQueryBrw  := "Select ADJ_NROPOR, ADJ_REVISA, ADJ_ITEM, ADJ_PROD, ADJ_QUANT, ADJ_PRUNIT, ADJ_VALOR, B1_DESC, ADJ_XTIPO, ADJ.R_E_C_N_O_ As RECADJ"+Chr(13)+Chr(10)
            _cQueryBrwW := "	From "+RetSqlName('ADJ')+" ADJ"+Chr(13)+Chr(10)
            _cQueryBrwW += "	Inner Join "+RetSqlName('SB1')+" SB1 On B1_COD = ADJ_PROD And SB1.D_E_L_E_T_ = ''"+Chr(13)+Chr(10)
            _cQueryBrwW += "	Where ADJ.D_E_L_E_T_ = '' And ADJ_NROPOR = '"+AD1->AD1_NROPOR+"' And ADJ_REVISA = '"+AD1->AD1_REVISA+"' and ADJ_XTIPO='L'"+Chr(13)+Chr(10)
            _cQueryBrwT := "Select Sum(ADJ_VALOR) TOTAL "+_cQUeryBrwW
      		DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryBrwT),"_ADJ",.F.,.T.)
            _nComod := _ADJ->TOTAL
            _ADJ->(DbCloseArea())
            _cQueryBrw := _cQUeryBrw + _cQueryBrwW+"	Order By ADJ_ITEM"                        +Chr(13)+Chr(10)
            _aCab   := {{'icons',{{If(_lV,'',u_Icone("incluir")),"/PALM/v1/AppCRM11APr?OPER=INC&TIPO=L&NROPOR="+AD1->AD1_NROPOR+"&REVISAO="+AD1->AD1_REVISA,,"Incluir Produto",.T.,.T.,15}}},;
                        'Item','Equipamento','Descricao','Unitário R$','Total R$'}
            _aIconsBrw := {}
            AADD( _aIconsBrw , {'If(_lV,"",u_Icone("alterar"))','"/PALM/v1/AppCRM11Apr?Oper=ALT&TIPO=L&REC="+Alltrim(Str(RECADJ))',,'Alterar Item',.T.}  )
            AADD( _aIconsBrw , {'If(_lV,"",u_Icone("Excluir"))', '"/PALM/v1/AppCRM11Apr?Oper=EXC&TIPO=L&REC="+Alltrim(Str(RECADJ))','Confirma excluir esse Item?','Excluir Item',.F.} )
            _aItens := {{'icons',_aIconsBrw },;              
                     {'text','ADJ_ITEM','',,14,'left',.T.},;
                     {'text','AllTrim(ADJ_PROD)','',,14,'left',.T.},;
                     {'text','AllTrim(B1_DESC)','',,14,'left',.T.},;
                     {'text','Transform(ADJ_PRUNIT,"@E 999,999,999.99")','1D2B64',,14,'right',.T.},;
                     {'text','Transform(ADJ_VALOR, "@E 999,999,999.99")','1D2B64',,14,'right',.T.}}
            _cTab := u_JsonCmpTab(_cQueryBrw, _aCab,,,, _aItens,16,,.F.,,.F.,.F.,.T.,,30,,.F.,'ADJ_PROD',,{2,3,4})
            aAdd(_aCampos, {'table', _cTab})
            //aAdd(_aCampos, {'wrapper_end'})        
         //
         // FINAL COMODATO
         // VENDEDORES
            /*
            _aWrap   := {{'icons',{{"http://server.palmapp.com.br:8090/imagens/time.png",,,,.T.,.T.}}},;         
                        'Vendedores da Proposta'}      
            aAdd(_aCampos, {'wrapper_ini', 'VENDEDORES',      {'C0C0C0', 4, 'C0C0C0', _lWeb, _aWrap,,},,If(_lWeb, 40, .T.),'center'})
            */
            aAdd(_aCampos, {'folder_03',  'Vendedores da Proposta','DCDCDC'})
            _cQueryBrw := "Select AD2_NROPOR, AD2_REVISA, AD2_VEND, AD2_PERC, A3_NOME, AD2.R_E_C_N_O_ As RECAD2"+Chr(13)+Chr(10)
            _cQueryBrw += "	From "+RetSqlName('AD2')+" AD2"+Chr(13)+Chr(10)
            _cQueryBrw += "	Inner Join "+RetSqlName('SA3')+" SA3 On A3_COD = AD2_VEND And SA3.D_E_L_E_T_ = ''"+Chr(13)+Chr(10)
            _cQueryBrw += "	Where AD2.D_E_L_E_T_ = '' And AD2_NROPOR = '"+AD1->AD1_NROPOR+"' And AD2_REVISA = '"+AD1->AD1_REVISA+"'"+Chr(13)+Chr(10)
            _aCab   := {{'icons',{{If(_lV,'','http://server.palmapp.com.br:8090/imagens/iconnovo.png'),"/PALM/v1/AppCRM11Ite?OPER=INC&TAB=AD2&NROPOR="+AD1->AD1_NROPOR+"&REVISAO="+AD1->AD1_REVISA,,"Incluir Vendedor",.T.,.T.,15}}},;
                        'Código','Nome Vendedor','Comissão'}
            _aIconsBrw := {}
            AADD( _aIconsBrw , {'If(_lV,"",u_Icone("alterar"))','"/PALM/v1/AppCRM11Ite?Oper=ALT&TAB=AD2&REC="+AllTrim(STR(RECAD2))',,'Alterar Item',.T.}  )
            AADD( _aIconsBrw , {'If(_lV,"",u_Icone("Excluir"))', '"/PALM/v1/AppCRM11Ite?Oper=EXC&TAB=AD2&REC="+Alltrim(Str(RECAD2))','Confirma excluir esse Item?','Excluir Item',.F.} )
            _aItens := {{'icons',_aIconsBrw },;              
                     {'text','AD2_VEND','',,14,'left',.T.},;
                     {'text','AllTrim(A3_NOME)','',,14,'left',.T.},;
                     {'text','Transform(AD2_PERC, "@E 999.99")+" %"','1D2B64',,14,'right',.T.}}
            _cTab := u_JsonCmpTab(_cQueryBrw, _aCab,,,, _aItens,16,,.F.,,.F.,.F.,.T.,,30,,.F.,'',,, )
            aAdd(_aCampos, {'table', _cTab})
            //aAdd(_aCampos, {'wrapper_end'})
         // FINAL VENDEDORES         
         aAdd(_aCampos, {'folder_end'})

         aAdd(_aCampos, {'wrapper_ini', 'wrap01', {'transparent', 3, 'transparent', .T., {}},,If(_lWeb,15,50)})
         aAdd(_aCampos, {'label',     'l02',    'Total Produtos',16,.T.})
         aAdd(_aCampos, {'label',     'l02',   'R$ '+AllTrim(Transform(_nProdutos, '@E 9,999,999.99')),25,.T.,,,,,,,,,,,,})
         aAdd(_aCampos, {'wrapper_end'})
         aAdd(_aCampos, {'wrapper_ini', 'wrap02', {'transparent', 3, 'transparent', .T., {}},,If(_lWeb,15,50)})
         aAdd(_aCampos, {'label',     'l02',    'Total Comodato',16,.T.})
         aAdd(_aCampos, {'label',     'l02',   'R$ '+AllTrim(Transform(_nComod, '@E 9,999,999.99')),25,.T.,,,,,,,,,,,,})
         aAdd(_aCampos, {'wrapper_end'})
         aAdd(_aCampos, {'wrapper_ini', 'wrap03', {'transparent', 3, 'transparent', .T., {}},,If(_lWeb,15,100)})
         aAdd(_aCampos, {'label',     'l02',    'Total Proposta',16,.T.})
         aAdd(_aCampos, {'label',     'l02',   'R$ '+AllTrim(Transform(_nProdutos+_nComod, '@E 9,999,999.99')),25,.T.,,,,,,,,,,,,_cCor})
         aAdd(_aCampos, {'wrapper_end'})

         If !_lV
            aAdd(_aCampos, {'switch',    'EXCLUIR',    'Excluir Proposta',                                   1,   If(_lWeb, 20, .F.), .T., .F.,  'false'   ,  'X',       '',  "",{}})
         Else
            _cTit := 'Visualiza Proposta'   
         EndIf   
         If !Empty(AD1->AD1_XREJ1)
            aAdd(_aCampos, {'label',     'REJEICAO',  'Motivo de rejeição: '+AllTrim(AD1->AD1_XREJ1),20,.T.,,,,,,,,,,,,'#FF4500'})
         EndIf

      Else
         aAdd(_aCampos, {'folder_end'})
         //aAdd(_aCampos, {'folder_end'})
         aAdd(_aCampos, {'label',  'l01',  'Confirme a inclusão do cabeçalho para que seja possivel o lançamento de itens...',16,.T.})
      EndIf

      aAdd(_aCampos, {'textfield',  'AD1_PROVEN',   'Processo Venda',             12,   If(_lWeb,45,.T.), _l, .T.,  _cProcesso,     'X',     '',  "",{},,,,,,,,,,.F.})

      _cTitulo := If(Empty(_cID),'Inclusão ','Alteração ')+If(_cTipo=='PROPOSTA','de Proposta de Venda','de Contrato de Venda')
      If _cTipo == 'PROPOSTA'
         _cPerg   := If(Empty(_cID),'Confirma a inclusão de uma nova proposta?','Confirma a atualização da proposta?')
      Else
         _cPerg   := If(Empty(_cID),'Confirma a inclusão de um novo contrato?','Confirma a atualização do contrato?')
      EndIf  
      If Empty(_cID)
         _cPerg := ''
      EndIf   
      _cJson := u_JsonEdit(_cTitulo, _cGatilho, If(_lV,'',"/PALM/v1/AppCRM11Add?ID="+_cID), _aCampos,,_cPerg,,,,,,,.T.)
      Memowrite('edit.json', _cJson)
      ::setStatus(200)
      ::SetResponse(EncodeUtf8(_cJSON))
      lRet := .T.		
   EndIf

   If _lErro
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf
   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,ID WSSERVICE AppCRM11Add
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cId      := If(Empty(Self:ID),'',Self:ID)
   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
      Return .F.
   EndIf
   _cUsuario := _aToken[4]//PswRet()[1][2]

   _cErro := ''
   oParseJSON := Nil
   ::SetContentType("application/json")
   FWJsonDeserialize((cJson),@oParseJSON)
   //conout(cJson)

   aCab := {}
   If Empty(_cID)
      _lNew    := .T.
      _nOpc    := 3
		_cQuery := "Select Max(AD1_NROPOR) NextNum From "+RetSqlName('AD1')+" Where D_E_L_E_T_ = ''"
		DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_T",.F.,.T.)
		_cNrOpor := Soma1(_T->NextNum)
		_T->(DbCloseArea())      

      If !Empty(oParseJSON:AD1_PROSPE) .And. !Empty(oParseJSON:AD1_CODCLI)
         _cJson := u_JsonMsg("Inclusão não permitida", "Deve-se selecionar apenas o cliente ou prospect para inclusão da Proposta!", "alert", .F.,'6000')  
         ::SetResponse(NoAcento(_cJSON))      
         Return .T.
      EndIf

      If Empty(oParseJSON:AD1_PROSPE) .And. Empty(oParseJSON:AD1_CODCLI)
         _cJson := u_JsonMsg("Inclusão não permitida", "Deve-se selecionar o cliente ou prospect para inclusão da Proposta!", "alert", .F.,'6000')  
         ::SetResponse(NoAcento(_cJSON))      
         Return .T.
      EndIf

      _cStatus := '1'
   Else
      AD1->(DbSetOrder(1))
      AD1->(DbSeek(xFilial('AD1')+_cID))
      _cNrOpor := AD1->AD1_NROPOR   
      _nOpc    := 4
      _lNew    := .F.
      _cStatus := AD1->AD1_STATUS
   EndIf

   If Type('oParseJson:EXCLUIR') == 'C' .and. oParseJson:EXCLUIR == 'true'
      _cUpd := 'Update '+RetSqlName('AD2')+" Set D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ Where AD2_NROPOR = '"+AD1->AD1_NROPOR+"' And AD2_REVISA = '"+AD1->AD1_REVISA+"'"
      TcSqlExec(_cUpd)
      _cUpd := 'Update '+RetSqlName('AD3')+" Set D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ Where AD3_NROPOR = '"+AD1->AD1_NROPOR+"' And AD3_REVISA = '"+AD1->AD1_REVISA+"'"
      TcSqlExec(_cUpd)
      _cUpd := 'Update '+RetSqlName('AD4')+" Set D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ Where AD4_NROPOR = '"+AD1->AD1_NROPOR+"' And AD4_REVISA = '"+AD1->AD1_REVISA+"'"
      TcSqlExec(_cUpd)
      _cUpd := 'Update '+RetSqlName('AIJ')+" Set D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ Where AIJ_NROPOR = '"+AD1->AD1_NROPOR+"' And AIJ_REVISA = '"+AD1->AD1_REVISA+"'"
      TcSqlExec(_cUpd)
      _cUpd := 'Update '+RetSqlName('AD7')+" Set D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ Where AD7_NROPOR = '"+AD1->AD1_NROPOR+"' And AD7_REVISA = '"+AD1->AD1_REVISA+"'"
      TcSqlExec(_cUpd)
      _cUpd := 'Update '+RetSqlName('AD1')+" Set D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ Where AD1_NROPOR = '"+AD1->AD1_NROPOR+"' And AD1_REVISA = '"+AD1->AD1_REVISA+"'"
      TcSqlExec(_cUpd)

      _cJson := u_JsonMsg("Exclusão OK", "Proposta excluída com sucesso! Numero: "+AD1->AD1_NROPOR, "success", .T.,'500',,"/PALM/v1/AppCRM11")  
      ::setStatus(200)
      ::setResponse(EncodeUtf8(_cJson))
      Return .T.

   EndIf

   _lGeraSCR := .F.
   RecLock('AD1', _lNew)
   If _lNew
      Replace AD1->AD1_FILIAL With xFilial('AD1')
      If !Empty(oParseJSON:AD1_PROSPE)
         SUS->(DbSetOrder(4))
         SUS->(DbSeek(xFilial('SUS')+oParseJson:AD1_PROSPE))      
         Replace AD1->AD1_PROSPE With SUS->US_COD	
         Replace AD1->AD1_LOJPRO With SUS->US_LOJA
      Else
         SA1->(DbSetOrder(3))
         SA1->(DbSeek(xFilial('SA1')+oParseJson:AD1_CODCLI))      
         Replace AD1->AD1_CODCLI With SA1->A1_COD
         Replace AD1->AD1_LOJCLI With SA1->A1_LOJA
      EndIf 
      Replace AD1->AD1_NROPOR With _cNrOpor    
      Replace AD1->AD1_REVISA With '01'                     
      Replace AD1->AD1_PROVEN With Left(oParseJSON:AD1_PROVEN,6)		
      Replace AD1->AD1_STAGE  With Substring(oParseJSON:AD1_PROVEN,7,6)
   EndIf
   Replace AD1->AD1_DTINI  With CtoD(oParseJSON:AD1_DTINIC)	 
   Replace AD1->AD1_DTFIM  With CtoD(oParseJSON:AD1_DTFIM)    
   //Replace AD1->AD1_CANAL  With oParseJSON:AD1_CANAL            
   Replace AD1->AD1_DESCRI With oParseJSON:AD1_DESCRI          
   Replace AD1->AD1_VEND   With __cUserID						      
   Replace AD1->AD1_MOEDA  With 1 //Val(oParseJSON:AD1_MOEDA)
   Replace AD1->AD1_PRIOR  With oParseJSON:AD1_PRIOR
   Replace AD1->AD1_FEELIN With oParseJSON:AD1_FEELIN
   //Replace AD1->AD1_RCFECH With Val(StrTran(oParseJSON:AD1_RCFECH, ".",""))
   //Replace AD1->AD1_RCREAL With Val(StrTran(oParseJSON:AD1_RCREAL, ".",""))
   //AAdd(aCab,{"AD1_TIPO"	, Val(oParseJSON:AD1_TIPO)				     , Nil	})
   //Replace AD1->AD1_TPOPOR With oParseJSON:AD1_TPOPOR
   //Replace AD1->AD1_XCOMEN With oParseJSON:AD1_XCOMEN
   Replace AD1->AD1_OBSPRO With oParseJSON:AD1_OBSPRO
   Replace AD1->AD1_DATA   With dDataBase
   Replace AD1->AD1_HORA   With Left(Time(),5)
   Replace AD1->AD1_USER   With __cUserID
   Replace AD1->AD1_STATUS With oParseJson:AD1_STATUS //1=Aberto;2=Perdido;3=Suspenso;9=Ganha                                                                                           
   Replace AD1->AD1_XEND   With AllTrim(oParseJson:AD1_XEND)
   Replace AD1->AD1_XNUM   With AllTrim(oParseJson:AD1_XNUM)
   Replace AD1->AD1_XBAIR  With AllTrim(oParseJson:AD1_XBAIR)
   Replace AD1->AD1_XCEP   With AllTrim(oParseJson:AD1_XCEP)
   Replace AD1->AD1_XMUN   With AllTrim(oParseJson:AD1_XMUN)
   Replace AD1->AD1_XUF    With AllTrim(oParseJson:AD1_XUF)
   Replace AD1->AD1_XEMAIL With AllTrim(oParseJson:AD1_XEMAIL)
   Replace AD1->AD1_XCEI   With AllTrim(oParseJson:AD1_XCEI)
   Replace AD1->AD1_XOBS   With AllTrim(oParseJson:AD1_XOBS)
   Replace AD1->AD1_XOBSNF With AllTrim(oParseJson:AD1_XOBSNF)
   //Replace AD1->AD1_XUSINA With oParseJson:AD1_XUSINA
   // Envia para aprovação   
   If oParseJson:AD1_STATUS == '9'
      Replace AD1->AD1_STAGE  With '000003'
      Replace AD1->AD1_XREJ1  With ''
      _lGeraSCR := .T.
   ElseIf oParseJson:AD1_STATUS == '1'
      Replace AD1->AD1_STAGE  With '000001'
   EndIf
   AD1->(MsUnlock())   

   If _lNew 
      SA3->(DbSetOrder(1))
      SA3->(DbSeek(xFilial('SA3')+__cUserID))

      // Cria registro de Vendedor da Proposta
      RecLock('AD2', .T.)
      Replace AD2->AD2_FILIAL With xFilial('AD2')
      Replace AD2->AD2_NROPOR With AD1->AD1_NROPOR
      Replace AD2->AD2_REVISA With AD1->AD1_REVISA
      Replace AD2->AD2_HISTOR With '2'
      Replace AD2->AD2_VEND   With __cUserID
      Replace AD2->AD2_PERC   With SA3->A3_COMIS
      AD2->(MSUnlock())

      // Cria registro de Parceiro da Proposta
      /*
      If !Empty(SA3->A3_XPARCE)
         RecLock('AD4', .T.)
         Replace AD4->AD4_FILIAL With xFilial('AD4')
         Replace AD4->AD4_NROPOR With AD1->AD1_NROPOR
         Replace AD4->AD4_REVISA With AD1->AD1_REVISA
         Replace AD4->AD4_HISTOR With '2'
         Replace AD4->AD4_PARTNE With SA3->A3_XPARCE
         AD4->(MSUnlock())        
      EndIf
      */
   EndIf         

   ADJ->(DbSetOrder(1))
   ADJ->(DbSeek(xFilial('ADJ')+AD1->(AD1_NROPOR+AD1_REVISA)))
   _cTxtAprov := ''
   Do While ADJ->(ADJ_NROPOR+ADJ_REVISA) == AD1->(AD1_NROPOR+AD1_REVISA) .and. !ADJ->(EoF())
      If ADJ->ADJ_PRUNIT < ADJ->ADJ_XPRTAB
         SB1->(DbSeek(ADJ->ADJ_PROD))
         If !Empty(_cTxtAprov)
            _cTxtAprov += '\n'
         EndIf
         _cTxtAprov += 'Preço '+AllTrim(SB1->B1_DESC)+' negociado (R$ '+AllTrim(Str(ADJ->ADJ_PRUNIT))+') menor que tabela (R$ '+AllTrim(Str(ADJ->ADJ_XPRTAB))+')'
      EndIf
      ADJ->(DbSkip())
   EndDo

   _lContrato := .F.
   If !Empty(_cTxtAprov) .and. _lGeraSCR
      Reclock("SCR",.T.)
      SCR->CR_FILIAL	 := xFilial('SCR')
      SCR->CR_NUM		 := AD1->(AD1_NROPOR+AD1_REVISA)
      //SCR->CR_XSEQ	 := SEQ
      SCR->CR_TIPO	 := 'PR' //Proposta
      SCR->CR_NIVEL	 := '01'
      SCR->CR_USER	 := ''
      SCR->CR_APROV	 := ''
      SCR->CR_STATUS	 := '02'
      SCR->CR_TOTAL	 := AD1->AD1_RCFECH
      SCR->CR_EMISSAO := dDataBase
      SCR->CR_MOEDA	 := 1
      SCR->CR_TXMOEDA := 1
      SCR->CR_PRAZO	 := dDataBase+2
      SCR->CR_AVISO	 := dDataBase+3
      SCR->CR_GRUPO   := ''
      SCR->CR_ITGRP   := ''
      SCR->CR_USERORI := __cUserID
      SCR->CR_OBS     := _cTxtAprov
      SCR->CR_XTPCRM  := 'CP'   //CP:Comercial - Preço negociado a menor   CT:Comercial - Taxa a menor   CD:Comercial - Taxa deletada   FP:Financeiro - Novo Pagamento inserido
      //SCR->CR_ESCALON:= lEscalona
      //SCR->CR_ESCALSP:= lEscalonaS
      SCR->(MsUnlock())
   ElseIf _lGeraSCR
      /* Gera contrato sem necessidade de aprovação */
      u_GravaCN9(AllTrim(AD1->(AD1_NROPOR+AD1_REVISA))) 
      _lContrato := .T.
   EndIf

   If _lNew   
      If _lContrato
         _cJson := u_JsonMsg("Geração de Contrato", "Proposta atualizada com sucesso e contrato "+AllTrim(CN9->CN9_NUMERO)+" gerado no Sistema!", "success", .T.,'2000',,"/PALM/v1/AppCRM11")  
      Else   
         _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'&OPER=ALT"}'  
      EndIf   
   Else
      If _lContrato
         _cJson := u_JsonMsg("Geração de Contrato", "Proposta atualizada com sucesso e contrato "+AllTrim(CN9->CN9_NUMERO)+" gerado no Sistema!", "success", .T.,'2000',,"/PALM/v1/AppCRM11")  
      Else
         _cJson := u_JsonMsg("Proposta OK", "Proposta "+If(_nOpc==3,'incluída','alterada')+" com sucesso! Numero: "+_cNrOpor, "success", .T.,'500',,"/PALM/v1/AppCRM11")  
      EndIf   
   EndIf   
   //EndIf   
   ::setStatus(200)
   ::setResponse(EncodeUtf8(_cJson))
   Return .T.
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppCRM11APr - Adiciona Etapas na OS
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCRM11APr DESCRIPTION ("Oportunidade - Adicionar Produtos - PALM")
   WSDATA USERID   As String //Json Recebido no corpo da requição
   WSDATA TOKEN    As String //String que vamos receber via URL
   WSDATA ID       As String
   WSDATA DEVICEID As String
   WSDATA OPER     As String
   WSDATA REC      As String
   WSDATA NROPOR   As String
   WSDATA REVISAO  As String
   WSDATA PRODUTO  As String
   WSDATA QUANT    As String
   WSDATA DESC     As String
   WSDATA TIPO     As String
   WSMETHOD GET DESCRIPTION "Oportunidade - Adicionar Produtos - PALM" WSSYNTAX "/PALM/v1/AppCRM11APr" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION "Oportunidade - Adicionar Produtos - PALM" WSSYNTAX "/PALM/v1/AppCRM11APr" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,ID,OPER,REC,PRODUTO,NROPOR,REVISAO,DEVICEID,QUANT,DESC,TIPO WSSERVICE AppCRM11APr
   Local _lRet		  := .T.
   Local _lErro      := .F.
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cID      := Self:ID
   Private _nRec          := If(Empty(Self:REC), 0, Val(Self:REC))
   Private _lWeb          := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)
   Private _cNrOpor       := If(Empty(Self:NROPOR), '', Self:NROPOR)
   Private _cRev          := If(Empty(Self:REVISAO), '', Self:REVISAO)
   Private _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   Private _cProd         := If(Empty(Self:PRODUTO), '', Self:PRODUTO)
   Private _nQuant        := If(Empty((Self:QUANT)), 0,   Val(Self:QUANT))
   Private _nDesc         := If(Empty((Self:DESC)), 0,    Val(Self:DESC))
   Private _cTipo         := If(Empty((Self:TIPO)), 'V',   (Self:TIPO))
   _cErro := ''

   If !_lErro
      // Valida token
      _aToken := u_ValidToken(_cToken)
      If !_aToken[1] 
         _lErro := .T.
         _cErro += _aToken[2]

         SetRestFault(401, _cErro)
         Return .F.
      EndIf
      _cAlias    := AllTrim(_aToken[7])
      _cUserApp  := AllTrim(_aToken[8])
      _cNomeUser := _aToken[4]
      _cCOr      := _aToken[17]
      Conout('[PALM] Propostas - Inclusão de Produto -> Usuario: '+_cNomeUser)

      If _cOper == 'INC'
         _cQuery := "Select Max(ADJ_ITEM) PROXIMO From "+RetSqlName('ADJ')+" Where ADJ_NROPOR = '"+_cNrOpor+"' And D_E_L_E_T_ = ''"
         DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_ADJ",.F.,.T.)
         If Empty(_ADJ->PROXIMO)
            _cItem := '001'
         Else
            _cItem := Soma1(_ADJ->PROXIMO)
         EndIf   
         _ADJ->(DbCloseARea())
         _nQuant  := 0
         _nTot    := 0
         _nPrc    := 0
         _nPrcTab := 0
         _nQSeg   := 0
         _nQTer   := 0
         _nQQua   := 0
         _nQQui   := 0
         _nQSex   := 0

         AD1->(DbSetOrder(1))
         AD1->(DbSeek(xFilial('AD1')+_cNrOpor+_cRev))
         _cTit  := 'Inclusão de Item na Proposta '+AD1->AD1_NROPOR'
         _cPerg := 'Confirma incluir esse item na Proposta?'
         _lE    := .T.
      Else
         ADJ->(DbGoTo(_nRec))
         AD1->(DbSetOrder(1))
         AD1->(DbSeek(xFilial('AD1')+ADJ->(ADJ_NROPOR+ADJ_REVISA)))
         _cItem   := ADJ->ADJ_ITEM
         _nQuant  := ADJ->ADJ_QUANT
         _cProd   := ADJ->ADJ_PROD
         _nTot    := ADJ->ADJ_VALOR
         _nPrc    := ADJ->ADJ_PRUNIT
         _nPrcTab := ADJ->ADJ_XPRTAB
         _nQSeg   := ADJ->ADJ_XSEG
         _nQTer   := ADJ->ADJ_XTER
         _nQQua   := ADJ->ADJ_XQUA
         _nQQui   := ADJ->ADJ_XQUI
         _nQSex   := ADJ->ADJ_XSEX
         _cTipoV  := ADJ->ADJ_XTIPO
         _cTit    := 'Alteração de Item na Proposta '+AD1->AD1_NROPOR'
         _cPerg   := 'Confirma alterar esse item da Proposta?'
         _cNrOpor := AD1->AD1_NROPOR
         _lE      := .F.
      EndIf

      _cGatilho := '/PALM/v1/AppCRM11Gat'
      _aCampos  := {}

      // Tipo = Venda -> Concreto
      If _cTipo == 'V'
         _cGrupoPA := GetMV('APP_GRP_PA',.F.,'0001')
         _cF3SB1A  := '/PALM/v1/AppConsPad'
         _cF3SB1A  += "?CMPRET="   + Escape("{'B1_COD','B1_DESC'}")
         _cF3SB1A += "&CMPBUSCA=" + Escape("B1_COD+B1_DESC")
         _cF3SB1A += "&QUERY="    + Escape("Select Top 100 B1_COD, B1_DESC From "+RetSqlName('SB1')+ " Where D_E_L_E_T_ = '' And B1_MSBLQL <> '1' and B1_GRUPO = '"+_cGrupoPA+"'") // Adicionar Filtro de Concreto
         _cF3SB1A += "&ORDEM="    + Escape("B1_DESC")
         aAdd(_aCampos, {'textfield', 'ADJ_ITEM',   'Item',             03,   If(_lWeb,04, 15), .F., .F., _cItem,    'X',  '',  "",{}})
         aAdd(_aCampos, {'search',    'ADJ_PROD',   'Produto',          15,   If(_lWeb,27, 84), _lE, .T., _cProd,    'X',  _cF3SB1A,  "",{},,,,,,,.T.})
         aAdd(_aCampos, {'decimal',   'ADJ_QUANT',  'Qte. Contrato',    12,   If(_lWeb,07,.F.), .T., .T., _nQuant,   'X',  '',  "",{},,,,,,,.T.})
         aAdd(_aCampos, {'decimal',   'ADJ_XPRTAB', 'Preço Tabela',     10,   If(_lWeb,07,.F.), .F., .F., _nPrcTab,  'X',  '',  "",{}})
         aAdd(_aCampos, {'decimal',   'ADJ_PRUNIT', 'Preço Negociado',  10,   If(_lWeb,07,.F.), .T., .T., _nPrc,     'X',  '',  "",{},,,,,,,.T.})
         aAdd(_aCampos, {'decimal',   'ADJ_VALOR',  'Valor Total',      10,   If(_lWeb,07,.F.), .F., .T., _nTot,     'X',  '',  "",{}})
         aAdd(_aCampos, {'decimal',   'ADJ_XSEG',   'Segunda',          08,   If(_lWeb,07,.F.), .T., .F., _nQSeg,    'X',  '',  "",{}})
         aAdd(_aCampos, {'decimal',   'ADJ_XTER',   'Terça',            08,   If(_lWeb,07,.F.), .T., .F., _nQTer,    'X',  '',  "",{}})
         aAdd(_aCampos, {'decimal',   'ADJ_XQUA',   'Quarta',           08,   If(_lWeb,07,.F.), .T., .F., _nQQua,    'X',  '',  "",{}})
         aAdd(_aCampos, {'decimal',   'ADJ_XQUI',   'Quinta',           08,   If(_lWeb,07,.F.), .T., .F., _nQQui,    'X',  '',  "",{}})
         aAdd(_aCampos, {'decimal',   'ADJ_XSEX',   'Sexta',            08,   If(_lWeb,07,.F.), .T., .F., _nQSex,    'X',  '',  "",{}})
      // Tipo = Locação -> Bombas
      Else
         _cGrupoCM := GetMV('APP_GRP_CM',.F.,'0007')
         _cF3SB1A  := '/PALM/v1/AppConsPad'
         _cF3SB1A  += "?CMPRET="   + Escape("{'B1_COD','B1_DESC'}")
         _cF3SB1A  += "&CMPBUSCA=" + Escape("B1_COD+B1_DESC")
         _cF3SB1A  += "&QUERY="    + Escape("Select Top 100 B1_COD, B1_DESC From "+RetSqlName('SB1')+ " Where D_E_L_E_T_ = '' And B1_MSBLQL <> '1' and B1_GRUPO = '"+_cGrupoCM+"'") // Adicionar Filtro de Bombas
         _cF3SB1A  += "&ORDEM="    + Escape("B1_DESC")
         aAdd(_aCampos, {'textfield', 'ADJ_ITEM',   'Item',               03,   If(_lWeb,05, 15), .F., .F., _cItem,    'X',  '',  "",{}})
         aAdd(_aCampos, {'search',    'ADJ_PROD',   'Selecione a Bomba',  15,   If(_lWeb,50, 84), _lE, .T., _cProd,    'X',  _cF3SB1A,  "",{},,,,,,,.T.})
         aAdd(_aCampos, {'decimal',   'ADJ_XPRTAB', 'Preço Tabela',       10,   If(_lWeb,12, 33), .F., .F., _nPrcTab,  'X',  '',  "",{}})
         aAdd(_aCampos, {'decimal',   'ADJ_PRUNIT', 'Preço Negociado',    10,   If(_lWeb,12, 33), .T., .T., _nPrc,     'X',  '',  "",{},,,,,,,.T.})

         aAdd(_aCampos, {'textfield', 'ADJ_XTIPO',  'Tipo de Venda',    01,   If(_lWeb,19,.T.), .F., .F., 'L',       'X',     '',  "",{{'V','Venda'},{'L','Locação'}},,,,,,,,,,.F.})
         aAdd(_aCampos, {'decimal',   'ADJ_QUANT',  'Quantidade',       08,   If(_lWeb,08,.F.), .F., .F., '1',       'X',  '',  "",{},,,,,,,,,,.F.})
         aAdd(_aCampos, {'decimal',   'ADJ_VALOR',  'Taxa Mínima',      10,   If(_lWeb,08,.F.), .F., .T., _nTot,     'X',  '',  "",{},,,,,,,,,,.F.})
      EndIf
      
      aAdd(_aCampos, {'textfield', 'AD1_NROPOR', 'Oportu.',    06, .F., .F., .F.,  _cNrOpor,     'X', '',  "", {},,,,,,,,,,.F.})
      aAdd(_aCampos, {'textfield', 'AD1_REVISA', 'Revisao',    02, .F., .F., .F.,  _cRev   ,     'X', '',  "", {},,,,,,,,,,.F.})
      aAdd(_aCampos, {'textfield', 'REC',        'RecNo',      10, .F., .F., .F.,  _nRec,        'X', '',  "", {},,,,,,,,,,.F.})

      _cJson := u_JsonEdit(_cTit, _cGatilho, "/PALM/v1/AppCRM11APr?REC="+AllTrim(Str(_nRec))+'&OPER='+_cOper+'&TIPO='+_cTipo, _aCampos,,_cPerg,,,,,,,)//.T.)
      Memowrite('edit.json', _cJson)
      ::setStatus(200)
      ::SetResponse(EncodeUtf8(_cJSON))
      lRet := .T.		
   EndIf

   If _lErro
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf
   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,OPER,TAB,REC,TIPO WSSERVICE AppCRM11APr
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   Private __cUserID := Self:USERID
   Private _cToken   := Self:TOKEN
   Private _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   Private _nRec          := If(Empty(Self:REC), 0, Val(Self:REC))
   Private _cTipo         := If(Empty(Self:TIPO), 'V', Self:TIPO)

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
   conout(cJson)
   ::SetContentType("application/json")
   FWJsonDeserialize((cJson),@oParseJSON)
   Conout('[PALM] Gravando novo item na Proposta | Usuario '+_cNomeUser)

   If _cOper == 'EXC'
      ADJ->(DbGoTo(_nRec))
      RecLock('ADJ', .F.)      
      _cNrOpor := ADJ->ADJ_NROPOR
      _cRev    := ADJ->ADJ_REVISA
      Conout('[PALM] Excluindo item da Proposta '+_cNrOpor+' | Usuario '+_cNomeUser)
      ADJ->(DbDelete())
      ADJ->(MsUnlock())

      _cQueryAD1T := "Select Sum(ADJ_VALOR) VALOR From "+RetSqlName('ADJ')+" Where ADJ_NROPOR = '"+_cNrOpor+"' And D_E_L_E_T_ = '' Group By ADJ_NROPOR"
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryAD1T),"_ADJ",.F.,.T.)
      _nValTot := _ADJ->VALOR
      _ADJ->(DbCloseArea())
      
      AD1->(DbSetOrder(1))
      AD1->(DbSeek(xFilial('AD1')+_cNrOpor+_cRev))
      RecLock('AD1',.F.)
      Replace AD1_RCFECH With _nValTot
      AD1->(MsUnlock())

      _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'"}'
      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson))
      Return .T.      

   ElseIf _cOper == 'ALT'
      ADJ->(DbGoTo(_nRec))
      RecLock('ADJ', .F.)
   Else   
      RecLock('ADJ', .T.)
      Replace ADJ->ADJ_FILIAL With xFilial('ADJ')
      Replace ADJ->ADJ_NROPOR With oParseJson:AD1_NROPOR
      Replace ADJ->ADJ_REVISA With '01' //oParseJson:AD1_REVISA
      Replace ADJ->ADJ_ITEM   With oParseJson:ADJ_ITEM
      Replace ADJ->ADJ_PROD   With oParseJson:ADJ_PROD
   EndIf
   // Concreto
   If _cTipo == 'V'
      _nUnit  := Val(StrTran(StrTran(oParseJson:ADJ_PRUNIT, '.'), ',','.'))
      _nPrTab := Val(StrTran(StrTran(oParseJson:ADJ_XPRTAB, '.'), ',','.'))
      _nQuant := Val(StrTran(StrTran(oParseJson:ADJ_QUANT, '.'), ',','.'))
      Replace ADJ->ADJ_PROD   With oParseJson:ADJ_PROD
      Replace ADJ->ADJ_QUANT  With _nQuant
      Replace ADJ->ADJ_PRUNIT With _nUnit
      Replace ADJ->ADJ_VALOR  With _nQuant*_nUnit
      Replace ADJ->ADJ_XTIPO  With _cTipo
      Replace ADJ->ADJ_XPRTAB With _nPrTab
      Replace ADJ->ADJ_XSEG   With Val(StrTran(StrTran(oParseJson:ADJ_XSEG, '.'), ',','.'))
      Replace ADJ->ADJ_XTER   With Val(StrTran(StrTran(oParseJson:ADJ_XTER, '.'), ',','.'))
      Replace ADJ->ADJ_XQUA   With Val(StrTran(StrTran(oParseJson:ADJ_XQUA, '.'), ',','.'))
      Replace ADJ->ADJ_XQUI   With Val(StrTran(StrTran(oParseJson:ADJ_XQUI, '.'), ',','.'))
      Replace ADJ->ADJ_XSEX   With Val(StrTran(StrTran(oParseJson:ADJ_XSEX, '.'), ',','.'))
   // Bombas
   Else
      _nUnit  := Val(StrTran(StrTran(oParseJson:ADJ_PRUNIT, '.'), ',','.'))
      _nPrTab := Val(StrTran(StrTran(oParseJson:ADJ_XPRTAB, '.'), ',','.'))
      _nQuant := Val(StrTran(StrTran(oParseJson:ADJ_QUANT, '.'), ',','.'))
      Replace ADJ->ADJ_QUANT  With 1
      Replace ADJ->ADJ_PRUNIT With _nUnit
      Replace ADJ->ADJ_VALOR  With _nUnit
      Replace ADJ->ADJ_XTIPO  With _cTipo
      Replace ADJ->ADJ_XPRTAB With _nPrTab
   EndIf
   ADJ->(MsUnlock())

   _cQueryAD1T := "Select Sum(ADJ_VALOR) VALOR From "+RetSqlName('ADJ')+" Where ADJ_NROPOR = '"+ADJ->ADJ_NROPOR+"' And D_E_L_E_T_ = ''  and ADJ_XTIPO = 'V' Group By ADJ_NROPOR"
   DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQueryAD1T),"_ADJ",.F.,.T.)
   _nValTot := _ADJ->VALOR
   _ADJ->(DbCloseArea())

   AD1->(DbSetOrder(1))
   AD1->(DbSeek(xFilial('AD1')+ADJ->ADJ_NROPOR+ADJ->ADJ_REVISA))
   RecLock('AD1',.F.)
   Replace AD1_RCFECH With _nValTot
   AD1->(MsUnlock())

   If _cOper == 'ALT'
      _cJson := u_JsonMsg('Alteração OK!', "Atualização realizada com sucesso!", "success", .T.,'1000',,"/PALM/v1/AppCRM11Add?ID="+oParseJson:AD1_NROPOR)
   Else   
      _cJson := u_JsonMsg('Inclusão OK!',  "Inclusão realizada com sucesso!",    "success", .T.,'1000',,"/PALM/v1/AppCRM11Add?ID="+oParseJson:AD1_NROPOR)
   EndIf
   //_cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+oParseJson:AD1_NROPOR+'"}'
   
   ::setStatus(200)
   ::setResponse(EncodeUTF8(_cJson))
   Return .T.
//


/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* Gatilho de todas as Abas
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCRM11Gat DESCRIPTION "Gatilho da solicitação de serviço - PALM"
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA GRUPO  As String //String que vamos receber via URL

   WSMETHOD POST DESCRIPTION "Gatilho da Solicitação de Serviço" WSSYNTAX "/PALM/v1/AppCRM11Gat" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD POST WSRECEIVE userID,token,GRUPO WSSERVICE AppCRM11Gat
   Local _lRet		  := .T.
   Local _lErro      := .F.
   Local cJSON 	 := Self:GetContent()
   __cUserID := Self:USERID
   _cToken   := Self:TOKEN
   _cGrupo   := GRUPO
   _cErro    := ''

   oParseJSON := Nil
   ::SetContentType("application/json")
   FWJsonDeserialize((cJson),@oParseJSON)

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
      If oParseJSON:TRIGGER $ 'PARCEIRO.VENDEDOR.DATA_ATE'
         _cParceiro := ''
         _cVendedor := ''
         _cData     := oParseJson:valores:DATA_ATE
         If Type('oParseJson:valores:PARCEIRO') == 'C'
            _cParceiro := oParseJson:valores:PARCEIRO
         EndIf   
         If Type('oParseJson:valores:VENDEDOR') == 'C'
            _cVendedor := oParseJson:valores:VENDEDOR
         EndIf   
         //_cJson := u_JsonMsg("Tipo Insumo", "Carregando informações de ", "success", .F.,'500',,'/PALM/v1/AppMNT02AIn?ID='+oParseJSON:valores:ID+'&OPER='+_cOper+'&TAREFA='+_cTarefa)
         _cJson := '{"refresh":"/PALM/v1/APPCRM11?DATA_ATE='+_cData+'&PARCEIRO='+_cParceiro+'&VENDEDOR='+_cVendedor+'"}'
         //_cJson := '{"refresh":"/PALM/v1/APPCRM11"}'
         ::setStatus(200)
         ::SetResponse(encodeUtf8(_cJSON))
         Return .T.
      ElseIf oParseJson:TRIGGER == 'A3_COD'
         SA3->(DbSetOrder(1))
         SA3->(DbSeek(xFilial('SA3')+oParseJson:valores:A3_COD))

         _cJson := '{"A3_COMIS": '+AllTrim(Str(SA3->A3_COMIS,12,2))+'}'   
      ElseIf oParseJson:TRIGGER $ 'AD1_PROSPE'
         SUS->(DbSetOrder(4))
         SUS->(DbSeek(xFilial('SUS')+oParseJson:valores:AD1_PROSPE))
         _cJson := '{'
         _cJson += '    "LAB_CLIENTE":"Dados do Prospect",'
         _cJson += '    "A1_CGC":   "'+AllTrim(SUS->US_CGC)+'",'
         _cJson += '    "A1_CEP":   "'+AllTrim(SUS->US_CEP)+'",'
         _cJson += '    "A1_COMP":  "'+''+'",'
         _cJson += '    "A1_END":   "'+AllTrim(SUS->US_END)+'",'
         _cJson += '    "A1_BAIRRO":"'+AllTrim(SUS->US_BAIRRO)+'",'
         _cJson += '    "A1_CEP":   "'+AllTrim(SUS->US_CEP)+'",'
         _cJson += '    "A1_UF":    "'+AllTrim(SUS->US_EST)+'",'
         _cJson += '    "A1_MUN":   "'+AllTrim(SUS->US_MUN)+'"'
         _cJson += '}'
      ElseIf oParseJson:TRIGGER $ 'AD1_CODCLI'
         SA1->(DbSetOrder(3))
         SA1->(DbSeek(xFilial('SA1')+oParseJson:valores:AD1_CODCLI))
         _cJson := '{'
         _cJson += '    "LAB_CLIENTE":"Dados do Cliente",'
         _cJson += '    "A1_CGC":   "'+AllTrim(SA1->A1_CGC)+'",'
         _cJson += '    "A1_END":   "'+AllTrim(SA1->A1_END)+'",'
         _cJson += '    "A1_BAIRRO":"'+AllTrim(SA1->A1_BAIRRO)+'",'
         _cJson += '    "A1_CEP":   "'+AllTrim(SA1->A1_CEP)+'",'
         _cJson += '    "A1_UF":    "'+AllTrim(SA1->A1_EST)+'",'
         _cJson += '    "A1_MUN":   "'+AllTrim(SA1->A1_MUN)+'"'
         _cJson += '}'
      ElseIf oParseJson:TRIGGER $ 'ENDCLI'
         _cJson := '{"Folder":'
         _cJson += '{'
         _cJson += '    "AD1_XCEP":   "'+AllTrim(oParseJson:valores:A1_CEP)+'",'
         _cJson += '    "AD1_XEND":   "'+AllTrim(oParseJson:valores:A1_END)+'",'
         _cJson += '    "AD1_XBAIR":  "'+AllTrim(oParseJson:valores:A1_BAIRRO)+'",'
         _cJson += '    "AD1_XUF":    "'+AllTrim(oParseJson:valores:A1_UF)+'",'
         _cJson += '    "AD1_XMUN":   "'+AllTrim(oParseJson:valores:A1_MUN)+'"'
         _cJson += '}}'         
      ElseIf oParseJson:TRIGGER $ 'ADJ_PROD.ADJ_QUANT.ADJ_PRUNIT'
         _cQuery := "Select Top 1 DA1_PRCVEN"+Chr(13)+Chr(10)
         _cQuery += "	From "+RetSqlName('DA1')+" DA1"+Chr(13)+Chr(10)
         _cQuery += "	Where DA1_CODPRO = '"+oParseJson:valores:ADJ_PROD+"' And DA1.D_E_L_E_T_ = ''"+Chr(13)+Chr(10)
         _cQuery += "	Order By DA1_ITEM"+Chr(13)+Chr(10)
   		DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_DA1",.F.,.T.)
         _nPrTab := _DA1->DA1_PRCVEN
         _DA1->(DbCloseArea())
         conout(oParseJson:valores:ADJ_PRUNIT)
         _nPreco := Val(StrTran(StrTran(oParseJson:valores:ADJ_PRUNIT,'.',''), ',','.'))
         If oParseJson:TRIGGER == 'ADJ_PROD'
            //_cJson := '{"ADJ_PRUNIT":'+AllTrim(Str(_nPreco))+', "refresh":"/PALM/v1/APPCRM11Apr?PRODUTO='+oParseJson:valores:ADJ_PROD+'&NROPOR='+oParseJson:valores:AD1_NROPOR+'&REVISAO=01'+oParseJson:valores:AD1_REVISA+'"}'
            _cJson := '{"ADJ_PRUNIT":'+AllTrim(Str(_nPrTab))+', "ADJ_XPRTAB":'+AllTrim(Str(_nPrTab))+'}'
         ElseIf oParseJson:TRIGGER $ 'ADJ_QUANT.ADJ_PRUNIT'
            _nTotal := _nPreco * Val(StrTran(StrTran(oParseJson:valores:ADJ_QUANT,'.',''),',','.'))
            //_cJson := '{"ADJ_PRUNIT":'+AllTrim(Str(_nPreco))+', "ADJ_VALOR":'+AllTrim(Str(_nTotal))+', "refresh":"/PALM/v1/APPCRM11Apr?PRODUTO='+oParseJson:valores:ADJ_PROD+'&NROPOR='+oParseJson:valores:AD1_NROPOR+'&REVISAO='+oParseJson:valores:AD1_REVISA+'&USERS='+AllTrim(oParseJson:valores:ADJ_QUANT)+"}'
            _cJson := '{"ADJ_XPRTAB":'+AllTrim(Str(_nPrTab))+', "ADJ_VALOR":'+AllTrim(Str(_nTotal))+'}'
            conout(AllTrim(Str(_nTotal)))
         EndIf   
      EndIf
      
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

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppCRM11AIte - Edita Parceiros/Concorrentes/Vendedores/Evolução de Proposta
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCRM11Ite DESCRIPTION UnEscape("Edita Entidades da Proposta - PALM")
   WSDATA USERID   As String //Json Recebido no corpo da requição
   WSDATA TOKEN    As String //String que vamos receber via URL
   WSDATA OPER     As String //String que vamos receber via URL
   WSDATA REC   As String //String que vamos receber via URL
   WSDATA TAB   As String //String que vamos receber via URL
   WSDATA NROPOR   As String //String que vamos receber via URL
   WSDATA REVISAO  As String //String que vamos receber via URL
   WSDATA SEQ  As String //String que vamos receber via URL
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION Unescape("Edição de Operador") WSSYNTAX "/PALM/v1/AppCRM11Ite" //Disponibilizamos um método do tipo GET
   WSMETHOD POST DESCRIPTION Unescape("Edição de Operador") WSSYNTAX "/PALM/v1/AppCRM11Ite" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,REC,TAB,NROPORE,REVISAO,SEQ,DEVICEID WSSERVICE AppCRM11Ite
   Local _lRet	   := .T.
   Local _lErro   := .F.
   Local _nI
   Private __cUserID      := Self:USERID
   Private _cToken        := Self:TOKEN
   Private _cErro         := ''
   Private _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   Private _cTab          := If(Empty(Self:TAB), '',(Self:TAB))
   Private _nRec          := If(Empty(Self:REC), 0, Val(Self:REC))
   Private _lWeb          := If(!Empty(Self:DEVICEID), If(Self:DEVICEID=='0', .T., .F.), .F.)
   Private _cNrOpor       := If(Empty(Self:NROPOR), '', Self:NROPOR)
   Private _cRev          := If(Empty(Self:REVISAO), '', Self:REVISAO)
   Private _cSeq          := If(Empty(Self:SEQ), '', Self:SEQ)

   // Valida token
   _aToken := u_ValidToken(_cToken)
   If !_aToken[1] 
      _lErro := .T.
      _cErro += _aToken[2]

      SetRestFault(401, _cErro)
   EndIf
   _cNomeUser := _aToken[4]
   _cGrupo    := AllTrim(_aToken[11])

   If !_lErro
      // Vendedor
      If _cTab == 'AD2'
         Conout('[PALM] Editando Vendedor na Proposta | Usuário '+_cNomeUser)

         _cF3SA3 := '/MeliorApp/v1/AppConsPad'
         _cF3SA3 += "?CMPRET="   + Escape("{'A3_COD','A3_NOME'}")
         _cF3SA3 += "&CMPBUSCA=" + Escape("A3_COD+A3_NOME")
         _cF3SA3 += "&QUERY="    + Escape("Select Top 100 A3_COD, A3_NOME From "+RetSqlName('SA3')+" Where D_E_L_E_T_ = ''")
         _cF3SA3 += "&ORDEM="    + Escape("A3_NOME")            
         If _cOper == 'INC'
            _cVend  := ''
            _cNome  := ''
            _nComis := 0
            _cTit   := 'Inclusão de Vendedor '   
            _cPerg  := 'Confirma incluir o vendedor nessa proposta?' 
         ElseIf _cOper == 'ALT'
            AD2->(DbGoTo(_nRec))
            SA3->(DbSetOrder(1))
            SA3->(DbSeek(xFilial('SA3')+AD2->AD2_VEND))

            _cNrOpor := AD2->AD2_NROPOR
            _cRev    := AD2->AD2_REVISA
            _cVend   := AD2->AD2_VEND
            _cNome   := SA3->A3_NOME
            _nComis  := AD2->AD2_PERC
            _cTit    := 'Edição Vendedor '+  AD2->AD2_VEND   
            _cPerg   := 'Confirma alterar os dados desse vendedor?' 
         EndIf

         _aCampos := {}   
         aAdd(_aCampos, {'search',    'A3_COD' ,  'Código',   06, If(_lWeb,80, 75), _cOper=='INC', .T.,  _cVend,   'X',  _cF3SA3,  "", {},,,,,,,.T.})
         aAdd(_aCampos, {'decimal',   'A3_COMIS', 'Comissão', 10, If(_lWeb,20, 24), .T., .F.,  (_nComis),  'X', '',  "", {}})
         _cGatilho := '/PALM/v1/APPCRM11Gat'

      // Concorrente
      ElseIf _cTab == 'AD3'
         Conout('[PALM] Editando Concorrente na Proposta | Usuario '+_cNomeUser)

         _cF3AC3 := '/MeliorApp/v1/AppConsPad'
         _cF3AC3 += "?CMPRET="   + Escape("{'AC3_CODCON','AC3_NOME'}")
         _cF3AC3 += "&CMPBUSCA=" + Escape("AC3_CODCON+AC3_NOME")
         _cF3AC3 += "&QUERY="    + Escape("Select Top 100 AC3_CODCON, AC3_NOME From "+RetSqlName('AC3')+" Where D_E_L_E_T_ = ''")
         _cF3AC3 += "&ORDEM="    + Escape("AC3_NOME")            
         If _cOper == 'INC'
            _cCodCon := ''
            _nPreco  := 0
            _cTit    := 'Inclusão de Concorrente'   
            _cPerg   := 'Confirma incluir o concorrente nessa proposta?' 
         ElseIf _cOper == 'ALT'
            AD3->(DbGoTo(_nRec))
            AC3->(DbSetOrder(1))
            AC3->(DbSeek(xFilial('AD3')+AD3->AD3_CODCON))

            _cNrOpor  := AD3->AD3_NROPOR
            _cRev     := AD3->AD3_REVISA
            _cCodCon  := AD3->AD3_CODCON
            _nPreco   := AD3->AD3_PRECO
            _cTit     := 'Edição Concorrente '+  AC3->AC3_CODCON   
            _cPerg    := 'Confirma alterar os dados desse concorrente?' 
         EndIf

         _aCampos := {}   
         aAdd(_aCampos, {'search',    'AD3_CODCON' ,  'Código',   06, If(_lWeb,80, 75), _cOper=='INC', .T.,  _cCodCon,   'X',  _cF3AC3,  "", {},"/PALM/v1/AppCRM11ITE?OPER=INC&TAB=AC3",,,,,,})
         aAdd(_aCampos, {'decimal',   'AD3_PRECO',    'Preço',    10, If(_lWeb,20, 24), .T., .F.,           (_nPreco),  'X', '',  "", {}})
         _cGatilho := ''

      // Parceiro
      ElseIf _cTab == 'AD4'
         Conout('[PALM] Editando Parceiro na Proposta | Usuario '+_cNomeUser)

         _cF3AC4 := '/MeliorApp/v1/AppConsPad'
         _cF3AC4 += "?CMPRET="   + Escape("{'AC4_PARTNE','AC4_NOME'}")
         _cF3AC4 += "&CMPBUSCA=" + Escape("AC4_PARTNE+AC4_NOME")
         _cF3AC4 += "&QUERY="    + Escape("Select Top 100 AC4_PARTNE, AC4_NOME From "+RetSqlName('AC4')+" Where D_E_L_E_T_ = ''")
         _cF3AC4 += "&ORDEM="    + Escape("AC4_NOME")            
         If _cOper == 'INC'
            _cParce  := ''
            _cTit    := 'Inclusão de Parceiro'   
            _cPerg   := 'Confirma incluir o parceiro nessa proposta?' 
         ElseIf _cOper == 'ALT'
            AD4->(DbGoTo(_nRec))
            AC4->(DbSetOrder(1))
            AC4->(DbSeek(xFilial('AC4')+AD4->AD4_PARTNE))

            _cNrOpor  := AD4->AD4_NROPOR
            _cRev     := AD4->AD4_REVISA
            _cParce   := AD4->AD4_PARTNE
            _cTit     := 'Edição Parceiro '+  AC4->AC4_PARTNE   
            _cPerg    := 'Confirma alterar os dados desse concorrente?' 
         EndIf

         _aCampos := {}   
         aAdd(_aCampos, {'search',    'AD4_PARTNE' ,  'Código do Parceiro',   06, .T., _cOper=='INC', .T.,  _cParce,   'X',  _cF3AC4,  "", {}}) //,"/PALM/v1/AppCRM11ITE?OPER=INC&TAB=AC3",,,,,,})
         _cGatilho := ''
      // Evolução da Venda
      ElseIf _cTab == 'AIJ'
         Conout('[PALM] Editando Evolucao de Venda na Proposta | Usuario '+_cNomeUser)

         If _cOper == 'INC'
            _cProcesso  := ''
            _dInicio    := dDataBase
            _cInicio    := '09:00'
            _dLimite    := dDataBase + 30
            _cLimite    := '18:00'
            _dEncerr    := CtoD('')
            _cEncerr    := ''
            _cObs       := ''
            _cTit   := 'Evolução de Venda '   
            _cPerg  := 'Confirma incluir esse estágio nessa proposta?' 
         ElseIf _cOper == 'ALT'
            AIJ->(DbGoTo(_nRec))
            AC2->(DbSetOrder(1))
            AC2->(DbSeek(xFilial('AC2')+AIJ->AIJ_PROVEN+AIJ->AIJ_STAGE))

            _cNrOpor    := AIJ->AIJ_NROPOR
            _cRev       := AIJ->AIJ_REVISA
            _cProcesso  := AIJ->(AIJ_PROVEN+AIJ_STAGE)
            _dInicio    := AIJ->AIJ_DTINIC
            _cInicio    := AIJ->AIJ_HRINIC
            _dLimite    := AIJ->AIJ_DTLIMI
            _cLimite    := AIJ->AIJ_HRLIMI
            _dEncerr    := AIJ->AIJ_DTENCE
            _cEncerr    := AIJ->AIJ_HRENCE
            _cObs       := AIJ->AIJ_XOBS
            _cTit    := 'Edição - Evolução de venda '+  AIJ->AIJ_STAGE   
            _cPerg   := 'Confirma alterar os dados desse estágio?' 
         EndIf

         AD1->(DbSetOrder(1))
         AD1->(DbSeek(xFilial('AD1')+AIJ->(AIJ_NROPOR+AIJ_REVISA)))

         AC2->(DbSetOrder(1))
         AC2->(DbSeek(xFilial('AC2')+AD1->AD1_PROVEN))
         _nPerc    := 0
         _aProcVen := {}
         Do While !AC2->(EoF()) .and. AC2->AC2_FILIAL == xFilial('AC2') .and. AC2->AC2_PROVEN == AD1->AD1_PROVEN
            _nPerc    := _nPerc + AC2->AC2_RELEVA 
            _cProAnt  := AC2->AC2_PROVEN
            aAdd(_aProcVen, {AC2->AC2_PROVEN+AC2->AC2_STAGE, AllTrim(AC2->AC2_DESCRI)+' ('+AllTrim(Str(_nPerc))+'%)'})
            AC2->(DbSkip())
            If _cProAnt <> AC2->AC2_PROVEN
               _nPerc := 0
            EndIf
         EndDo           

         _aCampos := {}   
         aAdd(_aCampos, {'dropdown',  'AIJ_STAGE', 'Processo de Venda',  06, If(_lWeb,50,.T.), _cOper=='INC', .T.,  _cProcesso,     'X',  '',  "",_aProcVen})
         aAdd(_aCampos, {'date',      'AIJ_DTINIC','Data Início',        10, If(_lWeb,12,.F.), _cOper=='INC', .T.,  _dInicio,       'X',  '',  "", {}})
         aAdd(_aCampos, {'time',      'AIJ_HRINIC','Hora Início',        05, If(_lWeb,13,.F.), _cOper=='INC', .T.,  _cInicio,       'X',  '',  "", {}})
         aAdd(_aCampos, {'date',      'AIJ_DTLIMI','Data Limite',        10, If(_lWeb,12,.F.), _cOper=='INC', .T.,  _dLimite,       'X',  '',  "", {}})
         aAdd(_aCampos, {'time',      'AIJ_HRLIMI','Hora Limite',        05, If(_lWeb,12,.F.), _cOper=='INC', .T.,  _cLimite,       'X',  '',  "", {}})
         aAdd(_aCampos, {'date',      'AIJ_DTENCE','Data Encerra',       10, If(_lWeb,13,.F.), .T., .F.,  _dEncerr,       'X',  '',  "", {}})
         aAdd(_aCampos, {'time',      'AIJ_HRENCE','Hora Encerra',       05, If(_lWeb,12,.F.), .T., .F.,  _cEncerr,       'X',  '',  "", {}})
         aAdd(_aCampos, {'time',      'AIJ_XOBS',  'Observação',        250, If(_lWeb,12,.F.), .T., .F.,  _cObs,          'X',  '',  "", {},.T.})
         _cGatilho := '/PALM/v1/APPCRM11Gat'
      // Agenda da Proposta
      ElseIf _cTab == 'AD7'
         Conout('[PALM] Editando Agenda da Proposta | Usuario '+_cNomeUser)

         If _cOper == 'INC'
            _dInicio    := dDataBase
            _cInicio    := '08:00'
            _cFim       := '10:00'
            _nAlerta    := 15
            _cTpAler    := 'M'
            _cVend      := ''//__cUserID
            _cOrigem    := '1'
            _cAgeReu    := '1'
            _cLocal     := ''
            _cObs       := ''
            _cEmail     := ''
            _cTit   := 'Agendamento '   
            _cPerg  := 'Confirma incluir esse agendamento nessa proposta?' 
         ElseIf _cOper == 'ALT'
            AD7->(DbGoTo(_nRec))

            _cNrOpor    := AD7->AD7_NROPOR
            _cRev       := ''
            _dInicio    := AD7->AD7_DATA
            _cInicio    := AD7->AD7_HORA1
            _cFim       := AD7->AD7_HORA2
            _nAlerta    := AD7->AD7_ALERTA
            _cTpAler    := AD7->AD7_TPALER
            _cVend      := AD7->AD7_VEND
            _cOrigem    := AD7->AD7_ORIGEM
            _cAgeReu    := AD7->AD7_AGEREU
            _cLocal     := AD7->AD7_LOCAL
            _cObs       := AD7->AD7_XOBS
            _cEmail     := AD7->AD7_EMAILP
            _cTit    := 'Edição - Agendamento' 
            _cPerg   := 'Confirma alterar os dados desse vendedor?' 
         EndIf

         _cF3SA3 := '/MeliorApp/v1/AppConsPad'
         _cF3SA3 += "?CMPRET="   + Escape("{'A3_COD','A3_NOME'}")
         _cF3SA3 += "&CMPBUSCA=" + Escape("A3_COD+A3_NOME")
         _cF3SA3 += "&QUERY="    + Escape("Select Top 100 A3_COD, A3_NOME From "+RetSqlName('SA3')+" SA3, "+RetSqlName('AD2')+" AD2 Where A3_COD = AD2_VEND And AD2_NROPOR = '"+_cNrOpor+"' And SA3.D_E_L_E_T_ = '' And AD2.D_E_L_E_T_ = ''")
         _cF3SA3 += "&ORDEM="    + Escape("A3_NOME")   

         AD1->(DbSetOrder(1))
         AD1->(DbSeek(xFilial('AD1')+AD7->(AD7_NROPOR)))
         _aOrigem := {{'1','Manual'},{'2','Visita Programada'}}
         _aTipo   := {{"1","Reunião Presencial"},{"2","Reunião Remota"},{"3","Demo Presencial"},{"4","Demo Remota"},{"5","Levantamento Presencial"},{"6","Levantamento Remoto","Agendamento"}}
         _aCampos := {}   
         aAdd(_aCampos, {'date',      'AD7_DATA',  'Data',               10, If(_lWeb,08, 33), _cOper=='INC', .T.,  _dInicio,       'X',  '',  "", {}})
         aAdd(_aCampos, {'time',      'AD7_HORA1', 'Hora Início',        05, If(_lWeb,08, 33), _cOper=='INC', .T.,  _cInicio,       'X',  '',  "", {}})
         aAdd(_aCampos, {'time',      'AD7_HORA2', 'Hora Fim',           05, If(_lWeb,08, 33), _cOper=='INC', .T.,  _cFim,          'X',  '',  "", {}})
         aAdd(_aCampos, {'numeric',   'AD7_ALERTA','Alerta (dias)',      04, If(_lWeb,08, 33), _cOper=='INC', .T.,  _nAlerta,       'X',  '',  "", {}})
         aAdd(_aCampos, {'search',    'AD7_VEND',  'Vendedor',           06, If(_lWeb,27, 66), .T., .T.,            _cVend,         'X',  _cF3SA3,  "", {}})
         aAdd(_aCampos, {'dropdown',  'AD7_ORIGEM','Origem',             01, If(_lWeb,20,.F.), .T., .F.,            _cOrigem,       'X',  '',  "", _aOrigem})
         aAdd(_aCampos, {'dropdown',  'AD7_AGEREU','Tipo Agenda',        01, If(_lWeb,20,.F.), .T., .F.,            _cAgeReu,       'X',  '',  "", _aTipo})
         aAdd(_aCampos, {'textfield', 'AD7_LOCAL', 'Local',              70, If(_lWeb,33,.T.), .T., .F.,            _cLocal,        'X',  '',  "", {}})
         aAdd(_aCampos, {'textfield', 'AD7_XOBS',  'Observação',        250, If(_lWeb,33,.T.), .T., .F.,            _cObs,          'X',  '',  "", {},.T.})
         aAdd(_aCampos, {'textfield', 'AD7_EMAILP','E-mail Particular', 250, If(_lWeb,33,.T.), .T., .F.,            _cEmail,        'X',  '',  "", {},.T.})
         _cGatilho := '/PALM/v1/APPCRM11Gat'

      // Incluindo Cadastro de Concorrente
      ElseIf _cTab == 'AC3'
         Conout('[PALM] Adicionando Concorrente AC3 | Usuario '+_cNomeUser)
         _cVend  := ''
         _cNome  := ''
         _nComis := 0
         _cTit   := 'Inclusão de Vendedor '   
         _cPerg  := 'Confirma incluir o vendedor nessa proposta?' 

         _aCampos := {}   
         aAdd(_aCampos, {'textfield',   'AC3_CODCON' ,  'Código',    06, If(_lWeb,10, 20), .F., .T.,  'Novo...',   'X',  '',  "", {},,,,,,,.T.})
         aAdd(_aCampos, {'textfield',   'AC3_NOME',     'Nome',      40, If(_lWeb,45, 79), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_NREDUZ',   'Fantasia',  20, If(_lWeb,20, 30), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_END',      'Endereço',  40, If(_lWeb,24, 69), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_BAIRRO',   'Bairro',    30, If(_lWeb,18, 50), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_MUN',      'Município', 15, If(_lWeb,18, 49), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_CEP',      'CEP',       08, If(_lWeb,10, 30), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_EST',      'UF',        02, If(_lWeb,06, 20), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_TEL',      'Fone',      15, If(_lWeb,10, 49), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_CONTAT',   'Contato',   15, If(_lWeb,15, 40), .T., .F.,  '',     'X', '',  "", {}})
         aAdd(_aCampos, {'textfield',   'AC3_HPAGE',    'Site',      30, If(_lWeb,20, 59), .T., .F.,  '',     'X', '',  "", {}})
         _cGatilho := '/PALM/v1/APPCRM11Gat'
      // Configurando Taxas da proposta
      ElseIf _cTab == 'PA0'
         Conout('[PALM] Configurando taxas da proposta | Usuario '+_cNomeUser)
         _cVend  := ''
         _cNome  := ''
         _nComis := 0
         _cTit   := 'Configurando Taxa '   
         _cPerg  := 'Confirma atualizar essa taxa para a proposta?' 

         AD1->(DbSetOrder(1))
         AD1->(DbSeek(xFilial('AD1')+_cNrOpor+_cRev))

         PA0->(DbSetOrder(1))
         PA0->(DbSeek(_cSeq))
         _nPos := At(_cSeq, AD1->AD1_XTAXAS)
         If !Empty(_nPos)
            _cTexto1 := Substr(AD1->AD1_XTAXAS, _nPos+8, 100)
            _nPos    := At(Chr(13)+Chr(10), _cTexto1)
            _cTexto  := Left(_cTexto1, _nPos-1)
         EndIf
         _aVars := Separa(_cTexto, '|')
         VarInfo('_aVars', _aVars)
         _aCampos := {}   
         aAdd(_aCampos, {'textfield', 'PA0_SEQ' ,    'Sequência',               2, If(_lWeb,06, .F.), .F., .T.,  PA0->PA0_SEQ,        'X',    ,  "", {}})
         aAdd(_aCampos, {'textfield', 'PA0_FORMUL' , 'Texto atual',           254, If(_lWeb,93, .T.), .F., .T.,  u_RetTxtFim(_cSeq, _cTexto),     'x',    ,  "", {}})

         // Percorre String em busca de camopos editáveis (5 niveis apenas)
         For _nI := 1 To 10
            _cTxt := '#'+StrZero(_nI,2)
            _nPos := aScan(_aVars, _cTxt)
            If !Empty(_nPos)
               _aSepVar := Separa(_aVars[_nPos], ':') 
               aAdd(_aCampos, {'textfield', 'TXT'+StrZero(_nI,2) ,  'Campo #'+StrZero(_nI,2), 10, If(_lWeb,10, .F.), .T., .T.,  _aSepVar[2],    'x',    ,  "", {},,,,,,,.T.})  //&('_cTxt'+StrZero(_nI,2))
               /*
               // Verifica se já existe preenchido
               If _cTxt $ PA0->PA0_FORMUL
                  aAdd(_aCampos, {'textfield', 'TXT'+StrZero(_nI,2) ,  'Campo #'+StrZero(_nI,2), 10, If(_lWeb,10, .F.), .T., .T.,  '',    'x',    ,  "", {},,,,,,,.T.})  //&('_cTxt'+StrZero(_nI,2))
               EndIf
               */
            EndIf   
         Next         
         _cGatilho := '/PALM/v1/APPCRM11Gat'      
         aAdd(_aCampos, {'textfield', 'SEQ',     'SEQ',       06, .F., .F., .F.,  _cSeq,       'X', '',  "", {},,,,,,,,,,.F.})
         aAdd(_aCampos, {'textfield', 'TEXTO',   'TEXTO',    100, .F., .F., .F.,  StrTran(_cTexto, Chr(13)+Chr(10)),     'X', '',  "", {},,,,,,,,,,.F.})
      // Pagamentos da Proposta
      ElseIf _cTab == 'AD6'
         Conout('[PALM] Editando Pagamentos da Proposta | Usuario '+_cNomeUser)

         If _cOper == 'INC'
            _dData      := dDataBase
            _cCond      := ''
            _cTipo      := ''
            _cOper      := ''
            _nValor     := 0
            _cObs       := ''
            _nParc      := 0
            _cAut       := ''

            _cTit   := 'Agendamento '   
            _cPerg  := 'Confirma incluir esse agendamento nessa proposta?' 
         ElseIf _cOper == 'ALT'
            AD6->(DbGoTo(_nRec))
            _cNrOpor    := AD6->AD6_XNROPO
            _cRev       := AD6->AD6_XREVIS
            _dData      := AD6->AD6_DATA
            _cCond      := AD6->AD6_XCOND
            _cTipo      := AD6->AD6_XTIPO
            _cOper      := AD6->AD6_XOPER
            _nValor     := AD6->AD6_TOTAL
            _nParc      := AD6->AD6_XNPARC
            _cAut       := AD6->AD6_XAUT
            _cObs       := AllTrim(AD6->AD6_XOBS)

            _cTit    := 'Edição - Agendamento' 
            _cPerg   := 'Confirma alterar os dados desse vendedor?' 
         EndIf

         _cF3SX51 := '/PALM/v1/AppConsPad'
         _cF3SX51 += "?CMPRET="   + Escape("{'X5_CHAVE','X5_DESCRI'}")
         _cF3SX51 += "&CMPBUSCA=" + Escape("X5_CHAVE+X5_DESCRI")
         _cF3SX51 += "&QUERY="    + Escape("Select X5_CHAVE,X5_DESCRI From "+RetSqlName('SX5')+" Where X5_TABELA = '_1' And D_E_L_E_T_ = ''")
         _cF3SX51 += "&ORDEM="    + Escape("X5_CHAVE")

         _cF3SX52 := '/PALM/v1/AppConsPad'
         _cF3SX52 += "?CMPRET="   + Escape("{'X5_CHAVE','X5_DESCRI'}")
         _cF3SX52 += "&CMPBUSCA=" + Escape("X5_CHAVE+X5_DESCRI")
         _cF3SX52 += "&QUERY="    + Escape("Select X5_CHAVE,X5_DESCRI From "+RetSqlName('SX5')+" Where X5_TABELA = '_2' And D_E_L_E_T_ = ''")
         _cF3SX52 += "&ORDEM="    + Escape("X5_CHAVE")
 
         _aOper   := {{'402','GETNET'},{'999','OUTRAS'}}
         _aCampos := {}   
         aAdd(_aCampos, {'date',      'AD6_DATA',   'Data',                 10, If(_lWeb,09, 33), .T., .T.,  _dData,         'X',  '',  "", {}})
         aAdd(_aCampos, {'search',    'AD6_XCOND',  'Condição de Pagamento',02, If(_lWeb,30,.T.), .T., .T.,  _cCond,         'X',  _cF3SX51, "", {}})
         aAdd(_aCampos, {'search',    'AD6_XTIPO',  'Tipo de Cobrança',     02, If(_lWeb,30,.T.), .T., .F.,  _cTipo,         'X',  _cF3SX52, "", {}})
         aAdd(_aCampos, {'dropdown',  'AD6_XOPER',  'Bandeira',             03, If(_lWeb,30,.T.), .T., .F.,  _cOper,         'X',   '',  "", _aOper})
         aAdd(_aCampos, {'decimal',   'AD6_TOTAL',  'Valor Total',          10, If(_lWeb,12,.T.), .T., .F.,  _nValor ,       '#',  '',  "", {}})
         aAdd(_aCampos, {'textfield', 'AD6_XAUT',   'Num.Autorização',      20, If(_lWeb,20,.T.), .T., .F.,  _cAut ,         'X',  '',  "", {}})
         aAdd(_aCampos, {'textfield', 'AD6_XOBS',   'Observação',           50, If(_lWeb,67,.T.), .T., .F.,  _cObs,          'X',  '',  "", {}})
         _cGatilho := '/PALM/v1/APPCRM11Gat'
      EndIf
      
      aAdd(_aCampos, {'textfield', 'AD1_NROPOR', 'Oportu.',    06, .F., .F., .F.,  _cNrOpor,     'X', '',  "", {},,,,,,,,,,.F.})
      aAdd(_aCampos, {'textfield', 'AD1_REVISA', 'Revisao',    02, .F., .F., .F.,  _cRev   ,     'X', '',  "", {},,,,,,,,,,.F.})
      aAdd(_aCampos, {'textfield', 'REC',        'RecNo',      10, .F., .F., .F.,  _nRec,        'X', '',  "", {},,,,,,,,,,.F.})

      _cJson := u_JsonEdit(_cTit, _cGatilho, "/PALM/v1/AppCRM11ITE?OPER="+_cOper+'&TAB='+_cTab, _aCampos,,_cPerg)
      ::SetResponse(EncodeUTF8(_cJSON))
      lRet := .T.	        
   Else
      SetRestFault(400, _cErro)
      _lRet := .F.
   EndIf

   Return(_lRet)
//
WSMETHOD POST WSRECEIVE userID,token,OPER,TAB,REC WSSERVICE AppCRM11Ite
   Local _lErro      := .F.
   Local cJSON 	   := Self:GetContent()
   Local _nI
   Private __cUserID := Self:USERID
   Private _cToken   := Self:TOKEN
   Private _cOper         := If(Empty(Self:OPER), 'INC', Self:OPER)
   Private _cTab          := If(Empty(Self:TAB), '',(Self:TAB))
   Private _nRec          := If(Empty(Self:REC), 0, Val(Self:REC))

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
  
   If _cTab == 'AD2'
      If _cOper == 'EXC'
         Conout('[PALM] Excluindo Vendedor na Proposta | Usuario '+_cNomeUser)
         AD2->(DbGoTo(_nRec))
         _cNrOpor := AD2->AD2_NROPOR
         RecLock('AD2',.F.)
         AD2->(DbDelete())
         AD2->(MsUnlock())
         //_cJson := u_JsonMsg('Exclusão OK!',  "Exclusão realizada com sucesso!",    "success", .F.,'1500',,"/PALM/v1/AppCRM11Add?ID="+_cNrOpor)
         _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'"}'
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
         Return .T.
      EndIf

      Conout('[PALM] Gravando Vendedor na Proposta | Usuario '+_cNomeUser)
      If _cOper == 'INC'
         RecLock('AD2', .T.)
         Replace AD2->AD2_FILIAL With xFilial('AD2')
         Replace AD2->AD2_NROPOR With oParseJson:AD1_NROPOR
         Replace AD2->AD2_REVISA With oParseJson:AD1_REVISA
         Replace AD2->AD2_VEND   With oParseJson:A3_COD
      Else
         AD2->(DbGoTo(Val(oParseJson:REC)))
         RecLock('AD2', .F.)
      EndIf
      Replace AD2->AD2_PERC With Val(oParseJson:A3_COMIS)
      AD2->(MsUnlock())
   
   // Concorrente
   ElseIf _cTab == 'AD3'
      If _cOper == 'EXC'
         Conout('[PALM] Excluindo Concorrente na Proposta | Usuario '+_cNomeUser)
         AD3->(DbGoTo(_nRec))
         _cNrOpor := AD3->AD3_NROPOR
         RecLock('AD3',.F.)
         AD3->(DbDelete())
         AD3->(MsUnlock())
         //_cJson := u_JsonMsg('Exclusão OK!',  "Exclusão realizada com sucesso!",    "success", .F.,'1500',,"/PALM/v1/AppCRM11Add?ID="+_cNrOpor)
         _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'"}'
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
         Return .T.
      EndIf

      Conout('[PALM] Gravando Concorrente na Proposta | Usuario '+_cNomeUser)
      If _cOper == 'INC'
         RecLock('AD3', .T.)
         Replace AD3->AD3_FILIAL With xFilial('AD2')
         Replace AD3->AD3_NROPOR With oParseJson:AD1_NROPOR
         Replace AD3->AD3_REVISA With oParseJson:AD1_REVISA
         Replace AD3->AD3_CODCON With oParseJson:AD3_CODCON
      Else
         AD3->(DbGoTo(Val(oParseJson:REC)))
         RecLock('AD3', .F.)
      EndIf
      Replace AD3->AD3_PRECO With Val(StrTran(oParseJson:AD3_PRECO,".",""))
      AD3->(MsUnlock())      

   // Parceiro
   ElseIf _cTab == 'AD4'
      If _cOper == 'EXC'
         Conout('[PALM] Excluindo Concorrente na Proposta | Usuario '+_cNomeUser)
         AD4->(DbGoTo(_nRec))
         _cNrOpor := AD4->AD4_NROPOR
         RecLock('AD4',.F.)
         AD4->(DbDelete())
         AD4->(MsUnlock())
         //_cJson := u_JsonMsg('Exclusão OK!',  "Exclusão realizada com sucesso!",    "success", .F.,'1500',,"/PALM/v1/AppCRM11Add?ID="+_cNrOpor)
         _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'"}'
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
         Return .T.
      EndIf
      Conout('[PALM] Gravando Parceiro na Proposta | Usuario '+_cNomeUser)
      If _cOper == 'INC'
         RecLock('AD4', .T.)
         Replace AD4->AD4_FILIAL With xFilial('AD4')
         Replace AD4->AD4_NROPOR With oParseJson:AD1_NROPOR
         Replace AD4->AD4_REVISA With oParseJson:AD1_REVISA
         Replace AD4->AD4_PARTNE With oParseJson:AD4_PARTNE
      EndIf
      AD4->(MsUnlock())   

   // Evolução da Venda
   ElseIf _cTab == 'AIJ'
      If _cOper == 'EXC'
         Conout('[PALM] Excluindo Evolucao de venda na Proposta | Usuario '+_cNomeUser)
         AIJ->(DbGoTo(_nRec))
         _cNrOpor := AIJ->AIJ_NROPOR
         conout(_nRec)
         conout(_cNrOpor)
         RecLock('AIJ',.F.)
         AIJ->(DbDelete())
         AIJ->(MsUnlock())
         //_cJson := u_JsonMsg('Exclusão OK!',  "Exclusão realizada com sucesso!",    "success", .F.,'1500',,"/PALM/v1/AppCRM11Add?ID="+_cNrOpor)
         _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'"}'
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
         Return .T.
      EndIf
      Conout('[PALM] Gravando Evolucao de Venda na Proposta | Usuario '+_cNomeUser)
      If _cOper == 'INC'
         RecLock('AIJ', .T.)
         Replace AIJ->AIJ_FILIAL With xFilial('AD4')
         Replace AIJ->AIJ_NROPOR With oParseJson:AD1_NROPOR
         Replace AIJ->AIJ_REVISA With oParseJson:AD1_REVISA
         Replace AIJ->AIJ_PROVEN With Left(oParseJson:AIJ_STAGE,6)
         Replace AIJ->AIJ_STAGE  With Substring(oParseJson:AIJ_STAGE,7,6)
      Else
         AIJ->(DbGoTo(Val(oParseJson:REC)))
         RecLock('AIJ', .F.)
      EndIf
      Replace AIJ->AIJ_DTINIC With CtoD(oParseJson:AIJ_DTINIC)
      Replace AIJ->AIJ_HRINIC With (oParseJson:AIJ_HRINIC)
      Replace AIJ->AIJ_DTLIMI With CtoD(oParseJson:AIJ_DTLIMI)
      Replace AIJ->AIJ_HRLIMI With (oParseJson:AIJ_HRLIMI)
      Replace AIJ->AIJ_DTENCE With CtoD(oParseJson:AIJ_DTENCE)
      Replace AIJ->AIJ_HRENCE With (oParseJson:AIJ_HRENCE)
      Replace AIJ->AIJ_XOBS   With (oParseJson:AIJ_XOBS)
      AIJ->(MsUnlock())   

   // Agendamento
   ElseIf _cTab == 'AD7'
      If _cOper == 'EXC'
         Conout('[PALM] Excluindo Agendamento da Proposta | Usuario '+_cNomeUser)
         AD7->(DbGoTo(_nRec))
         _cNrOpor := AD7->AD7_NROPOR
         conout(_nRec)
         conout(_cNrOpor)
         RecLock('AD7',.F.)
         AD7->(DbDelete())
         AD7->(MsUnlock())
         //_cJson := u_JsonMsg('Exclusão OK!',  "Exclusão realizada com sucesso!",    "success", .F.,'1500',,"/PALM/v1/AppCRM11Add?ID="+_cNrOpor)
         _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'"}'
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
         Return .T.
      EndIf
      Conout('[PALM] Gravando Agendamento da Proposta | Usuario '+_cNomeUser)
      If _cOper == 'INC'
         RecLock('AD7', .T.)
         Replace AD7->AD7_NROPOR With oParseJson:AD1_NROPOR
         Replace AD7->AD7_DATA   With CtoD(oParseJson:AD7_DATA)
         Replace AD7->AD7_HORA1  With oParseJson:AD7_HORA1
         Replace AD7->AD7_HORA2  With oParseJson:AD7_HORA2
         Replace AD7->AD7_ALERTA With Val(oParseJson:AD7_ALERTA)
         Replace AD7->AD7_TPALER With '3'
         Replace AD7->AD7_VEND   With oParseJson:AD7_VEND
         Replace AD7->AD7_ORIGEM With oParseJson:AD7_ORIGEM
         Replace AD7->AD7_AGEREU With oParseJson:AD7_AGEREU
      Else
         AD7->(DbGoTo(Val(oParseJson:REC)))
         RecLock('AD7', .F.)
      EndIf
      Replace AD7->AD7_LOCAL  With oParseJson:AD7_LOCAL
      Replace AD7->AD7_XOBS   With oParseJson:AD7_XOBS
      Replace AD7->AD7_EMAILP With oParseJson:AD7_EMAILP
      AD7->(MsUnlock())   

   // Cadastro de Concorrentes
   ElseIf _cTab == 'AC3'
      Conout('[PALM] Gravando novo concorrente | Usuario '+_cNomeUser)

      _cQuery := "Select Max(AC3_CODCON) PROXIMO From "+RetSqlName('AC3')
      DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_AC3",.F.,.T.)
      If Empty(_AC3->PROXIMO)
         _cProximo := '000001'
      Else
         _cProximo := Soma1(_AC3->PROXIMO)
      EndIf   
      _AC3->(DbCloseARea())

      RecLock('AC3', .T.)
      Replace AC3->AC3_FILIAL With xFilial('AC3')
      Replace AC3->AC3_CODCON With _cProximo
      Replace AC3->AC3_NOME   With oParseJson:AC3_NOME
      Replace AC3->AC3_NREDUZ With oParseJson:AC3_NREDUZ
      Replace AC3->AC3_END    With oParseJson:AC3_END
      Replace AC3->AC3_MUN    With oParseJson:AC3_MUN
      Replace AC3->AC3_EST    With oParseJson:AC3_EST
      Replace AC3->AC3_BAIRRO With oParseJson:AC3_BAIRRO
      Replace AC3->AC3_CEP    With oParseJson:AC3_CEP
      Replace AC3->AC3_TEL    With oParseJson:AC3_TEL
      Replace AC3->AC3_CONTAT With oParseJson:AC3_CONTAT
      Replace AC3->AC3_HPAGE  With oParseJson:AC3_HPAGE
      AC3->(MsUnlock())
      _cJson := u_JsonMsg('Inclusão OK!',  "Inclusão realizada com sucesso!",    "success", .T.,'1000',,)
      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson))
      Return .T.

   // Taxas da Proposta
   ElseIf _cTab == 'PA0'
      Conout('[PALM] Atualizando taxa da Proposta | Usuario '+_cNomeUser)
      varInfo('oparseJson', oParseJson)
      
      _cNewTaxa := oParseJson:SEQ+'\'
      For _nI := 1 To 10
         If Type('oParseJson:TXT'+StrZero(_nI,2)) == 'C'
            _cNewTaxa += '#'+StrZero(_nI,2)+':'+ AllTrim(&('oParseJson:TXT'+StrZero(_nI,2)))+'|'
         EndIf   
      Next
      _cTxtOri := oParseJson:SEQ+'\'+oParseJson:TEXTO
      _cTaxas  := StrTran(AD1->AD1_XTAXAS, _cTxtOri, _cNewTaxa)
      conout(_cNewTaxa)

      AD1->(DbSetOrder(1))
      If AD1->(DbSeek(xFilial('AD1')+oParseJson:AD1_NROPOR+oParseJson:AD1_REVISA))
         RecLock('AD1', .F.)
         Replace AD1->AD1_XTAXAS With _cTaxas
         AD1->(MsUnlock())
      EndIf      
      _cJson := u_JsonMsg('Atualização OK!',  "Taxa ajusatda com sucesso!",    "success", .T.,'1000',,)
      ::setStatus(200)
      ::setResponse(EncodeUTF8(_cJson))
      Return .T. 
   
   // Agendamento
   ElseIf _cTab == 'AD6'
      If _cOper == 'EXC'
         Conout('[PALM] Excluindo Pagamento da Proposta | Usuario '+_cNomeUser)
         AD6->(DbGoTo(_nRec))
         _cNrOpor := AD6->AD6_XNROPO
         RecLock('AD6',.F.)
         AD6->(DbDelete())
         AD6->(MsUnlock())
         //_cJson := u_JsonMsg('Exclusão OK!',  "Exclusão realizada com sucesso!",    "success", .F.,'1500',,"/PALM/v1/AppCRM11Add?ID="+_cNrOpor)
         _cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+_cNrOpor+'"}'
         ::setStatus(200)
         ::setResponse(EncodeUTF8(_cJson))
         Return .T.
      EndIf
      Conout('[PALM] Gravando Pagamento da Proposta | Usuario '+_cNomeUser)
      If _cOper == 'INC'
         _cQuery := "Select Max(AD6_SEQUEN) PROXIMO From "+RetSqlName('AD6')+" Where AD6_XNROPO = '"+oParseJson:AD1_NROPOR+"' And D_E_L_E_T_ = ''"
         DbUseArea(.T.,"TOPCONN",TCGENQRY(,,_cQuery),"_AD6",.F.,.T.)
         If Empty(_AD6->PROXIMO)
            _cItem := '01'
         Else
            _cItem := Soma1(_AD6->PROXIMO)
         EndIf  
         _AD6->(DbCloseARea())

         _lGeraSCR := .T.
         If _lGeraSCR
            Reclock("SCR",.T.)
            SCR->CR_FILIAL	 := xFilial('SCR')
            SCR->CR_NUM		 := AllTrim(oParseJson:AD1_NROPOR)+AllTrim(oParseJson:AD1_REVISA)
            //SCR->CR_XSEQ	 := SEQ
            SCR->CR_TIPO	 := 'PR' //Proposta
            SCR->CR_NIVEL	 := '01'
            SCR->CR_USER	 := ''
            SCR->CR_APROV	 := ''
            SCR->CR_STATUS	 := '02'
            SCR->CR_TOTAL	 := AD1->AD1_RCFECH
            SCR->CR_EMISSAO := dDataBase
            SCR->CR_MOEDA	 := 1
            SCR->CR_TXMOEDA := 1
            SCR->CR_PRAZO	 := dDataBase+2
            SCR->CR_AVISO	 := dDataBase+3
            SCR->CR_GRUPO   := ''
            SCR->CR_ITGRP   := ''
            SCR->CR_USERORI := __cUserID
            SCR->CR_OBS     := 'Novo recebimento na Proposta: R$ '+AllTrim(Transform(Val(StrTran(StrTran(oParseJson:AD6_TOTAL,'.',''), ',','.')), '@E 9,999,999.99'))
            SCR->CR_XTPCRM  := 'FP'   //CP:Comercial - Preço negociado a menor   CT:Comercial - Taxa a menor   CD:Comercial - Taxa deletada   FP:Financeiro - Novo Pagamento inserido
            //SCR->CR_ESCALON:= lEscalona
            //SCR->CR_ESCALSP:= lEscalonaS
            SCR->(MsUnlock())
         EndIf

         RecLock('AD6', .T.)
         Replace AD6->AD6_XNROPO With oParseJson:AD1_NROPOR
         Replace AD6->AD6_XREVIS With oParseJson:AD1_REVISA
         Replace AD6->AD6_DATA   With CtoD(oParseJson:AD6_DATA)
         Replace AD6->AD6_SEQUEN With _cItem
      Else
         AD6->(DbGoTo(Val(oParseJson:REC)))
         RecLock('AD6', .F.)
      EndIf
      Replace AD6->AD6_XCOND  With oParseJson:AD6_XCOND
      Replace AD6->AD6_XTIPO  With oParseJson:AD6_XTIPO
      Replace AD6->AD6_XOPER  With oParseJson:AD6_XOPER
      Replace AD6->AD6_TOTAL  With Val(StrTran(StrTran(oParseJson:AD6_TOTAL,'.',''), ',','.'))
      Replace AD6->AD6_XAUT   With AllTrim(oParseJson:AD6_XAUT)
      Replace AD6->AD6_XOBS   With oParseJson:AD6_XOBS
      AD6->(MsUnlock())   

   EndIf

   If _cOper == 'ALT'
      _cJson := u_JsonMsg('Alteração OK!', "Atualização realizada com sucesso!", "success", .T.,'1000',,"/PALM/v1/AppCRM11Add?ID="+oParseJson:AD1_NROPOR)
   Else   
      _cJson := u_JsonMsg('Inclusão OK!',  "Inclusão realizada com sucesso!",    "success", .T.,'1000',,"/PALM/v1/AppCRM11Add?ID="+oParseJson:AD1_NROPOR)
   EndIf
   //_cJson := '{"refresh":"/PALM/v1/AppCRM11Add?ID='+oParseJson:AD1_NROPOR+'"}'
   
   ::setStatus(200)
   ::setResponse(EncodeUTF8(_cJson))
   Return .T.
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
/* AppCRM11Imp - Imprime Proposta Comercial
/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
WSRESTFUL AppCRM11Imp DESCRIPTION UnEscape("Edicao de Processo Disciplinar - PALM")
   WSDATA USERID As String //Json Recebido no corpo da requição
   WSDATA TOKEN  As String //String que vamos receber via URL
   WSDATA NROPOR     As String //String que vamos receber via URL
   WSDATA REV As String //String que vamos receber via URL
   WSDATA DEVICEID As String

   WSMETHOD GET DESCRIPTION Unescape("Edicao de Registro Disciplinar") WSSYNTAX "/PALM/v1/AppCRM11Imp" //Disponibilizamos um método do tipo GET
   END WSRESTFUL

WSMETHOD GET WSRECEIVE userID,token,OPER,ID,DEVICEID,ORIGEM,DOWNLOAD WSSERVICE AppCRM11Imp
   Local _lRet	   := .T.
   Local _lErro   := .F.
   Local _nI
   __cUserID      := Self:USERID
   _cToken        := Self:TOKEN
   _cErro         := ''
   _cNrOpor       := If(Empty(Self:NROPOR), '', Self:NROPOR)
   _cRev          := If(Empty(Self:REV),    '', Self:REV)
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

   _cPathBase := "\web\temp\"
   _cArq      := 'Prop_'+_cNrOpor+'.pdf'
   _oPrn := u_Proposta(_cNrOpor, _cRev, _cArq)
   If Type('_oPRN') == 'O'
      MS_Flush()
      _oPrn:Preview()
   EndIf   
   FreeObj(_oPrn)

   aFiles := {} // O array receberá os nomes dos arquivos e do diretório
   aSizes := {} // O array receberá os tamanhos dos arquivos e do diretorio
   ADir(_cPathBase+_cArq, aFiles, aSizes)
   nHandle := fopen(_cPathBase+_cArq , FO_READWRITE + FO_SHARED )
   cString := ""
   FRead( nHandle, cString, aSizes[1] ) //Carrega na variável cString, a string ASCII do arquivo.
   _cPDF64 := Encode64(cString) //Converte o arquivo para BASE64
   fclose(nHandle)            

   // Monta Tela de exibição de PDF
   _cJson  := u_JsonVPDF(_cPDF64, .T.,)
   Memowrite('VPDF.json', _cJson)
   ::SetResponse(EncodeUTF8(_cJSON))
   Return .T.  

   Return(_lRet)
//

/*\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\*/
User Function ProdsOpor(_cChave)
   _cArea  := GetArea()
   _cProdS := ''

   ADJ->(DbSetOrder(1))
   ADJ->(DbGoTop())
   ADJ->(DbSeek(AllTrim(_cChave)))
   Do While AllTrim(ADJ->ADJ_FILIAL+ADJ->ADJ_NROPOR) == AllTrim(_cChave) .and. !ADJ->(EoF())
      _cProds += ALlTrim(ADJ->ADJ_PROD)+' | '
      ADJ->(DbSkip())
   EndDo

   RestArea(_cArea)
   Return _cProds
