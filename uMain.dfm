object fMain: TfMain
  Left = 338
  Top = 156
  Caption = 'TMQTT Version V3.1.1(QOS=0/1/2)'
  ClientHeight = 443
  ClientWidth = 561
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 561
    Height = 313
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 9
      Top = 88
      Width = 41
      Height = 13
      Caption = 'AppKey:'
    end
    object Label2: TLabel
      Left = 6
      Top = 119
      Width = 53
      Height = 13
      Caption = 'SecretKey:'
    end
    object Label3: TLabel
      Left = 5
      Top = 151
      Width = 22
      Height = 13
      Caption = 'UID:'
    end
    object Label4: TLabel
      Left = 6
      Top = 227
      Width = 61
      Height = 13
      Caption = 'Publish Topic'
    end
    object Label5: TLabel
      Left = 6
      Top = 267
      Width = 78
      Height = 13
      Caption = 'Publish Message'
    end
    object Label6: TLabel
      Left = 145
      Top = 227
      Width = 75
      Height = 13
      Caption = 'SubScribe Topic'
    end
    object Label7: TLabel
      Left = 260
      Top = 227
      Width = 56
      Height = 13
      Caption = 'QOS(0/1/2)'
    end
    object lblHeader: TLabel
      Left = 8
      Top = 0
      Width = 410
      Height = 34
      Alignment = taCenter
      AutoSize = False
      Caption = 'MQTT-Client'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = [fsBold, fsUnderline]
      ParentFont = False
      Layout = tlCenter
    end
    object lblSynapse: TLabel
      Left = 8
      Top = 40
      Width = 402
      Height = 13
      Caption = 
        'You will need the Synapse Internet components to be in your proj' +
        'ect search paths. '
    end
    object Label8: TLabel
      Left = 5
      Top = 186
      Width = 53
      Height = 13
      Caption = 'UserName:'
    end
    object Label9: TLabel
      Left = 188
      Top = 185
      Width = 52
      Height = 13
      Caption = 'PassWord:'
    end
    object Label10: TLabel
      Left = 456
      Top = 112
      Width = 37
      Height = 13
      Caption = 'Label10'
      Visible = False
    end
    object btnConnect: TButton
      Left = 343
      Top = 56
      Width = 75
      Height = 25
      Caption = 'Connect'
      TabOrder = 0
      OnClick = btnConnectClick
    end
    object btnDisconnect: TButton
      Left = 343
      Top = 87
      Width = 75
      Height = 25
      Caption = 'Disconnect'
      TabOrder = 1
      OnClick = btnDisconnectClick
    end
    object btnPing: TButton
      Left = 343
      Top = 118
      Width = 75
      Height = 25
      Caption = 'Ping'
      TabOrder = 2
      OnClick = btnPingClick
    end
    object btnPublish: TButton
      Left = 343
      Top = 150
      Width = 75
      Height = 25
      Caption = 'Publish'
      TabOrder = 3
      OnClick = btnPublishClick
    end
    object btnSubscribe: TButton
      Left = 343
      Top = 224
      Width = 75
      Height = 25
      Caption = 'Subscribe'
      TabOrder = 4
      OnClick = btnSubscribeClick
    end
    object edt_appkey: TEdit
      Left = 56
      Top = 87
      Width = 281
      Height = 21
      TabOrder = 5
      Text = 'b51077f8-8028-944509'
    end
    object edt_qos: TEdit
      Left = 260
      Top = 246
      Width = 48
      Height = 21
      TabOrder = 6
      Text = '0'
    end
    object edt_Secretkey: TEdit
      Left = 56
      Top = 118
      Width = 281
      Height = 21
      TabOrder = 7
      Text = '0e57836981eec035db182b52877c9e7f'
    end
    object edt_Uid: TEdit
      Left = 56
      Top = 149
      Width = 281
      Height = 21
      TabOrder = 8
      Text = 'Fc5wGsTuvumomVomEtTWD4TKtyub7iWjR9'
    end
    object eIP: TEdit
      Left = 8
      Top = 58
      Width = 202
      Height = 21
      TabOrder = 9
      Text = '192.168.1.18'
    end
    object eMessage: TEdit
      Left = 6
      Top = 286
      Width = 329
      Height = 21
      TabOrder = 10
      Text = 'abc'
    end
    object ePort: TEdit
      Left = 216
      Top = 58
      Width = 121
      Height = 21
      TabOrder = 11
      Text = '1883'
    end
    object eSubTopic: TEdit
      Left = 144
      Top = 246
      Width = 110
      Height = 21
      TabOrder = 12
      Text = 'test'
    end
    object eTopic: TEdit
      Left = 6
      Top = 246
      Width = 121
      Height = 21
      TabOrder = 13
      Text = 'test'
    end
    object UnSubscribe: TButton
      Left = 343
      Top = 255
      Width = 75
      Height = 25
      Caption = 'UnSubscribe'
      TabOrder = 14
      OnClick = UnSubscribeClick
    end
    object edt_UserName: TEdit
      Left = 56
      Top = 184
      Width = 126
      Height = 21
      TabOrder = 15
      Text = 'testuser'
    end
    object edt_TestPassWord: TEdit
      Left = 246
      Top = 182
      Width = 91
      Height = 21
      TabOrder = 16
      Text = 'testpassword'
    end
    object PublishBytes: TButton
      Left = 343
      Top = 181
      Width = 75
      Height = 25
      Caption = 'PublishBytes'
      TabOrder = 17
      OnClick = PublishBytesClick
    end
    object Button1: TButton
      Left = 341
      Top = 286
      Width = 77
      Height = 25
      Caption = 'Clear'
      TabOrder = 18
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 456
      Top = 56
      Width = 89
      Height = 25
      Caption = 'PUBLISH(WHILE)'
      TabOrder = 19
      OnClick = Button2Click
    end
    object Button4: TButton
      Left = 456
      Top = 138
      Width = 89
      Height = 25
      Caption = 'test'
      TabOrder = 20
      Visible = False
      OnClick = Button4Click
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 313
    Width = 561
    Height = 130
    Align = alClient
    TabOrder = 1
    object mStatus: TMemo
      Left = 1
      Top = 1
      Width = 559
      Height = 128
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object Button3: TButton
    Left = 456
    Top = 107
    Width = 89
    Height = 25
    Caption = 'count'
    TabOrder = 2
    Visible = False
    OnClick = Button3Click
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100000
    OnTimer = Timer1Timer
    Left = 512
    Top = 104
  end
end
