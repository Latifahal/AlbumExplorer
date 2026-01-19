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



  private

  public
    CurrentUserID: Integer;

  end;

var
  dmMain: TdmMain;

implementation

{$R *.lfm}

{ TdmMain }



end.

