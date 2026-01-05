unit RegisterFormUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, Uni, UserObjectUnit;

type
  { TRegisterForm }
  TRegisterForm = class(TForm)
    btnRegister: TButton;
    btnCancel: TButton;
    chkAcceptTerms: TCheckBox;
    edtEmail: TEdit;
    edtUsername: TEdit;
    edtPassword: TEdit;
    edtConfirmPassword: TEdit;
    lblRegistorFormTitle: TLabel;
    lblRegisterStatus: TLabel;

    procedure btnCancelClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);

  private
    FUserObj: TUserObject;
    function ValidateInput: Boolean;
    function GetNewUsername: string;
  public
    constructor Create(AOwner: TComponent; AQueryCheck, AQueryInsert, AQueryLogin: TUniQuery); reintroduce;
    destructor Destroy; override;

    property NewUsername: string read GetNewUsername;
    property UserObj: TUserObject read FUserObj;
  end;

var
  RegisterForm: TRegisterForm;

implementation

{$R *.lfm}

{ Constructor / Destructor }
constructor TRegisterForm.Create(AOwner: TComponent; AQueryCheck, AQueryInsert, AQueryLogin: TUniQuery);
begin
  inherited Create(AOwner);
  FUserObj := TUserObject.Create(AQueryCheck, AQueryInsert, AQueryLogin);
end;

destructor TRegisterForm.Destroy;
begin
  FUserObj.Free;
  inherited Destroy;
end;

function TRegisterForm.GetNewUsername: string;
begin
  Result := Trim(edtUsername.Text);
end;

{ Cancel button }
procedure TRegisterForm.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

{ Register button }
procedure TRegisterForm.btnRegisterClick(Sender: TObject);

begin
  lblRegisterStatus.Caption := '';
  if not ValidateInput then Exit;

  // Set user info
  FUserObj.Username := Trim(edtUsername.Text);
  FUserObj.Email := Trim(edtEmail.Text);

  FUserObj.Password := Trim(edtPassword.Text);

  // Attempt registration
  if FUserObj.RegisterUser then
  begin
    lblRegisterStatus.Caption := 'Registration successful.';
    ModalResult := mrOK;
  end
  else
    lblRegisterStatus.Caption := 'Database error: ' + FUserObj.LastError;
end;




{ Input validation }
function TRegisterForm.ValidateInput: Boolean;
begin
  Result := False;
  if Trim(edtUsername.Text) = '' then begin lblRegisterStatus.Caption := 'Enter username'; Exit; end;
  if Trim(edtEmail.Text) = '' then begin lblRegisterStatus.Caption := 'Enter email'; Exit; end;
  if Trim(edtPassword.Text) = '' then begin lblRegisterStatus.Caption := 'Enter password'; Exit; end;
  if edtPassword.Text <> edtConfirmPassword.Text then begin lblRegisterStatus.Caption := 'Passwords do not match'; Exit; end;
  if not chkAcceptTerms.Checked then begin lblRegisterStatus.Caption := 'Accept terms'; Exit; end;
  Result := True;
end;

end.

