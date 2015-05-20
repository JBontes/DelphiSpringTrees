program Project37;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Spring.Collections.Trees in 'Spring.Collections.Trees.pas';

var
  Tree: TRedBlackTree<string>;

begin
  Tree:= TRedBlackTree<string>.Create;
  Tree.Free;
end.
