// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright © 2018 Salvador Díaz Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uTinyBrowser2;

{$MODE Delphi}

interface

uses
  SysUtils, Classes,
  uCEFInterfaces, uCEFTypes, uCEFChromiumCore;

type
  TTinyBrowser2 = class
    private
      FChromium : TChromiumCore;         

      function GetClient : ICefClient;

      procedure Chromium_OnBeforeClose(Sender: TObject; const browser: ICefBrowser);
      procedure Chromium_OnBeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient; var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);
      procedure Chromium_OnOpenUrlFromTab(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const targetUrl: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; out Result: Boolean);

    public
      constructor Create;
      destructor  Destroy; override;
      procedure   AfterConstruction; override;      

      property Client      : ICefClient read GetClient;
  end;

procedure CreateGlobalCEFApp;
procedure DestroyTinyBrowser;

implementation

// This demo is similar to the cefsimple demo in the official CEF project.

// It doesn't use LCL to create forms from Lazarus code.
// It just uses CEF to create a browser window as if it was a popup browser
// window.

// This browser doesn't use multiple threads to handle the browser and it
// doesn't use an external message pump. For this reason we have to call
// GlobalCEFApp.RunMessageLoop to let CEF handle the message loop and
// GlobalCEFApp.QuitMessageLoop when the browser has been destroyed.

// The destruction steps are much simpler for that reason.
// In this demo it's only necessary to implement the TChromium.OnBeforeClose
// event. The TChromium.OnBeforeClose event calls GlobalCEFApp.QuitMessageLoop
// because the browser has been destroyed and it's necessary to close the
// message loop.

uses
  xlib,
  uCEFApplication, uCEFConstants, uCEFMiscFunctions;

var
  TinyBrowser : TTinyBrowser2 = nil;

function CustomX11ErrorHandler(Display:PDisplay; ErrorEv:PXErrorEvent):longint;cdecl;
begin
  {$IFDEF DEBUG}
  XError := ErrorEv^.error_code;
  WriteLn('Error: ' + IntToStr(XError));
  {$ENDIF}
  Result := 0;
end;

function CustomXIOErrorHandler(Display:PDisplay):longint;cdecl;
begin
  Result := 0;
end;

procedure GlobalCEFApp_OnContextInitialized;
begin
  TinyBrowser := TTinyBrowser2.Create;
end;                  

procedure GlobalCEFApp_OnGetDefaultClient(var aClient : ICefClient);
begin
  aClient := TinyBrowser.Client;
end;

procedure CreateGlobalCEFApp;          
begin
  // Install xlib error handlers so that the application won't be terminated
  // on non-fatal errors. Must be done after initializing GTK.
  XSetErrorHandler(@CustomX11ErrorHandler);
  XSetIOErrorHandler(@CustomXIOErrorHandler);

  GlobalCEFApp                            := TCefApplication.Create;
  GlobalCEFApp.MultiThreadedMessageLoop   := False;
  GlobalCEFApp.ExternalMessagePump        := False;                         
  //GlobalCEFApp.ChromeRuntime              := True; // Enable this line to enable the "ChromeRuntime" mode. It's in experimental state.
  GlobalCEFApp.cache                      := 'cache';
  GlobalCEFApp.DisableZygote              := True;
  GlobalCEFApp.OnContextInitialized       := GlobalCEFApp_OnContextInitialized;     
  GlobalCEFApp.OnGetDefaultClient         := GlobalCEFApp_OnGetDefaultClient;    // This event is only used in "ChromeRuntime" mode

  // Add a debug log in the BIN directory
  //GlobalCEFApp.LogFile     := 'cef.log';
  //GlobalCEFApp.LogSeverity := LOGSEVERITY_VERBOSE;
end;

procedure DestroyTinyBrowser;
begin
  if (TinyBrowser <> nil) then
    FreeAndNil(TinyBrowser);
end;

constructor TTinyBrowser2.Create;
begin
  inherited Create;

  FChromium := nil;
end;

destructor TTinyBrowser2.Destroy;
begin
  if (FChromium <> nil) then
    FreeAndNil(FChromium);

  inherited Destroy;
end;

procedure TTinyBrowser2.AfterConstruction;
var
  TempHandle : TCefWindowHandle;
  TempRect : TRect;
begin
  inherited AfterConstruction;
  
  FChromium                  := TChromiumCore.Create(nil);
  FChromium.DefaultURL       := 'https://www.google.com';
  FChromium.OnBeforeClose    := Chromium_OnBeforeClose;
  FChromium.OnBeforePopup    := Chromium_OnBeforePopup;
  FChromium.OnOpenUrlFromTab := Chromium_OnOpenUrlFromTab;

  InitializeWindowHandle(TempHandle);
  FChromium.CreateBrowser(TempHandle, TempRect, 'Tiny Browser 2', nil, nil, True);
end;             

function TTinyBrowser2.GetClient : ICefClient;
begin
  if (FChromium <> nil) then
    Result := FChromium.CefClient
   else
    Result := nil;
end;

procedure TTinyBrowser2.Chromium_OnBeforeClose(Sender: TObject;
  const browser: ICefBrowser);
begin
  GlobalCEFApp.QuitMessageLoop;
end;

procedure TTinyBrowser2.Chromium_OnBeforePopup(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; const targetUrl,
  targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition;
  userGesture: Boolean; const popupFeatures: TCefPopupFeatures;
  var windowInfo: TCefWindowInfo; var client: ICefClient;
  var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue;
  var noJavascriptAccess: Boolean; var Result: Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [WOD_NEW_FOREGROUND_TAB, WOD_NEW_BACKGROUND_TAB, WOD_NEW_POPUP, WOD_NEW_WINDOW]);
end;

procedure TTinyBrowser2.Chromium_OnOpenUrlFromTab(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const targetUrl: ustring; targetDisposition: TCefWindowOpenDisposition;
  userGesture: Boolean; out Result: Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [WOD_NEW_FOREGROUND_TAB, WOD_NEW_BACKGROUND_TAB, WOD_NEW_POPUP, WOD_NEW_WINDOW]);
end;

end.
