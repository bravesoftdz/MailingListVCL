﻿{ Testowy komentarz: zażółć gęślą jaźń }
unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, ChromeTabs,
  ChromeTabsClasses, ChromeTabsTypes;

type
  TFrameClass = class of TFrame;

  TFormMain = class(TForm)
    tmrFirstShow: TTimer;
    grboxCommands: TGroupBox;
    ChromeTabs1: TChromeTabs;
    pnMain: TPanel;
    FlowPanel1: TFlowPanel;
    btnCreateDatabaseStructures: TButton;
    btnManageContacts: TButton;
    btnImportContacts: TButton;
    btnListManager: TButton;
    ScrollBox1: TScrollBox;
    btnImportUnregistered: TButton;
    Button5: TButton;
    grboxAutoOpen: TGroupBox;
    rbtnDialogCreateDB: TRadioButton;
    rbtnFrameImportContacts: TRadioButton;
    rbtFrameManageContacts: TRadioButton;
    rbtnWelcome: TRadioButton;
    grboxConfiguration: TGroupBox;
    edtAppVersion: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edtDBVersion: TEdit;
    procedure btnCreateDatabaseStructuresClick(Sender: TObject);
    procedure btnImportContactsClick(Sender: TObject);
    procedure btnManageContactsClick(Sender: TObject);
    procedure ChromeTabs1ButtonCloseTabClick(Sender: TObject; ATab: TChromeTab;
      var Close: Boolean);
    procedure ChromeTabs1Change(Sender: TObject; ATab: TChromeTab;
      TabChangeType: TTabChangeType);
    procedure FlowPanel1Resize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmrFirstShowTimer(Sender: TObject);
  private
    isDeveloperMode: Boolean;
    isDatabaseOK: Boolean;
    procedure HideAllChildFrames(AParenControl: TWinControl);
    function OpenFrameAsChromeTab(Frame: TFrameClass): TChromeTab;
    procedure eventOnFormFirstShow;
    procedure verifyDatabaseVersion(expectedVersionNr: Integer);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  FireDAC.Stan.Error, Dialog.RunSQLScript, Frame.ImportContacts,
  Frame.ManageContacts, Frame.Welcome, Module.Main, System.StrUtils;

const
  SQL_SELECT_DatabaseVersion = 'SELECT versionnr FROM DBInfo';

resourcestring
  SWelcomeScreen = 'Ekran powitalny';
  SDBServerGone = 'Nie można nawiazać połączenia z serwerem bazy danych.';
  SDBConnectionUserPwdInvalid = 'Błędna konfiguracja połączenia z bazą danych.'
    + ' Dane użytkownika aplikacyjnego są nie poprawne.';
  SDBConnectionError = 'Nie można nawiazać połączenia z bazą danych';
  SDBRequireCreate = 'Baza danych jest pusta.' +
    ' Proszę najpierw uruchomić skrypt budujący strukturę.';
  SDBErrorSelect = 'Nie można wykonać polecenia SELECT w bazie danych.';

procedure TFormMain.btnCreateDatabaseStructuresClick(Sender: TObject);
begin
  FormDBScript.Show;
end;

procedure TFormMain.HideAllChildFrames(AParenControl: TWinControl);
var
  i: Integer;
begin
  for i := AParenControl.ControlCount - 1 downto 0 do
    if AParenControl.Controls[i] is TFrame then
      (AParenControl.Controls[i] as TFrame).Visible := False;
end;

function TFormMain.OpenFrameAsChromeTab(Frame: TFrameClass): TChromeTab;
var
  frm: TFrame;
begin
  Result := nil;
  { TODO: Dodać kontrolę otwierania tej samej zakładki po raz drugi }
  // Błąd zgłoszony. github #2
  { DONE: Powtórka: COPY-PASTE }
  { DONE : Wydziel metodę OpenFrameAsChromeTab (TFrame) }

  HideAllChildFrames(pnMain);

  frm := Frame.Create(pnMain);
  frm.Parent := pnMain;
  frm.Visible := True;
  frm.Align := alClient;

  Result := ChromeTabs1.Tabs.Add;
  Result.Data := frm;
end;

procedure TFormMain.eventOnFormFirstShow;
var
  tab: TChromeTab;
  expectedDatabaseNumber: Integer;
  expectedVersionNr: Integer;
begin
  { TODO: Przebudować logikę metody. Jest zbyt skomplikowana i mało czytelna }
  tab := OpenFrameAsChromeTab(TFrameWelcome);
  tab.Caption := SWelcomeScreen;
  self.Caption := self.Caption + ' - ' + edtAppVersion.Text;
  expectedDatabaseNumber := StrToInt(edtDBVersion.Text);
  verifyDatabaseVersion(expectedDatabaseNumber);
  if isDeveloperMode then
  begin
    if rbtnDialogCreateDB.Checked then
      btnCreateDatabaseStructures.Click;
    if rbtnFrameImportContacts.Checked then
      btnImportContacts.Click;
    if rbtFrameManageContacts.Checked then
      btnManageContacts.Click;
  end;
end;

procedure TFormMain.verifyDatabaseVersion(expectedVersionNr: Integer);
var
  res: Variant;
  VersionNr: Integer;
  msg1: string;
begin
  isDatabaseOK := False;
  try
    MainDM.FDConnection1.Open;
  except
    on E: EFDDBEngineException do
    begin
      case E.kind of
        ekUserPwdInvalid:
          msg1 := SDBConnectionUserPwdInvalid;
        ekServerGone:
          msg1 := SDBServerGone;
      else
        msg1 := SDBConnectionError
      end;
      { TODO: Zamieć [ShowMessage] na informacje na ekranie powitalnym }
      ShowMessage(msg1);
      exit;
    end;
  end;
  try
    res := MainDM.FDConnection1.ExecSQLScalar(SQL_SELECT_DatabaseVersion);
  except
    on E: EFDDBEngineException do
    begin
      msg1 := IfThen(E.kind = ekObjNotExists, SDBRequireCreate, SDBErrorSelect);
      { TODO: Zamieć [ShowMessage] na informacje na ekranie powitalnym }
      ShowMessage(msg1);
      exit;
    end;
  end;
  VersionNr := res;
  if VersionNr = expectedVersionNr then
    isDatabaseOK := True
  else begin
    { TODO: Wyłącz jako stała resourcestring }
    { TODO: Zamieć ShowMessage na informacje na ekranie powitalnym }
    msg1 := 'Błędna wersja bazy danych. Proszę zaktualizować strukturę ' +
      'bazy. Oczekiwana wersja bazy: %d, aktualna wersja bazy: %d';
    ShowMessage(Format(msg1, [expectedVersionNr, VersionNr]));
  end;
end;

procedure TFormMain.btnImportContactsClick(Sender: TObject);
var
  frm: TChromeTab;
begin
  { DONE: Powtórka: COPY-PASTE }
  frm := OpenFrameAsChromeTab(TFrameImport);
  frm.Caption := (Sender as TButton).Caption;
end;

procedure TFormMain.btnManageContactsClick(Sender: TObject);
var
  frm: TChromeTab;
begin
  { DONE: Powtórka: COPY-PASTE }
  frm := OpenFrameAsChromeTab(TFrameManageContacts);
  frm.Caption := (Sender as TButton).Caption;
end;

procedure TFormMain.ChromeTabs1ButtonCloseTabClick(Sender: TObject;
  ATab: TChromeTab; var Close: Boolean);
var
  obj: TObject;
begin
  obj := TObject(ATab.Data);
  (obj as TFrame).Free;
end;

procedure TFormMain.ChromeTabs1Change(Sender: TObject; ATab: TChromeTab;
  TabChangeType: TTabChangeType);
var
  obj: TObject;
begin
  if Assigned(ATab) then
  begin
    obj := TObject(ATab.Data);
    if (TabChangeType = tcActivated) and Assigned(obj) then
    begin
      HideAllChildFrames(pnMain);
      (obj as TFrame).Visible := True;
    end;
  end;
end;

procedure TFormMain.FlowPanel1Resize(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to FlowPanel1.ControlCount - 1 do
  begin
    if FlowPanel1.Controls[i].Top + FlowPanel1.Controls[i].Height + 6 >
      FlowPanel1.ClientHeight then
      FlowPanel1.ClientHeight := FlowPanel1.Controls[i].Top +
        FlowPanel1.Controls[i].Height + 6;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  sProjFileName: string;
  ext: string;
begin
  FlowPanel1.Caption := '';
  pnMain.Caption := '';
  { TODO: Powtórka: COPY-PASTE }
  { TODO: Poprawić rozpoznawanie projektu: dpr w bieżącym folderze }
{$IFDEF DEBUG}
  ext := '.dpr'; // do not localize
  sProjFileName := ChangeFileExt(ExtractFileName(Application.ExeName), ext);
  isDeveloperMode := FileExists('..\..\' + sProjFileName);
{$ELSE}
  isDeveloperMode := False;
{$ENDIF}
end;

procedure TFormMain.tmrFirstShowTimer(Sender: TObject);
begin
  tmrFirstShow.Enabled := False;
  eventOnFormFirstShow;
end;

end.
