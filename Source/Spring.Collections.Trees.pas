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

  /// <summary>
  ///   Abstract parent for tree, defines the tree as a set of keys
  /// </summary>
  TTree<K> = class abstract(TCollectionBase<K>, ISet<K>)
  private
    procedure ArgumentNilError(const MethodName: string); virtual;
  protected
    procedure AddInternal(const Item: K); override;
  public

    ///	<summary>
    ///	  Adds an element to the current set and returns a value to indicate if
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
    ///	  Removes all elements in the specified collection from the current
    ///	  <see cref="Tree&lt;T&gt;" /> object.
    ///	</summary>
    ///	<param name="other">
    ///	  The collection of items to remove from the
    ///	  <see cref="THashSet&lt;T&gt;" /> object.
    ///	</param>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    procedure ExceptWith(const other: IEnumerable<K>); virtual;

    ///	<summary>
    ///	  Modifies the current <see cref="Tree&lt;T&gt;" /> object to
    ///	  contain only elements that are present in that object and in the
    ///	  specified collection.
    ///	</summary>
    ///	<param name="other">
    ///	  The collection to compare to the current
    ///	  <see cref="Tree&lt;T&gt;" /> object.
    ///	</param>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    procedure IntersectWith(const other: IEnumerable<K>); virtual;

    ///	<summary>
    ///	  Modifies the current <see cref="Tree&lt;T&gt;" /> object to
    ///	  contain all elements that are present in itself, the specified
    ///	  collection, or both.
    ///	</summary>
    ///	<param name="other">
    ///	  The collection to compare to the current
    ///	  <see cref="Tree&lt;T&gt;" /> object.
    ///	</param>
    ///	<exception cref="EArgumentNullException">
    ///	  <i>other</i> is <b>nil</b>.
    ///	</exception>
    procedure UnionWith(const other: IEnumerable<K>); virtual;

    ///	<summary>
    ///	  Determines whether a <see cref="Tree&lt;T&gt;" /> object is a
    ///	  subset of the specified collection.
    ///	</summary>
    ///	<param name="other">
    ///	  The collection to compare to the current
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
    ///	  superset of the specified collection.
    ///	</summary>
    ///	<param name="other">
    ///	  The collection to compare to the current
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
    ///	  specified collection contain the same elements.
    ///	</summary>
    ///	<param name="other">
    ///	  The collection to compare to the current
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
    ///	  object and a specified collection share common elements.
    ///	</summary>
    ///	<param name="other">
    ///	  The collection to compare to the current
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

  TBinaryTreeBase<K> = class(TTree<K>)
  private type
    // Nodes in the tree, because the parent is not stored, these are dump nodes.
    TNode = class
    protected
      fLeft: TNode; // Left nodes hold lower values
      fRight: TNode; // Right nodes hold higher values
      fKey: K; // The payload, use a TPair<X,Y> to store a Key/Value pair.
      fIsBlack: boolean; // Red is the default.

      /// <summary>
      /// Static method to get the color. Always use this method, never read the
      /// field directly, because the Node might be nil.
      /// </summary>
      /// <returns>false if self is nil.</returns>
      function IsRed: boolean; inline;
    public
      constructor Create(const Key: K);
    public
      property Left: TNode read fLeft write fLeft;
      property Right: TNode read fRight write fRight;
      property Key: K read fKey write fKey;
      property NodeColor: boolean read fIsBlack write fIsBlack;
    end;
  private type
    /// <summary>
    /// Enumerator for the trees, works on Nodes, not values.
    /// Depends on an altered TIterator with a virtual GetCurrent Method.
    /// </summary>
    TTreeEnumerator = class(TIterator<K>)
    private
      fHead: TNode;
      fCurrentNode: TNode;
      fStack: TMiniStack<TNode>;
      // Enumerator can be reversed.
      fDirection: TDirection;
    protected
      // function GetCurrentNonGeneric: V; override;
      function Clone: TIterator<K>; override;
    public
      constructor Create(const Head: TNode; Direction: TDirection); overload;
      constructor Create(const Head: TNode); overload;
      procedure Reset; override;
      function MoveNext: Boolean; override;
      // function GetEnumerator: IEnumerator<K>; override;
      destructor Destroy; override;
      // The parent TIterator must be altered to have a virtual GetCurrent method.
      function GetCurrent: K;
      property Current: K read GetCurrent;
      property CurrentNode: TNode read fCurrentNode;
    end;
  private type
    TNodePredicate = TPredicate<TNode>;
  private
    fRoot: TNode;
    fCount: Integer;
    procedure TraversePreOrder(const Node: TNode; Action: TNodePredicate);
    procedure TraversePostOrder(const Node: TNode; Action: TNodePredicate);
    procedure TraverseInOrder(const Node: TNode; Action: TNodePredicate);
    /// <summary>
    /// Destroys a single Node and updates the count.
    /// Fixes the root if nessecary
    /// </summary>
    /// <remarks>
    /// Only deletes a single node; does not delete childern and does not fixup the tree.
    /// </remarks>
    procedure FreeSingleNode(Node: TNode); inline;
    /// <summary>
    /// Convienance method to see if two keys are equal.
    /// </summary>
    function Equal(const a, b: K): boolean; inline;
    /// <summary>
    /// Convienance method to see if (a < b).
    /// </summary>
    function Less(const a, b: K): Boolean; inline;
    /// <summary>
    /// Finds the node containing the key in the given subtree.
    /// </summary>
    /// <param name="Head">The head of the subtree</param>
    /// <param name="Key">The key to look for</param>
    /// <returns>nil if the key is not found in the subtree; the containing node otherwise</returns>
    function FindNode(const Head: TNode; const Key: K): TNode;

    function NewNode(const Key: K): TNode; inline;

    function InternalInsert(Head: TNode; const Key: K): TNode; virtual;

    property Root: TNode read fRoot;
  public
    function Add(const Item: K): boolean; override;
    function Contains(const Key: K): boolean; override;
    procedure Clear; reintroduce;
    property Count: integer read fCount;
  end;

  TBinaryTreeBase<K,V> = class(TBinaryTreeBase<TPair<K, V>>)
  private type
    TNode = TBinaryTreeBase<TPair<K, V>>.TNode;
  private
    class var fKeyComparer: IComparer<K>;
    class function GetKeyComparer: IComparer<K>; static;
  protected
    function Equal(const a, b: K): boolean; overload; virtual;
    function Less(const a, b: K): boolean; overload; virtual;
    function Pair(Key:K; Value: V): TPair<K,V>; inline;
    class property KeyComparer: IComparer<K> read GetKeyComparer;
  end;

  TNAryTree<K, V> = class(TBinaryTreeBase<K, V>)
  private type
    TNode = TBinaryTreeBase<TPair<K,V>>.TNode;
  private
    /// <summary>
    /// Inserts a node into the subtree anchored at Start.
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The key to insert into the subtree</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be assigned in place if the old start node
    /// in order to retain the RedBlackness of the tree</returns>
    /// <remarks>
    /// Does *not* return an exception if a duplicate key is inserted, but simply returns
    /// the Start node as its result; doing nothing else.
    /// Examine the Count property to see if a node was inserted.
    ///
    /// Can lead to duplicate keys in the tree if not called with the Root as the Start</remarks>
    function InternalInsert(Head: TNode; const Key: K; const Value: V): TNode; overload; virtual;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Add(const Key: TPair<K,V>): boolean; overload; override;
    procedure Add(const Key: K; const Value: V); overload; virtual;
    function Get(Key: K): TPair<K,V>;
    function GetDirectChildern(const ParentKey: K): TArray<TPair<K,V>>;
  end;

  /// <summary>
  /// Left Leaning red black tree, mainly useful for encapsulating a Set.
  /// Does not allow duplicate items.
  /// </summary>
  TRedBlackTree<K> = class(TBinaryTreeBase<K>)
  private type
    TNode = TBinaryTreeBase<K>.TNode;
    TNodePredicate = TBinaryTreeBase<K>.TNodePredicate;
  private
    // A RedBlack tree emulates a binary 234 tree.
    // This tree can run in 234 and 23 mode.
    // For some problem domains the 23 runs faster than the 234
    // For other problems the 234 is faster.
    fSpecies: TTreeSpecies;
{$IF defined(debug)}
  private // Test methods
    function Is234(Node: TNode): boolean; overload; virtual;
    function IsBST(Node: TNode; MinKey, MaxKey: K): boolean; overload; virtual;
    function IsBalanced(Node: TNode; Black: integer): boolean; overload; virtual;
{$IFEND}
  private
    /// <summary>
    /// Deletes the rightmost child of Start node, retaining the RedBlack property
    /// </summary>
    function DeleteMax(Head: TNode): TNode; overload;
    /// <summary>
    /// Deletes the leftmost child of Start node, retaining the RedBlack property
    /// </summary>
    function DeleteMin(Head: TNode): TNode; overload;
    /// <summary>
    /// Deletes the node with the given Key inside the subtree under Start
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The id of the node to be deleted</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be assigned in place if the old start node
    /// in order to retain the RedBlackness of the tree</returns>
    /// <remarks>
    /// Does *not* return an exception if the key is not found, but simply returns
    /// the Start node as its result.
    /// Examine the Count property to see if a node was deleted.
    /// </remarks>
    function DeleteNode(Head: TNode; Key: K): TNode; overload;

    /// <summary>
    /// Inserts a node into the subtree anchored at Start.
    /// </summary>
    /// <param name="Start">The 'root' of the subtree</param>
    /// <param name="Key">The key to insert into the subtree</param>
    /// <returns>The new root of the subtree.
    /// This new root needs to be assigned in place if the old start node
    /// in order to retain the RedBlackness of the tree</returns>
    /// <remarks>
    /// Does *not* return an exception if a duplicate key is inserted, but simply returns
    /// the Start node as its result; doing nothing else.
    /// Examine the Count property to see if a node was inserted.
    ///
    /// Can lead to duplicate keys in the tree if not called with the Root as the Start</remarks>
    function InternalInsert(Head: TNode; const Key: K): TNode; override;

    /// <summary>
    /// Corrects the RedBlackness of a node and its immediate childern after insertion or deletion.
    /// </summary>
    /// <param name="Node"></param>
    /// <returns></returns>
    function FixUp(Node: TNode): TNode;
    /// <summary>
    /// Inverts the color of a 3-node and its immediate childern.
    /// </summary>
    /// <param name="Head"></param>
    procedure ColorFlip(const Node: TNode);
    /// <summary>
    /// Assuming that node is red and both node.left and node.left.left
    /// are black, make node.left or one of its children red.
    /// </summary>
    function MoveRedLeft(Node: TNode): TNode;
    /// <summary>
    /// Assuming that node is red and both node.right and node.right.left
    /// are black, make node.right or one of its children red.
    /// </summary>
    function MoveRedRight(Node: TNode): TNode;
    /// <summary>
    /// Make a right-leaning 3-node lean to the left.
    /// </summary>
    function RotateLeft(Node: TNode): TNode;
    /// <summary>
    /// Make a left-leaning 3-node lean to the right.
    /// </summary>
    function RotateRight(Node: TNode): TNode;

    /// <summary>
    /// Get the leftmost (smallest node) in the given subtree.
    /// </summary>
    /// <param name="Head">The head of the subtree, must not be nil</param>
    /// <returns>The leftmost (smallest) node in the subtree</returns>
    function MinNode(const Head: TNode): TNode;
    /// <summary>
    /// Get the rightmost (largest node) in the given subtree.
    /// </summary>
    /// <param name="Head">The head of the subtree, must not be nil</param>
    /// <returns>The rightmost (largest) node in the subtree</returns>
    function MaxNode(const Head: TNode): TNode;
  protected
  public
    constructor Create(Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const comparer: IComparer<K>; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const comparer: TComparison<K>; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const values: array of K; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const collection: IEnumerable<K>; Species: TTreeSpecies = TD234); reintroduce; overload;
    destructor Destroy; override;
    function GetEnumerator: IEnumerator<K>; override;
    function Reversed: IEnumerable<K>; override;
{$IF defined(Debug)}
  public // Test Methods
    function Is234: boolean; overload;
    function IsBST: boolean; overload;
    function IsBalanced: boolean; overload;
    function Check: boolean;
{$IFEND}
  public
    function Last: K; overload; override;
    function Last(const Predicate: TPredicate<K>): K; overload;
    function LastOrDefault(const DefaultValue: K): K; overload;
    function LastOrDefault(const Predicate: TPredicate<K>; const DefaultValue: K): K; overload;
    function First: K; override;
    function Extract(const Key: K): K; override;
    function Remove(const Key: K): boolean; override;
    function Add(const Key: K): boolean; override;
    function Get(const Key: K): K; overload;
  end;

  TRedBlackTree<K, V> = class(TRedBlackTree<TPair<K, V>>, IDictionary<K, V>)
  private type
    TPair = TPair<K, V>;
  private type
    TTreeComparer = class(TInterfacedObject, IComparer<TPair>)
    private
      fComparer: IComparer<K>;
    public
      constructor Create(const comparer: IComparer<K>);
      function Compare(const a, b: TPair): Integer;
    end;
  private
    fValueComparer: IComparer<V>;
    fKeyComparer: IComparer<TPair>;
    fOnKeyChanged: ICollectionChangedEvent<K>;
    fOnValueChanged: ICollectionChangedEvent<V>;
  protected
{$REGION 'Property Accessors'}
    function GetItem(const key: K): V;
    function GetKeys: IReadOnlyCollection<K>;
    function GetKeyType: PTypeInfo;
    function GetOnKeyChanged: ICollectionChangedEvent<K>;
    function GetOnValueChanged: ICollectionChangedEvent<V>;
    function GetValues: IReadOnlyCollection<V>;
    function GetValueType: PTypeInfo;
    procedure SetItem(const key: K; const value: V);
    function GetComparer: IComparer<TPair>;
    property Comparer: IComparer<TPair> read GetComparer;
    function Pair(const Key:K; const Value: V): TPair;
{$ENDREGION}
  public
    constructor Create(Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const comparer: IComparer<K>; Species: TTreeSpecies = TD234); reintroduce; overload;
    constructor Create(const comparer: TComparison<K>; Species: TTreeSpecies = TD234); reintroduce; overload;
  public
    /// <summary>
    /// Adds an element with the provided key and value to the
    /// IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <param name="key">
    /// The item to use as the key of the element to add.
    /// </param>
    /// <param name="value">
    /// The item to use as the value of the element to add.
    /// </param>
    procedure Add(const key: K; const value: V); reintroduce;
    procedure AddOrSetValue(const key: K; const value: V);

    /// <summary>
    /// Determines whether the IDictionary&lt;K, V&gt; contains an
    /// element with the specified key.
    /// </summary>
    /// <param name="key">
    /// The key to locate in the IDictionary&lt;K, V&gt;.
    /// </param>
    /// <returns>
    /// <b>True</b> if the IDictionary&lt;K, V&gt; contains an
    /// element with the key; otherwise, <b>False</b>.
    /// </returns>
    function ContainsKey(const key: K): Boolean;
    /// <summary>
    /// Determines whether the IDictionary&lt;K, V&gt; contains an
    /// element with the specified value.
    /// </summary>
    /// <param name="value">
    /// The value to locate in the IDictionary&lt;K, V&gt;.
    /// </param>
    function ContainsValue(const value: V): Boolean;

    /// <summary>
    ///   Determines whether the IMap&lt;TKey,TValue&gt; contains the specified
    ///   key/value pair.
    /// </summary>
    /// <param name="key">
    ///   The key of the pair to locate in the IMap&lt;TKey, TValue&gt;.
    /// </param>
    /// <param name="value">
    ///   The value of the pair to locate in the IMap&lt;TKey, TValue&gt;.
    /// </param>
    /// <returns>
    ///   <b>True</b> if the IMap&lt;TKey, TValue&gt; contains a pair with the
    ///   specified key and value; otherwise <b>False</b>.
    /// </returns>
    function Contains(const key: K; const value: V): Boolean;

    /// <summary>
    /// Removes the element with the specified key from the
    /// IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <param name="key">
    /// The key of the element to remove.
    /// </param>
    /// <returns>
    /// <b>True</b> if the element is successfully removed; otherwise,
    /// <b>False</b>. This method also returns <b>False</b> if <i>key</i> was
    /// not found in the original IDictionary&lt;K, V&gt;.
    /// </returns>
    function Remove(const key: K): Boolean; overload;
    function Remove(const key: K; const value: V): Boolean; overload;

    function Extract(const key: K; const value: V): TPair; overload;

    /// <summary>
    ///   Removes the value for a specified key without triggering lifetime
    ///   management for objects.
    /// </summary>
    /// <param name="key">
    ///   The key whose value to remove.
    /// </param>
    /// <returns>
    ///   The removed value for the specified key if it existed; <b>default</b>
    ///   otherwise.
    /// </returns>
    function Extract(const key: K): V; overload;

    /// <summary>
    ///   Removes the value for a specified key without triggering lifetime
    ///   management for objects.
    /// </summary>
    /// <param name="key">
    ///   The key whose value to remove.
    /// </param>
    /// <returns>
    ///   The removed pair for the specified key if it existed; <b>default</b>
    ///   otherwise.
    /// </returns>
    function ExtractPair(const key: K): TPair;

    /// <summary>
    /// Gets the value associated with the specified key.
    /// </summary>
    /// <param name="key">
    /// The key whose value to get.
    /// </param>
    /// <param name="value">
    /// When this method returns, the value associated with the specified
    /// key, if the key is found; otherwise, the default value for the type
    /// of the value parameter. This parameter is passed uninitialized.
    /// </param>
    /// <returns>
    /// <b>True</b> if the object that implements IDictionary&lt;K,
    /// V&gt; contains an element with the specified key; otherwise,
    /// <b>False</b>.
    /// </returns>
    function TryGetValue(const key: K; out value: V): Boolean;

    /// <summary>
    ///   Gets the value for a given key if a matching key exists in the
    ///   dictionary; returns the default value otherwise.
    /// </summary>
    function GetValueOrDefault(const key: K): V; overload;

    /// <summary>
    ///   Gets the value for a given key if a matching key exists in the
    ///   dictionary; returns the given default value otherwise.
    /// </summary>
    function GetValueOrDefault(const key: K; const defaultValue: V): V; overload;

    function AsReadOnlyDictionary: IReadOnlyDictionary<K, V>;

    /// <summary>
    /// Gets or sets the element with the specified key.
    /// </summary>
    /// <param name="key">
    /// The key of the element to get or set.
    /// </param>
    /// <value>
    /// The element with the specified key.
    /// </value>
    property Items[const key: K]: V read GetItem write SetItem; default;

    /// <summary>
    /// Gets an <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the
    /// keys of the IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <value>
    /// An <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the keys of
    /// the object that implements IDictionary&lt;K, V&gt;.
    /// </value>
    property Keys: IReadOnlyCollection<K> read GetKeys;

    /// <summary>
    /// Gets an <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the
    /// values in the IDictionary&lt;K, V&gt;.
    /// </summary>
    /// <value>
    /// An <see cref="IReadOnlyCollection&lt;T&gt;" /> containing the values
    /// in the object that implements IDictionary&lt;K, V&gt;.
    /// </value>
    property Values: IReadOnlyCollection<V> read GetValues;

    property OnKeyChanged: ICollectionChangedEvent<K> read GetOnKeyChanged;
    property OnValueChanged: ICollectionChangedEvent<V> read GetOnValueChanged;
    property KeyType: PTypeInfo read GetKeyType;
    property ValueType: PTypeInfo read GetValueType;
  end;



resourcestring
  SSetDuplicateInsert = 'Cannot insert a duplicate item in a set';

implementation

uses
  Spring.ResourceStrings,
  Spring.Collections.Lists,
  Spring.Collections.Events;


constructor TRedBlackTree<K>.Create(Species: TTreeSpecies);
begin
  inherited Create;
  fSpecies:= Species;
end;

constructor TRedBlackTree<K>.Create(const comparer: TComparison<K>;
  Species: TTreeSpecies);
begin
  inherited Create(comparer);
  fSpecies := Species;
end;

constructor TRedBlackTree<K>.Create(const comparer: IComparer<K>; Species: TTreeSpecies);
begin
  inherited Create(comparer);
  fSpecies := Species;
end;

constructor TRedBlackTree<K>.Create(const collection: IEnumerable<K>;
  Species: TTreeSpecies);
begin
  Create(Species);
  AddRange(collection);
end;

constructor TRedBlackTree<K>.Create(const values: array of K; Species: TTreeSpecies);
begin
  Create(Species);
  AddRange(values);
end;

constructor TBinaryTreeBase<K>.TNode.Create(const Key: K);
begin
  inherited Create;
  fKey:= Key;
  fIsBlack:= Color.Red;
end;

function TBinaryTreeBase<K>.Contains(const Key: K): boolean;
begin
  Result:= Assigned(FindNode(Root, Key));
end;

function TRedBlackTree<K>.Get(const Key: K): K;
var
  Node: TNode;
begin
  Node:= FindNode(Root, Key);
  if Assigned(Node) then Result:= Node.Key
  else raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TBinaryTreeBase<K>.Add(const Item: K): boolean;
var
  OldCount: integer;
begin
  OldCount:= Count;
  fRoot:= Self.InternalInsert(fRoot, Item);
  Result:= (Count <> OldCount);
end;

function TRedBlackTree<K>.GetEnumerator: IEnumerator<K>;
begin
  Result:= TTreeEnumerator.Create(Root);
end;

function TBinaryTreeBase<K>.FindNode(const Head: TNode; const Key: K): TNode;
begin
  Result:= Head;
  while Result <> nil do begin
    if (Equal(Key, Result.Key)) then Exit;
    if (Less(Key, Result.Key)) then Result:= Result.Left
    else Result:= Result.Right;
  end;
end;

function TBinaryTreeBase<K>.InternalInsert(Head: TNode; const Key: K): TNode;
begin
  if Head = nil then begin
    Exit(NewNode(Key));
  end;

  if Equal(Key, Head.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
  else if (Less(Key, Head.Key)) then Head.Left:= InternalInsert(Head.Left, Key)
  else Head.Right:= InternalInsert(Head.Right, Key);

  Result:= Head;
end;


function TRedBlackTree<K>.First: K;
begin
  if (Root = nil) then raise EInvalidOperationException.CreateRes(@SSequenceContainsNoElements);
  Result:= MinNode(Root).Key;
end;

function TRedBlackTree<K>.MinNode(const Head: TNode): TNode;
begin
  Assert(Head <> nil);
  Result:= Head;
  while Result.Left <> nil do Result:= Result.Left;
end;

function TRedBlackTree<K>.MaxNode(const Head: TNode): TNode;
begin
  Assert(Head <> nil);
  Result:= Head;
  while Result.Right <> nil do Result:= Result.Right;
end;

function TBinaryTreeBase<K>.TNode.IsRed: boolean;
begin
  if Self = nil then Exit(false);
  Result:= (NodeColor = Color.Red);
end;

function TRedBlackTree<K>.Add(const Key: K): boolean;
var
  OldCount: integer;
begin
  OldCount:= Count;
  fRoot:= InternalInsert(fRoot, Key);
  // if fRoot.IsRed then Inc(HeightBlack);
  fRoot.NodeColor:= Color.Black;
  Result:= (Count <> OldCount);
end;

function TRedBlackTree<K>.InternalInsert(Head: TNode; const Key: K): TNode;
begin
  if Head = nil then begin
    Exit(NewNode(Key));
  end;
  if (fSpecies = TD234) then begin
    if (Head.Left.IsRed) and (Head.Right.IsRed) then ColorFlip(Head);
  end;

  if Equal(Key, Head.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
  else if (Less(Key, Head.Key)) then Head.Left:= InternalInsert(Head.Left, Key)
  else Head.Right:= InternalInsert(Head.Right, Key);

  // if (fSpecies = BST) then exit(Head);

  if Head.Right.IsRed then Head:= RotateLeft(Head);

  if Head.Left.IsRed and Head.Left.Left.IsRed then Head:= RotateRight(Head);

  if (fSpecies = BU23) then begin
    if (Head.Left.IsRed and Head.Right.IsRed) then ColorFlip(Head);
  end;

  Result:= Head;
end;

function TRedBlackTree<K>.DeleteMin(Head: TNode): TNode;
begin
  if (Head.Left = nil) then begin
    FreeSingleNode(Head);
    Exit(nil);
  end;
  if not(Head.Left.IsRed) and not(Head.Left.Left.IsRed) then Head:= MoveRedLeft(Head);
  Head.Left:= DeleteMin(Head.Left);
  Result:= FixUp(Head);
end;

destructor TRedBlackTree<K>.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TRedBlackTree<K>.DeleteMax(Head: TNode): TNode;
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

function TRedBlackTree<K>.Remove(const Key: K): boolean;
var
  OldCount: integer;
begin
  OldCount:= Count;
  fRoot:= DeleteNode(Root, Key);
  if Root <> nil then Root.NodeColor:= Color.Black;
  Result:= (Count <> OldCount);
end;

function TRedBlackTree<K>.Reversed: IEnumerable<K>;
begin
  Result:= TTreeEnumerator.Create(Root, FromEnd);
end;

function TRedBlackTree<K>.DeleteNode(Head: TNode; Key: K): TNode;
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

function TRedBlackTree<K>.Last: K;
begin
  if (Root = nil) then raise EInvalidOperationException.CreateRes(@SSequenceContainsNoElements);
  Result:= MaxNode(Root).Key;
end;

function TRedBlackTree<K>.Last(const Predicate: TPredicate<K>): K;
var
  Item: K;
begin
  for Item in Reversed do begin
    if Predicate(Item) then Exit(Item);
  end;
  raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TRedBlackTree<K>.LastOrDefault(const DefaultValue: K): K;
begin
  if (Root = nil) then Exit(DefaultValue);
  Result:= MaxNode(Root).Key;
end;

function TRedBlackTree<K>.LastOrDefault(const Predicate: TPredicate<K>; const DefaultValue: K): K;
var
  Item: K;
begin
  for Item in Reversed do begin
    if Predicate(Item) then Exit(Item);
  end;
  Result:= DefaultValue;
end;

function TBinaryTreeBase<K>.Less(const a, b: K): Boolean;
begin
  Result:= Comparer.Compare(a, b) < 0;
end;

function TBinaryTreeBase<K>.Equal(const a, b: K): boolean;
begin
  Result:= Comparer.Compare(a, b) = 0;
end;

function TRedBlackTree<K>.Extract(const Key: K): K;
var
  Node: TNode;
begin
  Node:= FindNode(Root, Key);
  Result:= Node.Key;
  Remove(Key);
end;

procedure TRedBlackTree<K>.ColorFlip(const Node: TNode);
begin
  Node.NodeColor:= not(Node.NodeColor);
  if Node.Left <> nil then Node.Left.NodeColor:= not(Node.Left.NodeColor);
  if Node.Right <> nil then Node.Right.NodeColor:= not(Node.Right.NodeColor);
end;

function TRedBlackTree<K>.RotateLeft(Node: TNode): TNode;
var
  x: TNode;
begin
  // Make a right-leaning 3-node lean to the left.
  x:= Node.Right;
  Node.Right:= x.Left;
  x.Left:= Node;
  x.NodeColor:= x.Left.NodeColor;
  x.Left.NodeColor:= Color.Red;
  Result:= x;
end;

function TRedBlackTree<K>.RotateRight(Node: TNode): TNode;
var
  x: TNode;
begin
  // Make a left-leaning 3-node lean to the right.
  x:= Node.Left;
  Node.Left:= x.Right;
  x.Right:= Node;
  x.NodeColor:= x.Right.NodeColor;
  x.Right.NodeColor:= Color.Red;
  Result:= x;
end;

function TRedBlackTree<K>.MoveRedLeft(Node: TNode): TNode;
begin
  // Assuming that node is red and both node.left and node.left.left
  // are black, make node.left or one of its children red.
  ColorFlip(Node);
  if ((Node.Right.Left.IsRed)) then begin
    Node.Right:= RotateRight(node.Right);

    Node:= RotateLeft(Node);
    ColorFlip(Node);

    if ((Node.Right.Right.IsRed)) then Node.Right:= RotateLeft(Node.Right);
  end;
  Result:= Node;
end;

function TRedBlackTree<K>.MoveRedRight(Node: TNode): TNode;
begin
  // Assuming that node is red and both node.right and node.right.left
  // are black, make node.right or one of its children red.
  ColorFlip(node);
  if (Node.Left.Left.IsRed) then begin
    Node:= RotateRight(node);
    ColorFlip(Node);
  end;
  Result:= Node;
end;



function TRedBlackTree<K>.FixUp(Node: TNode): TNode;
begin
  if ((Node.Right.IsRed)) then begin
    if (fSpecies = TD234) and ((Node.Right.Left.IsRed)) then Node.Right:= RotateRight(Node.Right);
    Node:= RotateLeft(Node);
  end;

  if ((Node.Left.IsRed) and (Node.Left.Left.IsRed)) then Node:= RotateRight(Node);

  if (fSpecies = BU23) and (Node.Left.IsRed) and (Node.Right.IsRed) then ColorFlip(Node);

  Result:= Node;
end;

procedure TBinaryTreeBase<K>.FreeSingleNode(Node: TNode);
begin
  Assert(Node <> nil);
  Dec(fCount);
  Node.Free;
end;

procedure TBinaryTreeBase<K>.TraverseInOrder(const Node: TNode; Action: TNodePredicate);
begin
  if (Node = nil) then exit;
  TraverseInOrder(Node.Left, Action);
  if Action(Node) then exit;
  TraverseInOrder(Node.Right, Action);
end;

procedure TBinaryTreeBase<K>.TraversePostOrder(const Node: TNode; Action: TNodePredicate);
begin
  if (Node = nil) then exit;
  TraversePostOrder(Node.Left, Action);
  TraversePostOrder(Node.Right, Action);
  if Action(Node) then exit;
end;

procedure TBinaryTreeBase<K>.TraversePreOrder(const Node: TNode; Action: TNodePredicate);
begin
  if (Node = nil) then exit;
  if Action(Node) then exit;
  TraversePreOrder(Node.Left, Action);
  TraversePreOrder(Node.Right, Action);
end;

procedure TBinaryTreeBase<K>.Clear;
begin
  TraversePostOrder(Root,
    function(const Node: TNode): boolean
    begin
      FreeSingleNode(Node);
      Result:= false;
    end);
  fRoot:= nil;
  Assert(fCount = 0);
end;

{$IF defined(debug)}

function TRedBlackTree<K>.Check: boolean;
begin
  // Is this tree a red-black tree?
  Result:= isBST and Is234 and IsBalanced;
end;

function TRedBlackTree<K>.IsBST: boolean;
begin
  // Is this tree a BST?
  if (Root = nil) then exit(true);
  Result:= IsBST(Root, First, Last);
end;

function TRedBlackTree<K>.IsBST(Node: TNode; MinKey, MaxKey: K): boolean;
begin
  // Are all the values in the BST rooted at x between min and max,
  // and does the same property hold for both subtrees?
  if (Node = nil) then Exit(true);
  if (Less(Node.key, MinKey) or Less(MaxKey, Node.key)) then Exit(false);
  Result:= IsBST(Node.Left, MinKey, Node.key) and IsBST(Node.Right, Node.key, MaxKey);
end;

function TRedBlackTree<K>.Is234: boolean;
begin
  Result:= Is234(Root);
end;

function TRedBlackTree<K>.Is234(Node: TNode): boolean;
begin
  if (Node = nil) then Exit(true);
  if ((Node.Right.IsRed)) then Exit((fspecies = TD234) and (Node.Left.IsRed));
  if (not(Node.Right.IsRed)) then Exit(true);
  Result:= Is234(Node.Left) and Is234(Node.Right);
end;

function TRedBlackTree<K>.IsBalanced: boolean;
var
  x: TNode;
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

function TRedBlackTree<K>.IsBalanced(Node: TNode; Black: integer): boolean;
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

constructor TBinaryTreeBase<K>.TTreeEnumerator.Create(const Head: TNode; Direction: TDirection);
begin
  inherited Create;
  fHead:= Head;
  fStack.Init;
  fDirection:= Direction;
end;

function TBinaryTreeBase<K>.TTreeEnumerator.Clone: TIterator<K>;
begin
  Result:= TTreeEnumerator.Create(self.fHead, Self.fDirection);
end;

constructor TBinaryTreeBase<K>.TTreeEnumerator.Create(const Head: TNode);
begin
  Create(Head, FromBeginning);
end;

destructor TBinaryTreeBase<K>.TTreeEnumerator.Destroy;
begin
  // fStack.Free;
  inherited;
end;

function TBinaryTreeBase<K>.TTreeEnumerator.GetCurrent: K;
begin
  Assert(Assigned(fCurrentNode));
  Result:= fCurrentNode.Key;
end;

function TBinaryTreeBase<K>.TTreeEnumerator.MoveNext: Boolean;
var
  Node: TNode;
begin
  if (fCurrentNode = nil) then begin
    fCurrentNode:= fHead;
    if fCurrentNode = nil then Exit(false);
    // Start in the Left most position
    fStack.Push(fCurrentNode);
  end;
  while not fStack.IsEmpty do begin
    { get the node at the head of the queue }
    Node:= fStack.Pop;
    { if it's nil, pop the next node, perform the action on it. If
      this returns with a request to stop then return this node }
    if (Node = nil) then begin
      fCurrentNode:= fStack.Pop;
      exit(true);
    end
    { otherwise, the children of the node have not been pushed yet }
    else begin
      case fDirection of
        FromBeginning:begin { push the Left child, if it's not nil }
          if (Node.Right <> nil) then fStack.Push(Node.Right);
          { push the node, followed by a nil pointer }
          fStack.Push(Node);
          fStack.Push(nil);
          { push the Right child, if it's not nil }
          if (Node.Left <> nil) then fStack.Push(Node.Left);
        end; { FromBeginning }
        FromEnd:begin { push the Left child, if it's not nil }
          if (Node.Left <> nil) then fStack.Push(Node.Left);
          { push the node, followed by a nil pointer }
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

procedure TBinaryTreeBase<K>.TTreeEnumerator.Reset;
begin
  fStack.Init;
  fCurrentNode:= nil;
end;

{ TRedBlackTree<K, V> }

constructor TRedBlackTree<K, V>.Create(const comparer: IComparer<K>; Species: TTreeSpecies);
begin
  fKeyComparer := TTreeComparer.Create(comparer);
  inherited Create(fKeyComparer);
  fValueComparer:= TComparer<V>.Default;
  fOnKeyChanged:= TCollectionChangedEventImpl<K>.Create;
  fOnValueChanged:= TCollectionChangedEventImpl<V>.Create;
end;

constructor TRedBlackTree<K, V>.Create(Species: TTreeSpecies);
begin
  Create(TComparer<K>.Default);
end;

constructor TRedBlackTree<K, V>.Create(const comparer: TComparison<K>; Species: TTreeSpecies);
begin
  Create(IComparer<K>(PPointer(@comparer)^));
end;

procedure TRedBlackTree<K, V>.Add(const key: K; const value: V);
var
  Pair: TPair;
begin
  Pair:= TPair.Create(Key, Value);
  inherited Add(Pair);
end;

procedure TRedBlackTree<K, V>.AddOrSetValue(const key: K; const value: V);
var
  Pair: TPair;
  Node: TNode;
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

function TRedBlackTree<K, V>.ContainsKey(const key: K): Boolean;
var
  Pair: TPair;
begin
  Pair:= TPair.Create(Key, default (V));
  Result:= Assigned(FindNode(Root, Pair));
end;

function TRedBlackTree<K, V>.ContainsValue(const value: V): Boolean;
var
  DummyPair: TPair;
begin
  Result:= Any(
    function(const Pair: TPair): boolean
    begin
      Result:= fValueComparer.Compare(Pair.Value, Value) = 0;
    end);
end;

function TRedBlackTree<K, V>.Contains(const key: K; const value: V): Boolean;
begin
  Result := Assigned(FindNode(Root, TPair.Create(key, value)));
end;

function TRedBlackTree<K, V>.Extract(const key: K): V;
begin
  Result := ExtractPair(key).Value;
end;

function TRedBlackTree<K, V>.ExtractPair(const key: K): TPair<K, V>;
var
  Pair: TPair;
  Node: TNode;
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

function TRedBlackTree<K, V>.GetItem(const key: K): V;
var
  Node: TNode;
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

function TRedBlackTree<K, V>.Remove(const key: K): Boolean;
var
  Pair: TPair;
begin
  Pair.Create(Key, default (V));
  Result:= inherited Remove(Pair);
end;

function TRedBlackTree<K, V>.Remove(const key: K; const Value: V): Boolean;
var
  Pair: TPair;
begin
  Pair.Create(Key, Value);
  Result:= inherited Remove(Pair);
end;

function TRedBlackTree<K, V>.Extract(const key: K; const value: V): TPair<K,V>;
begin
  Result := TPair.Create(key, value);
  inherited Remove(Result);
end;

procedure TRedBlackTree<K, V>.SetItem(const key: K; const value: V);
var
  Pair: TPair;
  Node: TNode;
begin
  Pair:= TPair.Create(Key, Value);
  Node:= FindNode(Root, Pair);
  if Assigned(Node) then Node.Key:= Pair
  else raise EInvalidOperationException.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TRedBlackTree<K, V>.TryGetValue(const key: K; out value: V): Boolean;
var
  Pair: TPair;
  Node: TNode;
begin
  Pair:= TPair.Create(Key, default (V));
  Node:= FindNode(Root, Pair);
  Result:= Assigned(Node);
  if Result then Value:= Node.Key.Value;
  TObject.NewInstance
end;

function TRedBlackTree<K, V>.GetValueOrDefault(const key: K): V;
begin
  if not TryGetValue(key, Result) then
    Result := default (V);
end;

function TRedBlackTree<K, V>.GetValueOrDefault(const key: K; const defaultValue: V): V;
begin
  if not TryGetValue(key, Result) then
    Result := defaultValue;
end;

function TRedBlackTree<K, V>.Pair(const Key: K; const Value: V): TPair;
begin
  Result:= TPair.Create(Key, Value);
end;

{ TRedBlackTree<K, V>.TTreeComparer }

constructor TRedBlackTree<K, V>.TTreeComparer.Create(const comparer: IComparer<K>);
begin
  inherited Create;
  fComparer:= comparer;
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
  Node: TNode;
begin
  Node:= FindNode(Root, Pair(Key, Default(V)));
  Result:= Node.Key;
end;

function TNAryTree<K, V>.GetDirectChildern(const ParentKey: K): TArray<TPair<K, V>>;
var
  Node, Parent: TNode;
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

function TNAryTree<K,V>.InternalInsert(Head: TNode; const Key: K; const Value: V): TNode;
begin
  if Head = nil then begin
    Exit(NewNode(Pair(Key,Value)));
  end;

  if Equal(Key, Head.Key.Key) then raise EInvalidOperationException.CreateRes(@SSetDuplicateInsert)
  else if (Less(Key, Head.Key.Key)) then Head.Left:= InternalInsert(Head.Left, Key, Value)
  else Head.Right:= InternalInsert(Head.Right, Key, Value);

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

function TBinaryTreeBase<K>.NewNode(const Key: K): TNode;
begin
  Result:= TNode.Create(Key);
  Inc(fCount);
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

function TBinaryTreeBase<K, V>.Pair(Key: K; Value: V): TPair<K, V>;
begin
  Result := TPair<K,V>.Create(key, value);
end;

end.


