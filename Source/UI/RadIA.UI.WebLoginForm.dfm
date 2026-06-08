object FormWebLogin: TFormWebLogin
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Conex'#227'o do Provedor de IA'
  ClientHeight = 700
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnClose = FormClose
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 45
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object btnDone: TSpeedButton
      Left = 810
      Top = 10
      Width = 80
      Height = 25
      Cursor = crHandPoint
      Caption = 'Conclu'#237'do'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnDoneClick
    end
    object lblInfo: TLabel
      Left = 15
      Top = 13
      Width = 478
      Height = 15
      Caption = 
        'Fa'#231'a o login na sua conta oficial abaixo. Quando terminar de log' +
        'ar, clique em "Conclu'#237'do".'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
  end
  object pnlBrowserContainer: TPanel
    Left = 0
    Top = 45
    Width = 900
    Height = 655
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
  end
end
