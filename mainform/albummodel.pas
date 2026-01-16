unit AlbumModel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Graphics, Dialogs, ExtCtrls, Uni;

type
  { TAlbumModel manages album data, including album cover BLOBs }
  TAlbumModel = class
  private
    FDataSet:     TDataSet;
    FInsertQuery: TUniQuery;  // Dedicated insert query (qAlbumInsert)
  public
    constructor Create(ADataSet: TDataSet; AInsertQuery: TUniQuery);

    function HasValidDataset: Boolean;
    function HasCover: Boolean;
    function CreateCoverStream: TStream;
    function LoadCoverFromDialog(Dialog: TOpenDialog): Boolean;
    procedure AddNewAlbum(UserID: Integer);
    procedure SaveCoverFromFile(Dialog: TOpenDialog);
  end;

implementation

{-------------------- CONSTRUCTOR --------------------}
constructor TAlbumModel.Create(ADataSet: TDataSet; AInsertQuery: TUniQuery);
begin
  Writeln('TAlbumModel.Create: start');
  FDataSet := ADataSet;
  Writeln('TAlbumModel.Create: dataset assigned');
  FInsertQuery := AInsertQuery;
  Writeln('TAlbumModel.Create: insert query assigned');
  Writeln('TAlbumModel.Create: done');
end;

{-------------------- DATASET VALIDATION --------------------}
function TAlbumModel.HasValidDataset: Boolean;
begin
  Writeln('HasValidDataset: start');
  Result :=
    Assigned(FDataSet) and
    FDataSet.Active and
    not FDataSet.IsEmpty;
  Writeln('HasValidDataset: result = ', Result);
end;

{-------------------- COVER CHECK -------------------}
function TAlbumModel.HasCover: Boolean;
var
  Field: TField;
begin
  Writeln('HasCover: start');
  Result := False;
  if not HasValidDataset then
  begin
    Writeln('HasCover: dataset not valid');
    Exit;
  end;

  Field := FDataSet.FindField('ALBUMCOVER');
  if (Field is TBlobField) then
    Result := (not Field.IsNull) and (TBlobField(Field).BlobSize > 0);
  Writeln('HasCover: result = ', Result);
end;

{-------------------- CREATE STREAM --------------------}
function TAlbumModel.CreateCoverStream: TStream;
var
  Field: TField;
begin
  Writeln('CreateCoverStream: start');
  Result := nil;
  if not HasValidDataset then
  begin
    Writeln('CreateCoverStream: dataset not valid');
    Exit;
  end;

  Field := FDataSet.FindField('ALBUMCOVER');
  if (Field is TBlobField) and (not Field.IsNull) then
    Result := FDataSet.CreateBlobStream(Field, bmRead);
  if Assigned(Result) then
    Writeln('CreateCoverStream: stream created')
  else
    Writeln('CreateCoverStream: stream not created');
end;

{-------------------- LOAD COVER FROM DIALOG --------------------}
function TAlbumModel.LoadCoverFromDialog(Dialog: TOpenDialog): Boolean;
var
  Field: TField;
begin
  Writeln('LoadCoverFromDialog: start');
  Result := False;

  if not HasValidDataset then
  begin
    Writeln('LoadCoverFromDialog: dataset not valid');
    Exit;
  end;

  if not Assigned(Dialog) then
  begin
    Writeln('LoadCoverFromDialog: dialog not assigned');
    Exit;
  end;

  Writeln('LoadCoverFromDialog: about to execute dialog');
  if not Dialog.Execute then
  begin
    Writeln('LoadCoverFromDialog: dialog canceled or failed');
    Exit;
  end;
  Writeln('LoadCoverFromDialog: dialog executed');

  Field := FDataSet.FindField('ALBUMCOVER');
  if not (Field is TBlobField) then
  begin
    Writeln('LoadCoverFromDialog: ALBUMCOVER field not found');
    Exit;
  end;

  Writeln('LoadCoverFromDialog: editing dataset');
  FDataSet.Edit;
  try
    Writeln('LoadCoverFromDialog: loading file into BLOB');
    TBlobField(Field).LoadFromFile(Dialog.FileName);
    Writeln('LoadCoverFromDialog: posting dataset');
    FDataSet.Post;
    Writeln('LoadCoverFromDialog: file loaded successfully');
    Result := True;
  except
    on E: Exception do
    begin
      Writeln('LoadCoverFromDialog: exception occurred - ' + E.Message);
      FDataSet.Cancel;
      raise;
    end;
  end;
end;

{-------------------- Save Cover From File --------------------}
procedure TAlbumModel.SaveCoverFromFile(Dialog: TOpenDialog);
var
  Field: TBlobField;
begin
  Writeln('SaveCoverFromFile: start');

  if not HasValidDataset then
  begin
    Writeln('SaveCoverFromFile: dataset not valid');
    Exit;
  end;

  if not Assigned(Dialog) then
  begin
    Writeln('SaveCoverFromFile: dialog not assigned');
    Exit;
  end;

  Writeln('SaveCoverFromFile: about to execute dialog');
  if not Dialog.Execute then
  begin
    Writeln('SaveCoverFromFile: dialog canceled or failed');
    Exit;
  end;
  Writeln('SaveCoverFromFile: dialog executed');

  Field := FDataSet.FieldByName('ALBUMCOVER') as TBlobField;
  if not Assigned(Field) then
  begin
    Writeln('SaveCoverFromFile: ALBUMCOVER field not found');
    Exit;
  end;

  if not (FDataSet.State in dsEditModes) then
    FDataSet.Edit;
  Writeln('SaveCoverFromFile: dataset in edit mode');

  try
    Writeln('SaveCoverFromFile: loading file into BLOB');
    Field.LoadFromFile(Dialog.FileName);
    Writeln('SaveCoverFromFile: posting dataset');
    FDataSet.Post;
    Writeln('SaveCoverFromFile: file loaded successfully');
  except
    on E: Exception do
    begin
      Writeln('SaveCoverFromFile: exception occurred - ' + E.Message);
      FDataSet.Cancel;
      raise;
    end;
  end;
end;


{ -------------------- ADD NEW ALBUM -------------------- }
procedure TAlbumModel.AddNewAlbum(UserID: Integer);
begin
  Writeln('AddNewAlbum: start');

  if not Assigned(FInsertQuery) then
  begin
    Writeln('AddNewAlbum: insert query not assigned');
    Exit;
  end;

  if not Assigned(FDataSet) then
  begin
    Writeln('AddNewAlbum: dataset not assigned');
    Exit;
  end;

  Writeln('AddNewAlbum: preparing parameters');
  FInsertQuery.Close;

  FInsertQuery.ParamByName('ALBUM').AsString := 'New Album';
  FInsertQuery.ParamByName('ARTIST').AsString := 'Unknown';
  FInsertQuery.ParamByName('RELEASEYEAR').AsInteger := 0;
  FInsertQuery.ParamByName('DESCRIPTION').AsString := '';
  FInsertQuery.ParamByName('USERID').AsInteger := UserID;
  FInsertQuery.ParamByName('ALBUMCOVER').Clear;

  Writeln('AddNewAlbum: executing insert query');
  FInsertQuery.ExecSQL;
  Writeln('AddNewAlbum: insert executed');

  Writeln('AddNewAlbum: refreshing dataset');
  FDataSet.Close;
  FDataSet.Open;
  Writeln('AddNewAlbum: done');
end;

end.

