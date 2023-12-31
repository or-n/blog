use std::fs::*;
use warp::Filter;

pub mod post;
pub mod util;

fn html() -> route!(impl warp::Reply) {
    warp::fs::dir("html")
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    warp::serve(html().or(api()))
        .run(([127, 0, 0, 1], 3030))
        .await;
    Ok(())
}

fn api() -> route!(impl warp::Reply) {
    let end = warp::get().map(handle_end);
    post::api().or(end)
}

fn handle_end() -> impl warp::Reply {
    let contents = read_to_string("html/index.html").unwrap();
    //let modified_html_content = contents.replace("__PATH_PARAM__", &path);
    warp::reply::html(contents)
}
