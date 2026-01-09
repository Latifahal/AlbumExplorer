unit Unit1;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ExtDlgs, StdCtrls, DB,
  dDatenbank, LResources;

type
  TForm1 = class(TForm)
    imgBlob: TImage;
    dlgPicture: TOpenPictureDialog;
    btnDeleteImage: TButton;
    procedure FormCreate(Sender: TObject);
    procedure imgBlobClick(Sender: TObject);
    procedure btnDeleteImageClick(Sender: TObject);
  private
    procedure LoadBlob;
    procedure SaveBlob(const FileName: string);
    procedure LoadPlaceholder;
    procedure UpdateDeleteButton;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}
{$R images.lrs}

procedure TForm1.FormCreate(Sender: TObject);
begin
  if not dmMain.cDatenbank.Connected then
    dmMain.cDatenbank.Connected := True;

  dmMain.qBlobTest.Open;

  LoadBlob;
  UpdateDeleteButton;
end;

procedure TForm1.LoadPlaceholder;
begin
  imgBlob.Picture.Clear;
  imgBlob.Picture.LoadFromLazarusResource('ROBOT_PLACEHOLDER');
end;

procedure TForm1.LoadBlob;
var
  Blob: TBlobField;
  S: TMemoryStream;
begin
  if dmMain.qBlobTest.IsEmpty then
  begin
    LoadPlaceholder;
    Exit;
  end;

  Blob := dmMain.qBlobTest.FieldByName('COLUMN1') as TBlobField;

  if Blob.IsNull or (Blob.BlobSize = 0) then
  begin
    LoadPlaceholder;
    Exit;
  end;

  S := TMemoryStream.Create;
  try
    Blob.SaveToStream(S);
    S.Position := 0;
    imgBlob.Picture.LoadFromStream(S);
  finally
    S.Free;
  end;
end;

procedure TForm1.SaveBlob(const FileName: string);
var
  Blob: TBlobField;
begin
  if dmMain.qBlobTest.IsEmpty then
    dmMain.qBlobTest.Append
  else
    dmMain.qBlobTest.Edit;

  Blob := dmMain.qBlobTest.FieldByName('COLUMN1') as TBlobField;
  Blob.LoadFromFile(FileName);

  dmMain.qBlobTest.Post;

  LoadBlob;
  UpdateDeleteButton;
end;

procedure TForm1.btnDeleteImageClick(Sender: TObject);
var
  Blob: TBlobField;
begin
  if dmMain.qBlobTest.IsEmpty then Exit;

  dmMain.qBlobTest.Edit;

  Blob := dmMain.qBlobTest.FieldByName('COLUMN1') as TBlobField;
  Blob.Clear;

  dmMain.qBlobTest.Post;

  LoadPlaceholder;
  UpdateDeleteButton;
end;

procedure TForm1.imgBlobClick(Sender: TObject);
begin
  if dlgPicture.Execute then
    SaveBlob(dlgPicture.FileName);
end;

procedure TForm1.UpdateDeleteButton;
var
  Blob: TBlobField;
begin
  if dmMain.qBlobTest.IsEmpty then
  begin
    btnDeleteImage.Enabled := False;
    Exit;
  end;

  Blob := dmMain.qBlobTest.FieldByName('COLUMN1') as TBlobField;
  btnDeleteImage.Enabled := not Blob.IsNull;
end;

end.

