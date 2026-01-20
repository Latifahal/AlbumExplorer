unit dDatenbank;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Uni, InterBaseUniProvider;

type

  { TdmMain }

  TdmMain = class(TDataModule)
    {Connection}
    cDatenbank:            TUniConnection;

    {Provider}
    InterBaseUniProvider1: TInterBaseUniProvider;

    {Album & Track Queries and DataSource}
    qAlbum:                TUniQuery;
    qAlbumDelete:          TUniQuery;
    qSongs:                TUniQuery;
    sqAlbum:               TUniDataSource;
    sqSongs:               TUniDataSource;

    {User Quiries}
    qUsersLogin:           TUniQuery;
    qUsersRegister:        TUniQuery;
    qUsersInsert:          TUniQuery;
    qUserCheckExists:      TUniQuery;
    qAlbumInsert:          TUniQuery;

    {q and sq for testing}
    sqUnit1:               TUniDataSource;
    qUnit1:                TUniQuery;
    qUsers:                TUniQuery;
    sqUsers: TUniDataSource;



  private
    FCurrentUserID:   LongInt;
    FCurrentUsername: AnsiString;
    FCurrentEmail:    AnsiString;
  public
    procedure SetCurrentUser(AID:  LongInt; AUsername, AEmail: AnsiString);
    function  GetCurrentUserID:   LongInt;
    function  GetCurrentUsername: AnsiString;
    function  GetCurrentEmail:    AnsiString;

  end;

var
  dmMain: TdmMain;

implementation

procedure TdmMain.SetCurrentUser(AID: LongInt; AUsername, AEmail: AnsiString);
begin
  FCurrentUserID   := AID;
  FCurrentUsername := AUsername;
  FCurrentEmail    := AEmail;
end;

function TdmMain.GetCurrentUserID: LongInt;
begin
  Result := FCurrentUserID;
end;

function TdmMain.GetCurrentUserName: AnsiString;
begin
  Result := FCurrentUsername;
end;

function TdmMain.GetCurrentEmail: AnsiString;
begin
  Result := FCurrentEmail;
end;

{$R *.lfm}

{ TdmMain }



end.

