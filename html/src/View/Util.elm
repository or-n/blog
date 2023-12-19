module View.Util exposing (..)

import Element exposing (..)
import Element.Border as Border
import Html.Parser
import Html.Parser.Util


vsep : Int -> List (Attribute msg) -> Element msg
vsep value style =
    let
        new_style =
            [ width fill
            , height (minimum value shrink)
            ]
                ++ style
    in
    el new_style none


button_style : List (Attribute msg)
button_style =
    [ padding 6
    , Border.color (rgb 0.0 0.0 0.0)

    {- , Border.widthEach
       { bottom = 2
       , top = 1
       , left = 1
       , right = 1
       }
    -}
    , Border.rounded 10
    ]


embed xs =
    case Html.Parser.run xs of
        Ok nodes ->
            Html.Parser.Util.toVirtualDom nodes
                |> List.map html
                |> column
                    []

        _ ->
            text "Parsing error"
