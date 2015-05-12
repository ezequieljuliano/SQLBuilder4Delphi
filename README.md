SQLBuilder For Delphi
=================

Generates Delphi code from your database and lets you build typesafe SQL queries through its fluent API.

SQLBuilder4Delphi is a little Delphi library for dynamically generating SQL statements. It's sweet spot is for applications that need to build up complicated queries with criteria that changes at runtime. Ordinarily it can be quite painful to figure out how to build this string. SQLBuilder4Delphi takes much of this pain away.

SQLBuilder4Delphi applies the concept: DSL. This acronym stands for Domain Specific Language and portrays a common trend in modern languages ​​which basically consists in creating a subset of the language in order to facilitate the solution of simple and specific problems.

The code of SQLBuilder4Delphi is intentionally clean and simple. Rather than provide support for every thing you could ever do with SQL, it provides support for the most common situations and allows you to easily modify the source to suit your needs.

The SQLBuilder4Delphi provides libraries useful auxiliary for developing any Delphi application and requires Delphi XE or greater.

Features
========

- Concise and intuitive API;
- Simple code, so easy to customize;
- Small, lightweight, fast;
- Generates clean SQL designed that is very human readable;
- Supports SELECT, UPDATE, INSERT and DELETE statements;   
- Suports Aggregate Functions, Coalesce, CASE, JOIN, UNION, SUB-SELECT, WHERE, GROUP BY, HAVING, ORDER BY;
- Combine criteria with AND, OR and NOT operators;

Limitations
===========

- Values ​​of type TDateTime, TDate, TTime should be used as string, for through TValue can not differentiate these types of a Float. (Example: Where('FieldDateTime').Equal('01.01.2015 01:05:22')). Or you can use the SQL.Value(). With this feature you can do something like: SQL.Value(Date).Date, SQL.Value(Now).Datetime and SQL.Value(Now).Time.

Examples
=========

To use SQLBuilder4D you should give Uses of their respective Unit: **SQLBuilder4D.pas**


**SELECT**

    //SQLBuilder Command
    SQL.Select
    .AllColumns
    .From('Customer')
    .ToString;
    
    //SQL Result
    Select * From Customer

    //SQLBuilder Command
    SQL.Select
    .Column('Emp_No')
    .Column('Full_Name')
    .Column('Job_Code')
    .Column('Job_Country')
    .From('Employee')
    .ToString;
    
    //SQL Result
    Select Emp_No, Full_Name, Job_Code, Job_Country From Employee

    //SQLBuilder Command
    SQL.Select
    .Column('Emp_No')
    .Column('Full_Name')
    .Column('Job_Code')
    .Column('Job_Country')
    .Column('Currency')
    .From('Employee')
    .Join(
       SQL.Join('Country').Condition(
         SQL.JoinTerm.Left('Job_Country').Op(opEqual).Right('Country')
         )
     ).Where('Currency').Equal('Dollar')
    .ToString;
    
    //SQL Result 
    Select Emp_No, Full_Name, Job_Code, Job_Country, Currency
    From Employee
    Join Country On (Job_Country = Country)
    Where (Currency = 'Dollar')

    //SQLBuilder Command
    SQL.Select
    .Column('Job_Country')
    .Column(
       SQL.Aggregate(aggSum, 'Min_Salary').Alias('Min_Salary')
     )
    .Column(
       SQL.Coalesce(SQL.Aggregate(aggSum, 'Max_Salary'), 0).Alias('Max_Salary')
     )
    .From('Job')
    .GroupBy(
      SQL.GroupBy('job_country')
     )
    .Having.Expression(
      SQL.AggCondition(SQL.Aggregate(aggSum, 'Min_Salary'), opGreater, 70000)
     )
    .OrderBy(
      SQL.OrderBy('Job_Country')
     )
    .ToString;
    
    //SQL Result
    Select
    Job_Country, Sum(Min_Salary) As Min_Salary, 
    Coalesce(Sum(Max_Salary),0) As Max_Salary
    From Job
    Group By job_country
    Having (Sum(Min_Salary) > 70000)
    Order By Job_Country

    //SQLBuilder Command
    SQL.Select
    .Column('First_Name')
    .Column('Last_Name')
    .Column(
       SQL.&Case('Job_Country')
         .When('USA').&Then('United State')
         .When('England').&Then('Great Britain')
         .&Else('Other')
         .&End.Alias('Job_Country')
     )
    .From('Employee')
    .Where('Job_Grade').Greater(3)
    .&And(SQL.Where('Job_Code').Equal('Admin')
      .&Or('Job_Code').Equal('SRep'))
    .ToString;
    
    //SQL Result
    Select
    First_Name, Last_Name,
    Case Job_Country
      When 'USA' Then 'United State'
      When 'England' Then 'Great Britain'
      Else 'Other'
    End As Job_Country
    From Employee
    Where (Job_Grade > 3) And ((Job_Code = 'Admin') Or (Job_Code = 'SRep'))

**DELETE**

    //SQLBuilder Command
    SQL.Delete
    .From('Employee')
    .Where('Job_Grade').Greater(3)
    .&And(SQL.Where('Job_Code').Equal('Admin')
      .&Or('Job_Code').Equal('SRep'))
    .ToString;
    
    //SQL Result
    Delete From Employee
    Where (Job_Grade > 3) And ((Job_Code = 'Admin') Or (Job_Code = 'SRep'))
    
**UPDATE**

    //SQLBuilder Command
    SQL.Update
    .Table('Employee')
    .ColumnSetValue('First_Name', 'Ezequiel')
    .ColumnSetValue('Last_Name', 'Müller')
    .Where('Job_Grade').Equal(1)
    .ToString;
    
    //SQL Result
    Update Employee Set
      First_Name = 'Ezequiel',
      Last_Name = 'Müller'
    Where (Job_Grade = 1)
    

**INSERT**

    //SQLBuilder Command
    SQL.Insert
    .Into('Employee')
    .ColumnValue('First_Name', 'Ezequiel')
    .ColumnValue('Last_Name', 'Müller')
    .ToString;
    
    //SQL Result
    Insert Into Employee
     (First_Name, Last_Name)
    Values
     ('Ezequiel', 'Müller')

Using SQL Parser
========================

The SQLBuilder4Delphi has an SQL parser. He is able to break or set an SQL statement. For it to work properly this project has a dependency of gaSQLParser (http://sourceforge.net/projects/gasqlparser/). Therefore this dependence is included in the project Within the "dependencies" folder. If you use the library parser you shouldnt add to the Path gaSQLParser.

**Use SQL Parser**

To use SQLBuilder4D Parser you should give Uses of their respective Units: **SQLBuilder4D.Parser.pas and SQLBuilder4D.Parser.GaSQLParser.pas**
    
    const
      SQL =
        'Select Emp_No, Full_Name, Job_Code, Job_Country, Currency ' +
        'From Employee ' +
        'Join Country On (Job_Country = Country) ' +
        'Where (Currency = ''Dollar'')';
    var
      vSQLParserSelect: ISQLParserSelect;
    begin
      vSQLParserSelect := TGaSQLParserFactory.Select(SQL);
      ShowMessage(vSQLParserSelect.Columns);
      ShowMessage(vSQLParserSelect.From);
      ShowMessage(vSQLParserSelect.Join);
      ShowMessage(vSQLParserSelect.Where);
      ShowMessage(vSQLParserSelect.GroupBy);
      ShowMessage(vSQLParserSelect.Having);
      ShowMessage(vSQLParserSelect.OrderBy);

      vSQLParserSelect.AddColumns('Salary');
      vSQLParserSelect.AddWhere('(Salary > 0)');
    end;

Add SQLBuilder4Delphi in IDE
============================

Using this library will is very simple, you simply add the Search Path of your IDE or your project the following directories:

- SQLBuilder4Delphi\src\
- SQLBuilder4Delphi\dependencies\gaSQLParser\src

Analyze the unit tests they will assist you.