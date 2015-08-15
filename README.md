# Pascal Executeable Parser

A collection of classes and functions to prase executeable files for the Pascal
language, namely for Free Pascal and Delphi.

These are my findings trying to parse these files. Not everything is implemented yet
(e.g. Resource parsing, MZ files), and I may be wrong here and there. If you have 
improvements let me know.

## License

BSD

## Supported files

- 16 Bit DOS EXE aka NE
- 32 Bit PE
- 64 Bit PE
- 32 Bit ELF
- 64 Bit ELF

## Compatibility

OS
: Windows, Linux

Compiler
: Delphi, Free Pascal (Generics required)

## Usage

	// Register files we need
  TPseFile.RegisterFile(TPsePeFile);
  TPseFile.RegisterFile(TPseElfFile);
  TPseFile.RegisterFile(TPseNeFile);
  // If its not one of the above load it as raw file
  TPseFile.RegisterFile(TPseRawFile);

  // filename contains the name of the executable
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
      // PE specific code...
    end else if PseFile is TPseElfFile then begin
      // ELF specific code...
		end;
    
  finally
    PseFile.Free;
  end;
    
For details see `pse.dpr`.

## Screenshot

![PESP](%base_url%/content/projects/pesp-pe.png "PESP parsed a 32-bit PE DLL file")

## References

- TIS Committee. *Tool Interface Standard (TIS) Executable and Linking
    Format (ELF) Specification*. TIS Committee, 1995.
- Micosoft. *Microsoft Portable Executable and Common Object File Format
    Specification*. Microsoft, February 2013.
- Micosoft. *Executeable-file Header Format*. Microsoft, February 1999.
    <ftp://ftp.microsoft.com/MISC1/DEVELOPR/WIN_DK/KB/Q65/1/22.TXT>
- <http://www.nondot.org/sabre/os/files/Executables/EXE-3.1.txt>
- <http://wiki.osdev.org/NE>
- <http://www.fileformat.info/format/exe/corion-ne.htm>
