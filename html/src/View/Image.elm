module View.Image exposing (..)

import Animation
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import File
import Model exposing (..)
import Update exposing (..)
import Update.Image exposing (..)
import View.Util exposing (button_style)


view_image_tool : ImageUploadModel -> Element ImageMsg
view_image_tool data =
    column
        [ spacing 10 ]
        [ Input.button
            [ mouseOver [ Font.color (rgb 0 1 0) ]
            , padding 10
            , Border.width 4
            , Border.color (rgb 0 1 0)
            ]
            { onPress = Just SelectImage
            , label = text "Select image"
            }
        , case data.image_file of
            Just file ->
                text <| File.name file

            _ ->
                none
        , let
            scale_attrs =
                List.map htmlAttribute (Animation.render data.anim_scale)

            alpha_attrs =
                List.map htmlAttribute (Animation.render data.anim_alpha)

            style =
                events
                    ++ scale_attrs
                    ++ gradient
                    ++ button_style

            text_attrs =
                [ Font.color (rgb 0 0 0)
                , width fill
                , height fill
                , paddingXY 25 15
                , Border.rounded 10
                ]
          in
          Input.button style
            { onPress = Just UploadImage
            , label = text "Upload" |> el (text_attrs ++ alpha_attrs)
            }
        ]


mul : Float -> Color -> Color
mul value color =
    let
        c =
            toRgb color
    in
    fromRgb
        { red = c.red * value
        , green = c.green * value
        , blue = c.blue * value
        , alpha = c.alpha
        }


gradient =
    [ Background.gradient
        { angle = 3.14159 * 0.75
        , steps =
            [ rgb 0.25 1.0 0.5, rgb 0.0 1.0 1.0 ]
                |> List.map (mul 1.0)
        }
    , Font.bold

    --, Font.color (rgb 1 1 0.5)
    ]


hover_gradient =
    Background.gradient
        { angle = 0.0
        , steps = [ rgb 0.5 1.0 0.5, rgb 0.5 0.5 0.5 ]
        }
        |> List.singleton
        |> mouseOver


events =
    [ Events.onMouseEnter <| Scale 0.9

    --, Events.onMouseEnter <| Alpha 0.0
    , Events.onMouseLeave <| Scale 1.0

    --, Events.onMouseLeave <| Alpha 1.0
    ]
