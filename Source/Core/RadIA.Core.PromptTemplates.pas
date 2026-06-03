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
    'Revisar Clean Code Delphi',
    'Revisa código Pascal aplicando Clean Code e SOLID',
    'Revise o seguinte código Delphi Pascal aplicando princípios de Clean Code, legibilidade e otimização:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Documentar unit completa',
    'Gera documentação XML para classes e métodos',
    'Gere a documentação no formato XML Documentation (compatível com Delphi) para a seguinte unit:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Criar mock DUnitX',
    'Gera unit de teste com DUnitX para a classe',
    'Crie uma unit de teste utilizando DUnitX para testar a seguinte classe Delphi:'#13#10#13#10'{code}'
  );
  AddTemplate(
    'Analisar performance',
    'Identifica gargalos e memory leaks no código',
    'Análise de performance: identifique possíveis gargalos, vazamentos de memória (memory leaks) ou redundâncias no seguinte código Delphi:'#13#10#13#10'{code}'
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
    LParsedVal := TJSONObject.ParseJSONValue(LJsonContent);
    if Assigned(LParsedVal) then
    begin
      if LParsedVal is TJSONArray then
      begin
        LJsonArr := LParsedVal as TJSONArray;
        try
          for LVal in LJsonArr do
          begin
            if LVal is TJSONObject then
            begin
              LObj := LVal as TJSONObject;
              LTemplate.Name := LObj.GetValue('name').Value;
              LTemplate.Description := LObj.GetValue('description').Value;
              LTemplate.Template := LObj.GetValue('template').Value;
              FTemplates.Add(LTemplate);
            end;
          end;
        finally
          LJsonArr.Free;
        end;
      end
      else
      begin
        LParsedVal.Free;
        CreateDefaultTemplates;
      end;
    end;
  except
    { Fallback to defaults on corrupt file }
    CreateDefaultTemplates;
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
