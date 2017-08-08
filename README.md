  
 QQ: 394251165 
  
 Develop IDE Delphi 10.2 Version 25.0.26309.314 
**Features**
* [MQTT v3.1 - V3.1.1 compliant](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html)

**Future**
SSL
android



socket api use  Delphi-Cross-Socket 
 WiNDDRiVER(soulawing@gmail.com)
 https://github.com/winddriver/Delphi-Cross-Socket.git



# TMQTT 2 (ALPHA) for Delphi by Jamie I and  join

## Introduction

**WARNING: This is still considered ALPHA quality, and is NOT considered ready for *any real* use yet. All contributions and bug fix pull requests are appreciated.**


TMQTT is a non-visual Delphi Client Library for the IBM Websphere MQ Transport Telemetry protocol ( http://mqtt.org ). It allows you to connect to a Message Broker that uses MQTT such as the [Really Small Message Broker](http://alphaworks.ibm.com/tech/rsmb) which is freely available for evaluation purposes on IBM Alphaworks. Mosquitto is an open source MQTT 3.1 broker ( http://mosquitto.org/ ).

TMQTT is a complete re-write of the original TMQTTClient that I wrote and it is sufficiently different enough to release in parallel.

MQTT is an IoT protocol, further information can be found here: http://mqtt.org/
 

## Points of Note
you must test, but i tested.

## Usage
There is a sample VCL project included in the download but usage is relatively simple. 
This is a non-visual component so all you need to do is to put the TMQTT directory into your compiler paths and then put MQTT in your uses.

```delphi
uses MQTT;
var
  MQTTClient: TMQTT;
begin
  MQTT := TMQTT.Create('localhost', 1883);
 
  MQTT.WillTopic := '';
  MQTT.WillMsg := '';
  
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

```

Contact information: 394251165@qq.com