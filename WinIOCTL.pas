unit WinIOCTL;

// John Newbigin
// from winioctl.h

{$A+,Z+}

interface
   uses Windows;

const
   Large0 : _Large_Integer = (LowPart : 0; HighPart : 0) ;

function div2(a : LongInt; b : LongInt) : LongInt;

{   function DeviceIoControl(hDevice : THandle; dwIoControlCode : DWORD;
                           var lpInBuffer; nInBuffer : DWORD;
                           var lpOutuffer; nOutBuffer : DWORD;
                           var BytesReturned: DWORD; Overlapped : pOverlapped):BOOL; stdcall;
 }
   function DeviceIoControl(hDevice : THandle; dwIoControlCode : DWORD;
                           lpInBuffer : Pointer; nInBuffer : DWORD;
                           lpOutuffer : Pointer; nOutBuffer : DWORD;
                           var BytesReturned: DWORD; Overlapped : pOverlapped):BOOL; stdcall;

   function ReadFile2(hFile: THandle; Buffer : Pointer; nNumberOfBytesToRead: DWORD;
    var lpNumberOfBytesRead: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;
   function WriteFile2(hFile: THandle; Buffer : Pointer; nNumberOfBytesToWrite: DWORD;
    var lpNumberOfBytesWritten: DWORD; lpOverlapped: POverlapped): BOOL; stdcall;


type
  DEVICE_TYPE=DWORD;


const
  FILE_DEVICE_BEEP               = $00000001;
  FILE_DEVICE_CD_ROM             = $00000002;
  FILE_DEVICE_CD_ROM_FILE_SYSTEM = $00000003;
  FILE_DEVICE_CONTROLLER         = $00000004;
  FILE_DEVICE_DATALINK           = $00000005;
  FILE_DEVICE_DFS                = $00000006;
  FILE_DEVICE_DISK               = $00000007;
  FILE_DEVICE_DISK_FILE_SYSTEM   = $00000008;
  FILE_DEVICE_FILE_SYSTEM        = $00000009;
  FILE_DEVICE_INPORT_PORT        = $0000000a;
  FILE_DEVICE_KEYBOARD           = $0000000b;
  FILE_DEVICE_MAILSLOT           = $0000000c;
  FILE_DEVICE_MIDI_IN            = $0000000d;
  FILE_DEVICE_MIDI_OUT           = $0000000e;
  FILE_DEVICE_MOUSE              = $0000000f;
  FILE_DEVICE_MULTI_UNC_PROVIDER = $00000010;
  FILE_DEVICE_NAMED_PIPE         = $00000011;
  FILE_DEVICE_NETWORK            = $00000012;
  FILE_DEVICE_NETWORK_BROWSER    = $00000013;
  FILE_DEVICE_NETWORK_FILE_SYSTEM= $00000014;
  FILE_DEVICE_NULL               = $00000015;
  FILE_DEVICE_PARALLEL_PORT      = $00000016;
  FILE_DEVICE_PHYSICAL_NETCARD   = $00000017;
  FILE_DEVICE_PRINTER            = $00000018;
  FILE_DEVICE_SCANNER            = $00000019;
  FILE_DEVICE_SERIAL_MOUSE_PORT  = $0000001a;
  FILE_DEVICE_SERIAL_PORT        = $0000001b;
  FILE_DEVICE_SCREEN             = $0000001c;
  FILE_DEVICE_SOUND              = $0000001d;
  FILE_DEVICE_STREAMS            = $0000001e;
  FILE_DEVICE_TAPE               = $0000001f;
  FILE_DEVICE_TAPE_FILE_SYSTEM   = $00000020;
  FILE_DEVICE_TRANSPORT          = $00000021;
  FILE_DEVICE_UNKNOWN            = $00000022;
  FILE_DEVICE_VIDEO              = $00000023;
  FILE_DEVICE_VIRTUAL_DISK       = $00000024;
  FILE_DEVICE_WAVE_IN            = $00000025;
  FILE_DEVICE_WAVE_OUT           = $00000026;
  FILE_DEVICE_8042_PORT          = $00000027;
  FILE_DEVICE_NETWORK_REDIRECTOR = $00000028;
  FILE_DEVICE_BATTERY            = $00000029;
  FILE_DEVICE_BUS_EXTENDER       = $0000002a;
  FILE_DEVICE_MODEM              = $0000002b;
  FILE_DEVICE_VDM                = $0000002c;
  FILE_DEVICE_MASS_STORAGE       = $0000002d;

  IOCTL_STORAGE_BASE = FILE_DEVICE_MASS_STORAGE;
{//
// Macro definition for defining IOCTL and FSCTL function control codes.  Note
// that function codes 0-2047 are reserved for Microsoft Corporation, and
// 2048-4095 are reserved for customers.
//

#define CTL_CODE( DeviceType, Function, Method, Access ) (                 \
    ((DeviceType) << 16) | ((Access) << 14) | ((Function) << 2) | (Method) \
)

//
// Define the method codes for how buffers are passed for I/O and FS controls
//}

const
  METHOD_BUFFERED   = 0;
  METHOD_IN_DIRECT  = 1;
  METHOD_OUT_DIRECT = 2;
  METHOD_NEITHER    = 3;

//
// Define the access check value for any access
//
//
// The FILE_READ_ACCESS and FILE_WRITE_ACCESS constants are also defined in
// ntioapi.h as FILE_READ_DATA and FILE_WRITE_DATA. The values for these
// constants *MUST* always be in sync.
//

const
  FILE_ANY_ACCESS   = $00;
  FILE_READ_ACCESS  = $01;    // file & pipe
  FILE_WRITE_ACCESS = $02;    // file & pipe

// end_ntddk end_nthal end_ntifs

//
// IoControlCode values for disk devices.
//

{
#define IOCTL_DISK_BASE                 FILE_DEVICE_DISK
#define IOCTL_DISK_GET_DRIVE_GEOMETRY   CTL_CODE(IOCTL_DISK_BASE, 0x0000, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_DISK_GET_PARTITION_INFO   CTL_CODE(IOCTL_DISK_BASE, 0x0001, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_SET_PARTITION_INFO   CTL_CODE(IOCTL_DISK_BASE, 0x0002, METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS)
#define IOCTL_DISK_GET_DRIVE_LAYOUT     CTL_CODE(IOCTL_DISK_BASE, 0x0003, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_SET_DRIVE_LAYOUT     CTL_CODE(IOCTL_DISK_BASE, 0x0004, METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS)
#define IOCTL_DISK_VERIFY               CTL_CODE(IOCTL_DISK_BASE, 0x0005, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_DISK_FORMAT_TRACKS        CTL_CODE(IOCTL_DISK_BASE, 0x0006, METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS)
#define IOCTL_DISK_REASSIGN_BLOCKS      CTL_CODE(IOCTL_DISK_BASE, 0x0007, METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS)
#define IOCTL_DISK_PERFORMANCE          CTL_CODE(IOCTL_DISK_BASE, 0x0008, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_DISK_IS_WRITABLE          CTL_CODE(IOCTL_DISK_BASE, 0x0009, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_DISK_LOGGING              CTL_CODE(IOCTL_DISK_BASE, 0x000a, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define IOCTL_DISK_FORMAT_TRACKS_EX     CTL_CODE(IOCTL_DISK_BASE, 0x000b, METHOD_BUFFERED, FILE_READ_ACCESS | FILE_WRITE_ACCESS)
}
//
// The following device control codes are common for all class drivers.  The
// functions codes defined here must match all of the other class drivers.
//

{
#define IOCTL_DISK_CHECK_VERIFY     CTL_CODE(IOCTL_DISK_BASE, 0x0200, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_MEDIA_REMOVAL    CTL_CODE(IOCTL_DISK_BASE, 0x0201, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_EJECT_MEDIA      CTL_CODE(IOCTL_DISK_BASE, 0x0202, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_LOAD_MEDIA       CTL_CODE(IOCTL_DISK_BASE, 0x0203, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_RESERVE          CTL_CODE(IOCTL_DISK_BASE, 0x0204, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_RELEASE          CTL_CODE(IOCTL_DISK_BASE, 0x0205, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_FIND_NEW_DEVICES CTL_CODE(IOCTL_DISK_BASE, 0x0206, METHOD_BUFFERED, FILE_READ_ACCESS)
#define IOCTL_DISK_REMOVE_DEVICE    CTL_CODE(IOCTL_DISK_BASE, 0x0207, METHOD_BUFFERED, FILE_READ_ACCESS)

#define IOCTL_DISK_GET_MEDIA_TYPES CTL_CODE(IOCTL_DISK_BASE, 0x0300, METHOD_BUFFERED, FILE_ANY_ACCESS)
}

//
// Define the partition types returnable by known disk drivers.
//

const
  PARTITION_ENTRY_UNUSED       = $00;      // Entry unused
  PARTITION_FAT_12             = $01;      // 12-bit FAT entries
  PARTITION_XENIX_1            = $02;      // Xenix
  PARTITION_XENIX_2            = $03;      // Xenix
  PARTITION_FAT_16             = $04;      // 16-bit FAT entries
  PARTITION_EXTENDED           = $05;      // Extended partition entry
  PARTITION_HUGE               = $06;      // Huge partition MS-DOS V4
  PARTITION_IFS                = $07;      // IFS Partition
  PARTITION_UNIX               = $63;      // Unix
  PARTITION_LINUX_SWAP         = $82;      // Linux Swap Partition
  PARTITION_LINUX              = $83;      // Linux Native Partition

  VALID_NTFT                   = $C0;      // NTFT uses high order bits

  PARTITION_EXTENDED_LINUX     = $85;      // Extended partition entry
  PARTITION_EXTENDED_WIN98     = $0f;      // Extended partition entry

  EXTENDED_PARTITIONS  = [ PARTITION_EXTENDED, PARTITION_EXTENDED_LINUX, PARTITION_EXTENDED_WIN98 ]; 

//
// The following macro is used to determine which partitions should be
// assigned drive letters.
//

//++
//
// BOOLEAN
// IsRecognizedPartition(
//     IN DWORD PartitionType
//     )
//
// Routine Description:
//
//     This macro is used to determine to which partitions drive letters
//     should be assigned.
//
// Arguments:
//
//     PartitionType - Supplies the type of the partition being examined.
//
// Return Value:
//
//     The return value is TRUE if the partition type is recognized,
//     otherwise FALSE is returned.
//
//--
{
#define IsRecognizedPartition( PartitionType ) (       \
    (((PartitionType & ~0xC0) == PARTITION_FAT_12) ||  \
     ((PartitionType & ~0xC0) == PARTITION_FAT_16) ||  \
     ((PartitionType & ~0xC0) == PARTITION_IFS)    ||  \
     ((PartitionType & ~0xC0) == PARTITION_HUGE)) )
}
//
// The high bit of the partition type code indicates that a partition
// is part of an NTFT mirror or striped array.
//

  PARTITION_NTFT  = $80;     // NTFT partition

//
// Define the media types supported by the driver.
//

{typedef enum _MEDIA_TYPE
    Unknown,                // Format is unknown
    F5_1Pt2_512,            // 5.25", 1.2MB,  512 bytes/sector
    F3_1Pt44_512,           // 3.5",  1.44MB, 512 bytes/sector
    F3_2Pt88_512,           // 3.5",  2.88MB, 512 bytes/sector
    F3_20Pt8_512,           // 3.5",  20.8MB, 512 bytes/sector
    F3_720_512,             // 3.5",  720KB,  512 bytes/sector
    F5_360_512,             // 5.25", 360KB,  512 bytes/sector
    F5_320_512,             // 5.25", 320KB,  512 bytes/sector
    F5_320_1024,            // 5.25", 320KB,  1024 bytes/sector
    F5_180_512,             // 5.25", 180KB,  512 bytes/sector
    F5_160_512,             // 5.25", 160KB,  512 bytes/sector
    RemovableMedia,         // Removable media other than floppy
    FixedMedia              // Fixed hard disk media
 MEDIA_TYPE, *PMEDIA_TYPE;}

const
  Media_Type_Unknown       = 0;        // Format is unknown
  Media_Type_F5_1Pt2_512   = 1;        // 5.25", 1.2MB,  512 bytes/sector
  Media_Type_F3_1Pt44_512  = 2;        // 3.5",  1.44MB, 512 bytes/sector
  Media_Type_F3_2Pt88_512  = 3;        // 3.5",  2.88MB, 512 bytes/sector
  Media_Type_F3_20Pt8_512  = 4;        // 3.5",  20.8MB, 512 bytes/sector
  Media_Type_F3_720_512    = 5;        // 3.5",  720KB,  512 bytes/sector
  Media_Type_F5_360_512    = 6;        // 5.25", 360KB,  512 bytes/sector
  Media_Type_F5_320_512    = 7;        // 5.25", 320KB,  512 bytes/sector
  Media_Type_F5_320_1024   = 8;        // 5.25", 320KB,  1024 bytes/sector
  Media_Type_F5_180_512    = 9;        // 5.25", 180KB,  512 bytes/sector
  Media_Type_F5_160_512    = 10;       // 5.25", 160KB,  512 bytes/sector
  Media_Type_RemovableMedia= 11;       // Removable media other than floppy
  Media_Type_FixedMedia    = 12;       // Fixed hard disk media

//
// Define the input buffer structure for the driver, when
// it is called with IOCTL_DISK_FORMAT_TRACKS.
//

type
  TFORMAT_PARAMETERS = record
    MediaType           : DWORD;
    StartCylinderNumber : DWORD ;
    EndCylinderNumber   : DWORD ;
    StartHeadNumber     : DWORD ;
    EndHeadNumber       : DWORD ;
  end;
  PFORMAT_PARAMETERS = ^TFORMAT_PARAMETERS;

//
// Define the BAD_TRACK_NUMBER type. An array of elements of this type is
// returned by the driver on IOCTL_DISK_FORMAT_TRACKS requests, to indicate
// what tracks were bad during formatting. The length of that array is
// reported in the `Information' field of the I/O Status Block.
//

//typedef WORD   BAD_TRACK_NUMBER;
//typedef WORD   *PBAD_TRACK_NUMBER;

//
// Define the input buffer structure for the driver, when
// it is called with IOCTL_DISK_FORMAT_TRACKS_EX.
//

type
  TFORMAT_EX_PARAMETERS = record
   MediaType : DWORD;
   StartCylinderNumber : DWORD;
   EndCylinderNumber : DWORD;
   StartHeadNumber : DWORD;
   EndHeadNumber   : DWORD;
   FormatGapLength : WORD;
   SectorsPerTrack : WORD;
   SectorNumber    : array[0..0] of WORD;
  end;


//
// The following structure is returned on an IOCTL_DISK_GET_DRIVE_GEOMETRY
// request and an array of them is returned on an IOCTL_DISK_GET_MEDIA_TYPES
// request.
//

type
  TDISK_GEOMETRY = record
    Cylinders : _LARGE_INTEGER;//TLargeInteger ;//LARGE_INTEGER ;
    MediaType : DWord;
    TracksPerCylinder : DWORD;
    SectorsPerTrack : DWORD;
    BytesPerSector : DWORD;
  end;
  PDISK_GEOMETRY = ^TDISK_GEOMETRY;

//
// The following structure is returned on an IOCTL_DISK_GET_PARTITION_INFO
// and an IOCTL_DISK_GET_DRIVE_LAYOUT request.  It is also used in a request
// to change the drive layout, IOCTL_DISK_SET_DRIVE_LAYOUT.
//
  TPARTITION_INFORMATION = record
    StartingOffset      : _LARGE_INTEGER;//TLargeInteger;
    PartitionLength     : _LARGE_INTEGER;//TLargeInteger;
    HiddenSectors       : DWORD;
    PartitionNumber     : DWORD;
    PartitionType       : BYTE;
    BootIndicator       : BOOLEAN;
    RecognizedPartition : BOOLEAN;
    RewritePartition    : BOOLEAN;
   end;
   PPARTITION_INFORMATION = ^TPARTITION_INFORMATION;

//
// The following structure is used to change the partition type of a
// specified disk partition using an IOCTL_DISK_SET_PARTITION_INFO
// request.
//

  TSET_PARTITION_INFORMATION = record
    PartitionType : BYTE;
  end;
  PSET_PARTITION_INFORMATION = ^TSET_PARTITION_INFORMATION;

//
// The following structures is returned on an IOCTL_DISK_GET_DRIVE_LAYOUT
// request and given as input to an IOCTL_DISK_SET_DRIVE_LAYOUT request.
//

  TDRIVE_LAYOUT_INFORMATION = record
    PartitionCount : DWORD;
    Signature      : DWORD;
    PartitionEntry : array[0..0] of TPARTITION_INFORMATION;
  end;
  PDRIVE_LAYOUT_INFORMATION = ^TDRIVE_LAYOUT_INFORMATION;

//
// The following structure is passed in on an IOCTL_DISK_VERIFY request.
// The offset and length parameters are both given in bytes.
//
{$ifdef xxx}
typedef struct _VERIFY_INFORMATION {
    LARGE_INTEGER StartingOffset;
    DWORD Length;
} VERIFY_INFORMATION, *PVERIFY_INFORMATION;

//
// The following structure is passed in on an IOCTL_DISK_REASSIGN_BLOCKS
// request.
//

typedef struct _REASSIGN_BLOCKS {
    WORD   Reserved;
    WORD   Count;
    DWORD BlockNumber[1];
} REASSIGN_BLOCKS, *PREASSIGN_BLOCKS;

//
// IOCTL_DISK_MEDIA_REMOVAL disables the mechanism
// on a SCSI device that ejects media. This function
// may or may not be supported on SCSI devices that
// support removable media.
//
// TRUE means prevent media from being removed.
// FALSE means allow media removal.
//

typedef struct _PREVENT_MEDIA_REMOVAL {
    BOOLEAN PreventMediaRemoval;
} PREVENT_MEDIA_REMOVAL, *PPREVENT_MEDIA_REMOVAL;

///////////////////////////////////////////////////////
//                                                   //
// The following structures define disk debugging    //
// capabilities. The IOCTLs are directed to one of   //
// the two disk filter drivers.                      //
//                                                   //
// DISKPERF is a utilty for collecting disk request  //
// statistics.                                       //
//                                                   //
// SIMBAD is a utility for injecting faults in       //
// IO requests to disks.                             //
//                                                   //
///////////////////////////////////////////////////////

//
// The following structure is exchanged on an IOCTL_DISK_GET_PERFORMANCE
// request. This ioctl collects summary disk request statistics used
// in measuring performance.
//

typedef struct _DISK_PERFORMANCE {
        LARGE_INTEGER BytesRead;
        LARGE_INTEGER BytesWritten;
        LARGE_INTEGER ReadTime;
        LARGE_INTEGER WriteTime;
        DWORD ReadCount;
        DWORD WriteCount;
        DWORD QueueDepth;
} DISK_PERFORMANCE, *PDISK_PERFORMANCE;

//
// This structure defines the disk logging record. When disk logging
// is enabled, one of these is written to an internal buffer for each
// disk request.
//

typedef struct _DISK_RECORD {
   LARGE_INTEGER ByteOffset;
   LARGE_INTEGER StartTime;
   LARGE_INTEGER EndTime;
   PVOID VirtualAddress;
   DWORD NumberOfBytes;
   BYTE  DeviceNumber;
   BOOLEAN ReadRequest;
} DISK_RECORD, *PDISK_RECORD;

//
// The following structure is exchanged on an IOCTL_DISK_LOG request.
// Not all fields are valid with each function type.
//

typedef struct _DISK_LOGGING {
    BYTE  Function;
    PVOID BufferAddress;
    DWORD BufferSize;
} DISK_LOGGING, *PDISK_LOGGING;

//
// Disk logging functions
//
// Start disk logging. Only the Function and BufferSize fields are valid.
//

#define DISK_LOGGING_START    0

//
// Stop disk logging. Only the Function field is valid.
//

#define DISK_LOGGING_STOP     1

//
// Return disk log. All fields are valid. Data will be copied from internal
// buffer to buffer specified for the number of bytes requested.
//

#define DISK_LOGGING_DUMP     2

//
// DISK BINNING
//
// DISKPERF will keep counters for IO that falls in each of these ranges.
// The application determines the number and size of the ranges.
// Joe Lin wanted me to keep it flexible as possible, for instance, IO
// sizes are interesting in ranges like 0-4096, 4097-16384, 16385-65536, 65537+.
//

#define DISK_BINNING          3

//
// Bin types
//

typedef enum _BIN_TYPES {
    RequestSize,
    RequestLocation
} BIN_TYPES;

//
// Bin ranges
//

typedef struct _BIN_RANGE {
    LARGE_INTEGER StartValue;
    LARGE_INTEGER Length;
} BIN_RANGE, *PBIN_RANGE;

//
// Bin definition
//

typedef struct _PERF_BIN {
    DWORD NumberOfBins;
    DWORD TypeOfBin;
    BIN_RANGE BinsRanges[1];
} PERF_BIN, *PPERF_BIN ;

//
// Bin count
//

typedef struct _BIN_COUNT {
    BIN_RANGE BinRange;
    DWORD BinCount;
} BIN_COUNT, *PBIN_COUNT;

//
// Bin results
//

typedef struct _BIN_RESULTS {
    DWORD NumberOfBins;
    BIN_COUNT BinCounts[1];
} BIN_RESULTS, *PBIN_RESULTS;


#define IOCTL_SERIAL_LSRMST_INSERT      CTL_CODE(FILE_DEVICE_SERIAL_PORT,31,METHOD_BUFFERED,FILE_ANY_ACCESS)


//
// The following values follow the escape designator in the
// data stream if the LSRMST_INSERT mode has been turned on.
//
#define SERIAL_LSRMST_ESCAPE     ((BYTE )0x00)

//
// Following this value is the contents of the line status
// register, and then the character in the RX hardware when
// the line status register was encountered.
//
#define SERIAL_LSRMST_LSR_DATA   ((BYTE )0x01)

//
// Following this value is the contents of the line status
// register.  No error character follows
//
#define SERIAL_LSRMST_LSR_NODATA ((BYTE )0x02)

//
// Following this value is the contents of the modem status
// register.
//
#define SERIAL_LSRMST_MST        ((BYTE )0x03)


#define FSCTL_LOCK_VOLUME               CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 6, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define FSCTL_UNLOCK_VOLUME             CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 7, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define FSCTL_DISMOUNT_VOLUME           CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 8, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define FSCTL_MOUNT_DBLS_VOLUME         CTL_CODE(FILE_DEVICE_FILE_SYSTEM,13, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define FSCTL_GET_COMPRESSION           CTL_CODE(FILE_DEVICE_FILE_SYSTEM,15, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define FSCTL_SET_COMPRESSION           CTL_CODE(FILE_DEVICE_FILE_SYSTEM,16, METHOD_BUFFERED, FILE_ANY_ACCESS)
#define FSCTL_READ_COMPRESSION          CTL_CODE(FILE_DEVICE_FILE_SYSTEM,17, METHOD_NEITHER,  FILE_ANY_ACCESS)
#define FSCTL_WRITE_COMPRESSION         CTL_CODE(FILE_DEVICE_FILE_SYSTEM,18, METHOD_NEITHER,  FILE_ANY_ACCESS)


#endif // _WINIOCTL_
{$endif}

function CtlCode(DeviceType : DWORD; Func : DWord; Method : DWord; Access : DWord) : DWORD;
//#define CTL_CODE( DeviceType, Function, Method, Access ) (                 \
//    ((DeviceType) << 16) | ((Access) << 14) | ((Function) << 2) | (Method) \


function MediaDescription(Media : Integer) : String;

implementation

// like div but rounds up
function div2(a : LongInt; b : LongInt) : LongInt;
begin
   Result := a div b;
   if (a mod b) > 0 then
   begin
      Inc(Result);
   end;
end;



   function CtlCode(DeviceType : DWORD; Func : DWord; Method : DWord; Access : DWord) : DWORD;
   begin
      result := (DeviceType shl 16) or (Access shl 14) or (Func shl 2) or (Method);
   end;

   function DeviceIoControl; external 'kernel32.dll';
   function ReadFile2; external kernel32 name 'ReadFile';
   function WriteFile2; external kernel32 name 'WriteFile';

function MediaDescription(Media : Integer) : String;
begin
   case Media of
      Media_Type_F5_1Pt2_512:  Result := '5.25, 1.2MB,  512 bytes/sector';
      Media_Type_F3_1Pt44_512: Result := '3.5,  1.44MB, 512 bytes/sector';
      Media_Type_F3_2Pt88_512: Result := '3.5,  2.88MB, 512 bytes/sector';
      Media_Type_F3_20Pt8_512: Result := '3.5,  20.8MB, 512 bytes/sector';
      Media_Type_F3_720_512:   Result := '3.5,  720KB,  512 bytes/sector';
      Media_Type_F5_360_512:   Result := '5.25, 360KB,  512 bytes/sector';
      Media_Type_F5_320_512:   Result := '5.25, 320KB,  512 bytes/sector';
      Media_Type_F5_320_1024:  Result := '5.25, 320KB,  1024 bytes/sector';
      Media_Type_F5_180_512:   Result := '5.25, 180KB,  512 bytes/sector';
      Media_Type_F5_160_512:   Result := '5.25, 160KB,  512 bytes/sector';
      Media_Type_RemovableMedia: Result := 'Removable media other than floppy';
      Media_Type_FixedMedia:   Result := 'Fixed hard disk media';
   else
      Result := 'Unknown';
   end;
end;

end.
