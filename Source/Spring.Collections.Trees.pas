{ *************************************************************************** }
{                                                                             }
{ Proposed addition to the                                                    }
{           Spring Framework for Delphi                                       }
{                                                                             }
{ Copyright (c) 2009-2014 Spring4D Team                                       }
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

// Adds left leaning red black trees to the spring framework.
// Based on Sedgewick's 2008 paper where he proposes an improvement to the
// his 1978 Red Black trees.

unit Spring.Collections.Trees;

interface

uses
  System.Types,
  System.SysUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Spring,
  Spring.Collections,
  Spring.Collections.Queues,
  Spring.Collections.Base,
  Spring.Collections.Sets,
  Spring.Collections.MiniStacks,
  Spring.Collections.Extensions;


type
  Color = record
    public const
      // Red and Black are modelled as boolean to simplify the IsRed function.
      Red = false;
      Black = true;
  end;

  TTreeSpecies = (TD234, BU23); // Default is TD234

  ITree<T> = interface(ISet<T>)
  end;

  ITree<K,V> = interface(IDictionary<K,V>)
  end;

  Tree<T> = record
  public
    class function RedBlackTree(Species: TTreeSpecies = TD234): ITree<T>; overload; static;
    class function RedBlackTree(const Comparer: IComparer<T>; Species: TTreeSpecies = TD234): ITree<T>; overload; static;
    class function RedBlackTree(const Comparer: TComparison<T>; Species: TTreeSpecies = TD234): ITree<T>; overload; static;
    class function RedBlackTree(const Values: array of T; Species: TTreeSpecies = TD234): ITree<T>; overload; static;
    class function RedBlackTree(const Collection: IEnumerable<T>; Species: TTreeSpecies = TD234): ITree<T>; overload; static;
  end;

  Tree<K,V> = record
  public
    class function RedBlackTree(Species: TTreeSpecies = TD234): ITree<K,V>; overload; static;
    class function RedBlackTree(const Comparer: IComparer<K>; Species: TTreeSpecies = TD234): ITree<K,V>; overload; static;
    class function RedBlackTree(const Comparer: TComparison<K>; Species: TTreeSpecies = TD234): ITree<K,V>; overload; static;
    class function RedBlackTree(const Values: array of TPair<K,V>; Species: TTreeSpecies = TD234): ITree<K,V>; overload; static;
    class function RedBlackTree(const Collection: IEnumerable<TPair<K,V>>; Species: TTreeSpecies = TD234): ITree<K,V>; overload; static;
  end;

type
  {$Region 'TTree<K>'}
  /// <summary>
  ///   Abstract parent for tree, defines the tree as a set of keys
  /// </summary>
  TTree<K> = class abstract(TCollectionBase<K>, ISet<K>, ITree<K>)
  private
    procedure ArgumentNilError(const MethodName: string); virtual;
  protected
    procedure AddInternal(const Item: K); override;
  public

    ///	<summary>
    ///	  Adds an element to the current set and returns a Value to indicate if
    ///	  the element was successfully added.
    ///	</summary>
    ///	<param name="item">
    ///	  The element to add to the set.
    ///	</param>
    ///	<returns>
    ///	  <b>True</b> if the element is added to the set; <b>False</b> if the
    ///	  element is already in the set.
    ///	</returns>
    function Add(const Item: K): boolean; virtual; abstract;

    ///	<summary>
    ///	  Determines whether a <see cref="Tree&lt;T&gt;" /> object contains
    ///	  the specified element.
    ///	</summary>
    ///	<param name="item">
    ///	  The element to locate in the <see cref="THashSet&lt;T&gt;" /> object.
    ///	</param>
    ///	<returns>
    ///	  <b>True</b> if the <see cref="THashSet&lt;T&gt;" /> object contains
    ///	  the specified element; otherwise, <b>False</b>.
    ///	</returns>
    function Contains(const Key: K): boolean; reintroduce; virtual; abstract;

    ///	<summary>
    ///	  Removes all elements in the specified Collection from the current
    ///	  <see cref="Tree&lt;T&gt;" /> object.
    ///	</summary>
    ///	<param name="other">
    ///	  The Collection of items to remove from the
    ///	  <see cref="THashSet&lt;T&gt;" /> object.
    ///	</param>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    procedure ExceptWith(const other: IEnumerable<K>); virtual;

    ///	<summary>
    ///	  Modifies the current <see cref="Tree&lt;T&gt;" /> object to
    ///	  contain only elements that are present in that object and in the
    ///	  specified Collection.
    ///	</summary>
    ///	<param name="other">
    ///	  The Collection to compare to the current
    ///	  <see cref="Tree&lt;T&gt;" /> object.
    ///	</param>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    procedure IntersectWith(const other: IEnumerable<K>); virtual;

    ///	<summary>
    ///	  Modifies the current <see cref="Tree&lt;T&gt;" /> object to
    ///	  contain all elements that are present in itself, the specified
    ///	  Collection, or both.
    ///	</summary>
    ///	<param name="other">
    ///	  The Collection to compare to the current
    ///	  <see cref="Tree&lt;T&gt;" /> object.
    ///	</param>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    procedure UnionWith(const other: IEnumerable<K>); virtual;

    ///	<summary>
    ///	  Determines whether a <see cref="Tree&lt;T&gt;" /> object is a
    ///	  subset of the specified Collection.
    ///	</summary>
    ///	<param name="other">
    ///	  The Collection to compare to the current
    ///	  <see cref="THashSet&lt;T&gt;" /> object.
    ///	</param>
    ///	<returns>
    ///	  <b>True</b> if the <see cref="Tree&lt;T&gt;" /> object is a
    ///	  subset of <i>other</i>; otherwise, <b>False</b>.
    ///	</returns>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    function IsSubsetOf(const other: IEnumerable<K>): Boolean; virtual;

    ///	<summary>
    ///	  Determines whether a <see cref="Tree&lt;T&gt;" /> object is a
    ///	  superset of the specified Collection.
    ///	</summary>
    ///	<param name="other">
    ///	  The Collection to compare to the current
    ///	  <see cref="THashSet&lt;T&gt;" /> object.
    ///	</param>
    ///	<returns>
    ///	  <b>True</b> if the <see cref="Tree&lt;T&gt;" /> object is a
    ///	  superset of <i>other</i>; otherwise, <b>False</b>.
    ///	</returns>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    function IsSupersetOf(const other: IEnumerable<K>): Boolean; virtual;

    ///	<summary>
    ///	  Determines whether a <see cref="THashSet&lt;T&gt;" /> object and the
    ///	  specified Collection contain the same elements.
    ///	</summary>
    ///	<param name="other">
    ///	  The Collection to compare to the current
    ///	  <see cref="THashSet&lt;T&gt;" /> object.
    ///	</param>
    ///	<returns>
    ///	  <b>True</b> if the <see cref="THashSet&lt;T&gt;" /> object is equal
    ///	  to <i>other</i>; otherwise, <b>False</b>.
    ///	</returns>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    function SetEquals(const other: IEnumerable<K>): Boolean; virtual;

    ///	<summary>
    ///	  Determines whether the current <see cref="Tree&lt;T&gt;" />
    ///	  object and a specified Collection share common elements.
    ///	</summary>
    ///	<param name="other">
    ///	  The Collection to compare to the current
    ///	  <see cref="THashSet&lt;T&gt;" /> object.
    ///	</param>
    ///	<returns>
    ///	  <b>True</b> if the <see cref="Tree&lt;T&gt;" /> object and
    ///	  <i>other</i> share at least one common element; otherwise,
    ///	  <b>False</b>.
    ///	</returns>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    function Overlaps(const other: IEnumerable<K>): Boolean; virtual;
  end;
  {$EndRegion}

  {$SCOPEDENUMS ON}
  TraverseOrder = (PreOrder, InOrder, ReverseOrder, PostOrder);
  {$SCOPEDENUMS OFF}

  {$Region 'TBinaryTreeBase<T>'}
  TBinaryTreeBase<T> = class(TTree<T>)
  private type
    // Nodes in the tree, because the parent is not stored, these are dumb nodes.
    PNode = ^TNode;
    TNode = record
    strict private
      fParent: PNode; //Used for rearraging nodes in the underlying storage.
    private
      fLeft: PNode; // Left nodes hold lower values
      fRight: PNode; // Right nodes hold higher values
      fKey: T; // The payload, use a TPair<T,V> to store a Key/Value pair.
      fIsBlack: boolean; // Red is the default.

      /// <summary>
      /// Static method to get the color. Always use this method, never read the
      /// field directly, because the Node might be nil.
      /// </summary>
      /// <returns>false if self is nil.</returns>
        function IsRed: boolean; inline;
        procedure SetParent(const Value: PNode);
        procedure SetLeft(const Value: PNode); inline;
        procedure SetRight(const Value: PNode); inline;
    public
      property Left: PNode read fLeft write SetLeft;
      property Right: PNode read fRight write SetRight;
      property Parent: PNode read fParent;
      property Key: T read fKey write fKey;
      property NodeColor: boolean read fIsBlack write fIsBlack;
    end;
  private type
    /// <summary>
    /// Enumerator for the trees, works on Nodes, not values.
    /// </summary>
    TTreeEnumerator = class(TIterator<T>)
    private
      fHead: PNode;
      fCurrentNode: PNode;
      fStack: TMiniStack<PNode>;
      // Enumerator can be reversed.
      fDirection: TDirection;
    protected
      // function GetCurrentNonGeneric: V; override;
      function Clone: TIterator<T>; override;
      constructor Create(const Head: PNode; Direction: TDirection); overload;
      constructor Create(const Head: PNode); overload;
    public
      destructor Destroy; override;
      procedure Reset; override;
      function MoveNext: Boolean; override;
      // function GetEnumerator: IEnumerator<T>; override;
      //function GetCurrent: T;
      property Current: T read GetCurrent;
      property CurrentNode: PNode read fCurrentNode;
    end;
  private type
    TNodePredicate = TPredicate<PNode>;
  strict private
    constructor Create;
  protected
    /// <summary>
    /// Destroys a single Node and updates the count.
    /// Fixes the root if nessecary
    /// </summary>
    /// <remarks>
    /// Only deletes a single Node; does not delete childern and does not fixup the tree.
    /// </remarks>
    procedure FreeSingleNode(const Node: PNode);
  private
    fStorage: TArray<TNode>;
    fRoot: PNode;
    fCount: Integer;
    procedure TraversePreOrder(const Node: PNode; Action: TNodePredicate);
    procedure TraversePostOrder(const Node: PNode; Action: TNodePredicate);
    procedure TraverseInOrder(const Node: PNode; Action: TNodePredicate);
    procedure TraverseReverseOrder(const Node: PNode; Action: TNodePredicate);
    /// <summary>
    /// Convienance method to see if two keys are equal.
    /// </summary>
    function Equal(const a, b: T): boolean; inline;
    /// <summary>
    /// Convienance method to see if (a < b).
    /// </summary>
    function Less(const a, b: T): Boolean; inline;
    /// <summary>
    /// Finds the Node containing the Key in the given subtree.
    /// </summary>
    /// <param name="Head">The head of the subtree</param>
    /// <param name="Key">The Key to look for</param>
    /// <returns>nil if the Key is not found in the subtree; the containing Node otherwise</returns>
    function FindNode(const Head: PNode; const Key: T): PNode;

    function NewNode(const Key: T; Parent: PNode): PNode;

    function InternalInsert(Head: PNode; const Key: T): PNode; virtual;
    procedure ExpandStorage(OldCount: NativeUInt);

    property Root: PNode read fRoot;
  public type
    TTraverseAction = reference to procedure (const Key: T; var Abort: boolean);
  public
    function Add(const Item: T): boolean; override;
    function Contains(const Key: T): boolean; override;
    procedure Clear; reintroduce;
    property Count: integer read fCount;
    procedure Traverse(Order: TraverseOrder; const Action: TTraverseAction);
  end;
  {$EndRegion}


  {$Region 'TBinaryTreeBase<K,V>'}
  TBinaryTreeBase<K,V> = class(TBinaryTreeBase<TPair<K, V>>)
  protected type
    TPair = TPair<K,V>;
  private type
    PNode = TBinaryTreeBase<TPair>.PNode;
  private
    class var fKeyComparer: IComparer<K>;
    class function GetKeyComparer: IComparer<K>; static;
  public type
    TTraverseAction = reference to procedure (const Key: K; const Value: V; var Abort: boolean);
  protected
    function Equal(const a, b: K): boolean; overload;
    function Less(const a, b: K): boolean; overload;
    function Pair(const Key: K; const Value: V): TPair; inline;
    class property KeyComparer: IComparer<K> read GetKeyComparer;
  public
    procedure Traverse(Order: TraverseOrder; const Action: TTraverseAction);
  end;
  {$EndRegion}

  {$Region 'TNAryTree<K,V>'}
  TNAryTree<K, V> = class(TBinaryTreeBase<K, V>)
  private type
    PNode = ^TNode;
    TNode = TBinaryTreeBase<TPair<K,V>>.TNode;
  private
    /// <summary>
    /// Inserts a Node into the subtree anchored at Start.
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The Key to insert into the subtree</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be assigned in place if the old start Node
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
    function Add(const Key: TPair<K,V>): boolean; overload; override;
    procedure Add(const Key: K; const Value: V); reintroduce; overload; virtual;
    function Get(Key: K): TPair<K,V>;
    function GetDirectChildern(const ParentKey: K): TArray<TPair<K,V>>;
  end;
  {$EndRegion}


  {$Region 'TRedBlackTree<T>'}
  /// <summary>
  /// Left Leaning red black tree, mainly useful for encaplating a Set.
  /// Does not allow duplicate items.
  /// </summary>
  TRedBlackTree<T> = class(TBinaryTreeBase<T>)
  private type
    PNode = ^TNode;
    TNode = TBinaryTreeBase<T>.TNode;
    TNodePredicate = TBinaryTreeBase<T>.TNodePredicate;
  private
    // A RedBlack tree emulates a binary 234 tree.
    // This tree can run in 234 and 23 mode.
    // For some problem domains the 23 runs faster than the 234
    // For other problems the 234 is faster.
    fSpecies: TTreeSpecies;
{$IF defined(debug)}
  private // Test methods
    function Is234(Node: PNode): boolean; overload; virtual;
    function IsBST(Node: PNode; MinKey, MaxKey: T): boolean; overload; virtual;
    function IsBalanced(Node: PNode; Black: integer): boolean; overload; virtual;
{$ENDIF}
  private
    /// <summary>
    /// Deletes the rightmost child of Start Node, retaining the RedBlack property
    /// </summary>
    function DeleteMax(Head: PNode): PNode; overload;
    /// <summary>
    /// Deletes the leftmost child of Start Node, retaining the RedBlack property
    /// </summary>
    function DeleteMin(Head: PNode): PNode; overload;
    /// <summary>
    /// Deletes the Node with the given Key inside the subtree under Start
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The id of the Node to be deleted</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be assigned in place if the old start Node
    /// in order to retain the RedBlackness of the tree</returns>
    /// <remarks>
    /// Does *not* return an exception if the Key is not found, but simply returns
    /// the Start Node as its result.
    /// Examine the Count property to see if a Node was deleted.
    /// </remarks>
    function DeleteNode(Head: PNode; Key: T): PNode; overload;

    /// <summary>
    /// Inserts a Node into the subtree anchored at Start.
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The Key to insert into the subtree</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be assigned in place if the old start Node
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
    function FixUp(Node: PNode): PNode;
    /// <summary>
    /// Inverts the color of a 3-Node and its immediate childern.
    /// </summary>
    /// <param name="Head"></param>
    procedure ColorFlip(const Node: PNode);
    /// <summary>
    /// Assuming that Node is red and both Node.left and Node.left.left
    /// are black, make Node.left or one of its children red.
    /// </summary>
    function MoveRedLeft(Node: PNode): PNode;
    /// <summary>
    /// Assuming that Node is red and both Node.right and Node.right.left
    /// are black, make Node.right or one of its children red.
    /// </summary>
    function MoveRedRight(Node: PNode): PNode;
    /// <summary>
    /// Make a right-leaning 3-Node lean to the left.
    /// </summary>
    function RotateLeft(Node: PNode): PNode;
    /// <summary>
    /// Make a left-leaning 3-Node lean to the right.
    /// </summary>
    function RotateRight(Node: PNode): PNode;

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
{$IF defined(Debug)}
  public // Test Methods
    function Is234: boolean; overload;
    function IsBST: boolean; overload;
    function IsBalanced: boolean; overload;
    function Check: boolean;
{$ENDIF}
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
  {$EndRegion}

  {$Region 'TRedBlackTree<K,V>'}
  TRedBlackTree<K, V> = class(TRedBlackTree<TPair<K, V>>, IDictionary<K, V>, ITree<K,V>)
  private type
    TPair = TPair<K, V>;
  private type
    TTreeComparer = class(TInterfacedObject, IComparer<TPair>)
    private
      fComparer: IComparer<K>;
    public
      constructor Create(const Comparer: IComparer<K>);
      function Compare(const a, b: TPair): Integer;
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
    function Pair(const Key:K; const Value: V): TPair;
{$ENDREGION}
  public type
    TTraverseAction = reference to procedure (const Key: K; const Value: V; var Abort: boolean);
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
    function ContainsKey(const Key: K): Boolean;
    /// <summary>
    /// Determines whether the IDictionary&lt;K, V&gt; contains an
    /// element with the specified Value.
    /// </summary>
    /// <param name="Value">
    /// The Value to locate in the IDictionary&lt;K, V&gt;.
    /// </param>
    function ContainsValue(const Value: V): Boolean;

    /// <summary>
    ///   Determines whether the IMap&lt;TKey,TValue&gt; contains the specified
    ///   Key/Value pair.
    /// </summary>
    /// <param name="Key">
    ///   The Key of the pair to locate in the IMap&lt;TKey, TValue&gt;.
    /// </param>
    /// <param name="Value">
    ///   The Value of the pair to locate in the IMap&lt;TKey, TValue&gt;.
    /// </param>
    /// <returns>
    ///   <b>True</b> if the IMap&lt;TKey, TValue&gt; contains a pair with the
    ///   specified Key and Value; otherwise <b>False</b>.
    /// </returns>
    function Contains(const Key: K; const Value: V): Boolean; reintroduce;

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
    function Remove(const Key: K): Boolean; reintroduce; overload;
    function Remove(const Key: K; const Value: V): Boolean; reintroduce; overload;

    function Extract(const Key: K; const Value: V): TPair; reintroduce; overload;

    /// <summary>
    ///   Removes the Value for a specified Key without triggering lifetime
    ///   management for objects.
    /// </summary>
    /// <param name="Key">
    ///   The Key whose Value to remove.
    /// </param>
    /// <returns>
    ///   The removed Value for the specified Key if it existed; <b>default</b>
    ///   otherwise.
    /// </returns>
    function Extract(const Key: K): V; reintroduce; overload;

    /// <summary>
    ///   Removes the Value for a specified Key without triggering lifetime
    ///   management for objects.
    /// </summary>
    /// <param name="Key">
    ///   The Key whose Value to remove.
    /// </param>
    /// <returns>
    ///   The removed pair for the specified Key if it existed; <b>default</b>
    ///   otherwise.
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
    function TryGetValue(const Key: K; out Value: V): Boolean;

    /// <summary>
    ///   Gets the Value for a given Key if a matching Key exists in the
    ///   dictionary; returns the default Value otherwise.
    /// </summary>
    function GetValueOrDefault(const Key: K): V; overload;

    /// <summary>
    ///   Gets the Value for a given Key if a matching Key exists in the
    ///   dictionary; returns the given default Value otherwise.
    /// </summary>
    function GetValueOrDefault(const Key: K; const defaultValue: V): V; overload;

    function AsReadOnlyDictionary: IReadOnlyDictionary<K, V>;

    procedure Traverse(order: TraverseOrder; const Action: TTraverseAction);

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
  {$EndRegion}

resourcestring
  SSetDuplicateInsert = 'Cannot insert a duplicate item in a set';

implementation

uses
  Spring.ResourceStrings,
  Spring.Collections.Lists,
  Spring.Collections.Events;


procedure TBinaryTreeBase<T>.TNode.SetLeft(const Value: PNode);
begin
  fLeft := Value;
  if Assigned(Value) then Value.fParent:= @Self;
end;

procedure TBinaryTreeBase<T>.TNode.SetParent(const Value: PNode);
begin
  fParent:= Value;
end;

procedure TBinaryTreeBase<T>.TNode.SetRight(const Value: PNode);
begin
  fRight := Value;
  if Assigned(Value) then Value.fParent:= @Self;
end;

constructor TRedBlackTree<T>.Create(Species: TTreeSpecies);
begin
  inherited Create;
  fSpecies:= Species;
end;

constructor TRedBlackTree<T>.Create(const Comparer: TComparison<T>;
  Species: TTreeSpecies);
begin
  inherited Create(Comparer);
  fSpecies := Species;
end;

constructor TRedBlackTree<T>.Create(const Comparer: IComparer<T>; Species: TTreeSpecies);
begin
  inherited Create(Comparer);
  fSpecies := Species;
end;

constructor TRedBlackTree<T>.Create(const Collection: IEnumerable<T>;
  Species: TTreeSpecies);
begin
  Create(Species);
  AddRange(Collection);
end;

constructor TRedBlackTree<T>.Create(const Values: array of T; Species: TTreeSpecies);
begin
  Create(Species);
  AddRange(Values);
end;

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
  OldCount: integer;
begin
  OldCount:= Count;
  fRoot:= Self.InternalInsert(fRoot, Item);
  Result:= (Count <> OldCount);
end;

function TRedBlackTree<T>.GetEnumerator: IEnumerator<T>;
begin
  Result:= TTreeEnumerator.Create(Root);
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
begin
  if Head = nil then begin
    Exit(NewNode(Key, nil));
  end;

  if Equal(Key, Head.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
  else if (Less(Key, Head.Key)) then begin
    Head.Left:= InternalInsert(Head.Left, Key);
  end
  else begin
    Head.Right:= InternalInsert(Head.Right, Key);
  end;

  Result:= Head;
end;


function TRedBlackTree<T>.First: T;
begin
  if (Root = nil) then raise EInvalidOperationException.CreateRes(@SSequenceContainsNoElements);
  Result:= MinNode(Root).Key;
end;

function TRedBlackTree<T>.MinNode(const Head: PNode): PNode;
begin
  Assert(Head <> nil);
  Result:= Head;
  while Result.Left <> nil do Result:= Result.Left;
end;

function TRedBlackTree<T>.MaxNode(const Head: PNode): PNode;
begin
  Assert(Head <> nil);
  Result:= Head;
  while Result.Right <> nil do Result:= Result.Right;
end;

function TBinaryTreeBase<T>.TNode.IsRed: boolean;
begin
  if @Self = nil then Exit(false);
  Result:= (NodeColor = Color.Red);
end;

function TRedBlackTree<T>.Add(const Key: T): boolean;
var
  OldCount: integer;
begin
  OldCount:= Count;
  fRoot:= InternalInsert(fRoot, Key);
  // if fRoot.IsRed then Inc(HeightBlack);
  fRoot.NodeColor:= Color.Black;
  Result:= (Count <> OldCount);
end;

function TRedBlackTree<T>.InternalInsert(Head: PNode; const Key: T): PNode;
begin
  if Head = nil then begin
    Exit(NewNode(Key, nil));
  end;
  if (fSpecies = TD234) then begin
    if (Head.Left.IsRed) and (Head.Right.IsRed) then ColorFlip(Head);
  end;

  if Equal(Key, Head.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
  else if (Less(Key, Head.Key)) then begin
    Head.Left:= InternalInsert(Head.Left, Key);
  end else begin
    Head.Right:= InternalInsert(Head.Right, Key);
  end;

  // if (fSpecies = BST) then exit(Head);

  if Head.Right.IsRed then Head:= RotateLeft(Head);

  if Head.Left.IsRed and Head.Left.Left.IsRed then Head:= RotateRight(Head);

  if (fSpecies = BU23) then begin
    if (Head.Left.IsRed and Head.Right.IsRed) then ColorFlip(Head);
  end;

  Result:= Head;
end;

function TRedBlackTree<T>.DeleteMin(Head: PNode): PNode;
begin
  if (Head.Left = nil) then begin
    FreeSingleNode(Head);
    Exit(nil);
  end;
  if not(Head.Left.IsRed) and not(Head.Left.Left.IsRed) then Head:= MoveRedLeft(Head);
  Head.Left:= DeleteMin(Head.Left);
  Result:= FixUp(Head);
end;

destructor TRedBlackTree<T>.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TRedBlackTree<T>.DeleteMax(Head: PNode): PNode;
begin
  if (Head.Left.IsRed) then Head:= RotateRight(Head);
  if Head.Right = nil then begin
    FreeSingleNode(Head);
    Exit(nil);
  end;
  if not(Head.Right.IsRed) and not(Head.Right.Left.IsRed) then Head:= MoveRedRight(Head);
  Head.Right:= DeleteMax(Head.Right);
  Result:= FixUp(Head);
end;

function TRedBlackTree<T>.Remove(const Key: T): boolean;
var
  OldCount: integer;
begin
  OldCount:= Count;
  fRoot:= DeleteNode(Root, Key);
  if Root <> nil then Root.NodeColor:= Color.Black;
  Result:= (Count <> OldCount);
end;

function TRedBlackTree<T>.Reversed: IEnumerable<T>;
begin
  Result:= TTreeEnumerator.Create(Root, FromEnd);
end;

function TRedBlackTree<T>.DeleteNode(Head: PNode; Key: T): PNode;
begin
  if Less(Key, Head.Key) then begin
    if not(Head.Left.IsRed) and not(Head.Left.Left.IsRed) then Head:= MoveRedLeft(Head);
    Head.Left:= DeleteNode(Head.Left, Key);
  end else begin
    if Head.Left.IsRed then Head:= RotateRight(Head);
    if Equal(Key, Head.Key) and (Head.Right = nil) then begin
      FreeSingleNode(Head);
      Exit(nil);
    end;
    if not(Head.Right.IsRed) and not(Head.Right.Left.IsRed) then Head:= MoveRedRight(Head);
    if Equal(Key, Head.Key) then begin
      Head.Key:= MinNode(Head.Right).Key;
      Head.Right:= DeleteMin(Head.Right);
    end
    else Head.Right:= DeleteNode(Head.Right, Key);
  end;
  Result:= FixUp(Head);
end;

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

function TBinaryTreeBase<T>.Less(const a, b: T): Boolean;
begin
  Result:= Comparer.Compare(a, b) < 0;
end;

function TBinaryTreeBase<T>.Equal(const a, b: T): boolean;
begin
  Result:= Comparer.Compare(a, b) = 0;
end;

function TRedBlackTree<T>.Extract(const Key: T): T;
var
  Node: PNode;
begin
  Node:= FindNode(Root, Key);
  Result:= Node.Key;
  Remove(Key);
end;

procedure TRedBlackTree<T>.ColorFlip(const Node: PNode);
begin
  Node.NodeColor:= not(Node.NodeColor);
  if Node.Left <> nil then Node.Left.NodeColor:= not(Node.Left.NodeColor);
  if Node.Right <> nil then Node.Right.NodeColor:= not(Node.Right.NodeColor);
end;

function TRedBlackTree<T>.RotateLeft(Node: PNode): PNode;
var
  x: PNode;
begin
  // Make a right-leaning 3-Node lean to the left.
  x:= Node.Right;
  Node.Right:= x.Left;

  x.Left:= Node;

  x.NodeColor:= x.Left.NodeColor;
  x.Left.NodeColor:= Color.Red;
  Result:= x;
end;

function TRedBlackTree<T>.RotateRight(Node: PNode): PNode;
var
  x: PNode;
begin
  // Make a left-leaning 3-Node lean to the right.
  x:= Node.Left;
  Node.Left:= x.Right;

  x.Right:= Node;

  x.NodeColor:= x.Right.NodeColor;
  x.Right.NodeColor:= Color.Red;
  Result:= x;
end;

function TRedBlackTree<T>.MoveRedLeft(Node: PNode): PNode;
begin
  // Assuming that Node is red and both Node.left and Node.left.left
  // are black, make Node.left or one of its children red.
  ColorFlip(Node);
  if ((Node.Right.Left.IsRed)) then begin
    Node.Right:= RotateRight(Node.Right);

    Node:= RotateLeft(Node);
    ColorFlip(Node);

    if ((Node.Right.Right.IsRed)) then begin
      Node.Right:= RotateLeft(Node.Right);
    end;
  end;
  Result:= Node;
end;

function TRedBlackTree<T>.MoveRedRight(Node: PNode): PNode;
begin
  // Assuming that Node is red and both Node.right and Node.right.left
  // are black, make Node.right or one of its children red.
  ColorFlip(Node);
  if (Node.Left.Left.IsRed) then begin
    Node:= RotateRight(Node);
    ColorFlip(Node);
  end;
  Result:= Node;
end;



function TRedBlackTree<T>.FixUp(Node: PNode): PNode;
begin
  if ((Node.Right.IsRed)) then begin
    if (fSpecies = TD234) and ((Node.Right.Left.IsRed)) then Node.Right:= RotateRight(Node.Right);
    Node:= RotateLeft(Node);
  end;

  if ((Node.Left.IsRed) and (Node.Left.Left.IsRed)) then Node:= RotateRight(Node);

  if (fSpecies = BU23) and (Node.Left.IsRed) and (Node.Right.IsRed) then ColorFlip(Node);

  Result:= Node;
end;

procedure TBinaryTreeBase<T>.FreeSingleNode(const Node: PNode);
begin
  if Assigned(Node.Parent) then begin
    if (Node.Parent.Left = Node) then Node.Parent.Left:= nil
    else Node.Parent.Right:= nil;
  end;
  if (fCount > 1) then begin
    Move(fStorage[fCount-1], Node^, SizeOf(TNode));
  end;
  Dec(fCount);
end;

procedure TBinaryTreeBase<T>.TraverseInOrder(const Node: PNode; Action: TNodePredicate);
begin
  if assigned(Node.Left) then TraverseInOrder(Node.Left, Action);
  if Action(Node) then exit;
  if assigned(Node.Right) then TraverseInOrder(Node.Right, Action);
end;

procedure TBinaryTreeBase<T>.TraverseReverseOrder(const Node: PNode; Action:
  TNodePredicate);
begin
  if assigned(Node.Right) then TraverseReverseOrder(Node.Right, Action);
  if Action(Node) then exit;
  if assigned(Node.Left) then TraverseReverseOrder(Node.Left, Action);
end;

procedure TBinaryTreeBase<T>.TraversePostOrder(const Node: PNode; Action: TNodePredicate);
begin
  if assigned(Node.Left) then TraversePostOrder(Node.Left, Action);
  if assigned(Node.Right) then TraversePostOrder(Node.Right, Action);
  if Action(Node) then exit;
end;

procedure TBinaryTreeBase<T>.TraversePreOrder(const Node: PNode; Action: TNodePredicate);
begin
  if Action(Node) then exit;
  if assigned(Node.Left) then TraversePreOrder(Node.Left, Action);
  if assigned(Node.Right) then TraversePreOrder(Node.Right, Action);
end;

procedure TBinaryTreeBase<T>.Clear;
begin
  TraversePostOrder(Root,
    function(const Node: PNode): boolean
    begin
      FreeSingleNode(Node);
      Result:= false;
    end);
  fRoot:= nil;
  Assert(fCount = 0);
end;

{$IF defined(debug)}

function TRedBlackTree<T>.Check: boolean;
begin
  // Is this tree a red-black tree?
  Result:= isBST and Is234 and IsBalanced;
end;

function TRedBlackTree<T>.IsBST: boolean;
begin
  // Is this tree a BST?
  if (Root = nil) then exit(true);
  Result:= IsBST(Root, First, Last);
end;

function TRedBlackTree<T>.IsBST(Node: PNode; MinKey, MaxKey: T): boolean;
begin
  // Are all the values in the BST rooted at x between min and max,
  // and does the same property hold for both subtrees?
  if (Node = nil) then Exit(true);
  if (Less(Node.Key, MinKey) or Less(MaxKey, Node.Key)) then Exit(false);
  Result:= IsBST(Node.Left, MinKey, Node.Key) and IsBST(Node.Right, Node.Key, MaxKey);
end;

function TRedBlackTree<T>.Is234: boolean;
begin
  Result:= Is234(Root);
end;

function TRedBlackTree<T>.Is234(Node: PNode): boolean;
begin
  if (Node = nil) then Exit(true);
  if ((Node.Right.IsRed)) then Exit((fspecies = TD234) and (Node.Left.IsRed));
  if (not(Node.Right.IsRed)) then Exit(true);
  Result:= Is234(Node.Left) and Is234(Node.Right);
end;

function TRedBlackTree<T>.IsBalanced: boolean;
var
  x: PNode;
  BlackCount: Integer;
begin
  // Do all paths from root to leaf have same number of black edges?
  BlackCount:= 0; // number of black links on path from root to min
  x:= Root;
  while (x <> nil) do begin
    if (not(x.IsRed)) then Inc(BlackCount);
    x:= x.Left;
  end;
  Result:= IsBalanced(Root, blackCount);
end;

function TRedBlackTree<T>.IsBalanced(Node: PNode; Black: integer): boolean;
begin
  // Does every path from the root to a leaf have the given number
  // of black links?
  if (Node = nil) and (black = 0) then Exit(true)
  else if (Node = nil) and (black <> 0) then Exit(false);
  if (not(Node.IsRed)) then Dec(black);
  Result:= IsBalanced(Node.Left, black) and IsBalanced(Node.Right, black);
end;
{$ENDIF}
{ TRedBlackTree<K>.TreeEnumerator }

constructor TBinaryTreeBase<T>.TTreeEnumerator.Create(const Head: PNode; Direction: TDirection);
begin
  inherited Create;
  fHead:= Head;
  fStack.Init;
  fDirection:= Direction;
end;

function TBinaryTreeBase<T>.TTreeEnumerator.Clone: TIterator<T>;
begin
  Result:= TTreeEnumerator.Create(self.fHead, Self.fDirection);
end;

constructor TBinaryTreeBase<T>.TTreeEnumerator.Create(const Head: PNode);
begin
  Create(Head, FromBeginning);
end;

destructor TBinaryTreeBase<T>.TTreeEnumerator.Destroy;
begin
  // fStack.Free; //stack is a record, does not need to be freed.
  inherited;
end;


function TBinaryTreeBase<T>.TTreeEnumerator.MoveNext: Boolean;
var
  Node: PNode;
begin
  if (fCurrentNode = nil) then begin
    fCurrentNode:= fHead;
    if fCurrentNode = nil then Exit(false);
    // Start in the Left most position
    fStack.Push(fCurrentNode);
  end;
  while not fStack.IsEmpty do begin
    { get the Node at the head of the queue }
    Node:= fStack.Pop;
    { if it's nil, pop the next Node, perform the Action on it. If
      this returns with a request to stop then return this Node }
    if (Node = nil) then begin
      fCurrentNode:= fStack.Pop;
      fCurrent:= fCurrentNode.Key;
      exit(true);
    end
    { otherwise, the children of the Node have not been pushed yet }
    else begin
      case fDirection of
        FromBeginning:begin { push the Left child, if it's not nil }
          if (Node.Right <> nil) then fStack.Push(Node.Right);
          { push the Node, followed by a nil pointer }
          fStack.Push(Node);
          fStack.Push(nil);
          { push the Right child, if it's not nil }
          if (Node.Left <> nil) then fStack.Push(Node.Left);
        end; { FromBeginning }
        FromEnd:begin { push the Left child, if it's not nil }
          if (Node.Left <> nil) then fStack.Push(Node.Left);
          { push the Node, followed by a nil pointer }
          fStack.Push(Node);
          fStack.Push(nil);
          { push the Right child, if it's not nil }
          if (Node.Right <> nil) then fStack.Push(Node.Right);
        end; { FromEnd: }
      end; { case }
    end; { else }
  end; { while }
  Result:= false;
end;

procedure TBinaryTreeBase<T>.TTreeEnumerator.Reset;
begin
  fStack.Init;
  fCurrentNode:= nil;
end;

{ TRedBlackTree<K, V> }

constructor TRedBlackTree<K, V>.Create(const Comparer: IComparer<K>; Species: TTreeSpecies);
begin
  fKeyComparer := TTreeComparer.Create(Comparer);
  inherited Create(fKeyComparer);
  fValueComparer:= TComparer<V>.Default;
  fOnKeyChanged:= TCollectionChangedEventImpl<K>.Create;
  fOnValueChanged:= TCollectionChangedEventImpl<V>.Create;
end;

constructor TRedBlackTree<K, V>.Create(Species: TTreeSpecies);
begin
  Create(TComparer<K>.Default);
end;

constructor TRedBlackTree<K, V>.Create(const Comparer: TComparison<K>; Species: TTreeSpecies);
begin
  Create(IComparer<K>(PPointer(@Comparer)^));
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
  Pair:= TPair.Create(Key, Value);
  inherited Add(Pair);
end;

procedure TRedBlackTree<K, V>.AddOrSetValue(const Key: K; const Value: V);
var
  Pair: TPair;
  Node: PNode;
begin
  Pair:= TPair.Create(Key, Value);
  Node:= FindNode(Root, Pair);
  if Node = nil then inherited Add(Pair)
  else Node.Key:= Pair;
end;

function TRedBlackTree<K, V>.AsReadOnlyDictionary: IReadOnlyDictionary<K, V>;
begin
  Result:= Self as IReadOnlyDictionary<K, V>;
end;

function TRedBlackTree<K, V>.ContainsKey(const Key: K): Boolean;
var
  Pair: TPair;
begin
  Pair:= TPair.Create(Key, default (V));
  Result:= Assigned(FindNode(Root, Pair));
end;

function TRedBlackTree<K, V>.ContainsValue(const Value: V): Boolean;
var
  DummyPair: TPair;
begin
  Result:= Any(
    function(const Pair: TPair): boolean
    begin
      Result:= fValueComparer.Compare(Pair.Value, Value) = 0;
    end);
end;

function TRedBlackTree<K, V>.Contains(const Key: K; const Value: V): Boolean;
begin
  Result := Assigned(FindNode(Root, TPair.Create(Key, Value)));
end;

function TRedBlackTree<K, V>.Extract(const Key: K): V;
begin
  Result := ExtractPair(Key).Value;
end;

function TRedBlackTree<K, V>.ExtractPair(const Key: K): TPair<K, V>;
var
  Pair: TPair;
  Node: PNode;
begin
  Pair:= TPair.Create(Key, default (V));
  Node:= FindNode(Root, Pair);
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
  Node:= FindNode(Root, Pair(Key, Default(V)));
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

function TRedBlackTree<K, V>.Remove(const Key: K): Boolean;
var
  Pair: TPair;
begin
  Pair.Create(Key, default (V));
  Result:= inherited Remove(Pair);
end;

function TRedBlackTree<K, V>.Remove(const Key: K; const Value: V): Boolean;
var
  Pair: TPair;
begin
  Pair.Create(Key, Value);
  Result:= inherited Remove(Pair);
end;

function TRedBlackTree<K, V>.Extract(const Key: K; const Value: V): TPair<K,V>;
begin
  Result := TPair.Create(Key, Value);
  inherited Remove(Result);
end;

procedure TRedBlackTree<K, V>.SetItem(const Key: K; const Value: V);
var
  Pair: TPair;
  Node: PNode;
begin
  Pair:= TPair.Create(Key, Value);
  Node:= FindNode(Root, Pair);
  if Assigned(Node) then Node.Key:= Pair
  else raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TRedBlackTree<K, V>.TryGetValue(const Key: K; out Value: V): Boolean;
var
  Pair: TPair;
  Node: PNode;
begin
  Pair:= TPair.Create(Key, default (V));
  Node:= FindNode(Root, Pair);
  Result:= Assigned(Node);
  if Result then Value:= Node.Key.Value;
  TObject.NewInstance
end;

function TRedBlackTree<K, V>.GetValueOrDefault(const Key: K): V;
begin
  if not TryGetValue(Key, Result) then
    Result := default (V);
end;

function TRedBlackTree<K, V>.GetValueOrDefault(const Key: K; const defaultValue: V): V;
begin
  if not TryGetValue(Key, Result) then
    Result := defaultValue;
end;

function TRedBlackTree<K, V>.Pair(const Key: K; const Value: V): TPair;
begin
  Result:= TPair.Create(Key, Value);
end;

procedure TRedBlackTree<K, V>.Traverse(order: TraverseOrder; const Action:
  TTraverseAction);
var
  ActionWrapper: TNodePredicate;
begin
  ActionWrapper :=
    function (const Node: PNode): boolean
    var
      Abort: boolean;
    begin
      Abort := false;
      Action(Node.Key.Key, Node.Key.Value, Abort);
      Result := Abort;
    end;

  case order of
    TraverseOrder.InOrder: TraverseInOrder(Root, ActionWrapper);
    TraverseOrder.PreOrder: TraversePreOrder(Root, ActionWrapper);
    TraverseOrder.PostOrder: TraversePostOrder(Root, ActionWrapper);
    TraverseOrder.ReverseOrder: TraverseReverseOrder(Root, ActionWrapper);
    else raise Exception.Create('Unsupported traverse order');
  end;
end;

{ TRedBlackTree<K, V>.TTreeComparer }

constructor TRedBlackTree<K, V>.TTreeComparer.Create(const Comparer: IComparer<K>);
begin
  inherited Create;
  fComparer:= Comparer;
end;

function TRedBlackTree<K, V>.TTreeComparer.Compare(const a, b: TPair<K, V>): Integer;
begin
  Result:= fComparer.Compare(a.Key, b.Key);
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


//Todo: implement addition code.
function TNAryTree<K, V>.Add(const Key: TPair<K,V>): boolean;
begin
  fRoot:= InternalInsert(fRoot, Key);
end;

procedure TNAryTree<K, V>.Add(const Key: K; const Value: V);
begin
  fRoot:= InternalInsert(fRoot, Key, Value);
end;


function TNAryTree<K, V>.Get(Key: K): TPair<K, V>;
var
  Node: PNode;
begin
  Node:= FindNode(Root, Pair(Key, Default(V)));
  Result:= Node.Key;
end;

function TNAryTree<K, V>.GetDirectChildern(const ParentKey: K): TArray<TPair<K, V>>;
var
  Node, Parent: PNode;
  Count, Index: integer;
begin
  Parent:= FindNode(Root, Pair(ParentKey, Default(V)));
  count:= 0;
  Node:= Parent.Left;
  while Node <> nil do begin
    Inc(count);
    Node:= Node.Right;
  end; {while}
  SetLength(Result, count);
  Index:= 0;
  Node:= Parent.Left;
  while Node <> nil do begin
    Result[Index]:= Node.Key;
    Inc(Index);
    Node:= Node.Right;
  end; {while}
end;

function TNAryTree<K,V>.InternalInsert(Head: PNode; const Key: K; const Value: V): PNode;
begin
  if Head = nil then begin
    Exit(NewNode(Pair(Key,Value), nil));
  end;

  if Equal(Key, Head.Key.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
  else if (Less(Key, Head.Key.Key)) then begin
    Head.Left:= InternalInsert(Head.Left, Key, Value);
  end else begin
    Head.Right:= InternalInsert(Head.Right, Key, Value);
  end;

  Result:= Head;
end;


{TTree<K>}

procedure TTree<K>.ExceptWith(const other: IEnumerable<K>);
var
  Element: K;
begin
  if (other = nil) then ArgumentNilError('ExceptWith');
  for Element in other do begin
    Self.Remove(Element);
  end;
end;

procedure TTree<K>.IntersectWith(const other: IEnumerable<K>);
var
  Element: K;
begin
  if (other = nil) then ArgumentNilError('IntersectWith');
  for Element in Self do begin
    if not(Other.Contains(Element)) then Self.Remove(Element);
  end;
end;

procedure TTree<K>.UnionWith(const other: IEnumerable<K>);
var
  Element: K;
begin
  if (other = nil) then ArgumentNilError('UnionWith');
  for Element in other do begin
    Self.Add(Element);
  end;
end;

function TTree<K>.IsSubsetOf(const other: IEnumerable<K>): Boolean;
var
  Element: K;
begin
  if (other = nil) then ArgumentNilError('IsSubsetOf');
  for Element in Self do begin
    if not(Other.Contains(Element)) then Exit(false);
  end;
  Result:= true;
end;

function TTree<K>.IsSupersetOf(const other: IEnumerable<K>): Boolean;
var
  Element: K;
begin
  if (other = nil) then ArgumentNilError('IsSupersetOf');
  for Element in Other do begin
    if not(Self.Contains(Element)) then Exit(false);
  end;
  Result:= true;
end;

function TTree<K>.SetEquals(const other: IEnumerable<K>): Boolean;
begin
  if (other = nil) then ArgumentNilError('SetEquals');
  Result:= IsSubsetOf(Other) and IsSupersetOf(Other);
end;

function TTree<K>.Overlaps(const other: IEnumerable<K>): Boolean;
var
  Element: K;
begin
  if (other = nil) then ArgumentNilError('Overlaps');
  for Element in Other do begin
    if Self.Contains(Element) then Exit(true);
  end;
  Result:= false;
end;

procedure TBinaryTreeBase<T>.ExpandStorage(OldCount: NativeUInt);
begin
  SetLength(fStorage, (OldCount+10 * 3) div 2);
end;

function TBinaryTreeBase<T>.NewNode(const Key: T; Parent: PNode): PNode;
begin
  if Length(fStorage) <= fCount then ExpandStorage(fCount);
  Result:= @fStorage[fCount];
  Result.fLeft:= nil;
  Result.fRight:= nil;
  Result.SetParent(Parent);
  Result.fKey:= Key;
  Result.fIsBlack:= Color.Red;
  Inc(fCount);
end;

procedure TBinaryTreeBase<T>.Traverse(order: TraverseOrder; const Action:
  TTraverseAction);
var
  ActionWrapper: TNodePredicate;
begin
  ActionWrapper :=
    function (const Node: PNode): boolean
    var
      Abort: boolean;
    begin
      Abort := false;
      Action(Node.Key, Abort);
      Result := Abort;
    end;

  case order of
    TraverseOrder.PreOrder:  TraversePreOrder(Root, ActionWrapper);
    TraverseOrder.InOrder:   TraverseInOrder(Root, ActionWrapper);
    TraverseOrder.PostOrder: TraversePostOrder(Root, ActionWrapper);
    else raise Exception.Create('Unsupported traverse order');
  end;
end;

procedure TTree<K>.ArgumentNilError(const MethodName: string);
begin
  raise EArgumentNullException.Create(Self.ClassName + MethodName +
    ' does not accept a nil argument');
end;

procedure TTree<K>.AddInternal(const Item: K);
begin
  if not(Add(Item)) then raise Exception.Create('Cannot add a duplicate item in a tree');
end;

{ TBinaryTreeBase<K, V> }

function TBinaryTreeBase<K, V>.Equal(const a, b: K): boolean;
begin
  Result:= KeyComparer.Compare(a, b) = 0;
end;

class function TBinaryTreeBase<K, V>.GetKeyComparer: IComparer<K>;
begin
  if not(Assigned(fKeyComparer)) then fKeyComparer:= TComparer<K>.Default;
    Result:= fKeyComparer;
end;

function TBinaryTreeBase<K, V>.Less(const a, b: K): boolean;
begin
  Result:= KeyComparer.Compare(a, b) < 0;
end;

function TBinaryTreeBase<K, V>.Pair(const Key: K; const Value: V): TPair;
begin
  Result := TPair.Create(Key, Value);
end;

procedure TBinaryTreeBase<K, V>.Traverse(order: TraverseOrder;
  const Action: TTraverseAction);
var
  ActionWrapper: TNodePredicate;
begin
  ActionWrapper :=
    function (const Node: PNode): boolean
    var
      Abort: boolean;
    begin
      Abort := false;
      Action(Node.Key.Key, Node.Key.Value, Abort);
      Result := Abort;
    end;

  case order of
    TraverseOrder.PreOrder:  TraversePreOrder(Root, ActionWrapper);
    TraverseOrder.InOrder:   TraverseInOrder(Root, ActionWrapper);
    TraverseOrder.PostOrder: TraversePostOrder(Root, ActionWrapper);
    else raise Exception.Create('Unsupported traverse order');
  end;
end;

{ Tree<T> }

class function Tree<T>.RedBlackTree(const Comparer: IComparer<T>; Species: TTreeSpecies): ITree<T>;
begin
  Result:= TRedBlackTree<T>.Create(Comparer, Species);
end;

class function Tree<T>.RedBlackTree(Species: TTreeSpecies): ITree<T>;
begin
  Result:= TRedBlackTree<T>.Create(Species);
end;

class function Tree<T>.RedBlackTree(const Comparer: TComparison<T>; Species: TTreeSpecies): ITree<T>;
begin
  Result:= TRedBlackTree<T>.Create(Comparer, Species);
end;

class function Tree<T>.RedBlackTree(const Collection: IEnumerable<T>; Species: TTreeSpecies): ITree<T>;
begin
  Result:= TRedBlackTree<T>.Create(Collection, Species);
end;

class function Tree<T>.RedBlackTree(const Values: array of T; Species: TTreeSpecies): ITree<T>;
begin
  Result:= TRedBlackTree<T>.Create(Values, Species);
end;

{ Tree<K, V> }

class function Tree<K, V>.RedBlackTree(const Comparer: IComparer<K>; Species: TTreeSpecies): ITree<K, V>;
begin
  Result:= TRedBlackTree<K,V>.Create(Comparer, Species);
end;

class function Tree<K, V>.RedBlackTree(Species: TTreeSpecies): ITree<K, V>;
begin
  Result:= TRedBlackTree<K,V>.Create(Species);
end;

class function Tree<K, V>.RedBlackTree(const Collection: IEnumerable<TPair<K, V>>; Species: TTreeSpecies): ITree<K, V>;
begin
  Result:= TRedBlackTree<K,V>.Create(Collection, Species);
end;


class function Tree<K, V>.RedBlackTree(const Values: array of TPair<K, V>; Species: TTreeSpecies): ITree<K, V>;
begin
  Result:= TRedBlackTree<K,V>.Create(Values, Species);
end;


class function Tree<K, V>.RedBlackTree(const Comparer: TComparison<K>; Species: TTreeSpecies): ITree<K, V>;
begin
  Result:= TRedBlackTree<K,V>.Create(Comparer, Species);
end;



end.
