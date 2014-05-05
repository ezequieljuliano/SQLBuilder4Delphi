unit SQLBuilder4D.Parser;

interface

uses
  System.SysUtils;

type

  ESQLParserException = class(Exception);

  TSQLParserType = (prGaSQLParser);

  ISQLParser = interface
    ['{9AD11598-086C-4D73-855D-15C6EB223B8A}']
    procedure Parse(const pSQLText: string);
    function GetSQLText(): string;
  end;

  ISQLParserSelect = interface(ISQLParser)
    ['{A2A1BF73-37EC-4B32-83C7-A9F0A9B8F289}']
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
  end;

  TSQLParserFactory = class sealed
  public
    class function GetSelectInstance(const pType: TSQLParserType): ISQLParserSelect; static;
  end;

implementation

uses
  SQLBuilder4D.Parser.GaSQLParser;

{ TSQLParserFactory }

class function TSQLParserFactory.GetSelectInstance(
  const pType: TSQLParserType): ISQLParserSelect;
begin
  case pType of
    prGaSQLParser:
      Result := TGaSQLParserSelect.Create();
  else
    raise ESQLParserException.Create('Parser Type not set!');
  end;
end;

end.
