unit RadIA.OTA.InlineCompletion;

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Graphics, Vcl.Menus, ToolsAPI;

type
  TRadIAInlineCompletionEditViewNotifier = class(TNotifierObject, IOTANotifier, INTAEditViewNotifier)
  private
    FView: IOTAEditView;
    FIndex: Integer;
    FFileName: string;
    procedure RemoveNotifier;
  public
    constructor Create(const AFileName: string; const AView: IOTAEditView);
    destructor Destroy; override;
    procedure AfterSave;
    procedure BeforeSave;
    procedure Modified;
    procedure Destroyed;
    procedure EditorIdle(const View: IOTAEditView);
    procedure BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);
    procedure PaintLine(const View: IOTAEditView; LineNumber: Integer;
      const LineText: PAnsiChar; const TextWidth: Word; const LineAttributes: TOTAAttributeArray;
      const Canvas: TCanvas; const TextRect: TRect; const LineRect: TRect; const CellSize: TSize);
    procedure EndPaint(const View: IOTAEditView);
  end;

  TRadIAInlineCompletionKeyboardBinding = class(TNotifierObject, IOTAKeyboardBinding)
  private
    procedure RequestCompletion(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
    procedure AcceptCompletion(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
    procedure CancelCompletion(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
  protected
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  public
    class function New: IOTAKeyboardBinding;
  end;

procedure RegisterInlineCompletionKeyboardBinding;
procedure UnregisterInlineCompletionKeyboardBinding;
procedure RefreshInlineCompletionKeyboardBinding;
function InlineCompletionShortcutFromText(const AText: string): TShortcut;

implementation

uses
  Winapi.Windows, RadIA.Core.Config, RadIA.Core.Interfaces, RadIA.Core.Types,
  RadIA.Core.InlineCompletion, RadIA.Core.InlineCompletionService, RadIA.Core.Logger,
  RadIA.OTA.Helper;

var
  GKeyboardBindingIndex: Integer = -1;

function InlineCompletionShortcutFromText(const AText: string): TShortcut;
var
  LText: string;
begin
  LText := AText.Trim.ToLower.Replace(' ', '');

  if (LText = 'alt+enter') or (LText = 'alt+return') then
    Exit(Shortcut(VK_RETURN, [ssAlt]));
  if (LText = 'ctrl+space') or (LText = 'control+space') then
    Exit(Shortcut(VK_SPACE, [ssCtrl]));
  if (LText = 'ctrl+alt+space') or (LText = 'control+alt+space') then
    Exit(Shortcut(VK_SPACE, [ssCtrl, ssAlt]));
  if (LText = 'ctrl+shift+space') or (LText = 'control+shift+space') then
    Exit(Shortcut(VK_SPACE, [ssCtrl, ssShift]));
  if (LText = 'ctrl+alt+enter') or (LText = 'control+alt+enter') or
     (LText = 'ctrl+alt+return') or (LText = 'control+alt+return') then
    Exit(Shortcut(VK_RETURN, [ssCtrl, ssAlt]));

  Result := TextToShortCut(AText);
end;

procedure RepaintCurrentView;
var
  LView: IOTAEditView;
begin
  LView := TRadIAOTAHelper.GetCurrentEditView;
  if Assigned(LView) then
    LView.Paint;
end;

procedure RegisterInlineCompletionKeyboardBinding;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if GKeyboardBindingIndex >= 0 then
    Exit;

  if Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    GKeyboardBindingIndex := LKeyboardServices.AddKeyboardBinding(TRadIAInlineCompletionKeyboardBinding.New);
end;

procedure UnregisterInlineCompletionKeyboardBinding;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if GKeyboardBindingIndex < 0 then
    Exit;

  if Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    LKeyboardServices.RemoveKeyboardBinding(GKeyboardBindingIndex);
  GKeyboardBindingIndex := -1;
end;

procedure RefreshInlineCompletionKeyboardBinding;
begin
  UnregisterInlineCompletionKeyboardBinding;
  RegisterInlineCompletionKeyboardBinding;
end;

function ReadEditBufferText(const AEditBuffer: IOTAEditBuffer; out AText: string): Boolean;
var
  LEditReader: IOTAEditReader;
  LBytes: TBytes;
  LBytesRead: Integer;
begin
  Result := False;
  AText := '';

  if not Assigned(AEditBuffer) then
    Exit;

  LEditReader := AEditBuffer.CreateReader;
  if not Assigned(LEditReader) then
    Exit;

  SetLength(LBytes, LEditReader.GetText(0, nil, 0));
  if Length(LBytes) = 0 then
  begin
    Result := True;
    Exit;
  end;

  LBytesRead := LEditReader.GetText(0, PAnsiChar(@LBytes[0]), Length(LBytes));
  SetLength(LBytes, LBytesRead);
  AText := TEncoding.UTF8.GetString(LBytes);
  Result := True;
end;

constructor TRadIAInlineCompletionEditViewNotifier.Create(const AFileName: string; const AView: IOTAEditView);
begin
  inherited Create;
  FView := AView;
  FFileName := AFileName;
  FIndex := -1;
  if Assigned(FView) then
    FIndex := FView.AddNotifier(Self);
end;

destructor TRadIAInlineCompletionEditViewNotifier.Destroy;
begin
  RemoveNotifier;
  inherited Destroy;
end;

procedure TRadIAInlineCompletionEditViewNotifier.RemoveNotifier;
begin
  if Assigned(FView) and (FIndex >= 0) then
  begin
    FView.RemoveNotifier(FIndex);
    FIndex := -1;
    FView := nil;
  end;
end;

procedure TRadIAInlineCompletionEditViewNotifier.AfterSave;
begin
end;

procedure TRadIAInlineCompletionEditViewNotifier.BeforeSave;
begin
end;

procedure TRadIAInlineCompletionEditViewNotifier.Modified;
begin
  TInlineCompletionSuggestionState.Instance.Clear;
end;

procedure TRadIAInlineCompletionEditViewNotifier.Destroyed;
begin
  RemoveNotifier;
end;

procedure TRadIAInlineCompletionEditViewNotifier.EditorIdle(const View: IOTAEditView);
var
  LActive: Boolean;
  LFileName: string;
  LText: string;
  LRow: Integer;
  LColumn: Integer;
begin
  TInlineCompletionSuggestionState.Instance.Snapshot(LActive, LFileName, LText, LRow, LColumn);
  if not LActive then
    Exit;

  if not Assigned(View) or not SameFileName(FFileName, LFileName) or
     (View.CursorPos.Line <> LRow) or (View.CursorPos.Col <> LColumn) then
  begin
    TInlineCompletionSuggestionState.Instance.Clear;
    RepaintCurrentView;
  end;
end;

procedure TRadIAInlineCompletionEditViewNotifier.BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);
begin
end;

procedure TRadIAInlineCompletionEditViewNotifier.PaintLine(const View: IOTAEditView; LineNumber: Integer;
  const LineText: PAnsiChar; const TextWidth: Word; const LineAttributes: TOTAAttributeArray;
  const Canvas: TCanvas; const TextRect: TRect; const LineRect: TRect; const CellSize: TSize);
var
  LActive: Boolean;
  LFileName: string;
  LText: string;
  LRow: Integer;
  LColumn: Integer;
  LFirstLine: string;
  LBreakPos: Integer;
begin
  TInlineCompletionSuggestionState.Instance.Snapshot(LActive, LFileName, LText, LRow, LColumn);
  if (not LActive) or (LineNumber <> LRow) or (not SameFileName(FFileName, LFileName)) then
    Exit;

  LFirstLine := LText;
  LBreakPos := Pos(sLineBreak, LFirstLine);
  if LBreakPos > 0 then
    LFirstLine := Copy(LFirstLine, 1, LBreakPos - 1);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := TColor(TRadIAConfig.GetInstance.GetAutocompleteSuggestionColor);
  Canvas.TextOut(TextRect.Left + ((LColumn - 1) * CellSize.cx), TextRect.Top, LFirstLine.TrimRight);
end;

procedure TRadIAInlineCompletionEditViewNotifier.EndPaint(const View: IOTAEditView);
begin
end;

class function TRadIAInlineCompletionKeyboardBinding.New: IOTAKeyboardBinding;
begin
  Result := Self.Create;
end;

function TRadIAInlineCompletionKeyboardBinding.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TRadIAInlineCompletionKeyboardBinding.GetDisplayName: string;
begin
  Result := 'RadIA Inline Completion';
end;

function TRadIAInlineCompletionKeyboardBinding.GetName: string;
begin
  Result := 'RadIA.InlineCompletion';
end;

procedure TRadIAInlineCompletionKeyboardBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
var
  LShortcut: TShortcut;
  LShortcutText: string;
begin
  LShortcutText := TRadIAConfig.GetInstance.GetAutocompleteShortcut;
  LShortcut := InlineCompletionShortcutFromText(LShortcutText);
  if LShortcut = 0 then
    LShortcut := Shortcut(VK_RETURN, [ssAlt]);

  TLogger.Log(
    'Binding inline completion shortcut: ' + LShortcutText + ' -> ' + ShortCutToText(LShortcut),
    'InlineCompletion'
  );
  BindingServices.AddKeyBinding([LShortcut], RequestCompletion, nil);
  BindingServices.AddKeyBinding([Shortcut(VK_TAB, [])], AcceptCompletion, nil);
  BindingServices.AddKeyBinding([Shortcut(VK_ESCAPE, [])], CancelCompletion, nil);
end;

procedure TRadIAInlineCompletionKeyboardBinding.RequestCompletion(const Context: IOTAKeyContext;
  KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
var
  LConfig: IAIConfig;
  LSourceText: string;
  LView: IOTAEditView;
  LFileName: string;
  LRow: Integer;
  LColumn: Integer;
  LContext: TInlineCompletionContext;
  LPrompt: string;
  LRequestId: Integer;
  LService: TInlineCompletionService;
  LEditBuffer: IOTAEditBuffer;
begin
  BindingResult := krUnhandled;
  TLogger.Log('Inline completion shortcut invoked', 'InlineCompletion');
  LConfig := TRadIAConfig.GetInstance;
  if not LConfig.GetAutocompleteEnabled then
  begin
    TLogger.Log('Inline completion ignored: disabled in config', 'InlineCompletion');
    Exit;
  end;

  LEditBuffer := Context.EditBuffer;
  if not Assigned(LEditBuffer) then
  begin
    LEditBuffer := TRadIAOTAHelper.GetCurrentEditBuffer;
    if not Assigned(LEditBuffer) then
    begin
      TLogger.Log('Inline completion ignored: no edit buffer in context', 'InlineCompletion');
      Exit;
    end;
  end;

  if not ReadEditBufferText(LEditBuffer, LSourceText) then
  begin
    TLogger.Log('Inline completion ignored: failed to read edit buffer text', 'InlineCompletion');
    Exit;
  end;

  LFileName := LEditBuffer.FileName;
  LRow := LEditBuffer.EditPosition.Row;
  LColumn := LEditBuffer.EditPosition.Column;

  if (LRow <= 0) or (LColumn <= 0) then
  begin
    LView := TRadIAOTAHelper.GetCurrentEditView;
    if Assigned(LView) then
    begin
      LRow := LView.CursorPos.Line;
      LColumn := LView.CursorPos.Col;
    end;
  end;

  if (LRow <= 0) or (LColumn <= 0) then
  begin
    TLogger.Log('Inline completion ignored: invalid editor cursor position', 'InlineCompletion');
    Exit;
  end;

  LContext := TInlineCompletionContextBuilder.BuildContext(
    LSourceText,
    LFileName,
    LRow,
    LColumn,
    LConfig.GetAutocompleteContextMode,
    LConfig.GetAutocompleteContextBeforeLines,
    LConfig.GetAutocompleteContextAfterLines);
  LPrompt := TInlineCompletionContextBuilder.BuildPrompt(LContext);
  LRequestId := TInlineCompletionSuggestionState.Instance.NextRequestId;
  BindingResult := krHandled;

  LService := TInlineCompletionService.Create(LConfig);
  try
    LService.RequestCompletion(LPrompt,
      procedure(const ASuggestion: string; const AError: string)
      begin
        if LRequestId <> TInlineCompletionSuggestionState.Instance.RequestId then
          Exit;

        if not AError.IsEmpty then
        begin
          TLogger.Log('Inline completion failed: ' + AError, 'InlineCompletion');
          Exit;
        end;

        TInlineCompletionSuggestionState.Instance.SetSuggestion(
          LFileName,
          ASuggestion,
          LRow,
          LColumn);
        RepaintCurrentView;
      end);
  finally
    LService.Free;
  end;
end;

procedure TRadIAInlineCompletionKeyboardBinding.AcceptCompletion(const Context: IOTAKeyContext;
  KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
var
  LActive: Boolean;
  LFileName: string;
  LText: string;
  LRow: Integer;
  LColumn: Integer;
begin
  BindingResult := krUnhandled;
  TInlineCompletionSuggestionState.Instance.Snapshot(LActive, LFileName, LText, LRow, LColumn);
  if not LActive then
    Exit;

  Context.EditBuffer.EditPosition.InsertText(LText);
  TInlineCompletionSuggestionState.Instance.Clear;
  RepaintCurrentView;
  BindingResult := krHandled;
end;

procedure TRadIAInlineCompletionKeyboardBinding.CancelCompletion(const Context: IOTAKeyContext;
  KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
  BindingResult := krUnhandled;
  if TInlineCompletionSuggestionState.Instance.HasActiveSuggestion then
  begin
    TInlineCompletionSuggestionState.Instance.Clear;
    RepaintCurrentView;
    BindingResult := krHandled;
  end;
end;

initialization

finalization
  UnregisterInlineCompletionKeyboardBinding;

end.
