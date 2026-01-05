unit UserObjectUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, DB, Uni, dDatenbank, PasswordUtilsUnit, Dialogs;

const
  C_INI_FILE = 'user.ini';
  C_SECTION  = 'Login';

type
  { TUserObject: Encapsulates all user-related operations }
  TUserObject = class
  private
    FUsername: string;
    FEmail: string;
    FPassword: string;
    FStayLoggedIn: Boolean;
    FLastError: string;
    FUserID: Integer; // <-- added property to store DB ID

    FQueryCheckExists: TUniQuery; // SELECT check
    FQueryInsert:      TUniQuery; // INSERT
    FQueryLogin:       TUniQuery; // SELECT for login

    procedure SetPassword(const APassword: string);
    procedure HandleDatabaseError(const E: Exception);
  public
    constructor Create(AQueryCheck, AQueryInsert, AQueryLogin: TUniQuery);

    property Username: string read FUsername write FUsername;
    property Email: string read FEmail write FEmail;
    property Password: string write SetPassword;
    property StayLoggedIn: Boolean read FStayLoggedIn write FStayLoggedIn;
    property LastError: string read FLastError;
    property UserID: Integer read FUserID; // <-- read-only property

    function ValidateCredentials(const AUsername, APassword: string): Boolean;
    function RegisterUser: Boolean;

    procedure LoadSettings;
    procedure SaveSettings;
  end;

implementation

{ Constructor }
constructor TUserObject.Create(AQueryCheck, AQueryInsert, AQueryLogin: TUniQuery);
begin
  inherited Create;
  FUsername := '';
  FEmail := '';
  FPassword := '';
  FStayLoggedIn := False;
  FLastError := '';
  FUserID := 0;
  FQueryCheckExists := AQueryCheck;
  FQueryInsert := AQueryInsert;
  FQueryLogin := AQueryLogin;
end;

{ Password Setter }
procedure TUserObject.SetPassword(const APassword: string);
begin
  FPassword := APassword; // Plain text for now
end;

{ Load settings from INI }
procedure TUserObject.LoadSettings;
var
  Sett: TIniFile;
begin
  Sett := TIniFile.Create(C_INI_FILE);
  try
    FUsername := Sett.ReadString(C_SECTION, 'Username', '');
    FStayLoggedIn := Sett.ReadBool(C_SECTION, 'StayLoggedIn', False);
  finally
    Sett.Free;
  end;
end;

{ Save settings to INI }
procedure TUserObject.SaveSettings;
var
  Sett: TIniFile;
begin
  Sett := TIniFile.Create(C_INI_FILE);
  try
    Sett.WriteString(C_SECTION, 'Username', FUsername);
    Sett.WriteBool(C_SECTION, 'StayLoggedIn', FStayLoggedIn);
  finally
    Sett.Free;
  end;
end;

{ Centralized error handling }
procedure TUserObject.HandleDatabaseError(const E: Exception);
begin
  FLastError := 'DB error: ' + E.Message;
end;

{ Register user in DB }
function TUserObject.RegisterUser: Boolean;
var
  Salt, Hash: string;
begin
  Result := False;
  FLastError := '';
  try
    // --- Check if username/email exists ---
    FQueryCheckExists.Close;
    FQueryCheckExists.ParamByName('USERNAME').AsString := Trim(FUsername);
    FQueryCheckExists.ParamByName('EMAIL').AsString := Trim(FEmail);
    FQueryCheckExists.Open;
    if not FQueryCheckExists.IsEmpty then
    begin
      FLastError := 'Username or email already exists';
      Exit(False);
    end;

    // --- Generate hash and salt ---
    Hash := CreatePasswordHash(FPassword, Salt);

    // --- Insert user ---
    FQueryInsert.Close;
    FQueryInsert.SQL.Text :=
      'INSERT INTO USERS (USERNAME, EMAIL, PWDHASH, PWDSALT) ' +
      'VALUES (:USERNAME, :EMAIL, :PWDHASH, :PWDSALT)';
    FQueryInsert.ParamByName('USERNAME').AsString := Trim(FUsername);
    FQueryInsert.ParamByName('EMAIL').AsString := Trim(FEmail);
    FQueryInsert.ParamByName('PWDHASH').AsString := Hash;
    FQueryInsert.ParamByName('PWDSALT').AsString := Salt;
    FQueryInsert.ExecSQL;

    // --- Retrieve the new user's ID safely ---
    FQueryCheckExists.Close;
    FQueryCheckExists.SQL.Text := 'SELECT ID FROM USERS WHERE USERNAME = :USERNAME';
    FQueryCheckExists.ParamByName('USERNAME').AsString := Trim(FUsername);
    FQueryCheckExists.Open;
    if not FQueryCheckExists.IsEmpty then
      FUserID := FQueryCheckExists.FieldByName('ID').AsInteger
    else
      FUserID := 0;

    dmMain.cDatenbank.Commit;
    Result := True;
  except
    on E: Exception do
      FLastError := E.Message;
  end;
end;


{ Validate credentials }
function TUserObject.ValidateCredentials(const AUsername, APassword: string): Boolean;
var
  StoredHash, StoredSalt, ComputedHash: string;
begin
  Result := False;
  FLastError := '';
  try
    FQueryLogin.Close;
    FQueryLogin.ParamByName('USERNAME').AsString := Trim(AUsername);
    FQueryLogin.Open;

    if FQueryLogin.IsEmpty then
    begin
      FLastError := 'User not found';
      Exit(False);
    end;

    StoredHash := FQueryLogin.FieldByName('PWDHASH').AsString;
    StoredSalt := FQueryLogin.FieldByName('PWDSALT').AsString;

    // Compute hash for debug
    ComputedHash := CreatePasswordHash(APassword, StoredSalt);

    // --- Debug message ---
    ShowMessage('Password: ' + APassword + sLineBreak +
                'Salt: ' + StoredSalt + sLineBreak +
                'Computed Hash: ' + ComputedHash + sLineBreak +
                'Stored Hash: ' + StoredHash);

    // --- Verify password using salted hash ---
    if UpperCase(ComputedHash) = UpperCase(StoredHash) then
      Result := True
    else
      FLastError := 'Invalid password';

  except
    on E: Exception do
    begin
      HandleDatabaseError(E);
      Result := False;
    end;
  end;
end;

end.
