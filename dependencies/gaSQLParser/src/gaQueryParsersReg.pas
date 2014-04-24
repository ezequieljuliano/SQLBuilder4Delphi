{*******************************************************}
{                                                       }
{       SQL statement parser components                 }
{       Copyright (c) 2001 - 2003 AS Gaiasoft           }
{       Created by Gert Kello                           }
{                                                       }
{*******************************************************}

unit gaQueryParsersReg;

interface

procedure Register;

implementation

uses
  Classes, gaBasicSQLParser, gaAdvancedSQLParser;

procedure Register;
begin
  RegisterComponents('Samples', [TgaBasicSQLParser, TgaAdvancedSQLParser]);
end;

end.
