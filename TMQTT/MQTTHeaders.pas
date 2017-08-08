unit MQTTHeaders;

interface

uses
  SysUtils,
  Types,
  DateUtils,
  strUtils,
  Generics.Collections,

  Classes;

type

  TMQTTMessageType = (Reserved0, // 0	Reserved
    CONNECT, // 1	Client request to connect to Broker
    CONNACK, // 2	Connect Acknowledgment
    PUBLISH, // 3	Publish message
    PUBACK, // 4	Publish Acknowledgment
    PUBREC, // 5	Publish Received (assured delivery part 1)
    PUBREL, // 6	Publish Release (assured delivery part 2)
    PUBCOMP, // 7	Publish Complete (assured delivery part 3)
    SUBSCRIBE, // 8	Client Subscribe request
    SUBACK, // 9	Subscribe Acknowledgment
    UNSUBSCRIBE, // 10	Client Unsubscribe request
    UNSUBACK, // 11	Unsubscribe Acknowledgment
    PINGREQ, // 12	PING Request
    PINGRESP, // 13	PING Response
    DISCONNECT, // 14	Client is Disconnecting
    Reserved15 // 15 Reserved
    );

  TMQTTRecvState = (FixedHeaderByte, RemainingLength, Data);

  {
    bit	    7	6	5	4	      3	        2	1	      0
    byte 1	Message Type	DUP flag	QoS level	RETAIN
    byte 2	Remaining Length
  }
  TMQTTFixedHeader = packed record
  private
    function GetBits(const aIndex: Integer): Integer;
    procedure SetBits(const aIndex: Integer; const aValue: Integer);
  public
    Flags: Byte;
    property Retain: Integer index $0001 read GetBits write SetBits;
    // 1 bits at offset 0
    property QoSLevel: Integer index $0102 read GetBits write SetBits;
    // 2 bits at offset 1
    property Duplicate: Integer index $0301 read GetBits write SetBits;
    // 1 bits at offset 3
    property MessageType: Integer index $0404 read GetBits write SetBits;
    // 4 bits at offset 4
  end;

  {
    Description	    7	6	5	4	3	2	1	0
    Connect Flags
    byte 10	        1	1	0	0	1	1	1	0
    Username Flag (1)
    Password Flag (1)
    Will RETAIN   (0)
    Will QoS      (01)
    Will flag     (1)
    Clean Session (1)
    Reserved      (0)
  }
  TMQTTConnectFlags = packed record
  private
    function GetBits(const aIndex: Integer): Integer;
    procedure SetBits(const aIndex: Integer; const aValue: Integer);
  public
    Flags: Byte;
    property Reserved: Integer index $0001 read GetBits write SetBits; // 1 bit  at offset  0
    property CleanSession: Integer index $0101 read GetBits write SetBits; // 1 bit  at offset  1
    property WillFlag: Integer index $0201 read GetBits write SetBits; // 1 bit  at offset  2
    property WillQoS: Integer index $0302 read GetBits write SetBits; // 2 bits at offset 3-4
    property WillRetain: Integer index $0501 read GetBits write SetBits; // 1 bit  at offset  5
    property PasswordFlag: Integer index $0601 read GetBits write SetBits; // 1 bit  at offset  6
    property UserNameFlag: Integer index $0701 read GetBits write SetBits; // 1 bit  at offset  7

  end;

  TUnparsedMsg = record
  public
    FixedHeader: Byte;
    RL: TBytes; // remianlength
    Data: TBytes;
  end;

  PUnparsedMsg = ^TUnparsedMsg;

  TRevMsg = record
  public
    Bytes: TBytes;
    Len: Integer;
  end;

  PRevMsg = ^TRevMsg;

  TConnAckEvent = procedure(Sender: TObject; ReturnCode: Integer) of object;
  TPublishEvent = procedure(Sender: TObject; topic: string; PackageId: Integer; payload: string; QOS: Integer)
    of object;

  TPublishBytesEvent = procedure(Sender: TObject; topic: string; PackageId: Integer; payload: TBytes;
    QOS: Integer) of object;

  TPingRespEvent = procedure(Sender: TObject) of object;
  TPingReqEvent = procedure(Sender: TObject) of object;
  TSubAckEvent = procedure(Sender: TObject; MessageID: Integer; GrantedQoS: Array of Integer) of object;
  TUnSubAckEvent = procedure(Sender: TObject; MessageID: Integer) of object;
  TPubAckEvent = procedure(Sender: TObject; MessageID: Integer) of object;
  TPubRelEvent = procedure(Sender: TObject; MessageID: Integer) of object;
  TPubRecEvent = procedure(Sender: TObject; MessageID: Integer) of object;
  TPubCompEvent = procedure(Sender: TObject; MessageID: Integer) of object;

  TSubEvent = procedure(Sender: TObject; MessageID: Integer; Topics: TDictionary<String, Integer>) of object;
  TUnSubEvent = procedure(Sender: TObject; topic: string; MessageID: Integer; Topics: TDictionary<String, Integer>)
    of object;

  TUnSubSendEvent = procedure(Sender: TObject; MessageID: Integer; Topics: TStringList) of object;

  TConnectEvent = procedure(Sender: TObject; IP: string; Port: Integer; isConnected: boolean) of object;

  TMQTTVariableHeader = class
  private
    FBytes: TBytes;
  protected
    procedure AddField(AByte: Byte); overload;
    procedure AddField(ABytes: TBytes); overload;
    procedure ClearField;
  public
    constructor Create;
    function ToBytes: TBytes; virtual;
  end;

  TMQTTConnectVarHeader = class(TMQTTVariableHeader)
  const
    PROTOCOL_NAME = 'MQTT';
    PROTOCOL_VER = 4;
  private
    FConnectFlags: TMQTTConnectFlags;
    FKeepAlive: Integer;
    function rebuildHeader: boolean;
    procedure setupDefaultValues;
    function get_CleanSession: Integer;
    function get_QoSLevel: Integer;
    function get_Retain: Integer;
    procedure set_CleanSession(const Value: Integer);
    procedure set_QoSLevel(const Value: Integer);
    procedure set_Retain(const Value: Integer);
    function get_WillFlag: Integer;
    procedure set_WillFlag(const Value: Integer);
    function get_UsernameFlag: Integer;
    procedure set_UsernameFlag(const Value: Integer);
    function get_PasswordFlag: Integer;
    procedure set_PasswordFlag(const Value: Integer);
    function get_Reserved: Integer;
    procedure set_Reserved(const Value: Integer);
  public
    constructor Create(AKeepAlive: Integer); overload;
    constructor Create; overload;
    constructor Create(ACleanSession: boolean); overload;
    property KeepAlive: Integer read FKeepAlive write FKeepAlive;
    property CleanSession: Integer read get_CleanSession write set_CleanSession;
    property QoSLevel: Integer read get_QoSLevel write set_QoSLevel;
    property Retain: Integer read get_Retain write set_Retain;
    property UserNameFlag: Integer read get_UsernameFlag write set_UsernameFlag;
    property PasswordFlag: Integer read get_PasswordFlag write set_PasswordFlag;
    property WillFlag: Integer read get_WillFlag write set_WillFlag;
    property Reserved: Integer read get_Reserved write set_Reserved;
    function ToBytes: TBytes; override;
  end;

  TMQTTPublishVarHeader = class(TMQTTVariableHeader)
  private
    FTopic: String;
    FQoSLevel: Integer;
    FMessageID: Integer;
    function get_MessageID: Integer;
    function get_QoSLevel: Integer;
    procedure set_MessageID(const Value: Integer);
    procedure set_QoSLevel(const Value: Integer);
    function get_Topic: String;
    procedure set_Topic(const Value: String);
    procedure rebuildHeader;
  public
    constructor Create(QoSLevel: Integer); overload;
    property MessageID: Integer read get_MessageID write set_MessageID;
    property QoSLevel: Integer read get_QoSLevel write set_QoSLevel;
    property topic: String read get_Topic write set_Topic;
    function ToBytes: TBytes; override;

  end;

  TMQTTPubAckVarHeader = class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    function get_MessageID: Integer;
    procedure set_MessageID(const Value: Integer);
    procedure rebuildHeader;
  public
    constructor Create(MessageID: Integer); overload;
    property MessageID: Integer read get_MessageID write set_MessageID;
    function ToBytes: TBytes; override;
  end;

  TMQTTPubRecVarHeader = class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    function get_MessageID: Integer;
    procedure set_MessageID(const Value: Integer);
    procedure rebuildHeader;
  public
    constructor Create(MessageID: Integer); overload;
    property MessageID: Integer read get_MessageID write set_MessageID;
    function ToBytes: TBytes; override;
  end;

  TMQTTPubRelVarHeader = class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    function get_MessageID: Integer;
    procedure set_MessageID(const Value: Integer);
    procedure rebuildHeader;
  public
    constructor Create(MessageID: Integer); overload;
    property MessageID: Integer read get_MessageID write set_MessageID;
    function ToBytes: TBytes; override;
  end;

  TMQTTPubCompVarHeader = class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    function get_MessageID: Integer;
    procedure set_MessageID(const Value: Integer);
    procedure rebuildHeader;
  public
    constructor Create(MessageID: Integer); overload;
    property MessageID: Integer read get_MessageID write set_MessageID;
    function ToBytes: TBytes; override;
  end;

  TMQTTSubscribeVarHeader = class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    function get_MessageID: Integer;
    procedure set_MessageID(const Value: Integer);
  public
    constructor Create(MessageID: Integer); overload;
    property MessageID: Integer read get_MessageID write set_MessageID;
    function ToBytes: TBytes; override;
  end;

  TMQTTUnsubscribeVarHeader = class(TMQTTVariableHeader)
  private
    FMessageID: Integer;
    function get_MessageID: Integer;
    procedure set_MessageID(const Value: Integer);
  public
    constructor Create(MessageID: Integer); overload;
    property MessageID: Integer read get_MessageID write set_MessageID;
    function ToBytes: TBytes; override;
  end;

  TMQTTPayload = class
  private
    FContents: TStringList;
    FContainsIntLiterals: boolean;
    FPublishMessage: boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function ToBytes: TBytes; overload;
    function ToBytes(WithIntegerLiterals: boolean): TBytes; overload;
    property Contents: TStringList read FContents;
    property ContainsIntLiterals: boolean read FContainsIntLiterals write FContainsIntLiterals;
    property PublishMessage: boolean read FPublishMessage write FPublishMessage;
  end;

  TMQTTMessage = class
  private
    FRemainingLength: Integer;
  public
    FixedHeader: TMQTTFixedHeader;
    VariableHeader: TMQTTVariableHeader;
    payload: TMQTTPayload;
    constructor Create;
    destructor Destroy; override;
    function ToBytes: TBytes;
    property RemainingLength: Integer read FRemainingLength;
  end;

  TMQTTBytesMessage = class
  private
    FRemainingLength: Integer;
  public
    FixedHeader: TMQTTFixedHeader;
    VariableHeader: TMQTTVariableHeader;
    payload: TBytes;
    constructor Create;
    destructor Destroy; override;
    function ToBytes: TBytes;
    property RemainingLength: Integer read FRemainingLength;
  end;

  TMQTTBytes = packed Record
  public
    MessageID: Word; // 2Byte
    PushCount: Cardinal; // 4Byte  resend count
    TimeOut: UInt64; // 8Byte TimeOut
    Bytes: TBytes; // send content
  End;

  PMQTTBytes = ^TMQTTBytes;

  TMQTTUtilities = class
  public
    class function UTF8EncodeToBytes(AStrToEncode: AnsiString): TBytes;
    class function UTF8EncodeToBytesNoLength(AStrToEncode: AnsiString): TBytes;
    class function RLIntToBytes(ARlInt: Integer): TBytes;
    class function IntToMSBLSB(ANumber: Word): TBytes;

    class function MSBLSBToInt(ALengthBytes: TBytes): Integer;
    class function RLBytesToInt(ARlBytes: TBytes): Integer;

    class function ValidateQos(RequestQoS: Integer): boolean;
  end;

procedure AppendBytes(var DestArray: TBytes; const NewBytes: TBytes);
procedure AppendToByteArray(ASourceBytes: TBytes; var ATargetBytes: TBytes); overload;
procedure AppendToByteArray(ASourceByte: Byte; var ATargetBytes: TBytes); overload;

function UInt16ToMSBLSB(ANumber: Uint16): TBytes;
function MSBLSBToWord(ALengthBytes: TBytes): Uint16;
function UInt32ToMSBLSB(ANumber: Cardinal): TBytes;
function MSBLSBToUInt32(ALengthBytes: TBytes): Uint32;
function UInt64ToMSBLSB(ANumber: UInt64): TBytes;
function MSBLSBToUInt64(ALengthBytes: TBytes): UInt64;
function GetGUIDStr: string;
procedure searchfile(path: string; var FileNameList: TStringList);

implementation

// 16bit=Word BigEnd
function UInt16ToMSBLSB(ANumber: Uint16): TBytes;
begin
  SetLength(Result, 2);
  Result[0] := Byte(ANumber shr 8);
  Result[1] := Byte(ANumber)
end;

// bytes =>Uint16
function MSBLSBToWord(ALengthBytes: TBytes): Uint16;
begin
  Result := Uint16(ALengthBytes[1]) or Uint16(ALengthBytes[0]) shl 8;
end;

// 32bit=Word BigEnd
function UInt32ToMSBLSB(ANumber: Cardinal): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := Byte(ANumber shr 24);
  Result[1] := Byte(ANumber shr 16);
  Result[2] := Byte(ANumber shr 8);
  Result[3] := Byte(ANumber)
end;

function MSBLSBToUInt32(ALengthBytes: TBytes): Uint32;
begin
  Result := Uint32(ALengthBytes[3]) or Uint32(ALengthBytes[2]) shl 8 or Uint32(ALengthBytes[1]) shl 16 or
    Uint32(ALengthBytes[0]) shl 24;
end;

// 64bit=Word BigEnd
function UInt64ToMSBLSB(ANumber: UInt64): TBytes;
begin
  SetLength(Result, 8);
  Result[0] := Byte(ANumber shr 56);
  Result[1] := Byte(ANumber shr 48);
  Result[2] := Byte(ANumber shr 40);
  Result[3] := Byte(ANumber shr 32);
  Result[4] := Byte(ANumber shr 24);
  Result[5] := Byte(ANumber shr 16);
  Result[6] := Byte(ANumber shr 8);
  Result[7] := Byte(ANumber)
end;

function MSBLSBToUInt64(ALengthBytes: TBytes): UInt64;
begin

  Result := UInt64(ALengthBytes[7]) or UInt64(ALengthBytes[6]) shl 8 or UInt64(ALengthBytes[5]) shl 16 or
    UInt64(ALengthBytes[4]) shl 24 or UInt64(ALengthBytes[3]) shl 32 or UInt64(ALengthBytes[2]) shl 40 or
    UInt64(ALengthBytes[1]) shl 48 or UInt64(ALengthBytes[0]) shl 56

end;

function GetGUIDStr: string;
var
  guid: TGUID;
begin
  CreateGUID(guid);
  Result := GUIDToString(guid);
  Result := AnsiReplaceStr(Result, '-', '');
  Result := AnsiReplaceStr(Result, '{', '');
  Result := AnsiReplaceStr(Result, '}', '');
end;

procedure searchfile(path: string; var FileNameList: TStringList); // 注意,path后面要有'\';
var
  SearchRec: TSearchRec;
  found: Integer;
begin
  found := FindFirst(path + '*.*', faAnyFile, SearchRec);
  while found = 0 do
  begin
    if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and (SearchRec.Attr <> faDirectory) then
      FileNameList.Add(SearchRec.Name);
    found := FindNext(SearchRec);
  end;
  FindClose(SearchRec);
end;

function GetDWordBits(const Bits: Byte; const aIndex: Integer): Integer;
begin
  Result := (Bits shr (aIndex shr 8)) // offset
    and ((1 shl Byte(aIndex)) - 1); // mask
end;

procedure SetDWordBits(var Bits: Byte; const aIndex: Integer; const aValue: Integer);
var
  Offset: Byte;
  Mask: Integer;
begin
  Mask := ((1 shl Byte(aIndex)) - 1);
  Assert(aValue <= Mask);

  Offset := aIndex shr 8;
  Bits := (Bits and (not(Mask shl Offset))) or DWORD(aValue shl Offset);
end;

class function TMQTTUtilities.IntToMSBLSB(ANumber: Word): TBytes;
begin
  SetLength(Result, 2);
  Result[0] := ANumber div 256;
  Result[1] := ANumber mod 256;
end;

class function TMQTTUtilities.MSBLSBToInt(ALengthBytes: TBytes): Integer;
begin
  Assert(ALengthBytes <> nil, 'Must not pass nil to this method');
  Assert(Length(ALengthBytes) = 2, 'The MSB-LSB 2 bytes structure must be 2 Bytes in length');

  Result := ALengthBytes[0] shl 8;
  Result := Result + ALengthBytes[1];
end;

class function TMQTTUtilities.RLBytesToInt(ARlBytes: TBytes): Integer;
var
  multi: Integer;
  i: Integer;
  digit: Byte;
begin
  // Assert(ARlBytes <> nil, 'Must not pass nil to this method');
  if (ARlBytes = nil) or (Length(ARlBytes) = 0) then
  begin
    Result := 0;
    exit;
  end;

  multi := 1;
  i := 0;
  Result := 0;

  if ((Length(ARlBytes) > 0) and (Length(ARlBytes) <= 4)) then
  begin
    repeat
      digit := ARlBytes[i];
      Result := Result + (digit and 127) * multi;
      multi := multi * 128;
      Inc(i);
    until ((digit and 128) = 0);
  end;
end;

procedure AppendBytes(var DestArray: TBytes; const NewBytes: TBytes);
var
  DestLen: Integer;
begin
  if Length(NewBytes) > 0 then
  begin
    DestLen := Length(DestArray);
    SetLength(DestArray, DestLen + Length(NewBytes));
    Move(NewBytes[0], DestArray[DestLen], Length(NewBytes));
  end;
end;

{ MSBLSBToInt is in the MQTTRecvThread unit }

class function TMQTTUtilities.UTF8EncodeToBytes(AStrToEncode: AnsiString): TBytes;
var
  v: Word;

begin
  { This is a UTF-8 hack to give 2 Bytes of Length MSB-LSB followed by a Single-byte
    per character String. }

  v := Length(AStrToEncode);
  SetLength(Result, v + 2);
  Result[0] := Byte(v shr 8);
  Result[1] := Byte(v);
  Move(AStrToEncode[1], Result[2], Length(AStrToEncode));

end;

class function TMQTTUtilities.UTF8EncodeToBytesNoLength(AStrToEncode: AnsiString): TBytes;

begin
  SetLength(Result, Length(AStrToEncode));
  Move(AStrToEncode[1], Result[0], Length(AStrToEncode));

end;

class function TMQTTUtilities.ValidateQos(RequestQoS: Integer): boolean;
begin
  Result := false;
  if (RequestQoS >= 0) and (RequestQoS <= 2) then
    Result := true;
end;

procedure AppendToByteArray(ASourceBytes: TBytes; var ATargetBytes: TBytes); overload;
var
  iUpperBnd: Integer;
begin

  if Length(ASourceBytes) > 0 then
  begin
    iUpperBnd := Length(ATargetBytes);
    SetLength(ATargetBytes, iUpperBnd + Length(ASourceBytes));
    Move(ASourceBytes[0], ATargetBytes[iUpperBnd], Length(ASourceBytes));
  end;
end;

procedure AppendToByteArray(ASourceByte: Byte; var ATargetBytes: TBytes); overload;
var
  iUpperBnd: Integer;
begin
  iUpperBnd := Length(ATargetBytes);
  SetLength(ATargetBytes, iUpperBnd + 1);
  Move(ASourceByte, ATargetBytes[iUpperBnd], 1);
end;

class function TMQTTUtilities.RLIntToBytes(ARlInt: Integer): TBytes;
var
  byteindex: Integer;
  digit: Integer;
begin
  SetLength(Result, 1);
  byteindex := 0;
  while (ARlInt > 0) do
  begin
    digit := ARlInt mod 128;
    ARlInt := ARlInt div 128;
    if ARlInt > 0 then
    begin
      digit := digit or $80;
    end;
    Result[byteindex] := digit;
    if ARlInt > 0 then
    begin
      Inc(byteindex);
      SetLength(Result, Length(Result) + 1);
    end;
  end;
end;

{ TMQTTFixedHeader }

function TMQTTFixedHeader.GetBits(const aIndex: Integer): Integer;
begin
  Result := GetDWordBits(Flags, aIndex);
end;

procedure TMQTTFixedHeader.SetBits(const aIndex, aValue: Integer);
begin
  SetDWordBits(Flags, aIndex, aValue);
end;

{ TMQTTMessage }

{ TMQTTVariableHeader }

procedure TMQTTVariableHeader.AddField(AByte: Byte);
var
  DestUpperBnd: Integer;
begin
  DestUpperBnd := Length(FBytes);
  SetLength(FBytes, DestUpperBnd + SizeOf(AByte));
  Move(AByte, FBytes[DestUpperBnd], SizeOf(AByte));
end;

procedure TMQTTVariableHeader.AddField(ABytes: TBytes);
var
  DestUpperBnd: Integer;
begin
  DestUpperBnd := Length(FBytes);
  SetLength(FBytes, DestUpperBnd + Length(ABytes));
  Move(ABytes[0], FBytes[DestUpperBnd], Length(ABytes));
end;

procedure TMQTTVariableHeader.ClearField;
begin
  SetLength(FBytes, 0);
end;

constructor TMQTTVariableHeader.Create;
begin
end;

function TMQTTVariableHeader.ToBytes: TBytes;
begin
  Result := FBytes;
end;

{ TMQTTConnectVarHeader }

constructor TMQTTConnectVarHeader.Create(ACleanSession: boolean);
begin
  inherited Create;
  setupDefaultValues;
  Self.FConnectFlags.CleanSession := Ord(ACleanSession);
end;

function TMQTTConnectVarHeader.get_CleanSession: Integer;
begin
  Result := Self.FConnectFlags.CleanSession;
end;

function TMQTTConnectVarHeader.get_PasswordFlag: Integer;
begin
  Result := Self.FConnectFlags.PasswordFlag;
end;

function TMQTTConnectVarHeader.get_QoSLevel: Integer;
begin
  Result := Self.FConnectFlags.WillQoS;
end;

function TMQTTConnectVarHeader.get_Reserved: Integer;
begin
  Result := Self.FConnectFlags.Reserved;
end;

function TMQTTConnectVarHeader.get_Retain: Integer;
begin
  Result := Self.FConnectFlags.WillRetain;
end;

function TMQTTConnectVarHeader.get_UsernameFlag: Integer;
begin
  Result := Self.FConnectFlags.UserNameFlag;
end;

function TMQTTConnectVarHeader.get_WillFlag: Integer;
begin
  Result := Self.FConnectFlags.WillFlag;
end;

constructor TMQTTConnectVarHeader.Create(AKeepAlive: Integer);
begin
  inherited Create;
  setupDefaultValues;
  Self.FKeepAlive := AKeepAlive;
end;

constructor TMQTTConnectVarHeader.Create;
begin
  inherited Create;
  setupDefaultValues;
end;

function TMQTTConnectVarHeader.rebuildHeader: boolean;
begin
  ClearField;
  AddField(TMQTTUtilities.UTF8EncodeToBytes(Self.PROTOCOL_NAME));
  AddField(Byte(Self.PROTOCOL_VER));
  AddField(FConnectFlags.Flags);
  AddField(TMQTTUtilities.IntToMSBLSB(FKeepAlive));
  Result := true;
end;

// ( byte(FConnectFlags.CleanSession) shl 1) or (byte(FConnectFlags.WillFlag) shl 2) or (byte(FConnectFlags.WillQoS) shl 3)    or (byte(FConnectFlags.WillRetain) shl 5 ) or
// (byte(FConnectFlags.PasswordFlag) shl 6) or (byte(FConnectFlags.UserNameFlag ) shl 7);
procedure TMQTTConnectVarHeader.setupDefaultValues;
begin
  Self.FConnectFlags.Flags := 0;
  Self.FConnectFlags.CleanSession := 1;
  Self.FConnectFlags.WillQoS := 1;
  Self.FConnectFlags.WillRetain := 0;
  Self.FConnectFlags.WillFlag := 1;
  Self.FConnectFlags.UserNameFlag := 1;
  Self.FConnectFlags.PasswordFlag := 1;
  Self.FConnectFlags.Reserved := 0;
  Self.FKeepAlive := 60;
end;

procedure TMQTTConnectVarHeader.set_CleanSession(const Value: Integer);
begin
  Self.FConnectFlags.CleanSession := Value;
end;

procedure TMQTTConnectVarHeader.set_PasswordFlag(const Value: Integer);
begin
  Self.FConnectFlags.UserNameFlag := Value;
end;

procedure TMQTTConnectVarHeader.set_QoSLevel(const Value: Integer);
begin
  Self.FConnectFlags.WillQoS := Value;
end;

procedure TMQTTConnectVarHeader.set_Reserved(const Value: Integer);
begin
  Self.FConnectFlags.Reserved := Value;
end;

procedure TMQTTConnectVarHeader.set_Retain(const Value: Integer);
begin
  Self.FConnectFlags.WillRetain := Value;
end;

procedure TMQTTConnectVarHeader.set_UsernameFlag(const Value: Integer);
begin
  Self.FConnectFlags.PasswordFlag := Value;
end;

procedure TMQTTConnectVarHeader.set_WillFlag(const Value: Integer);
begin
  Self.FConnectFlags.WillFlag := Value;
end;

function TMQTTConnectVarHeader.ToBytes: TBytes;
begin
  Self.rebuildHeader;
  Result := FBytes;
end;

{ TMQTTConnectFlags }

function TMQTTConnectFlags.GetBits(const aIndex: Integer): Integer;
begin
  Result := GetDWordBits(Flags, aIndex);
end;

procedure TMQTTConnectFlags.SetBits(const aIndex, aValue: Integer);
begin
  SetDWordBits(Flags, aIndex, aValue);
end;

{ TMQTTPayload }

constructor TMQTTPayload.Create;
begin
  FContents := TStringList.Create();
  FContainsIntLiterals := false;
  FPublishMessage := false;
end;

destructor TMQTTPayload.Destroy;
begin
  FContents.Free;
  inherited;
end;

function TMQTTPayload.ToBytes(WithIntegerLiterals: boolean): TBytes;
var

  line: string;
  lineAsBytes: TBytes;
  lineAsInt: Integer;
begin
  SetLength(Result, 0);
  for line in FContents do
  begin
    // This is really nasty and needs refactoring into subclasses
    if PublishMessage then
    begin
      lineAsBytes := TMQTTUtilities.UTF8EncodeToBytesNoLength(AnsiString(line));
      AppendToByteArray(lineAsBytes, Result);
    end
    else
    begin
      if (WithIntegerLiterals and TryStrToInt(line, lineAsInt)) then
      begin
        AppendToByteArray(Lo(lineAsInt), Result);
      end
      else
      begin
        lineAsBytes := TMQTTUtilities.UTF8EncodeToBytes(AnsiString(line));
        AppendToByteArray(lineAsBytes, Result);
      end;
    end;
  end;
end;

function TMQTTPayload.ToBytes: TBytes;
begin
  Result := ToBytes(FContainsIntLiterals);
end;

{ TMQTTMessage }

constructor TMQTTMessage.Create;
begin
  inherited;
  // Fill our Fixed Header with Zeros to wipe any unintended noise.
  // FillChar(FixedHeader, SizeOf(FixedHeader), #0);
end;

destructor TMQTTMessage.Destroy;
begin
  if Assigned(VariableHeader) then
    VariableHeader.Free;
  if Assigned(payload) then
    payload.Free;
  inherited;
end;

function TMQTTMessage.ToBytes: TBytes;
var
  iRemainingLength: Integer;
  bytesRemainingLength: TBytes;
begin

  iRemainingLength := 0;
  if Assigned(VariableHeader) then
    iRemainingLength := iRemainingLength + Length(VariableHeader.ToBytes);
  if Assigned(payload) then
    iRemainingLength := iRemainingLength + Length(payload.ToBytes);

  FRemainingLength := iRemainingLength;
  bytesRemainingLength := TMQTTUtilities.RLIntToBytes(FRemainingLength);

  AppendToByteArray(FixedHeader.Flags, Result);
  AppendToByteArray(bytesRemainingLength, Result);
  if Assigned(VariableHeader) then
    AppendToByteArray(VariableHeader.ToBytes, Result);
  if Assigned(payload) then
    AppendToByteArray(payload.ToBytes, Result);

end;

{ TMQTTPublishVarHeader }

constructor TMQTTPublishVarHeader.Create(QoSLevel: Integer);
begin
  inherited Create;
  FQoSLevel := QoSLevel;
end;

function TMQTTPublishVarHeader.get_MessageID: Integer;
begin
  Result := FMessageID;
end;

function TMQTTPublishVarHeader.get_QoSLevel: Integer;
begin
  Result := FQoSLevel;
end;

function TMQTTPublishVarHeader.get_Topic: String;
begin
  Result := FTopic;
end;

procedure TMQTTPublishVarHeader.rebuildHeader;
begin
  ClearField;
  AddField(TMQTTUtilities.UTF8EncodeToBytes(FTopic));
  if (FQoSLevel > 0) then
  begin
    AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  end;
end;

procedure TMQTTPublishVarHeader.set_MessageID(const Value: Integer);
begin
  FMessageID := Value;
end;

procedure TMQTTPublishVarHeader.set_QoSLevel(const Value: Integer);
begin
  FQoSLevel := Value;
end;

procedure TMQTTPublishVarHeader.set_Topic(const Value: String);
begin
  FTopic := Value;
end;

function TMQTTPublishVarHeader.ToBytes: TBytes;
begin
  Self.rebuildHeader;
  Result := Self.FBytes;
end;

{ TMQTTSubscribeVarHeader }

constructor TMQTTSubscribeVarHeader.Create(MessageID: Integer);
begin
  inherited Create;
  FMessageID := MessageID;
end;

function TMQTTSubscribeVarHeader.get_MessageID: Integer;
begin
  Result := FMessageID;
end;

procedure TMQTTSubscribeVarHeader.set_MessageID(const Value: Integer);
begin
  FMessageID := Value;
end;

function TMQTTSubscribeVarHeader.ToBytes: TBytes;
begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
end;

{ TMQTTUnsubscribeVarHeader }

constructor TMQTTUnsubscribeVarHeader.Create(MessageID: Integer);
begin
  inherited Create;
  FMessageID := MessageID;
end;

function TMQTTUnsubscribeVarHeader.get_MessageID: Integer;
begin
  Result := FMessageID;
end;

procedure TMQTTUnsubscribeVarHeader.set_MessageID(const Value: Integer);
begin
  FMessageID := Value;
end;

function TMQTTUnsubscribeVarHeader.ToBytes: TBytes;
begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
  Result := FBytes;
end;

{ TMQTTPubAckVarHeader }

constructor TMQTTPubAckVarHeader.Create(MessageID: Integer);
begin
  inherited Create;
  FMessageID := MessageID;
end;

function TMQTTPubAckVarHeader.get_MessageID: Integer;
begin
  Result := FMessageID;
end;

procedure TMQTTPubAckVarHeader.rebuildHeader;
begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));

end;

procedure TMQTTPubAckVarHeader.set_MessageID(const Value: Integer);
begin
  FMessageID := Value;
end;

function TMQTTPubAckVarHeader.ToBytes: TBytes;
begin
  Self.rebuildHeader;
  Result := Self.FBytes;
end;

{ TMQTTPubRecVarHeader }

constructor TMQTTPubRecVarHeader.Create(MessageID: Integer);
begin
  inherited Create;
  FMessageID := MessageID;
end;

function TMQTTPubRecVarHeader.get_MessageID: Integer;
begin
  Result := FMessageID;
end;

procedure TMQTTPubRecVarHeader.rebuildHeader;
begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
end;

procedure TMQTTPubRecVarHeader.set_MessageID(const Value: Integer);
begin
  FMessageID := Value;
end;

function TMQTTPubRecVarHeader.ToBytes: TBytes;
begin
  Self.rebuildHeader;
  Result := Self.FBytes;
end;

{ TMQTTPubRelVarHeader }

constructor TMQTTPubRelVarHeader.Create(MessageID: Integer);
begin
  inherited Create;
  FMessageID := MessageID;
end;

function TMQTTPubRelVarHeader.get_MessageID: Integer;
begin
  Result := FMessageID;
end;

procedure TMQTTPubRelVarHeader.rebuildHeader;
begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
end;

procedure TMQTTPubRelVarHeader.set_MessageID(const Value: Integer);
begin
  FMessageID := Value;
end;

function TMQTTPubRelVarHeader.ToBytes: TBytes;
begin
  Self.rebuildHeader;
  Result := Self.FBytes;
end;

{ TMQTTPubCompVarHeader }

constructor TMQTTPubCompVarHeader.Create(MessageID: Integer);
begin
  inherited Create;
  FMessageID := MessageID;
end;

function TMQTTPubCompVarHeader.get_MessageID: Integer;
begin
  Result := FMessageID;
end;

procedure TMQTTPubCompVarHeader.rebuildHeader;
begin
  ClearField;
  AddField(TMQTTUtilities.IntToMSBLSB(FMessageID));
end;

procedure TMQTTPubCompVarHeader.set_MessageID(const Value: Integer);
begin
  FMessageID := Value;
end;

function TMQTTPubCompVarHeader.ToBytes: TBytes;
begin
  Self.rebuildHeader;
  Result := Self.FBytes;
end;

{ TMQTTBytesMessage }

constructor TMQTTBytesMessage.Create;
begin

end;

destructor TMQTTBytesMessage.Destroy;
begin
  if Assigned(VariableHeader) then
    VariableHeader.Free;
  SetLength(payload, 0);
  inherited;
end;

function TMQTTBytesMessage.ToBytes: TBytes;
var
  iRemainingLength: Integer;
  bytesRemainingLength: TBytes;
begin
  try
    iRemainingLength := 0;
    if Assigned(VariableHeader) then
      iRemainingLength := iRemainingLength + Length(VariableHeader.ToBytes);
    if Assigned(payload) then
      iRemainingLength := iRemainingLength + Length(payload);

    FRemainingLength := iRemainingLength;
    bytesRemainingLength := TMQTTUtilities.RLIntToBytes(FRemainingLength);

    AppendToByteArray(FixedHeader.Flags, Result);
    AppendToByteArray(bytesRemainingLength, Result);
    if Assigned(VariableHeader) then
      AppendToByteArray(VariableHeader.ToBytes, Result);
    if Assigned(payload) then
      AppendToByteArray(payload, Result);
  except
    on E: Exception do
      // log9.syslog.LogByTime('Error:' + E.Message);

  end;
end;

end.
