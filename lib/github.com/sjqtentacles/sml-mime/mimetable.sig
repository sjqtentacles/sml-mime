(* mimetable.sig

   A small filename-extension -> MIME type table, the common cases a static
   file server needs. Lookup is case-insensitive on the extension. *)

signature MIME_TABLE =
sig
  (* Look up by bare extension ("html") or by filename/path ("a/b.html").
     Returns NONE when unknown. *)
  val byExtension : string -> string option
  val byFilename  : string -> string option
  (* The fallback used by static servers when the type is unknown. *)
  val default : string
end
