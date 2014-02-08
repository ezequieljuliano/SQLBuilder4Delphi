(*
  Copyright 2013 Ezequiel Juliano Müller - ezequieljuliano@gmail.com

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

unit SQLBuilder4D;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections;

type

  TSQLStatementType = (stNone, stSelect, stInsert, stUpdate, stDelete);
  TSQLJoinType = (jtNone, jtInner, jtLeftOuter, jtRightOuter);
  TSQLSortType = (srNone, srAsc, srDesc);
  TSQLLikeType = (loEqual, loStarting, loEnding, loContaining);
  TSQLConnectorType = (ctAnd, ctOr, ctComma);
  TSQLUnionType = (utUnion, utUnionAll);
  TSQLOperatorType = (opEqual, opDifferent, opGreater, opLess, opGreaterOrEqual, opLessOrEqual, opLike, opNotLike);

const

  _cSQLOperator: array [TSQLOperatorType] of string = ('=', '<>', '>', '<', '>=', '<=', 'Like', 'Not Like');

type

  ESQLBuilderException = class(Exception);

  ISQL = interface
    ['{0094632E-6419-462A-A4CE-46759542E65D}']
  end;

  ISQLStatement = interface(ISQL)
    ['{8056A6BA-E648-4EF5-B17A-F42CC8F343E3}']
    function GetStatementType(): TSQLStatementType;

    function ToString(): string;

    property StatementType: TSQLStatementType read GetStatementType;
  end;

  ISQLCriteria = interface(ISQL)
    ['{C735CA85-286E-4DC3-8067-DAE41C2E13C5}']
    function GetCriteria(): string;
    procedure SetCriteria(const pCriteria: string);

    function GetConnector(): TSQLConnectorType;
    procedure SetConnector(const pConnector: TSQLConnectorType);

    function GetConnectorDescription(): string;

    property Criteria: string read GetCriteria write SetCriteria;
    property Connector: TSQLConnectorType read GetConnector write SetConnector;
  end;

  ISQLClause = interface(ISQL)
    ['{4C2E15B7-7752-4648-88A2-477AFCFDC336}']
    function GetCriterias(): TList<ISQLCriteria>;

    procedure AppendStatementToString(const pFuncToString: TFunc<string>);
    procedure AppendStatementType(const pStatementType: TSQLStatementType);

    function ToString(): string;

    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  ISQLTable = interface(ISQL)
    ['{16D8E207-E05D-406C-8083-068CBAF9F78B}']
    function GetTableName(): string;
    procedure SetTableName(const pName: string);

    property TableName: string read GetTableName write SetTableName;
  end;

  ISQLValue = interface(ISQL)
    ['{F72BC95B-EDCF-47A0-8246-C83ED721813F}']
    function GetValue(): string;
    procedure SetValue(const pValue: string);

    property Value: string read GetValue write SetValue;
  end;

  ISQLJoin = interface(ISQL)
    ['{67F8E366-5509-4765-93D8-3621683936A3}']
    function GetTable(): ISQLTable;
    procedure SetTable(const pSQLTable: ISQLTable);

    function GetJoinType(): TSQLJoinType;
    procedure SetJoinType(const pType: TSQLJoinType);

    function GetCriteria(): string;
    procedure SetCriteria(const pCriteria: string);

    function ToString(): string;

    property Table: ISQLTable read GetTable write SetTable;
    property JoinType: TSQLJoinType read GetJoinType write SetJoinType;
    property Criteria: string read GetCriteria write SetCriteria;
  end;

  ISQLUnion = interface(ISQL)
    ['{47C6E5F5-B105-4CA3-BAA9-0146DDA50CAE}']
    function GetUnionType(): TSQLUnionType;
    procedure SetUnionType(const pUnionType: TSQLUnionType);

    function GetUnionSQL(): string;
    procedure SetUnionSQL(const pUnionSQL: string);

    function ToString(): string;

    property UnionType: TSQLUnionType read GetUnionType write SetUnionType;
    property UnionSQL: string read GetUnionSQL write SetUnionSQL;
  end;

  ISQLSelect = interface;
  ISQLGroupBy = interface;
  ISQLWhere = interface;
  ISQLHaving = interface;

  ISQLOrderBy = interface(ISQLClause)
    ['{9B16882D-08F9-4CA9-8E9A-9E4A0BF19C59}']
    procedure CopyOf(const pSource: ISQLOrderBy);

    function Column(const pColumnName: string): ISQLOrderBy;
    function Columns(const pColumnNames: array of string): ISQLOrderBy;
    function Sort(const pSortType: TSQLSortType): ISQLOrderBy;

    function Union(const pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(const pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
  end;

  ISQLHaving = interface(ISQLClause)
    ['{DB27217D-6AE6-4356-9435-203D514D1503}']
    procedure CopyOf(const pSource: ISQLHaving);

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

  ISQLGroupBy = interface(ISQLClause)
    ['{C3368CA9-DCC6-43D9-A2D2-E503965F6326}']
    procedure CopyOf(const pSource: ISQLGroupBy);

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

  ISQLWhere = interface(ISQLClause)
    ['{916ACD04-0DC2-4887-8A3B-E3F4F61EB4B3}']
    procedure CopyOf(const pSource: ISQLWhere);

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
    function Between(const pStart, pEnd: TValue): ISQLWhere;

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

  ISQLSelect = interface(ISQLStatement)
    ['{80AB8C0C-A2AD-4EDC-8E05-F2F6D4D80A7A}']
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
  end;

  ISQLDelete = interface(ISQLStatement)
    ['{B8799C06-80FA-4790-9E42-AE1F28043723}']
    function From(const pTableName: string): ISQLDelete;

    function Where(): ISQLWhere; overload;
    function Where(const pColumnName: string): ISQLWhere; overload;
    function Where(const pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  ISQLUpdate = interface(ISQLStatement)
    ['{0AA172FD-0307-4FC1-B727-4668202D5B44}']
    function Table(const pTableName: string): ISQLUpdate;
    function ColumnSetValue(const pColumnName: string; const pValue: TValue): ISQLUpdate;
    function Columns(const pColumnNames: array of string): ISQLUpdate;
    function SetValues(const pValues: array of TValue): ISQLUpdate;

    function Where(): ISQLWhere; overload;
    function Where(const pColumnName: string): ISQLWhere; overload;
    function Where(const pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  ISQLInsert = interface(ISQLStatement)
    ['{F2E132B1-28AB-48EC-B826-C59BE328DF2C}']
    function Into(const pTableName: string): ISQLInsert;
    function ColumnValue(const pColumnName: string; const pValue: TValue): ISQLInsert;
    function Columns(const pColumnNames: array of string): ISQLInsert;
    function Values(const pValues: array of TValue): ISQLInsert;
  end;

  TSQLBuilder = class
  public
    class function Select(): ISQLSelect; static;
    class function Delete(): ISQLDelete; static;
    class function Update(): ISQLUpdate; static;
    class function Insert(): ISQLInsert; static;

    class function Where(): ISQLWhere; overload; static;
    class function Where(const pColumnName: string): ISQLWhere; overload; static;

    class function GroupBy(): ISQLGroupBy; overload; static;
    class function GroupBy(const pColumnNames: array of string): ISQLGroupBy; overload; static;

    class function Having(): ISQLHaving; overload; static;
    class function Having(const pHavingCriterias: array of string): ISQLHaving; overload; static;

    class function OrderBy(): ISQLOrderBy; overload; static;
    class function OrderBy(const pColumnNames: array of string): ISQLOrderBy; overload; static;
  end;

implementation

uses
  Spring,
  Spring.Services;

{ TSQLBuilder }

class function TSQLBuilder.Delete: ISQLDelete;
begin
  Result := ServiceLocator.GetService<ISQLDelete>;
end;

class function TSQLBuilder.GroupBy: ISQLGroupBy;
begin
  Result := ServiceLocator.GetService<ISQLGroupBy>;
end;

class function TSQLBuilder.Having: ISQLHaving;
begin
  Result := ServiceLocator.GetService<ISQLHaving>;
end;

class function TSQLBuilder.Insert: ISQLInsert;
begin
  Result := ServiceLocator.GetService<ISQLInsert>;
end;

class function TSQLBuilder.OrderBy(const pColumnNames: array of string): ISQLOrderBy;
begin
  Result := TSQLBuilder.OrderBy();
  Result.Columns(pColumnNames);
end;

class function TSQLBuilder.OrderBy: ISQLOrderBy;
begin
  Result := ServiceLocator.GetService<ISQLOrderBy>;
end;

class function TSQLBuilder.Select: ISQLSelect;
begin
  Result := ServiceLocator.GetService<ISQLSelect>;
end;

class function TSQLBuilder.Update: ISQLUpdate;
begin
  Result := ServiceLocator.GetService<ISQLUpdate>;
end;

class function TSQLBuilder.Where(const pColumnName: string): ISQLWhere;
begin
  Result := TSQLBuilder.Where();
  Result.Column(pColumnName);
end;

class function TSQLBuilder.Where: ISQLWhere;
begin
  Result := ServiceLocator.GetService<ISQLWhere>;
end;

class function TSQLBuilder.GroupBy(const pColumnNames: array of string): ISQLGroupBy;
begin
  Result := TSQLBuilder.GroupBy();
  Result.Columns(pColumnNames);
end;

class function TSQLBuilder.Having(const pHavingCriterias: array of string): ISQLHaving;
begin
  Result := TSQLBuilder.Having();
  Result.Aggregate(pHavingCriterias);
end;

end.
