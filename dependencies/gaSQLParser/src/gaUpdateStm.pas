{ ******************************************************* }
{ }
{ Advanced SQL statement parser }
{ Classes for parsing "Update ..." statements }
{ Copyright (c) 2001 - 2003 AS Gaiasoft }
{ Created by Gert Kello }
{ }
{ ******************************************************* }

unit gaUpdateStm;

interface

uses
  gaBasicSQLParser, gaAdvancedSQLParser, gaSQLParserHelperClasses,
  gaSQLExpressionParsers, gaSQLTableRefParsers;

type
  TUpdateStatementState = (ussNone, ussUpdateTable, ussFieldList, ussWhereClause,
    ussStatementComplete);

  TUpdateStatementStates = set of TUpdateStatementState;

  TgaUpdateSQLStatement = class(TgaCustomSQLStatement)
  private
    FStatementState: TUpdateStatementState;
    FStatementTable: TgaSQLTable;
    FUpdateExpressions: TgaListOfSQLTokenLists;
    FWhereClause: TgaSQLWhereExpression;
    procedure SetStatementState(const Value: TUpdateStatementState);
  protected
    procedure DoAfterStatementStateChange; override;
    procedure DoBeforeStatementStateChange(const NewStateOrd: LongInt);
      override;
    function GetNewStatementState: TUpdateStatementState;
    function GetStatementType: TSQLStatementType; override;
    procedure ModifyStatementInNormalState(Sender: TObject; AToken:
      TgaSQLTokenObj); override;
    property StatementState: TUpdateStatementState read FStatementState write
      SetStatementState;
  public
    constructor Create(AOwner: TgaAdvancedSQLParser); override;
    constructor CreateFromStatement(AOwner: TgaAdvancedSQLParser; AStatement:
      TgaNoSQLStatement); override;
    destructor Destroy; override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property StatementTable: TgaSQLTable read FStatementTable;
    property UpdateExpressions: TgaListOfSQLTokenLists read FUpdateExpressions;
    property WhereClause: TgaSQLWhereExpression read FWhereClause;
  end;

const
  UpdateAllowedNextState: array [TUpdateStatementState] of TUpdateStatementStates =
    ( { ussNone } [ussUpdateTable],
    { ussUpdateTable } [ussFieldList],
    { ussFieldList } [ussWhereClause, ussStatementComplete],
    { ussWhereClause } [ussStatementComplete],
    { ussStatementComplete } []
    );

implementation

uses
  SysUtils, TypInfo, gaSQLParserConsts, gaParserVisitor;

{
  **************************** TgaUpdateSQLStatement *****************************
}
constructor TgaUpdateSQLStatement.Create(AOwner: TgaAdvancedSQLParser);
begin
  inherited Create(AOwner);
  FStatementTable := TgaSQLTable.Create(Self);
  FStatementTable.IsAliasAllowed := False;
  FUpdateExpressions := TgaSQLExpressionList.Create(Self);
end;

constructor TgaUpdateSQLStatement.CreateFromStatement(AOwner:
  TgaAdvancedSQLParser; AStatement: TgaNoSQLStatement);
begin
  inherited CreateFromStatement(AOwner, AStatement);
  FStatementTable := TgaSQLTable.Create(Self);
  FStatementTable.IsAliasAllowed := False;
  FUpdateExpressions := TgaSQLExpressionList.Create(Self);
end;

destructor TgaUpdateSQLStatement.Destroy;
begin
  FStatementTable.Free;
  FWhereClause.Free;
  FUpdateExpressions.Free;
  inherited Destroy;
end;

procedure TgaUpdateSQLStatement.AcceptParserVisitor(Visitor:
  TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitUpdateSQLStatement(Self);
end;

procedure TgaUpdateSQLStatement.DoAfterStatementStateChange;
begin
  inherited;
  case StatementState of
    ussFieldList:
      UpdateExpressions.Add(TgaSQLExpression.Create(Self));
  end;
  if (StatementState > ussFieldList) and (FWhereClause = nil) then
  begin
    if StatementState = ussWhereClause then
    begin
      FWhereClause := TgaSQLWhereExpression.Create(Self);
      FWhereClause.ExecuteTokenAdded(Self, CurrentToken);
    end
    else
    begin
      CurrentSQL.Previous;
      CurrentSQL.InsertAfterCurrent(TgaSQLTokenObj.CreatePlaceHolder, True);
      FWhereClause := TgaSQLWhereExpression.Create(Self);
      FWhereClause.ParseComplete := True;
      CurrentSQL.Next;
    end;
  end;
end;

procedure TgaUpdateSQLStatement.DoBeforeStatementStateChange(const NewStateOrd:
  LongInt);
begin
  inherited;
  case StatementState of
    ussUpdateTable:
      StatementTable.CompleteParseAtPreviousToken;
    ussFieldList:
      (UpdateExpressions.LastItem as TgaSQLStatementPart).CompleteParseAtPreviousToken;
    ussWhereClause:
      WhereClause.CompleteParseAtPreviousToken;
  end;
end;

function TgaUpdateSQLStatement.GetNewStatementState: TUpdateStatementState;
var
  TokenStr: string;
begin
  Result := StatementState;
  if IsTokenStatementTerminator(CurrentToken) then
  begin
    Result := ussStatementComplete;
    Exit;
  end;
  if not CanParseEnd then
    Exit;
  TokenStr := UpperCase(OwnerParser.TokenString);
  if OwnerParser.TokenType = stSymbol then
  begin
    if TokenStr = 'UPDATE' then
      Result := ussUpdateTable
    else if TokenStr = 'SET' then
      Result := ussFieldList
    else if TokenStr = 'WHERE' then
      Result := ussWhereClause
  end;
end;

function TgaUpdateSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := sstUpdate;
end;

procedure TgaUpdateSQLStatement.ModifyStatementInNormalState(Sender: TObject;
  AToken: TgaSQLTokenObj);
begin
  inherited;
  StatementState := GetNewStatementState;
  if InternalStatementState > 0 then
    case StatementState of
      ussNone:
        { the statement starts with comment or whitespace };
      ussUpdateTable:
        StatementTable.ExecuteTokenAdded(Sender, AToken);
      ussFieldList:
        UpdateExpressions.ExecuteTokenAdded(Self, AToken);
      ussWhereClause:
        WhereClause.ExecuteTokenAdded(Sender, AToken);
      ussStatementComplete:
        DoStatementComplete;
    else
      raise Exception.CreateFmt(SUnknownStatementState,
        [ClassName, GetEnumName(TypeInfo(TUpdateStatementState), Ord(StatementState))]);
    end
  else
    InternalStatementState := 1;
end;

procedure TgaUpdateSQLStatement.SetStatementState(const Value:
  TUpdateStatementState);
begin
  if StatementState <> Value then
  begin
    if StatusCode = 0 then
      if Value in UpdateAllowedNextState[FStatementState] then
      begin
        DoBeforeStatementStateChange(Ord(Value));
        FStatementState := Value;
        InternalStatementState := 0;
        DoAfterStatementStateChange;
      end
      else
        StatusCode := errWrongKeywordSequence;
    if Value = ussStatementComplete then
    begin
      DoBeforeStatementStateChange(Ord(Value));
      FStatementState := Value;
      InternalStatementState := 0;
      DoAfterStatementStateChange;
    end;
  end;
end;

end.
