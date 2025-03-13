unit uWebUI;

{$I uWebUI.inc}

{$IFDEF FPC}
  {$MODE delphiunicode}
{$ENDIF}

{$IFNDEF TARGET_64BITS}{$ALIGN ON}{$ENDIF}
{$MINENUMSIZE 4}

{$IFNDEF DELPHI12_UP}
  // Workaround for "Internal error" in old Delphi versions caused by uint64 handling
  {$R-}
{$ENDIF}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows,{$ENDIF} System.Classes, System.SysUtils,
    System.Math, System.SyncObjs,
    {$IFDEF MACOS}
    FMX.Helpers.Mac, System.Messaging, Macapi.CoreFoundation, Macapi.Foundation,
    {$ENDIF}
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows,{$ENDIF} Classes, SysUtils, Math, SyncObjs,
  {$ENDIF}
  uWebUIConstants, uWebUITypes, uWebUILibFunctions, uWebUIWindow;

type
  /// <summary>
  /// Class used to simplify the WebUI initialization and destruction.
  /// </summary>
  TWebUI = class
    protected
      FLibHandle                              : {$IFDEF FPC}TLibHandle{$ELSE}THandle{$ENDIF};
      FSetCurrentDir                          : boolean;
      FReRaiseExceptions                      : boolean;
      FLibraryPath                            : string;
      FStatus                                 : TLoaderStatus;
      FErrorLog                               : TStringList;
      FError                                  : int64;
      FShowMessageDlg                         : boolean;
      FTimeout                                : NativeUInt;
      FWindowList                             : TList;
      FCritSection                            : TCriticalSection;
      {$IFDEF DELPHI14_UP}
      FSyncedEvents                           : boolean;
      {$ENDIF}
      function  GetErrorMessage : string;
      function  GetInitialized : boolean;
      function  GetInitializationError : boolean;
      function  GetIsAppRunning : boolean;
      function  GetStatus : TLoaderStatus;
      function  GetLibraryVersion : string;
      function  GetFreePort: NativeUInt;
      function  GetIsHighContrast : boolean;

      procedure SetTimeout(aValue: NativeUInt);
      procedure SetStatus(aValue: TLoaderStatus);

      procedure DestroyWindowList;
      function  DefaultLibraryPath : string;
      function  LoadWebUILibrary : boolean;
      function  LoadLibProcedures : boolean;
      procedure UnLoadWebUILibrary;
      procedure ShowErrorMessageDlg(const aError : string);
      function  SearchWindowIndex(windowId: TWebUIWindowID) : integer;
      function  Lock: boolean;
      procedure Unlock;

    public
      constructor Create;
      procedure   AfterConstruction; override;
      procedure   BeforeDestruction; override;
      /// <summary>
      /// Initialize the WebUI library.
      /// </summary>
      function    Initialize : boolean;
      /// <summary>
      /// Append aText to the ErrorMessage property.
      /// </summary>
      procedure   AppendErrorLog(const aText : string); overload;
      /// <summary>
      /// Append aTextLines to the ErrorMessage property.
      /// </summary>
      procedure   AppendErrorLog(const aTextLines : TStringList); overload;
      /// <summary>
      /// Wait until all opened windows get closed.
      /// </summary>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_wait)</see></para>
      /// </remarks>
      procedure   Wait;
      /// <summary>
      /// Free all memory resources. Should be called only at the end.
      /// </summary>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_clean)</see></para>
      /// </remarks>
      procedure   Clean;
      /// <summary>
      /// Close all open windows. `webui_wait()` will return (Break).
      /// </summary>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_exit)</see></para>
      /// </remarks>
      procedure   Exit;
      /// <summary>
      /// Delete all local web-browser profiles folder. It should called at the end.
      /// </summary>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_delete_all_profiles)</see></para>
      /// </remarks>
      procedure   DeleteAllProfiles;
      /// <summary>
      /// Set the web-server root folder path for all windows. Should be used before `webui_show()`.
      /// </summary>
      /// <param name="path">The local folder full path.</param>
      /// <returns>Returns True if the function was successful.</returns>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_set_default_root_folder)</see></para>
      /// </remarks>
      function    SetDefaultRootFolder(const path : string) : boolean;
      /// <summary>
      /// Set the SSL/TLS certificate and the private key content, both in PEM
      /// format. This works only with `webui-2-secure` library. If set empty WebUI
      /// will generate a self-signed certificate.
      /// </summary>
      /// <param name="certificate_pem">The SSL/TLS certificate content in PEM format.</param>
      /// <param name="private_key_pem">The private key content in PEM format.</param>
      /// <returns>Returns True if the certificate and the key are valid.</returns>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_set_tls_certificate)</see></para>
      /// </remarks>
      function    SetTLSCertificate(const certificate_pem, private_key_pem : string): boolean;
      /// <summary>
      /// Search an IWebUIWindow instance.
      /// </summary>
      function    SearchWindow(windowId: TWebUIWindowID) : IWebUIWindow;
      /// <summary>
      /// Add an IWebUIWindow instance.
      /// </summary>
      function    AddWindow(const window: IWebUIWindow): int64;
      /// <summary>
      /// Remove an IWebUIWindow instance.
      /// </summary>
      procedure   RemoveWindow(windowId: TWebUIWindowID);
      /// <summary>
      /// Control the WebUI behaviour. It's recommended to be called at the beginning.
      /// </summary>
      /// <param name="option">The desired option from `webui_config` enum.</param>
      /// <param name="status">The status of the option, `true` or `false`.</param>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_set_config)</see></para>
      /// </remarks>
      procedure   SetConfig(option: TWebUIConfig; status: boolean);
      /// <summary>
      /// Check if a web browser is installed.
      /// </summary>
      /// <param name="browser">The web browser to be found.</param>
      /// <returns>Returns True if the specified browser is available.</returns>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_is_high_contrast)</see></para>
      /// </remarks>
      function    BrowserExist(browser: TWebUIBrowser): boolean;
      /// <summary>
      /// Get the HTTP mime type of a file.
      /// </summary>
      /// <param name="file_">The file name.</param>
      /// <returns>Returns the HTTP mime string.</returns>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_get_mime_type)</see></para>
      /// </remarks>
      function    GetMimeType(const file_: string): string;
      /// <summary>
      /// Open an URL in the native default web browser.
      /// </summary>
      /// <param name="url">The URL to open.</param>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_open_url)</see></para>
      /// </remarks>
      procedure   OpenURL(const url: string);

      /// <summary>
      /// Returns the TWVLoader initialization status.
      /// </summary>
      property Status                                 : TLoaderStatus                      read GetStatus                                write SetStatus;
      /// <summary>
      /// Returns all the text appended to the error log with AppendErrorLog.
      /// </summary>
      property ErrorMessage                           : string                             read GetErrorMessage;
      /// <summary>
      ///  Used to set the current directory when the WebView2 library is loaded. This is required if the application is launched from a different application.
      /// </summary>
      property SetCurrentDir                          : boolean                            read FSetCurrentDir                           write FSetCurrentDir;
      /// <summary>
      /// Set to true to raise all exceptions.
      /// </summary>
      property ReRaiseExceptions                      : boolean                            read FReRaiseExceptions                       write FReRaiseExceptions;
      /// <summary>
      /// Full path to WebUI library. Leave empty to load the library from the current directory.
      /// </summary>
      property LibraryPath                            : string                             read FLibraryPath                             write FLibraryPath;
      /// <summary>
      /// Supported WebUI library version.
      /// </summary>
      property LibraryVersion                         : string                             read GetLibraryVersion;
      /// <summary>
      /// Set to true when you need to use a showmessage dialog to show the error messages.
      /// </summary>
      property ShowMessageDlg                         : boolean                            read FShowMessageDlg                          write FShowMessageDlg;
      /// <summary>
      /// Returns true if the Status is lsInitialized.
      /// </summary>
      property Initialized                            : boolean                            read GetInitialized;
      /// <summary>
      /// Returns true if the Status is lsError.
      /// </summary>
      property InitializationError                    : boolean                            read GetInitializationError;
      /// <summary>
      /// Check if the app still running.
      /// </summary>
      /// <returns>Returns True if app is running.</returns>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_interface_is_app_running)</see></para>
      /// </remarks>
      property IsAppRunning                           : boolean                            read GetIsAppRunning;
      /// <summary>
      /// Set the maximum time in seconds to wait for the window to connect. This effect `show()` and `wait()`. Value of `0` means wait forever.
      /// </summary>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_set_timeout)</see></para>
      /// </remarks>
      property Timeout                                : NativeUInt                         read FTimeout                                 write SetTimeout;
      {$IFDEF DELPHI14_UP}
      /// <summary>
      /// Execute the events in the main application thread whenever it's possible.
      /// </summary>
      property SyncedEvents                           : boolean                            read FSyncedEvents                            write FSyncedEvents;
      {$ENDIF}
      /// <summary>
      /// Get OS high contrast preference.
      /// </summary>
      /// <returns>Returns True if OS is using high contrast theme.</returns>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_is_high_contrast)</see></para>
      /// </remarks>
      property IsHighContrast                         : boolean                            read GetIsHighContrast;
      /// <summary>
      /// Get an available usable free network port.
      /// </summary>
      /// <remarks>
      /// <para><see href="https://github.com/webui-dev/webui/blob/main/include/webui.h">WebUI source file: /include/webui.h (webui_get_free_port)</see></para>
      /// </remarks>
      property FreePort                               : NativeUInt                         read GetFreePort;
  end;

var
  WebUI : TWebUI = nil;

procedure DestroyWebUI;
procedure global_webui_event_callback(e: PWebUIEvent); cdecl;

implementation

uses
  {$IFDEF LINUXFPC}
    {$IFDEF CONSOLE}dynlibs,{$ELSE}Forms, InterfaceBase,{$ENDIF}
  {$ENDIF}
  uWebUIMiscFunctions, uWebUIEventHandler;

procedure DestroyWebUI;
begin
  if assigned(WebUI) then
    FreeAndNil(WebUI);
end;

procedure global_webui_event_callback(e: PWebUIEvent); cdecl;
var
  LWindow : IWebUIWindow;
  LEvent  : IWebUIEventHandler;
begin
  if assigned(WebUI) and WebUI.Initialized then
    try
      LEvent  := TWebUIEventHandler.Create(e);
      LWindow := WebUI.SearchWindow(LEvent.WindowID);

      if assigned(LWindow) and LWindow.HasBindID(e^.bind_id) then
        LWindow.doOnWebUIEvent(LEvent);
    finally
      LEvent  := nil;
      LWindow := nil;
    end;
end;

constructor TWebUI.Create;
begin
  inherited Create;

  FLibHandle                              := 0;
  FSetCurrentDir                          := True;
  FReRaiseExceptions                      := False;
  FLibraryPath                            := '';
  FStatus                                 := lsCreated;
  FErrorLog                               := nil;
  FShowMessageDlg                         := True;
  FTimeout                                := WEBUI_DEFAULT_TIMEOUT;
  FWindowList                             := nil;
  FCritSection                            := nil;
  {$IFDEF DELPHI14_UP}
  FSyncedEvents                           := True;
  {$ENDIF}
end;

procedure TWebUI.AfterConstruction;
begin
  inherited AfterConstruction;

  FCritSection := TCriticalSection.Create;
  FWindowList  := TList.Create;
  FErrorLog    := TStringList.Create;
end;

procedure TWebUI.BeforeDestruction;
begin
  try
    DestroyWindowList;
    Clean;
    UnLoadWebUILibrary;

    if assigned(FCritSection) then
      FreeAndNil(FCritSection);

    if assigned(FErrorLog) then
      FreeAndNil(FErrorLog);
  finally
    inherited BeforeDestruction;
  end;
end;

function TWebUI.Lock: boolean;
begin
  Result := False;

  if assigned(FCritSection) then
    begin
      FCritSection.Acquire;
      Result := True;
    end;
end;

procedure TWebUI.Unlock;
begin
  if assigned(FCritSection) then
    FCritSection.Release;
end;

procedure TWebUI.DestroyWindowList;
var
  i: integer;
begin
  if assigned(FWindowList) then
    begin
      for i := 0 to pred(FWindowList.Count) do
        FWindowList[i] := nil;

      FreeAndNil(FWindowList);
    end;
end;

function TWebUI.Initialize : boolean;
begin
  Result := LoadWebUILibrary and
            LoadLibProcedures;
end;

procedure TWebUI.UnLoadWebUILibrary;
begin
  try
    if (FLibHandle <> 0) then
      begin
        FreeLibrary(FLibHandle);
        FLibHandle := 0;
        Status     := lsUnloaded;
      end;
  except
    on e : exception do
      if CustomExceptionHandler('TWebUI.UnLoadWebUILibrary', e) then raise;
  end;
end;

function TWebUI.LoadWebUILibrary : boolean;
var
  TempOldDir      : string;
  TempLibraryPath : string;
begin
  Result := False;

  try
    if (FLibHandle <> 0) then
      Result := True
     else
      try
        if FSetCurrentDir then
          begin
            TempOldDir := {$IFDEF FPC}string({$ENDIF}GetCurrentDir{$IFDEF FPC}){$ENDIF};
            chdir(GetModulePath);
          end;

        Status := lsLoading;

        if (FLibraryPath <> '') then
          TempLibraryPath := FLibraryPath
         else
          TempLibraryPath := DefaultLibraryPath;

        if LibraryExists(TempLibraryPath) then
          begin
            {$IFDEF FPC}
              {$IFDEF MSWINDOWS}
              FLibHandle := LoadLibraryW(PWideChar(TempLibraryPath));
              {$ELSE}
              FLibHandle := LoadLibrary(TempLibraryPath);
              {$ENDIF}
            {$ELSE}
            FLibHandle := LoadLibrary({$IFDEF DELPHI12_UP}PWideChar{$ELSE}PAnsiChar{$ENDIF}(TempLibraryPath));
            {$ENDIF}

            if (FLibHandle = 0) then
              begin
                Status := lsError;
                {$IFDEF MSWINDOWS}
                FError := GetLastError;
                {$ELSE}
                  {$IFDEF FPC}
                  FError := GetLastOSError;
                  {$ENDIF}
                {$ENDIF}
                AppendErrorLog('Error loading ' + TempLibraryPath);
                {$IFDEF MSWINDOWS}
                AppendErrorLog('Error code : 0x' + {$IFDEF FPC}string({$ENDIF}inttohex(cardinal(FError), 8)){$IFDEF FPC}){$ENDIF};
                AppendErrorLog({$IFDEF FPC}string({$ENDIF}SysErrorMessage(cardinal(FError)){$IFDEF FPC}){$ENDIF});
                {$ELSE}
                  {$IFDEF FPC}
                  AppendErrorLog('Error code : 0x' + string(inttohex(cardinal(FError), 8)));
                  AppendErrorLog(trim(GetLoadErrorStr));
                  {$ENDIF}
                {$ENDIF}
                ShowErrorMessageDlg(ErrorMessage);
              end
             else
              begin
                Status := lsLoaded;
                Result := True;
              end;
          end
         else
          begin
            Status := lsError;

            AppendErrorLog('Error loading ' + TempLibraryPath);
            AppendErrorLog('The WebUI library is missing.');

            ShowErrorMessageDlg(ErrorMessage);
          end;
      finally
        if FSetCurrentDir then
          chdir(TempOldDir);
      end;
  except
    on e : exception do
      if CustomExceptionHandler('TWebUI.LoadWebUILibrary', e) then raise;
  end;
end;

function TWebUI.LoadLibProcedures : boolean;
var
  LMissing : TStringList;
begin
  Result   := False;
  LMissing := nil;

  if (FLibHandle = 0) then exit;

  try
    try
      LMissing := TStringList.Create;

      webui_new_window                          := GetProcAddress(FLibHandle, 'webui_new_window');
      webui_new_window_id                       := GetProcAddress(FLibHandle, 'webui_new_window_id');
      webui_get_new_window_id                   := GetProcAddress(FLibHandle, 'webui_get_new_window_id');
      webui_bind                                := GetProcAddress(FLibHandle, 'webui_bind');
      webui_set_context                         := GetProcAddress(FLibHandle, 'webui_set_context');
      webui_get_context                         := GetProcAddress(FLibHandle, 'webui_get_context');
      webui_get_best_browser                    := GetProcAddress(FLibHandle, 'webui_get_best_browser');
      webui_show                                := GetProcAddress(FLibHandle, 'webui_show');
      webui_show_client                         := GetProcAddress(FLibHandle, 'webui_show_client');
      webui_show_browser                        := GetProcAddress(FLibHandle, 'webui_show_browser');
      webui_start_server                        := GetProcAddress(FLibHandle, 'webui_start_server');
      webui_show_wv                             := GetProcAddress(FLibHandle, 'webui_show_wv');
      webui_set_kiosk                           := GetProcAddress(FLibHandle, 'webui_set_kiosk');
      webui_set_custom_parameters               := GetProcAddress(FLibHandle, 'webui_set_custom_parameters');
      webui_set_high_contrast                   := GetProcAddress(FLibHandle, 'webui_set_high_contrast');
      webui_is_high_contrast                    := GetProcAddress(FLibHandle, 'webui_is_high_contrast');
      webui_browser_exist                       := GetProcAddress(FLibHandle, 'webui_browser_exist');
      webui_wait                                := GetProcAddress(FLibHandle, 'webui_wait');
      webui_close                               := GetProcAddress(FLibHandle, 'webui_close');
      webui_close_client                        := GetProcAddress(FLibHandle, 'webui_close_client');
      webui_destroy                             := GetProcAddress(FLibHandle, 'webui_destroy');
      webui_exit                                := GetProcAddress(FLibHandle, 'webui_exit');
      webui_set_root_folder                     := GetProcAddress(FLibHandle, 'webui_set_root_folder');
      webui_set_default_root_folder             := GetProcAddress(FLibHandle, 'webui_set_default_root_folder');
      webui_set_file_handler                    := GetProcAddress(FLibHandle, 'webui_set_file_handler');
      webui_set_file_handler_window             := GetProcAddress(FLibHandle, 'webui_set_file_handler_window');
      webui_interface_set_response_file_handler := GetProcAddress(FLibHandle, 'webui_interface_set_response_file_handler');
      webui_is_shown                            := GetProcAddress(FLibHandle, 'webui_is_shown');
      webui_set_timeout                         := GetProcAddress(FLibHandle, 'webui_set_timeout');
      webui_set_icon                            := GetProcAddress(FLibHandle, 'webui_set_icon');
      webui_encode                              := GetProcAddress(FLibHandle, 'webui_encode');
      webui_decode                              := GetProcAddress(FLibHandle, 'webui_decode');
      webui_free                                := GetProcAddress(FLibHandle, 'webui_free');
      webui_malloc                              := GetProcAddress(FLibHandle, 'webui_malloc');
      webui_memcpy                              := GetProcAddress(FLibHandle, 'webui_memcpy');
      webui_send_raw                            := GetProcAddress(FLibHandle, 'webui_send_raw');
      webui_send_raw_client                     := GetProcAddress(FLibHandle, 'webui_send_raw_client');
      webui_set_hide                            := GetProcAddress(FLibHandle, 'webui_set_hide');
      webui_set_size                            := GetProcAddress(FLibHandle, 'webui_set_size');
      webui_set_minimum_size                    := GetProcAddress(FLibHandle, 'webui_set_minimum_size');
      webui_set_position                        := GetProcAddress(FLibHandle, 'webui_set_position');
      webui_set_profile                         := GetProcAddress(FLibHandle, 'webui_set_profile');
      webui_set_proxy                           := GetProcAddress(FLibHandle, 'webui_set_proxy');
      webui_get_url                             := GetProcAddress(FLibHandle, 'webui_get_url');
      webui_open_url                            := GetProcAddress(FLibHandle, 'webui_open_url');
      webui_set_public                          := GetProcAddress(FLibHandle, 'webui_set_public');
      webui_navigate                            := GetProcAddress(FLibHandle, 'webui_navigate');
      webui_navigate_client                     := GetProcAddress(FLibHandle, 'webui_navigate_client');
      webui_clean                               := GetProcAddress(FLibHandle, 'webui_clean');
      webui_delete_all_profiles                 := GetProcAddress(FLibHandle, 'webui_delete_all_profiles');
      webui_delete_profile                      := GetProcAddress(FLibHandle, 'webui_delete_profile');
      webui_get_parent_process_id               := GetProcAddress(FLibHandle, 'webui_get_parent_process_id');
      webui_get_child_process_id                := GetProcAddress(FLibHandle, 'webui_get_child_process_id');
      webui_win32_get_hwnd                      := GetProcAddress(FLibHandle, 'webui_win32_get_hwnd');
      webui_get_port                            := GetProcAddress(FLibHandle, 'webui_get_port');
      webui_set_port                            := GetProcAddress(FLibHandle, 'webui_set_port');
      webui_get_free_port                       := GetProcAddress(FLibHandle, 'webui_get_free_port');
      webui_set_config                          := GetProcAddress(FLibHandle, 'webui_set_config');
      webui_set_event_blocking                  := GetProcAddress(FLibHandle, 'webui_set_event_blocking');
      webui_get_mime_type                       := GetProcAddress(FLibHandle, 'webui_get_mime_type');
      webui_set_tls_certificate                 := GetProcAddress(FLibHandle, 'webui_set_tls_certificate');
      webui_run                                 := GetProcAddress(FLibHandle, 'webui_run');
      webui_run_client                          := GetProcAddress(FLibHandle, 'webui_run_client');
      webui_script                              := GetProcAddress(FLibHandle, 'webui_script');
      webui_script_client                       := GetProcAddress(FLibHandle, 'webui_script_client');
      webui_set_runtime                         := GetProcAddress(FLibHandle, 'webui_set_runtime');
      webui_get_count                           := GetProcAddress(FLibHandle, 'webui_get_count');
      webui_get_int_at                          := GetProcAddress(FLibHandle, 'webui_get_int_at');
      webui_get_int                             := GetProcAddress(FLibHandle, 'webui_get_int');
      webui_get_float_at                        := GetProcAddress(FLibHandle, 'webui_get_float_at');
      webui_get_float                           := GetProcAddress(FLibHandle, 'webui_get_float');
      webui_get_string_at                       := GetProcAddress(FLibHandle, 'webui_get_string_at');
      webui_get_string                          := GetProcAddress(FLibHandle, 'webui_get_string');
      webui_get_bool_at                         := GetProcAddress(FLibHandle, 'webui_get_bool_at');
      webui_get_bool                            := GetProcAddress(FLibHandle, 'webui_get_bool');
      webui_get_size_at                         := GetProcAddress(FLibHandle, 'webui_get_size_at');
      webui_get_size                            := GetProcAddress(FLibHandle, 'webui_get_size');
      webui_return_int                          := GetProcAddress(FLibHandle, 'webui_return_int');
      webui_return_float                        := GetProcAddress(FLibHandle, 'webui_return_float');
      webui_return_string                       := GetProcAddress(FLibHandle, 'webui_return_string');
      webui_return_bool                         := GetProcAddress(FLibHandle, 'webui_return_bool');
      webui_interface_bind                      := GetProcAddress(FLibHandle, 'webui_interface_bind');
      webui_interface_set_response              := GetProcAddress(FLibHandle, 'webui_interface_set_response');
      webui_interface_is_app_running            := GetProcAddress(FLibHandle, 'webui_interface_is_app_running');
      webui_interface_get_window_id             := GetProcAddress(FLibHandle, 'webui_interface_get_window_id');
      webui_interface_get_string_at             := GetProcAddress(FLibHandle, 'webui_interface_get_string_at');
      webui_interface_get_int_at                := GetProcAddress(FLibHandle, 'webui_interface_get_int_at');
      webui_interface_get_float_at              := GetProcAddress(FLibHandle, 'webui_interface_get_float_at');
      webui_interface_get_bool_at               := GetProcAddress(FLibHandle, 'webui_interface_get_bool_at');
      webui_interface_get_size_at               := GetProcAddress(FLibHandle, 'webui_interface_get_size_at');
      webui_interface_show_client               := GetProcAddress(FLibHandle, 'webui_interface_show_client');
      webui_interface_close_client              := GetProcAddress(FLibHandle, 'webui_interface_close_client');
      webui_interface_send_raw_client           := GetProcAddress(FLibHandle, 'webui_interface_send_raw_client');
      webui_interface_navigate_client           := GetProcAddress(FLibHandle, 'webui_interface_navigate_client');
      webui_interface_run_client                := GetProcAddress(FLibHandle, 'webui_interface_run_client');
      webui_interface_script_client             := GetProcAddress(FLibHandle, 'webui_interface_script_client');

      if not(assigned(webui_new_window))                           then LMissing.Add('webui_new_window');
      if not(assigned(webui_new_window_id))                        then LMissing.Add('webui_new_window_id');
      if not(assigned(webui_get_new_window_id))                    then LMissing.Add('webui_get_new_window_id');
      if not(assigned(webui_bind))                                 then LMissing.Add('webui_bind');
      if not(assigned(webui_set_context))                          then LMissing.Add('webui_set_context');
      if not(assigned(webui_get_context))                          then LMissing.Add('webui_get_context');
      if not(assigned(webui_get_best_browser))                     then LMissing.Add('webui_get_best_browser');
      if not(assigned(webui_show))                                 then LMissing.Add('webui_show');
      if not(assigned(webui_show_client))                          then LMissing.Add('webui_show_client');
      if not(assigned(webui_show_browser))                         then LMissing.Add('webui_show_browser');
      if not(assigned(webui_start_server))                         then LMissing.Add('webui_start_server');
      if not(assigned(webui_show_wv))                              then LMissing.Add('webui_show_wv');
      if not(assigned(webui_set_kiosk))                            then LMissing.Add('webui_set_kiosk');
      if not(assigned(webui_set_custom_parameters))                then LMissing.Add('webui_set_custom_parameters');
      if not(assigned(webui_set_high_contrast))                    then LMissing.Add('webui_set_high_contrast');
      if not(assigned(webui_is_high_contrast))                     then LMissing.Add('webui_is_high_contrast');
      if not(assigned(webui_browser_exist))                        then LMissing.Add('webui_browser_exist');
      if not(assigned(webui_wait))                                 then LMissing.Add('webui_wait');
      if not(assigned(webui_close))                                then LMissing.Add('webui_close');
      if not(assigned(webui_close_client))                         then LMissing.Add('webui_close_client');
      if not(assigned(webui_destroy))                              then LMissing.Add('webui_destroy');
      if not(assigned(webui_exit))                                 then LMissing.Add('webui_exit');
      if not(assigned(webui_set_root_folder))                      then LMissing.Add('webui_set_root_folder');
      if not(assigned(webui_set_default_root_folder))              then LMissing.Add('webui_set_default_root_folder');
      if not(assigned(webui_set_file_handler))                     then LMissing.Add('webui_set_file_handler');
      if not(assigned(webui_set_file_handler_window))              then LMissing.Add('webui_set_file_handler_window');
      if not(assigned(webui_interface_set_response_file_handler))  then LMissing.Add('webui_interface_set_response_file_handler');
      if not(assigned(webui_is_shown))                             then LMissing.Add('webui_is_shown');
      if not(assigned(webui_set_timeout))                          then LMissing.Add('webui_set_timeout');
      if not(assigned(webui_set_icon))                             then LMissing.Add('webui_set_icon');
      if not(assigned(webui_encode))                               then LMissing.Add('webui_encode');
      if not(assigned(webui_decode))                               then LMissing.Add('webui_decode');
      if not(assigned(webui_free))                                 then LMissing.Add('webui_free');
      if not(assigned(webui_malloc))                               then LMissing.Add('webui_malloc');
      if not(assigned(webui_memcpy))                               then LMissing.Add('webui_memcpy');
      if not(assigned(webui_send_raw))                             then LMissing.Add('webui_send_raw');
      if not(assigned(webui_send_raw_client))                      then LMissing.Add('webui_send_raw_client');
      if not(assigned(webui_set_hide))                             then LMissing.Add('webui_set_hide');
      if not(assigned(webui_set_size))                             then LMissing.Add('webui_set_size');
      if not(assigned(webui_set_minimum_size))                     then LMissing.Add('webui_set_minimum_size');
      if not(assigned(webui_set_position))                         then LMissing.Add('webui_set_position');
      if not(assigned(webui_set_profile))                          then LMissing.Add('webui_set_profile');
      if not(assigned(webui_set_proxy))                            then LMissing.Add('webui_set_proxy');
      if not(assigned(webui_get_url))                              then LMissing.Add('webui_get_url');
      if not(assigned(webui_open_url))                             then LMissing.Add('webui_open_url');
      if not(assigned(webui_set_public))                           then LMissing.Add('webui_set_public');
      if not(assigned(webui_navigate))                             then LMissing.Add('webui_navigate');
      if not(assigned(webui_navigate_client))                      then LMissing.Add('webui_navigate_client');
      if not(assigned(webui_clean))                                then LMissing.Add('webui_clean');
      if not(assigned(webui_delete_all_profiles))                  then LMissing.Add('webui_delete_all_profiles');
      if not(assigned(webui_delete_profile))                       then LMissing.Add('webui_delete_profile');
      if not(assigned(webui_get_parent_process_id))                then LMissing.Add('webui_get_parent_process_id');
      if not(assigned(webui_get_child_process_id))                 then LMissing.Add('webui_get_child_process_id');
      if not(assigned(webui_win32_get_hwnd))                       then LMissing.Add('webui_win32_get_hwnd');
      if not(assigned(webui_get_port))                             then LMissing.Add('webui_get_port');
      if not(assigned(webui_set_port))                             then LMissing.Add('webui_set_port');
      if not(assigned(webui_get_free_port))                        then LMissing.Add('webui_get_free_port');
      if not(assigned(webui_set_config))                           then LMissing.Add('webui_set_config');
      if not(assigned(webui_set_event_blocking))                   then LMissing.Add('webui_set_event_blocking');
      if not(assigned(webui_get_mime_type))                        then LMissing.Add('webui_get_mime_type');
      if not(assigned(webui_set_tls_certificate))                  then LMissing.Add('webui_set_tls_certificate');
      if not(assigned(webui_run))                                  then LMissing.Add('webui_run');
      if not(assigned(webui_run_client))                           then LMissing.Add('webui_run_client');
      if not(assigned(webui_script))                               then LMissing.Add('webui_script');
      if not(assigned(webui_script_client))                        then LMissing.Add('webui_script_client');
      if not(assigned(webui_set_runtime))                          then LMissing.Add('webui_set_runtime');
      if not(assigned(webui_get_count))                            then LMissing.Add('webui_get_count');
      if not(assigned(webui_get_int_at))                           then LMissing.Add('webui_get_int_at');
      if not(assigned(webui_get_int))                              then LMissing.Add('webui_get_int');
      if not(assigned(webui_get_float_at))                         then LMissing.Add('webui_get_float_at');
      if not(assigned(webui_get_float))                            then LMissing.Add('webui_get_float');
      if not(assigned(webui_get_string_at))                        then LMissing.Add('webui_get_string_at');
      if not(assigned(webui_get_string))                           then LMissing.Add('webui_get_string');
      if not(assigned(webui_get_bool_at))                          then LMissing.Add('webui_get_bool_at');
      if not(assigned(webui_get_bool))                             then LMissing.Add('webui_get_bool');
      if not(assigned(webui_get_size_at))                          then LMissing.Add('webui_get_size_at');
      if not(assigned(webui_get_size))                             then LMissing.Add('webui_get_size');
      if not(assigned(webui_return_int))                           then LMissing.Add('webui_return_int');
      if not(assigned(webui_return_float))                         then LMissing.Add('webui_return_float');
      if not(assigned(webui_return_string))                        then LMissing.Add('webui_return_string');
      if not(assigned(webui_return_bool))                          then LMissing.Add('webui_return_bool');
      if not(assigned(webui_interface_bind))                       then LMissing.Add('webui_interface_bind');
      if not(assigned(webui_interface_set_response))               then LMissing.Add('webui_interface_set_response');
      if not(assigned(webui_interface_is_app_running))             then LMissing.Add('webui_interface_is_app_running');
      if not(assigned(webui_interface_get_window_id))              then LMissing.Add('webui_interface_get_window_id');
      if not(assigned(webui_interface_get_string_at))              then LMissing.Add('webui_interface_get_string_at');
      if not(assigned(webui_interface_get_int_at))                 then LMissing.Add('webui_interface_get_int_at');
      if not(assigned(webui_interface_get_float_at))               then LMissing.Add('webui_interface_get_float_at');
      if not(assigned(webui_interface_get_bool_at))                then LMissing.Add('webui_interface_get_bool_at');
      if not(assigned(webui_interface_get_size_at))                then LMissing.Add('webui_interface_get_size_at');
      if not(assigned(webui_interface_show_client))                then LMissing.Add('webui_interface_show_client');
      if not(assigned(webui_interface_close_client))               then LMissing.Add('webui_interface_close_client');
      if not(assigned(webui_interface_send_raw_client))            then LMissing.Add('webui_interface_send_raw_client');
      if not(assigned(webui_interface_navigate_client))            then LMissing.Add('webui_interface_navigate_client');
      if not(assigned(webui_interface_run_client))                 then LMissing.Add('webui_interface_run_client');
      if not(assigned(webui_interface_script_client))              then LMissing.Add('webui_interface_script_client');

      if (LMissing.Count = 0) then
        begin
          Result := True;
          Status := lsInitialized;
        end
       else
        begin
          Status := lsError;
          AppendErrorLog('There was a problem loading the library procedures.');
          AppendErrorLog({$IFDEF FPC}string({$ENDIF}inttostr(LMissing.Count){$IFDEF FPC}){$ENDIF} + ' missing procedures: ');
          AppendErrorLog(LMissing);

          ShowErrorMessageDlg(ErrorMessage);
        end;
    except
      on e : exception do
        if CustomExceptionHandler('TWebUI.LoadLibProcedures', e) then raise;
    end;
  finally
    if assigned(LMissing) then
      FreeAndNil(LMissing);
  end;
end;

procedure TWebUI.AppendErrorLog(const aText : string);
begin
  OutputDebugMessage(aText);
  if Lock then
    try
      if assigned(FErrorLog) then
        FErrorLog.Add({$IFDEF FPC}UTF8Encode({$ENDIF}aText{$IFDEF FPC}){$ENDIF});
    finally
      UnLock;
    end;
end;

procedure TWebUI.AppendErrorLog(const aTextLines : TStringList);
var
  i: integer;
begin
  if assigned(aTextLines) and
     (aTextLines.Count > 0) and
     Lock then
    try
      if assigned(FErrorLog) then
        FErrorLog.AddStrings(aTextLines);

      for i := 0 to pred(aTextLines.Count) do
        OutputDebugMessage({$IFDEF FPC}string({$ENDIF}aTextLines[i]{$IFDEF FPC}){$ENDIF});
    finally
      UnLock;
    end;
end;

{$IFNDEF FPC}
{$IFDEF MACOSX}
procedure ShowMessageCF(const aHeading, aMessage : string; const aTimeoutInSecs : double = 0);
var
  TempHeading, TempMessage : CFStringRef;
  TempResponse : CFOptionFlags;
begin
  TempHeading := CFStringCreateWithCharactersNoCopy(nil, PChar(aHeading), Length(AHeading), kCFAllocatorNull);
  TempMessage := CFStringCreateWithCharactersNoCopy(nil, PChar(aMessage), Length(AMessage), kCFAllocatorNull);

  try
    CFUserNotificationDisplayAlert(aTimeoutInSecs, kCFUserNotificationNoteAlertLevel, nil, nil, nil, TempHeading, TempMessage, nil, nil, nil, TempResponse);
  finally
    CFRelease(TempHeading);
    CFRelease(TempMessage);
  end;
end;
{$ENDIF}
{$ENDIF}

procedure TWebUI.ShowErrorMessageDlg(const aError : string);
{$IFDEF LINUXFPC}
const
  MB_OK        = $00000000;
  MB_ICONERROR = $00000010;
{$ENDIF}
begin
  OutputDebugMessage(aError);

  if FShowMessageDlg then
    begin
      {$IFDEF CONSOLE}
        writeln(aError);
      {$ELSE}
        {$IFDEF MSWINDOWS}
          {$IFDEF FPC}
          MessageBoxW(0, PWideChar(aError + #0), PWideChar('Error' + #0), MB_ICONERROR or MB_OK or MB_TOPMOST);
          {$ELSE}
          MessageBox(0, PChar(aError + #0), PChar('Error' + #0), MB_ICONERROR or MB_OK or MB_TOPMOST);
          {$ENDIF}
        {$ENDIF}

        {$IFDEF LINUX}
          {$IFDEF FPC}
          if (WidgetSet <> nil) then
            Application.MessageBox(PAnsiChar(UTF8Encode(aError + #0)), PAnsiChar(AnsiString('Error' + #0)), MB_ICONERROR or MB_OK);
          {$ELSE}
          // TO-DO: Find a way to show message boxes in FMXLinux
          {$ENDIF}
        {$ENDIF}

        {$IFDEF MACOSX}
          {$IFDEF FPC}
          // TO-DO: Find a way to show message boxes in Lazarus/FPC for MacOS
          {$ELSE}
          ShowMessageCF('Error', aError, 10);
          {$ENDIF}
        {$ENDIF}
      {$ENDIF}
    end;
end;

function TWebUI.GetErrorMessage : string;
begin
  Result := '';

  if Lock then
    try
      if assigned(FErrorLog) then
        Result := {$IFDEF FPC}UTF8Decode({$ENDIF}FErrorLog.Text{$IFDEF FPC}){$ENDIF};
    finally
      UnLock;
    end;
end;

function TWebUI.GetInitialized : boolean;
begin
  Result := False;

  if Lock then
    try
      Result := (FStatus = lsInitialized);
    finally
      UnLock;
    end;
end;

function TWebUI.GetInitializationError : boolean;
begin
  Result := False;

  if Lock then
    try
      Result := (FStatus = lsError);
    finally
      UnLock;
    end;
end;

function TWebUI.GetIsAppRunning : boolean;
begin
  Result := Initialized and
            webui_interface_is_app_running();
end;

function TWebUI.GetStatus : TLoaderStatus;
begin
  Result := lsCreated;
  if Lock then
    try
      Result := FStatus;
    finally
      UnLock;
    end;
end;

function TWebUI.GetLibraryVersion : string;
begin
  Result := {$IFDEF FPC}string({$ENDIF}inttostr(WEBUI_VERSION_MAJOR){$IFDEF FPC}){$ENDIF} + '.' +
            {$IFDEF FPC}string({$ENDIF}inttostr(WEBUI_VERSION_MINOR){$IFDEF FPC}){$ENDIF} + '.' +
            {$IFDEF FPC}string({$ENDIF}inttostr(WEBUI_VERSION_RELEASE){$IFDEF FPC}){$ENDIF};

  if WEBUI_VERSION_STAGE <> '' then
    Result := Result + '-' + WEBUI_VERSION_STAGE;
end;

function TWebUI.GetFreePort: NativeUInt;
begin
  if Initialized then
    Result := webui_get_free_port()
   else
    Result := 0;
end;

function TWebUI.DefaultLibraryPath : string;
begin
  {$IFDEF MACOSX}
  Result := IncludeTrailingPathDelimiter(GetModulePath) + WEBUI_FRAMEWORK + WEBUI_LIB;
  {$ELSE}
  Result := IncludeTrailingPathDelimiter(GetModulePath) + WEBUI_LIB;
  {$ENDIF}
end;

function TWebUI.GetIsHighContrast : boolean;
begin
  Result := Initialized and
            webui_is_high_contrast();
end;

procedure TWebUI.SetTimeout(aValue: NativeUInt);
begin
  FTimeout := aValue;

  if Initialized then
    webui_set_timeout(FTimeout);
end;

procedure TWebUI.SetStatus(aValue: TLoaderStatus);
begin
  if Lock then
    try
      FStatus := aValue;
    finally
      UnLock;
    end;
end;

procedure TWebUI.Wait;
begin
  if Initialized then
    webui_wait();
end;

procedure TWebUI.Clean;
begin
  if Initialized then
    webui_clean();
end;

procedure TWebUI.Exit;
begin
  if Initialized then
    webui_exit();
end;

procedure TWebUI.DeleteAllProfiles;
begin
  if Initialized then
    webui_delete_all_profiles();
end;

function TWebUI.SetDefaultRootFolder(const path : string) : boolean;
var
  LPath: AnsiString;
begin
  Result := False;

  if Initialized and (length(path) > 0) then
    begin
      LPath  := UTF8Encode(path + #0);
      Result := webui_set_default_root_folder(@LPath[1]);
    end;
end;

function TWebUI.SetTLSCertificate(const certificate_pem, private_key_pem : string): boolean;
var
  LCertificate, LPrivateKey : AnsiString;
begin
  Result := False;

  if Initialized and (length(certificate_pem) > 0) and (length(private_key_pem) > 0) then
    begin
      LCertificate  := UTF8Encode(certificate_pem + #0);
      LPrivateKey   := UTF8Encode(private_key_pem + #0);
      Result        := webui_set_tls_certificate(@LCertificate[1], @LPrivateKey[1]);
    end;
end;

function TWebUI.SearchWindowIndex(windowId: TWebUIWindowID) : integer;
var
  i, j: integer;
begin
  Result := -1;

  if assigned(FWindowList) then
    begin
      i := 0;
      j := FWindowList.Count;

      while (i < j) do
        begin
          if assigned(FWindowList[i]) and
             (IWebUIWindow(FWindowList[i]).ID = windowId) then
            begin
              Result := i;
              break;
            end;

          inc(i);
        end;
    end;
end;

function TWebUI.SearchWindow(windowId: TWebUIWindowID) : IWebUIWindow;
var
  i: integer;
begin
  Result := nil;

  if Lock then
    try
      i := SearchWindowIndex(windowId);
      if (i >= 0) then
        Result := IWebUIWindow(FWindowList[i]);
    finally
      Unlock;
    end;
end;

function TWebUI.AddWindow(const window: IWebUIWindow): int64;
begin
  Result := -1;

  if Lock then
    try
      if assigned(FWindowList) and (SearchWindowIndex(window.ID) < 0) then
        Result := FWindowList.Add(Pointer(window));
    finally
      Unlock;
    end;
end;

procedure TWebUI.RemoveWindow(windowId: TWebUIWindowID);
var
  i : int64;
begin
  if Lock then
    try
      i := SearchWindowIndex(windowId);
      if (i >= 0) then
        begin
          FWindowList[i] := nil;
          FWindowList.Delete(i);
        end;
    finally
      Unlock;
    end;
end;

procedure TWebUI.SetConfig(option: TWebUIConfig; status: boolean);
begin
  if Initialized then
    webui_set_config(option, status);
end;

function TWebUI.BrowserExist(browser: TWebUIBrowser): boolean;
begin
  Result := Initialized and
            webui_browser_exist(browser);
end;

function TWebUI.GetMimeType(const file_: string): string;
var
  LFile : AnsiString;
begin
  Result := 'text/plain';

  if Initialized and (length(file_) > 0) then
    begin
      LFile  := UTF8Encode(file_ + #0);
      Result := {$IFDEF DELPHI12_UP}UTF8ToString{$ELSE}UTF8Decode{$ENDIF}(PAnsiChar(webui_get_mime_type(@LFile[1])));
    end;
end;

procedure TWebUI.OpenURL(const url: string);
var
  LUrl    : AnsiString;
  LUrlPtr : PWebUIChar;
begin
  if Initialized then
    begin
      if (length(Url) > 0) then
        begin
          LUrl    := UTF8Encode(Url + #0);
          LUrlPtr := @LUrl[1];
        end
       else
        LUrlPtr := nil;

      webui_open_url(LUrlPtr);
    end;
end;

initialization

finalization
  DestroyWebUI;

end.
