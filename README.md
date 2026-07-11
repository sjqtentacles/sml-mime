# sml-mime

[![CI](https://github.com/sjqtentacles/sml-mime/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-mime/actions/workflows/ci.yml)

Pure, I/O-free MIME helpers for Standard ML: media-type parsing/formatting
([RFC 9110](https://www.rfc-editor.org/rfc/rfc9110)), a filename-extension ->
MIME type table, and `multipart/form-data` split/build
([RFC 7578](https://www.rfc-editor.org/rfc/rfc7578)). Everything is a
deterministic `string -> string` function.

Builds and tests identically under **MLton** and **Poly/ML**.

## Features

- **`MediaType`**: parse `"text/html; charset=utf-8"` into a record, with
  quote-aware parameter splitting, canonical (lowercased) formatting, and
  case-insensitive parameter lookup.
- **`MimeTable`**: common extension -> MIME mappings, by bare extension or by
  filename/path, with an `application/octet-stream` default.
- **`Multipart`**: split a `multipart/form-data` body into parts (each with its
  own headers + raw body) and build one from parts, plus `fieldName`/`fileName`
  helpers reading `Content-Disposition`.

Vendors [`sml-http`](https://github.com/sjqtentacles/sml-http) (which vendors
`sml-uri`).

## API sketch

```sml
(* MediaType *)
type media_type = { typ : string, subtype : string, params : (string * string) list }
val parse   : string -> media_type option
val format  : media_type -> string
val param   : media_type -> string -> string option
val essence : media_type -> string

(* MimeTable *)
val byExtension : string -> string option
val byFilename  : string -> string option
val default     : string

(* Multipart *)
type part = { headers : (string * string) list, body : string }
val split     : { boundary : string, body : string } -> part list option
val build     : { boundary : string, parts : part list } -> string
val fieldName : part -> string option
val fileName  : part -> string option
```

## Example

```sml
val SOME mt = MediaType.parse "text/html; charset=utf-8"
val SOME "utf-8" = MediaType.param mt "charset"

val SOME "image/png" = MimeTable.byFilename "img/logo.png"

val SOME parts = Multipart.split { boundary = b, body = rawBody }
val SOME "avatar" = Multipart.fieldName (hd parts)
```

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
parses a media type and looks up its parameters, looks up a few filename
extensions, and builds a multipart body from two parts before splitting it
back apart (output is byte-identical under MLton and Poly/ML):

```
sml-mime demo
MediaType.parse "text/html; charset=UTF-8":
  essence          = text/html
  format           = text/html; charset=UTF-8
  param "charset"  = UTF-8
  param "CharSet"  = UTF-8
  param "boundary" = NONE
MimeTable lookups:
  byFilename "index.html" = text/html; charset=utf-8
  byFilename "photo.PNG" = image/png
  byFilename "archive.tar.xyz" = NONE
  default            = application/octet-stream
Multipart.build produced 222 bytes
Multipart.split recovered 2 parts:
  fieldName = username, fileName = NONE, body = "ada"
  fieldName = avatar, fileName = a.png, body = "PNGDATA..."
```

## Build

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
```

**30 deterministic checks**, green under both compilers.

## Installation

```
require {
  github.com/sjqtentacles/sml-mime
}
```

then `smlpkg sync`, or vendor under `lib/github.com/sjqtentacles/sml-mime/` and
reference `sml-mime.mlb`.

## Layout

```
lib/github.com/sjqtentacles/
  sml-mime/
    mediatype.{sig,sml}  RFC 9110 media-type parse/format
    mimetable.{sig,sml}  extension -> MIME table
    multipart.{sig,sml}  RFC 7578 multipart/form-data split/build
    sources.mlb sml-mime.mlb
  sml-http/  sml-uri/    vendored dependencies (committed)
test/                    Harness suite (30 checks)
```

## License

MIT. See [LICENSE](LICENSE).
