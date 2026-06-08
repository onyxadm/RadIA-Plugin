object FrameAIConfig: TFrameAIConfig
  Left = 0
  Top = 0
  Width = 630
  Height = 480
  TabOrder = 0
  object pgcSettings: TPageControl
    Left = 0
    Top = 0
    Width = 630
    Height = 480
    ActivePage = tsGemini
    Align = alClient
    TabOrder = 0
    object tsGemini: TTabSheet
      Caption = 'Gemini'
      TabVisible = False
      object pnlGemini: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblGeminiKey: TLabel
          Left = 16
          Top = 100
          Width = 43
          Height = 15
          Caption = 'API Key:'
        end
        object lnkGeminiGetKey: TLabel
          Left = 520
          Top = 100
          Width = 76
          Height = 15
          Cursor = crHandPoint
          Caption = 'Obter API Key'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlight
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsUnderline]
          ParentFont = False
          OnClick = lnkGeminiGetKeyClick
        end
        object grpGeminiAuthType: TRadioGroup
          Left = 16
          Top = 16
          Width = 580
          Height = 65
          Caption = ' Connection Method '
          Columns = 2
          ItemIndex = 0
          Items.Strings = (
            'API Key (BYOK)'
            'Web Login (Plus/Pro)')
          TabOrder = 0
          OnClick = grpGeminiAuthTypeClick
        end
        object edtGeminiKey: TEdit
          Left = 16
          Top = 119
          Width = 580
          Height = 23
          TabOrder = 1
        end
      end
    end
    object tsOpenAI: TTabSheet
      Caption = 'OpenAI'
      TabVisible = False
      object pnlOpenAI: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblOpenAIKey: TLabel
          Left = 16
          Top = 100
          Width = 43
          Height = 15
          Caption = 'API Key:'
        end
        object lnkOpenAIGetKey: TLabel
          Left = 520
          Top = 100
          Width = 76
          Height = 15
          Cursor = crHandPoint
          Caption = 'Obter API Key'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlight
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsUnderline]
          ParentFont = False
          OnClick = lnkOpenAIGetKeyClick
        end
        object lblOpenAICustomUrl: TLabel
          Left = 16
          Top = 160
          Width = 151
          Height = 15
          Caption = 'Custom Base URL (optional):'
        end
        object grpOpenAIAuthType: TRadioGroup
          Left = 16
          Top = 16
          Width = 580
          Height = 65
          Caption = ' Connection Method '
          Columns = 2
          ItemIndex = 0
          Items.Strings = (
            'API Key (BYOK)'
            'Web Login (Plus/Pro)')
          TabOrder = 0
          OnClick = grpOpenAIAuthTypeClick
        end
        object edtOpenAIKey: TEdit
          Left = 16
          Top = 119
          Width = 580
          Height = 23
          TabOrder = 1
        end
        object edtOpenAICustomUrl: TEdit
          Left = 16
          Top = 179
          Width = 575
          Height = 23
          Hint = 
            'e.g.: http://localhost:1234/v1 (LM Studio), https://api.groq.com' +
            '/openai/v1 (Groq)'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
        end
      end
    end
    object tsClaude: TTabSheet
      Caption = 'Claude'
      TabVisible = False
      object pnlClaude: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblClaudeKey: TLabel
          Left = 16
          Top = 24
          Width = 43
          Height = 15
          Caption = 'API Key:'
        end
        object lnkClaudeGetKey: TLabel
          Left = 520
          Top = 24
          Width = 76
          Height = 15
          Cursor = crHandPoint
          Caption = 'Obter API Key'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlight
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsUnderline]
          ParentFont = False
          OnClick = lnkClaudeGetKeyClick
        end
        object edtClaudeKey: TEdit
          Left = 16
          Top = 43
          Width = 580
          Height = 23
          TabOrder = 0
        end
      end
    end
    object tsDeepSeek: TTabSheet
      Caption = 'DeepSeek'
      TabVisible = False
      object pnlDeepSeek: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblDeepSeekKey: TLabel
          Left = 16
          Top = 24
          Width = 43
          Height = 15
          Caption = 'API Key:'
        end
        object lnkDeepSeekGetKey: TLabel
          Left = 520
          Top = 24
          Width = 76
          Height = 15
          Cursor = crHandPoint
          Caption = 'Obter API Key'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlight
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsUnderline]
          ParentFont = False
          OnClick = lnkDeepSeekGetKeyClick
        end
        object edtDeepSeekKey: TEdit
          Left = 16
          Top = 43
          Width = 580
          Height = 23
          TabOrder = 0
        end
      end
    end
    object tsGroq: TTabSheet
      Caption = 'Groq'
      TabVisible = False
      object pnlGroq: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblGroqKey: TLabel
          Left = 16
          Top = 24
          Width = 43
          Height = 15
          Caption = 'API Key:'
        end
        object lnkGroqGetKey: TLabel
          Left = 520
          Top = 24
          Width = 76
          Height = 15
          Cursor = crHandPoint
          Caption = 'Obter API Key'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlight
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsUnderline]
          ParentFont = False
          OnClick = lnkGroqGetKeyClick
        end
        object edtGroqKey: TEdit
          Left = 16
          Top = 43
          Width = 580
          Height = 23
          TabOrder = 0
        end
      end
    end
    object tsOllama: TTabSheet
      Caption = 'Ollama'
      TabVisible = False
      object pnlOllama: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
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
          Width = 580
          Height = 23
          TabOrder = 0
        end
      end
    end
    object tsOpenRouter: TTabSheet
      Caption = 'OpenRouter'
      TabVisible = False
      object pnlOpenRouter: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblOpenRouterKey: TLabel
          Left = 16
          Top = 24
          Width = 43
          Height = 15
          Caption = 'API Key:'
        end
        object lnkOpenRouterGetKey: TLabel
          Left = 520
          Top = 24
          Width = 76
          Height = 15
          Cursor = crHandPoint
          Caption = 'Obter API Key'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clHighlight
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsUnderline]
          ParentFont = False
          OnClick = lnkOpenRouterGetKeyClick
        end
        object edtOpenRouterKey: TEdit
          Left = 16
          Top = 43
          Width = 580
          Height = 23
          TabOrder = 0
        end
      end
    end
    object tsLMStudio: TTabSheet
      Caption = 'LM Studio'
      TabVisible = False
      object pnlLMStudio: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblLMStudioUrl: TLabel
          Left = 16
          Top = 24
          Width = 62
          Height = 15
          Caption = 'Server URL:'
        end
        object edtLMStudioUrl: TEdit
          Left = 16
          Top = 43
          Width = 580
          Height = 23
          TabOrder = 0
        end
      end
    end
    object tsGithubCopilot: TTabSheet
      Caption = 'GitHub Copilot'
      TabVisible = False
      object pnlGithubCopilot: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblGithubCopilotKey: TLabel
          Left = 16
          Top = 100
          Width = 320
          Height = 15
          Caption = 'GitHub User Token (ghu_... or gho_...):'
        end
        object edtGithubCopilotKey: TEdit
          Left = 16
          Top = 119
          Width = 580
          Height = 23
          TabOrder = 0
        end
        object btnConnectGithub: TButton
          Left = 16
          Top = 24
          Width = 200
          Height = 30
          Caption = 'Conectar Conta do GitHub'
          TabOrder = 1
          OnClick = btnConnectGithubClick
        end
        object btnImportVSCode: TButton
          Left = 230
          Top = 24
          Width = 180
          Height = 30
          Caption = 'Importar do VS Code'
          TabOrder = 2
          OnClick = btnImportVSCodeClick
        end
      end
    end
    object tsSystemPrompt: TTabSheet
      Caption = 'System'
      TabVisible = False
      object pnlSystemPrompt: TPanel
        Left = 0
        Top = 0
        Width = 622
        Height = 472
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object memSystemPrompt: TMemo
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 616
          Height = 466
          Align = alClient
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
    object tsTemplates: TTabSheet
      Caption = 'Templates'
      TabVisible = False
      object pnlTemplatesLeft: TPanel
        Left = 0
        Top = 0
        Width = 180
        Height = 470
        Align = alLeft
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lstTemplates: TListBox
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 174
          Height = 424
          Align = alClient
          ItemHeight = 15
          TabOrder = 0
          OnClick = lstTemplatesClick
        end
        object pnlTemplatesLeftButtons: TPanel
          Left = 0
          Top = 430
          Width = 180
          Height = 40
          Align = alBottom
          BevelOuter = bvNone
          ShowCaption = False
          TabOrder = 1
          object btnNewTemplate: TButton
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 84
            Height = 34
            Align = alLeft
            Caption = 'New'
            TabOrder = 0
            OnClick = btnNewTemplateClick
          end
          object btnDeleteTemplate: TButton
            AlignWithMargins = True
            Left = 93
            Top = 3
            Width = 84
            Height = 34
            Align = alClient
            Caption = 'Delete'
            TabOrder = 1
            OnClick = btnDeleteTemplateClick
          end
        end
      end
      object pnlTemplatesClient: TPanel
        Left = 180
        Top = 0
        Width = 442
        Height = 470
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 1
        object lblTemplateName: TLabel
          Left = 14
          Top = 6
          Width = 87
          Height = 15
          Caption = 'Template Name:'
        end
        object lblTemplateDesc: TLabel
          Left = 14
          Top = 56
          Width = 63
          Height = 15
          Caption = 'Description:'
        end
        object lblTemplateBody: TLabel
          Left = 14
          Top = 106
          Width = 52
          Height = 15
          Caption = 'Template:'
        end
        object edtTemplateName: TEdit
          Left = 14
          Top = 24
          Width = 425
          Height = 23
          TabOrder = 0
        end
        object edtTemplateDesc: TEdit
          Left = 14
          Top = 74
          Width = 425
          Height = 23
          TabOrder = 1
        end
        object memTemplateBody: TMemo
          Left = 14
          Top = 124
          Width = 425
          Height = 235
          ScrollBars = ssVertical
          TabOrder = 2
        end
        object btnSaveTemplate: TButton
          Left = 14
          Top = 377
          Width = 110
          Height = 28
          Caption = 'Save Template'
          TabOrder = 3
          OnClick = btnSaveTemplateClick
        end
        object btnRestoreDefaults: TButton
          Left = 319
          Top = 377
          Width = 120
          Height = 28
          Caption = 'Restore Defaults'
          TabOrder = 4
          OnClick = btnRestoreDefaultsClick
        end
      end
    end
  end
end
