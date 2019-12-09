# This is a Kaitai-Struct definition file for a VLDB v5 database encapsulated
# in a ubik .DB0 file.
#
# See kaitai.io for more info, or https://ide.kaitai.io to use this file to
# interactively explore a vldb v5 .DB0 file.

meta:
  id: ubik_vldb5
  file-extension: DB0
  endian: be

seq:
  - id: header
    type: ubik_hdr
    size: 0x40

  - id: root_record
    type: root_record

  - id: records
    type: record
    size: root_record.funinfo.recsize
    repeat: eos

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

  root_record:
    seq:
      - id: tag
        contents: [0x00, 0x00, 0x00, 0x05]
      - id: val_fun
        type: value
      - id: body
        type: record_body

        # Tag takes 4 bytes, the funinfo tag/len takes 8 bytes, and the funinfo
        # payload takes another 4 bytes.
        size: funinfo.recsize - 4 - 8 - 4
    instances:
      funinfo:
        value: val_fun.body.as<value_funinfo>

  record:
    seq:
      - id: tag
        type: u4
        enum: vl5_tag
      - id: body
        type: record_body

  record_body:
    seq:
      - id: values
        type: value
        repeat: until
        # Keep parsing values until we hit the 0x00 tag, or until we don't have
        # enough space to represent another value.
        repeat-until: _.tag == vl5_tag::empty or _io.size - _io.pos < 8

  value:
    seq:
      - id: tag
        type: u4
        enum: vl5_tag
      - id: len
        type: u4
      - id: body
        size: len
        type:
          switch-on: tag
          cases:
            vl5_tag::empty: value_empty
            vl5_tag::funinfo_be: value_funinfo
            vl5_tag::eof: recno
            vl5_tag::free_ptr: recno
            vl5_tag::next_volid: volid
            vl5_tag::fs_uuid: value_fsuuid
            vl5_tag::fs_ipv4list: value_ipv4list
            vl5_tag::fileserver_list_ptr: recno
            vl5_tag::fs_recno_list: value_fs_recno_list
            vl5_tag::partition_list_ptr: recno
            vl5_tag::partition_list_val: value_partition_list
            vl5_tag::node_ptr: recno
            vl5_tag::vol_name: bytestr
            vl5_tag::vol_basic_info: value_vol_basicinfo
            vl5_tag::vol_cloneid: volid
            vl5_tag::vol_lockinfo: value_vol_lockinfo
            vl5_tag::vol_sitelist: value_vol_sitelist
            vl5_tag::vol_idtree_ptr: recno
            vl5_tag::vol_idtree_leaf: value_vol_idtree_leaf
            vl5_tag::vol_idtree_node: value_vol_idtree_node
            vl5_tag::vol_namehtree_ptr: recno
            vl5_tag::vol_namehtree_leaf: value_vol_namehtree_leaf
            vl5_tag::vol_namehtree_node: value_vol_namehtree_node
            vl5_tag::vol_namehtree_rootinfo: value_vol_namehtree_rootinfo
            vl5_tag::vol_namehtree_coll_val: value_vol_namehtree_coll

  value_empty: {}

  recno:
    seq:
      - id: recno
        type: u8

  volid:
    seq:
      - id: volid
        type: u8

  fsid:
    seq:
      - id: fsid
        type: u4

  partid:
    seq:
      - id: partid
        type: u4

  value_funinfo:
    seq:
      - id: endian
        # We only support big-endian (0x1) for now.
        contents: [0x01]
      - id: recsize_log2
        type: u1
      - id: padding
        contents: [0x00]
        repeat: expr
        repeat-expr: 2
    instances:
      recsize:
        value: 1 << recsize_log2

  value_eof:
    seq:
      - id: recno
        type: u8

  value_fsuuid:
    seq:
      - id: uuid
        size: 16

  value_ipv4list:
    seq:
      - id: len
        type: u4
      - id: val
        type: ipv4_addr
        repeat: expr
        repeat-expr: len

  ipv4_addr:
    seq:
      - id: val
        size: 4

  value_fs_recno_list:
    seq:
      - id: len
        type: u4
      - id: val
        type: fs_recno_list_item
        repeat: expr
        repeat-expr: len

  fs_recno_list_item:
    seq:
      - id: fsid
        type: fsid
      - id: recno
        type: recno

  value_partition_list:
    seq:
      - id: len
        type: u4
      - id: val
        type: partition_list_item
        repeat: expr
        repeat-expr: len

  partition_list_item:
    seq:
      - id: partid
        type: partid
      - id: fsid
        type: fsid
      - id: partnum
        type: u4

  bytestr:
    seq:
      - id: len
        type: u4
      - id: val
        size: len

      # xdr pads the end of the string so that the actual string payload is a
      # multiple of 4
      - id: padding
        size: (4 - (len % 4)) % 4

  value_vol_basicinfo:
    seq:
      - id: rwid
        type: volid
      - id: roid
        type: volid
      - id: bkid
        type: volid
      - id: vlf_backexists
        type: u4

  value_vol_lockinfo:
    seq:
      - id: locktype
        type: u4
        enum: vl5_lock
      - id: time
        type: timestamp
      - id: duration
        type: timestamp
      - id: userid
        type: u8

  timestamp:
    seq:
      - id: centins
        type: u8

  value_vol_sitelist:
    seq:
      - id: len
        type: u4
      - id: val
        type: vol_site
        repeat: expr
        repeat-expr: len

  vol_site:
    seq:
      - id: type
        type: u4
        enum: vl5_site
      - id: partid
        type: partid
      - id: flags
        type: u4

  value_vol_idtree_leaf:
    seq:
      - id: parent
        type: recno
      - id: n_keys
        type: u4
      - id: children
        type: vol_idtree_leaf_entry
        repeat: expr
        repeat-expr: n_keys

  vol_idtree_leaf_entry:
    seq:
      - id: volid
        type: volid
      - id: vlentry
        type: recno

  value_vol_idtree_node:
    seq:
      - id: parent
        type: recno
      - id: max_child
        type: recno
      - id: n_keys
        type: u4
      - id: children
        type: vol_idtree_node_entry
        repeat: expr
        repeat-expr: n_keys

  vol_idtree_node_entry:
    seq:
      - id: max_volid
        type: volid
      - id: child
        type: recno

  value_vol_namehtree_leaf:
    seq:
      - id: parent
        type: recno
      - id: n_keys
        type: u4
      - id: children
        type: vol_namehtree_leaf_entry
        repeat: expr
        repeat-expr: n_keys

  vol_namehtree_leaf_entry:
    seq:
      - id: hashval
        type: u4
      - id: value
        type: recno

  value_vol_namehtree_node:
    seq:
      - id: parent
        type: recno
      - id: max_child
        type: recno
      - id: n_keys
        type: u4
      - id: children
        type: vol_namehtree_node_entry
        repeat: expr
        repeat-expr: n_keys

  vol_namehtree_node_entry:
    seq:
      - id: max_hash
        type: u4
      - id: child
        type: recno

  value_vol_namehtree_rootinfo:
    seq:
      - id: hashfunc
        type: u4
        enum: vl5_namehtree_hashfunc

  value_vol_namehtree_coll:
    seq:
      - id: parent
        type: recno
      - id: n_entries
        type: u4
      - id: entries
        type: vol_namehtree_coll_entry
        repeat: expr
        repeat-expr: n_entries

  vol_namehtree_coll_entry:
    seq:
      - id: vlentry
        type: recno
      - id: name
        type: bytestr

enums:
  vl5_tag:
    0x00: empty
    0x05: root_be
    0x55555555: funinfo_be
    0x06: eof
    0x07: continue_ptr
    0x08: continue_rec
    0x09: continue_val
    0x0C: free_ptr
    0x0D: free_rec
    0x0E: free_next
    0x0F: global_gen
    0x10: next_volid
    0x11: fileserver
    0x12: fs_uuid
    0x13: fs_ipv4list
    0x14: fileserver_list_ptr
    0x15: fileserver_list_rec
    0x16: fs_recno_list
    0x17: partition_list_ptr
    0x18: partition_list_rec
    0x19: partition_list_val
    0x1A: note_ptr
    0x1B: note_rec
    0x1C: note_utf8
    0x1D: volume
    0x1E: vol_name
    0x1F: vol_basic_info
    0x20: vol_cloneid
    0x21: vol_lockinfo
    0x22: vol_sitelist
    0x23: vol_idtree_ptr
    0x24: vol_idtree_rec
    0x25: vol_idtree_leaf
    0x26: vol_idtree_node
    0x27: vol_namehtree_ptr
    0x28: vol_namehtree_rec
    0x29: vol_namehtree_leaf
    0x2A: vol_namehtree_node
    0x2B: vol_namehtree_rootinfo
    0x2C: vol_namehtree_coll_rec
    0x2D: vol_namehtree_coll_val

  vl5_lock:
    1: move
    2: release
    3: backup
    4: delete
    5: dump
    6: unknown

  vl5_site:
    1: rw
    2: ro

  vl5_namehtree_hashfunc:
    1: crc32c
