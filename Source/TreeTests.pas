unit TreeTests;

interface

uses
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  Spring.Collections.TreeIntf,
  Spring.Collections.Trees;

type
  [TestFixture]
  TestTreesInteger = class(TObject)
  strict private
    FTree: ITree<integer>;
    ConsoleLogger: TDUnitXConsoleLogger;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Test with TestCase Atribute to supply parameters.
    [TestCase('Add20','20')]
    [TestCase('Add100','100')]
    [TestCase('Add1000','1600')]
    procedure RandomAdd(Count: Integer);
    // Test with TestCase Atribute to supply parameters.
    [TestCase('AddDelete20','20')]
    [TestCase('AddDelete100','100')]
    [TestCase('AddDelete1000','1600')]
    procedure RandomAddDelete(Count: Integer);
    [TestCase('Enumerate20','20')]
    [TestCase('Enumerate100','100')]
    [TestCase('Enumerate1000','1024')]
    procedure Enumerate(Count: Integer);
    [TestCase('SpeedTest16000','16000')]
    procedure SpeedTest(Count: Integer);
  end;


  [TestFixture]
  TestTreesIntInt = class(TObject)
  strict private
    FTree: ITree<Integer, Integer>;

  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Test with TestCase Atribute to supply parameters.
    [TestCase('Add20','20')]
    [TestCase('Add100','100')]
    [TestCase('Add1000','1000')]
    procedure RandomAdd(Count: Integer);
    // Test with TestCase Atribute to supply parameters.
    [TestCase('AddDelete20','20')]
    [TestCase('AddDelete100','100')]
    [TestCase('AddDelete1000','1000')]
    procedure RandomAddDelete(Count: Integer);
    [TestCase('Enumerate20','20')]
    [TestCase('Enumerate100','100')]
    [TestCase('Enumerate1000','1000')]
    procedure Enumerate(Count: Integer);
  end;


implementation

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

{ TestTrees<T> }
var
Previous: integer;

  procedure ActionNext(const Key: integer; var Abort: boolean);
  begin
    Assert.IsTrue(Key > Previous);
    Previous:= Key;
  end;

  procedure ActionPrevious(const Key: integer; var Abort: boolean);
  begin
    Assert.IsTrue(Key < Previous);
    Previous:= Key;
  end;

procedure TestTreesInteger.Enumerate(Count: Integer);
var
  i,a,r,c: integer;
begin
  //Add random data
  for i:= 0 to Count - 1 do begin
    r:= Random(MaxInt);
    while FTree.Contains(r) do r:= Random(MaxInt);
    c:= FTree.Count;
    FTree.Add(r);
    Assert.IsTrue(FTree.Count = (c+1));
  end;
  //forward enumeration
  a:= -1;
  for i in FTree do begin
    Assert.IsTrue(a < i);
    a:= i;
  end;
  //Reverse enumeration
  a:= MaxInt;
  for i in FTree.Reversed do begin
    Assert.IsTrue(a > i);
    a:= i;
  end;
  Previous:= FTree.First-1;
  FTree.Traverse(TTraverseOrder.InOrder, ActionNext);

  Previous:= FTree.Last+1;
  FTree.Traverse(TTraverseOrder.ReverseOrder, ActionPrevious);
end;

procedure TestTreesInteger.RandomAdd(Count: Integer);
var
  i,j: integer;
  r: integer;
  c: integer;
begin
  i:= 0;
  while i < Count do begin
    r:= Random(MaxInt);
    c:= FTree.Count;
    if not(FTree.Contains(r)) then begin
      FTree.Add(r);
      Assert.IsTrue((c+1) = FTree.Count);
      Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
      inc(i);
    end else begin
      Assert.IsTrue(c > 0);
      FTree.Remove(r);
      Assert.IsTrue((c-1) = FTree.Count);
      Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
      FTree.Add(r);
      Assert.IsTrue((c) = FTree.Count);
      Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
    end;
  end; {while}
  j:= -1;
  for i in FTree do begin
    Assert.IsTrue(j < i);
    j:= i;
  end;
  j:= MaxInt;
  for i in FTree.Reversed do begin
    Assert.IsTrue(j > i);
    j:= i;
  end;
  FTree.Clear;
  Assert.IsTrue(FTree.Count = 0);
end;

procedure TestTreesInteger.RandomAddDelete(Count: Integer);
var
  i,r,a,c: integer;
  Data: TArray<integer>;
begin
  SetLength(Data, Count);
  for i:= 0 to Count - 1 do begin
    Data[i]:= i;
    c:= FTree.Count;
    FTree.Add(Data[i]);
    Assert.IsTrue(FTree.Count = (c+1));
    Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
  end;
  //Shuffle the items
  for i:= 0 to Count -1 do begin
    r:= Random(Count);
    a:= Data[i];
    Data[i]:= Data[r];
    Data[r]:= a;
  end;
  for i:= 0 to Count -1 do begin
    c:= FTree.Count;
    FTree.Remove(Data[i]);
    Assert.IsTrue(FTree.Count = (c-1));
    Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
  end;
  Assert.IsTrue(FTree.Count = 0);
end;

procedure TestTreesInteger.Setup;
begin
  ConsoleLogger:= TDUnitXConsoleLogger.Create(false);
  ConsoleLogger.WriteLn('Start');
  FTree:= Tree<Integer>.RedBlackTree;
end;


procedure TestTreesInteger.SpeedTest(Count: Integer);
var
  i,r,a,c: integer;
  Data: TArray<integer>;
  Ticks: cardinal;
begin
  Ticks:= TThread.GetTickCount;
  SetLength(Data, Count);
  for i:= 0 to Count - 1 do begin
    Data[i]:= i;
    FTree.Add(Data[i]);
  end;
  //Shuffle the items
  for i:= 0 to Count -1 do begin
    r:= Random(Count);
    a:= Data[i];
    Data[i]:= Data[r];
    Data[r]:= a;
  end;
  for i:= 0 to Count -1 do begin
    FTree.Remove(Data[i]);
  end;
  ConsoleLogger.WriteLn('Adding and removing '+Count.ToString + 'elements took '+(TThread.GetTickCount - Ticks).ToString+' ticks');
  Assert.IsTrue(FTree.Count = 0);
end;

procedure TestTreesInteger.TearDown;
begin
  FTree:= nil;
  ConsoleLogger.Free;
end;


{ TestTrees<K, V> }

procedure TestTreesIntInt.Enumerate(Count: Integer);
var
  i,a,r,c: integer;
  Pair: TPair<integer, integer>;
begin
  //Add random data
  for i:= 0 to Count - 1 do begin
    r:= Random(MaxInt);
    while FTree.ContainsKey(r) do r:= Random(MaxInt);
    c:= FTree.Count;
    FTree.Add(r,i);
    Assert.IsTrue(FTree.Count = (c+1));
  end;
  //forward enumeration
  a:= -1;
  for Pair in FTree do begin
    Assert.IsTrue(a < Pair.Key);
    a:= Pair.Key;
  end;
  //Reverse enumeration
  a:= MaxInt;
  for Pair in FTree.Reversed do begin
    Assert.IsTrue(a > Pair.Key);
    a:= Pair.Key;
  end;
end;

procedure TestTreesIntInt.RandomAdd(Count: Integer);
var
  i,j: integer;
  r: integer;
  c: integer;
  p: TPair<Integer, Integer>;
begin
  i:= 0;
  while i < Count do begin
    r:= Random(MaxInt);
    c:= FTree.Count;
    if not(FTree.ContainsKey(r)) then begin
      FTree.Add(r,0);
      Assert.IsTrue((c+1) = FTree.Count);
      Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
      inc(i);
    end else begin
      Assert.IsTrue(c > 0);
      FTree.Remove(r);
      Assert.IsTrue((c-1) = FTree.Count);
      Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
      FTree.Add(r,0);
      Assert.IsTrue((c) = FTree.Count);
      Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
    end;
  end; {while}
  j:= -1;
  for p in FTree do begin
    Assert.IsTrue(j < p.Key);
    j:= p.Key;
  end;
  j:= MaxInt;
  for p in FTree.Reversed do begin
    Assert.IsTrue(j > p.Key);
    j:= p.Key;
  end;
  FTree.Clear;
  Assert.IsTrue(FTree.Count = 0);
end;

procedure TestTreesIntInt.RandomAddDelete(Count: Integer);
var
  i,r,a,c: integer;
  Data: TArray<integer>;
begin
  SetLength(Data, Count);
  for i:= 0 to Count - 1 do begin
    Data[i]:= i;
    c:= FTree.Count;
    FTree.Add(Data[i],i);
    Assert.IsTrue(FTree.Count = (c+1));
    Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
  end;
  //Shuffle the items
  for i:= 0 to Count -1 do begin
    r:= Random(Count);
    a:= Data[i];
    Data[i]:= Data[r];
    Data[r]:= a;
  end;
  for i:= 0 to Count -1 do begin
    c:= FTree.Count;
    FTree.Remove(Data[i]);
    Assert.IsTrue(FTree.Count = (c-1));
    Assert.IsTrue((fTree as ITreeDebug).VerifyIntegrity);
  end;
  Assert.IsTrue(FTree.Count = 0);
end;

procedure TestTreesIntInt.TearDown;
begin
  FTree:= nil;
end;

procedure TestTreesIntInt.Setup;
begin
  FTree:= Tree<Integer, Integer>.RedBlackTree;
end;


initialization
  TDUnitX.RegisterTestFixture(TestTreesInteger);
  TDUnitX.RegisterTestFixture(TestTreesIntInt);
end.
