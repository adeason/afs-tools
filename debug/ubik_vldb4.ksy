# This is a Kaitai-Struct definition file for a VLDB v4 database encapsulated
# in a ubik .DB0 file.
#
# See kaitai.io for more info, or https://ide.kaitai.io to use this file to
# interactively explore a vldb v4 .DB0 file.

meta:
  id: ubik_vldb4
  file-extension: DB0
  endian: be

seq:
  - id: header
    type: ubik_hdr
    size: 0x40

  - id: vlheader
    size: 0x20418 # sizeof(vlheader)
    type: vlheader

  - id: entries
    type: entries_array
    size: vlheader.vital_header.eofptr - 0x20418

types:
  ubik_version:
    seq:
      - id: epoch
        type: u4
      - id: counter
        type: u4
  ubik_hdr:
    seq:
      - id: magic
        contents: [0x00, 0x35, 0x45, 0x45]
      - id: pad1
        type: u2
      - id: size
        contents: [0x00, 0x40]
      - id: version
        type: ubik_version

  vlheader:
    seq:
      - id: vital_header
        type: vital_vlheader
      - id: ipmappedaddr
        type: u4
        repeat: expr
        repeat-expr: 255 # MAXSERVERID+1
      - id: volnamehash
        type: u4
        repeat: expr
        repeat-expr: 8191 # HASHSIZE
      - id: volidhash
        type: volid_hash
        repeat: expr
        repeat-expr: 3 # MAXTYPES
      - id: sit
        type: u4

  vital_vlheader:
    seq:
      - id: vldbversion
        contents: [0x00, 0x00, 0x00, 0x04]
      - id: headersize
        type: s4
      - id: freeptr
        type: s4
      - id: eofptr
        type: s4
      - id: allocs
        type: s4
      - id: frees
        type: s4
      - id: maxvolumeid
        type: u4
      - id: totalentries
        type: s4
        repeat: expr
        repeat-expr: 3 # MAXTYPES

  volid_hash:
    seq:
      - id: hash
        type: u4
        repeat: expr
        repeat-expr: 8191 # HASHSIZE

  entries_array:
    seq:
      - id: entries
        type: entry
        repeat: eos

  entry:
    seq:
      - id: volumeid
        type: u4
        repeat: expr
        repeat-expr: 3

      - id: flags
        type: s4
        enum: vl4_entry_flag

      - id: body
        type:
          switch-on: flags
          cases:
            vl4_entry_flag::vlcontblock: body_mhblock
            _: body_nvlentry

  body_nvlentry:
    seq:
      - id: lockafsid
        type: s4
      - id: locktimestamp
        type: s4
      - id: cloneid
        type: u4
      - id: nextidhash
        type: u4
        repeat: expr
        repeat-expr: 3 # MAXTYPES
      - id: nextnamehash
        type: u4
      - id: name
        size: 65
      - id: servernumber
        size: 13
      - id: serverpartition
        size: 13
      - id: serverflags
        size: 13

  body_mhblock:
    seq:
      - id: ex_header
        type: mhblock_header
      - id: ex_addrentry
        type: mhblock_addrentry
        repeat: expr
        repeat-expr: 63

  mhblock_header:
    seq:
      - id: contaddrs
        type: u4
        repeat: expr
        repeat-expr: 4 # VL_MAX_ADDREXTBLKS
      - id: spares2
        type: s4
        repeat: expr
        repeat-expr: 24

  mhblock_addrentry:
    seq:
      - id: hostuuid
        size: 16
      - id: uniquifier
        type: s4
      - id: addrs
        type: ipv4_addr
        repeat: expr
        repeat-expr: 15 # VL_MAXIPADDRS_PERMH
      - id: flags
        type: u4
      - id: spares
        type: s4
        repeat: expr
        repeat-expr: 11

  ipv4_addr:
    seq:
      - id: addr
        size: 4

enums:
  vl4_entry_flag:
    0x1: vlfree
    0x2: vldeleted
    0x4: vllocked
    0x8: vlcontblock
