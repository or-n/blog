module Model exposing (..)

import Animation
import Browser.Navigation as Nav
import File exposing (File)


type alias Model =
    { route : Route
    , shared : Shared
    }

type alias Meta = (String, String)

type alias Shared =
    { key : Nav.Key
    , error : Maybe String
    , meta : Maybe (List Meta)
    }


type Route
    = ImageUpload ImageUploadModel
    | FileView FileViewModel
    | EditFile EditFileModel
    | Root
    | NotFound


type alias EditFileModel =
    { initial_title : Maybe String
    , title : String
    , content : String
    }


type alias ImageUploadModel =
    { image_file : Maybe File
    , anim_alpha : Animation.State
    , anim_scale : Animation.State
    }


type alias FileViewModel =
    { name : String
    , loaded_file : String
    }


set_error v r =
    { r | error = v }


update_shared update r =
    let
        shared =
            r.shared
    in
    { r | shared = update shared }


init : Nav.Key -> Model
init key =
    { route = Root
    , shared = init_shared key
    }


init_shared key =
    { meta = Nothing
    , key = key
    , error = Nothing
    }


init_image_upload =
    { image_file = Nothing
    , anim_alpha =
        Animation.styleWith
            (Animation.speed { perSecond = 4 })
            [ Animation.backgroundColor
                { red = 150
                , green = 250
                , blue = 200
                , alpha = 1
                }
            , Animation.scale 1
            ]
    , anim_scale =
        Animation.styleWith
            (Animation.speed { perSecond = 4 })
            [ Animation.scale 1
            ]
    }
