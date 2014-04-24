{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Various helper classes                          }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaSQLParserHelperClasses;

interface

uses
  gaAdvancedSQLParser, gaBasicSQLParser;

type
  TgaSQLStatementPartClass = class of TgaSQLStatementPart;

  TgaSQLStatementPartList = class (TgaListOfSQLTokenLists)
  private
    FOwnerStatement: TgaCustomSQLStatement;
    FParenEnclosedList: Boolean;
    FParseComplete: Boolean;
    FParseStarted: Boolean;
    FStatementPartType: TgaSQLStatementPartClass;
    FTokenList: TgaSQLTokenList;
    function GetParseComplete: Boolean;
    procedure SetParseComplete(const Value: Boolean);
  protected
    FCurrentPart: TgaSQLStatementPart;
    function CreateCurrentPart(ForToken: TgaSQLTokenObj): TgaSQLStatementPart;
    function CreateNewPart(ForToken: TgaSQLTokenObj): TgaSQLStatementPart; 
            virtual;
    procedure DiscardParse; virtual;
    function GetAsString: string; override;
    function GetCanParseEnd: Boolean; virtual;
    procedure InitializeParse; virtual;
    procedure InternalSetParseComplete; virtual;
    function IsSeparatorToken(AToken: TgaSQLTokenObj): Boolean; virtual;
    function IsTokenWhitespace(AToken: TgaSQLTokenObj): Boolean; virtual;
    procedure SetAsString(const Value: string); virtual;
    procedure StartParse(AToken: TgaSQLTokenObj);
    property CurrentPart: TgaSQLStatementPart read FCurrentPart;
    property OwnerStatement: TgaCustomSQLStatement read FOwnerStatement;
    property ParseStarted: Boolean read FParseStarted;
    property StatementPartType: TgaSQLStatementPartClass read 
            FStatementPartType;
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement; 
            AStatementPartType: TgaSQLStatementPartClass);
    destructor Destroy; override;
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure Clear; override;
    procedure CompleteParseAtPreviousToken; virtual;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    procedure RestartParse;
    property AsString read GetAsString write SetAsString;
    property CanParseEnd: Boolean read GetCanParseEnd;
    property ParenEnclosedList: Boolean read FParenEnclosedList write 
            FParenEnclosedList;
    property ParseComplete: Boolean read GetParseComplete write 
            SetParseComplete;
    property TokenList: TgaSQLTokenList read FTokenList;
  end;
  
procedure ParseStringToTokens(const AString: string; ATokenList: TgaSQLTokenHolderList);

implementation

uses
  SysUtils, gaSQLParserConsts, gaParserVisitor;

procedure ParseStringToTokens(const AString: string; ATokenList: TgaSQLTokenHolderList);
var
  lSQLParser: TgaBasicSQLParser;
  lTokenObj: TgaSQLTokenObj;
begin
  ATokenList.Clear;
  lSQLParser := TgaBasicSQLParser.Create(nil);
  try
    lSQLParser.Text := AString;
    lSQLParser.Reset;
    while lSQLParser.TokenType <> stEnd do
    begin
      lTokenObj := ATokenList.NewToken;
      lTokenObj.AssignTokenInfo(lSQLParser);
      lSQLParser.NextToken;
    end;
  finally
    lSQLParser.Free;
  end;
end;


{
*************************** TgaSQLStatementPartList ****************************
}
constructor TgaSQLStatementPartList.Create(AOwnerStatement: 
        TgaCustomSQLStatement; AStatementPartType: TgaSQLStatementPartClass);
begin
  Assert(ClassType <> TgaSQLStatementPartList);
  inherited Create;
  FTokenList := TgaSQLTokenList.CreateMirror(AOwnerStatement, 
          AOwnerStatement.CurrentSQL);
  FTokenList.SetStartPos(AOwnerStatement.CurrentSQL, True);
  FStatementPartType := AStatementPartType;
  FOwnerStatement := AOwnerStatement;
end;

destructor TgaSQLStatementPartList.Destroy;
begin
  FreeAndNil(FTokenList);
  inherited Destroy;
end;

procedure TgaSQLStatementPartList.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLStatementPartList(Self);
end;

procedure TgaSQLStatementPartList.Clear;
begin
  FCurrentPart := nil;
  inherited Clear;
  if TokenList <> nil then
    TokenList.Clear;
end;

procedure TgaSQLStatementPartList.CompleteParseAtPreviousToken;
begin
  TokenList.Last;
  TokenList.Previous;
  ParseComplete := True;
end;

function TgaSQLStatementPartList.CreateCurrentPart(ForToken: TgaSQLTokenObj): 
        TgaSQLStatementPart;
begin
  if FCurrentPart = nil then
  begin
    FCurrentPart := CreateNewPart(ForToken);
    Add(FCurrentPart);
  end;
  Result := FCurrentPart;
end;

function TgaSQLStatementPartList.CreateNewPart(ForToken: TgaSQLTokenObj): 
        TgaSQLStatementPart;
begin
  Result := StatementPartType.Create(OwnerStatement);
end;

procedure TgaSQLStatementPartList.DiscardParse;
begin
  Clear;
end;

procedure TgaSQLStatementPartList.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if ParseComplete then
    raise EgaSQLInvalidParseState.CreateFmt(SerrStmPartParseFinised, [ClassName]);
  if not ParseStarted then
    StartParse(AToken);
  if ParenEnclosedList and (AToken.TokenType = stRParen) and
    ((CurrentPart = nil) or CurrentPart.CanParseEnd)then
  begin
    if CurrentPart <> nil then
      CurrentPart.CompleteParseAtPreviousToken;
    TokenList.Locate(AToken);
    ParseComplete := True;
    Exit;
  end;
  if CurrentPart = nil then
    if not (IsTokenWhitespace(AToken) or IsSeparatorToken(AToken)) then
      FCurrentPart := CreateCurrentPart(AToken);
  if CurrentPart <> nil then
  begin
    if (AToken.TokenType = stComma) and CurrentPart.CanParseEnd then
      CurrentPart.CompleteParseAtPreviousToken
    else
      CurrentPart.ExecuteTokenAdded(Sender, AToken);
    if CurrentPart.ParseComplete then
      FCurrentPart := nil;
  end;
  TokenList.Locate(AToken);
end;

function TgaSQLStatementPartList.GetAsString: string;
var
  Cursor: TgaSQLTokenListBookmark;
begin
  Result := '';
  Cursor := TokenList.GetBookmark;
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

function TgaSQLStatementPartList.GetCanParseEnd: Boolean;
begin
  Result := (CurrentPart = nil) or CurrentPart.CanParseEnd;
end;

function TgaSQLStatementPartList.GetParseComplete: Boolean;
begin
  Result := FParseComplete;
end;

procedure TgaSQLStatementPartList.InitializeParse;
begin
  FParseComplete := False;
  FParseStarted := False;
end;

procedure TgaSQLStatementPartList.InternalSetParseComplete;
begin
  if (FCurrentPart <> nil) and (not FCurrentPart.ParseComplete) then
  begin
    FCurrentPart.Locate(TokenList.CurrentItem);
    FCurrentPart.ParseComplete := True;
    FCurrentPart := nil;
  end;
  FParseComplete := True;
  TokenList.SetEndPos(TokenList, True);
end;

function TgaSQLStatementPartList.IsSeparatorToken(AToken: TgaSQLTokenObj): 
        Boolean;
begin
  Result := AToken.TokenType = stComma;
end;

function TgaSQLStatementPartList.IsTokenWhitespace(AToken: TgaSQLTokenObj): 
        Boolean;
begin
  Result := AToken.TokenType in [stComment, stDelimitier, stPlaceHolder];
end;

procedure TgaSQLStatementPartList.RestartParse;
begin
  DiscardParse;
  Clear;
  InitializeParse;
end;

procedure TgaSQLStatementPartList.SetAsString(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
  AItem: TgaSQLTokenObj;
begin
  tmpTokenList := TgaSQLTokenHolderList.Create(nil);
  try
    ParseStringToTokens(Value, tmpTokenList);
    TrimTokenList(tmpTokenList, True, [stEnd]);
    if tmpTokenList.Count = 0 then
      tmpTokenList.AddToken(TgaSQLTokenObj.CreatePlaceHolder)
    else if tmpTokenList.LastItem.TokenType <> stDelimitier then
      tmpTokenList.AddToken(TgaSQLTokenObj.CreateDelimitier);
    RestartParse;
    tmpTokenList.First;
    while not tmpTokenList.Eof do
    begin
      AItem := tmpTokenList.CurrentItem;
      TokenList.Add(AItem);
      // #Todo2 this can be optimized
      OwnerStatement.CurrentSQL.Locate(AItem);
      ExecuteTokenAdded(Self, AItem);
      tmpTokenList.Next;
    end;
  finally
    tmpTokenList.Free;
  end;
end;

procedure TgaSQLStatementPartList.SetParseComplete(const Value: Boolean);
begin
  if Value then
    InternalSetParseComplete;
end;

procedure TgaSQLStatementPartList.StartParse(AToken: TgaSQLTokenObj);
begin
  if ParenEnclosedList then
  begin
    if AToken.TokenType = stLParen then
      FParseStarted := True
    else if not IsTokenWhitespace(AToken) then
      raise EgaSQLInvalidParseState.Create('Parenthes enclosed statement part list must start with "("');
    TokenList.Locate(AToken);
    TokenList.SetStartPos(TokenList, True);
    Exit;
  end
  else
  begin
    FParseStarted := True;
    TokenList.Locate(AToken);
    TokenList.SetStartPos(TokenList, True);
  end;
end;

end.
