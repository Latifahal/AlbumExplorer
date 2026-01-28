unit LoginFormUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs,
  dDatenbank, UserObjectUnit, RegisterFormUnit, PasswordUtilsUnit;

type
  { TLoginForm }
  TLoginForm = class(TForm)
    edtUsername: TEdit;
    edtUserPassword: TEdit;
    cbkStayLoggedIn: TCheckBox;
    btnLogin: TButton;
    btnRegister: TButton;
    lblLoginStatusMsg: TLabel;

    procedure btnLoginClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
  private
    FLoginSuccessful: Boolean;
  public
    function Execute: Boolean;
    property LoginSuccessful: Boolean read FLoginSuccessful;
  end;

var
  LoginForm: TLoginForm;

implementation

{$R *.lfm}

procedure TLoginForm.btnLoginClick(Sender: TObject);
var
  StoredHash, StoredSalt: string;
begin
  FLoginSuccessful := False;
  lblLoginStatusMsg.Caption := '';

  // prepare login query
  dmMain.qUsersLogin.Close;
  dmMain.qUsersLogin.ParamByName('USERNAME').AsString :=
    Trim(edtUsername.Text);
  dmMain.qUsersLogin.Open;

  if dmMain.qUsersLogin.IsEmpty then
  begin
    lblLoginStatusMsg.Caption := 'User not found';
    Exit;
  end;

  StoredHash := dmMain.qUsersLogin.FieldByName('PWDHASH').AsString;
  StoredSalt := dmMain.qUsersLogin.FieldByName('PWDSALT').AsString;

  
  if not VerifyPassword(
       edtUserPassword.Text,
       StoredSalt,
       StoredHash
     ) then
  begin
    lblLoginStatusMsg.Caption := 'Invalid password';
    Exit;
  end;

  // login success
  FLoginSuccessful := True;
  lblLoginStatusMsg.Caption := 'Login successful';

  // store logged-in user ID
  //dmMain.FCurrentUserID :=
  //  dmMain.qUsersLogin.FieldByName('ID').AsInteger;
    dmMain.SetCurrentUser(
    dmMain.qUsersLogin.FieldByName('ID').AsInteger,
    dmMain.qUsersLogin.FieldByName('USERNAME').AsString,
    dmMain.qUsersLogin.FieldByName('EMAIL').AsString
    );

  // open album dataset filtered by user
  dmMain.qAlbum.Close;
  dmMain.qAlbum.ParamByName('UID').AsInteger := dmMain.GetCurrentUserID;
  dmMain.qAlbum.ParamByName('SEARCH').AsString := '%';
  dmMain.qAlbum.Open;

  // open songs dataset
  if not dmMain.qSongs.Active then
    dmMain.qSongs.Open;

  // stay logged in
  if cbkStayLoggedIn.Checked then
  begin
    with TUserObject.Create(nil, nil, nil) do
    try
      Username := edtUsername.Text;
      StayLoggedIn := True;
      SaveSettings;
    finally
      Free;
    end;
  end;

  Close;
end;

procedure TLoginForm.btnRegisterClick(Sender: TObject);
var
  RegForm: TRegisterForm;
begin
  RegForm := TRegisterForm.Create(
               Self,
               dmMain.qUserCheckExists,
               dmMain.qUsersInsert,
               dmMain.qUsersLogin
             );
  try
    if RegForm.ShowModal = mrOK then
      edtUsername.Text := RegForm.NewUsername;
  finally
    RegForm.Free;
  end;
end;

function TLoginForm.Execute: Boolean;
begin
  FLoginSuccessful := False;
  ShowModal;
  Result := FLoginSuccessful;
end;

end.

