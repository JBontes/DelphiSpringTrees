unit Spring.Collections.TreeImpl;

{ *************************************************************************** }
{                                                                             }
{ Proposed addition to the                                                    }
{ Spring Framework for Delphi                                                 }
{                                                                             }
{ Copyright (c) 2009-2017 Spring4D Team                                       }
{                                                                             }
{ http://www.spring4d.org                                                     }
{                                                                             }
{ *************************************************************************** }
{                                                                             }
{ Licensed under the Apache License, Version 2.0 (the "License");             }
{ you may not use this file except in compliance with the License.            }
{ You may obtain a copy of the License at                                     }
{                                                                             }
{ http://www.apache.org/licenses/LICENSE-2.0                                  }
{                                                                             }
{ Unless required by applicable law or agreed to in writing, software         }
{ distributed under the License is distributed on an "AS IS" BASIS,           }
{ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{ See the License for the specific language governing permissions and         }
{ limitations under the License.                                              }
{                                                                             }
{ *************************************************************************** }

// Adds red black trees to the spring framework.
// Core Red black tree code is an adoptation of code (c) 2017 Lukas Barth,
// released under the MIT License under the following terms:
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
// Data is stored in sized sized buckets (dynamic arrays)
// The buckets are kept in a dynamic array.
// When a element is added, it will always be added to the top free item in the
// top free bucket.
// When an element is deleted, it is first swapped with the top occupied item
// in the top bucket; after that the top item in the top bucket is freed.
// For small items this is fast, because there is no memory fragmentation.
// Also pointers to nodes do not change (except when swapping items, which only
// affects a single node).
// For large items, combined with trees with many insertions and deletions,
// it may be better to simply store the items in the heap.

interface

uses
  System.Types,
  System.Generics.Collections,
  System.Generics.Defaults,
  Spring,
  Spring.Collections,
  Spring.Collections.Base,
  Spring.Collections.TreeIntf;
  //Spring.Collections.MiniStacks;

type
{$REGION 'TTree<T>'}
  /// <summary>
  /// Abstract parent for tree, defines the tree as a set of keys
  /// </summary>
  TTree<T> = class abstract(TCollectionBase<T>, ISet<T>, ITree<T>)
  private
    procedure ArgumentNilError(const MethodName: string); virtual;
  protected
    procedure AddInternal(const Item: T); override;
  public

    /// <summary>
    /// Adds an element to the current set and returns a Value to indicate if
    /// the element was successfully added.
    /// </summary>
    /// <param name="item">
    /// The element to add to the set.
    /// </param>
    /// <returns>
    /// <b>True</b> if the element is added to the set; <b>False</b> if the
    /// element is already in the set.
    /// </returns>
    function Add(const Item: T): boolean; virtual; abstract;

    /// <summary>
    /// Determines whether a <see cref="Tree&lt;T&gt;" /> object contains
    /// the specified element.
    /// </summary>
    /// <param name="item">
    /// The element to locate in the <see cref="THashSet&lt;T&gt;" /> object.
    /// </param>
    /// <returns>
    /// <b>True</b> if the <see cref="THashSet&lt;T&gt;" /> object contains
    /// the specified element; otherwise, <b>False</b>.
    /// </returns>
    function Contains(const Key: T): boolean; reintroduce; virtual; abstract;

    /// <summary>
    /// Removes all elements in the specified Collection from the current
    /// <see cref="Tree&lt;T&gt;" /> object.
    /// </summary>
    /// <param name="Other">
    /// The Collection of items to remove from the
    /// <see cref="THashSet&lt;T&gt;" /> object.
    /// </param>
    /// <exception cref="EArgumentNullException">
    /// <i>Other</i> is <b>nil</b>.
    /// </exception>
    procedure ExceptWith(const Other: IEnumerable<T>); virtual;

    /// <summary>
    /// Modifies the current <see cref="Tree&lt;T&gt;" /> object to
    /// contain only elements that are present in that object and in the
    /// specified Collection.
    /// </summary>
    /// <param name="Other">
    /// The Collection to compare to the current
    /// <see cref="Tree&lt;T&gt;" /> object.
    /// </param>
    /// <exception cref="EArgumentNullException">
    /// <i>Other</i> is <b>nil</b>.
    /// </exception>
    procedure IntersectWith(const Other: IEnumerable<T>); virtual;

    /// <summary>
    /// Modifies the current <see cref="Tree&lt;T&gt;" /> object to
    /// contain all elements that are present in itself, the specified
    /// Collection, or both.
    /// </summary>
    /// <param name="Other">
    /// The Collection to compare to the current
    /// <see cref="Tree&lt;T&gt;" /> object.
    /// </param>
    /// <exception cref="EArgumentNullException">
    /// <i>Other</i> is <b>nil</b>.
    /// </exception>
    procedure UnionWith(const Other: IEnumerable<T>); virtual;

    /// <summary>
    /// Determines whether a <see cref="Tree&lt;T&gt;" /> object is a
    /// subset of the specified Collection.
    /// </summary>
    /// <param name="Other">
    /// The Collection to compare to the current
    /// <see cref="THashSet&lt;T&gt;" /> object.
    /// </param>
    /// <returns>
    /// <b>True</b> if the <see cref="Tree&lt;T&gt;" /> object is a
    /// subset of <i>Other</i>; otherwise, <b>False</b>.
    /// </returns>
    /// <exception cref="EArgumentNullException">
    /// <i>Other</i> is <b>nil</b>.
    /// </exception>
    function IsSubsetOf(const Other: IEnumerable<T>): boolean; virtual;

    /// <summary>
    /// Determines whether a <see cref="Tree&lt;T&gt;" /> object is a
    /// superset of the specified Collection.
    /// </summary>
    /// <param name="Other">
    /// The Collection to compare to the current
    /// <see cref="THashSet&lt;T&gt;" /> object.
    /// </param>
    /// <returns>
    /// <b>True</b> if the <see cref="Tree&lt;T&gt;" /> object is a
    /// superset of <i>Other</i>; otherwise, <b>False</b>.
    /// </returns>
    /// <exception cref="EArgumentNullException">
    /// <i>Other</i> is <b>nil</b>.
    /// </exception>
    function IsSupersetOf(const Other: IEnumerable<T>): boolean; virtual;

    /// <summary>
    /// Determines whether a <see cref="THashSet&lt;T&gt;" /> object and the
    /// specified Collection contain the same elements.
    /// </summary>
    /// <param name="Other">
    /// The Collection to compare to the current
    /// <see cref="THashSet&lt;T&gt;" /> object.
    /// </param>
    /// <returns>
    /// <b>True</b> if the <see cref="THashSet&lt;T&gt;" /> object is equal
    /// to <i>Other</i>; otherwise, <b>False</b>.
    /// </returns>
    /// <exception cref="EArgumentNullException">
    /// <i>Other</i> is <b>nil</b>.
    /// </exception>
    function SetEquals(const Other: IEnumerable<T>): boolean; virtual;

    /// <summary>
    /// Determines whether the current <see cref="Tree&lt;T&gt;" />
    /// object and a specified Collection share common elements.
    /// </summary>
    /// <param name="Other">
    /// The Collection to compare to the current
    /// <see cref="THashSet&lt;T&gt;" /> object.
    /// </param>
    /// <returns>
    /// <b>True</b> if the <see cref="Tree&lt;T&gt;" /> object and
    /// <i>Other</i> share at least one common element; otherwise,
    /// <b>False</b>.
    /// </returns>
    /// <exception cref="EArgumentNullException">
    /// <i>Other</i> is <b>nil</b>.
    /// </exception>
    function Overlaps(const Other: IEnumerable<T>): boolean; virtual;
    procedure Traverse(Order: TTraverseOrder; const Action: TTraverseAction<T>); virtual; abstract;
  end;
{$ENDREGION}

{$REGION 'TBinaryTreeBase<T>'}

  TBinaryTreeBase<T> = class(TTree<T>)
  private const
{$IFDEF debug}
    cBucketSize = 1024;
{$ELSE}
    cBucketSize = 1024;
{$ENDIF}
  protected type
    // Nodes in the tree. The nodes hold a pointer to their parent to allow
    // for swapping of nodes, which we need to support the bucket storage system.
    PNode = ^TNode;

    TNode = record
    strict private
      fParent: PNode; // Used for rearraging nodes in the underlying storage.
    private
      fLeft: PNode; // Left nodes hold lower values
      fRight: PNode; // Right nodes hold higher values
      fKey: T; // The payload, use a TPair<K,V> to store a Key/Value pair.
    public //Allow fIsBlack to be repurposed
      fIsBlack: Boolean; // Red is the default.
    private
      /// <summary>
      /// Static method to get the color. Always use this method, never read the
      /// field directly, because the Node might be nil.
      /// A nil node with a color is valid.
      /// </summary>
      /// <returns> false if self is nil; true is the Node is red, false otherwise</returns>
      function IsRed: boolean; inline;
      /// <summary>
      /// Update the Left node and set the correct parent as well.
      /// A nil Value is allowed.
      /// </summary>
      procedure SetLeft(const Value: PNode); inline;
      /// <summary>
      /// Update the Right node and set the correct parent as well.
      /// A nil Value is allowed.
      /// </summary>
      procedure SetRight(const Value: PNode); inline;
      /// <summary>
      /// Only call SetParent in Tree.NewNode!
      /// Everywhere else SetLeft/SetRight will set the correct parent.
      /// </summary>
      procedure SetParent(const Value: PNode); inline;
      function Uncle: PNode;
      property NodeColor: Boolean read fIsBlack write fIsBlack;
    public
      property Left: PNode read fLeft write fLeft;
      property Right: PNode read fRight write fRight;
      property Parent: PNode read fParent write fParent;
      property Key: T read fKey; // write fKey;
    end;
  private type
    /// <summary>
    /// Enumerator for the trees, works on Nodes, not values.
    /// </summary>
    TTreeEnumerator = class(TIterator<T>)
    private
      fTree: TBinaryTreeBase<T>;
      fCurrentNode: PNode;
      // Enumerator can be reversed.
      fDirection: TDirection;
    protected
      // function GetCurrentNonGeneric: V; override;
      function Clone: TIterator<T>; override;
      constructor Create(const Tree: TBinaryTreeBase<T>; Direction: TDirection); overload;
      constructor Create(const Tree: TBinaryTreeBase<T>); overload;
    public
      destructor Destroy; override;
      procedure Reset; override;
      function MoveNext: boolean; override;
      // function GetEnumerator: IEnumerator<T>; override;
      // function GetCurrent: T;
      property Current: T read GetCurrent;
      property CurrentNode: PNode read fCurrentNode;
    end;
  private type
    TNodePredicate = TPredicate<PNode>;
  strict private
    // Disable the default constructor.
    constructor Create; override;
  protected type
    TBucketIndex = TPair<NativeUInt, NativeUInt>;
  protected
    fStorage: TArray<TArray<TNode>>;
    function BucketIndex(Index: NativeUInt): TBucketIndex; inline;
    /// <summary>
    /// Destroys a single Node and updates the count.
    /// Fixes the root if nessecary
    /// </summary>
    /// <remarks>
    /// Only deletes a single Node; does not delete childern and does not fixup the tree.
    /// </remarks>
    procedure FreeSingleNode(const Node: PNode);
  private
    fRoot: PNode;
    fCount: Integer;
    procedure SetRoot(const Value: PNode); inline;
    procedure TraversePreOrder(const Node: PNode; Action: TNodePredicate);
    procedure TraversePostOrder(const Node: PNode; Action: TNodePredicate);
    procedure TraverseInOrder(const Node: PNode; Action: TNodePredicate);
    procedure TraverseReverseOrder(const Node: PNode; Action: TNodePredicate);
    /// <summary>
    ///  Convienance method to see if two keys are equal.
    /// </summary>
    function Equal(const A, B: T): boolean; inline;
    /// <summary>
    ///  Convienance method to see if (a < b).
    /// </summary>
    /// <returns>
    ///  True if A < B, False if A >= B
    /// </returns>
    function Less(const A, B: T): boolean; inline;
    /// <summary>
    /// Finds the Node containing the Key in the given subtree.
    /// </summary>
    /// <param name="Head">The head of the subtree</param>
    /// <param name="Key">The Key to look for</param>
    /// <returns>nil if the Key is not found in the subtree; the containing Node otherwise</returns>
    function FindNode(const Head: PNode; const Key: T): PNode;

    function NewNode(const Key: T; Parent: PNode): PNode;

    function InternalInsert(Head: PNode; const Key: T): PNode; virtual;
    /// <summary>
    /// Expand the storage to add another bucket.
    /// Should perhaps be more intelligent when the tree is expanding fast?
    /// </summary>
    procedure ExpandStorage(OldCount: NativeUInt);
    function NextNode(const Node: PNode): PNode;
    /// <summary>
    /// Get the leftmost (smallest Node) in the given subtree.
    /// </summary>
    /// <param name="Head">The head of the subtree, must not be nil</param>
    /// <returns>The leftmost (smallest) Node in the subtree</returns>
    function MinNode(const Head: PNode): PNode;
    /// <summary>
    /// Get the rightmost (largest Node) in the given subtree.
    /// </summary>
    /// <param name="Head">The head of the subtree, must not be nil</param>
    /// <returns>The rightmost (largest) Node in the subtree</returns>
    function MaxNode(const Head: PNode): PNode;
    function PreviousNode(const Node: PNode): PNode;

    property Root: PNode read fRoot write SetRoot;
  public
    function Add(const Item: T): boolean; override;
    function Contains(const Key: T): boolean; override;
    procedure Clear; override;
    property Count: Integer read fCount;
    procedure Traverse(Order: TTraverseOrder; const Action: TTraverseAction<T>); override;
  end;
{$ENDREGION}
{$REGION 'TBinaryTreeBase<K,V>'}

  TBinaryTreeBase<K, V> = class(TBinaryTreeBase<TPair<K, V>>)
  protected type
    TPair = TPair<K, V>;
  private type
    PNode = TBinaryTreeBase<TPair>.PNode;
  private
    class var fKeyComparer: IComparer<K>;
    class function GetKeyComparer: IComparer<K>; static;
  public type
    TTraverseAction = reference to procedure(const Key: K; const Value: V; var Abort: boolean);
  protected
    function Equal(const A, B: K): boolean; overload;
    function Less(const A, B: K): boolean; overload;
    function Pair(const Key: K; const Value: V): TPair; inline;
    class property KeyComparer: IComparer<K> read GetKeyComparer;
  public
  end;
{$ENDREGION}
{$REGION 'TNAryTree<K,V>'}

  TNAryTree<K, V> = class(TBinaryTreeBase<K, V>)
  private type
    PNode = ^TNode;
    TNode = TBinaryTreeBase < TPair < K, V >>.TNode;
  private
    /// <summary>
    /// Inserts a Node into the subtree anchored at Start.
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The Key to insert into the subtree</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be Assigned in place if the old start Node
    /// in order to retain the RedBlackness of the tree</returns>
    /// <remarks>
    /// Does *not* return an exception if a duplicate Key is inserted, but simply returns
    /// the Start Node as its result; doing nothing else.
    /// Examine the Count property to see if a Node was inserted.
    ///
    /// Can lead to duplicate keys in the tree if not called with the Root as the Head</remarks>
    function InternalInsert(Head: PNode; const Key: K; const Value: V): PNode; reintroduce; overload; virtual;
  protected
    constructor Create; override;
    destructor Destroy; override;
  public
    function Add(const Key: TPair<K, V>): boolean; overload; override;
    procedure Add(const Key: K; const Value: V); reintroduce; overload; virtual;
    function Get(Key: K): TPair<K, V>;
    function GetDirectChildern(const ParentKey: K): TArray<TPair<K, V>>;
  end;
{$ENDREGION}


//{$REGION 'TAVLTree<T>'}
//  TAVLTree<T> = class(TBinaryTreeBase<T>)
//  private type
//    TBalance = -2..2;
//  private type
//    PNode = ^TNode;
//    TNode = TBinaryTreeBase<T>.TNode;
//    TNodePredicate = TBinaryTreeBase<T>.TNodePredicate;
//  private type
//    TAVLNodeHelper = record helper for TNode
//      function GetCount: NativeInt;
//      function TreeDepth: NativeInt;        //longest way down
//      //We repurpose the fColor as a TBalance member.
//      function GetBalance: TBalance; inline;
//      procedure SetBalance(const Value: TBalance); inline;
//      property Balance: TBalance read GetBalance write SetBalance;
//      property Count: NativeInt read GetCount;
//    end;
//  protected
//    procedure BalanceAfterInsert(Node: PNode);
//    procedure BalanceAfterDelete(Node: PNode);
//    procedure RotateLeft(Node: PNode);
//    procedure RotateRight(Node: PNode);
//    procedure SwitchPositionWithSuccessor
//  end;
//{$ENDREGION}

  /// <summary>
  /// Left Leaning red black tree, mainly useful for encaplating a Set.
  /// Does not allow duplicate items.
  /// </summary>
{$REGION 'TRedBlackTree<T>'}
  TRedBlackTree<T> = class(TBinaryTreeBase<T>{$ifdef debug}, ITreeDebug{$endif})
  private type
    PNode = ^TNode;
    TNode = TBinaryTreeBase<T>.TNode;
    TNodePredicate = TBinaryTreeBase<T>.TNodePredicate;
  private
    // A RedBlack tree emulates a binary 234 tree.
    // This tree can run in 234 and 23 mode.
    // For some problem domains the 23 runs faster than the 234
    // For Other problems the 234 is faster.
    fSpecies: TTreeSpecies;
  private
    /// <summary>
    /// Deletes the rightmost child of Start Node, retaining the RedBlack property
    /// </summary>
    //function DeleteMax(Head: PNode): PNode; overload;
    /// <summary>
    /// Deletes the leftmost child of Start Node, retaining the RedBlack property
    /// </summary>
    //function DeleteMin(Head: PNode): PNode; overload;
    /// <summary>
    /// Deletes the Node with the given Key inside the subtree under Start
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The id of the Node to be deleted</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be Assigned in place if the old start Node
    /// in order to retain the RedBlackness of the tree</returns>
    /// <remarks>
    /// Does *not* return an exception if the Key is not found, but simply returns
    /// the Start Node as its result.
    /// Examine the Count property to see if a Node was deleted.
    /// </remarks>
    //function DeleteNode(Head: PNode; Key: T): PNode; overload;

    /// <summary>
    /// Inserts a Node into the subtree anchored at Start.
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The Key to insert into the subtree</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be Assigned in place if the old start Node
    /// in order to retain the RedBlackness of the tree</returns>
    /// <remarks>
    /// Does *not* return an exception if a duplicate Key is inserted, but simply returns
    /// the Start Node as its result; doing nothing else.
    /// Examine the Count property to see if a Node was inserted.
    ///
    /// Can lead to duplicate keys in the tree if not called with the Root as the Start</remarks>
    function InternalInsert(Head: PNode; const Key: T): PNode; override;

    /// <summary>
    /// Corrects the RedBlackness of a Node and its immediate childern after insertion or deletion.
    /// </summary>
    /// <param name="Node"></param>
    /// <returns></returns>
    //function FixUp(Node: PNode): PNode;
    /// <summary>
    /// Inverts the color of a 3-Node and its immediate childern.
    /// </summary>
    /// <param name="Head"></param>
    //procedure ColorFlip(const Node: PNode);
    /// <summary>
    /// Assuming that Node is red and both Node.left and Node.left.left
    /// are black, make Node.left or one of its children red.
    /// </summary>
    //function MoveRedLeft(Node: PNode): PNode;
    /// <summary>
    /// Assuming that Node is red and both Node.right and Node.right.left
    /// are black, make Node.right or one of its children red.
    /// </summary>
    //function MoveRedRight(Node: PNode): PNode;
    /// <summary>
    /// Make a right-leaning 3-Node lean to the left.
    /// </summary>
    //function RotateLeft(Node: PNode): PNode;
    /// <summary>
    /// Make a left-leaning 3-Node lean to the right.
    /// </summary>
    //function RotateRight(Node: PNode): PNode;
    //function DoInsert(Head: PNode; const Key: T): PNode;
    //procedure FixUpAfterInsert(NewNode: PNode);
  private
    procedure rbFixupAfterDelete(Parent: PNode; DeletedLeft: Boolean);
    procedure rbFixupAfterInsert(Node: PNode);
    //procedure rbInsert(const Key: T); overload; inline;
    //procedure rbInsert(const Key: T; Hint: PNode); overload;
    //procedure rbInsert(const Key: T; Start: PNode); overload; inline;
    function rbInsertBase(const Key: T; Start: PNode; BaisedLeft: Boolean): PNode;
    //procedure rbInsertRightBiased(const Key: T; Start: PNode); inline;
    //procedure rbRemove(Node: PNode); inline;
    procedure rbRemoveNode(Node: PNode);
    procedure rbRotateLeft(Parent: PNode);
    procedure rbRotateRight(Parent: PNode);
    procedure rbSwapNeighbors(Parent, Child: PNode);
    procedure rbSwapNodes(n1, n2: PNode; SwapColors: Boolean);
    procedure rbSwapUnrelatedNodes(n1, n2: PNode);
    //TestMethods
    function VerifyBlackPaths(const Node: PNode; var PathLength: NativeUInt): Boolean;
    function VerifyBlackRoot: Boolean; inline;
    function VerifyIntegrity: Boolean;
    function VerifyOrder: Boolean;
    function VerifyRedBlack(const Node: PNode): Boolean;
    function VerifyTree: Boolean;
  protected
    constructor Create(Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const Comparer: IComparer<T>; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const Comparer: TComparison<T>; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const Values: array of T; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const Collection: IEnumerable<T>; Species: TTreeSpecies = TD234); reintroduce; overload;
    destructor Destroy; override;
  public
    function GetEnumerator: IEnumerator<T>; override;
    function Reversed: IEnumerable<T>; override;
  public
    function Last: T; overload; override;
    function Last(const Predicate: TPredicate<T>): T; overload;
    function LastOrDefault(const DefaultValue: T): T; overload; override;
    function LastOrDefault(const Predicate: TPredicate<T>; const DefaultValue: T): T; overload;
    function First: T; override;
    function Extract(const Key: T): T; override;
    function Remove(const Key: T): boolean; override;
    function Add(const Key: T): boolean; override;
    function Get(const Key: T): T; overload;
  end;
{$ENDREGION}
{$REGION 'TRedBlackTree<K,V>'}

  TRedBlackTree<K, V> = class(TRedBlackTree<TPair<K, V>>, IDictionary<K, V>, ITree<K, V>)
  private type
    TPair = TPair<K, V>;
  private type
    TTreeComparer = class(TInterfacedObject, IComparer<TPair>)
    private
      fComparer: IComparer<K>;
    public
      constructor Create(const Comparer: IComparer<K>);
      function Compare(const A, B: TPair): Integer; inline;
    end;
  private
    fValueComparer: IComparer<V>;
    fKeyComparer: IComparer<TPair>;
    fOnKeyChanged: ICollectionChangedEvent<K>;
    fOnValueChanged: ICollectionChangedEvent<V>;
  protected
{$REGION 'Property Accessors'}
    function GetItem(const Key: K): V;
    function GetKeys: IReadOnlyCollection<K>;
    function GetKeyType: PTypeInfo;
    function GetOnKeyChanged: ICollectionChangedEvent<K>;
    function GetOnValueChanged: ICollectionChangedEvent<V>;
    function GetValues: IReadOnlyCollection<V>;
    function GetValueType: PTypeInfo;
    procedure SetItem(const Key: K; const Value: V);
    function GetComparer: IComparer<TPair>;
    property Comparer: IComparer<TPair> read GetComparer;
    function Pair(const Key: K; const Value: V): TPair;
{$ENDREGION}
  public type
    TTraverseAction = reference to procedure(const Key: K; const Value: V; var Abort: boolean);
  protected
    constructor Create(Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const Comparer: IComparer<K>; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const Comparer: TComparison<K>; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const Collection: IEnumerable<TPair<K, V>>; Species: TTreeSpecies); reintroduce; overload;
    constructor Create(const Values: array of TPair<K, V>; Species: TTreeSpecies); reintroduce; overload;
  public

    /// <summary>
    /// Adds an element with the provided Key and Value to the
    /// IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <param name="Key">
    /// The item to use as the Key of the element to add.
    /// </param>
    /// <param name="Value">
    /// The item to use as the Value of the element to add.
    /// </param>
    procedure Add(const Key: K; const Value: V); reintroduce;
    procedure AddOrSetValue(const Key: K; const Value: V);

    /// <summary>
    /// Determines whether the IDictionary&lt;K, V&gt; contains an
    /// element with the specified Key.
    /// </summary>
    /// <param name="Key">
    /// The Key to locate in the IDictionary&lt;K, V&gt;.
    /// </param>
    /// <returns>
    /// <b>True</b> if the IDictionary&lt;K, V&gt; contains an
    /// element with the Key; otherwise, <b>False</b>.
    /// </returns>
    function ContainsKey(const Key: K): boolean;
    /// <summary>
    /// Determines whether the IDictionary&lt;K, V&gt; contains an
    /// element with the specified Value.
    /// </summary>
    /// <param name="Value">
    /// The Value to locate in the IDictionary&lt;K, V&gt;.
    /// </param>
    function ContainsValue(const Value: V): boolean;

    /// <summary>
    /// Determines whether the IMap&lt;TKey,TValue&gt; contains the specified
    /// Key/Value pair.
    /// </summary>
    /// <param name="Key">
    /// The Key of the pair to locate in the IMap&lt;TKey, TValue&gt;.
    /// </param>
    /// <param name="Value">
    /// The Value of the pair to locate in the IMap&lt;TKey, TValue&gt;.
    /// </param>
    /// <returns>
    /// <b>True</b> if the IMap&lt;TKey, TValue&gt; contains a pair with the
    /// specified Key and Value; otherwise <b>False</b>.
    /// </returns>
    function Contains(const Key: K; const Value: V): boolean; reintroduce;

    /// <summary>
    /// Removes the element with the specified Key from the
    /// IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <param name="Key">
    /// The Key of the element to remove.
    /// </param>
    /// <returns>
    /// <b>True</b> if the element is successfully removed; otherwise,
    /// <b>False</b>. This method also returns <b>False</b> if <i>Key</i> was
    /// not found in the original IDictionary&lt;K, V&gt;.
    /// </returns>
    function Remove(const Key: K): boolean; reintroduce; overload;
    function Remove(const Key: K; const Value: V): boolean; reintroduce; overload;

    function Extract(const Key: K; const Value: V): TPair; reintroduce; overload;

    /// <summary>
    /// Removes the Value for a specified Key without triggering lifetime
    /// management for objects.
    /// </summary>
    /// <param name="Key">
    /// The Key whose Value to remove.
    /// </param>
    /// <returns>
    /// The removed Value for the specified Key if it existed; <b>default</b>
    /// otherwise.
    /// </returns>
    function Extract(const Key: K): V; reintroduce; overload;

    /// <summary>
    /// Removes the Value for a specified Key without triggering lifetime
    /// management for objects.
    /// </summary>
    /// <param name="Key">
    /// The Key whose Value to remove.
    /// </param>
    /// <returns>
    /// The removed pair for the specified Key if it existed; <b>default</b>
    /// otherwise.
    /// </returns>
    function ExtractPair(const Key: K): TPair;

    /// <summary>
    /// Gets the Value associated with the specified Key.
    /// </summary>
    /// <param name="Key">
    /// The Key whose Value to get.
    /// </param>
    /// <param name="Value">
    /// When this method returns, the Value associated with the specified
    /// Key, if the Key is found; otherwise, the default Value for the type
    /// of the Value parameter. This parameter is passed uninitialized.
    /// </param>
    /// <returns>
    /// <b>True</b> if the object that implements IDictionary&lt;K,
    /// V&gt; contains an element with the specified Key; otherwise,
    /// <b>False</b>.
    /// </returns>
    function TryGetValue(const Key: K; out Value: V): boolean;

    /// <summary>
    /// Gets the Value for a given Key if a matching Key exists in the
    /// dictionary; returns the default Value otherwise.
    /// </summary>
    function GetValueOrDefault(const Key: K): V; overload;

    /// <summary>
    /// Gets the Value for a given Key if a matching Key exists in the
    /// dictionary; returns the given default Value otherwise.
    /// </summary>
    function GetValueOrDefault(const Key: K; const DefaultValue: V): V; overload;

    function AsReadOnlyDictionary: IReadOnlyDictionary<K, V>;

    /// <summary>
    /// Gets or sets the element with the specified Key.
    /// </summary>
    /// <param name="Key">
    /// The Key of the element to get or set.
    /// </param>
    /// <Value>
    /// The element with the specified Key.
    /// </Value>
    property Items[const Key: K]: V read GetItem write SetItem; default;

    /// <summary>
    /// Gets an <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the
    /// keys of the IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <Value>
    /// An <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the keys of
    /// the object that implements IDictionary&lt;K, V&gt;.
    /// </Value>
    property Keys: IReadOnlyCollection<K> read GetKeys;

    /// <summary>
    /// Gets an <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the
    /// values in the IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <Value>
    /// An <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the values
    /// in the object that implements IDictionary&lt;K, V&gt;.
    /// </Value>
    property Values: IReadOnlyCollection<V> read GetValues;

    property OnKeyChanged: ICollectionChangedEvent<K> read GetOnKeyChanged;
    property OnValueChanged: ICollectionChangedEvent<V> read GetOnValueChanged;
    property KeyType: PTypeInfo read GetKeyType;
    property ValueType: PTypeInfo read GetValueType;
  end;
{$ENDREGION}

resourcestring
  SSetDuplicateInsert = 'Cannot insert a duplicate item in a set';
  SInvalidTraverseOrder = 'Invalid traverse order';

implementation

uses
  Spring.ResourceStrings,
  Spring.Collections.Lists,
  Spring.Collections.Events;

type
  Color = record
  public const
    // Red and Black are modelled as boolean to simplify the IsRed function.
    Red = false;
    Black = true;
  end;

procedure TBinaryTreeBase<T>.TNode.SetLeft(const Value: PNode);
begin
  fLeft:= Value;
  if Assigned(Value) then Value.fParent:= @Self;
end;

procedure TBinaryTreeBase<T>.TNode.SetParent(const Value: PNode);
begin
  fParent:= Value;
end;

procedure TBinaryTreeBase<T>.TNode.SetRight(const Value: PNode);
begin
  fRight:= Value;
  if Assigned(Value) then Value.fParent:= @Self;
end;

procedure TBinaryTreeBase<T>.SetRoot(const Value: PNode);
begin
  fRoot := Value;
  if (Assigned(Value)) then begin
    fRoot.SetParent(nil);
    fRoot.NodeColor:= Color.Black;
  end;
end;

function TBinaryTreeBase<T>.BucketIndex(Index: NativeUInt): TBucketIndex;
begin
  Result.Key:= index div NativeUInt(cBucketSize);
  Result.Value:= index mod NativeUInt(cBucketSize);
end;

constructor TRedBlackTree<T>.Create(Species: TTreeSpecies = TD234);
begin
  inherited Create;
  fSpecies:= Species;
end;

constructor TRedBlackTree<T>.Create(const Comparer: TComparison<T>; Species: TTreeSpecies = TD234);
begin
  inherited Create(Comparer);
  fSpecies:= Species;
end;

constructor TRedBlackTree<T>.Create(const Comparer: IComparer<T>; Species: TTreeSpecies = TD234);
begin
  inherited Create(Comparer);
  fSpecies:= Species;
end;

constructor TRedBlackTree<T>.Create(const Collection: IEnumerable<T>; Species: TTreeSpecies = TD234);
begin
  Create(Species);
  AddRange(Collection);
end;

constructor TRedBlackTree<T>.Create(const Values: array of T; Species: TTreeSpecies = TD234);
begin
  Create(Species);
  AddRange(Values);
end;

function TRedBlackTree<T>.rbInsertBase(const Key: T; Start: PNode; BaisedLeft: Boolean): PNode;
const
  AllowDuplicates = false;
var
  Parent, Cur: PNode;
begin
  Parent := Start;
  Cur := Start;

  while (Cur <> nil) do begin
    Parent := Cur;

	  if (BaisedLeft) then begin
      if (Comparer.Compare(Key, Cur.Key) > 0) then Cur := Cur.Right
      else Cur := Cur.Left;
    end else begin
      if (Comparer.Compare(Cur.Key, Key) > 0) then Cur := Cur.Left
      else Cur := Cur.Right;
    end;
  end;

  if (Parent = nil) then begin
    // new root!
    Root := NewNode(Key, nil);
    Result:= Root;
  end else begin
    if not(AllowDuplicates) and (Comparer.Compare(Key, Parent.Key) = 0) then begin
      raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert);
    end;

    Result:= NewNode(Key, Parent);

    if (Comparer.Compare(Parent.Key, Key) > 0) then Parent.Left := Result
    else if (Comparer.Compare(Key, Parent.Key) > 0) then Parent.Right := Result
    else begin
	    if (BaisedLeft) then Parent.Left := Result
      else Parent.Right := Result;
    end;

    rbFixupAfterInsert(Result);
  end;
end;

procedure TRedBlackTree<T>.rbRotateLeft(Parent: PNode);
var
  RightChild: PNode;
begin
  RightChild := Parent.Right;
  Parent.Right := RightChild.Left;
  if (RightChild.Left <> nil) then begin
    RightChild.Left.Parent := Parent;
  end;

  RightChild.Left := Parent;
  RightChild.Parent := Parent.Parent;

  if (Parent <> Root) then begin
    if (Parent.Parent.Left = Parent) then Parent.Parent.Left := RightChild
    else Parent.Parent.Right := RightChild;
  end else begin
    Root := RightChild;
  end;

  Parent.Parent := RightChild;
end;

procedure TRedBlackTree<T>.rbRotateRight(Parent: PNode);
var
  LeftChild: PNode;
begin
  LeftChild := Parent.Left;
  Parent.Left := LeftChild.Right;
  if (LeftChild.Right <> nil) then LeftChild.Right.Parent := Parent;

  LeftChild.Right := Parent;
  LeftChild.Parent := Parent.Parent;

  if (Parent <> Root) then begin
    if (Parent.Parent.Left = Parent) then Parent.Parent.Left := LeftChild
    else Parent.Parent.Right := LeftChild
  end else Root := LeftChild;

  Parent.Parent := LeftChild;
end;

procedure TRedBlackTree<T>.rbFixupAfterInsert(Node: PNode);
var
  Parent: PNode;
  GrandParent: PNode;
begin
  //The root is never red. If the Parent is red, it must be below the root.
  //Also red nodes are always assigned
  while ((Node.Parent.IsRed) and (Node.Uncle.IsRed)) do begin
    Node.Parent.NodeColor := Color.Black;
    Node.Uncle.NodeColor := Color.Black;

    if (Node.Parent.Parent <> Root) then begin // never iterate into the root
      Node.Parent.Parent.NodeColor := Color.Red;
      Node := Node.Parent.Parent;
    end else begin
      // Don't recurse into the root.
      Exit;
    end;
  end;

  if (Node.Parent.NodeColor = Color.Black) then Exit;

  Parent := Node.Parent;
  Assert(Assigned(Parent)); //The root is never red, so the grandparent is always valid.
  GrandParent := Parent.Parent;

  if (GrandParent.Left = Parent) then begin
    if (Parent.Right = Node) then begin
      // 'folded in' situation
      rbRotateLeft(Parent);
      Node.NodeColor := Color.Black;
    end else begin
      // 'straight' situation
      Parent.NodeColor := Color.Black;
    end;
	  rbRotateRight(GrandParent);
  end else begin
    //GrandParent.Right = Parent
    if (Parent.Left = Node) then begin
      // 'folded in'
      rbRotateRight(Parent);
      Node.NodeColor := Color.Black;
    end else begin
      // 'straight'
      Parent.NodeColor := Color.Black;
    end;
    rbRotateLeft(GrandParent);
  end;

  GrandParent.NodeColor := Color.Red;
end;

function TRedBlackTree<T>.VerifyBlackRoot: boolean;
begin
  //The root must be black.
  Result:= (Root = nil) or (Root.NodeColor = Color.Black);
end;

function TRedBlackTree<T>.VerifyBlackPaths(const Node: PNode; var PathLength: NativeUInt): boolean;
var
  LeftLength, RightLength: NativeUInt;
begin
  //All nodes must have the same number of black non-nil children.
  if (Node.Left = nil) then LeftLength := 0
  else if not(VerifyBlackPaths(Node.Left, LeftLength)) then Exit(False);

  if (Node.Right = nil) then RightLength := 0
  else if (not VerifyBlackPaths(Node.Right, RightLength)) then Exit(False);

  if (LeftLength <> RightLength) then begin
    Exit(False);
  end;

  if (Node.NodeColor = Color.Black) then PathLength := LeftLength + 1
  else PathLength := LeftLength;

  Result:= True;
end;

function TRedBlackTree<T>.VerifyRedBlack(const Node: PNode): boolean;
begin
  //A red node must have two black children
  if (Node = nil) then Exit(True);

  if (Node.IsRed) then begin
    if (Node.Right.IsRed) or (Node.Left.IsRed) then begin
      Exit(False);
    end;
  end;

  Result:= VerifyRedBlack(Node.Left) and VerifyRedBlack(Node.Right);
end;

{TODO -oJB -cVerifyOrder : Rewrite using iterator}
function TRedBlackTree<T>.VerifyOrder: boolean;
const
  AllowDuplicates = false;
var
  Key, Previous: T;
  Start: boolean;
begin
  //A binary tree must always have the nodes in sorted order.
  Start:= true;
  for Key in Self do begin
    if (Start) then begin
      Previous:= Key;
      Start:= false;
      continue;
    end else begin
      if Comparer.Compare(Key, Previous) < 0 then Exit(False);
      if not(AllowDuplicates) and (Comparer.Compare(Key, Previous) = 0) then Exit(False);
      Previous:= Key;
    end;
  end;

  Result:= True;
end;

function TRedBlackTree<T>.VerifyTree: Boolean;
var
  Cur: PNode;
begin
  //A tree cannot have loops
  if (Count = 0) then Exit(True);

  Cur := Self.Root;
  while (Cur.Left <> nil) do begin
    Cur := Cur.Left;
    if (Cur.Left = Cur) then begin
      Assert(false);
      Exit(false);
    end;
  end;

  while (Cur <> nil) do begin

    if (Cur.Left <> nil) then begin
      if (Cur.Left.Parent <> Cur) then begin
        assert(false);
        Exit(False);
      end;
      if (Cur.Right = Cur) then begin
         assert(false);
         Exit(False);
      end;
    end;

    if (Cur.Right <> nil) then begin
      if (Cur.Right.Parent <> Cur) then begin
        assert(false);
        Exit(False);
      end;
      if (Cur.Right = Cur) then begin
         assert(false);
         Exit(False);
      end;
    end;

    //find the next-largest vertex
    if (Cur.Right <> nil) then begin
      // go to smallest larger-or-equal Child
      Cur := Cur.Right;
      while (Cur.Left <> nil) do begin
        Cur := Cur.Left;
      end;
    end else begin
      // go up

      // skip over the Nodes already visited
      while ((Cur.Parent <> nil) and (Cur.Parent.Right = Cur)) do begin // these are the Nodes which are smaller and were already visited
        Cur := Cur.Parent;
      end;

      // go one further up
      if (Cur.Parent = nil) then begin
        // done
        Cur := nil;
      end else begin
        // go up
        Cur := Cur.Parent;
      end;
    end;
  end; {while}

  Exit(True);
end;

function TRedBlackTree<T>.VerifyIntegrity: Boolean;
var
  Dummy: NativeUInt;
  TreeOK: Boolean;
  RootOK: Boolean;
  PathsOK: Boolean;
  ChildrenOK: Boolean;
  OrderOK: Boolean;

begin
  TreeOK := Self.VerifyTree;

  RootOK := Self.VerifyBlackRoot;
  PathsOK := (Self.Root = nil) or VerifyBlackPaths(Root, dummy);
  ChildrenOK := VerifyRedBlack(Self.Root);

  OrderOK := Self.VerifyOrder;
  Assert(RootOK,'Root not OK');
  Assert(PathsOK, 'Paths not OK');
  Assert(ChildrenOK, 'Children not OK');
  Assert(TreeOK, 'Tree not OK');
  Assert(OrderOK, 'Order not OK');

  Result:= RootOK and PathsOK and ChildrenOK and TreeOK and OrderOK;
end;

procedure TRedBlackTree<T>.rbSwapNodes(n1, n2: PNode; SwapColors: Boolean);
var
  Temp: Boolean;
begin
  if (n1.Parent = n2) then begin
    Self.rbSwapNeighbors(n2, n1);
  end else if (n2.Parent = n1) then begin
    Self.rbSwapNeighbors(n1, n2);
  end else begin
    Self.rbSwapUnrelatedNodes(n1, n2);
  end;

  if not(SwapColors) then begin
    Temp:= n1.NodeColor;
    n1.NodeColor:= n2.NodeColor;
    n2.NodeColor:= Temp;
  end;
end;

procedure TRedBlackTree<T>.rbSwapNeighbors(Parent, Child: PNode);
var
  Temp: PNode;
begin
  Child.Parent := Parent.Parent;
  Parent.Parent := Child;
  if (Child.Parent <> nil) then begin
    if (Child.Parent.Left = Parent) then begin
      Child.Parent.Left := Child;
    end else begin
      Child.Parent.Right := Child;
    end;
  end else begin
    //This may color the root red, we will correct this later.
    //Do not force the Root Black here.
    fRoot := Child;
  end;

  if (Parent.Left = Child) then begin
    Parent.Left := Child.Left;
    if (Parent.Left <> nil) then begin
      Parent.Left.Parent := Parent;
    end;
    Child.Left := Parent;

    Temp:= Parent.Right;
    Parent.Right:= Child.Right;
    Child.Right:= Temp;

    if (Child.Right <> nil) then begin
      Child.Right.Parent := Child;
    end;
    if (Parent.Right <> nil) then begin
      Parent.Right.Parent := Parent;
    end;
  end else begin
    Parent.Right := Child.Right;
    if (Parent.Right <> nil) then begin
      Parent.Right.Parent := Parent;
    end;
    Child.Right := Parent;

    Temp:= Parent.Left;
    Parent.Left:= Child.Left;
    Child.Left:= Temp;

    if (Child.Left <> nil) then begin
      Child.Left.Parent := Child;
    end;
    if (Parent.Left <> nil) then begin
      Parent.Left.Parent := Parent;
    end;
  end;
end;

procedure TRedBlackTree<T>.rbSwapUnrelatedNodes(n1, n2: PNode);
var
  Temp: PNode;
begin
  Temp:= n1.Left;
  n1.Left:= n2.Left;
  n2.Left:= Temp;

  if (n1.Left <> nil) then n1.Left.Parent := n1;
  if (n2.Left <> nil) then n2.Left.Parent := n2;

  Temp:= n1.Right;
  n1.Right:= n2.Right;
  n2.Right:= Temp;

  if (n1.Right <> nil) then n1.Right.Parent := n1;
  if (n2.Right <> nil) then n2.Right.Parent := n2;

  Temp:= n1.Parent;
  n1.Parent:= n2.Parent;
  n2.Parent:= Temp;

  if (n1.Parent <> nil) then begin
    if (n1.Parent.Right = n2) then n1.Parent.Right := n1
    else n1.Parent.Left := n1;
  end else begin
    fRoot := n1; //Allow the root to be red, we will correct this later.
  end;
  if (n2.Parent <> nil) then begin
    if (n2.Parent.Right = n1) then n2.Parent.Right := n2
    else n2.Parent.Left := n2;
  end else begin
    fRoot := n2;
  end;
end;

procedure TRedBlackTree<T>.rbRemoveNode(Node: PNode);
var
  Cur, Child: PNode;
  RightChild: PNode;
  DeletedLeft: Boolean;
  {$ifopt C+} ColorDiff: boolean; {$endif}
begin
  Dec(fCount);
  if IsManagedType(T) then Finalize(Node.fKey);
  Cur := Node;
  Child := Node;

  if ((Cur.Right <> nil) and (Cur.Left <> nil)) then begin
    // Find the minimum of the larger-or-equal Children
    Child := Cur.Right;
    while (Child.Left <> nil) do begin
      Child := Child.Left;
    end; {while}
  end else if (Cur.Left <> nil) then begin
    // Only a left Child. This must be red and cannot have further Children (otherwise, black-balance would be violated)
    Child := Child.Left;
    Assert(Child.IsRed);
    Assert((Child.Left = nil) and (Child.Right = nil));
  end;

  if (Child <> Node) then begin
    {$ifopt c+} ColorDiff:= Node.NodeColor <> Child.NodeColor; {$endif}
    Self.rbSwapNodes(Node, Child, false);
    Assert(ColorDiff = (Node.NodeColor <> Child.NodeColor)); //Make sure color is not lost
  end;
  // Now, Node is a pseudo-leaf with the color of Child.

  // Node cannot have a left Child, so if it has a right Child, the child must be red,
  // thus Node must be black
  if (Node.Right <> nil) then begin
    Assert(Node.Right.IsRed);
    Assert(Node.NodeColor = Color.Black);
    // replace Node with its Child and color the Child black.
    RightChild := Node.Right;
    Self.rbSwapNodes(Node, RightChild, true);
    RightChild.NodeColor := Color.Black;
    RightChild.Right := nil; // Self stored the Node to be deleted…

    Exit; // no fixup necessary
  end;

  // Node has no Children, so we have to just delete it, which is no problem if we are red. Otherwise, we must start a fixup at the Parent.
  if (Node.Parent <> nil) then begin
    DeletedLeft:= (Node.Parent.Left = Node);
    if (DeletedLeft) then Node.Parent.Left := nil
    else Node.Parent.Right := nil;

  end else begin
    Root := nil; // Tree is now empty!
    Exit; // No fixup needed!
  end;

  if (Node.NodeColor = Color.Black) then begin
    rbFixupAfterDelete(Node.Parent, DeletedLeft);
  end;
end;

procedure TRedBlackTree<T>.rbFixupAfterDelete(Parent: PNode; DeletedLeft: Boolean);
var
  Sibling: PNode;
  Temp: Boolean;
begin
  Assert((DeletedLeft and (Parent.Left = nil)) or (Parent.Right = nil));

  while True do begin
    // We just deleted a black Node below Parent.
    if (DeletedLeft) then begin
      Sibling := Parent.Right;
    end else begin
      Sibling := Parent.Left;
    end;

    Assert(Assigned(Sibling));
    // Sibling must exist! If it didn't, then that branch would have had too few blacks…
    if (
        (Parent.NodeColor = Color.Black) and
        (Sibling.NodeColor = Color.Black) and
        ((Sibling.Left = nil) or (Sibling.Left.NodeColor = Color.Black)) and
        ((Sibling.Right = nil) or (Sibling.Right.NodeColor = Color.Black))
    ) then begin

      // We can recolor and propagate up! (Case 3)
      Sibling.NodeColor := Color.Red;
      // Now everything below Parent is ok, but the branch started in Parent lost a black!
      if (Parent = Root) then begin
        // Doesn't matter! Parent is the root, no harm done.
        Exit;
      end else begin
        // propagate up!
        DeletedLeft := (Parent.Parent.Left = Parent);
        Parent := Parent.Parent;
      end;
    end else begin // could not recolor the Sibling, do not propagate up
      Break; //Stop propagating red nodes up.
    end;
  end;

  if (Sibling.IsRed) then begin
    // Case 2
    Sibling.NodeColor := Color.Black;
    Parent.NodeColor := Color.Red;
    if (DeletedLeft) then begin
      rbRotateLeft(Parent);
      Sibling := Parent.Right;
    end else begin
      rbRotateRight(Parent);
      Sibling := Parent.Left;
    end;
  end;

  if (
      (Sibling.NodeColor = Color.Black) and
      ((Sibling.Left = nil) or (Sibling.Left.NodeColor = Color.Black)) and
      ((Sibling.Right = nil) or (Sibling.Right.NodeColor = Color.Black))
  ) then begin
    // case 4
    Parent.NodeColor := Color.Black;
    Sibling.NodeColor := Color.Red;

    Exit; // No further fixup necessary
  end;

  if (DeletedLeft) then begin
    if ((Sibling.Right = nil) or (Sibling.Right.NodeColor = Color.Black)) then begin
      // left Child of Sibling must be red! This is the folded case. (Case 5) Unfold!
      rbRotateRight(Sibling);
      Sibling.NodeColor := Color.Red;
      // The new Sibling is now the Parent of the Sibling
      Sibling := Sibling.Parent;
      Sibling.NodeColor := Color.Black;
    end;

    // straight situation, case 6 applies!
    rbRotateLeft(Parent);

    Temp:= Parent.NodeColor;
    Parent.NodeColor:= Sibling.NodeColor;
    Sibling.NodeColor:= Temp;

    Sibling.Right.NodeColor := Color.Black;
  end else begin
    if ((Sibling.Left = nil) or (Sibling.Left.NodeColor = Color.Black)) then begin
      // right Child of Sibling must be red! This is the folded case. (Case 5) Unfold!

      rbRotateLeft(Sibling);
      Sibling.NodeColor := Color.Red;
      // The new Sibling is now the Parent of the Sibling
      Sibling := Sibling.Parent;
      Sibling.NodeColor := Color.Black;
    end;

    // straight situation, case 6 applies!
    rbRotateRight(Parent);

    Temp:= Parent.NodeColor;
    Parent.NodeColor:= Sibling.NodeColor;
    Sibling.NodeColor:= Temp;

    Sibling.Left.NodeColor := Color.Black;
  end;
end;

//procedure TRedBlackTree<T>.rbRemove(Node: PNode);
//begin
//  rbRemoveNode(Node);
//end;


function TBinaryTreeBase<T>.Contains(const Key: T): boolean;
begin
  Result:= Assigned(FindNode(Root, Key));
end;

constructor TBinaryTreeBase<T>.Create;
begin
  inherited Create;
end;

function TRedBlackTree<T>.Get(const Key: T): T;
var
  Node: PNode;
begin
  Node:= FindNode(Root, Key);
  if Assigned(Node) then Result:= Node.Key
  else raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TBinaryTreeBase<T>.Add(const Item: T): boolean;
var
  OldCount: Integer;
begin
  OldCount:= Count;
  Root:= Self.InternalInsert(Root, Item);
  Result:= (Count <> OldCount);
end;

function TRedBlackTree<T>.GetEnumerator: IEnumerator<T>;
begin
  Result:= TTreeEnumerator.Create(Self);
end;

function TBinaryTreeBase<T>.FindNode(const Head: PNode; const Key: T): PNode;
begin
  Result:= Head;
  while Result <> nil do begin
    if (Equal(Key, Result.Key)) then Exit;
    if (Less(Key, Result.Key)) then Result:= Result.Left
    else Result:= Result.Right;
  end;
end;

function TBinaryTreeBase<T>.InternalInsert(Head: PNode; const Key: T): PNode;
var
  Current, Parent: PNode;
  Compare: integer;
begin
  Parent:= nil;
  Current:= Head;
  while Current <> nil do begin
    Compare:= Comparer.Compare(Key, Current.fKey);
    Parent:= Current;
    if (Compare > 0) then Current:= Current.Right
    else if (Compare < 0) then Current:= Current.Left
    else raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert);
  end;

  Current:= NewNode(Key, Parent);
  if (Compare > 0) then begin
    Current.Right:= Parent.Right;
    Parent.fRight:= Current;
  end else begin
    Current.Left:= Parent.Left;
    Parent.fLeft:= Current;
  end;
  Result:= Current;

//  if Head = nil then begin
//    Exit(NewNode(Key, nil));
//  end;
//
//  if Equal(Key, Head.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
//  else if (Less(Key, Head.Key)) then begin
//    Head.Left:= InternalInsert(Head.Left, Key);
//  end else begin
//    Head.Right:= InternalInsert(Head.Right, Key);
//  end;
//
//  Result:= Head;
end;

function TRedBlackTree<T>.First: T;
begin
  if (Root = nil) then raise EInvalidOperationException.CreateRes(@SSequenceContainsNoElements);
  Result:= MinNode(Root).Key;
end;

function TBinaryTreeBase<T>.TNode.Uncle: PNode;
var
  GrandParent: PNode;
begin
  Assert(Assigned(Parent));
  GrandParent:= Parent.Parent;
  Assert(Assigned(GrandParent));
  if (GrandParent.Left = Parent) then Result:= GrandParent.Right
  else Result:= GrandParent.Left;
end;

function TBinaryTreeBase<T>.TNode.IsRed: boolean;
begin
  if @Self = nil then Exit(false);
  Result:= not(fIsBlack);
end;

function TRedBlackTree<T>.Add(const Key: T): boolean;
var
  OldCount: Integer;
begin
  OldCount:= Count;
  InternalInsert(Root, Key);
  //Root.NodeColor:= Color.Black;
  Result:= (Count <> OldCount);
end;

//function TRedBlackTree<T>.DoInsert(Head: PNode; const Key: T): PNode;
//var
//  Node, Parent, InsertedNode: PNode;
//  Diff: integer;
//begin
//  Parent:= nil;
//  Node:= Head;
//  while (Node <> nil) do begin
//    Diff:= Comparer.Compare(Key, Node.Key);
//    if (Diff = 0) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert);
//    Parent:= Node;
//    if (Diff < 0) then Node:= Node.Left else Node:= Node.Right;
//  end; {while}
//  InsertedNode:= NewNode(Key, Parent);
//  if Assigned(Parent) then begin
//
//    if (Diff < 0) then Parent.Left:= InsertedNode
//    else Parent.Right:= InsertedNode;
//    FixUpAfterInsert(InsertedNode);
//  end else begin
//    Root:= InsertedNode;  //SetRoot will also correct the color and parent nodes
//  end;
//
//
////  if Head = nil then begin
////    Exit(NewNode(Key, nil));
////  end;
////  if (fSpecies = TD234) then begin
////    if (Head.Left.IsRed) and (Head.Right.IsRed) then ColorFlip(Head);
////  end;
////
////  if (Less(Key, Head.Key)) then begin
////    Head.Left:= DoInsert(Head.Left, Key);
////  end else begin
////    Head.Right:= DoInsert(Head.Right, Key);
////  end;
////
////  if Head.Right.IsRed then Head:= RotateLeft(Head);
////  if Head.Left.IsRed and Head.Left.Left.IsRed then Head:= RotateRight(Head);
////
////  if (fSpecies = BU23) then begin
////    if (Head.Left.IsRed and Head.Right.IsRed) then ColorFlip(Head);
////  end;
////
////  Result:= Head;
//end;

function TRedBlackTree<T>.InternalInsert(Head: PNode; const Key: T): PNode;
begin
  Result:= rbInsertBase(Key, Head, true);
end;

//var
//  Current, Parent: PNode;
////  Compare: integer;
////begin
////  Parent:= nil;
////  Current:= Head;
////  while Current <> nil do begin
////    Compare:= Comparer.Compare(Key, Current.fKey);
////    Parent:= Current;
////    if (Compare > 0) then Current:= Current.Right
////    else if (Compare < 0) then Current:= Current.Left
////    else raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert);
////  end;
//begin
//  Parent:= Head;
//  DoInsert(Parent, Key);
//end;

//function TRedBlackTree<T>.DeleteMin(Head: PNode): PNode;
//begin
//  Assert(Assigned(Head));
//  if (Head.Left = nil) then begin
//    FreeSingleNode(Head);
//    Exit(nil);
//  end;
//  if not(Head.Left.IsRed) and not(Head.Left.Left.IsRed) then Head:= MoveRedLeft(Head);
//  Head.Left:= DeleteMin(Head.Left);
//  Result:= FixUp(Head);
//end;

destructor TRedBlackTree<T>.Destroy;
begin
  Clear;
  inherited Destroy;
end;

//function TRedBlackTree<T>.DeleteMax(Head: PNode): PNode;
//begin
//  Assert(Assigned(Head));
//  if (Head.Left.IsRed) then Head:= RotateRight(Head);
//  if Head.Right = nil then begin
//    FreeSingleNode(Head);
//    Exit(nil);
//  end;
//  if not(Head.Right.IsRed) and not(Head.Right.Left.IsRed) then Head:= MoveRedRight(Head);
//  Head.Right:= DeleteMax(Head.Right);
//  Result:= FixUp(Head);
//end;

function TRedBlackTree<T>.Remove(const Key: T): boolean;
var
  Node: PNode;
begin
  Node:= FindNode(Root, Key);
  if (Node = nil) then Exit(false);
  rbRemoveNode(Node);
  Result:= True;
end;

//var
//  OldCount: Integer;
//begin
//  OldCount:= Count;
//  Root:= DeleteNode(Root, Key);
//  if Root <> nil then begin
//    Root.NodeColor:= Color.Black;
//  end;
//  Result:= (Count <> OldCount);
//end;

function TRedBlackTree<T>.Reversed: IEnumerable<T>;
begin
  Result:= TTreeEnumerator.Create(Self, FromEnd);
end;

//function TRedBlackTree<T>.DeleteNode(Head: PNode; Key: T): PNode;
//begin
//  Assert(Assigned(Head));
//  if Less(Key, Head.Key) then begin
//    if not(Head.Left.IsRed) and not(Head.Left.Left.IsRed) then Head:= MoveRedLeft(Head);
//    Head.Left:= DeleteNode(Head.Left, Key);
//  end else begin
//    if Head.Left.IsRed then Head:= RotateRight(Head);
//    if Equal(Key, Head.Key) and (Head.Right = nil) then begin
//      FreeSingleNode(Head);
//      Exit(nil);
//    end;
//    if not(Head.Right.IsRed) and not(Head.Right.Left.IsRed) then Head:= MoveRedRight(Head);
//    if Equal(Key, Head.Key) then begin
//      Head.fKey:= MinNode(Head.Right).Key;
//      Head.Right:= DeleteMin(Head.Right);
//    end
//    else Head.Right:= DeleteNode(Head.Right, Key);
//  end;
//  Result:= FixUp(Head);
//end;

function TRedBlackTree<T>.Last: T;
begin
  if (Root = nil) then raise EInvalidOperationException.CreateRes(@SSequenceContainsNoElements);
  Result:= MaxNode(Root).Key;
end;

function TRedBlackTree<T>.Last(const Predicate: TPredicate<T>): T;
var
  Item: T;
begin
  for Item in Reversed do begin
    if Predicate(Item) then Exit(Item);
  end;
  raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TRedBlackTree<T>.LastOrDefault(const DefaultValue: T): T;
begin
  if (Root = nil) then Exit(DefaultValue);
  Result:= MaxNode(Root).Key;
end;

function TRedBlackTree<T>.LastOrDefault(const Predicate: TPredicate<T>; const DefaultValue: T): T;
var
  Item: T;
begin
  for Item in Reversed do begin
    if Predicate(Item) then Exit(Item);
  end;
  Result:= DefaultValue;
end;

function TBinaryTreeBase<T>.MinNode(const Head: PNode): PNode;
begin
  Assert(Head <> nil);
  Result:= Head;
  while Result.Left <> nil do Result:= Result.Left;
end;

function TBinaryTreeBase<T>.MaxNode(const Head: PNode): PNode;
begin
  Assert(Head <> nil);
  Result:= Head;
  while Result.Right <> nil do Result:= Result.Right;
end;

function TBinaryTreeBase<T>.Less(const A, B: T): boolean;
begin
  Result:= Comparer.Compare(A, B) < 0;
end;

function TBinaryTreeBase<T>.Equal(const A, B: T): boolean;
begin
  Result:= Comparer.Compare(A, B) = 0;
end;

function TRedBlackTree<T>.Extract(const Key: T): T;
var
  Node: PNode;
begin
  Node:= FindNode(Root, Key);
  if (Node = nil) then raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
  Result:= Node.Key;
  Remove(Key);
end;

//procedure TRedBlackTree<T>.ColorFlip(const Node: PNode);
//begin
//  Assert(Assigned(Node));
//  Node.NodeColor:= not(Node.NodeColor);
//  if Node.Left <> nil then Node.Left.NodeColor:= not(Node.Left.NodeColor);
//  if Node.Right <> nil then Node.Right.NodeColor:= not(Node.Right.NodeColor);
//end;


//function TRedBlackTree<T>.RotateRight(Node: PNode): PNode;
//var
//  x: PNode;
//begin
//  Assert(Assigned(Node));
//  // Make a left-leaning 3-Node lean to the right.
//  x:= Node.Left;
//  Node.Left:= x.Right;
//
//  x.Right:= Node;
//
//  x.NodeColor:= x.Right.NodeColor;
//  x.Right.NodeColor:= Color.Red;
//  Result:= x;
//end;
//
//function TRedBlackTree<T>.MoveRedLeft(Node: PNode): PNode;
//begin
//  Assert(Assigned(Node));
//  // Assuming that Node is red and both Node.left and Node.left.left
//  // are black, make Node.left or one of its children red.
//  ColorFlip(Node);
//  if ((Node.Right.Left.IsRed)) then begin
//    Node.Right:= RotateRight(Node.Right);
//
//    Node:= RotateLeft(Node);
//    ColorFlip(Node);
//
//    if ((Node.Right.Right.IsRed)) then begin
//      Node.Right:= RotateLeft(Node.Right);
//    end;
//  end;
//  Result:= Node;
//end;
//
//function TRedBlackTree<T>.MoveRedRight(Node: PNode): PNode;
//begin
//  Assert(Assigned(Node));
//  // Assuming that Node is red and both Node.right and Node.right.left
//  // are black, make Node.right or one of its children red.
//  ColorFlip(Node);
//  if (Node.Left.Left.IsRed) then begin
//    Node:= RotateRight(Node);
//    ColorFlip(Node);
//  end;
//  Result:= Node;
//end;
//
//procedure TRedBlackTree<T>.FixUpAfterInsert(NewNode: PNode);
//var
//  Node: PNode;
//  P,G: PNode;
//begin
//  Assert(NewNode <> fRoot);
//  Node:= NewNode;
//  //Recolor
//  while (Node.Parent.IsRed) //The root is always black, so we are sure to have a grandparent
//        and (Node.Uncle.IsRed) do begin
//    Node.Parent.NodeColor:= Color.Black;
//    Node.Uncle.NodeColor:= Color.Black;
//
//    if (Node.Parent.Parent <> Root) then begin //do not iterate into the root
//      Node.Parent.Parent.NodeColor:= Color.Red;
//      Node:= Node.Parent.Parent;
//    end else Exit;
//  end; {while}
//
//  //Rebalance
//  if (Node.Parent.NodeColor = Color.Black) then Exit;
//  P:= Node.Parent;
//  G:= P.Parent;
//  if (G.Left = P) then begin
//    if (P.Right = Node) then begin
//      RotateLeft(P);
//      Node.NodeColor:= Color.Black;
//    end else P.NodeColor:= Color.Black;
//    RotateRight(G);
//  end else begin
//    if (P.Left = Node) then begin
//      RotateRight(P);
//      Node.NodeColor:= Color.Black;
//    end else P.NodeColor:= Color.Black;
//    RotateLeft(G);
//  end;
//  G.NodeColor:= Color.Red;
//end;
//
//function TRedBlackTree<T>.FixUp(Node: PNode): PNode;
//begin
//  Assert(Assigned(Node));
//  if ((Node.Right.IsRed)) then begin
//    if (fSpecies = TD234) and ((Node.Right.Left.IsRed)) then Node.Right:= RotateRight(Node.Right);
//    Node:= RotateLeft(Node);
//  end;
//
//  if ((Node.Left.IsRed) and (Node.Left.Left.IsRed)) then Node:= RotateRight(Node);
//
//  if (fSpecies = BU23) and (Node.Left.IsRed) and (Node.Right.IsRed) then ColorFlip(Node);
//
//  Result:= Node;
//end;

procedure TBinaryTreeBase<T>.FreeSingleNode(const Node: PNode);
var
  Index: TBucketIndex;
begin
  Assert(Assigned(Node));
  if Assigned(Node.Parent) then begin
    if (Node.Parent.Left = Node) then Node.Parent.Left:= nil
    else Node.Parent.Right:= nil;
  end;
  if (fCount > 1) then begin
    index:= BucketIndex(fCount-1);
    Move(fStorage[index.Key, index.Value], Node^, SizeOf(TNode));
  end;
  Dec(fCount);
end;

function TBinaryTreeBase<T>.NextNode(const Node: PNode): PNode;
var
  Current, Parent: PNode;
begin
  if (Node = nil) then Exit(MinNode(Root))
  else if (Node.Right = nil) then begin
    Current:= Node;
    Parent:= Node.Parent;
    while (True) do begin
      if (Parent = nil) or (Current = Parent.Left) then Exit(Parent)
      else begin
        Current:= Parent;
        Parent:= Parent.Parent;
      end;
    end; {while}
  end else begin
    Result:= Node.Right;
    while Assigned(Result.Left) do begin
      Result:= Result.Left;
    end;
  end;
end;

function TBinaryTreeBase<T>.PreviousNode(const Node: PNode): PNode;
var
  p,q: PNode;
begin
  if (Node = nil) then Exit(MaxNode(Root))
  else if (Node.Left = nil) then begin
    p:= Node;
    q:= Node.Parent;
    while (True) do begin
      if (q = nil) or (p = q.Right) then Exit(q)
      else begin
        p:= q;
        q:= q.Parent;
      end;
    end; {while}
  end else begin
    Result:= Node.Left;
    while Assigned(Result.Right) do begin
      Result:= Result.Right;
    end;
  end;
end;

procedure TBinaryTreeBase<T>.TraverseInOrder(const Node: PNode; Action: TNodePredicate);
var
  Current: PNode;
begin
  Assert(Assigned(Action));
  //Assert(Assigned(Node));
  //if Assigned(Node.Left) then TraverseInOrder(Node.Left, Action);
  //if Action(Node) then Exit;
  //if Assigned(Node.Right) then TraverseInOrder(Node.Right, Action);
  Current:= Node;
  repeat
    if (Current <> nil) then if (Action(Current)) then Exit;
    Current:= NextNode(Current);
  until Current = nil;
end;

procedure TBinaryTreeBase<T>.TraverseReverseOrder(const Node: PNode; Action: TNodePredicate);
var
  Current: PNode;
begin
  Assert(Assigned(Action));
  //Assert(Assigned(Node));
//  if Assigned(Node.Right) then TraverseReverseOrder(Node.Right, Action);
//  if Action(Node) then Exit;
//  if Assigned(Node.Left) then TraverseReverseOrder(Node.Left, Action);
  Current:= Node;
  repeat
    if (Current <> nil) then if (Action(Current)) then Exit;
    Current:= PreviousNode(Current);
  until Current = nil;
end;

procedure TBinaryTreeBase<T>.TraversePostOrder(const Node: PNode; Action: TNodePredicate);
begin
  Assert(Assigned(Action));
  Assert(Assigned(Node));
  if Assigned(Node.Left) then TraversePostOrder(Node.Left, Action);
  if Assigned(Node.Right) then TraversePostOrder(Node.Right, Action);
  if Action(Node) then Exit;
end;

procedure TBinaryTreeBase<T>.TraversePreOrder(const Node: PNode; Action: TNodePredicate);
begin
  Assert(Assigned(Action));
  Assert(Assigned(Node));
  if Action(Node) then Exit;
  if Assigned(Node.Left) then TraversePreOrder(Node.Left, Action);
  if Assigned(Node.Right) then TraversePreOrder(Node.Right, Action);
end;

procedure TBinaryTreeBase<T>.Clear;
var
  Bucket: NativeUInt;
  i: NativeInt;
  j: integer;
begin
  if (fCount = 0) then Exit;
  i:= 0;
  j:= 0;
  if IsManagedType(T) then while Count > 0 do begin
    Finalize(fStorage[i][j].fKey);
    Inc(j);
    if (j = cBucketSize) then begin
      j:= 0;
      SetLength(fStorage[i],0);
      Inc(i);
    end;
    Dec(fCount);
  end else for i:= 0 to (Count div cBucketSize)-1 do begin
    //Release the bucket
    SetLength(fStorage[i],0);
  end;
  //Release the store
  SetLength(fStorage,0);
  fRoot:= nil;
  fCount:= 0;
end;

{ TRedBlackTree<K>.TreeEnumerator }

constructor TBinaryTreeBase<T>.TTreeEnumerator.Create(const Tree: TBinaryTreeBase<T>; Direction: TDirection);
begin
  inherited Create;
  fTree:= Tree;
  fDirection:= Direction;
end;

function TBinaryTreeBase<T>.TTreeEnumerator.Clone: TIterator<T>;
begin
  Result:= TTreeEnumerator.Create(Self.fTree, Self.fDirection);
end;

constructor TBinaryTreeBase<T>.TTreeEnumerator.Create(const Tree: TBinaryTreeBase<T>);
begin
  Create(Tree, FromBeginning);
end;

destructor TBinaryTreeBase<T>.TTreeEnumerator.Destroy;
begin
  inherited;
end;

function TBinaryTreeBase<T>.TTreeEnumerator.MoveNext: boolean;
begin
  if (fCurrentNode = nil) then begin
    if (fTree.Count = 0) then Exit(false);
    case fDirection of
      FromBeginning: fCurrentNode:= fTree.MinNode(fTree.Root);
      FromEnd: fCurrentNode:= fTree.MaxNode(fTree.Root);
    end;
  end else begin
    case fDirection of
      FromBeginning: fCurrentNode:= FTree.NextNode(fCurrentNode);
      FromEnd: fCurrentNode:= FTree.PreviousNode(fCurrentNode);
    end;
  end;
  if (fCurrentNode = nil) then Result:= false
  else begin
    Result:= True;
    fCurrent:= fCurrentNode.Key;
  end;
end;

procedure TBinaryTreeBase<T>.TTreeEnumerator.Reset;
begin
  fCurrentNode:= nil;
end;

{ TRedBlackTree<K, V> }

constructor TRedBlackTree<K, V>.Create(const Comparer: IComparer<K>; Species: TTreeSpecies);
begin
  fKeyComparer:= TTreeComparer.Create(Comparer);
  inherited Create(fKeyComparer, Species);
  fValueComparer:= TComparer<V>.Default;
  fOnKeyChanged:= TCollectionChangedEventImpl<K>.Create;
  fOnValueChanged:= TCollectionChangedEventImpl<V>.Create;
end;

constructor TRedBlackTree<K, V>.Create(Species: TTreeSpecies);
begin
  Create(TComparer<K>.Default, Species);
end;

constructor TRedBlackTree<K, V>.Create(const Comparer: TComparison<K>; Species: TTreeSpecies);
begin
  Create(IComparer<K>(PPointer(@Comparer)^), Species);
end;

constructor TRedBlackTree<K, V>.Create(const Collection: IEnumerable<TPair<K, V>>; Species: TTreeSpecies);
var
  Item: TPair;
begin
  Create(Species);
  for Item in Collection do Self.Add(Item.Key, Item.Value);
end;

constructor TRedBlackTree<K, V>.Create(const Values: array of TPair<K, V>; Species: TTreeSpecies);
var
  Item: TPair;
begin
  Create(Species);
  for Item in Values do Self.Add(Item.Key, Item.Value);
end;

procedure TRedBlackTree<K, V>.Add(const Key: K; const Value: V);
var
  Pair: TPair;
begin
  // Pair:= TPair.Create(Key, Value);
  Pair.Key:= Key;
  Pair.Value:= Value;
  inherited Add(Pair);
end;

procedure TRedBlackTree<K, V>.AddOrSetValue(const Key: K; const Value: V);
var
  Pair: TPair;
  Node: PNode;
begin
  Pair.Key:= Key;
  Pair.Value:= Value;
  Node:= FindNode(Root, Pair);
  if (Node = nil) then inherited Add(Pair)
  else Node.fKey:= Pair;
end;

function TRedBlackTree<K, V>.AsReadOnlyDictionary: IReadOnlyDictionary<K, V>;
begin
  Result:= Self as IReadOnlyDictionary<K, V>;
end;

function TRedBlackTree<K, V>.ContainsKey(const Key: K): boolean;
var
  DummyPair: TPair;
begin
  DummyPair.Key:= Key;
  DummyPair.Value:= default (V);
  Result:= Assigned(FindNode(Root, DummyPair));
end;

function TRedBlackTree<K, V>.ContainsValue(const Value: V): boolean;
begin
  Result:= Any(
    function(const Pair: TPair): boolean
    begin
      Result:= fValueComparer.Compare(Pair.Value, Value) = 0;
    end);
end;

function TRedBlackTree<K, V>.Contains(const Key: K; const Value: V): boolean;
begin
  Result:= Assigned(FindNode(Root, TPair.Create(Key, Value)));
end;

function TRedBlackTree<K, V>.Extract(const Key: K): V;
begin
  Result:= ExtractPair(Key).Value;
end;

function TRedBlackTree<K, V>.ExtractPair(const Key: K): TPair<K, V>;
var
  DummyPair: TPair;
  Node: PNode;
begin
  DummyPair.Key:= Key;
  DummyPair.Value:= default (V);
  Node:= FindNode(Root, DummyPair);
  if Assigned(Node) then Result:= Node.Key
  else raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TRedBlackTree<K, V>.GetComparer: IComparer<TPair>;
begin
  Result:= fKeyComparer;
end;

function TRedBlackTree<K, V>.GetItem(const Key: K): V;
var
  Node: PNode;
begin
  Node:= FindNode(Root, Pair(Key, default (V)));
  if Assigned(Node) then Result:= Node.Key.Value
  else raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TRedBlackTree<K, V>.GetKeys: IReadOnlyCollection<K>;
var
  Output: TList<K>;
  Item: TPair;
begin
  Output:= TList<K>.Create;
  for Item in Self do begin
    Output.Add(Item.Key);
  end;
  Result:= Output as IReadOnlyCollection<K>;
end;

function TRedBlackTree<K, V>.GetKeyType: PTypeInfo;
begin
  Result:= TypeInfo(K);
end;

function TRedBlackTree<K, V>.GetOnKeyChanged: ICollectionChangedEvent<K>;
begin
  Result:= fOnKeyChanged;
end;

function TRedBlackTree<K, V>.GetOnValueChanged: ICollectionChangedEvent<V>;
begin
  Result:= fOnValueChanged;
end;

function TRedBlackTree<K, V>.GetValues: IReadOnlyCollection<V>;
var
  Output: TList<V>;
  Item: TPair;
begin
  Output:= TList<V>.Create;
  for Item in Self do begin
    Output.Add(Item.Value);
  end;
  Result:= Output as IReadOnlyCollection<V>;
end;

function TRedBlackTree<K, V>.GetValueType: PTypeInfo;
begin
  Result:= TypeInfo(V);
end;

function TRedBlackTree<K, V>.Remove(const Key: K): boolean;
var
  Pair: TPair;
begin
  Pair.Create(Key, default (V));
  Result:= inherited Remove(Pair);
end;

function TRedBlackTree<K, V>.Remove(const Key: K; const Value: V): boolean;
var
  Pair: TPair;
begin
  Pair.Create(Key, Value);
  Result:= inherited Remove(Pair);
end;

function TRedBlackTree<K, V>.Extract(const Key: K; const Value: V): TPair<K, V>;
begin
  Result:= TPair.Create(Key, Value);
  inherited Remove(Result);
end;

procedure TRedBlackTree<K, V>.SetItem(const Key: K; const Value: V);
var
  Pair: TPair;
  Node: PNode;
begin
  Pair:= TPair.Create(Key, Value);
  Node:= FindNode(Root, Pair);
  if Assigned(Node) then Node.fKey:= Pair
  else raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TRedBlackTree<K, V>.TryGetValue(const Key: K; out Value: V): boolean;
var
  Pair: TPair;
  Node: PNode;
begin
  Pair:= TPair.Create(Key, default (V));
  Node:= FindNode(Root, Pair);
  Result:= Assigned(Node);
  if Result then Value:= Node.Key.Value;
end;

function TRedBlackTree<K, V>.GetValueOrDefault(const Key: K): V;
begin
  if not TryGetValue(Key, Result) then Result:= default (V);
end;

function TRedBlackTree<K, V>.GetValueOrDefault(const Key: K; const DefaultValue: V): V;
begin
  if not TryGetValue(Key, Result) then Result:= DefaultValue;
end;

function TRedBlackTree<K, V>.Pair(const Key: K; const Value: V): TPair;
begin
  Result:= TPair.Create(Key, Value);
end;

{ TRedBlackTree<K, V>.TTreeComparer }

constructor TRedBlackTree<K, V>.TTreeComparer.Create(const Comparer: IComparer<K>);
begin
  inherited Create;
  fComparer:= Comparer;
end;

function TRedBlackTree<K, V>.TTreeComparer.Compare(const A, B: TPair<K, V>): Integer;
begin
  Result:= fComparer.Compare(A.Key, B.Key);
end;

{ TNAryTree<K, V> }

constructor TNAryTree<K, V>.Create;
begin
  inherited;
end;

destructor TNAryTree<K, V>.Destroy;
begin
  inherited;
end;

// Todo: implement addition code.
function TNAryTree<K, V>.Add(const Key: TPair<K, V>): boolean;
begin
  Root:= InternalInsert(Root, Key);
end;

procedure TNAryTree<K, V>.Add(const Key: K; const Value: V);
begin
  Root:= InternalInsert(Root, Key, Value);
end;

function TNAryTree<K, V>.Get(Key: K): TPair<K, V>;
var
  Node: PNode;
begin
  Node:= FindNode(Root, Pair(Key, default (V)));
  Result:= Node.Key;
end;

function TNAryTree<K, V>.GetDirectChildern(const ParentKey: K): TArray<TPair<K, V>>;
var
  Node, Parent: PNode;
  Count, Index: Integer;
begin
  Parent:= FindNode(Root, Pair(ParentKey, default (V)));
  Count:= 0;
  Node:= Parent.Left;
  while Node <> nil do begin
    Inc(Count);
    Node:= Node.Right;
  end; { while }
  SetLength(Result, Count);
  index:= 0;
  Node:= Parent.Left;
  while Node <> nil do begin
    Result[index]:= Node.Key;
    Inc(index);
    Node:= Node.Right;
  end; { while }
end;

function TNAryTree<K, V>.InternalInsert(Head: PNode; const Key: K; const Value: V): PNode;
var
  Current, Parent: PNode;
  Compare: integer;
  KVPair: TPair<K,V>;
begin
  Parent:= nil;
  Current:= Head;
  KVPair:= Pair(Key, Value);
  while Current <> nil do begin
    Compare:= Comparer.Compare(KVPair, Current.fKey);
    Parent:= Current;
    if (Compare > 0) then Current:= Current.Right
    else if (Compare < 0) then Current:= Current.Left
    else raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert);
  end;

  Current:= NewNode(KVPair, Parent);
  if (Compare > 0) then begin
    Current.Right:= Parent.Right;
    Parent.fRight:= Current;
  end else begin
    Current.Left:= Parent.Left;
    Parent.fLeft:= Current;
  end;
  Result:= Current;
end;
//begin
//  if Head = nil then begin
//    Exit(NewNode(Pair(Key, Value), nil));
//  end;
//
//  if Equal(Key, Head.Key.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
//  else if (Less(Key, Head.Key.Key)) then begin
//    Head.Left:= InternalInsert(Head.Left, Key, Value);
//  end else begin
//    Head.Right:= InternalInsert(Head.Right, Key, Value);
//  end;
//
//  Result:= Head;
//end;

{ TTree<K> }

procedure TTree<T>.ExceptWith(const Other: IEnumerable<T>);
var
  Element: T;
begin
  if (Other = nil) then ArgumentNilError('ExceptWith');
  for Element in Other do begin
    Self.Remove(Element);
  end;
end;

procedure TTree<T>.IntersectWith(const Other: IEnumerable<T>);
var
  Element: T;
begin
  if (Other = nil) then ArgumentNilError('IntersectWith');
  for Element in Self do begin
    if not(Other.Contains(Element)) then Self.Remove(Element);
  end;
end;

procedure TTree<T>.UnionWith(const Other: IEnumerable<T>);
var
  Element: T;
begin
  if (Other = nil) then ArgumentNilError('UnionWith');
  for Element in Other do begin
    Self.Add(Element);
  end;
end;

function TTree<T>.IsSubsetOf(const Other: IEnumerable<T>): boolean;
var
  Element: T;
begin
  if (Other = nil) then ArgumentNilError('IsSubsetOf');
  for Element in Self do begin
    if not(Other.Contains(Element)) then Exit(false);
  end;
  Result:= true;
end;

function TTree<T>.IsSupersetOf(const Other: IEnumerable<T>): boolean;
var
  Element: T;
begin
  if (Other = nil) then ArgumentNilError('IsSupersetOf');
  for Element in Other do begin
    if not(Self.Contains(Element)) then Exit(false);
  end;
  Result:= true;
end;

function TTree<T>.SetEquals(const Other: IEnumerable<T>): boolean;
begin
  if (Other = nil) then ArgumentNilError('SetEquals');
  Result:= IsSubsetOf(Other) and IsSupersetOf(Other);
end;

function TTree<T>.Overlaps(const Other: IEnumerable<T>): boolean;
var
  Element: T;
begin
  if (Other = nil) then ArgumentNilError('Overlaps');
  for Element in Other do begin
    if Self.Contains(Element) then Exit(true);
  end;
  Result:= false;
end;

procedure TBinaryTreeBase<T>.ExpandStorage(OldCount: NativeUInt);
var
  Index: TBucketIndex;
begin
  index:= BucketIndex(OldCount);
  SetLength(fStorage, index.Key + 1);
  SetLength(fStorage[index.Key], cBucketSize);
end;

function TBinaryTreeBase<T>.NewNode(const Key: T; Parent: PNode): PNode;
var
  Index: TBucketIndex;
begin
  index:= BucketIndex(fCount);
  if (index.Value = 0) then begin
    // we do not test for Out of Memory. If it occurs here that's fine.
    ExpandStorage(fCount);
  end;
  // An Index.Value = 0 means insert it at the beginning of a bucket.
  // This is fine we just added a bucket.
  // The Key is the index of the bucket, which will also will be correct
  // when we just added a bucket.
  Result:= @fStorage[index.Key, index.Value];
  Result.fLeft:= nil;
  Result.fRight:= nil;
  Result.SetParent(Parent);
  Result.fKey:= Key;
  Result.fIsBlack:= Color.Red;
  Inc(fCount);
end;

procedure TBinaryTreeBase<T>.Traverse(Order: TTraverseOrder; const Action: TTraverseAction<T>);
var
  ActionWrapper: TNodePredicate;
begin
  ActionWrapper:= function(const Node: PNode): boolean
    var
      Abort: boolean;
    begin
      Abort:= false;
      Action(Node.Key, Abort);
      Result:= Abort;
    end;

  case Order of
    TTraverseOrder.PreOrder: TraversePreOrder(Root, ActionWrapper);
    TTraverseOrder.InOrder: TraverseInOrder(nil, ActionWrapper);
    TTraverseOrder.PostOrder: TraversePostOrder(Root, ActionWrapper);
    TTraverseOrder.ReverseOrder: TraverseReverseOrder(nil, ActionWrapper);
  else raise EInvalidOperationException.CreateRes(@SInvalidTraverseOrder);
  end;
end;

procedure TTree<T>.ArgumentNilError(const MethodName: string);
begin
  raise EArgumentNullException.Create(Self.ClassName + MethodName + ' does not accept a nil argument');
end;

procedure TTree<T>.AddInternal(const Item: T);
begin
  if not(Add(Item)) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert);
end;

{ TBinaryTreeBase<K, V> }

function TBinaryTreeBase<K, V>.Equal(const A, B: K): boolean;
begin
  Result:= KeyComparer.Compare(A, B) = 0;
end;

class function TBinaryTreeBase<K, V>.GetKeyComparer: IComparer<K>;
begin
  if not(Assigned(fKeyComparer)) then fKeyComparer:= TComparer<K>.Default;
  Result:= fKeyComparer;
end;

function TBinaryTreeBase<K, V>.Less(const A, B: K): boolean;
begin
  Result:= KeyComparer.Compare(A, B) < 0;
end;

function TBinaryTreeBase<K, V>.Pair(const Key: K; const Value: V): TPair;
begin
  Result:= TPair.Create(Key, Value);
end;


{ TAVLTree<T>.TAVLNodeHelper }

//function TAVLTree<T>.TAVLNodeHelper.GetBalance: TBalance;
//begin
//  Result:= TBalance(Self.fIsBlack);
//end;
//
//function TAVLTree<T>.TAVLNodeHelper.GetCount: NativeInt;
//begin
//
//end;
//
//procedure TAVLTree<T>.TAVLNodeHelper.SetBalance(const Value: TBalance);
//begin
//  TBalance(Self.fIsBlack):= Value;
//end;
//
//function TAVLTree<T>.TAVLNodeHelper.TreeDepth: NativeInt;
//begin
//
//end;

end.
