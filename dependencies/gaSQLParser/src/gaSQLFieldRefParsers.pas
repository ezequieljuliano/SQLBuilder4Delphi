{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Classes for parsing field references            }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaSQLFieldRefParsers;

interface

uses
  gaBasicSQLParser, gaAdvancedSQLParser, gaSQLParserHelperClasses,
  gaSQLExpressionParsers;

type
  TgaSQLFieldReference = class (TgaSQLExpressionPart)
  private
    FFieldName: TgaSQLTokenListBookmark;
    FFieldPrefixies: TgaSQLTokenList;
    FLastWasPeriod: Boolean;
    function GetFieldName: string;
    function GetFieldPrefix: string;
    procedure SetFieldName(const Value: string);
    procedure SetFieldPrefix(const Value: string);
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    function GetExpressionType: TgaSQLExpressionPartType; override;
    procedure InitializeParse; override;
    procedure InternalSetParseComplete; override;
    procedure InternalStartParse; override;
    function InvalidTokenFmtStr(AToken: TgaSQLTokenObj): string; override;
    function IsValidMidparseToken(AToken: TgaSQLTokenObj): Boolean; override;
    function IsValidStartToken(AToken: TgaSQLTokenObj): Boolean; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property FieldName: string read GetFieldName write SetFieldName;
    property FieldNameToken: TgaSQLTokenListBookmark read FFieldName;
    property FieldPrefix: string read GetFieldPrefix write SetFieldPrefix;
    property FieldPrefixies: TgaSQLTokenList read FFieldPrefixies;
  end;
  
  TgaSecondaryFieldReferenceType = (sfrUnknown, sfrField, sfrFieldNumber, sfrFunction);

  TgaSecondaryFieldReference = class (TgaSQLStatementPart)
  private
    FReference: TgaSQLStatementPart;
    FReferenceType: TgaSecondaryFieldReferenceType;
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    procedure InitializeParse; override;
    procedure InternalSetParseComplete; override;
    procedure SwitchToFunctionParsing;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property Reference: TgaSQLStatementPart read FReference;
    property ReferenceType: TgaSecondaryFieldReferenceType read FReferenceType;
  end;
  
  TgaSQLGroupByReference = class (TgaSecondaryFieldReference)
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  
  TgaSQLFieldList = class (TgaSQLStatementPartList)
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement);
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;
  
  TgaOrderByNullHandling = (onhNotSpecified, onhNullsFirst, onhNullLast);

  TgaSQLOrderByReference = class (TgaSecondaryFieldReference)
  private
    FNullHandling: TgaOrderByNullHandling;
    FNullHandlingTokens: TgaSQLTokenList;
    FOrderDescriptor: TgaSQLTokenListBookmark;
    function GetOrderDescriptorStr: string;
    function GetOrderedAscending: Boolean;
    function GetOrderField: TgaSQLFieldReference;
    procedure SetNullHandling(const Value: TgaOrderByNullHandling);
    procedure SetOrderDescriptorStr(const Value: string);
    procedure SetOrderedAscending(const Value: Boolean);
  protected
    procedure DiscardParse; override;
    procedure InitializeParse; override;
    procedure InternalSetParseComplete; override;
    property NullHandlingTokens: TgaSQLTokenList read FNullHandlingTokens;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property NullHandling: TgaOrderByNullHandling read FNullHandling write 
            SetNullHandling;
    property OrderDescriptorStr: string read GetOrderDescriptorStr write 
            SetOrderDescriptorStr;
    property OrderedAscending: Boolean read GetOrderedAscending write 
            SetOrderedAscending;
    property OrderField: TgaSQLFieldReference read GetOrderField;
  end;
  
  TgaSQLOrderByList = class (TgaSQLStatementPartList)
  private
    FInOrderFieldList: Boolean;
    function GetCurrent: TgaSQLOrderByReference;
  protected
    function GetAsString: string; override;
    procedure InitializeParse; override;
    procedure SetAsString(const Value: string); override;
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement);
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj);
            override;
    property CurrentItem: TgaSQLOrderByReference read GetCurrent;
  end;
  
  TgaSQLGroupByList = class (TgaSQLStatementPartList)
  private
    FInGroupByList: Boolean;
  protected
    function GetAsString: string; override;
    procedure InitializeParse; override;
    procedure SetAsString(const Value: string); override;
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement);
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  

implementation

uses
  SysUtils, gaSQLParserConsts, gaParserVisitor;


{
***************************** TgaSQLFieldReference *****************************
}
procedure TgaSQLFieldReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLFieldReference(Self);
end;

procedure TgaSQLFieldReference.DiscardParse;
begin
  inherited;
  FFieldPrefixies.Free;
  FFieldPrefixies := nil;
  FFieldName.Free;
  FFieldName := nil;
  if OwnerStatement <> nil then
    OwnerStatement.RemoveFieldReference(Self);
end;

procedure TgaSQLFieldReference.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  inherited;
  { Field reference is written in SQL as follows:
    [table alias][whitespace/comment][.][whitespace/comment]FieldName}
  case AToken.TokenType of
    stSymbol, stQuotedSymbol: begin
      Assert(FLastWasPeriod);
      FLastWasPeriod := False;
    end;
    stPeriod: begin
      Assert(not FLastWasPeriod);
      FLastWasPeriod := True;
    end;
    stDelimitier, stComment:;
    stOther:
      if AToken.TokenString = '*' then
        ParseComplete := True
      else
        IsInvalid := True;
    else
      IsInvalid := True;
  end;
end;

function TgaSQLFieldReference.GetCanParseEnd: Boolean;
begin
  Result := not FLastWasPeriod;
end;

function TgaSQLFieldReference.GetExpressionType: TgaSQLExpressionPartType;
begin
  Result := eptFieldRef;
end;

function TgaSQLFieldReference.GetFieldName: string;
begin
  if FFieldName <> nil then
    Result := GetTokenObjAsString(FFieldName.TokenObj)
  else
    Result := '';
end;

function TgaSQLFieldReference.GetFieldPrefix: string;
begin
  Result := FFieldPrefixies.AsString;
end;

procedure TgaSQLFieldReference.InitializeParse;
begin
  inherited;
  FLastWasPeriod := True;
end;

procedure TgaSQLFieldReference.InternalSetParseComplete;
begin
  // current one should be the last delimitier, comment or "*"
  while CurrentItem.TokenType in [stComment, stDelimitier] do
    Previous;
  if CurrentItem.TokenType <> stPeriod then
  begin
    FFieldName := GetBookmark;
    FFieldPrefixies.Locate(CurrentItem);
    FFieldPrefixies.Previous;
    FFieldPrefixies.SetEndPos(FFieldPrefixies, True);
  end
  else
    IsInvalid := True;
  inherited;
end;

procedure TgaSQLFieldReference.InternalStartParse;
begin
  inherited;
  FFieldPrefixies := TgaSQLTokenList.CreateMirror(OwnerStatement, Self);
  FFieldPrefixies.SetEndPos(Self, False);
  if OwnerStatement <> nil then
    OwnerStatement.AddFieldReference(Self);
end;

function TgaSQLFieldReference.InvalidTokenFmtStr(AToken: TgaSQLTokenObj): 
        string;
begin
  if not ParseStarted then
    Result := 'Field reference parsing: First token must be symbol but %s found'
  else if FLastWasPeriod then
    Result := 'Field reference parsing: Waiting for symbol but %s found'
  else
    Result := 'Field reference parsing: Waiting for period but %s found';
end;

function TgaSQLFieldReference.IsValidMidparseToken(AToken: TgaSQLTokenObj): 
        Boolean;
begin
  if FLastWasPeriod then
    Result := (AToken.TokenType in [stSymbol, stQuotedSymbol, stDelimitier, stComment]) or
              (AToken.TokenType = stOther) and (AToken.TokenString = '*')
  else
    Result := (AToken.TokenType in [stDelimitier, stComment, stPeriod]);
end;

function TgaSQLFieldReference.IsValidStartToken(AToken: TgaSQLTokenObj): 
        Boolean;
begin
  Result := (AToken.TokenType in [stSymbol, stQuotedSymbol]) or
            (AToken.TokenType = stOther) and (AToken.TokenString = '*')
end;

procedure TgaSQLFieldReference.SetFieldName(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
begin
  if FieldName <> Value then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(Value, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      if tmpTokenList.Count <> 1 then
        raise Exception.CreateFmt(SerrWrongTokenCountInArg, ['Field name', 1, tmpTokenList.Count]);
      tmpTokenList.First;
      FFieldName.TokenObj := tmpTokenList.CurrentItem;
    finally
      tmpTokenList.Free;
    end;
  end;
end;

procedure TgaSQLFieldReference.SetFieldPrefix(const Value: string);
var
  tmpStr: string;
  tmpTokenList: TgaSQLTokenHolderList;
begin
  if Value[Length(Value)] = '.' then
    tmpStr := Value
  else
    tmpStr := Value + '.';
  if (FieldPrefix <> tmpStr) then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(tmpStr, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      FieldPrefixies.CopyListContest(tmpTokenList)
    finally
      tmpTokenList.Free;
    end;
  end;
end;

{
************************** TgaSecondaryFieldReference **************************
}
procedure TgaSecondaryFieldReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSecondaryFieldReference(Self);
end;

procedure TgaSecondaryFieldReference.DiscardParse;
begin
  inherited DiscardParse;
  FReference.Free;
  FReference := nil;
end;

procedure TgaSecondaryFieldReference.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  inherited ExecuteTokenAdded(Sender, AToken);
  if (AToken.TokenType = stLParen) and (ReferenceType <> sfrFunction) then
  begin
    SwitchToFunctionParsing;
    Exit;
  end;
  if ReferenceType = sfrUnknown then
  begin
    Assert(FReference = nil);
    if AToken.TokenType = stNumber then
    begin
      FReferenceType := sfrFieldNumber;
      FReference := TgaSQLExpressionConstant.Create(OwnerStatement);
    end
    else
    begin
      FReference := TgaSQLFieldReference.Create(OwnerStatement);
      FReferenceType := sfrField;
    end;
  end;
  if Reference.IsEmpty or (Reference.LastItem <> CurrentItem) then
    Reference.SetEndPos(Self, False);
  Reference.ExecuteTokenAdded(Sender, AToken);
end;

function TgaSecondaryFieldReference.GetCanParseEnd: Boolean;
begin
  Result := (Reference <> nil) and
      (Reference.ParseComplete or Reference.CanParseEnd);
end;

procedure TgaSecondaryFieldReference.InitializeParse;
begin
  inherited InitializeParse;
  FReferenceType := sfrUnknown;
end;

procedure TgaSecondaryFieldReference.InternalSetParseComplete;
begin
  if not Reference.ParseComplete then
    Reference.ParseComplete := True;
  inherited InternalSetParseComplete;
end;

procedure TgaSecondaryFieldReference.SwitchToFunctionParsing;
begin
  First;
  FReference.Free;
  FReferenceType := sfrFunction;
  FReference := TgaSQLExpressionFunction.Create(OwnerStatement);
  FReference.SetStartPos(Self, True);
  while not Eof do
  begin
    ExecuteTokenAdded(Self, CurrentItem);
    Next;
  end;
end;

{
**************************** TgaSQLGroupByReference ****************************
}
procedure TgaSQLGroupByReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLGroupByReference(Self);
end;

procedure TgaSQLGroupByReference.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  inherited ExecuteTokenAdded(Sender, AToken);
  if (ReferenceType <> sfrUnknown) and Reference.ParseComplete then
    ParseComplete := True;
end;

{
******************************* TgaSQLFieldList ********************************
}
constructor TgaSQLFieldList.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  inherited Create(AOwnerSTatement, TgaSQLFieldReference);
end;

procedure TgaSQLFieldList.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLFieldList(Self);
end;

{
**************************** TgaSQLOrderByReference ****************************
}
procedure TgaSQLOrderByReference.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLOrderByReference(Self);
end;

procedure TgaSQLOrderByReference.DiscardParse;
begin
  inherited DiscardParse;
  FOrderDescriptor.Free;
  FOrderDescriptor := nil;
  FNullHandlingTokens.Free;
  FNullHandlingTokens := nil;
end;

procedure TgaSQLOrderByReference.ExecuteTokenAdded(Sender: TObject; AToken:
        TgaSQLTokenObj);
begin
  if (Referencetype <> sfrUnknown) and
      (Reference.ParseComplete or Reference.CanParseEnd) then
  begin
    if AToken.TokenSymbolIs('ASC') or AToken.TokenSymbolIs('DESC') then
    begin
      Assert(Reference <> nil);
      if not Locate(AToken) then
      begin
        Assert(False);
      end;
      FOrderDescriptor := GetBookmark;
      if not Reference.ParseComplete then
        Reference.CompleteParseAtPreviousToken;
      Exit;
    end;
    if FNullHandlingTokens = nil then
    begin
      if AToken.TokenSymbolIs('NULLS') then
      begin
        FNullHandlingTokens := TgaSQLTokenList.CreateMirror(OwnerStatement, Self);
        Exit;
      end;
    end
    else if FNullHandling = onhNotSpecified then
    begin
      if AToken.TokenSymbolIs('FIRST') then
        FNullHandling := onhNullsFirst
      else if AToken.TokenSymbolIs('LAST') then
        FNullHandling := onhNullLast
      else if not (AToken.TokenType in [stDelimitier, stComment]) then
        raise EgaSQLParserException.Create('"ORDERY BY ... NULLS [FIRST|LAST]": "NULLS" not followed by "FIRST" or "LAST"');
      if FNullHandling <> onhNotSpecified then
      begin
        if not Self.Locate(AToken) then
        begin
          Assert(False);
        end;
        FNullHandlingTokens.SetEndPos(Self, True);
        Exit;
      end;
    end;
  end;
  if (AToken.TokenType in [stDelimitier, stComment]) and Reference.ParseComplete then
    Exit;
  inherited ExecuteTokenAdded(Sender, AToken);
end;

function TgaSQLOrderByReference.GetOrderDescriptorStr: string;
begin
  if FOrderDescriptor = nil then
    Result := ''
  else
    Result := FOrderDescriptor.TokenObj.TokenAsString;
end;

function TgaSQLOrderByReference.GetOrderedAscending: Boolean;
begin
  Result := not(SameText(OrderDescriptorStr, 'DESC'));
end;

function TgaSQLOrderByReference.GetOrderField: TgaSQLFieldReference;
begin
  if ReferenceType = sfrField then
  begin
    Assert(Reference is TgaSQLFieldReference);
    Result := TgaSQLFieldReference(Reference);
  end
  else
    Result := nil;
end;

procedure TgaSQLOrderByReference.InitializeParse;
begin
  inherited InitializeParse;
  FNullHandling := onhNotSpecified;
end;

procedure TgaSQLOrderByReference.InternalSetParseComplete;
begin
  if FNullHandlingTokens = nil then
  begin
    InsertAfterCurrent(TgaSQLTokenObj.CreatePlaceHolder, True);
    FNullHandlingTokens := TgaSQLTokenList.CreateMirror(OwnerStatement, Self);
  end;
  if not FNullHandlingTokens.StrictEndPos then
    FNullHandlingTokens.SetEndPos(Self, True);
  inherited InternalSetParseComplete;
end;

procedure TgaSQLOrderByReference.SetNullHandling(const Value: 
        TgaOrderByNullHandling);
begin
  if FNullHandling <> Value then
  begin
    FNullHandling := Value;
    FNullHandlingTokens.First;
    if FNullHandlingTokens.CurrentItem.TokenType <> stPlaceHolder then
    begin
      FNullHandlingTokens.Previous;
      FNullHandlingTokens.InsertAfterCurrent(TgaSQLTokenObj.CreatePlaceHolder, True);
    end;
    FNullHandlingTokens.Next;
    while not FNullHandlingTokens.Eof do
      FNullHandlingTokens.DeleteCurrent;
    case Value of
      onhNotSpecified: ; // do nothing
      onhNullsFirst:
        FNullHandlingTokens.AsString := ' NULLS FIRST';
      onhNullLast:
        FNullHandlingTokens.AsString := ' NULLS LAST';
      else
      begin
        Assert(False);
      end;
    end;
    FNullHandlingTokens.Last;
    SetEndPos(FNullHandlingTokens, True);
  end;
end;

procedure TgaSQLOrderByReference.SetOrderDescriptorStr(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
  tmpToken: TgaSQLTokenObj;
begin
  if OrderDescriptorStr <> Value then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(Value, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      if tmpTokenList.Count <> 1 then
        raise Exception.CreateFmt(SerrWrongTokenCountInArg, ['Sort descriptor', 1, tmpTokenList.Count]);
      tmpTokenList.First;
      tmpToken := tmpTokenList.CurrentItem;
      if FOrderDescriptor = nil then
      begin
        Add(TgaSQLTokenObj.CreateDelimitier);
        Add(tmpToken);
        Last;
        FOrderDescriptor := GetBookmark;
      end else
        FOrderDescriptor.TokenObj := tmpToken;
    finally
      tmpTokenList.Free;
    end;
  end;
end;

procedure TgaSQLOrderByReference.SetOrderedAscending(const Value: Boolean);
begin
  if Value <> GetOrderedAscending then
    if Value then
      OrderDescriptorStr := 'ASC'
    else
      OrderDescriptorStr := 'DESC';
end;

{
****************************** TgaSQLOrderByList *******************************
}
constructor TgaSQLOrderByList.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  inherited Create(AOwnerStatement, TgaSQLOrderByReference);
end;

procedure TgaSQLOrderByList.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLOrderByList(Self);
end;

procedure TgaSQLOrderByList.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if FInOrderFieldList then
    inherited ExecuteTokenAdded(Sender, AToken)
  else
  begin
    if AToken.TokenType in [stComment, stDelimitier] then
      Exit;
    if not ParseStarted then
    begin
      if not AToken.TokenSymbolIs('ORDER') then
        raise EgaSQLParserException.Create('"ORDER BY": First symbol is not "ORDER"');
      StartParse(AToken);
      Exit;
    end;
    if AToken.TokenSymbolIs('BY') then
      FInOrderFieldList := True
    else
      raise EgaSQLParserException.Create('"ORDER BY": "ORDER" not followed by "BY"');
  end;
end;

function TgaSQLOrderByList.GetAsString: string;
var
  tmpCur: TgaSQLTokenListBookmark;
begin
  Result := '';
  if TokenList.IsEmpty then
    Exit;
  tmpCur := TokenList.GetBookmark;
  try
    tmpCur.First;
    if tmpCur.TokenObj.TokenSymbolIs('ORDER') then
    begin
      tmpCur.Next;
      while (not tmpCur.Eof) and (tmpCur.TokenObj.TokenType = stDelimitier) do
        tmpCur.Next;
      if tmpCur.TokenObj.TokenSymbolIs('BY') then
      begin
        tmpCur.Next;
        while (not tmpCur.Eof) and (tmpCur.TokenObj.TokenType = stDelimitier) do
          tmpCur.Next;
      end;
    end;
    while not tmpCur.Eof do
    begin
      Result := Result + tmpCur.TokenObj.TokenAsString;
      tmpCur.Next;
    end;
  finally
    tmpCur.Free;
  end;
end;

procedure TgaSQLOrderByList.InitializeParse;
begin
  inherited;
  FInOrderFieldList := False;
end;

procedure TgaSQLOrderByList.SetAsString(const Value: string);
var
  tmpStr: string;
  tmpToken: TgaSQLTokenObj;
begin
  if (Trim(Value) = '') or (SameText('order by ', Copy(Value, 1, 9))) then
    tmpStr := Value
  else
    tmpStr := 'order by ' + Value;
  inherited SetAsString(tmpStr);
  TokenList.Last;
  if TokenList.CurrentItem.TokenType <> stDelimitier then
  begin
    tmpToken := TgaSQLTokenObj.CreateDelimitier;
    TokenList.Add(tmpToken);
    ExecuteTokenAdded(Self, tmpToken);
  end;
end;

function TgaSQLOrderByList.GetCurrent: TgaSQLOrderByReference;
begin
  Result := inherited CurrentItem as TgaSQLOrderByReference;
end;

{
****************************** TgaSQLGroupByList *******************************
}
constructor TgaSQLGroupByList.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  inherited Create(AOwnerStatement, TgaSQLGroupByReference);
end;

procedure TgaSQLGroupByList.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLGroupByList(Self);
end;

procedure TgaSQLGroupByList.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if FInGroupByList then
    inherited ExecuteTokenAdded(Sender, AToken)
  else
  begin
    if AToken.TokenType in [stComment, stDelimitier] then
      Exit;
    if not ParseStarted then
    begin
      if not AToken.TokenSymbolIs('GROUP') then
        raise EgaSQLParserException.Create('"GROUP BY": First symbol is not "GROUP"');
      StartParse(AToken);
      Exit;
    end;
    if AToken.TokenSymbolIs('BY') then
      FInGroupByList := True
    else
      raise EgaSQLParserException.Create('"GROUP BY": "GROUP" not followed by "BY"');
  end;
end;

function TgaSQLGroupByList.GetAsString: string;
var
  tmpCur: TgaSQLTokenListBookmark;
begin
  Result := '';
  if TokenList.IsEmpty then
    Exit;
  tmpCur := TokenList.GetBookmark;
  try
    tmpCur.First;
    if tmpCur.TokenObj.TokenSymbolIs('GROUP') then
    begin
      tmpCur.Next;
      while (not tmpCur.Eof) and (tmpCur.TokenObj.TokenType = stDelimitier) do
        tmpCur.Next;
      if tmpCur.TokenObj.TokenSymbolIs('BY') then
      begin
        tmpCur.Next;
        while (not tmpCur.Eof) and (tmpCur.TokenObj.TokenType = stDelimitier) do
          tmpCur.Next;
      end;
    end;
    while not tmpCur.Eof do
    begin
      Result := Result + tmpCur.TokenObj.TokenAsString;
      tmpCur.Next;
    end;
  finally
    tmpCur.Free;
  end;
end;

procedure TgaSQLGroupByList.InitializeParse;
begin
  inherited;
  FInGroupByList := False;
end;

procedure TgaSQLGroupByList.SetAsString(const Value: string);
var
  tmpStr: string;
  tmpToken: TgaSQLTokenObj;
begin
  if (Trim(Value) = '') or (SameText('group by ', Copy(Value, 1, 9))) then
    tmpStr := Value
  else
    tmpStr := 'group by ' + Value;
  inherited SetAsString(tmpStr);
  TokenList.Last;
  if TokenList.CurrentItem.TokenType <> stDelimitier then
  begin
    tmpToken := TgaSQLTokenObj.CreateDelimitier;
    TokenList.Add(tmpToken);
    ExecuteTokenAdded(Self, tmpToken);
  end;
end;

end.
