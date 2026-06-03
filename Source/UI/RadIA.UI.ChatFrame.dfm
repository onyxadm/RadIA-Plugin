object FrameAIChat: TFrameAIChat
  Left = 0
  Top = 0
  Width = 320
  Height = 600
  TabOrder = 0
  object pnlToolbar: TPanel
    Left = 0
    Top = 0
    Width = 320
    Height = 35
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object cbProvider: TComboBox
      Left = 5
      Top = 6
      Width = 65
      Height = 22
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbProviderChange
    end
    object cbModel: TComboBox
      Left = 75
      Top = 6
      Width = 80
      Height = 22
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbModelChange
    end
    object btnTemplates: TButton
      Left = 160
      Top = 5
      Width = 30
      Height = 24
      Caption = 'Tpl'
      TabOrder = 2
      OnClick = btnTemplatesClick
    end
    object btnExport: TButton
      Left = 195
      Top = 5
      Width = 40
      Height = 24
      Caption = 'Export'
      TabOrder = 3
      OnClick = btnExportClick
    end
    object btnClear: TButton
      Left = 238
      Top = 5
      Width = 38
      Height = 24
      Caption = 'Clear'
      TabOrder = 4
      OnClick = btnClearClick
    end
    object btnSettings: TButton
      Left = 278
      Top = 5
      Width = 38
      Height = 24
      Caption = 'Setup'
      TabOrder = 5
      OnClick = btnSettingsClick
    end
  end
  object SaveDialog: TSaveDialog
    Filter = 'Markdown File (*.md)|*.md|HTML File (*.html)|*.html'
    DefaultExt = 'md'
    Left = 150
    Top = 200
  end
  object pnlInput: TPanel
    Left = 0
    Top = 500
    Width = 320
    Height = 100
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object lblContext: TLabel
      Left = 0
      Top = 0
      Width = 320
      Height = 13
      Align = alTop
      Caption = '  Ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ExplicitWidth = 33
    end
    object memPrompt: TMemo
      Left = 0
      Top = 13
      Width = 260
      Height = 87
      Align = alClient
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object btnSend: TButton
      Left = 260
      Top = 13
      Width = 60
      Height = 87
      Align = alRight
      Caption = 'Send'
      TabOrder = 1
      OnClick = btnSendClick
    end
  end
  object pnlBrowser: TPanel
    Left = 0
    Top = 35
    Width = 320
    Height = 465
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object EdgeBrowser: TEdgeBrowser
      Left = 0
      Top = 0
      Width = 320
      Height = 465
      Align = alClient
      TabOrder = 0
      OnCreateWebViewCompleted = EdgeBrowserCreateWebViewCompleted
      OnWebMessageReceived = EdgeBrowserWebMessageReceived
    end
  end
end
