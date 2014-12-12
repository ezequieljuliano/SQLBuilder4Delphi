unit SQLBuilder4D.Impl;

interface

uses
  SQLBuilder4D,
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  System.TypInfo,
  System.Rtti,
  System.StrUtils;

type

  TSQLTable = class(TInterfacedObject, ISQLTable)
  strict private
    FTableName: string;
  public
    constructor Create(); overload;
    constructor Create(const pTableName: string); overload;

    function GetTableName(): string;
    procedure SetTableName(const pColumnName: string);

    property TableName: string read GetTableName write SetTableName;
  end;

  TSQLValue = class(TInterfacedObject, ISQLValue)
  strict private
    FValue: string;
  public
    constructor Create(); overload;
    constructor Create(const pValue: string); overload;

    function GetValue(): string;
    procedure SetValue(const pValue: string);

    property Value: string read GetValue write SetValue;
  end;

  TSQLJoin = class(TInterfacedObject, ISQLJoin)
  strict private
    FTable: ISQLTable;
    FJoinType: TSQLJoinType;
    FCriteria: string;
  public
    constructor Create(); overload;
    constructor Create(const pTableName: string; const pJoinType: TSQLJoinType; const pCriteria: string); overload;

    function GetTable(): ISQLTable;
    procedure SetTable(const pSQLTable: ISQLTable);

    function GetJoinType(): TSQLJoinType;
    procedure SetJoinType(const pType: TSQLJoinType);

    function GetCriteria(): string;
    procedure SetCriteria(const pCriteria: string);

    function ToString(): string; override;

    property Table: ISQLTable read GetTable write SetTable;
    property JoinType: TSQLJoinType read GetJoinType write SetJoinType;
    property Criteria: string read GetCriteria write SetCriteria;
  end;

  TSQLUnion = class(TInterfacedObject, ISQLUnion)
  strict private
    FUnionType: TSQLUnionType;
    FUnionSQL: string;
  public
    constructor Create(); overload;
    constructor Create(const pType: TSQLUnionType; const pUnionSQL: string); overload;

    function GetUnionType(): TSQLUnionType;
    procedure SetUnionType(const pUnionType: TSQLUnionType);

    function GetUnionSQL(): string;
    procedure SetUnionSQL(const pUnionSQL: string);

    function ToString(): string; override;

    property UnionType: TSQLUnionType read GetUnionType write SetUnionType;
    property UnionSQL: string read GetUnionSQL write SetUnionSQL;
  end;

  TSQLCriteria = class(TInterfacedObject, ISQLCriteria)
  strict private
    FCriteria: string;
    FConnectorType: TSQLConnectorType;
  public
    constructor Create(); overload;
    constructor Create(const pCriteria: string; const pConnectorType: TSQLConnectorType); overload;

    function GetCriteria(): string;
    procedure SetCriteria(const pCriteria: string);

    function GetConnector(): TSQLConnectorType;
    procedure SetConnector(const pConnectorType: TSQLConnectorType);

    function GetConnectorDescription(): string;

    property Criteria: string read GetCriteria write SetCriteria;
    property Connector: TSQLConnectorType read GetConnector write SetConnector;
  end;

  TSQLClause = class(TInterfacedObject, ISQLClause)
  strict private
    FCriterias: TList<ISQLCriteria>;
    FStatementType: TSQLStatementType;
  strict protected
    FStatementToString: TFunc<string>;
    function GetStatementType(): TSQLStatementType;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetCriterias(): TList<ISQLCriteria>;

    procedure AppendStatementToString(const pFuncToString: TFunc<string>);
    procedure AppendStatementType(const pStatementType: TSQLStatementType);

    function ToString(): string; reintroduce; virtual;
    procedure SaveToFile(const pFileName: string);

    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  TSQLOrderBy = class(TSQLClause, ISQLOrderBy)
  strict private
    FSortType: TSQLSortType;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(const pSource: ISQLOrderBy);

    function ToString(): string; override;

    function Column(const pColumnName: string; const pSortType: TSQLSortType = srNone): ISQLOrderBy;
    function Columns(const pColumnNames: array of string; const pSortType: TSQLSortType = srNone): ISQLOrderBy;
    function Sort(const pSortType: TSQLSortType): ISQLOrderBy;

    function Union(const pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
  end;

  TSQLHaving = class(TSQLClause, ISQLHaving)
  strict private
    FOrderBy: ISQLOrderBy;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(const pSource: ISQLHaving);

    function ToString(): string; override;

    function Aggregate(const pHavingCriteria: string): ISQLHaving; overload;
    function Aggregate(const pHavingCriterias: array of string): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(const pColumnNames: array of string): ISQLOrderBy; overload;
    function OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(const pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(const pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(const pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
  end;

  TSQLGroupBy = class(TSQLClause, ISQLGroupBy)
  strict private
    FOrderBy: ISQLOrderBy;
    FHaving: ISQLHaving;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(const pSource: ISQLGroupBy);

    function ToString(): string; override;

    function Column(const pColumnName: string): ISQLGroupBy;
    function Columns(const pColumnNames: array of string): ISQLGroupBy;

    function Having(): ISQLHaving; overload;
    function Having(const pHavingCriterias: array of string): ISQLHaving; overload;
    function Having(const pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(const pColumnNames: array of string): ISQLOrderBy; overload;
    function OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(const pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(const pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(const pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
  end;

  TSQLWhere = class(TSQLClause, ISQLWhere)
  strict private
    FColumnName: string;
    FConnectorType: TSQLConnectorType;
    FGroupBy: ISQLGroupBy;
    FHaving: ISQLHaving;
    FOrderBy: ISQLOrderBy;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
    procedure InternalAddBasicCriteria(const pSQLOperator: string; const pSQLValue: TValue; const pCaseSensitive: Boolean);
    procedure InternalAddLikeCriteria(const pSQLOperator, pSQLValue: string; const pLikeOperator: TSQLLikeType; const pCaseSensitive: Boolean);
    function InternalInList(const pValues: array of TValue; const pNotIn: Boolean): ISQLWhere;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(const pSource: ISQLWhere);

    function ToString(): string; override;

    function Column(const pColumnName: string): ISQLWhere;

    function _And(const pColumnName: string): ISQLWhere; overload;
    function _And(const pWhere: ISQLWhere): ISQLWhere; overload;

    function _Or(const pColumnName: string): ISQLWhere; overload;
    function _Or(const pWhere: ISQLWhere): ISQLWhere; overload;

    function Equal(const pValue: TValue): ISQLWhere; overload;
    function Equal(const pValue: string; const pCaseSensitive: Boolean): ISQLWhere; overload;

    function Different(const pValue: TValue): ISQLWhere; overload;
    function Different(const pValue: string; const pCaseSensitive: Boolean): ISQLWhere; overload;

    function Greater(const pValue: TValue): ISQLWhere;
    function Less(const pValue: TValue): ISQLWhere;
    function GreaterOrEqual(const pValue: TValue): ISQLWhere;
    function LessOrEqual(const pValue: TValue): ISQLWhere;

    function Like(const pValue: string; const pOperator: TSQLLikeType = loEqual): ISQLWhere; overload;
    function Like(const pValue: string; const pCaseSensitive: Boolean; const pOperator: TSQLLikeType = loEqual): ISQLWhere; overload;
    function Like(const pValues: array of string; const pOperator: TSQLLikeType = loEqual): ISQLWhere; overload;
    function Like(const pValues: array of string; const pCaseSensitive: Boolean; const pOperator: TSQLLikeType = loEqual): ISQLWhere; overload;

    function NotLike(const pValue: string; const pOperator: TSQLLikeType = loEqual): ISQLWhere; overload;
    function NotLike(const pValue: string; const pCaseSensitive: Boolean; const pOperator: TSQLLikeType = loEqual): ISQLWhere; overload;

    function IsNull(): ISQLWhere;
    function IsNotNull(): ISQLWhere;
    function InList(const pValues: array of TValue): ISQLWhere;
    function NotInList(const pValues: array of TValue): ISQLWhere;
    function Between(const pInitial, pFinal: TValue): ISQLWhere;

    function Criterion(const pOperator: TSQLOperatorType; const pValue: TValue): ISQLWhere;
    function ColumnCriterion(const pOperator: TSQLOperatorType; const pColumnNameValue: string): ISQLWhere;

    function GroupBy(): ISQLGroupBy; overload;
    function GroupBy(const pColumnNames: array of string): ISQLGroupBy; overload;
    function GroupBy(const pGroupBy: ISQLGroupBy): ISQLGroupBy; overload;

    function Having(): ISQLHaving; overload;
    function Having(const pHavingCriterias: array of string): ISQLHaving; overload;
    function Having(const pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(const pColumnNames: array of string): ISQLOrderBy; overload;
    function OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(const pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(const pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(const pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
  end;

  TSQLCoalesce = class(TInterfacedObject, ISQLCoalesce)
  strict private
    FValue: TValue;
  public
    constructor Create(); overload;
    constructor Create(const pValue: TValue); overload;

    function Value(const pValue: TValue): ISQLCoalesce;
    function GetValue(): TValue;
  end;

  TSQLAggregate = class(TInterfacedObject, ISQLAggregate)
  strict private
    FFunction: TSQLAggregateFunctions;
    FExpression: string;
    FAlias: string;
    FCoalesce: ISQLCoalesce;
  public
    constructor Create(); overload;
    constructor Create(const pFunction: TSQLAggregateFunctions; const pExpression, pAlias: string; const pCoalesce: ISQLCoalesce); overload;

    function AggFunction(const pFunction: TSQLAggregateFunctions): ISQLAggregate;
    function AggExpression(const pExpression: string): ISQLAggregate;
    function AggAlias(const pAlias: string): ISQLAggregate;
    function AggCoalesce(const pCoalesce: ISQLCoalesce): ISQLAggregate;

    function GetAggFunction(): TSQLAggregateFunctions;
    function GetAggExpression(): string;
    function GetAggAlias(): string;
    function GetAggCoalesce(): ISQLCoalesce;

    function ToString(const pOwnerCoalesce: ISQLCoalesce = nil): string; reintroduce;
  end;

  TSQLStatement = class(TInterfacedObject, ISQLStatement)
  strict private
    FStatementType: TSQLStatementType;
  strict protected
    procedure SetStatementType(const pStatementType: TSQLStatementType);
  public
    procedure AfterConstruction; override;

    function GetStatementType(): TSQLStatementType;

    function ToString(): string; reintroduce; virtual;
    procedure SaveToFile(const pFileName: string);

    property StatementType: TSQLStatementType read GetStatementType;
  end;

  TSQLSelect = class(TSQLStatement, ISQLSelect)
  strict private
    FDistinct: Boolean;
    FColumns: TStringList;
    FJoinedTables: TList<ISQLJoin>;
    FFromTable: ISQLTable;
    FGroupBy: ISQLGroupBy;
    FHaving: ISQLHaving;
    FOrderBy: ISQLOrderBy;
    FWhere: ISQLWhere;
    FUnions: TList<ISQLUnion>;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function Distinct(): ISQLSelect;

    function AllColumns(): ISQLSelect;
    function Column(const pColumnName: string): ISQLSelect; overload;
    function Column(const pColumnName, pColumnAlias: string): ISQLSelect; overload;
    function Column(const pColumnName: string; const pCoalesce: ISQLCoalesce; const pColumnAlias: string = ''): ISQLSelect; overload;
    function Column(const pAggregate: ISQLAggregate): ISQLSelect; overload;
    function Column(const pAggregate: ISQLAggregate; const pCoalesce: ISQLCoalesce): ISQLSelect; overload;
    function Alias(const pColumnAlias: string): ISQLSelect;

    function SubSelect(const pSelect: ISQLSelect; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pWhere: ISQLWhere; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pGroupBy: ISQLGroupBy; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pHaving: ISQLHaving; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pOrderBy: ISQLOrderBy; const pAlias: string): ISQLSelect; overload;

    function From(const pTableName: string): ISQLSelect; overload;
    function From(const pTableName, pTableAlias: string): ISQLSelect; overload;
    function TableAlias(const pAlias: string): ISQLSelect;
    function Join(const pTableName, pJoinCriteria: string): ISQLSelect;
    function LeftOuterJoin(const pTableName, pJoinCriteria: string): ISQLSelect;
    function RightOuterJoin(const pTableName, pJoinCriteria: string): ISQLSelect;

    function Union(const pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(const pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(const pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;

    function Where(): ISQLWhere; overload;
    function Where(const pColumnName: string): ISQLWhere; overload;
    function Where(const pWhere: ISQLWhere): ISQLWhere; overload;

    function GroupBy(): ISQLGroupBy; overload;
    function GroupBy(const pColumnNames: array of string): ISQLGroupBy; overload;
    function GroupBy(const pGroupBy: ISQLGroupBy): ISQLGroupBy; overload;

    function Having(): ISQLHaving; overload;
    function Having(const pHavingCriterias: array of string): ISQLHaving; overload;
    function Having(const pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(const pColumnNames: array of string): ISQLOrderBy; overload;
    function OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function ToString(): string; override;
  end;

  TSQLDelete = class(TSQLStatement, ISQLDelete)
  strict private
    FTable: ISQLTable;
    FWhere: ISQLWhere;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function ToString(): string; override;

    function From(const pTableName: string): ISQLDelete;

    function Where(): ISQLWhere; overload;
    function Where(const pColumnName: string): ISQLWhere; overload;
    function Where(const pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  TSQLUpdate = class(TSQLStatement, ISQLUpdate)
  strict private
    FColumns: TStringList;
    FValues: TList<ISQLValue>;
    FTable: ISQLTable;
    FWhere: ISQLWhere;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function ToString(): string; override;

    function Table(const pTableName: string): ISQLUpdate;
    function ColumnSetValue(const pColumnName: string; const pValue: TValue): ISQLUpdate;
    function Columns(const pColumnNames: array of string): ISQLUpdate;
    function SetValues(const pValues: array of TValue): ISQLUpdate;

    function Where(): ISQLWhere; overload;
    function Where(const pColumnName: string): ISQLWhere; overload;
    function Where(const pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  TSQLInsert = class(TSQLStatement, ISQLInsert)
  strict private
    FColumns: TStringList;
    FValues: TList<ISQLValue>;
    FTable: ISQLTable;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function ToString(): string; override;

    function Into(const pTableName: string): ISQLInsert;
    function ColumnValue(const pColumnName: string; const pValue: TValue): ISQLInsert;
    function Columns(const pColumnNames: array of string): ISQLInsert;
    function Values(const pValues: array of TValue): ISQLInsert;
  end;

implementation

procedure ColumnIsValid(const pColumnName: string);
begin
  if (pColumnName = EmptyStr) then
    raise ESQLBuilderException.Create('ColumnName can not be empty!');
end;

procedure ValidateSQLReservedWord(const pValue: string);

  function GetWords(): TArray<string>;
  begin
    Result := TArray<string>.Create('or', 'and', 'between', 'is', 'not', 'null', 'in', 'like', 'select', 'union', 'inner', 'join', 'right', 'full',
      'first', 'insert', 'update', 'delete', 'upper', 'lower');
  end;

var
  vValue: string;
  I: Integer;
  vWords: TArray<string>;
begin
  vValue := AnsiReplaceStr(pValue, #39, '');

  vWords := GetWords();
  for I := low(vWords) to high(vWords) do
    if (AnsiCompareText(vValue, vWords[I]) = 0) then
      raise ESQLBuilderException.Create('Value reported for SQL Builder is invalid!');
end;

function ConvertSQLValue(const pValue: TValue): string;
begin
  Result := pValue.ToString;

  if (Result = EmptyStr) then
    Exit('Null');

  ValidateSQLReservedWord(Result);

  case pValue.Kind of
    tkUString, tkWChar, tkLString, tkWString, tkString, tkChar:
      begin
        Result := QuotedStr(Result);
      end;
    tkUnknown:
      begin
        Result := 'Null';
      end;
    tkFloat:
      begin
        Result := AnsiReplaceText(Result, ',', '.');
      end;
  end;
end;

function AggregateFunctionToString(const pAggFunction: TSQLAggregateFunctions): string;
begin
  case pAggFunction of
    aggAvg:
      Result := 'Avg';
    aggCount:
      Result := 'Count';
    aggMax:
      Result := 'Max';
    aggMin:
      Result := 'Min';
    aggSum:
      Result := 'Sum';
  end;
end;

procedure SaveSQLToFile(const pFileName: string; const pSQL: string);
var
  vStringList: TStringList;
begin
  if FileExists(pFileName) then
    DeleteFile(pFileName);

  vStringList := TStringList.Create;
  try
    vStringList.Text := pSQL;
    vStringList.SaveToFile(pFileName);

    if not FileExists(pFileName) then
      raise ESQLBuilderException.Create('Could not save the file!');
  finally
    FreeAndNil(vStringList);
  end;
end;

{ TSQLTable }

constructor TSQLTable.Create(const pTableName: string);
begin
  FTableName := pTableName;
end;

constructor TSQLTable.Create;
begin
  FTableName := EmptyStr;
end;

function TSQLTable.GetTableName: string;
begin
  Result := FTableName;
end;

procedure TSQLTable.SetTableName(const pColumnName: string);
begin
  FTableName := pColumnName;
end;

{ TSQLOrderBy }

function TSQLOrderBy.Column(const pColumnName: string; const pSortType: TSQLSortType): ISQLOrderBy;
var
  vOrderByColumn: string;
begin
  case pSortType of
    srNone:
      vOrderByColumn := pColumnName;
    srAsc:
      vOrderByColumn := pColumnName + ' Asc';
    srDesc:
      vOrderByColumn := pColumnName + ' Desc';
  end;
  GetCriterias.Add(TSQLCriteria.Create(vOrderByColumn, ctComma));
  Result := Self;
end;

function TSQLOrderBy.Columns(const pColumnNames: array of string; const pSortType: TSQLSortType): ISQLOrderBy;
var
  I: Integer;
begin
  GetCriterias.Clear;
  for I := low(pColumnNames) to high(pColumnNames) do
    Column(pColumnNames[I]);
  if (pSortType <> srNone) then
    Sort(pSortType);
  Result := Self;
end;

procedure TSQLOrderBy.AfterConstruction;
begin
  inherited AfterConstruction;
  FUnions := TList<ISQLUnion>.Create;
  FSortType := srNone;
end;

procedure TSQLOrderBy.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

procedure TSQLOrderBy.CopyOf(const pSource: ISQLOrderBy);
var
  I: Integer;
begin
  GetCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    GetCriterias.Add(pSource.Criterias[I]);
end;

procedure TSQLOrderBy.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (GetStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLOrderBy.Sort(const pSortType: TSQLSortType): ISQLOrderBy;
begin
  FSortType := pSortType;
  Result := Self;
end;

function TSQLOrderBy.ToString: string;
var
  I: Integer;
  vStrBuilder: TStringBuilder;
begin
  Result := EmptyStr;

  vStrBuilder := TStringBuilder.Create;
  try
    if Assigned(FStatementToString) then
    begin
      vStrBuilder.Append(FStatementToString);
      vStrBuilder.AppendLine;
    end;

    for I := 0 to Pred(GetCriterias.Count) do
    begin
      if I = 0 then
        vStrBuilder.Append(' Order By')
      else
        vStrBuilder.Append(GetCriterias[I].GetConnectorDescription);

      vStrBuilder.Append(' ' + Criterias[I].Criteria);

      case FSortType of
        srAsc:
          if not AnsiContainsStr(Criterias[I].Criteria, 'Asc') then
            vStrBuilder.Append(' Asc');
        srDesc:
          if not AnsiContainsStr(Criterias[I].Criteria, 'Desc') then
            vStrBuilder.Append(' Desc');
      end;
    end;

    for I := 0 to Pred(FUnions.Count) do
      vStrBuilder.AppendLine.Append(FUnions[I].ToString);

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLOrderBy.Union(const pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLOrderBy;
begin
  InternalAddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(const pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLOrderBy;
begin
  InternalAddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLOrderBy;
begin
  InternalAddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLOrderBy;
begin
  InternalAddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(const pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLOrderBy;
begin
  InternalAddUnion(pHaving.ToString, pType);
  Result := Self;
end;

{ TSQLHaving }

function TSQLHaving.Aggregate(const pHavingCriteria: string): ISQLHaving;
begin
  GetCriterias.Add(TSQLCriteria.Create(pHavingCriteria, ctAnd));
  Result := Self;
end;

procedure TSQLHaving.AfterConstruction;
begin
  inherited AfterConstruction;
  FOrderBy := TSQLOrderBy.Create;
  FUnions := TList<ISQLUnion>.Create;
end;

function TSQLHaving.Aggregate(const pHavingCriterias: array of string): ISQLHaving;
var
  I: Integer;
begin
  GetCriterias.Clear;
  for I := low(pHavingCriterias) to high(pHavingCriterias) do
    Aggregate(pHavingCriterias[I]);
  Result := Self;
end;

procedure TSQLHaving.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

procedure TSQLHaving.CopyOf(const pSource: ISQLHaving);
var
  I: Integer;
begin
  GetCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    GetCriterias.Add(pSource.Criterias[I]);
end;

procedure TSQLHaving.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (GetStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLHaving.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  Result := FOrderBy;
end;

function TSQLHaving.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLHaving.ToString: string;
var
  I: Integer;
  vStrBuilder: TStringBuilder;
begin
  Result := EmptyStr;

  vStrBuilder := TStringBuilder.Create;
  try
    if Assigned(FStatementToString) then
    begin
      vStrBuilder.Append(FStatementToString);
      vStrBuilder.AppendLine;
    end;

    for I := 0 to Pred(GetCriterias.Count) do
    begin
      if I = 0 then
        vStrBuilder.Append(' Having ')
      else
        vStrBuilder.Append(' ' + GetCriterias[I].GetConnectorDescription + ' ');

      vStrBuilder.AppendFormat('(%0:S)', [GetCriterias[I].Criteria]);
    end;

    for I := 0 to Pred(FUnions.Count) do
      vStrBuilder.AppendLine.Append(FUnions[I].ToString);

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLHaving.Union(const pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLHaving;
begin
  InternalAddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(const pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLHaving;
begin
  InternalAddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLHaving;
begin
  InternalAddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLHaving;
begin
  InternalAddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(const pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLHaving;
begin
  InternalAddUnion(pHaving.ToString, pType);
  Result := Self;
end;

function TSQLHaving.OrderBy(const pColumnNames: array of string): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

{ TSQLGroupBy }

function TSQLGroupBy.Column(const pColumnName: string): ISQLGroupBy;
begin
  GetCriterias.Add(TSQLCriteria.Create(pColumnName, ctComma));
  Result := Self;
end;

function TSQLGroupBy.Columns(const pColumnNames: array of string): ISQLGroupBy;
var
  I: Integer;
begin
  GetCriterias.Clear;
  for I := low(pColumnNames) to high(pColumnNames) do
    Column(pColumnNames[I]);
  Result := Self;
end;

procedure TSQLGroupBy.AfterConstruction;
begin
  inherited AfterConstruction;
  FOrderBy := TSQLOrderBy.Create;
  FHaving := TSQLHaving.Create;
  FUnions := TList<ISQLUnion>.Create;
end;

procedure TSQLGroupBy.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

procedure TSQLGroupBy.CopyOf(const pSource: ISQLGroupBy);
var
  I: Integer;
begin
  GetCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    GetCriterias.Add(pSource.Criterias[I]);
end;

function TSQLGroupBy.Having(const pHavingCriterias: array of string): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  FHaving.Aggregate(pHavingCriterias);
  Result := FHaving;
end;

function TSQLGroupBy.Having: ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  Result := FHaving;
end;

function TSQLGroupBy.Having(const pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

procedure TSQLGroupBy.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (GetStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLGroupBy.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  Result := FOrderBy;
end;

function TSQLGroupBy.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLGroupBy.ToString: string;
var
  I: Integer;
  vStrBuilder: TStringBuilder;
begin
  Result := EmptyStr;

  vStrBuilder := TStringBuilder.Create;
  try
    if Assigned(FStatementToString) then
    begin
      vStrBuilder.Append(FStatementToString);
      vStrBuilder.AppendLine;
    end;

    for I := 0 to Pred(GetCriterias.Count) do
    begin
      if I = 0 then
        vStrBuilder.Append(' Group By')
      else
        vStrBuilder.Append(GetCriterias[I].GetConnectorDescription);

      vStrBuilder.Append(' ' + GetCriterias[I].Criteria);
    end;

    for I := 0 to Pred(FUnions.Count) do
      vStrBuilder.AppendLine.Append(FUnions[I].ToString);

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLGroupBy.Union(const pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLGroupBy;
begin
  InternalAddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(const pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLGroupBy;
begin
  InternalAddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLGroupBy;
begin
  InternalAddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLGroupBy;
begin
  InternalAddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(const pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLGroupBy;
begin
  InternalAddUnion(pHaving.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.OrderBy(const pColumnNames: array of string): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

{ TSQLSelect }

function TSQLSelect.Column(const pColumnName: string): ISQLSelect;
begin
  FColumns.Add(pColumnName);
  Result := Self;
end;

function TSQLSelect.Distinct: ISQLSelect;
begin
  FDistinct := True;
  Result := Self;
end;

function TSQLSelect.From(const pTableName, pTableAlias: string): ISQLSelect;
begin
  FFromTable.TableName := pTableName + ' ' + pTableAlias;
  Result := Self;
end;

procedure TSQLSelect.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stSelect);
  FDistinct := False;
  FColumns := TStringList.Create;
  FColumns.Delimiter := ',';
  FColumns.StrictDelimiter := True;
  FJoinedTables := TList<ISQLJoin>.Create;
  FFromTable := TSQLTable.Create;
  FGroupBy := TSQLGroupBy.Create;
  FHaving := TSQLHaving.Create;
  FOrderBy := TSQLOrderBy.Create;
  FWhere := TSQLWhere.Create;
  FUnions := TList<ISQLUnion>.Create;
end;

function TSQLSelect.Alias(const pColumnAlias: string): ISQLSelect;
var
  vColumn: string;
begin
  vColumn := FColumns[FColumns.Count - 1];
  if not ContainsText(vColumn, 'As') then
    FColumns[FColumns.Count - 1] := vColumn + ' As ' + pColumnAlias;
  Result := Self;
end;

function TSQLSelect.AllColumns: ISQLSelect;
begin
  FColumns.Clear;
  FColumns.Add('*');
  Result := Self;
end;

procedure TSQLSelect.BeforeDestruction;
begin
  FreeAndNil(FColumns);
  FreeAndNil(FJoinedTables);
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

function TSQLSelect.Column(const pColumnName, pColumnAlias: string): ISQLSelect;
var
  vColumn: string;
begin
  vColumn := pColumnName;

  if not pColumnAlias.IsEmpty then
    vColumn := vColumn + ' As ' + pColumnAlias;

  FColumns.Add(vColumn);
  Result := Self;
end;

function TSQLSelect.Column(const pColumnName: string; const pCoalesce: ISQLCoalesce; const pColumnAlias: string): ISQLSelect;
var
  vColumn: string;
begin
  if (pCoalesce <> nil) then
    vColumn := 'Coalesce(' + pColumnName + ',' + ConvertSQLValue(pCoalesce.GetValue) + ')'
  else
    vColumn := (pColumnName);

  if (pColumnAlias <> EmptyStr) then
    vColumn := vColumn + ' As ' + pColumnAlias;

  FColumns.Add(vColumn);
  Result := Self;
end;

function TSQLSelect.Column(const pAggregate: ISQLAggregate): ISQLSelect;
begin
  FColumns.Add(pAggregate.ToString);
  Result := Self;
end;

function TSQLSelect.Column(const pAggregate: ISQLAggregate; const pCoalesce: ISQLCoalesce): ISQLSelect;
begin
  FColumns.Add(pAggregate.ToString(pCoalesce));
  Result := Self;
end;

function TSQLSelect.From(const pTableName: string): ISQLSelect;
begin
  FFromTable.TableName := pTableName;
  Result := Self;
end;

function TSQLSelect.GroupBy(const pGroupBy: ISQLGroupBy): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.GetStatementType);
  FGroupBy.CopyOf(pGroupBy);
  Result := FGroupBy;
end;

function TSQLSelect.GroupBy: ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.GetStatementType);
  Result := FGroupBy;
end;

function TSQLSelect.GroupBy(const pColumnNames: array of string): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.GetStatementType);
  FGroupBy.Columns(pColumnNames);
  Result := FGroupBy;
end;

function TSQLSelect.Having: ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  Result := FHaving;
end;

function TSQLSelect.Having(const pHavingCriterias: array of string): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  FHaving.Aggregate(pHavingCriterias);
  Result := FHaving;
end;

function TSQLSelect.Having(const pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

function TSQLSelect.Join(const pTableName, pJoinCriteria: string): ISQLSelect;
begin
  FJoinedTables.Add(TSQLJoin.Create(pTableName, jtInner, pJoinCriteria));
  Result := Self;
end;

function TSQLSelect.LeftOuterJoin(const pTableName, pJoinCriteria: string): ISQLSelect;
begin
  FJoinedTables.Add(TSQLJoin.Create(pTableName, jtLeftOuter, pJoinCriteria));
  Result := Self;
end;

function TSQLSelect.OrderBy(const pColumnNames: array of string): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

function TSQLSelect.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLSelect.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  Result := FOrderBy;
end;

function TSQLSelect.RightOuterJoin(const pTableName, pJoinCriteria: string): ISQLSelect;
begin
  FJoinedTables.Add(TSQLJoin.Create(pTableName, jtRightOuter, pJoinCriteria));
  Result := Self;
end;

function TSQLSelect.SubSelect(const pGroupBy: ISQLGroupBy; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pGroupBy.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(const pWhere: ISQLWhere; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pWhere.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(const pOrderBy: ISQLOrderBy; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pOrderBy.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(const pHaving: ISQLHaving; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pHaving.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(const pSelect: ISQLSelect; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pSelect.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.TableAlias(const pAlias: string): ISQLSelect;
begin
  FFromTable.TableName := FFromTable.TableName + ' ' + pAlias;
  Result := Self;
end;

function TSQLSelect.ToString: string;
var
  I: Integer;
  vStrBuilder: TStringBuilder;
begin
  Result := '';

  if (FColumns.Count < 1) or (FFromTable.TableName = EmptyStr) then
    Exit;

  vStrBuilder := TStringBuilder.Create;
  try
    vStrBuilder.Append('Select ');

    if FDistinct then
      vStrBuilder.Append('Distinct ');

    for I := 0 to Pred(FColumns.Count) do
    begin
      if I = 0 then
        vStrBuilder.AppendLine
      else
        vStrBuilder.Append(',');

      vStrBuilder.Append(' ' + FColumns[I]);
    end;

    vStrBuilder.AppendLine.Append(' From ' + FFromTable.TableName);

    for I := 0 to Pred(FJoinedTables.Count) do
      vStrBuilder.AppendLine.Append(FJoinedTables[I].ToString);

    for I := 0 to Pred(FUnions.Count) do
      vStrBuilder.AppendLine.Append(FUnions[I].ToString);

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLSelect.Where: ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.AppendStatementType(Self.GetStatementType);
  Result := FWhere;
end;

function TSQLSelect.Where(const pColumnName: string): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.AppendStatementType(Self.GetStatementType);
  FWhere.Column(pColumnName);
  Result := FWhere;
end;

function TSQLSelect.Where(const pWhere: ISQLWhere): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.AppendStatementType(Self.GetStatementType);
  FWhere.CopyOf(pWhere);
  Result := FWhere;
end;

function TSQLSelect.Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pGroupBy.ToString));
  Result := Self;
end;

function TSQLSelect.Union(const pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pSelect.ToString));
  Result := Self;
end;

function TSQLSelect.Union(const pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pWhere.ToString));
  Result := Self;
end;

function TSQLSelect.Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pOrderBy.ToString));
  Result := Self;
end;

function TSQLSelect.Union(const pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pHaving.ToString));
  Result := Self;
end;

{ TSQLJoin }

constructor TSQLJoin.Create(const pTableName: string; const pJoinType: TSQLJoinType; const pCriteria: string);
begin
  FTable := TSQLTable.Create(pTableName);
  FJoinType := pJoinType;
  FCriteria := pCriteria;
end;

constructor TSQLJoin.Create;
begin
  FTable := TSQLTable.Create;
  FJoinType := jtNone;
  FCriteria := EmptyStr;
end;

function TSQLJoin.GetCriteria: string;
begin
  Result := FCriteria;
end;

function TSQLJoin.GetJoinType: TSQLJoinType;
begin
  Result := FJoinType;
end;

function TSQLJoin.GetTable: ISQLTable;
begin
  Result := FTable;
end;

procedure TSQLJoin.SetCriteria(const pCriteria: string);
begin
  FCriteria := pCriteria;
end;

procedure TSQLJoin.SetJoinType(const pType: TSQLJoinType);
begin
  FJoinType := pType;
end;

procedure TSQLJoin.SetTable(const pSQLTable: ISQLTable);
begin
  FTable := pSQLTable;
end;

function TSQLJoin.ToString: string;
begin
  Result := FTable.TableName;
  case FJoinType of
    jtInner:
      Result := ' Join ' + FTable.TableName + ' On ' + FCriteria;
    jtLeftOuter:
      Result := ' Left Outer Join ' + FTable.TableName + ' On ' + FCriteria;
    jtRightOuter:
      Result := ' Right Outer Join ' + FTable.TableName + ' On ' + FCriteria;
  end;
end;

{ TSQLWhere }

procedure TSQLWhere.AfterConstruction;
begin
  inherited AfterConstruction;
  FColumnName := EmptyStr;
  FConnectorType := ctAnd;
  FGroupBy := TSQLGroupBy.Create;
  FHaving := TSQLHaving.Create;
  FOrderBy := TSQLOrderBy.Create;
  FUnions := TList<ISQLUnion>.Create;
end;

procedure TSQLWhere.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

function TSQLWhere.Between(const pInitial, pFinal: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' Between ' + ConvertSQLValue(pInitial) + ' And ' + ConvertSQLValue(pFinal) + ')',
    FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

procedure TSQLWhere.CopyOf(const pSource: ISQLWhere);
var
  I: Integer;
begin
  GetCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    GetCriterias.Add(pSource.Criterias[I]);
end;

function TSQLWhere.Criterion(const pOperator: TSQLOperatorType; const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[pOperator] + ' ' + ConvertSQLValue(pValue) + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.ColumnCriterion(const pOperator: TSQLOperatorType; const pColumnNameValue: string): ISQLWhere;
begin
  ColumnIsValid(FColumnName);
  ColumnIsValid(pColumnNameValue);

  GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[pOperator] + ' ' + pColumnNameValue + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Column(const pColumnName: string): ISQLWhere;
begin
  FConnectorType := ctAnd;
  FColumnName := pColumnName;
  Result := Self;
end;

function TSQLWhere.Different(const pValue: string; const pCaseSensitive: Boolean): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opDifferent], pValue, pCaseSensitive);
  Result := Self;
end;

function TSQLWhere.Different(const pValue: TValue): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opDifferent], pValue, True);
  Result := Self;
end;

function TSQLWhere.Equal(const pValue: string; const pCaseSensitive: Boolean): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opEqual], pValue, pCaseSensitive);
  Result := Self;
end;

function TSQLWhere.Equal(const pValue: TValue): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opEqual], pValue, True);
  Result := Self;
end;

function TSQLWhere.Greater(const pValue: TValue): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opGreater], pValue, True);
  Result := Self;
end;

function TSQLWhere.GreaterOrEqual(const pValue: TValue): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opGreaterOrEqual], pValue, True);
  Result := Self;
end;

function TSQLWhere.GroupBy(const pColumnNames: array of string): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.GetStatementType);
  FGroupBy.Columns(pColumnNames);
  Result := FGroupBy;
end;

function TSQLWhere.GroupBy(const pGroupBy: ISQLGroupBy): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.GetStatementType);
  FGroupBy.CopyOf(pGroupBy);
  Result := FGroupBy;
end;

function TSQLWhere.GroupBy: ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.GetStatementType);
  Result := FGroupBy;
end;

function TSQLWhere.Having(const pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

function TSQLWhere.Having(const pHavingCriterias: array of string): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  FHaving.Aggregate(pHavingCriterias);
  Result := FHaving;
end;

function TSQLWhere.Having: ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.GetStatementType);
  Result := FHaving;
end;

function TSQLWhere.InList(const pValues: array of TValue): ISQLWhere;
begin
  Result := Self.InternalInList(pValues, False);
end;

procedure TSQLWhere.InternalAddBasicCriteria(const pSQLOperator: string; const pSQLValue: TValue; const pCaseSensitive: Boolean);
begin
  ColumnIsValid(FColumnName);

  if pCaseSensitive then
    GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' +
      pSQLOperator + ' ' + ConvertSQLValue(pSQLValue) + ')', FConnectorType))
  else
    GetCriterias.Add(TSQLCriteria.Create('(Upper(' + FColumnName + ') ' +
      pSQLOperator + ' Upper(' + ConvertSQLValue(pSQLValue) + '))', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
end;

procedure TSQLWhere.InternalAddLikeCriteria(const pSQLOperator, pSQLValue: string; const pLikeOperator: TSQLLikeType; const pCaseSensitive: Boolean);
var
  vValue: string;
begin
  ColumnIsValid(FColumnName);

  ValidateSQLReservedWord(pSQLValue);

  case pLikeOperator of
    loEqual:
      vValue := QuotedStr(pSQLValue);
    loStarting:
      vValue := QuotedStr(pSQLValue + '%');
    loEnding:
      vValue := QuotedStr('%' + pSQLValue);
    loContaining:
      vValue := QuotedStr('%' + pSQLValue + '%');
  end;

  if pCaseSensitive then
    GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + pSQLOperator + ' ' + vValue + ')', FConnectorType))
  else
    GetCriterias.Add(TSQLCriteria.Create('(Upper(' + FColumnName + ') ' + pSQLOperator + ' Upper(' + vValue + '))', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
end;

procedure TSQLWhere.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (GetStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLWhere.InternalInList(const pValues: array of TValue; const pNotIn: Boolean): ISQLWhere;
var
  vStrBuilder: TStringBuilder;
  I: Integer;
begin
  ColumnIsValid(FColumnName);

  vStrBuilder := TStringBuilder.Create;
  try
    vStrBuilder.Append('(');
    for I := low(pValues) to high(pValues) do
    begin
      if (I > 0) then
        vStrBuilder.Append(', ');

      vStrBuilder.Append(ConvertSQLValue(pValues[I]));
    end;
    vStrBuilder.Append(')');

    if pNotIn then
      GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' Not In ' + vStrBuilder.ToString + ')', FConnectorType))
    else
      GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' In ' + vStrBuilder.ToString + ')', FConnectorType));
  finally
    FreeAndNil(vStrBuilder);
  end;

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.IsNotNull: ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' Is Not Null)', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.IsNull: ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  GetCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' Is Null)', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Less(const pValue: TValue): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opLess], pValue, True);
  Result := Self;
end;

function TSQLWhere.LessOrEqual(const pValue: TValue): ISQLWhere;
begin
  InternalAddBasicCriteria(_cSQLOperator[opLessOrEqual], pValue, True);
  Result := Self;
end;

function TSQLWhere.Like(const pValues: array of string; const pOperator: TSQLLikeType): ISQLWhere;
var
  vWhere: ISQLWhere;
  I: Integer;
begin
  vWhere := TSQLBuilder.Where(FColumnName).Like(pValues[0], pOperator);
  for I := 1 to High(pValues) do
    vWhere._Or(FColumnName).Like(pValues[I], pOperator);

  Self._And(vWhere);

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Like(const pValues: array of string; const pCaseSensitive: Boolean; const pOperator: TSQLLikeType): ISQLWhere;
var
  vWhere: ISQLWhere;
  I: Integer;
begin
  vWhere := TSQLBuilder.Where(FColumnName).Like(pValues[0], pCaseSensitive, pOperator);
  for I := 1 to High(pValues) do
    vWhere._Or(FColumnName).Like(pValues[I], pCaseSensitive, pOperator);

  Self._And(vWhere);

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Like(const pValue: string; const pCaseSensitive: Boolean; const pOperator: TSQLLikeType): ISQLWhere;
begin
  InternalAddLikeCriteria(_cSQLOperator[opLike], pValue, pOperator, pCaseSensitive);
  Result := Self;
end;

function TSQLWhere.Like(const pValue: string; const pOperator: TSQLLikeType): ISQLWhere;
begin
  InternalAddLikeCriteria(_cSQLOperator[opLike], pValue, pOperator, True);
  Result := Self;
end;

function TSQLWhere.NotInList(const pValues: array of TValue): ISQLWhere;
begin
  Result := Self.InternalInList(pValues, True);
end;

function TSQLWhere.NotLike(const pValue: string; const pCaseSensitive: Boolean; const pOperator: TSQLLikeType): ISQLWhere;
begin
  InternalAddLikeCriteria(_cSQLOperator[opNotLike], pValue, pOperator, pCaseSensitive);
  Result := Self;
end;

function TSQLWhere.NotLike(const pValue: string; const pOperator: TSQLLikeType): ISQLWhere;
begin
  InternalAddLikeCriteria(_cSQLOperator[opNotLike], pValue, pOperator, True);
  Result := Self;
end;

function TSQLWhere.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  Result := FOrderBy;
end;

function TSQLWhere.OrderBy(const pColumnNames: array of string): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

function TSQLWhere.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.GetStatementType);
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLWhere.ToString: string;
var
  I: Integer;
  vStrBuilder: TStringBuilder;
begin
  Result := EmptyStr;

  vStrBuilder := TStringBuilder.Create;
  try
    if Assigned(FStatementToString) then
    begin
      vStrBuilder.Append(FStatementToString);
      vStrBuilder.AppendLine;
    end;

    for I := 0 to Pred(GetCriterias.Count) do
    begin
      if (I = 0) then
        vStrBuilder.Append(' Where ')
      else
        vStrBuilder.Append(' ' + GetCriterias[I].GetConnectorDescription + ' ');

      vStrBuilder.Append(GetCriterias[I].Criteria);
    end;

    for I := 0 to Pred(FUnions.Count) do
      vStrBuilder.AppendLine.Append(FUnions[I].ToString);

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLWhere._And(const pColumnName: string): ISQLWhere;
begin
  FConnectorType := ctAnd;
  FColumnName := pColumnName;
  Result := Self;
end;

function TSQLWhere._And(const pWhere: ISQLWhere): ISQLWhere;
begin
  pWhere.AppendStatementToString(nil);

  GetCriterias.Add(TSQLCriteria.Create('(' + AnsiReplaceText(pWhere.ToString, ' Where ', '') + ')', ctAnd));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere._Or(const pWhere: ISQLWhere): ISQLWhere;
begin
  pWhere.AppendStatementToString(nil);

  GetCriterias.Add(TSQLCriteria.Create('(' + AnsiReplaceText(pWhere.ToString, ' Where ', '') + ')', ctOr));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere._Or(const pColumnName: string): ISQLWhere;
begin
  FConnectorType := ctOr;
  FColumnName := pColumnName;
  Result := Self;
end;

{ TSQLCriteria }

constructor TSQLCriteria.Create(const pCriteria: string; const pConnectorType: TSQLConnectorType);
begin
  FCriteria := pCriteria;
  FConnectorType := pConnectorType;
end;

constructor TSQLCriteria.Create;
begin
  FCriteria := EmptyStr;
  FConnectorType := ctAnd;
end;

function TSQLCriteria.GetCriteria: string;
begin
  Result := FCriteria;
end;

function TSQLCriteria.GetConnector: TSQLConnectorType;
begin
  Result := FConnectorType;
end;

function TSQLCriteria.GetConnectorDescription: string;
begin
  Result := EmptyStr;
  case FConnectorType of
    ctAnd:
      Result := 'And';
    ctOr:
      Result := 'Or';
    ctComma:
      Result := ',';
  end;
end;

procedure TSQLCriteria.SetCriteria(const pCriteria: string);
begin
  FCriteria := pCriteria;
end;

procedure TSQLCriteria.SetConnector(const pConnectorType: TSQLConnectorType);
begin
  FConnectorType := pConnectorType;
end;

function TSQLWhere.Union(const pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLWhere;
begin
  InternalAddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLWhere;
begin
  InternalAddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(const pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLWhere;
begin
  InternalAddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLWhere;
begin
  InternalAddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(const pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLWhere;
begin
  InternalAddUnion(pHaving.ToString, pType);
  Result := Self;
end;

{ TSQLDelete }

procedure TSQLDelete.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stDelete);
  FTable := TSQLTable.Create;
  FWhere := TSQLWhere.Create;
end;

procedure TSQLDelete.BeforeDestruction;
begin

  inherited BeforeDestruction;
end;

function TSQLDelete.From(const pTableName: string): ISQLDelete;
begin
  FTable.TableName := pTableName;
  Result := Self;
end;

function TSQLDelete.ToString: string;
var
  vStrBuilder: TStringBuilder;
begin
  Result := '';

  if (FTable.TableName = EmptyStr) then
    Exit;

  vStrBuilder := TStringBuilder.Create;
  try
    vStrBuilder.Append('Delete From ').Append(FTable.TableName);

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLDelete.Where(const pWhere: ISQLWhere): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.CopyOf(pWhere);
  Result := FWhere;
end;

function TSQLDelete.Where(const pColumnName: string): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.Column(pColumnName);
  Result := FWhere;
end;

function TSQLDelete.Where: ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  Result := FWhere;
end;

{ TSQLValue }

constructor TSQLValue.Create;
begin
  FValue := EmptyStr;
end;

constructor TSQLValue.Create(const pValue: string);
begin
  FValue := pValue;
end;

function TSQLValue.GetValue: string;
begin
  Result := FValue;
end;

procedure TSQLValue.SetValue(const pValue: string);
begin
  FValue := pValue;
end;

{ TSQLUpdate }

procedure TSQLUpdate.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stUpdate);
  FColumns := TStringList.Create;
  FValues := TList<ISQLValue>.Create;
  FTable := TSQLTable.Create;
  FWhere := TSQLWhere.Create;
end;

procedure TSQLUpdate.BeforeDestruction;
begin
  FreeAndNil(FColumns);
  FreeAndNil(FValues);
  inherited BeforeDestruction;
end;

function TSQLUpdate.Columns(const pColumnNames: array of string): ISQLUpdate;
var
  I: Integer;
begin
  FColumns.Clear;
  for I := low(pColumnNames) to high(pColumnNames) do
  begin
    ColumnIsValid(pColumnNames[I]);
    FColumns.Add(pColumnNames[I]);
  end;
  Result := Self;
end;

function TSQLUpdate.ColumnSetValue(const pColumnName: string; const pValue: TValue): ISQLUpdate;
begin
  ColumnIsValid(pColumnName);
  FColumns.Add(pColumnName);
  FValues.Add(TSQLValue.Create(ConvertSQLValue(pValue)));
  Result := Self;
end;

function TSQLUpdate.Table(const pTableName: string): ISQLUpdate;
begin
  FTable.TableName := pTableName;
  Result := Self;
end;

function TSQLUpdate.ToString: string;
var
  I: Integer;
  vStrBuilder: TStringBuilder;
begin
  Result := '';

  if (FColumns.Count <> FValues.Count) then
    raise ESQLBuilderException.Create('Columns count and Values count must be equal!');

  if (FTable.TableName = EmptyStr) then
    Exit;

  vStrBuilder := TStringBuilder.Create;
  try
    vStrBuilder.Append('Update ' + FTable.TableName + ' Set');

    for I := 0 to Pred(FColumns.Count) do
    begin
      if I = 0 then
        vStrBuilder.AppendLine
      else
        vStrBuilder.Append(',').AppendLine;

      vStrBuilder.AppendFormat(' %0:S = %1:S', [FColumns[I], FValues[I].Value]);
    end;

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLUpdate.SetValues(const pValues: array of TValue): ISQLUpdate;
var
  I: Integer;
begin
  FValues.Clear;
  for I := low(pValues) to high(pValues) do
    FValues.Add(TSQLValue.Create(ConvertSQLValue(pValues[I])));
  Result := Self;
end;

function TSQLUpdate.Where(const pWhere: ISQLWhere): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.CopyOf(pWhere);
  Result := FWhere;
end;

function TSQLUpdate.Where(const pColumnName: string): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.Column(pColumnName);
  Result := FWhere;
end;

function TSQLUpdate.Where: ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  Result := FWhere;
end;

{ TSQLInsert }

procedure TSQLInsert.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stInsert);
  FColumns := TStringList.Create;
  FValues := TList<ISQLValue>.Create;
  FTable := TSQLTable.Create;
end;

procedure TSQLInsert.BeforeDestruction;
begin
  FreeAndNil(FColumns);
  FreeAndNil(FValues);
  inherited BeforeDestruction;
end;

function TSQLInsert.Columns(const pColumnNames: array of string): ISQLInsert;
var
  I: Integer;
begin
  FColumns.Clear;
  for I := low(pColumnNames) to high(pColumnNames) do
  begin
    ColumnIsValid(pColumnNames[I]);
    FColumns.Add(pColumnNames[I]);
  end;
  Result := Self;
end;

function TSQLInsert.ColumnValue(const pColumnName: string; const pValue: TValue): ISQLInsert;
begin
  ColumnIsValid(pColumnName);
  FColumns.Add(pColumnName);
  FValues.Add(TSQLValue.Create(ConvertSQLValue(pValue)));
  Result := Self;
end;

function TSQLInsert.Into(const pTableName: string): ISQLInsert;
begin
  FTable.TableName := pTableName;
  Result := Self;
end;

function TSQLInsert.ToString: string;
var
  I: Integer;
  vStrBuilder: TStringBuilder;
begin
  Result := '';

  if (FColumns.Count <> FValues.Count) then
    raise ESQLBuilderException.Create('Columns count and Values count must be equal!');

  if (FTable.TableName = EmptyStr) then
    Exit;

  vStrBuilder := TStringBuilder.Create;
  try
    vStrBuilder.Append('Insert Into ' + FTable.TableName);

    vStrBuilder.AppendLine.Append(' (');

    for I := 0 to Pred(FColumns.Count) do
    begin
      if (I = 0) then
        vStrBuilder.Append(FColumns[I])
      else
      begin
        vStrBuilder.Append(',').AppendLine;
        vStrBuilder.Append('  ' + FColumns[I]);
      end;
    end;

    vStrBuilder.Append(')').AppendLine.Append(' Values').AppendLine.Append(' (');

    for I := 0 to Pred(FValues.Count) do
    begin
      if (I = 0) then
        vStrBuilder.Append(FValues[I].Value)
      else
      begin
        vStrBuilder.Append(',').AppendLine;
        vStrBuilder.Append('  ' + FValues[I].Value);
      end;
    end;

    vStrBuilder.Append(')');

    Result := vStrBuilder.ToString;
  finally
    FreeAndNil(vStrBuilder);
  end;
end;

function TSQLInsert.Values(const pValues: array of TValue): ISQLInsert;
var
  I: Integer;
begin
  FValues.Clear;
  for I := low(pValues) to high(pValues) do
    FValues.Add(TSQLValue.Create(ConvertSQLValue(pValues[I])));
  Result := Self;
end;

{ TSQLUnion }

constructor TSQLUnion.Create;
begin
  FUnionType := utUnion;
  FUnionSQL := EmptyStr;
end;

constructor TSQLUnion.Create(const pType: TSQLUnionType; const pUnionSQL: string);
begin
  FUnionType := pType;
  FUnionSQL := pUnionSQL;
end;

function TSQLUnion.GetUnionSQL: string;
begin
  Result := FUnionSQL;
end;

function TSQLUnion.GetUnionType: TSQLUnionType;
begin
  Result := FUnionType;
end;

procedure TSQLUnion.SetUnionSQL(const pUnionSQL: string);
begin
  FUnionSQL := pUnionSQL;
end;

procedure TSQLUnion.SetUnionType(const pUnionType: TSQLUnionType);
begin
  FUnionType := pUnionType;
end;

function TSQLUnion.ToString: string;
begin
  case FUnionType of
    utUnion:
      Result := 'Union';
    utUnionAll:
      Result := 'Union All';
  end;
  Result := Result + sLineBreak + FUnionSQL;
end;

{ TSQLAggregate }

function TSQLAggregate.AggAlias(const pAlias: string): ISQLAggregate;
begin
  FAlias := pAlias;
  Result := Self;
end;

function TSQLAggregate.AggCoalesce(const pCoalesce: ISQLCoalesce): ISQLAggregate;
begin
  FCoalesce := pCoalesce;
  Result := Self;
end;

function TSQLAggregate.AggExpression(const pExpression: string): ISQLAggregate;
begin
  FExpression := pExpression;
  Result := Self;
end;

function TSQLAggregate.AggFunction(const pFunction: TSQLAggregateFunctions): ISQLAggregate;
begin
  FFunction := pFunction;
  Result := Self;
end;

constructor TSQLAggregate.Create;
begin
  FFunction := aggAvg;
  FExpression := EmptyStr;
  FAlias := EmptyStr;
  FCoalesce := nil;
end;

constructor TSQLAggregate.Create(const pFunction: TSQLAggregateFunctions; const pExpression, pAlias: string; const pCoalesce: ISQLCoalesce);
begin
  FFunction := pFunction;
  FExpression := pExpression;
  FAlias := pAlias;
  FCoalesce := pCoalesce;
end;

function TSQLAggregate.GetAggAlias: string;
begin
  Result := FAlias;
end;

function TSQLAggregate.GetAggCoalesce: ISQLCoalesce;
begin
  Result := FCoalesce;
end;

function TSQLAggregate.GetAggExpression: string;
begin
  Result := FExpression;
end;

function TSQLAggregate.GetAggFunction: TSQLAggregateFunctions;
begin
  Result := FFunction;
end;

function TSQLAggregate.ToString(const pOwnerCoalesce: ISQLCoalesce): string;
begin
  if (GetAggCoalesce <> nil) then
  begin
    if (pOwnerCoalesce <> nil) then
      Result := 'Coalesce(' + AggregateFunctionToString(GetAggFunction) +
        '(Coalesce(' + GetAggExpression + ',' + ConvertSQLValue(GetAggCoalesce.GetValue) + ')),' + ConvertSQLValue(pOwnerCoalesce.GetValue) + ')'
    else
      Result := AggregateFunctionToString(GetAggFunction) +
        '(Coalesce(' + GetAggExpression + ',' + ConvertSQLValue(GetAggCoalesce.GetValue) + '))'
  end
  else
  begin
    if (pOwnerCoalesce <> nil) then
      Result := 'Coalesce(' + AggregateFunctionToString(GetAggFunction) +
        '(' + GetAggExpression + '),' + ConvertSQLValue(pOwnerCoalesce.GetValue) + ')'
    else
      Result := AggregateFunctionToString(GetAggFunction) +
        '(' + GetAggExpression + ')';
  end;

  if (GetAggAlias <> EmptyStr) then
    Result := Result + ' As ' + GetAggAlias;
end;

{ TSQLCoalesce }

constructor TSQLCoalesce.Create;
begin

end;

constructor TSQLCoalesce.Create(const pValue: TValue);
begin
  FValue := pValue;
end;

function TSQLCoalesce.GetValue: TValue;
begin
  Result := FValue;
end;

function TSQLCoalesce.Value(const pValue: TValue): ISQLCoalesce;
begin
  FValue := pValue;
  Result := Self;
end;

{ TSQLStatement }

procedure TSQLStatement.AfterConstruction;
begin
  inherited AfterConstruction;
  FStatementType := stNone;
end;

function TSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := FStatementType;
end;

procedure TSQLStatement.SaveToFile(const pFileName: string);
begin
  SaveSQLToFile(pFileName, Self.ToString);
end;

procedure TSQLStatement.SetStatementType(const pStatementType: TSQLStatementType);
begin
  FStatementType := pStatementType;
end;

function TSQLStatement.ToString: string;
begin
  // Inheritance ToString
end;

{ TSQLClause }

procedure TSQLClause.AfterConstruction;
begin
  inherited AfterConstruction;
  FCriterias := TList<ISQLCriteria>.Create;
  FStatementToString := nil;
  FStatementType := stNone;
end;

procedure TSQLClause.AppendStatementToString(const pFuncToString: TFunc<string>);
begin
  FStatementToString := pFuncToString;
end;

procedure TSQLClause.AppendStatementType(const pStatementType: TSQLStatementType);
begin
  FStatementType := pStatementType;
end;

procedure TSQLClause.BeforeDestruction;
begin
  FreeAndNil(FCriterias);
  inherited BeforeDestruction;
end;

function TSQLClause.GetCriterias: TList<ISQLCriteria>;
begin
  Result := FCriterias;
end;

function TSQLClause.GetStatementType: TSQLStatementType;
begin
  Result := FStatementType;
end;

procedure TSQLClause.SaveToFile(const pFileName: string);
begin
  SaveSQLToFile(pFileName, Self.ToString);
end;

function TSQLClause.ToString: string;
begin
  // Inheritance ToString
end;

end.
