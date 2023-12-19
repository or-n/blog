module View.Edit exposing (..)

import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Update exposing (..)
import Update.Edit exposing (..)


view_edit data =
    let
        title =
            Input.text
                [ width fill
                ]
                { onChange = TitleChange
                , text = data.title
                , placeholder = Nothing
                , label =
                    Input.labelLeft
                        [ paddingEach
                            { top = 0
                            , bottom = 0
                            , left = 0
                            , right = 10
                            }
                        ]
                        (text "url")
                }

        image =
            Input.text
                [ width fill
                ]
                { onChange = TitleChange
                , text = "not implemented"
                , placeholder = Nothing
                , label =
                    Input.labelLeft
                        [ paddingEach
                            { top = 0
                            , bottom = 0
                            , left = 0
                            , right = 10
                            }
                        ]
                        (text "image_url")
                }

        content =
            Input.multiline
                [ width fill
                , height (minimum 600 fill)
                ]
                { onChange = ContentChange
                , text = data.content
                , placeholder = Nothing
                , label =
                    Input.labelHidden ""
                , spellcheck = False
                }

        save =
            Input.button
                [ Border.color (rgb 0 1 0)
                , Border.rounded 10
                , padding 10
                , mouseOver [ Font.color (rgb 0 1 0) ]
                ]
                { onPress = Just <| Save data
                , label =
                    text "Save"
                }
    in
    column
        [ width fill, spacing 20 ]
        [ title
        , image
        , content
        , save
        ]
