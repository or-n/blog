module Update.Edit exposing (..)

import Http
import Model exposing (..)


type EditMsg
    = TitleChange String
    | ContentChange String
    | Save EditFileModel
    | Saved (Result Http.Error String)


update_edit : EditMsg -> EditFileModel -> Shared -> ( EditFileModel, Shared, Cmd EditMsg )
update_edit msg model shared =
    case msg of
        TitleChange new ->
            ( { model | title = new }, shared, Cmd.none )

        ContentChange new ->
            ( { model | content = new }, shared, Cmd.none )

        Save data ->
            case data.title of
                "" ->
                    ( model
                    , { shared | error = Just "url cannot be empty" }
                    , Cmd.none
                    )

                _ ->
                    ( model
                    , shared
                    , Cmd.batch
                        [ Http.post
                            { url = "file/" ++ data.title
                            , body = Http.stringBody "text/markdown" data.content
                            , expect = Http.expectString Saved
                            }
                        , case data.initial_title of
                            Just title ->
                                Http.post
                                    { url = "del/" ++ title
                                    , body = Http.emptyBody
                                    , expect = Http.expectString Saved
                                    }

                            _ ->
                                Cmd.none
                        ]
                    )

        Saved result ->
            case result of
                Ok m ->
                    ( model
                    , { shared | error = Just m }
                    , Cmd.none
                      ---Task.perform LoadNames (Task.succeed ())
                    )

                Err e ->
                    ( model
                    , { shared | error = Just <| showError e }
                    , Cmd.none
                    )


showError error =
    case error of
        Http.BadStatus n ->
            "Bad Status: " ++ String.fromInt n

        _ ->
            "Error"
