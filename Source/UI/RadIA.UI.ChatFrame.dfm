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
    Height = 44
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object cbProvider: TComboBox
      Left = 6
      Top = 10
      Width = 70
      Height = 22
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
      Left = 80
      Top = 10
      Width = 90
      Height = 22
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
    object btnTemplates: TButton
      Left = 178
      Top = 9
      Width = 28
      Height = 26
      Caption = #9889
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      Hint = 'Templates de Prompt'
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = btnTemplatesClick
    end
    object btnExport: TButton
      Left = 210
      Top = 9
      Width = 28
      Height = 26
      Caption = #10515
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      Hint = 'Exportar Conversa'
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = btnExportClick
    end
    object btnClear: TButton
      Left = 242
      Top = 9
      Width = 28
      Height = 26
      Caption = #9851
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      Hint = 'Limpar Hist'#243'rico'
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = btnClearClick
    end
    object btnSettings: TButton
      Left = 274
      Top = 9
      Width = 28
      Height = 26
      Caption = #9881
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      Hint = 'Configura'#231#245'es'
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
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
    Top = 498
    Width = 320
    Height = 102
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object lblContext: TLabel
      Left = 0
      Top = 0
      Width = 320
      Height = 16
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
      Top = 16
      Width = 272
      Height = 86
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object btnSend: TButton
      Left = 272
      Top = 16
      Width = 48
      Height = 86
      Align = alRight
      Caption = #10148
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -18
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = btnSendClick
    end
  end
  object pnlBrowser: TPanel
    Left = 0
    Top = 44
    Width = 320
    Height = 454
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object EdgeBrowser: TEdgeBrowser
      Left = 0
      Top = 0
      Width = 320
      Height = 454
      Align = alClient
      TabOrder = 0
      OnCreateWebViewCompleted = EdgeBrowserCreateWebViewCompleted
      OnWebMessageReceived = EdgeBrowserWebMessageReceived
    end
  end
end
