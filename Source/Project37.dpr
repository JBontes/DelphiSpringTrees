program Project37;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Spring.Collections.Trees in 'Spring.Collections.Trees.pas',
  TreeTests in 'TreeTests.pas',
  DUnitX.TestFrameWork,
  DUnitX.Loggers.Console,
  Spring.Collections.TreeImpl in 'Spring.Collections.TreeImpl.pas',
  Spring.Collections.TreeIntf in 'Spring.Collections.TreeIntf.pas',
  RedBlack in 'RedBlack.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
begin
  try
    //Create the runner
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    //tell the runner how we will log things
    logger := TDUnitXConsoleLogger.Create(true);
    //nunitLogger := TDUnitXXMLNUnitFileLogger.Create;
    runner.AddLogger(logger);
    //runner.AddLogger(nunitLogger);

    //Run tests
    results := runner.Execute;

    System.Write('Done.. press <Enter> key to quit.');
    System.Readln;
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
