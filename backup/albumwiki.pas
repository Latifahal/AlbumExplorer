unit unit_albumwiki;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, DB, SQLDB, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    SQLConnector1: TSQLConnector;
    SQLTransaction1: TSQLTransaction;
    SQLQuery1: TSQLQuery;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    ButtonLoadAlbums: TButton;
    ButtonAddAlbum: TButton;
    ButtonDeleteAlbum: TButton;
    edtTitle: TEdit;
    edtArtist: TEdit;
    edtYear: TEdit;
    lblTitle: TLabel;
    lblArtist: TLabel;
    lblYear: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ButtonLoadAlbumsClick(Sender: TObject);
    procedure ButtonAddAlbumClick(Sender: TObject);
    procedure ButtonDeleteAlbumClick(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  SQLConnector1.ConnectorType := 'Firebird';
  SQLConnector1.LibraryName := '/usr/lib/i386-linux-gnu/libfbembed.so'; // Embedded library
  SQLConnector1.HostName := '';                 // Embedded, no host
  SQLConnector1.DatabaseName := 'AlbumWiki.fdb'; // File in project folder
  SQLConnector1.UserName := 'sysdba';
  SQLConnector1.Password := 'slu01';
  SQLConnector1.Transaction := SQLTransaction1;

  SQLConnector1.Connected := True;             // Connect to DB
end;

procedure TForm1.ButtonLoadAlbumsClick(Sender: TObject);
begin
  SQLQuery1.Close;
  SQLQuery1.SQL.Text :=
    'SELECT Albums.AlbumID, Albums.Title, Artists.Name AS Artist, Albums.ReleaseYear ' +
    'FROM Albums JOIN Artists ON Albums.ArtistID = Artists.ArtistID ' +
    'ORDER BY Albums.AlbumID';
  SQLQuery1.Open;
end;

procedure TForm1.ButtonAddAlbumClick(Sender: TObject);
var
  ArtistID: Integer;
begin
  // Check if artist exists
  SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'SELECT ArtistID FROM Artists WHERE Name = :Name';
  SQLQuery1.Params.ParamByName('Name').AsString := edtArtist.Text;
  SQLQuery1.Open;

  if SQLQuery1.EOF then
  begin
    // Insert artist if not exists
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := 'INSERT INTO Artists (Name) VALUES (:Name)';
    SQLQuery1.Params.ParamByName('Name').AsString := edtArtist.Text;
    SQLQuery1.ExecSQL;
    SQLTransaction1.Commit;

    // Retrieve new ArtistID
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := 'SELECT ArtistID FROM Artists WHERE Name = :Name';
    SQLQuery1.Params.ParamByName('Name').AsString := edtArtist.Text;
    SQLQuery1.Open;
  end;

  ArtistID := SQLQuery1.FieldByName('ArtistID').AsInteger;

  // Insert new album
  SQLQuery1.Close;
  SQLQuery1.SQL.Text :=
    'INSERT INTO Albums (Title, ArtistID, ReleaseYear) VALUES (:Title, :ArtistID, :Year)';
  SQLQuery1.Params.ParamByName('Title').AsString := edtTitle.Text;
  SQLQuery1.Params.ParamByName('ArtistID').AsInteger := ArtistID;
  SQLQuery1.Params.ParamByName('Year').AsInteger := StrToInt(edtYear.Text);
  SQLQuery1.ExecSQL;
  SQLTransaction1.Commit;

  // Refresh grid
  ButtonLoadAlbumsClick(Sender);

  // Clear inputs
  edtTitle.Text := '';
  edtArtist.Text := '';
  edtYear.Text := '';
end;

procedure TForm1.ButtonDeleteAlbumClick(Sender: TObject);
var
  AlbumID: Integer;
begin
  if SQLQuery1.RecordCount = 0 then Exit;

  AlbumID := SQLQuery1.FieldByName('AlbumID').AsInteger;

  if MessageDlg('Delete Album',
    'Are you sure you want to delete this album?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := 'DELETE FROM Albums WHERE AlbumID = :AlbumID';
    SQLQuery1.Params.ParamByName('AlbumID').AsInteger := AlbumID;
    SQLQuery1.ExecSQL;
    SQLTransaction1.Commit;

    // Refresh grid
    ButtonLoadAlbumsClick(Sender);
  end;
end;

end.

