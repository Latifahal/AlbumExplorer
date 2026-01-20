program Album;

{$mode objfpc}{$H+}

uses
  Forms, Interfaces, LCLType, DB, dDatenbank, Uni, ibprovider10, LoginFormUnit,
  PasswordUtilsUnit, MainFormUnit, AlbumModel, Unit1, UserCredsTestUnit;

{$R *.res}

begin

  //Application.Initialize;
  Application.CreateForm(TdmMain, dmMain);
  //Application.CreateForm(TpmAlbum, pmAlbum);
  Application.CreateForm(TForm3, Form3);
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

  // Application.CreateForm(TdmMain, dmMain);
  //Application.CreateForm(TForm3, Form3);    // UserCredsTestUnit
  //Application.CreateForm(TLoginForm, LoginForm);
  //
  //if LoginForm.Execute then
  //begin
  //  LoginForm.Free;
  //
  //  // Fill Form3 labels from dmMain
  //  Form3.lblUsername.Caption := dmMain.GetCurrentUsername;
  //  Form3.lblEmail.Caption := dmMain.GetCurrentEmail;
  //
  //  Form3.Show;       // show the user info form
  //  Application.Run;  // run main loop
  //end
  //else
  //begin
  //  Application.Terminate;
  //end;
end.

