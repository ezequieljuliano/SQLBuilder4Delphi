(*
  Copyright 2014 Ezequiel Juliano Müller | Microsys Sistemas Ltda

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*)

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

  TSQLOrderBy = class(TInterfacedObject, ISQLOrderBy)
  strict private
    FCriterias: TList<ISQLCriteria>;
    FStatementToString: TFunc<string>;
    FStatementType: TSQLStatementType;
    FSortType: TSQLSortType;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetCriterias(): TList<ISQLCriteria>;

    procedure AppendStatementToString(const pFuncToString: TFunc<string>);
    procedure AppendStatementType(const pStatementType: TSQLStatementType);

    procedure CopyOf(const pSource: ISQLOrderBy);

    function ToString(): string; override;

    function Column(const pColumnName: string): ISQLOrderBy;
    function Columns(const pColumnNames: array of string): ISQLOrderBy;
    function Sort(const pSortType: TSQLSortType): ISQLOrderBy;

    function Union(const pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;

    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  TSQLHaving = class(TInterfacedObject, ISQLHaving)
  strict private
    FCriterias: TList<ISQLCriteria>;
    FStatementToString: TFunc<string>;
    FStatementType: TSQLStatementType;
    FOrderBy: ISQLOrderBy;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetCriterias(): TList<ISQLCriteria>;

    procedure AppendStatementToString(const pFuncToString: TFunc<string>);
    procedure AppendStatementType(const pStatementType: TSQLStatementType);

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

    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  TSQLGroupBy = class(TInterfacedObject, ISQLGroupBy)
  strict private
    FCriterias: TList<ISQLCriteria>;
    FStatementToString: TFunc<string>;
    FStatementType: TSQLStatementType;
    FOrderBy: ISQLOrderBy;
    FHaving: ISQLHaving;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetCriterias(): TList<ISQLCriteria>;

    procedure AppendStatementToString(const pFuncToString: TFunc<string>);
    procedure AppendStatementType(const pStatementType: TSQLStatementType);

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

    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  TSQLWhere = class(TInterfacedObject, ISQLWhere)
  strict private
    FCriterias: TList<ISQLCriteria>;
    FStatementToString: TFunc<string>;
    FStatementType: TSQLStatementType;
    FColumnName: string;
    FConnectorType: TSQLConnectorType;
    FGroupBy: ISQLGroupBy;
    FHaving: ISQLHaving;
    FOrderBy: ISQLOrderBy;
    FUnions: TList<ISQLUnion>;
    procedure InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetCriterias(): TList<ISQLCriteria>;

    procedure AppendStatementToString(const pFuncToString: TFunc<string>);
    procedure AppendStatementType(const pStatementType: TSQLStatementType);

    procedure CopyOf(const pSource: ISQLWhere);

    function ToString(): string; override;

    function Column(const pColumnName: string): ISQLWhere;

    function _And(const pColumnName: string): ISQLWhere; overload;
    function _And(const pWhere: ISQLWhere): ISQLWhere; overload;

    function _Or(const pColumnName: string): ISQLWhere; overload;
    function _Or(const pWhere: ISQLWhere): ISQLWhere; overload;

    function Equal(const pValue: TValue): ISQLWhere;
    function Different(const pValue: TValue): ISQLWhere;
    function Greater(const pValue: TValue): ISQLWhere;
    function Less(const pValue: TValue): ISQLWhere;
    function GreaterOrEqual(const pValue: TValue): ISQLWhere;
    function LessOrEqual(const pValue: TValue): ISQLWhere;
    function Like(const pValue: string; const pOperator: TSQLLikeType = loEqual): ISQLWhere;
    function NotLike(const pValue: string; const pOperator: TSQLLikeType = loEqual): ISQLWhere;
    function IsNull(): ISQLWhere;
    function IsNotNull(): ISQLWhere;
    function InList(const pValues: array of TValue): ISQLWhere;
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

    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  TSQLSelect = class(TInterfacedObject, ISQLSelect)
  strict private
    FStatementType: TSQLStatementType;
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

    function GetStatementType(): TSQLStatementType;

    function AllColumns(): ISQLSelect;
    function Column(const pColumnName: string): ISQLSelect;

    function SubSelect(const pSelect: ISQLSelect; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pWhere: ISQLWhere; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pGroupBy: ISQLGroupBy; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pHaving: ISQLHaving; const pAlias: string): ISQLSelect; overload;
    function SubSelect(const pOrderBy: ISQLOrderBy; const pAlias: string): ISQLSelect; overload;

    function From(const pTableName: string): ISQLSelect;
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

    property StatementType: TSQLStatementType read GetStatementType;
  end;

  TSQLDelete = class(TInterfacedObject, ISQLDelete)
  strict private
    FStatementType: TSQLStatementType;
    FTable: ISQLTable;
    FWhere: ISQLWhere;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetStatementType(): TSQLStatementType;

    function ToString(): string; override;

    function From(const pTableName: string): ISQLDelete;

    function Where(): ISQLWhere; overload;
    function Where(const pColumnName: string): ISQLWhere; overload;
    function Where(const pWhere: ISQLWhere): ISQLWhere; overload;

    property StatementType: TSQLStatementType read GetStatementType;
  end;

  TSQLUpdate = class(TInterfacedObject, ISQLUpdate)
  strict private
    FStatementType: TSQLStatementType;
    FColumns: TStringList;
    FValues: TList<ISQLValue>;
    FTable: ISQLTable;
    FWhere: ISQLWhere;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetStatementType(): TSQLStatementType;

    function ToString(): string; override;

    function Table(const pTableName: string): ISQLUpdate;
    function ColumnSetValue(const pColumnName: string; const pValue: TValue): ISQLUpdate;
    function Columns(const pColumnNames: array of string): ISQLUpdate;
    function SetValues(const pValues: array of TValue): ISQLUpdate;

    function Where(): ISQLWhere; overload;
    function Where(const pColumnName: string): ISQLWhere; overload;
    function Where(const pWhere: ISQLWhere): ISQLWhere; overload;

    property StatementType: TSQLStatementType read GetStatementType;
  end;

  TSQLInsert = class(TInterfacedObject, ISQLInsert)
  strict private
    FStatementType: TSQLStatementType;
    FColumns: TStringList;
    FValues: TList<ISQLValue>;
    FTable: ISQLTable;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function GetStatementType(): TSQLStatementType;

    function ToString(): string; override;

    function Into(const pTableName: string): ISQLInsert;
    function ColumnValue(const pColumnName: string; const pValue: TValue): ISQLInsert;
    function Columns(const pColumnNames: array of string): ISQLInsert;
    function Values(const pValues: array of TValue): ISQLInsert;

    property StatementType: TSQLStatementType read GetStatementType;
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
      'first', 'insert', 'update', 'delete');
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
    Exit(QuotedStr('Null'));

  ValidateSQLReservedWord(Result);

  case pValue.Kind of
    tkUString, tkWChar, tkLString, tkWString, tkString, tkChar:
      begin
        Result := QuotedStr(Result);
      end;
    tkUnknown:
      begin
        Result := QuotedStr('Null');
      end;
    tkFloat:
      begin
        Result := AnsiReplaceText(Result, ',', '.');
      end;
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

function TSQLOrderBy.Column(const pColumnName: string): ISQLOrderBy;
begin
  FCriterias.Add(TSQLCriteria.Create(pColumnName, ctComma));
  Result := Self;
end;

function TSQLOrderBy.Columns(const pColumnNames: array of string): ISQLOrderBy;
var
  I: Integer;
begin
  FCriterias.Clear;
  for I := low(pColumnNames) to high(pColumnNames) do
    Column(pColumnNames[I]);
  Result := Self;
end;

procedure TSQLOrderBy.AfterConstruction;
begin
  inherited AfterConstruction;
  FCriterias := TList<ISQLCriteria>.Create;
  FStatementToString := nil;
  FStatementType := stNone;
  FUnions := TList<ISQLUnion>.Create;
end;

procedure TSQLOrderBy.AppendStatementToString(const pFuncToString: TFunc<string>);
begin
  FStatementToString := pFuncToString;
end;

procedure TSQLOrderBy.AppendStatementType(const pStatementType: TSQLStatementType);
begin
  FStatementType := pStatementType;
end;

procedure TSQLOrderBy.BeforeDestruction;
begin
  FreeAndNil(FCriterias);
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

procedure TSQLOrderBy.CopyOf(const pSource: ISQLOrderBy);
var
  I: Integer;
begin
  FCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    FCriterias.Add(pSource.Criterias[I]);
end;

function TSQLOrderBy.GetCriterias: TList<ISQLCriteria>;
begin
  Result := FCriterias;
end;

procedure TSQLOrderBy.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (FStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLOrderBy.Sort(const pSortType: TSQLSortType): ISQLOrderBy;
begin
  FSortType := pSortType;
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

    for I := 0 to Pred(FCriterias.Count) do
    begin
      if I = 0 then
        vStrBuilder.Append(' Order By')
      else
        vStrBuilder.Append(FCriterias[I].GetConnectorDescription);

      vStrBuilder.Append(' ' + Criterias[I].Criteria);
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
  FCriterias.Add(TSQLCriteria.Create(pHavingCriteria, ctAnd));
  Result := Self;
end;

procedure TSQLHaving.AfterConstruction;
begin
  inherited AfterConstruction;
  FCriterias := TList<ISQLCriteria>.Create;
  FStatementToString := nil;
  FStatementType := stNone;
  FOrderBy := TSQLOrderBy.Create;
  FUnions := TList<ISQLUnion>.Create;
end;

function TSQLHaving.Aggregate(const pHavingCriterias: array of string): ISQLHaving;
var
  I: Integer;
begin
  FCriterias.Clear;
  for I := low(pHavingCriterias) to high(pHavingCriterias) do
    Aggregate(pHavingCriterias[I]);
  Result := Self;
end;

procedure TSQLHaving.AppendStatementToString(const pFuncToString: TFunc<string>);
begin
  FStatementToString := pFuncToString;
end;

procedure TSQLHaving.AppendStatementType(const pStatementType: TSQLStatementType);
begin
  FStatementType := pStatementType;
end;

procedure TSQLHaving.BeforeDestruction;
begin
  FreeAndNil(FCriterias);
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

procedure TSQLHaving.CopyOf(const pSource: ISQLHaving);
var
  I: Integer;
begin
  FCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    FCriterias.Add(pSource.Criterias[I]);
end;

function TSQLHaving.GetCriterias: TList<ISQLCriteria>;
begin
  Result := FCriterias;
end;

procedure TSQLHaving.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (FStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLHaving.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
  Result := FOrderBy;
end;

function TSQLHaving.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
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

    for I := 0 to Pred(FCriterias.Count) do
    begin
      if I = 0 then
        vStrBuilder.Append(' Having ')
      else
        vStrBuilder.Append(' ' + FCriterias[I].GetConnectorDescription + ' ');

      vStrBuilder.AppendFormat('(%0:S)', [FCriterias[I].Criteria]);
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
  FOrderBy.AppendStatementType(Self.FStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

{ TSQLGroupBy }

function TSQLGroupBy.Column(const pColumnName: string): ISQLGroupBy;
begin
  FCriterias.Add(TSQLCriteria.Create(pColumnName, ctComma));
  Result := Self;
end;

function TSQLGroupBy.Columns(const pColumnNames: array of string): ISQLGroupBy;
var
  I: Integer;
begin
  FCriterias.Clear;
  for I := low(pColumnNames) to high(pColumnNames) do
    Column(pColumnNames[I]);
  Result := Self;
end;

procedure TSQLGroupBy.AfterConstruction;
begin
  inherited AfterConstruction;
  FCriterias := TList<ISQLCriteria>.Create;
  FStatementToString := nil;
  FStatementType := stNone;
  FOrderBy := TSQLOrderBy.Create;
  FHaving := TSQLHaving.Create;
  FUnions := TList<ISQLUnion>.Create;
end;

procedure TSQLGroupBy.AppendStatementToString(const pFuncToString: TFunc<string>);
begin
  FStatementToString := pFuncToString;
end;

procedure TSQLGroupBy.AppendStatementType(const pStatementType: TSQLStatementType);
begin
  FStatementType := pStatementType;
end;

procedure TSQLGroupBy.BeforeDestruction;
begin
  FreeAndNil(FCriterias);
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

procedure TSQLGroupBy.CopyOf(const pSource: ISQLGroupBy);
var
  I: Integer;
begin
  FCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    FCriterias.Add(pSource.Criterias[I]);
end;

function TSQLGroupBy.GetCriterias: TList<ISQLCriteria>;
begin
  Result := FCriterias;
end;

function TSQLGroupBy.Having(const pHavingCriterias: array of string): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  FHaving.Aggregate(pHavingCriterias);
  Result := FHaving;
end;

function TSQLGroupBy.Having: ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  Result := FHaving;
end;

function TSQLGroupBy.Having(const pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

procedure TSQLGroupBy.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (FStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLGroupBy.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
  Result := FOrderBy;
end;

function TSQLGroupBy.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
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

    for I := 0 to Pred(FCriterias.Count) do
    begin
      if I = 0 then
        vStrBuilder.Append(' Group By')
      else
        vStrBuilder.Append(FCriterias[I].GetConnectorDescription);

      vStrBuilder.Append(' ' + FCriterias[I].Criteria);
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
  FOrderBy.AppendStatementType(Self.FStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

{ TSQLSelect }

function TSQLSelect.Column(const pColumnName: string): ISQLSelect;
begin
  FColumns.Add(pColumnName);
  Result := Self;
end;

procedure TSQLSelect.AfterConstruction;
begin
  inherited AfterConstruction;
  FStatementType := stSelect;
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

function TSQLSelect.From(const pTableName: string): ISQLSelect;
begin
  FFromTable.TableName := pTableName;
  Result := Self;
end;

function TSQLSelect.GetStatementType: TSQLStatementType;
begin
  Result := FStatementType;
end;

function TSQLSelect.GroupBy(const pGroupBy: ISQLGroupBy): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.FStatementType);
  FGroupBy.CopyOf(pGroupBy);
  Result := FGroupBy;
end;

function TSQLSelect.GroupBy: ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.FStatementType);
  Result := FGroupBy;
end;

function TSQLSelect.GroupBy(const pColumnNames: array of string): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.FStatementType);
  FGroupBy.Columns(pColumnNames);
  Result := FGroupBy;
end;

function TSQLSelect.Having: ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  Result := FHaving;
end;

function TSQLSelect.Having(const pHavingCriterias: array of string): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  FHaving.Aggregate(pHavingCriterias);
  Result := FHaving;
end;

function TSQLSelect.Having(const pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
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
  FOrderBy.AppendStatementType(Self.FStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

function TSQLSelect.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLSelect.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
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
  FWhere.AppendStatementType(Self.FStatementType);
  Result := FWhere;
end;

function TSQLSelect.Where(const pColumnName: string): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.AppendStatementType(Self.FStatementType);
  FWhere.Column(pColumnName);
  Result := FWhere;
end;

function TSQLSelect.Where(const pWhere: ISQLWhere): ISQLWhere;
begin
  FWhere.AppendStatementToString(Self.ToString);
  FWhere.AppendStatementType(Self.FStatementType);
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
  FCriterias := TList<ISQLCriteria>.Create;
  FStatementToString := nil;
  FColumnName := EmptyStr;
  FConnectorType := ctAnd;
  FStatementType := stNone;
  FGroupBy := TSQLGroupBy.Create;
  FHaving := TSQLHaving.Create;
  FOrderBy := TSQLOrderBy.Create;
  FUnions := TList<ISQLUnion>.Create;
end;

procedure TSQLWhere.AppendStatementToString(const pFuncToString: TFunc<string>);
begin
  FStatementToString := pFuncToString;
end;

procedure TSQLWhere.AppendStatementType(const pStatementType: TSQLStatementType);
begin
  FStatementType := pStatementType;
end;

procedure TSQLWhere.BeforeDestruction;
begin
  FreeAndNil(FCriterias);
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

function TSQLWhere.Between(const pInitial, pFinal: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' Between ' + ConvertSQLValue(pInitial) + ' And ' + ConvertSQLValue(pFinal) + ')',
    FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

procedure TSQLWhere.CopyOf(const pSource: ISQLWhere);
var
  I: Integer;
begin
  FCriterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    FCriterias.Add(pSource.Criterias[I]);
end;

function TSQLWhere.Criterion(const pOperator: TSQLOperatorType; const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[pOperator] + ' ' + ConvertSQLValue(pValue) + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.ColumnCriterion(const pOperator: TSQLOperatorType; const pColumnNameValue: string): ISQLWhere;
begin
  ColumnIsValid(FColumnName);
  ColumnIsValid(pColumnNameValue);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[pOperator] + ' ' + pColumnNameValue + ')', FConnectorType));

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

function TSQLWhere.Different(const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opDifferent] + ' ' + ConvertSQLValue(pValue) + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Equal(const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opEqual] + ' ' + ConvertSQLValue(pValue) + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.GetCriterias: TList<ISQLCriteria>;
begin
  Result := FCriterias;
end;

function TSQLWhere.Greater(const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opGreater] + ' ' + ConvertSQLValue(pValue) + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.GreaterOrEqual(const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opGreaterOrEqual] + ' ' + ConvertSQLValue(pValue) + ')',
    FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.GroupBy(const pColumnNames: array of string): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.FStatementType);
  FGroupBy.Columns(pColumnNames);
  Result := FGroupBy;
end;

function TSQLWhere.GroupBy(const pGroupBy: ISQLGroupBy): ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.FStatementType);
  FGroupBy.CopyOf(pGroupBy);
  Result := FGroupBy;
end;

function TSQLWhere.GroupBy: ISQLGroupBy;
begin
  FGroupBy.AppendStatementToString(Self.ToString);
  FGroupBy.AppendStatementType(Self.FStatementType);
  Result := FGroupBy;
end;

function TSQLWhere.Having(const pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

function TSQLWhere.Having(const pHavingCriterias: array of string): ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  FHaving.Aggregate(pHavingCriterias);
  Result := FHaving;
end;

function TSQLWhere.Having: ISQLHaving;
begin
  FHaving.AppendStatementToString(Self.ToString);
  FHaving.AppendStatementType(Self.FStatementType);
  Result := FHaving;
end;

function TSQLWhere.InList(const pValues: array of TValue): ISQLWhere;
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

    FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' In ' + vStrBuilder.ToString + ')', FConnectorType));
  finally
    FreeAndNil(vStrBuilder);
  end;

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

procedure TSQLWhere.InternalAddUnion(const pUnionSQL: string; const pUnionType: TSQLUnionType);
begin
  if (FStatementType = stSelect) then
    FUnions.Add(TSQLUnion.Create(pUnionType, pUnionSQL));
end;

function TSQLWhere.IsNotNull: ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' Is Not Null)', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.IsNull: ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' Is Null)', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Less(const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opLess] + ' ' + ConvertSQLValue(pValue) + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.LessOrEqual(const pValue: TValue): ISQLWhere;
begin
  ColumnIsValid(FColumnName);

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opLessOrEqual] + ' ' + ConvertSQLValue(pValue) + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Like(const pValue: string; const pOperator: TSQLLikeType): ISQLWhere;
var
  vValue: string;
begin
  ColumnIsValid(FColumnName);

  ValidateSQLReservedWord(pValue);

  case pOperator of
    loEqual:
      vValue := QuotedStr(pValue);
    loStarting:
      vValue := QuotedStr(pValue + '%');
    loEnding:
      vValue := QuotedStr('%' + pValue);
    loContaining:
      vValue := QuotedStr('%' + pValue + '%');
  end;

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opLike] + ' ' + vValue + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.NotLike(const pValue: string; const pOperator: TSQLLikeType): ISQLWhere;
var
  vValue: string;
begin
  ColumnIsValid(FColumnName);

  ValidateSQLReservedWord(pValue);

  case pOperator of
    loEqual:
      vValue := QuotedStr(pValue);
    loStarting:
      vValue := QuotedStr(pValue + '%');
    loEnding:
      vValue := QuotedStr('%' + pValue);
    loContaining:
      vValue := QuotedStr('%' + pValue + '%');
  end;

  FCriterias.Add(TSQLCriteria.Create('(' + FColumnName + ' ' + _cSQLOperator[opNotLike] + ' ' + vValue + ')', FConnectorType));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere.OrderBy: ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
  Result := FOrderBy;
end;

function TSQLWhere.OrderBy(const pColumnNames: array of string): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
  FOrderBy.Columns(pColumnNames);
  Result := FOrderBy;
end;

function TSQLWhere.OrderBy(const pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.AppendStatementToString(Self.ToString);
  FOrderBy.AppendStatementType(Self.FStatementType);
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

    for I := 0 to Pred(FCriterias.Count) do
    begin
      if (I = 0) then
        vStrBuilder.Append(' Where ')
      else
        vStrBuilder.Append(' ' + FCriterias[I].GetConnectorDescription + ' ');

      vStrBuilder.Append(FCriterias[I].Criteria);
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

  FCriterias.Add(TSQLCriteria.Create('(' + AnsiReplaceText(pWhere.ToString, ' Where ', '') + ')', ctAnd));

  FConnectorType := ctAnd;
  FColumnName := EmptyStr;
  Result := Self;
end;

function TSQLWhere._Or(const pWhere: ISQLWhere): ISQLWhere;
begin
  pWhere.AppendStatementToString(nil);

  FCriterias.Add(TSQLCriteria.Create('(' + AnsiReplaceText(pWhere.ToString, ' Where ', '') + ')', ctOr));

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
  FStatementType := stDelete;
  FTable := TSQLTable.Create;
  FWhere := TSQLWhere.Create;
end;

procedure TSQLDelete.BeforeDestruction;
begin

  inherited BeforeDestruction;
end;

function TSQLDelete.GetStatementType: TSQLStatementType;
begin
  Result := FStatementType;
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
  FStatementType := stUpdate;
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

function TSQLUpdate.GetStatementType: TSQLStatementType;
begin
  Result := FStatementType;
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
  FStatementType := stInsert;
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

function TSQLInsert.GetStatementType: TSQLStatementType;
begin
  Result := FStatementType;
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

end.
