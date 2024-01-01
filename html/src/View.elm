module View exposing (..)

import Browser exposing (Document)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Model exposing (..)
import Update exposing (..)
import Update.Edit exposing (..)
import Update.Route exposing (..)
import View.Edit exposing (..)
import View.Image exposing (..)
import View.Root exposing (..)
import View.Util exposing (embed)


documentView : Model -> Document Msg
documentView model =
    { title = "Blog"
    , body = [ view model ]
    }


view_route : Model -> Element Msg
view_route model =
    case model.route of
        Root ->
            view_root model.shared.meta

        FileView data ->
            column []
                [ row [ spacing 20 ]
                    [ Input.button button_attrs
                        { onPress =
                            InternalUrlRequest (internal "/")
                                |> RouteMsg
                                |> Just
                        , label = text "↩️"
                        }
                    , Input.button button_attrs
                        { onPress = Just (Edit data.name)
                        , label = text "Edit"
                        }
                    , Input.button button_attrs
                        { onPress = Just (Delete data.name)
                        , label = text "Delete"
                        }
                    ]
                , embed data.loaded_file
                ]

        EditFile data ->
            view_edit data
                |> Element.map EditMsg

        ImageUpload data ->
            view_image_tool data
                |> Element.map ImageMsg

        NotFound ->
            text "Not found"


view_error shared =
    case shared.error of
        Just msg ->
            text msg

        _ ->
            none


view : Model -> Html Msg
view model =
    column
        [ centerX
        , spacing 50
        , width (maximum 1050 fill)
        , padding 50
        ]
        [ view_error model.shared
        , view_route model |> content
        ]
        |> layoutWith
            { options =
                [ focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            [ Font.family
                [ Font.external
                    { url = "https://fonts.googleapis.com/css?family=Audiowide"
                    , name = "Audiowide"
                    }
                ]
            ]


content =
    el
        [ Background.color (rgb 0.9 1.0 0.9)
        , paddingXY 40 20
        , Border.rounded 10
        , Border.color (rgb 0.5 1.0 0.5)
        , Border.width 10
        , width fill
        ]
