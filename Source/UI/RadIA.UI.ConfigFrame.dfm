object FrameAIConfig: TFrameAIConfig
  Left = 0
  Top = 0
  Width = 320
  Height = 620
  TabOrder = 0
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 320
    Height = 575
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object grpGemini: TGroupBox
      Left = 10
      Top = 10
      Width = 300
      Height = 75
      Caption = ' Google Gemini Settings '
      TabOrder = 0
      object lblGeminiKey: TLabel
        Left = 10
        Top = 22
        Width = 42
        Height = 13
        Caption = 'API Key:'
      end
      object edtGeminiKey: TEdit
        Left = 10
        Top = 41
        Width = 280
        Height = 21
        PasswordChar = '*'
        TabOrder = 0
      end
    end
    object grpOpenAI: TGroupBox
      Left = 10
      Top = 95
      Width = 300
      Height = 130
      Caption = ' OpenAI / Compatible Endpoint Settings '
      TabOrder = 1
      object lblOpenAIKey: TLabel
        Left = 10
        Top = 22
        Width = 42
        Height = 13
        Caption = 'API Key:'
      end
      object edtOpenAIKey: TEdit
        Left = 10
        Top = 41
        Width = 280
        Height = 21
        PasswordChar = '*'
        TabOrder = 0
      end
      object lblOpenAICustomUrl: TLabel
        Left = 10
        Top = 72
        Width = 134
        Height = 13
        Caption = 'Custom Base URL (optional):'
      end
      object edtOpenAICustomUrl: TEdit
        Left = 10
        Top = 91
        Width = 280
        Height = 21
        Hint = 'e.g.: http://localhost:1234/v1 (LM Studio), https://api.groq.com/openai/v1 (Groq)'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
      end
    end
    object grpClaude: TGroupBox
      Left = 10
      Top = 235
      Width = 300
      Height = 75
      Caption = ' Anthropic Claude Settings '
      TabOrder = 2
      object lblClaudeKey: TLabel
        Left = 10
        Top = 22
        Width = 42
        Height = 13
        Caption = 'API Key:'
      end
      object edtClaudeKey: TEdit
        Left = 10
        Top = 41
        Width = 280
        Height = 21
        PasswordChar = '*'
        TabOrder = 0
      end
    end
    object grpOllama: TGroupBox
      Left = 10
      Top = 320
      Width = 300
      Height = 75
      Caption = ' Ollama Local/Network Settings '
      TabOrder = 3
      object lblOllamaUrl: TLabel
        Left = 10
        Top = 22
        Width = 59
        Height = 13
        Caption = 'Server URL:'
      end
      object edtOllamaUrl: TEdit
        Left = 10
        Top = 41
        Width = 280
        Height = 21
        TabOrder = 0
      end
    end
    object grpSystemPrompt: TGroupBox
      Left = 10
      Top = 405
      Width = 300
      Height = 130
      Caption = ' Custom System Instructions '
      TabOrder = 4
      object memSystemPrompt: TMemo
        Left = 10
        Top = 22
        Width = 280
        Height = 98
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 575
    Width = 320
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnSave: TButton
      Left = 150
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Save'
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCancel: TButton
      Left = 235
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end
