unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  System.Hash, Generics.Collections,
  MQTT;

type
  TfMain = class(TForm)
    lblHeader: TLabel;
    lblSynapse: TLabel;
    btnConnect: TButton;
    btnDisconnect: TButton;
    btnPublish: TButton;
    eTopic: TEdit;
    eMessage: TEdit;
    eIP: TEdit;
    ePort: TEdit;
    btnPing: TButton;
    btnSubscribe: TButton;
    eSubTopic: TEdit;
    mStatus: TMemo;
    edt_Secretkey: TEdit;
    edt_Uid: TEdit;
    edt_appkey: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    edt_qos: TEdit;
    UnSubscribe: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Label8: TLabel;
    edt_UserName: TEdit;
    Label9: TLabel;
    edt_TestPassWord: TEdit;
    PublishBytes: TButton;
    Button1: TButton;
    Button2: TButton;
    Timer1: TTimer;
    Label10: TLabel;
    Button3: TButton;
    Button4: TButton;
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnPingClick(Sender: TObject);
    procedure btnPublishClick(Sender: TObject);
    procedure btnSubscribeClick(Sender: TObject);
    procedure GotConnAck(Sender: TObject; ReturnCode: integer);
    procedure GotPingResp(Sender: TObject);
    procedure GotPingReq(Sender: TObject);
    procedure GotSubAck(Sender: TObject; MessageID: integer; GrantedQoS: Array of integer);
    procedure GotUnSubAck(Sender: TObject; MessageID: integer);
    procedure GotPub(Sender: TObject; topic: string; PackageId: integer; payload: string; QOS: integer);
    procedure GotPubBytes(Sender: TObject; topic: string; PackageId: integer; payload: TBytes; QOS: integer);

    procedure GotPubAck(Sender: TObject; MessageID: integer);
    procedure GotPubRec(Sender: TObject; MessageID: integer);
    procedure GotPubRel(Sender: TObject; MessageID: integer);
    procedure GotPubComp(Sender: TObject; MessageID: integer);
    procedure UnSubscribeClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PublishBytesClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    function GetCurrentDateTime: string;
    procedure GotPubAckSend(Sender: TObject; MessageID: integer);
    procedure GotPubCompSend(Sender: TObject; MessageID: integer);
    procedure GotPubRecSend(Sender: TObject; MessageID: integer);
    procedure GotPubRelSend(Sender: TObject; MessageID: integer);
    procedure GotPubSend(Sender: TObject; topic: string; PackageId: integer; payload: string; QOS: integer);
    procedure GotSubSend(Sender: TObject; MessageID: integer; Topics: TDictionary<String, integer>);
    procedure GotUnSubSend(Sender: TObject; MessageID: integer; Topics: TStringList);
    procedure GoConnect(Sender: TObject; IP: string; Port: integer; isConnected: boolean);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fMain: TfMain;
  MQTT: TMQTT;
  Rcv: UInt64;
  Send: UInt64;

implementation

{$R *.dfm}

uses MQTTHeaders;

function md5string(str: string): string;
var
  md5: THashMD5;
begin
  md5 := THashMD5.Create;
  md5.Update(str);
  result := md5.HashAsString;
end;

procedure TfMain.btnConnectClick(Sender: TObject);
var
  appkey, secretkey, uid: string;
  platformType: string;
begin

  MQTT := TMQTT.Create(eIP.Text, StrToInt(ePort.Text));
  MQTT.WillTopic := '';
  MQTT.WillMsg := '';

  appkey := edt_appkey.Text;
  secretkey := edt_Secretkey.Text;
  uid := edt_Uid.Text;

  // 192.168.199.122
  MQTT.Username := edt_UserName.Text;
  MQTT.Password := edt_TestPassWord.Text;
  MQTT.ClientID := edt_UserName.Text;

  // Events
  MQTT.OnConnAck := GotConnAck;
  MQTT.OnPublishBytes := GotPubBytes;
  MQTT.OnPubAck := GotPubAck;
  MQTT.OnPubRec := GotPubRec;
  MQTT.OnPubRel := GotPubRel;
  MQTT.OnPubComp := GotPubComp;

  MQTT.OnPingReq := GotPingReq;
  MQTT.OnPingResp := GotPingResp;
  MQTT.OnSubAck := GotSubAck;
  MQTT.OnUnSubAck := GotUnSubAck;

  MQTT.OnPubAckSend := GotPubAckSend;
  MQTT.OnPubRecSend := GotPubRecSend;
  MQTT.OnPubRelSend := GotPubRelSend;
  MQTT.OnPubCompSend := GotPubCompSend;
  MQTT.OnPublishSend := GotPubSend;
  MQTT.OnSubSend := GotSubSend;
  MQTT.OnUnSubSend := GotUnSubSend;

  MQTT.OnConnect := GoConnect;

  MQTT.Connect();

end;

procedure TfMain.GoConnect(Sender: TObject; IP: string; Port: integer; isConnected: boolean);
begin
  if isConnected then
    mStatus.Lines.Add(GetCurrentDateTime + ': send >> Connected to ' + IP + ' on ' + inttostr(Port))
  else
    mStatus.Lines.Add(GetCurrentDateTime + ': send >> Failed to connect');

end;

function TfMain.GetCurrentDateTime(): string;
begin
  result := FormatDateTime('yyyy-mm-dd hh:nn:ss', now());

end;

procedure TfMain.btnDisconnectClick(Sender: TObject);
begin
  if (Assigned(MQTT)) then
  begin
    if MQTT.Disconnect then
    begin
      mStatus.Lines.Add(GetCurrentDateTime + ': send >> Disconnected');
    end;
  end;
end;

procedure TfMain.btnPingClick(Sender: TObject);
begin
  if (Assigned(MQTT)) then
  begin
    mStatus.Lines.Add(GetCurrentDateTime + ': send >> Ping');
    MQTT.PingReq;
  end;
end;

procedure TfMain.btnPublishClick(Sender: TObject);
begin
  if (Assigned(MQTT)) then
  begin
    MQTT.Publish(eTopic.Text, eMessage.Text, StrToInt(edt_qos.Text));
  end;
end;

procedure TfMain.btnSubscribeClick(Sender: TObject);
begin
  if (Assigned(MQTT)) then
  begin
    if MQTT.Subscribe(eSubTopic.Text, StrToInt(edt_qos.Text)) = -1 then
    begin
      mStatus.Lines.Add(GetCurrentDateTime + ': send  << Subscribe: QOS must is [0,2],current qos is ' +
        edt_qos.Text + '  or  topic is empty string and includ $ char. ');
    end;
  end;
end;

procedure TfMain.Button1Click(Sender: TObject);
begin
  mStatus.Clear;
  Rcv := 0;
  self.Caption := '';
end;

procedure TfMain.Button2Click(Sender: TObject);
var
  b: TBytes;
  i: UInt64;
  dt: int64;
  sendCount: UInt64;
begin
  // setlength(b, 5);
  // b[0] := ord('h');
  // b[1] := ord('e');
  // b[2] := ord('l');
  // b[3] := ord('l');
  // b[4] := ord('o');

  setlength(b, 1024);
  for i := 1 to 1024 do
  begin
    b[i - 1] := i;
  end;

  Send := 0;
  if (Assigned(MQTT)) then
  begin
    dt := GetTickCount;
    for i := 1 to 10000 do // 100000
    // while true do
    begin
      Application.ProcessMessages;
      if not MQTT.Publish(eTopic.Text, b, StrToInt(edt_qos.Text)) then
      begin
        // sleep(1000);
        continue;
      end
      else
      begin
        sendCount := i;
        inc(Send);
        self.Caption := 'send count:(' + inttostr(i) + ')';
      end;

    end;

    mStatus.Clear;
    mStatus.Lines.Add('send count:(' + inttostr(i - 1) + '), times:' + floattostr((GetTickCount - dt) / 1000));
    mStatus.Lines.Add('per send count:' + floattostr(10000 / ((GetTickCount - dt) / 1000)) + '/s');
    setlength(b, 0);
  end;

end;

procedure TfMain.Button3Click(Sender: TObject);
begin
  if MQTT <> nil then
  begin
    // Label10.Caption := inttostr(MQTT.PublishMessageCount);
    // MQTT.GStringList.SaveToFile(ExtractFilePath(ParamStr(0)) + 'pulish.txt');
    // MQTT.GStringList.Clear;
  end;
end;

procedure TfMain.Button4Click(Sender: TObject);
var
  b, b2: TBytes;
  i, y: integer;
begin
  b := TMQTTUtilities.RLIntToBytes(268435455);
  for i := 1 to 4 do
  begin
    if ((b[i - 1] and 128) <> 0) then
    begin

      y := b[i - 1];
      ShowMessage(inttostr(y));
      // i := TMQTTUtilities.RLBytesToInt(b);
    end;
  end;

  // i := TMQTTUtilities.RLBytesToInt(b);

  setlength(b, 4);
  setlength(b2, 1);

  b2[0] := 89;
  b2[1] := 99;

  Move(b[0], b[2], 2);
  Move(b2[0], b[0], 2);

end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  if MQTT <> nil then
    MQTT.Destroy;
end;

procedure TfMain.GotConnAck(Sender: TObject; ReturnCode: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << Connection Acknowledged: ' + inttostr(ReturnCode));
end;

procedure TfMain.GotPingReq(Sender: TObject);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': send >>PING');
end;

procedure TfMain.GotPingResp(Sender: TObject);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << PONG');
end;

procedure TfMain.GotSubSend(Sender: TObject; MessageID: integer; Topics: TDictionary<String, integer>);
var
  sTopic, SubStr: string;
begin
  SubStr := '';
  for sTopic in Topics.Keys do
  begin
    SubStr := SubStr + ' [topic:' + sTopic + ',qos:' + inttostr(Topics.Items[sTopic]) + '] ';
  end;

  mStatus.Lines.Add(GetCurrentDateTime + ': send >> Subscribe  on ' + SubStr + ', package id=' + inttostr(MessageID));

end;

procedure TfMain.GotUnSubSend(Sender: TObject; MessageID: integer; Topics: TStringList);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': send >> UnSubscribe  on  topic:' + Topics.Text + ', package id=' +
    inttostr(MessageID));
end;

procedure TfMain.PublishBytesClick(Sender: TObject);
var
  b: TBytes;
begin
  setlength(b, 5);
  b[0] := ord('h');
  b[1] := ord('e');
  b[2] := ord('l');
  b[3] := ord('l');
  b[4] := ord('o');
  if (Assigned(MQTT)) then
  begin
    MQTT.Publish(eTopic.Text, b, StrToInt(edt_qos.Text));
    setlength(b, 0);
  end;
end;

procedure TfMain.Timer1Timer(Sender: TObject);
begin
  if MQTT <> nil then
  begin
    // Label10.Caption := inttostr(MQTT.PublishMessageCount);
    // MQTT.GStringList.SaveToFile(ExtractFilePath(ParamStr(0)) + 'pulish.txt');
  end;
end;

procedure TfMain.GotPubSend(Sender: TObject; topic: string; PackageId: integer; payload: string; QOS: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': send >> publish message on topic:' + string(topic) + ', PackageId:' +
    inttostr(PackageId) + ', qos:' + inttostr(QOS) + ', payload: ' + string(payload));
end;

procedure TfMain.GotPub(Sender: TObject; topic: string; PackageId: integer; payload: string; QOS: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << publish message on topic:' + string(topic) + ', PackageId:' +
    inttostr(PackageId) + ', qos:' + inttostr(QOS) + ', payload: ' + string(payload));
end;

procedure TfMain.GotPubAck(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << PubAck package id=' + inttostr(MessageID));
end;

procedure TfMain.GotPubComp(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << PubComp package id= ' + inttostr(MessageID));
end;

procedure TfMain.GotPubRec(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << PubRec package id=' + inttostr(MessageID));
end;

procedure TfMain.GotPubRel(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << PubRel package id=' + inttostr(MessageID));
end;

procedure TfMain.GotPubAckSend(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': send >> PubAck package id=' + inttostr(MessageID));
end;

procedure TfMain.GotPubBytes(Sender: TObject; topic: string; PackageId: integer; payload: TBytes; QOS: integer);
var
  cnt: Ansistring;
begin
  inc(Rcv);
  self.Caption := ' rcv count:(' + inttostr(Rcv) + ')';

  SetString(cnt, PAnsiChar(@payload[0]), length(payload));
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << publish message on topic:' + string(topic) + ', PackageId:' +
    inttostr(PackageId) + ', qos:' + inttostr(QOS) + ', payload: ' + string(cnt));

end;

procedure TfMain.GotPubCompSend(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': send >> PubComp package id= ' + inttostr(MessageID));
end;

procedure TfMain.GotPubRecSend(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': send >> PubRec package id=' + inttostr(MessageID));
end;

procedure TfMain.GotPubRelSend(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': send >> PubRel package id=' + inttostr(MessageID));
end;

procedure TfMain.GotSubAck(Sender: TObject; MessageID: integer; GrantedQoS: array of integer);
var
  i: integer;
  QOS: string;
begin
  for i := Low(GrantedQoS) to High(GrantedQoS) do
  begin
    QOS := QOS + inttostr(GrantedQoS[i]) + ' ';
  end;
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << SubAck package id=' + inttostr(MessageID) + ' qos=' + QOS);
end;

procedure TfMain.GotUnSubAck(Sender: TObject; MessageID: integer);
begin
  mStatus.Lines.Add(GetCurrentDateTime + ': rev  << UnSubAck ' + inttostr(MessageID));
end;

procedure TfMain.UnSubscribeClick(Sender: TObject);
begin
  if (Assigned(MQTT)) then
  begin
    MQTT.UnSubscribe(eSubTopic.Text);
    mStatus.Lines.Add(GetCurrentDateTime + ': send >> UnSubscribe');
  end;
end;

end.
