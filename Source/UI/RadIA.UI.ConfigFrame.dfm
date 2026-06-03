object FrameAIConfig: TFrameAIConfig
  Left = 0
  Top = 0
  Width = 320
  Height = 450
  TabOrder = 0
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 320
    Height = 405
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
      Height = 75
      Caption = ' OpenAI ChatGPT Settings '
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
    end
    object grpClaude: TGroupBox
      Left = 10
      Top = 180
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
    object grpSystemPrompt: TGroupBox
      Left = 10
      Top = 265
      Width = 300
      Height = 130
      Caption = ' Custom System Instructions '
      TabOrder = 3
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
    Top = 405
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
