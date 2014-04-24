{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Classes for parsing "Insert ..." statements     }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaInsertStm;

interface

uses
  gaAdvancedSQLParser, gaSQLParserHelperClasses, gaSQLFieldRefParsers,
  gaSQLExpressionParsers, gaSQLTableRefParsers;

type
  TInsertStatementState = (issNone, issInsertInto, issInsertTable,
    issColumnList, issAfterColumnList, issInsertValues, issAfterInsertValues,
    issInsertSelect,
    issStatementComplete);
  TInsertStatementStateS = set of TInsertStatementState;

  TgaInsertSQLStatement = class (TgaCustomSQLStatement)
  private
    FInsertFields: TgaSQLFieldList;
    FInsertValues: TgaSQLExpressionList;
    FSelectStm: TgaCustomSQLStatement;
    FStatementState: TInsertStatementState;
    FStatementTable: TgaSQLTable;
    procedure SetStatementState(Value: TInsertStatementState);
  protected
    procedure DoAfterStatementStateChange; override;
    procedure DoBeforeStatementStateChange(const NewStateOrd: LongInt); 
            override;
    function GetNewStatementState: TInsertStatementState;
    function GetStatementType: TSQLStatementType; override;
    procedure ModifyStatementInNormalState(Sender: TObject; AToken: 
            TgaSQLTokenObj); override;
  public
    constructor Create(AOwner: TgaAdvancedSQLParser); override;
    constructor CreateFromStatement(AOwner: TgaAdvancedSQLParser; AStatement: 
            TgaNoSQLStatement); override;
    destructor Destroy; override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property InsertFields: TgaSQLFieldList read FInsertFields;
    property InsertValues: TgaSQLExpressionList read FInsertValues;
    property SelectStm: TgaCustomSQLStatement read FSelectStm;
    property StatementState: TInsertStatementState read FStatementState write 
            SetStatementState;
    property StatementTable: TgaSQLTable read FStatementTable;
  end;
  

implementation

uses
  SysUtils, gaBasicSQLParser, gaSQLParserConsts, TypInfo, gaParserVisitor;

const
  InsertAllowedNextState: array[TInsertStatementState] of TInsertStatementStates = (
    {issNone} [issInsertInto],
    {issInsertInto} [issInsertTable],
    {issInsertTable} [issColumnList, issInsertValues, issInsertSelect],
    {issColumnList} [issAfterColumnList],
    {issAfterColumnList} [issInsertValues, issInsertSelect],
    {issInsertValues} [issAfterInsertValues],
    {issAfterInsertValues} [issStatementComplete],
    {issInsertSelect} [issStatementComplete],
    {issStatementComplete} []
    );

{
**************************** TgaInsertSQLStatement *****************************
}
constructor TgaInsertSQLStatement.Create(AOwner: TgaAdvancedSQLParser);
begin
  inherited Create(AOwner);
  FStatementTable := TgaSQLTable.Create(Self);
  FStatementTable.IsAliasAllowed := False;
end;

constructor TgaInsertSQLStatement.CreateFromStatement(AOwner: 
        TgaAdvancedSQLParser; AStatement: TgaNoSQLStatement);
begin
  inherited CreateFromStatement(AOwner, AStatement);
  FStatementTable := TgaSQLTable.Create(Self);
  FStatementTable.IsAliasAllowed := False;
end;

destructor TgaInsertSQLStatement.Destroy;
begin
  FInsertFields.Free;
  FInsertValues.Free;
  FStatementTable.Free;
  FSelectStm.Free;
  inherited Destroy;
end;

procedure TgaInsertSQLStatement.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitInsertSQLStatement(Self);
end;

procedure TgaInsertSQLStatement.DoAfterStatementStateChange;
begin
  inherited DoAfterStatementStateChange;
  if StatementState = issInsertSelect then
  begin
    FSelectStm := OwnerParser.GetStatementClassForToken('SELECT').CreateOwned(Self);
    SelectStm.DoTokenAdded(Self, CurrentToken);
  end;
end;

procedure TgaInsertSQLStatement.DoBeforeStatementStateChange(const NewStateOrd: 
        LongInt);
begin
  inherited;
  case StatementState of
    issInsertTable:
      StatementTable.CompleteParseAtPreviousToken;
    issColumnList:
      InsertFields.CompleteParseAtPreviousToken;
    issInsertValues:
      InsertValues.CompleteParseAtPreviousToken;
    issInsertSelect:
      SelectStm.FinishSubStatement;
  end;
end;

function TgaInsertSQLStatement.GetNewStatementState: TInsertStatementState;
var
  TokenStr: string;
begin
  (*
  INSERT [TRANSACTION transaction] INTO <object> [( col [, col …])]
  {VALUES ( <val> [, <val> …]) | <select_expr>};
  <object> = tablename | viewname
  <val> = {: variable | <constant> | <expr>
  | <function> | udf ([ <val> [, <val> …]])
  | NULL | USER | RDB$DB_KEY | ?
  } [COLLATE collation]
  <constant> = num | ' string' | charsetname ' string'
  <function> = CAST ( <val> AS < datatype>)
  | UPPER ( <val>)
  | GEN_ID ( generator, <val>)
  *)
  Result := StatementState;
  if IsTokenStatementTerminator(CurrentToken) then
  begin
    Result := issStatementComplete;
    Exit;
  end;
  if not CanParseEnd then
    Exit;
  TokenStr := UpperCase(OwnerParser.TokenString);
  case OwnerParser.TokenType of
    stSymbol: begin
      if TokenStr = 'INSERT' then
        Result := issInsertInto
      else if TokenStr = 'INTO' then
        Result := issInsertTable
      else if TokenStr = 'VALUES' then
        Result := issInsertValues
      else if TokenStr = 'SELECT' then
        Result := issInsertSelect;
    end;
    stLParen:
      if StatementState = issInsertTable then
        Result := issColumnList;
    stRParen:
      if StatementState = issColumnList then
        Result := issAfterColumnList;
  end;
end;

function TgaInsertSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := sstInsert;
end;

procedure TgaInsertSQLStatement.ModifyStatementInNormalState(Sender: TObject; 
        AToken: TgaSQLTokenObj);
begin
  inherited;
  StatementState := GetNewStatementState;
  if InternalStatementState > 0 then
    case StatementState of
      issNone:
          { the statement starts with comment or whitespace };
      issInsertInto:
          { waiting for 'INTO' keyword }
        if not (AToken.TokenType in [stDelimitier, stComment]) then
          StatusCode := errWrongKeywordSequence;
      issInsertTable:
        if StatementTable.ParseComplete then
        begin
          if not (AToken.TokenType in [stDelimitier, stComment]) then
            raise EgaSQLInvalidParseState.CreateFmt('Waiting for insert column list/insert values but %s found', [AToken.TokenAsString]);
        end
        else if (not StatementTable.ParseStarted) and (AToken.TokenType in [stDelimitier, stComment]) then
          // skip delimitiers
        else
          StatementTable.ExecuteTokenAdded(Sender, AToken);
      issColumnList: begin
        if InternalStatementState = 1 then
        begin
          FInsertFields := TgaSQLFieldList.Create(Self);
          InternalStatementState := 2;
        end;
        InsertFields.ExecuteTokenAdded(Sender, AToken);
      end;
      issAfterColumnList:
          { Do nothing as select or values should follow};
      issInsertValues: begin
        if InternalStatementState = 1 then
        begin
          FInsertValues := TgaSQLExpressionList.Create(Self);
          FInsertValues.ParenEnclosedList := True;
          InternalStatementState := 2;
        end;
        InsertValues.ExecuteTokenAdded(Sender, AToken);
        if InsertValues.ParseComplete then
          StatementState := issAfterInsertValues;
      end;
      issInsertSelect:
        SelectStm.DoTokenAdded(Self, AToken);
      issStatementComplete:
        DoStatementComplete;
      else
        raise Exception.CreateFmt(SUnknownStatementState,
          [ClassName, GetEnumName(TypeInfo(TInsertStatementState), Ord(StatementState))]);
    end
  else
    InternalStatementState := 1;
end;

procedure TgaInsertSQLStatement.SetStatementState(Value: TInsertStatementState);
begin
  if StatementState <> Value then
  begin
    if StatusCode = 0 then
      if Value in InsertAllowedNextState[FStatementState] then
      begin
        DoBeforeStatementStateChange(Ord(Value));
        FStatementState := Value;
        InternalStatementState := 0;
        DoAfterStatementStateChange;
      end else
        StatusCode := errWrongKeywordSequence;
    if Value = issStatementComplete then
    begin
      DoBeforeStatementStateChange(Ord(Value));
      FStatementState := Value;
      InternalStatementState := 0;
      DoAfterStatementStateChange;
    end;
  end;
end;

end.
