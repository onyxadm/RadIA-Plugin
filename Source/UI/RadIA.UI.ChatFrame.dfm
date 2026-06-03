object FrameAIChat: TFrameAIChat
  Left = 0
  Top = 0
  Width = 997
  Height = 649
  TabOrder = 0
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 997
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = -3
    ExplicitWidth = 873
    object btnTemplates: TSpeedButton
      AlignWithMargins = True
      Left = 848
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
      Left = 886
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
      Left = 924
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
      Left = 962
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
      Width = 135
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
      Left = 147
      Top = 10
      Width = 164
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
    Top = 544
    Width = 991
    Height = 102
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitLeft = 0
    ExplicitTop = 498
    ExplicitWidth = 320
    object lblContext: TLabel
      Left = 0
      Top = 0
      Width = 991
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
    object btnSend: TSpeedButton
      AlignWithMargins = True
      Left = 940
      Top = 16
      Width = 48
      Height = 83
      Align = alRight
      Caption = #10148
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -26
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      ParentFont = False
      OnClick = btnSendClick
      ExplicitLeft = 272
      ExplicitHeight = 86
    end
    object memPrompt: TMemo
      AlignWithMargins = True
      Left = 3
      Top = 16
      Width = 931
      Height = 83
      Align = alClient
      BorderStyle = bsNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 0
      ExplicitTop = 19
      ExplicitWidth = 813
    end
  end
  object pnlBrowser: TPanel
    Left = 0
    Top = 44
    Width = 997
    Height = 497
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitWidth = 320
    ExplicitHeight = 454
    object EdgeBrowser: TEdgeBrowser
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 991
      Height = 491
      Align = alClient
      TabOrder = 0
      AllowSingleSignOnUsingOSPrimaryAccount = False
      TargetCompatibleBrowserVersion = '137.0.3296.44'
      UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
      OnCreateWebViewCompleted = EdgeBrowserCreateWebViewCompleted
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 320
      ExplicitHeight = 454
    end
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'md'
    Filter = 'Markdown File (*.md)|*.md|HTML File (*.html)|*.html'
    Left = 150
    Top = 200
  end
end
