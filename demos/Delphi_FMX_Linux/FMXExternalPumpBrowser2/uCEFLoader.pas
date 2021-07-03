// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2021 Salvador Diaz Fau. All rights reserved.
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

unit uCEFLoader;

interface

uses
  // This unit *MUST NOT* have any reference to FMX units.
  // The reason for this is that Delphi will change the initialization order
  // and then FMX (including GTK) will be initialized before this unit.
  // That's the reason why we use GlobalCEFWorkScheduler even if this is an FMX
  // project.
  // Read the answer to this question for more more information :
  // https://stackoverflow.com/questions/52103407/changing-the-initialization-order-of-the-unit-in-delphi
  System.IOUtils,
  uCEFApplication, uCEFConstants, uCEFTimerWorkScheduler, uCEFLinuxFunctions,
  uCEFLinuxTypes;

implementation

function CustomX11ErrorHandler(Display:PDisplay; ErrorEv:PXErrorEvent):longint;cdecl;
begin
  Result := 0;
end;

function CustomXIOErrorHandler(Display:PDisplay):longint;cdecl;
begin
  Result := 0;
end;

procedure GlobalCEFApp_OnScheduleMessagePumpWork(const aDelayMS : int64);
begin
  if (GlobalCEFTimerWorkScheduler <> nil) then
    GlobalCEFTimerWorkScheduler.ScheduleMessagePumpWork(aDelayMS);
end;

procedure InitializeGlobalCEFApp;
begin
  GlobalCEFApp                            := TCefApplication.Create;
  GlobalCEFApp.WindowlessRenderingEnabled := True;
  GlobalCEFApp.EnableHighDPISupport       := True;
  GlobalCEFApp.ExternalMessagePump        := True;
  GlobalCEFApp.MultiThreadedMessageLoop   := False;
  GlobalCEFApp.DisableZygote              := True;
  GlobalCEFApp.OnScheduleMessagePumpWork  := GlobalCEFApp_OnScheduleMessagePumpWork;

  // Use these settings if you already have the CEF binaries in a directory called "cef" inside your home directory.
  // You can also use the "Deployment" window but debugging might be slower.
  GlobalCEFApp.FrameworkDirPath      := TPath.GetHomePath + TPath.DirectorySeparatorChar + 'cef';
  GlobalCEFApp.ResourcesDirPath      := GlobalCEFApp.FrameworkDirPath;
  GlobalCEFApp.LocalesDirPath        := GlobalCEFApp.FrameworkDirPath + TPath.DirectorySeparatorChar + 'locales';
  GlobalCEFApp.cache                 := GlobalCEFApp.FrameworkDirPath + TPath.DirectorySeparatorChar + 'cache';
  GlobalCEFApp.UserDataPath          := GlobalCEFApp.FrameworkDirPath + TPath.DirectorySeparatorChar + 'User Data';
  GlobalCEFApp.BrowserSubprocessPath := GlobalCEFApp.FrameworkDirPath + TPath.DirectorySeparatorChar + 'FMXExternalPumpBrowser2_sp';

  // TCEFTimerWorkScheduler will call cef_do_message_loop_work when
  // it's told in the GlobalCEFApp.OnScheduleMessagePumpWork event.
  // GlobalCEFTimerWorkScheduler needs to be created before the
  // GlobalCEFApp.StartMainProcess call.
  // We use CreateDelayed in order to have a single thread in the process while
  // CEF is initialized.
  GlobalCEFTimerWorkScheduler := TCEFTimerWorkScheduler.Create;

  {$IFDEF DEBUG}
  GlobalCEFApp.LogFile     := TPath.GetHomePath + TPath.DirectorySeparatorChar + 'debug.log';
  GlobalCEFApp.LogSeverity := LOGSEVERITY_INFO;
  {$ENDIF}

  // This is a workaround to fix a Chromium initialization crash.
  // The current FMX solution to initialize CEF with a loader unit
  // creates a race condition with the media key controller in Chromium.
  GlobalCEFApp.DisableFeatures := 'HardwareMediaKeyHandling';

  GlobalCEFApp.StartMainProcess;

  // Install xlib error handlers so that the application won't be terminated
  // on non-fatal errors. Must be done after initializing GTK.
  XSetErrorHandler(@CustomX11ErrorHandler);
  XSetIOErrorHandler(@CustomXIOErrorHandler);
end;

initialization
  InitializeGlobalCEFApp;

finalization
  if (GlobalCEFTimerWorkScheduler <> nil) then GlobalCEFTimerWorkScheduler.StopScheduler;
  DestroyGlobalCEFApp;
  DestroyGlobalCEFTimerWorkScheduler;

end.
