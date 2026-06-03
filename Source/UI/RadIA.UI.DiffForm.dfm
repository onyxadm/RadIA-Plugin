object FormAIDiff: TFormAIDiff
  Left = 0
  Top = 0
  Caption = 'RadIA - Code Refactoring Comparison'
  ClientHeight = 600
  ClientWidth = 800
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
    Top = 550
    Width = 800
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnApply: TButton
      Left = 630
      Top = 12
      Width = 75
      Height = 25
      Caption = 'Apply'
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 715
      Top = 12
      Width = 75
      Height = 25
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlBrowser: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 550
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object EdgeBrowser: TEdgeBrowser
      Left = 0
      Top = 0
      Width = 800
      Height = 550
      Align = alClient
      TabOrder = 0
      OnCreateWebViewCompleted = EdgeBrowserCreateWebViewCompleted
    end
  end
end
