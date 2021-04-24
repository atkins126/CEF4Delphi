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

implementation

uses
  {$IFDEF CEFSUBPROCESS}
  uCEFApplicationCore;
  {$ELSE}
  uCEFApplication;
  {$ENDIF}

procedure CreateGlobalCEFApp;
begin
  // In case you prefer to call CreateGlobalCEFApp and DestroyGlobalCEFApp manually
  // you have to remember that GlobalCEFApp can only be initialized *ONCE* per process.
  // This is a CEF requirement and there's no workaround.
  if (GlobalCEFApp <> nil) then
    exit;

  {$IFDEF CEFSUBPROCESS}
  GlobalCEFApp := TCefApplicationCore.Create;
  {$ELSE}
  GlobalCEFApp := TCefApplication.Create;
  GlobalCEFApp.BrowserSubprocessPath := 'SimpleBrowser_sp.exe';
  {$ENDIF}

  // In case you want to use custom directories for the CEF binaries, cache and user data.
  // If you don't set a cache directory the browser will use in-memory cache.
  // The cache and user data directories must be writable.
{
  GlobalCEFApp.FrameworkDirPath     := 'cef';
  GlobalCEFApp.ResourcesDirPath     := 'cef';
  GlobalCEFApp.LocalesDirPath       := 'cef\locales';
  GlobalCEFApp.cache                := 'cef\cache';
  GlobalCEFApp.UserDataPath         := 'cef\User Data';
}

  // This demo uses a different EXE for the subprocesses.
  // With this configuration it's not necessary to have the
  // GlobalCEFApp.StartMainProcess call in a if..then clause.
  GlobalCEFApp.StartMainProcess;
end;

initialization
  CreateGlobalCEFApp;

finalization
  DestroyGlobalCEFApp;

end.
