# DelphiSpringTrees
Trees in Spring4D

#Trees are a much needed feature in any toolkit.  
Delphi generics.collections does not have any trees and neither does Spring4D.  
To remedy this omision here is a modest proposal for efficient generic trees.  

Trees contains:  
- `TRedBlackTree<K>` : Left-leaning red black tree
- `TRedBlackTree<K,V>` : Left-leaning red-black tree, can serve as a replacement for TDictionary

All classes are written with the Spring framework in mind and conform to the spring conventions.  

Because the trees are based on Spring, you can only use them via the interfaces `ITree<T>` and `ITree<K,V>`.  

Minimal sample code:

```Delphi
unit Tree;

interface

uses
  //for technical reasons you need to include both units  
  Spring.Collections.TreeIntf,  //contains the tree interfaces.
  Spring.Collections.Trees;     //contains the static tree factories.
  
var
  TreeAsSet: ITree<integer>;
  TreeAsDictionary: ITree<integer, string>;
  
implementation
initialization
  //Tree<T> factory
  TreeAsSet = Tree<integer>.RedBlackTree;
  //Tree<K,V> factory
  TreeAsDictionary = Tree<integer, string>.RedBlackTree;
  TreeAsSet.Add(1);
  TreeAsDictionary.Add(1,'test');
end.

```
