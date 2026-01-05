unit PasswordUtilsUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

function CreatePasswordHash(const Password: string; out Salt: string): string;
function VerifyPassword(const Password, Salt, Hash: string): Boolean;

implementation

{ Helper to compute hash with an existing salt without regenerating it }
function CreatePasswordHashWithSalt(const Password, Salt: string): string;
var
  i, j, X: Integer;
begin
  Result := '';
  j := 1;
  for i := 1 to Length(Password) do
  begin
    X := Ord(Password[i]) xor Ord(Salt[j]);
    Result := Result + IntToHex(X, 2);
    Inc(j);
    if j > Length(Salt) then
      j := 1;
  end;
end;

{ Generates a random salt (hex string) }
function GenerateSalt: string;
var
  i, B: Integer;
begin
  Randomize;
  Result := '';
  for i := 1 to 8 do
  begin
    B := Random(256);
    Result := Result + IntToHex(B, 2);
  end;
end;

{ Minimal KISS hash: XOR each char with salt bytes, output hex }
function CreatePasswordHash(const Password: string; out Salt: string): string;
begin
  { Generate a new salt }
  Salt := GenerateSalt;
  Result := CreatePasswordHashWithSalt(Password, Salt);
end;

{ Verify password by recomputing hash with provided salt }
function VerifyPassword(const Password, Salt, Hash: string): Boolean;
begin
  Result := CreatePasswordHashWithSalt(Password, Salt) = Hash;
end;

end.

