(*
  Copyright 2013 Ezequiel Juliano Müller - ezequieljuliano@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*)

unit SQLBuilder4D.UnitTest;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  System.TypInfo;

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
    procedure TestSQLSelectUnion();
    procedure TestSQLInjection();
    procedure TestSQLDelete();
    procedure TestSQLUpdate();
    procedure TestSQLInsert();
    procedure TestSQLDateTime();
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
  vDate: TDate;
  vDateTime: TDateTime;
  vTime: TTime;
begin
  vDate := StrToDate('01/01/2014');
  vOut := TSQLBuilder
    .Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Date').Equal(vDate)
    .ToString;

  CheckEqualsString(cSelectDate, vOut);

  vDateTime := StrToDateTime('01/01/2014 01:05:22');
  vOut := TSQLBuilder
    .Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_DateTime').Equal(vDateTime)
    .ToString;

  CheckEqualsString(cSelectDateTime, vOut);

  vTime := StrToTime('01:05:22');
  vOut := TSQLBuilder
    .Select
    .AllColumns
    .From('Customers C')
    .Where('C.C_Time').Equal(vTime)
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
