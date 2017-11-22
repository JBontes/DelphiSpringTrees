unit Spring.Collections.TreeIntf;

interface

uses
  Spring.Collections,
  Spring.Collections.Sets;

type
  ITree<T> = interface(ISet<T>)
  end;

  ITree<K,V> = interface(IDictionary<K,V>)
  end;

  TTreeSpecies = (TD234, BU23); // Default is TD234

implementation

end.
