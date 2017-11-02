program Project37;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Spring.Collections.Trees in 'Spring.Collections.Trees.pas';

var
  Tree: TRedBlackTree<string>;
  t1: TRedBlackTree<integer,string>;

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
  Tree.Free;

  t1 := TRedBlackTree<integer,string>.Create;
  t1.Add(1, 'aaa');
  t1.Add(2, 'zzz');
  t1.Add(3, 'ccc');
  Assert(Equals(t1.First, TPair<integer,string>.Create(1,'aaa')));
  Assert(Equals(t1.Last, TPair<integer,string>.Create(3,'ccc')));
  t1.Add(0, 'ZZZ');
  Assert(Equals(t1.First, TPair<integer,string>.Create(0,'ZZZ')));
  Assert(t1.ContainsKey(2));
  Assert(t1[3] = 'ccc');
  t1.Free;
end.
