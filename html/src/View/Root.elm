module View.Root exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Model exposing (..)
import Update exposing (..)
import Update.Route exposing (..)
import View.Image exposing (..)


button_attrs =
    [ Background.color (rgb 1 1 1)
    , mouseOver [ Background.color (rgb 0 1 0.5) ]
    , Border.color (rgb 0 1 0)
    , Border.rounded 10
    , Border.width 4
    , padding 10
    ]


view_root file_names =
    let
        new =
            Input.button button_attrs
                { onPress = Just <| RouteMsg <| InternalUrlRequest (internal "/create")
                , label = text "New" |> el [ centerX, centerY ]
                }

        upload_file =
            Input.button button_attrs
                { onPress = Nothing

                -- init_image_upload
                --     |> ImageUpload
                --     |> NewRoute
                --     |> RouteMsg
                --     |> Just
                , label =
                    text "Upload image (refer to them using /images)"
                        |> el [ centerX, centerY ]
                }
    in
    column [ width fill, spacing 20 ]
        [ row [ spacing 20 ]
            [ text "Posts"
            , new
            , upload_file
            ]
        , case file_names of
            Just names ->
                view_names names

            _ ->
                none
        ]


view_names =
    List.map view_post_miniature
        >> column
            [ width fill
            , spacing 10
            ]


view_post_miniature name =
    link
        [ Background.color (rgb 1.0 1.0 1.0)
        , Border.rounded 10
        , width fill
        , padding 10
        , mouseOver [ Font.color (rgb 0 0.8 0) ]
        ]
        { url = name
        , label =
            Input.button []
                { onPress = Nothing
                , label = text name
                }
        }
