program Minimal;

{$I ..\..\source\uWebUI.inc}

{$APPTYPE CONSOLE}

{$R *.res}

uses
  {$IFDEF DELPHI16_UP}
  System.SysUtils,
  {$ELSE}
  SysUtils,
  {$ENDIF}
  uWebUI, uWebUIWindow;

var
  LWindow : TWebUIWindow;

begin
  LWindow := nil;
  try
    try
      WebUI := TWebUI.Create;
      if WebUI.Initialize then
        begin
          LWindow := TWebUIWindow.Create;
          LWindow.Show('<html><head><script src="webui.js"></script></head> Hello World ! </html>');
          WebUI.Wait;
        end;
    finally
      if assigned(LWindow) then
        FreeAndNil(LWindow);

      DestroyWebUI;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
