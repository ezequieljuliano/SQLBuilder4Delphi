program SQLBuilder4DTests;
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
