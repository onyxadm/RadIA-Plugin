unit RadIA.Core.PromptTemplates;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  { Represents a single prompt template }
  TPromptTemplate = record
    Name: string;
    Description: string;
    Template: string;
  end;

  { Manages prompt templates with persistence in AppData }
  TPromptTemplateManager = class
  private
    FTemplates: TList<TPromptTemplate>;
    FFilePath: string;
    
    procedure CreateDefaultTemplates;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Load;
    procedure Save;
    procedure AddTemplate(const AName, ADescription, ATemplate: string);
    procedure DeleteTemplate(const AName: string);
    procedure ClearTemplates;
    procedure RestoreDefaultTemplates;
    function GetTemplates: TArray<TPromptTemplate>;
    function FindTemplate(const AName: string; out ATemplate: TPromptTemplate): Boolean;
    function ResolveTemplate(const AName: string; const AActiveCode: string): string;
  end;

implementation

uses
  System.IOUtils, System.JSON;

{ TPromptTemplateManager }

constructor TPromptTemplateManager.Create;
begin
  inherited Create;
  FTemplates := TList<TPromptTemplate>.Create;
  FFilePath := TPath.Combine(TPath.GetHomePath, 'RadIA\templates.json');
end;

destructor TPromptTemplateManager.Destroy;
begin
  FTemplates.Free;
  inherited Destroy;
end;

procedure TPromptTemplateManager.CreateDefaultTemplates;
begin
  FTemplates.Clear;
  AddTemplate(
    'Review Clean Code Delphi',
    'Review Pascal code applying Clean Code and SOLID',
    'Review the following Delphi Pascal code block applying Clean Code, readability, and optimization principles:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Document Complete Unit',
    'Generate XML documentation for classes and methods',
    'Generate documentation in XML Documentation format (compatible with Delphi) for the following unit:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Create DUnitX Mock',
    'Generate unit tests using DUnitX for the class',
    'Create a unit test using DUnitX to test the following Delphi class:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Analyze Performance',
    'Identify bottlenecks and memory leaks in the code',
    'Performance analysis: identify potential bottlenecks, memory leaks, or redundancies in the following Delphi code:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Analyze Stack Trace',
    'Analyze exception stack trace and suggest root cause fixes',
    'Analyze the following Delphi stack trace/error log:'#13#10#13#10'{stacktrace}'#13#10#13#10'Here is the active unit code context for line reference:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Review Leaks and SOLID',
    'Run static analysis on the unit for memory leaks and SOLID principles',
    'Perform a comprehensive static analysis on the following Delphi code unit. Focus on identifying:'#13#10 +
    '1. Memory Leaks (missing try..finally blocks on object creations or incorrect deallocations)'#13#10 +
    '2. SOLID and Clean Code violations'#13#10 +
    '3. Anti-patterns or potential run-time bugs'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Create Project Delphi',
    'Generate a complete Delphi project from specification with file paths',
    'You are a Senior Delphi Software Architect. Create a complete, fully functional and compilable Delphi project based on the following specification:'#13#10 +
    '"{specification}"'#13#10#13#10 +
    'Provide all necessary files (such as .dpr, .pas, .dfm) so the project is complete and ready to compile and run. Follow these strict rules:'#13#10 +
    '1. Do not use placeholders or omit any code. Write the entire implementation.'#13#10 +
    '2. You MUST start the very first line of EVERY code block with a filepath comment representing the relative path of that file in the project directory.'#13#10 +
    'Use the following format for each file block:'#13#10 +
    '```pascal'#13#10 +
    '// filepath: ProjectName.dpr'#13#10 +
    'program ProjectName;'#13#10 +
    '...'#13#10 +
    '```'#13#10 +
    'and for forms:'#13#10 +
    '```dfm'#13#10 +
    '// filepath: uMain.dfm'#13#10 +
    'object MainForm: TMainForm'#13#10 +
    '...'#13#10 +
    'end'#13#10 +
    '```'#13#10 +
    '3. Ensure all unit linkages, main program blocks, form definitions, and class declarations match and compile correctly together.'
  );
end;

procedure TPromptTemplateManager.Load;
var
  LJsonContent: string;
  LJsonArr: TJSONArray;
  LVal: TJSONValue;
  LObj: TJSONObject;
  LTemplate: TPromptTemplate;
  LParsedVal: TJSONValue;
begin
  FTemplates.Clear;
  
  if not TFile.Exists(FFilePath) then
  begin
    CreateDefaultTemplates;
    Save;
    Exit;
  end;

  try
    LJsonContent := TFile.ReadAllText(FFilePath, TEncoding.UTF8);
    if LJsonContent.Trim.IsEmpty then
    begin
      CreateDefaultTemplates;
      Save;
      Exit;
    end;
    
    LParsedVal := TJSONObject.ParseJSONValue(LJsonContent);
    if Assigned(LParsedVal) then
    begin
      try
        if LParsedVal is TJSONArray then
        begin
          LJsonArr := LParsedVal as TJSONArray;
          for LVal in LJsonArr do
          begin
            if LVal is TJSONObject then
            begin
              LObj := LVal as TJSONObject;
              LTemplate.Name := LObj.GetValue<string>('name', '');
              LTemplate.Description := LObj.GetValue<string>('description', '');
              LTemplate.Template := LObj.GetValue<string>('template', '');
              
              if not LTemplate.Name.IsEmpty then
                FTemplates.Add(LTemplate);
            end;
          end;
        end
        else
        begin
          CreateDefaultTemplates;
        end;
      finally
        LParsedVal.Free;
      end;
    end
    else
    begin
      CreateDefaultTemplates;
    end;
  except
    { Fallback to defaults on corrupt file }
    CreateDefaultTemplates;
  end;
  
  if FTemplates.Count = 0 then
  begin
    CreateDefaultTemplates;
    Save;
  end;

  { Auto-migration: if legacy Portuguese templates are found, overwrite with English defaults }
  if (FTemplates.Count > 0) and SameText(FTemplates[0].Name, 'Revisar Clean Code Delphi') then
  begin
    CreateDefaultTemplates;
    Save;
  end;
end;

procedure TPromptTemplateManager.Save;
var
  LJsonArr: TJSONArray;
  LObj: TJSONObject;
  LTemplate: TPromptTemplate;
begin
  ForceDirectories(TPath.GetDirectoryName(FFilePath));
  
  LJsonArr := TJSONArray.Create;
  try
    for LTemplate in FTemplates do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('name', LTemplate.Name);
      LObj.AddPair('description', LTemplate.Description);
      LObj.AddPair('template', LTemplate.Template);
      LJsonArr.AddElement(LObj);
    end;
    
    TFile.WriteAllText(FFilePath, LJsonArr.ToJSON, TEncoding.UTF8);
  finally
    LJsonArr.Free;
  end;
end;

procedure TPromptTemplateManager.AddTemplate(const AName, ADescription, ATemplate: string);
var
  LTemplate: TPromptTemplate;
  I: Integer;
begin
  { Override existing template if name matches }
  for I := 0 to FTemplates.Count - 1 do
  begin
    if SameText(FTemplates[I].Name, AName) then
    begin
      LTemplate.Name := AName;
      LTemplate.Description := ADescription;
      LTemplate.Template := ATemplate;
      FTemplates[I] := LTemplate;
      Exit;
    end;
  end;

  LTemplate.Name := AName;
  LTemplate.Description := ADescription;
  LTemplate.Template := ATemplate;
  FTemplates.Add(LTemplate);
end;

procedure TPromptTemplateManager.DeleteTemplate(const AName: string);
var
  I: Integer;
begin
  for I := 0 to FTemplates.Count - 1 do
  begin
    if SameText(FTemplates[I].Name, AName) then
    begin
      FTemplates.Delete(I);
      Break;
    end;
  end;
end;

procedure TPromptTemplateManager.ClearTemplates;
begin
  FTemplates.Clear;
end;

procedure TPromptTemplateManager.RestoreDefaultTemplates;
begin
  CreateDefaultTemplates;
  Save;
end;

function TPromptTemplateManager.GetTemplates: TArray<TPromptTemplate>;
begin
  Result := FTemplates.ToArray;
end;

function TPromptTemplateManager.FindTemplate(const AName: string; out ATemplate: TPromptTemplate): Boolean;
var
  LTemp: TPromptTemplate;
begin
  for LTemp in FTemplates do
  begin
    if SameText(LTemp.Name, AName) then
    begin
      ATemplate := LTemp;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TPromptTemplateManager.ResolveTemplate(const AName: string; const AActiveCode: string): string;
var
  LTemp: TPromptTemplate;
begin
  if FindTemplate(AName, LTemp) then
  begin
    Result := LTemp.Template.Replace('{code}', AActiveCode);
  end;
end;

end.
