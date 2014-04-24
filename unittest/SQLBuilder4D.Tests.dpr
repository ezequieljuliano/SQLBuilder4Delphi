(*
  Copyright 2014 Ezequiel Juliano Müller - ezequieljuliano@gmail.com

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

program SQLBuilder4D.Tests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}


uses
  DUnitTestRunner,
  SQLBuilder4D in '..\src\SQLBuilder4D.pas',
  SQLBuilder4D.Impl in '..\src\SQLBuilder4D.Impl.pas',
  SQLBuilder4D.UnitTest in 'SQLBuilder4D.UnitTest.pas',
  SQLBuilder4D.Parser in '..\src\SQLBuilder4D.Parser.pas',
  SQLBuilder4D.Parser.GaSQLParser in '..\src\SQLBuilder4D.Parser.GaSQLParser.pas';

{$R *.RES}


begin

  ReportMemoryLeaksOnShutdown := True;

  DUnitTestRunner.RunRegisteredTests;

end.
