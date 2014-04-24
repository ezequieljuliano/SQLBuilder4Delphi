{*******************************************************}
{                                                       }
{       Basic SQL statement parser                      }
{       Based on Borland's TSQLParser found in          }
{       UpdateSQL editor                                }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaBasicSQLParser;

{ To do list: }

{  #ToDo2 How the parameters have to be parsed, and which forms are allowed
          Need to check Delphi source...}
{  #ToDo2 Add statement delimitier/multistatement support (may require support
          for something like "set term ..")
}

interface

uses
  Classes;
type
  TSQLToken = (stSymbol, stQuotedSymbol, stString, stDelimitier, stParameter,
    stNumber, stComment, stComma, stPeriod, stEQ, stLParen, stRParen, stOther,
    stPlaceHolder, stSubStatementEnd, stEnd);
  TSQLTokenTypes = set of TSQLToken;

  TCommentType = (ctMultiLine, ctLineEnd);

  TgaQuoteType = (qtUnknown, qtString, qtSymbol);

  TgaSQLQuoteInfoItem = class (TCollectionItem)
  private
    FEndDelimitier: Char;
    FQuotedIdentifierType: TgaQuoteType;
    FStartDelimitier: Char;
  published
    property EndDelimitier: Char read FEndDelimitier write FEndDelimitier;
    property QuotedIdentifierType: TgaQuoteType read FQuotedIdentifierType 
            write FQuotedIdentifierType;
    property StartDelimitier: Char read FStartDelimitier write FStartDelimitier;
  end;
  
  TgaSQLQuoteInfoCollection = class (TOwnedCollection)
  private
    function GetItem(Index: Integer): TgaSQLQuoteInfoItem;
    procedure SetItem(Index: Integer; const Value: TgaSQLQuoteInfoItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TgaSQLQuoteInfoItem;
    function Insert(Index: Integer): TgaSQLQuoteInfoItem;
    property Items[Index: Integer]: TgaSQLQuoteInfoItem read GetItem write 
            SetItem;
  end;
  
  TgaBasicSQLParser = class (TComponent)
  private
    FCurrentPos: PChar;
    FEndQuote: Char;
    FOnTokenParsed: TNotifyEvent;
    FSourcePtr: PChar;
    FSQLText: TStrings;
    FStartQuote: Char;
    FSymbolQuotes: TgaSQLQuoteInfoCollection;
    FText: string;
    FToken: TSQLToken;
    FTokenEnd: PChar;
    FTokenQuoted: Boolean;
    FTokenStart: PChar;
    FTokenString: string;
    procedure SetSQLText(const Value: TStrings);
    procedure SetSymbolQuotes(const Value: TgaSQLQuoteInfoCollection);
    procedure SetText(const Value: string);
  protected
    procedure DoTokenParsed; virtual;
    function FindQuoteInfoForChar(AChar: Char): TgaSQLQuoteInfoItem;
    function IsStartQuote(AChar: Char): Boolean;
    function ScanComment(CommentType: TCommentType): TSQLToken;
    function ScanDelimitier: TSQLToken;
    function ScanNumber: TSQLToken;
    function ScanOther: TSQLToken;
    function ScanParam: TSQLToken;
    function ScanQuotedtSymbol: TSQLToken;
    function ScanSpecial: TSQLToken;
    function ScanSymbol: TSQLToken;
    procedure SQLTextChanged(Sender: TObject);
    function TokenSymbolIs(const S: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function NextToken: TSQLToken;
    procedure Reset; virtual;
    property EndQuote: Char read FEndQuote;
    property StartQuote: Char read FStartQuote;
    property Text: string read FText write SetText;
    property TokenQuoted: Boolean read FTokenQuoted;
    property TokenString: string read FTokenString;
    property TokenType: TSQLToken read FToken;
  published
    property OnTokenParsed: TNotifyEvent read FOnTokenParsed write 
            FOnTokenParsed;
    property SQLText: TStrings read FSQLText write SetSQLText;
    property SymbolQuotes: TgaSQLQuoteInfoCollection read FSymbolQuotes write 
            SetSymbolQuotes;
  end;
  
implementation

// Delphi5 does not have MSWINDOWS defined...
{$ifdef Win32}
{$define MSWINDOWS}
{$endif}

uses
  SysUtils{$ifdef MSWINDOWS}, Windows{$endif}, gaSQLParserConsts;

function IsKatakana(const Chr: Byte): Boolean;
begin
  {$ifdef MSWINDOWS}
  Result := (SysLocale.PriLangID = LANG_JAPANESE) and (Chr in [$A1..$DF]);
  {$endif}
  {$ifdef LINUX}
  Result := False;
  {$endif}
  // #ToDo1 quick dirty solution for Kylix
end;

{
****************************** TgaBasicSQLParser *******************************
}
constructor TgaBasicSQLParser.Create(AOwner: TComponent);
begin
  inherited;
  FSQLText := TStringList.Create;
  TStringList(FSQLText).OnChange := SQLTextChanged;
  FSymbolQuotes := TgaSQLQuoteInfoCollection.Create(Self);
  with FSymbolQuotes.Add as TgaSQLQuoteInfoItem do
  begin
    StartDelimitier := '"';
    EndDelimitier := '"';
    QuotedIdentifierType := qtSymbol;
  end;
  with FSymbolQuotes.Add as TgaSQLQuoteInfoItem do
  begin
    StartDelimitier := '''';
    EndDelimitier := '''';
    QuotedIdentifierType := qtString;
  end;
end;

destructor TgaBasicSQLParser.Destroy;
begin
  TStringList(FSQLText).OnChange := nil;
  FSQLText.Free;
  FSymbolQuotes.Free;
  inherited;
end;

procedure TgaBasicSQLParser.DoTokenParsed;
begin
  if Assigned(FOnTokenParsed) then
    FOnTokenParsed(self);
end;

function TgaBasicSQLParser.FindQuoteInfoForChar(AChar: Char): 
        TgaSQLQuoteInfoItem;
var
  i: Integer;
begin
  for i := 0 to FSymbolQuotes.Count - 1 do
  begin
    Result := FSymbolQuotes.Items[i] as TgaSQLQuoteInfoItem;
    if Result.StartDelimitier = AChar then
      Exit;
  end;
  Result := nil;
end;

function TgaBasicSQLParser.IsStartQuote(AChar: Char): Boolean;
begin
  Result := FindQuoteInfoForChar(AChar) <> nil;
end;

function TgaBasicSQLParser.NextToken: TSQLToken;
begin
  if FToken = stEnd then
    SysUtils.Abort;
  FTokenString := '';
  FTokenQuoted := False;
  FStartQuote := ' ';
  FEndQuote := ' ';
  FCurrentPos := FSourcePtr;
  FTokenStart := FSourcePtr;
  FTokenEnd := nil;
  case FCurrentPos^ of
    #01..' ':
      FToken := ScanDelimitier;
    ':':
      if (FCurrentPos+1)^ = ':' then
        FToken := ScanSymbol //actually BDE alias
      else
        FToken := ScanParam;
    'A'..'Z', 'a'..'z', '_', '$', #127..#255:
      FToken := ScanSymbol;
    '0'..'9':
      FToken := ScanNumber;
    '/':
      if (FCurrentPos+1)^ in ['*', '/'] then
        // ((P+1)^ = '/') = True; Ord(True) = 1; TCommnetType(1) = ctLineEnd;
        FToken := ScanComment(TCommentType(Ord((FCurrentPos+1)^ = '/')))
      else
        FToken := ScanOther;
    ',', '=', '(', ')', '.':
      FToken := ScanSpecial;
    #0:
      FToken := stEnd;
    else
      if (FCurrentPos^ = '-') and ((FCurrentPos+1)^ = '-') then
        FToken := ScanComment(ctLineEnd)
      else if IsStartQuote(FCurrentPos^) then
        FToken := ScanQuotedtSymbol
      else
        FToken := ScanOther;
  end;
  FSourcePtr := FCurrentPos;
  if FTokenEnd = nil then
    FTokenEnd := FCurrentPos;
  SetString(FTokenString, FTokenStart, FTokenEnd - FTokenStart);
  Result := FToken;
  DoTokenParsed;
end;

procedure TgaBasicSQLParser.Reset;
begin
  FSourcePtr := PChar(FText);
  FToken := stSymbol;
  NextToken;
end;

function TgaBasicSQLParser.ScanComment(CommentType: TCommentType): TSQLToken;
begin
  Inc(FCurrentPos, 2); // every comment starts with doublechar comment identifier
  if CommentType = ctLineEnd then
    while not (FCurrentPos^ in [#10, #13]) do
      Inc(FCurrentPos)
  else
    while not (((FCurrentPos-1)^ = '/') and ((FCurrentPos-2)^ = '*')) do
      Inc(FCurrentPos);
  Result := stComment;
end;

function TgaBasicSQLParser.ScanDelimitier: TSQLToken;
begin
  while (FCurrentPos^ in [#01..' ']) do
    Inc(FCurrentPos);
  Result := stDelimitier;
end;

function TgaBasicSQLParser.ScanNumber: TSQLToken;
begin
  Inc(FCurrentPos);
  while FCurrentPos^ in ['0'..'9', '.', 'e', 'E', '+', '-'] do
    Inc(FCurrentPos);
  Result := stNumber;
end;

function TgaBasicSQLParser.ScanOther: TSQLToken;
begin
  Inc(FCurrentPos);
  Result := stOther;
end;

function TgaBasicSQLParser.ScanParam: TSQLToken;
begin
  Inc(FCurrentPos);
  FTokenStart := FCurrentPos;
  case FCurrentPos^ of
    #0..' ', ',':
      FTokenEnd := FCurrentPos;
    '''', '"':
      ScanQuotedtSymbol;
    else
  //    '0'..'9', 'A'..'Z', 'a'..'z', '_', '$', #127..#255:
      ScanSymbol;
  end;
  Result := stParameter;
end;

function TgaBasicSQLParser.ScanQuotedtSymbol: TSQLToken;
var
  QuoteInfo: TgaSQLQuoteInfoItem;
begin
  FStartQuote := FCurrentPos^;
  QuoteInfo := FindQuoteInfoForChar(FStartQuote);
  Assert(QuoteInfo <> nil);
  if QuoteInfo.QuotedIdentifierType = qtUnknown then
    raise Exception.CreateFmt('The type of quote %s<text>%s is unknown',  [QuoteInfo.StartDelimitier, QuoteInfo.EndDelimitier]);
  Inc(FCurrentPos);
  FTokenStart := FCurrentPos;
  while not (FCurrentPos^ in [QuoteInfo.EndDelimitier, #0]) do
    Inc(FCurrentPos);
  if FCurrentPos^ = #0 then
    raise Exception.CreateFmt('No end quote (%s) found in SQL text for start quote (%s)', [QuoteInfo.EndDelimitier, QuoteInfo.StartDelimitier]);
  FEndQuote := FCurrentPos^;
  FTokenEnd := FCurrentPos;
  Inc(FCurrentPos);
  FTokenQuoted := True;
  if QuoteInfo.QuotedIdentifierType = qtSymbol then
    Result := stQuotedSymbol
  else
    Result := stString;
end;

function TgaBasicSQLParser.ScanSpecial: TSQLToken;
begin
  case FCurrentPos^ of
    ',':
      Result := stComma;
    '=':
      Result := stEQ;
    '(':
      Result := stLParen;
    ')':
      Result := stRParen;
    '.':
      Result := stPeriod;
    else
      raise Exception.CreateFmt(SWrongSpecialChar, [FCurrentPos^]);
  end;
  inc(FCurrentPos);
end;

function TgaBasicSQLParser.ScanSymbol: TSQLToken;
begin
  if not SysLocale.FarEast then
  begin
    Inc(FCurrentPos);
    while FCurrentPos^ in ['A'..'Z', 'a'..'z', '0'..'9', '_', '"', '$', #127..#255] do
      Inc(FCurrentPos);
  end
  else begin
    while TRUE do
    begin
      if (FCurrentPos^ in ['A'..'Z', 'a'..'z', '0'..'9', '_', '"', '$']) or
         IsKatakana(Byte(FCurrentPos^)) then
        Inc(FCurrentPos)
      else
        if FCurrentPos^ in LeadBytes then
          Inc(FCurrentPos, 2)
        else
          Break;
    end;
  end;
  Result := stSymbol;
end;

procedure TgaBasicSQLParser.SetSQLText(const Value: TStrings);
begin
  FSQLText.Assign(Value);
end;

procedure TgaBasicSQLParser.SetSymbolQuotes(const Value: 
        TgaSQLQuoteInfoCollection);
begin
  FSymbolQuotes.Assign(Value);
end;

procedure TgaBasicSQLParser.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    Reset;
  end;
end;

procedure TgaBasicSQLParser.SQLTextChanged(Sender: TObject);
begin
  Text := FSQLText.Text;
end;

function TgaBasicSQLParser.TokenSymbolIs(const S: string): Boolean;
begin
  Result := (FToken = stSymbol) and (CompareText(FTokenString, S) = 0);
end;

{ TgaSQLQuoteInfoCollection }

{
************************** TgaSQLQuoteInfoCollection ***************************
}
constructor TgaSQLQuoteInfoCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TgaSQLQuoteInfoItem);
end;

function TgaSQLQuoteInfoCollection.Add: TgaSQLQuoteInfoItem;
begin
  Result := TgaSQLQuoteInfoItem(inherited Add);
end;

function TgaSQLQuoteInfoCollection.GetItem(Index: Integer): TgaSQLQuoteInfoItem;
begin
  Result := TgaSQLQuoteInfoItem(inherited Items[Index]);
end;

function TgaSQLQuoteInfoCollection.Insert(Index: Integer): TgaSQLQuoteInfoItem;
begin
  Result := TgaSQLQuoteInfoItem(inherited Insert(Index));
end;

procedure TgaSQLQuoteInfoCollection.SetItem(Index: Integer; const Value: 
        TgaSQLQuoteInfoItem);
begin
  inherited Items[Index] := Value;
end;

end.
