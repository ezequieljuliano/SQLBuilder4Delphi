{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Table reference parsers                         }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}
unit gaSQLTableRefParsers;

interface

uses
  gaBasicSQLParser, gaAdvancedSQLParser, gaSQLExpressionParsers,
  gaSQLParserHelperClasses;

type
  TgaSQLDataReference = class (TgaSQLStatementPart)
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;
  
  TgaSQLTableReference = class (TgaSQLDataReference)
  private
    FLastWasPeriod: Boolean;
    FTableName: TgaSQLTokenListBookmark;
    FTablePrefixies: TgaSQLTokenList;
    function GetTableName: string;
    function GetTablePrefix: string;
    procedure SetTableName(const Value: string);
    procedure SetTablePrefix(const Value: string);
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    procedure InternalSetParseComplete; override;
    procedure InternalStartParse; override;
    function IsValidMidparseToken(AToken: TgaSQLTokenObj): Boolean; override;
    function IsValidStartToken(AToken: TgaSQLTokenObj): Boolean; override;
    procedure ParseTableName(AToken: TgaSQLTokenObj);
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property TableName: string read GetTableName write SetTableName;
    property TableNameToken: TgaSQLTokenListBookmark read FTableName;
    property TablePrefix: string read GetTablePrefix write SetTablePrefix;
    property TablePrefixies: TgaSQLTokenList read FTablePrefixies;
  end;
  
  TgaSQLStoredProcReference = class (TgaSQLDataReference)
  private
    FParameterParseStarted: Boolean;
    FStoredProcedureNameToken: TgaSQLTokenListBookmark;
    FStoredProcedureParameters: TgaSQLExpressionList;
    function GetStoredProcedureName: string;
    procedure SetStoredProcedureName(const Value: string);
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    procedure InitializeParse; override;
    property StoredProcedureNameToken: TgaSQLTokenListBookmark read 
            FStoredProcedureNameToken;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property StoredProcedureName: string read GetStoredProcedureName write 
            SetStoredProcedureName;
    property StoredProcedureParameters: TgaSQLExpressionList read 
            FStoredProcedureParameters;
  end;
  
  TgaSQLSelectReference = class (TgaSQLDataReference)
  private
    FFirstToken: Boolean;
    FSelectStm: TgaCustomSQLStatement;
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    procedure InitializeParse; override;
    procedure InternalSetParseComplete; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property SelectStm: TgaCustomSQLStatement read FSelectStm;
  end;
  
  TgaSQLTable = class (TgaSQLStatementPart)
  private
    FDataReference: TgaSQLDataReference;
    FIsAliasAllowed: Boolean;
    FLastWasDelmitier: Boolean;
    FTableAlias: TgaSQLTokenListBookmark;
    function GetTableAlias: string;
    function GetTableName: string;
    function GetTablePrefix: string;
    function GetTableRef: TgaSQLTableReference;
    procedure SetTableAlias(const Value: string);
    procedure SetTableName(const Value: string);
    procedure SetTablePrefix(const Value: string);
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    procedure InternalSetParseComplete; override;
    procedure InternalStartParse; override;
    procedure ParseTableAlias(AToken: TgaSQLTokenObj);
    procedure StartDataExpressionParse;
    property TableRef: TgaSQLTableReference read GetTableRef;
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement); override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property DataReference: TgaSQLDataReference read FDataReference;
    property IsAliasAllowed: Boolean read FIsAliasAllowed write FIsAliasAllowed;
    property TableAlias: string read GetTableAlias write SetTableAlias;
    property TableAliasToken: TgaSQLTokenListBookmark read FTableAlias;
    property TableName: string read GetTableName write SetTableName;
    property TablePrefix: string read GetTablePrefix write SetTablePrefix;
  end;
  
  TgaSQLTableList = class (TgaSQLStatementPartList)
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement);
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;
  

implementation

uses
  SysUtils, gaSQLParserConsts, gaParserVisitor;

{
***************************** TgaSQLDataReference ******************************
}
procedure TgaSQLDataReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLDataReference(Self);
end;

{
***************************** TgaSQLTableReference *****************************
}
procedure TgaSQLTableReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLTableReference(Self);
end;

procedure TgaSQLTableReference.DiscardParse;
begin
  inherited DiscardParse;
  FTablePrefixies.Free;
  FTablePrefixies := nil;
  FTableName.Free;
  FTableName := nil;
end;

function TgaSQLTableReference.GetCanParseEnd: Boolean;
begin
  Result := not FLastWasPeriod;
end;

function TgaSQLTableReference.GetTableName: string;
begin
  if FTableName <> nil then
    Result := GetTokenObjAsString(FTableName.TokenObj)
  else
    Result := '';
end;

function TgaSQLTableReference.GetTablePrefix: string;
begin
  if TablePrefixies <> nil then
    Result := TablePrefixies.AsString
  else
    Result := '';
end;

procedure TgaSQLTableReference.InternalSetParseComplete;
begin
  // Current one should be delimitier or symbol
  while not (CurrentItem.TokenType in [stSymbol, stQuotedSymbol]) do
    Previous;
  FTableName := GetBookmark;
  FTablePrefixies.Locate(CurrentItem);
  FTablePrefixies.Previous;
  FTablePrefixies.SetEndPos(FTablePrefixies, True);
  inherited;
end;

procedure TgaSQLTableReference.InternalStartParse;
begin
  inherited InternalStartParse;
  FTablePrefixies := TgaSQLTokenList.CreateMirror(OwnerStatement, Self);
end;

function TgaSQLTableReference.IsValidMidparseToken(AToken: TgaSQLTokenObj): 
        Boolean;
begin
  Result := AToken.TokenType in [stSymbol, stQuotedSymbol, stDelimitier, stComment, stPeriod];
end;

function TgaSQLTableReference.IsValidStartToken(AToken: TgaSQLTokenObj): 
        Boolean;
begin
  Result := AToken.TokenType in [stSymbol, stQuotedSymbol];
end;

procedure TgaSQLTableReference.ParseTableName(AToken: TgaSQLTokenObj);
begin
  case AToken.TokenType of
    stSymbol, stQuotedSymbol:
      FLastwasPeriod := False;
    stPeriod:
      FLastWasPeriod := True;
    stDelimitier, stComment: ;
    else
      IsInvalid := True;
  end;
end;

procedure TgaSQLTableReference.SetTableName(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
begin
  if TableName <> Value then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(Value, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      if tmpTokenList.Count <> 1 then
        raise Exception.CreateFmt(SerrWrongTokenCountInArg, ['Table name', 1, tmpTokenList.Count]);
      tmpTokenList.First;
      FTableName.TokenObj := tmpTokenList.CurrentItem;
    finally
      tmpTokenList.Free;
    end;
  end;
end;

procedure TgaSQLTableReference.SetTablePrefix(const Value: string);
var
  tmpStr: string;
  tmpTokenList: TgaSQLTokenHolderList;
begin
  if Value[Length(Value)] = '.' then
    tmpStr := Value
  else
    tmpStr := Value + '.';
  if (TablePrefix <> tmpStr) then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(tmpStr, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      TablePrefixies.CopyListContest(tmpTokenList);
    finally
      tmpTokenList.Free;
    end;
  end;
end;

{
************************** TgaSQLStoredProcReference ***************************
}
procedure TgaSQLStoredProcReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLStoredProcReference(Self);
end;

procedure TgaSQLStoredProcReference.DiscardParse;
begin
  inherited DiscardParse;
  FStoredProcedureNameToken.Free;
  FStoredProcedureNameToken := nil;
  FStoredProcedureParameters.Free;
  FStoredProcedureParameters := nil;
end;

procedure TgaSQLStoredProcReference.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if not ParseStarted then
  begin
  inherited ExecuteTokenAdded(Sender, AToken);
    Assert(AToken.TokenType in [stSymbol, stQuotedSymbol]);
    FStoredProcedureNameToken := GetBookmark;
  end else
  begin
    inherited ExecuteTokenAdded(Sender, AToken);
    if not FParameterParseStarted then
    begin
      if AToken.TokenType in [stComment, stDelimitier] then
        Exit;
      if AToken.TokenType <> stLParen then
        IsInvalid := True;
      FParameterParseStarted := True;
    end else
    begin
      if StoredProcedureParameters.TokenList.IsEmpty or (StoredProcedureParameters.TokenList.LastItem <> CurrentItem) then
        StoredProcedureParameters.TokenList.SetEndPos(Self, False);
      if StoredProcedureParameters.CanParseEnd and (AToken.TokenType = stRParen) then
      begin
        StoredProcedureParameters.CompleteParseAtPreviousToken;
        ParseComplete := True;
      end
      else
        StoredProcedureParameters.ExecuteTokenAdded(Self, AToken);
    end;
  end;
end;

function TgaSQLStoredProcReference.GetCanParseEnd: Boolean;
begin
  Result := False;
end;

function TgaSQLStoredProcReference.GetStoredProcedureName: string;
begin
  if FStoredProcedureNameToken <> nil then
    Result := GetTokenObjAsString(FStoredProcedureNameToken.TokenObj)
  else
    Result := '';
end;

procedure TgaSQLStoredProcReference.InitializeParse;
begin
  inherited InitializeParse;
  FParameterParseStarted := False;
  FStoredProcedureParameters := TgaSQLExpressionList.Create(OwnerStatement);
end;

procedure TgaSQLStoredProcReference.SetStoredProcedureName(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
begin
  if StoredProcedureName <> Value then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(Value, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      if tmpTokenList.Count <> 1 then
        raise Exception.CreateFmt(SerrWrongTokenCountInArg, ['Stored procedure name', 1, tmpTokenList.Count]);
      tmpTokenList.First;
      FStoredProcedureNameToken.TokenObj := tmpTokenList.CurrentItem;
    finally
      tmpTokenList.Free;
    end;
  end;
end;

{
**************************** TgaSQLSelectReference *****************************
}
procedure TgaSQLSelectReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLSelectReference(Self);
end;

procedure TgaSQLSelectReference.DiscardParse;
begin
  inherited DiscardParse;
  FreeAndNil(FSelectStm);
end;

procedure TgaSQLSelectReference.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  inherited ExecuteTokenAdded(Sender, AToken);
  if FFirstToken then
  begin
    Assert(AToken.TokenType = stLParen);
    FFirstToken := False;
  end
  else begin
    if (SelectStm = nil) and AToken.TokenSymbolIs('SELECT') then
        FSelectStm := TgaAdvancedSQLParser.GetStatementClassForToken('SELECT').CreateOwned(OwnerStatement);
    if SelectStm = nil then
        Assert(AToken.TokenType in [stComment, stDelimitier])
    else
    begin
      if SelectStm.CanParseEnd and (AToken.TokenType = stRParen) then
      begin
        SelectStm.CurrentSQL.Locate(CurrentItem);
        SelectStm.CurrentSQL.Previous;
        SelectStm.FinishSubStatement;
        ParseComplete := True;
      end
      else
        SelectStm.DoTokenAdded(Sender, AToken);
    end;
  end;
end;

function TgaSQLSelectReference.GetCanParseEnd: Boolean;
begin
  Result := False;
end;

procedure TgaSQLSelectReference.InitializeParse;
begin
  inherited InitializeParse;
  FFirstToken := True;
end;

procedure TgaSQLSelectReference.InternalSetParseComplete;
begin
  inherited InternalSetParseComplete;
end;

{
********************************* TgaSQLTable **********************************
}
constructor TgaSQLTable.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  inherited;
  FIsAliasAllowed := True;
end;

procedure TgaSQLTable.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLTable(Self);
end;

procedure TgaSQLTable.DiscardParse;
begin
  OwnerStatement.RemoveTable(Self);
  FreeAndNil(FTableAlias);
  FreeAndNil(FDataReference);
  inherited DiscardParse;
end;

procedure TgaSQLTable.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if (not ParseStarted) and (AToken.TokenType in [stComment, stDelimitier]) then
    Exit; // skip leading whitespaces
  inherited;
  if FLastWasDelmitier and DataReference.CanParseEnd and
    (AToken.TokenType in [stSymbol, stQuotedSymbol, stString]) then
    DataReference.CompleteParseAtPreviousToken;
  FLastWasDelmitier := AToken.TokenType in [stComment, stDelimitier];
  if DataReference.ParseComplete then
  begin
    if IsAliasAllowed then
      ParseTableAlias(AToken)
    else
      raise EgaSQLParserException.Create('Alias not allowed for table reference');
  end
  else
  begin
    if (TableRef <> nil) and (not TableRef.IsTokenValid(AToken)) then
      StartDataExpressionParse
    else begin
      if DataReference.IsEmpty or (DataReference.LastItem <> CurrentItem) then
        DataReference.SetEndPos(Self, False);
      DataReference.ExecuteTokenAdded(Self, AToken);
    end;
  end;
end;

function TgaSQLTable.GetCanParseEnd: Boolean;
begin
  Result := DataReference.ParseComplete or DataReference.CanParseEnd;
end;

function TgaSQLTable.GetTableAlias: string;
begin
  if FTableAlias <> nil then
    Result := GetTokenObjAsString(FTableAlias.TokenObj)
  else
    Result := '';
end;

function TgaSQLTable.GetTableName: string;
begin
  if TableRef <> nil then
    Result := TableRef.TableName
  else
    Result := '';
end;

function TgaSQLTable.GetTablePrefix: string;
begin
  if TableRef <> nil then
    Result := TableRef.GetTablePrefix
  else
    Result := '';
end;

function TgaSQLTable.GetTableRef: TgaSQLTableReference;
begin
  if DataReference is TgaSQLTableReference then
    Result := TgaSQLTableReference(DataReference)
  else
    Result := nil;
end;

procedure TgaSQLTable.InternalSetParseComplete;
begin
  if not DataReference.ParseComplete then
  begin
    DataReference.Locate(CurrentItem);
    DataReference.ParseComplete := True;
    Locate(DataReference.LastItem);
  end
  else if TableAliasToken <> nil then
    GotoBookmark(TableAliasToken);
  inherited;
end;

procedure TgaSQLTable.InternalStartParse;
begin
  inherited InternalStartParse;
  FDataReference := TgaSQLTableReference.CreateMirror(OwnerStatement, Self);
  OwnerStatement.AddTable(Self);
end;

procedure TgaSQLTable.ParseTableAlias(AToken: TgaSQLTokenObj);
begin
  case AToken.TokenType of
    stDelimitier, stComment:
      {no special processing};
    stSymbol, stQuotedSymbol, stString:
    begin
      if not AToken.TokenSymbolIs('AS') then
      begin
        FTableAlias := GetBookmark;
        ParseComplete := True;
      end;
    end;
    else
      IsInvalid := True;
  end;
end;

procedure TgaSQLTable.SetTableAlias(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
  tmpToken: TgaSQLTokenObj;
begin
  if TableAlias <> Value then
  begin
    CheckModifyAllowed;
    if (not IsAliasAllowed) and (Value <> '') then
      raise Exception.Create(SerrTableAliasNotAllowed);
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(Value, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      if tmpTokenList.Count > 1 then
        raise Exception.CreateFmt(SerrWrongTokenCountInArg, ['Table alias', 1, tmpTokenList.Count]);
      tmpTokenList.First;
      if FTableAlias <> nil then
        FTableAlias.TokenObj := tmpTokenList.CurrentItem
      else begin
        tmpToken := TgaSQLTokenObj.CreateDelimitier;
        Locate(DataReference.LastItem);
        InsertAfterCurrent(tmpToken, True);
        InsertAfterCurrent(tmpTokenList.CurrentItem, True);
        FTableAlias := GetBookmark;
      end;
    finally
      tmpTokenList.Free;
    end;
  end;
end;

procedure TgaSQLTable.SetTableName(const Value: string);
begin
  if TableRef <> nil then
    TableRef.TableName := Value
  else
    raise Exception.Create('Not table refernce - can''t change table name');
end;

procedure TgaSQLTable.SetTablePrefix(const Value: string);
begin
  if TableRef <> nil then
    TableRef.TablePrefix := Value
  else
    raise Exception.Create('Not table refernce - can''t change table prefixies');
end;

procedure TgaSQLTable.StartDataExpressionParse;
begin
  if CurrentItem.TokenType <> stLParen then
    raise EgaSQLInvalidTokenEncountered.Create(Self, CurrentItem);
  FDataReference.Free;
  FDataReference := nil;
  First;
  if CurrentItem.TokenType in [stSymbol, stQuotedSymbol] then
    FDataReference := TgaSQLStoredProcReference.Create(OwnerStatement)
  else if CurrentItem.TokenType = stLParen then
    FDataReference := TgaSQLSelectReference.Create(OwnerStatement)
  else
    raise EgaSQLInvalidTokenEncountered.Create(Self, CurrentItem);
  FDataReference.SetStartPos(Self, True);
  while not Eof do
  begin
    ExecuteTokenAdded(Self, CurrentItem);
    Next;
  end;
end;

{
******************************* TgaSQLTableList ********************************
}
constructor TgaSQLTableList.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  inherited Create(AOwnerSTatement, TgaSQLTable);
end;

procedure TgaSQLTableList.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLTableList(Self);
end;


end.

