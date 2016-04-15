unit SQLBuilder4D;

interface

uses
  Classes,
  SysUtils,
  Generics.Collections,
  StrUtils,
  Rtti,
  TypInfo;

type

  TSQLStatementType = (stNone, stSelect, stInsert, stUpdate, stDelete);
  TSQLConnector = (ctAnd, ctOr, ctComma);
  TSQLJoinType = (jtNone, jtInner, jtLeft, jtRight, jtFull);
  TSQLUnionType = (utUnion, utUnionAll);
  TSQLSort = (srNone, srAsc, srDesc);
  TSQLLikeOperator = (loEqual, loStarting, loEnding, loContaining);
  TSQLOperator = (opEqual, opDifferent, opGreater, opLess, opGreaterOrEqual, opLessOrEqual, opLike, opNotLike, opIsNull, opNotNull);

  ESQLBuilderException = class(Exception);

  ISQL = interface
    ['{2919F28B-1B98-4D9F-9403-8EA14A81B6EC}']
    function ToString(): string;
    function ToFile(const pFileName: string): ISQL;
  end;

  ISQLStatement = interface(ISQL)
    ['{8056A6BA-E648-4EF5-B17A-F42CC8F343E3}']
    function GetStatementType(): TSQLStatementType;
    property StatementType: TSQLStatementType read GetStatementType;
  end;

  ISQLCriteria = interface(ISQL)
    ['{C735CA85-286E-4DC3-8067-DAE41C2E13C5}']
    function GetCriteria(): string;
    function GetConnector(): TSQLConnector;

    function ConnectorDescription(): string;

    property Criteria: string read GetCriteria;
    property Connector: TSQLConnector read GetConnector;
  end;

  ISQLClause = interface(ISQL)
    ['{4C2E15B7-7752-4648-88A2-477AFCFDC336}']
    function GetCriterias(): TList<ISQLCriteria>;
    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  ISQLTable = interface(ISQL)
    ['{DDA7511E-4B4D-4CB9-8428-75A4AD52B232}']
    function GetName(): string;
    property Name: string read GetName;
  end;

  ISQLFrom = interface(ISQL)
    ['{16D8E207-E05D-406C-8083-068CBAF9F78B}']
    function GetTable(): ISQLTable;
    property Table: ISQLTable read GetTable;
  end;

  TSQLValueCase = (vcNone, vcUpper, vcLower);

  ISQLValue = interface(ISQL)
    ['{F72BC95B-EDCF-47A0-8246-C83ED721813F}']
    function Insensetive(): ISQLValue;
    function IsInsensetive(): Boolean;

    function Column(): ISQLValue;
    function IsColumn(): Boolean;

    function Expression(): ISQLValue;
    function IsExpression(): Boolean;

    function Upper(): ISQLValue;
    function IsUpper(): Boolean;

    function Lower(): ISQLValue;
    function IsLower(): Boolean;

    function Like(const pOp: TSQLLikeOperator): ISQLValue;
    function IsLike(): Boolean;

    function Date(): ISQLValue;
    function IsDate(): Boolean;

    function DateTime(): ISQLValue;
    function IsDateTime(): Boolean;

    function Time(): ISQLValue;
    function IsTime(): Boolean;

    function GetValue(): TValue;

    property Value: TValue read GetValue;
  end;

  ISQLJoinTerm = interface(ISQL)
    ['{0AA745F4-7FC6-4C81-8603-D012ADB9A09B}']
    function Left(const pTerm: TValue): ISQLJoinTerm; overload;
    function Left(pTerm: ISQLValue): ISQLJoinTerm; overload;

    function Op(const pOp: TSQLOperator): ISQLJoinTerm;

    function Right(const pTerm: TValue): ISQLJoinTerm; overload;
    function Right(pTerm: ISQLValue): ISQLJoinTerm; overload;
  end;

  ISQLJoin = interface(ISQL)
    ['{67F8E366-5509-4765-93D8-3621683936A3}']
    function Table(pTable: ISQLTable): ISQLJoin;
    function Condition(pTerm: ISQLJoinTerm): ISQLJoin;
    function &And(pTerm: ISQLJoinTerm): ISQLJoin;
    function &Or(pTerm: ISQLJoinTerm): ISQLJoin;
  end;

  ISQLUnion = interface(ISQL)
    ['{47C6E5F5-B105-4CA3-BAA9-0146DDA50CAE}']
    function GetUnionType(): TSQLUnionType;
    function GetUnionSQL(): string;

    property UnionType: TSQLUnionType read GetUnionType;
    property UnionSQL: string read GetUnionSQL;
  end;

  ISQLSelect = interface;
  ISQLWhere = interface;
  ISQLGroupBy = interface;
  ISQLHaving = interface;
  ISQLCoalesce = interface;
  ISQLAggregate = interface;

  ISQLCase = interface(ISQL)
    ['{49A86CB5-CCDF-4CA6-8FF4-DEF93232F6EB}']
    function Expression(const pTerm: string): ISQLCase; overload;
    function Expression(pTerm: ISQLValue): ISQLCase; overload;

    function When(const pCondition: TValue): ISQLCase; overload;
    function When(pCondition: ISQLValue): ISQLCase; overload;

    function &Then(const pValue: TValue): ISQLCase; overload;
    function &Then(pValue: ISQLValue): ISQLCase; overload;
    function &Then(pValue: ISQLAggregate): ISQLCase; overload;
    function &Then(pValue: ISQLCoalesce): ISQLCase; overload;

    function &Else(const pDefValue: TValue): ISQLCase; overload;
    function &Else(pDefValue: ISQLValue): ISQLCase; overload;
    function &Else(pDefValue: ISQLAggregate): ISQLCase; overload;
    function &Else(pDefValue: ISQLCoalesce): ISQLCase; overload;

    function &End(): ISQLCase;

    function &As(const pAlias: string): ISQLCase;
    function Alias(const pAlias: string): ISQLCase;
  end;

  ISQLOrderBy = interface(ISQLClause)
    ['{9B16882D-08F9-4CA9-8E9A-9E4A0BF19C59}']
    procedure CopyOf(pSource: ISQLOrderBy);

    function Column(const pColumn: string; const pSortType: TSQLSort = srNone): ISQLOrderBy;
    function Columns(const pColumns: array of string; const pSortType: TSQLSort = srNone): ISQLOrderBy;
    function Sort(const pSortType: TSQLSort): ISQLOrderBy;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
  end;

  ISQLHaving = interface(ISQLClause)
    ['{DB27217D-6AE6-4356-9435-203D514D1503}']
    procedure CopyOf(pSource: ISQLHaving);

    function Expression(pAggregateTerm: ISQLAggregate): ISQLHaving; overload;
    function Expression(const pTerm: string): ISQLHaving; overload;

    function Expressions(pAggregateTerms: array of ISQLAggregate): ISQLHaving; overload;
    function Expressions(const pTerms: array of string): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
  end;

  ISQLGroupBy = interface(ISQLClause)
    ['{C3368CA9-DCC6-43D9-A2D2-E503965F6326}']
    procedure CopyOf(pSource: ISQLGroupBy);

    function Column(const pColumn: string): ISQLGroupBy;
    function Columns(const pColumns: array of string): ISQLGroupBy;

    function Having(): ISQLHaving; overload;
    function Having(pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
  end;

  ISQLWhere = interface(ISQLClause)
    ['{916ACD04-0DC2-4887-8A3B-E3F4F61EB4B3}']
    procedure CopyOf(pSource: ISQLWhere);

    function Column(const pColumn: string): ISQLWhere;

    function &And(const pColumn: string): ISQLWhere; overload;
    function &And(pWhere: ISQLWhere): ISQLWhere; overload;

    function &Or(const pColumn: string): ISQLWhere; overload;
    function &Or(pWhere: ISQLWhere): ISQLWhere; overload;

    function Equal(const pValue: TValue): ISQLWhere; overload;
    function Equal(pValue: ISQLValue): ISQLWhere; overload;

    function Different(const pValue: TValue): ISQLWhere; overload;
    function Different(pValue: ISQLValue): ISQLWhere; overload;

    function Greater(const pValue: TValue): ISQLWhere; overload;
    function Greater(pValue: ISQLValue): ISQLWhere; overload;

    function GreaterOrEqual(const pValue: TValue): ISQLWhere; overload;
    function GreaterOrEqual(pValue: ISQLValue): ISQLWhere; overload;

    function Less(const pValue: TValue): ISQLWhere; overload;
    function Less(pValue: ISQLValue): ISQLWhere; overload;

    function LessOrEqual(const pValue: TValue): ISQLWhere; overload;
    function LessOrEqual(pValue: ISQLValue): ISQLWhere; overload;

    function Like(const pValue: string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function Like(pValue: ISQLValue): ISQLWhere; overload;
    function Like(const pValues: array of string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function Like(pValues: array of ISQLValue): ISQLWhere; overload;

    function NotLike(const pValue: string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function NotLike(pValue: ISQLValue): ISQLWhere; overload;
    function NotLike(const pValues: array of string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function NotLike(pValues: array of ISQLValue): ISQLWhere; overload;

    function IsNull(): ISQLWhere;
    function IsNotNull(): ISQLWhere;

    function InList(const pValues: array of TValue): ISQLWhere; overload;
    function InList(pValues: array of ISQLValue): ISQLWhere; overload;

    function NotInList(const pValues: array of TValue): ISQLWhere; overload;
    function NotInList(pValues: array of ISQLValue): ISQLWhere; overload;

    function Between(const pStart, pEnd: TValue): ISQLWhere; overload;
    function Between(pStart, pEnd: ISQLValue): ISQLWhere; overload;

    function Expression(const pOp: TSQLOperator; const pValue: TValue): ISQLWhere; overload;
    function Expression(const pOp: TSQLOperator; pValue: ISQLValue): ISQLWhere; overload;
    function Expression(const pOp: TSQLOperator): ISQLWhere; overload;

    function GroupBy(): ISQLGroupBy; overload;
    function GroupBy(pGroupBy: ISQLGroupBy): ISQLGroupBy; overload;

    function Having(): ISQLHaving; overload;
    function Having(pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
  end;

  TSQLAggFunction = (aggAvg, aggCount, aggMax, aggMin, aggSum);

  ISQLAggregate = interface(ISQL)
    ['{3B040F41-A4EA-4034-A7D9-15F5B594CD46}']
    function Avg(): ISQLAggregate; overload;
    function Avg(const pExpression: string): ISQLAggregate; overload;
    function Avg(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Avg(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Count(): ISQLAggregate; overload;
    function Count(const pExpression: string): ISQLAggregate; overload;
    function Count(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Count(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Max(): ISQLAggregate; overload;
    function Max(const pExpression: string): ISQLAggregate; overload;
    function Max(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Max(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Min(): ISQLAggregate; overload;
    function Min(const pExpression: string): ISQLAggregate; overload;
    function Min(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Min(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Sum(): ISQLAggregate; overload;
    function Sum(const pExpression: string): ISQLAggregate; overload;
    function Sum(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Sum(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Expression(const pTerm: string): ISQLAggregate; overload;
    function Expression(pCoalesceTerm: ISQLCoalesce): ISQLAggregate; overload;
    function Expression(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Condition(const pOp: TSQLOperator; const pValue: TValue): ISQLAggregate; overload;
    function Condition(const pOp: TSQLOperator; pValue: ISQLValue): ISQLAggregate; overload;
    function Condition(const pOp: TSQLOperator): ISQLAggregate; overload;

    function &As(const pAlias: string): ISQLAggregate;
    function Alias(const pAlias: string): ISQLAggregate;
  end;

  ISQLCoalesce = interface(ISQL)
    ['{48252AD8-E021-44D1-8C9F-DEBC18492735}']
    function Expression(const pTerm: string): ISQLCoalesce; overload;
    function Expression(const pAggregateTerm: ISQLAggregate): ISQLCoalesce; overload;
    function Expression(const pCaseTerm: ISQLCase): ISQLCoalesce; overload;

    function Value(const pValue: TValue): ISQLCoalesce; overload;
    function Value(pValue: ISQLValue): ISQLCoalesce; overload;

    function &As(const pAlias: string): ISQLCoalesce;
    function Alias(const pAlias: string): ISQLCoalesce;
  end;

  ISQLSelect = interface(ISQLStatement)
    ['{80AB8C0C-A2AD-4EDC-8E05-F2F6D4D80A7A}']
    function Distinct(): ISQLSelect;

    function AllColumns(): ISQLSelect;
    function Column(const pColumn: string): ISQLSelect; overload;
    function Column(const pColumn: ISQLCoalesce): ISQLSelect; overload;
    function Column(const pColumn: ISQLAggregate): ISQLSelect; overload;
    function Column(const pColumn: ISQLCase): ISQLSelect; overload;
    function &As(const pAlias: string): ISQLSelect;
    function Alias(const pAlias: string): ISQLSelect;

    function SubSelect(pSelect: ISQLSelect; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pWhere: ISQLWhere; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pGroupBy: ISQLGroupBy; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pHaving: ISQLHaving; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pOrderBy: ISQLOrderBy; const pAlias: string): ISQLSelect; overload;

    function From(const pTable: string): ISQLSelect; overload;
    function From(const pTables: array of string): ISQLSelect; overload;
    function From(pTerm: ISQLFrom): ISQLSelect; overload;
    function From(pTerms: array of ISQLFrom): ISQLSelect; overload;

    function Join(pJoin: ISQLJoin): ISQLSelect; overload;
    function Join(const pTable, pCondition: string): ISQLSelect; overload;

    function LeftJoin(pLeftJoin: ISQLJoin): ISQLSelect; overload;
    function LeftJoin(const pTable, pCondition: string): ISQLSelect; overload;

    function RightJoin(pRightJoin: ISQLJoin): ISQLSelect; overload;
    function RightJoin(const pTable, pCondition: string): ISQLSelect; overload;

    function FullJoin(pFullJoin: ISQLJoin): ISQLSelect; overload;
    function FullJoin(const pTable, pCondition: string): ISQLSelect; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;

    function Where(): ISQLWhere; overload;
    function Where(const pColumn: string): ISQLWhere; overload;
    function Where(pWhere: ISQLWhere): ISQLWhere; overload;

    function GroupBy(): ISQLGroupBy; overload;
    function GroupBy(pGroupBy: ISQLGroupBy): ISQLGroupBy; overload;

    function Having(): ISQLHaving; overload;
    function Having(pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;
  end;

  ISQLDelete = interface(ISQLStatement)
    ['{B8799C06-80FA-4790-9E42-AE1F28043723}']
    function From(const pTable: string): ISQLDelete; overload;
    function From(pTable: ISQLTable): ISQLDelete; overload;

    function Where(): ISQLWhere; overload;
    function Where(const pColumn: string): ISQLWhere; overload;
    function Where(pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  ISQLUpdate = interface(ISQLStatement)
    ['{0AA172FD-0307-4FC1-B727-4668202D5B44}']
    function Table(const pName: string): ISQLUpdate; overload;
    function Table(pTable: ISQLTable): ISQLUpdate; overload;

    function ColumnSetValue(const pColumn: string; const pValue: TValue): ISQLUpdate; overload;
    function ColumnSetValue(const pColumn: string; pValue: ISQLValue): ISQLUpdate; overload;

    function Columns(const pColumns: array of string): ISQLUpdate;
    function SetValues(const pValues: array of TValue): ISQLUpdate; overload;
    function SetValues(pValues: array of ISQLValue): ISQLUpdate; overload;

    function Where(): ISQLWhere; overload;
    function Where(const pColumn: string): ISQLWhere; overload;
    function Where(pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  ISQLInsert = interface(ISQLStatement)
    ['{44D021D5-7F84-471B-875D-F8F637A16607}']
    function Into(const pTable: string): ISQLInsert; overload;
    function Into(pTable: ISQLTable): ISQLInsert; overload;

    function ColumnValue(const pColumn: string; const pValue: TValue): ISQLInsert; overload;
    function ColumnValue(const pColumn: string; pValue: ISQLValue): ISQLInsert; overload;

    function Columns(const pColumns: array of string): ISQLInsert;
    function Values(const pValues: array of TValue): ISQLInsert; overload;
    function Values(pValues: array of ISQLValue): ISQLInsert; overload;
  end;

  SQL = class sealed
  strict private
  const
    CanNotBeInstantiatedException = 'This class can not be instantiated!';
  strict private

    {$HINTS OFF}

    constructor Create;

    {$HINTS ON}

  public
    class function Select(): ISQLSelect; static;
    class function Insert(): ISQLInsert; static;
    class function Update(): ISQLUpdate; static;
    class function Delete(): ISQLDelete; static;

    class function Where(): ISQLWhere; overload; static;
    class function Where(const pColumn: string): ISQLWhere; overload; static;

    class function GroupBy(): ISQLGroupBy; overload; static;
    class function GroupBy(const pColumn: string): ISQLGroupBy; overload; static;
    class function GroupBy(const pColumns: array of string): ISQLGroupBy; overload; static;

    class function Having(): ISQLHaving; overload; static;
    class function Having(const pExpression: string): ISQLHaving; overload; static;
    class function Having(const pExpressions: array of string): ISQLHaving; overload; static;
    class function Having(pExpression: ISQLAggregate): ISQLHaving; overload; static;
    class function Having(pExpressions: array of ISQLAggregate): ISQLHaving; overload; static;

    class function OrderBy(): ISQLOrderBy; overload; static;
    class function OrderBy(const pColumn: string; const pSortType: TSQLSort = srNone): ISQLOrderBy; overload; static;
    class function OrderBy(const pColumns: array of string; const pSortType: TSQLSort = srNone): ISQLOrderBy; overload; static;

    class function Coalesce(): ISQLCoalesce; overload;
    class function Coalesce(const pExpression: string; const pValue: TValue): ISQLCoalesce; overload; static;
    class function Coalesce(const pExpression: string; pValue: ISQLValue): ISQLCoalesce; overload; static;
    class function Coalesce(pExpression: ISQLAggregate; const pValue: TValue): ISQLCoalesce; overload; static;
    class function Coalesce(pExpression: ISQLAggregate; pValue: ISQLValue): ISQLCoalesce; overload; static;
    class function Coalesce(pExpression: ISQLCase; const pValue: TValue): ISQLCoalesce; overload; static;
    class function Coalesce(pExpression: ISQLCase; pValue: ISQLValue): ISQLCoalesce; overload; static;

    class function Aggregate(): ISQLAggregate; overload;
    class function Aggregate(const pFunction: TSQLAggFunction; const pExpression: string): ISQLAggregate; overload; static;
    class function Aggregate(const pFunction: TSQLAggFunction; pExpression: ISQLCoalesce): ISQLAggregate; overload; static;

    class function &Case(): ISQLCase; overload; static;
    class function &Case(const pExpression: string): ISQLCase; overload; static;
    class function &Case(pExpression: ISQLValue): ISQLCase; overload; static;

    class function Join(): ISQLJoin; overload; static;
    class function Join(const pTable: string): ISQLJoin; overload; static;
    class function Join(pTable: ISQLTable): ISQLJoin; overload; static;

    class function LeftJoin(): ISQLJoin; overload; static;
    class function LeftJoin(const pTable: string): ISQLJoin; overload; static;
    class function LeftJoin(pTable: ISQLTable): ISQLJoin; overload; static;

    class function RightJoin(): ISQLJoin; overload; static;
    class function RightJoin(const pTable: string): ISQLJoin; overload; static;
    class function RightJoin(pTable: ISQLTable): ISQLJoin; overload; static;

    class function FullJoin(): ISQLJoin; overload; static;
    class function FullJoin(const pTable: string): ISQLJoin; overload; static;
    class function FullJoin(pTable: ISQLTable): ISQLJoin; overload; static;

    class function JoinTerm(): ISQLJoinTerm; static;

    class function Value(const pValue: TValue): ISQLValue; static;
    class function Table(const pName: string): ISQLTable; static;
    class function From(pTable: ISQLTable): ISQLFrom; static;
  end;

implementation

const
  SQL_OPERATOR: array [TSQLOperator] of string = ('=', '<>', '>', '<', '>=', '<=', 'Like', 'Not Like', 'Is Null', 'Is Not Null');

type

  TSQL = class(TInterfacedObject, ISQL)
  strict protected
    function DoToString(): string; virtual; abstract;
  public
    function ToString(): string; override;
    function ToFile(const pFileName: string): ISQL;
  end;

  TSQLStatement = class(TSQL, ISQLStatement)
  strict private
    FStatementType: TSQLStatementType;
    function GetStatementType(): TSQLStatementType;
  strict protected
    procedure SetStatementType(const pValue: TSQLStatementType);
    function DoToString(): string; override;
  public
    constructor Create();

    property StatementType: TSQLStatementType read GetStatementType;
  end;

  TSQLCriteria = class(TSQL, ISQLCriteria)
  strict private
    FCriteria: string;
    FConnectorType: TSQLConnector;
    function GetCriteria(): string;
    function GetConnector(): TSQLConnector;
  strict protected
    function DoToString(): string; override;
    function ConnectorDescription(): string;
  public
    constructor Create(const pCriteria: string; const pConnector: TSQLConnector);

    property Criteria: string read GetCriteria;
    property Connector: TSQLConnector read GetConnector;
  end;

  TSQLClause = class(TSQL, ISQLClause)
  strict private
    FCriterias: TList<ISQLCriteria>;
    function GetCriterias(): TList<ISQLCriteria>;
  strict protected
    OwnerString: TFunc<string>;
    function DoToString(): string; override;
  public
    constructor Create(const pOwnerString: TFunc<string>);
    destructor Destroy; override;

    property Criterias: TList<ISQLCriteria> read GetCriterias;
  end;

  TSQLTable = class(TSQL, ISQLTable)
  strict private
    FName: string;
    function GetName(): string;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create(const pName: string);

    property Name: string read GetName;
  end;

  TSQLFrom = class(TSQL, ISQLFrom)
  strict private
    FTable: ISQLTable;
    function GetTable(): ISQLTable;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create(pTable: ISQLTable);

    property Table: ISQLTable read GetTable;
  end;

  TSQLValue = class(TSQL, ISQLValue)
  strict private
    FValue: TValue;
    FIsColumn: Boolean;
    FIsExpression: Boolean;
    FCase: TSQLValueCase;
    FIsInsensetive: Boolean;
    FIsLike: Boolean;
    FIsDate: Boolean;
    FIsDateTime: Boolean;
    FIsTime: Boolean;
    FLikeOp: TSQLLikeOperator;
    function GetValue(): TValue;
    function IsReserverdWord(const pValue: string): Boolean;
    function GetLikeOperator(): TSQLLikeOperator;
    function ConvertDate(const pDate: TDate): string;
    function ConvertDateTime(const pDateTime: TDateTime): string;
    function ConvertTime(const pTime: TTime): string;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create(const pValue: TValue);

    function Insensetive(): ISQLValue;
    function IsInsensetive(): Boolean;

    function Column(): ISQLValue;
    function IsColumn(): Boolean;

    function Expression(): ISQLValue;
    function IsExpression(): Boolean;

    function Upper(): ISQLValue;
    function IsUpper(): Boolean;

    function Lower(): ISQLValue;
    function IsLower(): Boolean;

    function Like(const pOp: TSQLLikeOperator): ISQLValue;
    function IsLike(): Boolean;

    function Date(): ISQLValue;
    function IsDate(): Boolean;

    function DateTime(): ISQLValue;
    function IsDateTime(): Boolean;

    function Time(): ISQLValue;
    function IsTime(): Boolean;

    property Value: TValue read GetValue;
  end;

  TSQLJoinTerm = class(TSQL, ISQLJoinTerm)
  strict private
    FLeft: ISQLValue;
    FOp: TSQLOperator;
    FRight: ISQLValue;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create();

    function Left(const pTerm: TValue): ISQLJoinTerm; overload;
    function Left(pTerm: ISQLValue): ISQLJoinTerm; overload;

    function Op(const pOp: TSQLOperator): ISQLJoinTerm;

    function Right(const pTerm: TValue): ISQLJoinTerm; overload;
    function Right(pTerm: ISQLValue): ISQLJoinTerm; overload;
  end;

  TSQLJoin = class(TSQL, ISQLJoin)
  strict private
    FTable: ISQLTable;
    FType: TSQLJoinType;
    FConditions: TStringList;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create(pTable: ISQLTable; const pType: TSQLJoinType; const pDefaultCondition: string);
    destructor Destroy; override;

    function Table(pTable: ISQLTable): ISQLJoin;
    function Condition(pTerm: ISQLJoinTerm): ISQLJoin;
    function &And(pTerm: ISQLJoinTerm): ISQLJoin;
    function &Or(pTerm: ISQLJoinTerm): ISQLJoin;
  end;

  TSQLUnion = class(TSQL, ISQLUnion)
  strict private
    FUnionType: TSQLUnionType;
    FUnionSQL: string;
    function GetUnionType(): TSQLUnionType;
    function GetUnionSQL(): string;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create(const pType: TSQLUnionType; const pSQL: string);

    property UnionType: TSQLUnionType read GetUnionType;
    property UnionSQL: string read GetUnionSQL;
  end;

  TSQLOrderBy = class(TSQLClause, ISQLOrderBy)
  strict private
    FSortType: TSQLSort;
    FUnions: TList<ISQLUnion>;
    procedure AddUnion(const pSQL: string; const pType: TSQLUnionType);
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(pSource: ISQLOrderBy);

    function Column(const pColumn: string; const pSortType: TSQLSort = srNone): ISQLOrderBy;
    function Columns(const pColumns: array of string; const pSortType: TSQLSort = srNone): ISQLOrderBy;
    function Sort(const pSortType: TSQLSort): ISQLOrderBy;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLOrderBy; overload;
  end;

  TSQLHaving = class(TSQLClause, ISQLHaving)
  strict private
    FOrderBy: ISQLOrderBy;
    FUnions: TList<ISQLUnion>;
    procedure AddUnion(const pSQL: string; const pType: TSQLUnionType);
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(pSource: ISQLHaving);

    function Expression(pAggregateTerm: ISQLAggregate): ISQLHaving; overload;
    function Expression(const pTerm: string): ISQLHaving; overload;

    function Expressions(pAggregateTerms: array of ISQLAggregate): ISQLHaving; overload;
    function Expressions(const pTerms: array of string): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLHaving; overload;
  end;

  TSQLGroupBy = class(TSQLClause, ISQLGroupBy)
  strict private
    FOrderBy: ISQLOrderBy;
    FHaving: ISQLHaving;
    FUnions: TList<ISQLUnion>;
    procedure AddUnion(const pSQL: string; const pType: TSQLUnionType);
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(pSource: ISQLGroupBy);

    function Column(const pColumn: string): ISQLGroupBy;
    function Columns(const pColumns: array of string): ISQLGroupBy;

    function Having(): ISQLHaving; overload;
    function Having(pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLGroupBy; overload;
  end;

  TSQLWhere = class(TSQLClause, ISQLWhere)
  strict private
    FColumn: string;
    FConnector: TSQLConnector;
    FGroupBy: ISQLGroupBy;
    FHaving: ISQLHaving;
    FOrderBy: ISQLOrderBy;
    FUnions: TList<ISQLUnion>;
    procedure AddUnion(const pSQL: string; const pType: TSQLUnionType);
    procedure AddExpression(const pSQLOp: TSQLOperator; pSQLValue: ISQLValue);
    procedure AddInList(pValues: array of ISQLValue; const pNotIn: Boolean);
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure CopyOf(pSource: ISQLWhere);

    function Column(const pColumn: string): ISQLWhere;

    function &And(const pColumn: string): ISQLWhere; overload;
    function &And(pWhere: ISQLWhere): ISQLWhere; overload;

    function &Or(const pColumn: string): ISQLWhere; overload;
    function &Or(pWhere: ISQLWhere): ISQLWhere; overload;

    function Equal(const pValue: TValue): ISQLWhere; overload;
    function Equal(pValue: ISQLValue): ISQLWhere; overload;

    function Different(const pValue: TValue): ISQLWhere; overload;
    function Different(pValue: ISQLValue): ISQLWhere; overload;

    function Greater(const pValue: TValue): ISQLWhere; overload;
    function Greater(pValue: ISQLValue): ISQLWhere; overload;

    function GreaterOrEqual(const pValue: TValue): ISQLWhere; overload;
    function GreaterOrEqual(pValue: ISQLValue): ISQLWhere; overload;

    function Less(const pValue: TValue): ISQLWhere; overload;
    function Less(pValue: ISQLValue): ISQLWhere; overload;

    function LessOrEqual(const pValue: TValue): ISQLWhere; overload;
    function LessOrEqual(pValue: ISQLValue): ISQLWhere; overload;

    function Like(const pValue: string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function Like(pValue: ISQLValue): ISQLWhere; overload;
    function Like(const pValues: array of string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function Like(pValues: array of ISQLValue): ISQLWhere; overload;

    function NotLike(const pValue: string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function NotLike(pValue: ISQLValue): ISQLWhere; overload;
    function NotLike(const pValues: array of string; const pOp: TSQLLikeOperator = loEqual): ISQLWhere; overload;
    function NotLike(pValues: array of ISQLValue): ISQLWhere; overload;

    function IsNull(): ISQLWhere;
    function IsNotNull(): ISQLWhere;

    function InList(const pValues: array of TValue): ISQLWhere; overload;
    function InList(pValues: array of ISQLValue): ISQLWhere; overload;

    function NotInList(const pValues: array of TValue): ISQLWhere; overload;
    function NotInList(pValues: array of ISQLValue): ISQLWhere; overload;

    function Between(const pStart, pEnd: TValue): ISQLWhere; overload;
    function Between(pStart, pEnd: ISQLValue): ISQLWhere; overload;

    function Expression(const pOp: TSQLOperator; const pValue: TValue): ISQLWhere; overload;
    function Expression(const pOp: TSQLOperator; pValue: ISQLValue): ISQLWhere; overload;
    function Expression(const pOp: TSQLOperator): ISQLWhere; overload;

    function GroupBy(): ISQLGroupBy; overload;
    function GroupBy(pGroupBy: ISQLGroupBy): ISQLGroupBy; overload;

    function Having(): ISQLHaving; overload;
    function Having(pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLWhere; overload;
  end;

  TSQLSelect = class(TSQLStatement, ISQLSelect)
  strict private
    FDistinct: Boolean;
    FColumns: TStringList;
    FJoinedTables: TList<ISQLJoin>;
    FFrom: ISQLFrom;
    FGroupBy: ISQLGroupBy;
    FHaving: ISQLHaving;
    FOrderBy: ISQLOrderBy;
    FWhere: ISQLWhere;
    FUnions: TList<ISQLUnion>;
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function Distinct(): ISQLSelect;

    function AllColumns(): ISQLSelect;
    function Column(const pColumn: string): ISQLSelect; overload;
    function Column(const pColumn: ISQLCoalesce): ISQLSelect; overload;
    function Column(const pColumn: ISQLAggregate): ISQLSelect; overload;
    function Column(const pColumn: ISQLCase): ISQLSelect; overload;
    function &As(const pAlias: string): ISQLSelect;
    function Alias(const pAlias: string): ISQLSelect;

    function SubSelect(pSelect: ISQLSelect; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pWhere: ISQLWhere; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pGroupBy: ISQLGroupBy; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pHaving: ISQLHaving; const pAlias: string): ISQLSelect; overload;
    function SubSelect(pOrderBy: ISQLOrderBy; const pAlias: string): ISQLSelect; overload;

    function From(const pTable: string): ISQLSelect; overload;
    function From(const pTables: array of string): ISQLSelect; overload;
    function From(pTerm: ISQLFrom): ISQLSelect; overload;
    function From(pTerms: array of ISQLFrom): ISQLSelect; overload;

    function Join(pJoin: ISQLJoin): ISQLSelect; overload;
    function Join(const pTable, pCondition: string): ISQLSelect; overload;

    function LeftJoin(pLeftJoin: ISQLJoin): ISQLSelect; overload;
    function LeftJoin(const pTable, pCondition: string): ISQLSelect; overload;

    function RightJoin(pRightJoin: ISQLJoin): ISQLSelect; overload;
    function RightJoin(const pTable, pCondition: string): ISQLSelect; overload;

    function FullJoin(pFullJoin: ISQLJoin): ISQLSelect; overload;
    function FullJoin(const pTable, pCondition: string): ISQLSelect; overload;

    function Union(pSelect: ISQLSelect; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pWhere: ISQLWhere; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pHaving: ISQLHaving; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;
    function Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType = utUnion): ISQLSelect; overload;

    function Where(): ISQLWhere; overload;
    function Where(const pColumn: string): ISQLWhere; overload;
    function Where(pWhere: ISQLWhere): ISQLWhere; overload;

    function GroupBy(): ISQLGroupBy; overload;
    function GroupBy(pGroupBy: ISQLGroupBy): ISQLGroupBy; overload;

    function Having(): ISQLHaving; overload;
    function Having(pHaving: ISQLHaving): ISQLHaving; overload;

    function OrderBy(): ISQLOrderBy; overload;
    function OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy; overload;
  end;

  TSQLDelete = class(TSQLStatement, ISQLDelete)
  strict private
    FTable: ISQLTable;
    FWhere: ISQLWhere;
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function From(const pTable: string): ISQLDelete; overload;
    function From(pTable: ISQLTable): ISQLDelete; overload;

    function Where(): ISQLWhere; overload;
    function Where(const pColumn: string): ISQLWhere; overload;
    function Where(pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  TSQLUpdate = class(TSQLStatement, ISQLUpdate)
  strict private
    FColumns: TStringList;
    FValues: TList<ISQLValue>;
    FTable: ISQLTable;
    FWhere: ISQLWhere;
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function Table(const pName: string): ISQLUpdate; overload;
    function Table(pTable: ISQLTable): ISQLUpdate; overload;

    function ColumnSetValue(const pColumn: string; const pValue: TValue): ISQLUpdate; overload;
    function ColumnSetValue(const pColumn: string; pValue: ISQLValue): ISQLUpdate; overload;

    function Columns(const pColumns: array of string): ISQLUpdate;
    function SetValues(const pValues: array of TValue): ISQLUpdate; overload;
    function SetValues(pValues: array of ISQLValue): ISQLUpdate; overload;

    function Where(): ISQLWhere; overload;
    function Where(const pColumn: string): ISQLWhere; overload;
    function Where(pWhere: ISQLWhere): ISQLWhere; overload;
  end;

  TSQLInsert = class(TSQLStatement, ISQLInsert)
  strict private
    FColumns: TStringList;
    FValues: TList<ISQLValue>;
    FTable: ISQLTable;
  strict protected
    function DoToString(): string; override;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    function Into(const pTable: string): ISQLInsert; overload;
    function Into(pTable: ISQLTable): ISQLInsert; overload;

    function ColumnValue(const pColumn: string; const pValue: TValue): ISQLInsert; overload;
    function ColumnValue(const pColumn: string; pValue: ISQLValue): ISQLInsert; overload;

    function Columns(const pColumns: array of string): ISQLInsert;
    function Values(const pValues: array of TValue): ISQLInsert; overload;
    function Values(pValues: array of ISQLValue): ISQLInsert; overload;
  end;

  TSQLCoalesce = class(TSQL, ISQLCoalesce)
  strict private
    FTerm: string;
    FValue: ISQLValue;
    FAlias: string;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create();

    function Expression(const pTerm: string): ISQLCoalesce; overload;
    function Expression(const pAggregateTerm: ISQLAggregate): ISQLCoalesce; overload;
    function Expression(const pCaseTerm: ISQLCase): ISQLCoalesce; overload;

    function Value(const pValue: TValue): ISQLCoalesce; overload;
    function Value(pValue: ISQLValue): ISQLCoalesce; overload;

    function &As(const pAlias: string): ISQLCoalesce;
    function Alias(const pAlias: string): ISQLCoalesce;
  end;

  TSQLAggregate = class(TSQL, ISQLAggregate)
  strict private
    FFunction: TSQLAggFunction;
    FTerm: string;
    FAlias: string;
    FOp: TSQLOperator;
    FValue: ISQLValue;
    FIsCondition: Boolean;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create();

    function Avg(): ISQLAggregate; overload;
    function Avg(const pExpression: string): ISQLAggregate; overload;
    function Avg(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Avg(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Count(): ISQLAggregate; overload;
    function Count(const pExpression: string): ISQLAggregate; overload;
    function Count(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Count(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Max(): ISQLAggregate; overload;
    function Max(const pExpression: string): ISQLAggregate; overload;
    function Max(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Max(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Min(): ISQLAggregate; overload;
    function Min(const pExpression: string): ISQLAggregate; overload;
    function Min(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Min(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Sum(): ISQLAggregate; overload;
    function Sum(const pExpression: string): ISQLAggregate; overload;
    function Sum(pCoalesceExpression: ISQLCoalesce): ISQLAggregate; overload;
    function Sum(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Expression(const pTerm: string): ISQLAggregate; overload;
    function Expression(pCoalesceTerm: ISQLCoalesce): ISQLAggregate; overload;
    function Expression(pCaseTerm: ISQLCase): ISQLAggregate; overload;

    function Condition(const pOp: TSQLOperator; const pValue: TValue): ISQLAggregate; overload;
    function Condition(const pOp: TSQLOperator; pValue: ISQLValue): ISQLAggregate; overload;
    function Condition(const pOp: TSQLOperator): ISQLAggregate; overload;

    function &As(const pAlias: string): ISQLAggregate;
    function Alias(const pAlias: string): ISQLAggregate;
  end;

  TSQLCase = class(TSQL, ISQLCase)
  strict private

  type
    TPossibility = class
    private
      FCondition: ISQLValue;
      FValue: ISQLValue;
    public
      constructor Create(pCondition, pValue: ISQLValue);

      property Condition: ISQLValue read FCondition;
      property Value: ISQLValue read FValue;
    end;

  strict private
    FExpression: ISQLValue;
    FDefValue: ISQLValue;
    FCondition: ISQLValue;
    FPossibilities: TObjectList<TPossibility>;
    FAlias: string;
  strict protected
    function DoToString(): string; override;
  public
    constructor Create();
    destructor Destroy; override;

    function Expression(const pTerm: string): ISQLCase; overload;
    function Expression(pTerm: ISQLValue): ISQLCase; overload;

    function When(const pCondition: TValue): ISQLCase; overload;
    function When(pCondition: ISQLValue): ISQLCase; overload;

    function &Then(const pValue: TValue): ISQLCase; overload;
    function &Then(pValue: ISQLValue): ISQLCase; overload;
    function &Then(pValue: ISQLAggregate): ISQLCase; overload;
    function &Then(pValue: ISQLCoalesce): ISQLCase; overload;

    function &Else(const pDefValue: TValue): ISQLCase; overload;
    function &Else(pDefValue: ISQLValue): ISQLCase; overload;
    function &Else(pDefValue: ISQLAggregate): ISQLCase; overload;
    function &Else(pDefValue: ISQLCoalesce): ISQLCase; overload;

    function &End(): ISQLCase;

    function &As(const pAlias: string): ISQLCase;
    function Alias(const pAlias: string): ISQLCase;
  end;

  { TSQL }

function TSQL.ToFile(const pFileName: string): ISQL;
var
  vSl: TStringList;
begin
  if FileExists(pFileName) then
    DeleteFile(pFileName);

  vSl := TStringList.Create;
  try
    vSl.Add(ToString());
    vSl.SaveToFile(pFileName);

    if not FileExists(pFileName) then
      raise ESQLBuilderException.Create('Could not save the file!');
  finally
    FreeAndNil(vSl);
  end;
end;

function TSQL.ToString: string;
begin
  Result := DoToString();
end;

{ TSQLStatement }

constructor TSQLStatement.Create;
begin
  FStatementType := stNone;
end;

function TSQLStatement.DoToString: string;
begin
  Result := EmptyStr;
end;

function TSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := FStatementType;
end;

procedure TSQLStatement.SetStatementType(const pValue: TSQLStatementType);
begin
  FStatementType := pValue;
end;

{ TSQLCriteria }

constructor TSQLCriteria.Create(const pCriteria: string; const pConnector: TSQLConnector);
begin
  FCriteria := pCriteria;
  FConnectorType := pConnector;
end;

function TSQLCriteria.DoToString: string;
begin
  Result := EmptyStr;
end;

function TSQLCriteria.GetConnector: TSQLConnector;
begin
  Result := FConnectorType;
end;

function TSQLCriteria.ConnectorDescription: string;
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

function TSQLCriteria.GetCriteria: string;
begin
  Result := FCriteria;
end;

{ TSQLClause }

constructor TSQLClause.Create(const pOwnerString: TFunc<string>);
begin
  FCriterias := TList<ISQLCriteria>.Create;
  OwnerString := pOwnerString;
end;

destructor TSQLClause.Destroy;
begin
  FreeAndNil(FCriterias);
  inherited;
end;

function TSQLClause.DoToString: string;
begin
  Result := EmptyStr;
end;

function TSQLClause.GetCriterias: TList<ISQLCriteria>;
begin
  Result := FCriterias;
end;

{ TSQLValue }

function TSQLValue.Column: ISQLValue;
begin
  FIsColumn := True;
  Result := Self;
end;

function TSQLValue.ConvertDate(const pDate: TDate): string;
var
  vFmt: TFormatSettings;
begin

  {$IFDEF VER210}

  vFmt.DateSeparator := '.';
  vFmt.ShortDateFormat := 'dd.mm.yyyy';
  vFmt.LongDateFormat := 'dd.mm.yyyy';
  Result := QuotedStr(DateToStr(pDate, vFmt));

  {$ELSE}

  vFmt := TFormatSettings.Create;
  vFmt.DateSeparator := '.';
  vFmt.ShortDateFormat := 'dd.mm.yyyy';
  vFmt.LongDateFormat := 'dd.mm.yyyy';
  Result := QuotedStr(DateToStr(pDate, vFmt));

  {$ENDIF}

end;

function TSQLValue.ConvertDateTime(const pDateTime: TDateTime): string;
var
  vFmt: TFormatSettings;
begin

  {$IFDEF VER210}

  vFmt.DateSeparator := '.';
  vFmt.ShortDateFormat := 'dd.mm.yyyy hh:mm:ss';
  vFmt.LongDateFormat := 'dd.mm.yyyy hh:mm:ss';
  vFmt.TimeSeparator := ':';
  vFmt.TimeAMString := 'AM';
  vFmt.TimePMString := 'PM';
  vFmt.ShortTimeFormat := 'hh:mm:ss';
  vFmt.LongTimeFormat := 'hh:mm:ss';
  Result := QuotedStr(DateToStr(pDateTime, vFmt));

  {$ELSE}

  vFmt := TFormatSettings.Create();
  vFmt.DateSeparator := '.';
  vFmt.ShortDateFormat := 'dd.mm.yyyy hh:mm:ss';
  vFmt.LongDateFormat := 'dd.mm.yyyy hh:mm:ss';
  vFmt.TimeSeparator := ':';
  vFmt.TimeAMString := 'AM';
  vFmt.TimePMString := 'PM';
  vFmt.ShortTimeFormat := 'hh:mm:ss';
  vFmt.LongTimeFormat := 'hh:mm:ss';
  Result := QuotedStr(DateToStr(pDateTime, vFmt));

  {$ENDIF}

end;

function TSQLValue.ConvertTime(const pTime: TTime): string;
var
  vFmt: TFormatSettings;
begin

  {$IFDEF VER210}

  vFmt.ShortDateFormat := 'hh:mm:ss';
  vFmt.LongDateFormat := 'hh:mm:ss';
  vFmt.TimeSeparator := ':';
  vFmt.TimeAMString := 'AM';
  vFmt.TimePMString := 'PM';
  vFmt.ShortTimeFormat := 'hh:mm:ss';
  vFmt.LongTimeFormat := 'hh:mm:ss';
  Result := QuotedStr(DateToStr(pTime, vFmt));

  {$ELSE}

  vFmt := TFormatSettings.Create();
  vFmt.ShortDateFormat := 'hh:mm:ss';
  vFmt.LongDateFormat := 'hh:mm:ss';
  vFmt.TimeSeparator := ':';
  vFmt.TimeAMString := 'AM';
  vFmt.TimePMString := 'PM';
  vFmt.ShortTimeFormat := 'hh:mm:ss';
  vFmt.LongTimeFormat := 'hh:mm:ss';
  Result := QuotedStr(DateToStr(pTime, vFmt));

  {$ENDIF}

end;

constructor TSQLValue.Create(const pValue: TValue);
begin
  FValue := pValue;
  FIsColumn := False;
  FIsExpression := False;
  FCase := vcNone;
  FIsInsensetive := False;
  FIsLike := False;
  FIsDate := False;
  FIsDateTime := False;
  FIsTime := False;
  FLikeOp := loEqual;
end;

function TSQLValue.Date: ISQLValue;
begin
  FIsDate := True;
  Result := Self;
end;

function TSQLValue.DateTime: ISQLValue;
begin
  FIsDateTime := True;
  Result := Self;
end;

function TSQLValue.DoToString: string;
begin
  if IsDate then
    Exit(ConvertDate(FloatToDateTime(GetValue.AsExtended)));

  if IsDateTime then
    Exit(ConvertDateTime(FloatToDateTime(GetValue.AsExtended)));

  if IsTime then
    Exit(ConvertTime(FloatToDateTime(GetValue.AsExtended)));

  Result := FValue.ToString;

  if (Result = '') and (not IsExpression) then
    Exit('Null');

  if IsReserverdWord(Result) then
    raise ESQLBuilderException.Create('Value informed for the SQL Builder is invalid!');

  case FValue.Kind of
    tkUString, tkWChar, tkLString, tkWString, tkString, tkChar:
      if (IsColumn or IsExpression) then
      begin
        if (IsInsensetive or IsLower) then
          Result := 'Lower(' + Result + ')'
        else if IsUpper then
          Result := 'Upper(' + Result + ')'
        else
          Result := Result;
      end
      else
      begin
        if IsLike then
          case GetLikeOperator of
            loStarting:
              Result := Result + '%';
            loEnding:
              Result := '%' + Result;
            loContaining:
              Result := '%' + Result + '%';
          end;
        if (IsInsensetive or IsLower) then
          Result := ' Lower(' + QuotedStr(Result) + ')'
        else if IsUpper then
          Result := 'Upper(' + Result + ')'
        else
          Result := QuotedStr(Result);
      end;
    tkUnknown:
      Result := 'Null';
    tkFloat:
      Result := ReplaceText(Result, ',', '.');
  end;
end;

function TSQLValue.Expression: ISQLValue;
begin
  FIsExpression := True;
  Result := Self;
end;

function TSQLValue.GetLikeOperator: TSQLLikeOperator;
begin
  Result := FLikeOp;
end;

function TSQLValue.GetValue: TValue;
begin
  Result := FValue;
end;

function TSQLValue.IsColumn: Boolean;
begin
  Result := FIsColumn;
end;

function TSQLValue.IsDate: Boolean;
begin
  Result := FIsDate;
end;

function TSQLValue.IsDateTime: Boolean;
begin
  Result := FIsDateTime;
end;

function TSQLValue.IsExpression: Boolean;
begin
  Result := FIsExpression;
end;

function TSQLValue.IsReserverdWord(const pValue: string): Boolean;
var
  vWords: TArray<string>;
  I: Integer;
begin
  Result := False;

  vWords := TArray<string>.Create('or', 'and', 'between', 'is', 'not', 'null', 'in', 'like',
    'select', 'union', 'inner', 'join', 'right', 'full', 'first', 'insert', 'update', 'delete',
    'upper', 'lower');

  for I := Low(vWords) to High(vWords) do
    if (CompareText(LowerCase(pValue), vWords[I]) = 0) then
      Exit(True);
end;

function TSQLValue.IsTime: Boolean;
begin
  Result := FIsTime;
end;

function TSQLValue.IsUpper: Boolean;
begin
  Result := (FCase = vcUpper);
end;

function TSQLValue.Like(const pOp: TSQLLikeOperator): ISQLValue;
begin
  FLikeOp := pOp;
  FIsLike := True;
  Result := Self;
end;

function TSQLValue.Lower: ISQLValue;
begin
  FCase := vcLower;
  Result := Self;
end;

function TSQLValue.Time: ISQLValue;
begin
  FIsTime := True;
  Result := Self;
end;

function TSQLValue.Upper: ISQLValue;
begin
  FCase := vcUpper;
  Result := Self;
end;

function TSQLValue.IsInsensetive: Boolean;
begin
  Result := FIsInsensetive;
end;

function TSQLValue.IsLike: Boolean;
begin
  Result := FIsLike;
end;

function TSQLValue.IsLower: Boolean;
begin
  Result := (FCase = vcLower);
end;

function TSQLValue.Insensetive: ISQLValue;
begin
  FIsInsensetive := True;
  Result := Self;
end;

{ TSQLTable }

constructor TSQLTable.Create(const pName: string);
begin
  FName := pName;
end;

function TSQLTable.DoToString: string;
begin
  Result := EmptyStr;
end;

function TSQLTable.GetName: string;
begin
  Result := FName;
end;

{ TSQLFrom }

constructor TSQLFrom.Create(pTable: ISQLTable);
begin
  FTable := pTable;
end;

function TSQLFrom.DoToString: string;
begin
  Result := EmptyStr;
end;

function TSQLFrom.GetTable: ISQLTable;
begin
  Result := FTable;
end;

{ TSQLJoinCondition }

function TSQLJoinTerm.Op(const pOp: TSQLOperator): ISQLJoinTerm;
begin
  FOp := pOp;
  Result := Self;
end;

constructor TSQLJoinTerm.Create;
begin
  FLeft := nil;
  FOp := opEqual;
  FRight := nil;
end;

function TSQLJoinTerm.DoToString: string;
begin
  Result := EmptyStr;
  if (FLeft <> nil) and (FRight <> nil) then
    Result := '(' + FLeft.ToString() + ' ' + SQL_OPERATOR[FOp] + ' ' + FRight.ToString() + ')';
end;

function TSQLJoinTerm.Left(const pTerm: TValue): ISQLJoinTerm;
begin
  Result := Left(TSQLValue.Create(pTerm).Column);
end;

function TSQLJoinTerm.Left(pTerm: ISQLValue): ISQLJoinTerm;
begin
  FLeft := pTerm;
  Result := Self;
end;

function TSQLJoinTerm.Right(const pTerm: TValue): ISQLJoinTerm;
begin
  Result := Right(TSQLValue.Create(pTerm).Column);
end;

function TSQLJoinTerm.Right(pTerm: ISQLValue): ISQLJoinTerm;
begin
  FRight := pTerm;
  Result := Self;
end;

{ TSQLJoin }

constructor TSQLJoin.Create(pTable: ISQLTable; const pType: TSQLJoinType; const pDefaultCondition: string);
begin
  FConditions := TStringList.Create;

  if not(pDefaultCondition = '') then
    FConditions.Add(pDefaultCondition);

  FType := pType;
  FTable := pTable;
end;

destructor TSQLJoin.Destroy;
begin
  FreeAndNil(FConditions);
  inherited;
end;

function TSQLJoin.Table(pTable: ISQLTable): ISQLJoin;
begin
  FTable := pTable;
  Result := Self;
end;

function TSQLJoin.&And(pTerm: ISQLJoinTerm): ISQLJoin;
begin
  FConditions.Add(' And ' + pTerm.ToString());
  Result := Self;
end;

function TSQLJoin.Condition(pTerm: ISQLJoinTerm): ISQLJoin;
begin
  if (FConditions.Count > 0) then
    Result := &And(pTerm)
  else
  begin
    FConditions.Add(pTerm.ToString());
    Result := Self;
  end;
end;

function TSQLJoin.&Or(pTerm: ISQLJoinTerm): ISQLJoin;
begin
  FConditions.Add(' Or ' + pTerm.ToString());
  Result := Self;
end;

function TSQLJoin.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  if (FTable = nil) or (FTable.Name = '') or (FConditions.Count = 0) then
    Exit();

  case FType of
    jtInner:
      Result := ' Join ' + FTable.Name + ' On ';
    jtLeft:
      Result := ' Left Join ' + FTable.Name + ' On ';
    jtRight:
      Result := ' Right Join ' + FTable.Name + ' On ';
    jtFull:
      Result := ' Full Join ' + FTable.Name + ' On ';
  end;

  vSb := TStringBuilder.Create;
  try
    for I := 0 to Pred(FConditions.Count) do
    begin
      vSb.Append(FConditions[I]);
      if (I < Pred(FConditions.Count)) then
        vSb.AppendLine;
    end;
    Result := Result + vSb.ToString();
  finally
    FreeAndNil(vSb);
  end;
end;

{ TSQLUnion }

constructor TSQLUnion.Create(const pType: TSQLUnionType; const pSQL: string);
begin
  FUnionType := pType;
  FUnionSQL := pSQL;
end;

function TSQLUnion.DoToString: string;
begin
  case FUnionType of
    utUnion:
      Result := 'Union';
    utUnionAll:
      Result := 'Union All';
  end;
  Result := Result + sLineBreak + FUnionSQL;
end;

function TSQLUnion.GetUnionSQL: string;
begin
  Result := FUnionSQL;
end;

function TSQLUnion.GetUnionType: TSQLUnionType;
begin
  Result := FUnionType;
end;

{ TSQLOrderBy }

procedure TSQLOrderBy.AddUnion(const pSQL: string; const pType: TSQLUnionType);
begin
  FUnions.Add(TSQLUnion.Create(pType, pSQL));
end;

procedure TSQLOrderBy.AfterConstruction;
begin
  inherited AfterConstruction;
  FSortType := srNone;
  FUnions := TList<ISQLUnion>.Create;
end;

procedure TSQLOrderBy.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

function TSQLOrderBy.Column(const pColumn: string; const pSortType: TSQLSort): ISQLOrderBy;
var
  vStr: string;
begin
  case pSortType of
    srNone:
      vStr := pColumn;
    srAsc:
      vStr := pColumn + ' Asc';
    srDesc:
      vStr := pColumn + ' Desc';
  end;
  Criterias.Add(TSQLCriteria.Create(vStr, ctComma));
  Result := Self;
end;

function TSQLOrderBy.Columns(const pColumns: array of string;
  const pSortType: TSQLSort): ISQLOrderBy;
var
  I: Integer;
begin
  Criterias.Clear;
  for I := Low(pColumns) to High(pColumns) do
    Column(pColumns[I]);
  if (pSortType <> srNone) then
    Sort(pSortType);
  Result := Self;
end;

procedure TSQLOrderBy.CopyOf(pSource: ISQLOrderBy);
var
  I: Integer;
begin
  Criterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    Criterias.Add(pSource.Criterias[I]);
end;

function TSQLOrderBy.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  vSb := TStringBuilder.Create;
  try
    if Assigned(OwnerString) then
    begin
      vSb.Append(OwnerString);
      vSb.AppendLine;
    end;

    for I := 0 to Pred(Criterias.Count) do
    begin
      if I = 0 then
        vSb.Append(' Order By')
      else
        vSb.Append(Criterias[I].ConnectorDescription);
      vSb.Append(' ' + Criterias[I].Criteria);
      case FSortType of
        srAsc:
          if not ContainsStr(Criterias[I].Criteria, 'Asc') then
            vSb.Append(' Asc');
        srDesc:
          if not ContainsStr(Criterias[I].Criteria, 'Desc') then
            vSb.Append(' Desc');
      end;
    end;

    for I := 0 to Pred(FUnions.Count) do
      vSb.AppendLine.Append(FUnions[I].ToString);

    Result := vSb.ToString();
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLOrderBy.Sort(const pSortType: TSQLSort): ISQLOrderBy;
begin
  FSortType := pSortType;
  Result := Self;
end;

function TSQLOrderBy.Union(pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLOrderBy;
begin
  AddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLOrderBy;
begin
  AddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLOrderBy;
begin
  AddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLOrderBy;
begin
  AddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLOrderBy.Union(pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLOrderBy;
begin
  AddUnion(pHaving.ToString, pType);
  Result := Self;
end;

{ TSQLHaving }

procedure TSQLHaving.AddUnion(const pSQL: string; const pType: TSQLUnionType);
begin
  FUnions.Add(TSQLUnion.Create(pType, pSQL));
end;

procedure TSQLHaving.AfterConstruction;
begin
  inherited AfterConstruction;
  FOrderBy := TSQLOrderBy.Create(Self.ToString);
  FUnions := TList<ISQLUnion>.Create;
end;

function TSQLHaving.Expression(pAggregateTerm: ISQLAggregate): ISQLHaving;
begin
  Result := Expression(pAggregateTerm.ToString());
end;

function TSQLHaving.Expression(const pTerm: string): ISQLHaving;
begin
  Criterias.Add(TSQLCriteria.Create(pTerm, ctAnd));
  Result := Self;
end;

function TSQLHaving.Expressions(pAggregateTerms: array of ISQLAggregate): ISQLHaving;
var
  I: Integer;
begin
  Criterias.Clear;
  for I := Low(pAggregateTerms) to High(pAggregateTerms) do
    Expression(pAggregateTerms[I]);
  Result := Self;
end;

function TSQLHaving.Expressions(const pTerms: array of string): ISQLHaving;
var
  I: Integer;
begin
  Criterias.Clear;
  for I := Low(pTerms) to High(pTerms) do
    Expression(pTerms[I]);
  Result := Self;
end;

procedure TSQLHaving.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

procedure TSQLHaving.CopyOf(pSource: ISQLHaving);
var
  I: Integer;
begin
  Criterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    Criterias.Add(pSource.Criterias[I]);
end;

function TSQLHaving.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  vSb := TStringBuilder.Create;
  try
    if Assigned(OwnerString) then
    begin
      vSb.Append(OwnerString);
      vSb.AppendLine;
    end;

    for I := 0 to Pred(Criterias.Count) do
    begin
      if I = 0 then
        vSb.Append(' Having ')
      else
        vSb.Append(' ' + Criterias[I].ConnectorDescription + ' ');
      vSb.AppendFormat('(%0:S)', [Criterias[I].Criteria]);
    end;

    for I := 0 to Pred(FUnions.Count) do
      vSb.AppendLine.Append(FUnions[I].ToString);

    Result := vSb.ToString();
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLHaving.OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLHaving.Union(pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLHaving;
begin
  AddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLHaving;
begin
  AddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLHaving;
begin
  AddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLHaving;
begin
  AddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLHaving.Union(pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLHaving;
begin
  AddUnion(pHaving.ToString, pType);
  Result := Self;
end;

function TSQLHaving.OrderBy: ISQLOrderBy;
begin
  Result := FOrderBy;
end;

{ TSQLGroupBy }

procedure TSQLGroupBy.AddUnion(const pSQL: string; const pType: TSQLUnionType);
begin
  FUnions.Add(TSQLUnion.Create(pType, pSQL));
end;

procedure TSQLGroupBy.AfterConstruction;
begin
  inherited AfterConstruction;
  FOrderBy := TSQLOrderBy.Create(Self.ToString);
  FHaving := TSQLHaving.Create(Self.ToString);
  FUnions := TList<ISQLUnion>.Create;
end;

procedure TSQLGroupBy.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

function TSQLGroupBy.Column(const pColumn: string): ISQLGroupBy;
begin
  Criterias.Add(TSQLCriteria.Create(pColumn, ctComma));
  Result := Self;
end;

function TSQLGroupBy.Columns(const pColumns: array of string): ISQLGroupBy;
var
  I: Integer;
begin
  Criterias.Clear;
  for I := Low(pColumns) to High(pColumns) do
    Column(pColumns[I]);
  Result := Self;
end;

procedure TSQLGroupBy.CopyOf(pSource: ISQLGroupBy);
var
  I: Integer;
begin
  Criterias.Clear;
  for I := 0 to Pred(pSource.Criterias.Count) do
    Criterias.Add(pSource.Criterias[I]);
end;

function TSQLGroupBy.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  vSb := TStringBuilder.Create;
  try
    if Assigned(OwnerString) then
    begin
      vSb.Append(OwnerString);
      vSb.AppendLine;
    end;

    for I := 0 to Pred(Criterias.Count) do
    begin
      if I = 0 then
        vSb.Append(' Group By')
      else
        vSb.Append(Criterias[I].ConnectorDescription);
      vSb.Append(' ' + Criterias[I].Criteria);
    end;

    for I := 0 to Pred(FUnions.Count) do
      vSb.AppendLine.Append(FUnions[I].ToString);

    Result := vSb.ToString;
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLGroupBy.Having: ISQLHaving;
begin
  Result := FHaving;
end;

function TSQLGroupBy.Having(pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

function TSQLGroupBy.OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLGroupBy.Union(pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLGroupBy;
begin
  AddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLGroupBy;
begin
  AddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLGroupBy;
begin
  AddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLGroupBy;
begin
  AddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.Union(pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLGroupBy;
begin
  AddUnion(pHaving.ToString, pType);
  Result := Self;
end;

function TSQLGroupBy.OrderBy: ISQLOrderBy;
begin
  Result := FOrderBy;
end;

{ TSQLWhere }

procedure TSQLWhere.AddInList(pValues: array of ISQLValue; const pNotIn: Boolean);
var
  vSb: TStringBuilder;
  I: Integer;
  vInsensetive: Boolean;
  vStrIn: string;
begin

  if (FColumn = '') then
    raise ESQLBuilderException.Create('Column can not be empty!');

  vInsensetive := False;

  vSb := TStringBuilder.Create;
  try
    vSb.Append('(');
    for I := Low(pValues) to High(pValues) do
    begin
      if (I > 0) then
        vSb.Append(', ');
      vSb.Append(pValues[I].ToString);
      if pValues[I].IsInsensetive then
        vInsensetive := True;
    end;
    vSb.Append(')');

    if pNotIn then
      vStrIn := ' Not In '
    else
      vStrIn := ' In ';

    if vInsensetive then
      Criterias.Add(TSQLCriteria.Create('(Lower(' + FColumn + ')' + vStrIn + vSb.ToString + ')', FConnector))
    else
      Criterias.Add(TSQLCriteria.Create('(' + FColumn + vStrIn + vSb.ToString + ')', FConnector));
  finally
    FreeAndNil(vSb);
  end;

  FConnector := ctAnd;
  FColumn := EmptyStr;
end;

procedure TSQLWhere.AddExpression(const pSQLOp: TSQLOperator; pSQLValue: ISQLValue);
var
  vValue: string;
begin
  if (FColumn = '') then
    raise ESQLBuilderException.Create('Column can not be empty!');

  if pSQLValue.IsInsensetive then
    Criterias.Add(
      TSQLCriteria.Create('(Lower(' + FColumn + ') ' + SQL_OPERATOR[pSQLOp] + pSQLValue.ToString + ')', FConnector)
      )
  else
  begin
    vValue := pSQLValue.ToString;

    if (vValue <> '') then
      vValue := ' ' + vValue;

    Criterias.Add(
      TSQLCriteria.Create('(' + FColumn + ' ' + SQL_OPERATOR[pSQLOp] + vValue + ')', FConnector)
      );
  end;

  FConnector := ctAnd;
  FColumn := EmptyStr;
end;

procedure TSQLWhere.AddUnion(const pSQL: string; const pType: TSQLUnionType);
begin
  FUnions.Add(TSQLUnion.Create(pType, pSQL));
end;

procedure TSQLWhere.AfterConstruction;
begin
  inherited AfterConstruction;
  FColumn := EmptyStr;
  FConnector := ctAnd;
  FGroupBy := TSQLGroupBy.Create(Self.ToString);
  FHaving := TSQLHaving.Create(Self.ToString);
  FOrderBy := TSQLOrderBy.Create(Self.ToString);
  FUnions := TList<ISQLUnion>.Create;
end;

function TSQLWhere.&And(const pColumn: string): ISQLWhere;
begin
  FConnector := ctAnd;
  FColumn := pColumn;
  Result := Self;
end;

function TSQLWhere.&And(pWhere: ISQLWhere): ISQLWhere;
begin
  Criterias.Add(TSQLCriteria.Create('(' + ReplaceText(pWhere.ToString, ' Where ', '') + ')', ctAnd));
  FConnector := ctAnd;
  FColumn := EmptyStr;
  Result := Self;
end;

procedure TSQLWhere.BeforeDestruction;
begin
  FreeAndNil(FUnions);
  inherited BeforeDestruction;
end;

function TSQLWhere.Between(pStart, pEnd: ISQLValue): ISQLWhere;
begin
  if (FColumn = '') then
    raise ESQLBuilderException.Create('Column can not be empty!');

  Criterias.Add(
    TSQLCriteria.Create('(' + FColumn + ' Between ' + pStart.ToString +
    ' And ' + pEnd.ToString + ')', FConnector)
    );

  FConnector := ctAnd;
  FColumn := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Between(const pStart, pEnd: TValue): ISQLWhere;
begin
  Result := Between(TSQLValue.Create(pStart), TSQLValue.Create(pEnd));
end;

function TSQLWhere.Column(const pColumn: string): ISQLWhere;
begin
  FConnector := ctAnd;
  FColumn := pColumn;
  Result := Self;
end;

procedure TSQLWhere.CopyOf(pSource: ISQLWhere);
begin
  Criterias.Clear;
  &And(pSource);
end;

function TSQLWhere.Different(const pValue: TValue): ISQLWhere;
begin
  Result := Different(TSQLValue.Create(pValue));
end;

function TSQLWhere.Different(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opDifferent, pValue);
  Result := Self;
end;

function TSQLWhere.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  vSb := TStringBuilder.Create;
  try
    if Assigned(OwnerString) then
    begin
      vSb.Append(OwnerString);
      vSb.AppendLine;
    end;

    for I := 0 to Pred(Criterias.Count) do
    begin
      if (I = 0) then
        vSb.Append(' Where ')
      else
        vSb.Append(' ' + Criterias[I].ConnectorDescription + ' ');

      vSb.Append(Criterias[I].Criteria);
    end;

    for I := 0 to Pred(FUnions.Count) do
      vSb.AppendLine.Append(FUnions[I].ToString);

    Result := vSb.ToString;
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLWhere.Equal(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opEqual, pValue);
  Result := Self;
end;

function TSQLWhere.Equal(const pValue: TValue): ISQLWhere;
begin
  Result := Equal(TSQLValue.Create(pValue));
end;

function TSQLWhere.Expression(const pOp: TSQLOperator; pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(pOp, pValue);
  Result := Self;
end;

function TSQLWhere.Expression(const pOp: TSQLOperator; const pValue: TValue): ISQLWhere;
begin
  Result := Expression(pOp, TSQLValue.Create(pValue));
end;

function TSQLWhere.Greater(const pValue: TValue): ISQLWhere;
begin
  Result := Greater(TSQLValue.Create(pValue));
end;

function TSQLWhere.Greater(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opGreater, pValue);
  Result := Self;
end;

function TSQLWhere.GreaterOrEqual(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opGreaterOrEqual, pValue);
  Result := Self;
end;

function TSQLWhere.GreaterOrEqual(const pValue: TValue): ISQLWhere;
begin
  Result := GreaterOrEqual(TSQLValue.Create(pValue));
end;

function TSQLWhere.GroupBy(pGroupBy: ISQLGroupBy): ISQLGroupBy;
begin
  FGroupBy.CopyOf(pGroupBy);
  Result := FGroupBy;
end;

function TSQLWhere.GroupBy: ISQLGroupBy;
begin
  Result := FGroupBy;
end;

function TSQLWhere.Having(pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

function TSQLWhere.Having: ISQLHaving;
begin
  Result := FHaving;
end;

function TSQLWhere.InList(const pValues: array of TValue): ISQLWhere;
var
  vValues: array of ISQLValue;
  I: Integer;
begin
  SetLength(vValues, Length(pValues));
  for I := Low(pValues) to High(pValues) do
    vValues[I] := TSQLValue.Create(pValues[I]);
  Result := InList(vValues);
end;

function TSQLWhere.InList(pValues: array of ISQLValue): ISQLWhere;
begin
  AddInList(pValues, False);
  Result := Self;
end;

function TSQLWhere.IsNotNull: ISQLWhere;
begin
  AddExpression(opNotNull, TSQLValue.Create('').Expression);
  Result := Self;
end;

function TSQLWhere.IsNull: ISQLWhere;
begin
  AddExpression(opIsNull, TSQLValue.Create('').Expression);
  Result := Self;
end;

function TSQLWhere.Less(const pValue: TValue): ISQLWhere;
begin
  Result := Less(TSQLValue.Create(pValue));
end;

function TSQLWhere.Less(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opLess, pValue);
  Result := Self;
end;

function TSQLWhere.LessOrEqual(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opLessOrEqual, pValue);
  Result := Self;
end;

function TSQLWhere.Like(const pValues: array of string;
  const pOp: TSQLLikeOperator): ISQLWhere;
var
  vValues: array of ISQLValue;
  I: Integer;
begin
  SetLength(vValues, Length(pValues));
  for I := Low(pValues) to High(pValues) do
    vValues[I] := TSQLValue.Create(pValues[I]).Like(pOp);
  Result := Like(vValues);
end;

function TSQLWhere.LessOrEqual(const pValue: TValue): ISQLWhere;
begin
  Result := LessOrEqual(TSQLValue.Create(pValue));
end;

function TSQLWhere.Like(pValues: array of ISQLValue): ISQLWhere;
var
  vWhere: ISQLWhere;
  I: Integer;
begin
  vWhere := TSQLWhere.Create(nil);

  vWhere.Column(FColumn).Like(pValues[0]);
  for I := 1 to High(pValues) do
    vWhere.&Or(FColumn).Like(pValues[I]);

  Self.&And(vWhere);

  FConnector := ctAnd;
  FColumn := EmptyStr;
  Result := Self;
end;

function TSQLWhere.Like(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opLike, pValue);
  Result := Self;
end;

function TSQLWhere.Like(const pValue: string; const pOp: TSQLLikeOperator): ISQLWhere;
begin
  Result := Like(TSQLValue.Create(pValue).Like(pOp));
end;

function TSQLWhere.NotInList(pValues: array of ISQLValue): ISQLWhere;
begin
  AddInList(pValues, True);
  Result := Self;
end;

function TSQLWhere.NotInList(const pValues: array of TValue): ISQLWhere;
var
  vValues: array of ISQLValue;
  I: Integer;
begin
  SetLength(vValues, Length(pValues));
  for I := Low(pValues) to High(pValues) do
    vValues[I] := TSQLValue.Create(pValues[I]);
  Result := NotInList(vValues);
end;

function TSQLWhere.NotLike(pValue: ISQLValue): ISQLWhere;
begin
  AddExpression(opNotLike, pValue);
  Result := Self;
end;

function TSQLWhere.NotLike(const pValue: string; const pOp: TSQLLikeOperator): ISQLWhere;
begin
  Result := NotLike(TSQLValue.Create(pValue).Like(pOp));
end;

function TSQLWhere.NotLike(pValues: array of ISQLValue): ISQLWhere;
var
  vWhere: ISQLWhere;
  I: Integer;
begin
  vWhere := TSQLWhere.Create(nil);

  vWhere.Column(FColumn).NotLike(pValues[0]);
  for I := 1 to High(pValues) do
    vWhere.&Or(FColumn).NotLike(pValues[I]);

  Self.&And(vWhere);

  FConnector := ctAnd;
  FColumn := EmptyStr;
  Result := Self;
end;

function TSQLWhere.NotLike(const pValues: array of string;
  const pOp: TSQLLikeOperator): ISQLWhere;
var
  vValues: array of ISQLValue;
  I: Integer;
begin
  SetLength(vValues, Length(pValues));
  for I := Low(pValues) to High(pValues) do
    vValues[I] := TSQLValue.Create(pValues[I]).Like(pOp);
  Result := NotLike(vValues);
end;

function TSQLWhere.&Or(const pColumn: string): ISQLWhere;
begin
  FConnector := ctOr;
  FColumn := pColumn;
  Result := Self;
end;

function TSQLWhere.&Or(pWhere: ISQLWhere): ISQLWhere;
begin
  Criterias.Add(TSQLCriteria.Create('(' + AnsiReplaceText(pWhere.ToString, ' Where ', '') + ')', ctOr));
  FConnector := ctAnd;
  FColumn := EmptyStr;
  Result := Self;
end;

function TSQLWhere.OrderBy: ISQLOrderBy;
begin
  Result := FOrderBy;
end;

function TSQLWhere.OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLWhere.Union(pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLWhere;
begin
  AddUnion(pWhere.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLWhere;
begin
  AddUnion(pSelect.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLWhere;
begin
  AddUnion(pGroupBy.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLWhere;
begin
  AddUnion(pOrderBy.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Union(pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLWhere;
begin
  AddUnion(pHaving.ToString, pType);
  Result := Self;
end;

function TSQLWhere.Expression(const pOp: TSQLOperator): ISQLWhere;
begin
  Result := Expression(pOp, TSQLValue.Create('').Expression);
end;

{ TSQLSelect }

function TSQLSelect.&As(const pAlias: string): ISQLSelect;
begin
  Result := Alias(pAlias);
end;

procedure TSQLSelect.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stSelect);
  FDistinct := False;
  FColumns := TStringList.Create;
  FColumns.Delimiter := ',';
  FColumns.StrictDelimiter := True;
  FFrom := nil;
  FJoinedTables := TList<ISQLJoin>.Create;
  FGroupBy := TSQLGroupBy.Create(Self.ToString);
  FHaving := TSQLHaving.Create(Self.ToString);
  FOrderBy := TSQLOrderBy.Create(Self.ToString);
  FWhere := TSQLWhere.Create(Self.ToString);
  FUnions := TList<ISQLUnion>.Create;
end;

function TSQLSelect.Alias(const pAlias: string): ISQLSelect;
var
  vColumn: string;
begin
  if not(pAlias = '') then
  begin
    vColumn := FColumns[FColumns.Count - 1];
    if not ContainsText(vColumn, ' As ') then
      FColumns[FColumns.Count - 1] := vColumn + ' As ' + pAlias;
  end;
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

function TSQLSelect.Column(const pColumn: ISQLAggregate): ISQLSelect;
begin
  Result := Column(pColumn.ToString());
end;

function TSQLSelect.Column(const pColumn: ISQLCoalesce): ISQLSelect;
begin
  Result := Column(pColumn.ToString());
end;

function TSQLSelect.Column(const pColumn: string): ISQLSelect;
begin
  FColumns.Add(pColumn);
  Result := Self;
end;

function TSQLSelect.Distinct: ISQLSelect;
begin
  FDistinct := True;
  Result := Self;
end;

function TSQLSelect.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  if (FColumns.Count = 0) or (FFrom = nil) or (FFrom.Table.Name = '') then
    Exit;

  vSb := TStringBuilder.Create;
  try
    vSb.Append('Select ');

    if FDistinct then
      vSb.Append('Distinct ');

    for I := 0 to Pred(FColumns.Count) do
    begin
      if I = 0 then
        vSb.AppendLine
      else
        vSb.Append(',');
      vSb.Append(' ' + FColumns[I]);
    end;

    vSb.AppendLine.Append(' From ' + FFrom.Table.Name);

    for I := 0 to Pred(FJoinedTables.Count) do
      vSb.AppendLine.Append(FJoinedTables[I].ToString);

    for I := 0 to Pred(FUnions.Count) do
      vSb.AppendLine.Append(FUnions[I].ToString);

    Result := vSb.ToString;
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLSelect.From(pTerm: ISQLFrom): ISQLSelect;
begin
  FFrom := TSQLFrom.Create(TSQLTable.Create(pTerm.Table.Name));
  Result := Self;
end;

function TSQLSelect.From(pTerms: array of ISQLFrom): ISQLSelect;
var
  vSb: TStringBuilder;
  I: Integer;
begin
  vSb := TStringBuilder.Create;
  try
    for I := Low(pTerms) to High(pTerms) do
    begin
      if (I > 0) then
        vSb.Append(', ');
      vSb.Append(pTerms[I].Table.Name);
    end;
    Result := From(vSb.ToString);
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLSelect.From(const pTable: string): ISQLSelect;
begin
  Result := From(TSQLFrom.Create(TSQLTable.Create(pTable)));
end;

function TSQLSelect.From(const pTables: array of string): ISQLSelect;
var
  vFroms: array of ISQLFrom;
  I: Integer;
begin
  SetLength(vFroms, Length(pTables));
  for I := Low(pTables) to High(pTables) do
    vFroms[I] := TSQLFrom.Create(TSQLTable.Create(pTables[I]));
  Result := From(vFroms);
end;

function TSQLSelect.FullJoin(const pTable, pCondition: string): ISQLSelect;
begin
  Result := FullJoin(TSQLJoin.Create(TSQLTable.Create(pTable), jtFull, pCondition));
end;

function TSQLSelect.FullJoin(pFullJoin: ISQLJoin): ISQLSelect;
begin
  FJoinedTables.Add(pFullJoin);
  Result := Self;
end;

function TSQLSelect.GroupBy(pGroupBy: ISQLGroupBy): ISQLGroupBy;
begin
  FGroupBy.CopyOf(pGroupBy);
  Result := FGroupBy;
end;

function TSQLSelect.GroupBy: ISQLGroupBy;
begin
  Result := FGroupBy;
end;

function TSQLSelect.Having(pHaving: ISQLHaving): ISQLHaving;
begin
  FHaving.CopyOf(pHaving);
  Result := FHaving;
end;

function TSQLSelect.Having: ISQLHaving;
begin
  Result := FHaving;
end;

function TSQLSelect.Join(const pTable, pCondition: string): ISQLSelect;
begin
  Result := Join(TSQLJoin.Create(TSQLTable.Create(pTable), jtInner, pCondition));
end;

function TSQLSelect.Join(pJoin: ISQLJoin): ISQLSelect;
begin
  FJoinedTables.Add(pJoin);
  Result := Self;
end;

function TSQLSelect.LeftJoin(pLeftJoin: ISQLJoin): ISQLSelect;
begin
  FJoinedTables.Add(pLeftJoin);
  Result := Self;
end;

function TSQLSelect.LeftJoin(const pTable, pCondition: string): ISQLSelect;
begin
  Result := LeftJoin(TSQLJoin.Create(TSQLTable.Create(pTable), jtLeft, pCondition));
end;

function TSQLSelect.OrderBy: ISQLOrderBy;
begin
  Result := FOrderBy;
end;

function TSQLSelect.OrderBy(pOrderBy: ISQLOrderBy): ISQLOrderBy;
begin
  FOrderBy.CopyOf(pOrderBy);
  Result := FOrderBy;
end;

function TSQLSelect.RightJoin(pRightJoin: ISQLJoin): ISQLSelect;
begin
  FJoinedTables.Add(pRightJoin);
  Result := Self;
end;

function TSQLSelect.RightJoin(const pTable, pCondition: string): ISQLSelect;
begin
  Result := RightJoin(TSQLJoin.Create(TSQLTable.Create(pTable), jtRight, pCondition));
end;

function TSQLSelect.SubSelect(pHaving: ISQLHaving; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pHaving.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(pOrderBy: ISQLOrderBy; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pOrderBy.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(pSelect: ISQLSelect; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pSelect.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(pGroupBy: ISQLGroupBy; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pGroupBy.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.SubSelect(pWhere: ISQLWhere; const pAlias: string): ISQLSelect;
begin
  FColumns.Add('(' + pWhere.ToString + ') As ' + pAlias);
  Result := Self;
end;

function TSQLSelect.Union(pOrderBy: ISQLOrderBy; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pOrderBy.ToString));
  Result := Self;
end;

function TSQLSelect.Union(pHaving: ISQLHaving; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pHaving.ToString));
  Result := Self;
end;

function TSQLSelect.Union(pSelect: ISQLSelect; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pSelect.ToString));
  Result := Self;
end;

function TSQLSelect.Union(pWhere: ISQLWhere; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pWhere.ToString));
  Result := Self;
end;

function TSQLSelect.Union(pGroupBy: ISQLGroupBy; const pType: TSQLUnionType): ISQLSelect;
begin
  FUnions.Add(TSQLUnion.Create(pType, pGroupBy.ToString));
  Result := Self;
end;

function TSQLSelect.Where(pWhere: ISQLWhere): ISQLWhere;
begin
  FWhere.CopyOf(pWhere);
  Result := FWhere;
end;

function TSQLSelect.Where(const pColumn: string): ISQLWhere;
begin
  FWhere.Column(pColumn);
  Result := FWhere;
end;

function TSQLSelect.Where: ISQLWhere;
begin
  Result := FWhere;
end;

function TSQLSelect.Column(const pColumn: ISQLCase): ISQLSelect;
begin
  Result := Column(pColumn.ToString());
end;

{ TSQLDelete }

procedure TSQLDelete.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stDelete);
  FWhere := TSQLWhere.Create(Self.ToString);
  FTable := nil;
end;

procedure TSQLDelete.BeforeDestruction;
begin
  inherited BeforeDestruction;
end;

function TSQLDelete.DoToString: string;
var
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  if (FTable = nil) or (FTable.Name = '') then
    Exit;

  vSb := TStringBuilder.Create;
  try
    vSb.Append('Delete From ').Append(FTable.Name);
    Result := vSb.ToString;
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLDelete.From(pTable: ISQLTable): ISQLDelete;
begin
  FTable := pTable;
  Result := Self;
end;

function TSQLDelete.From(const pTable: string): ISQLDelete;
begin
  Result := From(TSQLTable.Create(pTable));
end;

function TSQLDelete.Where: ISQLWhere;
begin
  Result := FWhere;
end;

function TSQLDelete.Where(pWhere: ISQLWhere): ISQLWhere;
begin
  FWhere.CopyOf(pWhere);
  Result := FWhere;
end;

function TSQLDelete.Where(const pColumn: string): ISQLWhere;
begin
  FWhere.Column(pColumn);
  Result := FWhere;
end;

{ TSQLUpdate }

procedure TSQLUpdate.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stUpdate);
  FColumns := TStringList.Create;
  FValues := TList<ISQLValue>.Create;
  FWhere := TSQLWhere.Create(Self.ToString);
  FTable := nil;
end;

procedure TSQLUpdate.BeforeDestruction;
begin
  FreeAndNil(FColumns);
  FreeAndNil(FValues);
  inherited BeforeDestruction;
end;

function TSQLUpdate.Columns(const pColumns: array of string): ISQLUpdate;
var
  I: Integer;
begin
  FColumns.Clear;
  for I := Low(pColumns) to High(pColumns) do
  begin
    if pColumns[I] = '' then
      raise Exception.Create('The column can not be empty!');

    FColumns.Add(pColumns[I]);
  end;
  Result := Self;
end;

function TSQLUpdate.ColumnSetValue(const pColumn: string; pValue: ISQLValue): ISQLUpdate;
begin
  if (pColumn = '') then
    raise Exception.Create('The column can not be empty!');

  FColumns.Add(pColumn);
  FValues.Add(pValue);
  Result := Self;
end;

function TSQLUpdate.ColumnSetValue(const pColumn: string; const pValue: TValue): ISQLUpdate;
begin
  Result := ColumnSetValue(pColumn, TSQLValue.Create(pValue));
end;

function TSQLUpdate.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  if (FColumns.Count <> FValues.Count) then
    raise ESQLBuilderException.Create('Columns count and Values count must be equal!');

  if (FTable = nil) or (FTable.Name = '') then
    Exit;

  vSb := TStringBuilder.Create;
  try
    vSb.Append('Update ' + FTable.Name + ' Set');
    for I := 0 to Pred(FColumns.Count) do
    begin
      if I = 0 then
        vSb.AppendLine
      else
        vSb.Append(',').AppendLine;
      vSb.AppendFormat(' %0:S = %1:S', [FColumns[I], FValues[I].ToString]);
    end;

    Result := vSb.ToString;
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLUpdate.SetValues(const pValues: array of TValue): ISQLUpdate;
var
  vValues: array of ISQLValue;
  I: Integer;
begin
  SetLength(vValues, Length(pValues));
  for I := Low(pValues) to High(pValues) do
    vValues[I] := TSQLValue.Create(pValues[I]);
  Result := SetValues(vValues);
end;

function TSQLUpdate.SetValues(pValues: array of ISQLValue): ISQLUpdate;
var
  I: Integer;
begin
  FValues.Clear;
  for I := Low(pValues) to High(pValues) do
    FValues.Add(pValues[I]);
  Result := Self;
end;

function TSQLUpdate.Table(const pName: string): ISQLUpdate;
begin
  Result := Table(TSQLTable.Create(pName));
end;

function TSQLUpdate.Table(pTable: ISQLTable): ISQLUpdate;
begin
  FTable := pTable;
  Result := Self;
end;

function TSQLUpdate.Where(pWhere: ISQLWhere): ISQLWhere;
begin
  FWhere.CopyOf(pWhere);
  Result := FWhere;
end;

function TSQLUpdate.Where: ISQLWhere;
begin
  Result := FWhere;
end;

function TSQLUpdate.Where(const pColumn: string): ISQLWhere;
begin
  FWhere.Column(pColumn);
  Result := FWhere;
end;

{ TSQLInsert }

procedure TSQLInsert.AfterConstruction;
begin
  inherited AfterConstruction;
  SetStatementType(stInsert);
  FColumns := TStringList.Create;
  FValues := TList<ISQLValue>.Create;
  FTable := nil;
end;

procedure TSQLInsert.BeforeDestruction;
begin
  FreeAndNil(FColumns);
  FreeAndNil(FValues);
  inherited BeforeDestruction;
end;

function TSQLInsert.Columns(const pColumns: array of string): ISQLInsert;
var
  I: Integer;
begin
  FColumns.Clear;
  for I := low(pColumns) to high(pColumns) do
  begin
    if (pColumns[I] = '') then
      raise Exception.Create('The column can not be empty!');

    FColumns.Add(pColumns[I]);
  end;
  Result := Self;
end;

function TSQLInsert.ColumnValue(const pColumn: string; pValue: ISQLValue): ISQLInsert;
begin
  if (pColumn = '') then
    raise Exception.Create('The column can not be empty!');

  FColumns.Add(pColumn);
  FValues.Add(pValue);
  Result := Self;
end;

function TSQLInsert.ColumnValue(const pColumn: string; const pValue: TValue): ISQLInsert;
begin
  Result := ColumnValue(pColumn, TSQLValue.Create(pValue));
end;

function TSQLInsert.DoToString: string;
var
  I: Integer;
  vSb: TStringBuilder;
begin
  Result := EmptyStr;

  if (FColumns.Count <> FValues.Count) then
    raise ESQLBuilderException.Create('Columns count and Values count must be equal!');

  if (FTable = nil) or (FTable.Name = '') then
    Exit;

  vSb := TStringBuilder.Create;
  try
    vSb.Append('Insert Into ' + FTable.Name);

    vSb.AppendLine.Append(' (');

    for I := 0 to Pred(FColumns.Count) do
    begin
      if (I = 0) then
        vSb.Append(FColumns[I])
      else
      begin
        vSb.Append(',').AppendLine;
        vSb.Append('  ' + FColumns[I]);
      end;
    end;

    vSb.Append(')').AppendLine.Append(' Values').AppendLine.Append(' (');

    for I := 0 to Pred(FValues.Count) do
    begin
      if (I = 0) then
        vSb.Append(FValues[I].ToString)
      else
      begin
        vSb.Append(',').AppendLine;
        vSb.Append('  ' + FValues[I].ToString);
      end;
    end;

    vSb.Append(')');

    Result := vSb.ToString;
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLInsert.Into(pTable: ISQLTable): ISQLInsert;
begin
  FTable := pTable;
  Result := Self;
end;

function TSQLInsert.Into(const pTable: string): ISQLInsert;
begin
  Result := Into(TSQLTable.Create(pTable));
end;

function TSQLInsert.Values(pValues: array of ISQLValue): ISQLInsert;
var
  I: Integer;
begin
  FValues.Clear;
  for I := Low(pValues) to High(pValues) do
    FValues.Add(pValues[I]);
  Result := Self;
end;

function TSQLInsert.Values(const pValues: array of TValue): ISQLInsert;
var
  vValues: array of ISQLValue;
  I: Integer;
begin
  SetLength(vValues, Length(pValues));
  for I := Low(pValues) to High(pValues) do
    vValues[I] := TSQLValue.Create(pValues[I]);
  Result := Values(vValues);
end;

{ TSQLCoalesce }

function TSQLCoalesce.&As(const pAlias: string): ISQLCoalesce;
begin
  Result := Alias(pAlias);
end;

function TSQLCoalesce.Alias(const pAlias: string): ISQLCoalesce;
begin
  FAlias := pAlias;
  Result := Self;
end;

constructor TSQLCoalesce.Create;
begin
  FTerm := EmptyStr;
  FValue := nil;
  FAlias := EmptyStr;
end;

function TSQLCoalesce.DoToString: string;
begin
  Result := 'Coalesce(' + FTerm + ',' + FValue.ToString() + ')';
  if (FAlias <> '') then
    Result := Result + ' As ' + FAlias;
end;

function TSQLCoalesce.Expression(const pCaseTerm: ISQLCase): ISQLCoalesce;
begin
  Result := Expression(pCaseTerm.ToString());
end;

function TSQLCoalesce.Expression(const pAggregateTerm: ISQLAggregate): ISQLCoalesce;
begin
  Result := Expression(pAggregateTerm.ToString());
end;

function TSQLCoalesce.Expression(const pTerm: string): ISQLCoalesce;
begin
  FTerm := pTerm;
  Result := Self;
end;

function TSQLCoalesce.Value(const pValue: TValue): ISQLCoalesce;
begin
  Result := Value(TSQLValue.Create(pValue));
end;

function TSQLCoalesce.Value(pValue: ISQLValue): ISQLCoalesce;
begin
  FValue := pValue;
  Result := Self;
end;

{ TSQLAggregate }

function TSQLAggregate.&As(const pAlias: string): ISQLAggregate;
begin
  Result := Alias(pAlias);
end;

function TSQLAggregate.Alias(const pAlias: string): ISQLAggregate;
begin
  FAlias := pAlias;
  Result := Self;
end;

function TSQLAggregate.Avg: ISQLAggregate;
begin
  FFunction := aggAvg;
  Result := Self;
end;

function TSQLAggregate.Condition(const pOp: TSQLOperator; const pValue: TValue): ISQLAggregate;
begin
  Result := Condition(pOp, TSQLValue.Create(pValue));
end;

function TSQLAggregate.Condition(const pOp: TSQLOperator; pValue: ISQLValue): ISQLAggregate;
begin
  FOp := pOp;
  FValue := pValue;
  FIsCondition := True;
  Result := Self;
end;

function TSQLAggregate.Condition(const pOp: TSQLOperator): ISQLAggregate;
begin
  Result := Condition(pOp, nil);
end;

function TSQLAggregate.Count: ISQLAggregate;
begin
  FFunction := aggCount;
  Result := Self;
end;

function TSQLAggregate.Count(const pExpression: string): ISQLAggregate;
begin
  Result := Self.Count().Expression(pExpression);
end;

function TSQLAggregate.Count(pCoalesceExpression: ISQLCoalesce): ISQLAggregate;
begin
  Result := Self.Count().Expression(pCoalesceExpression);
end;

function TSQLAggregate.Count(pCaseTerm: ISQLCase): ISQLAggregate;
begin
  Result := Self.Count().Expression(pCaseTerm);
end;

constructor TSQLAggregate.Create;
begin
  FFunction := aggAvg;
  FTerm := EmptyStr;
  FAlias := EmptyStr;
  FIsCondition := False;
  FOp := opEqual;
  FValue := nil;
end;

function TSQLAggregate.DoToString: string;
var
  vValue: string;
begin
  case FFunction of
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

  Result := Result + '(' + FTerm + ')';

  if FIsCondition then
  begin
    vValue := FValue.ToString();
    if (vValue <> '') then
      vValue := ' ' + vValue;
    Result := Result + ' ' + SQL_OPERATOR[FOp] + vValue;
  end;

  if (FAlias <> '') then
    Result := Result + ' As ' + FAlias;
end;

function TSQLAggregate.Expression(pCaseTerm: ISQLCase): ISQLAggregate;
begin
  Result := Expression(pCaseTerm.ToString());
end;

function TSQLAggregate.Expression(pCoalesceTerm: ISQLCoalesce): ISQLAggregate;
begin
  Result := Expression(pCoalesceTerm.ToString());
end;

function TSQLAggregate.Expression(const pTerm: string): ISQLAggregate;
begin
  FTerm := pTerm;
  Result := Self;
end;

function TSQLAggregate.Avg(const pExpression: string): ISQLAggregate;
begin
  Result := Self.Avg().Expression(pExpression);
end;

function TSQLAggregate.Avg(pCoalesceExpression: ISQLCoalesce): ISQLAggregate;
begin
  Result := Self.Avg().Expression(pCoalesceExpression);
end;

function TSQLAggregate.Avg(pCaseTerm: ISQLCase): ISQLAggregate;
begin
  Result := Self.Avg().Expression(pCaseTerm);
end;

function TSQLAggregate.Max: ISQLAggregate;
begin
  FFunction := aggMax;
  Result := Self;
end;

function TSQLAggregate.Max(pCoalesceExpression: ISQLCoalesce): ISQLAggregate;
begin
  Result := Self.Max().Expression(pCoalesceExpression);
end;

function TSQLAggregate.Max(const pExpression: string): ISQLAggregate;
begin
  Result := Self.Max().Expression(pExpression);
end;

function TSQLAggregate.Max(pCaseTerm: ISQLCase): ISQLAggregate;
begin
  Result := Self.Max().Expression(pCaseTerm);
end;

function TSQLAggregate.Min: ISQLAggregate;
begin
  FFunction := aggMin;
  Result := Self;
end;

function TSQLAggregate.Min(pCoalesceExpression: ISQLCoalesce): ISQLAggregate;
begin
  Result := Self.Min().Expression(pCoalesceExpression);
end;

function TSQLAggregate.Min(const pExpression: string): ISQLAggregate;
begin
  Result := Self.Min().Expression(pExpression);
end;

function TSQLAggregate.Min(pCaseTerm: ISQLCase): ISQLAggregate;
begin
  Result := Self.Min().Expression(pCaseTerm);
end;

function TSQLAggregate.Sum: ISQLAggregate;
begin
  FFunction := aggSum;
  Result := Self;
end;

function TSQLAggregate.Sum(const pExpression: string): ISQLAggregate;
begin
  Result := Self.Sum().Expression(pExpression);
end;

function TSQLAggregate.Sum(pCoalesceExpression: ISQLCoalesce): ISQLAggregate;
begin
  Result := Self.Sum().Expression(pCoalesceExpression);
end;

function TSQLAggregate.Sum(pCaseTerm: ISQLCase): ISQLAggregate;
begin
  Result := Self.Sum().Expression(pCaseTerm);
end;

{ TSQLCase }

function TSQLCase.&Else(pDefValue: ISQLValue): ISQLCase;
begin
  FDefValue := pDefValue;
  Result := Self;
end;

function TSQLCase.&Else(const pDefValue: TValue): ISQLCase;
begin
  Result := &Else(TSQLValue.Create(pDefValue));
end;

function TSQLCase.&Else(pDefValue: ISQLAggregate): ISQLCase;
begin
  Result := &Else(TSQLValue.Create(pDefValue.ToString()).Expression);
end;

function TSQLCase.&Else(pDefValue: ISQLCoalesce): ISQLCase;
begin
  Result := &Else(TSQLValue.Create(pDefValue.ToString()).Expression);
end;

function TSQLCase.&End: ISQLCase;
begin
  Result := Self;
end;

function TSQLCase.&Then(pValue: ISQLValue): ISQLCase;
begin
  if (FCondition = nil) then
    raise ESQLBuilderException.Create('You must call the When first!');
  FPossibilities.Add(TPossibility.Create(FCondition, pValue));
  FCondition := nil;
  Result := Self;
end;

function TSQLCase.&Then(const pValue: TValue): ISQLCase;
begin
  Result := &Then(TSQLValue.Create(pValue));
end;

function TSQLCase.&Then(pValue: ISQLAggregate): ISQLCase;
begin
  Result := &Then(TSQLValue.Create(pValue.ToString()).Expression);
end;

function TSQLCase.&Then(pValue: ISQLCoalesce): ISQLCase;
begin
  Result := &Then(TSQLValue.Create(pValue.ToString()).Expression);
end;

function TSQLCase.&As(const pAlias: string): ISQLCase;
begin
  Result := Alias(pAlias);
end;

function TSQLCase.Alias(const pAlias: string): ISQLCase;
begin
  FAlias := pAlias;
  Result := Self;
end;

constructor TSQLCase.Create;
begin
  FExpression := nil;
  FDefValue := nil;
  FCondition := nil;
  FPossibilities := TObjectList<TPossibility>.Create(True);
  FAlias := EmptyStr;
end;

destructor TSQLCase.Destroy;
begin
  FreeAndNil(FPossibilities);
  inherited;
end;

function TSQLCase.DoToString: string;
var
  vSb: TStringBuilder;
  vPs: TPossibility;
  vExp: string;
begin
  Result := EmptyStr;

  vExp := EmptyStr;

  if (FExpression <> nil) and (FExpression.ToString <> '') then
    vExp := FExpression.ToString();

  vSb := TStringBuilder.Create;
  try
    vSb.Append('Case ' + vExp).AppendLine;

    for vPs in FPossibilities do
      vSb.Append('  When ' + vPs.Condition.ToString() + ' Then ' + vPs.Value.ToString()).AppendLine;

    if (FDefValue <> nil) then
      vSb.Append('  Else ' + FDefValue.ToString()).AppendLine;

    vSb.Append(' End');

    if (FAlias <> '') then
      vSb.Append(' As ' + FAlias);

    Result := vSb.ToString;
  finally
    FreeAndNil(vSb);
  end;
end;

function TSQLCase.Expression(const pTerm: string): ISQLCase;
begin
  Result := Expression(TSQLValue.Create(pTerm).Expression);
end;

function TSQLCase.Expression(pTerm: ISQLValue): ISQLCase;
begin
  FExpression := pTerm;
  Result := Self;
end;

function TSQLCase.When(pCondition: ISQLValue): ISQLCase;
begin
  FCondition := pCondition;
  Result := Self;
end;

function TSQLCase.When(const pCondition: TValue): ISQLCase;
begin
  Result := When(TSQLValue.Create(pCondition));
end;

{ TSQLCase.TPossibility }

constructor TSQLCase.TPossibility.Create(pCondition, pValue: ISQLValue);
begin
  FCondition := pCondition;
  FValue := pValue;
end;

{ SQL }

class function SQL.Aggregate: ISQLAggregate;
begin
  Result := TSQLAggregate.Create;
end;

class function SQL.Aggregate(const pFunction: TSQLAggFunction; const pExpression: string): ISQLAggregate;
begin
  Result := SQL.Aggregate;
  case pFunction of
    aggAvg:
      Result.Avg;
    aggCount:
      Result.Count;
    aggMax:
      Result.Max;
    aggMin:
      Result.Min;
    aggSum:
      Result.Sum;
  end;
  Result.Expression(pExpression);
end;

class function SQL.Aggregate(const pFunction: TSQLAggFunction; pExpression: ISQLCoalesce): ISQLAggregate;
begin
  Result := SQL.Aggregate(pFunction, pExpression.ToString());
end;

class function SQL.Coalesce(const pExpression: string; pValue: ISQLValue): ISQLCoalesce;
begin
  Result := SQL.Coalesce();
  Result.Expression(pExpression);
  Result.Value(pValue);
end;

class function SQL.Coalesce: ISQLCoalesce;
begin
  Result := TSQLCoalesce.Create;
end;

class function SQL.Coalesce(const pExpression: string; const pValue: TValue): ISQLCoalesce;
begin
  Result := SQL.Coalesce(pExpression, SQL.Value(pValue));
end;

class function SQL.Coalesce(pExpression: ISQLAggregate; const pValue: TValue): ISQLCoalesce;
begin
  Result := SQL.Coalesce(pExpression.ToString(), SQL.Value(pValue));
end;

class function SQL.Coalesce(pExpression: ISQLCase; const pValue: TValue): ISQLCoalesce;
begin
  Result := SQL.Coalesce(pExpression.ToString(), SQL.Value(pValue));
end;

class function SQL.Coalesce(pExpression: ISQLCase; pValue: ISQLValue): ISQLCoalesce;
begin
  Result := SQL.Coalesce();
  Result.Expression(pExpression);
  Result.Value(pValue);
end;

constructor SQL.Create;
begin
  raise ESQLBuilderException.Create(CanNotBeInstantiatedException);
end;

class function SQL.&Case: ISQLCase;
begin
  Result := TSQLCase.Create;
end;

class function SQL.&Case(const pExpression: string): ISQLCase;
begin
  Result := SQL.&Case(TSQLValue.Create(pExpression).Expression);
end;

class function SQL.&Case(pExpression: ISQLValue): ISQLCase;
begin
  Result := SQL.&Case();
  Result.Expression(pExpression);
end;

class function SQL.Coalesce(pExpression: ISQLAggregate; pValue: ISQLValue): ISQLCoalesce;
begin
  Result := SQL.Coalesce(pExpression.ToString(), pValue);
end;

class function SQL.Delete: ISQLDelete;
begin
  Result := TSQLDelete.Create;
end;

class function SQL.Where: ISQLWhere;
begin
  Result := TSQLWhere.Create(nil);
end;

class function SQL.Where(const pColumn: string): ISQLWhere;
begin
  Result := SQL.Where();
  Result.Column(pColumn);
end;

class function SQL.From(pTable: ISQLTable): ISQLFrom;
begin
  Result := TSQLFrom.Create(pTable);
end;

class function SQL.FullJoin(pTable: ISQLTable): ISQLJoin;
begin
  Result := TSQLJoin.Create(pTable, jtFull, EmptyStr);
end;

class function SQL.FullJoin(const pTable: string): ISQLJoin;
begin
  Result := SQL.FullJoin(SQL.Table(pTable));
end;

class function SQL.FullJoin: ISQLJoin;
begin
  Result := SQL.FullJoin(nil);
end;

class function SQL.GroupBy: ISQLGroupBy;
begin
  Result := TSQLGroupBy.Create(nil);
end;

class function SQL.GroupBy(const pColumn: string): ISQLGroupBy;
begin
  Result := SQL.GroupBy();
  Result.Column(pColumn);
end;

class function SQL.GroupBy(const pColumns: array of string): ISQLGroupBy;
begin
  Result := SQL.GroupBy();
  Result.Columns(pColumns);
end;

class function SQL.Having(pExpression: ISQLAggregate): ISQLHaving;
begin
  Result := SQL.Having();
  Result.Expression(pExpression);
end;

class function SQL.Having(pExpressions: array of ISQLAggregate): ISQLHaving;
begin
  Result := SQL.Having();
  Result.Expressions(pExpressions);
end;

class function SQL.Having: ISQLHaving;
begin
  Result := TSQLHaving.Create(nil);
end;

class function SQL.Having(const pExpression: string): ISQLHaving;
begin
  Result := SQL.Having();
  Result.Expression(pExpression);
end;

class function SQL.Having(const pExpressions: array of string): ISQLHaving;
begin
  Result := SQL.Having();
  Result.Expressions(pExpressions);
end;

class function SQL.Insert: ISQLInsert;
begin
  Result := TSQLInsert.Create;
end;

class function SQL.Join: ISQLJoin;
begin
  Result := SQL.Join(nil);
end;

class function SQL.Join(const pTable: string): ISQLJoin;
begin
  Result := SQL.Join(SQL.Table(pTable));
end;

class function SQL.Join(pTable: ISQLTable): ISQLJoin;
begin
  Result := TSQLJoin.Create(pTable, jtInner, EmptyStr);
end;

class function SQL.JoinTerm: ISQLJoinTerm;
begin
  Result := TSQLJoinTerm.Create;
end;

class function SQL.LeftJoin: ISQLJoin;
begin
  Result := SQL.LeftJoin(nil);
end;

class function SQL.LeftJoin(const pTable: string): ISQLJoin;
begin
  Result := SQL.LeftJoin(SQL.Table(pTable));
end;

class function SQL.LeftJoin(pTable: ISQLTable): ISQLJoin;
begin
  Result := TSQLJoin.Create(pTable, jtLeft, EmptyStr);
end;

class function SQL.OrderBy: ISQLOrderBy;
begin
  Result := TSQLOrderBy.Create(nil);
end;

class function SQL.OrderBy(const pColumn: string; const pSortType: TSQLSort): ISQLOrderBy;
begin
  Result := SQL.OrderBy();
  Result.Column(pColumn, pSortType);
end;

class function SQL.OrderBy(const pColumns: array of string; const pSortType: TSQLSort): ISQLOrderBy;
begin
  Result := SQL.OrderBy();
  Result.Columns(pColumns, pSortType);
end;

class function SQL.RightJoin(pTable: ISQLTable): ISQLJoin;
begin
  Result := TSQLJoin.Create(pTable, jtRight, EmptyStr);
end;

class function SQL.RightJoin(const pTable: string): ISQLJoin;
begin
  Result := SQL.RightJoin(SQL.Table(pTable));
end;

class function SQL.RightJoin: ISQLJoin;
begin
  Result := SQL.RightJoin(nil);
end;

class function SQL.Select: ISQLSelect;
begin
  Result := TSQLSelect.Create;
end;

class function SQL.Table(const pName: string): ISQLTable;
begin
  Result := TSQLTable.Create(pName);
end;

class function SQL.Update: ISQLUpdate;
begin
  Result := TSQLUpdate.Create;
end;

class function SQL.Value(const pValue: TValue): ISQLValue;
begin
  Result := TSQLValue.Create(pValue);
end;

end.
