unit SQLBuilder4D.UnitTest;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  System.TypInfo,
  SQLBuilder4D.Parser;

type

  TTestSQLBuilder4D = class(TTestCase)
  strict private
    procedure ValidateSQLInject();
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSQLSelect();
    procedure TestSQLSelectWhere();
    procedure TestSQLSelectWhereCaseInSensitive();
    procedure TestSQLSelectUnion();
    procedure TestSQLSelectDistinct();
    procedure TestSQLSelectColumnCoalesce();
    procedure TestSQLSelectAggregate();
    procedure TestSQLInjection();
    procedure TestSQLDelete();
    procedure TestSQLUpdate();
    procedure TestSQLInsert();
    procedure TestSQLDateTime();
    procedure TestSQLFloat();
    procedure TestSQLParserSelect();
    procedure TestSQLStatementSaveToFile();
    procedure TestSQLClauseSaveToFile();
    procedure TestSQLColumnAlias();
    procedure TestSQLTableAlias();
  end;

implementation

{ TTestSQLBuilder4D }

uses
  SQLBuilder4D;

procedure TTestSQLBuilder4D.SetUp;
begin
  inherited;

end;

procedure TTestSQLBuilder4D.TearDown;
begin
  inherited;

end;

procedure TTestSQLBuilder4D.TestSQLClauseSaveToFile;
const
  cSQLFile = 'SQLFile.SQL';

  cExpected_1 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) And (C_Name <> ''Ezequiel'')' +
    sLineBreak;
var
  vStringList: TStringList;
begin
  vStringList := TStringList.Create;
  try
    TSQLBuilder.Select
      .Column('C_Code')
      .Column('C_Name')
      .Column('C_Doc')
      .From('Customers')
      .Where('C_Code').Equal(1)
      ._And('C_Name').Different('Ezequiel')
      .SaveToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vStringList.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cExpected_1, vStringList.Text);
  finally
    FreeAndNil(vStringList);
  end;
end;

procedure TTestSQLBuilder4D.TestSQLColumnAlias;
const
  cExpected =
    'Select '
    + sLineBreak +
    ' C_Code As Code, C_Name As Name, C_Doc As Doc'
    + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut := TSQLBuilder.Select
    .Column('C_Code', 'Code')
    .Column('C_Name', 'Name')
    .Column('C_Doc', 'Doc')
    .From('Customers').ToString;

  CheckEqualsString(cExpected, vOut);

  vOut := TSQLBuilder.Select
    .Column('C_Code').Alias('Code')
    .Column('C_Name').Alias('Name')
    .Column('C_Doc').Alias('Doc')
    .From('Customers').ToString;

  CheckEqualsString(cExpected, vOut);

  vOut := TSQLBuilder.Select
    .Column('C_Code', 'Code').Alias('Code')
    .Column('C_Name', 'Name').Alias('Name')
    .Column('C_Doc', 'Doc')
    .From('Customers').ToString;

  CheckEqualsString(cExpected, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLDateTime;
const
  cSelectDate =
    'Select '
    + sLineBreak +
    ' *'
    + sLineBreak +
    ' From Customers C'
    + sLineBreak +
    ' Where (C.C_Date = ''01/01/2014'')';

  cSelectDateTime =
    'Select '
    + sLineBreak +
    ' *'
    + sLineBreak +
    ' From Customers C'
    + sLineBreak +
    ' Where (C.C_DateTime = ''01/01/2014 01:05:22'')';

  cSelectTime =
    'Select '
    + sLineBreak +
    ' *'
    + sLineBreak +
    ' From Customers C'
    + sLineBreak +
    ' Where (C.C_Time = ''01:05:22'')';
var
  vOut: string;
begin
  vOut := TSQLBuilder
    .Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Date').Equal('01/01/2014')
    .ToString;

  CheckEqualsString(cSelectDate, vOut);

  vOut := TSQLBuilder
    .Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_DateTime').Equal('01/01/2014 01:05:22')
    .ToString;

  CheckEqualsString(cSelectDateTime, vOut);

  vOut := TSQLBuilder
    .Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Time').Equal('01:05:22')
    .ToString;

  CheckEqualsString(cSelectTime, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLDelete;
const
  cDeleteNormal =
    'Delete From Customers';

  cDeleteWithWhere =
    'Delete From Customers'
    + sLineBreak +
    ' Where (C_Code > 1) And (C_Name <> ''Ejm'') And ((C_Code In (1, 2, 3)) Or (C_Code < 10))';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Delete
    .From('Customers').ToString;
  CheckEqualsString(cDeleteNormal, vOut);

  vOut :=
    TSQLBuilder.Delete
    .From('Customers')
    .Where('C_Code').Greater(1)
    ._And('C_Name').Different('Ejm')
    ._And(
    TSQLBuilder.Where.Column('C_Code').InList([1, 2, 3])
    ._Or('C_Code').Less(10)
    )
    .ToString;
  CheckEqualsString(cDeleteWithWhere, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLFloat;
const
  cSelectDate =
    'Select '
    + sLineBreak +
    ' *'
    + sLineBreak +
    ' From Customers C'
    + sLineBreak +
    ' Where (C.C_Value = 25.22)';
var
  vOut: string;
begin
  vOut := TSQLBuilder
    .Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Value').Equal(25.22)
    .ToString;

  CheckEqualsString(cSelectDate, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLInjection;
begin
  CheckException(
    ValidateSQLInject,
    ESQLBuilderException
    );
end;

procedure TTestSQLBuilder4D.TestSQLInsert;
const
  cInsert =
    'Insert Into Customers'
    + sLineBreak +
    ' (C_Code,'
    + sLineBreak +
    '  C_Name,'
    + sLineBreak +
    '  C_Doc)'
    + sLineBreak +
    ' Values'
    + sLineBreak +
    ' (1,'
    + sLineBreak +
    '  ''Ejm'','
    + sLineBreak +
    '  58)';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Insert
    .Into('Customers')
    .ColumnValue('C_Code', 1)
    .ColumnValue('C_Name', 'Ejm')
    .ColumnValue('C_Doc', 58)
    .ToString;
  CheckEqualsString(cInsert, vOut);

  vOut :=
    TSQLBuilder.Insert
    .Into('Customers')
    .Columns(['C_Code', 'C_Name', 'C_Doc'])
    .Values([1, 'Ejm', 58])
    .ToString;
  CheckEqualsString(cInsert, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLParserSelect;
const
  cSQL =
    'Select '
    + sLineBreak +
    '   Customers.C_Cod, '
    + sLineBreak +
    '   Customers.C_Name, '
    + sLineBreak +
    '   Customers.C_Doc, '
    + sLineBreak +
    '   Sum(Customers.C_Limit) as Limite  '
    + sLineBreak +
    'From Customers '
    + sLineBreak +
    'Inner Join Places On (Customers.P_Code = Places.P_Code) '
    + sLineBreak +
    'Where '
    + sLineBreak +
    '    (Customers.C_Cod = 10) And '
    + sLineBreak +
    '    (Customers.C_Name = ''Ezequiel'') '
    + sLineBreak +
    'Group By '
    + sLineBreak +
    '     Customers.C_Cod, '
    + sLineBreak +
    '     Customers.C_Name, '
    + sLineBreak +
    '     Customers.C_Doc '
    + sLineBreak +
    'Having '
    + sLineBreak +
    '    (Customers.C_Cod > 0) '
    + sLineBreak +
    'Order By '
    + sLineBreak +
    '     Customers.C_Cod ';

  cSQLSelect =
    'Customers.C_Cod, '
    + sLineBreak +
    '   Customers.C_Name, '
    + sLineBreak +
    '   Customers.C_Doc, '
    + sLineBreak +
    '   Sum(Customers.C_Limit) as Limite  '
    + sLineBreak;

  cSQLFrom =
    ' Customers '
    + sLineBreak;

  cSQLJoin =
    'Inner Join Places On (Customers.P_Code = Places.P_Code) '
    + sLineBreak;

  cSQLWhere =
    '(Customers.C_Cod = 10) And '
    + sLineBreak +
    '    (Customers.C_Name = ''Ezequiel'') '
    + sLineBreak;

  cSQLGroupBy =
    'Customers.C_Cod, '
    + sLineBreak +
    '     Customers.C_Name, '
    + sLineBreak +
    '     Customers.C_Doc '
    + sLineBreak;

  cSQLHaving =
    '(Customers.C_Cod > 0) '
    + sLineBreak;

  cSQLOrderBy =
    'Customers.C_Cod '
    + sLineBreak;

  cSetSQLSelect =
    'Customers.C_Name, '
    + sLineBreak +
    '   Customers.C_Cod, '
    + sLineBreak +
    '   Customers.C_Doc, '
    + sLineBreak +
    '   Sum(Customers.C_Value) as Value  '
    + sLineBreak;

  cSetSQLFrom =
    ' Customers C '
    + sLineBreak;

  cSetSQLJoin =
    'Left Outer Join Places On (Customers.P_Code = Places.P_Code) '
    + sLineBreak;

  cSetSQLWhere =
    '(Customers.C_Cod = 500) And '
    + sLineBreak +
    '    (Customers.C_Name = ''Juliano'') '
    + sLineBreak;

  cSetSQLGroupBy =
    'Customers.C_Name, '
    + sLineBreak +
    '     Customers.C_Cod, '
    + sLineBreak +
    '     Customers.C_Doc '
    + sLineBreak;

  cSetSQLHaving =
    '(Customers.C_Doc > 0) '
    + sLineBreak;

  cSetSQLOrderBy =
    'Customers.C_Doc '
    + sLineBreak;

  cSQLValidateSet =
    'Select '
    + sLineBreak +
    '   Customers.C_Name, '
    + sLineBreak +
    '   Customers.C_Cod, '
    + sLineBreak +
    '   Customers.C_Doc, '
    + sLineBreak +
    '   Sum(Customers.C_Value) as Value  '
    + sLineBreak +
    'From Customers C '
    + sLineBreak +
    'Left Outer Join Places On (Customers.P_Code = Places.P_Code) '
    + sLineBreak +
    'where ' +
    '(Customers.C_Cod = 500) And '
    + sLineBreak +
    '    (Customers.C_Name = ''Juliano'') '
    + sLineBreak +
    'group by ' +
    'Customers.C_Name, '
    + sLineBreak +
    '     Customers.C_Cod, '
    + sLineBreak +
    '     Customers.C_Doc '
    + sLineBreak +
    'having ' +
    '(Customers.C_Doc > 0) '
    + sLineBreak +
    'order by ' +
    'Customers.C_Doc '
    + sLineBreak;

  cSQLValidateAddOrSet =
    'Select '
    + sLineBreak +
    '   Customers.C_Cod, '
    + sLineBreak +
    '   Customers.C_Name, '
    + sLineBreak +
    '   Customers.C_Doc, '
    + sLineBreak +
    '   Sum(Customers.C_Limit) as Limite  '
    + sLineBreak +
    ',' +
    ' Customers.C_Test ' +
    'From Customers '
    + sLineBreak +
    ',' +
    ' Customers S ' +
    'Inner Join Places On (Customers.P_Code = Places.P_Code) '
    + sLineBreak +
    'Left Outer Join Places On (Customers.P_Code = Places.P_Code) ' +
    'where ' +
    '(Customers.C_Cod = 10) And '
    + sLineBreak +
    '    (Customers.C_Name = ''Ezequiel'') '
    + sLineBreak +
    ' And ((Customers.C_Cod = 700)) ' +
    'group by ' +
    'Customers.C_Cod, '
    + sLineBreak +
    '     Customers.C_Name, '
    + sLineBreak +
    '     Customers.C_Doc '
    + sLineBreak +
    ',' +
    ' Customers.C_Value ' +
    'having ' +
    '(Customers.C_Cod > 0) '
    + sLineBreak +
    ' And ((Customers.C_Doc < 300)) ' +
    'order by ' +
    'Customers.C_Cod '
    + sLineBreak +
    ', Customers.C_Doc ';
var
  vSQLParserSelect: ISQLParserSelect;
begin
  vSQLParserSelect := TSQLParserFactory.GetSelectInstance(prGaSQLParser);

  vSQLParserSelect.Parse(cSQL);
  CheckEqualsString(cSQLSelect, vSQLParserSelect.GetSelect);
  CheckEqualsString(cSQLFrom, vSQLParserSelect.GetFrom);
  CheckEqualsString(cSQLJoin, vSQLParserSelect.GetJoin);
  CheckEqualsString(cSQLWhere, vSQLParserSelect.GetWhere);
  CheckEqualsString(cSQLGroupBy, vSQLParserSelect.GetGroupBy);
  CheckEqualsString(cSQLHaving, vSQLParserSelect.GetHaving);
  CheckEqualsString(cSQLOrderBy, vSQLParserSelect.GetOrderBy);

  vSQLParserSelect.SetSelect(cSetSQLSelect);
  vSQLParserSelect.SetFrom(cSetSQLFrom);
  vSQLParserSelect.SetJoin(cSetSQLJoin);
  vSQLParserSelect.SetWhere(cSetSQLWhere);
  vSQLParserSelect.SetGroupBy(cSetSQLGroupBy);
  vSQLParserSelect.SetHaving(cSetSQLHaving);
  vSQLParserSelect.SetOrderBy(cSetSQLOrderBy);
  CheckEqualsString(cSQLValidateSet, vSQLParserSelect.GetSQLText);

  vSQLParserSelect.Parse(cSQL);
  vSQLParserSelect.AddOrSetSelect('Customers.C_Test');
  vSQLParserSelect.AddOrSetFrom('Customers S');
  vSQLParserSelect.AddOrSetJoin('Left Outer Join Places On (Customers.P_Code = Places.P_Code)');
  vSQLParserSelect.AddOrSetWhere('(Customers.C_Cod = 700)');
  vSQLParserSelect.AddOrSetGroupBy('Customers.C_Value');
  vSQLParserSelect.AddOrSetHaving('(Customers.C_Doc < 300)');
  vSQLParserSelect.AddOrSetOrderBy('Customers.C_Doc');
  CheckEqualsString(cSQLValidateAddOrSet, vSQLParserSelect.GetSQLText);
end;

procedure TTestSQLBuilder4D.TestSQLSelect;
const
  cSelectAllFields =
    'Select '
    + sLineBreak +
    ' *'
    + sLineBreak +
    ' From Customers';

  cSelectFields =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';

  cSelectWithJoins =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)'
    + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)'
    + sLineBreak +
    ' Left Outer Join Places On (Customers.P_Code = Places.P_Code)'
    + sLineBreak +
    ' Right Outer Join Places On (Customers.P_Code = Places.P_Code)';

  cSelectComplete =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)'
    + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)'
    + sLineBreak +
    ' Left Outer Join Places On (Customers.P_Code = Places.P_Code)'
    + sLineBreak +
    ' Right Outer Join Places On (Customers.P_Code = Places.P_Code)'
    + sLineBreak +
    ' Group By C_Code, C_Name'
    + sLineBreak +
    ' Having ((C_Code > 0))'
    + sLineBreak +
    ' Order By C_Code, C_Doc';

  cSelectSubSelect =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name,' +
    ' (Select '
    + sLineBreak +
    ' C.C_Doc'
    + sLineBreak +
    ' From Customers C'
    + sLineBreak +
    ' Where (C.C_Code = Customers.C_Code)) As Sub'
    + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Select
    .AllColumns
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectAllFields, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectFields, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .ToString;
  CheckEqualsString(cSelectWithJoins, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy.Column('C_Code').Column('C_Name')
    .Having.Aggregate('(C_Code > 0)')
    .OrderBy.Column('C_Code').Column('C_Doc')
    .ToString;
  CheckEqualsString(cSelectComplete, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy(TSQLBuilder.GroupBy.Column('C_Code').Column('C_Name'))
    .Having(TSQLBuilder.Having.Aggregate('(C_Code > 0)'))
    .OrderBy(TSQLBuilder.OrderBy.Column('C_Code').Column('C_Doc'))
    .ToString;
  CheckEqualsString(cSelectComplete, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightOuterJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy(['C_Code', 'C_Name'])
    .Having(['(C_Code > 0)'])
    .OrderBy(['C_Code', 'C_Doc'])
    .ToString;
  CheckEqualsString(cSelectComplete, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .SubSelect(
    TSQLBuilder.
    Select.Column('C.C_Doc')
    .From('Customers C')
    .Where('C.C_Code').ColumnCriterion(opEqual, 'Customers.C_Code'),
    'Sub'
    )
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectSubSelect, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectAggregate;
const
  cSelect_1 =
    'Select '
    + sLineBreak +
    ' Sum(C_Code * 1), C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';

  cSelect_2 =
    'Select '
    + sLineBreak +
    ' Sum(C_Code * 1) As CodeM, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';

  cSelect_3 =
    'Select '
    + sLineBreak +
    ' Sum(Coalesce(C_Code * 1,0)) As CodeM, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';

  cSelect_4 =
    'Select '
    + sLineBreak +
    ' Coalesce(Sum(Coalesce(C_Code * 1,0)),0) As CodeM, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Select
    .Column(
    TSQLBuilder.Aggregate
    .AggFunction(aggSum).AggExpression('C_Code * 1')
    )
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column(
    TSQLBuilder.Aggregate
    .AggFunction(aggSum).AggExpression('C_Code * 1').AggAlias('CodeM')
    )
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column(
    TSQLBuilder.Aggregate
    .AggFunction(aggSum).AggExpression('C_Code * 1').AggAlias('CodeM').AggCoalesce(TSQLBuilder.Coalesce.Value(0)),
    TSQLBuilder.Coalesce.Value(0)
    )
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_4, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectColumnCoalesce;
const
  cSelect_1 =
    'Select '
    + sLineBreak +
    ' Coalesce(C_Code,0), C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';

  cSelect_2 =
    'Select '
    + sLineBreak +
    ' Coalesce(C_Code,0) As Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Select
    .Column('C_Code', TSQLBuilder.Coalesce.Value(0))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code', TSQLBuilder.Coalesce.Value(0), 'Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectDistinct;
const
  cSelect_1 =
    'Select Distinct '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Select
    .Distinct
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectUnion;
const
  cSelect_1 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    'Union'
    + sLineBreak +
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';

  cSelect_2 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    'Union All'
    + sLineBreak +
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers';

  cSelect_3 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    'Union'
    + sLineBreak +
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)';

  cSelect_4 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    'Union All'
    + sLineBreak +
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)';

  cSelect_5 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    ' Group By C_Code'
    + sLineBreak +
    'Union All'
    + sLineBreak +
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    ' Group By C_Code';

  cSelect_6 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    ' Group By C_Code'
    + sLineBreak +
    ' Having ((C_Code > 0))'
    + sLineBreak +
    'Union All'
    + sLineBreak +
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    ' Group By C_Code'
    + sLineBreak +
    ' Having ((C_Code > 0))';

  cSelect_7 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    ' Group By C_Code'
    + sLineBreak +
    ' Having ((C_Code > 0))'
    + sLineBreak +
    'Union All'
    + sLineBreak +
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)'
    + sLineBreak +
    ' Group By C_Code'
    + sLineBreak +
    ' Having ((C_Code > 0))'
    + sLineBreak +
    ' Order By C_Code';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Union(
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    )
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Union(
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers'), utUnionAll
    )
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .Union(
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1))
    .ToString;
  CheckEqualsString(cSelect_3, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .Union(
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1), utUnionAll)
    .ToString;
  CheckEqualsString(cSelect_4, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(['C_Code'])
    .Union(
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(['C_Code']), utUnionAll)
    .ToString;
  CheckEqualsString(cSelect_5, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(['C_Code'])
    .Having(['(C_Code > 0)'])
    .Union(
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(['C_Code'])
    .Having(['(C_Code > 0)']), utUnionAll)
    .ToString;
  CheckEqualsString(cSelect_6, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(['C_Code'])
    .Having(['(C_Code > 0)'])
    .Union(
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(['C_Code'])
    .Having(['(C_Code > 0)']), utUnionAll)
    .OrderBy(['C_Code'])
    .ToString;
  CheckEqualsString(cSelect_7, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectWhere;
const
  cExpected_1 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) And (C_Name <> ''Ezequiel'')';

  cExpected_2 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) And ((C_Code = 2) And (C_Name <> ''Juliano''))';

  cExpected_3 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (C_Name <> ''Juliano''))';

  cExpected_4 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (C_Name <> ''Juliano'') Or (C_Code < 5))' +
    ' And (C_Code > 0) And (C_Code < 0) And (C_Code >= 0) Or (C_Code <= 0)' +
    ' And (C_Name Like ''%Ejm%'') Or (C_Name Like ''%Ejm'') Or (C_Name Like ''Ejm%'')' +
    ' Or (C_Name Not Like ''%Ejm%'') Or (C_Name Not Like ''%Ejm'') Or (C_Name Not Like ''Ejm%'')' +
    ' And (C_Doc Is Null) Or (C_Name Is Not Null)' +
    ' Or (C_Code In (1, 2, 3)) And (C_Date Between ''01.01.2013'' And ''01.01.2013'')';

  cExpected_5 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (C_Name <> ''Juliano''))'
    + sLineBreak +
    ' Group By C_Code, C_Name'
    + sLineBreak +
    ' Having ((C_Code > 0))'
    + sLineBreak +
    ' Order By C_Code, C_Doc';

  cExpected_6 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)' +
    ' And ((C_Name Like ''Ejm'') Or (C_Name Like ''Mje'') Or (C_Name Like ''Jme''))' +
    ' And ((C_Name Like ''Ejm%'') Or (C_Name Like ''Mje%'') Or (C_Name Like ''Jme%''))' +
    ' And ((C_Name Like ''%Ejm'') Or (C_Name Like ''%Mje'') Or (C_Name Like ''%Jme''))' +
    ' And ((C_Name Like ''%Ejm%'') Or (C_Name Like ''%Mje%'') Or (C_Name Like ''%Jme%''))';

  cExpected_7 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where ((C_Name Like ''Ejm'') Or (C_Name Like ''Mje'') Or (C_Name Like ''Jme''))' +
    ' And ((C_Name Like ''Ejm%'') Or (C_Name Like ''Mje%'') Or (C_Name Like ''Jme%''))' +
    ' And ((C_Name Like ''%Ejm'') Or (C_Name Like ''%Mje'') Or (C_Name Like ''%Jme''))' +
    ' And ((C_Name Like ''%Ejm%'') Or (C_Name Like ''%Mje%'') Or (C_Name Like ''%Jme%''))';

  cExpected_8 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)' +
    ' Or (C_Code Not In (1, 2, 3))';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._And('C_Name').Different('Ezequiel')
    .ToString;
  CheckEqualsString(cExpected_1, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Criterion(opEqual, 1)
    ._And('C_Name').Criterion(opDifferent, 'Ezequiel')
    .ToString;
  CheckEqualsString(cExpected_1, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._And(
    TSQLBuilder.Where.Column('C_Code').Equal(2)._And('C_Name').Different('Juliano')
    )
    .ToString;
  CheckEqualsString(cExpected_2, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._And(
    TSQLBuilder.Where.Column('C_Code').Criterion(opEqual, 2)._And('C_Name').Criterion(opDifferent, 'Juliano')
    )
    .ToString;
  CheckEqualsString(cExpected_2, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._Or(
    TSQLBuilder.Where.Column('C_Code').Equal(2)._And('C_Name').Different('Juliano')
    )
    .ToString;
  CheckEqualsString(cExpected_3, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._Or(
    TSQLBuilder.Where.Column('C_Code').Equal(2)
    ._And('C_Name').Different('Juliano')
    ._Or('C_Code').Less(5)
    )
    ._And('C_Code').Greater(0)
    ._And('C_Code').Less(0)
    ._And('C_Code').GreaterOrEqual(0)
    ._Or('C_Code').LessOrEqual(0)
    ._And('C_Name').Like('Ejm', loContaining)
    ._Or('C_Name').Like('Ejm', loEnding)
    ._Or('C_Name').Like('Ejm', loStarting)
    ._Or('C_Name').NotLike('Ejm', loContaining)
    ._Or('C_Name').NotLike('Ejm', loEnding)
    ._Or('C_Name').NotLike('Ejm', loStarting)
    ._And('C_Doc').IsNull
    ._Or('C_Name').IsNotNull
    ._Or('C_Code').InList([1, 2, 3])
    ._And('C_Date').Between('01.01.2013', '01.01.2013')
    .ToString;
  CheckEqualsString(cExpected_4, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._Or(
    TSQLBuilder.Where.Column('C_Code').Equal(2)._And('C_Name').Different('Juliano')
    )
    .GroupBy(['C_Code', 'C_Name'])
    .Having(['(C_Code > 0)'])
    .OrderBy(['C_Code', 'C_Doc'])
    .ToString;
  CheckEqualsString(cExpected_5, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEqual)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loStarting)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEnding)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loContaining)
    .ToString;
  CheckEqualsString(cExpected_6, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEqual)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loStarting)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEnding)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loContaining)
    .ToString;
  CheckEqualsString(cExpected_7, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._Or('C_Code').NotInList([1, 2, 3])
    .ToString;
  CheckEqualsString(cExpected_8, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectWhereCaseInSensitive;
const
  cExpected_1 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) And (Upper(C_Name) <> Upper(''Ezequiel''))';

  cExpected_2 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) And ((C_Code = 2) And (Upper(C_Name) <> Upper(''Juliano'')))';

  cExpected_3 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (Upper(C_Name) <> Upper(''Juliano'')))';

  cExpected_4 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (Upper(C_Name) <> Upper(''Juliano'')) Or (C_Code < 5))' +
    ' And (C_Code > 0) And (C_Code < 0) And (C_Code >= 0) Or (C_Code <= 0)' +
    ' And (Upper(C_Name) Like Upper(''%Ejm%'')) Or (Upper(C_Name) Like Upper(''%Ejm'')) Or (Upper(C_Name) Like Upper(''Ejm%''))' +
    ' Or (Upper(C_Name) Not Like Upper(''%Ejm%'')) Or (Upper(C_Name) Not Like Upper(''%Ejm'')) Or (Upper(C_Name) Not Like Upper(''Ejm%''))' +
    ' And (C_Doc Is Null) Or (C_Name Is Not Null)' +
    ' Or (C_Code In (1, 2, 3)) And (C_Date Between ''01.01.2013'' And ''01.01.2013'')';

  cExpected_5 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (Upper(C_Name) <> Upper(''Juliano'')))'
    + sLineBreak +
    ' Group By C_Code, C_Name'
    + sLineBreak +
    ' Having ((C_Code > 0))'
    + sLineBreak +
    ' Order By C_Code, C_Doc';

  cExpected_6 =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak +
    ' Where (C_Code = 1)' +
    ' And ((Upper(C_Name) Like Upper(''Ejm'')) Or (Upper(C_Name) Like Upper(''Mje'')) Or (Upper(C_Name) Like Upper(''Jme'')))' +
    ' And ((Upper(C_Name) Like Upper(''Ejm%'')) Or (Upper(C_Name) Like Upper(''Mje%'')) Or (Upper(C_Name) Like Upper(''Jme%'')))' +
    ' And ((Upper(C_Name) Like Upper(''%Ejm'')) Or (Upper(C_Name) Like Upper(''%Mje'')) Or (Upper(C_Name) Like Upper(''%Jme'')))' +
    ' And ((Upper(C_Name) Like Upper(''%Ejm%'')) Or (Upper(C_Name) Like Upper(''%Mje%'')) Or (Upper(C_Name) Like Upper(''%Jme%'')))';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._And('C_Name').Different('Ezequiel', False)
    .ToString;
  CheckEqualsString(cExpected_1, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._And(
    TSQLBuilder.Where.Column('C_Code').Equal(2)._And('C_Name').Different('Juliano', False)
    )
    .ToString;
  CheckEqualsString(cExpected_2, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._Or(
    TSQLBuilder.Where.Column('C_Code').Equal(2)._And('C_Name').Different('Juliano', False)
    )
    .ToString;
  CheckEqualsString(cExpected_3, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._Or(
    TSQLBuilder.Where.Column('C_Code').Equal(2)
    ._And('C_Name').Different('Juliano', False)
    ._Or('C_Code').Less(5)
    )
    ._And('C_Code').Greater(0)
    ._And('C_Code').Less(0)
    ._And('C_Code').GreaterOrEqual(0)
    ._Or('C_Code').LessOrEqual(0)
    ._And('C_Name').Like('Ejm', False, loContaining)
    ._Or('C_Name').Like('Ejm', False, loEnding)
    ._Or('C_Name').Like('Ejm', False, loStarting)
    ._Or('C_Name').NotLike('Ejm', False, loContaining)
    ._Or('C_Name').NotLike('Ejm', False, loEnding)
    ._Or('C_Name').NotLike('Ejm', False, loStarting)
    ._And('C_Doc').IsNull
    ._Or('C_Name').IsNotNull
    ._Or('C_Code').InList([1, 2, 3])
    ._And('C_Date').Between('01.01.2013', '01.01.2013')
    .ToString;
  CheckEqualsString(cExpected_4, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._Or(
    TSQLBuilder.Where.Column('C_Code').Equal(2)._And('C_Name').Different('Juliano', False)
    )
    .GroupBy(['C_Code', 'C_Name'])
    .Having(['(C_Code > 0)'])
    .OrderBy(['C_Code', 'C_Doc'])
    .ToString;
  CheckEqualsString(cExpected_5, vOut);

  vOut :=
    TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], False, loEqual)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], False, loStarting)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], False, loEnding)
    ._And('C_Name').Like(['Ejm', 'Mje', 'Jme'], False, loContaining)
    .ToString;
  CheckEqualsString(cExpected_6, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLStatementSaveToFile;
const
  cSQLFile = 'SQLFile.SQL';

  cSelect =
    'Select '
    + sLineBreak +
    ' C_Code, C_Name, C_Doc'
    + sLineBreak +
    ' From Customers'
    + sLineBreak;

  cUpdate =
    'Update Customers Set'
    + sLineBreak +
    ' C_Code = 1,'
    + sLineBreak +
    ' C_Name = ''Ejm''' +
    sLineBreak;

  cDelete =
    'Delete From Customers' +
    sLineBreak;

  cInsert =
    'Insert Into Customers'
    + sLineBreak +
    ' (C_Code,'
    + sLineBreak +
    '  C_Name,'
    + sLineBreak +
    '  C_Doc)'
    + sLineBreak +
    ' Values'
    + sLineBreak +
    ' (1,'
    + sLineBreak +
    '  ''Ejm'','
    + sLineBreak +
    '  58)' +
    sLineBreak;
var
  vStringList: TStringList;
begin
  vStringList := TStringList.Create;
  try
    TSQLBuilder.Select
      .Column('C_Code')
      .Column('C_Name')
      .Column('C_Doc')
      .From('Customers')
      .SaveToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vStringList.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cSelect, vStringList.Text);

    TSQLBuilder.Update
      .Table('Customers')
      .ColumnSetValue('C_Code', 1)
      .ColumnSetValue('C_Name', 'Ejm')
      .SaveToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vStringList.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cUpdate, vStringList.Text);

    TSQLBuilder.Delete
      .From('Customers')
      .SaveToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vStringList.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cDelete, vStringList.Text);

    TSQLBuilder.Insert
      .Into('Customers')
      .ColumnValue('C_Code', 1)
      .ColumnValue('C_Name', 'Ejm')
      .ColumnValue('C_Doc', 58)
      .SaveToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vStringList.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cInsert, vStringList.Text);
  finally
    FreeAndNil(vStringList);
  end;
end;

procedure TTestSQLBuilder4D.TestSQLTableAlias;
const
  cExpected =
    'Select '
    + sLineBreak +
    ' C_Code As Code, C_Name As Name, C_Doc As Doc'
    + sLineBreak +
    ' From Customers C';
var
  vOut: string;
begin
  vOut := TSQLBuilder.Select
    .Column('C_Code', 'Code')
    .Column('C_Name', 'Name')
    .Column('C_Doc', 'Doc')
    .From('Customers', 'C').ToString;

  CheckEqualsString(cExpected, vOut);

  vOut := TSQLBuilder.Select
    .Column('C_Code', 'Code')
    .Column('C_Name', 'Name')
    .Column('C_Doc', 'Doc')
    .From('Customers').TableAlias('C').ToString;

  CheckEqualsString(cExpected, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLUpdate;
const
  cUpdateNormal =
    'Update Customers Set'
    + sLineBreak +
    ' C_Code = 1,'
    + sLineBreak +
    ' C_Name = ''Ejm''';

  cUpdateWithWhere =
    'Update Customers Set'
    + sLineBreak +
    ' C_Code = 1,'
    + sLineBreak +
    ' C_Name = ''Ejm'''
    + sLineBreak +
    ' Where (C_Code = 1) And ((C_Name = ''Ejm'') Or (C_Name <> ''Ejm''))';
var
  vOut: string;
begin
  vOut :=
    TSQLBuilder.Update
    .Table('Customers')
    .ColumnSetValue('C_Code', 1)
    .ColumnSetValue('C_Name', 'Ejm')
    .ToString;
  CheckEqualsString(cUpdateNormal, vOut);

  vOut :=
    TSQLBuilder.Update
    .Table('Customers')
    .ColumnSetValue('C_Code', 1)
    .ColumnSetValue('C_Name', 'Ejm')
    .Where('C_Code').Equal(1)
    ._And(
    TSQLBuilder.Where.Column('C_Name').Equal('Ejm')
    ._Or('C_Name').Different('Ejm')
    )
    .ToString;
  CheckEqualsString(cUpdateWithWhere, vOut);

  vOut :=
    TSQLBuilder.Update
    .Table('Customers')
    .Columns(['C_Code', 'C_Name'])
    .SetValues([1, 'Ejm'])
    .ToString;
  CheckEqualsString(cUpdateNormal, vOut);

  vOut :=
    TSQLBuilder.Update
    .Table('Customers')
    .Columns(['C_Code', 'C_Name'])
    .SetValues([1, 'Ejm'])
    .Where('C_Code').Equal(1)
    ._And(
    TSQLBuilder.Where.Column('C_Name').Equal('Ejm')
    ._Or('C_Name').Different('Ejm')
    )
    .ToString;
  CheckEqualsString(cUpdateWithWhere, vOut);
end;

procedure TTestSQLBuilder4D.ValidateSQLInject;
begin
  TSQLBuilder.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal('Or')
end;

initialization

RegisterTest(TTestSQLBuilder4D.Suite);

end.
