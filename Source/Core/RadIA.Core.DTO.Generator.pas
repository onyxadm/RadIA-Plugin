unit RadIA.Core.DTO.Generator;

interface

uses
  RadIA.Core.Interfaces;

type
  TRadIADTOBuilder = class(TInterfacedObject, IRadIADTOBuilder)
  public
    function BuildPrompt(const AInput, AInputType, AOutputType: string): string;
  end;

implementation

uses
  System.SysUtils;

function TRadIADTOBuilder.BuildPrompt(const AInput, AInputType, AOutputType: string): string;
var
  LFormatRules: string;
begin
  LFormatRules := '';
  
  if SameText(AOutputType, 'vanilla') then
  begin
    LFormatRules := 
      'Generate a standard Delphi class structure. ' +
      'Use proper private fields prefixed with "F" (e.g., FName: string) ' +
      'and matching public properties with read/write accessors. ' +
      'Implement a constructor (Create) and a destructor (Destroy) if needed. ' +
      'Do not include any external library attributes.';
  end
  else if SameText(AOutputType, 'record') then
  begin
    LFormatRules := 
      'Generate a modern Delphi record structure. ' +
      'Use PascalCase for field names. Do not use "F" prefix for record fields. ' +
      'Include simple helper methods if appropriate, but keep it lightweight. ' +
      'Do not use classes, only records.';
  end
  else if SameText(AOutputType, 'restjson') then
  begin
    LFormatRules := 
      'Generate a Delphi class structure mapped for REST.Json serialization. ' +
      'Ensure the properties are decorated with the [JSONName(''field_name'')] attribute ' +
      'from the REST.Json.Types unit (part of System.JSON/REST.Json). ' +
      'Include the appropriate uses clause (REST.Json.Types, System.JSON).';
  end
  else if SameText(AOutputType, 'aurelius') then
  begin
    LFormatRules := 
      'Generate a Delphi class structure mapped for TMS Aurelius ORM. ' +
      'Ensure the class is decorated with [Entity] and [Table(''table_name'')]. ' +
      'Properties/Fields must have mapping attributes like [Column(''col_name'', [TColumnProp.Required])], ' +
      '[Id(''FId'', TIdGenerator.IdentityOrSequence)]. ' +
      'Include the appropriate Aurelius units in the uses clause (Aurelius.Mapping.Attributes).';
  end
  else if SameText(AOutputType, 'dext') then
  begin
LFormatRules := 
        'Generate a complete Delphi class structure mapped for DEXT ORM using the following rules:' + sLineBreak +
        '1. Uses Clause: Must include: System.SysUtils, System.Classes, Dext.Entity, Dext.Entity.Collections, Dext.Types.Nullable, Dext.Types.Lazy, Dext.Core.SmartTypes.' + sLineBreak +
        '2. Properties: Map database columns via public properties, not private/public fields. Private backing fields must start with F (e.g., FId, FName).' + sLineBreak +
        '3. No Unnecessary Getters/Setters: For regular columns (including standard Smart Properties and nullable columns), ' +
        'do NOT create getter/setter methods. Use direct read/write access to the backing fields ' +
        '(e.g., property Name: StringType read FName write FName;). Getters and setters should ' +
        'only be created for relationship properties (BelongsTo/HasMany).' + sLineBreak +
        '4. Smart Properties: Use native aliases for columns: IntType, StringType, DoubleType, BoolType.' + sLineBreak +
        '5. Class Attributes: Apply [Table(''table_name'')] directly above the class definition.' + sLineBreak +
        '6. Primary Keys: Annotate properties with [PK] or [PK, AutoInc] for auto-incrementing fields.' + sLineBreak +
        '7. Columns: Use [Column(''column_name'')]. Use [Required] for non-nullable fields, and [MaxLength(N)] for string limits. NEVER use [StringLength].' + sLineBreak +
        '8. Nullable: For database columns that can be NULL, use Nullable<T> (e.g. Nullable<Integer>) for standard fields. For Smart Properties, use Prop<Nullable<T>> (e.g. Prop<Nullable<string>>). NEVER use Nullable<Prop<T>> or Nullable<StringType>.' + sLineBreak +
        '9. Many-to-One (BelongsTo) Relationships:' + sLineBreak +
        '   - Private backing field must be ILazy<TEntityClass> (e.g., FUser: ILazy<TUser>;).' + sLineBreak +
        '   - Annotate property with [ForeignKey(''foreign_key_column''), BelongsTo].' + sLineBreak +
        '   - Getter implementation pattern:' + sLineBreak +
        '     function TMyClass.GetMyRef: TEntityClass;' + sLineBreak +
        '     begin' + sLineBreak +
        '       if FMyRef <> nil then Result := FMyRef.Value else Result := nil;' + sLineBreak +
        '     end;' + sLineBreak +
        '   - Setter implementation pattern:' + sLineBreak +
        '     procedure TMyClass.SetMyRef(const Value: TEntityClass);' + sLineBreak +
        '     begin' + sLineBreak +
        '       FMyRef := TValueLazy<TEntityClass>.Create(Value);' + sLineBreak +
        '       if Value <> nil then FForeignKeyId := Value.Id;' + sLineBreak +
        '     end;' + sLineBreak +
        '10. One-to-Many (HasMany) Relationships:' + sLineBreak +
        '    - Private backing field must be ILazy<TList<TEntityClass>> (e.g., FOrders: ILazy<TList<TOrder>>;).' + sLineBreak +
        '    - Annotate property with [InverseProperty(''BackNavigationPropName''), HasMany]. No setter should be generated.' + sLineBreak +
        '    - Getter implementation pattern:' + sLineBreak +
        '      function TMyClass.GetMyList: TList<TEntityClass>;' + sLineBreak +
        '      begin' + sLineBreak +
        '        if FMyList = nil then FMyList := TLazy<TList<TEntityClass>>.Create;' + sLineBreak +
        '        Result := FMyList.Value;' + sLineBreak +
        '      end;' + sLineBreak +
        '11. Ensure that getter and setter methods for relationship properties are fully implemented inside the implementation section.';
  end;

  Result := 
    'You are a senior Delphi developer. Your task is to convert the following input ' +
    'into clean, well-formatted, and compile-ready Delphi Object Pascal code. ' +
    'The output MUST contain only the Delphi unit code (interface, implementation, uses clauses, ' +
    'class declarations, property declarations) inside a code block. Do not write explanations ' +
    'or conversational text outside the code block.' + sLineBreak + sLineBreak +
    'Input Type: ' + AInputType.ToUpper + sLineBreak +
    'Desired Output Format: ' + AOutputType.ToUpper + sLineBreak + sLineBreak +
    'Specific Formatting Rules:' + sLineBreak + LFormatRules + sLineBreak + sLineBreak +
    'Input Data:' + sLineBreak + AInput;
end;

end.
