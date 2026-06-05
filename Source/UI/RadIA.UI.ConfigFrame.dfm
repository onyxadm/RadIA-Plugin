object FormAIConfig: TFormAIConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'RadIA Configuration'
  ClientHeight = 520
  ClientWidth = 840
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object pnlSidebar: TPanel
    Left = 0
    Top = 0
    Width = 200
    Height = 487
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 2
    object tvCategories: TTreeView
      Left = 0
      Top = 0
      Width = 200
      Height = 487
      Align = alClient
      Indent = 19
      ReadOnly = True
      ShowLines = False
      TabOrder = 0
    end
  end
  object splSidebar: TSplitter
    Left = 200
    Top = 0
    Width = 3
    Height = 487
  end
  object pgcSettings: TPageControl
    AlignWithMargins = True
    Left = 206
    Top = 3
    Width = 631
    Height = 481
    ActivePage = tsGemini
    Align = alClient
    TabOrder = 0
    object tsGemini: TTabSheet
      Caption = 'Gemini'
      TabVisible = False
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
      TabVisible = False
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
      TabVisible = False
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
      TabVisible = False
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
      TabVisible = False
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
      TabVisible = False
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
      TabVisible = False
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
    object tsTemplates: TTabSheet
      Caption = 'Templates'
      TabVisible = False
      object pnlTemplatesLeft: TPanel
        Left = 0
        Top = 0
        Width = 180
        Height = 414
        Align = alLeft
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lstTemplates: TListBox
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 174
          Height = 368
          Align = alClient
          ItemHeight = 15
          TabOrder = 0
          OnClick = lstTemplatesClick
        end
        object pnlTemplatesLeftButtons: TPanel
          Left = 0
          Top = 374
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
        Width = 455
        Height = 414
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
  object pnlFooter: TPanel
    Left = 0
    Top = 487
    Width = 840
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
