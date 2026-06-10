unit RadIA.Core.InlineCompletion;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, RadIA.Core.Types;

const
  CInlineCompletionCursorMarker = '//RadIA_Inline_Completion';

type
  TInlineCompletionContext = record
    FileName: string;
    CursorRow: Integer;
    CursorColumn: Integer;
    Text: string;
  end;

  TInlineCompletionContextBuilder = class
  public
    class function BuildContext(const ASourceText: string; const AFileName: string;
      const ARow, AColumn: Integer; const AMode: TInlineCompletionContextMode;
      const ABeforeLines, AAfterLines: Integer): TInlineCompletionContext; static;
    class function BuildPrompt(const AContext: TInlineCompletionContext): string; static;
  end;

  TInlineCompletionResponseCleaner = class
  public
    class function Clean(const AResponse: string): string; static;
  end;

  TInlineCompletionSuggestionState = class
  private
    class var FInstance: TInlineCompletionSuggestionState;
    FCriticalSection: TCriticalSection;
    FActive: Boolean;
    FFileName: string;
    FText: string;
    FRow: Integer;
    FColumn: Integer;
    FRequestId: Integer;
    function GetRequestId: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    class function Instance: TInlineCompletionSuggestionState;
    class procedure ReleaseInstance;
    function NextRequestId: Integer;
    function HasActiveSuggestion: Boolean;
    procedure SetSuggestion(const AFileName, AText: string; const ARow, AColumn: Integer);
    procedure Clear;
    procedure Snapshot(out AActive: Boolean; out AFileName, AText: string;
      out ARow, AColumn: Integer);
    property RequestId: Integer read GetRequestId;
  end;

implementation

uses
  RadIA.OTA.Helper;

class function TInlineCompletionContextBuilder.BuildContext(const ASourceText: string;
  const AFileName: string; const ARow, AColumn: Integer; const AMode: TInlineCompletionContextMode;
  const ABeforeLines, AAfterLines: Integer): TInlineCompletionContext;
var
  LLines: TStringList;
  LStartLine: Integer;
  LEndLine: Integer;
  LRowIndex: Integer;
  LColumnIndex: Integer;
  I: Integer;
  LLine: string;
begin
  Result.FileName := AFileName;
  Result.CursorRow := ARow;
  Result.CursorColumn := AColumn;
  Result.Text := '';

  LLines := TStringList.Create;
  try
    LLines.Text := ASourceText;
    if LLines.Count = 0 then
      LLines.Add('');

    LRowIndex := ARow - 1;
    if LRowIndex < 0 then
      LRowIndex := 0;
    if LRowIndex >= LLines.Count then
      LRowIndex := LLines.Count - 1;

    LColumnIndex := AColumn - 1;
    if LColumnIndex < 0 then
      LColumnIndex := 0;

    LLine := LLines[LRowIndex];
    if LColumnIndex > Length(LLine) then
      LColumnIndex := Length(LLine);
    Insert(CInlineCompletionCursorMarker, LLine, LColumnIndex + 1);
    LLines[LRowIndex] := LLine;

    if AMode = icmFullFile then
    begin
      Result.Text := LLines.Text.TrimRight;
      Exit;
    end;

    LStartLine := LRowIndex - ABeforeLines;
    if LStartLine < 0 then
      LStartLine := 0;

    LEndLine := LRowIndex + AAfterLines;
    if LEndLine >= LLines.Count then
      LEndLine := LLines.Count - 1;

    for I := LStartLine to LEndLine do
    begin
      if not Result.Text.IsEmpty then
        Result.Text := Result.Text + sLineBreak;
      Result.Text := Result.Text + LLines[I];
    end;
  finally
    LLines.Free;
  end;
end;

class function TInlineCompletionContextBuilder.BuildPrompt(
  const AContext: TInlineCompletionContext): string;
var
  LMarkerPos: Integer;
  LPrefix: string;
  LSuffix: string;
  LDelphiVersionName: string;
  LLanguageInstruction: string;
begin
  LMarkerPos := Pos(CInlineCompletionCursorMarker, AContext.Text);
  if LMarkerPos > 0 then
  begin
    LPrefix := Copy(AContext.Text, 1, LMarkerPos - 1);
    LSuffix := Copy(
      AContext.Text,
      LMarkerPos + Length(CInlineCompletionCursorMarker),
      MaxInt
    );
  end
  else
  begin
    LPrefix := AContext.Text;
    LSuffix := '';
  end;

  LDelphiVersionName := TRadIAOTAHelper.GetDelphiVersionName;
  LLanguageInstruction := TRadIAOTAHelper.GetPreferredLanguageInstruction;

  Result :=
    'You are an inline Delphi/Object Pascal completion engine.' + sLineBreak +
    'Complete code exactly where the marker ' + CInlineCompletionCursorMarker +
    ' appears.' + sLineBreak +
    'Return only the code that should replace that marker.' + sLineBreak +
    'The code must connect the prefix and suffix naturally.' + sLineBreak +
    'Never repeat existing code, the unit header, interface, uses, or implementation.' + sLineBreak +
    'Never create a full unit, class, method, explanation, markdown, or comments.' + sLineBreak +
    'Do not prefix the answer with a language name such as Delphi or Pascal.' + sLineBreak +
    'Before implementation, or inside private/protected/public/published, return only declarations.' + sLineBreak +
    'In declaration areas, never return implementation code containing begin.' + sLineBreak +
    'Preserve normal Delphi formatting, indentation, and line breaks.' + sLineBreak +
    'Focus only on the immediate code around the marker.' + sLineBreak +
    'Match naming, indentation, casing, and surrounding style.' + sLineBreak +
    'If the marker is in the middle of a line, return only the missing continuation.' + sLineBreak +
    'Read the suffix carefully and do not duplicate code, punctuation, or block endings.' + sLineBreak +
    'Inside a class declaration, suggest declarations only.' + sLineBreak +
    'Inside a method body, suggest executable statements only.' + sLineBreak +
    'Do not add units to uses unless the marker is inside a uses clause.' + sLineBreak +
    'Use Delphi Object Pascal syntax, not Free Pascal-only syntax.' + sLineBreak +
    'Keep the suggestion minimal: one expression, statement, or declaration when possible.' + sLineBreak +
    'The user is writing code using Embarcadero ' + LDelphiVersionName + '.' + sLineBreak +
    'Only suggest code compatible with ' + LDelphiVersionName + '.' + sLineBreak +
    LLanguageInstruction + sLineBreak +
    'If there is no confident local completion, return an empty response.' + sLineBreak +
    'Prefer at most one short line unless the cursor clearly needs a block.' + sLineBreak +
    'File: ' + ExtractFileName(AContext.FileName) + sLineBreak + sLineBreak +
    'Code before marker:' + sLineBreak +
    '```pascal' + sLineBreak +
    LPrefix + CInlineCompletionCursorMarker + sLineBreak +
    '```' + sLineBreak + sLineBreak +
    'Code after marker:' + sLineBreak +
    '```pascal' + sLineBreak +
    LSuffix + sLineBreak +
    '```';
end;

class function TInlineCompletionResponseCleaner.Clean(const AResponse: string): string;
var
  LText: string;
  LLower: string;
  LFirstToken: string;
  LTokenEnd: Integer;
  LFencePos: Integer;
  LEndFencePos: Integer;
begin
  LText := AResponse.Trim;
  LText := StringReplace(LText, '\r\n', sLineBreak, [rfReplaceAll]);
  LText := StringReplace(LText, '\n', sLineBreak, [rfReplaceAll]);
  LText := StringReplace(LText, '\t', #9, [rfReplaceAll]);
  LLower := LText.ToLower;

  LFencePos := Pos('```', LText);
  if LFencePos > 0 then
  begin
    LText := Copy(LText, LFencePos + 3, MaxInt).Trim;
    LEndFencePos := Pos('```', LText);
    if LEndFencePos > 0 then
      LText := Copy(LText, 1, LEndFencePos - 1).Trim;

    LLower := LText.ToLower;
    if LLower.StartsWith('objectpascal') then
      LText := Copy(LText, 13, MaxInt).Trim
    else if LLower.StartsWith('pascal') then
      LText := Copy(LText, 7, MaxInt).Trim
    else if LLower.StartsWith('delphi') then
      LText := Copy(LText, 7, MaxInt).Trim;
  end;

  if LText.EndsWith('```') then
    LText := LText.Substring(0, LText.Length - 3).Trim;

  LLower := LText.ToLower;
  if LLower.StartsWith('delphi:') then
    LText := Copy(LText, 8, MaxInt).Trim
  else if LLower.StartsWith('delphi') and (Length(LText) <= 6) then
    Exit('');

  LLower := LText.ToLower;
  if (LLower.Contains('unit ') and LLower.Contains('interface')) or
     (LLower.Contains('unit') and LLower.Contains('interfaceuses')) then
    Exit('');

  LFirstToken := LText.TrimLeft;
  LTokenEnd := Pos(' ', LFirstToken);
  if LTokenEnd = 0 then
    LTokenEnd := Pos(sLineBreak, LFirstToken);
  if LTokenEnd > 0 then
    LFirstToken := Copy(LFirstToken, 1, LTokenEnd - 1);
  LFirstToken := LFirstToken.Trim([' ', #9, #13, #10, ';', ':']).ToLower;

  if (LFirstToken = 'unit') or (LFirstToken = 'interface') or
     (LFirstToken = 'uses') or (LFirstToken = 'implementation') or
     (LFirstToken = 'program') or (LFirstToken = 'library') or
     (LFirstToken = 'package') then
    Exit('');

  Result := LText;
end;

constructor TInlineCompletionSuggestionState.Create;
begin
  inherited Create;
  FCriticalSection := TCriticalSection.Create;
  Clear;
end;

destructor TInlineCompletionSuggestionState.Destroy;
begin
  FCriticalSection.Free;
  inherited Destroy;
end;

class function TInlineCompletionSuggestionState.Instance: TInlineCompletionSuggestionState;
begin
  if FInstance = nil then
    FInstance := TInlineCompletionSuggestionState.Create;
  Result := FInstance;
end;

class procedure TInlineCompletionSuggestionState.ReleaseInstance;
begin
  if Assigned(FInstance) then
    FreeAndNil(FInstance);
end;

function TInlineCompletionSuggestionState.NextRequestId: Integer;
begin
  FCriticalSection.Enter;
  try
    Inc(FRequestId);
    Result := FRequestId;
  finally
    FCriticalSection.Leave;
  end;
end;

function TInlineCompletionSuggestionState.GetRequestId: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := FRequestId;
  finally
    FCriticalSection.Leave;
  end;
end;

function TInlineCompletionSuggestionState.HasActiveSuggestion: Boolean;
begin
  FCriticalSection.Enter;
  try
    Result := FActive and not FText.Trim.IsEmpty;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TInlineCompletionSuggestionState.SetSuggestion(const AFileName, AText: string;
  const ARow, AColumn: Integer);
begin
  FCriticalSection.Enter;
  try
    FFileName := AFileName;
    FText := AText;
    FRow := ARow;
    FColumn := AColumn;
    FActive := not AText.Trim.IsEmpty;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TInlineCompletionSuggestionState.Clear;
begin
  FCriticalSection.Enter;
  try
    FActive := False;
    FFileName := '';
    FText := '';
    FRow := 0;
    FColumn := 0;
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TInlineCompletionSuggestionState.Snapshot(out AActive: Boolean; out AFileName,
  AText: string; out ARow, AColumn: Integer);
begin
  FCriticalSection.Enter;
  try
    AActive := FActive;
    AFileName := FFileName;
    AText := FText;
    ARow := FRow;
    AColumn := FColumn;
  finally
    FCriticalSection.Leave;
  end;
end;

initialization

finalization
  TInlineCompletionSuggestionState.ReleaseInstance;

end.
