unit SQLBuilder4D.Parser;

interface

uses
  System.SysUtils;

type

  ESQLParserException = class(Exception);

  TSQLParserConnector = (pcNone, pcAnd, pcOr, pcComma);

  ISQLParser = interface
    ['{97130BFD-BB82-4BB5-9A5D-341993D33128}']
    procedure Parse(const pSQLCommand: string);
    function ToString(): string;
  end;

  ISQLParserSelect = interface(ISQLParser)
    ['{359F150F-CF2E-44EA-8D4C-83DEED93CD52}']
    function GetColumns(): string;
    function GetFrom(): string;
    function GetJoin(): string;
    function GetWhere(): string;
    function GetGroupBy(): string;
    function GetHaving(): string;
    function GetOrderBy(): string;

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

implementation

end.
