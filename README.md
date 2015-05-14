# DelphiSpringTrees
Trees in Spring4D

#Trees are a much needed feature in any toolkit.  
Delphi generics.collections does not have any trees and neither does Spring4D.  
To remedy this omision here is a modest proposal for efficient generic trees.  

Trees contains:  
- TBinaryTreeBase<K> : generic unbalanced binary tree
- TNAryTree<K, V> : Generic unbalanced n-ary tree, can serve as a replacement for TDictionary
- TRedBlackTree<K> : Left-leaning red black tree
- TRedBlackTree<K,V> : Left-leaning red-black tree, can serve as a replacement for TDictionary

BPlusTrees contains:
- TBPlusTree<K, V> : Generic B+ Tree  

All classes are written with the Spring framework in mind and conform to the spring conventions.  
