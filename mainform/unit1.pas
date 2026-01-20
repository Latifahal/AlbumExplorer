unit Unit1;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ExtDlgs, StdCtrls, DB, Uni;

type
  { TForm1 }
  TForm1 = class(TForm)
    btnDeleteImage: TButton;
    imgAlbumCover: TImage;
    dlgAlbumCover: TOpenPictureDialog;
    procedure btnDeleteImageClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgAlbumCoverClick(Sender: TObject);
  private
    sqUnit1: TUniDataSource;
    qUnit1: TUniQuery;
    procedure ClearBlob;
    procedure LoadCurrentCover;
    procedure SaveCoverToDB(const FileName: string);
  end;

var
  Form1: TForm1;

implementation

uses dDatenbank;

{$R *.lfm}

{ ---------------------- Form Create ---------------------- }
procedure TForm1.FormCreate(Sender: TObject);
begin
  // Connect to database
  if not dmMain.cDatenbank.Connected then
    dmMain.cDatenbank.Connected := True;

  // Create query and datasource if not using designer
  if not Assigned(qUnit1) then
  begin
    qUnit1 := TUniQuery.Create(Self);
    qUnit1.Connection := dmMain.cDatenbank;

    sqUnit1 := TUniDataSource.Create(Self);
    sqUnit1.DataSet := qUnit1;
  end;

  // Open query safely
  qUnit1.Close;
  qUnit1.SQL.Text := 'SELECT * FROM BLOBTEST';
  qUnit1.Open;

  // Load cover if exists
  LoadCurrentCover;
end;

procedure TForm1.btnDeleteImageClick(Sender: TObject);
begin
  ClearBlob;
end;

procedure TForm1.ClearBlob;
var
  Blob: TBlobField;
begin
  if qUnit1.IsEmpty then Exit;

  qUnit1.Edit;

  Blob := qUnit1.FieldByName('COLUMN1') as TBlobField;
  Blob.Clear;

  qUnit1.Post;

  imgAlbumCover.Picture.Clear; // clears UI
end;

{ ---------------------- Load Cover ---------------------- }
procedure TForm1.LoadCurrentCover;
var
  BlobField: TBlobField;
  MemStream: TMemoryStream;
begin
  imgAlbumCover.Picture.Clear;

  if not Assigned(qUnit1) then Exit;
  if not qUnit1.Active then Exit;
  if qUnit1.IsEmpty then Exit;

  BlobField := qUnit1.FieldByName('COLUMN1') as TBlobField;

  if Assigned(BlobField) and
  (not BlobField.IsNull) and
  (BlobField.BlobSize > 0) then
  begin
    MemStream := TMemoryStream.Create;
    try
      BlobField.SaveToStream(MemStream);
      MemStream.Position := 0;
      try
        imgAlbumCover.Picture.LoadFromStream(MemStream);
      except
        on E: Exception do
          ShowMessage('Failed to load image: ' + E.Message);
      end;
    finally
      MemStream.Free;
    end;
  end;
end;

{ ---------------------- Save Cover ---------------------- }
procedure TForm1.SaveCoverToDB(const FileName: string);
var
  BlobField: TBlobField;
begin
  if not Assigned(qUnit1) then Exit;
  if not qUnit1.Active then Exit;
  if qUnit1.IsEmpty then Exit;

  BlobField := qUnit1.FieldByName('COLUMN1') as TBlobField;
  if not Assigned(BlobField) then Exit;

  if not (qUnit1.State in dsEditModes) then
    qUnit1.Edit;

  BlobField.LoadFromFile(FileName);
  qUnit1.Post;

  // Reload image
  LoadCurrentCover;
end;

{ ---------------------- Image Click ---------------------- }
procedure TForm1.imgAlbumCoverClick(Sender: TObject);
begin
  if dlgAlbumCover.Execute then
    SaveCoverToDB(dlgAlbumCover.FileName);
end;

end.

