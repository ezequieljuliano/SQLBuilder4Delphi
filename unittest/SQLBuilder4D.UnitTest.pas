unit SQLBuilder4D.UnitTest;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  System.TypInfo;

type

  TTestSQLBuilder4D = class(TTestCase)
  private
    procedure SQLInject();
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
    procedure TestSQLSelectColumnCase();
    procedure TestSQLSelectHaving();
    procedure TestSQLSelectColumnAlias();

    procedure TestSQLInsert();
    procedure TestSQLUpdate();
    procedure TestSQLDelete();

    procedure TestSQLDateAndTime();
    procedure TestSQLFloat();
    procedure TestSQLInjection();
    procedure TestSQLToFile();
  end;

implementation

uses
  SQLBuilder4D;

{ TTestSQLBuilder4D }

procedure TTestSQLBuilder4D.SetUp;
begin
  inherited;

end;

procedure TTestSQLBuilder4D.SQLInject;
begin
  SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal('Or')
end;

procedure TTestSQLBuilder4D.TearDown;
begin
  inherited;

end;

procedure TTestSQLBuilder4D.TestSQLDateAndTime;
const
  cSelectDate = 'Select ' + sLineBreak +
    ' *' + sLineBreak +
    ' From Customers C' + sLineBreak +
    ' Where (C.C_Date = ''01.01.2014'')';

  cSelectDateTime = 'Select ' + sLineBreak +
    ' *' + sLineBreak +
    ' From Customers C' + sLineBreak +
    ' Where (C.C_DateTime = ''01.01.2014 01:05:22'')';

  cSelectTime = 'Select ' + sLineBreak +
    ' *' + sLineBreak +
    ' From Customers C' + sLineBreak +
    ' Where (C.C_Time = ''01:05:22'')';
var
  vOut: string;
begin
  vOut := SQL.Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Date').Equal('01.01.2014')
    .ToString;

  vOut := SQL.Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Date').Equal(SQL.Value(StrToDate('01/01/2014')).Date)
    .ToString;

  vOut := SQL.Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_DateTime').Equal('01.01.2014 01:05:22')
    .ToString;
  CheckEqualsString(cSelectDateTime, vOut);

  vOut := SQL.Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_DateTime').Equal(SQL.Value(StrToDateTime('01/01/2014 01:05:22')).DateTime)
    .ToString;
  CheckEqualsString(cSelectDateTime, vOut);

  vOut := SQL.Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Time').Equal('01:05:22')
    .ToString;
  CheckEqualsString(cSelectTime, vOut);

  vOut := SQL.Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Time').Equal((SQL.Value(StrToDateTime('01:05:22')).Time))
    .ToString;
  CheckEqualsString(cSelectTime, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLDelete;
const
  cDelete = 'Delete From Customers';
  cDeleteWithWhere = 'Delete From Customers' + sLineBreak +
    ' Where (C_Code > 1) And (C_Name <> ''Ejm'') And ((C_Code In (1, 2, 3)) Or (C_Code < 10))';
var
  vOut: string;
begin
  vOut := SQL.Delete.From('Customers').ToString;
  CheckEqualsString(cDelete, vOut);

  vOut := SQL.Delete.From(SQL.Table('Customers')).ToString;
  CheckEqualsString(cDelete, vOut);

  vOut := SQL.Delete.From('Customers')
    .Where('C_Code').Greater(1)
    .&And('C_Name').Different('Ejm')
    .&And(SQL.Where.Column('C_Code').InList([1, 2, 3])
    .&Or('C_Code').Less(10))
    .ToString;
  CheckEqualsString(cDeleteWithWhere, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLFloat;
const
  cSelect = 'Select ' + sLineBreak +
    ' *' + sLineBreak +
    ' From Customers C' + sLineBreak +
    ' Where (C.C_Value = 25.22)';
var
  vOut: string;
begin
  vOut := SQL.Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Value').Equal(25.22)
    .ToString;
  CheckEqualsString(cSelect, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLInjection;
begin
  CheckException(
    SQLInject,
    ESQLBuilderException
    );
end;

procedure TTestSQLBuilder4D.TestSQLInsert;
const
  cInsert =
    'Insert Into Customers' + sLineBreak +
    ' (C_Code,' + sLineBreak +
    '  C_Name,' + sLineBreak +
    '  C_Doc)' + sLineBreak +
    ' Values' + sLineBreak +
    ' (1,'+ sLineBreak +
    '  ''Ejm'','+ sLineBreak +
    '  58)';
var
  vOut: string;
begin
  vOut := SQL.Insert.Into('Customers')
    .ColumnValue('C_Code', 1)
    .ColumnValue('C_Name', 'Ejm')
    .ColumnValue('C_Doc', 58)
    .ToString;
  CheckEqualsString(cInsert, vOut);

  vOut := SQL.Insert.Into(SQL.Table('Customers'))
    .ColumnValue('C_Code', SQL.Value(1))
    .ColumnValue('C_Name', SQL.Value('Ejm'))
    .ColumnValue('C_Doc', 58)
    .ToString;
  CheckEqualsString(cInsert, vOut);

  vOut := SQL.Insert.Into('Customers')
    .Columns(['C_Code', 'C_Name', 'C_Doc'])
    .Values([1, 'Ejm', 58])
    .ToString;
  CheckEqualsString(cInsert, vOut);

  vOut := SQL.Insert.Into('Customers')
    .Columns(['C_Code', 'C_Name', 'C_Doc'])
    .Values([SQL.Value(1), SQL.Value('Ejm'), SQL.Value(58)])
    .ToString;
  CheckEqualsString(cInsert, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelect;
const
  cSelectAllFields =
    'Select ' + sLineBreak +
    ' *' + sLineBreak +
    ' From Customers';

  cSelectAllFieldsWithTables =
    'Select ' + sLineBreak +
    ' *' + sLineBreak +
    ' From Customers, Places';

  cSelectFields =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers';

  cSelectWithJoins =
    'Select '+ sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Left Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Right Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Full Join Places On (Customers.P_Code = Places.P_Code)';

  cSelectWithJoins_2 =
    'Select '+ sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' And (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Or (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' And (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Or (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Left Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' And (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Or (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Right Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' And (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Or (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Full Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' And (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Or (Customers.P_Code = Places.P_Code)';

  cSelectWithJoins_3 =
    'Select '+ sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (0 = 0)' + sLineBreak +
    ' Join Places On (''EJM'' = ''EJM'')' + sLineBreak +
    ' Left Join Places On (1 = 1)' + sLineBreak +
    ' Right Join Places On (''JM'' = ''JM'')' + sLineBreak +
    ' Full Join Places On (2 = 2)';

  cSelectComplete =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Left Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Right Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Group By C_Code, C_Name' + sLineBreak +
    ' Having ((C_Code > 0))' + sLineBreak +
    ' Order By C_Code, C_Doc';

  cSelectSubSelect =
    'Select ' + sLineBreak +
    ' C_Code, C_Name,' +
    ' (Select ' + sLineBreak +
    ' C.C_Doc' + sLineBreak +
    ' From Customers C' + sLineBreak +
    ' Where (C.C_Code = Customers.C_Code)) As Sub' + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut := SQL.Select
    .AllColumns
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectAllFields, vOut);

  vOut := SQL.Select
    .AllColumns
    .From(SQL.From(SQL.Table('Customers')))
    .ToString;
  CheckEqualsString(cSelectAllFields, vOut);

  vOut := SQL.Select
    .AllColumns
    .From(['Customers', 'Places'])
    .ToString;
  CheckEqualsString(cSelectAllFieldsWithTables, vOut);

  vOut := SQL.Select
    .AllColumns
    .From([SQL.From(SQL.Table('Customers')), SQL.From(SQL.Table('Places'))])
    .ToString;
  CheckEqualsString(cSelectAllFieldsWithTables, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectFields, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .FullJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .ToString;
  CheckEqualsString(cSelectWithJoins, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .LeftJoin(SQL.LeftJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .RightJoin(SQL.RightJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .FullJoin(SQL.FullJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .ToString;
  CheckEqualsString(cSelectWithJoins, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&And(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&Or(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&And(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&Or(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .LeftJoin(SQL.LeftJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&And(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&Or(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .RightJoin(SQL.RightJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&And(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&Or(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .FullJoin(SQL.FullJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&And(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code'))
    .&Or(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .ToString;
  CheckEqualsString(cSelectWithJoins_2, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left(SQL.Value(0)).Op(opEqual).Right(SQL.Value(0))))
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left(SQL.Value('EJM')).Op(opEqual).Right(SQL.Value('EJM'))))
    .LeftJoin(SQL.LeftJoin('Places').Condition(SQL.JoinTerm.Left(SQL.Value(1)).Op(opEqual).Right(SQL.Value(1))))
    .RightJoin(SQL.RightJoin('Places').Condition(SQL.JoinTerm.Left(SQL.Value('JM')).Op(opEqual).Right(SQL.Value('JM'))))
    .FullJoin(SQL.FullJoin('Places').Condition(SQL.JoinTerm.Left(SQL.Value(2)).Op(opEqual).Right(SQL.Value(2))))
    .ToString;
  CheckEqualsString(cSelectWithJoins_3, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy.Column('C_Code').Column('C_Name')
    .Having.Expression('(C_Code > 0)')
    .OrderBy.Column('C_Code').Column('C_Doc')
    .ToString;
  CheckEqualsString(cSelectComplete, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .Join(SQL.Join('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .LeftJoin(SQL.LeftJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .RightJoin(SQL.RightJoin('Places').Condition(SQL.JoinTerm.Left('Customers.P_Code').Op(opEqual).Right('Places.P_Code')))
    .GroupBy(SQL.GroupBy.Column('C_Code').Column('C_Name'))
    .Having(SQL.Having.Expression('(C_Code > 0)'))
    .OrderBy(SQL.OrderBy.Column('C_Code').Column('C_Doc'))
    .ToString;
  CheckEqualsString(cSelectComplete, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy(SQL.GroupBy(['C_Code', 'C_Name']))
    .Having(SQL.Having(['(C_Code > 0)']))
    .OrderBy(SQL.OrderBy(['C_Code', 'C_Doc']))
    .ToString;
  CheckEqualsString(cSelectComplete, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .SubSelect(
    SQL.Select
    .Column('C.C_Doc')
    .From('Customers C')
    .Where('C.C_Code').Expression(opEqual, SQL.Value('Customers.C_Code').Column),
    'Sub')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectSubSelect, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .SubSelect(
    SQL.Select
    .Column('C.C_Doc')
    .From('Customers C')
    .Where('C.C_Code').Equal(SQL.Value('Customers.C_Code').Column),
    'Sub')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectSubSelect, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectAggregate;
const
  cSelect_1 = 'Select ' + sLineBreak +
    ' Sum(C_Code * 1), C_Name, C_Doc' + sLineBreak +
    ' From Customers';

  cSelect_2 = 'Select ' + sLineBreak +
    ' Sum(C_Code * 1) As CodeM, C_Name, C_Doc' + sLineBreak +
    ' From Customers';

  cSelect_3 = 'Select ' + sLineBreak +
    ' Sum(Coalesce(C_Code * 1,0)) As CodeM, C_Name, C_Doc' + sLineBreak +
    ' From Customers';

  cSelect_4 = 'Select ' + sLineBreak +
    ' Coalesce(Sum(Coalesce(C_Code * 1,0)),0) As CodeM, C_Name, C_Doc' + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column(SQL.Aggregate(aggSum, 'C_Code * 1'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate.Sum('C_Code * 1'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate.Sum.Expression('C_Code * 1'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate(aggSum, 'C_Code * 1').Alias('CodeM'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate(aggSum, 'C_Code * 1').&As('CodeM'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate.Sum('C_Code * 1').Alias('CodeM'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate(aggSum, SQL.Coalesce('C_Code * 1', 0)).Alias('CodeM'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_3, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate.Sum(SQL.Coalesce('C_Code * 1', 0)).Alias('CodeM'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_3, vOut);

  vOut := SQL.Select
    .Column(SQL.Coalesce(SQL.Aggregate(aggSum, SQL.Coalesce('C_Code * 1', 0)), 0).Alias('CodeM'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_4, vOut);

  vOut := SQL.Select
    .Column(SQL.Coalesce(SQL.Aggregate.Sum(SQL.Coalesce('C_Code * 1', 0)), 0).Alias('CodeM'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_4, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectColumnAlias;
const
  cExpected =
    'Select ' + sLineBreak +
    ' C_Code As Code, C_Name As Name, C_Doc As Doc' + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column('C_Code').Alias('Code')
    .Column('C_Name').Alias('Name')
    .Column('C_Doc').Alias('Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cExpected, vOut);

  vOut := SQL.Select
    .Column('C_Code').&As('Code')
    .Column('C_Name').&As('Name')
    .Column('C_Doc').&As('Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cExpected, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectColumnCase;
const
  cSelect_1 = 'Select ' + sLineBreak +
    ' Case C_Code' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else 4' + sLineBreak +
    ' End, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_1_1 = 'Select ' + sLineBreak +
    ' Sum(Case ' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else 4' + sLineBreak +
    ' End) As C_Sum, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_1_2 = 'Select ' + sLineBreak +
    ' Sum(Case ' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else 4' + sLineBreak +
    ' End), C_Name' + sLineBreak +
    ' From Customers';

  cSelect_1_3 = 'Select ' + sLineBreak +
    ' Case ' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else Sum(C_Value)' + sLineBreak +
    ' End, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_1_4 = 'Select ' + sLineBreak +
    ' Case ' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else Sum(Coalesce(C_Value,0))' + sLineBreak +
    ' End, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_1_5 = 'Select ' + sLineBreak +
    ' Case ' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else Coalesce(Sum(C_Value),0)' + sLineBreak +
    ' End, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_1_6 = 'Select ' + sLineBreak +
    ' Coalesce(Sum(Case ' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else 4' + sLineBreak +
    ' End),0) As C_Sum, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_1_7 = 'Select ' + sLineBreak +
    ' Coalesce(Case ' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else 4' + sLineBreak +
    ' End,0) As C_Sum, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_2 = 'Select ' + sLineBreak +
    ' Case C_Code' + sLineBreak +
    '  When 1 Then 2' + sLineBreak +
    '  When 2 Then 3' + sLineBreak +
    '  Else 4' + sLineBreak +
    ' End As Code, C_Name' + sLineBreak +
    ' From Customers';

  cSelect_3 = 'Select ' + sLineBreak +
    ' Case Upper(C_Name)' + sLineBreak +
    '  When ''EJM'' Then ''EZE''' + sLineBreak +
    '  When ''MJM'' Then ''JMS''' + sLineBreak +
    '  Else ''KLM''' + sLineBreak +
    ' End As Name, C_Code' + sLineBreak +
    ' From Customers';

  cSelect_4 = 'Select ' + sLineBreak +
    ' Case Lower(C_Name)' + sLineBreak +
    '  When ''ejm'' Then ''eze''' + sLineBreak +
    '  When ''mjm'' Then ''jms''' + sLineBreak +
    '  Else ''klm''' + sLineBreak +
    ' End As Name, C_Code' + sLineBreak +
    ' From Customers';

  cSelect_5 = 'Select ' + sLineBreak +
    ' Case ' + sLineBreak +
    '  When ListPrice =  0 Then ''Mfg item - not for resale''' + sLineBreak +
    '  When ListPrice < 50 Then ''Under $50''' + sLineBreak +
    '  Else ''Over $1000''' + sLineBreak +
    ' End As Desc, ProductNumber' + sLineBreak +
    ' From Product';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column(SQL.&Case('C_Code').&When(1).&Then(2).&When(2).&Then(3).&Else(4).&End)
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate.Sum(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(4).&End).Alias('C_Sum'))
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_1, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate.Sum(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(4).&End).&As('C_Sum'))
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_1, vOut);

  vOut := SQL.Select
    .Column(SQL.Aggregate.Sum(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(4).&End))
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_2, vOut);

  vOut := SQL.Select
    .Column(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(SQL.Aggregate.Sum('C_Value')).&End)
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_3, vOut);

  vOut := SQL.Select
    .Column(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(SQL.Aggregate.Sum(SQL.Coalesce('C_Value', 0))).&End)
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_4, vOut);

  vOut := SQL.Select
    .Column(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(SQL.Coalesce(SQL.Aggregate.Sum('C_Value'), 0)).&End)
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_5, vOut);

  vOut := SQL.Select
    .Column(SQL.Coalesce(SQL.Aggregate.Sum(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(4).&End), 0).Alias('C_Sum'))
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_6, vOut);

  vOut := SQL.Select
    .Column(SQL.Coalesce(SQL.&Case.&When(1).&Then(2).&When(2).&Then(3).&Else(4).&End, 0).Alias('C_Sum'))
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1_7, vOut);

  vOut := SQL.Select
    .Column(SQL.&Case('C_Code').&When(1).&Then(2).&When(2).&Then(3).&Else(4).Alias('Code'))
    .Column('C_Name')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut := SQL.Select
    .Column(SQL.&Case(SQL.Value('C_Name').Column.Lower).&When('ejm').&Then('eze').&When('mjm').&Then('jms').&Else('klm').Alias('Name'))
    .Column('C_Code')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_4, vOut);

  vOut := SQL.Select
    .Column(SQL.&Case
    .&When(SQL.Value('ListPrice =  0').Expression).&Then('Mfg item - not for resale')
    .&When(SQL.Value('ListPrice < 50').Expression).&Then('Under $50')
    .&Else('Over $1000').Alias('Desc'))
    .Column('ProductNumber')
    .From('Product')
    .ToString;
  CheckEqualsString(cSelect_5, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectColumnCoalesce;
const
  cSelect_1 = 'Select ' + sLineBreak +
    ' Coalesce(C_Code,0), C_Name, C_Doc' + sLineBreak +
    ' From Customers';

  cSelect_2 = 'Select ' + sLineBreak +
    ' Coalesce(C_Code,0) As Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column(SQL.Coalesce('C_Code', 0))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut := SQL.Select
    .Column(SQL.Coalesce.Expression('C_Code').Value(0).Alias('Code'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut := SQL.Select
    .Column(SQL.Coalesce('C_Code', 0).Alias('Code'))
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectDistinct;
const
  cSelectDistinct = 'Select Distinct ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Distinct
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .ToString;
  CheckEqualsString(cSelectDistinct, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectHaving;
const
  cSelect_1 =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Left Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Right Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Group By C_Code, C_Name' + sLineBreak +
    ' Having (Sum(C_Code) > 0)' + sLineBreak +
    ' Order By C_Code, C_Doc';

  cSelect_1_1 =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Left Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Right Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Group By C_Code, C_Name' + sLineBreak +
    ' Having (Sum(Coalesce(C_Code,0)) > 0)' + sLineBreak +
    ' Order By C_Code, C_Doc';

  cSelect_2 =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Left Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Right Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Group By C_Code, C_Name' + sLineBreak +
    ' Having (Count(C_Code) <> 0)' + sLineBreak +
    ' Order By C_Code, C_Doc';

  cSelect_3 =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Left Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Right Join Places On (Customers.P_Code = Places.P_Code)' + sLineBreak +
    ' Group By C_Code, C_Name' + sLineBreak +
    ' Having (Count(C_Code) > 0) And (Count(C_Code) < 0)' + sLineBreak +
    ' Order By C_Code, C_Doc';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy.Column('C_Code').Column('C_Name')
    .Having.Expression(SQL.Aggregate.Sum('C_Code').Condition(opGreater, 0))
    .OrderBy.Column('C_Code').Column('C_Doc')
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy.Column('C_Code').Column('C_Name')
    .Having.Expression(SQL.Aggregate(aggSum, SQL.Coalesce('C_Code', 0)).Condition(opGreater, 0))
    .OrderBy.Column('C_Code').Column('C_Doc')
    .ToString;
  CheckEqualsString(cSelect_1_1, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy.Column('C_Code').Column('C_Name')
    .Having(SQL.Having(SQL.Aggregate.Count('C_Code').Condition(opDifferent, SQL.Value(0))))
    .OrderBy.Column('C_Code').Column('C_Doc')
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy.Column('C_Code').Column('C_Name')
    .Having
    .Expression(SQL.Aggregate.Count('C_Code').Condition(opGreater, 0))
    .Expression(SQL.Aggregate.Count('C_Code').Condition(opLess, 0))
    .OrderBy.Column('C_Code').Column('C_Doc')
    .ToString;
  CheckEqualsString(cSelect_3, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .Join('Places', '(Customers.P_Code = Places.P_Code)')
    .LeftJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .RightJoin('Places', '(Customers.P_Code = Places.P_Code)')
    .GroupBy.Column('C_Code').Column('C_Name')
    .Having(SQL.Having([
    SQL.Aggregate.Count('C_Code').Condition(opGreater, 0),
    SQL.Aggregate.Count('C_Code').Condition(opLess, 0)
    ]))
    .OrderBy.Column('C_Code').Column('C_Doc')
    .ToString;
  CheckEqualsString(cSelect_3, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectUnion;
const
  cSelect_1 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    'Union' + sLineBreak +
    'Select '+ sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers';

  cSelect_2 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    'Union All' + sLineBreak +
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers';

  cSelect_3 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    'Union' + sLineBreak +
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)';

  cSelect_4 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    'Union All' + sLineBreak +
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)';

  cSelect_5 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    ' Group By C_Code' + sLineBreak +
    'Union All' + sLineBreak +
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    ' Group By C_Code';

  cSelect_6 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    ' Group By C_Code' + sLineBreak +
    ' Having ((C_Code > 0))' + sLineBreak +
    'Union All' + sLineBreak +
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    ' Group By C_Code' + sLineBreak +
    ' Having ((C_Code > 0))';

  cSelect_7 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    ' Group By C_Code' + sLineBreak +
    ' Having ((C_Code > 0))' + sLineBreak +
    'Union All' + sLineBreak +
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' + sLineBreak +
    ' Group By C_Code' + sLineBreak +
    ' Having ((C_Code > 0))' + sLineBreak +
    ' Order By C_Code';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Union(
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    )
    .ToString;
  CheckEqualsString(cSelect_1, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Union(
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers'), utUnionAll
    )
    .ToString;
  CheckEqualsString(cSelect_2, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .Union(
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1))
    .ToString;
  CheckEqualsString(cSelect_3, vOut);

  vOut :=
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .Union(
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1), utUnionAll)
    .ToString;
  CheckEqualsString(cSelect_4, vOut);

  vOut :=
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(SQL.GroupBy(['C_Code']))
    .Union(
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(SQL.GroupBy(['C_Code'])), utUnionAll)
    .ToString;
  CheckEqualsString(cSelect_5, vOut);

  vOut :=
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(SQL.GroupBy(['C_Code']))
    .Having(SQL.Having(['(C_Code > 0)']))
    .Union(
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(SQL.GroupBy(['C_Code']))
    .Having(SQL.Having(['(C_Code > 0)'])), utUnionAll)
    .ToString;
  CheckEqualsString(cSelect_6, vOut);

  vOut :=
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(SQL.GroupBy(['C_Code']))
    .Having(SQL.Having(['(C_Code > 0)']))
    .Union(
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .GroupBy(SQL.GroupBy(['C_Code']))
    .Having(SQL.Having(['(C_Code > 0)'])), utUnionAll)
    .OrderBy(SQL.OrderBy(['C_Code']))
    .ToString;
  CheckEqualsString(cSelect_7, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectWhere;
const
  cExpected_1 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) And (C_Name <> ''Ezequiel'')';

  cExpected_2 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) And ((C_Code = 2) And (C_Name <> ''Juliano''))';

  cExpected_3 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (C_Name <> ''Juliano''))';

  cExpected_4 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (C_Name <> ''Juliano'') Or (C_Code < 5))' +
    ' And (C_Code > 0) And (C_Code < 0) And (C_Code >= 0) Or (C_Code <= 0)' +
    ' And (C_Name Like ''%Ejm%'') Or (C_Name Like ''%Ejm'') Or (C_Name Like ''Ejm%'')' +
    ' Or (C_Name Not Like ''%Ejm%'') Or (C_Name Not Like ''%Ejm'') Or (C_Name Not Like ''Ejm%'')' +
    ' And (C_Doc Is Null) Or (C_Name Is Not Null)' +
    ' Or (C_Code In (1, 2, 3)) And (C_Date Between ''01.01.2013'' And ''01.01.2013'')';

  cExpected_4_1 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where ((C_Code = 2) And (C_Name <> ''Juliano'') Or (C_Code < 5)) Or (C_Code = 1)' +
    ' And (C_Code > 0) And (C_Code < 0) And (C_Code >= 0) Or (C_Code <= 0)' +
    ' And (C_Name Like ''%Ejm%'') Or (C_Name Like ''%Ejm'') Or (C_Name Like ''Ejm%'')' +
    ' Or (C_Name Not Like ''%Ejm%'') Or (C_Name Not Like ''%Ejm'') Or (C_Name Not Like ''Ejm%'')' +
    ' And (C_Doc Is Null) Or (C_Name Is Not Null)' +
    ' Or (C_Code In (1, 2, 3)) And (C_Date Between ''01.01.2013'' And ''01.01.2013'')';

  cExpected_5 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (C_Name <> ''Juliano''))' + sLineBreak +
    ' Group By C_Code, C_Name' + sLineBreak +
    ' Having ((C_Code > 0))' + sLineBreak +
    ' Order By C_Code, C_Doc';

  cExpected_6 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' +
    ' And ((C_Name Like ''Ejm'') Or (C_Name Like ''Mje'') Or (C_Name Like ''Jme''))' +
    ' And ((C_Name Like ''Ejm%'') Or (C_Name Like ''Mje%'') Or (C_Name Like ''Jme%''))' +
    ' And ((C_Name Like ''%Ejm'') Or (C_Name Like ''%Mje'') Or (C_Name Like ''%Jme''))' +
    ' And ((C_Name Like ''%Ejm%'') Or (C_Name Like ''%Mje%'') Or (C_Name Like ''%Jme%''))';

  cExpected_7 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where ((C_Name Like ''Ejm'') Or (C_Name Like ''Mje'') Or (C_Name Like ''Jme''))' +
    ' And ((C_Name Like ''Ejm%'') Or (C_Name Like ''Mje%'') Or (C_Name Like ''Jme%''))' +
    ' And ((C_Name Like ''%Ejm'') Or (C_Name Like ''%Mje'') Or (C_Name Like ''%Jme''))' +
    ' And ((C_Name Like ''%Ejm%'') Or (C_Name Like ''%Mje%'') Or (C_Name Like ''%Jme%''))';

  cExpected_8 =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' +
    ' Or (C_Code Not In (1, 2, 3))';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&And('C_Name').Different('Ezequiel')
    .ToString;
  CheckEqualsString(cExpected_1, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Expression(opEqual, 1)
    .&And('C_Name').Expression(opDifferent, 'Ezequiel')
    .ToString;
  CheckEqualsString(cExpected_1, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&And(SQL.Where('C_Code').Equal(2).&And('C_Name').Different('Juliano'))
    .ToString;
  CheckEqualsString(cExpected_2, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&And(SQL.Where.Column('C_Code').Expression(opEqual, 2).&And('C_Name').Expression(opDifferent, 'Juliano'))
    .ToString;
  CheckEqualsString(cExpected_2, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(SQL.Where.Column('C_Code').Equal(2).&And('C_Name').Different('Juliano'))
    .ToString;
  CheckEqualsString(cExpected_3, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(SQL.Where('C_Code').Equal(2).&And('C_Name').Different('Juliano').&Or('C_Code').Less(5))
    .&And('C_Code').Greater(0)
    .&And('C_Code').Less(0)
    .&And('C_Code').GreaterOrEqual(0)
    .&Or('C_Code').LessOrEqual(0)
    .&And('C_Name').Like('Ejm', loContaining)
    .&Or('C_Name').Like('Ejm', loEnding)
    .&Or('C_Name').Like('Ejm', loStarting)
    .&Or('C_Name').NotLike('Ejm', loContaining)
    .&Or('C_Name').NotLike('Ejm', loEnding)
    .&Or('C_Name').NotLike('Ejm', loStarting)
    .&And('C_Doc').IsNull
    .&Or('C_Name').IsNotNull
    .&Or('C_Code').InList([1, 2, 3])
    .&And('C_Date').Between('01.01.2013', '01.01.2013')
    .ToString;
  CheckEqualsString(cExpected_4, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where(SQL.Where('C_Code').Equal(2).&And('C_Name').Different('Juliano').&Or('C_Code').Less(5))
    .&Or('C_Code').Equal(1)
    .&And('C_Code').Greater(0)
    .&And('C_Code').Less(0)
    .&And('C_Code').GreaterOrEqual(0)
    .&Or('C_Code').LessOrEqual(0)
    .&And('C_Name').Like('Ejm', loContaining)
    .&Or('C_Name').Like('Ejm', loEnding)
    .&Or('C_Name').Like('Ejm', loStarting)
    .&Or('C_Name').NotLike('Ejm', loContaining)
    .&Or('C_Name').NotLike('Ejm', loEnding)
    .&Or('C_Name').NotLike('Ejm', loStarting)
    .&And('C_Doc').IsNull
    .&Or('C_Name').IsNotNull
    .&Or('C_Code').InList([1, 2, 3])
    .&And('C_Date').Between('01.01.2013', '01.01.2013')
    .ToString;
  CheckEqualsString(cExpected_4_1, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(SQL.Where('C_Code').Equal(2).&And('C_Name').Different('Juliano').&Or('C_Code').Less(5))
    .&And('C_Code').Greater(0)
    .&And('C_Code').Less(0)
    .&And('C_Code').GreaterOrEqual(0)
    .&Or('C_Code').LessOrEqual(0)
    .&And('C_Name').Like('Ejm', loContaining)
    .&Or('C_Name').Like('Ejm', loEnding)
    .&Or('C_Name').Like('Ejm', loStarting)
    .&Or('C_Name').NotLike('Ejm', loContaining)
    .&Or('C_Name').NotLike('Ejm', loEnding)
    .&Or('C_Name').NotLike('Ejm', loStarting)
    .&And('C_Doc').Expression(opIsNull)
    .&Or('C_Name').Expression(opNotNull)
    .&Or('C_Code').InList([1, 2, 3])
    .&And('C_Date').Between('01.01.2013', '01.01.2013')
    .ToString;
  CheckEqualsString(cExpected_4, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(SQL.Where('C_Code').Equal(2).&And('C_Name').Different('Juliano').&Or('C_Code').Less(5))
    .&And('C_Code').Greater(SQL.Value(0))
    .&And('C_Code').Less(SQL.Value(0))
    .&And('C_Code').GreaterOrEqual(SQL.Value(0))
    .&Or('C_Code').LessOrEqual(SQL.Value(0))
    .&And('C_Name').Like(SQL.Value('Ejm').Like(loContaining))
    .&Or('C_Name').Like(SQL.Value('Ejm').Like(loEnding))
    .&Or('C_Name').Like(SQL.Value('Ejm').Like(loStarting))
    .&Or('C_Name').NotLike(SQL.Value('Ejm').Like(loContaining))
    .&Or('C_Name').NotLike(SQL.Value('Ejm').Like(loEnding))
    .&Or('C_Name').NotLike(SQL.Value('Ejm').Like(loStarting))
    .&And('C_Doc').IsNull
    .&Or('C_Name').IsNotNull
    .&Or('C_Code').InList([1, 2, 3])
    .&And('C_Date').Between(SQL.Value(StrToDate('01/01/2013')).Date, SQL.Value(StrToDate('01/01/2013')).Date)
    .ToString;
  CheckEqualsString(cExpected_4, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(SQL.Where('C_Code').Equal(2).&And('C_Name').Different('Juliano'))
    .GroupBy(SQL.GroupBy(['C_Code', 'C_Name']))
    .Having(SQL.Having(['(C_Code > 0)']))
    .OrderBy(SQL.OrderBy(['C_Code', 'C_Doc']))
    .ToString;
  CheckEqualsString(cExpected_5, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEqual)
    .&And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loStarting)
    .&And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEnding)
    .&And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loContaining)
    .ToString;
  CheckEqualsString(cExpected_6, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEqual)
    .&And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loStarting)
    .&And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loEnding)
    .&And('C_Name').Like(['Ejm', 'Mje', 'Jme'], loContaining)
    .ToString;
  CheckEqualsString(cExpected_7, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or('C_Code').NotInList([1, 2, 3])
    .ToString;
  CheckEqualsString(cExpected_8, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLSelectWhereCaseInSensitive;
const
  cExpected_1 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) And (Lower(C_Name) <> Lower(''Ezequiel''))';

  cExpected_2 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) And ((C_Code = 2) And (Lower(C_Name) <> Lower(''Juliano'')))';

  cExpected_3 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (Lower(C_Name) <> Lower(''Juliano'')))';

  cExpected_4 = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (Lower(C_Name) <> Lower(''Juliano'')) Or (C_Code < 5))' +
    ' And (C_Code > 0) And (C_Code < 0) And (C_Code >= 0) Or (C_Code <= 0)' +
    ' And (Lower(C_Name) Like Lower(''%Ejm%'')) Or (Lower(C_Name) Like Lower(''%Ejm'')) Or (Lower(C_Name) Like Lower(''Ejm%''))' +
    ' Or (Lower(C_Name) Not Like Lower(''%Ejm%'')) Or (Lower(C_Name) Not Like Lower(''%Ejm'')) Or (Lower(C_Name) Not Like Lower(''Ejm%''))' +
    ' And (C_Doc Is Null) Or (C_Name Is Not Null)' +
    ' Or (C_Code In (1, 2, 3)) And (C_Date Between ''01.01.2013'' And ''01.01.2013'')';

  cExpected_5 =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1) Or ((C_Code = 2) And (Lower(C_Name) <> Lower(''Juliano'')))' + sLineBreak +
    ' Group By C_Code, C_Name' + sLineBreak +
    ' Having ((C_Code > 0))' + sLineBreak +
    ' Order By C_Code, C_Doc';

  cExpected_6 =
    'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak +
    ' Where (C_Code = 1)' +
    ' And ((Lower(C_Name) Like Lower(''Ejm'')) Or (Lower(C_Name) Like Lower(''Mje'')) Or (Lower(C_Name) Like Lower(''Jme'')))' +
    ' And ((Lower(C_Name) Like Lower(''Ejm%'')) Or (Lower(C_Name) Like Lower(''Mje%'')) Or (Lower(C_Name) Like Lower(''Jme%'')))' +
    ' And ((Lower(C_Name) Like Lower(''%Ejm'')) Or (Lower(C_Name) Like Lower(''%Mje'')) Or (Lower(C_Name) Like Lower(''%Jme'')))' +
    ' And ((Lower(C_Name) Like Lower(''%Ejm%'')) Or (Lower(C_Name) Like Lower(''%Mje%'')) Or (Lower(C_Name) Like Lower(''%Jme%'')))';
var
  vOut: string;
begin
  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&And('C_Name').Different(SQL.Value('Ezequiel').Insensetive)
    .ToString;
  CheckEqualsString(cExpected_1, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&And(SQL.Where('C_Code').Equal(2).&And('C_Name').Different(SQL.Value('Juliano').Insensetive))
    .ToString;
  CheckEqualsString(cExpected_2, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(SQL.Where('C_Code').Equal(2).&And('C_Name').Different(SQL.Value('Juliano').Insensetive))
    .ToString;
  CheckEqualsString(cExpected_3, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(
    SQL.Where('C_Code').Equal(2)
    .&And('C_Name').Different(SQL.Value('Juliano').Insensetive)
    .&Or('C_Code').Less(5)
    )
    .&And('C_Code').Greater(0)
    .&And('C_Code').Less(0)
    .&And('C_Code').GreaterOrEqual(0)
    .&Or('C_Code').LessOrEqual(0)
    .&And('C_Name').Like(SQL.Value('Ejm').Like(loContaining).Insensetive)
    .&Or('C_Name').Like(SQL.Value('Ejm').Like(loEnding).Insensetive)
    .&Or('C_Name').Like(SQL.Value('Ejm').Like(loStarting).Insensetive)
    .&Or('C_Name').NotLike(SQL.Value('Ejm').Like(loContaining).Insensetive)
    .&Or('C_Name').NotLike(SQL.Value('Ejm').Like(loEnding).Insensetive)
    .&Or('C_Name').NotLike(SQL.Value('Ejm').Like(loStarting).Insensetive)
    .&And('C_Doc').IsNull
    .&Or('C_Name').IsNotNull
    .&Or('C_Code').InList([1, 2, 3])
    .&And('C_Date').Between(SQL.Value(StrToDate('01/01/2013')).Date, SQL.Value(StrToDate('01/01/2013')).Date)
    .ToString;
  CheckEqualsString(cExpected_4, vOut);

  vOut :=
    SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&Or(SQL.Where('C_Code').Equal(2).&And('C_Name').Different(SQL.Value('Juliano').Insensetive))
    .GroupBy(SQL.GroupBy(['C_Code', 'C_Name']))
    .Having(SQL.Having(['(C_Code > 0)']))
    .OrderBy(SQL.OrderBy(['C_Code', 'C_Doc']))
    .ToString;
  CheckEqualsString(cExpected_5, vOut);

  vOut := SQL.Select
    .Column('C_Code')
    .Column('C_Name')
    .Column('C_Doc')
    .From('Customers')
    .Where('C_Code').Equal(1)
    .&And('C_Name').Like(
    [SQL.Value('Ejm').Like(loEqual).Insensetive, SQL.Value('Mje').Like(loEqual).Insensetive, SQL.Value('Jme').Like(loEqual).Insensetive]
    )
    .&And('C_Name').Like(
    [SQL.Value('Ejm').Like(loStarting).Insensetive, SQL.Value('Mje').Like(loStarting).Insensetive, SQL.Value('Jme').Like(loStarting).Insensetive]
    )
    .&And('C_Name').Like(
    [SQL.Value('Ejm').Like(loEnding).Insensetive, SQL.Value('Mje').Like(loEnding).Insensetive, SQL.Value('Jme').Like(loEnding).Insensetive]
    )
    .&And('C_Name').Like(
    [SQL.Value('Ejm').Like(loContaining).Insensetive, SQL.Value('Mje').Like(loContaining).Insensetive, SQL.Value('Jme').Like(loContaining).Insensetive]
    )
    .ToString;
  CheckEqualsString(cExpected_6, vOut);
end;

procedure TTestSQLBuilder4D.TestSQLToFile;
const
  cSQLFile = 'SQLFile.SQL';

  cSelect = 'Select ' + sLineBreak +
    ' C_Code, C_Name, C_Doc' + sLineBreak +
    ' From Customers' + sLineBreak;

  cUpdate = 'Update Customers Set' + sLineBreak +
    ' C_Code = 1,' + sLineBreak +
    ' C_Name = ''Ejm''' + sLineBreak;

  cDelete =
    'Delete From Customers' + sLineBreak;

  cInsert =
    'Insert Into Customers' + sLineBreak +
    ' (C_Code,' + sLineBreak +
    '  C_Name,' + sLineBreak +
    '  C_Doc)' + sLineBreak +
    ' Values' + sLineBreak +
    ' (1,' + sLineBreak +
    '  ''Ejm'',' + sLineBreak +
    '  58)' + sLineBreak;
var
  vSl: TStringList;
begin
  vSl := TStringList.Create;
  try
    SQL.Select
      .Column('C_Code')
      .Column('C_Name')
      .Column('C_Doc')
      .From('Customers')
      .ToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vSl.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cSelect, vSl.Text);

    SQL.Update
      .Table('Customers')
      .ColumnSetValue('C_Code', 1)
      .ColumnSetValue('C_Name', 'Ejm')
      .ToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vSl.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cUpdate, vSl.Text);

    SQL.Delete
      .From('Customers')
      .ToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vSl.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cDelete, vSl.Text);

    SQL.Insert
      .Into('Customers')
      .ColumnValue('C_Code', 1)
      .ColumnValue('C_Name', 'Ejm')
      .ColumnValue('C_Doc', 58)
      .ToFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    vSl.LoadFromFile(ExtractFilePath(ParamStr(0)) + cSQLFile);
    CheckEqualsString(cInsert, vSl.Text);
  finally
    FreeAndNil(vSl);
  end;
end;

procedure TTestSQLBuilder4D.TestSQLUpdate;
const
  cUpdate = 'Update Customers Set' + sLineBreak +
    ' C_Code = 1,' + sLineBreak +
    ' C_Name = ''Ejm''';
  cUpdateWithWhere = 'Update Customers Set' + sLineBreak +
    ' C_Code = 1,' + sLineBreak +
    ' C_Name = ''Ejm''' + sLineBreak +
    ' Where (C_Code = 1) And ((C_Name = ''Ejm'') Or (C_Name <> ''Ejm''))';
var
  vOut: string;
begin
  vOut := SQL.Update.Table('Customers')
    .ColumnSetValue('C_Code', 1)
    .ColumnSetValue('C_Name', 'Ejm')
    .ToString;
  CheckEqualsString(cUpdate, vOut);

  vOut := SQL.Update.Table(SQL.Table('Customers'))
    .ColumnSetValue('C_Code', SQL.Value(1))
    .ColumnSetValue('C_Name', SQL.Value('Ejm'))
    .ToString;
  CheckEqualsString(cUpdate, vOut);

  vOut := SQL.Update.Table('Customers')
    .ColumnSetValue('C_Code', 1)
    .ColumnSetValue('C_Name', 'Ejm')
    .Where('C_Code').Equal(1)
    .&And(SQL.Where.Column('C_Name').Equal('Ejm')
    .&Or('C_Name').Different('Ejm')
    ).ToString;
  CheckEqualsString(cUpdateWithWhere, vOut);

  vOut := SQL.Update.Table('Customers')
    .Columns(['C_Code', 'C_Name'])
    .SetValues([1, 'Ejm'])
    .ToString;
  CheckEqualsString(cUpdate, vOut);

  vOut := SQL.Update.Table('Customers')
    .Columns(['C_Code', 'C_Name'])
    .SetValues([SQL.Value(1), SQL.Value('Ejm')])
    .ToString;
  CheckEqualsString(cUpdate, vOut);

  vOut := SQL.Update.Table('Customers')
    .Columns(['C_Code', 'C_Name'])
    .SetValues([1, 'Ejm'])
    .Where('C_Code').Equal(1)
    .&And(SQL.Where('C_Name').Equal('Ejm')
    .&Or('C_Name').Different('Ejm')
    ).ToString;
  CheckEqualsString(cUpdateWithWhere, vOut);
end;

initialization

RegisterTest(TTestSQLBuilder4D.Suite);

end.
