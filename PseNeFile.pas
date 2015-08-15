unit PseNeFile;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, PseFile, PseSection,
  PseImportTable, PseCmn, PseMz,
{$ifdef FPC}
  fgl
{$else}
  Generics.Collections
{$endif}
  ;

const
	NOAUTODATA     = $0000;
  SINGLEDATA     = $0001;
  MULTIPLEDATA   = $0002;
  ERRORS         = $2000;
  LIBRARY_MODULE = $8000;

  EXETYPE_UNKNOWN = $0;
  EXETYPE_OS2     = $1;
  EXETYPE_WINDOWS = $2;
  EXETYPE_DOS40   = $3;
  EXETYPE_WIN386  = $4;
  EXETYPE_BOSS    = $5;

  SEGMENTGLAG_TYPE_MASK = $0007;
	SEGMENTGLAG_CODE      = $0000;
  SEGMENTGLAG_DATA      = $0001;
  SEGMENTGLAG_MOVEABLE  = $0010;
  SEGMENTGLAG_PRELOAD   = $0040;
  SEGMENTGLAG_RELOCINFO = $0100;
  SEGMENTGLAG_DISCARD   = $F000;

  RESTABLEFLAG_MOVEABLE = $0010;
	RESTABLEFLAG_PURE     = $0020;
  RESTABLEFLAG_PRELOAD  = $0040;

type
	_SEGMENTED_EXE_HEADER = record
		Signature: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    EntryTableFileOffset: Word;
    EntryTableSize: Word;
    Checksum: Cardinal;
    Flags: Word;
    SegmentNumber: Word;
    HeapInitialSize: Word;
    StackInitialSize: Word;
    SegmentNumberOffsetCSIP: Cardinal;
    SegmentNumberOffsetSSSP: Cardinal;
    SegmentNumberOfElements: Word;
    ModuleReferenceNumberEntries: Word;
    NonResidentTableSize: Word;
    SegmentTableFileOffset: Word;
    ResourceTableFileOffset: Word;
    ResidentNameTableFileOffset: Word;
    ModulReferenceTableFileOffset: Word;
    ImportNamesTableFileOffset: Word;
    NonResidentNameTableFileOffset: Cardinal;
    NumberOfMoveableEntries: Word;
    SectorAlignmentShiftCount: Word;
    NumberOfResourceEntries: Word;
    ExecuteableType: Byte;
    OS2EXEFlags: Byte;
    RetThunkOffset: Word;
    SegRefThunksOff: Word;
    MinCodeSwap: Word;
    ExpectedWinVer: array[0..1] of Byte;                                        //Expected windows version (minor first)
  end;
  TSegmentedExeHeader = _SEGMENTED_EXE_HEADER;

  _EXE_SEGMENTHEADER = record
  	Offset: Word;
    Size: Word;
    Flags: Word;
    MinAllocSize: Word;
  end;
  TExeSegmentHeader = _EXE_SEGMENTHEADER;

  _RESIDENT_NAME_TABLE_ENTRY = record
  	Size: Byte;
    Name: Byte;
    Ordinal: Word;
  end;
  TResidentNameTableEntry = _RESIDENT_NAME_TABLE_ENTRY;

  _IMPORTED_NAME_TABLE_ENTRY = record
  	Size: Byte;
    Name: Byte;
  end;
  TImportedNameTableEntry = _IMPORTED_NAME_TABLE_ENTRY;

  _RESOURCE_BLOCK = record
  	TypeId: Word;
    Count: Word;
    Reserved: Cardinal;
    Table: record
    	FileOffset: Word;
      Length: Word;
      Flag: Word;
      ResourceId: Word;
      Reserved: Cardinal;
    end;
  end;
  TResourceBlock = _RESOURCE_BLOCK;

  _RESOURCE_TABLE_ENTRY = record
  	AlignShift: Word;
    Block: TResourceBlock;
    SizeOfTypeName: Byte;
    Text: Byte;
  end;
  TResourceTableEntry = _RESOURCE_TABLE_ENTRY;

  {
    Windows NE files.

    16 Bit Windows EXE file.

    References

    Micosoft. Executeable-file Header Format. Microsoft, February 1999.
    <ftp://ftp.microsoft.com/MISC1/DEVELOPR/WIN_DK/KB/Q65/1/22.TXT>

    <http://www.nondot.org/sabre/os/files/Executables/EXE-3.1.txt>

    <http://wiki.osdev.org/NE>

    <http://www.fileformat.info/format/exe/corion-ne.htm>
  }
	TPseNeFile = class(TPseFile)
  private
    FDosHeader: TImageDosHeader;
    FExeHeader: TSegmentedExeHeader;
    FExeHeaderOffset: Word;
    procedure ReadSections;
    procedure ReadImports;
    procedure ReadExports;
    procedure ReadResources;
	public
    function LoadFromStream(Stream: TStream): boolean; override;
    function GetFriendlyName: string; override;
    function GetArch: TPseArch; override;
    function GetMode: TPseMode; override;

    function GetEntryPoint: UInt64; override;
    function GetFirstAddr: UInt64; override;

    procedure SaveSectionToStream(const ASection: integer; Stream: TStream); override;

    property DosHeader: TImageDosHeader read FDosHeader;
    property ExeHeader: TSegmentedExeHeader read FExeHeader;
  end;

function GetFlagsString(const AFlags: Word): string;
function GetExeTypeString(const AType: Byte): string;
function GetSecCharacteristicsString(const AFlags: Word): string;

implementation

uses
	Math;

const
  DOS_HEADER_MZ = ((Ord('Z') shl 8) + Ord('M'));
  EXE_HEADER_NE = ((Ord('E') shl 8) + Ord('N'));

function GetSecCharacteristicsString(const AFlags: Word): string;
begin
	Result := '';
	if (AFlags and SEGMENTGLAG_CODE) = SEGMENTGLAG_CODE then
    Result := Result + 'CODE | ';
	if (AFlags and SEGMENTGLAG_DATA) = SEGMENTGLAG_DATA then
    Result := Result + 'DATA | ';
	if (AFlags and SEGMENTGLAG_MOVEABLE) = SEGMENTGLAG_MOVEABLE then
    Result := Result + 'MOVEABLE | ';
	if (AFlags and SEGMENTGLAG_PRELOAD) = SEGMENTGLAG_PRELOAD then
    Result := Result + 'PRELOAD | ';
	if (AFlags and SEGMENTGLAG_RELOCINFO) = SEGMENTGLAG_RELOCINFO then
    Result := Result + 'RELOCINFO | ';
	if (AFlags and SEGMENTGLAG_DISCARD) = SEGMENTGLAG_DISCARD then
    Result := Result + 'DISCARD | ';

  if Result <> '' then
    Delete(Result, Length(Result) - 2, MaxInt);
end;

function GetFlagsString(const AFlags: Word): string;
begin
	Result := '';
	if (AFlags and NOAUTODATA) = NOAUTODATA then
    Result := Result + 'NOAUTODATA | ';
	if (AFlags and SINGLEDATA) = SINGLEDATA then
    Result := Result + 'SINGLEDATA | ';
	if (AFlags and MULTIPLEDATA) = MULTIPLEDATA then
    Result := Result + 'MULTIPLEDATA | ';
	if (AFlags and ERRORS) = ERRORS then
    Result := Result + 'ERRORS | ';
	if (AFlags and LIBRARY_MODULE) = LIBRARY_MODULE then
    Result := Result + 'LIBRARY_MODULE | ';

  if Result <> '' then
    Delete(Result, Length(Result) - 2, MaxInt);
end;

function GetExeTypeString(const AType: Byte): string;
begin
  case AType of
  	EXETYPE_UNKNOWN: Result := 'Unknown';
    EXETYPE_OS2: Result := 'OS/2';
    EXETYPE_WINDOWS: Result := 'Windows';
    EXETYPE_DOS40: Result := 'MS-DOS 4.0';
    EXETYPE_WIN386: Result := 'Windows 386';
    EXETYPE_BOSS: Result := 'BOSS';
  else
  	Result := 'Unknown';
  end;
end;

function TPseNeFile.LoadFromStream(Stream: TStream): boolean;
begin
  Result := inherited;
  if Result then begin
    FStream.Position := 0;
    if (FStream.Read(FDosHeader, SizeOf(TImageDosHeader)) <> SizeOf(TImageDosHeader)) then
      Exit(false);
    if FDosHeader.e_magic <> DOS_HEADER_MZ then
      Exit(false);

    // Offset of EXE header
    FStream.Seek($3c, soFromBeginning);
    FStream.Read(FExeHeaderOffset, SizeOf(Word));
    FStream.Seek(FExeHeaderOffset, soFromBeginning);
    if (FStream.Read(FExeHeader, SizeOf(TSegmentedExeHeader)) <> SizeOf(TSegmentedExeHeader)) then
      Exit(false);
    if FExeHeader.Signature <> EXE_HEADER_NE then
    	Exit(false);

    ReadSections;
    ReadResources;
    ReadExports;
    ReadImports;
		Result := true;
  end;
end;

procedure TPseNeFile.ReadResources;
var
	entry: TResourceTableEntry;
begin
  // RESOURCE TABLE
  FStream.Seek(FExeHeader.ResourceTableFileOffset + FExeHeaderOffset, soFromBeginning);
  if (FStream.Read(entry, SizeOf(TResourceTableEntry)) <> SizeOf(TResourceTableEntry)) then
    Exit;
  while entry.Block.TypeId <> 0 do begin
    if (FStream.Read(entry, SizeOf(TResourceTableEntry)) <> SizeOf(TResourceTableEntry)) then
      Break;

  end;

end;

procedure TPseNeFile.ReadExports;
begin
   // RESIDENT-NAME TABLE
   FExports.Clear;
end;

procedure TPseNeFile.ReadImports;
var
	i: integer;
  offset: Word;
  offsets: {$ifdef FPC}TFPGList{$else}TList{$endif}<Word>;
  next_offset: Word;
  string_len: Byte;
  name: array[0..MAXBYTE-1] of AnsiChar;
  import_obj: TPseImport;
  imp_api: TPseApi;
begin
	FImports.Clear;
  FStream.Seek(FExeHeader.ModulReferenceTableFileOffset + FExeHeaderOffset, soFromBeginning);
  offsets := {$ifdef FPC}TFPGList{$else}TList{$endif}<Word>.Create;
  try
  	// Each entry contains an offset for the module-name string within the imported-
		// names table; each entry is 2 bytes long.
    for i := 0 to FExeHeader.ModuleReferenceNumberEntries - 1 do begin
    	// Offset within Imported Names Table to referenced module name
      // string.
			FStream.Read(offset, SizeOf(Word));
      offsets.Add(offset);
    end;

		for i := 0 to offsets.Count - 1 do begin
    	// This table contains the names of modules and procedures that are imported
      // by the executable file. Each entry is composed of a 1-byte field that
      // contains the length of the string, followed by any number of characters.
      // The strings are not null-terminated and are case sensitive.
		  FStream.Seek(FExeHeader.ImportNamesTableFileOffset + FExeHeaderOffset + offsets[i], soFromBeginning);
			FStream.Read(string_len, SizeOf(Byte));
      FillChar(name, MAXBYTE, 0);
      FStream.Read(name, string_len);
      import_obj := FImports.New;
      import_obj.DllName := string(StrPas(PAnsiChar(@name)));
      if i < offsets.Count - 1 then
      	next_offset := FExeHeader.ImportNamesTableFileOffset + FExeHeaderOffset + offsets[i+1]
      else
				next_offset := FExeHeader.EntryTableFileOffset + FExeHeaderOffset;

      while FStream.Position < next_offset do begin
        FStream.Read(string_len, SizeOf(Byte));
        FillChar(name, MAXBYTE, 0);
        FStream.Read(name, string_len);
        imp_api := import_obj.New;
	      imp_api.Name := string(StrPas(PAnsiChar(@name)));
      end;

    end;
  finally
    offsets.Free;
  end;
end;

procedure TPseNeFile.ReadSections;
var
	i: integer;
  seg_header: TExeSegmentHeader;
  sec: TPseSection;
  attribs: TSectionAttribs;
begin
  FSections.Clear;
  FStream.Seek(FExeHeader.SegmentTableFileOffset + FExeHeaderOffset, soFromBeginning);
	for i := 0 to FExeHeader.SegmentNumber - 1 do begin
    if (FStream.Read(seg_header, SizeOf(TExeSegmentHeader)) <> SizeOf(TExeSegmentHeader)) then
      Break;
    attribs := [];
		sec := FSections.New;
    sec.Name := Format('Segment %d', [i+1]);
    sec.Address := seg_header.Offset;
    sec.FileOffset := seg_header.Offset;
    if seg_header.Size <> 0 then
	    sec.Size := seg_header.Size
    else
    	sec.Size := 64 * 1024;                                                    // Zero means 64K.
    sec.OrigAttribs := seg_header.Flags;

    if (seg_header.Flags and SEGMENTGLAG_CODE) = SEGMENTGLAG_CODE then begin
      Include(attribs, saCode);
      Include(attribs, saExecuteable);
    end;
    if (seg_header.Flags and SEGMENTGLAG_DATA) = SEGMENTGLAG_DATA then begin
      Include(attribs, saData);
      if (seg_header.Flags and SEGMENTGLAG_PRELOAD) = SEGMENTGLAG_PRELOAD then
	      Include(attribs, saReadable);
    end;
		sec.Attribs := attribs;
  end;
end;

function TPseNeFile.GetEntryPoint: UInt64;
begin
  Result := FExeHeader.SegmentNumberOffsetCSIP mod 65536;
end;

function TPseNeFile.GetFirstAddr: UInt64;
begin
  Result := 0;
end;

procedure TPseNeFile.SaveSectionToStream(const ASection: integer; Stream: TStream);
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

function TPseNeFile.GetArch: TPseArch;
begin
  Result := pseaX86;
end;

function TPseNeFile.GetMode: TPseMode;
begin
  Result := [psem16];
end;

function TPseNeFile.GetFriendlyName: string;
begin
  Result := 'NE16';
end;

initialization

end.
