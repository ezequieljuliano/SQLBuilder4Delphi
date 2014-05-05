unit SQLBuilder4D.Parser.GaSQLParser;

interface

uses
  System.SysUtils,
  System.StrUtils,
  SQLBuilder4D.Parser,
  gaBasicSQLParser,
  gaAdvancedSQLParser,
  gaSQLExpressionParsers,
  gaSelectStm;

type

  TGaSQLParserSelect = class(TInterfacedObject, ISQLParserSelect)
  strict private
    FAdvParser: TgaAdvancedSQLParser;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Parse(const pSQLText: string);

    function GetSelect(): string;
    procedure SetSelect(const pSelectClause: string);
    procedure AddOrSetSelect(const pSelectClause: string);

    function GetFrom(): string;
    procedure SetFrom(const pFromClause: string);
    procedure AddOrSetFrom(const pFromClause: string);

    function GetJoin(): string;
    procedure SetJoin(const pJoinClause: string);
    procedure AddOrSetJoin(const pJoinClause: string);

    function GetWhere(): string;
    procedure SetWhere(const pWhereClause: string);
    procedure AddOrSetWhere(const pWhereClause: string);

    function GetGroupBy(): string;
    procedure SetGroupBy(const pGroupByClause: string);
    procedure AddOrSetGroupBy(const pGroupByClause: string);

    function GetHaving(): string;
    procedure SetHaving(const pHavingClause: string);
    procedure AddOrSetHaving(const pHavingClause: string);

    function GetOrderBy(): string;
    procedure SetOrderBy(const pOrderByClause: string);
    procedure AddOrSetOrderBy(const pOrderByClause: string);

    function GetSQLText(): string;
  end;

implementation

{ TGaSQLParserSelect }

procedure TGaSQLParserSelect.AddOrSetFrom(const pFromClause: string);
var
  vFrom: string;
begin
  vFrom := GetFrom();
  if (vFrom <> EmptyStr) then
    vFrom := vFrom + ', ' + pFromClause
  else
    vFrom := pFromClause;
  SetFrom(vFrom);
end;

procedure TGaSQLParserSelect.AddOrSetGroupBy(const pGroupByClause: string);
var
  vGroupBy: string;
begin
  vGroupBy := GetGroupBy();
  if (vGroupBy <> EmptyStr) then
    vGroupBy := vGroupBy + ', ' + pGroupByClause
  else
    vGroupBy := pGroupByClause;
  SetGroupBy(vGroupBy);
end;

procedure TGaSQLParserSelect.AddOrSetHaving(const pHavingClause: string);
var
  vHaving: string;
begin
  vHaving := GetHaving();
  if (vHaving <> EmptyStr) then
    vHaving := vHaving + ' And (' + pHavingClause + ')'
  else
    vHaving := pHavingClause;
  SetHaving(vHaving);
end;

procedure TGaSQLParserSelect.AddOrSetJoin(const pJoinClause: string);
var
  vJoin: string;
begin
  vJoin := GetJoin();
  if (vJoin <> EmptyStr) then
    vJoin := vJoin + pJoinClause
  else
    vJoin := pJoinClause;
  SetJoin(vJoin);
end;

procedure TGaSQLParserSelect.AddOrSetOrderBy(const pOrderByClause: string);
var
  vOrderBy: string;
begin
  vOrderBy := GetOrderBy();
  if (vOrderBy <> EmptyStr) then
    vOrderBy := vOrderBy + ', ' + pOrderByClause
  else
    vOrderBy := pOrderByClause;
  SetOrderBy(vOrderBy);
end;

procedure TGaSQLParserSelect.AddOrSetSelect(const pSelectClause: string);
var
  vSelect: string;
begin
  vSelect := GetSelect();
  if (vSelect <> EmptyStr) then
    vSelect := vSelect + ', ' + pSelectClause
  else
    vSelect := pSelectClause;
  SetSelect(vSelect);
end;

procedure TGaSQLParserSelect.AddOrSetWhere(const pWhereClause: string);
var
  vWhere: string;
begin
  vWhere := GetWhere();
  if (vWhere <> EmptyStr) then
    vWhere := vWhere + ' And (' + pWhereClause + ')'
  else
    vWhere := pWhereClause;
  SetWhere(vWhere);
end;

constructor TGaSQLParserSelect.Create;
begin
  FAdvParser := TgaAdvancedSQLParser.Create(nil);
end;

destructor TGaSQLParserSelect.Destroy;
begin
  FreeAndNil(FAdvParser);
  inherited;
end;

function TGaSQLParserSelect.GetFrom: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(FAdvParser.CurrentStatement).StatementTables <> nil) then
    Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).StatementTables.AsString;
end;

function TGaSQLParserSelect.GetGroupBy: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(FAdvParser.CurrentStatement).GroupByClause <> nil) then
    Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).GroupByClause.AsString;
end;

function TGaSQLParserSelect.GetHaving: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(FAdvParser.CurrentStatement).HavingClause <> nil) then
    Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).HavingClause.AsString;
end;

function TGaSQLParserSelect.GetJoin: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(FAdvParser.CurrentStatement).JoinCaluses <> nil) then
    Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).JoinCaluses.AsString;
end;

function TGaSQLParserSelect.GetOrderBy: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(FAdvParser.CurrentStatement).OrderByClause <> nil) then
    Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).OrderByClause.AsString;
end;

function TGaSQLParserSelect.GetSelect: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(FAdvParser.CurrentStatement).StatementFields <> nil) then
    Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).StatementFields.AsString;
end;

function TGaSQLParserSelect.GetSQLText: string;
begin
  Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).AsString;
end;

function TGaSQLParserSelect.GetWhere: string;
begin
  Result := EmptyStr;
  if (TgaSelectSQLStatement(FAdvParser.CurrentStatement).WhereClause <> nil) then
    Result := TgaSelectSQLStatement(FAdvParser.CurrentStatement).WhereClause.AsString;
end;

procedure TGaSQLParserSelect.Parse(const pSQLText: string);
begin
  FAdvParser.SQLText.Clear;
  FAdvParser.SQLText.Text := pSQLText;
  FAdvParser.Reset;
  while not(FAdvParser.TokenType = stEnd) do
    FAdvParser.NextToken;
end;

procedure TGaSQLParserSelect.SetFrom(const pFromClause: string);
begin
  TgaSelectSQLStatement(FAdvParser.CurrentStatement)
    .StatementTables.AsString := ReplaceText(pFromClause, 'From', '');
end;

procedure TGaSQLParserSelect.SetGroupBy(const pGroupByClause: string);
begin
  TgaSelectSQLStatement(FAdvParser.CurrentStatement)
    .GroupByClause.AsString := ReplaceText(pGroupByClause, 'Group By', '');
end;

procedure TGaSQLParserSelect.SetHaving(const pHavingClause: string);
begin
  TgaSelectSQLStatement(FAdvParser.CurrentStatement)
    .HavingClause.AsString := ReplaceText(pHavingClause, 'Having', '');
end;

procedure TGaSQLParserSelect.SetJoin(const pJoinClause: string);
begin
  TgaSelectSQLStatement(FAdvParser.CurrentStatement)
    .JoinCaluses.AsString := pJoinClause;
end;

procedure TGaSQLParserSelect.SetOrderBy(const pOrderByClause: string);
begin
  TgaSelectSQLStatement(FAdvParser.CurrentStatement)
    .OrderByClause.AsString := ReplaceText(pOrderByClause, 'Order By', '');
end;

procedure TGaSQLParserSelect.SetSelect(const pSelectClause: string);
begin
  TgaSelectSQLStatement(FAdvParser.CurrentStatement)
    .StatementFields.AsString := ReplaceText(pSelectClause, 'Select', '');
end;

procedure TGaSQLParserSelect.SetWhere(const pWhereClause: string);
begin
  TgaSelectSQLStatement(FAdvParser.CurrentStatement)
    .WhereClause.AsString := ReplaceText(pWhereClause, 'Where', '');
end;

end.
