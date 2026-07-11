(* demo.sml - exercise all three sml-mime structures: parse/format a media
   type with parameters, look up a few filename extensions, and build a
   small multipart/form-data body from parts before splitting it back
   apart. Deterministic: pure string transformations, no I/O. *)

val () = print "sml-mime demo\n"

(* 1. MediaType: parse, essence, and case-insensitive parameter lookup. *)
val mt = valOf (MediaType.parse "text/html; charset=UTF-8")
val () = print "MediaType.parse \"text/html; charset=UTF-8\":\n"
val () = print ("  essence          = " ^ MediaType.essence mt ^ "\n")
val () = print ("  format           = " ^ MediaType.format mt ^ "\n")
val () = print ("  param \"charset\"  = "
                ^ (case MediaType.param mt "charset" of SOME v => v | NONE => "NONE") ^ "\n")
val () = print ("  param \"CharSet\"  = "
                ^ (case MediaType.param mt "CharSet" of SOME v => v | NONE => "NONE") ^ "\n")
val () = print ("  param \"boundary\" = "
                ^ (case MediaType.param mt "boundary" of SOME v => v | NONE => "NONE") ^ "\n")

(* 2. MimeTable: extension and filename lookups, plus the default. *)
val () = print "MimeTable lookups:\n"
val () = List.app
  (fn f => print ("  byFilename \"" ^ f ^ "\" = "
                  ^ (case MimeTable.byFilename f of SOME v => v | NONE => "NONE") ^ "\n"))
  ["index.html", "photo.PNG", "archive.tar.xyz"]
val () = print ("  default            = " ^ MimeTable.default ^ "\n")

(* 3. Multipart: build a body from parts, then split it back apart. *)
val boundary = "demo-boundary-42"
val parts =
  [ { headers = [("Content-Disposition", "form-data; name=\"username\"")]
    , body = "ada" }
  , { headers = [ ("Content-Disposition",
                    "form-data; name=\"avatar\"; filename=\"a.png\"")
                , ("Content-Type", "image/png") ]
    , body = "PNGDATA..." }
  ]
val built = Multipart.build { boundary = boundary, parts = parts }
val () = print ("Multipart.build produced " ^ Int.toString (String.size built) ^ " bytes\n")

val rebuilt = valOf (Multipart.split { boundary = boundary, body = built })
val () = print ("Multipart.split recovered " ^ Int.toString (List.length rebuilt) ^ " parts:\n")
val () = List.app
  (fn p =>
     print ("  fieldName = "
            ^ (case Multipart.fieldName p of SOME v => v | NONE => "NONE")
            ^ ", fileName = "
            ^ (case Multipart.fileName p of SOME v => v | NONE => "NONE")
            ^ ", body = \"" ^ #body p ^ "\"\n"))
  rebuilt
