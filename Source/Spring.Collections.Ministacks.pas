unit Spring.Collections.Ministacks;

interface

const
  DefaultSize = 31;

type
  /// <summary>
  /// The ministack stores 31 elements on the system's stack.
  /// It is coded for raw speed.
  /// The stack is safe for holding managed types
  /// It does not do range checking, other than through Assertions at debug time
  /// </summary>
  TMiniStack<T> = record
{$IFDEF DEBUG}
  strict private
    function capacity: Integer;
{$ENDIF}
  private
    SP: Integer;
{$IFDEF CPUX64}
    Filler: integer; // Keep array aligned
{$ENDIF}
{$IFDEF DEBUG}
    HeapFlag: TGUID;
    HeapSize: Integer;
{$ENDIF}
    Items: array[0..DefaultSize - 1] of T;
    function GetItem(index: Integer): T; inline;
  public
    procedure Free;
    /// <summary>
    /// Initializes the stack.
    /// Must be called before the stack can be used.
    /// </summary>
    procedure Init; inline;
    function Pop: T; inline;
    procedure Push(const Item: T); inline;
    /// <summary>
    /// Returns the top item on the stack, does not alter the stack pointer.
    /// </summary>
    /// <returns></returns>
    function Peek: T; inline;
    function IsEmpty: Boolean; inline;
    /// <summary>
    /// Allows the stack to be accessed as a read-only array.
    /// </summary>
    property Item[index: Integer]: T read GetItem;
    property Count: integer read SP;
  end;

  MiniStack<T> = class
  public type
    PStack = ^Stack;
    Stack = TMiniStack<T>;
  public
    /// <summary>
    /// Creates new ministack on the heap.
    /// </summary>
    /// <param name="Size">The maximum number of elements the stack can hold</param>
    /// <returns>Pointer to the newly created stack.</returns>
    /// <remarks>
    /// Do not create and destroy a Ministack in a loop, use the stack based Ministack instead.
    /// You can increase the constant DefaultSize (must be a true constant) if you need a bigger
    /// stack.
    /// </remarks>
    class function Create(Size: integer = DefaultSize): PStack;
  end;

{$IFDEF DEBUG}
const
  MagicHeapFlag: TGUID = '{EF227045-27A9-4EF3-99E3-9D279D58F9A0}';
  FreedAlreadyFlag: TGUID = '{A76BBA2F-09C5-44B7-81BF-3C8869FB8D80}';
{$ENDIF}

implementation

uses
  System.SysUtils;

{ TMiniStack<T> }

procedure TMiniStack<T>.Init;
var
  i: Integer;
begin
  SP:= 0;
end;

class function MiniStack<T>.Create(Size: integer = DefaultSize): PStack;
begin
  Result:= AllocMem(SizeOf(TMiniStack<T>) - (DefaultSize * SizeOf(T)) + (Size * SizeOf(T)));
{$IFDEF DEBUG}
  Result.HeapFlag:= MagicHeapFlag;
  Result.HeapSize:= Size;
{$ENDIF}
end;

{$IFDEF DEBUG}
function TMiniStack<T>.capacity: Integer;
begin
  if HeapFlag = MagicHeapFlag then begin
    Result:= HeapSize;
  end
  else Result:= DefaultSize;
end;
{$ENDIF}

procedure TMiniStack<T>.Free;
begin
{$IFDEF DEBUG}
  Assert((HeapFlag = MagicHeapFlag) or (HeapFlag = FreedAlreadyFlag),
    'Do not call free on stack based MiniStacks');
  Assert((HeapFlag <> FreedAlreadyFlag), 'This stack has already been freed');
{$ENDIF}
  Finalize(Items, count);
  FreeMem(@Self);
end;

function TMiniStack<T>.GetItem(index: Integer): T;
begin
  Assert((index >= 0) and (index < Count),
    Format('Trying to get item #%d, but there are only %d items on the stack',[index, count]));
  Result:= Items[index];
end;

function TMiniStack<T>.IsEmpty: Boolean;
begin
  Result:= (SP = 0);
end;

function TMiniStack<T>.Pop: T;
begin
  Assert(SP > 0, 'Stack underflow');
  Dec(SP);
  Result:= Items[SP];
end;

function TMiniStack<T>.Peek: T;
begin
  Assert(SP > 0, 'You cannot peek at an empty stack');
  Result:= Items[SP-1];
end;

procedure TMiniStack<T>.Push(const Item: T);
begin
  Items[SP]:= Item;
  Inc(SP);
{$IFDEF DEBUG}
  Assert(SP <= Capacity, 'Stack overflow');
{$ENDIF}
end;

end.
