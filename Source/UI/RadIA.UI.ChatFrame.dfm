object FrameAIChat: TFrameAIChat
  Left = 0
  Top = 0
  Width = 990
  Height = 650
  TabOrder = 0
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 990
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnTemplates: TSpeedButton
      AlignWithMargins = True
      Left = 841
      Top = 3
      Width = 32
      Height = 38
      Hint = 'Templates de Prompt'
      Align = alRight
      Caption = #9889
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -18
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = btnTemplatesClick
      ExplicitLeft = 178
      ExplicitTop = 6
      ExplicitHeight = 32
    end
    object btnExport: TSpeedButton
      AlignWithMargins = True
      Left = 879
      Top = 3
      Width = 32
      Height = 38
      Hint = 'Exportar Conversa'
      Align = alRight
      Caption = #10515
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -18
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = btnExportClick
      ExplicitLeft = 214
      ExplicitTop = 6
      ExplicitHeight = 32
    end
    object btnClear: TSpeedButton
      AlignWithMargins = True
      Left = 917
      Top = 3
      Width = 32
      Height = 38
      Hint = 'Limpar Hist'#243'rico'
      Align = alRight
      Caption = #9851
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -18
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = btnClearClick
      ExplicitLeft = 250
      ExplicitTop = 6
      ExplicitHeight = 32
    end
    object btnSettings: TSpeedButton
      AlignWithMargins = True
      Left = 955
      Top = 3
      Width = 32
      Height = 38
      Hint = 'Configura'#231#245'es'
      Align = alRight
      Caption = #9881
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -18
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = btnSettingsClick
      ExplicitLeft = 286
      ExplicitTop = 6
      ExplicitHeight = 32
    end
    object cbProvider: TComboBox
      Left = 6
      Top = 10
      Width = 105
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnChange = cbProviderChange
    end
    object cbModel: TComboBox
      Left = 117
      Top = 10
      Width = 289
      Height = 21
      Style = csDropDownList
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnChange = cbModelChange
    end
  end
  object pnlInput: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 537
    Width = 984
    Height = 110
    Align = alBottom
    BevelOuter = bvNone
    StyleElements = [seFont]
    TabOrder = 1
    object lblContext: TLabel
      Left = 0
      Top = 0
      Width = 984
      Height = 13
      Align = alTop
      Caption = '  Ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ExplicitWidth = 37
    end
    object shpInputBg: TShape
      Left = 10
      Top = 18
      Width = 964
      Height = 84
      Anchors = [akLeft, akTop, akRight, akBottom]
      Shape = stRoundRect
    end
    object shpSendBg: TShape
      Left = 944
      Top = 68
      Width = 28
      Height = 28
      Anchors = [akRight, akBottom]
      Shape = stCircle
    end
    object btnSend: TSpeedButton
      Left = 944
      Top = 68
      Width = 28
      Height = 28
      Cursor = crHandPoint
      Anchors = [akRight, akBottom]
      Caption = #11014
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
      Font.Name = 'Segoe UI Symbol'
      Font.Style = [fsBold]
      ParentFont = False
      StyleElements = [seFont]
      OnClick = btnSendClick
    end
    object memPrompt: TMemo
      Left = 20
      Top = 26
      Width = 910
      Height = 66
      Anchors = [akLeft, akTop, akRight, akBottom]
      BorderStyle = bsNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssNone
      TabOrder = 0
    end
  end
  object pnlBrowser: TPanel
    Left = 0
    Top = 44
    Width = 990
    Height = 493
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'md'
    Filter = 'Markdown File (*.md)|*.md|HTML File (*.html)|*.html'
    Left = 150
    Top = 200
  end
end
