unit UserCredsTestUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ExtDlgs, DB, Uni, Math;

type

  { TForm3 }

  TForm3 = class(TForm)
    imgUserPic:  TImage;
    lblEmail:    TLabel;
    lblUsername: TLabel;
    dlgUserPic:  TOpenPictureDialog;

    procedure FormCreate(Sender: TObject);
    procedure imgUserPicClick(Sender: TObject);
    procedure LoadCurrentUserImage;
    Procedure SavePicToDB(Const FileName: String);

  private
    qUsers:  TUniQuery;
    sqUsers: TUniDataSource;
  public
  end;

var
  Form3: TForm3;

implementation

  uses dDatenbank;

{$R *.lfm}

{ TForm3 }

procedure TForm3.FormCreate(Sender: TObject);
begin

  if not dmMain.cDatenbank.Connected then
  dmMain.cDatenbank.Connected := True;

    if not Assigned(qUsers) then
  begin
    qUsers := TUniQuery.Create(Self);
    qUsers.Connection := dmMain.cDatenbank;

    sqUsers := TUniDataSource.Create(Self);
    sqUsers.DataSet := qUsers;
  end;

  dmMain.qUsers.Close;
  dmMain.qUsers.ParamByName('ID').AsInteger := dmMain.GetCurrentUserID;
  //dmMain.qUsers.ParamByName('USERNAME').AsString := dmMain.GetCurrentUsername;
  //dmMain.qUsers.ParamByName('EMAIL').AsString := dmMain.GetCurrentEmail;
  dmMain.qUsers.open;

  lblUsername.Caption := dmMain.GetCurrentUsername;
  lblEmail.Caption    := dmMain.GetCurrentEmail;

   LoadCurrentUserImage;

end;

procedure ResetFPU;
begin
  // Disable all floating point exceptions (GTK safe mode)
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
                    exOverflow, exUnderflow, exPrecision]);
end;

procedure TForm3.imgUserPicClick(Sender: TObject);
begin
  ResetFPU;

  if dlgUserPic.Execute then
    SavePicToDB(dlgUSerPic.FileName);
end;


{.............. Save Pic ToDB .......................}
Procedure TForm3.SavePicToDB(Const FileName: String);
var
  BlobField: TBlobField;
begin
  ResetFPU;
  if not Assigned(qUsers) then Exit;
  if not qUsers.Active then Exit;
  if qUsers.IsEmpty then Exit;

  //lblUsername := qUsers.FieldByName('USERNAME') as TLable;
  //lblUsername := qUsers.FieldByName('EMAIL') as TLable;
  BlobField := qUsers.FieldByName('USERPICTURE') as TBlobField;
  if not Assigned(BlobField) then Exit;

   if not (qUsers.State in dsEditModes) then
    qUsers.Edit;

  BlobField.LoadFromFile(FileName);
  qUsers.Post;

  // Reload image
  LoadCurrentUserImage;
end;

{......... Load Current User Img ..................}
procedure TForm3.LoadCurrentUserImage;
var
  BlobField: TBlobField;
  MemStream: TMemoryStream;
begin
  ResetFPU;
  imgUserPic.Picture.Clear;

  if not Assigned(qUsers) then Exit;
  if not qUsers.Active then Exit;
  if qUsers.IsEmpty then Exit;

  BlobField := qUsers.FieldByName('USERPICTURE') as TBlobField;

  if Assigned(BlobField) and (not BlobField.IsNull) and (BlobField.BlobSize > 0) then
  begin
    MemStream := TMemoryStream.Create;
    try
      BlobField.SaveToStream(MemStream);
      MemStream.Position := 0;
      try
        imgUserPic.Picture.LoadFromStream(MemStream);
      except
        on E: Exception do
          ShowMessage('Failed to load image: ' + E.Message);
      end;
    finally
      MemStream.Free;
    end;
  end;
end;



end.

