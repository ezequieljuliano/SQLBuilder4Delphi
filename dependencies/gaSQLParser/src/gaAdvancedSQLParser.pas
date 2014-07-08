{ ******************************************************* }
{ }
{ Advanced SQL statement parser }
{ Copyright (c) 2001 - 2004 AS Gaiasoft }
{ Created by Gert Kello }
{ }
{ ******************************************************* }

unit gaAdvancedSQLParser;

interface

uses
  Classes, gaBasicSQLParser, gaLnkList, SysUtils, System.Types;

type
  EgaSQLParserException = class(Exception)
  end;

  EgaSQLInvalidParseState = class(EgaSQLParserException)
  end;

  TSQLStatementType = (sstSelect, sstInsert, sstUpdate, sstDelete,
    sstCreate, sstAlter, sstDrop, sstUnknown, sstNoStatementFound);

  TSQLStatementTypes = set of TSQLStatementType;

  TgaCustomSQLStatement = class;

  TgaParserVisitorBase = class(TObject)
  end;

  TgaSQLTokenObj = class(TObject)
  private
    FEndQuote: Char;
    FStartQuote: Char;
    FTokenQuoted: Boolean;
    FTokenString: string;
    FTokenType: TSQLToken;
    function GetTokenAsString: string;
  public
    procedure AssignTokenInfo(ASQLParser: TgaBasicSQLParser);
    class function CreateDelimitier: TgaSQLTokenObj;
    class function CreatePlaceHolder: TgaSQLTokenObj;
    class function CreateSubStatementEnd: TgaSQLTokenObj;
    procedure SetTokenInfo(const AString: string; ATokenType: TSQLToken;
      AQuoted: Boolean; AStartQuote, AEndQuote: char);
    function TokenSymbolIs(const S: string): Boolean;
    property EndQuote: Char read FEndQuote;
    property StartQuote: Char read FStartQuote;
    property TokenAsString: string read GetTokenAsString;
    property TokenQuoted: Boolean read FTokenQuoted;
    property TokenString: string read FTokenString;
    property TokenType: TSQLToken read FTokenType;
  end;

  TgaTokenEvent = procedure(Sender: TObject; AToken: TgaSQLTokenObj) of object;

  TgaSQLTokenListBookmark = class(TgaDoubleListBookmark)
  private
    function GetTokenObj: TgaSQLTokenObj;
    procedure SetTokenObj(Value: TgaSQLTokenObj);
  public
    property TokenObj: TgaSQLTokenObj read GetTokenObj write SetTokenObj;
  end;

  TgaSQLTokenList = class(TgaSharedDoubleList)
  private
    FOwnerStatement: TgaCustomSQLStatement;
    function GetLastItem: TgaSQLTokenObj;
  protected
    procedure GetAllTokens(ATokenList: TgaSQLTokenList);
    function GetAsString: string; virtual;
    function GetCurrentItem: TgaSQLTokenObj; reintroduce; virtual;
    function GetTokenObjAsString(ATokenObj: TgaSQLTokenObj): string;
    procedure SetAsString(const Value: string); virtual;
    procedure SetCurrentItem(Value: TgaSQLTokenObj); reintroduce; virtual;
    property OwnerStatement: TgaCustomSQLStatement read FOwnerStatement;
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement); virtual;
    constructor CreateMirror(AOwnerStatement: TgaCustomSQLStatement;
      AMirroredList: TgaSQLTokenList); virtual;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); virtual;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj);
      virtual;
    function GetBookmark: TgaSQLTokenListBookmark; reintroduce; virtual;
    property AsString: string read GetAsString write SetAsString;
    property CurrentItem: TgaSQLTokenObj read GetCurrentItem write
      SetCurrentItem;
    property LastItem: TgaSQLTokenObj read GetLastItem;
  end;

  TgaAdvancedSQLParser = class;

  TgaListOfSQLTokenListsBookmark = class(TgaDoubleListBookmark)
  private
    function GetTokenList: TgaSQLTokenList;
    procedure SetTokenList(Value: TgaSQLTokenList);
  public
    property TokenList: TgaSQLTokenList read GetTokenList write SetTokenList;
  end;

  TgaListOfSQLTokenLists = class(TgaSharedDoubleList)
  private
    FOwnsLists: Boolean;
  protected
    procedure GetAllTokens(ATokenList: TgaSQLTokenList);
    function GetAsString: string; virtual;
    function GetCurrentItem: TgaSQLTokenList; reintroduce; virtual;
    function GetLastItem: TgaSQLTokenList; reintroduce; virtual;
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    constructor Create;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); virtual;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj);
      virtual;
    function GetBookmark: TgaListOfSQLTokenListsBookmark; reintroduce; virtual;
    property AsString: string read GetAsString;
    property CurrentItem: TgaSQLTokenList read GetCurrentItem;
    property LastItem: TgaSQLTokenList read GetLastItem;
    property OwnsLists: Boolean read FOwnsLists write FOwnsLists;
  end;

  TgaSQLSTatementClass = class of TgaCustomSQLStatement;

  TgaSQLTokenHolderList = class(TgaSQLTokenList)
  private
    FOwnsAll: Boolean;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure AddToken(AToken: TgaSQLTokenObj);
    function NewToken: TgaSQLTokenObj; virtual;
    procedure SetOwner(AOwner: TgaCustomSQLStatement);
    property OwnsAll: Boolean read FOwnsAll write FOwnsAll;
  end;

  TgaNoSQLStatement = class;

  TgaSQLStatementPart = class(TgaSQLTokenList)
  private
    FIsInvalid: Boolean;
    FParseComplete: Boolean;
    FParseStarted: Boolean;
    procedure SetParseComplete(const Value: Boolean);
  protected
    procedure CheckModifyAllowed; virtual;
    procedure DiscardParse; virtual;
    function GetCanParseEnd: Boolean; virtual;
    procedure InitializeParse; virtual;
    procedure InternalSetParseComplete; virtual;
    procedure InternalStartParse; virtual;
    function InvalidTokenFmtStr(AToken: TgaSQLTokenObj): string; virtual;
    function IsValidMidparseToken(AToken: TgaSQLTokenObj): Boolean; virtual;
    function IsValidStartToken(AToken: TgaSQLTokenObj): Boolean; virtual;
    procedure SetAsString(const Value: string); override;
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement); override;
    constructor CreateMirror(AOwnerStatement: TgaCustomSQLStatement;
      AMirroredList: TgaSQLTokenList); override;
    destructor Destroy; override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure CheckTokenValid(AToken: TgaSQLTokenObj);
    procedure CompleteParseAtPreviousToken; virtual;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj);
      override;
    function IsTokenValid(AToken: TgaSQLTokenObj): Boolean;
    procedure RestartParse;
    property CanParseEnd: Boolean read GetCanParseEnd;
    property IsInvalid: Boolean read FIsInvalid write FIsInvalid;
    property ParseComplete: Boolean read FParseComplete write SetParseComplete;
    property ParseStarted: Boolean read FParseStarted;
  end;

  EgaSQLInvalidTokenEncountered = class(EgaSQLParserException)
  private
    FStatementPart: TgaSQLStatementPart;
    FToken: TgaSQLTokenObj;
  public
    constructor Create(AStatementPart: TgaSQLStatementPart; AToken:
      TgaSQLTokenObj);
    property StatementPart: TgaSQLStatementPart read FStatementPart;
    property Token: TgaSQLTokenObj read FToken;
  end;

  TgaCustomSQLStatement = class(TObject)
  private
    FAllFieldReferences: TgaListOfSQLTokenLists;
    FAllFields: TgaListOfSQLTokenLists;
    FAllTables: TgaListOfSQLTokenLists;
    FCurrentSQL: TgaSQLTokenHolderList;
    FCurrentToken: TgaSQLTokenObj;
    FInternalStatementState: Integer;
    FOriginalSQL: TgaSQLTokenHolderList;
    FOwnerParser: TgaAdvancedSQLParser;
    FOwnerStm: TgaCustomSQLStatement;
    FStatementPartStack: TList;
    FStatusCode: Integer;
    function GetTopStatementPart: TgaSQLStatementPart;
  protected
    procedure DoAfterStatementStateChange; virtual;
    procedure DoBeforeStatementStateChange(const NewStateOrd: LongInt); virtual;
    procedure DoStatementComplete; virtual;
    function GetAsString: string; virtual;
    function GetStatementType: TSQLStatementType; virtual; abstract;
    function IsTokenStatementTerminator(AToken: TgaSQLTokenObj): Boolean;
      virtual;
    procedure ModifyStatementInErrorState(Sender: TObject; AToken:
      TgaSQLTokenObj); virtual;
    procedure ModifyStatementInNormalState(Sender: TObject; AToken:
      TgaSQLTokenObj); virtual;
    procedure RemoveTopStatementPart(AStamentPart: TgaSQLStatementPart);
      virtual;
    procedure SetTopStatementPart(AStamentPart: TgaSQLStatementPart); virtual;
    property CurrentToken: TgaSQLTokenObj read FCurrentToken write
      FCurrentToken;
    property InternalStatementState: Integer read FInternalStatementState write
      FInternalStatementState;
    property OriginalSQL: TgaSQLTokenHolderList read FOriginalSQL;
    property OwnerParser: TgaAdvancedSQLParser read FOwnerParser;
    property OwnerStm: TgaCustomSQLStatement read FOwnerStm;
  public
    constructor Create(AOwner: TgaAdvancedSQLParser); virtual;
    constructor CreateFromStatement(AOwner: TgaAdvancedSQLParser; AStatement:
      TgaNoSQLStatement); virtual;
    constructor CreateOwned(AOwnerStatement: TgaCustomSQLStatement); virtual;
    destructor Destroy; override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); virtual;
    procedure AddField(AField: TgaSQLTokenList);
    procedure AddFieldReference(AField: TgaSQLTokenList);
    procedure AddTable(ATable: TgaSQLTokenList);
    function CanParseEnd: Boolean; virtual;
    procedure Clear; virtual;
    procedure DoTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); virtual;
    procedure DoTokenParsed;
    procedure FinishSubStatement;
    function IsTokenOperator(AToken: TgaSQLTokenObj): Boolean;
    procedure ReleaseOwnedItems;
    procedure RemoveField(AField: TgaSQLTokenList);
    procedure RemoveFieldReference(AField: TgaSQLTokenList);
    procedure RemoveTable(ATable: TgaSQLTokenList);
    property AllFieldReferences: TgaListOfSQLTokenLists read
      FAllFieldReferences;
    property AllFields: TgaListOfSQLTokenLists read FAllFields;
    property AllTables: TgaListOfSQLTokenLists read FAllTables;
    property AsString: string read GetAsString;
    property CurrentSQL: TgaSQLTokenHolderList read FCurrentSQL;
    property StatementType: TSQLStatementType read GetStatementType;
    property StatusCode: Integer read FStatusCode write FStatusCode;
    property TopStatementPart: TgaSQLStatementPart read GetTopStatementPart;
  end;

  TgaNoSQLStatement = class(TgaCustomSQLStatement)
  protected
    function GetStatementType: TSQLStatementType; override;
    procedure ModifyStatementInNormalState(Sender: TObject; AToken:
      TgaSQLTokenObj); override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;

  TgaAdvancedSQLParser = class(TgaBasicSQLParser)
  private
    FCurrentStatement: TgaCustomSQLStatement;
    FOnStatementComplete: TNotifyEvent;
    FOperatorSymbolList: TStrings;
    function GetCurrentStatement: TgaCustomSQLStatement;
    procedure SetOperatorSymbolList(const Value: TStrings);
  protected
    procedure DoStatementComplete; virtual;
    procedure DoTokenParsed; override;
    procedure FillOperatorList;
    procedure SetCurrentStatement(AStatement: TgaCustomSQLStatement);
    property OperatorSymbolList: TStrings read FOperatorSymbolList write
      SetOperatorSymbolList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class function AddStatementClass(const ATokenSymbol: string;
      AStatementClass: TgaSQLSTatementClass): Integer;
    function GetStatementClass: TgaSQLSTatementClass;
    class function GetStatementClassForToken(const ATokenSymbol: string):
      TgaSQLSTatementClass;
    function IsTokenOperator(AToken: TgaSQLTokenObj): Boolean;
    class procedure RemoveStatementClass(const ATokenSymbol: string;
      AStatementClass: TgaSQLSTatementClass);
    procedure Reset; override;
    property CurrentStatement: TgaCustomSQLStatement read GetCurrentStatement;
    property OnStatementComplete: TNotifyEvent read FOnStatementComplete write
      FOnStatementComplete;
  end;

  TgaUnkownSQLStatement = class(TgaCustomSQLStatement)
  protected
    function GetStatementType: TSQLStatementType; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;

const
  DMLStatementTypes = [sstSelect, sstInsert, sstUpdate, sstDelete];
  DDLStatementTypes = [sstCreate, sstAlter, sstDrop];

  errWrongKeywordSequence = $101;
  errUnexpectedTokenInStatement = $102;

procedure TrimTokenList(ATokenList: TgaSQLTokenList;
  const FreeRemovedTokens: boolean;
  TrimmedTokenTypes: TSQLTokenTypes = [stDelimitier, stEnd]);

implementation

uses
  gaSelectStm, gaUpdateStm, gaDeleteStm, gaInsertStm,
  gaSQLParserConsts, gaParserVisitor, gaSQLParserHelperClasses;

var
  StatementClassList: TStrings;

procedure TrimTokenList(ATokenList: TgaSQLTokenList;
  const FreeRemovedTokens: boolean;
  TrimmedTokenTypes: TSQLTokenTypes = [stDelimitier, stEnd]);
begin
  ATokenList.First;
  while (not ATokenList.Eof) and (ATokenList.CurrentItem.TokenType in TrimmedTokenTypes) do
  begin
    if FreeRemovedTokens then
      ATokenList.CurrentItem.Free;
    ATokenList.DeleteCurrent;
  end;
  ATokenList.Last;
  while (not ATokenList.Bof) and (ATokenList.CurrentItem.TokenType in TrimmedTokenTypes) do
  begin
    if FreeRemovedTokens then
      ATokenList.CurrentItem.Free;
    ATokenList.DeleteCurrent;
    ATokenList.Previous;
  end;
end;

{
  **************************** TgaListOfSQLTokenLists ****************************
}
constructor TgaListOfSQLTokenLists.Create;
begin
  inherited;
  FOwnsLists := True;
end;

procedure TgaListOfSQLTokenLists.AcceptParserVisitor(Visitor:
  TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitListOfSQLTokenLists(Self);
end;

procedure TgaListOfSQLTokenLists.ExecuteTokenAdded(Sender: TObject; AToken:
  TgaSQLTokenObj);
begin
    ; // Do nothing here
end;

procedure TgaListOfSQLTokenLists.GetAllTokens(ATokenList: TgaSQLTokenList);
var
  AItem: TgaSQLTokenList;
begin
  ATokenList.Clear;
  First;
  while not Eof do
  begin
    AItem := CurrentItem;
    AItem.First;
    while not AItem.Eof do
    begin
      ATokenList.Add(AItem.CurrentItem);
      AItem.Next;
    end;
    Next;
  end;
end;

function TgaListOfSQLTokenLists.GetAsString: string;
begin
  Result := '';
  First;
  while not Eof do
  begin
    Result := Result + CurrentItem.AsString;
    Next;
  end;
end;

function TgaListOfSQLTokenLists.GetBookmark: TgaListOfSQLTokenListsBookmark;
begin
  Result := TgaListOfSQLTokenListsBookmark.Create(Self, Cursor);
end;

function TgaListOfSQLTokenLists.GetCurrentItem: TgaSQLTokenList;
begin
  Result := TgaSQLTokenList(inherited CurrentItem);
end;

function TgaListOfSQLTokenLists.GetLastItem: TgaSQLTokenList;
begin
  Result := TgaSQLTokenList(inherited LastItem);
end;

procedure TgaListOfSQLTokenLists.Notify(Ptr: Pointer; Action:
  TListNotification);
begin
  if OwnsLists then
    if Action = lnDeleted then
      TObject(Ptr).Free;
  inherited;
end;

{
  **************************** TgaSQLTokenHolderList *****************************
}
procedure TgaSQLTokenHolderList.AcceptParserVisitor(Visitor:
  TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLTokenHolderList(Self);
end;

procedure TgaSQLTokenHolderList.AddToken(AToken: TgaSQLTokenObj);
begin
  Add(AToken);
  Last;
end;

function TgaSQLTokenHolderList.NewToken: TgaSQLTokenObj;
begin
  Result := TgaSQLTokenObj.Create;
  AddToken(Result);
end;

procedure TgaSQLTokenHolderList.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
    if OwnsAll then
      TgaSQLTokenObj(Ptr).Free;
  inherited Notify(Ptr, Action);
end;

procedure TgaSQLTokenHolderList.SetOwner(AOwner: TgaCustomSQLStatement);
begin
  FOwnerStatement := AOwner;
end;

{
  ****************************** TgaNoSQLStatement *******************************
}
procedure TgaNoSQLStatement.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitNoSQLStatement(Self);
end;

function TgaNoSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := sstNoStatementFound;
end;

procedure TgaNoSQLStatement.ModifyStatementInNormalState(Sender: TObject;
  AToken: TgaSQLTokenObj);
var
  tmpSQLStatement: TgaCustomSQLStatement;
begin
  if OwnerParser.GetStatementClass <> TgaNoSQLStatement then
  begin
    tmpSQLStatement := OwnerParser.GetStatementClass.CreateFromStatement(OwnerParser, Self);
    OwnerParser.SetCurrentStatement(tmpSQLStatement);
    tmpSQLStatement.ModifyStatementInNormalState(Sender, AToken);
    Self.Free;
  end
  else
    inherited;
end;

{
  ***************************** TgaSQLStatementPart ******************************
}
constructor TgaSQLStatementPart.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  if AOwnerStatement = nil then
    raise Exception.Create(SerrStmPartWithoutStm);
  inherited CreateMirror(AOwnerStatement, AOwnerStatement.CurrentSQL);
  InitializeParse;
end;

constructor TgaSQLStatementPart.CreateMirror(AOwnerStatement:
  TgaCustomSQLStatement; AMirroredList: TgaSQLTokenList);
begin
  if AOwnerStatement = nil then
    raise Exception.Create(SerrStmPartWithoutStm);
  inherited CreateMirror(AOwnerStatement, AMirroredList);
  InitializeParse;
end;

destructor TgaSQLStatementPart.Destroy;
begin
  DiscardParse;
  inherited Destroy;
end;

procedure TgaSQLStatementPart.AcceptParserVisitor(Visitor:
  TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLStatementPart(Self);
end;

procedure TgaSQLStatementPart.CheckModifyAllowed;
begin
  if OwnerStatement = nil then
    raise Exception.Create(SerrNowOwnerParser)
end;

procedure TgaSQLStatementPart.CheckTokenValid(AToken: TgaSQLTokenObj);
begin
  if not IsTokenValid(AToken) then
    raise EgaSQLInvalidTokenEncountered.Create(Self, AToken);
end;

procedure TgaSQLStatementPart.CompleteParseAtPreviousToken;
begin
  Last;
  Previous;
  ParseComplete := True;
end;

procedure TgaSQLStatementPart.DiscardParse;
begin
  if ParseStarted and (not ParseComplete) and (OwnerStatement <> nil) then
    OwnerStatement.FStatementPartStack.Remove(Self);
end;

procedure TgaSQLStatementPart.ExecuteTokenAdded(Sender: TObject; AToken:
  TgaSQLTokenObj);
begin
  if IsInvalid then
    raise EgaSQLInvalidParseState.CreateFmt(SerrStmPartParseInvalid, [ClassName]);
  if ParseComplete then
    raise EgaSQLInvalidParseState.CreateFmt(SerrStmPartParseFinised, [ClassName]);
  CheckTokenValid(AToken);
  inherited;
  if not FParseStarted then
    InternalStartParse;
end;

function TgaSQLStatementPart.GetCanParseEnd: Boolean;
begin
  Result := True;
end;

procedure TgaSQLStatementPart.InitializeParse;
begin
  SetStartPos(OwnerStatement.CurrentSQL, True);
  SetEndPos(OwnerStatement.CurrentSQL, False);
  FIsInvalid := False;
  FParseComplete := False;
end;

procedure TgaSQLStatementPart.InternalSetParseComplete;
begin
  Assert(FParseStarted);
  Assert(not FParseComplete, 'Parse already completed');
  FParseComplete := True;
  SetEndPos(Self, True);
  OwnerStatement.RemoveTopStatementPart(Self);
end;

procedure TgaSQLStatementPart.InternalStartParse;
begin
  Last;
  SetStartPos(Self, True);
  OwnerStatement.SetTopStatementPart(Self);
  FParseStarted := True;
end;

function TgaSQLStatementPart.InvalidTokenFmtStr(AToken: TgaSQLTokenObj): string;
begin
  Result := Format('Statement part parser "%s" does not accept token "%%s" in it''s current state', [ClassName]);
end;

function TgaSQLStatementPart.IsTokenValid(AToken: TgaSQLTokenObj): Boolean;
begin
  if ParseStarted then
    Result := IsValidMidparseToken(AToken)
  else
    Result := IsValidStartToken(AToken);
end;

function TgaSQLStatementPart.IsValidMidparseToken(AToken: TgaSQLTokenObj):
  Boolean;
begin
  Result := True;
end;

function TgaSQLStatementPart.IsValidStartToken(AToken: TgaSQLTokenObj): Boolean;
begin
  Result := True;
end;

procedure TgaSQLStatementPart.RestartParse;
begin
  if FParseStarted then
  begin
    DiscardParse;
    OwnerStatement.CurrentSQL.Locate(FirstItem);
    OwnerStatement.CurrentSQL.Previous;
    Clear;
    InitializeParse;
    FParseStarted := False;
  end;
end;

procedure TgaSQLStatementPart.SetAsString(const Value: string);
begin
  CheckModifyAllowed;
  RestartParse;
  First;
  inherited SetAsString(Value);
end;

procedure TgaSQLStatementPart.SetParseComplete(const Value: Boolean);
begin
  if Value and (not FParseComplete) then
  begin
    if not ParseStarted then
      InternalStartParse;
    InternalSetParseComplete;
  end;
end;

{
  **************************** TgaCustomSQLStatement *****************************
}
constructor TgaCustomSQLStatement.Create(AOwner: TgaAdvancedSQLParser);
begin
  inherited Create;
  FOwnerParser := AOwner;
  FStatusCode := 0;
  FStatementPartStack := TList.Create;
  FAllFields := TgaListOfSQLTokenLists.Create;
  FAllFieldReferences := TgaListOfSQLTokenLists.Create;;
  FAllTables := TgaListOfSQLTokenLists.Create;
  FCurrentSQL := TgaSQLTokenHolderList.Create(Self);
  FOriginalSQL := TgaSQLTokenHolderList.Create(Self);
  FOriginalSQL.OwnsAll := True;
  FCurrentSQL.OwnsAll := True;
  FAllTables.OwnsLists := False;
  FAllFields.OwnsLists := False;
  FAllFieldReferences.OwnsLists := False;
end;

constructor TgaCustomSQLStatement.CreateFromStatement(AOwner:
  TgaAdvancedSQLParser; AStatement: TgaNoSQLStatement);
begin
  inherited Create;
  FOwnerParser := AOwner;
  FStatusCode := 0;
  FStatementPartStack := TList.Create;
  FCurrentToken := AStatement.CurrentToken;
  FAllFields := AStatement.AllFields;
  FAllTables := AStatement.AllTables;
  FAllFieldReferences := AStatement.AllFieldReferences;
  FCurrentSQL := AStatement.CurrentSQL;
  FOriginalSQL := AStatement.OriginalSQL;
  AStatement.ReleaseOwnedItems;
  CurrentSQL.SetOwner(Self);
  OriginalSQL.SetOwner(Self);
end;

constructor TgaCustomSQLStatement.CreateOwned(AOwnerStatement:
  TgaCustomSQLStatement);
begin
  Assert(AOwnerStatement <> nil);
  inherited Create;
  FOwnerStm := AOwnerStatement;
  FOwnerParser := AOwnerStatement.OwnerParser;
  FStatusCode := 0;
  FStatementPartStack := TList.Create;
  FAllFields := TgaListOfSQLTokenLists.Create;
  FAllTables := TgaListOfSQLTokenLists.Create;
  FAllFieldReferences := TgaListOfSQLTokenLists.Create;;
  FCurrentSQL := TgaSQLTokenHolderList.CreateMirror(Self, AOwnerStatement.CurrentSQL);
  FOriginalSQL := TgaSQLTokenHolderList.CreateMirror(Self, AOwnerStatement.CurrentSQL);
  FOriginalSQL.OwnsAll := False;
  FCurrentSQL.OwnsAll := False;
  FAllTables.OwnsLists := False;
  FAllFields.OwnsLists := False;
  FAllFieldReferences.OwnsLists := False;
end;

destructor TgaCustomSQLStatement.Destroy;
begin
  Clear;
  FAllFields.Free;
  FAllFieldReferences.Free;
  FAllTables.Free;
  FCurrentSQL.Free;
  FOriginalSQL.Free;
  FStatementPartStack.Free;
  inherited Destroy;
end;

procedure TgaCustomSQLStatement.AcceptParserVisitor(Visitor:
  TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitCustomSQLStatement(Self);
end;

procedure TgaCustomSQLStatement.AddField(AField: TgaSQLTokenList);
begin
  AllFields.Add(AField);
  if OwnerStm <> nil then
    OwnerStm.AddField(AField);
end;

procedure TgaCustomSQLStatement.AddFieldReference(AField: TgaSQLTokenList);
begin
  AllFieldReferences.Add(AField);
  if OwnerStm <> nil then
    OwnerStm.AddFieldReference(AField);
end;

procedure TgaCustomSQLStatement.AddTable(ATable: TgaSQLTokenList);
begin
  FAllTables.Add(ATable);
  if OwnerStm <> nil then
    OwnerStm.AddTable(ATable);
end;

function TgaCustomSQLStatement.CanParseEnd: Boolean;
var
  i: Integer;
begin
  Result := True;
  i := FStatementPartStack.Count;
  while Result and (i > 0) do
  begin
    Dec(i);
    Result := TgaSQLStatementPart(FStatementPartStack.Items[i]).CanParseEnd;
  end;
end;

procedure TgaCustomSQLStatement.Clear;
begin
  if CurrentSQL <> nil then
    CurrentSQL.Clear;
  if OriginalSQL <> nil then
    OriginalSQL.Clear;
  if AllTables <> nil then
    AllTables.Clear;
  if AllFields <> nil then
    AllFields.Clear;
  if AllFieldReferences <> nil then
    AllFieldReferences.Clear;
end;

procedure TgaCustomSQLStatement.DoAfterStatementStateChange;
begin
    ; // Do nothing here
end;

procedure TgaCustomSQLStatement.DoBeforeStatementStateChange(const NewStateOrd:
  LongInt);
begin
    ; // Do nothing here
end;

procedure TgaCustomSQLStatement.DoStatementComplete;
begin
  if FOwnerParser <> nil then
    FOwnerParser.DoStatementComplete;
end;

procedure TgaCustomSQLStatement.DoTokenAdded(Sender: TObject; AToken:
  TgaSQLTokenObj);
begin
  if not CurrentSQL.Locate(AToken) then
    raise Exception.Create('Token added not found from CurrentSQL');
  FCurrentToken := AToken;
  if StatusCode = 0 then
    ModifyStatementInNormalState(Sender, AToken)
  else
    ModifyStatementInErrorState(Sender, AToken);
end;

procedure TgaCustomSQLStatement.DoTokenParsed;
var
  tmpToken: TgaSQLTokenObj;
begin
  tmpToken := OriginalSQL.NewToken;
  tmpToken.AssignTokenInfo(OwnerParser);
  CurrentToken := CurrentSQL.NewToken;
  CurrentToken.AssignTokenInfo(OwnerParser);
  DoTokenAdded(Self, CurrentToken);
end;

procedure TgaCustomSQLStatement.FinishSubStatement;
begin
  Assert(OwnerStm <> nil);
  FCurrentToken := TgaSQLTokenObj.CreateSubStatementEnd;
  CurrentSQL.InsertAfterCurrent(FCurrentToken, True);
  DoTokenAdded(Self, FCurrentToken);
end;

function TgaCustomSQLStatement.GetAsString: string;
begin
  Result := CurrentSQL.AsString;
end;

function TgaCustomSQLStatement.GetTopStatementPart: TgaSQLStatementPart;
begin
  if FStatementPartStack.Count = 0 then
    Result := nil
  else
    Result := TgaSQLStatementPart(FStatementPartStack.Last);
end;

function TgaCustomSQLStatement.IsTokenOperator(AToken: TgaSQLTokenObj): Boolean;
begin
  if OwnerParser <> nil then
    Result := OwnerParser.IsTokenOperator(AToken)
  else
    Result := False;
end;

function TgaCustomSQLStatement.IsTokenStatementTerminator(AToken:
  TgaSQLTokenObj): Boolean;
begin
  case AToken.TokenType of
    stSubStatementEnd:
      begin
        Assert(OwnerStm <> nil);
        Result := True;
      end;
    stEnd:
      Result := True;
    stOther:
      Result := AToken.TokenString = ';';
  else
    Result := False;
  end;
end;

procedure TgaCustomSQLStatement.ModifyStatementInErrorState(Sender: TObject;
  AToken: TgaSQLTokenObj);
begin
    ; // Do nothing here
end;

procedure TgaCustomSQLStatement.ModifyStatementInNormalState(Sender: TObject;
  AToken: TgaSQLTokenObj);
begin
    ; // Do nothing here
end;

procedure TgaCustomSQLStatement.ReleaseOwnedItems;
begin
  FCurrentToken := nil;
  FAllFields := nil;
  FAllTables := nil;
  FCurrentSQL := nil;
  FOriginalSQL := nil;
  FAllFieldReferences := nil;
end;

procedure TgaCustomSQLStatement.RemoveField(AField: TgaSQLTokenList);
begin
  AllFields.Remove(AField);
  if OwnerStm <> nil then
    OwnerStm.RemoveField(AField);
end;

procedure TgaCustomSQLStatement.RemoveFieldReference(AField: TgaSQLTokenList);
begin
  AllFieldReferences.Remove(AField);
  if OwnerStm <> nil then
    OwnerStm.RemoveFieldReference(AField);
end;

procedure TgaCustomSQLStatement.RemoveTable(ATable: TgaSQLTokenList);
begin
  AllTables.Remove(ATable);
  if OwnerStm <> nil then
    OwnerStm.RemoveTable(ATable);
end;

procedure TgaCustomSQLStatement.RemoveTopStatementPart(AStamentPart:
  TgaSQLStatementPart);
var
  i: Integer;
begin
  try
    Assert(FStatementPartStack.Count > 0);
    Assert(FStatementPartStack.Last = AStamentPart);
    FStatementPartStack.Delete(FStatementPartStack.Count - 1);
  except
    if IsConsole then
    begin
      Writeln('RemovedPart');
      Writeln(AStamentPart.ClassName, ': ', AStamentPart.AsString);

      Writeln('StmStackList');
      for i := 0 to FStatementPartStack.Count - 1 do
        Writeln(i, ' -> ', TgaSQLStatementPart(FStatementPartStack.Items[i]).ClassName, ': ',
          TgaSQLStatementPart(FStatementPartStack.Items[i]).AsString);
      WriteLn(OriginalSQL.AsString);
    end;
    raise;
  end;
end;

procedure TgaCustomSQLStatement.SetTopStatementPart(AStamentPart:
  TgaSQLStatementPart);
begin
  Assert((FStatementPartStack.count = 0) or (FStatementPartStack.Last <> AStamentPart));
  FStatementPartStack.Add(AStamentPart);
end;

{
  ***************************** TgaAdvancedSQLParser *****************************
}
constructor TgaAdvancedSQLParser.Create(AOwner: TComponent);
begin
  inherited;
  FOperatorSymbolList := TStringList.Create;
  TStringList(FOperatorSymbolList).Sorted := True;
  TStringList(FOperatorSymbolList).Duplicates := dupError;
  FillOperatorList;
end;

destructor TgaAdvancedSQLParser.Destroy;
begin
  FCurrentStatement.Free;
  FOperatorSymbolList.Free;
  inherited;
end;

class function TgaAdvancedSQLParser.AddStatementClass(const ATokenSymbol:
  string; AStatementClass: TgaSQLSTatementClass): Integer;
begin
  Result := StatementClassList.AddObject(UpperCase(ATokenSymbol), TObject(AStatementClass));
end;

procedure TgaAdvancedSQLParser.DoStatementComplete;
begin
  if Assigned(FOnStatementComplete) then
    FOnStatementComplete(Self);
end;

procedure TgaAdvancedSQLParser.DoTokenParsed;
begin
  CurrentStatement.DoTokenParsed;
  inherited;
end;

procedure TgaAdvancedSQLParser.FillOperatorList;
begin
  OperatorSymbolList.Add('ALL');
  OperatorSymbolList.Add('AND');
  OperatorSymbolList.Add('ANY');
  OperatorSymbolList.Add('BETWEEN');
  OperatorSymbolList.Add('EXISTS');
  OperatorSymbolList.Add('IN');
  OperatorSymbolList.Add('LIKE');
  OperatorSymbolList.Add('NOT');
  OperatorSymbolList.Add('OR');
  OperatorSymbolList.Add('SOME');
  OperatorSymbolList.Add('+');
  OperatorSymbolList.Add('-');
  OperatorSymbolList.Add('*');
  OperatorSymbolList.Add('/');
  OperatorSymbolList.Add('=');
  OperatorSymbolList.Add('>');
  OperatorSymbolList.Add('<');
  OperatorSymbolList.Add('>=');
  OperatorSymbolList.Add('<=');
  OperatorSymbolList.Add('<>');
end;

function TgaAdvancedSQLParser.GetCurrentStatement: TgaCustomSQLStatement;
begin
  if FCurrentStatement = nil then
    FCurrentStatement := GetStatementClass.Create(Self);
  Result := FCurrentStatement;
end;

function TgaAdvancedSQLParser.GetStatementClass: TgaSQLSTatementClass;
begin
  Result := TgaNoSQLStatement;
  if TokenType = stSymbol then
    Result := GetStatementClassForToken(TokenString);
end;

class function TgaAdvancedSQLParser.GetStatementClassForToken(const
  ATokenSymbol: string): TgaSQLSTatementClass;
var
  i: Integer;
  lTokenSymbol: string;
begin
  Result := TgaUnkownSQLSTatement;
  lTokenSymbol := UpperCase(ATokenSymbol);
  for i := StatementClassList.Count - 1 downto 0 do
    if StatementClassList[i] = lTokenSymbol then
    begin
      Result := TgaSQLSTatementClass(StatementClassList.Objects[i]);
      Exit;
    end;
end;

function TgaAdvancedSQLParser.IsTokenOperator(AToken: TgaSQLTokenObj): Boolean;
begin
  if AToken.TokenType in [stSymbol, stEq, stOther] then
    Result := OperatorSymbolList.IndexOf(AToken.TokenString) >= 0
  else
    Result := False;
end;

class procedure TgaAdvancedSQLParser.RemoveStatementClass(const ATokenSymbol:
  string; AStatementClass: TgaSQLSTatementClass);
var
  i: Integer;
  lTokenSymbol: string;
begin
  lTokenSymbol := UpperCase(ATokenSymbol);
  for i := StatementClassList.Count - 1 downto 0 do
    if (StatementClassList[i] = lTokenSymbol) and
      (StatementClassList.Objects[i] = TObject(AStatementClass)) then
    begin
      StatementClassList.Delete(i);
      Exit;
    end;
end;

procedure TgaAdvancedSQLParser.Reset;
begin
  FreeAndNil(FCurrentStatement);
  inherited;
end;

procedure TgaAdvancedSQLParser.SetCurrentStatement(AStatement:
  TgaCustomSQLStatement);
begin
  FCurrentStatement := AStatement;
end;

procedure TgaAdvancedSQLParser.SetOperatorSymbolList(const Value: TStrings);
begin
  FOperatorSymbolList.Assign(Value);
end;

{
  **************************** TgaUnkownSQLStatement *****************************
}
procedure TgaUnkownSQLStatement.AcceptParserVisitor(Visitor:
  TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitUnkownSQLStatement(Self);
end;

function TgaUnkownSQLStatement.GetStatementType: TSQLStatementType;
begin
  Result := sstUnknown;
end;

{
  ******************************* TgaSQLTokenList ********************************
}
constructor TgaSQLTokenList.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  inherited Create;
  FOwnerStatement := AOwnerStatement;
end;

constructor TgaSQLTokenList.CreateMirror(AOwnerStatement: TgaCustomSQLStatement;
  AMirroredList: TgaSQLTokenList);
var
  IsOk: Boolean;
begin
  if AOwnerStatement.OwnerStm <> nil then
  begin
    IsOk := (AMirroredList.DataOwner = AOwnerStatement.OwnerStm.CurrentSQL.DataOwner) or
      (AMirroredList.DataOwner = AOwnerStatement.OwnerStm.OriginalSQL.DataOwner);
  end
  else
    IsOk := AOwnerStatement.CurrentSQL.DataOwner = AMirroredList.DataOwner;
  if not IsOk then
    raise Exception.Create('List to be mirrored is not the OwnerStatement list');
  FOwnerStatement := AOwnerStatement;
  inherited CreateMirror(AMirroredList);
  SetStartPos(AMirroredList, True);
end;

procedure TgaSQLTokenList.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLTokenList(Self);
end;

procedure TgaSQLTokenList.ExecuteTokenAdded(Sender: TObject; AToken:
  TgaSQLTokenObj);
begin
  if not Locate(AToken) then
    raise EgaSQLParserException.CreateFmt('Token beeing added is not part of the current statement part. Class: %s',
      [Classname]);
end;

procedure TgaSQLTokenList.GetAllTokens(ATokenList: TgaSQLTokenList);
begin
  ATokenList.Clear;
  First;
  while not Eof do
  begin
    ATokenList.Add(CurrentItem);
    Next;
  end;
end;

function TgaSQLTokenList.GetAsString: string;
var
  Cursor: TgaSQLTokenListBookmark;
begin
  Result := '';
  Cursor := GetBookmark;
  try
    Cursor.First;
    while not Cursor.Eof do
    begin
      Result := Result + Cursor.TokenObj.TokenAsString;
      Cursor.Next;
    end;
  finally
    Cursor.Free;
  end
end;

function TgaSQLTokenList.GetBookmark: TgaSQLTokenListBookmark;
begin
  Result := TgaSQLTokenListBookmark.Create(Self, Cursor);
end;

function TgaSQLTokenList.GetCurrentItem: TgaSQLTokenObj;
begin
  Result := TgaSQLTokenObj(inherited CurrentItem);
end;

function TgaSQLTokenList.GetLastItem: TgaSQLTokenObj;
begin
  Result := TgaSQLTokenObj(inherited LastItem);
end;

function TgaSQLTokenList.GetTokenObjAsString(ATokenObj: TgaSQLTokenObj): string;
begin
  if ATokenObj <> nil then
    Result := ATokenObj.TokenAsString
  else
    Result := '';
end;

procedure TgaSQLTokenList.SetAsString(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
  AItem: TgaSQLTokenObj;
begin
  tmpTokenList := TgaSQLTokenHolderList.Create(nil);
  try
    ParseStringToTokens(Value, tmpTokenList);
    TrimTokenList(tmpTokenList, True, [stEnd]);
    if tmpTokenList.Count = 0 then
      tmpTokenList.AddToken(TgaSQLTokenObj.CreatePlaceHolder);
    tmpTokenList.First;
    while not tmpTokenList.Eof do
    begin
      AItem := tmpTokenList.CurrentItem;
      Add(AItem);
      // #Todo2 this can be optimized
      OwnerStatement.CurrentSQL.Locate(AItem);
      if (AItem.TokenType <> stPlaceHolder) then
        ExecuteTokenAdded(Self, AItem);
      tmpTokenList.Next;
    end;
  finally
    tmpTokenList.Free;
  end;
end;

procedure TgaSQLTokenList.SetCurrentItem(Value: TgaSQLTokenObj);
begin
  if (OwnerStatement <> nil) and (OwnerStatement.CurrentSQL = DataOwner) then
    CurrentItem.Free;
  inherited CurrentItem := Value;
end;

{
  ******************************** TgaSQLTokenObj ********************************
}
procedure TgaSQLTokenObj.AssignTokenInfo(ASQLParser: TgaBasicSQLParser);
begin
  FTokenType := ASQLParser.TokenType;
  FTokenString := ASQLParser.TokenString;
  FStartQuote := ASQLParser.StartQuote;
  FEndQuote := ASQLParser.EndQuote;
  FTokenQuoted := ASQLParser.TokenQuoted;
end;

class function TgaSQLTokenObj.CreateDelimitier: TgaSQLTokenObj;
begin
  Result := Create;
  try
    Result.FTokenType := stDelimitier;
    Result.FTokenString := ' ';
    Result.FStartQuote := #0;
    Result.FEndQuote := #0;
    Result.FTokenQuoted := False;
  except
    Result.Free;
    raise;
  end;
end;

class function TgaSQLTokenObj.CreatePlaceHolder: TgaSQLTokenObj;
begin
  Result := Create;
  try
    Result.FTokenType := stPlaceHolder;
    Result.FTokenString := '';
    Result.FStartQuote := #0;
    Result.FEndQuote := #0;
    Result.FTokenQuoted := False;
  except
    Result.Free;
    raise;
  end;
end;

class function TgaSQLTokenObj.CreateSubStatementEnd: TgaSQLTokenObj;
begin
  Result := Create;
  try
    Result.FTokenType := stSubStatementEnd;
    Result.FTokenString := '';
    Result.FStartQuote := #0;
    Result.FEndQuote := #0;
    Result.FTokenQuoted := False;
  except
    Result.Free;
    raise;
  end;
end;

function TgaSQLTokenObj.GetTokenAsString: string;
begin
  Result := TokenString;
  if TokenQuoted then
    Result := StartQuote + Result + EndQuote;
  if TokenType = stParameter then
    Result := ':' + Result;
end;

procedure TgaSQLTokenObj.SetTokenInfo(const AString: string; ATokenType:
  TSQLToken; AQuoted: Boolean; AStartQuote, AEndQuote: char);
begin
  FTokenType := ATokenType;
  FTokenString := AString;
  FStartQuote := AStartQuote;
  FEndQuote := AEndQuote;
  FTokenQuoted := AQuoted;
end;

function TgaSQLTokenObj.TokenSymbolIs(const S: string): Boolean;
begin
  Result := (TokenType = stSymbol) and (CompareText(FTokenString, S) = 0);
end;

{
  *************************** TgaSQLTokenListBookmark ****************************
}
function TgaSQLTokenListBookmark.GetTokenObj: TgaSQLTokenObj;
begin
  Result := TgaSQLTokenObj(Item);
end;

procedure TgaSQLTokenListBookmark.SetTokenObj(Value: TgaSQLTokenObj);
begin
  Item := Value;
end;

{
  ************************ EgaSQLInvalidTokenEncountered *************************
}
constructor EgaSQLInvalidTokenEncountered.Create(AStatementPart:
  TgaSQLStatementPart; AToken: TgaSQLTokenObj);
begin
  FStatementPart := AStatementPart;
  FToken := AToken;
  inherited CreateFmt(StatementPart.InvalidTokenFmtStr(TOken), [AToken.TokenAsString]);
end;

{
  ************************ TgaListOfSQLTokenListsBookmark ************************
}
function TgaListOfSQLTokenListsBookmark.GetTokenList: TgaSQLTokenList;
begin
  Result := TgaSQLTokenList(Item);
end;

procedure TgaListOfSQLTokenListsBookmark.SetTokenList(Value: TgaSQLTokenList);
begin
  Item := Value;
end;

initialization

StatementClassList := TStringList.Create;
TgaAdvancedSQLParser.AddStatementClass('SELECT', TgaSelectSQLStatement);
TgaAdvancedSQLParser.AddStatementClass('UPDATE', TgaUpdateSQLStatement);
TgaAdvancedSQLParser.AddStatementClass('DELETE', TgaDeleteSQLStatement);
TgaAdvancedSQLParser.AddStatementClass('INSERT', TgaInsertSQLStatement);

finalization

TgaAdvancedSQLParser.RemoveStatementClass('SELECT', TgaSelectSQLStatement);
TgaAdvancedSQLParser.RemoveStatementClass('UPDATE', TgaUpdateSQLStatement);
TgaAdvancedSQLParser.RemoveStatementClass('DELETE', TgaDeleteSQLStatement);
TgaAdvancedSQLParser.RemoveStatementClass('INSERT', TgaInsertSQLStatement);
StatementClassList.Free;

end.
