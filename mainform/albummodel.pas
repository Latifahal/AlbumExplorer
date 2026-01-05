unit AlbumModel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Graphics, Dialogs, ExtCtrls, Uni;

type
  { TAlbumModel manages album data, including album cover BLOBs }
  TAlbumModel = class
  private
    FDataSet: TDataSet;       // the main album dataset (qAlbum)
    FInsertQuery: TUniQuery;  // dedicated insert query (qAlbumInsert)
  public
    constructor Create(ADataSet: TDataSet; AInsertQuery: TUniQuery);

    function HasValidDataset: Boolean;

    function HasCover: Boolean;
    function CreateCoverStream: TStream;

    procedure LoadCoverFromDialog(TargetImage: TImage; Dialog: TOpenDialog);

    { -------------------- NEW ALBUM -------------------- }
    procedure AddNewAlbum(UserID: Integer);
  end;

implementation

{-------------------- CONSTRUCTOR --------------------}
constructor TAlbumModel.Create(ADataSet: TDataSet; AInsertQuery: TUniQuery);
begin
  FDataSet := ADataSet;
  FInsertQuery := AInsertQuery;
end;

{-------------------- DATASET VALIDATION --------------------}
function TAlbumModel.HasValidDataset: Boolean;
begin
  Result :=
    Assigned(FDataSet) and
    FDataSet.Active;
end;

{-------------------- COVER CHECK -------------------}
function TAlbumModel.HasCover: Boolean;
var
  Field: TField;
begin
  Result := False;
  if not HasValidDataset then Exit;

  Field := FDataSet.FindField('ALBUMCOVER');
  if (Field is TBlobField) then
    Result := (not Field.IsNull) and (TBlobField(Field).BlobSize > 0);
end;

{-------------------- CREATE STREAM --------------------}
function TAlbumModel.CreateCoverStream: TStream;
var
  Field: TField;
begin
  Result := nil;
  if not HasValidDataset then Exit;

  Field := FDataSet.FindField('ALBUMCOVER');
  if (Field is TBlobField) and (not Field.IsNull) then
    Result := FDataSet.CreateBlobStream(Field, bmRead);
end;

{-------------------- LOAD COVER FROM DIALOG --------------------}
procedure TAlbumModel.LoadCoverFromDialog(TargetImage: TImage; Dialog: TOpenDialog);
var
  Field: TField;
begin
  if not HasValidDataset then Exit;
  if not Assigned(TargetImage) or not Assigned(Dialog) then Exit;
  if not Dialog.Execute then Exit;

  Field := FDataSet.FindField('ALBUMCOVER');
  if not (Field is TBlobField) then Exit;

  FDataSet.Edit;
  try
    TBlobField(Field).LoadFromFile(Dialog.FileName);
    FDataSet.Post;
  except
    FDataSet.Cancel;
    raise;
  end;

  TargetImage.Picture.LoadFromFile(Dialog.FileName);
end;

{ -------------------- ADD NEW ALBUM -------------------- }
procedure TAlbumModel.AddNewAlbum(UserID: Integer);
begin
  if not Assigned(FInsertQuery) then Exit;
  if not Assigned(FDataSet) then Exit;


  FInsertQuery.Close;

  FInsertQuery.ParamByName('ALBUM').AsString := 'New Album';
  FInsertQuery.ParamByName('ARTIST').AsString := 'Unknown';
  FInsertQuery.ParamByName('RELEASEYEAR').AsInteger := 0;
  FInsertQuery.ParamByName('DESCRIPTION').AsString := '';
  FInsertQuery.ParamByName('USERID').AsInteger := UserID;
  FInsertQuery.ParamByName('ALBUMCOVER').Clear;

  FInsertQuery.ExecSQL;

  // Refresh the main dataset to see the new row in the grid
  FDataSet.Close;
  FDataSet.Open;
end;

end.

