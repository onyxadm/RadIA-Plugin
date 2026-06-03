object FormAIConfig: TFormAIConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'RadIA Configuration'
  ClientHeight = 483
  ClientWidth = 649
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  object pgcSettings: TPageControl
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 643
    Height = 444
    ActivePage = tsGemini
    Align = alClient
    TabOrder = 0
    TabWidth = 80
    object tsGemini: TTabSheet
      Caption = 'Gemini'
      object lblGeminiKey: TLabel
        Left = 16
        Top = 24
        Width = 43
        Height = 15
        Caption = 'API Key:'
      end
      object edtGeminiKey: TEdit
        Left = 16
        Top = 43
        Width = 360
        Height = 23
        TabOrder = 0
      end
    end
    object tsOpenAI: TTabSheet
      Caption = 'OpenAI'
      object lblOpenAIKey: TLabel
        Left = 16
        Top = 24
        Width = 43
        Height = 15
        Caption = 'API Key:'
      end
      object lblOpenAICustomUrl: TLabel
        Left = 16
        Top = 80
        Width = 151
        Height = 15
        Caption = 'Custom Base URL (optional):'
      end
      object edtOpenAIKey: TEdit
        Left = 16
        Top = 43
        Width = 360
        Height = 23
        TabOrder = 0
      end
      object edtOpenAICustomUrl: TEdit
        Left = 16
        Top = 99
        Width = 360
        Height = 23
        Hint = 
          'e.g.: http://localhost:1234/v1 (LM Studio), https://api.groq.com' +
          '/openai/v1 (Groq)'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
      end
    end
    object tsClaude: TTabSheet
      Caption = 'Claude'
      object lblClaudeKey: TLabel
        Left = 16
        Top = 24
        Width = 43
        Height = 15
        Caption = 'API Key:'
      end
      object edtClaudeKey: TEdit
        Left = 16
        Top = 43
        Width = 360
        Height = 23
        TabOrder = 0
      end
    end
    object tsDeepSeek: TTabSheet
      Caption = 'DeepSeek'
      object lblDeepSeekKey: TLabel
        Left = 16
        Top = 24
        Width = 43
        Height = 15
        Caption = 'API Key:'
      end
      object edtDeepSeekKey: TEdit
        Left = 16
        Top = 43
        Width = 360
        Height = 23
        TabOrder = 0
      end
    end
    object tsGroq: TTabSheet
      Caption = 'Groq'
      object lblGroqKey: TLabel
        Left = 16
        Top = 24
        Width = 43
        Height = 15
        Caption = 'API Key:'
      end
      object edtGroqKey: TEdit
        Left = 16
        Top = 43
        Width = 360
        Height = 23
        TabOrder = 0
      end
    end
    object tsOllama: TTabSheet
      Caption = 'Ollama'
      object lblOllamaUrl: TLabel
        Left = 16
        Top = 24
        Width = 59
        Height = 15
        Caption = 'Server URL:'
      end
      object edtOllamaUrl: TEdit
        Left = 16
        Top = 43
        Width = 360
        Height = 23
        TabOrder = 0
      end
    end
    object tsSystemPrompt: TTabSheet
      Caption = 'System'
      object memSystemPrompt: TMemo
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 629
        Height = 408
        Align = alClient
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitLeft = 16
        ExplicitTop = 24
        ExplicitWidth = 360
        ExplicitHeight = 260
      end
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 450
    Width = 649
    Height = 33
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnSave: TButton
      AlignWithMargins = True
      Left = 490
      Top = 3
      Width = 75
      Height = 27
      Align = alRight
      Caption = 'Save'
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCancel: TButton
      AlignWithMargins = True
      Left = 571
      Top = 3
      Width = 75
      Height = 27
      Align = alRight
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end
