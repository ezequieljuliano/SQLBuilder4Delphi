{ ******************************************************* }
{ }
{ Advanced SQL statement parser }
{ Classes for parsing "Select ..." statements }
{ Copyright (c) 2001 - 2003 AS Gaiasoft }
{ Created by Gert Kello }
{ }
{ ******************************************************* }

unit gaSelectStm;

interface

uses
  gaAdvancedSQLParser, gaSQLParserHelperClasses, gaSQLFieldRefParsers,
  gaSQLSelectFieldParsers, gaSQLExpressionParsers, gaSQLTableRefParsers;

type
  TgaJoinType = (jtUnknown, jtInnerJoin, jtLeftOuterJoin, jtRightOuterJoin,
    jtFullOuterJoin);
  TgaJoinParseState = (jpsJoinType, jpsJoinTable, jpsOnPredicate);

  TgaJoinClause = class(TgaSQLStatementPart)
  private
    FJoinOnPredicate: TgaJoinOnPredicate;
    FJoinTable: TgaSQLTable;
    FJoinType: TgaJoinType;
    FParseState: TgaJoinParseState;
  protected
    procedure DiscardParse; override;
    procedure InitializeParse; override;
    procedure InternalSetParseComplete; override;
    procedure ParseJointType(AToken: TgaSQLTokenObj);
    procedure StartOnPredicateParse(AToken: TgaSQLTokenObj);
    property ParseState: TgaJoinParseState read FParseState write FParseState;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj);
      override;
    property JoinOnPredicate: TgaJoinOnPredicate read FJoinOnPredicate;
    property JoinTable: TgaSQLTable read FJoinTable;
    property JoinType: TgaJoinType read FJoinType;
  end;

  TgaJoinClauseList = class(TgaSQLStatementPartList)
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj);
      override;
  end;

  TSelectStatementState = (sssNone, sssFieldList, sssFromList, sssJoinClause,
    sssWhereClause, sssGroupBy, sssHavingClause, sssOrderBy, sssUnion,
    sssStatementComplete);

  TSelectStatementType = (sstSelectAll, sstSelectDistinct);

  TSelectStatementStates = set of TSelectStatementState;

  TgaSelectSQLStatement = class(TgaCustomSQLStatement)
  private
    FGroupByClause: TgaSQLGroupByList;
    FHavingClause: TgaHavingClause;
    FJoinClauses: TgaSQLStatementPartList;
    FNextUnionPart: TgaSelectSQLStatement;
    FOrderByClause: TgaSQLOrderByList;
    FSelectType: TSelectStatementType;
    FStatementFields: TgaSQLSelectFieldList;
    FStatementState: TSelectStatementState;
    FStatementTables: TgaSQLTableList;
    FWhereClause: TgaSQLWhereExpression;
    procedure SetStatementState(const Value: TSelectStatementState);
    function GetJoinClauses: TgaSQLStatementPartList;
  protected
    procedure DoAfterStatementStateChange; override;
    procedure DoBeforeStatementStateChange(const NewStateOrd: LongInt);
      override;
    function GetNewStatementState: TSelectStatementState;
    function GetStatementType: TSQLStatementType; override;
    procedure ModifyStatementInNormalState(Sender: TObject; AToken:
      TgaSQLTokenObj); override;
    procedure ParseFieldList(AToken: TgaSQLTokenObj);
    property StatementState: TSelectStatementState read FStatementState write
      SetStatementState;
  public
    constructor Create(AOwner: TgaAdvancedSQLParser); override;
    constructor CreateFromStatement(AOwner: TgaAdvancedSQLParser; AStatement:
      TgaNoSQLStatement); override;
    constructor CreateOwned(AOwnerStatement: TgaCustomSQLStatement); override;
    destructor Destroy; override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property GroupByClause: TgaSQLGroupByList read FGroupByClause;
    property HavingClause: TgaHavingClause read FHavingClause;
    property JoinCaluses: TgaSQLStatementPartList read GetJoinClauses;
    property NextUnionPart: TgaSelectSQLStatement read FNextUnionPart;
    property OrderByClause: TgaSQLOrderByList read FOrderByClause;
    property SelectType: TSelectStatementType read FSelectType;
    property StatementFields: TgaSQLSelectFieldList read FStatementFields;
    property StatementTables: TgaSQLTableList read FStatementTables;
    property WhereClause: TgaSQLWhereExpression read FWhereClause;
  end;

const
  SelectAllowedNextState: array [TSelectStatementState] of TSelectStatementStates =
    ( { sssNone } [sssFieldList],
    { sssFieldList } [sssFromList],
    { sssFromList } [sssJoinClause, sssWhereClause, sssGroupBy, sssOrderBy,
    sssUnion, sssStatementComplete],
    { sssJoinClause } [sssWhereClause, sssGroupBy, sssOrderBy, sssUnion,
    sssStatementComplete],
    { sssWhereClause } [sssGroupBy, sssOrderBy, sssUnion, sssStatementComplete],
    { sssGroupBy } [sssHavingClause, sssOrderBy, sssUnion, sssStatementComplete],
    { sssHavingClause } [sssOrderBy, sssUnion, sssStatementComplete],
    { sssOrderBy } [sssUnion, sssStatementComplete],
    { sssUnion } [sssStatementComplete],
    { sssStatementComplete } []);

implementation

uses
  SysUtils, TypInfo, gaBasicSQLParser, gaSQLParserConsts, gaParserVisitor;

{
  **************************** TgaSelectSQLStatement *****************************
}
constructor TgaSelectSQLStatement.Create(AOwner: TgaAdvancedSQLParser);
begin
  inherited Create(AOwner);
  FStatementState := sssNone;
  FStatementFields := TgaSQLSelectFieldList.Create(Self);
  FStatementTables := TgaSQLTableList.Create(Self);
end;

constructor TgaSelectSQLStatement.CreateFromStatement(AOwner:
  TgaAdvancedSQLParser; AStatement: TgaNoSQLStatement);
begin
  inherited CreateFromStatement(AOwner, AStatement);
  FStatementState := sssNone;
  FStatementFields := TgaSQLSelectFieldList.Create(Self);
  FStatementTables := TgaSQLTableList.Create(Self);
end;

constructor TgaSelectSQLStatement.CreateOwned(AOwnerStatement:
  TgaCustomSQLStatement);
begin
  inherited CreateOwned(AOwnerStatement);
  FStatementState := sssNone;
  FStatementFields := TgaSQLSelectFieldList.Create(Self);
  FStatementTables := TgaSQLTableList.Create(Self);
end;

destructor TgaSelectSQLStatement.Destroy;
begin
  FHavingClause.Free;
  FGroupByClause.Free;
  FOrderByClause.Free;
  FStatementFields.Free;
  FStatementTables.Free;
  FWhereClause.Free;
  FNextUnionPart.Free;
  FJoinClauses.Free;
  inherited Destroy;
end;

procedure TgaSelectSQLStatement.AcceptParserVisitor(Visitor:
  TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSelectSQLStatement(Self);
end;

procedure TgaSelectSQLStatement.DoAfterStatementStateChange;
begin
  inherited DoAfterStatementStateChange;
  if StatementState = sssJoinClause then
  begin
    if FJoinClauses = nil then
      FJoinClauses := TgaJoinClauseList.Create(Self, TgaJoinClause);
    // Join clause parse has to be started right now
    InternalStatementState := 1;
  end;
  if (StatementState > sssJoinClause) and (FWhereClause = nil) then
  begin
    if StatementState = sssWhereClause then
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
  if (StatementState > sssWhereClause) and (GroupByClause = nil) then
  begin
    if StatementState = sssGroupBy then
    begin
      FGroupByClause := TgaSQLGroupByList.Create(Self);
      // start parse right now
      InternalStatementState := 1;
    end
    else
    begin
      CurrentSQL.Previous;
      CurrentSQL.InsertAfterCurrent(TgaSQLTokenObj.CreatePlaceHolder, True);
      FGroupByClause := TgaSQLGroupByList.Create(Self);
      FGroupByClause.ParseComplete := True;
      CurrentSQL.Next;
    end
  end;
  if (StatementState > sssGroupBy) and (HavingClause = nil) then
  begin
    if StatementState = sssHavingClause then
    begin
      FHavingClause := TgaHavingClause.Create(Self);
      FHavingClause.ExecuteTokenAdded(Self, CurrentToken);
    end
    else
    begin
      CurrentSQL.Previous;
      CurrentSQL.InsertAfterCurrent(TgaSQLTokenObj.CreatePlaceHolder, True);
      FHavingClause := TgaHavingClause.Create(Self);
      FHavingClause.ParseComplete := True;
      CurrentSQL.Next;
    end
  end;
  if (StatementState > sssHavingClause) and (FOrderByClause = nil) then
  begin
    if StatementState = sssOrderBy then
    begin
      FOrderByClause := TgaSQLOrderByList.Create(Self);
      // start parse right now
      InternalStatementState := 1;
    end
    else
    begin
      CurrentSQL.Previous;
      CurrentSQL.InsertAfterCurrent(TgaSQLTokenObj.CreatePlaceHolder, True);
      FOrderByClause := TgaSQLOrderByList.Create(Self);
      FOrderByClause.ParseComplete := True;
      CurrentSQL.Next;
    end
  end;
  if StatementState = sssUnion then
    FNextUnionPart := TgaSelectSQLStatement.CreateOwned(Self);
end;

procedure TgaSelectSQLStatement.DoBeforeStatementStateChange(const NewStateOrd:
  LongInt);
begin
  inherited DoBeforeStatementStateChange(NewStateOrd);
  case StatementState of
    sssFieldList:
      StatementFields.CompleteParseAtPreviousToken;
    sssFromList:
      StatementTables.CompleteParseAtPreviousToken;
    sssJoinClause:
      JoinCaluses.CompleteParseAtPreviousToken;
    sssWhereClause:
      WhereClause.CompleteParseAtPreviousToken;
    sssGroupBy:
      GroupByClause.CompleteParseAtPreviousToken;
    sssHavingClause:
      HavingClause.CompleteParseAtPreviousToken;
    sssOrderBy:
      OrderByClause.CompleteParseAtPreviousToken;
  end;
end;

function TgaSelectSQLStatement.GetJoinClauses: TgaSQLStatementPartList;
begin
  if (FJoinClauses = nil) then
    FJoinClauses := TgaJoinClauseList.Create(Self, TgaJoinClause);
  Result := FJoinClauses;
end;

function TgaSelectSQLStatement.GetNewStatementState: TSelectStatementState;
var
  TokenStr: string;
begin
  (*
    SELECT [TRANSACTION transaction]
    [DISTINCT | ALL]
    {* | <val> [, <val> …]}
    [INTO : var [, : var …]]
    FROM <tableref> [, <tableref> …]
    [WHERE <search_condition>]
    [GROUP BY col [COLLATE collation] [, col [COLLATE collation] …]
    [HAVING <search_condition>]
    [UNION <select_expr> [ALL]]
    [PLAN <plan_expr>]
    [ORDER BY <order_list>]
    [FOR UPDATE [OF col [, col …]]];
  *)
  Result := StatementState;
  if IsTokenStatementTerminator(CurrentToken) then
  begin
    Result := sssStatementComplete;
    Exit;
  end;
  if (not CanParseEnd) or (StatementState = sssUnion) then
    Exit;
  TokenStr := UpperCase(CurrentToken.TokenAsString);
  if CurrentToken.TokenType = stSymbol then
  begin
    if TokenStr = 'SELECT' then
      Result := sssFieldList
    else if TokenStr = 'FROM' then
      Result := sssFromList
    else if TokenStr = 'WHERE' then
      Result := sssWhereClause
    else if TokenStr = 'GROUP' then
      Result := sssGroupBy
    else if TokenStr = 'HAVING' then
      Result := sssHavingClause
    else if TokenStr = 'ORDER' then
      Result := sssOrderBy
    else if TokenStr = 'UNION' then
      Result := sssUnion
      { Syntax of Join clause:
        LEFT | RIGHT | FULL [OUTER] JOIN table_reference
        ON predicate
        [INNER] JOIN table_reference
        ON predicate }
    else if (TokenStr = 'INNER') or (TokenStr = 'JOIN') or
      (TokenStr = 'LEFT') or (TokenStr = 'RIGHT') or (TokenStr = 'FULL') then
      Result := sssJoinClause;
  end;
end;

function TgaSelectSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := sstSelect;
end;

procedure TgaSelectSQLStatement.ModifyStatementInNormalState(Sender: TObject;
  AToken: TgaSQLTokenObj);
begin
  inherited;
  StatementState := GetNewStatementState;
  if StatusCode <> 0 then
    raise Exception.CreateFmt('Statement status code is %d', [StatusCode]);
  if InternalStatementState > 0 then
    case StatementState of
      sssNone:
        { the statement starts with comment or whitespace };
      sssFieldList:
        ParseFieldList(AToken);
      sssFromList:
        StatementTables.ExecuteTokenAdded(Sender, AToken);
      sssWhereClause:
        WhereClause.ExecuteTokenAdded(Sender, AToken);
      sssGroupBy:
        GroupByClause.ExecuteTokenAdded(Sender, AToken);
      sssHavingClause:
        HavingClause.ExecuteTokenAdded(Sender, AToken);
      sssJoinClause:
        JoinCaluses.ExecuteTokenAdded(Self, AToken);
      sssOrderBy:
        OrderByClause.ExecuteTokenAdded(Self, AToken);
      sssUnion:
        NextUnionPart.DoTokenAdded(Self, AToken);
      sssStatementComplete:
        if NextUnionPart <> nil then
          NextUnionPart.DoTokenAdded(Self, AToken);
    else
      raise Exception.CreateFmt(SUnknownStatementState,
        [ClassName, GetEnumName(TypeInfo(TSelectStatementState), Ord(StatementState))]);
    end
  else
  begin
    if StatementState = sssStatementComplete then
    begin
      if NextUnionPart <> nil then
        NextUnionPart.DoTokenAdded(Self, AToken);
      DoStatementComplete;
    end;
    InternalStatementState := 1;
  end;
end;

procedure TgaSelectSQLStatement.ParseFieldList(AToken: TgaSQLTokenObj);
begin
  if InternalStatementState = 1 then
  begin
    if AToken.TokenType in [stDelimitier, stComment] then
      // continue
    else
    begin
      if AToken.TokenSymbolIs('ALL') then
        FSelectType := sstSelectAll
      else if AToken.TokenSymbolIs('DISTINCT') then
        FSelectType := sstSelectDistinct
      else
      begin
        StatementFields.ExecuteTokenAdded(Self, AToken);
        InternalStatementState := 2;
      end;
    end;
  end
  else
    StatementFields.ExecuteTokenAdded(Self, AToken);
end;

procedure TgaSelectSQLStatement.SetStatementState(const Value:
  TSelectStatementState);
begin
  if StatementState <> Value then
  begin
    if StatusCode = 0 then
      if Value in SelectAllowedNextState[FStatementState] then
      begin
        DoBeforeStatementStateChange(Ord(Value));
        FStatementState := Value;
        InternalStatementState := 0;
        DoAfterStatementStateChange;
      end
      else
        StatusCode := errWrongKeywordSequence;
    if Value = sssStatementComplete then
    begin
      DoBeforeStatementStateChange(Ord(Value));
      FStatementState := Value;
      InternalStatementState := 0;
      DoAfterStatementStateChange;
    end;
  end;
end;

{
  ******************************** TgaJoinClause *********************************
}
procedure TgaJoinClause.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitJoinClause(Self);
end;

procedure TgaJoinClause.DiscardParse;
begin
  FJoinOnPredicate.Free;
  FJoinTable.Free;
  inherited;
end;

procedure TgaJoinClause.ExecuteTokenAdded(Sender: TObject; AToken:
  TgaSQLTokenObj);
begin
  inherited ExecuteTokenAdded(Sender, AToken);
  case ParseState of
    jpsJoinType:
      ParseJointType(AToken);
    jpsJoinTable:
      begin
        if AToken.TokenSymbolIs('ON') or JoinTable.ParseComplete then
          StartOnPredicateParse(AToken)
        else
          JoinTable.ExecuteTokenAdded(Self, AToken);
      end;
    jpsOnPredicate:
      begin
        if not JoinOnPredicate.ParseComplete then
          JoinOnPredicate.ExecuteTokenAdded(Self, AToken);
        if JoinOnPredicate.ParseComplete then
          ParseComplete := True;
      end;
  end;
end;

procedure TgaJoinClause.InitializeParse;
begin
  inherited InitializeParse;
  FJoinType := jtUnknown;
  FParseState := jpsJoinType;
  FJoinOnPredicate := TgaJoinOnPredicate.Create(OwnerStatement);
  FJoinTable := TgaSQLTable.Create(OwnerStatement);
end;

procedure TgaJoinClause.InternalSetParseComplete;
begin
  JoinOnPredicate.ParseComplete := True;
  inherited InternalSetParseComplete;
end;

procedure TgaJoinClause.ParseJointType(AToken: TgaSQLTokenObj);
begin
  { Syntax of Join clause:
    LEFT | RIGHT | FULL [OUTER] JOIN table_reference
    ON predicate
    [INNER] JOIN table_reference
    ON predicate }
  if AToken.TokenType in [stDelimitier, stComment] then
    Exit;
  case JoinType of
    jtUnknown:
      begin
        if AToken.TokenSymbolIs('INNER') or AToken.TokenSymbolIs('JOIN') then
          FJoinType := jtInnerJoin
        else if AToken.TokenSymbolIs('LEFT') then
          FJoinType := jtLeftOuterJoin
        else if AToken.TokenSymbolIs('RIGHT') then
          FJoinType := jtRightOuterJoin
        else if AToken.TokenSymbolIs('FULL') then
          FJoinType := jtFullOuterJoin
        else
          IsInvalid := True;
      end;
    jtInnerJoin:
      if not AToken.TokenSymbolIs('JOIN') then
        IsInvalid := True;
  else
    if not(AToken.TokenSymbolIs('JOIN') or AToken.TokenSymbolIs('OUTER')) then
      IsInvalid := True;
  end;
  if not IsInvalid then
    if AToken.TokenSymbolIs('JOIN') then
      ParseState := jpsJoinTable;
end;

procedure TgaJoinClause.StartOnPredicateParse(AToken: TgaSQLTokenObj);
begin
  JoinTable.ParseComplete := True;
  ParseState := jpsOnPredicate;
  JoinOnPredicate.ExecuteTokenAdded(Self, AToken);
end;

{
  ****************************** TgaJoinClauseList *******************************
}
procedure TgaJoinClauseList.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitJoinClauseList(Self);
end;

procedure TgaJoinClauseList.ExecuteTokenAdded(Sender: TObject; AToken:
  TgaSQLTokenObj);
var
  TokenStr: string;
begin
  if FCurrentPart <> nil then
  begin
    TokenStr := UpperCase(AToken.TokenString);
    if (AToken.TokenType = stSymbol) and
      (TgaJoinClause(FCurrentPart).ParseState > jpsJoinType) then
      if (TokenStr = 'INNER') or (TokenStr = 'JOIN') or
        (TokenStr = 'LEFT') or (TokenStr = 'RIGHT') or (TokenStr = 'FULL') then
      begin
        FCurrentPart.ParseComplete := True;
        FCurrentPart := nil;
      end;
  end;
  inherited ExecuteTokenAdded(Sender, AToken);
end;

end.
