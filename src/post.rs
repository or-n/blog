use crate::{route, util::*};
use std::fs::*;
use std::sync::{Arc, Mutex};
use warp::{http::StatusCode, path, Filter};

const ROOT: &str = "files";

pub fn api() -> route!(impl warp::Reply) {
    let meta: Vec<_> = file_names(ROOT, ".md")
        .unwrap()
        .into_iter()
        .map(|url| read_post_metadata(url).unwrap())
        .collect();
    let all_posts_metadata = Arc::new(Mutex::new(meta));
    let with_all_posts_metadata = warp::any().map(move || all_posts_metadata.clone());
    let list_metadata = path("files")
        .and(path::end())
        .and(warp::get())
        .and(with_all_posts_metadata.clone())
        .and_then(handle_list_metadata);
    let view_html = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::get())
        .map(handle_view_html);
    let view_markdown = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::put())
        .map(handle_view_markdown);
    let create = path("file")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::post())
        .and(with_all_posts_metadata.clone())
        .and(string_body(1_000_1000))
        .map(handle_create);
    let delete = path("del")
        .and(warp::path::param())
        .and(path::end())
        .and(warp::post())
        .and(with_all_posts_metadata.clone())
        .map(handle_delete);
    list_metadata
        .or(view_html)
        .or(view_markdown)
        .or(create)
        .or(delete)
}

async fn handle_list_metadata(
    meta: Arc<Mutex<Vec<Meta>>>,
) -> Result<impl warp::Reply, warp::Rejection> {
    let meta: Vec<_> = meta
        .lock()
        .unwrap()
        .iter()
        .map(|m| (m.url.clone(), m.image_url.clone()))
        .collect();
    Ok(warp::reply::json(&meta))
}

fn handle_view_html(path: String) -> impl warp::Reply {
    let contents = read_to_string(format!("{ROOT}/{}", &path)).expect(path.as_str());
    let markdown = render_markdown(contents.as_str());
    warp::reply::html(markdown)
}

fn handle_view_markdown(path: String) -> impl warp::Reply {
    let contents = read_to_string(format!("{ROOT}/{}", &path)).expect(path.as_str());
    warp::reply::html(contents)
}

fn handle_create(path: String, meta: Arc<Mutex<Vec<Meta>>>, body: String) -> impl warp::Reply {
    let full_path = format!("{ROOT}/{}.md", &path);
    match File::create(&full_path) {
        Ok(_) => {
            meta.lock().unwrap().push(Meta {
                url: path.clone(),
                image_url: "".to_string(),
            });
            std::fs::write(&full_path, &body).unwrap();
            println!("content: {}", body);
            warp::reply::with_status(
                format!("File saved successfully at path: \"{}\"", path),
                StatusCode::CREATED,
            )
        }
        Err(_) => warp::reply::with_status(
            format!("Error saving file at path: \"{}\"", path),
            StatusCode::CONFLICT,
        ),
    }
}

fn handle_delete(path: String, meta: Arc<Mutex<Vec<Meta>>>) -> impl warp::Reply {
    meta.lock().unwrap().retain(|m| &m.url != &path);
    std::fs::remove_file(format!("{ROOT}/{}.md", &path)).unwrap();
    warp::reply::with_status(
        format!("Deleted file at path: \"{}\"", path),
        StatusCode::OK,
    )
}

pub struct Meta {
    pub url: String,
    pub image_url: String,
}

pub fn read_post_metadata(url: String) -> std::io::Result<Meta> {
    let metadata = read_until_delimiter(format!("{ROOT}/{}.md", &url), "---")?;
    let lines: Vec<String> = metadata.lines().map(|x| x.to_string()).collect();
    Ok(Meta {
        url,
        image_url: lines[0].clone(),
    })
}
