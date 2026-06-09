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
    IsProjectGenerator: Boolean;
    SlashCommand: string;
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
    procedure AddTemplate(const AName, ADescription, ATemplate: string; const AIsProjectGenerator: Boolean = False; const ASlashCommand: string = '');
    procedure DeleteTemplate(const AName: string);
    procedure ClearTemplates;
    procedure RestoreDefaultTemplates;
    function GetTemplates: TArray<TPromptTemplate>;
    function FindTemplate(const AName: string; out ATemplate: TPromptTemplate): Boolean;
    function ResolveTemplate(const AName: string; const AActiveCode: string): string;
    
    { Backup / Restore }
    procedure ExportToFile(const AFileName: string);
    function ImportFromFile(const AFileName: string; const AMerge: Boolean; out AErrorMsg: string): Boolean;
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
    'Review the following Delphi Pascal code block applying Clean Code, readability, and optimization principles:'#13#10#13#10'{code}',
    False,
    '/explain'
  );
  AddTemplate(
    'Document Complete Unit',
    'Generate XML documentation for classes and methods',
    'Generate documentation in XML Documentation format (compatible with Delphi) for the following unit:'#13#10#13#10'{code}',
    False,
    '/doc'
  );
  AddTemplate(
    'Create DUnitX Mock',
    'Generate unit tests using DUnitX for the class',
    'Create a unit test using DUnitX to test the following Delphi class:'#13#10#13#10'{code}',
    False,
    '/test'
  );
  AddTemplate(
    'Analyze Performance',
    'Identify bottlenecks and memory leaks in the code',
    'Performance analysis: identify potential bottlenecks, memory leaks, or redundancies in the following Delphi code:'#13#10#13#10'{code}',
    False,
    '/performance'
  );
  AddTemplate(
    'Analyze Stack Trace',
    'Analyze exception stack trace and suggest root cause fixes',
    'Analyze the following Delphi stack trace/error log:'#13#10#13#10'{stacktrace}'#13#10#13#10'Here is the active unit code context for line reference:'#13#10#13#10'{code}',
    False,
    '/stacktrace'
  );
  AddTemplate(
    'Review Leaks and SOLID',
    'Run static analysis on the unit for memory leaks and SOLID principles',
    'Perform a comprehensive static analysis on the following Delphi code unit. Focus on identifying:'#13#10 +
    '1. Memory Leaks (missing try..finally blocks on object creations or incorrect deallocations)'#13#10 +
    '2. SOLID and Clean Code violations'#13#10 +
    '3. Anti-patterns or potential run-time bugs'#13#10#13#10'{code}',
    False,
    '/bugs'
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
    '3. Ensure all unit linkages, main program blocks, form definitions, and class declarations match and compile correctly together.'#13#10 +
    '4. Memory Safety, Type Safety and Dependencies:'#13#10 +
    '   - Enforce proper "uses" clauses: Double-check that every unit imports all units required for its compilation (e.g. System.Generics.Collections for generic lists, System.Classes for persistence/lists, System.SysUtils for exceptions/guid, Vcl.Dialogs/Forms/Controls/Graphics/StdCtrls/ExtCtrls for VCL UI controls, etc.).'#13#10 +
    '   - Use strongly typed generic collections (from System.Generics.Collections like TList<T> or TDictionary<K,V>) instead of legacy non-generic collections (like TList without generic type parameters). Never use raw non-generic lists.',
    True,
    '/createproject'
  );
  AddTemplate(
    'Create Project Delphi Architecture',
    'Generate a SOLID clean architecture Delphi project from specification with files paths',
    'You are a Senior Delphi Software Architect. Create a complete, fully functional, compilable, and highly structured Delphi project based on the following specification:'#13#10 +
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
    '3. Architectural Best Practices (SOLID & Clean Code):'#13#10 +
    '   - Enforce Single Responsibility Principle (SRP): Segregate business logic, calculations, and data access into pure Object Pascal classes or services. Do not write business logic inside UI form event handlers (OnClick, OnCreate, etc.). Event handlers should only call domain services.'#13#10 +
    '   - Dependency Inversion (DIP): Use interfaces (IInterface) to decouple objects where appropriate.'#13#10 +
    '4. Memory Safety & Resource Management:'#13#10 +
    '   - Prevent memory leaks: Every time an object is instantiated locally, wrap its usage inside a try..finally block and free it in the finally block.'#13#10 +
    '5. Delphi Naming Style Guide Conventions:'#13#10 +
    '   - Types and classes must be prefixed with "T" (e.g., TDomainService).'#13#10 +
    '   - Interfaces must be prefixed with "I" (e.g., IDomainService).'#13#10 +
    '   - Private class fields must be prefixed with "F" (e.g., FCount).'#13#10 +
    '   - Method parameters/arguments must be prefixed with "A" (e.g., AInputText).'#13#10 +
    '   - Local variables inside methods must be prefixed with "L" (e.g., LResultObj).'#13#10 +
    '6. Modern Object Pascal Features:'#13#10 +
    '   - Use strong typing, enums, advanced records, and generics (from System.Generics.Collections like TList<T> or TDictionary<K,V>) instead of legacy Pointer lists or untyped structures. NEVER use raw non-generic collections like TList without a type parameter (TList<T>) if you import System.Generics.Collections, and always specify its generic arguments.'#13#10 +
    '7. Compile-Ready Integration:'#13#10 +
    '   - Ensure all unit linkages, main program blocks, form definitions, and class declarations match and compile correctly together without external third-party dependencies unless explicitly requested.'#13#10 +
    '   - Double-check the "uses" clause of every unit: ensure every type, class, record, interface or collection used is properly imported (e.g. System.Generics.Collections for generic lists, System.Classes for persistence/lists, System.SysUtils for exceptions/guid, Vcl.Dialogs/Forms/Controls/Graphics/StdCtrls/ExtCtrls for VCL UI controls, etc.). Do not miss any unit dependency.',
    True,
    '/createprojectarch'
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
  LArchTemp: TPromptTemplate;
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
              LTemplate.IsProjectGenerator := LObj.GetValue<Boolean>('isProjectGenerator', False);
              LTemplate.SlashCommand := LObj.GetValue<string>('slashCommand', '');
              
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

  { Auto-migration: if legacy Portuguese templates are found, or new architecture template is missing, or prompt directives need updating, restore defaults }
  if ((FTemplates.Count > 0) and SameText(FTemplates[0].Name, 'Revisar Clean Code Delphi')) or
     (not FindTemplate('Create Project Delphi Architecture', LArchTemp)) or
     (FindTemplate('Create Project Delphi', LArchTemp) and not LArchTemp.Template.Contains('uses')) then
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
      LObj.AddPair('isProjectGenerator', TJSONBool.Create(LTemplate.IsProjectGenerator));
      LObj.AddPair('slashCommand', LTemplate.SlashCommand);
      LJsonArr.AddElement(LObj);
    end;
    
    TFile.WriteAllText(FFilePath, LJsonArr.ToJSON, TEncoding.UTF8);
  finally
    LJsonArr.Free;
  end;
end;

procedure TPromptTemplateManager.AddTemplate(const AName, ADescription, ATemplate: string; const AIsProjectGenerator: Boolean = False; const ASlashCommand: string = '');
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
      LTemplate.IsProjectGenerator := AIsProjectGenerator;
      LTemplate.SlashCommand := ASlashCommand;
      FTemplates[I] := LTemplate;
      Exit;
    end;
  end;

  LTemplate.Name := AName;
  LTemplate.Description := ADescription;
  LTemplate.Template := ATemplate;
  LTemplate.IsProjectGenerator := AIsProjectGenerator;
  LTemplate.SlashCommand := ASlashCommand;
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

procedure TPromptTemplateManager.ExportToFile(const AFileName: string);
var
  LJsonArr: TJSONArray;
  LObj: TJSONObject;
  LTemplate: TPromptTemplate;
begin
  LJsonArr := TJSONArray.Create;
  try
    for LTemplate in FTemplates do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('name', LTemplate.Name);
      LObj.AddPair('description', LTemplate.Description);
      LObj.AddPair('template', LTemplate.Template);
      LObj.AddPair('isProjectGenerator', TJSONBool.Create(LTemplate.IsProjectGenerator));
      LObj.AddPair('slashCommand', LTemplate.SlashCommand);
      LJsonArr.AddElement(LObj);
    end;
    TFile.WriteAllText(AFileName, LJsonArr.ToJSON, TEncoding.UTF8);
  finally
    LJsonArr.Free;
  end;
end;

function TPromptTemplateManager.ImportFromFile(const AFileName: string; const AMerge: Boolean; out AErrorMsg: string): Boolean;
var
  LJsonContent: string;
  LParsedVal: TJSONValue;
  LJsonArr: TJSONArray;
  LVal: TJSONValue;
  LObj: TJSONObject;
  LTemplate: TPromptTemplate;
  LImportedTemplates: TList<TPromptTemplate>;
begin
  Result := False;
  AErrorMsg := '';
  
  if not TFile.Exists(AFileName) then
  begin
    AErrorMsg := 'File not found.';
    Exit;
  end;

  try
    LJsonContent := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  except
    on E: Exception do
    begin
      AErrorMsg := 'Failed to read file: ' + E.Message;
      Exit;
    end;
  end;

  if LJsonContent.Trim.IsEmpty then
  begin
    AErrorMsg := 'File is empty.';
    Exit;
  end;

  LParsedVal := TJSONObject.ParseJSONValue(LJsonContent);
  if not Assigned(LParsedVal) then
  begin
    AErrorMsg := 'Invalid JSON syntax.';
    Exit;
  end;

  LImportedTemplates := TList<TPromptTemplate>.Create;
  try
    try
      if not (LParsedVal is TJSONArray) then
      begin
        AErrorMsg := 'Invalid templates format. Root must be a JSON array.';
        Exit;
      end;

      LJsonArr := LParsedVal as TJSONArray;
      for LVal in LJsonArr do
      begin
        if not (LVal is TJSONObject) then
        begin
          AErrorMsg := 'Invalid template item format. Each item must be a JSON object.';
          Exit;
        end;

        LObj := LVal as TJSONObject;
        LTemplate.Name := LObj.GetValue<string>('name', '');
        LTemplate.Description := LObj.GetValue<string>('description', '');
        LTemplate.Template := LObj.GetValue<string>('template', '');
        LTemplate.IsProjectGenerator := LObj.GetValue<Boolean>('isProjectGenerator', False);
        LTemplate.SlashCommand := LObj.GetValue<string>('slashCommand', '');

        if LTemplate.Name.IsEmpty then
        begin
          AErrorMsg := 'Invalid template item: "name" property is mandatory.';
          Exit;
        end;

        if LTemplate.Template.IsEmpty then
        begin
          AErrorMsg := 'Invalid template item: "template" property is mandatory.';
          Exit;
        end;

        LImportedTemplates.Add(LTemplate);
      end;

      { Se a validação passou, aplica à base ativa }
      if not AMerge then
      begin
        FTemplates.Clear;
      end;

      for LTemplate in LImportedTemplates do
      begin
        AddTemplate(
          LTemplate.Name,
          LTemplate.Description,
          LTemplate.Template,
          LTemplate.IsProjectGenerator,
          LTemplate.SlashCommand
        );
      end;

      Save; // Grava imediatamente as mudanças no arquivo local
      Result := True;

    except
      on E: Exception do
      begin
        AErrorMsg := 'Error parsing templates data: ' + E.Message;
      end;
    end;
  finally
    LImportedTemplates.Free;
    LParsedVal.Free;
  end;
end;

end.
