unit RadIA.Core.Sessions;

interface

uses
  System.Generics.Collections, RadIA.Core.Interfaces;

type
  TSessionInfo = record
    Id: string;
    Name: string;
    CreatedAt: TDateTime;
    LastActive: TDateTime;

    class function CreateNew(const AId, AName: string): TSessionInfo; static;
  end;

  TRadIASessionManager = class
  private
    FSessionsDir: string;
    FIndexFile: string;
    FSessions: TList<TSessionInfo>;
    FActiveSessionId: string;

    procedure LoadIndex;
    procedure SaveIndex;
    function FindSessionIndex(const AId: string): Integer;
  public
    constructor Create(const ASessionsDir: string = '');
    destructor Destroy; override;

    property Sessions: TList<TSessionInfo> read FSessions;
    property ActiveSessionId: string read FActiveSessionId write FActiveSessionId;

    function CreateSession(const AName: string = ''): TSessionInfo;
    procedure DeleteSession(const AId: string);
    procedure RenameSession(const AId: string; const ANewName: string);
    procedure UpdateSessionActivity(const AId: string);

    function GetSessionFilePath(const AId: string): string;
    function SessionHasHistory(const AId: string): Boolean;
    function LoadSessionHistory(const AId: string): TArray<IRadIAChatMessage>;
    procedure SaveSessionHistory(const AId: string; const AHistory: TArray<IRadIAChatMessage>);
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON, System.DateUtils, System.Generics.Defaults,
  RadIA.Core.Types, RadIA.Core.Logger, RadIA.Core.ChatMessage;

procedure LogSession(const AMsg: string);
begin
  TLogger.Log(AMsg, 'Sessions');
end;

{ TSessionInfo }

class function TSessionInfo.CreateNew(const AId, AName: string): TSessionInfo;
begin
  Result.Id := AId;
  Result.Name := AName;
  Result.CreatedAt := Now;
  Result.LastActive := Now;
end;

{ TRadIASessionManager }

constructor TRadIASessionManager.Create(const ASessionsDir: string);
begin
  inherited Create;
  FSessions := TList<TSessionInfo>.Create;
  if ASessionsDir.IsEmpty then
    FSessionsDir := TPath.Combine(TPath.GetHomePath, 'RadIA\sessions')
  else
    FSessionsDir := ASessionsDir;
  FIndexFile := TPath.Combine(FSessionsDir, 'sessions_index.json');
  ForceDirectories(FSessionsDir);
  LoadIndex;
end;

destructor TRadIASessionManager.Destroy;
begin
  FSessions.Free;
  inherited Destroy;
end;

function TRadIASessionManager.FindSessionIndex(const AId: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FSessions.Count - 1 do
  begin
    if SameText(FSessions[I].Id, AId) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

procedure TRadIASessionManager.LoadIndex;
var
  LContent: string;
  LVal: TJSONValue;
  LArr: TJSONArray;
  LObj: TJSONObject;
  LInfo: TSessionInfo;
begin
  FSessions.Clear;
  if not TFile.Exists(FIndexFile) then
  begin
    LogSession('LoadIndex: Index file not found, initializing empty.');
    Exit;
  end;

  try
    LContent := TFile.ReadAllText(FIndexFile, TEncoding.UTF8);
    if LContent.IsEmpty then
      Exit;

    LVal := TJSONObject.ParseJSONValue(LContent);
    if Assigned(LVal) then
    begin
      if LVal is TJSONArray then
      begin
        LArr := LVal as TJSONArray;
        for LVal in LArr do
        begin
          if LVal is TJSONObject then
          begin
            LObj := LVal as TJSONObject;

            if LObj.GetValue('id') <> nil then
              LInfo.Id := LObj.GetValue('id').Value
            else
              LInfo.Id := '';

            if LObj.GetValue('name') <> nil then
              LInfo.Name := LObj.GetValue('name').Value
            else
              LInfo.Name := '';

            if LObj.GetValue('createdAt') <> nil then
            begin
              try
                LInfo.CreatedAt := ISO8601ToDate(LObj.GetValue('createdAt').Value);
              except
                LInfo.CreatedAt := Now;
              end;
            end
            else
              LInfo.CreatedAt := Now;

            if LObj.GetValue('lastActive') <> nil then
            begin
              try
                LInfo.LastActive := ISO8601ToDate(LObj.GetValue('lastActive').Value);
              except
                LInfo.LastActive := Now;
              end;
            end
            else
              LInfo.LastActive := Now;

            if not LInfo.Id.IsEmpty then
              FSessions.Add(LInfo);
          end;
        end;
      end;
      LVal.Free;
    end;

    { Sort by LastActive descending to show recent first }
    FSessions.Sort(TComparer<TSessionInfo>.Construct(
      function(const L, R: TSessionInfo): Integer
      begin
        if L.LastActive > R.LastActive then
          Result := -1
        else if L.LastActive < R.LastActive then
          Result := 1
        else
          Result := 0;
      end));

    LogSession(Format('LoadIndex: Loaded %d sessions.', [FSessions.Count]));
  except
    on E: Exception do
      LogSession('LoadIndex error: ' + E.Message);
  end;
end;

procedure TRadIASessionManager.SaveIndex;
var
  LArr: TJSONArray;
  LObj: TJSONObject;
  LInfo: TSessionInfo;
begin
  LArr := TJSONArray.Create;
  try
    for LInfo in FSessions do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', LInfo.Id);
      LObj.AddPair('name', LInfo.Name);
      LObj.AddPair('createdAt', DateToISO8601(LInfo.CreatedAt));
      LObj.AddPair('lastActive', DateToISO8601(LInfo.LastActive));
      LArr.AddElement(LObj);
    end;

    TFile.WriteAllText(FIndexFile, LArr.ToJSON, TEncoding.UTF8);
  finally
    LArr.Free;
  end;
end;

function TRadIASessionManager.CreateSession(const AName: string): TSessionInfo;
var
  LGuid: TGUID;
  LSessionName: string;
begin
  CreateGUID(LGuid);
  if AName.Trim.IsEmpty then
    LSessionName := 'New Chat Session'
  else
    LSessionName := AName.Trim;

  Result := TSessionInfo.CreateNew(LGuid.ToString.Replace('{', '').Replace('}', ''), LSessionName);
  FSessions.Insert(0, Result);
  SaveIndex;

  LogSession('CreateSession: Created ' + Result.Id);
end;

procedure TRadIASessionManager.DeleteSession(const AId: string);
var
  LIndex: Integer;
  LFile: string;
begin
  LIndex := FindSessionIndex(AId);
  if LIndex <> -1 then
  begin
    FSessions.Delete(LIndex);
    SaveIndex;

    LFile := GetSessionFilePath(AId);
    if TFile.Exists(LFile) then
    begin
      try
        TFile.Delete(LFile);
      except
        on E: Exception do
          LogSession('DeleteSession: Error deleting file ' + LFile + ': ' + E.Message);
      end;
    end;

    if SameText(FActiveSessionId, AId) then
      FActiveSessionId := '';

    LogSession('DeleteSession: Deleted ' + AId);
  end;
end;

procedure TRadIASessionManager.RenameSession(const AId: string; const ANewName: string);
var
  LIndex: Integer;
  LInfo: TSessionInfo;
begin
  LIndex := FindSessionIndex(AId);
  if (LIndex <> -1) and not ANewName.Trim.IsEmpty then
  begin
    LInfo := FSessions[LIndex];
    LInfo.Name := ANewName.Trim;
    FSessions[LIndex] := LInfo;
    SaveIndex;
    LogSession('RenameSession: Renamed ' + AId + ' to ' + ANewName);
  end;
end;

procedure TRadIASessionManager.UpdateSessionActivity(const AId: string);
var
  LIndex: Integer;
  LInfo: TSessionInfo;
begin
  LIndex := FindSessionIndex(AId);
  if LIndex <> -1 then
  begin
    LInfo := FSessions[LIndex];
    LInfo.LastActive := Now;
    FSessions[LIndex] := LInfo;
    SaveIndex;
  end;
end;

function TRadIASessionManager.GetSessionFilePath(const AId: string): string;
begin
  Result := TPath.Combine(FSessionsDir, AId + '.json');
end;

function TRadIASessionManager.SessionHasHistory(const AId: string): Boolean;
var
  LFile: string;
  LContent: string;
begin
  Result := False;
  LFile := GetSessionFilePath(AId);
  if not TFile.Exists(LFile) then
    Exit;

  try
    LContent := TFile.ReadAllText(LFile, TEncoding.UTF8).Trim;
    Result := (not LContent.IsEmpty) and (not SameText(LContent, '[]'));
  except
    on E: Exception do
    begin
      LogSession('SessionHasHistory error: ' + E.Message);
      Result := True;
    end;
  end;
end;

function TRadIASessionManager.LoadSessionHistory(const AId: string): TArray<IRadIAChatMessage>;
var
  LFile: string;
  LContent: string;
  LParsedVal: TJSONValue;
  LJsonArr: TJSONArray;
  LVal: TJSONValue;
  LMsgObj: TJSONObject;
  LRole: TAIMessageRole;
  LRoleStr, LContentStr, LProviderStr, LModelStr: string;
begin
  Result := [];
  LFile := GetSessionFilePath(AId);
  if not TFile.Exists(LFile) then
    Exit;

  try
    LContent := TFile.ReadAllText(LFile, TEncoding.UTF8);
    if LContent.IsEmpty then
      Exit;

    LParsedVal := TJSONObject.ParseJSONValue(LContent);
    if Assigned(LParsedVal) then
    begin
      if LParsedVal is TJSONArray then
      begin
        LJsonArr := LParsedVal as TJSONArray;
        for LVal in LJsonArr do
        begin
          if LVal is TJSONObject then
          begin
            LMsgObj := LVal as TJSONObject;

            if LMsgObj.GetValue('role') <> nil then
              LRoleStr := LMsgObj.GetValue('role').Value
            else
              LRoleStr := '';

            if LMsgObj.GetValue('content') <> nil then
              LContentStr := LMsgObj.GetValue('content').Value
            else
              LContentStr := '';

            if LMsgObj.GetValue('provider') <> nil then
              LProviderStr := LMsgObj.GetValue('provider').Value
            else
              LProviderStr := '';

            if LMsgObj.GetValue('model') <> nil then
              LModelStr := LMsgObj.GetValue('model').Value
            else
              LModelStr := '';

            if not LContentStr.IsEmpty then
            begin
              LRole := StringToMessageRole(LRoleStr);
              Result := Result + [TRadIAChatMessage.CreateMessage(LRole, LContentStr, LProviderStr, LModelStr)];
            end;
          end;
        end;
      end;
      LParsedVal.Free;
    end;
  except
    on E: Exception do
      LogSession('LoadSessionHistory error: ' + E.Message);
  end;
end;

procedure TRadIASessionManager.SaveSessionHistory(const AId: string; const AHistory: TArray<IRadIAChatMessage>);
var
  LFile: string;
  LJsonArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IRadIAChatMessage;
begin
  if AId.IsEmpty then
    Exit;

  LFile := GetSessionFilePath(AId);
  LJsonArr := TJSONArray.Create;
  try
    for LMsg in AHistory do
    begin
      if LMsg.Role = mrSystem then
        Continue;

      LMsgObj := TJSONObject.Create;
      LMsgObj.AddPair('role', MessageRoleToString(LMsg.Role));
      LMsgObj.AddPair('content', LMsg.Content);
      if not LMsg.Provider.IsEmpty then
        LMsgObj.AddPair('provider', LMsg.Provider);
      if not LMsg.Model.IsEmpty then
        LMsgObj.AddPair('model', LMsg.Model);
      LJsonArr.AddElement(LMsgObj);
    end;

    TFile.WriteAllText(LFile, LJsonArr.ToJSON, TEncoding.UTF8);
  finally
    LJsonArr.Free;
  end;
end;

end.
