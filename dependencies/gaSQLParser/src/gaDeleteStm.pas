{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Classes for parsing "Delete ..." statements     }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaDeleteStm;

interface

uses
  gaBasicSQLParser, gaAdvancedSQLParser, gaSQLParserHelperClasses,
  gaSQLExpressionParsers, gaSQLTableRefParsers;

type
  TDeleteStatementState = (dssNone, dssDeleteTable, dssWhereClause,
    dssStatementComplete);
  TDeleteStatementStates = set of TDeleteStatementState;

  TgaDeleteSQLStatement = class (TgaCustomSQLStatement)
  private
    FStatementState: TDeleteStatementState;
    FStatementTable: TgaSQLTable;
    FWhereClause: TgaSQLWhereExpression;
    procedure SetStatementState(const Value: TDeleteStatementState);
  protected
    procedure DoAfterStatementStateChange; override;
    procedure DoBeforeStatementStateChange(const NewStateOrd: LongInt); 
            override;
    function GetNewStatementState: TDeleteStatementState;
    function GetStatementType: TSQLStatementType; override;
    procedure ModifyStatementInNormalState(Sender: TObject; AToken: 
            TgaSQLTokenObj); override;
    procedure ParseDeleteTable(Sender: TObject; AToken: TgaSQLTokenObj);
    property StatementState: TDeleteStatementState read FStatementState write 
            SetStatementState;
  public
    constructor Create(AOwner: TgaAdvancedSQLParser); override;
    constructor CreateFromStatement(AOwner: TgaAdvancedSQLParser; AStatement: 
            TgaNoSQLStatement); override;
    destructor Destroy; override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property StatementTable: TgaSQLTable read FStatementTable;
    property WhereClause: TgaSQLWhereExpression read FWhereClause;
  end;
  
const
  DeleteAllowedNextState: array [TDeleteStatementState] of TDeleteStatementStates =
    ({dssNone} [dssDeleteTable],
     {dssDeleteTable} [dssWhereClause, dssStatementComplete],
     {dssWhereClause} [dssStatementComplete],
     {dssStatementComplete} []);

implementation

uses
  SysUtils, TypInfo, gaSQLParserConsts, gaParserVisitor;

{
**************************** TgaDeleteSQLStatement *****************************
}
constructor TgaDeleteSQLStatement.Create(AOwner: TgaAdvancedSQLParser);
begin
  inherited Create(AOwner);
  FStatementTable := TgaSQLTable.Create(Self);
  FStatementTable.IsAliasAllowed := False;
end;

constructor TgaDeleteSQLStatement.CreateFromStatement(AOwner: 
        TgaAdvancedSQLParser; AStatement: TgaNoSQLStatement);
begin
  inherited CreateFromStatement(AOwner, AStatement);
  FStatementTable := TgaSQLTable.Create(Self);
  FStatementTable.IsAliasAllowed := False;
end;

destructor TgaDeleteSQLStatement.Destroy;
begin
  FStatementTable.Free;
  FWhereClause.Free;
  inherited Destroy;
end;

procedure TgaDeleteSQLStatement.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitDeleteSQLStatement(Self);
end;

procedure TgaDeleteSQLStatement.DoAfterStatementStateChange;
begin
  inherited;
  if (StatementState > dssDeleteTable) and (FWhereClause = nil) then
  begin
    if StatementState = dssWhereClause then
    begin
      FWhereClause := TgaSQLWhereExpression.Create(Self);
      FWhereClause.ExecuteTokenAdded(Self, CurrentToken);
    end
    else begin
      CurrentSQL.Previous;
      CurrentSQL.InsertAfterCurrent(TgaSQLTokenObj.CreatePlaceHolder, True);
      FWhereClause := TgaSQLWhereExpression.Create(Self);
      FWhereClause.ParseComplete := True;
      CurrentSQL.Next;
    end;
  end;
end;

procedure TgaDeleteSQLStatement.DoBeforeStatementStateChange(const NewStateOrd: 
        LongInt);
begin
  inherited DoBeforeStatementStateChange(NewStateOrd);
  case StatementState of
    dssDeleteTable:
      StatementTable.CompleteParseAtPreviousToken;
    dssWhereClause:
      WhereClause.CompleteParseAtPreviousToken;
  end;
end;

function TgaDeleteSQLStatement.GetNewStatementState: TDeleteStatementState;
var
  TokenStr: string;
begin
  Result := StatementState;
  if IsTokenStatementTerminator(CurrentToken) then
  begin
    Result := dssStatementComplete;
    Exit;
  end;
  if not CanParseEnd then
    Exit;
  TokenStr := UpperCase(OwnerParser.TokenString);
  if OwnerParser.TokenType = stSymbol then
  begin
    if TokenStr = 'DELETE' then
      Result := dssDeleteTable
    else if TokenStr = 'WHERE' then
      Result := dssWhereClause
  end;
end;

function TgaDeleteSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := sstDelete;
end;

procedure TgaDeleteSQLStatement.ModifyStatementInNormalState(Sender: TObject; 
        AToken: TgaSQLTokenObj);
begin
  inherited;
  StatementState := GetNewStatementState;
  if InternalStatementState > 0 then
    case StatementState of
      dssNone:
        {the statement starts with comment or whitespace};
      dssDeleteTable:
        ParseDeleteTable(Sender, AToken);
      dssWhereClause:
        WhereClause.ExecuteTokenAdded(Sender, AToken);
      dssStatementComplete:
        DoStatementComplete;
      else
        raise Exception.CreateFmt(SUnknownStatementState,
          [ClassName, GetEnumName(TypeInfo(TDeleteStatementState), Ord(StatementState))]);
    end
  else
    InternalStatementState := 1;
end;

procedure TgaDeleteSQLStatement.ParseDeleteTable(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  case InternalStatementState of
    1: { delete* FROM* ....}
      case CurrentToken.TokenType of
        stComment, stDelimitier:
          ;
        stSymbol:
          if CurrentToken.TokenSymbolIs('FROM') then
            InternalStatementState := 2
          else
            StatusCode := errWrongKeywordSequence;
        else
          StatusCode := errUnexpectedTokenInStatement;
      end;
    2: { delete from *....*}
      StatementTable.ExecuteTokenAdded(Sender, AToken);
  end;
end;

procedure TgaDeleteSQLStatement.SetStatementState(const Value: 
        TDeleteStatementState);
begin
  if StatementState <> Value then
  begin
    if StatusCode = 0 then
      if Value in DeleteAllowedNextState[FStatementState] then
      begin
        DoBeforeStatementStateChange(Ord(Value));
        FStatementState := Value;
        InternalStatementState := 0;
        DoAfterStatementStateChange;
      end else
        StatusCode := errWrongKeywordSequence;
    if Value = dssStatementComplete then
    begin
      DoBeforeStatementStateChange(Ord(Value));
      FStatementState := Value;
      InternalStatementState := 0;
      DoAfterStatementStateChange;
    end;
  end;
end;

end.
