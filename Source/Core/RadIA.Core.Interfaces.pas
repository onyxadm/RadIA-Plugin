unit RadIA.Core.Interfaces;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Types;

type
  { Callback type for asynchronous AI responses }
  TCompletionCallback = reference to procedure(const AResponse: string; const AError: string; AFromCache: Boolean);

  { Interface representing a message in the chat history }
  IChatMessage = interface
    ['{69A8A5DC-0F88-46E1-AD7A-8A46101EA97D}']
    function GetRole: TAIMessageRole;
    function GetContent: string;
    procedure SetContent(const AValue: string);
    property Role: TAIMessageRole read GetRole;
    property Content: string read GetContent write SetContent;
  end;

  { Interface representing an AI Provider }
  IIAProvider = interface
    ['{A2833F49-9A0B-432D-8B8D-20DFF15FF25D}']
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback);
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
    function GetAvailableModels: TArray<string>;
    function GetName: string;
    function GetProviderType: TAIProviderType;
  end;

  { Interface representing Configuration Management }
  IAIConfig = interface
    ['{88A9678F-520E-4BF5-BFB4-5C04A5826A6F}']
    function GetApiKey(const AProvider: TAIProviderType): string;
    procedure SetApiKey(const AProvider: TAIProviderType; const AKey: string);
    function GetActiveProvider: TAIProviderType;
    procedure SetActiveProvider(const AProvider: TAIProviderType);
    function GetActiveModel(const AProvider: TAIProviderType): string;
    procedure SetActiveModel(const AProvider: TAIProviderType; const AModel: string);
    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    procedure Save;
    procedure Load;
    property SystemPrompt: string read GetSystemPrompt write SetSystemPrompt;
  end;

implementation

end.
