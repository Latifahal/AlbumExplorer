unit MainFormUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, ExtCtrls,
  StdCtrls, Buttons, Menus, DB, ExtDlgs, Uni, AlbumModel, DateUtils,
  DBCtrls, SongsFormUnit, dDatenbank, LCLType, Math;

type
  { TpmAlbum }
  TpmAlbum = class(TForm)
    btnDeleteAlbum: TButton;
    dbgAlbums: TDBGrid;
    edtAlbumSearch: TEdit;
    imgAlbumCover: TImage;
    lblDescription: TLabel;
    lblSearch: TLabel;
    dlgAlbumCover: TOpenPictureDialog;
    pmAlbum: TPopupMenu;
    miEditAlbum: TMenuItem;
    miViewTracks: TMenuItem;
    btnClearSearch: TSpeedButton;
    dbMemoAlbumDescription: TDBMemo;
    btnAddNewAlbum: TButton;

    procedure btnDeleteAlbumClick(Sender: TObject);
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

{$R *.lfm}

{ ---------------------- FPU RESET (CRITICAL FIX) ---------------------- }
procedure ResetFPU;
begin
  // Disable all floating point exceptions (GTK safe mode)
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
                    exOverflow, exUnderflow, exPrecision]);
end;

function AskConfirmation(const Msg: string = 'Are you sure you want to proceed?'): Boolean;
begin
  Result := QuestionDlg('Confirmation', Msg, mtConfirmation, [mrYes, mrNo], 0) = mrYes;
end;

procedure TpmAlbum.btnDeleteAlbumClick(Sender: TObject);
begin
  if not Assigned(FAlbumModel) then Exit;
  if not dmMain.qAlbum.Active then Exit;
  if dmMain.qAlbum.IsEmpty then Exit;

  if not AskConfirmation('Are you sure you want to delete this album?') then Exit;

  dmMain.qAlbumDelete.ParamByName('ID').AsInteger :=
    dmMain.qAlbum.FieldByName('ID').AsInteger;
  dmMain.qAlbumDelete.Execute;
  dmMain.qAlbum.Refresh;
end;

{ ---------------------- FORM CREATE ---------------------- }
procedure TpmAlbum.FormCreate(Sender: TObject);
begin
  ResetFPU;   // VERY IMPORTANT

  dmMain.cDatenbank.Connected := True;

  dmMain.sqAlbum.OnDataChange := @AlbumDataChange;

  dmMain.qAlbum.ParamByName('UID').AsInteger := dmMain.CurrentUserID;
  dmMain.qAlbum.ParamByName('SEARCH').AsString := '%%';
  dmMain.qAlbum.Open;

  FAlbumModel := TAlbumModel.Create(dmMain.qAlbum, dmMain.qAlbumInsert);

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
  Result := Assigned(FAlbumModel) and Assigned(dmMain.qAlbum) and
            dmMain.qAlbum.Active and not dmMain.qAlbum.IsEmpty;
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
  ResetFPU;   // GTK + image safety

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
  ResetFPU;   // CRITICAL BEFORE GTK IMAGE OPERATIONS

  if not Assigned(dmMain.qAlbum) then Exit;
  if not dmMain.qAlbum.Active then dmMain.qAlbum.Open;
  if dmMain.qAlbum.IsEmpty then Exit;

  BlobField := dmMain.qAlbum.FieldByName('ALBUMCOVER') as TBlobField;
  if not Assigned(BlobField) then Exit;

  try
    if dlgAlbumCover.Execute then
    begin
      if not (dmMain.qAlbum.State in dsEditModes) then
        dmMain.qAlbum.Edit;

      BlobField.LoadFromFile(dlgAlbumCover.FileName);
      dmMain.qAlbum.Post;

      imgAlbumCover.Picture.Clear;

      MemStream := TMemoryStream.Create;
      try
        BlobField.SaveToStream(MemStream);
        MemStream.Position := 0;
        imgAlbumCover.Picture.LoadFromStream(MemStream);
      finally
        MemStream.Free;
      end;
    end;
  except
    on E: Exception do
      Writeln('Exception in imgAlbumCoverClick: ', E.ClassName, ' - ', E.Message);
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

  Tracks := TTracks.Create(Application);
  Tracks.LoadSongsFromAlbum(AlbumID);
  Tracks.Show;
end;

end.

