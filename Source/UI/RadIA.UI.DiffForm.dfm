object FormAIDiff: TFormAIDiff
  Left = 0
  Top = 0
  Caption = 'Rad IA - Smart Diff'
  ClientHeight = 620
  ClientWidth = 860
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlFooter: TPanel
    Left = 0
    Top = 568
    Width = 860
    Height = 52
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object lblSeparator: TLabel
      Left = 0
      Top = 0
      Width = 860
      Height = 1
      Align = alTop
      Caption = ''
    end
    object btnPrevConflict: TButton
      Left = 8
      Top = 10
      Width = 130
      Height = 32
      Caption = #8592' Previous'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      Hint = 'Bloco anterior com diff'
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = btnPrevConflictClick
    end
    object btnNextConflict: TButton
      Left = 146
      Top = 10
      Width = 130
      Height = 32
      Caption = 'Next '#8594
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      Hint = 'Pr'#243'ximo bloco com diff'
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = btnNextConflictClick
    end
    object btnApply: TButton
      Left = 620
      Top = 10
      Width = 148
      Height = 32
      Caption = #10003' Apply Changes'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Symbol'
      Font.Style = [fsBold]
      Hint = 'Aplicar altera'#231#245'es no editor'
      ModalResult = 1
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object btnCancel: TButton
      Left = 776
      Top = 10
      Width = 76
      Height = 32
      Caption = #10007' Cancel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      Hint = 'Descartar sugest'#227'o'
      ModalResult = 2
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
    end
  end
  object pnlBrowser: TPanel
    Left = 0
    Top = 0
    Width = 860
    Height = 568
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object EdgeBrowser: TEdgeBrowser
      Left = 0
      Top = 0
      Width = 860
      Height = 568
      Align = alClient
      TabOrder = 0
      OnCreateWebViewCompleted = EdgeBrowserCreateWebViewCompleted
    end
  end
end
