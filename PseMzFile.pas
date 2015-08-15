unit PseMzFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile, PseSection,
  PseExportTable, PseImportTable, PseCmn, PseMz;

type
	TExeHeader = record
		Signature: Word;
  end;

  // http://www.delorie.com/djgpp/doc/exe/
	TPseMzFile = class(TPseFile)
  private
    FExeHeader: TExeHeader;
  public
    function LoadFromStream(Stream: TStream): boolean; override;
    function GetFriendlyName: string; override;
    function GetArch: TPseArch; override;
    function GetMode: TPseMode; override;

    function GetEntryPoint: UInt64; override;
    function GetFirstAddr: UInt64; override;

    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); override;
	end;

implementation

uses
	Math;

function TPseMzFile.LoadFromStream(Stream: TStream): boolean;
begin
  Result := inherited;
  if Result then begin
    FStream.Position := 0;

  end;

  // Not implemented
  Result := false;
end;

function TPseMzFile.GetEntryPoint: UInt64;
begin
  Result := 0;
end;

function TPseMzFile.GetFirstAddr: UInt64;
begin
  Result := 0;
end;

procedure TPseMzFile.SaveSectionToStream(const ASection: integer; Stream: TStream);
var
  sec: TPseSection;
	o, s: Int64;
begin
  sec := FSections[ASection];
  o := sec.Address;
  FStream.Position := o;
  s := Min(Int64(sec.Size), Int64(FStream.Size - o));
  Stream.CopyFrom(FStream, s);
end;

function TPseMzFile.GetArch: TPseArch;
begin
  Result := pseaX86;
end;

function TPseMzFile.GetMode: TPseMode;
begin
  Result := [psem16];
end;

function TPseMzFile.GetFriendlyName: string;
begin
  Result := 'MZ16';
end;

initialization
//  TPseFile.RegisterFile(TPseMzFile);

end.
