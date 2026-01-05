unit MainFormUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  DBGrids, ExtCtrls, StdCtrls, Buttons, Menus, DB,
  dDatenbank, SongsFormUnit, DBCtrls, ExtDlgs,
  AlbumModel, DateUtils;

type
  { TpmAlbum }

  TpmAlbum = class(TForm)
    btnDeleteAlbum:         TButton;
    dbgAlbums:              TDBGrid;
    edtAlbumSearch:         TEdit;
    dlgAlbumCover:          TOpenPictureDialog;
    imgAlbumCover:          TImage;
    lblDescription:         TLabel;
    lblSearch:              TLabel;
    pmAlbum:                TPopupMenu;
    miEditAlbum:            TMenuItem;
    miViewTracks:           TMenuItem;
    btnClearSearch:         TSpeedButton;
    dbMemoAlbumDescription: TDBMemo;
    btnAddNewAlbum:         TButton;


    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edtAlbumSearchChange(Sender: TObject);
    procedure btnClearSearchClick(Sender: TObject);
    procedure dbgAlbumsCellClick(Column: TColumn);
    procedure imgAlbumCoverClick(Sender: TObject);
    procedure miEditAlbumClick(Sender: TObject);
    procedure miViewTracksClick(Sender: TObject);
    procedure btnAddNewAlbumClick(Sender: TObject);
    procedure btnDeleteAlbumClick(Sender: TObject);

  private
    FAlbumModel: TAlbumModel;
    procedure AlbumDataChange(Sender: TObject; Field: TField);
    procedure DisplayCurrentRecord;
    function  CanEditDataset: Boolean;
  end;

var
  pmAlbum: TpmAlbum;

implementation

{$R *.lfm}

{ -------------------- INIT -------------------- }
procedure TpmAlbum.FormCreate(Sender: TObject);
begin
  dmMain.cDatenbank.Connected := True;

  pmAlbum.PopupComponent := dbgAlbums;

  dmMain.qAlbum.Close;
  dmMain.qAlbum.ParamByName('UID').AsInteger := dmMain.CurrentUserID;
  dmMain.qAlbum.ParamByName('SEARCH').AsString := '%%';
  dmMain.qAlbum.Open;

  FreeAndNil(FAlbumModel);
  FAlbumModel := TAlbumModel.Create(dmMain.qAlbum, dmMain.qAlbumInsert);


  if Assigned(dmMain.sqAlbum) then
    dmMain.sqAlbum.OnDataChange := @AlbumDataChange;

  DisplayCurrentRecord;
end;

procedure TpmAlbum.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FAlbumModel);
end;
{ -------------------- DATA -------------------- }
function TpmAlbum.CanEditDataset: Boolean;
begin
  // Allow dataset edits even if empty
  Result := Assigned(FAlbumModel) and FAlbumModel.HasValidDataset;
end;

procedure TpmAlbum.AlbumDataChange(Sender: TObject; Field: TField);
begin
  DisplayCurrentRecord;
end;

procedure TpmAlbum.DisplayCurrentRecord;
var
  BlobStream: TStream;
begin
  imgAlbumCover.Picture := nil;

  if not CanEditDataset then
  begin
    lblDescription.Caption := 'No albums yet';
    Exit;
  end;

  if FAlbumModel.HasCover then
  begin
    BlobStream := FAlbumModel.CreateCoverStream;
    if Assigned(BlobStream) then
    try
      if BlobStream.Size > 0 then
        imgAlbumCover.Picture.LoadFromStream(BlobStream);
    finally
      BlobStream.Free;
    end;
  end;
end;
{ -------------------- SEARCH (SERVER SIDE) -------------------- }
procedure TpmAlbum.edtAlbumSearchChange(Sender: TObject);
var
  S: string;
begin
  S := Trim(edtAlbumSearch.Text);
  btnClearSearch.Visible := S <> '';

  dmMain.qAlbum.Close;
  dmMain.qAlbum.ParamByName('UID').AsInteger := dmMain.CurrentUserID;

  if S = '' then
    dmMain.qAlbum.ParamByName('SEARCH').AsString := '%%'
  else
    dmMain.qAlbum.ParamByName('SEARCH').AsString := '%' + S + '%';

  dmMain.qAlbum.Open;

  FreeAndNil(FAlbumModel);
  FAlbumModel := TAlbumModel.Create(
  dmMain.qAlbum,
  dmMain.qAlbumInsert
);

  DisplayCurrentRecord;
end;

procedure TpmAlbum.btnClearSearchClick(Sender: TObject);
begin
  edtAlbumSearch.Text := ''; // triggers OnChange
end;
{ -------------------- GRID -------------------- }
procedure TpmAlbum.dbgAlbumsCellClick(Column: TColumn);
begin
  DisplayCurrentRecord;
end;
{ -------------------- ALBUM COVER -------------------- }
procedure TpmAlbum.imgAlbumCoverClick(Sender: TObject);
begin
  if CanEditDataset then
   FAlbumModel := TAlbumModel.Create(
  dmMain.qAlbum,
  dmMain.qAlbumInsert
);

end;
{ -------------------- NEW ALBUM -------------------- }
procedure TpmAlbum.btnAddNewAlbumClick(Sender: TObject);
begin
  if Assigned(FAlbumModel) then
    FAlbumModel.AddNewAlbum(dmMain.CurrentUserID);

  // display the new record
  DisplayCurrentRecord;
end;

{ ------------------ DELETE ALBUM ------------------ }
procedure TpmAlbum.btnDeleteAlbumClick(Sender: TObject);
begin
  if not CanEditDataset then
  begin
    ShowMessage('No album selected.');
    Exit;
  end;

  if MessageDlg('Delete Album',
                'Are you sure you want to delete this album?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  try
    dmMain.qAlbum.Delete;
    dmMain.cDatenbank.Commit;

    // Refresh display only, do NOT recreate model incorrectly
    DisplayCurrentRecord;

    ShowMessage('Album deleted successfully.');
  except
    on E: Exception do
      ShowMessage('Failed to delete album: ' + E.Message);
  end;
end;

{ -------------------- POPUP -------------------- }
procedure TpmAlbum.miEditAlbumClick(Sender: TObject);
begin
  if not CanEditDataset then
  begin
    ShowMessage('No album selected.');
    Exit;
  end;

  if not dmMain.qAlbum.CanModify then
  begin
    ShowMessage('Dataset is not editable.');
    Exit;
  end;

  dmMain.qAlbum.Edit;
end;

procedure TpmAlbum.miViewTracksClick(Sender: TObject);
var
  AlbumID: Integer;
begin
  if not CanEditDataset then
  begin
    ShowMessage('No album selected.');
    Exit;
  end;

  AlbumID := dmMain.qAlbum.FieldByName('ID').AsInteger;

  if not Assigned(Tracks) then
    Tracks := TTracks.Create(Application);

  // Ensure that Tracks is fully initialized before calling method
  try
    Tracks.LoadSongsFromAlbum(AlbumID);
    Tracks.Show;
  except
    on E: Exception do
      ShowMessage('Failed to open tracks: ' + E.Message);
  end;
end;
end.

