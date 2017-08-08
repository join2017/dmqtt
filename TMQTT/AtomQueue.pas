unit AtomQueue;

interface

Uses
  SysUtils,
  SyncObjs;

Type
  TAtomFIFO = Class
  Protected
    FWritePtr: Integer;
    FReadPtr: Integer;
    FCount:Integer;
    FHighBound:Integer;
    FisEmpty:Integer;
    FData: array of Pointer;
    function GetSize:Integer;
  Public
    procedure Push(Item: Pointer);
    function Pop: Pointer;
    Constructor Create(Size: Integer); Virtual;
    Destructor Destroy; Override;
    Procedure Empty;
    property Size: Integer read GetSize;
    property UsedCount:Integer read FCount;
  End;

Implementation

//创建队列，大小必须是2的幂，需要开辟足够大的队列，防止队列溢出

Constructor TAtomFIFO.Create(Size: Integer);
var
  i:NativeInt;
  OK:Boolean;
Begin
  Inherited Create;
  OK:=(Size and (Size-1)=0);

  if not OK then raise Exception.Create('FIFO长度必须大于等于256并为2的幂');

  try
    SetLength(FData, Size);
    FHighBound:=Size-1;
  except
    Raise Exception.Create('FIFO申请内存失败');
  end;
End;

Destructor TAtomFIFO.Destroy;
Begin
  SetLength(FData, 0);
  Inherited;
End;

procedure TAtomFIFO.Empty;
begin
  while (TInterlocked.Exchange(FReadPtr, 0)<>0) and
  (TInterlocked.Exchange(FWritePtr, 0)<>0) and
  (TInterlocked.Exchange(FCount, 0)<>0)
  do;
end;

function TAtomFIFO.GetSize: Integer;
begin
  Result:=FHighBound+1;
end;

procedure TAtomFIFO.Push(Item:Pointer);
var
  N:Integer;
begin
  if Item=nil then Exit;
  N:=TInterlocked.Increment(FWritePtr) and FHighBound;
  FData[N]:=Item;
  TInterlocked.Increment(FCount);
end;

Function TAtomFIFO.Pop:Pointer;
var
  N:Integer;
begin
  if TInterlocked.Decrement(FCount)<0 then
  begin
    TInterlocked.Increment(FCount);
    Result:=nil;
  end
  else
  begin
    N:=TInterlocked.Increment(FReadPtr) and FHighBound;
    //假设线程A调用了Push,并且正好是第1个push，
    //执行了N:=TInterlocked.Increment(FWritePtr) and FHighBound,
    //还没执行FData[N]:=Item, 被切换到其他线程
    //此时假设线程B调用了Push，并且正好是第2个push,并且执行完毕，这样出现FCount=1,
    //第2个Item不为空，而第一个Item还是nil（线程A还没执行赋值）
    //假设线程C执行Pop，由于Count>0（线程B的作用）所以可以执行到这里，但此时FData[N]=nil（线程A还没执行赋值），
    //因此线程C要等待线程A完成FData[N]:=Item后，才能取走FData[N]
    //出现这种情况的概率应该比较小，基本上不会浪费太多CPU
    while FData[N]=nil do Sleep(1);
    Result:=FData[N];

    FData[N]:=nil;
  end;
end;

End.
