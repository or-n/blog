module View.Markdown exposing (..)

import Element exposing (..)
import Markdown


render xs =
    Markdown.toHtml [] xs
        |> html
