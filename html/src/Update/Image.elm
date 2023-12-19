module Update.Image exposing (..)

import Animation
import Browser.Navigation as Nav
import File exposing (File)
import File.Select as Select
import Model exposing (..)


type ImageMsg
    = SelectImage
    | UploadImage
    | ImageLoaded File
    | Scale Float
    | Alpha Float
    | Animate Animation.Msg


update_image : ImageMsg -> ImageUploadModel -> Shared -> ( ImageUploadModel, Shared, Cmd ImageMsg )
update_image msg model shared =
    case msg of
        SelectImage ->
            ( model, shared, Select.file [ "image/png", "image/jpg" ] ImageLoaded )

        UploadImage ->
            ( model, { shared | error = Just "not implemented" }, Cmd.none )

        ImageLoaded file ->
            ( { model | image_file = Just file }
            , shared
            , Cmd.none
            )

        Scale value ->
            ( { model
                | anim_scale =
                    Animation.interrupt
                        [ Animation.to
                            [ Animation.scale value
                            ]
                        ]
                        model.anim_scale
              }
            , shared
            , Cmd.none
            )

        Alpha value ->
            ( { model
                | anim_alpha =
                    Animation.interrupt
                        [ Animation.to
                            [ Animation.backgroundColor
                                { red = 150
                                , green = 250
                                , blue = 200
                                , alpha = value
                                }
                            ]
                        ]
                        model.anim_alpha
              }
            , shared
            , Cmd.none
            )

        Animate m ->
            ( { model
                | anim_alpha = Animation.update m model.anim_alpha
                , anim_scale = Animation.update m model.anim_scale
              }
            , shared
            , Cmd.none
            )
