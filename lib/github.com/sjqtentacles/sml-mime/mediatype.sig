(* mediatype.sig

   RFC 9110 media types: a type/subtype plus case-insensitive parameters,
   e.g. "text/html; charset=utf-8". Parsing is lenient about surrounding
   whitespace; formatting is canonical (lowercased type/subtype, params in
   given order). *)

signature MEDIA_TYPE =
sig
  type media_type =
    { typ : string          (* lowercased, e.g. "text" *)
    , subtype : string      (* lowercased, e.g. "html" *)
    , params : (string * string) list }  (* attribute lowercased, value as-is *)

  val parse  : string -> media_type option
  val format : media_type -> string

  (* Case-insensitive parameter lookup. *)
  val param  : media_type -> string -> string option
  (* "type/subtype" without parameters. *)
  val essence : media_type -> string
end
