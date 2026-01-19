program Album;

{$mode objfpc}{$H+}

uses
  Forms, Interfaces, LCLType, DB, dDatenbank, Uni, ibprovider10, LoginFormUnit,
  PasswordUtilsUnit, MainFormUnit, AlbumModel, Unit1, UserCredsTestUnit;

{$R *.res}

begin

  Application.Initialize;
  Application.CreateForm(TdmMain, dmMain);
  //Application.CreateForm(TpmAlbum, pmAlbum);
  Application.CreateForm(TUCTUnit, UCTUnit);
  Application.CreateForm(TLoginForm, LoginForm);

  //Application.CreateForm(TForm1, Form1);

  if LoginForm.Execute then
  begin
    LoginForm.Destroy;
    Application.Run;
  end
  else
  begin
    Application.Terminate;
  end;
   //Application.Run;
end.

