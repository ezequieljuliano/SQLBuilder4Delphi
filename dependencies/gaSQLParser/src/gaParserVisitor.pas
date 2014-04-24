{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Base class for writing visitors                 }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaParserVisitor;

interface

uses
  gaAdvancedSQLParser, gaDeleteStm, gaInsertStm, gaSelectStm, gaUpdateStm,
  gaSQLParserHelperClasses, gaSQLFieldRefParsers, gaSQLSelectFieldParsers,
  gaSQLExpressionParsers, gaSQLTableRefParsers;

type
  TgaCustomParserVisitor = class (TgaParserVisitorBase)
  public
    procedure VisitCustomSQLStatement(Instance: TgaCustomSQLStatement); virtual;
            abstract;
    procedure VisitDeleteSQLStatement(Instance: TgaDeleteSQLStatement); virtual;
            abstract;
    procedure VisitHavingClause(Instance: TgaHavingClause); virtual; abstract;
    procedure VisitInsertSQLStatement(Instance: TgaInsertSQLStatement); virtual;
            abstract;
    procedure VisitJoinClause(Instance: TgaJoinClause); virtual; abstract;
    procedure VisitJoinClauseList(Instance: TgaJoinClauseList); virtual; 
            abstract;
    procedure VisitJoinOnPredicate(Instance: TgaJoinOnPredicate); virtual; 
            abstract;
    procedure VisitListOfSQLTokenLists(Instance: TgaListOfSQLTokenLists); 
            virtual; abstract;
    procedure VisitNoSQLStatement(Instance: TgaNoSQLStatement); virtual; 
            abstract;
    procedure VisitSecondaryFieldReference(Instance: 
            TgaSecondaryFieldReference); virtual; abstract;
    procedure VisitSelectSQLStatement(Instance: TgaSelectSQLStatement); virtual;
            abstract;
    procedure VisitSQLDataReference(Instance: TgaSQLDataReference); virtual; 
            abstract;
    procedure VisitSQLExpression(Instance: TgaSQLExpression); virtual; abstract;
    procedure VisitSQLExpressionBase(Instance: TgaSQLExpressionBase); virtual; 
            abstract;
    procedure VisitSQLExpressionConstant(Instance: TgaSQLExpressionConstant); 
            virtual; abstract;
    procedure VisitSQLExpressionFunction(Instance: TgaSQLExpressionFunction); 
            virtual; abstract;
    procedure VisitSQLExpressionList(Instance: TgaSQLExpressionList); virtual; 
            abstract;
    procedure VisitSQLExpressionOperator(Instance: TgaSQLExpressionOperator); 
            virtual; abstract;
    procedure VisitSQLExpressionPart(Instance: TgaSQLExpressionPart); virtual; 
            abstract;
    procedure VisitSQLExpressionPartBuilder(Instance: 
            TgaSQLExpressionPartBuilder); virtual; abstract;
    procedure VisitSQLExpressionSubselect(Instance: TgaSQLExpressionSubselect); 
            virtual; abstract;
    procedure VisitSQLFieldList(Instance: TgaSQLFieldList); virtual; abstract;
    procedure VisitSQLFieldReference(Instance: TgaSQLFieldReference); virtual; 
            abstract;
    procedure VisitSQLFunctionParamsList(Instance: TgaSQLFunctionParamsList); 
            virtual; abstract;
    procedure VisitSQLGroupByList(Instance: TgaSQLGroupByList); virtual; 
            abstract;
    procedure VisitSQLGroupByReference(Instance: TgaSQLGroupByReference); 
            virtual; abstract;
    procedure VisitSQLMultipartExpression(Instance: TgaSQLMultipartExpression); 
            virtual; abstract;
    procedure VisitSQLOrderByList(Instance: TgaSQLOrderByList); virtual; 
            abstract;
    procedure VisitSQLOrderByReference(Instance: TgaSQLOrderByReference); 
            virtual; abstract;
    procedure VisitSQLSelectExpression(Instance: TgaSQLSelectExpression); 
            virtual; abstract;
    procedure VisitSQLSelectField(Instance: TgaSQLSelectField); virtual; 
            abstract;
    procedure VisitSQLSelectFieldList(Instance: TgaSQLSelectFieldList); virtual;
            abstract;
    procedure VisitSQLSelectReference(Instance: TgaSQLSelectReference); virtual;
            abstract;
    procedure VisitSQLStatementPart(Instance: TgaSQLStatementPart); virtual; 
            abstract;
    procedure VisitSQLStatementPartList(Instance: TgaSQLStatementPartList); 
            virtual; abstract;
    procedure VisitSQLStoredProcReference(Instance: TgaSQLStoredProcReference); 
            virtual; abstract;
    procedure VisitSQLSubExpression(Instance: TgaSQLSubExpression); virtual; 
            abstract;
    procedure VisitSQLTable(Instance: TgaSQLTable); virtual; abstract;
    procedure VisitSQLTableList(Instance: TgaSQLTableList); virtual; abstract;
    procedure VisitSQLTableReference(Instance: TgaSQLTableReference); virtual; 
            abstract;
    procedure VisitSQLTokenHolderList(Instance: TgaSQLTokenHolderList); virtual;
            abstract;
    procedure VisitSQLTokenList(Instance: TgaSQLTokenList); virtual; abstract;
    procedure VisitSQLUnrecognizedExpression(Instance: 
            TgaSQLUnrecognizedExpression); virtual; abstract;
    procedure VisitSQLWhereExpression(Instance: TgaSQLWhereExpression); virtual;
            abstract;
    procedure VisitUnkownSQLStatement(Instance: TgaUnkownSQLStatement); virtual;
            abstract;
    procedure VisitUpdateSQLStatement(Instance: TgaUpdateSQLStatement); virtual;
            abstract;
  end;
  
implementation

end.
