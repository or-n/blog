module Update.Route exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Http
import Model exposing (..)
import Task
import Url exposing (Url)


type RouteMsg
    = --NewRoute Route
      UrlRequest UrlRequest
    | InternalUrlRequest Url
    | FileLoaded String (Result Http.Error String)
    | Load String



--| NewRoute Route


update_route : RouteMsg -> Model -> ( Model, Cmd RouteMsg )
update_route msg model =
    case msg of
        {- NewRoute route ->
           ( { model | route = route }
           , Cmd.none
           )
        -}
        UrlRequest urlRequest ->
            case urlRequest of
                Internal url ->
                    update_route (InternalUrlRequest url) model

                External url ->
                    ( model, Nav.load url )

        InternalUrlRequest url ->
            ( model
            , Cmd.batch
                [ Task.perform Load (Task.succeed url.path)
                , Nav.pushUrl model.shared.key url.path
                ]
            )

        FileLoaded name result ->
            let
                route =
                    case result of
                        Ok contents ->
                            FileView
                                { name = name
                                , loaded_file = contents
                                }

                        _ ->
                            NotFound
            in
            ( { model | route = route }
                |> update_shared (set_error Nothing)
            , Cmd.none
            )

        {-

           Idea: Routes with (Maybe Data)

        -}
        Load path ->
            if path == "/" then
                ( { model | route = Root }
                    |> update_shared (set_error Nothing)
                , Cmd.none
                )

            else if path == "/create" then
                ( { model
                    | route =
                        EditFile
                            { initial_title = Nothing
                            , title = ""
                            , content = ""
                            }
                  }
                    |> update_shared (set_error Nothing)
                , Cmd.none
                )

            else
                ( model
                , Http.get
                    { url = "file" ++ path ++ ".md"
                    , expect = Http.expectString (FileLoaded (String.dropLeft 1 path))
                    }
                )
