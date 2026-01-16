unit MainFormUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  DBGrids, ExtCtrls, StdCtrls, Buttons, Menus, DB,
  ExtDlgs, Uni, AlbumModel, DateUtils, DBCtrls, SongsFormUnit, dDatenbank, LCLType;

type
  { TpmAlbum }

  TpmAlbum = class(TForm)
    btnDeleteAlbum:         TButton;
    dbgAlbums:              TDBGrid;
    edtAlbumSearch:         TEdit;
    imgAlbumCover:          TImage;
    lblDescription:         TLabel;
    lblSearch:              TLabel;
    dlgAlbumCover:          TOpenPictureDialog;
    pmAlbum:                TPopupMenu;
    miEditAlbum:            TMenuItem;
    miViewTracks:           TMenuItem;
    btnClearSearch:         TSpeedButton;
    dbMemoAlbumDescription: TDBMemo;
    btnAddNewAlbum:         TButton;

    procedure btnDeleteAlbumClick(Sender: TObject);
    procedure FormCreate            (Sender: TObject);
    procedure FormDestroy           (Sender: TObject);
    procedure edtAlbumSearchChange  (Sender: TObject);
    procedure btnClearSearchClick   (Sender: TObject);
    procedure imgAlbumCoverClick    (Sender: TObject);
    procedure miEditAlbumClick      (Sender: TObject);
    procedure miViewTracksClick     (Sender: TObject);
    procedure btnAddNewAlbumClick   (Sender: TObject);

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


{$R *.lfm}
function AskConfirmation(const Msg: string = 'Are you sure you want to proceed?'): Boolean;
begin
  Result := QuestionDlg('Confirmation', Msg, mtConfirmation, [mrYes, mrNo], 0) = mrYes;
end;

procedure TpmAlbum.btnDeleteAlbumClick(Sender: TObject);
begin
  // Exit early if model or dataset not ready
  if not Assigned(FAlbumModel) then Exit;
  if not dmMain.qAlbum.Active then Exit;
  if dmMain.qAlbum.IsEmpty then Exit;

  // Ask the user for confirmation
  if not AskConfirmation('Are you sure you want to delete this album?') then
    Exit; // User chose No, exit procedure

  // Proceed with deletion
  dmMain.qAlbumDelete.ParamByName('ID').AsInteger :=
    dmMain.qAlbum.FieldByName('ID').AsInteger;

  dmMain.qAlbumDelete.Execute;

  dmMain.qAlbum.Refresh;
end;


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

  Writeln('Before checking qAlbum assignment');
  if not Assigned(dmMain.qAlbum) then Exit;
  Writeln('After checking qAlbum assignment: qAlbum assigned');

  Writeln('Before checking if qAlbum is active');
  if not dmMain.qAlbum.Active then
  begin
    Writeln('qAlbum not active, opening');
    dmMain.qAlbum.Open;
  end
  else
    Writeln('qAlbum already active');

  Writeln('Before checking if qAlbum is empty');
  if dmMain.qAlbum.IsEmpty then Exit;
  Writeln('qAlbum has records');

  Writeln('Before getting ALBUMCOVER field');
  BlobField := dmMain.qAlbum.FieldByName('ALBUMCOVER') as TBlobField;
  if not Assigned(BlobField) then Exit;
  Writeln('ALBUMCOVER field assigned');

  Writeln('Before executing dialog');
  if dlgAlbumCover.Execute then
  begin
    Writeln('Dialog executed successfully');

    Writeln('Before checking dataset edit state');
    if not (dmMain.qAlbum.State in dsEditModes) then
    begin
      Writeln('Dataset not in edit mode, switching to Edit');
      dmMain.qAlbum.Edit;
    end
    else
      Writeln('Dataset already in edit mode');

    Writeln('Before loading file into blob field');
    BlobField.LoadFromFile(dlgAlbumCover.FileName);
    Writeln('File loaded into blob field');

    Writeln('Before posting dataset');
    dmMain.qAlbum.Post;
    Writeln('Dataset posted');

    Writeln('Before clearing image');
    imgAlbumCover.Picture.Clear;
    Writeln('Image cleared');

    Writeln('Before creating memory stream');
    MemStream := TMemoryStream.Create;
    try
      Writeln('Before saving blob to stream');
      BlobField.SaveToStream(MemStream);

      Writeln('Resetting stream position');
      MemStream.Position := 0;

      Writeln('Before loading image from stream');
      imgAlbumCover.Picture.LoadFromStream(MemStream);
      Writeln('Image loaded from stream');
    finally
      Writeln('Freeing memory stream');
      MemStream.Free;
    end;
  end
  else
    Writeln('Dialog execution canceled');

  Writeln('imgAlbumCoverClick: end');
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

   //Ensure Tracks form is properly declared and created
   //Use a singleton pattern or create/destroy manually
   Tracks := TTracks.Create(Application);
   Tracks.LoadSongsFromAlbum(AlbumID);
   Tracks.Show;

  ShowMessage('Tracks form call placeholder: AlbumID=' + IntToStr(AlbumID));
end;

end.

