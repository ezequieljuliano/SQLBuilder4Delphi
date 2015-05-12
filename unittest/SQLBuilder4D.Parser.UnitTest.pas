unit SQLBuilder4D.Parser.UnitTest;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  System.TypInfo,
  SQLBuilder4D.Parser,
  SQLBuilder4D.Parser.GaSQLParser;

type

  TTestSQLBuilder4DParser = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSQLSelect();
  end;

implementation


{ TTestSQLBuilder4DParser }

procedure TTestSQLBuilder4DParser.SetUp;
begin
  inherited;

end;

procedure TTestSQLBuilder4DParser.TearDown;
begin
  inherited;

end;

procedure TTestSQLBuilder4DParser.TestSQLSelect;
const
  cSQL = 'Select ' + sLineBreak +
    '   Customers.C_Cod, ' + sLineBreak +
    '   Customers.C_Name, ' + sLineBreak +
    '   Customers.C_Doc, ' + sLineBreak +
    '   Sum(Customers.C_Limit) as Limite  ' + sLineBreak +
    'From Customers ' + sLineBreak +
    'Inner Join Places On (Customers.P_Code = Places.P_Code) ' + sLineBreak +
    'Where ' + sLineBreak +
    '    (Customers.C_Cod = 10) And ' + sLineBreak +
    '    (Customers.C_Name = ''Ezequiel'') ' + sLineBreak +
    'Group By ' + sLineBreak +
    '     Customers.C_Cod, ' + sLineBreak +
    '     Customers.C_Name, ' + sLineBreak +
    '     Customers.C_Doc ' + sLineBreak +
    'Having ' + sLineBreak +
    '    (Customers.C_Cod > 0) ' + sLineBreak +
    'Order By ' + sLineBreak +
    '     Customers.C_Cod ';

  cSQLColumns = 'Customers.C_Cod, ' + sLineBreak +
    '   Customers.C_Name, ' + sLineBreak +
    '   Customers.C_Doc, ' + sLineBreak +
    '   Sum(Customers.C_Limit) as Limite  ' + sLineBreak;

  cSQLFrom = ' Customers ' + sLineBreak;

  cSQLJoin = 'Inner Join Places On (Customers.P_Code = Places.P_Code) ' + sLineBreak;

  cSQLWhere = '(Customers.C_Cod = 10) And ' + sLineBreak +
    '    (Customers.C_Name = ''Ezequiel'') ' + sLineBreak;

  cSQLGroupBy = 'Customers.C_Cod, ' + sLineBreak +
    '     Customers.C_Name, ' + sLineBreak +
    '     Customers.C_Doc ' + sLineBreak;

  cSQLHaving = '(Customers.C_Cod > 0) ' + sLineBreak;

  cSQLOrderBy = 'Customers.C_Cod ' + sLineBreak;

  cSetSQLColumn = 'Customers.C_Name, ' + sLineBreak +
    '   Customers.C_Cod, ' + sLineBreak +
    '   Customers.C_Doc, ' + sLineBreak +
    '   Sum(Customers.C_Value) as Value  ' + sLineBreak;

  cSetSQLFrom = ' Customers C ' + sLineBreak;

  cSetSQLJoin = 'Left Outer Join Places On (Customers.P_Code = Places.P_Code) ' + sLineBreak;

  cSetSQLWhere = '(Customers.C_Cod = 500) And ' + sLineBreak +
    '    (Customers.C_Name = ''Juliano'') ' + sLineBreak;

  cSetSQLGroupBy = 'Customers.C_Name, ' + sLineBreak +
    '     Customers.C_Cod, ' + sLineBreak +
    '     Customers.C_Doc ' + sLineBreak;

  cSetSQLHaving = '(Customers.C_Doc > 0) ' + sLineBreak;

  cSetSQLOrderBy = 'Customers.C_Doc ' + sLineBreak;

  cSQLValidateSet = 'Select ' + sLineBreak +
    '   Customers.C_Name, ' + sLineBreak +
    '   Customers.C_Cod, ' + sLineBreak +
    '   Customers.C_Doc, ' + sLineBreak +
    '   Sum(Customers.C_Value) as Value  ' + sLineBreak +
    'From Customers C ' + sLineBreak +
    'Left Outer Join Places On (Customers.P_Code = Places.P_Code) ' + sLineBreak +
    'where ' +
    '(Customers.C_Cod = 500) And ' + sLineBreak +
    '    (Customers.C_Name = ''Juliano'') ' + sLineBreak +
    'group by ' +
    'Customers.C_Name, ' + sLineBreak +
    '     Customers.C_Cod, ' + sLineBreak +
    '     Customers.C_Doc ' + sLineBreak +
    'having ' +
    '(Customers.C_Doc > 0) ' + sLineBreak +
    'order by ' +
    'Customers.C_Doc ' + sLineBreak;

  cSQLValidateAdd = 'Select ' + sLineBreak +
    '   Customers.C_Cod, ' + sLineBreak +
    '   Customers.C_Name, ' + sLineBreak +
    '   Customers.C_Doc, ' + sLineBreak +
    '   Sum(Customers.C_Limit) as Limite  ' + sLineBreak +
    ',' +
    ' Customers.C_Test ' +
    'From Customers ' + sLineBreak +
    ',' +
    ' Customers S ' +
    'Inner Join Places On (Customers.P_Code = Places.P_Code) ' + sLineBreak +
    'Left Outer Join Places On (Customers.P_Code = Places.P_Code) ' +
    'where ' +
    '(Customers.C_Cod = 10) And ' + sLineBreak +
    '    (Customers.C_Name = ''Ezequiel'') ' + sLineBreak +
    ' And ((Customers.C_Cod = 700)) ' +
    'group by ' +
    'Customers.C_Cod, ' + sLineBreak +
    '     Customers.C_Name, ' + sLineBreak +
    '     Customers.C_Doc ' + sLineBreak +
    ',' +
    ' Customers.C_Value ' +
    'having ' +
    '(Customers.C_Cod > 0) ' + sLineBreak +
    ' And ((Customers.C_Doc < 300)) ' +
    'order by ' +
    'Customers.C_Cod ' + sLineBreak +
    ', Customers.C_Doc ';
var
  vSQLParserSelect: ISQLParserSelect;
begin
  vSQLParserSelect := TGaSQLParserFactory.Select(cSQL);

  CheckEqualsString(cSQLColumns, vSQLParserSelect.Columns);
  CheckEqualsString(cSQLFrom, vSQLParserSelect.From);
  CheckEqualsString(cSQLJoin, vSQLParserSelect.Join);
  CheckEqualsString(cSQLWhere, vSQLParserSelect.Where);
  CheckEqualsString(cSQLGroupBy, vSQLParserSelect.GroupBy);
  CheckEqualsString(cSQLHaving, vSQLParserSelect.Having);
  CheckEqualsString(cSQLOrderBy, vSQLParserSelect.OrderBy);

  vSQLParserSelect.SetColumns(cSetSQLColumn);
  vSQLParserSelect.SetFrom(cSetSQLFrom);
  vSQLParserSelect.SetJoin(cSetSQLJoin);
  vSQLParserSelect.SetWhere(cSetSQLWhere);
  vSQLParserSelect.SetGroupBy(cSetSQLGroupBy);
  vSQLParserSelect.SetHaving(cSetSQLHaving);
  vSQLParserSelect.SetOrderBy(cSetSQLOrderBy);
  CheckEqualsString(cSQLValidateSet, vSQLParserSelect.ToString());

  vSQLParserSelect.Parse(cSQL);
  vSQLParserSelect.AddColumns('Customers.C_Test');
  vSQLParserSelect.AddFrom('Customers S');
  vSQLParserSelect.AddJoin('Left Outer Join Places On (Customers.P_Code = Places.P_Code)');
  vSQLParserSelect.AddWhere('(Customers.C_Cod = 700)');
  vSQLParserSelect.AddGroupBy('Customers.C_Value');
  vSQLParserSelect.AddHaving('(Customers.C_Doc < 300)');
  vSQLParserSelect.AddOrderBy('Customers.C_Doc');
  CheckEqualsString(cSQLValidateAdd, vSQLParserSelect.ToString());

  vSQLParserSelect.Parse(cSQL);
  vSQLParserSelect
    .AddColumns('Customers.C_Test')
    .AddFrom('Customers S')
    .AddJoin('Left Outer Join Places On (Customers.P_Code = Places.P_Code)')
    .AddWhere('(Customers.C_Cod = 700)')
    .AddGroupBy('Customers.C_Value')
    .AddHaving('(Customers.C_Doc < 300)')
    .AddOrderBy('Customers.C_Doc');
  CheckEqualsString(cSQLValidateAdd, vSQLParserSelect.ToString());
end;

initialization

RegisterTest(TTestSQLBuilder4DParser.Suite);

end.
