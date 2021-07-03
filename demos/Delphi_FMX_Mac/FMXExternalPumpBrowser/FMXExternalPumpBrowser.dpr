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
//        Copyright � 2018 Salvador D�az Fau. All rights reserved.
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

program FMXExternalPumpBrowser;

{$I cef.inc}

uses
  {$IFDEF DELPHI17_UP}
  System.StartUpCopy,
  {$ENDIF }
  FMX.Forms,
  uCEFApplication,
  uCEFTimerWorkScheduler,
  uCEFMacOSFunctions,
  uFMXExternalPumpBrowser in 'uFMXExternalPumpBrowser.pas' {FMXExternalPumpBrowserFrm},
  uFMXApplicationService in 'uFMXApplicationService.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  // Copy the CEF framework and the CEF helpers locally instead of deploying
  // them to debug faster.
  // Copy the "Chromium Embedded Framework.framework" directory into the same
  // directory where this project is deployed on the Mac.
  // The 4 "helper" projects in this group should also be deployed in the same
  // directory as this project.
  // CopyCEFHelpers requires that the helper projects end with "_helper",
  // "_helper_gpu", "_helper_plugin" and "_helper_renderer".
  CopyCEFFramework;
  CopyCEFHelpers('FMXExternalPumpBrowser');
  {$ENDIF}

  CreateGlobalCEFApp;

  if GlobalCEFApp.StartMainProcess then
    begin
      Application.Initialize;
      Application.CreateForm(TFMXExternalPumpBrowserFrm, FMXExternalPumpBrowserFrm);
      Application.Run;

      // The form needs to be destroyed *BEFORE* stopping the scheduler.
      FMXExternalPumpBrowserFrm.Free;

      if (GlobalCEFTimerWorkScheduler <> nil) then
        GlobalCEFTimerWorkScheduler.StopScheduler;
    end;

  DestroyGlobalCEFApp;
  DestroyGlobalCEFTimerWorkScheduler;
end.
