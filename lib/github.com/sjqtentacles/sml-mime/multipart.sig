(* multipart.sig

   multipart/form-data (RFC 7578) splitting and building. A body is a list of
   parts, each with its own headers and raw content. The boundary is the
   delimiter taken from the Content-Type ("boundary=...").

   This is a pure byte-level codec: no streaming, no temp files. *)

signature MULTIPART =
sig
  type part =
    { headers : (string * string) list   (* part headers, e.g. Content-Disposition *)
    , body : string }

  (* Split a multipart body given the boundary (without the leading "--").
     Returns NONE on a malformed body. *)
  val split : { boundary : string, body : string } -> part list option

  (* Build a multipart body from parts and a boundary. Returns the body; the
     caller sets Content-Type: multipart/form-data; boundary=<boundary>. *)
  val build : { boundary : string, parts : part list } -> string

  (* Convenience: extract the form field name from a part's
     Content-Disposition header, if present. *)
  val fieldName : part -> string option
  (* Extract the filename attribute from Content-Disposition, if present. *)
  val fileName  : part -> string option
end
