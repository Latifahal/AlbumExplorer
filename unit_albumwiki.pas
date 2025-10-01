unit unit_albumwiki;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DB, SQLDB,
  IBConnection, StdCtrls, Grids, IBDatabase;

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
    procedure StringGrid1SelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
  private
    SelectedAlbumID: Integer;
    procedure LoadAlbums;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  IBConnection1.DatabaseName := '/var/lib/firebird/3.0/data/AlbumWiki.fdb';
  IBConnection1.UserName := 'sysdba';
  IBConnection1.Password := 'slu01';
  IBConnection1.Connected := True;

  SQLTransaction1.DataBase := IBConnection1;
  SQLTransaction1.StartTransaction;

  SQLQuery1.DataBase := IBConnection1;
  SQLQuery1.Transaction := SQLTransaction1;

  // Setup StringGrid
  StringGrid1.ColCount := 4;
  StringGrid1.RowCount := 1;
  StringGrid1.FixedRows := 1;
  StringGrid1.Cells[0,0] := 'AlbumID';
  StringGrid1.Cells[1,0] := 'Title';
  StringGrid1.Cells[2,0] := 'Artist';
  StringGrid1.Cells[3,0] := 'Year';

  SelectedAlbumID := -1;

  LoadAlbums;
end;

procedure TForm1.LoadAlbums;
var
  Row: Integer;
begin
  SQLQuery1.Close;
  SQLQuery1.SQL.Text :=
    'SELECT A.ALBUMID, A.TITLE, R.NAME AS ARTIST, A.RELEASEYEAR ' +
    'FROM ALBUMS A JOIN ARTISTS R ON A.ARTISTID = R.ARTISTID ' +
    'ORDER BY A.ALBUMID';
  SQLQuery1.Open;

  StringGrid1.RowCount := 1;
  Row := 1;

  while not SQLQuery1.EOF do
  begin
    StringGrid1.RowCount := Row + 1;
    StringGrid1.Cells[0,Row] := SQLQuery1.FieldByName('ALBUMID').AsString;
    StringGrid1.Cells[1,Row] := SQLQuery1.FieldByName('TITLE').AsString;
    StringGrid1.Cells[2,Row] := SQLQuery1.FieldByName('ARTIST').AsString;
    StringGrid1.Cells[3,Row] := SQLQuery1.FieldByName('RELEASEYEAR').AsString;

    SQLQuery1.Next;
    Inc(Row);
  end;
end;

procedure TForm1.ButtonLoadAlbumsClick(Sender: TObject);
begin
  LoadAlbums;
end;

procedure TForm1.StringGrid1SelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  if aRow > 0 then
    SelectedAlbumID := StrToIntDef(StringGrid1.Cells[0,aRow], -1)
  else
    SelectedAlbumID := -1;
end;

procedure TForm1.ButtonAddAlbumClick(Sender: TObject);
var
  ArtistID: Integer;
  YearValue: Integer;
begin
  YearValue := StrToIntDef(edtYear.Text, 0);

  // Check if artist exists
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
    SQLTransaction1.Commit;

    SQLQuery1.Close;
    SQLQuery1.SQL.Text := 'SELECT ARTISTID FROM ARTISTS WHERE NAME = :Name';
    SQLQuery1.Params.ParamByName('Name').AsString := edtArtist.Text;
    SQLQuery1.Open;
  end;

  ArtistID := SQLQuery1.FieldByName('ARTISTID').AsInteger;

  // Insert album
  SQLQuery1.Close;
  SQLQuery1.SQL.Text :=
    'INSERT INTO ALBUMS (TITLE, ARTISTID, RELEASEYEAR) VALUES (:Title, :ArtistID, :Year)';
  SQLQuery1.Params.ParamByName('Title').AsString := edtTitle.Text;
  SQLQuery1.Params.ParamByName('ArtistID').AsInteger := ArtistID;
  SQLQuery1.Params.ParamByName('Year').AsInteger := YearValue;
  SQLQuery1.ExecSQL;
  SQLTransaction1.Commit;

  LoadAlbums;

  edtTitle.Text := '';
  edtArtist.Text := '';
  edtYear.Text := '';
end;

procedure TForm1.ButtonDeleteAlbumClick(Sender: TObject);
begin
  if SelectedAlbumID = -1 then Exit;

  if MessageDlg('Delete Album',
    'Are you sure you want to delete this album?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := 'DELETE FROM ALBUMS WHERE ALBUMID = :AlbumID';
    SQLQuery1.Params.ParamByName('AlbumID').AsInteger := SelectedAlbumID;
    SQLQuery1.ExecSQL;
    SQLTransaction1.Commit;

    SelectedAlbumID := -1;
    LoadAlbums;
  end;
end;

end.

