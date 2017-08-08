unit MQTT;

// -> publish()
// load(dll)->    config() -> start() -> subscribe()   ->stop() ->unload()
// -> unsubscribe()
{ .$DEFINE __SSL__ }
interface

uses
  SysUtils,
  Types,
  Classes,

  ExtCtrls,
  Generics.Collections,
  SyncObjs,

  AtomQueue,

  Net.CrossSocket,
{$IFDEF __SSL__}
  Net.CrossSslSocket,
{$IFDEF POSIX}
  Net.CrossSslDemoCert,
{$ENDIF}
{$ENDIF}
  Net.SocketAPI,
  System.IOUtils,
  DateUtils,
  MQTTHeaders;

const
  // Queue size  8388608
  QueueSize = 8 * 1024;
  MaxCacheFileSize = 500;

type
{$IF not declared(TBytes)}
  TBytes = array of Byte;
{$IFEND}
  TMyProce = procedure of object;
  TProcessComeMsgThread = class;
  TProcessRevMsgParseThread = class;


  TMQTT = class
  private
    { Private Declarations }
    FClientID: String;
    FHostname: String;
    FPort: Integer;
    FMessageID: Integer;
    FisConnected: boolean;

    FProcessThread: TProcessComeMsgThread;

    FProcessRevMsgParseThread: TProcessRevMsgParseThread;

    FQueue, FRevQueue: TAtomFIFO;

    FWillMsg: String;
    FWillTopic: String;
    FUsername: String;
    FPassword: String;

    FSocket: {$IFDEF __SSL__}TCrossSslSocket{$ELSE}TCrossSocket{$ENDIF};

    FKeepAliveTimer: TTimer;
    FSessionTimer: TTimer;

    ReceiveBuffer: TBytes;

    FSessionList: TThreadList<PMQTTBytes>;

    // Event Fields
    FConnAckEvent: TConnAckEvent;
    FPublishEvent: TPublishEvent;
    FPublishBytesEvent: TPublishBytesEvent;

    FPingRespEvent: TPingRespEvent;
    FPingReqEvent: TPingReqEvent;
    FSubAckEvent: TSubAckEvent;
    FUnSubAckEvent: TUnSubAckEvent;
    FPubAckEvent: TPubAckEvent;
    FPubRelEvent: TPubRelEvent;
    FPubRecEvent: TPubRecEvent;
    FPubCompEvent: TPubCompEvent;

    /// ///send log record /////////////////
    FPublishSendEvent: TPublishEvent;
    FPubAckSendEvent: TPubAckEvent;
    FPubRelSendEvent: TPubRelEvent;
    FPubRecSendEvent: TPubRecEvent;
    FPubCompSendEvent: TPubCompEvent;

    FSubSendEvent: TSubEvent;
    FUnSubSendEvent: TUnSubSendEvent;
    FConnectEvent: TConnectEvent;
    // default is 60second
    FKeepAlive: Cardinal;

    /// ///////////////////////

    function WriteData(const AData: TBytes): boolean;
    function hasWill: boolean;
    function getNextMessageId: Integer;

    // TMQTTMessage Factory Methods.
    function ConnectMessage: TMQTTMessage;
    function DisconnectMessage: TMQTTMessage;
    function PublishMessage: TMQTTMessage;
    function PingReqMessage: TMQTTMessage;
    function SubscribeMessage: TMQTTMessage;
    function UnsubscribeMessage: TMQTTMessage;

    // publish ack     qos=1
    function PubAckMessage: TMQTTMessage;
    // publish ack     qos=2
    function PubRecMessage: TMQTTMessage;
    // pubrec  ack     qos=2
    function PubRelMessage: TMQTTMessage;
    // pubrel  ack      qos=2
    function PubCompleMessage: TMQTTMessage;

    function PublishBytesMessage: TMQTTBytesMessage;

    // Our Keep Alive Ping Timer Event
    procedure KeepAliveTimer_Event(sender: TObject);

    // Recv Thread Event Handling Procedures.
    procedure ConnAckDo(sender: TObject; ReturnCode: Integer);
    procedure PingRespDo(sender: TObject);
    procedure PingReqDo(sender: TObject);

    procedure SubAckDo(sender: TObject; MessageID: Integer; GrantedQoS: Array of Integer);
    procedure UnSubAckDo(sender: TObject; MessageID: Integer);
    procedure PublishDo(sender: TObject; topic: String; PackageId: Integer; payload: String; QOS: Integer);
    procedure PubAckDo(sender: TObject; MessageID: Integer);
    procedure PubRecDo(sender: TObject; MessageID: Integer);
    procedure PubRelDo(sender: TObject; MessageID: Integer);
    procedure PubCompDo(sender: TObject; MessageID: Integer);

    // publish ack     qos=1
    function PubAck(PkgId: Integer): boolean;
    // publish ack     qos=2
    function PubRec(PkgId: Integer): boolean;
    // pubrec  ack     qos=2
    function PubRel(PkgId: Integer): boolean;
    // pubrel  ack      qos=2
    function PubComple(PkgId: Integer): boolean;

    // handle all come from server message
    procedure ProcessMessage;

    // procedure ProcessMessage;
    function readSingleString(const dataStream: TBytes; const indexStartAt: Integer;
      var stringRead: AnsiString): Integer;
    // function readMessageId(const dataStream: TBytes; const indexStartAt: Integer; var MessageID: Integer): Integer;
    function readStringWithoutPrefix(const dataStream: TBytes; const indexStartAt: Integer;
      var stringRead: AnsiString): Integer;
    function readIdentifier(const dataStream: TBytes; const indexStartAt: Integer; var Identifier: Integer): Integer;

    function ReadFromFile(f: string): PMQTTBytes;
    function SaveToFile(O: TMQTTBytes): string;

    procedure SessionRemove(msgID: uint16);
    procedure SessionAdd(O: PMQTTBytes);
    procedure LoadCacheFileToSend;

    procedure SessionDO(msg: TMQTTMessage);
    procedure SessionPublishDO(msg: TMQTTBytesMessage);

    procedure SessionProcess();
    procedure SocketInit;
    procedure CreateProcessComingThread;

    procedure PublishBytesDo(sender: TObject; topic: String; PackageId: Integer; const payload: TBytes; QOS: Integer);
    function readPlayLoad(const dataStream: TBytes; const indexStartAt: Integer; var B: TBytes): Integer;

    procedure MessageDispatch;
    procedure ReceiveBytesParse;
    function MqttHeaderIsLegal(FixHeader: Byte): boolean;

  public

    // PublishMessageCount: UInt64;
    // GStringList: TStringList;
    { Public Declarations }

    procedure OnConnected(sender: TObject; AConnection: ICrossConnection);
    procedure OnDisConnected(sender: TObject; AConnection: ICrossConnection);
    procedure OnReceived(sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer);
    // procedure OnSent(sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer);

    procedure Connect;
    function Disconnect: boolean;

    function Publish(topic: String; const sPayload: TBytes; QOS: Integer): boolean; overload;
    function Publish(topic: String; const sPayload: TBytes; Retain: boolean; QOS: Integer): boolean; overload;
    function Publish(topic: String; sPayload: String; QOS: Integer): boolean; overload;

    function Subscribe(topic: String; RequestQoS: Integer): Integer; overload;
    function Subscribe(Topics: TDictionary<String, Integer>): Integer; overload;

    function Unsubscribe(topic: String): Integer; overload;
    function Unsubscribe(Topics: TStringList): Integer; overload;

    function PingReq: boolean;

    constructor Create(hostName: String; port: Integer);
    destructor Destroy; override;

    property WillTopic: String read FWillTopic write FWillTopic;
    property WillMsg: String read FWillMsg write FWillMsg;

    property Username: String read FUsername write FUsername;
    property Password: String read FPassword write FPassword;
    // Client ID is our Client Identifier.
    property ClientID: String read FClientID write FClientID;
    property isConnected: boolean read FisConnected;

    // // Event Handlers
    property OnConnAck: TConnAckEvent read FConnAckEvent write FConnAckEvent;
    property OnPublishBytes: TPublishBytesEvent read FPublishBytesEvent write FPublishBytesEvent;
    property OnPublish: TPublishEvent read FPublishEvent write FPublishEvent;
    property OnPingResp: TPingRespEvent read FPingRespEvent write FPingRespEvent;
    property OnPingReq: TPingReqEvent read FPingReqEvent write FPingReqEvent;
    property OnSubAck: TSubAckEvent read FSubAckEvent write FSubAckEvent;
    property OnUnSubAck: TUnSubAckEvent read FUnSubAckEvent write FUnSubAckEvent;
    property OnPubAck: TPubAckEvent read FPubAckEvent write FPubAckEvent;
    property OnPubRec: TPubRecEvent read FPubRecEvent write FPubRecEvent;
    property OnPubRel: TPubRelEvent read FPubRelEvent write FPubRelEvent;
    property OnPubComp: TPubCompEvent read FPubCompEvent write FPubCompEvent;

    property OnPubAckSend: TPubAckEvent read FPubAckSendEvent write FPubAckSendEvent;
    property OnPubRecSend: TPubRecEvent read FPubRecSendEvent write FPubRecSendEvent;
    property OnPubRelSend: TPubRelEvent read FPubRelSendEvent write FPubRelSendEvent;
    property OnPubCompSend: TPubCompEvent read FPubCompSendEvent write FPubCompSendEvent;

    property OnPublishSend: TPublishEvent read FPublishSendEvent write FPublishSendEvent;
    property OnSubSend: TSubEvent read FSubSendEvent write FSubSendEvent;
    property OnUnSubSend: TUnSubSendEvent read FUnSubSendEvent write FUnSubSendEvent;

    property OnConnect: TConnectEvent read FConnectEvent write FConnectEvent;
    property KeepAlive: Cardinal read FKeepAlive write FKeepAlive;

  end;

  TProcessComeMsgThread = class(TThread)
    FProc: TMyProce;
  protected
    procedure Execute; override;
  public
    constructor Create(ThreadProc: TMyProce);
  end;

  TProcessRevMsgParseThread = class(TThread)
    FProc: TMyProce;
  protected
    procedure Execute; override;
  public
    constructor Create(ThreadProc: TMyProce);
  end;

implementation

{ TMQTTClient }

procedure TMQTT.ConnAckDo(sender: TObject; ReturnCode: Integer);
begin
  // Load cache data to server;
  FSessionTimer.Enabled := true;
  LoadCacheFileToSend;
  if Assigned(OnConnAck) then
    OnConnAck(Self, ReturnCode);
end;

procedure TMQTT.SocketInit();
begin
  FSocket :=
{$IFDEF __SSL__}
    TCrossSslSocket
{$ELSE}
    TCrossSocket
{$ENDIF}
    .Create(0);
  FSocket.OnConnected := OnConnected;
  FSocket.OnDisConnected := OnDisConnected;
  FSocket.OnReceived := OnReceived;
  // FSocket.OnSent := OnSent;
  // FRunWatch := TStopwatch.StartNew;

{$IFDEF __SSL__}
  FSocket.InitSslCtx(SSLv23);
{$IFDEF POSIX}
  FSocket.SetCertificate(SSL_SERVER_CERT);
  FSocket.SetPrivateKey(SSL_SERVER_PKEY);
{$ELSE}
  FSocket.SetCertificateFile('server.crt');
  FSocket.SetPrivateKeyFile('server.key');
{$ENDIF}
{$ENDIF}
end;

procedure TMQTT.Connect;
begin
  // Create socket and connect.
  FisConnected := false;
  FSocket.Connect(Self.FHostname, Self.FPort,
    procedure(ASocket: THandle; ASuccess: boolean)
    var
      msg: TMQTTMessage;
      LConn: ICrossConnection;
    begin
      if ASuccess then
      begin
        msg := ConnectMessage;
        try
          msg.payload.Contents.Add(Self.FClientID);
          (msg.VariableHeader as TMQTTConnectVarHeader).KeepAlive := FKeepAlive;
          (msg.VariableHeader as TMQTTConnectVarHeader).WillFlag := ord(hasWill);
          if hasWill then
          begin
            msg.payload.Contents.Add(Self.FWillTopic);
            msg.payload.Contents.Add(Self.FWillMsg);
          end
          else
          begin
            (msg.VariableHeader as TMQTTConnectVarHeader).QoSLevel := 0;
            (msg.VariableHeader as TMQTTConnectVarHeader).Retain := 0;

          end;

          if ((Length(FUsername) > 1) and (Length(FPassword) > 1)) then
          begin
            msg.payload.Contents.Add(FUsername);
            msg.payload.Contents.Add(FPassword);
            (msg.VariableHeader as TMQTTConnectVarHeader).UsernameFlag := 1;
            (msg.VariableHeader as TMQTTConnectVarHeader).PasswordFlag := 1;
          end
          else
          begin
            (msg.VariableHeader as TMQTTConnectVarHeader).UsernameFlag := 0;
            (msg.VariableHeader as TMQTTConnectVarHeader).PasswordFlag := 0;
          end;

          LConn := FSocket.LockConnections.Values.ToArray[0];
          try
            if LConn <> nil then
              LConn.SendBytes(msg.ToBytes,
                procedure(AConnection: ICrossConnection; ASuccess: boolean)
                begin
                  if ASuccess then
                  begin
                    FisConnected := true;
                    // thread  handle receive
                    CreateProcessComingThread();
                    FKeepAliveTimer.Interval := Round(Self.FKeepAlive * 0.8 * 1000);
                    FKeepAliveTimer.Enabled := true;

                    TThread.CreateAnonymousThread(SessionProcess).Start;

                    // todo notify application
                    if Assigned(OnConnect) then
                      OnConnect(Self, Self.FHostname, Self.FPort, FisConnected);

                  end;
                end);
          finally
            FSocket.UnlockConnections;
          end;
        finally
          msg.Free;
        end;
      end;

    end);

end;

function TMQTT.ConnectMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.VariableHeader := TMQTTConnectVarHeader.Create;
  result.payload := TMQTTPayload.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.Connect);
  result.FixedHeader.Retain := 0;
  result.FixedHeader.QoSLevel := 0;
  result.FixedHeader.Duplicate := 0;
end;

constructor TMQTT.Create(hostName: String; port: Integer);
begin
  inherited Create;

  Self.FisConnected := false;
  Self.FHostname := hostName;
  Self.FPort := port;
  Self.FMessageID := 1;
  Self.FKeepAlive := 60;

  // Randomise and create a random client id.
  Randomize;
  Self.FClientID := 'TMQTT' + IntToStr(Random(1000) + 1);
  // FCSSock := TCriticalSection.Create;
  FQueue := TAtomFIFO.Create(QueueSize);
  FRevQueue := TAtomFIFO.Create(QueueSize);

  // save the session
  FSessionList := TThreadList<PMQTTBytes>.Create;

  // Create the timer responsible for pinging.
  FKeepAliveTimer := TTimer.Create(nil);
  FKeepAliveTimer.Enabled := false;

  FKeepAliveTimer.OnTimer := KeepAliveTimer_Event;

  // init socket
  SocketInit();

end;

procedure TMQTT.CreateProcessComingThread();
begin
  FProcessThread := TProcessComeMsgThread.Create(ProcessMessage);
  FProcessThread.Start;

  FProcessRevMsgParseThread := TProcessRevMsgParseThread.Create(MessageDispatch);
  FProcessRevMsgParseThread.Start;

end;

destructor TMQTT.Destroy;
begin
  if Assigned(FSocket) then
  begin
    Disconnect;
  end;

  if Assigned(FKeepAliveTimer) then
    FreeAndNil(FKeepAliveTimer);

  if Assigned(FSessionTimer) then
    FreeAndNil(FSessionTimer);

  if Assigned(FSessionList) then
    FreeAndNil(FSessionList);

  if Assigned(FProcessThread) then
    FreeAndNil(FProcessThread);

  if Assigned(FProcessRevMsgParseThread) then
    FreeAndNil(FProcessRevMsgParseThread);

  if Assigned(FQueue) then
  begin
    FreeAndNil(FQueue);
  end;

  if Assigned(FRevQueue) then
  begin
    FreeAndNil(FRevQueue);
  end;

  inherited;
end;

function TMQTT.Disconnect: boolean;
var
  msg: TMQTTMessage;
begin
  result := false;
  if isConnected then
  begin
    FKeepAliveTimer.Enabled := false;
    FSessionTimer.Enabled := false;
    msg := DisconnectMessage;
    try
      if WriteData(msg.ToBytes) then
        result := true
      else
        result := false;
    finally
      FreeAndNil(msg);
    end;

    // Terminate our socket receive thread.

    if Assigned(FProcessThread) then
    begin
      FProcessThread.Terminate;
      FProcessThread.WaitFor;

    end;

    if Assigned(FProcessRevMsgParseThread) then
    begin
      FProcessRevMsgParseThread.Terminate;
      FProcessRevMsgParseThread.WaitFor;
    end;

    // Close our socket.
    FSocket.DisconnectAll;
    FisConnected := false;

  end;
end;

function TMQTT.DisconnectMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.Disconnect);
end;

function TMQTT.getNextMessageId: Integer;
begin
  // If we've reached the upper bounds of our 16 bit unsigned message Id then
  // start again. The spec says it typically does but is not required to Inc(MsgId,1).
  if (FMessageID = 65535) then
  begin
    FMessageID := 1;
  end;

  // Return our current message Id
  result := FMessageID;
  // Increment message Id
  Inc(FMessageID);
end;

function TMQTT.hasWill: boolean;
begin
  if ((Length(FWillTopic) < 1) and (Length(FWillMsg) < 1)) then
  begin
    result := false;
  end
  else
    result := true;
end;

procedure TMQTT.KeepAliveTimer_Event(sender: TObject);
begin
  if Self.isConnected then
  begin
    PingReq;

    if Assigned(OnPingReq) then
      OnPingReq(Self);

  end;
end;

procedure TMQTT.SessionAdd(O: PMQTTBytes);
var
  LockList: TList<PMQTTBytes>;
begin
  LockList := FSessionList.LockList;
  try
    LockList.Add(O);
  finally
    FSessionList.UnlockList;
  end;
end;

procedure TMQTT.SessionRemove(msgID: uint16);
var
  i: Integer;
  msgO: PMQTTBytes;
begin
  try
    for i := FSessionList.LockList.Count - 1 downto 0 do
    begin
      msgO := FSessionList.LockList.Items[i];
      if PMQTTBytes(msgO).MessageID = msgID then
      begin
        FSessionList.LockList.Delete(i);
        setlength(msgO.Bytes, 0);
        Dispose(msgO);
      end;

    end;
  finally
    FSessionList.UnlockList;
  end;
end;

procedure TMQTT.SessionProcess;
const
  timeOutSeconet = 5; // 超时秒数
  RePushCount = 1; // 重发次数
var
  i: Integer;
  msgO: PMQTTBytes;
  LockList: TList<PMQTTBytes>;
begin
  LockList := FSessionList.LockList;
  try
    for i := LockList.Count - 1 downto 0 do
    begin
      msgO := LockList.Items[i];
      if (DateTimeToUnix(Now) - msgO.TimeOut > timeOutSeconet) and (FisConnected = true) then
      begin
        // todo save file
        if msgO.PushCount < RePushCount then
        begin
          msgO.PushCount := msgO.PushCount + 1;
          WriteData(msgO.Bytes);
        end
        else
        begin
          SaveToFile(msgO^);
          LockList.Delete(i);
          setlength(msgO.Bytes, 0);
          Dispose(msgO);
        end;
      end; // not timeout
      sleep(100);
    end;

  finally
    FSessionList.UnlockList;
  end;

end;

function TMQTT.PingReq: boolean;
var
  msg: TMQTTMessage;

begin
  result := false;
  if isConnected then
  begin
    msg := PingReqMessage;
    try
      if WriteData(msg.ToBytes) then
        result := true
      else
        result := false;
    finally
      FreeAndNil(msg);
    end;

  end;
end;

procedure TMQTT.PingReqDo(sender: TObject);
begin
  if Assigned(OnPingReq) then
    OnPingReq(Self);
end;

function TMQTT.PingReqMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.PingReq);
end;

procedure TMQTT.PingRespDo(sender: TObject);
begin
  if Assigned(OnPingResp) then
    OnPingResp(Self);
end;

function TMQTT.Publish(topic: String; sPayload: String; QOS: Integer): boolean;
var
  B: TBytes;
  payload: AnsiString;
begin

  payload := AnsiString(sPayload);
  if Length(payload) > 0 then
  begin
    setlength(B, Length(payload));
    Move(payload[1], B[0], Length(payload));
  end
  else
    setlength(B, 0);

  result := Publish(topic, B, false, QOS);
  setlength(B, 0);

end;

function TMQTT.PubAck(PkgId: Integer): boolean;
var
  msg: TMQTTMessage;
begin
  result := false;
  if isConnected then
  begin
    msg := PubAckMessage;
    try
      msg.FixedHeader.QoSLevel := 0;
      (msg.VariableHeader as TMQTTPubAckVarHeader).MessageID := PkgId;

      if WriteData(msg.ToBytes) then
        result := true
      else
        result := false;
    finally
      FreeAndNil(msg);
    end;

  end;

end;

function TMQTT.PubAckMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.PubAck);
  result.VariableHeader := TMQTTPubAckVarHeader.Create(0);
end;

function TMQTT.PubComple(PkgId: Integer): boolean;
var
  msg: TMQTTMessage;

begin
  result := false;
  if isConnected then
  begin
    msg := PubCompleMessage;
    try
      msg.FixedHeader.QoSLevel := 0;
      (msg.VariableHeader as TMQTTPubCompVarHeader).MessageID := PkgId;

      if WriteData(msg.ToBytes) then
        result := true
      else
        result := false;
    finally
      FreeAndNil(msg);
    end;
  end;

end;

function TMQTT.PubCompleMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.PUBCOMP);
  result.VariableHeader := TMQTTPubCompVarHeader.Create(0);
end;

procedure TMQTT.SessionDO(msg: TMQTTMessage);
var
  O: PMQTTBytes;
begin
  if (msg.FixedHeader.MessageType = ord(TMQTTMessageType.Publish)) or
    (msg.FixedHeader.MessageType = ord(TMQTTMessageType.PubRec)) or
    (msg.FixedHeader.MessageType = ord(TMQTTMessageType.PubRel)) or
    (msg.FixedHeader.MessageType = ord(TMQTTMessageType.Subscribe)) or
    (msg.FixedHeader.MessageType = ord(TMQTTMessageType.Unsubscribe)) then
  begin
    O := New(PMQTTBytes);
    case msg.FixedHeader.MessageType of
      ord(TMQTTMessageType.Publish):
        O.MessageID := (msg.VariableHeader as TMQTTPublishVarHeader).MessageID;
      ord(TMQTTMessageType.PubRec):
        O.MessageID := (msg.VariableHeader as TMQTTPubRecVarHeader).MessageID;
      ord(TMQTTMessageType.PubRel):
        O.MessageID := (msg.VariableHeader as TMQTTPubRelVarHeader).MessageID;
      ord(TMQTTMessageType.Subscribe):
        O.MessageID := (msg.VariableHeader as TMQTTSubscribeVarHeader).MessageID;
      ord(TMQTTMessageType.Unsubscribe):
        O.MessageID := (msg.VariableHeader as TMQTTUnsubscribeVarHeader).MessageID;

    end;
    O.PushCount := 0;
    O.TimeOut := DateTimeToUnix(Now);
    AppendToByteArray(msg.ToBytes, O.Bytes);
    SessionAdd(O);
  end;

end;

procedure TMQTT.SessionPublishDO(msg: TMQTTBytesMessage);
var
  O: PMQTTBytes;
begin
  if (msg.FixedHeader.MessageType = ord(TMQTTMessageType.Publish)) then
  begin
    O := New(PMQTTBytes);
    O.MessageID := (msg.VariableHeader as TMQTTPublishVarHeader).MessageID;
    O.PushCount := 0;
    O.TimeOut := DateTimeToUnix(Now);
    AppendToByteArray(msg.ToBytes, O.Bytes);
    SessionAdd(O);
  end;
end;

function TMQTT.Publish(topic: string; const sPayload: TBytes; Retain: boolean; QOS: Integer): boolean;
var
  msg: TMQTTBytesMessage;
  msgID: Integer;
  cnt: AnsiString;
  B: TBytes;
begin
  result := false;
  if ((QOS > -1) and (QOS < 3)) then
  begin
    msgID := 0;
    if FisConnected then
    begin
      msg := PublishBytesMessage;
      try
        msg.FixedHeader.QoSLevel := QOS;
        (msg.VariableHeader as TMQTTPublishVarHeader).QoSLevel := QOS;
        (msg.VariableHeader as TMQTTPublishVarHeader).topic := topic;
        if (QOS > 0) then
        begin
          msgID := getNextMessageId;
          (msg.VariableHeader as TMQTTPublishVarHeader).MessageID := msgID;
        end;

        setlength(msg.payload, Length(sPayload));
        Move(sPayload[0], msg.payload[0], Length(sPayload));

        // msg.payload := Copy(sPayload, 0, Length(sPayload));
        // Todo QOS =1 /2 要 本地持久化cache, 在收到数据ACK，要进行删除。
        // 系统在 连接上 服务器后，要对cache，进行处理，如果有未确认的数据。
        if QOS > 0 then
          SessionPublishDO(msg);

        B := msg.ToBytes;

        if WriteData(B) then
          result := true;

        setlength(B, 0);
        // log print the publish
        if Assigned(OnPublishSend) then
        begin
          SetString(cnt, PAnsiChar(@msg.payload[0]), Length(msg.payload));
          OnPublishSend(Self, topic, msgID, cnt, QOS);
        end;
      finally
        FreeAndNil(msg);
      end;

    end;
  end
  else
    raise EInvalidOp.Create('QoS level can only be equal to or between 0 and 3.');
end;

function TMQTT.Publish(topic: String; const sPayload: TBytes; QOS: Integer): boolean;
begin
  Publish(topic, sPayload, false, QOS);
end;

function TMQTT.PublishMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.Publish);
  result.VariableHeader := TMQTTPublishVarHeader.Create(0);
  result.payload := TMQTTPayload.Create;
end;

function TMQTT.PublishBytesMessage: TMQTTBytesMessage;
begin
  result := TMQTTBytesMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.Publish);
  result.VariableHeader := TMQTTPublishVarHeader.Create(0);
end;

function TMQTT.PubRec(PkgId: Integer): boolean;
var
  msg: TMQTTMessage;
begin
  result := false;
  if isConnected then
  begin
    msg := PubRecMessage;
    try
      msg.FixedHeader.QoSLevel := 0;
      (msg.VariableHeader as TMQTTPubRecVarHeader).MessageID := PkgId;

      // wait for ,pubrel
      SessionDO(msg);
      if WriteData(msg.ToBytes) then
        result := true;

    finally
      FreeAndNil(msg);
    end;
  end;
end;

function TMQTT.PubRecMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.PubRec);
  result.VariableHeader := TMQTTPubRecVarHeader.Create(0);
end;

function TMQTT.PubRel(PkgId: Integer): boolean;
var
  msg: TMQTTMessage;
begin

  result := false;
  if isConnected then
  begin
    msg := PubRelMessage;
    try

      msg.FixedHeader.QoSLevel := 1;
      (msg.VariableHeader as TMQTTPubRelVarHeader).MessageID := PkgId;

      // wait for ,pubcomp
      SessionDO(msg);
      if WriteData(msg.ToBytes) then
        result := true;

    finally
      FreeAndNil(msg);
    end;
  end;

end;

function TMQTT.PubRelMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.PubRel);
  result.VariableHeader := TMQTTPubRelVarHeader.Create(0);
end;

procedure TMQTT.PubRecDo(sender: TObject; MessageID: Integer);
begin
  if Assigned(OnPubRec) then
    OnPubRec(Self, MessageID);
end;

procedure TMQTT.PubRelDo(sender: TObject; MessageID: Integer);
begin
  if Assigned(OnPubRel) then
    OnPubRel(Self, MessageID);
end;

procedure TMQTT.SubAckDo(sender: TObject; MessageID: Integer; GrantedQoS: array of Integer);
begin
  if Assigned(OnSubAck) then
    OnSubAck(Self, MessageID, GrantedQoS);
end;

/// <summary>
/// //single  topic   subscribe   ,format: topic:qos
/// header fix :130
/// Remaining lenght 9 = length(playload)+length(variable herder)
/// variable header  2 (pacakge id)
/// play load:  7
/// MSB         1
/// LSB         1
/// t           1
/// e           1
/// x           1
/// t           1
/// qos         1
/// </summary>
function TMQTT.Subscribe(topic: String; RequestQoS: Integer): Integer;
var
  dTopics: TDictionary<String, Integer>;
begin
  result := -1;

  if Pos('$', topic) > 0 then
    exit;

  if (TMQTTUtilities.ValidateQos(RequestQoS)) and (Length(topic) > 0) then
  begin
    dTopics := TDictionary<String, Integer>.Create;
    try
      dTopics.Add(topic, RequestQoS);
      result := Subscribe(dTopics);
    finally
      FreeAndNil(dTopics);
    end;
  end;

end;

/// <summary>
/// mulite  topic   subscribe   topic:qos; topic:qos
/// header fix :130
/// Remaining lenght 9 = length(playload)+length(variable herder)
/// variable header  2 (pacakge id)
/// play load:  7
/// MSB         1
/// LSB         1
/// t           1
/// e           1
/// x           1
/// t           1
/// qos         1
/// </summary>

function TMQTT.Subscribe(Topics: TDictionary<String, Integer>): Integer;
var
  msg: TMQTTMessage;
  msgID: Integer;
  sTopic: String;

begin
  result := -1;
  if isConnected then
  begin
    msg := SubscribeMessage;
    try
      msgID := getNextMessageId;
      (msg.VariableHeader as TMQTTSubscribeVarHeader).MessageID := msgID;

      for sTopic in Topics.Keys do
      begin
        msg.payload.Contents.Add(sTopic);
        msg.payload.Contents.Add(IntToStr(Topics.Items[sTopic]))
      end;
      // the subscribe message contains integer literals not encoded as strings.
      msg.payload.ContainsIntLiterals := true;

      // add the list ,wait for ack
      SessionDO(msg);
      result := msgID;
      WriteData(msg.ToBytes);
      if Assigned(OnSubSend) then
        OnSubSend(Self, msgID, Topics);

    finally
      FreeAndNil(msg);
    end;

  end;
end;

function TMQTT.SubscribeMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.Subscribe);
  result.FixedHeader.QoSLevel := 1;
  result.VariableHeader := TMQTTSubscribeVarHeader.Create;
  result.payload := TMQTTPayload.Create;
end;

function TMQTT.Unsubscribe(topic: String): Integer;
var
  slTopics: TStringList;
begin
  slTopics := TStringList.Create;
  slTopics.Add(topic);
  result := Unsubscribe(slTopics);
  slTopics.Free;
end;

procedure TMQTT.UnSubAckDo(sender: TObject; MessageID: Integer);
begin
  if Assigned(OnUnSubAck) then
    OnUnSubAck(Self, MessageID);
end;

function TMQTT.Unsubscribe(Topics: TStringList): Integer;
var
  msg: TMQTTMessage;
  msgID: Integer;

begin
  result := -1;
  if isConnected then
  begin
    msg := UnsubscribeMessage;
    try
      msgID := getNextMessageId;
      (msg.VariableHeader as TMQTTUnsubscribeVarHeader).MessageID := msgID;
      msg.payload.Contents.AddStrings(Topics);

      // add to list, wait for ack;
      SessionDO(msg);

      if WriteData(msg.ToBytes) then
        result := msgID;

      if Assigned(OnUnSubSend) then
        OnUnSubSend(Self, msgID, Topics);

    finally
      FreeAndNil(msg);
    end;

  end;
end;

function TMQTT.UnsubscribeMessage: TMQTTMessage;
begin
  result := TMQTTMessage.Create;
  result.FixedHeader.MessageType := ord(TMQTTMessageType.Unsubscribe);
  result.FixedHeader.QoSLevel := 1;
  result.VariableHeader := TMQTTUnsubscribeVarHeader.Create;
  result.payload := TMQTTPayload.Create;
end;

function TMQTT.WriteData(const AData: TBytes): boolean;
var
  LConn: ICrossConnection;
  sendB: boolean;
  ConDr: TDictionary<THandle, ICrossConnection>;
begin

  result := false;
  sendB := false;
  if Length(AData) <= 0 then
    exit;

  if FisConnected then
  begin
    if FSocket <> nil then
    begin
      ConDr := FSocket.LockConnections;
      try
        if ConDr <> nil then
        begin
          if ConDr.Values.Count > 0 then
            LConn := ConDr.Values.ToArray[0];

          if LConn <> nil then
          begin
            LConn.SendBytes(AData,
              procedure(AConnection: ICrossConnection; ASuccess: boolean)
              begin
                if ASuccess then
                  sendB := true;
              end);
            result := sendB;
          end;
        end;
      finally
        FSocket.UnlockConnections;
      end;

    end;

  end;
end;

procedure TMQTT.PublishDo(sender: TObject; topic: String; PackageId: Integer; payload: String; QOS: Integer);
begin
  if PackageId > 0 then
  begin
    PubAck(PackageId);
  end;
  if Assigned(OnPublish) then
    OnPublish(Self, topic, PackageId, payload, QOS);

end;

procedure TMQTT.PublishBytesDo(sender: TObject; topic: String; PackageId: Integer; const payload: TBytes; QOS: Integer);
begin
  if PackageId > 0 then
  begin
    PubAck(PackageId);
  end;
  if Assigned(OnPublishBytes) then
    OnPublishBytes(Self, topic, PackageId, payload, QOS);

end;

procedure TMQTT.PubAckDo(sender: TObject; MessageID: Integer);
begin
  if Assigned(OnPubAck) then
    OnPubAck(Self, MessageID);
end;

procedure TMQTT.PubCompDo(sender: TObject; MessageID: Integer);
begin
  if Assigned(OnPubComp) then
    OnPubComp(Self, MessageID);
end;

procedure TMQTT.ProcessMessage;
begin
  ReceiveBytesParse();
end;

procedure TMQTT.MessageDispatch();
var
  NewMsg: PUnparsedMsg;
  FHCode: Byte;
  dataCaret: Integer;
  GrantedQoS: Array of Integer;
  i: Integer;
  strTopic, strPayload: AnsiString;
  PackageId: Integer;
  FixedHeader: TMQTTFixedHeader;
  B: TBytes;
begin
  try
    NewMsg := PUnparsedMsg(FQueue.Pop);
    if Assigned(NewMsg) then
    begin
      FixedHeader.Flags := NewMsg.FixedHeader;
      FHCode := NewMsg.FixedHeader shr 4;
      case FHCode of
        ord(TMQTTMessageType.CONNACK):
          begin
            if Length(NewMsg.data) > 0 then
            begin
              // NewMsg.Data[0] is  Session Present Flag
              // NewMsg.Data[1] is  Connect Return code
              // 0 0x00 Connection Accepted
              // 1 0x01 Connection Refused, unacceptable protocol version ,The Server does not support the level of the MQTT protocol requested by the Clien
              // 2 0x02 Connection Refused, identifier rejected The Client identifier is correct UTF-8 but not   allowed by the Server
              // 3 0x03 Connection Refused, Server unavailable The Network Connection has been made but the MQTT service is unavailable
              // 4 0x04 Connection Refused, bad user name or password  The data in the user name or password is malformed
              // 5 0x05 Connection Refused, not authorized The Client is not authorized to connect
              // 6-255 Reserved for future us

              ConnAckDo(Self, NewMsg.data[1]);
            end;
          end;

        ord(TMQTTMessageType.PingReq):
          begin
            PingReqDo(Self);
          end;
        ord(TMQTTMessageType.PINGRESP):
          begin
            PingRespDo(Self);
          end;
        ord(TMQTTMessageType.Publish): // OK
          begin
            // Todo: This only applies for QoS level 0/1 messages.
            // Inc(PublishMessageCount);

            PackageId := 0;
            dataCaret := 0;
            dataCaret := readSingleString(NewMsg.data, dataCaret, strTopic);
            if FixedHeader.QoSLevel = 1 then
            begin
              dataCaret := readIdentifier(NewMsg.data, dataCaret, PackageId);
              // receive from server publish(qos=1) and send back puback the server.
              PubAck(PackageId);
            end;

            if FixedHeader.QoSLevel = 2 then
            begin
              dataCaret := readIdentifier(NewMsg.data, dataCaret, PackageId);
              // receive from server publish(qos=0) and send back pubRec the server.
              PubRec(PackageId);
            end;
            // readStringWithoutPrefix(NewMsg.data, dataCaret, strPayload);
            // PublishDo(Self, string(strTopic), PackageId, string(strPayload), FixedHeader.QoSLevel);
            readPlayLoad(NewMsg.data, dataCaret, B);
            if Length(B) > 0 then
            begin
              try
                PublishBytesDo(Self, string(strTopic), PackageId, B, FixedHeader.QoSLevel);
                setlength(B, 0);
              except
                on E: Exception do
                  // log9.syslog.LogByTime('Error:' + E.Message);
              end;
            end;

            // for  log print
            if FixedHeader.QoSLevel = 1 then
            begin
              if Assigned(OnPubAckSend) then
                OnPubAckSend(Self, PackageId);
            end;
            if FixedHeader.QoSLevel = 2 then
            begin
              if Assigned(OnPubRecSend) then
                OnPubRecSend(Self, PackageId);
            end;

          end;
        ord(TMQTTMessageType.SUBACK): // OK
          begin
            if (Length(NewMsg.data) > 2) then
            begin
              setlength(GrantedQoS, Length(NewMsg.data) - 2);
              for i := 0 to High(NewMsg.data) - 2 do
              begin
                GrantedQoS[i] := NewMsg.data[i + 2];
              end;
              PackageId := 0;
              PackageId := TMQTTUtilities.MSBLSBToInt(Copy(NewMsg.data, 0, 2));
              // remove  subscribe  waitfor
              SessionRemove(PackageId);
              SubAckDo(Self, PackageId, GrantedQoS);
            end;
          end;
        ord(TMQTTMessageType.UNSUBACK): // OK
          begin
            if Length(NewMsg.data) = 2 then
            begin
              PackageId := 0;
              PackageId := TMQTTUtilities.MSBLSBToInt(Copy(NewMsg.data, 0, 2));
              // remove  unsubscribe  waitfor
              SessionRemove(PackageId);

              UnSubAckDo(Self, TMQTTUtilities.MSBLSBToInt(NewMsg.data))
            end;
          end;
        ord(TMQTTMessageType.PubRec): //
          begin
            if Length(NewMsg.data) = 2 then
            begin
              PackageId := 0;
              PackageId := TMQTTUtilities.MSBLSBToInt(Copy(NewMsg.data, 0, 2));
              // send  publish(qos=2) to server and receive from server pubrec, and send pubrel to server
              PubRel(PackageId);
              PubRecDo(Self, TMQTTUtilities.MSBLSBToInt(NewMsg.data));
              if Assigned(OnPubRelSend) then
                OnPubRelSend(Self, PackageId);
              // remove  publish  waitfor
              SessionRemove(PackageId);

            end;
          end;
        ord(TMQTTMessageType.PubRel): // todo    Pubrec
          begin
            if Length(NewMsg.data) = 2 then
            begin
              PackageId := 0;
              PackageId := TMQTTUtilities.MSBLSBToInt(Copy(NewMsg.data, 0, 2));
              // send  pubrel(qos=0) to server and receive from server pubrel(qos=1), and send pubcomp to server
              PubComple(PackageId);
              PubRelDo(Self, TMQTTUtilities.MSBLSBToInt(NewMsg.data));
              if Assigned(OnPubCompSend) then
                OnPubCompSend(Self, PackageId);
              // remove  pubrec  waitfor
              SessionRemove(PackageId);

            end;
          end;
        ord(TMQTTMessageType.PubAck):
          begin
            if Length(NewMsg.data) = 2 then
            begin
              PackageId := 0;
              PackageId := TMQTTUtilities.MSBLSBToInt(Copy(NewMsg.data, 0, 2));
              // remove  publish  waitfor
              SessionRemove(PackageId);
              PubAckDo(Self, TMQTTUtilities.MSBLSBToInt(NewMsg.data))
              // todo Delete  Publish(qos=1) msgid's Data  from sqllite
            end;
          end;
        ord(TMQTTMessageType.PUBCOMP): //
          begin
            if Length(NewMsg.data) = 2 then
            begin
              PackageId := 0;
              PackageId := TMQTTUtilities.MSBLSBToInt(Copy(NewMsg.data, 0, 2));
              // remove  pubrel  waitfor
              SessionRemove(PackageId);
              PubCompDo(Self, TMQTTUtilities.MSBLSBToInt(NewMsg.data))
              // todo Delete  Publish(qos=2) msgid's Data from sqllite
            end;
          end;
      end;

      setlength(NewMsg.RL, 0);
      setlength(NewMsg.data, 0);
      Dispose(NewMsg);

    end;
  except
    // on E: Exception do
    // syslog.LogByTime(E.Message);
  end;
end;

function TMQTT.readPlayLoad(const dataStream: TBytes; const indexStartAt: Integer; var B: TBytes): Integer;
var
  BLen: Integer;
begin
  result := 0;
  if Length(dataStream) > 0 then
  begin
    BLen := Length(dataStream) - (indexStartAt + 2);
    if BLen > 0 then
    begin
      setlength(B, BLen);
      // B := Copy(dataStream, indexStartAt + 2, BLen);
      Move(dataStream[indexStartAt + 2], B[0], BLen);
    end;
    result := indexStartAt + BLen;
  end;
end;

function TMQTT.readStringWithoutPrefix(const dataStream: TBytes; const indexStartAt: Integer;
var stringRead: AnsiString): Integer;
var
  strLength: Integer;
begin
  strLength := Length(dataStream) - (indexStartAt + 2);
  if strLength > 0 then
  begin
    SetString(stringRead, PAnsiChar(@dataStream[indexStartAt + 2]), strLength);
  end;
  result := indexStartAt + strLength;
end;

function TMQTT.readIdentifier(const dataStream: TBytes; const indexStartAt: Integer; var Identifier: Integer): Integer;
begin
  Identifier := TMQTTUtilities.MSBLSBToInt(Copy(dataStream, indexStartAt + 2, 2));
  result := indexStartAt + 2;
end;

function TMQTT.readSingleString(const dataStream: TBytes; const indexStartAt: Integer;
var stringRead: AnsiString): Integer;
var
  strLength: Integer;
  B: TBytes;
begin
  result := 0;
  if Length(dataStream) > 2 then
  begin
    setlength(B, 2);
    Move(dataStream[indexStartAt], B[0], 2);

    strLength := TMQTTUtilities.MSBLSBToInt(B);
    if strLength > 0 then
    begin
      SetString(stringRead, PAnsiChar(@dataStream[indexStartAt + 2]), strLength);
    end;
    setlength(B, 0);

    result := indexStartAt + strLength;
  end;
end;

// save qos=2  session
//
function TMQTT.SaveToFile(O: TMQTTBytes): string;
var
  f, ps: string;
  barray: TBytes;
  fs: TMemoryStream;
begin
  fs := TMemoryStream.Create;
  try
    AppendToByteArray(UInt16ToMSBLSB(O.MessageID), barray); // 2
    AppendToByteArray(UInt32ToMSBLSB(O.PushCount), barray); // 4
    AppendToByteArray(UInt64ToMSBLSB(O.TimeOut), barray); // 8

    AppendToByteArray(O.Bytes, barray);
    ps := ExtractFilePath(ParamStr(0)) + 'cache';

    // if not DirectoryExists(ps) then
    // CreateDir(ps);
    // 使用   System.IOUtils.TDirectory 和 平台脱离关系
    if not System.IOUtils.TDirectory.Exists(ps) then
      System.IOUtils.TDirectory.CreateDirectory(ps);

    f := ps + '\' + GetGUIDStr;
    fs.Write(barray, Length(barray));
    fs.SaveToFile(f);
  finally
    fs.Free;
  end;
  result := f;
end;

function TMQTT.ReadFromFile(f: string): PMQTTBytes;
var
  B: TBytes;
  fs: TMemoryStream;
  O: PMQTTBytes;
begin
  result := nil;
  if not FileExists(f) then
    exit;
  fs := TMemoryStream.Create();
  try
    O := New(PMQTTBytes);
    fs.LoadFromFile(f);
    setlength(B, fs.Size);
    fs.Read(B, fs.Size);
    O.MessageID := MSBLSBToWord(Copy(B, 0, 2));
    O.PushCount := MSBLSBToUInt32(Copy(B, 2, 4));
    O.TimeOut := MSBLSBToUInt64(Copy(B, 6, 8));
    O.Bytes := Copy(B, 14, Length(B) - 14);
  finally
    fs.Free;
  end;
  result := O;
end;

procedure TMQTT.LoadCacheFileToSend();
var
  O: PMQTTBytes;
  f, dir: string;
  FileNameList: TStringList;
  i: Integer;
begin
  FileNameList := TStringList.Create;
  try
    dir := ExtractFilePath(ParamStr(0)) + 'cache\';
    searchfile(dir, FileNameList);
    // if Now()-TFile.GetCreationTime(f)
    // if  super MaxCacheFileSize , delete the cache and  file
    if FileNameList.Count > MaxCacheFileSize then
      for i := FileNameList.Count - 1 downto 0 do
      begin
        f := dir + FileNameList.Strings[i];
        System.IOUtils.TFile.Delete(f);
      end;

    for i := FileNameList.Count - 1 downto 0 do
    begin
      f := dir + FileNameList.Strings[i];
      O := ReadFromFile(f);
      if Assigned(O) then
      begin
        // todo resend and delete the file
        if WriteData(O.Bytes) then
        begin
          System.IOUtils.TFile.Delete(f);
          setlength(O.Bytes, 0);
          Dispose(O);
          FileNameList.Delete(i);
        end;
      end;
    end;
  finally
    FreeAndNil(FileNameList);
  end;

end;

procedure TMQTT.OnConnected(sender: TObject; AConnection: ICrossConnection);
begin
  FisConnected := true;
end;

procedure TMQTT.OnDisConnected(sender: TObject; AConnection: ICrossConnection);
begin
  FisConnected := false;
end;

procedure TMQTT.OnReceived(sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer);
var
  RevPack: PRevMsg;
begin
  if ALen > 0 then
  begin
    RevPack := New(PRevMsg);
    setlength(RevPack.Bytes, ALen);
    RevPack.Len := ALen;

    Move(ABuf^, Pointer(RevPack.Bytes)^, ALen);
    FRevQueue.Push(RevPack);

  end;

end;

function TMQTT.MqttHeaderIsLegal(FixHeader: Byte): boolean;
var
  HCode: Byte;
begin
  result := false;
  HCode := FixHeader shr 4;
  if (HCode > 0) or (HCode < 15) then
  begin
    result := true;
  end;

end;


procedure TMQTT.ReceiveBytesParse();
var
  i: Integer;
  RLInt: Integer;
  Buffer, B: TBytes;
  MsgPack: PUnparsedMsg;
  FHCode: Byte;
  RevPack: PRevMsg;
  FixIndex: Integer;
  FixHeaderIsLeagal: boolean;
  ALen: Integer;
  index, iUpperBnd: Integer;

begin

  RevPack := PRevMsg(FRevQueue.Pop);
  if RevPack = nil then
    exit;

  // insert tmpbuffer to revpack.bytes of header.
  if Length(ReceiveBuffer) > 0 then
  begin
    AppendToByteArray(ReceiveBuffer, B);
    AppendToByteArray(RevPack.Bytes, B);
    setlength(RevPack.Bytes, 0);
    RevPack.Len := Length(B);
    setlength(RevPack.Bytes, RevPack.Len);
    Move(B[0], RevPack.Bytes[0], Length(B));
    setlength(ReceiveBuffer, 0);
    setlength(B, 0);
  end;

  FixIndex := 0;
  FixHeaderIsLeagal := false;
  ALen := RevPack.Len;
  index := 0;

  while (ALen > 0) and (FixIndex < ALen) do
  begin
    // read fixed header

    index := FixIndex;
    MsgPack := New(PUnparsedMsg);
    FHCode := RevPack.Bytes[FixIndex];
    MsgPack.FixedHeader := FHCode;
    FixHeaderIsLeagal := MqttHeaderIsLegal(FHCode);
    if not FixHeaderIsLeagal then
    begin
      Inc(FixIndex);
      Continue;
    end;

    Inc(FixIndex);
    if FixIndex > ALen then
    begin
      setlength(B, ALen - index);
      Move(RevPack.Bytes[index], B[0], ALen - index);
      // save to tmp buffer
      AppendToByteArray(B, ReceiveBuffer);
      setlength(B, 0);
      setlength(MsgPack.RL, 0);
      setlength(MsgPack.data, 0);
      Dispose(MsgPack);

      setlength(RevPack.Bytes, 0);
      Dispose(RevPack);
      exit;
    end;
    // read remaining length
    setlength(MsgPack.RL, 1);
    setlength(Buffer, 1);
    MsgPack.RL[0] := RevPack.Bytes[FixIndex];

    // remain length max is 4 byte
    for i := 1 to 4 do
    begin
      if ((MsgPack.RL[i - 1] and 128) <> 0) then
      begin
        Inc(FixIndex);
        if FixIndex > ALen then
        begin
          setlength(B, ALen - index);
          Move(RevPack.Bytes[index], B[0], ALen - index);
          AppendToByteArray(B, ReceiveBuffer);
          setlength(B, 0);

          setlength(MsgPack.RL, 0);
          setlength(MsgPack.data, 0);
          Dispose(MsgPack);

          setlength(RevPack.Bytes, 0);
          Dispose(RevPack);

          exit;
        end;
        Buffer[0] := RevPack.Bytes[FixIndex];
        AppendBytes(MsgPack.RL, Buffer);
      end
      else
        Break;
    end;
    // remaining length
    RLInt := TMQTTUtilities.RLBytesToInt(MsgPack.RL);
    setlength(Buffer, 0);

    // read variable header  and  playload
    if (RLInt > 0) then
    begin
      if (ALen - (FixIndex + 1)) >= RLInt then
      begin
        if Assigned(MsgPack) then
        begin
          setlength(MsgPack.data, RLInt);
          Move(RevPack.Bytes[FixIndex + 1], MsgPack.data[0], RLInt);
        end;
      end
      else
      begin

        iUpperBnd := Length(ReceiveBuffer);
        setlength(ReceiveBuffer, iUpperBnd + (ALen - index));
        Move(RevPack.Bytes[index], ReceiveBuffer[iUpperBnd], ALen - index);

        setlength(MsgPack.RL, 0);
        setlength(MsgPack.data, 0);
        Dispose(MsgPack);

        setlength(RevPack.Bytes, 0);
        RevPack.Len := 0;
        Dispose(RevPack);
        exit;

      end;
    end;
    FQueue.Push(MsgPack);
    FixIndex := FixIndex + 1 + RLInt;
  end;
  setlength(RevPack.Bytes, 0);
  Dispose(RevPack);

end;

{ TMQTTRunThread }

constructor TProcessComeMsgThread.Create(ThreadProc: TMyProce);
begin
  inherited Create(true);
  FProc := ThreadProc;
  FreeOnTerminate := false;
end;

procedure TProcessComeMsgThread.Execute;
begin
  while not Terminated do
  begin
    Synchronize(FProc);
    sleep(1);
  end;

end;

{ TProcessRevMsgParseThread }

constructor TProcessRevMsgParseThread.Create(ThreadProc: TMyProce);
begin
  inherited Create(true);
  FProc := ThreadProc;
  FreeOnTerminate := false;
end;

procedure TProcessRevMsgParseThread.Execute;
begin
  while not Terminated do
  begin
    Synchronize(FProc);
    sleep(1);
  end;

end;

end.
