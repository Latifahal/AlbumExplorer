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
    procedure imgAlbumCoverClick(Sender: TObject);
    procedure miEditAlbumClick(Sender: TObject);
    procedure miViewTracksClick(Sender: TObject);
    procedure btnAddNewAlbumClick(Sender: TObject);


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



procedure TpmAlbum.FormCreate(Sender: TObject);
begin
  dmMain.cDatenbank.Connected := True;

  dmMain.sqAlbum.OnDataChange := @AlbumDataChange;

  dmMain.qAlbum.ParamByName('UID').AsInteger := dmMain.CurrentUserID;
  dmMain.qAlbum.ParamByName('SEARCH').AsString := '%%';
  dmMain.qAlbum.Open;

  FAlbumModel := TAlbumModel.Create(dmMain.qAlbum, dmMain.qAlbumInsert);
end;


procedure TpmAlbum.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FAlbumModel);
end;


function TpmAlbum.CanEditDataset: Boolean;
begin
  Result :=
    Assigned(FAlbumModel) and
    Assigned(dmMain.qAlbum) and
    dmMain.qAlbum.Active and
    not dmMain.qAlbum.IsEmpty;
end;


procedure TpmAlbum.AlbumDataChange(Sender: TObject; Field: TField);
begin
  DisplayCurrentRecord;
end;


procedure TpmAlbum.DisplayCurrentRecord;
var
  BlobField: TBlobField;
  MemStream: TMemoryStream;
begin
  imgAlbumCover.Picture.Clear;  // clear previous image

  if not CanEditDataset then Exit;

  BlobField := dmMain.qAlbum.FieldByName('ALBUMCOVER') as TBlobField;

  if Assigned(BlobField) and (not BlobField.IsNull) and (BlobField.BlobSize > 0) then
  begin
    MemStream := TMemoryStream.Create;
    try
      BlobField.SaveToStream(MemStream);  // copy blob to memory
      MemStream.Position := 0;             // must reset to start

      try
        imgAlbumCover.Picture.LoadFromStream(MemStream); // safe load
      except
        on E: Exception do
        begin
          imgAlbumCover.Picture.Clear;                 // prevent crash
          ShowMessage('Failed to load album cover: ' + E.Message);
        end;
      end;

    finally
      MemStream.Free;
    end;
  end;
end;




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

  DisplayCurrentRecord;
end;

procedure TpmAlbum.btnClearSearchClick(Sender: TObject);
begin
  edtAlbumSearch.Text := ''; // triggers OnChange
end;



procedure TpmAlbum.imgAlbumCoverClick(Sender: TObject);
begin
  if CanEditDataset then
  begin
    if Assigned(dlgAlbumCover) and dlgAlbumCover.Execute then
    begin
      FAlbumModel.SaveCoverFromFile(dlgAlbumCover); // save to DB
      DisplayCurrentRecord;                        // reload safely
    end;
  end;
end;



procedure TpmAlbum.btnAddNewAlbumClick(Sender: TObject);
begin
  if Assigned(FAlbumModel) then
    FAlbumModel.AddNewAlbum(dmMain.CurrentUserID);
end;


procedure TpmAlbum.miEditAlbumClick(Sender: TObject);
begin
  if CanEditDataset and dmMain.qAlbum.CanModify then
    dmMain.qAlbum.Edit;
end;


procedure TpmAlbum.miViewTracksClick(Sender: TObject);
var
  AlbumID: Integer;
begin
  if not CanEditDataset then Exit;

  AlbumID := dmMain.qAlbum.FieldByName('ID').AsInteger;

  if not Assigned(Tracks) then
    Tracks := TTracks.Create(Application);

  Tracks.LoadSongsFromAlbum(AlbumID);
  Tracks.Show;
end;

end.

