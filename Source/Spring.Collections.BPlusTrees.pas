unit Spring.Collections.BPlusTrees;

interface

uses
  System.Types,
  System.TypInfo,
  System.Generics.Collections,
  System.Generics.Defaults,
  Spring.Collections,
  Spring.Collections.Extensions,
  Spring.Collections.Base,
  Spring.Collections.Ministacks;

const
  DefaultCapacity = 8;

type
  TBPlusTree<K, V> = class(TObject)
  private type
    // TPair has a constructor, and that cannot be inlined.
    TNodePair<N, I> = record
    private
      fNode: N;
      fIndex: I;
    public
      function Init(const Node: N; const Index: I): TNodePair<N, I>; inline;
      property Node: N read fNode;
      property index: I read fIndex;
    end;

    TKey = record
    public
      class var fComparer: IComparer<K>;
    private
      Key: K;
    private type
      PK = ^K;
    public
      class constructor Create;
      class operator Implicit(const A: TKey): K; inline;
      class operator Implicit(const Key: K): TKey; inline;
      class operator LessThan(const Key: K; const A: TKey): boolean; inline;
      class operator LessThan(const Key: TKey; const A: K): boolean; inline;
      class operator LessThanOrEqual(const Key: K; const A: TKey): boolean; inline;
      class operator GreaterThan(const Key: K; const A: TKey): boolean; inline;
      class operator GreaterThanOrEqual(const Key: K; const A: TKey): boolean; inline;
      class operator Equal(const Key: K; const A: TKey): boolean; inline;
      class function BinarySearch(const Values: array of TKey; const Item: K; Count: Integer)
        : Integer; static;
      class function BinaryInexact(const Values: array of TKey; const Item: K; Count: Integer)
        : Integer; static;
    end;

    TKeyArray = array [0..7] of TKey;
    // PKeyArray = ^TKeyArray;
    TValueArray = array[0..0] of V;
    PValueArray = ^TValueArray;

    TNode = record
    private type
      PNode = ^TNode;
      TChildArray = array[0..7] of PNode;
      PChildArray = ^TChildArray;
      PV = ^V;
      TBPlusTreeStack = TMiniStack<PNode>;

    class var
      Capacity: integer;
      KeyType: TTypeKind;
      ValueType: TTypeKind;
      KeySize: Integer;
      NodeSize: Integer;
      LeafSize: Integer;
      DataStart: Integer;
    private
      fPrev: PNode;
      fNext: PNode;
      fCount: Word;
      fIsLeaf: Boolean;
      fKeys: TKeyArray;
      fChildern: TChildArray;
{$REGION 'Property accessors'}
      procedure SetChild(const index: integer; value: PNode); inline;
      function GetChild(const index: Integer): PNode; inline;
      function GetChildPointer(const index: Integer): Pointer; inline;
      procedure SetValue(const index: Integer; const Value: V); inline;
      function GetValue(const index: Integer): V; inline;
      function GetValuePointer(const index: Integer): PV; inline;
{$ENDREGION}
      function SplitSequential(out NewKey: K): PNode;
      function MergeChild(Index: integer): K;
      function RemoveEntry(index: integer): integer;
      function ReplaceKey(KeyIndex: Integer; const OldKey, NewKey: K): Boolean;
      procedure MergeWith(Right: PNode; const ParentKey: K);
      function IndexOfLeaf(const Key: K): Integer; inline;
      function IndexOfNode(const Key: K): Integer; inline;
      function GetChildByKey(const Key: K): PNode;
      function SplitLeaf(out NewKey: K): PNode;
      function SplitNode(out NewKey: K): PNode;
      function IndexOfChild(Child: PNode): integer;
    public
      class function CreateNode: PNode; static;
      class function CreateLeaf: PNode; static;
      /// <summary>
      /// Recursively frees the node and all its childern
      /// Finalizes any managed types the node may contain.
      /// </summary>
      procedure Free;
      /// <summary>
      /// Use burn to dispose of nodes that have been merged with other objects.
      /// </summary>
      procedure Burn;
      function IsEmpty: Boolean; inline;
      function AddKey(const Key: K; const Value: V): boolean; overload;
      procedure AddKey(const Key: K; Left, Right: PNode); overload;
      function AddKeySequential(const Key: K; const Value: V): boolean; overload;
      procedure AddKeySequential(const Key: K; Left, Right: PNode); overload;
      function RemoveKey(const Key: K): boolean;
      function IsLeaf: Boolean; inline;
      property Values[const index: Integer]: V read GetValue write SetValue;
      property ValueP[const index: Integer]: PV read GetValuePointer;
      property Childern[const index: Integer]: PNode read GetChild write SetChild;
      property ChildByKey[const Key: K]: PNode read GetChildByKey;
      property ChildP[const index: Integer]: pointer read GetChildPointer;
      property Count: word read fCount write fCount;
      property Next: PNode read fNext write fNext;
      property Prev: PNode read fPrev write fPrev;
    end;

    PNode = TNode.PNode;
    TNodePair = TNodePair<PNode, integer>;

    TBPlusTreeStack = TNode.TBPlusTreeStack;
    TPairStack = TMiniStack<TNodePair>;

    TLeafIndex = record
    private
      Leaf: PNode;
      Index: Integer;
    public
      constructor Init(Leaf: PNode; Index: Integer);
      function Found: Boolean; inline;
      class operator Implicit(A: TLeafIndex): PNode; inline;
      function Next: TLeafIndex; inline;
      function Previous: TLeafIndex; inline;
      function Value: V; inline;
      function Key: K; inline;
    end;

    TTreeEnumerator = class(TIterator<K>)
    private
      fLeafIndex: TLeafIndex;
      fParent: TBPlusTree<K, V>;
      // Enumerator can be reversed.
      fDirection: TDirection;
    protected
      // function GetCurrentNonGeneric: V; override;
      function Clone: TIterator<K>; override;
    public
      constructor Create(const Parent: TBPlusTree<K, V>; Direction: TDirection = FromBeginning);
      procedure Reset; override;
      function MoveNext: Boolean; override;
      // function GetEnumerator: IEnumerator<K>; override;
      destructor Destroy; override;
      // The parent TIterator must be altered to have a virtual GetCurrent method.
      function GetCurrent: K; override;
      property Current: K read GetCurrent;
      property CurrentLeafIndex: TLeafIndex read fLeafIndex;
    end;
  private type
    PV = ^V;
    TCopyArray = procedure(const Source, Dest: PV; ElementCount: Integer);
  private
    class var fCopyArray: TCopyArray;
    class procedure CopyArraySimple(const Source, Dest: PV; ElementCount: Integer); static;
    class procedure CopyArrayOfDynArray(const Source, Dest: PV; ElementCount: Integer); static;
    class procedure CopyArrayOfString(const Source, Dest: PV; ElementCount: Integer); static;
  private
    fRoot: PNode;
    fCount: integer;
    fHeight: Integer;
    // Tracking fields for sequential inserts
    fSequentialInserts: boolean;
    fLargestKey: TKey;
    fLastStack: TBPlusTreeStack;
    // Allows accessing the B+Tree as an array.
    fLeafIndex: TLeafIndex;
    // Set the correct CopyArray method for array<V>.
    class constructor CreateClass;
    function Delete(const Key: K): boolean;
    function MoveTo(Index: integer): boolean;
    procedure FixNodes(const KeyList: TPairStack; const FromKey, ToKey: K);
    function FindNode(const Key: K): TLeafIndex;
    function GetLast: TLeafIndex;
    function GetFirst: TLeafIndex;
    function AddNonSequential(const Key: K; const Value: V): boolean;
    procedure InitStack(const Stack: TBPlusTreeStack);
    procedure SetKey(const index: integer; const Key: K);
    procedure SetValue(const index: integer; const Value: V);
    property Root: PNode read fRoot;
    property Height: integer read fHeight;
  protected
  public
    constructor Create(NodeSize: integer = DefaultCapacity);
    destructor Destroy; override;
    function AddSequential(const Key: K; const Value: V): Boolean;
  public
    // Enumerators
    function GetEnumerator: IEnumerator<K>; virtual;
    function Reversed: IEnumerable<K>; virtual;
  public
    // Wrapper functions are inlined
    procedure Clear;
    function Add(const Key: K; const Value: V): boolean; overload;
    function Add(const Value: TPair<K, V>): boolean; overload; inline;
    function Contains(const Key: K): Boolean;
    function Remove(const Key: K): boolean; inline;
    function Seek(const Key: K): boolean; inline;
    function GetKey(const index: integer): K;
    function GetValue(const Index: integer): V;
    function Skip(Count: integer): V;
    function GetRange(Start, Finish: K): TArray<V>;
    function First: V; inline;
    function Last: V; inline;
    property Count: integer read fCount;
    property Keys[const index: Integer]: K read GetKey write SetKey;
    property Values[const index: Integer]: V read GetValue write SetValue;
  end;

implementation

uses
  System.Classes,
  System.SysUtils,
  Spring.ResourceStrings,
  Spring.ManagedTypesUtilities;

const
  NotFound = -1;

  // helper functions

class function TBPlusTree<K, V>.TKey.BinaryInexact(const Values: array of TKey; const Item: K;
  Count: Integer): Integer;
const
  NotFound = -1;
var
  L, H: Integer;
  mid, cmp: Integer;
begin
  Result:= Count;
  if Count = 0 then Exit;
  L:= 0;
  H:= Count - 1;
  while L <= H do begin
    mid:= L + (H - L) shr 1;
    if Values[mid] < Item then begin
      L:= mid + 1;
    end else begin
      H:= mid - 1;
      Result:= mid;
    end;
  end; { while }
end;

class function TBPlusTree<K, V>.TKey.BinarySearch(const Values: array of TKey; const Item: K;
  Count: Integer): Integer;
const
  NotFound = -1;
var
  L, H: Integer;
  mid, cmp: Integer;
begin
  Result:= NotFound;
  if Count = 0 then Exit;
  L:= 0;
  H:= Count - 1;
  while L <= H do begin
    mid:= L + (H - L) shr 1;
    cmp:= TKey.fComparer.Compare(Values[mid].Key, Item);
    if cmp = 0 then exit(mid);
    if cmp < 0 then L:= mid + 1
    else begin
      H:= mid - 1;
    end;
  end;
end;

class constructor TBPlusTree<K, V>.TKey.Create;
begin
  fComparer:= TComparer<K>.Default;
end;

class operator TBPlusTree<K, V>.TKey.Equal(const Key: K; const A: TKey): boolean;
begin
  if (SizeOf(K) = SizeOf(integer)) and (TypeInfo(K) = TypeInfo(Integer)) then
      Result:= integer((@Key)^) = integer((@a.Key)^)
  else Result:= fComparer.Compare(A.Key, Key) = 0;
end;

class operator TBPlusTree<K, V>.TKey.LessThan(const Key: K; const A: TKey): boolean;
begin
  if (SizeOf(K) = SizeOf(integer)) and (TypeInfo(K) = TypeInfo(Integer)) then
      Result:= integer((@Key)^) < integer((@a.Key)^)
  else Result:= fComparer.Compare(Key, A.Key) < 0;
end;

class operator TBPlusTree<K, V>.TKey.LessThan(const Key: TKey; const A: K): boolean;
begin
  if (SizeOf(K) = SizeOf(integer)) and (TypeInfo(K) = TypeInfo(Integer)) then
      Result:= integer((@Key)^) < integer((@a)^)
  else Result:= fComparer.Compare(Key.Key, A) < 0;
end;

class operator TBPlusTree<K, V>.TKey.GreaterThan(const Key: K; const A: TKey): boolean;
begin
  if (SizeOf(K) = SizeOf(integer)) and (TypeInfo(K) = TypeInfo(Integer)) then
      Result:= integer((@Key)^) > integer((@a.Key)^)
  else Result:= fComparer.Compare(Key, A.Key) > 0;
end;

class operator TBPlusTree<K, V>.TKey.LessThanOrEqual(const Key: K; const A: TKey): boolean;
begin
  if (SizeOf(K) = SizeOf(integer)) and (TypeInfo(K) = TypeInfo(Integer)) then
      Result:= integer((@Key)^) <= integer((@a.Key)^)
  else Result:= fComparer.Compare(Key, A.Key) <= 0;
end;

class operator TBPlusTree<K, V>.TKey.GreaterThanOrEqual(const Key: K; const A: TKey): boolean;
begin
  if (SizeOf(K) = SizeOf(integer)) and (TypeInfo(K) = TypeInfo(Integer)) then
      Result:= integer((@Key)^) >= integer((@a.Key)^)
  else Result:= fComparer.Compare(Key, A.Key) >= 0;
end;

class operator TBPlusTree<K, V>.TKey.Implicit(const A: TKey): K;
begin
  Result:= A.Key;
end;

class operator TBPlusTree<K, V>.TKey.Implicit(const Key: K): TKey;
begin
  Result.Key:= Key;
end;

{ TBPlusTree<K, V>.TChild }

class function TBPlusTree<K, V>.TNode.CreateNode: PNode;
begin
  Result:= AllocMem(TNode.NodeSize);
end;

class function TBPlusTree<K, V>.TNode.CreateLeaf: PNode;
begin
  Result:= AllocMem(TNode.LeafSize);
  Result.fIsLeaf:= true;
end;

function TBPlusTree<K, V>.TNode.GetValue(const index: Integer): V;
begin
  Result:= ValueP[index]^;
end;

procedure TBPlusTree<K, V>.SetValue(const index: integer; const Value: V);
begin
  if MoveTo(index) then begin
    fLeafIndex.Leaf.Values[fLeafIndex.Index]:= Value;
  end
  else raise EInvalidOperation.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TBPlusTree<K, V>.TNode.GetValuePointer(const Index: Integer): PV;
begin
  Result:= pointer(NativeInt(@Self) + TNode.DataStart + (SizeOf(V) * index));
end;

function TBPlusTree<K, V>.TNode.GetChildPointer(const Index: Integer): Pointer;
begin
  Result:= pointer(NativeInt(@Self) + TNode.DataStart + (SizeOf(K) * index));
end;

function TBPlusTree<K, V>.TNode.IsLeaf: boolean;
begin
  if ((@Self) = nil) then Exit(true);
  Result:= Self.fIsLeaf;
end;

function TBPlusTree<K, V>.TNode.IsEmpty: Boolean;
begin
  Result:= (fCount = 0);
end;

procedure TBPlusTree<K, V>.TNode.MergeWith(Right: PNode; const ParentKey: K);
begin
  Assert(Count + Right.Count <= Capacity);
  case IsLeaf of
    false: begin
      // Leave a gap for the parentkey to be inserted into.
      Move(Right.fKeys[0], fKeys[Count], (Right.Count - 1) * SizeOf(K));
      fKeys[Count-1]:= ParentKey; // Todo: refactor to remove managed type init code.
      Move(Right.ChildP[0]^, ChildP[Count]^, Right.Count * SizeOf(PNode));
    end; // IsNode:
    true: begin
      Move(Right.fKeys[0], fKeys[Count], Right.Count * SizeOf(K));
      Move(Right.ValueP[0]^, ValueP[Count]^, Right.Count * SizeOf(V));
      Next:= Right.Next;
      if Assigned(Next) then Next.Prev:= @Self;
    end; // IsLeaf:
  end;
  Count:= Count + Right.Count;
  Right.Burn; // Do not free because right's payload has been moved.
end;

procedure TBPlusTree<K, V>.TNode.Free;
var
  i: Integer;
begin
  if @Self <> nil then begin
    case fIsLeaf of
      True: begin
        Finalize(fKeys[0], count);
        Finalize(PV(GetValuePointer(0))^, Count);
        if Assigned(Prev) then begin
          Prev.Next:= Next;
        end;
        if Assigned(Next) then begin
          Next.Prev:= Prev;
        end;
      end;
      false: begin
        for i:= 0 to Count-1 do begin
          // Every node has Count-1 Keys and Count Childern
          Childern[i].Free;
        end;
        Finalize(fKeys[0], count-1);
      end;
    end;
    FreeMem(@Self);
  end;
end;

procedure TBPlusTree<K, V>.TNode.Burn;
begin
  Assert(@Self <> nil);
  FreeMem(@Self);
end;

function TBPlusTree<K, V>.TNode.IndexOfLeaf(const Key: K): Integer;
begin
  Result:= TKey.BinarySearch(fKeys, Key, fCount);
end;

function TBPlusTree<K, V>.TNode.IndexOfNode(const Key: K): Integer;
begin
  Result:= TKey.BinaryInexact(fKeys, Key, Count - 1);
end;

function TBPlusTree<K, V>.TNode.AddKey(const Key: K; const Value: V): boolean;
var
  i, a: integer;
  Source, Dest: Pointer;
begin
  Assert(fIsLeaf);
  i:= TKey.BinaryInexact(fKeys, Key, Count);
  if (i < fCount) then begin
    if Key = fKeys[i] then exit(false); // Key already exists
    // Make space for the key
    Move(fKeys[i], fKeys[i+1], (fCount - i) * SizeOf(TKey));
    // Clear reference to a managed type
    if (SizeOf(K) = SizeOf(Pointer)) then NativeInt((@fKeys[i])^):= 0;
    Source:= GetValuePointer(i);
    Dest:= pointer(NativeInt(Source)+SizeOf(V));
    Move(Source^, Dest^, (fCount - i) * SizeOf(V));
    // Clear reference to a managed type
    if (SizeOf(V) = SizeOf(Pointer)) then NativeInt(Source^):= 0;
  end;
  Inc(fCount);
  fKeys[i]:= Key;
  Values[i]:= Value;
  Result:= true;
end;

function TBPlusTree<K, V>.TNode.AddKeySequential(const Key: K; const Value: V): boolean;
var
  i: integer;
  Source, Dest: Pointer;
begin
  Assert(fIsLeaf);
  fKeys[fCount]:= Key;
  Values[fCount]:= Value;
  Inc(fCount);
  Result:= true;
end;

procedure TBPlusTree<K, V>.TNode.SetValue(const index: Integer; const Value: V);
var
  Dest: PV;
begin
  Dest:= PV(GetValuePointer(index));
  Dest^:= Value;
end;

function TBPlusTree<K, V>.TNode.SplitNode(out NewKey: K): PNode;
var
  Median: Integer;
  NewNode: PNode;
  AfterSize: Integer;
begin
  Median:= fCount div 2;
  NewNode:= TNode.CreateNode;
  AfterSize:= ((fCount-Median)-1) * SizeOf(K);
  NewKey:= fKeys[Median-1];
  Move(fKeys[Median], NewNode.fKeys[0], AfterSize);
  AfterSize:= AfterSize + SizeOf(K);
  // Clear references to managed types
  if SizeOf(K) = SizeOf(Pointer) then FillChar(fKeys[Median-1], AfterSize, #0);
  NewNode.fCount:= (fCount - Median);
  AfterSize:= (fCount - Median) * SizeOf(PNode);
  Move(ChildP[Median]^, NewNode.ChildP[0]^, AfterSize);
  fCount:= Median;
  Result:= NewNode;
end;

function TBPlusTree<K, V>.TNode.SplitLeaf(out NewKey: K): PNode;
var
  Median: Integer;
  NewLeaf: PNode;
  NewLength, AfterSize: Integer;
begin
  Median:= fCount div 2;
  NewLeaf:= TNode.CreateLeaf;
  NewLength:= fCount - Median;
  AfterSize:= (NewLength) * SizeOf(K);
  // Split the node, the median key is migrated to the parent
  Move(fKeys[Median], NewLeaf.fKeys[0], AfterSize);
  // Clear any references to managed types
  if SizeOf(K) = SizeOf(Pointer) then FillChar(fKeys[Median], AfterSize, #0);
  AfterSize:= (NewLength) * SizeOf(V);
  // Move(fValues[Median], NewLeaf.fValues[0], AfterSize);
  Move(ValueP[Median]^, NewLeaf.ValueP[0]^, AfterSize);
  if SizeOf(V) = SizeOf(Pointer) then FillChar(ValueP[Median]^, AfterSize, #0);
  NewLeaf.Count:= NewLength;
  Count:= Median;
  // Fixup the linked list of nodes
  NewLeaf.Prev:= @Self;
  NewLeaf.Next:= Next;
  if Next <> nil then Next.Prev:= NewLeaf;
  Next:= NewLeaf;
  NewKey:= fKeys[fCount-1];
  Result:= NewLeaf;
end;

// function TBPlusTree<K, V>.TNode.Split(out NewKey: K): PNode;
// var
// Median: integer;
// NewLeaf: PNode;
// NewNode: PNode;
// i: integer;
// NewLength: Integer;
// AfterSize: integer;
// begin
// case fIsLeaf of
// True: begin
// end; { IsLeaf = true: }
// false: begin
// end; { IsLeaf = false: }
// end; { case }
// end;

function TBPlusTree<K, V>.TNode.SplitSequential(out NewKey: K): PNode;
var
  Median: integer;
  NewLeaf: PNode;
  i: integer;
  NewLength: Integer;
  AfterSize: integer;
begin
  case fIsLeaf of
    true: begin
      Result:= TNode.CreateLeaf;
      NewKey:= fKeys[fCount-1];
      // Fixup the linked list of nodes
      Result.Prev:= @Self;
      Result.Next:= Next;
      if Next <> nil then Next.Prev:= Result;
      Next:= Result;
    end; { IsLeaf = true: }
    false: begin
      Result:= TNode.CreateNode;
      Dec(fCount);
      Result.Childern[0]:= Childern[fCount];
      Result.fCount:= 1;
      NewKey:= fKeys[Count-1];
    end; { IsLeaf = false: }
  end; { case }
end;

function TBPlusTree<K, V>.TNode.RemoveEntry(index: integer): integer;
var
  MoveCount: integer;
begin
  if (index = (Count - 1)) then begin
    // Remove the last item
    Dec(fCount);
    Finalize(fKeys[Count]);
    if fIsLeaf then Finalize(ValueP[index]^);
    Exit(Count);
  end;
  // Remove from the middle.
  Dec(fCount);
  Finalize(fKeys[index]); // Release the reference if it's a managed type
  MoveCount:= Count - index;
  case fIsLeaf of
    true: begin
      Finalize(ValueP[index]^);
      if (MoveCount = 0) then exit(Count);
      Move(fKeys[index+1], fKeys[index], MoveCount * SizeOf(K));
      Move(ValueP[index+1]^, ValueP[index]^, MoveCount * SizeOf(V));
    end;
    false: begin
      // Childern[index].Free;
      if (MoveCount = 0) then Exit(count);
      Move(ChildP[index+1]^, ChildP[index]^, MoveCount * SizeOf(PNode));
      Dec(MoveCount);
      if (MoveCount > 0) then begin
        Move(fKeys[index+1], fKeys[index], MoveCount * SizeOf(K));
      end;
    end;
  end;
  Result:= Count;
end;

function TBPlusTree<K, V>.TNode.RemoveKey(const Key: K): boolean;
var
  index: integer;
begin
  if fIsLeaf then index:= IndexOfLeaf(Key)
  else index:= IndexOfNode(Key);

  if (index = NotFound) then Exit(false);
  RemoveEntry(index);
  Result:= true;
end;

function TBPlusTree<K, V>.TNode.GetChild(const index: integer): PNode;
begin
  Result:= PNode(GetChildPointer(index)^);
end;

function TBPlusTree<K, V>.TNode.GetChildByKey(const Key: K): PNode;
var
  i: Integer;
  index: Integer;
begin
  index:= count-1;
  for i:= 0 to fCount - 2 do begin
    if Key <= fKeys[i] then begin
      index:= i;
      break;
    end;
  end;
  Result:= PNode(pointer(NativeInt(@Self) + TNode.DataStart + (SizeOf(K) * index))^);
end;

procedure TBPlusTree<K, V>.TNode.SetChild(const index: integer; value: PNode);
begin
  PNode(GetChildPointer(index)^):= value;
end;

procedure TBPlusTree<K, V>.TNode.AddKey(const Key: K; Left, Right: PNode);
var
  Index: integer;
  MoveCount: integer;
begin
  if (fCount = 0) then begin
    fKeys[0]:= Key;
    Childern[0]:= Left;
    Childern[1]:= Right;
    fCount:= 2;
  end else begin
    index:= IndexOfNode(Key);
    if (index = count - 1) then begin
      // Add a new item at the end.
      fKeys[index]:= Key;
      Childern[index+1]:= Right;
      Inc(fCount);
    end else begin
      if (fKeys[index] = Key) then Exit; // Key already exists.
      // Insert a new item in the middle.
      MoveCount:= (fCount - index) - 1;
      Move(ChildP[index+1]^, ChildP[index+2]^, MoveCount * SizeOf(PNode));
      Move(fKeys[index], fKeys[index+1], MoveCount * SizeOf(TKey));
      if SizeOf(K) = SizeOf(Pointer) then NativeInt((@fKeys[index])^):= 0;
      fKeys[index].Key:= Key;
      // fChildern[i]:= Left;
      Childern[index+1]:= Right;
      Inc(fCount);
    end;
  end;
end;

procedure TBPlusTree<K, V>.TNode.AddKeySequential(const Key: K; Left, Right: PNode);
var
  Index: integer;
  MoveCount: integer;
begin
  if (fCount = 0) then begin
    fKeys[0]:= Key;
    Childern[0]:= Left;
    Childern[1]:= Right;
    fCount:= 2;
  end else begin
    fKeys[fCount-1]:= Key;
    Childern[fCount]:= Right;
    Inc(fCount);
  end;
end;

function TBPlusTree<K, V>.TNode.IndexOfChild(Child: PNode): integer;
var
  i: integer;
begin
  Assert(fIsLeaf = False);
  for i:= 0 to count - 1 do begin
    if Childern[i] = Child then Exit(i);
  end;
  Result:= -1;
end;

function TBPlusTree<K, V>.TNode.MergeChild(Index: integer): K;
var
  Left, Right: PNode;
begin
  // Both childern need to fall under the same parent.
  Assert((index < Count-1) and (index > -1));
  Assert(fIsLeaf = False);
  Left:= Childern[index];
  Right:= Childern[index+1];
  // Assert(IndexOfChild(Left) = index);
  // Assert(IndexOfChild(Right) = index+1);
  Result:= fKeys[index];
  Left.MergeWith(Right, Result);
  Dec(fCount);
  if index < Count then begin
    Finalize(fKeys[index]);
    Move(fKeys[index+1], fKeys[index], (Count - index) * SizeOf(K));
    Move(ChildP[index+2]^, ChildP[index+1]^, (Count - index) * SizeOf(PNode));
  end;
end;

function TBPlusTree<K, V>.TNode.ReplaceKey(KeyIndex: Integer; const OldKey, NewKey: K): Boolean;
begin
  if not(fKeys[KeyIndex] = OldKey) then Exit(false);
  // i:= TKey.BinarySearch(fKeys, OldKey, Count - 1);
  // if i <> NotFound then begin
  fKeys[KeyIndex]:= NewKey;
  Exit(true);
end;


// ---------- B+ Tree ----------

class constructor TBPlusTree<K, V>.CreateClass;
begin
  // Examine the nature of V and set the copy method of Array<V> appropriatly.
  case PTypeInfo(TypeInfo(V)).Kind of
    tkInteger, tkChar, tkEnumeration, tkFloat, tkSet, tkInt64, tkPointer, tkString, tkWString: begin
      fCopyArray:= TBPlusTree<K, V>.CopyArraySimple;
    end;
    tkDynArray: begin
      fCopyArray:= TBPlusTree<K, V>.CopyArrayOfDynArray;
    end;
    tkLString, tkUString: begin
      fCopyArray:= TBPlusTree<K, V>.CopyArrayOfString;
    end;
    tkVariant, tkArray, tkDynArray, tkRecord, tkInterface: begin
      fCopyArray:= TBPlusTree<K, V>.CopyArrayOfDynArray;
    end;
    tkClass: begin
      // Perhaps clone the class at some future point?
      fCopyArray:= TBPlusTree<K, V>.CopyArraySimple;
    end;
    tkMethod: begin
      // Special case it some some later use
      fCopyArray:= TBPlusTree<K, V>.CopyArraySimple;
    end;
    tkClassRef: begin
      // Special case it some some later use
      fCopyArray:= TBPlusTree<K, V>.CopyArraySimple;
    end;
    tkProcedure: begin
      // Special case it some some later use
      fCopyArray:= TBPlusTree<K, V>.CopyArraySimple;
    end;
  end;
end;

constructor TBPlusTree<K, V>.Create(NodeSize: integer = DefaultCapacity);
begin
  inherited Create;
  TNode.Capacity:= NodeSize;
  TNode.KeyType:= PTypeInfo(TypeInfo(K))^.Kind;
  TNode.ValueType:= PTypeInfo(TypeInfo(V))^.Kind;
  TNode.KeySize:= SizeOf(TKey) * TNode.Capacity;
  TNode.DataStart:= SizeOf(TNode) + TNode.KeySize - SizeOf(TKeyArray) - SizeOf(TNode.TChildArray);
  TNode.NodeSize:= TNode.DataStart + SizeOf(PNode) * TNode.Capacity;
  TNode.LeafSize:= TNode.DataStart + SizeOf(V) * TNode.Capacity;
  Clear;
end;

destructor TBPlusTree<K, V>.Destroy;
begin
  Clear;
  inherited;
  Root.Free;
end;

procedure TBPlusTree<K, V>.Clear;
begin
  Root.Free;
  fRoot:= TNode.CreateLeaf;
  fCount:= 0;
  fHeight:= 0;
  fSequentialInserts:= true;
  fLargestKey:= default (K);
  InitStack(fLastStack);
  fLeafIndex.Init(nil,-1);
end;

function TBPlusTree<K, V>.Add(const Key: K; const Value: V): boolean;
var
  Node: PNode;
  i: Integer;
  StackCount: Integer;
  SequentialOK: Boolean;
begin
  // As long as the InsertionValue keeps increasing we can do a simplified insert.
  SequentialOK:= ((Count = 0) or (Key > fLargestKey));
  fSequentialInserts:= fSequentialInserts and SequentialOK;
  if not(SequentialOK) then begin
    Result:= AddNonSequential(Key, Value);
    Exit;
  end;
  fLargestKey:= Key;
  if not fSequentialInserts then begin
    fSequentialInserts:= true;
    InitStack(fLastStack); // Force rebuilding of the stack.
  end;
  // If a node has been split the stack needs to be rebuild.
  StackCount:= fLastStack.Count;
  if StackCount <= fHeight then begin
    if StackCount <= 1 then begin
      // Do a full stack rebuild.
      InitStack(fLastStack);
      Node:= Root;
      fLastStack.Push(Node);
      for i:= 2 to fHeight do begin
        Node:= Node.Childern[Node.Count - 1];
        fLastStack.Push(Node);
      end; { for i }
    end else begin
      // Do a partial rebuild
      Node:= fLastStack.Peek;
      for i:= StackCount to fHeight do begin
        Node:= Node.Childern[Node.Count - 1];
        fLastStack.Push(Node);
      end;
    end;
  end;
  Result:= AddSequential(Key, Value);
end;

function TBPlusTree<K, V>.AddNonSequential(const Key: K; const Value: V): boolean;
var
  Stack: TBPlusTreeStack;
  Node, NewNode: PNode;
  Leaf: PNode;
  index: integer;
  Left, Right: PNode;
  NewKey: TKey;
  i: Integer;
begin
  InitStack(Stack);
  Node:= Root;
  for i:= 0 to fHeight - 1 do begin
    Stack.Push(Node);
    Node:= Node.ChildByKey[Key];
  end;
  Leaf:= Node;
  if Leaf.Count = TNode.Capacity then begin
    // Split the leaf
    Left:= Leaf;
    Right:= Leaf.SplitLeaf(NewKey.Key);
    if Key > NewKey then Leaf:= Right;
    repeat
      Node:= Stack.Pop;
      if (Node = nil) then begin
        // The leaf we splitted is actually the root, create a new root
        Node:= TNode.CreateNode;
        fRoot:= Node;
        Inc(fHeight);
      end;
      Node.AddKey(NewKey, Left, Right);
      if (Node.Count < Node.Capacity) then break;
      Left:= Node;
      Right:= Node.SplitNode(NewKey.Key);
    until (Stack.Count = 0);
  end; { split }
  if not(Leaf.AddKey(Key, Value)) then begin
    Exit(false);
  end else begin
    Result:= true;
    Inc(fCount);
  end; { not Found }
end;

function TBPlusTree<K, V>.Add(const Value: TPair<K, V>): boolean;
begin
  Result:= Add(Value.Key, Value.Value);
end;

function TBPlusTree<K, V>.AddSequential(const Key: K; const Value: V): Boolean;
var
  Node, NewNode: PNode;
  Leaf: PNode;
  index: integer;
  Left, Right: PNode;
  NewKey: TKey;
  Done: Boolean;
  i: Integer;
  NextValue: K;
begin
  Node:= fLastStack.Peek;
  if Node = nil then Leaf:= Root
  else begin
    Leaf:= Node.Childern[Node.Count - 1];
  end;
  if Leaf.Count = TNode.Capacity then begin
    // Split the leaf
    Left:= Leaf;
    Right:= Leaf.SplitSequential(NewKey.Key);
    // Right:= Leaf.Split(NewKey.Key);
    if Key > NewKey then Leaf:= Right;
    repeat
      Node:= fLastStack.Pop;
      if (Node = nil) then begin
        // The leaf we splitted is actually the root, create a new root
        Node:= TNode.CreateNode;
        fRoot:= Node;
        Inc(fHeight);
        Node.AddKeySequential(NewKey, Left, Right);
        Break;
      end;
      Node.AddKeySequential(NewKey, Left, Right);
      if (Node.Count < Node.Capacity) then break;
      Left:= Node;
      Right:= Node.SplitSequential(NewKey.Key);
    until (fLastStack.Count = 0); { while }
  end; { split }
  Leaf.AddKeySequential(Key, Value);
  Result:= true;
  Inc(fCount);
end;

function TBPlusTree<K, V>.Remove(const Key: K): boolean;
begin
  if fCount = 0 then exit(false);
  Result:= Self.Delete(Key);
end;

function TBPlusTree<K, V>.Reversed: IEnumerable<K>;
begin
  Result:= TTreeEnumerator.Create(Self, FromEnd);
end;

function TBPlusTree<K, V>.Seek(const Key: K): Boolean;
var
  LeafIndex: TLeafIndex;
begin
  fLeafIndex:= FindNode(Key);
  Result:= fLeafIndex.Found;
end;

function TBPlusTree<K, V>.FindNode(const Key: K): TLeafIndex;
var
  Child: PNode;
  Index: Integer;
  i: Integer;
begin
  Child:= Root;
  for i:= 0 to height - 1 do begin
    index:= Child.IndexOfNode(Key);
    Child:= Child.Childern[index];
  end;
  index:= Child.IndexOfLeaf(Key);
  if index = NotFound then begin
    Result.Init(nil, NotFound);
  end else begin
    Result.Init(Child, index);
  end;
end;

function TBPlusTree<K, V>.Contains(const Key: K): Boolean;
var
  Child: PNode;
  Index: Integer;
  i: Integer;
begin
  if Count = 0 then exit(false);
  // Todo change to for loop with height
  Child:= Root;
  for i:= 0 to Height -1 do begin
    index:= Child.IndexOfNode(Key);
    Child:= Child.Childern[index];
  end;
  index:= Child.IndexOfLeaf(Key);
  if index = NotFound then Exit(false);
  Result:= true;
end;

class procedure TBPlusTree<K, V>.CopyArraySimple(const Source, Dest: PV; ElementCount: Integer);
begin
  Move(Source^, Dest^, ElementCount * SizeOf(V));
end;

{$POINTERMATH on}

class procedure TBPlusTree<K, V>.CopyArrayOfDynArray(const Source, Dest: PV; ElementCount: Integer);
var
  i: Integer;
begin
  // Update the reference counts
  for i:= 0 to ElementCount - 1 do begin
    IncArrayRefCount(@Source[i]);
  end;
  Move(Source^, Dest^, ElementCount * SizeOf(V));
end;
{$POINTERMATH off}

{$POINTERMATH on}
class procedure TBPlusTree<K, V>.CopyArrayOfString(const Source, Dest: PV; ElementCount: Integer);
var
  i: Integer;
begin
  // Update the reference counts
  for i:= 0 to ElementCount - 1 do begin
    IncStringRefCount(@Source[i]);
  end;
  Move(Source^, Dest^, ElementCount * SizeOf(V));
end;
{$POINTERMATH off}

function TBPlusTree<K, V>.Skip(Count: integer): V;
var
  Index: integer;
begin
  index:= fLeafIndex.Index + Count;
  while (fLeafIndex.Found) and (index >= fLeafIndex.Leaf.Count) do begin
    index:= index - fLeafIndex.Leaf.Count;
    fLeafIndex.Leaf:= fLeafIndex.Leaf.Next;
  end;
  if (fLeafIndex.Found) then begin
    fLeafIndex.Index:= index;
    Result:= fLeafIndex.Value;
  end else begin
    fLeafIndex.Init(nil, NotFound);
    raise EInvalidOperation.CreateRes(@SSequenceContainsNoMatchingElement);
  end;
end;

function TBPlusTree<K, V>.GetValue(const index: integer): V;
begin
  if MoveTo(index) then begin
    Result:= fLeafIndex.Value;
  end
  else raise EInvalidOperation.CreateRes(@SSequenceContainsNoMatchingElement);
end;

procedure TBPlusTree<K, V>.InitStack(const Stack: TBPlusTreeStack);
begin
  Stack.Init;
  Stack.Push(nil);
end;

// DONE: merge nodes.
// DONE: If root has 1 child, remove the root and make the child the root.
function TBPlusTree<K, V>.Delete(const Key: K): boolean;
var
  Stack: TPairStack;
  Index: integer;
  MergeLeaf: PNode;
  Node, NextNode, PrevNode: PNode;
  Parent: PNode;
  ReplaceKeyInParent: boolean;
  i: Integer;
  ParentPair: TNodePair;
  Count: Integer;
begin
  Node:= Root;
  Stack.Init;
  for i:= 0 to fHeight - 1 do begin
    index:= Node.IndexOfNode(Key);
    Stack.Push(ParentPair.Init(Node, index));
    Node:= Node.Childern[index];
  end;
  index:= Node.IndexOfLeaf(Key);
  if (index = NotFound) then Exit(false);
  Dec(fCount);
  Count:= Node.RemoveEntry(index);
  ReplaceKeyInParent:= (Count > 0) and (index = Count);
  if ReplaceKeyInParent then FixNodes(Stack, Key, Node.fKeys[index]);
  while (Stack.Count > 0) do begin
    ParentPair:= Stack.Pop;
    if Node.IsEmpty then begin
      ParentPair.Node.RemoveEntry(ParentPair.Index);
      Node.Free;
      Node:= ParentPair.Node;
    end else begin
      // Merge childern
      index:= ParentPair.Index;
      if (index < ParentPair.Node.Count-1) then begin
        NextNode:= ParentPair.Node.Childern[index+1];
        if ((NextNode.Count + Node.Count) < TNode.Capacity) then begin
          ParentPair.Node.MergeChild(index);
        end;
      end else if (ParentPair.Index > 0) then begin
        Dec(index);
        PrevNode:= ParentPair.Node.Childern[index];
        if ((PrevNode.Count + Node.Count) < TNode.Capacity) then begin
          ParentPair.Node.MergeChild(index);
        end;
      end;
      Node:= ParentPair.Node;
      // See if the root can be squashed.
      if (Node = Root) and (Node.Count = 1) then begin
        fRoot:= Root.Childern[0];
        Node.Burn;
        Dec(fHeight);
      end;
    end; { Merge childern }
  end; { while }
end;

function TBPlusTree<K, V>.GetEnumerator: IEnumerator<K>;
begin
  Result:= TTreeEnumerator.Create(Self);
end;

procedure TBPlusTree<K, V>.SetKey(const index: integer; const Key: K);
begin
  if MoveTo(index) then begin
    fLeafIndex.Leaf.fKeys[fLeafIndex.Index]:= Key;
  end
  else raise EInvalidOperation.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TBPlusTree<K, V>.GetKey(const index: integer): K;
begin
  if MoveTo(index) then begin
    Result:= fLeafIndex.Key;
  end
  else raise EInvalidOperation.CreateRes(@SSequenceContainsNoMatchingElement);
end;

function TBPlusTree<K, V>.MoveTo(Index: integer): boolean;
var
  Leaf: PNode;
begin
  if index >= Count then Exit(false);
  if (Count - index) < index then begin
    // We're closer to the end, search backwards.
    index:= index - Count;
    Last;
    Leaf:= fLeafIndex.Leaf;
    index:= index + Leaf.Count;
    while Assigned(Leaf) and (index < 0) do begin
      Leaf:= Leaf.Prev;
      index:= index + Leaf.Count;
    end;
  end else begin
    First;
    Leaf:= fLeafIndex.Leaf;
    while Assigned(Leaf) and (index >= Leaf.Count) do begin
      index:= index - Leaf.Count;
      Leaf:= Leaf.Next;
    end;
  end;
  fLeafIndex.Init(Leaf, index);
  Result:= fLeafIndex.Found;
end;

function TBPlusTree<K, V>.GetFirst: TLeafIndex;
var
  Child: PNode;
  i: Integer;
begin
  if Count = 0 then raise EInvalidOperation.CreateRes(@SSequenceContainsNoElements);
  Child:= Root;
  for i:= 0 to height - 1 do Child:= Child.Childern[0];
  Result.Init(Child, 0);
end;

function TBPlusTree<K, V>.First: V;
begin
  fLeafIndex:= GetFirst;
  Result:= fLeafIndex.Value;
end;

function TBPlusTree<K, V>.GetLast: TLeafIndex;
var
  Child: PNode;
  i: Integer;
begin
  if Count = 0 then raise EInvalidOperation.CreateRes(@SSequenceContainsNoElements);
  Child:= Root;
  for i:= 0 to height -1 do Child:= Child.Childern[Child.Count-1];
  Result.Init(Child, Child.Count - 1);
end;

// Todo: make sure Start <= Finish
// Todo: update the reference count for managed types.
function TBPlusTree<K, V>.GetRange(Start, Finish: K): TArray<V>;
var
  StartLeaf, FinishLeaf: TLeafIndex;
  WalkLeaf: PNode;
  Count, Offset: Integer;
begin
  FinishLeaf:= FindNode(Finish);
  StartLeaf:= FindNode(Start);
  if not(FinishLeaf.Found) then FinishLeaf:= GetLast;
  if not(FinishLeaf.Found) then StartLeaf:= GetFirst;
  // Count the number of values included.
  Count:= -StartLeaf.Index;
  WalkLeaf:= StartLeaf.Leaf;
  while WalkLeaf <> FinishLeaf.Leaf do begin
    Count:= Count + WalkLeaf.Count;
    WalkLeaf:= WalkLeaf.Next;
  end;
  Count:= Count + (FinishLeaf.Index + 1);
  SetLength(Result, Count);

  // Copy the data over.
  WalkLeaf:= StartLeaf.Leaf;
  Offset:= StartLeaf.Leaf.Count - StartLeaf.Index;
  Move(StartLeaf.Leaf.ValueP[StartLeaf.Index]^, Result[0], Offset * SizeOf(V));
  WalkLeaf:= StartLeaf.Leaf.Next;
  while WalkLeaf <> FinishLeaf.Leaf do begin
    Count:= WalkLeaf.Count;
    Move(WalkLeaf.ValueP[0]^, Result[Offset], Count * SizeOf(V));
    Offset:= Offset + Count;
    WalkLeaf:= WalkLeaf.Next;
  end;
  Move(WalkLeaf.ValueP[0]^, Result[Offset], (FinishLeaf.Index + 1) * SizeOf(V));
end;

function TBPlusTree<K, V>.Last: V;
begin
  fLeafIndex:= GetLast;
  Result:= fLeafIndex.Value;
end;

procedure TBPlusTree<K, V>.FixNodes(const KeyList: TPairStack; const FromKey, ToKey: K);
var
  Count: integer;
  Done: boolean;
  Node: PNode;
  index: integer;
  Pair: TNodePair;
begin
  for index:= KeyList.Count -1 downto 1 do begin
    Pair:= KeyList.Item[index];

    if not(Pair.Node.ReplaceKey(Pair.Index, FromKey, ToKey)) then Exit;
  end; { for }
end;

{ TBPlusTree<K, V>.TLeafIndex }

function TBPlusTree<K, V>.TLeafIndex.Found: Boolean;
begin
  Result:= Assigned(Leaf);
end;

class operator TBPlusTree<K, V>.TLeafIndex.Implicit(A: TLeafIndex): PNode;
begin
  Result:= a.Leaf;
end;

constructor TBPlusTree<K, V>.TLeafIndex.Init(Leaf: PNode; Index: Integer);
begin
  Self.Leaf:= Leaf;
  Self.Index:= index;
end;

function TBPlusTree<K, V>.TLeafIndex.Key: K;
begin
  Result:= Leaf.fKeys[index];
end;

function TBPlusTree<K, V>.TLeafIndex.Next: TLeafIndex;
begin
  Inc(index);
  if (index >= Leaf.Count) then begin
    Leaf:= Leaf.Next;
    index:= 0;
  end;
end;

function TBPlusTree<K, V>.TLeafIndex.Previous: TLeafIndex;
begin
  Dec(index);
  if (index = -1) then begin
    Leaf:= Leaf.Prev;
    if Assigned(Leaf) then index:= Leaf.Count - 1;
  end;
end;

function TBPlusTree<K, V>.TLeafIndex.Value: V;
begin
  Result:= Leaf.Values[index];
end;

{ TBPlusTree<K, V>.TTreeEnumerator }

function TBPlusTree<K, V>.TTreeEnumerator.Clone: TIterator<K>;
begin
  Result:= TTreeEnumerator.Create(fParent, fDirection);
end;

constructor TBPlusTree<K, V>.TTreeEnumerator.Create(const Parent: TBPlusTree<K, V>; Direction: TDirection);
begin
  inherited Create;
  fDirection:= Direction;
  fParent:= Parent;
  Reset;
end;

destructor TBPlusTree<K, V>.TTreeEnumerator.Destroy;
begin
  inherited;
end;

function TBPlusTree<K, V>.TTreeEnumerator.GetCurrent: K;
begin
  Result:= fLeafIndex.Key;
end;

function TBPlusTree<K, V>.TTreeEnumerator.MoveNext: Boolean;
begin
  case fDirection of
    FromBeginning: fLeafIndex.Next;
    FromEnd: fLeafIndex.Previous;
  end;
  Result:= fLeafIndex.Found;
end;

procedure TBPlusTree<K, V>.TTreeEnumerator.Reset;
begin
  if fDirection = FromBeginning then begin
    fLeafIndex:= fParent.GetFirst;
    Dec(fLeafIndex.Index);
  end else begin
    fLeafIndex:= fParent.GetLast;
    Inc(fLeafIndex.Index);
  end;
end;

{ TBPlusTree<K, V>.TNodePair<N, I> }

function TBPlusTree<K, V>.TNodePair<N, I>.Init(const Node: N; const Index: I): TNodePair<N, I>;
begin
  fNode:= Node;
  fIndex:= index;
  Result:= Self;
end;

end.
