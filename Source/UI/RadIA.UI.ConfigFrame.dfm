object FrameAIConfig: TFrameAIConfig
  Left = 0
  Top = 0
  Width = 400
  Height = 380
  TabOrder = 0
  object pgcSettings: TPageControl
    Left = 0
    Top = 0
    Width = 400
    Height = 335
    ActivePage = tsGemini
    Align = alClient
    TabOrder = 0
    object tsGemini: TTabSheet
      Caption = 'Gemini'
      object grpGemini: TGroupBox
        Left = 0
        Top = 0
        Width = 392
        Height = 307
        Align = alClient
        Caption = ' Google Gemini Settings '
        TabOrder = 0
        object lblGeminiKey: TLabel
          Left = 16
          Top = 24
          Width = 42
          Height = 13
          Caption = 'API Key:'
        end
        object edtGeminiKey: TEdit
          Left = 16
          Top = 43
          Width = 360
          Height = 21
          PasswordChar = '*'
          TabOrder = 0
        end
      end
    end
    object tsOpenAI: TTabSheet
      Caption = 'OpenAI'
      object grpOpenAI: TGroupBox
        Left = 0
        Top = 0
        Width = 392
        Height = 307
        Align = alClient
        Caption = ' OpenAI / Compatible Endpoint Settings '
        TabOrder = 0
        object lblOpenAIKey: TLabel
          Left = 16
          Top = 24
          Width = 42
          Height = 13
          Caption = 'API Key:'
        end
        object edtOpenAIKey: TEdit
          Left = 16
          Top = 43
          Width = 360
          Height = 21
          PasswordChar = '*'
          TabOrder = 0
        end
        object lblOpenAICustomUrl: TLabel
          Left = 16
          Top = 80
          Width = 134
          Height = 13
          Caption = 'Custom Base URL (optional):'
        end
        object edtOpenAICustomUrl: TEdit
          Left = 16
          Top = 99
          Width = 360
          Height = 21
          Hint = 'e.g.: http://localhost:1234/v1 (LM Studio), https://api.groq.com/openai/v1 (Groq)'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
        end
      end
    end
    object tsClaude: TTabSheet
      Caption = 'Claude'
      object grpClaude: TGroupBox
        Left = 0
        Top = 0
        Width = 392
        Height = 307
        Align = alClient
        Caption = ' Anthropic Claude Settings '
        TabOrder = 0
        object lblClaudeKey: TLabel
          Left = 16
          Top = 24
          Width = 42
          Height = 13
          Caption = 'API Key:'
        end
        object edtClaudeKey: TEdit
          Left = 16
          Top = 43
          Width = 360
          Height = 21
          PasswordChar = '*'
          TabOrder = 0
        end
      end
    end
    object tsDeepSeek: TTabSheet
      Caption = 'DeepSeek'
      object grpDeepSeek: TGroupBox
        Left = 0
        Top = 0
        Width = 392
        Height = 307
        Align = alClient
        Caption = ' DeepSeek Settings '
        TabOrder = 0
        object lblDeepSeekKey: TLabel
          Left = 16
          Top = 24
          Width = 42
          Height = 13
          Caption = 'API Key:'
        end
        object edtDeepSeekKey: TEdit
          Left = 16
          Top = 43
          Width = 360
          Height = 21
          PasswordChar = '*'
          TabOrder = 0
        end
      end
    end
    object tsGroq: TTabSheet
      Caption = 'Groq'
      object grpGroq: TGroupBox
        Left = 0
        Top = 0
        Width = 392
        Height = 307
        Align = alClient
        Caption = ' Groq Settings '
        TabOrder = 0
        object lblGroqKey: TLabel
          Left = 16
          Top = 24
          Width = 42
          Height = 13
          Caption = 'API Key:'
        end
        object edtGroqKey: TEdit
          Left = 16
          Top = 43
          Width = 360
          Height = 21
          PasswordChar = '*'
          TabOrder = 0
        end
      end
    end
    object tsOllama: TTabSheet
      Caption = 'Ollama'
      object grpOllama: TGroupBox
        Left = 0
        Top = 0
        Width = 392
        Height = 307
        Align = alClient
        Caption = ' Ollama Local/Network Settings '
        TabOrder = 0
        object lblOllamaUrl: TLabel
          Left = 16
          Top = 24
          Width = 59
          Height = 13
          Caption = 'Server URL:'
        end
        object edtOllamaUrl: TEdit
          Left = 16
          Top = 43
          Width = 360
          Height = 21
          TabOrder = 0
        end
      end
    end
    object tsSystemPrompt: TTabSheet
      Caption = 'System'
      object grpSystemPrompt: TGroupBox
        Left = 0
        Top = 0
        Width = 392
        Height = 307
        Align = alClient
        Caption = ' Custom System Instructions '
        TabOrder = 0
        object memSystemPrompt: TMemo
          Left = 16
          Top = 24
          Width = 360
          Height = 260
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 335
    Width = 400
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnSave: TButton
      Left = 230
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Save'
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCancel: TButton
      Left = 315
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end
