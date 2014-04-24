{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Classes for parsing select fields               }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaSQLSelectFieldParsers;

interface

uses
  gaBasicSQLParser, gaAdvancedSQLParser, gaSQLParserHelperClasses,
  gaSQLFieldRefParsers, gaSQLExpressionParsers;

type
  TgaSQLSelectExpression = class (TgaSQLExpression)
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;
  
  TgaSQLSelectField = class (TgaSQLStatementPart)
  private
    FFieldAlias: TgaSQLTokenListBookmark;
    FLastWasDelmitier: Boolean;
    FValueExpression: TgaSQLExpressionBase;
    function GetFieldAlias: string;
    function GetFieldName: string;
    function GetFieldPrefix: string;
    function GetFieldRef: TgaSQLFieldReference;
    procedure SetFieldAlias(const Value: string);
    procedure SetFieldName(const Value: string);
    procedure SetFieldPrefix(const Value: string);
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    procedure InternalSetParseComplete; override;
    procedure InternalStartParse; override;
    procedure ParseFieldAlias(AToken: TgaSQLTokenObj);
    procedure StartExpressionParse;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property FieldAlias: string read GetFieldAlias write SetFieldAlias;
    property FieldAliasToken: TgaSQLTokenListBookmark read FFieldAlias;
    property FieldName: string read GetFieldName write SetFieldName;
    property FieldPrefix: string read GetFieldPrefix write SetFieldPrefix;
    property FieldRef: TgaSQLFieldReference read GetFieldRef;
    property ValueExpression: TgaSQLExpressionBase read FValueExpression;
  end;
  
  TgaSQLSelectFieldList = class (TgaSQLStatementPartList)
  protected
    function GetCurrentItem: TgaSQLSelectField; reintroduce; virtual;
    function IsTokenWhitespace(AToken: TgaSQLTokenObj): Boolean; override;
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement);
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property CurrentItem: TgaSQLSelectField read GetCurrentItem;
  end;
  

implementation

uses
  SysUtils, gaSQLParserConsts, TypInfo, gaParserVisitor;

{
****************************** TgaSQLSelectField *******************************
}
procedure TgaSQLSelectField.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLSelectField(Self);
end;

procedure TgaSQLSelectField.DiscardParse;
begin
  if OwnerStatement <> nil then
    OwnerStatement.RemoveField(Self);
  FValueExpression.Free;
  FValueExpression := nil;
  FFieldAlias.Free;
  FFieldAlias := nil;
  inherited;
end;

procedure TgaSQLSelectField.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  inherited;
  { Field is written in SQL as follows:
    [table alias][.]FieldName[whitespace][FieldAlias],}
  if FLastWasDelmitier and ValueExpression.CanParseEnd and
    (AToken.TokenType in [stSymbol, stQuotedSymbol, stString]) then
    ValueExpression.CompleteParseAtPreviousToken;
  FLastWasDelmitier := AToken.TokenType in [stComment, stDelimitier];
  if not ValueExpression.ParseComplete then
  begin
    if (FieldRef <> nil) and (not FieldRef.IsTokenValid(AToken)) then
      StartExpressionParse
    else
      ValueExpression.ExecuteTokenAdded(Self, AToken);
    if (FieldRef <> nil) and FieldRef.ParseComplete and (AToken.TokenAsString = '*') then
      ParseComplete := True;
    if (AToken.TokenType = stComma) and ValueExpression.CanParseEnd then
      CompleteParseAtPreviousToken;
  end else
  begin
    ParseFieldAlias(AToken);
    if (AToken.TokenType = stComma) then
      CompleteParseAtPreviousToken;
  end;
end;

function TgaSQLSelectField.GetCanParseEnd: Boolean;
begin
  Result := ValueExpression.ParseComplete or ValueExpression.CanParseEnd;
end;

function TgaSQLSelectField.GetFieldAlias: string;
begin
  if FFieldAlias <> nil then
    Result := GetTokenObjAsString(FFieldAlias.TokenObj)
  else
    Result := '';
end;

function TgaSQLSelectField.GetFieldName: string;
begin
  if FieldRef <> nil then
    Result := FieldRef.FieldName
  else
    Result := '';
end;

function TgaSQLSelectField.GetFieldPrefix: string;
begin
  if FieldRef <> nil then
    Result := FieldRef.FieldPrefix
  else
    Result := '';
end;

function TgaSQLSelectField.GetFieldRef: TgaSQLFieldReference;
begin
  if (ValueExpression  is TgaSQLFieldReference) then
    Result := TgaSQLFieldReference(ValueExpression)
  else
    Result := nil;
end;

procedure TgaSQLSelectField.InternalSetParseComplete;
begin
  if ValueExpression <> nil then
    ValueExpression.ParseComplete := True;
  inherited;
end;

procedure TgaSQLSelectField.InternalStartParse;
begin
  inherited InternalStartParse;
  FValueExpression := TgaSQLFieldReference.Create(OwnerStatement);
  OwnerStatement.AddField(Self);
  FLastWasDelmitier := False;
end;

procedure TgaSQLSelectField.ParseFieldAlias(AToken: TgaSQLTokenObj);
begin
  case AToken.TokenType of
    stDelimitier, stComma, stComment:
      {no special processing};
    stSymbol, stQuotedSymbol, stString:
      if not AToken.TokenSymbolIs('AS') then
      begin
        Assert(FFieldAlias = nil);
        FFieldAlias := GetBookmark;
        ParseComplete := True;
      end;
  end;
end;

procedure TgaSQLSelectField.SetFieldAlias(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
  tmpToken: TgaSQLTokenObj;
begin
  if FieldAlias <> Value then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(Value, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      if tmpTokenList.Count > 1 then
        raise Exception.CreateFmt(SerrWrongTokenCountInArg, ['Field alias', 1, tmpTokenList.Count]);
      tmpTokenList.First;
      if FFieldAlias <> nil then
        FFieldAlias.TokenObj := tmpTokenList.CurrentItem
      else begin
        Last;
        tmpToken := TgaSQLTokenObj.CreateDelimitier;
        InsertAfterCurrent(tmpToken, True);
        InsertAfterCurrent(tmpTokenList.CurrentItem, True);
        FFieldAlias := GetBookmark;
      end;
    finally
      tmpTokenList.Free;
    end;
  end;
end;

procedure TgaSQLSelectField.SetFieldName(const Value: string);
begin
  if FieldName <> Value then
  begin
    if FieldRef = nil then
      raise Exception.Create(SerrFieldAttrCantBeChangedInExpression);
    FieldRef.FieldName := Value;
  end;
end;

procedure TgaSQLSelectField.SetFieldPrefix(const Value: string);
var
  tmpStr: string;
begin
  if (Value = '') or (Value[Length(Value)] = '.') then
    tmpStr := Value
  else
    tmpStr := Value + '.';
  if (FieldPrefix <> tmpStr) then
  begin
    if FieldRef = nil then
      raise Exception.Create(SerrFieldAttrCantBeChangedInExpression);
    FieldRef.FieldPrefix := Value;
  end;
end;

procedure TgaSQLSelectField.StartExpressionParse;
begin
  FValueExpression.Free;
  FValueExpression := TgaSQLSelectExpression.Create(OwnerStatement);
  First;
  FValueExpression.SetStartPos(Self, True);
  while not Eof do
  begin
    FValueExpression.SetEndPos(Self, False);
    FValueExpression.ExecuteTokenAdded(Self, CurrentItem);
    Next;
  end;
end;

{
**************************** TgaSQLSelectExpression ****************************
}
procedure TgaSQLSelectExpression.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLSelectExpression(Self);
end;

{
**************************** TgaSQLSelectFieldList *****************************
}
constructor TgaSQLSelectFieldList.Create(AOwnerStatement: 
        TgaCustomSQLStatement);
begin
  inherited Create(AOwnerSTatement, TgaSQLSelectField);
end;

procedure TgaSQLSelectFieldList.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLSelectFieldList(Self);
end;

function TgaSQLSelectFieldList.GetCurrentItem: TgaSQLSelectField;
begin
  Result := TgaSQLSelectField(inherited CurrentItem);
end;

function TgaSQLSelectFieldList.IsTokenWhitespace(AToken: TgaSQLTokenObj): 
        Boolean;
begin
  Result := inherited IsTokenWhitespace(AToken) or (AToken.TokenType = stComma);
end;


end.
