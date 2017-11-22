program Project37;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Spring.Collections,
  Spring.Collections.Trees in 'Spring.Collections.Trees.pas';

var
  Tree: ICollection<string>;
//  t1: ICollection<integer,string>;
  s: string;

  function Equals(const p1, p2: TPair<integer,string>): boolean;
  begin
    Result := (p1.Key = p2.Key) and (p1.Value = p2.Value);
  end;

begin
  Tree:= TRedBlackTree<string>.Create;
  Tree.Add('bbb');
  Tree.Add('aaa');
  Tree.Add('ccc');
  Assert(Tree.First = 'aaa');
  Assert(Tree.Last = 'ccc');
  Tree.Add('aa');
  Assert(Tree.First = 'aa');
//  Tree.Traverse(TraverseOrder.InOrder,
//    procedure (const key: string; var abort: boolean)
//    begin
//      Writeln(key);
//    end);

  for s in Tree.Where(function(const s: string): boolean
    begin
      Result := s[1] <> 'a';
    end)
  do begin
    writeLn(s);
  end;

  Tree := nil;

//  Writeln;
//
//  t1 := TRedBlackTree<integer,string>.Create;
//  t1.Add(1, 'aaa');
//  t1.Add(2, 'zzz');
//  t1.Add(3, 'ccc');
//  Assert(Equals(t1.First, TPair<integer,string>.Create(1,'aaa')));
//  Assert(Equals(t1.Last, TPair<integer,string>.Create(3,'ccc')));
//  t1.Add(0, 'ZZZ');
//  Assert(Equals(t1.First, TPair<integer,string>.Create(0,'ZZZ')));
//  Assert(t1.ContainsKey(2));
//  Assert(t1[3] = 'ccc');
//  t1.Traverse(TraverseOrder.ReverseOrder,
//    procedure (const key: integer; const value: string; var abort: boolean)
//    begin
//      Writeln(key, ':', value);
//    end);
//  t1.Free;

  Readln;
end.
