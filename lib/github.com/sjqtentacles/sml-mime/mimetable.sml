(* mimetable.sml -- extension -> MIME type lookup. *)

structure MimeTable :> MIME_TABLE =
struct
  val default = "application/octet-stream"

  val table =
    [ ("html", "text/html; charset=utf-8")
    , ("htm",  "text/html; charset=utf-8")
    , ("css",  "text/css; charset=utf-8")
    , ("js",   "text/javascript; charset=utf-8")
    , ("mjs",  "text/javascript; charset=utf-8")
    , ("json", "application/json")
    , ("xml",  "application/xml")
    , ("txt",  "text/plain; charset=utf-8")
    , ("md",   "text/markdown; charset=utf-8")
    , ("csv",  "text/csv; charset=utf-8")
    , ("svg",  "image/svg+xml")
    , ("png",  "image/png")
    , ("jpg",  "image/jpeg")
    , ("jpeg", "image/jpeg")
    , ("gif",  "image/gif")
    , ("webp", "image/webp")
    , ("ico",  "image/x-icon")
    , ("woff", "font/woff")
    , ("woff2","font/woff2")
    , ("ttf",  "font/ttf")
    , ("otf",  "font/otf")
    , ("pdf",  "application/pdf")
    , ("zip",  "application/zip")
    , ("gz",   "application/gzip")
    , ("wasm", "application/wasm")
    , ("mp3",  "audio/mpeg")
    , ("mp4",  "video/mp4")
    , ("webm", "video/webm")
    , ("wav",  "audio/wav") ]

  fun byExtension ext =
    let val e = String.map Char.toLower ext in
      Option.map #2 (List.find (fn (k, _) => k = e) table)
    end

  fun byFilename name =
    let
      val chars = String.explode name
      fun lastDot (cs, idx, found) =
        case cs of
            [] => found
          | (#"." :: rest) => lastDot (rest, idx + 1, SOME idx)
          | (_ :: rest) => lastDot (rest, idx + 1, found)
      val pos = lastDot (chars, 0, NONE)
    in
      case pos of
          NONE => NONE
        | SOME i =>
            if i + 1 >= String.size name then NONE
            else byExtension (String.extract (name, i + 1, NONE))
    end
end
