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
//        Copyright � 2018 Salvador Diaz Fau. All rights reserved.
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

unit uSimpleServer;

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Samples.Spin, Vcl.ExtCtrls, System.Math,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, Spin, ExtCtrls, Math,
  {$ENDIF}
  uCEFInterfaces, uCEFServerComponent, uCEFTypes, uCEFMiscFunctions;

type
  TSimpleServerFrm = class(TForm)
    CEFServerComponent1: TCEFServerComponent;
    ButtonPnl: TPanel;
    ConnectionLogMem: TMemo;
    AddressLbl: TLabel;
    AddressEdt: TEdit;
    PortLbl: TLabel;
    PortEdt: TSpinEdit;
    BacklogLbl: TLabel;
    BacklogEdt: TSpinEdit;
    StartBtn: TButton;
    StopBtn: TButton;
    procedure StartBtnClick(Sender: TObject);
    procedure AddressEdtChange(Sender: TObject);
    procedure CEFServerComponent1ServerCreated(Sender: TObject;
      const server: ICefServer);
    procedure CEFServerComponent1ServerDestroyed(Sender: TObject;
      const server: ICefServer);
    procedure CEFServerComponent1ClientConnected(Sender: TObject;
      const server: ICefServer; connection_id: Integer);
    procedure CEFServerComponent1ClientDisconnected(Sender: TObject;
      const server: ICefServer; connection_id: Integer);
    procedure StopBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure CEFServerComponent1HttpRequest(Sender: TObject;
      const server: ICefServer; connection_id: Integer;
      const client_address: ustring; const request: ICefRequest);
  protected
    FClosing : boolean;

    function  BufferToString(const aBuffer : TBytes) : string;
    procedure ShowRequestInfo(const aRequest : ICefRequest);
    procedure ShowPostDataInfo(const aPostData : ICefPostData);
  public
    { Public declarations }
  end;

var
  SimpleServerFrm: TSimpleServerFrm;

implementation

{$R *.dfm}

// Server capacity is limited and is intended to handle only a small number of
// simultaneous connections (e.g. for communicating between applications on localhost).

// To test it follow these steps :
// 1- Build and run this demo.
// 2- Click on the Start button.
// 3- Open your web browser and visit this address http://127.0.0.1:8099
// 4- You should see some connection details in the server log and a "Hellow world" text in your web browser.

procedure TSimpleServerFrm.AddressEdtChange(Sender: TObject);
begin
  if not(CEFServerComponent1.IsRunning) then
    StartBtn.Enabled := (length(trim(AddressEdt.Text)) > 0);
end;

procedure TSimpleServerFrm.StartBtnClick(Sender: TObject);
begin
  if (length(trim(AddressEdt.Text)) > 0) then
    CEFServerComponent1.CreateServer(AddressEdt.Text, PortEdt.Value, BacklogEdt.Value);
end;

procedure TSimpleServerFrm.StopBtnClick(Sender: TObject);
begin
  CEFServerComponent1.Shutdown;
end;

procedure TSimpleServerFrm.CEFServerComponent1ClientConnected(
  Sender: TObject; const server: ICefServer; connection_id: Integer);
begin
  ConnectionLogMem.Lines.Add('Client connected : ' + inttostr(connection_id));
end;

procedure TSimpleServerFrm.CEFServerComponent1ClientDisconnected(
  Sender: TObject; const server: ICefServer; connection_id: Integer);
begin
  ConnectionLogMem.Lines.Add('Client disconnected : ' + inttostr(connection_id));
end;

procedure TSimpleServerFrm.CEFServerComponent1HttpRequest(Sender: TObject;
  const server: ICefServer; connection_id: Integer;
  const client_address: ustring; const request: ICefRequest);
var
  TempData : string;
  TempParts : TUrlParts;
begin
  ConnectionLogMem.Lines.Add('---------------------------------------');
  ConnectionLogMem.Lines.Add('HTTP request received from connection ' + inttostr(connection_id));
  ConnectionLogMem.Lines.Add('Client address : ' + client_address);
  ShowRequestInfo(request);
  ConnectionLogMem.Lines.Add('---------------------------------------');

  if (request <> nil) and CefParseUrl(Request.URL, TempParts) then
    begin
      if (TempParts.path = '') or (TempParts.path = '/') then
        begin
          TempData := 'Hello world from Simple Server';
          CEFServerComponent1.SendHttp200response(connection_id, 'text/html', @TempData[1], length(TempData) * SizeOf(char));
        end
       else
        CEFServerComponent1.SendHttp404response(connection_id);
    end
   else
    CEFServerComponent1.SendHttp404response(connection_id);
end;

procedure TSimpleServerFrm.ShowRequestInfo(const aRequest : ICefRequest);
begin
  if (aRequest = nil) then exit;

  ConnectionLogMem.Lines.Add('Request URL : ' + aRequest.URL);
  ConnectionLogMem.Lines.Add('Request Method : ' + aRequest.Method);

  if (length(aRequest.ReferrerUrl) > 0) then
    ConnectionLogMem.Lines.Add('Request Referrer : ' + aRequest.ReferrerUrl);

  ShowPostDataInfo(aRequest.PostData);
end;

procedure TSimpleServerFrm.ShowPostDataInfo(const aPostData : ICefPostData);
var
  i, j : integer;
  TempLen : NativeUInt;
  TempList : IInterfaceList;
  TempElement : ICefPostDataElement;
  TempBytes : TBytes;
begin
  if (aPostData = nil) then exit;

  i := 0;
  j := aPostData.GetCount;

  TempList := aPostData.GetElements(j);

  while (i < j) do
    begin
      TempElement := TempList.Items[i] as ICefPostDataElement;

      if (TempElement.GetBytesCount > 0) then
        begin
          SetLength(TempBytes, TempElement.GetBytesCount);
          TempLen := TempElement.GetBytes(TempElement.GetBytesCount, @TempBytes[0]);

          if (TempLen > 0) then
            begin
              ConnectionLogMem.Lines.Add('Post contents length : ' + inttostr(TempLen));
              ConnectionLogMem.Lines.Add('Post contents sample : ' + BufferToString(TempBytes));
            end;
        end;

      inc(i);
    end;
end;

function TSimpleServerFrm.BufferToString(const aBuffer : TBytes) : string;
var
  i, j : integer;
begin
  Result := '';

  i := 0;
  j := min(length(aBuffer), 5);

  while (i < j) do
    begin
      Result := Result + IntToHex(aBuffer[i], 2);
      inc(i);
    end;
end;

procedure TSimpleServerFrm.CEFServerComponent1ServerCreated(Sender: TObject; const server: ICefServer);
begin
  if CEFServerComponent1.Initialized then
    begin
      ConnectionLogMem.Lines.Add('Server created');
      StartBtn.Enabled := False;
      StopBtn.Enabled  := True;
    end
   else
    ConnectionLogMem.Lines.Add('Server creation error!');
end;

procedure TSimpleServerFrm.CEFServerComponent1ServerDestroyed(Sender: TObject; const server: ICefServer);
begin
  if FClosing then
    PostMessage(Handle, WM_CLOSE, 0, 0)
   else
    begin
      ConnectionLogMem.Lines.Add('Server destroyed');
      StartBtn.Enabled := True;
      StopBtn.Enabled  := False;
    end;
end;

procedure TSimpleServerFrm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CEFServerComponent1.Initialized then
    begin
      CanClose := False;
      FClosing := True;
      Visible  := False;
      CEFServerComponent1.Shutdown;
    end
   else
    CanClose := True;
end;

procedure TSimpleServerFrm.FormCreate(Sender: TObject);
begin
  FClosing := False;
end;

end.
