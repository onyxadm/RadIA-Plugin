object FormGithubAuth: TFormGithubAuth
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'GitHub Copilot Authentication'
  ClientHeight = 260
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 15
  object pnlClient: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 260
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 16
      Width = 360
      Height = 21
      Alignment = taCenter
      AutoSize = False
      Caption = 'GitHub Copilot Device Login'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblInstructions: TLabel
      Left = 20
      Top = 50
      Width = 360
      Height = 40
      Alignment = taCenter
      AutoSize = False
      Caption = 
        '1. Copy the authentication code shown below.'#13#10'2. Click the button below to open GitHub and enter the code.'
      WordWrap = True
    end
    object lblPIN: TLabel
      Left = 20
      Top = 100
      Width = 360
      Height = 32
      Alignment = taCenter
      AutoSize = False
      Caption = '0000-0000'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clHighlight
      Font.Height = -24
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblStatus: TLabel
      Left = 20
      Top = 180
      Width = 360
      Height = 15
      Alignment = taCenter
      AutoSize = False
      Caption = 'Waiting for authorization...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object btnOpenBrowser: TButton
      Left = 60
      Top = 142
      Width = 280
      Height = 30
      Caption = 'Open GitHub Activation Page'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnOpenBrowserClick
    end
    object btnCancel: TButton
      Left = 160
      Top = 215
      Width = 80
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end
