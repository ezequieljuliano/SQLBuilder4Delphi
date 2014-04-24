{*******************************************************}
{                                                       }
{       Advanced SQL statement parser                   }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaSQLParserConsts;

interface

resourcestring
  SUnknownStatementState = '%s: Unexpected statement state "%s". Don''t know how to modify it';
  STokenInsertBeforeNotInSQL = 'Token to be used qas insert point is not a part of current SQL';
  STokenToBeRemovedNotInSQL = 'Token to be removed is not a part of current SQL';
  STokenToBeReplacedNotInSQL = 'Token to be replaced is not a part of current SQL';
  SWrongSpecialChar = 'Char "%s" is treated as speacial char but it''s type is unknown';
  SerrUnecpectedFieldParseState = 'Unexpected field expression parsing state "%s"';
  SerrUnecpectedTableParseState = 'Unexpected table expression parsing state "%s"';
  SerrWrongTokenCountInArg = 'Wrong token count in argument for %s: expected %d actual %d';
  SerrNoInsPointForAlias = 'Can''t find a point where the field alias should go..';
  SerrFieldAttrCantBeChangedInExpression = 'Can not change field attributes in expression';
  SerrNoTableForAlias = 'Can''t set alias for table without table name';
  SerrTableAliasNotAllowed = 'Using table alias is not allowed';
  SerrNowOwnerParser = 'Statement part cannot be editied if owning statement not set';
  SerrStmPartWithoutStm = 'Can''t create statement part without owner statement';
  SassIncorrectParserVisitor = 'Incorrect parser visitor class %s';
  SerrStmPartParseFinised = 'Cant "ExecuteTokeAdded": stament part parse finished, part parser class: "%s"';
  SerrStmPartParseInvalid = 'Cant "ExecuteTokeAdded": stament part inavlid, part parser class: "%s"';

implementation

end.

