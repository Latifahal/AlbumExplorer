unit MainFormUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  DBGrids, ExtCtrls, StdCtrls, Buttons, Menus, DB,
  ExtDlgs, Uni, AlbumModel, DateUtils, DBCtrls;

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
    FIgnoreDataChange: Boolean;
    procedure AlbumDataChange(Sender: TObject; Field: TField);
    procedure DisplayCurrentRecord;
    function  CanEditDataset: Boolean;
  end;

var
  pmAlbum: TpmAlbum;

implementation

uses dDatenbank;

{$R *.lfm}

{ ---------------------- FORM CREATE ---------------------- }
procedure TpmAlbum.FormCreate(Sender: TObject);
begin
  WriteLn('FormCreate: start');

  dmMain.cDatenbank.Connected := True;
  WriteLn('FormCreate: database connected');

  // Assign OnDataChange safely
  dmMain.sqAlbum.OnDataChange := @AlbumDataChange;

  dmMain.qAlbum.ParamByName('UID').AsInteger := dmMain.CurrentUserID;
  dmMain.qAlbum.ParamByName('SEARCH').AsString := '%%';
  dmMain.qAlbum.Open;
  WriteLn('FormCreate: qAlbum opened');

  // Create album model
  FAlbumModel := TAlbumModel.Create(dmMain.qAlbum, dmMain.qAlbumInsert);

  // Display current album cover safely
  DisplayCurrentRecord;
end;

{ ---------------------- FORM DESTROY ---------------------- }
procedure TpmAlbum.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FAlbumModel);
end;

{ ---------------------- DATASET CHECK ---------------------- }
function TpmAlbum.CanEditDataset: Boolean;
begin
  Result :=
    Assigned(FAlbumModel) and
    Assigned(dmMain.qAlbum) and
    dmMain.qAlbum.Active and
    not dmMain.qAlbum.IsEmpty;
end;

{ ---------------------- ON DATA CHANGE ---------------------- }
procedure TpmAlbum.AlbumDataChange(Sender: TObject; Field: TField);
begin
  if FIgnoreDataChange then Exit;
  DisplayCurrentRecord;
end;

{ ---------------------- DISPLAY CURRENT RECORD ---------------------- }
procedure TpmAlbum.DisplayCurrentRecord;
var
  BlobStream: TStream;
begin
  imgAlbumCover.Picture.Clear;

  if not CanEditDataset then Exit;

  FIgnoreDataChange := True;
  try
    if FAlbumModel.HasCover then
    begin
      BlobStream := FAlbumModel.CreateCoverStream;
      if Assigned(BlobStream) then
      begin
        try
          BlobStream.Position := 0;
          imgAlbumCover.Picture.LoadFromStream(BlobStream);
        finally
          BlobStream.Free;
        end;
      end;
    end;
  finally
    FIgnoreDataChange := False;
  end;
end;

{ ---------------------- SEARCH CHANGE ---------------------- }
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

{ ---------------------- CLEAR SEARCH ---------------------- }
procedure TpmAlbum.btnClearSearchClick(Sender: TObject);
begin
  edtAlbumSearch.Text := '';
end;

{ ---------------------- IMAGE CLICK ---------------------- }
procedure TpmAlbum.imgAlbumCoverClick(Sender: TObject);
var
  BlobField: TBlobField;
  MemStream: TMemoryStream;
begin
  Writeln('imgAlbumCoverClick: start');

  // Ensure dataset is assigned and open
  if not Assigned(dmMain.qAlbum) then Exit;
  if not dmMain.qAlbum.Active then
  begin
    Writeln('imgAlbumCoverClick: opening dataset');
    dmMain.qAlbum.Open;
  end;

  if dmMain.qAlbum.IsEmpty then
  begin
    Writeln('imgAlbumCoverClick: dataset is empty');
    Exit;
  end;

  // Get the BLOB field safely
  BlobField := dmMain.qAlbum.FieldByName('ALBUMCOVER') as TBlobField;
  if not Assigned(BlobField) then
  begin
    Writeln('imgAlbumCoverClick: ALBUMCOVER field not found');
    Exit;
  end;

  // Open dialog and save BLOB
  if dlgAlbumCover.Execute then
  begin
    // Edit dataset safely
    if not (dmMain.qAlbum.State in dsEditModes) then
      dmMain.qAlbum.Edit;

    try
      BlobField.LoadFromFile(dlgAlbumCover.FileName);
      dmMain.qAlbum.Post;
      Writeln('imgAlbumCoverClick: image saved to DB');
    except
      on E: Exception do
      begin
        dmMain.qAlbum.Cancel;
        ShowMessage('Failed to save image to database: ' + E.Message);
        Exit;
      end;
    end;

    // Reload image to UI safely
    imgAlbumCover.Picture.Clear;
    MemStream := TMemoryStream.Create;
    try
      BlobField.SaveToStream(MemStream);
      MemStream.Position := 0;
      imgAlbumCover.Picture.LoadFromStream(MemStream);
      Writeln('imgAlbumCoverClick: image loaded to UI');
    finally
      MemStream.Free;
      Writeln('imgAlbumCoverClick: memory stream freed');
    end;
  end;
end;



{ ---------------------- ADD NEW ALBUM ---------------------- }
procedure TpmAlbum.btnAddNewAlbumClick(Sender: TObject);
begin
  if Assigned(FAlbumModel) then
    FAlbumModel.AddNewAlbum(dmMain.CurrentUserID);
end;

{ ---------------------- EDIT ALBUM ---------------------- }
procedure TpmAlbum.miEditAlbumClick(Sender: TObject);
begin
  if CanEditDataset and dmMain.qAlbum.CanModify then
    dmMain.qAlbum.Edit;
end;

{ ---------------------- VIEW TRACKS ---------------------- }
procedure TpmAlbum.miViewTracksClick(Sender: TObject);
var
  AlbumID: Integer;
begin
  if not CanEditDataset then Exit;

  AlbumID := dmMain.qAlbum.FieldByName('ID').AsInteger;

  // Ensure Tracks form is properly declared and created
  // Use a singleton pattern or create/destroy manually
  // Tracks := TTracks.Create(Application);
  // Tracks.LoadSongsFromAlbum(AlbumID);
  // Tracks.Show;

  ShowMessage('Tracks form call placeholder: AlbumID=' + IntToStr(AlbumID));
end;

end.

