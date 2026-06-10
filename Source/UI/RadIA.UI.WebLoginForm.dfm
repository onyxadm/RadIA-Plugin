object FormWebLogin: TFormWebLogin
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'AI Provider Sign In'
  ClientHeight = 760
  ClientWidth = 980
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 76
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object btnDone: TSpeedButton
      AlignWithMargins = True
      Left = 856
      Top = 20
      Width = 132
      Height = 36
      Cursor = crHandPoint
      Margins.Left = 12
      Margins.Top = 20
      Margins.Right = 20
      Margins.Bottom = 20
      Align = alRight
      Caption = 'Use Current Session'
      Visible = False
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      OnClick = btnDoneClick
    end
    object lblTitle: TLabel
      Left = 20
      Top = 14
      Width = 248
      Height = 21
      Caption = 'Connect your provider account'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblInfo: TLabel
      Left = 20
      Top = 42
      Width = 640
      Height = 15
      Caption = 'Sign in using the official provider page below. RadIA will continue when the login is detected.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
  end
  object pnlBrowserContainer: TPanel
    AlignWithMargins = True
    Left = 16
    Top = 88
    Width = 948
    Height = 616
    Margins.Left = 16
    Margins.Top = 12
    Margins.Right = 16
    Margins.Bottom = 12
    Align = alClient
    BevelOuter = bvLowered
    TabOrder = 1
    object EdgeBrowser: TEdgeBrowser
      Left = 2
      Top = 2
      Width = 944
      Height = 612
      Align = alClient
      TabOrder = 0
    end
    object pnlBrowserFallback: TPanel
      Left = 2
      Top = 2
      Width = 944
      Height = 612
      Align = alClient
      BevelOuter = bvNone
      Caption = ''
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblFallbackTitle: TLabel
        Left = 172
        Top = 214
        Width = 600
        Height = 25
        Alignment = taCenter
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'Opening secure sign-in'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblFallbackInfo: TLabel
        Left = 202
        Top = 252
        Width = 540
        Height = 44
        Alignment = taCenter
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'If you are already signed in, use the current session. Otherwise wait for the provider page or retry the embedded browser.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        WordWrap = True
      end
      object btnUseSessionFallback: TSpeedButton
        Left = 318
        Top = 326
        Width = 148
        Height = 36
        Cursor = crHandPoint
        Caption = 'Use Current Session'
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnDoneClick
      end
      object btnRetryBrowser: TSpeedButton
        Left = 478
        Top = 326
        Width = 148
        Height = 36
        Cursor = crHandPoint
        Caption = 'Retry Browser'
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnRetryBrowserClick
      end
    end
  end
  object pnlFooter: TPanel
    Left = 0
    Top = 728
    Width = 980
    Height = 32
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblStatus: TLabel
      Left = 20
      Top = 8
      Width = 456
      Height = 15
      Caption = 'If you are already signed in, use the current browser session.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
end
