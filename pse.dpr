program pse;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  SysUtils,
  Classes,
  PseDebugInfo in 'PseDebugInfo.pas',
  PseElf in 'PseElf.pas',
  PseElfFile in 'PseElfFile.pas',
  PseExportTable in 'PseExportTable.pas',
  PseFile in 'PseFile.pas',
  PseImportTable in 'PseImportTable.pas',
  PseLibFile in 'PseLibFile.pas',
  PseMapFileReader in 'PseMapFileReader.pas',
  PseMzFile in 'PseMzFile.pas',
  PseNeFile in 'PseNeFile.pas',
  PseObjFile in 'PseObjFile.pas',
  PsePe in 'PsePe.pas',
  PsePeFile in 'PsePeFile.pas',
  PseRawFile in 'PseRawFile.pas',
  PseSection in 'PseSection.pas',
  PseCmn in 'PseCmn.pas',
  PseMz in 'PseMz.pas';

var
  filename: string;
  PseFile: TPseFile;
  i, j: integer;
  sec: TPseSection;
  imp: TPseImport;
  api: TPseApi;
  expo: TPseExport;
begin
  // Register files we need
  TPseFile.RegisterFile(TPsePeFile);
  TPseFile.RegisterFile(TPseElfFile);
  TPseFile.RegisterFile(TPseNeFile);
  // If its not one of the above load it as raw file
  TPseFile.RegisterFile(TPseRawFile);

  if ParamCount = 0 then begin
    WriteLn('pse <filename>');
    Halt(1);
  end;
  filename := ParamStr(1);
  if not FileExists(filename) then begin
    WriteLn(Format('File %s not found', [filename]));
    Halt(1);
  end;

  PseFile := TPseFile.GetInstance(filename, false);
  try
    WriteLn(PseFile.GetFriendlyName);
    WriteLn(Format('Entry point 0x%x', [PseFile.GetEntryPoint]));

    WriteLn(Format('%d Sections', [PseFile.Sections.Count]));
    for i := 0 to PseFile.Sections.Count - 1 do begin
      sec := PseFile.Sections[i];
      WriteLn(Format('%s: Address 0x%x, Size %d', [sec.Name, sec.Address, sec.Size]));
    end;

    WriteLn(Format('%d Imports', [PseFile.ImportTable.Count]));
    for i := 0 to PseFile.ImportTable.Count - 1 do begin
      imp := PseFile.ImportTable[i];
      WriteLn(Format('%s:', [imp.DllName]));
      for j := 0 to imp.Count - 1 do begin
        api := imp[j];
        WriteLn(Format('  %s: Hint %d, Address: 0x%x', [api.Name, api.Hint, api.Address]));
      end;
    end;

    WriteLn(Format('%d Exports', [PseFile.ExportTable.Count]));
    for i := 0 to PseFile.ExportTable.Count - 1 do begin
      expo := PseFile.ExportTable[i];
      WriteLn(Format('  %s: Orinal %d, Address: 0x%x', [expo.Name, expo.Ordinal, expo.Address]));
    end;

    if PseFile is TPsePeFile then begin

    end else if PseFile is TPseElfFile then begin
    end;

  finally
    PseFile.Free;
  end;
end.

