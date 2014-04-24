{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Classes for parsing SQL expressions             }
{       Copyright (c) 2001 - 2004 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaSQLExpressionParsers;

interface

uses
  gaBasicSQLParser, gaAdvancedSQLParser, gaSQLParserHelperClasses;

type
  TgaSQLExpressionPartType = (eptUnknown, eptMultipart, eptFieldRef, eptConstant,
      eptFunction, eptOperator, eptSubSelect, eptUnrecognized);

  TgaSQLExpressionBase = class (TgaSQLStatementPart)
  protected
    function GetExpressionType: TgaSQLExpressionPartType; virtual; abstract;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property ExpressionType: TgaSQLExpressionPartType read GetExpressionType;
  end;
  
  TgaSQLExpressionBuilderState = (ebsNoTokensParsed, ebsSymbolParsed,
      ebsLParenScanned, ebsAfterSymbolSequence, ebsScanDone);

  TgaSQLExpressionBuilderDecision = (ebdInsufficientInfo, ebdSuggestion,
      ebdFinaldecision);

  TgaSQLExpressionPart = class (TgaSQLExpressionBase)
  private
    FNextExpressionPart: TgaSQLExpressionPart;
    FPreviousExpressionPart: TgaSQLExpressionPart;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property NextExpressionPart: TgaSQLExpressionPart read FNextExpressionPart;
    property PreviousExpressionPart: TgaSQLExpressionPart read 
            FPreviousExpressionPart;
  end;
  
  TgaSQLExpressionPartBuilder = class (TgaSQLExpressionBase)
  private
    FDecision: TgaSQLExpressionBuilderDecision;
    FExpressionType: TgaSQLExpressionPartType;
    FScanState: TgaSQLExpressionBuilderState;
  protected
    function GetCanParseEnd: Boolean; override;
    function GetExpressionType: TgaSQLExpressionPartType; override;
    procedure InitializeParse; override;
    procedure ScanAfterFirstSymbol(AToken: TgaSQLTokenObj);
    procedure ScanAfterLParen(AToken: TgaSQLTokenObj);
    procedure ScanAfterSymbolSeq(AToken: TgaSQLTokenObj);
    procedure ScanFirstToken(AToken: TgaSQLTokenObj);
    property ScanState: TgaSQLExpressionBuilderState read FScanState;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    function CreateExpressionPart: TgaSQLExpressionPart; virtual;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property Decision: TgaSQLExpressionBuilderDecision read FDecision;
  end;
  
  TgaSQLUnrecognizedExpression = class (TgaSQLExpressionPart)
  protected
    function GetExpressionType: TgaSQLExpressionPartType; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  
  TgaSQLExpressionConstant = class (TgaSQLExpressionPart)
  protected
    function GetExpressionType: TgaSQLExpressionPartType; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  
  TgaSQLExpressionOperator = class (TgaSQLExpressionPart)
  protected
    function GetExpressionType: TgaSQLExpressionPartType; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  
  TgaSQLMultipartExpression = class (TgaSQLExpressionPart)
  private
    FExpressionPartInParse: TgaSQLExpressionPart;
    FExpressionScanner: TgaSQLExpressionPartBuilder;
    FFirstSubPart: TgaSQLExpressionPart;
    FInPartParse: Boolean;
    FLastSubPart: TgaSQLExpressionPart;
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    function GetExpressionType: TgaSQLExpressionPartType; override;
    procedure InternalSetParseComplete; override;
    procedure RescanExpression;
    property ExpressionPartInParse: TgaSQLExpressionPart read 
            FExpressionPartInParse;
    property ExpressionScanner: TgaSQLExpressionPartBuilder read 
            FExpressionScanner;
    property InPartParse: Boolean read FInPartParse write FInPartParse;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property FirstSubPart: TgaSQLExpressionPart read FFirstSubPart;
    property LastSubPart: TgaSQLExpressionPart read FLastSubPart;
  end;
  
  TgaSQLExpressionList = class (TgaSQLStatementPartList)
  public
    constructor Create(AOwnerStatement: TgaCustomSQLStatement);
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;
  
  TgaSQLFunctionParamsList = class (TgaSQLExpressionList)
  private
    FAllowAsterixParam: Boolean;
  protected
    function CreateNewPart(ForToken: TgaSQLTokenObj): TgaSQLStatementPart; 
            override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    property AllowAsterixParam: Boolean read FAllowAsterixParam write 
            FAllowAsterixParam;
  end;
  
  TgaSQLExpressionFunction = class (TgaSQLExpressionPart)
  private
    FFunctionNameToken: TgaSQLTokenListBookmark;
    FFunctionParameters: TgaSQLFunctionParamsList;
    FParameterParseStarted: Boolean;
    function GetFunctionName: string;
    procedure SetFunctionName(const Value: string);
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    function GetExpressionType: TgaSQLExpressionPartType; override;
    procedure InitializeParse; override;
    property FunctionNameToken: TgaSQLTokenListBookmark read FFunctionNameToken;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property FunctionName: string read GetFunctionName write SetFunctionName;
    property FunctionParameters: TgaSQLFunctionParamsList read 
            FFunctionParameters;
  end;
  
  TgaSQLExpressionSubselect = class (TgaSQLExpressionPart)
  private
    FFirstToken: Boolean;
    FSelectStm: TgaCustomSQLStatement;
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    function GetExpressionType: TgaSQLExpressionPartType; override;
    procedure InitializeParse; override;
    procedure InternalSetParseComplete; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property SelectStm: TgaCustomSQLStatement read FSelectStm;
  end;
  
  TgaSQLExpression = class (TgaSQLMultipartExpression)
  protected
    procedure InitializeParse; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
  end;
  
  TgaSQLSubExpression = class (TgaSQLExpressionPart)
  private
    FExpressionBody: TgaSQLExpression;
  protected
    procedure DiscardParse; override;
    function GetCanParseEnd: Boolean; override;
    function GetExpressionType: TgaSQLExpressionPartType; override;
    procedure InitializeParse; override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
    property ExpressionBody: TgaSQLExpression read FExpressionBody;
  end;
  
  TgaSQLWhereExpression = class (TgaSQLMultipartExpression)
  protected
    function GetAsString: string; override;
    procedure SetAsString(const Value: string); override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  
  TgaJoinOnPredicate = class (TgaSQLMultipartExpression)
  protected
    function GetAsString: string; override;
    procedure SetAsString(const Value: string); override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  

  TgaHavingClause = class (TgaSQLMultipartExpression)
  protected
    function GetAsString: string; override;
    procedure SetAsString(const Value: string); override;
  public
    procedure AcceptParserVisitor(Visitor: TgaParserVisitorBase); override;
    procedure ExecuteTokenAdded(Sender: TObject; AToken: TgaSQLTokenObj); 
            override;
  end;
  
implementation

uses
  gaParserVisitor, gaSQLParserConsts, SysUtils, gaSQLFieldRefParsers;

{
***************************** TgaSQLExpressionBase *****************************
}
procedure TgaSQLExpressionBase.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionBase(Self);
end;

{
***************************** TgaSQLExpressionPart *****************************
}
procedure TgaSQLExpressionPart.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionPart(Self);
end;

{
*************************** TgaSQLExpressionConstant ***************************
}
procedure TgaSQLExpressionConstant.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionConstant(Self);
end;

procedure TgaSQLExpressionConstant.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  Assert(AToken.TokenType in [stParameter, stString, stNumber]);
  inherited ExecuteTokenAdded(Sender, AToken);
  ParseComplete := True;
end;

function TgaSQLExpressionConstant.GetExpressionType: TgaSQLExpressionPartType;
begin
  Result := eptConstant;
end;

{
*************************** TgaSQLExpressionOperator ***************************
}
procedure TgaSQLExpressionOperator.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionOperator(Self);
end;

procedure TgaSQLExpressionOperator.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  Assert(not (AToken.TokenType in [stDelimitier, stComment, stEnd, stPlaceHolder]));
  inherited ExecuteTokenAdded(Sender, AToken);
  ParseComplete := True;
end;

function TgaSQLExpressionOperator.GetExpressionType: TgaSQLExpressionPartType;
begin
  Result := eptOperator;
end;

{
************************** TgaSQLMultipartExpression ***************************
}
procedure TgaSQLMultipartExpression.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLMultipartExpression(Self);
end;

procedure TgaSQLMultipartExpression.DiscardParse;
var
  tmpSubPart: TgaSQLExpressionPart;
begin
  FreeAndNil(FExpressionScanner);
  while FFirstSubPart <> nil do
  begin
    tmpSubPart := FFirstSubPart;
    FFirstSubPart := tmpSubPart.NextExpressionPart;
    tmpSubPart.Free;
  end;
  FLastSubPart := nil;
  inherited DiscardParse;
end;

procedure TgaSQLMultipartExpression.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
var
  TokenScanNeeded: Boolean;
begin
  inherited ExecuteTokenAdded(Sender, AToken);
  if InPartParse then
  begin
    TokenScanNeeded := True;
    if ExpressionPartInParse <> nil then
    begin
      if ExpressionPartInParse.IsEmpty or (ExpressionPartInParse.LastItem <> CurrentItem) then
        ExpressionPartInParse.SetEndPos(Self, False);
      if ExpressionPartInParse.IsTokenValid(AToken) then
      begin
        TokenScanNeeded := False;
        ExpressionPartInParse.ExecuteTokenAdded(Sender, AToken);
        if ExpressionPartInParse.ParseComplete then
          FExpressionPartInParse := nil;
      end
      else
      begin
        Assert(ExpressionPartInParse.ParseStarted);
        ExpressionPartInParse.CompleteParseAtPreviousToken;
        FExpressionPartInParse := nil;
      end;
    end;
    if TokenScanNeeded then
    begin
      if AToken.TokenType = stRParen then
      begin
        IsInvalid := True;
        Exit;
      end;
      if FExpressionScanner = nil then
      begin
        FExpressionScanner := TgaSQLExpressionPartBuilder.Create(OwnerStatement);
        FExpressionScanner.SetStartPos(Self, True);
      end;
      if ExpressionScanner.IsEmpty or (ExpressionScanner.LastItem <> CurrentItem) then
        ExpressionScanner.SetEndPos(Self, False);
      ExpressionScanner.ExecuteTokenAdded(Sender, AToken);
      if ExpressionScanner.Decision = ebdFinaldecision then
        RescanExpression;
    end;
  end;
end;

function TgaSQLMultipartExpression.GetCanParseEnd: Boolean;
begin
  if FExpressionPartInParse <> nil then
    Result := FExpressionPartInParse.CanParseEnd
  else if FExpressionScanner <> nil then
    Result := FExpressionScanner.CanParseEnd
  else if LastSubPart <> nil then
    Result := LastSubPart.ExpressionType <> eptOperator
  else
    Result := True;
end;

function TgaSQLMultipartExpression.GetExpressionType: TgaSQLExpressionPartType;
begin
  Result := eptMultipart;
end;

procedure TgaSQLMultipartExpression.InternalSetParseComplete;
begin
  SetEndPos(Self, True);
  if FExpressionScanner <> nil then
    RescanExpression;
  if FExpressionPartInParse <> nil then
  begin
    Last;
    ExpressionPartInParse.Locate(CurrentItem);
    ExpressionPartInParse.ParseComplete := True;
    FExpressionPartInParse := nil;
  end;
  inherited InternalSetParseComplete;
end;

procedure TgaSQLMultipartExpression.RescanExpression;
begin
  Assert(ExpressionScanner <> nil);
  ExpressionScanner.First;
  if (ExpressionScanner.Decision > ebdInsufficientInfo) and Locate(ExpressionScanner.CurrentItem) then
  begin
    FExpressionPartInParse := ExpressionScanner.CreateExpressionPart;
    if FFirstSubPart = nil then
    begin
      FFirstSubPart := FExpressionPartInParse;
      FLastSubPart := FExpressionPartInParse;
    end else
    begin
      FExpressionPartInParse.FPreviousExpressionPart := FLastSubPart;
      FLastSubPart.FNextExpressionPart := FExpressionPartInParse;
      FLastSubPart := FExpressionPartInParse;
    end;
    FreeAndNil(FExpressionScanner);
    while not Eof do
    begin
      ExecuteTokenAdded(Self, CurrentItem);
      Next;
    end;
  end
  else
    FreeAndNil(FExpressionScanner);
end;

{
***************************** TgaSQLSubExpression ******************************
}
procedure TgaSQLSubExpression.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLSubExpression(Self);
end;

procedure TgaSQLSubExpression.DiscardParse;
begin
  inherited DiscardParse;
  FExpressionBody.Free;
end;

procedure TgaSQLSubExpression.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if (not ParseStarted) then
  begin
    if (AToken.TokenType <> stLParen) then
      raise Exception.Create('Subexpression must start with "("');
  inherited ExecuteTokenAdded(Sender, AToken);
    Next;
    ExpressionBody.SetStartPos(Self, True);
  end
  else begin
    inherited ExecuteTokenAdded(Sender, AToken);
    if ExpressionBody.IsEmpty or (ExpressionBody.LastItem <> CurrentItem) then
      ExpressionBody.SetEndPos(Self, False);
    if ExpressionBody.CanParseEnd and (AToken.TokenType = stRParen) then
    begin
      ExpressionBody.CompleteParseAtPreviousToken;
      ParseComplete := True;
    end else
      ExpressionBody.ExecuteTokenAdded(Self, AToken);
  end;
end;

function TgaSQLSubExpression.GetCanParseEnd: Boolean;
begin
  Result := False;
end;

function TgaSQLSubExpression.GetExpressionType: TgaSQLExpressionPartType;
begin
  Result := eptMultipart;
end;

procedure TgaSQLSubExpression.InitializeParse;
begin
  inherited InitializeParse;
  FExpressionBody := TgaSQLExpression.Create(OwnerStatement);
end;

{
************************* TgaSQLExpressionPartBuilder **************************
}
procedure TgaSQLExpressionPartBuilder.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionPartBuilder(Self);
end;

function TgaSQLExpressionPartBuilder.CreateExpressionPart: TgaSQLExpressionPart;
begin
  ParseComplete := True;
  case ExpressionType of
    eptMultipart:
      Result := TgaSQLSubExpression.Create(OwnerStatement);
    eptFieldRef:
      Result := TgaSQLFieldReference.Create(OwnerStatement);
    eptConstant:
      Result := TgaSQLExpressionConstant.Create(OwnerStatement);
    eptFunction:
      Result := TgaSQLExpressionFunction.Create(OwnerStatement);
    eptOperator:
      Result := TgaSQLExpressionOperator.Create(OwnerStatement);
    eptSubSelect:
      Result := TgaSQLExpressionSubselect.Create(OwnerStatement);
  else
    Result := TgaSQLUnrecognizedExpression.Create(OwnerStatement);
  end;
  First;
  Result.SetStartPos(Self, True);
end;

procedure TgaSQLExpressionPartBuilder.ExecuteTokenAdded(Sender: TObject; 
        AToken: TgaSQLTokenObj);
begin
  if (ScanState = ebsNoTokensParsed) and (AToken.TokenType in [stDelimitier, stComment]) then
    Exit;
  inherited ExecuteTokenAdded(Sender, AToken);
  case ScanState of
    ebsNoTokensParsed: ScanFirstToken(AToken);
    ebsSymbolParsed: ScanAfterFirstSymbol(AToken);
    ebsLParenScanned: ScanAfterLParen(AToken);
    ebsAfterSymbolSequence: ScanAfterSymbolSeq(AToken);
    ebsScanDone: Assert(False, 'Expression scan done, can''t continue scanning');
    else
      Assert(False, 'Unimplemented scan state');
  end;
end;

function TgaSQLExpressionPartBuilder.GetCanParseEnd: Boolean;
begin
  Result := ScanState <> ebsLParenScanned;
end;

function TgaSQLExpressionPartBuilder.GetExpressionType: 
        TgaSQLExpressionPartType;
begin
  Result := FExpressionType;
end;

procedure TgaSQLExpressionPartBuilder.InitializeParse;
begin
  inherited InitializeParse;
  FExpressionType := eptUnknown;
  FDecision := ebdInsufficientInfo;
  FScanState := ebsNoTokensParsed;
end;

procedure TgaSQLExpressionPartBuilder.ScanAfterFirstSymbol(AToken: 
        TgaSQLTokenObj);
begin
  case AToken.TokenType of
    stSymbol:
      if AToken.TokenSymbolIs('SELECT') then
      begin
        FScanState := ebsScanDone;
        FExpressionType := eptSubSelect;
        FDecision := ebdFinaldecision;
      end;
    stQuotedSymbol, stComment: ; //
    stPeriod: begin
      FDecision := ebdFinaldecision;
      FScanState := ebsScanDone;
      FExpressionType := eptFieldRef;
    end;
    stDelimitier:
      FScanState := ebsAfterSymbolSequence;
    stLParen: begin
      FScanState := ebsScanDone;
      FExpressionType := eptFunction;
      FDecision := ebdFinaldecision;
    end;
    else begin
      FScanState := ebsScanDone;
      FDecision := ebdFinaldecision;
    end;
  end;
end;

procedure TgaSQLExpressionPartBuilder.ScanAfterLParen(AToken: TgaSQLTokenObj);
begin
  case AToken.TokenType of
    stDelimitier, stComment: ;
    stSymbol: begin
      if AToken.TokenSymbolIs('SELECT') then
        FExpressionType := eptSubSelect;
      FDecision := ebdFinaldecision;
      FScanState := ebsScanDone;
    end;
    else begin
      FDecision := ebdFinaldecision;
      FScanState := ebsScanDone;
    end;
  end;
end;

procedure TgaSQLExpressionPartBuilder.ScanAfterSymbolSeq(AToken: 
        TgaSQLTokenObj);
begin
  case AToken.TokenType of
    stDelimitier, stComment: ;
    stLParen: begin
      FScanState := ebsScanDone;
      FExpressionType := eptFunction;
      FDecision := ebdFinaldecision;
    end;
    else begin
      FScanState := ebsScanDone;
      FDecision := ebdFinaldecision;
    end;
  end;
end;

procedure TgaSQLExpressionPartBuilder.ScanFirstToken(AToken: TgaSQLTokenObj);
begin
  if OwnerStatement.IsTokenOperator(AToken) then
  begin
    FScanState := ebsScanDone;
    FExpressionType := eptOperator;
    FDecision := ebdFinaldecision;
    Exit;
  end;
  case AToken.TokenType of
    stSymbol, stQuotedSymbol: begin
      FDecision := ebdSuggestion;
      FExpressionType := eptFieldRef;
      FScanState := ebsSymbolParsed;
    end;
    stParameter, stString, stNumber: begin
      FDecision := ebdFinaldecision;
      FExpressionType := eptConstant;
      FScanState := ebsScanDone;
    end;
    stDelimitier, stComment, stPlaceHolder, stEQ,(* stSubStatementEnd, *)stEnd:
      Assert(False);
    stComma, stPeriod, stRParen:
    begin
      FDecision := ebdFinaldecision;
      FScanState := ebsScanDone;
      FExpressionType := eptUnrecognized;
    end;
    stLParen: begin
      FScanState := ebsLParenScanned;
      FDecision := ebdSuggestion;
      FExpressionType := eptMultipart;
    end;
    stOther: begin
      FDecision := ebdFinaldecision;
      FScanState := ebsScanDone;
      FExpressionType := eptUnrecognized;
    end;
    else
    begin
      FDecision := ebdFinaldecision;
      FScanState := ebsScanDone;
      FExpressionType := eptUnrecognized;
    end;
  end;
end;

{
*************************** TgaSQLExpressionFunction ***************************
}
procedure TgaSQLExpressionFunction.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionFunction(Self);
end;

procedure TgaSQLExpressionFunction.DiscardParse;
begin
  inherited DiscardParse;
  FFunctionNameToken.Free;
  FFunctionNameToken := nil;
  FFunctionParameters.Free;
  FFunctionParameters := nil;
end;

procedure TgaSQLExpressionFunction.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if not ParseStarted then
  begin
  inherited ExecuteTokenAdded(Sender, AToken);
    Assert(AToken.TokenType in [stSymbol, stQuotedSymbol]);
    FFunctionNameToken := GetBookmark;
    FFunctionParameters.AllowAsterixParam := FFunctionNameToken.TokenObj.TokenSymbolIs('COUNT');
  end else
  begin
    inherited ExecuteTokenAdded(Sender, AToken);
    if not FParameterParseStarted then
    begin
      if AToken.TokenType in [stComment, stDelimitier] then
        Exit;
      if AToken.TokenType <> stLParen then
        IsInvalid := True;
      FParameterParseStarted := True;
    end else
    begin
      if FunctionParameters.TokenList.IsEmpty or (FunctionParameters.TokenList.LastItem <> CurrentItem) then
        FunctionParameters.TokenList.SetEndPos(Self, False);
      if FunctionParameters.CanParseEnd and (AToken.TokenType = stRParen) then
      begin
        FunctionParameters.CompleteParseAtPreviousToken;
        ParseComplete := True;
      end
      else
        FunctionParameters.ExecuteTokenAdded(Self, AToken);
    end;
  end;
end;

function TgaSQLExpressionFunction.GetCanParseEnd: Boolean;
begin
  Result := False;
end;

function TgaSQLExpressionFunction.GetExpressionType: TgaSQLExpressionPartType;
begin
  Result := eptFunction;
end;

function TgaSQLExpressionFunction.GetFunctionName: string;
begin
  if FFunctionNameToken <> nil then
    Result := GetTokenObjAsString(FFunctionNameToken.TokenObj)
  else
    Result := '';
end;

procedure TgaSQLExpressionFunction.InitializeParse;
begin
  inherited InitializeParse;
  FParameterParseStarted := False;
  FFunctionParameters := TgaSQLFunctionParamsList.Create(OwnerStatement);
end;

procedure TgaSQLExpressionFunction.SetFunctionName(const Value: string);
var
  tmpTokenList: TgaSQLTokenHolderList;
begin
  if FunctionName <> Value then
  begin
    CheckModifyAllowed;
    tmpTokenList := TgaSQLTokenHolderList.Create(nil);
    try
      ParseStringToTokens(Value, tmpTokenList);
      TrimTokenList(tmpTokenList, True);
      if tmpTokenList.Count <> 1 then
        raise Exception.CreateFmt(SerrWrongTokenCountInArg, ['Function name', 1, tmpTokenList.Count]);
      tmpTokenList.First;
      FFunctionNameToken.TokenObj := tmpTokenList.CurrentItem;
    finally
      tmpTokenList.Free;
    end;
  end;
end;

{
************************** TgaSQLExpressionSubselect ***************************
}
procedure TgaSQLExpressionSubselect.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionSubselect(Self);
end;

procedure TgaSQLExpressionSubselect.DiscardParse;
begin
  inherited DiscardParse;
  FreeAndNil(FSelectStm);
end;

procedure TgaSQLExpressionSubselect.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  inherited ExecuteTokenAdded(Sender, AToken);
  if FFirstToken then
  begin
    Assert(AToken.TokenType = stLParen);
    FFirstToken := False;
  end
  else begin
    if (SelectStm = nil) and AToken.TokenSymbolIs('SELECT') then
        FSelectStm := TgaAdvancedSQLParser.GetStatementClassForToken('SELECT').CreateOwned(OwnerStatement);
    if SelectStm = nil then
        Assert(AToken.TokenType in [stComment, stDelimitier])
    else
    begin
      if SelectStm.CanParseEnd and (AToken.TokenType = stRParen) then
      begin
        SelectStm.CurrentSQL.Locate(CurrentItem);
        SelectStm.CurrentSQL.Previous;
        SelectStm.FinishSubStatement;
        ParseComplete := True;
      end
      else
        SelectStm.DoTokenAdded(Sender, AToken);
    end;
  end;
end;

function TgaSQLExpressionSubselect.GetCanParseEnd: Boolean;
begin
  Result := False;
end;

function TgaSQLExpressionSubselect.GetExpressionType: TgaSQLExpressionPartType;
begin
  Result := eptSubSelect;
end;

procedure TgaSQLExpressionSubselect.InitializeParse;
begin
  inherited InitializeParse;
  FFirstToken := True;
end;

procedure TgaSQLExpressionSubselect.InternalSetParseComplete;
begin
  inherited InternalSetParseComplete;
end;

{
******************************* TgaSQLExpression *******************************
}
procedure TgaSQLExpression.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpression(Self);
end;

procedure TgaSQLExpression.InitializeParse;
begin
  inherited;
  InPartParse := True;
end;

{
**************************** TgaSQLWhereExpression *****************************
}
procedure TgaSQLWhereExpression.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLWhereExpression(Self);
end;

procedure TgaSQLWhereExpression.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if not ParseStarted then
  begin
    // Wait for "where"
    if AToken.TokenType in [stDelimitier, stComment] then
      Exit;
    if not AToken.TokenSymbolIs('WHERE') then
      raise EgaSQLParserException.Create('Where clause must start with "where" keyword');
  end
  else if not InPartParse then
    InPartParse := not (AToken.TokenType in [stDelimitier, stComment]);
  inherited ExecuteTokenAdded(Sender, AToken);
end;

function TgaSQLWhereExpression.GetAsString: string;
begin
  Result := '';
  if IsEmpty then
    Exit;
  First;
  if CurrentItem.TokenSymbolIs('WHERE') then
  begin
    Next;
    while (not Eof) and (CurrentItem.TokenType = stDelimitier) do
      Next;
  end;
  while not Eof do
  begin
    Result := Result + CurrentItem.TokenAsString;
    Next;
  end;
end;

procedure TgaSQLWhereExpression.SetAsString(const Value: string);
var
  tmpStr: string;
  tmpToken: TgaSQLTokenObj;
begin
  if (Trim(Value) = '') or (SameText('where ', Copy(Value, 1, 6))) then
    tmpStr := Value
  else
    tmpStr := 'where ' + Value;
  inherited SetAsString(tmpStr);
  Last;
  if CurrentItem.TokenType <> stDelimitier then
  begin
    tmpToken := TgaSQLTokenObj.CreateDelimitier;
    InsertAfterCurrent(tmpToken, True);
    ExecuteTokenAdded(Self, tmpToken);
  end;
end;

{
****************************** TgaJoinOnPredicate ******************************
}
procedure TgaJoinOnPredicate.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitJoinOnPredicate(Self);
end;

procedure TgaJoinOnPredicate.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if not ParseStarted then
  begin
    // Wait for "on"
    if AToken.TokenType in [stDelimitier, stComment] then
      Exit;
    if not AToken.TokenSymbolIs('ON') then
      raise EgaSQLParserException.Create('JOIN ON predicate must start with "ON" keyword');
  end
  else if not InPartParse then
    InPartParse := not (AToken.TokenType in [stDelimitier, stComment]);
  inherited ExecuteTokenAdded(Sender, AToken);
end;

function TgaJoinOnPredicate.GetAsString: string;
begin
  Result := '';
  if IsEmpty then
    Exit;
  First;
  if CurrentItem.TokenSymbolIs('ON') then
  begin
    Next;
    while (not Eof) and (CurrentItem.TokenType = stDelimitier) do
      Next;
  end;
  while not Eof do
  begin
    Result := Result + CurrentItem.TokenAsString;
    Next;
  end;
end;

procedure TgaJoinOnPredicate.SetAsString(const Value: string);
var
  tmpStr: string;
  tmpToken: TgaSQLTokenObj;
begin
  if (Trim(Value) = '') or (SameText('on ', Copy(Value, 1, 3))) then
    tmpStr := Value
  else
    tmpStr := 'on ' + Value;
  inherited SetAsString(tmpStr);
  Last;
  if CurrentItem.TokenType <> stDelimitier then
  begin
    tmpToken := TgaSQLTokenObj.CreateDelimitier;
    Add(tmpToken);
    ExecuteTokenAdded(Self, tmpToken);
  end;
end;

{
************************* TgaSQLUnrecognizedExpression *************************
}
procedure TgaSQLUnrecognizedExpression.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLUnrecognizedExpression(Self);
end;

procedure TgaSQLUnrecognizedExpression.ExecuteTokenAdded(Sender: TObject; 
        AToken: TgaSQLTokenObj);
begin
  inherited ExecuteTokenAdded(Sender, AToken);
  ParseComplete := True;
end;

function TgaSQLUnrecognizedExpression.GetExpressionType: 
        TgaSQLExpressionPartType;
begin
  Result := eptUnrecognized;
end;

{
***************************** TgaSQLExpressionList *****************************
}
constructor TgaSQLExpressionList.Create(AOwnerStatement: TgaCustomSQLStatement);
begin
  inherited Create(AOwnerStatement, TgaSQLExpression);
end;

procedure TgaSQLExpressionList.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLExpressionList(Self);
end;

{
*************************** TgaSQLFunctionParamsList ***************************
}
procedure TgaSQLFunctionParamsList.AcceptParserVisitor(Visitor: 
        TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitSQLFunctionParamsList(Self);
end;

function TgaSQLFunctionParamsList.CreateNewPart(ForToken: TgaSQLTokenObj): 
        TgaSQLStatementPart;
begin
  if AllowAsterixParam and (ForToken.TokenString = '*') then
    Result := TgaSQLFieldReference.Create(OwnerStatement)
  else
    Result := inherited CreateNewPart(ForToken);
end;

{ TgaHavingClause }

{
******************************* TgaHavingClause ********************************
}
procedure TgaHavingClause.AcceptParserVisitor(Visitor: TgaParserVisitorBase);
begin
  Assert(Visitor is TgaCustomParserVisitor, Format(SassIncorrectParserVisitor, [Visitor.ClassName]));
  TgaCustomParserVisitor(Visitor).VisitHavingClause(Self);
end;

procedure TgaHavingClause.ExecuteTokenAdded(Sender: TObject; AToken: 
        TgaSQLTokenObj);
begin
  if not ParseStarted then
  begin
    if AToken.TokenType in [stDelimitier, stComment] then
      Exit;
    if not AToken.TokenSymbolIs('HAVING') then
      raise EgaSQLParserException.Create('HAVING clause must start with "HAVING" keyword');
  end
  else if not InPartParse then
    InPartParse := not (AToken.TokenType in [stDelimitier, stComment]);
  inherited ExecuteTokenAdded(Sender, AToken);
end;

function TgaHavingClause.GetAsString: string;
begin
  Result := '';
  if IsEmpty then
    Exit;
  First;
  if CurrentItem.TokenSymbolIs('HAVING') then
  begin
    Next;
    while (not Eof) and (CurrentItem.TokenType = stDelimitier) do
      Next;
  end;
  while not Eof do
  begin
    Result := Result + CurrentItem.TokenAsString;
    Next;
  end;
end;

procedure TgaHavingClause.SetAsString(const Value: string);
var
  tmpStr: string;
  tmpToken: TgaSQLTokenObj;
begin
  if (Trim(Value) = '') or (SameText('having ', Copy(Value, 1, 7))) then
    tmpStr := Value
  else
    tmpStr := 'having ' + Value;
  inherited SetAsString(tmpStr);
  Last;
  if CurrentItem.TokenType <> stDelimitier then
  begin
    tmpToken := TgaSQLTokenObj.CreateDelimitier;
    Add(tmpToken);
    ExecuteTokenAdded(Self, tmpToken);
  end;
end;

end.
