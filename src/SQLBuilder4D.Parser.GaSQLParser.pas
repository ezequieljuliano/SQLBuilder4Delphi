unit SQLBuilder4D.Parser.GaSQLParser;

interface

uses
  SysUtils,
  StrUtils,
  SQLBuilder4D.Parser;

type

  TGaSQLParserFactory = class sealed
  strict private
  const
    CanNotBeInstantiatedException = 'This class can not be instantiated!';
  strict private

    {$HINTS OFF}

    constructor Create;

    {$HINTS ON}

  public
    class function Select(): ISQLParserSelect; overload; static;
    class function Select(const pSQLCommand: string): ISQLParserSelect; overload; static;
  end;

implementation

uses
  gaBasicSQLParser,
  gaAdvancedSQLParser,
  gaSQLExpressionParsers,
  gaSelectStm;

type

  TGaSQLParser = class(TInterfacedObject, ISQLParser)
  strict private
    FParser: TgaAdvancedSQLParser;
  strict protected
    function GetParser(): TgaAdvancedSQLParser;
  public
    constructor Create(const pSQLCommand: string);
    destructor Destroy; override;

    procedure Parse(const pSQLCommand: string);
    function ToString(): string; override;
  end;

  TGaSQLParserSelect = class(TGaSQLParser, ISQLParserSelect)
  strict private
    function GetColumns(): string;
    function GetFrom(): string;
    function GetJoin(): string;
    function GetWhere(): string;
    function GetGroupBy(): string;
    function GetHaving(): string;
    function GetOrderBy(): string;
    function GetExpression(const pDefaultExpression, pCurrentTerm: string; const pConnector: TSQLParserConnector): string;
  public
    function SetColumns(const pColumnsClause: string): ISQLParserSelect;
    function AddColumns(const pColumnsTerm: string): ISQLParserSelect;

    function SetFrom(const pFromClause: string): ISQLParserSelect;
    function AddFrom(const pFromTerm: string): ISQLParserSelect;

    function SetJoin(const pJoinClause: string): ISQLParserSelect;
    function AddJoin(const pJoinTerm: string): ISQLParserSelect;

    function SetWhere(const pWhereClause: string): ISQLParserSelect;
    function AddWhere(const pWhereTerm: string; const pConnector: TSQLParserConnector = pcAnd): ISQLParserSelect;

    function SetGroupBy(const pGroupByClause: string): ISQLParserSelect;
    function AddGroupBy(const pGroupByTerm: string): ISQLParserSelect;

    function SetHaving(const pHavingClause: string): ISQLParserSelect;
    function AddHaving(const pHavingTerm: string; const pConnector: TSQLParserConnector = pcAnd): ISQLParserSelect;

    function SetOrderBy(const pOrderByClause: string): ISQLParserSelect;
    function AddOrderBy(const pOrderByTerm: string): ISQLParserSelect;

    property Columns: string read GetColumns;
    property From: string read GetFrom;
    property Join: string read GetJoin;
    property Where: string read GetWhere;
    property GroupBy: string read GetGroupBy;
    property Having: string read GetHaving;
    property OrderBy: string read GetOrderBy;
  end;

  { TGaSQLParser }

constructor TGaSQLParser.Create(const pSQLCommand: string);
begin
  FParser := TgaAdvancedSQLParser.Create(nil);
  if (pSQLCommand <> '') then
    Parse(pSQLCommand);
end;

destructor TGaSQLParser.Destroy;
begin
  FreeAndNil(FParser);
  inherited;
end;

function TGaSQLParser.GetParser: TgaAdvancedSQLParser;
begin
  Result := FParser;
end;

procedure TGaSQLParser.Parse(const pSQLCommand: string);
begin
  FParser.SQLText.Clear;
  FParser.SQLText.Text := pSQLCommand;
  FParser.Reset;
  while not(FParser.TokenType = stEnd) do
    FParser.NextToken;
end;

function TGaSQLParser.ToString: string;
begin
  Result := TgaSelectSQLStatement(FParser.CurrentStatement).AsString;
end;

{ TGaSQLParserSelect }

function TGaSQLParserSelect.AddColumns(const pColumnsTerm: string): ISQLParserSelect;
begin
  SetColumns(GetExpression(GetColumns, pColumnsTerm, pcComma));
  Result := Self;
end;

function TGaSQLParserSelect.AddFrom(const pFromTerm: string): ISQLParserSelect;
begin
  SetFrom(GetExpression(GetFrom, pFromTerm, pcComma));
  Result := Self;
end;

function TGaSQLParserSelect.AddGroupBy(const pGroupByTerm: string): ISQLParserSelect;
begin
  SetGroupBy(GetExpression(GetGroupBy, pGroupByTerm, pcComma));
  Result := Self;
end;

function TGaSQLParserSelect.AddHaving(const pHavingTerm: string;
  const pConnector: TSQLParserConnector): ISQLParserSelect;
begin
  SetHaving(GetExpression(GetHaving, pHavingTerm, pConnector));
  Result := Self;
end;

function TGaSQLParserSelect.AddJoin(const pJoinTerm: string): ISQLParserSelect;
begin
  SetJoin(GetExpression(GetJoin, pJoinTerm, pcNone));
  Result := Self;
end;

function TGaSQLParserSelect.AddOrderBy(const pOrderByTerm: string): ISQLParserSelect;
begin
  SetOrderBy(GetExpression(GetOrderBy, pOrderByTerm, pcComma));
  Result := Self;
end;

function TGaSQLParserSelect.AddWhere(const pWhereTerm: string;
  const pConnector: TSQLParserConnector): ISQLParserSelect;
begin
  SetWhere(GetExpression(GetWhere, pWhereTerm, pConnector));
  Result := Self;
end;

function TGaSQLParserSelect.GetColumns: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(GetParser.CurrentStatement).StatementFields <> nil) then
    Result := TgaSelectSQLStatement(GetParser.CurrentStatement).StatementFields.AsString;
end;

function TGaSQLParserSelect.GetExpression(const pDefaultExpression, pCurrentTerm: string;
  const pConnector: TSQLParserConnector): string;
begin
  Result := pDefaultExpression;
  if (Result <> '') then
  begin
    case pConnector of
      pcNone:
        Result := Result + '' + pCurrentTerm;
      pcAnd:
        Result := Result + ' And (' + pCurrentTerm + ')';
      pcOr:
        Result := Result + ' Or (' + pCurrentTerm + ')';
      pcComma:
        Result := Result + ', ' + pCurrentTerm;
    end;
  end
  else
    Result := pCurrentTerm;
end;

function TGaSQLParserSelect.GetFrom: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(GetParser.CurrentStatement).StatementTables <> nil) then
    Result := TgaSelectSQLStatement(GetParser.CurrentStatement).StatementTables.AsString;
end;

function TGaSQLParserSelect.GetGroupBy: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(GetParser.CurrentStatement).GroupByClause <> nil) then
    Result := TgaSelectSQLStatement(GetParser.CurrentStatement).GroupByClause.AsString;
end;

function TGaSQLParserSelect.GetHaving: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(GetParser.CurrentStatement).HavingClause <> nil) then
    Result := TgaSelectSQLStatement(GetParser.CurrentStatement).HavingClause.AsString;
end;

function TGaSQLParserSelect.GetJoin: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(GetParser.CurrentStatement).JoinCaluses <> nil) then
    Result := TgaSelectSQLStatement(GetParser.CurrentStatement).JoinCaluses.AsString;
end;

function TGaSQLParserSelect.GetOrderBy: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(GetParser.CurrentStatement).OrderByClause <> nil) then
    Result := TgaSelectSQLStatement(GetParser.CurrentStatement).OrderByClause.AsString;
end;

function TGaSQLParserSelect.GetWhere: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(GetParser.CurrentStatement).WhereClause <> nil) then
    Result := TgaSelectSQLStatement(GetParser.CurrentStatement).WhereClause.AsString;
end;

function TGaSQLParserSelect.SetColumns(const pColumnsClause: string): ISQLParserSelect;
begin
  TgaSelectSQLStatement(GetParser.CurrentStatement).StatementFields.AsString := ReplaceText(pColumnsClause, 'Select', EmptyStr);
end;

function TGaSQLParserSelect.SetFrom(const pFromClause: string): ISQLParserSelect;
begin
  TgaSelectSQLStatement(GetParser.CurrentStatement).StatementTables.AsString := ReplaceText(pFromClause, 'From', EmptyStr);
end;

function TGaSQLParserSelect.SetGroupBy(const pGroupByClause: string): ISQLParserSelect;
begin
  TgaSelectSQLStatement(GetParser.CurrentStatement).GroupByClause.AsString := ReplaceText(pGroupByClause, 'Group By', EmptyStr);
end;

function TGaSQLParserSelect.SetHaving(const pHavingClause: string): ISQLParserSelect;
begin
  TgaSelectSQLStatement(GetParser.CurrentStatement).HavingClause.AsString := ReplaceText(pHavingClause, 'Having', EmptyStr);
end;

function TGaSQLParserSelect.SetJoin(const pJoinClause: string): ISQLParserSelect;
begin
  TgaSelectSQLStatement(GetParser.CurrentStatement).JoinCaluses.AsString := pJoinClause;
end;

function TGaSQLParserSelect.SetOrderBy(const pOrderByClause: string): ISQLParserSelect;
begin
  TgaSelectSQLStatement(GetParser.CurrentStatement).OrderByClause.AsString := ReplaceText(pOrderByClause, 'Order By', EmptyStr);
end;

function TGaSQLParserSelect.SetWhere(const pWhereClause: string): ISQLParserSelect;
begin
  TgaSelectSQLStatement(GetParser.CurrentStatement).WhereClause.AsString := ReplaceText(pWhereClause, 'Where', EmptyStr);
end;

{ TGaSQLParserFactory }

class function TGaSQLParserFactory.Select: ISQLParserSelect;
begin
  Result := TGaSQLParserFactory.Select(EmptyStr);
end;

constructor TGaSQLParserFactory.Create;
begin
  raise ESQLParserException.Create(CanNotBeInstantiatedException);
end;

class function TGaSQLParserFactory.Select(const pSQLCommand: string): ISQLParserSelect;
begin
  Result := TGaSQLParserSelect.Create(pSQLCommand);
end;

end.
