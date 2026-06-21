unit RadIA.Core.ProjectGenerator;

interface

uses
  RadIA.Core.Interfaces;

type
  { Specialist service for generating complete Delphi projects on disk }
  TRadIAProjectGenerator = class(TInterfacedObject, IRadIAProjectGenerator)
  public
    { Generates a project structure from a JSON array of files.
      Opens a directory selection dialog, validates that it is empty,
      saves all files using UTF-8, and opens the main project file in the IDE. }
    function GenerateFromJSON(const AFilesJSON: string; out AErrorMsg: string; const ADestDir: string = ''): Boolean;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON, Vcl.Dialogs,
  RadIA.Core.Logger, RadIA.Core.Container;

{ TRadIAProjectGenerator }

function TRadIAProjectGenerator.GenerateFromJSON(const AFilesJSON: string; out AErrorMsg: string; const ADestDir: string): Boolean;
var
  LChosenDir: string;
  LJsonValue: TJSONValue;
  LJsonArr: TJSONArray;
  LVal: TJSONValue;
  LObj: TJSONObject;
  LRelPath: string;
  LContent: string;
  LAbsPath: string;
  LSubFolder: string;
  I: Integer;
  LWrittenFiles: TStringList;
  LProjectFileToOpen: string;
  LFileEntries: TArray<string>;
  LOpenDlg: TFileOpenDialog;
begin
  Result := False;
  AErrorMsg := '';
  LProjectFileToOpen := '';

  if AFilesJSON.Trim.IsEmpty then
  begin
    AErrorMsg := 'No files data provided.';
    Exit;
  end;

  { Parse JSON array of files }
  LJsonValue := TJSONObject.ParseJSONValue(AFilesJSON);
  if not Assigned(LJsonValue) then
  begin
    AErrorMsg := 'Invalid JSON files data.';
    Exit;
  end;

  try
    if not (LJsonValue is TJSONArray) then
    begin
      AErrorMsg := 'Files data must be a JSON array.';
      Exit;
    end;

    LJsonArr := LJsonValue as TJSONArray;
    if LJsonArr.Count = 0 then
    begin
      AErrorMsg := 'Files list is empty.';
      Exit;
    end;

    { 1. Ask user for destination folder using modern FileOpenDialog }
    LChosenDir := ADestDir;
    if LChosenDir.IsEmpty then
    begin
      LOpenDlg := TFileOpenDialog.Create(nil);
      try
        LOpenDlg.Title := 'Select a completely empty folder for the project';
        LOpenDlg.Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
        if LOpenDlg.Execute then
        begin
          LChosenDir := LOpenDlg.FileName;
        end;
      finally
        LOpenDlg.Free;
      end;
    end;

    if LChosenDir.IsEmpty then
      Exit;

    { 2. Validate folder }
    if TDirectory.Exists(LChosenDir) then
    begin
      LFileEntries := TDirectory.GetFileSystemEntries(LChosenDir);
      if Length(LFileEntries) > 0 then
      begin
        AErrorMsg := 'The chosen folder is not empty. Please select a completely empty folder for the project.';
        Exit;
      end;
    end
    else
    begin
      try
        TDirectory.CreateDirectory(LChosenDir);
      except
        on E: Exception do
        begin
          AErrorMsg := 'Failed to create destination folder: ' + E.Message;
          Exit;
        end;
      end;
    end;

    { 3. Write files physically }
    LWrittenFiles := TStringList.Create;
    try
      try
        for I := 0 to LJsonArr.Count - 1 do
        begin
          LVal := LJsonArr[I];
          if LVal is TJSONObject then
          begin
            LObj := LVal as TJSONObject;
            LRelPath := LObj.GetValue<string>('path', '');
            LContent := LObj.GetValue<string>('content', '');

            if LRelPath.IsEmpty then
              Continue;

            // Make it relative/safe
            LRelPath := LRelPath.Replace('/', '\');
            if LRelPath.StartsWith('\') then
              LRelPath := LRelPath.Substring(1);

            LAbsPath := TPath.Combine(LChosenDir, LRelPath);
            LSubFolder := TPath.GetDirectoryName(LAbsPath);

            if not LSubFolder.IsEmpty and not TDirectory.Exists(LSubFolder) then
              TDirectory.CreateDirectory(LSubFolder);

            TFile.WriteAllText(LAbsPath, LContent, TEncoding.UTF8);
            LWrittenFiles.Add(LAbsPath);
          end;
        end;

        Result := True;
      except
        on E: Exception do
        begin
          AErrorMsg := 'Error writing files: ' + E.Message;
          TLogger.Log('TRadIAProjectGenerator.GenerateFromJSON: Exception writing files. Rollback initiated.', 'Core');

          // Rollback: delete any files written in this execution
          for LRelPath in LWrittenFiles do
          begin
            try
              if TFile.Exists(LRelPath) then
                TFile.Delete(LRelPath);
            except
              on E: Exception do
                TLogger.Log('TRadIAProjectGenerator.GenerateFromJSON rollback: Failed to delete ' +
                  LRelPath + ': ' + E.Message, 'Core');
            end;
          end;

          Exit;
        end;
      end;

      { 4. Identify project file to open (.dproj first, then .dpr) }
      for LRelPath in LWrittenFiles do
      begin
        if SameText(TPath.GetExtension(LRelPath), '.dproj') then
        begin
          LProjectFileToOpen := LRelPath;
          Break;
        end;
      end;

      if LProjectFileToOpen.IsEmpty then
      begin
        for LRelPath in LWrittenFiles do
        begin
          if SameText(TPath.GetExtension(LRelPath), '.dpr') then
          begin
            LProjectFileToOpen := LRelPath;
            Break;
          end;
        end;
      end;

      { 5. Open project in IDE }
      if not LProjectFileToOpen.IsEmpty then
      begin
        TLogger.Log('TRadIAProjectGenerator.GenerateFromJSON: Opening project: ' + LProjectFileToOpen, 'Core');
        TThread.Queue(nil,
          procedure
          var
            LAdapter: IRadIAIDEAdapter;
          begin
            if TRadIAContainer.TryResolve<IRadIAIDEAdapter>(LAdapter) then
              LAdapter.OpenProjectInIDE(LProjectFileToOpen);
          end);
      end
      else
      begin
        TLogger.Log('TRadIAProjectGenerator.GenerateFromJSON: No project file (.dproj/.dpr) found to open.', 'Core');
      end;

    finally
      LWrittenFiles.Free;
    end;

  finally
    LJsonValue.Free;
  end;
end;

end.
