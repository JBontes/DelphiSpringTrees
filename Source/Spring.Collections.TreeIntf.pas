unit Spring.Collections.TreeIntf;

interface

uses
  Spring.Collections,
  Spring.Collections.Sets;

type
  {$SCOPEDENUMS ON}
  TTraverseOrder = (PreOrder, InOrder, ReverseOrder, PostOrder);
  {$SCOPEDENUMS OFF}
  TTraverseAction<T> = reference to procedure(const Key: T; var Abort: boolean);

  ITree<T> = interface(ISet<T>)
    ['{ABF7DBD8-C61A-4CEA-AEA6-A67C881E9F02}']
    procedure Traverse(Order: TTraverseOrder; const Action: TTraverseAction<T>);
  end;

  ITree<K,V> = interface(IDictionary<K,V>)
    ['{9466FCD0-BEF6-4BA5-BB6D-22106669C86D}']
  end;

  {$ifdef debug}
  ITreeDebug = interface
    ['{2E25C3A0-C381-4383-9060-7EC13C0E1C42}']
    function VerifyIntegrity: Boolean;
    function StorageSizeOK: Boolean;
  end;
  {$endif}

implementation

end.
