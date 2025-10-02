unit unit_albumwiki;

{$mode objfpc}{$H+}

interface

uses
Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DB, SQLDB,
IBConnection, StdCtrls, Grids;

type

{ TForm1 }

TForm1 = class(TForm)
IBConnection1: TIBConnection;
SQLTransaction1: TSQLTransaction;
SQLQuery1: TSQLQuery;
ButtonLoadAlbums: TButton;
ButtonAddAlbum: TButton;
ButtonDeleteAlbum: TButton;
edtTitle: TEdit;
edtArtist: TEdit;
edtYear: TEdit;
lblTitle: TLabel;
lblArtist: TLabel;
lblYear: TLabel;
StringGrid1: TStringGrid;
procedure FormCreate(Sender: TObject);
procedure ButtonLoadAlbumsClick(Sender: TObject);
procedure ButtonAddAlbumClick(Sender: TObject);
procedure ButtonDeleteAlbumClick(Sender: TObject);
private
procedure LoadAlbums;
procedure EnsureTransaction;
end;

var
Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.EnsureTransaction;
begin
if not SQLTransaction1.Active then
SQLTransaction1.StartTransaction;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
try
IBConnection1.Connected := False;
IBConnection1.DatabaseName := ExtractFilePath(Application.ExeName) + 'data/AlbumWiki.fdb';
IBConnection1.UserName := 'sysdba';
IBConnection1.Password := 'slu01';
IBConnection1.Params.Values['TempCacheDir'] := '/tmp/firebird';
IBConnection1.Connected := True;


SQLTransaction1.DataBase := IBConnection1;
SQLQuery1.DataBase := IBConnection1;
SQLQuery1.Transaction := SQLTransaction1;


except
on E: Exception do
ShowMessage('Database connection failed: ' + E.Message);
end;

StringGrid1.ColCount := 4;
StringGrid1.RowCount := 1;
StringGrid1.FixedRows := 1;
StringGrid1.Cells[0,0] := 'AlbumID';
StringGrid1.Cells[1,0] := 'Title';
StringGrid1.Cells[2,0] := 'Artist';
StringGrid1.Cells[3,0] := 'ReleaseYear';

LoadAlbums;
end;

procedure TForm1.LoadAlbums;
var
Row: Integer;
begin
EnsureTransaction;
SQLQuery1.Close;
SQLQuery1.SQL.Text :=
'SELECT A.ALBUMID, A.TITLE, R.NAME AS ARTIST, A.RELEASEYEAR ' +
'FROM ALBUMS A ' +
'LEFT JOIN ARTISTS R ON A.ARTISTID = R.ARTISTID ' +
'ORDER BY A.ALBUMID';
SQLQuery1.Open;

StringGrid1.RowCount := 1;
Row := 1;
while not SQLQuery1.EOF do
begin
StringGrid1.RowCount := Row + 1;
StringGrid1.Cells[0, Row] := SQLQuery1.FieldByName('ALBUMID').AsString;
StringGrid1.Cells[1, Row] := SQLQuery1.FieldByName('TITLE').AsString;
StringGrid1.Cells[2, Row] := SQLQuery1.FieldByName('ARTIST').AsString;
StringGrid1.Cells[3, Row] := SQLQuery1.FieldByName('RELEASEYEAR').AsString;
SQLQuery1.Next;
Inc(Row);
end;
end;

procedure TForm1.ButtonLoadAlbumsClick(Sender: TObject);
begin
LoadAlbums;
end;

procedure TForm1.ButtonAddAlbumClick(Sender: TObject);
var
ArtistID: Integer;
YearValue: Integer;
begin
YearValue := StrToIntDef(edtYear.Text, 0);

EnsureTransaction;
SQLQuery1.Close;
SQLQuery1.SQL.Text := 'SELECT ARTISTID FROM ARTISTS WHERE NAME = :Name';
SQLQuery1.Params.ParamByName('Name').AsString := edtArtist.Text;
SQLQuery1.Open;

if SQLQuery1.EOF then
begin
SQLQuery1.Close;
SQLQuery1.SQL.Text := 'INSERT INTO ARTISTS (NAME) VALUES (:Name)';
SQLQuery1.Params.ParamByName('Name').AsString := edtArtist.Text;
SQLQuery1.ExecSQL;
SQLTransaction1.CommitRetaining;


SQLQuery1.Close;
SQLQuery1.SQL.Text := 'SELECT ARTISTID FROM ARTISTS WHERE NAME = :Name';
SQLQuery1.Params.ParamByName('Name').AsString := edtArtist.Text;
SQLQuery1.Open;


end;

ArtistID := SQLQuery1.FieldByName('ARTISTID').AsInteger;

SQLQuery1.Close;
SQLQuery1.SQL.Text :=
'INSERT INTO ALBUMS (TITLE, ARTISTID, RELEASEYEAR) VALUES (:Title, :ArtistID, :ReleaseYear)';
SQLQuery1.Params.ParamByName('Title').AsString := edtTitle.Text;
SQLQuery1.Params.ParamByName('ArtistID').AsInteger := ArtistID;
SQLQuery1.Params.ParamByName('ReleaseYear').AsInteger := YearValue;
SQLQuery1.ExecSQL;
SQLTransaction1.CommitRetaining;

LoadAlbums;

edtTitle.Text := '';
edtArtist.Text := '';
edtYear.Text := '';
end;

procedure TForm1.ButtonDeleteAlbumClick(Sender: TObject);
var
AlbumID: Integer;
Row: Integer;
begin
Row := StringGrid1.Row;
if Row <= 0 then
begin
ShowMessage('Please select an album row first.');
Exit;
end;

AlbumID := StrToIntDef(StringGrid1.Cells[0, Row], -1);
if AlbumID = -1 then
begin
ShowMessage('Selected row has no valid AlbumID.');
Exit;
end;

if MessageDlg('Delete Album', 'Are you sure you want to delete this album?',
mtConfirmation, [mbYes, mbNo], 0) = mrYes then
begin
EnsureTransaction;
SQLQuery1.Close;
SQLQuery1.SQL.Text := 'DELETE FROM ALBUMS WHERE ALBUMID = :AlbumID';
SQLQuery1.Params.ParamByName('AlbumID').AsInteger := AlbumID;
SQLQuery1.ExecSQL;
SQLTransaction1.CommitRetaining;
LoadAlbums;
end;
end;

end.

